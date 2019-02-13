
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

    ctypedef my_error_mgr* my_error_ptr


    int _read_jpeg_decompress_struct(FILE* infile,
                                     j_decompress_ptr cinfo,
                                     my_error_ptr jerr)

    int _get_num_quant_tables(const j_decompress_ptr cinfo)
    
    void _read_quant_tables(UINT16 tables[],
                            const j_decompress_ptr cinfo)

    void _get_size_dct_block(DctBlockArraySize* blkarr_size,
                             const j_decompress_ptr cinfo,
                             int ci)
    
    void _read_coef_array(JCOEF* arr,
                          j_decompress_ptr cinfo,
                          jvirt_barray_ptr coef_array,
                          DctBlockArraySize blkarr_size)                       

    void _finalize(j_decompress_ptr cinfo)

cdef class DecompressedJpeg:
    cdef FILE* _infile
    cdef j_decompress_ptr _cinfo
    cdef my_error_ptr _jerr
    cdef public np.ndarray quant_tables
    cdef public list coef_arrays

    cpdef read(self, fname)
    cdef _get_quant_tables(self)
    cdef _get_dct_coefficients(self)
    cdef _finalize(self)
