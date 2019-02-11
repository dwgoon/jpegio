# cython: language_level=3, boundscheck=False

from libc.stdio cimport FILE, fopen, fclose
from libc.stdlib cimport malloc, free


import numpy as np
cimport numpy as np

#cimport clibjpeg
#from clibjpeg cimport *
#from clibjpeg cimport jpeg_decompress_struct
#from clibjpeg cimport JQUANT_TBL
#from clibjpeg cimport NUM_QUANT_TBLS
#from clibjpeg cimport UINT16
#from clibjpeg cimport read_jpeg_decompress_struct

cdef extern from "dctarraysize.h":
    cdef struct DctArraySize:
        JDIMENSION nrows
        JDIMENSION ncols
 

cdef extern from "read.h":

    int _read_jpeg_decompress_struct(FILE* infile,
                                     jpeg_decompress_struct* cinfo)
    
    void _get_quant_tables(UINT16 tables[],
                           jpeg_decompress_struct* obj)
        
    void _get_dct_array_size(int ci,
                             DctArraySize* arr_size,
                             const jpeg_decompress_struct* cinfo)
    
    void _get_dct_coefficients(JCOEF arr[],
                               jpeg_decompress_struct* cinfo)
    

#cdef extern from "read.c":
#    # C is include here so that it doesn't need to be compiled externally
#    pass


cdef class DecompressedJpeg:

    def __cinit__(self):
        self._cinfo = jpeg_decompress_struct() #<jpeg_decompress_struct*> malloc(sizeof(jpeg_decompress_struct))
        #if self._cinfo is NULL:
        #    raise MemoryError()
        
        self._infile = NULL

    def __dealloc__(self):
        #if self._cinfo:
        #    free(self._cinfo)
            
        if self._infile:
            fclose(self._infile)
            
    cpdef read(self, fname):
        cdef bytes py_bytes = fname.encode()
        cdef char* fname_cstr = py_bytes
        print(fname_cstr)
        cdef int res
        
#        cdef const int nqt = NUM_QUANT_TBLS
#        cdef const int len_dct_block = DCTSIZE*DCTSIZE
#        
#        cdef np.ndarray qaunt_tables = np.zeros((nqg*len_dct_block),
#                                                 dtype=np.uint16)        
#        cdef UINT16[::1] quant_tables_memview = quant_tables
        
        #_get_quant_tables(&quant_tables_memview[0], self._cinfo)
        
        
        
        #res = _read_jpeg_decompress_struct(self._cinfo, c_string)
        self._infile = fopen(fname_cstr, "rb")
        if self._infile == NULL:
            print("Can't open the given JPEG file.")
            return
        
        print("File has been opened")
        self._infile = fopen(fname_cstr, "rb")
        
        res = _read_jpeg_decompress_struct(self._infile, &self._cinfo)
        if res < 0:
            raise IOError("An error has occurs in reading the file.")
        
        self.get_quant_tables()
        self.get_dct_coefficients()
        
        
        fclose(self._infile)
        
    cpdef get_quant_tables(self):
        """Get the quantization tables.
        """
        cdef np.ndarray arr = np.zeros((NUM_QUANT_TBLS*DCTSIZE*DCTSIZE),
                                       dtype=np.uint16)
        cdef UINT16[::1] arr_memview = arr
        
        _get_quant_tables(&arr_memview[0], &self._cinfo)
        self.quant_tables = arr.reshape(NUM_QUANT_TBLS, DCTSIZE, DCTSIZE)
    
    
    
    cpdef get_dct_coefficients(self):
        """Get the DCT coefficients.
        """        
        cdef int nch = self._cinfo.num_components
        print("num components:", nch)
        #cdef int i
        cdef DctArraySize dct_arr_size
        cdef list list_arr_sizes = list()
        cdef int num_total_coef = 0
        for i in range(nch):
            _get_dct_array_size(i, &dct_arr_size, &self._cinfo)
            list_arr_sizes.append((dct_arr_size.nrows, dct_arr_size.ncols))
            print("DCT ARR SIZE: ", dct_arr_size.nrows, dct_arr_size.ncols)
            num_total_coef += (dct_arr_size.nrows * dct_arr_size.ncols)
        # end of for
        print(list_arr_sizes)
        
        
        
        #cdef unsigned int nch = dct_arr_size.nch
        #cdef JDIMENSION nrows = dct_arr_size.nrows
        #cdef JDIMENSION ncols = dct_arr_size.ncols
            
        cdef np.ndarray arr = np.zeros((num_total_coef),
                                       dtype=np.int16)
        cdef np.ndarray subarr
        
        cdef JCOEF[::1] arr_memview = arr        
        _get_dct_coefficients(&arr_memview[0], &self._cinfo)
        
        print("size of arr:", np.size(arr))
        
        self.dct_coefficients = list()
        cdef Py_ssize_t idx_beg = 0
        cdef JDIMENSION nrows
        cdef JDIMENSION ncols
        for i in range(nch):
            nrows, ncols = list_arr_sizes[i]  
            print("nrows, ncols = %d, %d"%(nrows, ncols))
            idx_end = idx_beg + nrows * ncols
            print("idx_beg, idx_end = %d, %d"%(idx_beg, idx_end))
            subarr = arr[idx_beg:idx_end]
            print("size of subarr:", np.size(subarr))
            self.dct_coefficients.append(subarr.reshape(nrows, ncols))
            idx_beg = idx_end
        