cimport numpy as cnp
from jstruct cimport jstruct


# Owns one read()'s jstruct and deletes it in __dealloc__. Every NumPy array
# handed out by a read() is based on the _JstructOwner of that read (not on the
# DecompressedJpeg), so the specific jstruct backing an array stays alive as long
# as that array does -- even across a later re-read() into the same object or
# after the DecompressedJpeg itself is dropped. Mirrors the C-API PyCapsule owner.
cdef class _JstructOwner:
    cdef jstruct* ptr


cdef class DecompressedJpeg:

    cdef public list comp_info
    cdef public list quant_tables
    cdef public list coef_arrays
    cdef public list spatial_arrays
    cdef public list ac_huff_tables
    cdef public list dc_huff_tables
    cdef public list markers

    cdef jstruct* _jstruct_obj   # borrowed pointer into _owner.ptr
    cdef _JstructOwner _owner    # owns the current read()'s jstruct

    cdef _read_comp_info(self)
    cdef _read_markers(self)
    cdef _read_quant_tables(self)
    cdef _read_huffman_tables(self)
    cdef _read_dct_coefficients(self)
    cdef _read_spatial_arrays(self)

    cdef _write_markers(self)
    cdef _write_comp_info(self)

    cpdef public read(self, fpath, bint read_spatial=*)
    cpdef public write(self, fpath)
    cpdef get_coef_block(self, c, i, j)
    cpdef get_coef_block_array_shape(self, c)
    cpdef are_channel_sizes_same(self)
    cpdef count_nnz_ac(self)


    cdef _is_valid_fpath(self, fpath)

