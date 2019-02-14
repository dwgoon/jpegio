# cython: language_level=3

# _cython: boundscheck=False, wraparound=False

from libc.stdio cimport printf
from libc.stdio cimport FILE, fopen, fclose
from libc.stdlib cimport malloc, free

import numpy as np
cimport numpy as np

cimport clibjpeg
from clibjpeg cimport *


cdef class DecompressedJpeg:

    def __cinit__(self):
        self._cinfo = <j_decompress_ptr> malloc(sizeof(jpeg_decompress_struct))
        self._jerr = <my_error_ptr> malloc(sizeof(my_error_mgr))
        
        if self._cinfo is NULL:
            raise MemoryError("jpeg_decompress_struct")
            
        if self._jerr is NULL:
            raise MemoryError("my_error_mgr")
        
        self._infile = NULL
        

    def __dealloc__(self):
        if self._cinfo != NULL:
            _finalize(self._cinfo)
        
        #if self._cinfo:
        #    free(self._cinfo)
        
        if self._jerr:
            free(self._jerr)
            
        if self._infile:
            fclose(self._infile)
            
    cpdef read(self, fname):
        cdef bytes py_bytes = fname.encode()
        cdef char* fname_cstr = py_bytes
        cdef int res
        
        self._infile = fopen(fname_cstr, "rb")
        if self._infile == NULL:
            printf("Can't open the given JPEG file.\n")
            return
        
        self._infile = fopen(fname_cstr, "rb")
        
        res = _read_jpeg_decompress_struct(self._infile,
                                           self._cinfo,
                                           self._jerr)
        if res < 0:
            raise IOError("An error has occurs in reading the file.")
        
        self._get_quant_tables()
        self._get_dct_coefficients()
        
        fclose(self._infile)
        self._infile = NULL
        
    cdef _get_quant_tables(self):
        """Get the quantization tables.
        """
        cdef int num_tables = _get_num_quant_tables(self._cinfo)
        cdef np.ndarray arr = np.zeros((num_tables*DCTSIZE2),
                                       dtype=np.uint16)
        cdef UINT16[::1] arr_memview = arr
                
        _read_quant_tables(&arr_memview[0], self._cinfo)
        self.quant_tables = arr.reshape(num_tables, DCTSIZE, DCTSIZE)
    
    
    
    cdef _get_dct_coefficients(self):
        """Get the DCT coefficients.
        """        
        self.coef_arrays = list()
        cdef int nch = self._cinfo.num_components
        cdef DctBlockArraySize blkarr_size
        cdef list list_blkarr_sizes = list()
        cdef int num_total_coef = 0
        cdef np.ndarray arr
        cdef JCOEF[:, ::1] arr_mv  # Memory view
        cdef jvirt_barray_ptr* coef_arrays      
                
        cdef Py_ssize_t idx_beg = 0
        cdef Py_ssize_t idx_end = 0
        cdef JDIMENSION nrows, ncols
        cdef np.ndarray block_array
        cdef np.ndarray subarr

                
        # Create and populate the DCT coefficient arrays
        coef_arrays = jpeg_read_coefficients(self._cinfo)
        if coef_arrays == NULL:
            printf("[LIBJPEG ERROR] Failed to read coefficients.\n")
            return
        
        for i in range(nch):
            _get_size_dct_block(&blkarr_size, self._cinfo, i)
            arr = np.zeros((blkarr_size.nrows*DCTSIZE,
                            blkarr_size.ncols*DCTSIZE), dtype=np.int16)
            arr_mv = arr
            _read_coef_array(<JCOEF*> &arr_mv[0, 0],
                             self._cinfo,
                             coef_arrays[i],
                             blkarr_size)
            
            self.coef_arrays.append(arr)
        # end of for

        
    cdef _finalize(self):
        _finalize(self._cinfo)
        
    @property
    def image_width(self):
        return self._cinfo.image_width
    @property
    def image_height(self):
        return self._cinfo.image_height    
    @property
    def out_color_space(self):
        return self._cinfo.out_color_space    
    @property
    def out_color_components(self):
        return self._cinfo.out_color_components    
    @property
    def jpeg_color_space(self):
        return self._cinfo.jpeg_color_space
    @property
    def num_components(self):
        return self._cinfo.num_components
    @property
    def progressive_mode(self):
        return self._cinfo.progressive_mode