

#include "read.h"

/* The default output_message routine causes a seg fault in Matlab,
 * at least on Windows.  Its generally used to emit warnings, since
 * fatal errors call the error_exit routine, so we emit a Matlab
 * warning instead.  If desired, warnings can be turned off by the
 * user with "warnings off".   -- PAS 10/03
*/
METHODDEF(void)
my_output_message(j_common_ptr cinfo)
{
    char buffer[JMSG_LENGTH_MAX];

    // Create the message
    (*cinfo->err->format_message) (cinfo, buffer);

    printf("[LIBJPEG MESSAGE] %s\n", buffer);
}


METHODDEF(void)
my_error_exit(j_common_ptr cinfo)
{
    char buffer[JMSG_LENGTH_MAX];

    // cinfo->err really points to a jpegio_error_mgr struct, so coerce pointer 
    jpegio_error_ptr myerr = (jpegio_error_ptr) cinfo->err;

    // create the message
    (*cinfo->err->format_message) (cinfo, buffer);
    printf("[LIBJPEG ERROR]: %s\n", buffer);

    // return control to the setjmp point
    longjmp(myerr->setjmp_buffer, 1);
}


unsigned char* _read_jpeg_decompress_struct(
    FILE* infile,
    j_decompress_ptr cinfo,
    jpegio_error_ptr jerr)
{
    unsigned char* mem_buffer = NULL;
    unsigned long mem_size = 0;

    // Set up the normal JPEG error routines, then override error_exit. 
    cinfo->err = jpeg_std_error(&jerr->pub);    
    jerr->pub.error_exit = my_error_exit;
    jerr->pub.output_message = my_output_message;
    
    
    // Establish the setjmp return context for error_exit to use. 
    if (setjmp(jerr->setjmp_buffer))
    {
        jpeg_destroy_decompress(cinfo);
        printf("[LIBJPEG] Error occurs during reading file.\n");
        return NULL;
    }
    
    // Get the size of file
    fseek(infile, 0, SEEK_END);
    mem_size = ftell(infile);
    rewind(infile);
    
    // Allocate memory buffer for the jpeg file.
    mem_buffer = (unsigned char*) malloc(mem_size + 100);

    int num_bytes = fread(mem_buffer, sizeof(unsigned char), mem_size, infile);

    // Initialize JPEG decompression cinfo object 
    jpeg_create_decompress(cinfo);
    
    // Replace jpeg_stdio_src(cinfo, infile) with jpeg_mem_src
    jpeg_mem_src(cinfo, mem_buffer, mem_size);

    // Save contents of markers 
    // jpeg_save_markers(cinfo, JPEG_COM, 0xFFFF);

    // Read header
    jpeg_read_header(cinfo, TRUE);

    // For some reason out_color_components isn't being set by
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
    
    return mem_buffer;
}


int _get_num_quant_tables(const j_decompress_ptr cinfo)
{
    int n;
    int num_tables = 0;
    
    // Count the number of tables.
    for (n = 0; n < NUM_QUANT_TBLS; n++)
    {
        if (cinfo->quant_tbl_ptrs[n] != NULL)
        {
            num_tables++;
        }
    }
    return num_tables;    
}

void _read_quant_tables(UINT16 tables[], const j_decompress_ptr cinfo)
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

void _get_size_dct_block(struct DctBlockArraySize* blkarr_size,
                         const j_decompress_ptr cinfo,
                         int ci)
{
    jpeg_component_info *compptr;

    compptr = cinfo->comp_info + ci;
    blkarr_size->nrows = compptr->height_in_blocks;
    blkarr_size->ncols = compptr->width_in_blocks;
}


void _read_coef_array(JCOEF* arr,
                      j_decompress_ptr cinfo,
                      jvirt_barray_ptr coef_array,
                      struct DctBlockArraySize blkarr_size)
{
    JBLOCKARRAY buffer;
    JCOEFPTR bufptr;
    JDIMENSION ir_blk, ic_blk;
    JDIMENSION ir_arr, ic_arr;
    int i, j;

    // Copy coefficients from virtual block arrays
    for (ir_blk = 0; ir_blk < blkarr_size.nrows; ir_blk++)
    {
        buffer = (cinfo->mem->access_virt_barray) ((j_common_ptr)cinfo, coef_array, ir_blk, 1, FALSE);
        for (ic_blk = 0; ic_blk < blkarr_size.ncols; ic_blk++)
        {
            bufptr = buffer[0][ic_blk];            
            ir_arr = DCTSIZE2*blkarr_size.ncols*ir_blk;
            
            // Read a single block of DCT coefficients
            for (i = 0; i < DCTSIZE; i++) // for each row in block
            {                
                ic_arr = DCTSIZE*ic_blk;
                for (j = 0; j < DCTSIZE; j++) // for each column in block
                {
                    *(arr + ir_arr + ic_arr) = bufptr[i*DCTSIZE + j];
                    ic_arr++;
                    
                }
                ir_arr += DCTSIZE*blkarr_size.ncols;
            }
        }
    }
}



