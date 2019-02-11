
from libc.stdio cimport FILE
cimport numpy as np
from clibjpeg cimport * #jpeg_decompress_struct

cdef class DecompressedJpeg:
    cdef FILE* _infile
    #cdef jpeg_decompress_struct* _cinfo
    cdef jpeg_decompress_struct _cinfo
    cdef public np.ndarray quant_tables
    cdef public list dct_coefficients

    cpdef read(self, fname)
    cpdef get_quant_tables(self)
    cpdef get_dct_coefficients(self)