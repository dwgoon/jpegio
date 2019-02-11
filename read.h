#pragma once

#include "jpeglib.h"
#include "dctarraysize.h"

int _read_jpeg_decompress_struct(FILE* infile,
                                 struct jpeg_decompress_struct* cinfo);

void _get_quant_tables(UINT16 tables[],
                       const struct jpeg_decompress_struct* cinfo);

void _get_dct_array_size(int ci,
                         struct DctArraySize* arr_size,
                         const struct jpeg_decompress_struct* cinfo);
                         
void _get_dct_coefficients(JCOEF arr[],
                           struct jpeg_decompress_struct* cinfo);