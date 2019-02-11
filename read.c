#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include "jerror.h"
#include "jpeglib.h"
//#include "jmorecfg.h"

#include "read.h"

struct error_mgr {
	struct jpeg_error_mgr pub; // "public" fields
	jmp_buf setjmp_buffer;	 // for return to caller
};

typedef struct error_mgr* error_ptr;

METHODDEF(void) 
output_message(j_common_ptr cinfo)
{
	char buffer[JMSG_LENGTH_MAX];

	// Create the message
	(*cinfo->err->format_message)(cinfo, buffer);

	// mexWarnMsgTxt(buffer);
	printf("%s\n", buffer);
}

METHODDEF(void)
error_exit(j_common_ptr cinfo)
{
	char buffer[JMSG_LENGTH_MAX];

	// cinfo->err really points to an error_mgr struct, so coerce pointer
	error_ptr err = (error_ptr) cinfo->err;

	// Create the message
	(*cinfo->err->format_message) (cinfo, buffer);
	printf("Error: %s\n", buffer);

	// Return control to the setjmp point
	longjmp(err->setjmp_buffer, 1);

}


int _read_jpeg_decompress_struct(FILE* infile,
                                 struct jpeg_decompress_struct* cinfo)
{

	//struct jpeg_decompress_struct cinfo;
	struct error_mgr jerr;
	jpeg_component_info *compptr;
	jvirt_barray_ptr *coef_arrays;
	jpeg_saved_marker_ptr marker_ptr;

	JDIMENSION blk_x, blk_y;
	JBLOCKARRAY buffer;
	JCOEFPTR bufptr;
	//JQUANT_TBL *quant_ptr;
	//JHUFF_TBL *huff_ptr;
	int strlen, c_width, c_height, ci, i, j, n, dims[2];
	//char *filename;
	double *mp, *mptop;

	/*
	#char *filename;
	#mxChar *mcp;
	#mxArray *mxtemp, *mxjpeg_cinfo, *mxcoef_arrays, *mxcomments;
	#mxArray *mxquant_tables, *mxhuff_tables, *mxcomp_info;

	# field names jpeg_cinfo Matlab struct
	const char *jpegcinfo_field_names[] = {
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
	const int num_jcinfo_fields = 14;

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



	# check output return jpegcinfo struct
	# if (nlhs > 1) mexErrMsgTxt("Too many output arguments");


	# get filename
	#strlen = mxGetM(prhs[0])*mxGetN(prhs[0]) + 1;
	#filename = mxCalloc(strlen, sizeof(char));
	#mxGetString(prhs[0], filename, strlen);
	"""
	
	*/
	
	// Open JPEG image file.
//	infile = fopen(fname, "rb");
//	if (infile == NULL)
//	{
//		printf("Can't open the given JPEG file.\n");
//		return -1; 
//    }
//    
//    printf("File has been opened.\n");
//	infile = fopen(fname, "rb");
	
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
		// printf("Error reading file");
		//mexErrMsgTxt("Error reading file");
		return -1;
	}
	
	// Initialize JPEG decompression cinfo object 
	jpeg_create_decompress(cinfo);
	jpeg_stdio_src(cinfo, infile);

	// Save contents of markers 
	jpeg_save_markers(cinfo, JPEG_COM, 0xFFFF);

	// Read header
	jpeg_read_header(cinfo, TRUE);

	// Create Matlab jpegcinfo struct 
	//mxjpeg_cinfo = mxCreateStructMatrix(1, 1, num_jcinfo_fields, jpegcinfo_field_names);

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
	
	
	//_get_quant_tables(quant_tables, cinfo);
	//_get_dct_coefficients(dct_coefficents, cinfo);

    printf("All done...\n");
    return 0;
}


void _get_quant_tables(UINT16 tables[],
                       const struct jpeg_decompress_struct* cinfo)
{
    size_t n, i, j;    
	JQUANT_TBL* quant_ptr;
    UINT16* vals;
    UINT16* table;

	for (n = 0; n < NUM_QUANT_TBLS; n++) 
	{
		if (cinfo->quant_tbl_ptrs[n] != NULL)
		{	
    		table = &tables[n*(DCTSIZE*DCTSIZE)];
			quant_ptr = cinfo->quant_tbl_ptrs[n];
			for (i = 0; i < DCTSIZE; i++)
			{
				for (j = 0; j < DCTSIZE; j++)
				{
    				vals = &(quant_ptr->quantval);
					table[i*DCTSIZE + j] = vals[i*DCTSIZE + j];
				}
			}
		}
	}
}