void _read_coef_array_zigzag_dct_1d(JCOEF* arr,
                                    j_decompress_ptr cinfo,
                                    jvirt_barray_ptr coef_array,
                                    struct DctBlockArraySize blkarr_size)
{
    JBLOCKARRAY buffer;
    JCOEFPTR bufptr;
    JDIMENSION ir_blk, ic_blk;
    JDIMENSION ir_arr, ic_arr;
    int i, j;

    // Copy coefficients from virtual block arrays
    for (ir_blk = 0; ir_blk < blkarr_size.nrows; ir_blk++)
    {
        buffer = (cinfo->mem->access_virt_barray) ((j_common_ptr)cinfo, coef_array, ir_blk, 1, FALSE);
        for (ic_blk = 0; ic_blk < blkarr_size.ncols; ic_blk++)
        {
            bufptr = buffer[0][ic_blk];            
            ir_arr = DCTSIZE2*blkarr_size.ncols*ir_blk;
            ic_arr = DCTSIZE2*ic_blk;
            
            /*
            // Read a single block of DCT coefficients
            for (i = 0; i < DCTSIZE; i++) // for each row in block
            {                
                ic_arr = DCTSIZE*ic_blk;
                for (j = 0; j < DCTSIZE; j++) // for each column in block
                {
                    *(arr + ir_arr + ic_arr) = bufptr[i*DCTSIZE + j];
                    ic_arr++;
                    
                }
                ir_arr += DCTSIZE*blkarr_size.ncols;
            }
            */
            
            *(arr + ir_arr + ic_arr) = bufptr[0];  // [0, 0]
    
            *(arr + ir_arr + ic_arr + 1) = bufptr[1];  // [0, 1]
            *(arr + ir_arr + ic_arr + 2) = bufptr[DCTSIZE];  // [1, 0]
            
            *(arr + ir_arr + ic_arr + 3) = bufptr[2*DCTSIZE];  // [2, 0]
            *(arr + ir_arr + ic_arr + 4) = bufptr[DCTSIZE + 1];  // [1, 1]
            *(arr + ir_arr + ic_arr + 5) = bufptr[2];  // [0, 2]
            
            *(arr + ir_arr + ic_arr + 6) = bufptr[3];  // [0, 3]
            *(arr + ir_arr + ic_arr + 7) = bufptr[DCTSIZE + 2];  // [1, 2]
            *(arr + ir_arr + ic_arr + 8) = bufptr[2*DCTSIZE + 1];  // [2, 1]
            *(arr + ir_arr + ic_arr + 9) = bufptr[3*DCTSIZE]; // [3, 0]
            
            *(arr + ir_arr + ic_arr + 10) = bufptr[4*DCTSIZE];  // [4, 0]
            *(arr + ir_arr + ic_arr + 11) = bufptr[3*DCTSIZE + 1];  // [3, 1]
            *(arr + ir_arr + ic_arr + 12) = bufptr[2*DCTSIZE + 2];  // [2, 2]
            *(arr + ir_arr + ic_arr + 13) = bufptr[DCTSIZE + 3];  // [1, 3]
            *(arr + ir_arr + ic_arr + 14) = bufptr[4]; // [0, 4]
            
            *(arr + ir_arr + ic_arr + 15) = bufptr[5];  // [0, 5]
            *(arr + ir_arr + ic_arr + 16) = bufptr[DCTSIZE + 4];  // [1, 4]
            *(arr + ir_arr + ic_arr + 17) = bufptr[2*DCTSIZE + 3];  // [2, 3]
            *(arr + ir_arr + ic_arr + 18) = bufptr[3*DCTSIZE + 2];  // [3, 2]
            *(arr + ir_arr + ic_arr + 19) = bufptr[4*DCTSIZE + 1];  // [4, 1]
            *(arr + ir_arr + ic_arr + 20) = bufptr[5*DCTSIZE];  // [5, 0]
            
            *(arr + ir_arr + ic_arr + 21) = bufptr[6*DCTSIZE];  // [6, 0]
            *(arr + ir_arr + ic_arr + 22) = bufptr[5*DCTSIZE + 1];  // [5, 1]
            *(arr + ir_arr + ic_arr + 23) = bufptr[4*DCTSIZE + 2];  // [4, 2]
            *(arr + ir_arr + ic_arr + 24) = bufptr[3*DCTSIZE + 3];  // [3, 3]
            *(arr + ir_arr + ic_arr + 25) = bufptr[2*DCTSIZE + 4];  // [2, 4]
            *(arr + ir_arr + ic_arr + 26) = bufptr[DCTSIZE + 5];  // [1, 5]
            *(arr + ir_arr + ic_arr + 27) = bufptr[6];  // [0, 6]
            
            *(arr + ir_arr + ic_arr + 28) = bufptr[7];  // [0, 7]
            *(arr + ir_arr + ic_arr + 29) = bufptr[DCTSIZE + 6];  // [1, 6]
            *(arr + ir_arr + ic_arr + 30) = bufptr[2*DCTSIZE + 5];  // [2, 5]
            *(arr + ir_arr + ic_arr + 31) = bufptr[3*DCTSIZE + 4];  // [3, 4]
            *(arr + ir_arr + ic_arr + 32) = bufptr[4*DCTSIZE + 3];  // [4, 3]
            *(arr + ir_arr + ic_arr + 33) = bufptr[5*DCTSIZE + 2];  // [5, 2]
            *(arr + ir_arr + ic_arr + 34) = bufptr[6*DCTSIZE + 1];  // [6, 1]
            *(arr + ir_arr + ic_arr + 35) = bufptr[7*DCTSIZE];  // [7, 0]
            
            *(arr + ir_arr + ic_arr + 36) = bufptr[7*DCTSIZE + 1];  // [7, 1]
            *(arr + ir_arr + ic_arr + 37) = bufptr[6*DCTSIZE + 2];  // [6, 2]
            *(arr + ir_arr + ic_arr + 38) = bufptr[5*DCTSIZE + 3];  // [5, 3]
            *(arr + ir_arr + ic_arr + 39) = bufptr[4*DCTSIZE + 4];  // [4, 4]
            *(arr + ir_arr + ic_arr + 40) = bufptr[3*DCTSIZE + 5];  // [3, 5]
            *(arr + ir_arr + ic_arr + 41) = bufptr[2*DCTSIZE + 6];  // [2, 6]
            *(arr + ir_arr + ic_arr + 42) = bufptr[DCTSIZE + 7];  // [1, 7]
            
            *(arr + ir_arr + ic_arr + 43) = bufptr[2*DCTSIZE + 7];  // [2, 7]
            *(arr + ir_arr + ic_arr + 44) = bufptr[3*DCTSIZE + 6];  // [3, 6]
            *(arr + ir_arr + ic_arr + 45) = bufptr[4*DCTSIZE + 5];  // [4, 5]
            *(arr + ir_arr + ic_arr + 46) = bufptr[5*DCTSIZE + 4];  // [5, 4]
            *(arr + ir_arr + ic_arr + 47) = bufptr[6*DCTSIZE + 3];  // [6, 3]
            *(arr + ir_arr + ic_arr + 48) = bufptr[7*DCTSIZE + 2];  // [7, 2]
        
            *(arr + ir_arr + ic_arr + 49) = bufptr[7*DCTSIZE + 3];  // [7, 3]
            *(arr + ir_arr + ic_arr + 50) = bufptr[6*DCTSIZE + 4];  // [6, 4]
            *(arr + ir_arr + ic_arr + 51) = bufptr[5*DCTSIZE + 5];  // [5, 5]
            *(arr + ir_arr + ic_arr + 52) = bufptr[4*DCTSIZE + 6];  // [4, 6]
            *(arr + ir_arr + ic_arr + 53) = bufptr[3*DCTSIZE + 7];  // [3, 7]
        
            *(arr + ir_arr + ic_arr + 54) = bufptr[4*DCTSIZE + 7];  // [4, 7]
            *(arr + ir_arr + ic_arr + 55) = bufptr[5*DCTSIZE + 6];  // [5, 6]
            *(arr + ir_arr + ic_arr + 56) = bufptr[6*DCTSIZE + 5];  // [6, 5]
            *(arr + ir_arr + ic_arr + 57) = bufptr[7*DCTSIZE + 4];  // [7, 4]
            
            *(arr + ir_arr + ic_arr + 58) = bufptr[7*DCTSIZE + 5];  // [7, 5]
            *(arr + ir_arr + ic_arr + 59) = bufptr[6*DCTSIZE + 6];  // [6, 6]
            *(arr + ir_arr + ic_arr + 60) = bufptr[5*DCTSIZE + 7];  // [5, 7]
            
            *(arr + ir_arr + ic_arr + 61) = bufptr[6*DCTSIZE + 7];  // [6, 7]
            *(arr + ir_arr + ic_arr + 62) = bufptr[7*DCTSIZE + 6];  // [7, 6]
            
            *(arr + ir_arr + ic_arr + 63) = bufptr[7*DCTSIZE + 7];  // [7, 7]
            
            
            //ir_arr += DCTSIZE*blkarr_size.ncols;
        }
    }
}

void _dealloc_jpeg_decompress(j_decompress_ptr cinfo)
{
    jpeg_finish_decompress(cinfo);
    jpeg_destroy_decompress(cinfo);
    
}

void _dealloc_memory_buffer(unsigned char* mem_buffer)
{
    if (mem_buffer != NULL)
    {
        free(mem_buffer);
    }
}