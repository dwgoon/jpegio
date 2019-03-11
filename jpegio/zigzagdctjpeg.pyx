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
    
    def __init__(self):
        super().__init__()
                
#    cpdef get_coef_block(self, c, i, j):
#        if not self.coef_arrays:
#            raise AttributeError("coef_arrays has not been created yet.")            
#
#        return self.coef_arrays[c][i, j, :]
    
    cpdef get_coef_block_array_shape(self, c):
        if not self.coef_arrays:
            raise AttributeError("coef_arrays has not been created yet.")
            
        return (self.coef_arrays[c].shape[0],
                self.coef_arrays[c].shape[1])
        
    # Override
    cdef _get_dct_coefficients(self):
        """Get the DCT coefficients.
        """        
        self.coef_arrays = list()

        cdef int nch = self._cinfo.num_components
        cdef DctBlockArraySize blkarr_size
        cdef cnp.ndarray arr
        cdef cnp.ndarray blk_arr
        cdef JCOEF[:, :, ::1] arr_mv  # Memory view
        cdef jvirt_barray_ptr* jvirt_barray      
                
        # Create and populate the DCT coefficient arrays
        jvirt_barray = jpeg_read_coefficients(self._cinfo)
        if jvirt_barray == NULL:
            printf("[LIBJPEG ERROR] Failed to read coefficients.\n")
            return
        
        cdef int i       
        for i in range(nch):
            _get_size_dct_block(&blkarr_size, self._cinfo, i)
            arr = np.zeros((blkarr_size.nrows, blkarr_size.ncols,
                            DCTSIZE2), dtype=np.int16)
            arr_mv = arr
            _read_coef_array_zigzag_dct_1d(<JCOEF*> &arr_mv[0, 0, 0],
                                           self._cinfo,
                                           jvirt_barray[i],
                                           blkarr_size)
            
            self.coef_arrays.append(arr)
                    
