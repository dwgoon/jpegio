# cython: language_level=3, boundscheck=False

from libc.stdlib cimport malloc, free

cimport clibjpeg
from clibjpeg cimport jpeg_decompress_struct

cdef class JpegDecompress:

    def __init__(self):
        pass

    def __cinit__(self):
        self._obj = <jpeg_decompress_struct*> malloc(sizeof(jpeg_decompress_struct))
        if self._obj is NULL:
            raise MemoryError()
        
    def __dealloc__(self):
        if self._obj:
            free(self._obj)