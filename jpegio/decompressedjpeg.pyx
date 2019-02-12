# cython: language_level=3, boundscheck=False

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
        if self._cinfo:
            free(self._cinfo)
        
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
            print("Can't open the given JPEG file.")
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
        
    cdef _get_quant_tables(self):
        """Get the quantization tables.
        """
        cdef np.ndarray arr = np.zeros((NUM_QUANT_TBLS*DCTSIZE*DCTSIZE),
                                       dtype=np.uint16)
        cdef UINT16[::1] arr_memview = arr
        
        _get_quant_tables(&arr_memview[0], self._cinfo)
        self.quant_tables = arr.reshape(NUM_QUANT_TBLS, DCTSIZE, DCTSIZE)
    
    
    
    cdef _get_dct_coefficients(self):
        """Get the DCT coefficients.
        """        
        cdef int nch = self._cinfo.num_components
        cdef DctBlockArraySize blkarr_size
        cdef list list_blkarr_sizes = list()
        cdef int num_total_coef = 0
        for i in range(nch):
            _get_size_dct_block(i, &blkarr_size, self._cinfo)
            list_blkarr_sizes.append((blkarr_size.nrows, blkarr_size.ncols))
            num_total_coef += (blkarr_size.nrows*blkarr_size.ncols*DCTSIZE2)
        # end of for
                    
        cdef np.ndarray arr = np.zeros((num_total_coef),
                                       dtype=np.int16)
        cdef JCOEF[::1] arr_memview = arr        
        _get_dct_coefficients(&arr_memview[0], self._cinfo)
        
        self.coef_arrays = list()
        cdef Py_ssize_t idx_beg = 0
        cdef Py_ssize_t idx_end = 0
        cdef JDIMENSION nrows, ncols
        cdef np.ndarray block_array
        cdef np.ndarray subarr

        for i in range(nch):
            nrows, ncols = list_blkarr_sizes[i]  
            idx_end = idx_beg + nrows*ncols*DCTSIZE2
            subarr = arr[idx_beg:idx_end]
            _get_size_dct_block(i, &blkarr_size, self._cinfo)
            block_array = self._arrange_blocks(subarr, blkarr_size)
            self.coef_arrays.append(block_array)
            idx_beg = idx_end
        # end of for
        
    cdef _arrange_blocks(self,
                         np.ndarray subarr,
                         DctBlockArraySize blkarr_size):
        
        cdef JDIMENSION i, j
        cdef JDIMENSION idx_beg, idx_end
        cdef list rows = list()
        cdef list row
        for i in range(blkarr_size.nrows):
            row = list()
            for j in range(blkarr_size.ncols):
                idx_beg = blkarr_size.ncols*DCTSIZE2*i + DCTSIZE2*j
                idx_end = idx_beg + DCTSIZE2
                blk = subarr[idx_beg:idx_end]
                blk = blk.reshape(DCTSIZE, DCTSIZE)
                row.append(blk)
            # end of for
            rows.append(row)
        # end of for
        return np.block(rows)
        
    cdef _finalize(self):
        _finalize(self._cinfo)
        