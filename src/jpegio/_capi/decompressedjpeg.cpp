/* Hand-written CPython C-API implementation of jpegio.decompressedjpeg.
 *
 * This is the "from scratch" (no Cython) binding. It wraps the C++ jpegio::jstruct
 * backend and exposes the DecompressedJpeg type, building NumPy arrays over the
 * jstruct buffers with the NumPy C-API.
 *
 * The coefficient / quantization / spatial arrays are zero-copy *views* onto the
 * jstruct buffers (so modifying them and calling write() round-trips), and they
 * keep the owning DecompressedJpeg alive via their base object. That creates an
 * object<->array reference cycle, which is handled with the cyclic GC protocol.
 */
#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <structmember.h>
#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
#include <numpy/arrayobject.h>

#include <string>
#include <vector>
#include <cstring>
#include <exception>

#include "jstruct.h"

using jpegio::jstruct;
using jpegio::mat2D;
using jpegio::struct_comp_info;
using jpegio::struct_huff_tables;

#define DCTSIZE 8

typedef struct {
    PyObject_HEAD
    jstruct *obj;         /* borrowed pointer into the `owner` capsule */
    PyObject *owner;      /* PyCapsule that owns the current jstruct */
    PyObject *comp_info;
    PyObject *quant_tables;
    PyObject *coef_arrays;
    PyObject *spatial_arrays;
    PyObject *ac_huff_tables;
    PyObject *dc_huff_tables;
    PyObject *markers;
} DecompressedJpegObject;


/* ------------------------------------------------------------------ helpers */

/* Each exported NumPy array is based on the per-read `owner` capsule (not on the
   DecompressedJpeg), so the specific jstruct that backs an array stays alive as
   long as that array does -- even across a re-read() or after the
   DecompressedJpeg itself is dropped. */
static void
jstruct_capsule_destructor(PyObject *capsule)
{
    jstruct *p = (jstruct *)PyCapsule_GetPointer(capsule, "jpegio.jstruct");
    delete p;
}

/* Cached jpegio.componentinfo.ComponentInfo type (borrowed, kept by the static). */
static PyObject *
get_component_info_type(void)
{
    static PyObject *cls = NULL;
    if (cls == NULL) {
        PyObject *mod = PyImport_ImportModule("jpegio.componentinfo");
        if (mod == NULL)
            return NULL;
        cls = PyObject_GetAttrString(mod, "ComponentInfo");
        Py_DECREF(mod);
    }
    return cls;
}

static int
set_long_attr(PyObject *o, const char *name, long value)
{
    PyObject *v = PyLong_FromLong(value);
    if (v == NULL)
        return -1;
    int r = PyObject_SetAttrString(o, name, v);
    Py_DECREF(v);
    return r;
}

static int
set_ulong_attr(PyObject *o, const char *name, unsigned long value)
{
    PyObject *v = PyLong_FromUnsignedLong(value);
    if (v == NULL)
        return -1;
    int r = PyObject_SetAttrString(o, name, v);
    Py_DECREF(v);
    return r;
}

/* Build a writable 2-D int32 NumPy array that is a zero-copy view over a mat2D
   buffer, keeping `base` alive. */
static PyObject *
wrap_mat2D(mat2D<int> *m, PyObject *base)
{
    npy_intp dims[2];
    dims[0] = m->rows;
    dims[1] = m->cols;
    PyObject *arr = PyArray_SimpleNewFromData(2, dims, NPY_INT, (void *)m->GetBuffer());
    if (arr == NULL)
        return NULL;
    Py_INCREF(base);
    if (PyArray_SetBaseObject((PyArrayObject *)arr, base) < 0) {
        Py_DECREF(base);
        Py_DECREF(arr);
        return NULL;
    }
    return arr;
}

