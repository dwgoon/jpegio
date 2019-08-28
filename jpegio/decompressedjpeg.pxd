

cimport numpy as cnp

from jstruct cimport jstruct
#from read cimport *

cdef class DecompressedJpeg:

    cdef public list comp_info
    cdef public cnp.ndarray quant_tables
    cdef public list coef_arrays

    cdef public cnp.ndarray numpy_array

    cdef jstruct* _jstruct_obj

    #cdef _get_comp_info(self)
    #cdef _get_quant_tables(self)
    cdef _get_dct_coefficients(self)

    cpdef read(self, fpath)
    cpdef write(self, fpath)
    cpdef get_coef_block(self, c, i, j)
    cpdef get_coef_block_array_shape(self, c)
    cpdef are_channel_sizes_same(self)
    cpdef count_nnz_ac(self)


    cdef _is_valid_fpath(self, fpath)

