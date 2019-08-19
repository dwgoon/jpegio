# -*- coding: utf-8 -*-

from libc.stdio cimport FILE
from clibjpeg cimport *


cdef extern from "dctblockarraysize.h":
    cdef struct DctBlockArraySize:
        JDIMENSION nrows
        JDIMENSION ncols
                
cdef extern from "read.h":
    cdef struct jpegio_error_mgr:
        pass    

    ctypedef jpegio_error_mgr* jpegio_error_ptr

    unsigned char* _read_jpeg_decompress_struct(FILE* infile,
                                                j_decompress_ptr cinfo,
                                                jpegio_error_ptr jerr)

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
                    
    void _read_coef_array_zigzag_dct_1d(JCOEF* arr,
                                    j_decompress_ptr cinfo,
                                    jvirt_barray_ptr coef_array,
                                    DctBlockArraySize blkarr_size)
    
    void _dealloc_jpeg_decompress(j_decompress_ptr cinfo)
    void _dealloc_memory_buffer(unsigned char* mem_buffer)