
from libc.stdio cimport FILE
cimport numpy as np
from clibjpeg cimport *

cdef extern from "dctblockarraysize.h":
    cdef struct DctBlockArraySize:
        JDIMENSION nrows
        JDIMENSION ncols
                
cdef extern from "read.h":
    cdef struct my_error_mgr:
        pass    

    int _read_jpeg_decompress_struct(FILE* infile,
                                     jpeg_decompress_struct* cinfo,
                                     my_error_mgr* jerr)
    
    void _get_quant_tables(UINT16 tables[],
                           jpeg_decompress_struct* obj)
               
    void _get_size_dct_block(int ci,
                             DctBlockArraySize* arr_size,
                             const jpeg_decompress_struct* cinfo)
        
    void _get_dct_coefficients(JCOEF arr[],
                               jpeg_decompress_struct* cinfo)
    

cdef class DecompressedJpeg:
    cdef FILE* _infile
    cdef jpeg_decompress_struct* _cinfo
    cdef my_error_mgr* _jerr
    cdef public np.ndarray quant_tables
    cdef public list coef_arrays

    cpdef read(self, fname)
    cdef _get_quant_tables(self)
    cdef _get_dct_coefficients(self)
    cdef _arrange_blocks(self,
                         np.ndarray subarr,
                         DctBlockArraySize blkarr_size)