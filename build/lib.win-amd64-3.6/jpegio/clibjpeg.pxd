
cdef extern from "jpeglib.h":      

    cdef const int DCTSIZE          = 8   # The basic DCT block is 8x8 coefficients
    cdef const int DCTSIZE2         = 64  # DCTSIZE squared; # of elements in a block
    cdef const int NUM_QUANT_TBLS   = 4   # Quantization tables are numbered 0..3
    cdef const int NUM_HUFF_TBLS    = 4   # Huffman tables are numbered 0..3
    cdef const int NUM_ARITH_TBLS   = 16  # Arith-coding tables are numbered 0..15


    cdef struct jpeg_decompress_struct:
        int num_components
        pass    

cdef extern from "jmorecfg.h":
    ctypedef unsigned short UINT16
    ctypedef unsigned int JDIMENSION
    ctypedef short JCOEF
