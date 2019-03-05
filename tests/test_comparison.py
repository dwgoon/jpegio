
import glob
import unittest
import os
from os.path import join as pjoin
from os.path import abspath as apath
import random

import numpy as np
import scipy.io as spio

import jpegio

BS = 8  # DCT block size

class ComparisionTest(unittest.TestCase):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        self.list_fpaths = []
        self.extensions = ['*.jpg', '*.jpeg']
        
        for ext in self.extensions:
            for fpath in glob.glob(pjoin('images', ext)):
                self.list_fpaths.append(fpath)
        
    def test_repeat_read(self):
        for i in range(1000):
            fpath = random.choice(self.list_fpaths)
            jpeg = jpegio.read(fpath)
                
    def test_compare_dct_coef(self):
        for fpath in self.list_fpaths:
            fname = os.path.basename(fpath)
            dpath_mat = apath(pjoin(os.path.dirname(fpath),
                                    os.path.pardir,
                                    'matlab_outputs'))
            fpath_mat = pjoin(dpath_mat, fname+'.mat')
            mat = spio.loadmat(fpath_mat)
            coef_arrays_mat = mat['coef_arrays'][0]
            jpeg = jpegio.read(fpath)
            for i in range(len(jpeg.coef_arrays)):
                self.assertEqual(coef_arrays_mat[i].dtype,
                                 jpeg.coef_arrays[i].dtype)
                res = np.array_equal(jpeg.coef_arrays[i],
                                     coef_arrays_mat[i])
                self.assertTrue(res)

    def test_compare_coef_block_shape(self):
        for fpath in self.list_fpaths:
            jpeg = jpegio.read(fpath)
            
            for c in range(len(jpeg.coef_arrays)):
                coef_arr = jpeg.coef_arrays[c]
                blk_shape = jpeg.get_coef_block_shape(c)
                self.assertTrue(int(coef_arr.shape[0]/BS) == blk_shape[0])
                self.assertTrue(int(coef_arr.shape[1]/BS) == blk_shape[1])

    def test_compare_coef_block(self):
<<<<<<< HEAD
=======
        
>>>>>>> d4e87c55a0914fb3f1ff54a44463cc177aa79ef7
        for fpath in self.list_fpaths:
            jpeg = jpegio.read(fpath)
            
            for c in range(len(jpeg.coef_arrays)):
                coef_arr = jpeg.coef_arrays[c]
                nrows_blk, ncols_blk = jpeg.get_coef_block_shape(c)
                for i in range(nrows_blk):
                    for j in range(ncols_blk):
                        coef_blk = jpeg.get_coef_block(c, i, j)
                        self.assertTrue(np.array_equal(coef_arr[BS*i:BS*(i+1), BS*j:BS*(j+1)], coef_blk))
                    # end of for
                # end of for
            # end of for
        # end of for


if __name__ == "__main__":
    unittest.main()
    
