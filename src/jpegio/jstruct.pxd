from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp cimport bool

from jpegio.clibjpeg cimport JDIMENSION

cdef extern from "mat2D.h" namespace "jpegio":
    cdef cppclass mat2D[T]:
        int rows
        int cols
        T* GetBuffer()


ctypedef mat2D[int]* ptr_mat2D


cdef extern from "jstruct.h" namespace "jpegio":
    cdef struct struct_huff_tables:
        vector[int] counts
        vector[int] symbols


    cdef struct struct_comp_info:
        int component_id
        int h_samp_factor
        int v_samp_factor
        int quant_tbl_no
        int dc_tbl_no
        int ac_tbl_no
        JDIMENSION downsampled_height
        JDIMENSION downsampled_width
        JDIMENSION height_in_blocks
        JDIMENSION width_in_blocks

    cdef struct struct_marker:
        int marker
        string data

ctypedef struct_huff_tables* ptr_struct_ht
ctypedef struct_comp_info* ptr_struct_ci


cdef extern from "jstruct.h" namespace "jpegio":

    cdef cppclass jstruct:
        jstruct() except +
        jstruct(string file_path) except +
        jstruct(string file_path, bool load_spatial) except +

        bool load_spatial
        unsigned int image_width
        unsigned int image_height
        int image_components
        unsigned int image_color_space
        int num_components
        unsigned int jpeg_color_space
        unsigned char optimize_coding
        unsigned char progressive_mode

        int data_precision
        unsigned int restart_interval
        unsigned char arith_code
        unsigned char saw_jfif_marker
        unsigned char jfif_major_version
        unsigned char jfif_minor_version
        unsigned char density_unit
        unsigned int x_density
        unsigned int y_density
        unsigned char saw_adobe_marker
        unsigned char adobe_transform
        int max_h_samp_factor
        int max_v_samp_factor

        vector[ptr_struct_ci] comp_info
        vector[struct_marker] markers
        vector[ptr_mat2D] coef_arrays
        vector[ptr_mat2D] spatial_arrays
        vector[ptr_mat2D] quant_tables
        vector[ptr_struct_ht] ac_huff_tables
        vector[ptr_struct_ht] dc_huff_tables

        void jpeg_load(string file_path) except +
        void spatial_load(string file_path) except +
        void jpeg_write(string file_path, bool optimize_coding) except +



