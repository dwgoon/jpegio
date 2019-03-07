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



cdef class DecompressedJpeg:

    def __cinit__(self):
        self._cinfo = <j_decompress_ptr> malloc(sizeof(jpeg_decompress_struct))
        self._jerr = <my_error_ptr> malloc(sizeof(my_error_mgr))
        self.coef_arrays = None
        
        if self._cinfo is NULL:
            raise MemoryError("Failed to malloc jpeg_decompress_struct")
            
        if self._jerr is NULL:
            raise MemoryError("Failed to malloc my_error_mgr")
        
        self._infile = NULL
        self._mem_buff = NULL
        

    def __dealloc__(self):
        if self._cinfo:
            _dealloc_jpeg_decompress(self._cinfo)
                    
        if self._infile != NULL:
            fclose(self._infile)
            
        if self._jerr != NULL:
            free(self._jerr)
            
        if self._cinfo != NULL:
            free(self._cinfo)
            
        if self._mem_buff != NULL:
            _dealloc_memory_buffer(self._mem_buff)
    
    cpdef read(self, fpath):
        if not os.path.isfile(fpath):
            print("Wrong file path: %s"%(fpath))
            return
            
        cdef bytes py_bytes = fpath.encode()
        cdef char* fpath_cstr = py_bytes        
        
        self._infile = fopen(fpath_cstr, "rb")
        if self._infile == NULL:
            printf("Can't open the given JPEG file.\n")
            return
        
        self._mem_buff = _read_jpeg_decompress_struct(self._infile,
                                                      self._cinfo,
                                                      self._jerr)

        if self._mem_buff == NULL:
            raise IOError("An error has occurs in reading the file.")
        
        self._get_comp_info()        
        self._get_quant_tables()        
        self._get_dct_coefficients()
        
        fclose(self._infile)
        self._infile = NULL
        
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
        
    cdef _get_comp_info(self):
        cdef int i
        cdef int nch = self._cinfo.num_components
        cdef jpeg_component_info* ptr_ci
        cdef ComponentInfo comp_info
        
        self.comp_info = list()        
        for i in range(nch):
            comp_info = ComponentInfo()
            ptr_ci = &(self._cinfo.comp_info[i])
            comp_info.component_id = ptr_ci.component_id
            comp_info.h_samp_factor = ptr_ci.h_samp_factor
            comp_info.v_samp_factor = ptr_ci.v_samp_factor    
            
            comp_info.quant_tbl_no = ptr_ci.quant_tbl_no 
            comp_info.ac_tbl_no = ptr_ci.ac_tbl_no
            comp_info.dc_tbl_no = ptr_ci.dc_tbl_no
            
            comp_info.downsampled_height = ptr_ci.downsampled_height
            comp_info.downsampled_width = ptr_ci.downsampled_width
        
            comp_info.height_in_blocks = ptr_ci.height_in_blocks
            comp_info.width_in_blocks = ptr_ci.width_in_blocks
            
            self.comp_info.append(comp_info)
#        # end of for
        
        
    cdef _get_quant_tables(self):
        """Get the quantization tables.
        """
        cdef int num_tables = _get_num_quant_tables(self._cinfo)
        cdef cnp.ndarray arr = np.zeros((num_tables*DCTSIZE2),
                                        dtype=np.uint16)
        cdef UINT16[::1] arr_mem_buffview = arr
                
        _read_quant_tables(&arr_mem_buffview[0], self._cinfo)
        self.quant_tables = arr.reshape(num_tables, DCTSIZE, DCTSIZE)
    
    
    cdef _get_dct_coefficients(self):
        """Get the DCT coefficients.
        """        
        self.coef_arrays = list()
#        self.coef_block_arrays = list()

        cdef int nch = self._cinfo.num_components
        cdef DctBlockArraySize blkarr_size
        #cdef list list_blkarr_sizes = list()
        #cdef int num_total_coef = 0
        cdef cnp.ndarray arr
        cdef cnp.ndarray blk_arr
        cdef JCOEF[:, ::1] arr_mv  # Memory view
        cdef jvirt_barray_ptr* jvirt_barray      
                
        #cdef Py_ssize_t idx_beg = 0
        #cdef Py_ssize_t idx_end = 0
        #cdef JDIMENSION nrows, ncols
        #cdef cnp.ndarray block_array
        #cdef cnp.ndarray subarr

                
        # Create and populate the DCT coefficient arrays
        jvirt_barray = jpeg_read_coefficients(self._cinfo)
        if jvirt_barray == NULL:
            printf("[LIBJPEG ERROR] Failed to read coefficients.\n")
            return
        
        cdef int i
        #cdef slice sr
        #cdef slice sc
        
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
#            for ir_blk in range(blkarr_size.nrows):
#                for ic_blk in range(blkarr_size.ncols):
#                    sr = slice(ir_blk*DCTSIZE, (ir_blk+1)*DCTSIZE, 1)
#                    sc = slice(ic_blk*DCTSIZE, (ir_blk+1)*DCTSIZE, 1)
#                    blk_arr[ir_blk, ic_blk, :, :] = arr[sr, sc]
#                # end of for
#            # end of for
#            self.coef_blocks.append(blk_arr)                
        # end of for
        
                
            
        
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