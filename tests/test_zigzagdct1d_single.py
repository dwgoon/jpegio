# -*- coding: utf-8 -*-
import numpy as np
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

fpath = "images/test05.jpg"
jpeg_de = jpegio.read(fpath, jpegio.DECOMPRESSED)
jpeg_zz = jpegio.read(fpath, jpegio.ZIGZAG_DCT_1D)


c = 0            
arr_de = jpeg_de.coef_arrays[c]
nrows_blk, ncols_blk = jpeg_de.get_coef_block_array_shape(c)
arr_de = arr_de.reshape(nrows_blk, BS, ncols_blk, BS)
arr_de = arr_de.transpose(0, 2, 1, 3)
arr_de = arr_de.reshape(nrows_blk*ncols_blk, BS, BS)

arr_zz = jpeg_zz.coef_arrays[c].reshape(nrows_blk*ncols_blk, BS*BS)

for i in range(arr_de.shape[0]):
    zz_de = get_arr_zigzag(arr_de[i])
    #print(np.array_equal(zz_de, arr_zz[i]))