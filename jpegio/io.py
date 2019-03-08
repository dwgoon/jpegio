# -*- coding: utf-8 -*-

import jpegio

def read(fpath, flag=None, **kwargs):
    """Read JPEG file and return the object of ctype.
    """
    if not flag or flag is jpegio.DECOMPRESSED: 
        obj = jpegio.DecompressedJpeg()  
        obj.read(fpath)
    elif flag == jpegio.ZIGZAG_DCT_1D:
        obj = jpegio.ZigzagDct1d()
        obj.read(**kwargs)
    
    return obj
