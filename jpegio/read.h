#pragma once

#include "jpeglib.h"
#include "dctblockarraysize.h"

int _read_jpeg_decompress_struct(FILE* infile,
                                 struct jpeg_decompress_struct* cinfo);

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