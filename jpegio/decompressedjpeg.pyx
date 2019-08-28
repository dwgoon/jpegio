
import os
import numpy as np
cimport numpy as cnp
from numpy import count_nonzero as cnt_nnz

from cython.operator cimport dereference as deref, preincrement as inc
from cython cimport view

from jstruct cimport jstruct, mat2D, ptr_mat2D

cdef class DecompressedJpeg:
    #cdef jstruct* _jstruct_obj

    def __cinit__(self):
        self._jstruct_obj = NULL # new jstruct()

    def __dealloc__(self):
        if self._jstruct_obj != NULL:
            del self._jstruct_obj

    cdef _is_valid_fpath(self, fpath):
        if not os.path.isfile(fpath):
            print("[JPEGIO] Wrong file path: %s"%(fpath))
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

        self._get_dct_coefficients()

        # cdef public list comp_info
        # cdef public cnp.ndarray quant_tables

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
        pass

    cpdef get_coef_block_array_shape(self, c):
        pass

    cpdef are_channel_sizes_same(self):
        pass

    cpdef count_nnz_ac(self):
        pass

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
    def jpeg_components(self):
        return self._jstruct_obj.jpeg_components

    @property
    def jpeg_color_space(self):
        return self._jstruct_obj.jpeg_color_space

    @property
    def optimize_coding(self):
        return self._jstruct_obj.optimize_coding

    @property
    def progressive_mode(self):
        return self._jstruct_obj.progressive_mode