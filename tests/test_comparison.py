
import glob
import unittest
from os.path import join as pjoin

import numpy as np
import scipy.io as spio


class ComparisionTest(unittest.TestCase):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        self.list_fpaths = []
        self.extensions = ['*.jpg', '*.jpeg']
        
        for ext in self.extensions:
            for fpath in glob.glob(pjoin('images', ext)):
                self.list_fpaths.append(fpath)
        
    def test_compare_dct_coef(self):
        pass

if __name__ == "__main__":
    unittest.main()
    