/* Build a 1-D int32 NumPy array that is a zero-copy view over a std::vector<int>. */
static PyObject *
wrap_int_vector(std::vector<int> &vec, PyObject *base)
{
    npy_intp n = (npy_intp)vec.size();
    void *data = n > 0 ? (void *)&vec[0] : NULL;
    PyObject *arr = PyArray_SimpleNewFromData(1, &n, NPY_INT, data);
    if (arr == NULL)
        return NULL;
    Py_INCREF(base);
    if (PyArray_SetBaseObject((PyArrayObject *)arr, base) < 0) {
        Py_DECREF(base);
        Py_DECREF(arr);
        return NULL;
    }
    return arr;
}


/* ----------------------------------------------------------- (de)allocation */

static PyObject *
DecompressedJpeg_new(PyTypeObject *type, PyObject *args, PyObject *kwds)
{
    DecompressedJpegObject *self = (DecompressedJpegObject *)type->tp_alloc(type, 0);
    if (self == NULL)
        return NULL;
    self->obj = NULL;
    self->owner = NULL;
    self->comp_info = PyList_New(0);
    self->quant_tables = PyList_New(0);
    self->coef_arrays = PyList_New(0);
    self->spatial_arrays = PyList_New(0);
    self->ac_huff_tables = PyList_New(0);
    self->dc_huff_tables = PyList_New(0);
    self->markers = PyList_New(0);
    if (!self->comp_info || !self->quant_tables || !self->coef_arrays ||
        !self->spatial_arrays || !self->ac_huff_tables || !self->dc_huff_tables ||
        !self->markers) {
        Py_DECREF(self);
        return NULL;
    }
    return (PyObject *)self;
}

static int
DecompressedJpeg_traverse(DecompressedJpegObject *self, visitproc visit, void *arg)
{
    Py_VISIT(self->owner);
    Py_VISIT(self->comp_info);
    Py_VISIT(self->quant_tables);
    Py_VISIT(self->coef_arrays);
    Py_VISIT(self->spatial_arrays);
    Py_VISIT(self->ac_huff_tables);
    Py_VISIT(self->dc_huff_tables);
    Py_VISIT(self->markers);
    return 0;
}

static int
DecompressedJpeg_clear(DecompressedJpegObject *self)
{
    self->obj = NULL;             /* borrowed; owned by the capsule below */
    Py_CLEAR(self->owner);
    Py_CLEAR(self->comp_info);
    Py_CLEAR(self->quant_tables);
    Py_CLEAR(self->coef_arrays);
    Py_CLEAR(self->spatial_arrays);
    Py_CLEAR(self->ac_huff_tables);
    Py_CLEAR(self->dc_huff_tables);
    Py_CLEAR(self->markers);
    return 0;
}

static void
DecompressedJpeg_dealloc(DecompressedJpegObject *self)
{
    PyObject_GC_UnTrack(self);
    /* The jstruct is owned by self->owner (a capsule); clear() drops it. */
    DecompressedJpeg_clear(self);
    Py_TYPE(self)->tp_free((PyObject *)self);
}


/* ------------------------------------------------------------ read pipeline */

static int
read_comp_info(DecompressedJpegObject *self)
{
    PyObject *cls = get_component_info_type();
    if (cls == NULL)
        return -1;
    PyObject *lst = PyList_New(0);
    if (lst == NULL)
        return -1;
    for (size_t i = 0; i < self->obj->comp_info.size(); i++) {
        struct_comp_info *ci = self->obj->comp_info[i];
        PyObject *o = PyObject_CallObject(cls, NULL);
        if (o == NULL) { Py_DECREF(lst); return -1; }
        if (set_long_attr(o, "component_id", ci->component_id) < 0 ||
            set_long_attr(o, "h_samp_factor", ci->h_samp_factor) < 0 ||
            set_long_attr(o, "v_samp_factor", ci->v_samp_factor) < 0 ||
            set_long_attr(o, "quant_tbl_no", ci->quant_tbl_no) < 0 ||
            set_long_attr(o, "ac_tbl_no", ci->ac_tbl_no) < 0 ||
            set_long_attr(o, "dc_tbl_no", ci->dc_tbl_no) < 0 ||
            set_ulong_attr(o, "downsampled_height", ci->downsampled_height) < 0 ||
            set_ulong_attr(o, "downsampled_width", ci->downsampled_width) < 0 ||
            set_ulong_attr(o, "height_in_blocks", ci->height_in_blocks) < 0 ||
            set_ulong_attr(o, "width_in_blocks", ci->width_in_blocks) < 0) {
            Py_DECREF(o); Py_DECREF(lst); return -1;
        }
        if (PyList_Append(lst, o) < 0) { Py_DECREF(o); Py_DECREF(lst); return -1; }
        Py_DECREF(o);
    }
    Py_SETREF(self->comp_info, lst);
    return 0;
}

