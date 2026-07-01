import os
import numpy as np
cimport numpy as cnp
from numpy import count_nonzero as cnt_nnz

import cython
from cython.operator cimport dereference as deref, preincrement as inc
from cython cimport view

from jpegio.clibjpeg cimport DCTSIZE, DCTSIZE2
from jpegio.jstruct cimport jstruct
from jpegio.jstruct cimport ptr_mat2D
from jpegio.jstruct cimport ptr_struct_ci
from jpegio.jstruct cimport ptr_struct_ht
from jpegio.componentinfo cimport ComponentInfo

from libc.stdio cimport printf
from libcpp.string cimport string
from cpython.ref cimport Py_INCREF

cnp.import_array()


cdef cnp.ndarray _own_mat2d(object owner, ptr_mat2D m):
    """Wrap a mat2D<int> buffer as a writable 2-D int32 view that keeps `owner`
    (hence the backing jstruct) alive for the array's lifetime."""
    cdef cnp.npy_intp[2] dims
    dims[0] = m.rows
    dims[1] = m.cols
    cdef cnp.ndarray arr = cnp.PyArray_SimpleNewFromData(
        2, dims, cnp.NPY_INT, <void *> m.GetBuffer())
    Py_INCREF(owner)
    cnp.PyArray_SetBaseObject(arr, owner)
    return arr


cdef cnp.ndarray _own_ivec(object owner, int* data, Py_ssize_t n):
    """Wrap an int buffer of length n as a 1-D int32 view owned by `owner`."""
    cdef cnp.npy_intp dim = n
    cdef cnp.ndarray arr = cnp.PyArray_SimpleNewFromData(
        1, &dim, cnp.NPY_INT, <void *> data if n > 0 else NULL)
    Py_INCREF(owner)
    cnp.PyArray_SetBaseObject(arr, owner)
    return arr


