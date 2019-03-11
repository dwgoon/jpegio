
import glob
import unittest

from os.path import join as pjoin
from os.path import abspath as apath

import time

import numpy as np
import scipy.io as spio

import jpegio

BS = 8  # DCT block size



def get_arr_zigzag(arr):
    zz = np.zeros((BS*BS), dtype=np.int16)
    
    zz[0] = arr[0, 0]
    
    zz[1] = arr[0, 1]
    zz[2] = arr[1, 0]
    
    zz[3] = arr[2, 0]
    zz[4] = arr[1, 1]
    zz[5] = arr[0, 2]
    
    zz[6] = arr[0, 3]
    zz[7] = arr[1, 2]
    zz[8] = arr[2, 1]
    zz[9] = arr[3, 0]
    
    zz[10] = arr[4, 0]
    zz[11] = arr[3, 1]
    zz[12] = arr[2, 2]
    zz[13] = arr[1, 3]
    zz[14] = arr[0, 4]
    
    zz[15] = arr[0, 5]
    zz[16] = arr[1, 4]
    zz[17] = arr[2, 3]
    zz[18] = arr[3, 2]
    zz[19] = arr[4, 1]
    zz[20] = arr[5, 0]
    
    zz[21] = arr[6, 0]
    zz[22] = arr[5, 1]
    zz[23] = arr[4, 2]
    zz[24] = arr[3, 3]
    zz[25] = arr[2, 4]
    zz[26] = arr[1, 5]
    zz[27] = arr[0, 6]
    
    zz[28] = arr[0, 7]
    zz[29] = arr[1, 6]
    zz[30] = arr[2, 5]
    zz[31] = arr[3, 4]
    zz[32] = arr[4, 3]
    zz[33] = arr[5, 2]
    zz[34] = arr[6, 1]
    zz[35] = arr[7, 0]
    
    zz[36] = arr[7, 1]
    zz[37] = arr[6, 2]
    zz[38] = arr[5, 3]
    zz[39] = arr[4, 4]
    zz[40] = arr[3, 5]
    zz[41] = arr[2, 6]
    zz[42] = arr[1, 7]
    
    zz[43] = arr[2, 7]
    zz[44] = arr[3, 6]
    zz[45] = arr[4, 5]
    zz[46] = arr[5, 4]
    zz[47] = arr[6, 3]
    zz[48] = arr[7, 2]

    zz[49] = arr[7, 3]
    zz[50] = arr[6, 4]
    zz[51] = arr[5, 5]
    zz[52] = arr[4, 6]
    zz[53] = arr[3, 7]

    zz[54] = arr[4, 7]
    zz[55] = arr[5, 6]
    zz[56] = arr[6, 5]
    zz[57] = arr[7, 4]
    
    zz[58] = arr[7, 5]
    zz[59] = arr[6, 6]
    zz[60] = arr[5, 7]
    
    zz[61] = arr[6, 7]
    zz[62] = arr[7, 6]
    
    zz[63] = arr[7, 7]
    return zz


