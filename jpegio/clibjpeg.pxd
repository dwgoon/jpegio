
cdef extern from "jconfig.h":
    ctypedef unsigned char boolean


cdef extern from "jmorecfg.h":
    ctypedef unsigned short UINT16
    ctypedef unsigned int JDIMENSION
    ctypedef short JCOEF


cdef extern from "jpeglib.h":    

    cdef const int DCTSIZE          = 8   # The basic DCT block is 8x8 coefficients
    cdef const int DCTSIZE2         = 64  # DCTSIZE squared; # of elements in a block
    cdef const int NUM_QUANT_TBLS   = 4   # Quantization tables are numbered 0..3
    cdef const int NUM_HUFF_TBLS    = 4   # Huffman tables are numbered 0..3
    cdef const int NUM_ARITH_TBLS   = 16  # Arith-coding tables are numbered 0..15
    
    ctypedef enum J_COLOR_SPACE:
        JCS_UNKNOWN,      # error/unspecified
        JCS_GRAYSCALE,    # monochrome
        JCS_RGB,          # red/green/blue
        JCS_YCbCr,        # Y/Cb/Cr (also known as YUV)
        JCS_CMYK,         # C/M/Y/K
        JCS_YCCK          # Y/Cb/Cr/K
            
    ctypedef struct jpeg_component_info:
        int component_id
        int h_samp_factor
        int v_samp_factor       
        int quant_tbl_no
        int ac_tbl_no
        int dc_tbl_no#        
        JDIMENSION downsampled_height         
        JDIMENSION downsampled_width        
        JDIMENSION height_in_blocks
        JDIMENSION width_in_blocks

    cdef struct jpeg_decompress_struct:        
        jpeg_component_info* comp_info
        
        JDIMENSION image_width
        JDIMENSION image_height
        int num_components
        int out_color_components
        J_COLOR_SPACE jpeg_color_space
        J_COLOR_SPACE out_color_space       
        boolean progressive_mode        
        

    ctypedef jpeg_decompress_struct* j_decompress_ptr    
    
    
    struct jvirt_barray_control:
        pass
    
    ctypedef jvirt_barray_control* jvirt_barray_ptr
    
    jvirt_barray_ptr* jpeg_read_coefficients(j_decompress_ptr cinfo)

