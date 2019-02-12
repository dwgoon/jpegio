#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include "jpeglib.h"
#include "jerror.h"

#include "dctblockarraysize.h"

/* We need to create our own error handler so that we can override the 
 * default handler in case a fatal error occurs.  The standard error_exit
 * method calls exit() which doesn't clean things up properly and also 
 * exits Matlab.  This is described in the example.c routine provided in
 * the IJG's code library.
 */
struct my_error_mgr {
  struct jpeg_error_mgr pub;	/* "public" fields */
  jmp_buf setjmp_buffer;	/* for return to caller */
};


int _read_jpeg_decompress_struct(FILE* infile,
                                 struct jpeg_decompress_struct* cinfo,
                                 struct my_error_mgr* jerr);

void _get_quant_tables(UINT16 tables[],
                       const struct jpeg_decompress_struct* cinfo);

//void _get_size_dct_array(int ci,
//                         struct DctArraySize* arr_size,
//                         const struct jpeg_decompress_struct* cinfo);
    
void _get_size_dct_block(int ci,
                         struct DctBlockArraySize* arr_size,
                         const struct jpeg_decompress_struct* cinfo);    
                         
void _get_dct_coefficients(JCOEF arr[],
                           struct jpeg_decompress_struct* cinfo);