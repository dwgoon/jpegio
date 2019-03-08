# cython: language_level=3

# _cython: boundscheck=False, wraparound=False

from libc.stdio cimport printf
from libc.stdio cimport FILE, fopen, fclose, fread
from libc.stdlib cimport malloc, free

import os

import numpy as np
cimport numpy as cnp

cimport clibjpeg
from .clibjpeg cimport *
from .clibjpeg cimport jpeg_component_info


from . cimport componentinfo
from .componentinfo cimport ComponentInfo

from .decompressedjpeg cimport DecompressedJpeg



cdef class ZigzagDct1d(DecompressedJpeg):

    def __cinit__(self):
        pass
        

    def __dealloc__(self):
        pass
    
    def __init__(self, icut=DCTSIZE2):
        super().__init__()
        self.icut = icut
                
    cpdef get_coef_block(self, c, i, j):
        if not self.coef_arrays:
            raise AttributeError("coef_arrays has not been created yet.")
            
        cdef slice sr = slice(i*DCTSIZE, (i+1)*DCTSIZE, 1)
        cdef slice sc = slice(j*DCTSIZE, (j+1)*DCTSIZE, 1)
        return self.coef_arrays[c][sr, sc]
    
    cpdef get_coef_block_array_shape(self, c):
        if not self.coef_arrays:
            raise AttributeError("coef_arrays has not been created yet.")
            
        return (int(self.coef_arrays[c].shape[0]/DCTSIZE),
                int(self.coef_arrays[c].shape[1]/DCTSIZE))
        
    # Override
    cdef _get_dct_coefficients(self):
        """Get the DCT coefficients.
        """        
        self.coef_arrays = list()

        cdef int nch = self._cinfo.num_components
        cdef DctBlockArraySize blkarr_size
        cdef cnp.ndarray arr
        cdef cnp.ndarray blk_arr
        cdef JCOEF[:, ::1] arr_mv  # Memory view
        cdef jvirt_barray_ptr* jvirt_barray      
                
        # Create and populate the DCT coefficient arrays
        jvirt_barray = jpeg_read_coefficients(self._cinfo)
        if jvirt_barray == NULL:
            printf("[LIBJPEG ERROR] Failed to read coefficients.\n")
            return
        
        cdef int i       
        for i in range(nch):
            _get_size_dct_block(&blkarr_size, self._cinfo, i)
            arr = np.zeros((blkarr_size.nrows*DCTSIZE,
                            blkarr_size.ncols*DCTSIZE), dtype=np.int16)
            arr_mv = arr
            _read_coef_array(<JCOEF*> &arr_mv[0, 0],
                             self._cinfo,
                             jvirt_barray[i],
                             blkarr_size)
            
            self.coef_arrays.append(arr)
            
            blk_arr = np.zeros((blkarr_size.nrows,
                                blkarr_size.ncols,
                                DCTSIZE,
                                DCTSIZE),
                                dtype=np.int16)
                    
#            
#        
#    @property
#    def image_width(self):
#        return self._cinfo.image_width
#    @property
#    def image_height(self):
#        return self._cinfo.image_height
#    @property
#    def out_color_space(self):
#        return self._cinfo.out_color_space
#    @property
#    def out_color_components(self):
#        return self._cinfo.out_color_components
#    @property
#    def jpeg_color_space(self):
#        return self._cinfo.jpeg_color_space
#    @property
#    def num_components(self):
#        return self._cinfo.num_components
#    @property
#    def progressive_mode(self):
#        return self._cinfo.progressive_mode