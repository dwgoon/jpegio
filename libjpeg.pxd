
#cimport clibjpeg
from clibjpeg cimport jpeg_decompress_struct

cdef class JpegDecompress:
    cdef jpeg_decompress_struct* _obj