void _get_dct_array_size(int ci,
                         struct DctArraySize* arr_size,
                         const struct jpeg_decompress_struct* cinfo)
{
	// JDIMENSION c_width, c_height;
	jpeg_component_info *compptr;
           
    compptr = cinfo->comp_info + ci;    
    arr_size->nrows = compptr->height_in_blocks * DCTSIZE;
	arr_size->ncols = compptr->width_in_blocks * DCTSIZE;
}

void _get_dct_coefficients(JCOEF arr[],
                           struct jpeg_decompress_struct* cinfo)
{
	jpeg_component_info *compptr;
	jvirt_barray_ptr *coef_arrays;
	JBLOCKARRAY buffer;
	JCOEFPTR bufptr;
	JDIMENSION nrows, ncols;
	JDIMENSION blk_x, blk_y;
	const JDIMENSION BLKSIZE = DCTSIZE*DCTSIZE;
	const JDIMENSION WIDTH_BLK = compptr->width_in_blocks;
	const JDIMENSION HEIGHT_BLK = compptr->height_in_blocks;
	
	JDIMENSION num_processed = 0;
	
	int ci, i, j, idx;

	printf("_get_dct_coefficients entered...\n");


    // Create and populate the DCT coefficient arrays
    printf("cinfo->global_state: %d\n", cinfo->global_state);
	coef_arrays = jpeg_read_coefficients(&(*cinfo));
	if (coef_arrays == NULL) 
	{
    	printf("Failed to read coefficients...\n");
	} 
	
	printf("Reading coefficents from cinfo completed...\n");
	//mxcoef_arrays = mxCreateCellMatrix(1, cinfo.num_components);
	//mxSetField(mxjpeg_cinfo, 0, "coef_arrays", mxcoef_arrays);
	for (ci = 0; ci < cinfo->num_components; ci++) 
	{
		compptr = cinfo->comp_info + ci;
		nrows = compptr->height_in_blocks * DCTSIZE;
		ncols = compptr->width_in_blocks * DCTSIZE;
		
		/* Create Matlab dct block array for this component
		mxtemp = mxCreateDoubleMatrix(c_height, c_width, mxREAL);
		mxSetCell(mxcoef_arrays, ci, mxtemp);
		mp = mxGetPr(mxtemp);
		mptop = mp;
		*/

		// Copy coefficients from virtual block arrays
		for (blk_y = 0; blk_y < compptr->height_in_blocks; blk_y++)
		{
			buffer = (cinfo->mem->access_virt_barray) ((j_common_ptr)cinfo, coef_arrays[ci], blk_y, 1, FALSE);
			for (blk_x = 0; blk_x < compptr->width_in_blocks; blk_x++) 
			{
				bufptr = buffer[0][blk_x];
				for (i = 0; i < DCTSIZE; i++) // for each row in block
				{
					for (j = 0; j < DCTSIZE; j++) // for each column in block
					{
    					//idx = (ci*nrows*ncols) + blk_y*(WIDTH_BLK*BLKSIZE) + blk_x*(BLKSIZE) + (i*DCTSIZE + j);
    					idx = num_processed;
						arr[idx] = bufptr[i*DCTSIZE + j];
						num_processed++;
					}
					//mp += DCTSIZE*c_height; // Pointer operation
				}
			}
			//mp = (mptop += DCTSIZE);
		}
		printf("[DCT COEF] num_processed: %d\n", num_processed);
		
	}
}


/*
	// Copy markers
	//mxcomments = mxCreateCellMatrix(0, 0);
	//mxSetField(mxjpeg_cinfo, 0, "comments", mxcomments);
void copy_markers(struct jpeg_decompress_struct* cinfo)
{
	marker_ptr = cinfo.marker_list;
	while (marker_ptr != NULL)
	{
		switch (marker_ptr->marker) 
		{
		case JPEG_COM:
			// this comment index
			n = mxGetN(mxcomments);

			// allocate space in cell array for a new comment
			//mxSetPr(mxcomments, mxRealloc(mxGetPr(mxcomments),
			//	(n + 1)*mxGetElementSize(mxcomments)));
			//mxSetM(mxcomments, 1);
			//mxSetN(mxcomments, n + 1);
			//

			// Create new char array to store comment string
//			dims[0] = 1;
//			dims[1] = marker_ptr->data_length;
//			mxtemp = mxCreateCharArray(2, dims);
//			mxSetCell(mxcomments, n, mxtemp);
//			mcp = (mxChar *)mxGetPr(mxtemp);
			// Copy comment string to char array
			for (int i = 0; i < (int)marker_ptr->data_length; i++)
			{
				*mcp++ = (mxChar)marker_ptr->data[i];
            }
			break;
		default:
			break;
		}
		marker_ptr = marker_ptr->next;
	}
}*/

