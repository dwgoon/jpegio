#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include "jerror.h"
#include "jpeglib.h"

#include "read.h"

struct error_mgr {
	struct jpeg_error_mgr pub; // "public" fields
	jmp_buf setjmp_buffer;	 // for return to caller
};

typedef struct error_mgr* error_ptr;

void output_message(j_common_ptr cinfo)
{
	char buffer[JMSG_LENGTH_MAX];

	// Create the message
	(*cinfo->err->format_message)(cinfo, buffer);

	// mexWarnMsgTxt(buffer);
	printf("%s\n", buffer);
}

void error_exit(j_common_ptr cinfo)
{
	char buffer[JMSG_LENGTH_MAX];

	// cinfo->err really points to a my_error_mgr struct, so coerce pointer
	error_ptr myerr = (error_ptr)cinfo->err;

	// Create the message
	(*cinfo->err->format_message) (cinfo, buffer);
	printf("Error: %s\n", buffer);

	// Return control to the setjmp point
	longjmp(myerr->setjmp_buffer, 1);

}

int read_jpeg_decompress_struct(char* fname,
                                struct jpeg_decompress_struct* cinfo)
{
	FILE *infile;

	//struct jpeg_decompress_struct cinfo;
	struct error_mgr jerr;
	jpeg_component_info *compptr;
	jvirt_barray_ptr *coef_arrays;
	jpeg_saved_marker_ptr marker_ptr;

	JDIMENSION blk_x, blk_y;
	JBLOCKARRAY buffer;
	JCOEFPTR bufptr;
	JQUANT_TBL *quant_ptr;
	JHUFF_TBL *huff_ptr;
	int strlen, c_width, c_height, ci, i, j, n, dims[2];
	char *filename;
	double *mp, *mptop;

	/*
	#char *filename;
	#mxChar *mcp;
	#mxArray *mxtemp, *mxjpeg_obj, *mxcoef_arrays, *mxcomments;
	#mxArray *mxquant_tables, *mxhuff_tables, *mxcomp_info;

	# field names jpeg_obj Matlab struct
	const char *jpegobj_field_names[] = {
	  "image_width",          # image width in pixels
	  "image_height",         # image height in pixels
	  "image_components",     # number of image color components
	  "image_color_space",    # in/out_color_space
	  "jpeg_components",      # number of JPEG color components
	  "jpeg_color_space",     # color space of DCT coefficients
	  "comments",             # COM markers, if any
	  "coef_arrays",          # DCT arrays for each component
	  "quant_tables",         # quantization tables
	  "ac_huff_tables",       # AC huffman encoding tables
	  "dc_huff_tables",       # DC huffman encoding tables
	  "optimize_coding",      # flag to optimize huffman tables
	  "comp_info",            # component info struct array
	  "progressive_mode",     # is progressive mode
	};
	const int num_jobj_fields = 14;

	# field names comp_info struct
	const char *comp_field_names[] = {
	  "component_id",         # JPEG one byte identifier code
	  "h_samp_factor",        # horizontal sampling factor
	  "v_samp_factor",        # vertical sampling factor
	  "quant_tbl_no",         # quantization table number for component
	  "dc_tbl_no",            # DC entropy coding table number
	  "ac_tbl_no"             # AC entropy encoding table number
	};
	const int num_comp_fields = 6;

	const char *huff_field_names[] = { "counts","symbols" };

	# check input value
	#
	#if (nrhs != 1) mexErrMsgTxt("One input argument required.");
	#if (mxIsChar(prhs[0]) != 1)
	#    mexErrMsgTxt("Filename must be a string");



	# check output return jpegobj struct
	# if (nlhs > 1) mexErrMsgTxt("Too many output arguments");


	# get filename
	#strlen = mxGetM(prhs[0])*mxGetN(prhs[0]) + 1;
	#filename = mxCalloc(strlen, sizeof(char));
	#mxGetString(prhs[0], filename, strlen);
	"""
	
	*/
	
	// Open JPEG image file.
	infile = fopen(fname, "rb");
	if (infile == NULL)
	{
		printf("Can't open the given JPEG file.\n");
		exit(1); 
    }
    
    printf("File has been opened.\n");
	infile = fopen(fname, "rb");
	
	// Set up the normal JPEG error routines, then override error_exit. 
	cinfo->err = jpeg_std_error(&jerr.pub);
	jerr.pub.error_exit = error_exit;
	jerr.pub.output_message = output_message;

	// Establish the setjmp return context for error_exit to use. 
	if (setjmp(jerr.setjmp_buffer))
	{
		//jpeg_destroy_decompress(&cinfo);
		jpeg_destroy_decompress(cinfo);
		fclose(infile);
		printf("Error reading file");
		//mexErrMsgTxt("Error reading file");
	}
	// Initialize JPEG decompression object 
	//jpeg_create_decompress(&cinfo);
	// jpeg_stdio_src(&cinfo, infile);
	jpeg_create_decompress(cinfo);
	jpeg_stdio_src(cinfo, infile);

	// Save contents of markers 
	jpeg_save_markers(cinfo, JPEG_COM, 0xFFFF);

	// Read header and coefficients 
	jpeg_read_header(cinfo, TRUE);

	// Create Matlab jpegobj struct 
	//mxjpeg_obj = mxCreateStructMatrix(1, 1, num_jobj_fields, jpegobj_field_names);

	// for some reason out_color_components isn't being set by
	// jpeg_read_header, so we will infer it from out_color_space: 
	switch (cinfo->out_color_space)
	{
	case JCS_GRAYSCALE:
		cinfo->out_color_components = 1;
		break;
	case JCS_RGB:
		cinfo->out_color_components = 3;
		break;
	case JCS_YCbCr:
		cinfo->out_color_components = 3;
		break;
	case JCS_CMYK:
		cinfo->out_color_components = 4;
		break;
	case JCS_YCCK:
		cinfo->out_color_components = 4;
		break;
	}

    printf("All done...\n");
	//return cinfo;
}