class ZigzagDct1dTest(unittest.TestCase):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        self.list_fpaths = []
        self.extensions = ['*.jpg', '*.jpeg']
        
        for ext in self.extensions:
            for fpath in glob.glob(pjoin('images', ext)):
                self.list_fpaths.append(fpath)
    
    def test_compare_coef_with_decompressedjpeg(self):
        """=> Compare DCT coef between ZigzagDct1d and DecompressedJpeg.
        """        
        for fpath in self.list_fpaths:
            time_beg_zz = time.time()
            jpeg_zz = jpegio.read(fpath, jpegio.ZIGZAG_DCT_1D)
            list_coef_zz = []
            for c in range(jpeg_zz.num_components):                
                nrows_blk, ncols_blk = jpeg_zz.get_coef_block_array_shape(c)
            
                arr_zz = jpeg_zz.coef_arrays[c].reshape(nrows_blk*ncols_blk,
                                                        BS*BS)
                list_coef_zz.append(arr_zz)
            # end of for
            time_elapsed_zz = time.time() - time_beg_zz
            
            time_beg_de = time.time()
            jpeg_de = jpegio.read(fpath, jpegio.DECOMPRESSED)
            list_coef_de = []
            for c in range(jpeg_de.num_components):
                arr_de = jpeg_de.coef_arrays[c]
                nrows_blk, ncols_blk = jpeg_de.get_coef_block_array_shape(c)
                arr_de = arr_de.reshape(nrows_blk, BS, ncols_blk, BS)
                arr_de = arr_de.transpose(0, 2, 1, 3)
                arr_de = arr_de.reshape(nrows_blk*ncols_blk, BS, BS)
                
                zz_de = np.zeros((nrows_blk, ncols_blk, BS*BS),
                                 dtype=np.int16)
                for i in range(arr_de.shape[0]):
                    #zz_de[i] = get_arr_zigzag(arr_de[i])
                    zz_de[i][0] = arr_de[i][0, 0]
                    
                    zz_de[i][1] = arr_de[i][0, 1]
                    zz_de[i][2] = arr_de[i][1, 0]
                    
                    zz_de[i][3] = arr_de[i][2, 0]
                    zz_de[i][4] = arr_de[i][1, 1]
                    zz_de[i][5] = arr_de[i][0, 2]
                    
                    zz_de[i][6] = arr_de[i][0, 3]
                    zz_de[i][7] = arr_de[i][1, 2]
                    zz_de[i][8] = arr_de[i][2, 1]
                    zz_de[i][9] = arr_de[i][3, 0]
                    
                    zz_de[i][10] = arr_de[i][4, 0]
                    zz_de[i][11] = arr_de[i][3, 1]
                    zz_de[i][12] = arr_de[i][2, 2]
                    zz_de[i][13] = arr_de[i][1, 3]
                    zz_de[i][14] = arr_de[i][0, 4]
                    
                    zz_de[i][15] = arr_de[i][0, 5]
                    zz_de[i][16] = arr_de[i][1, 4]
                    zz_de[i][17] = arr_de[i][2, 3]
                    zz_de[i][18] = arr_de[i][3, 2]
                    zz_de[i][19] = arr_de[i][4, 1]
                    zz_de[i][20] = arr_de[i][5, 0]
                    
                    zz_de[i][21] = arr_de[i][6, 0]
                    zz_de[i][22] = arr_de[i][5, 1]
                    zz_de[i][23] = arr_de[i][4, 2]
                    zz_de[i][24] = arr_de[i][3, 3]
                    zz_de[i][25] = arr_de[i][2, 4]
                    zz_de[i][26] = arr_de[i][1, 5]
                    zz_de[i][27] = arr_de[i][0, 6]
                    
                    zz_de[i][28] = arr_de[i][0, 7]
                    zz_de[i][29] = arr_de[i][1, 6]
                    zz_de[i][30] = arr_de[i][2, 5]
                    zz_de[i][31] = arr_de[i][3, 4]
                    zz_de[i][32] = arr_de[i][4, 3]
                    zz_de[i][33] = arr_de[i][5, 2]
                    zz_de[i][34] = arr_de[i][6, 1]
                    zz_de[i][35] = arr_de[i][7, 0]
                    
                    zz_de[i][36] = arr_de[i][7, 1]
                    zz_de[i][37] = arr_de[i][6, 2]
                    zz_de[i][38] = arr_de[i][5, 3]
                    zz_de[i][39] = arr_de[i][4, 4]
                    zz_de[i][40] = arr_de[i][3, 5]
                    zz_de[i][41] = arr_de[i][2, 6]
                    zz_de[i][42] = arr_de[i][1, 7]
                    
                    zz_de[i][43] = arr_de[i][2, 7]
                    zz_de[i][44] = arr_de[i][3, 6]
                    zz_de[i][45] = arr_de[i][4, 5]
                    zz_de[i][46] = arr_de[i][5, 4]
                    zz_de[i][47] = arr_de[i][6, 3]
                    zz_de[i][48] = arr_de[i][7, 2]
                
                    zz_de[i][49] = arr_de[i][7, 3]
                    zz_de[i][50] = arr_de[i][6, 4]
                    zz_de[i][51] = arr_de[i][5, 5]
                    zz_de[i][52] = arr_de[i][4, 6]
                    zz_de[i][53] = arr_de[i][3, 7]
                
                    zz_de[i][54] = arr_de[i][4, 7]
                    zz_de[i][55] = arr_de[i][5, 6]
                    zz_de[i][56] = arr_de[i][6, 5]
                    zz_de[i][57] = arr_de[i][7, 4]
                    
                    zz_de[i][58] = arr_de[i][7, 5]
                    zz_de[i][59] = arr_de[i][6, 6]
                    zz_de[i][60] = arr_de[i][5, 7]
                    
                    zz_de[i][61] = arr_de[i][6, 7]
                    zz_de[i][62] = arr_de[i][7, 6]
                    
                    zz_de[i][63] = arr_de[i][7, 7]
                # end of for
                list_coef_de.append(zz_de)
                    

            # end of for            
            time_elapsed_de = time.time() - time_beg_de
            print("[Time] zz: %f, de: %f"%(time_elapsed_zz, time_elapsed_de))
            self.assertTrue(time_elapsed_zz <= time_elapsed_de)
        # end of for
    # end of def

    def test_performance_load_dct_block(self):
        """=> Test the performance of loading zigzag DCT coef.
        """        
        for fpath in self.list_fpaths:
            jpeg_de = jpegio.read(fpath, jpegio.DECOMPRESSED)
            jpeg_zz = jpegio.read(fpath, jpegio.ZIGZAG_DCT_1D)
            
            for c in range(jpeg_de.num_components):
                arr_de = jpeg_de.coef_arrays[c]
                nrows_blk, ncols_blk = jpeg_de.get_coef_block_array_shape(c)
                arr_de = arr_de.reshape(nrows_blk, BS, ncols_blk, BS)
                arr_de = arr_de.transpose(0, 2, 1, 3)
                arr_de = arr_de.reshape(nrows_blk*ncols_blk, BS, BS)
                        
                arr_zz = jpeg_zz.coef_arrays[c].reshape(nrows_blk*ncols_blk,
                                                        BS*BS)

                for i in range(arr_de.shape[0]):
                    zz_de = get_arr_zigzag(arr_de[i])
                    self.assertTrue(np.array_equal(zz_de, arr_zz[i]))                  

            # end of for
        # end of for
    # end of def


if __name__ == "__main__":
    unittest.main()
    
