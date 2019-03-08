
from libc.stdio cimport FILE
cimport numpy as np

from read cimport *
from .decompressedjpeg cimport DecompressedJpeg


cdef class ZigzagDct1d(DecompressedJpeg):
    cdef public size_t icut
    
    cdef _get_dct_coefficients(self)
