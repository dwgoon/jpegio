
from libc.stdio cimport FILE
cimport numpy as np

from read cimport *
from .decompressedjpeg cimport DecompressedJpeg


cdef class ZigzagDct1d(DecompressedJpeg):
    cdef public size_t icut
    
    
    cpdef count_nnz_ac(self)
    cpdef get_coef_block_array_shape(self, c)
    cpdef get_coef_block(self, c, i, j)
    cdef _get_dct_coefficients(self)
