import os
import numpy as np
cimport numpy as cnp
from numpy import count_nonzero as cnt_nnz

from cython.operator cimport dereference as deref, preincrement as inc
from cython cimport view

from jpegio.clibjpeg cimport DCTSIZE, DCTSIZE2
from jpegio.jstruct cimport jstruct
from jpegio.jstruct cimport ptr_mat2D
from jpegio.jstruct cimport struct_comp_info
from jpegio.componentinfo cimport ComponentInfo

cdef class DecompressedJpeg:
    #cdef jstruct* _jstruct_obj

    def __cinit__(self):
        self._jstruct_obj = NULL  # new jstruct()

    def __dealloc__(self):
        if self._jstruct_obj != NULL:
            del self._jstruct_obj

    cdef _is_valid_fpath(self, fpath):
        if not os.path.isfile(fpath):
            print("[JPEGIO] Wrong file path: %s" % (fpath))
            return False

        return True

    cpdef read(self, fpath):
        if not self._is_valid_fpath(fpath):
            return

        if self._jstruct_obj != NULL:
            del self._jstruct_obj

        self._jstruct_obj = new jstruct()

        #cdef bytes py_bytes = fpath.encode()
        #cdef char* fpath_cstr = py_bytes
        self._jstruct_obj.jpeg_load(fpath.encode())

        #cdef int [:] carr_view =

        #cdef int[:, ::1] arr = self._jstruct_obj.coef_arrays[0][0].GetBuffer()

        cdef ptr_mat2D ptr_mat2D_obj = &self._jstruct_obj.coef_arrays[0][0]

        # <cnp.int_t[:]>
        #
        cdef view.array my_array = view.array(shape=(ptr_mat2D_obj.rows, ptr_mat2D_obj.cols),
                                              itemsize=sizeof(int),
                                              format="i",
                                              mode="c",
                                              allocate_buffer=False)
        my_array.data = <char *> ptr_mat2D_obj.GetBuffer()
        self.numpy_array = np.asarray(my_array)

        self._get_comp_info()
        self._get_quant_tables()
        self._get_dct_coefficients()

        # cdef public cnp.ndarray quant_tables

    cdef _get_comp_info(self):
        self.comp_info = list()

        cdef int i
        cdef int nch = self._jstruct_obj.num_components
        cdef ComponentInfo comp_info
        cdef struct_comp_info*ptr_ci

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

    cdef _get_quant_tables(self):
        """Get the quantization tables.
        """
        self.quant_tables = list()
        cdef int num_quant_tables = self._jstruct_obj.quant_tables.size()

        cdef ptr_mat2D ptr_mat2D_obj
        cdef view.array cy_arr
        cdef Py_ssize_t i
        for i in range(num_quant_tables):
            ptr_mat2D_obj = &self._jstruct_obj.quant_tables[i][0]
            shape = (ptr_mat2D_obj.rows, ptr_mat2D_obj.cols)
            cy_arr = view.array(shape=shape,
                                itemsize=sizeof(int),
                                format="i",
                                mode="c",
                                allocate_buffer=False)
            cy_arr.data = <char *> ptr_mat2D_obj.GetBuffer()
            self.quant_tables.append(np.asarray(cy_arr))

    cdef _get_dct_coefficients(self):
        """Get the DCT coefficients.
        """
        self.coef_arrays = list()
        cdef ptr_mat2D ptr_mat2D_obj
        cdef view.array cy_arr
        cdef Py_ssize_t i
        for i in range(self._jstruct_obj.coef_arrays.size()):
            ptr_mat2D_obj = &self._jstruct_obj.coef_arrays[i][0]
            shape = (ptr_mat2D_obj.rows, ptr_mat2D_obj.cols)
            cy_arr = view.array(shape=shape,
                                itemsize=sizeof(int),
                                format="i",
                                mode="c",
                                allocate_buffer=False)
            cy_arr.data = <char *> ptr_mat2D_obj.GetBuffer()
            self.coef_arrays.append(np.asarray(cy_arr))

    cpdef write(self, fpath):
        self._jstruct_obj.jpeg_write(fpath.encode(), self.optimize_coding)

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
        cdef ComponentInfo ci
        cdef set set_nrows = set()
        cdef set set_ncols = set()

        for ci in self.comp_info:
            if len(set_nrows) == 1 and ci.downsampled_height not in set_nrows:
                return False
            set_nrows.add(ci.downsampled_height)

            if len(set_ncols) == 1 and ci.downsampled_width not in set_ncols:
                return False
            set_ncols.add(ci.downsampled_width)

        return True

    cpdef count_nnz_ac(self):
        num_nnz_ac = 0
        for i in range(self.num_components):
            coef = self.coef_arrays[i]
            num_nnz_ac += (cnt_nnz(coef) - cnt_nnz(coef[0::8, 0::8]))
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