static int
read_markers(DecompressedJpegObject *self)
{
    PyObject *lst = PyList_New(0);
    if (lst == NULL)
        return -1;
    for (size_t i = 0; i < self->obj->markers.size(); i++) {
        const std::string &m = self->obj->markers[i];
        PyObject *b = PyBytes_FromStringAndSize(m.data(), (Py_ssize_t)m.size());
        if (b == NULL) { Py_DECREF(lst); return -1; }
        if (PyList_Append(lst, b) < 0) { Py_DECREF(b); Py_DECREF(lst); return -1; }
        Py_DECREF(b);
    }
    Py_SETREF(self->markers, lst);
    return 0;
}

static int
read_mat2D_list(PyObject **slot, std::vector<mat2D<int> *> &src, PyObject *base)
{
    PyObject *lst = PyList_New(0);
    if (lst == NULL)
        return -1;
    for (size_t i = 0; i < src.size(); i++) {
        PyObject *arr = wrap_mat2D(src[i], base);
        if (arr == NULL) { Py_DECREF(lst); return -1; }
        if (PyList_Append(lst, arr) < 0) { Py_DECREF(arr); Py_DECREF(lst); return -1; }
        Py_DECREF(arr);
    }
    Py_SETREF(*slot, lst);
    return 0;
}

static int
read_huff_list(PyObject **slot, std::vector<struct_huff_tables *> &src, PyObject *base)
{
    PyObject *lst = PyList_New(0);
    if (lst == NULL)
        return -1;
    for (size_t i = 0; i < src.size(); i++) {
        PyObject *counts = wrap_int_vector(src[i]->counts, base);
        if (counts == NULL) { Py_DECREF(lst); return -1; }
        PyObject *symbols = wrap_int_vector(src[i]->symbols, base);
        if (symbols == NULL) { Py_DECREF(counts); Py_DECREF(lst); return -1; }
        PyObject *d = PyDict_New();
        if (d == NULL) { Py_DECREF(counts); Py_DECREF(symbols); Py_DECREF(lst); return -1; }
        int rc = PyDict_SetItemString(d, "counts", counts);
        if (rc == 0) rc = PyDict_SetItemString(d, "symbols", symbols);
        Py_DECREF(counts);
        Py_DECREF(symbols);
        if (rc < 0) { Py_DECREF(d); Py_DECREF(lst); return -1; }
        if (PyList_Append(lst, d) < 0) { Py_DECREF(d); Py_DECREF(lst); return -1; }
        Py_DECREF(d);
    }
    Py_SETREF(*slot, lst);
    return 0;
}

