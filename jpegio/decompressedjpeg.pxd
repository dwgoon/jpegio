
from libc.stdio cimport FILE
cimport numpy as np
from clibjpeg cimport *

cdef extern from "dctblockarraysize.h":
    cdef struct DctBlockArraySize:
        JDIMENSION nrows
        JDIMENSION ncols

cdef class DecompressedJpeg:
    cdef FILE* _infile
    cdef jpeg_decompress_struct _cinfo
    cdef public np.ndarray quant_tables
    cdef public list coef_arrays

    cpdef read(self, fname)
    cdef _get_quant_tables(self)
    cdef _get_dct_coefficients(self)
    cdef _arrange_blocks(self,
                         np.ndarray subarr,
                         DctBlockArraySize blkarr_size)