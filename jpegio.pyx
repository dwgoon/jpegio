# cython: language_level=3, boundscheck=False

from libc.setjmp cimport jmp_buf
from libc.stdio cimport FILE
from libc.stdio cimport fopen, fclose

import numpy as np
cimport numpy as np

import libjpeg
cimport libjpeg

#from libjpeg cimport JpegDecompress
#from clibjpeg cimport JpegDecompress

#cimport clibjpeg
#from clibjpeg cimport jpeg_decompress_struct
#from clibjpeg cimport jpeg_error_mgr
from clibjpeg cimport *

def test(n, dtype):
    cdef np.ndarray arr = np.zeros((n, n), dtype=dtype)
    
    return arr
    
def test_jpeg_decompress():
    cdef libjpeg.JpegDecompress obj = libjpeg.JpegDecompress()
    return obj
    
#cpdef test_read_jpeg_decompress_struct(s):
#    = 
    
#cdef extern from "setjmp.h":
#    cdef struct jmp_buf:
#        pass

#ctypedef struct jmp_buf:
#        pass
    
#cdef struct __error_mgr:
#    jpeg_error_mgr pub    # public" fields
#    jmp_buf setjmp_buffer  # for return to caller
#
#ctypedef __error_mgr error_mgr
#ctypedef __error_mgr* error_ptr
#
#cdef output_message(j_common_ptr cinfo):
#    cdef char buffer[JMSG_LENGTH_MAX]
#    # Create the message
#    (*cinfo->err->format_message)(cinfo, buffer)
#    # mexWarnMsgTxt(buffer);
#
#cdef error_exit(j_common_ptr cinfo):
#    char buffer[JMSG_LENGTH_MAX]
#    # cinfo->err really points to a error_mgr struct, so coerce pointer
#    error_ptr err_ptr = (error_ptr) cinfo->err
#    
#    # Create the message
#    (*cinfo->err->format_message)(cinfo, buffer)
#    printf("Error: %s\n",buffer)
#    
#    # Return control to the setjmp point
#    longjmp(myerr->setjmp_buffer, 1);
#
#    
#cpdef read_jpeg(char* filename):
#    cdef FILE *infile
#    
#    cdef jpeg_decompress_struct cinfo
#    cdef error_mgr jerr
#
#    cdef jpeg_component_info* compptr
#    cdef jvirt_barray_ptr* coef_arrays
#    cdef jpeg_saved_marker_ptr marker_ptr
#    
#    cdef JDIMENSION blk_x, blk_y
#    cdef JBLOCKARRAY buffer
#    cdef JCOEFPTR bufptr
#    cdef JQUANT_TBL* quant_ptr
#    cdef JHUFF_TBL* huff_ptr
#    cdef int strlen, c_width, c_height, ci, i, j, n
#    cdef int dims[2]
#    cdef double *mp, *mptop
#    
#    """
#    #char *filename;
#    #mxChar *mcp;
#    #mxArray *mxtemp, *mxjpeg_obj, *mxcoef_arrays, *mxcomments;
#    #mxArray *mxquant_tables, *mxhuff_tables, *mxcomp_info;
#
#    # field names jpeg_obj Matlab struct 
#    const char *jpegobj_field_names[] = {
#      "image_width",          # image width in pixels 
#      "image_height",         # image height in pixels 
#      "image_components",     # number of image color components 
#      "image_color_space",    # in/out_color_space 
#      "jpeg_components",      # number of JPEG color components 
#      "jpeg_color_space",     # color space of DCT coefficients 
#      "comments",             # COM markers, if any 
#      "coef_arrays",          # DCT arrays for each component 
#      "quant_tables",         # quantization tables 
#      "ac_huff_tables",       # AC huffman encoding tables 
#      "dc_huff_tables",       # DC huffman encoding tables 
#      "optimize_coding",      # flag to optimize huffman tables 
#      "comp_info",            # component info struct array 
#      "progressive_mode",     # is progressive mode 
#    };
#    const int num_jobj_fields = 14;
#
#    # field names comp_info struct 
#    const char *comp_field_names[] = {
#      "component_id",         # JPEG one byte identifier code 
#      "h_samp_factor",        # horizontal sampling factor 
#      "v_samp_factor",        # vertical sampling factor 
#      "quant_tbl_no",         # quantization table number for component 
#      "dc_tbl_no",            # DC entropy coding table number 
#      "ac_tbl_no"             # AC entropy encoding table number 
#    };
#    const int num_comp_fields = 6;
#
#    const char *huff_field_names[] = { "counts","symbols" };
#
#    # check input value 
#    #
#    #if (nrhs != 1) mexErrMsgTxt("One input argument required.");
#    #if (mxIsChar(prhs[0]) != 1)
#    #    mexErrMsgTxt("Filename must be a string");
#    
#    
#    
#    # check output return jpegobj struct 
#    # if (nlhs > 1) mexErrMsgTxt("Too many output arguments"); 
#
#
#    # get filename 
#    #strlen = mxGetM(prhs[0])*mxGetN(prhs[0]) + 1;
#    #filename = mxCalloc(strlen, sizeof(char));
#    #mxGetString(prhs[0], filename, strlen);
#    """
#    # Open JPEG image file.
#    infile = fopen(filename, "rb")
#    if infile == NULL:
#        raise IOError("Can't open the given JPEG file.");
#
#    infile = fopen(filename, "rb")
#
#    # Set up the normal JPEG error routines, then override error_exit. 
#    cinfo.err = jpeg_std_error(&jerr.pub)
#    jerr.pub.error_exit = my_error_exit
#    jerr.pub.output_message = my_output_message
#
#    # Establish the setjmp return context for error_exit to use. 
#    if setjmp(jerr.setjmp_buffer):
#        jpeg_destroy_decompress(&cinfo)
#        fclose(infile)
#        #mexErrMsgTxt("Error reading file");
#
#    # Initialize JPEG decompression object 
#    jpeg_create_decompress(&cinfo)
#    jpeg_stdio_src(&cinfo, infile)
#
#    # Save contents of markers 
#    jpeg_save_markers(&cinfo, JPEG_COM, 0xFFFF)
#
#    # Read header and coefficients 
#    jpeg_read_header(&cinfo, TRUE)
#
#    # Create Matlab jpegobj struct 
#    #mxjpeg_obj = mxCreateStructMatrix(1, 1, num_jobj_fields, jpegobj_field_names);
#
#    # for some reason out_color_components isn't being set by
#    # jpeg_read_header, so we will infer it from out_color_space: 
#    switch (cinfo.out_color_space) {
#    case JCS_GRAYSCALE:
#        cinfo.out_color_components = 1;
#        break;
#    case JCS_RGB:
#        cinfo.out_color_components = 3;
#        break;
#    case JCS_YCbCr:
#        cinfo.out_color_components = 3;
#        break;
#    case JCS_CMYK:
#        cinfo.out_color_components = 4;
#        break;
#    case JCS_YCCK:
#        cinfo.out_color_components = 4;
#        break;
#    }
#
#    # copy header information 
#    #
#    
#    # mxSetField(mxjpeg_obj, 0, "image_width",
#        # mxCDS(cinfo.image_width));
#    # mxSetField(mxjpeg_obj, 0, "image_height",
#        # mxCDS(cinfo.image_height));
#    # mxSetField(mxjpeg_obj, 0, "image_color_space",
#        # mxCDS(cinfo.out_color_space));
#    # mxSetField(mxjpeg_obj, 0, "image_components",
#        # mxCDS(cinfo.out_color_components));
#    # mxSetField(mxjpeg_obj, 0, "jpeg_color_space",
#        # mxCDS(cinfo.jpeg_color_space));
#    # mxSetField(mxjpeg_obj, 0, "jpeg_components",
#        # mxCDS(cinfo.num_components));
#    # mxSetField(mxjpeg_obj, 0, "progressive_mode",
#        # mxCDS(cinfo.progressive_mode));
#    
#
#    # set optimize_coding flag for jpeg_write() 
#    #mxSetField(mxjpeg_obj, 0, "optimize_coding", mxCDS(FALSE));
#
#    # copy component information 
#    #
#    mxcomp_info = mxCreateStructMatrix(1, cinfo.num_components,
#        num_comp_fields, comp_field_names);
#    mxSetField(mxjpeg_obj, 0, "comp_info", mxcomp_info);
#    for (ci = 0; ci < cinfo.num_components; ci++) {
#        mxSetField(mxcomp_info, ci, "component_id",
#            mxCDS(cinfo.comp_info[ci].component_id));
#        mxSetField(mxcomp_info, ci, "h_samp_factor",
#            mxCDS(cinfo.comp_info[ci].h_samp_factor));
#        mxSetField(mxcomp_info, ci, "v_samp_factor",
#            mxCDS(cinfo.comp_info[ci].v_samp_factor));
#        mxSetField(mxcomp_info, ci, "quant_tbl_no",
#            mxCDS(cinfo.comp_info[ci].quant_tbl_no + 1));
#        mxSetField(mxcomp_info, ci, "ac_tbl_no",
#            mxCDS(cinfo.comp_info[ci].ac_tbl_no + 1));
#        mxSetField(mxcomp_info, ci, "dc_tbl_no",
#            mxCDS(cinfo.comp_info[ci].dc_tbl_no + 1));
#    }
#    
#
#    # Copy markers
#    #mxcomments = mxCreateCellMatrix(0, 0);
#    #mxSetField(mxjpeg_obj, 0, "comments", mxcomments);
#    marker_ptr = cinfo.marker_list;
#    while (marker_ptr != NULL) {
#        switch (marker_ptr->marker) {
#        case JPEG_COM:
#            # this comment index 
#            n = mxGetN(mxcomments);
#
#            # allocate space in cell array for a new comment
#            # mxSetPr(mxcomments, mxRealloc(mxGetPr(mxcomments),
#                # (n + 1)*mxGetElementSize(mxcomments)));
#            # mxSetM(mxcomments, 1);
#            # mxSetN(mxcomments, n + 1);
#            
#
#            # Create new char array to store comment string
#            #
#            # dims[0] = 1;
#            # dims[1] = marker_ptr->data_length;
#            # mxtemp = mxCreateCharArray(2, dims);
#            # mxSetCell(mxcomments, n, mxtemp);
#            # mcp = (mxChar *)mxGetPr(mxtemp);
#            
#            # Copy comment string to char array 
#            for (i = 0; i < (int)marker_ptr->data_length; i++)
#                *mcp++ = (mxChar)marker_ptr->data[i];
#
#            break;
#        default:
#            break;
#        }
#        marker_ptr = marker_ptr->next;
#    }
#
#    # Copy the quantization tables
#    # mxquant_tables = mxCreateCellMatrix(1, NUM_QUANT_TBLS);
#    # mxSetField(mxjpeg_obj, 0, "quant_tables", mxquant_tables);
#    # mxSetN(mxquant_tables, 0);
#    for (n = 0; n < NUM_QUANT_TBLS; n++) {
#        if (cinfo.quant_tbl_ptrs[n] != NULL) {
#            # mxSetN(mxquant_tables, n + 1);
#            # mxtemp = mxCreateDoubleMatrix(DCTSIZE, DCTSIZE, mxREAL);
#            # mxSetCell(mxquant_tables, n, mxtemp);
#            # mp = mxGetPr(mxtemp);
#            quant_ptr = cinfo.quant_tbl_ptrs[n];
#            for (i = 0; i < DCTSIZE; i++)
#                for (j = 0; j < DCTSIZE; j++)
#                    mp[j*DCTSIZE + i] = (double)quant_ptr->quantval[i*DCTSIZE + j];
#        }
#    }
#
#    # Copy the AC huffman tables
#    # mxhuff_tables = mxCreateStructMatrix(1, NUM_HUFF_TBLS, 2, huff_field_names);
#    # mxSetField(mxjpeg_obj, 0, "ac_huff_tables", mxhuff_tables);
#    # mxSetN(mxhuff_tables, 0);
#    for (n = 0; n < NUM_HUFF_TBLS; n++) {
#        if (cinfo.ac_huff_tbl_ptrs[n] != NULL) {
#            huff_ptr = cinfo.ac_huff_tbl_ptrs[n];
#            # mxSetN(mxhuff_tables, n + 1);
#
#            # mxtemp = mxCreateDoubleMatrix(1, 16, mxREAL);
#            # mxSetField(mxhuff_tables, n, "counts", mxtemp);
#            # mp = mxGetPr(mxtemp);
#            for (i = 1; i <= 16; i++)
#            {
#                *mp++ = huff_ptr->bits[i];
#            }
#
#            # mxtemp = mxCreateDoubleMatrix(1, 256, mxREAL);
#            # mxSetField(mxhuff_tables, n, "symbols", mxtemp);
#            # mp = mxGetPr(mxtemp);
#            for (i = 0; i < 256; i++)
#            {
#                *mp++ = huff_ptr->huffval[i];
#            }
#        }
#    }
#
#    # Copy the DC huffman tables 
#    # mxhuff_tables = mxCreateStructMatrix(1, NUM_HUFF_TBLS, 2, huff_field_names);
#    # mxSetField(mxjpeg_obj, 0, "dc_huff_tables", mxhuff_tables);
#    # mxSetN(mxhuff_tables, 0);
#    for (n = 0; n < NUM_HUFF_TBLS; n++)
#    {
#        if (cinfo.dc_huff_tbl_ptrs[n] != NULL) 
#        {
#            huff_ptr = cinfo.dc_huff_tbl_ptrs[n];
#            # mxSetN(mxhuff_tables, n + 1);
#
#            # mxtemp = mxCreateDoubleMatrix(1, 16, mxREAL);
#            # mxSetField(mxhuff_tables, n, "counts", mxtemp);
#            # mp = mxGetPr(mxtemp);
#            for (i = 1; i <= 16; i++)
#            {
#                *mp++ = huff_ptr->bits[i];
#            }
#
#            # mxtemp = mxCreateDoubleMatrix(1, 256, mxREAL);
#            # mxSetField(mxhuff_tables, n, "symbols", mxtemp);
#            # mp = mxGetPr(mxtemp);
#            for (i = 0; i < 256; i++)
#            {
#                *mp++ = huff_ptr->huffval[i];                
#            }
#        }
#    }
#
#    # Create and populate the DCT coefficient arrays
#    coef_arrays = jpeg_read_coefficients(&cinfo);
#    #mxcoef_arrays = mxCreateCellMatrix(1, cinfo.num_components);
#    #mxSetField(mxjpeg_obj, 0, "coef_arrays", mxcoef_arrays);
#    for (ci = 0; ci < cinfo.num_components; ci++) {
#        compptr = cinfo.comp_info + ci;
#        c_height = compptr->height_in_blocks * DCTSIZE;
#        c_width = compptr->width_in_blocks * DCTSIZE;
#
#        # Create Matlab dct block array for this component
#        mxtemp = mxCreateDoubleMatrix(c_height, c_width, mxREAL);
#        mxSetCell(mxcoef_arrays, ci, mxtemp);
#        mp = mxGetPr(mxtemp);
#        mptop = mp;
#        
#
#        # Copy coefficients from virtual block arrays
#        for (blk_y = 0; blk_y < compptr->height_in_blocks; blk_y++)
#        {
#            buffer = (cinfo.mem->access_virt_barray) ((j_common_ptr)&cinfo, coef_arrays[ci], blk_y, 1, FALSE);
#            for (blk_x = 0; blk_x < compptr->width_in_blocks; blk_x++) 
#            {
#                bufptr = buffer[0][blk_x];
#                for (i = 0; i < DCTSIZE; i++) # for each row in block
#                {
#                    for (j = 0; j < DCTSIZE; j++) # for each column in block
#                    {
#                        mp[j*c_height + i] = (double) bufptr[i*DCTSIZE + j];
#                    }
#                    mp += DCTSIZE*c_height; # Pointer operation
#                }
#            }
#            mp = (mptop += DCTSIZE);
#        }
#    }
#
#    # Done with cinfo
#    jpeg_finish_decompress(&cinfo);
#    jpeg_destroy_decompress(&cinfo);
#
#    # Close input file
#    fclose(infile);
#
#    # Set output
#    # if (nlhs == 1) plhs[0] = mxjpeg_obj;
#    """