static PyObject *
DecompressedJpeg_read(DecompressedJpegObject *self, PyObject *args, PyObject *kwds)
{
    static char *kwlist[] = {(char *)"fpath", (char *)"read_spatial", NULL};
    PyObject *fpath_obj;
    int read_spatial = 0;
    if (!PyArg_ParseTupleAndKeywords(args, kwds, "O|p", kwlist, &fpath_obj, &read_spatial))
        return NULL;

    PyObject *fspath = PyOS_FSPath(fpath_obj);
    if (fspath == NULL)
        return NULL;
    PyObject *path_bytes = NULL;
    if (!PyUnicode_FSConverter(fspath, &path_bytes)) {
        Py_DECREF(fspath);
        return NULL;
    }
    Py_DECREF(fspath);
    std::string path(PyBytes_AS_STRING(path_bytes));
    Py_DECREF(path_bytes);

    /* Validation matching the reference implementation. */
    {
        PyObject *os_path = PyImport_ImportModule("os.path");
        if (os_path == NULL) return NULL;
        PyObject *pathobj = PyUnicode_DecodeFSDefault(path.c_str());
        if (pathobj == NULL) { Py_DECREF(os_path); return NULL; }
        PyObject *isfile = PyObject_CallMethod(os_path, "isfile", "O", pathobj);
        int is_file = isfile != NULL && PyObject_IsTrue(isfile);
        Py_XDECREF(isfile);
        if (!is_file) {
            PyErr_Format(PyExc_FileNotFoundError, "[JPEGIO] No such file: %s", path.c_str());
            Py_DECREF(pathobj); Py_DECREF(os_path); return NULL;
        }
        PyObject *size = PyObject_CallMethod(os_path, "getsize", "O", pathobj);
        long sz = size != NULL ? PyLong_AsLong(size) : -1;
        Py_XDECREF(size);
        Py_DECREF(pathobj);
        Py_DECREF(os_path);
        if (sz == 0) {
            PyErr_Format(PyExc_ValueError, "[JPEGIO] Empty file: %s", path.c_str());
            return NULL;
        }
    }

    jstruct *js = new jstruct();
    try {
        js->jpeg_load(path);
    } catch (const std::exception &e) {
        delete js;
        PyErr_SetString(PyExc_RuntimeError, e.what());
        return NULL;
    } catch (...) {
        delete js;
        PyErr_SetString(PyExc_RuntimeError, "[JSTRUCT] unknown error while reading JPEG");
        return NULL;
    }

    /* Hand the jstruct to a capsule that owns it. Exported arrays are based on
       this capsule, so they keep *this* jstruct alive even across a later
       re-read() into the same object or after the object itself is dropped. */
    PyObject *cap = PyCapsule_New(js, "jpegio.jstruct", jstruct_capsule_destructor);
    if (cap == NULL) { delete js; return NULL; }
    Py_XSETREF(self->owner, cap);   /* drops the previous read's owner (if any) */
    self->obj = js;                 /* borrowed pointer into `cap` */

    if (read_comp_info(self) < 0) return NULL;
    if (read_markers(self) < 0) return NULL;
    if (read_mat2D_list(&self->quant_tables, self->obj->quant_tables, self->owner) < 0) return NULL;
    if (read_huff_list(&self->ac_huff_tables, self->obj->ac_huff_tables, self->owner) < 0) return NULL;
    if (read_huff_list(&self->dc_huff_tables, self->obj->dc_huff_tables, self->owner) < 0) return NULL;
    if (read_mat2D_list(&self->coef_arrays, self->obj->coef_arrays, self->owner) < 0) return NULL;

    PyObject *empty = PyList_New(0);
    if (empty == NULL) return NULL;
    Py_SETREF(self->spatial_arrays, empty);
    if (read_spatial) {
        try {
            self->obj->spatial_load(path);
            self->obj->load_spatial = true;
        } catch (const std::exception &e) {
            PyErr_SetString(PyExc_RuntimeError, e.what());
            return NULL;
        }
        if (read_mat2D_list(&self->spatial_arrays, self->obj->spatial_arrays, self->owner) < 0)
            return NULL;
    }

    Py_RETURN_NONE;
}


/* ------------------------------------------------------------------- write */

