
#from libc.stdio cimport FILE
cimport numpy as np
#from clibjpeg cimport *

from read cimport *

cdef class DecompressedJpeg:
    cdef public list comp_info
    cdef public np.ndarray quant_tables
    cdef public list coef_arrays
    
    cdef unsigned char* _mem_buff
    cdef FILE* _infile
    cdef j_decompress_ptr _cinfo
    cdef my_error_ptr _jerr    
        
    cdef _get_comp_info(self)
    cdef _get_quant_tables(self)
    cdef _get_dct_coefficients(self)
    
    
    cpdef read(self, fname)
    cpdef get_coef_block(self, c, i, j)
    cpdef get_coef_block_array_shape(self, c)
    cpdef are_channel_sizes_same(self)