cdef class DecompressedJpeg:
    
    def __cinit__(self):
        self._jstruct_obj = NULL  # new jstruct()

    def __dealloc__(self):
        if self._jstruct_obj != NULL:
            del self._jstruct_obj
    
    cdef _is_valid_fpath(self, fpath):
        if not os.path.isfile(fpath):
            raise FileNotFoundError("[JPEGIO] No such file: %s" % (fpath,))
        if os.path.getsize(fpath) == 0:
            raise ValueError("[JPEGIO] Empty file: %s" % (fpath,))
        return True

    cpdef read(self, fpath, bint read_spatial=False):
        fpath = os.fspath(fpath)
        self._is_valid_fpath(fpath)

        if self._jstruct_obj != NULL:
            del self._jstruct_obj
            self._jstruct_obj = NULL

        self._jstruct_obj = new jstruct()
        self._jstruct_obj.jpeg_load(fpath.encode())

        self._read_comp_info()
        self._read_markers()
        self._read_quant_tables()
        self._read_huffman_tables()
        self._read_dct_coefficients()

        # Spatial (pixel-domain) decoding is optional: it fully decompresses
        # the image, which is wasted work when only the DCT-domain data is
        # needed. It is loaded and exposed via ``spatial_arrays`` on request.
        self.spatial_arrays = list()
        if read_spatial:
            self._jstruct_obj.spatial_load(fpath.encode())
            self._jstruct_obj.load_spatial = True
            self._read_spatial_arrays()


    cdef _read_comp_info(self):
        self.comp_info = list()

        cdef int i
        cdef int nch = self._jstruct_obj.num_components
        cdef ComponentInfo comp_info
        cdef ptr_struct_ci ptr_ci

        for i in range(nch):
            comp_info = ComponentInfo()
            ptr_ci = self._jstruct_obj.comp_info[i]

            comp_info.component_id = ptr_ci.component_id
            comp_info.h_samp_factor = ptr_ci.h_samp_factor
            comp_info.v_samp_factor = ptr_ci.v_samp_factor

            comp_info.quant_tbl_no = ptr_ci.quant_tbl_no
            comp_info.ac_tbl_no = ptr_ci.ac_tbl_no
            comp_info.dc_tbl_no = ptr_ci.dc_tbl_no

            comp_info.downsampled_height = ptr_ci.downsampled_height
            comp_info.downsampled_width = ptr_ci.downsampled_width

            comp_info.height_in_blocks = ptr_ci.height_in_blocks
            comp_info.width_in_blocks = ptr_ci.width_in_blocks

            self.comp_info.append(comp_info)
        # end of for

    cdef _read_markers(self):
        """Connect the buffer of markers to numpy.ndarray.
        """
        self.markers = list()
        cdef Py_ssize_t n_markers = self._jstruct_obj.markers.size()
        cdef Py_ssize_t i
        cdef bytes py_bytes
        for i in range(n_markers):
            # std::string -> bytes preserves the length (binary-safe)
            py_bytes = self._jstruct_obj.markers[i]
            self.markers.append(py_bytes)

    cdef _read_quant_tables(self):
        """Connect the buffer of quantization tables to numpy.ndarray.
        """

        self.quant_tables = list()
        cdef ptr_mat2D ptr_mat2D_obj
        cdef Py_ssize_t i
        for i in range(self._jstruct_obj.quant_tables.size()):
            ptr_mat2D_obj = self._jstruct_obj.quant_tables[i]
            self.quant_tables.append(_own_mat2d(self, ptr_mat2D_obj))

    cdef _read_huffman_tables(self):
        """Connect the buffer of Huffman tables to numpy.ndarray.
        """

        self.ac_huff_tables = list()
        self.dc_huff_tables = list()

        cdef Py_ssize_t i
        cdef ptr_struct_ht ptr_ht

        for i in range(self._jstruct_obj.ac_huff_tables.size()):
            ptr_ht = self._jstruct_obj.ac_huff_tables[i]
            self.ac_huff_tables.append(
                {"counts": _own_ivec(self, &ptr_ht.counts[0], ptr_ht.counts.size()),
                 "symbols": _own_ivec(self, &ptr_ht.symbols[0], ptr_ht.symbols.size())})

        for i in range(self._jstruct_obj.dc_huff_tables.size()):
            ptr_ht = self._jstruct_obj.dc_huff_tables[i]
            self.dc_huff_tables.append(
                {"counts": _own_ivec(self, &ptr_ht.counts[0], ptr_ht.counts.size()),
                 "symbols": _own_ivec(self, &ptr_ht.symbols[0], ptr_ht.symbols.size())})

    cdef _read_dct_coefficients(self):
        """Connect the buffer of DCT coefficients to numpy.ndarray.
        """
        self.coef_arrays = list()
        cdef ptr_mat2D ptr_mat2D_obj
        cdef Py_ssize_t i
        for i in range(self._jstruct_obj.coef_arrays.size()):
            ptr_mat2D_obj = self._jstruct_obj.coef_arrays[i]
            self.coef_arrays.append(_own_mat2d(self, ptr_mat2D_obj))

    cdef _read_spatial_arrays(self):
        """Connect the buffer of spatial (pixel-domain) arrays to numpy.ndarray.
        """
        self.spatial_arrays = list()
        cdef ptr_mat2D ptr_mat2D_obj
        cdef Py_ssize_t i
        for i in range(self._jstruct_obj.spatial_arrays.size()):
            ptr_mat2D_obj = self._jstruct_obj.spatial_arrays[i]
            self.spatial_arrays.append(_own_mat2d(self, ptr_mat2D_obj))


    cpdef write(self, fpath):
        self._write_markers()
        self._jstruct_obj.jpeg_write(fpath.encode(), self.optimize_coding)

    cdef _write_markers(self):
        cdef Py_ssize_t n_markers = len(self.markers)
        cdef Py_ssize_t i
        cdef bytes py_bytes
        if n_markers > 0:
            self._jstruct_obj.markers.clear()
            for i in range(n_markers):
                # bytes -> std::string preserves the length (binary-safe)
                py_bytes = bytes(self.markers[i])
                self._jstruct_obj.markers.push_back(<string> py_bytes)

    cpdef get_coef_block(self, c, i, j):
        if not self.coef_arrays:
            raise AttributeError("coef_arrays has not been created yet.")

        cdef slice sr = slice(i * DCTSIZE, (i + 1) * DCTSIZE, 1)
        cdef slice sc = slice(j * DCTSIZE, (j + 1) * DCTSIZE, 1)
        return self.coef_arrays[c][sr, sc]

    cpdef get_coef_block_array_shape(self, c):
        if not self.coef_arrays:
            raise AttributeError("coef_arrays has not been created yet.")

        return (int(self.coef_arrays[c].shape[0] / DCTSIZE),
                int(self.coef_arrays[c].shape[1] / DCTSIZE))

    cpdef are_channel_sizes_same(self):
        heights = {ci.downsampled_height for ci in self.comp_info}
        widths = {ci.downsampled_width for ci in self.comp_info}
        return len(heights) <= 1 and len(widths) <= 1

    cpdef count_nnz_ac(self):
        num_nnz_ac = 0
        for i in range(self.num_components):
            coef = self.coef_arrays[i]
            num_nnz_ac += (cnt_nnz(coef) - cnt_nnz(coef[0::DCTSIZE, 0::DCTSIZE]))
        return num_nnz_ac

    @property
    def image_width(self):
        return self._jstruct_obj.image_width

    @property
    def image_height(self):
        return self._jstruct_obj.image_height

    @property
    def image_components(self):
        return self._jstruct_obj.image_components

    @property
    def image_color_space(self):
        return self._jstruct_obj.image_color_space

    @property
    def num_components(self):
        return self._jstruct_obj.num_components

    @property
    def jpeg_color_space(self):
        return self._jstruct_obj.jpeg_color_space

    @property
    def optimize_coding(self):
        return self._jstruct_obj.optimize_coding

    @property
    def progressive_mode(self):
        return self._jstruct_obj.progressive_mode