static PyObject *
DecompressedJpeg_write(DecompressedJpegObject *self, PyObject *args)
{
    PyObject *fpath_obj;
    if (!PyArg_ParseTuple(args, "O", &fpath_obj))
        return NULL;
    if (self->obj == NULL) {
        PyErr_SetString(PyExc_RuntimeError, "[JPEGIO] no JPEG has been read yet");
        return NULL;
    }
    PyObject *fspath = PyOS_FSPath(fpath_obj);
    if (fspath == NULL)
        return NULL;
    PyObject *path_bytes = NULL;
    if (!PyUnicode_FSConverter(fspath, &path_bytes)) { Py_DECREF(fspath); return NULL; }
    Py_DECREF(fspath);
    std::string path(PyBytes_AS_STRING(path_bytes));
    Py_DECREF(path_bytes);

    /* Copy the (possibly modified) markers back into the backend, preserving
       their exact length (binary-safe). */
    Py_ssize_t n_markers = PyList_Size(self->markers);
    if (n_markers > 0) {
        self->obj->markers.clear();
        for (Py_ssize_t i = 0; i < n_markers; i++) {
            PyObject *item = PyList_GetItem(self->markers, i);   /* borrowed */
            char *buf;
            Py_ssize_t len;
            if (PyBytes_AsStringAndSize(item, &buf, &len) < 0)
                return NULL;
            self->obj->markers.push_back(std::string(buf, (size_t)len));
        }
    }

    try {
        self->obj->jpeg_write(path, self->obj->optimize_coding);
    } catch (const std::exception &e) {
        PyErr_SetString(PyExc_RuntimeError, e.what());
        return NULL;
    } catch (...) {
        PyErr_SetString(PyExc_RuntimeError, "[JSTRUCT] unknown error while writing JPEG");
        return NULL;
    }
    Py_RETURN_NONE;
}


/* --------------------------------------------------------------- accessors */

static PyObject *
DecompressedJpeg_get_coef_block(DecompressedJpegObject *self, PyObject *args)
{
    int c, i, j;
    if (!PyArg_ParseTuple(args, "iii", &c, &i, &j))
        return NULL;
    if (PyList_Size(self->coef_arrays) == 0) {
        PyErr_SetString(PyExc_AttributeError, "coef_arrays has not been created yet.");
        return NULL;
    }
    PyObject *arr = PyList_GetItem(self->coef_arrays, c);  /* borrowed */
    if (arr == NULL)
        return NULL;
    PyObject *sr = PySlice_New(PyLong_FromLong((long)i * DCTSIZE),
                               PyLong_FromLong((long)(i + 1) * DCTSIZE), NULL);
    PyObject *sc = PySlice_New(PyLong_FromLong((long)j * DCTSIZE),
                               PyLong_FromLong((long)(j + 1) * DCTSIZE), NULL);
    if (sr == NULL || sc == NULL) { Py_XDECREF(sr); Py_XDECREF(sc); return NULL; }
    PyObject *key = PyTuple_Pack(2, sr, sc);
    Py_DECREF(sr);
    Py_DECREF(sc);
    if (key == NULL)
        return NULL;
    PyObject *result = PyObject_GetItem(arr, key);
    Py_DECREF(key);
    return result;
}

static PyObject *
DecompressedJpeg_get_coef_block_array_shape(DecompressedJpegObject *self, PyObject *args)
{
    int c;
    if (!PyArg_ParseTuple(args, "i", &c))
        return NULL;
    if (self->obj == NULL || self->obj->coef_arrays.empty()) {
        PyErr_SetString(PyExc_AttributeError, "coef_arrays has not been created yet.");
        return NULL;
    }
    if (c < 0 || (size_t)c >= self->obj->coef_arrays.size()) {
        PyErr_SetString(PyExc_IndexError, "coef array index out of range");
        return NULL;
    }
    mat2D<int> *m = self->obj->coef_arrays[c];
    return Py_BuildValue("(ii)", m->rows / DCTSIZE, m->cols / DCTSIZE);
}

