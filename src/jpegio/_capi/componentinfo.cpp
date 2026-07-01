/* Hand-written CPython C-API implementation of jpegio.componentinfo.
 *
 * This is the "from scratch" (no Cython) binding. It defines the
 * ComponentInfo value type, a plain container mirroring the fields of
 * libjpeg's jpeg_component_info that jpegio exposes.
 */
#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <structmember.h>

typedef struct {
    PyObject_HEAD
    int component_id;
    int h_samp_factor;
    int v_samp_factor;
    int quant_tbl_no;
    int ac_tbl_no;
    int dc_tbl_no;
    unsigned int downsampled_height;
    unsigned int downsampled_width;
    unsigned int height_in_blocks;
    unsigned int width_in_blocks;
} ComponentInfoObject;

static PyObject *
ComponentInfo_new(PyTypeObject *type, PyObject *args, PyObject *kwds)
{
    ComponentInfoObject *self = (ComponentInfoObject *)type->tp_alloc(type, 0);
    if (self != NULL) {
        /* tp_alloc zero-initialises the struct; only component_id differs. */
        self->component_id = -1;
    }
    return (PyObject *)self;
}

static PyMemberDef ComponentInfo_members[] = {
    {(char *)"component_id",       T_INT,  offsetof(ComponentInfoObject, component_id),       0, (char *)"component id"},
    {(char *)"h_samp_factor",      T_INT,  offsetof(ComponentInfoObject, h_samp_factor),      0, (char *)"horizontal sampling factor"},
    {(char *)"v_samp_factor",      T_INT,  offsetof(ComponentInfoObject, v_samp_factor),      0, (char *)"vertical sampling factor"},
    {(char *)"quant_tbl_no",       T_INT,  offsetof(ComponentInfoObject, quant_tbl_no),       0, (char *)"quantization table index"},
    {(char *)"ac_tbl_no",          T_INT,  offsetof(ComponentInfoObject, ac_tbl_no),          0, (char *)"AC Huffman table index"},
    {(char *)"dc_tbl_no",          T_INT,  offsetof(ComponentInfoObject, dc_tbl_no),          0, (char *)"DC Huffman table index"},
    {(char *)"downsampled_height", T_UINT, offsetof(ComponentInfoObject, downsampled_height), 0, (char *)"downsampled height in pixels"},
    {(char *)"downsampled_width",  T_UINT, offsetof(ComponentInfoObject, downsampled_width),  0, (char *)"downsampled width in pixels"},
    {(char *)"height_in_blocks",   T_UINT, offsetof(ComponentInfoObject, height_in_blocks),   0, (char *)"height in DCT blocks"},
    {(char *)"width_in_blocks",    T_UINT, offsetof(ComponentInfoObject, width_in_blocks),    0, (char *)"width in DCT blocks"},
    {NULL}
};

/* Zero-initialise the head and set the slots in the module init, which is
   portable across compilers (no positional-slot counting, no designated
   initializers). */
static PyTypeObject ComponentInfoType = {
    PyVarObject_HEAD_INIT(NULL, 0)
};

static PyModuleDef componentinfo_module = {
    PyModuleDef_HEAD_INIT,
    "componentinfo",
    "Hand-written C-API implementation of jpegio.componentinfo.",
    -1,
    NULL, NULL, NULL, NULL, NULL
};

PyMODINIT_FUNC
PyInit_componentinfo(void)
{
    ComponentInfoType.tp_name = "jpegio.componentinfo.ComponentInfo";
    ComponentInfoType.tp_basicsize = sizeof(ComponentInfoObject);
    ComponentInfoType.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    ComponentInfoType.tp_doc = "Per-component information of a JPEG image.";
    ComponentInfoType.tp_new = ComponentInfo_new;
    ComponentInfoType.tp_members = ComponentInfo_members;

    if (PyType_Ready(&ComponentInfoType) < 0)
        return NULL;

    PyObject *m = PyModule_Create(&componentinfo_module);
    if (m == NULL)
        return NULL;

    Py_INCREF(&ComponentInfoType);
    if (PyModule_AddObject(m, "ComponentInfo", (PyObject *)&ComponentInfoType) < 0) {
        Py_DECREF(&ComponentInfoType);
        Py_DECREF(m);
        return NULL;
    }
    return m;
}
