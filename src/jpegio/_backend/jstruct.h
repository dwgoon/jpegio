    #ifndef JSTRUCT_H_
#define JSTRUCT_H_

#include <vector>
#include <string>
#include "mat2D.h"
extern "C"
{
#include "jpeglib.h"
//#include "jmorecfg.h"
}

namespace jpegio {


    struct struct_huff_tables {
        std::vector<int> counts;
        std::vector<int> symbols;
    };

    struct struct_comp_info {
        int component_id;
        int h_samp_factor;
        int v_samp_factor;
        int quant_tbl_no;
        int dc_tbl_no;
        int ac_tbl_no;
        JDIMENSION downsampled_height;
        JDIMENSION downsampled_width;
        JDIMENSION height_in_blocks;
        JDIMENSION width_in_blocks;
    };

    // A JPEG marker with its marker code (e.g. JPEG_COM=0xFE, JPEG_APP0..15 =
    // 0xE0..0xEF) and raw payload bytes.
    struct struct_marker {
        int marker;
        std::string data;
    };


    class jstruct
    {
    public:
        bool load_spatial;

        unsigned int image_width;
        unsigned int image_height;
        int image_components;
        unsigned int image_color_space;
        int num_components;
        unsigned int jpeg_color_space;
        unsigned char progressive_mode;
        unsigned char optimize_coding;

        // Additional frame/coding properties (read on load, honoured on write
        // where meaningful).
        int data_precision;             // bits per sample (8, 12, ...)
        unsigned int restart_interval;  // MCUs between restart markers (DRI)
        unsigned char arith_code;       // arithmetic (1) vs Huffman (0) coding
        unsigned char saw_jfif_marker;
        unsigned char jfif_major_version;
        unsigned char jfif_minor_version;
        unsigned char density_unit;     // 0=none, 1=dots/inch, 2=dots/cm
        unsigned int x_density;
        unsigned int y_density;
        unsigned char saw_adobe_marker;
        unsigned char adobe_transform;
        int max_h_samp_factor;
        int max_v_samp_factor;

        // All markers (APP0..APP15 and COM) in file order, length-preserving
        // and binary-safe.
        std::vector<struct_marker> markers;
        std::vector<mat2D<int> *> coef_arrays;
        std::vector<mat2D<int> *> spatial_arrays;
        std::vector<mat2D<int> *> quant_tables;
        std::vector<struct_huff_tables *> ac_huff_tables;
        std::vector<struct_huff_tables *> dc_huff_tables;
        std::vector<struct_comp_info *> comp_info;

        // Original libjpeg table slot (0..3) for each entry above, so tables
        // that use sparse/non-contiguous slot numbers round-trip correctly.
        std::vector<int> quant_tbl_slots;
        std::vector<int> ac_huff_tbl_slots;
        std::vector<int> dc_huff_tbl_slots;

        jstruct() {}
        jstruct(std::string file_path);
        jstruct(std::string file_path, bool load_spatial);
        ~jstruct();

        void jpeg_write(std::string file_path, bool optimize_coding);
        void jpeg_load(std::string file_path);
        void spatial_load(std::string file_path);

    };

}
#endif
