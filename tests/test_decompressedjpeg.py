
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
        
    def test_repeat_read_1000(self):
        """=> Check memory errors and garbage collection.
        """
        for i in range(1000):
            fpath = random.choice(self.list_fpaths)
            jpeg = jpegio.read(fpath)
            del jpeg
                
    def test_compare_dct_coef(self):
        """=> Test reading DCT coefficients.
        """
        for fpath in self.list_fpaths:
            fname = os.path.basename(fpath)
            dpath_mat = apath(pjoin(os.path.dirname(fpath),
                                    os.path.pardir,
                                    'matlab_outputs'))
            fpath_mat = pjoin(dpath_mat, 'coef_arrays'+fname+'.mat')
            if not os.path.isfile(fpath_mat):
                continue

            mat = spio.loadmat(fpath_mat)
            coef_arrays_mat = mat['coef_arrays'][0]
            jpeg = jpegio.read(fpath)
            for i in range(len(jpeg.coef_arrays)):
                self.assertEqual(coef_arrays_mat[i].dtype,
                                 jpeg.coef_arrays[i].dtype)
                res = np.array_equal(jpeg.coef_arrays[i],
                                     coef_arrays_mat[i])
                self.assertTrue(res)

    def test_compare_coef_block_array_shape(self):
        """=> Test getting DCT block array shape.
        """        
        for fpath in self.list_fpaths:
            jpeg = jpegio.read(fpath)
            
            for c in range(len(jpeg.coef_arrays)):
                coef_arr = jpeg.coef_arrays[c]
                blk_shape = jpeg.get_coef_block_array_shape(c)
                self.assertTrue(int(coef_arr.shape[0]/BS) == blk_shape[0])
                self.assertTrue(int(coef_arr.shape[1]/BS) == blk_shape[1])

    def test_compare_coef_block(self):
        """=> Test getting DCT block array.
        """        
        for fpath in self.list_fpaths:
            jpeg = jpegio.read(fpath)
            
            for c in range(len(jpeg.coef_arrays)):
                coef_arr = jpeg.coef_arrays[c]
                nrows_blk, ncols_blk = jpeg.get_coef_block_array_shape(c)
                for i in range(nrows_blk):
                    for j in range(ncols_blk):
                        coef_blk = jpeg.get_coef_block(c, i, j)
                        self.assertTrue(np.array_equal(coef_arr[BS*i:BS*(i+1), BS*j:BS*(j+1)], coef_blk))
                    # end of for
                # end of for
            # end of for
        # end of for

    def test_are_channel_sizes_same(self):
        """=> Test deciding sizes of all channels are identical.
        """        
        # False cases
        jpeg = jpegio.read(pjoin('images', 'arborgreens01.jpg'))
        self.assertFalse(jpeg.are_channel_sizes_same())
        
        jpeg = jpegio.read(pjoin('images', 'cherries01.jpg'))
        self.assertFalse(jpeg.are_channel_sizes_same())
        
        jpeg = jpegio.read(pjoin('images', 'football01.jpg'))
        self.assertFalse(jpeg.are_channel_sizes_same())
        
        jpeg = jpegio.read(pjoin('images', 'greenlake01.jpg'))
        self.assertFalse(jpeg.are_channel_sizes_same())
        
        # True cases
        jpeg = jpegio.read(pjoin('images', 'test01.jpg'))
        self.assertTrue(jpeg.are_channel_sizes_same())
        
        jpeg = jpegio.read(pjoin('images', 'test02.jpg'))
        self.assertTrue(jpeg.are_channel_sizes_same())
        
        jpeg = jpegio.read(pjoin('images', 'test03.jpg'))
        self.assertTrue(jpeg.are_channel_sizes_same())
        
        jpeg = jpegio.read(pjoin('images', 'test04.jpg'))
        self.assertTrue(jpeg.are_channel_sizes_same())
        
        jpeg = jpegio.read(pjoin('images', 'test05.jpg'))
        self.assertTrue(jpeg.are_channel_sizes_same())
        
    def test_compare_count_nnz_ac(self):
        """=> Test counting non-zero DCT AC coefficients.
        """
        for fpath in self.list_fpaths:
            fname = os.path.basename(fpath)
            dpath_mat = apath(pjoin(os.path.dirname(fpath),
                                    os.path.pardir,
                                    'matlab_outputs'))
            fpath_mat = pjoin(dpath_mat, 'nnz_'+fname+'.mat')
            if not os.path.isfile(fpath_mat):
                continue

            mat = spio.loadmat(fpath_mat)
            nnz_ac_mat = mat['nnz_ac'][0]
            
            jpeg = jpegio.read(fpath)
            nnz_ac_jpegio = jpeg.count_nnz_ac()                
            
            self.assertTrue(nnz_ac_mat == nnz_ac_jpegio)
        # end of for
    # end of def
    
if __name__ == "__main__":
    unittest.main()
    
