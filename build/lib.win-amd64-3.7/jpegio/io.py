# -*- coding: utf-8 -*-

import jpegio

def read(fpath):
    """Read JPEG file and return DecompressedJpeg object.
    """
    obj = jpegio.DecompressedJpeg()  
    obj.read(fpath)
    return obj
