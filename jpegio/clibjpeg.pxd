
cdef extern from "jpeglib.h":    

    ctypedef unsigned int JDIMENSION
    cdef const int DCTSIZE          = 8   # The basic DCT block is 8x8 coefficients
    cdef const int DCTSIZE2         = 64  # DCTSIZE squared; # of elements in a block
