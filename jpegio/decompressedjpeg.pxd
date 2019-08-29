cimport numpy as cnp
from jstruct cimport jstruct

cdef class DecompressedJpeg:

    cdef public list comp_info
    cdef public list quant_tables
    cdef public list coef_arrays

    cdef public cnp.ndarray numpy_array

    cdef jstruct* _jstruct_obj

    cdef _get_comp_info(self)
    cdef _get_quant_tables(self)
    cdef _get_dct_coefficients(self)

    cpdef public read(self, fpath)
    cpdef public write(self, fpath)
    cpdef get_coef_block(self, c, i, j)
    cpdef get_coef_block_array_shape(self, c)
    cpdef are_channel_sizes_same(self)
    cpdef count_nnz_ac(self)


    cdef _is_valid_fpath(self, fpath)