static PyObject *
DecompressedJpeg_are_channel_sizes_same(DecompressedJpegObject *self, PyObject *Py_UNUSED(ignored))
{
    if (self->obj == NULL)
        Py_RETURN_TRUE;
    unsigned int h0 = 0, w0 = 0;
    bool first = true, same = true;
    for (size_t i = 0; i < self->obj->comp_info.size(); i++) {
        struct_comp_info *ci = self->obj->comp_info[i];
        if (first) {
            h0 = ci->downsampled_height;
            w0 = ci->downsampled_width;
            first = false;
        } else if (ci->downsampled_height != h0 || ci->downsampled_width != w0) {
            same = false;
            break;
        }
    }
    if (same)
        Py_RETURN_TRUE;
    Py_RETURN_FALSE;
}

static PyObject *
DecompressedJpeg_count_nnz_ac(DecompressedJpegObject *self, PyObject *Py_UNUSED(ignored))
{
    if (self->obj == NULL)
        return PyLong_FromLong(0);
    long total = 0;
    for (size_t k = 0; k < self->obj->coef_arrays.size(); k++) {
        mat2D<int> *m = self->obj->coef_arrays[k];
        int *buf = m->GetBuffer();
        int rows = m->rows, cols = m->cols;
        long nnz_all = 0, nnz_dc = 0;
        for (int r = 0; r < rows; r++)
            for (int col = 0; col < cols; col++)
                if (buf[r * cols + col] != 0) nnz_all++;
        for (int r = 0; r < rows; r += DCTSIZE)
            for (int col = 0; col < cols; col += DCTSIZE)
                if (buf[r * cols + col] != 0) nnz_dc++;
        total += nnz_all - nnz_dc;
    }
    return PyLong_FromLong(total);
}


/* ------------------------------------------------------------- properties */

#define UINT_GETTER(name, field) \
static PyObject *DecompressedJpeg_get_##name(DecompressedJpegObject *self, void *closure) { \
    if (self->obj == NULL) { PyErr_SetString(PyExc_AttributeError, "no JPEG loaded"); return NULL; } \
    return PyLong_FromUnsignedLong((unsigned long)self->obj->field); }

#define INT_GETTER(name, field) \
static PyObject *DecompressedJpeg_get_##name(DecompressedJpegObject *self, void *closure) { \
    if (self->obj == NULL) { PyErr_SetString(PyExc_AttributeError, "no JPEG loaded"); return NULL; } \
    return PyLong_FromLong((long)self->obj->field); }

UINT_GETTER(image_width, image_width)
UINT_GETTER(image_height, image_height)
INT_GETTER(image_components, image_components)
UINT_GETTER(image_color_space, image_color_space)
INT_GETTER(num_components, num_components)
UINT_GETTER(jpeg_color_space, jpeg_color_space)
INT_GETTER(optimize_coding, optimize_coding)
INT_GETTER(progressive_mode, progressive_mode)

static PyGetSetDef DecompressedJpeg_getset[] = {
    {(char *)"image_width", (getter)DecompressedJpeg_get_image_width, NULL, NULL, NULL},
    {(char *)"image_height", (getter)DecompressedJpeg_get_image_height, NULL, NULL, NULL},
    {(char *)"image_components", (getter)DecompressedJpeg_get_image_components, NULL, NULL, NULL},
    {(char *)"image_color_space", (getter)DecompressedJpeg_get_image_color_space, NULL, NULL, NULL},
    {(char *)"num_components", (getter)DecompressedJpeg_get_num_components, NULL, NULL, NULL},
    {(char *)"jpeg_color_space", (getter)DecompressedJpeg_get_jpeg_color_space, NULL, NULL, NULL},
    {(char *)"optimize_coding", (getter)DecompressedJpeg_get_optimize_coding, NULL, NULL, NULL},
    {(char *)"progressive_mode", (getter)DecompressedJpeg_get_progressive_mode, NULL, NULL, NULL},
    {NULL}
};

