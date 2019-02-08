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
            
    cpdef read(self, fname):
        cdef bytes py_bytes = fname.encode()
        cdef char* c_string = py_bytes
        print(c_string)
        cdef int res
        res = clibjpeg.read_jpeg_decompress_struct(c_string, self._obj)
        
    def __dealloc__(self):
        if self._obj:
            free(self._obj)