static PyMemberDef DecompressedJpeg_members[] = {
    {(char *)"comp_info", T_OBJECT_EX, offsetof(DecompressedJpegObject, comp_info), 0, NULL},
    {(char *)"quant_tables", T_OBJECT_EX, offsetof(DecompressedJpegObject, quant_tables), 0, NULL},
    {(char *)"coef_arrays", T_OBJECT_EX, offsetof(DecompressedJpegObject, coef_arrays), 0, NULL},
    {(char *)"spatial_arrays", T_OBJECT_EX, offsetof(DecompressedJpegObject, spatial_arrays), 0, NULL},
    {(char *)"ac_huff_tables", T_OBJECT_EX, offsetof(DecompressedJpegObject, ac_huff_tables), 0, NULL},
    {(char *)"dc_huff_tables", T_OBJECT_EX, offsetof(DecompressedJpegObject, dc_huff_tables), 0, NULL},
    {(char *)"markers", T_OBJECT_EX, offsetof(DecompressedJpegObject, markers), 0, NULL},
    {NULL}
};

static PyMethodDef DecompressedJpeg_methods[] = {
    {"read", (PyCFunction)DecompressedJpeg_read, METH_VARARGS | METH_KEYWORDS, "Read a JPEG file."},
    {"write", (PyCFunction)DecompressedJpeg_write, METH_VARARGS, "Write the JPEG to a file."},
    {"get_coef_block", (PyCFunction)DecompressedJpeg_get_coef_block, METH_VARARGS, "Get an 8x8 DCT block."},
    {"get_coef_block_array_shape", (PyCFunction)DecompressedJpeg_get_coef_block_array_shape, METH_VARARGS, "Block-array shape of a channel."},
    {"are_channel_sizes_same", (PyCFunction)DecompressedJpeg_are_channel_sizes_same, METH_NOARGS, "Whether all channels have the same size."},
    {"count_nnz_ac", (PyCFunction)DecompressedJpeg_count_nnz_ac, METH_NOARGS, "Number of non-zero AC coefficients."},
    {NULL}
};

/* Head-only; slots are assigned in the module init (portable, no positional
   slot counting). */
static PyTypeObject DecompressedJpegType = {
    PyVarObject_HEAD_INIT(NULL, 0)
};

static PyModuleDef decompressedjpeg_module = {
    PyModuleDef_HEAD_INIT,
    "decompressedjpeg",
    "Hand-written C-API implementation of jpegio.decompressedjpeg.",
    -1,
    NULL, NULL, NULL, NULL, NULL
};

PyMODINIT_FUNC
PyInit_decompressedjpeg(void)
{
    import_array();

    DecompressedJpegType.tp_name = "jpegio.decompressedjpeg.DecompressedJpeg";
    DecompressedJpegType.tp_basicsize = sizeof(DecompressedJpegObject);
    DecompressedJpegType.tp_dealloc = (destructor)DecompressedJpeg_dealloc;
    DecompressedJpegType.tp_flags =
        Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE | Py_TPFLAGS_HAVE_GC;
    DecompressedJpegType.tp_doc = "Decompressed JPEG (DCT-domain) representation.";
    DecompressedJpegType.tp_traverse = (traverseproc)DecompressedJpeg_traverse;
    DecompressedJpegType.tp_clear = (inquiry)DecompressedJpeg_clear;
    DecompressedJpegType.tp_methods = DecompressedJpeg_methods;
    DecompressedJpegType.tp_members = DecompressedJpeg_members;
    DecompressedJpegType.tp_getset = DecompressedJpeg_getset;
    DecompressedJpegType.tp_new = DecompressedJpeg_new;

    if (PyType_Ready(&DecompressedJpegType) < 0)
        return NULL;
    PyObject *m = PyModule_Create(&decompressedjpeg_module);
    if (m == NULL)
        return NULL;
    Py_INCREF(&DecompressedJpegType);
    if (PyModule_AddObject(m, "DecompressedJpeg", (PyObject *)&DecompressedJpegType) < 0) {
        Py_DECREF(&DecompressedJpegType);
        Py_DECREF(m);
        return NULL;
    }
    return m;
}
