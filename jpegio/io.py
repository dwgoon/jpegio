import jpegio

def read(fpath, flag=jpegio.DECOMPRESSED):
    """Read JPEG from file path.
    """
    if flag is jpegio.DECOMPRESSED: 
        obj = jpegio.DecompressedJpeg()  
        obj.read(fpath)
    elif flag == jpegio.ZIGZAG_DCT_1D:
        raise ValueError("ZIGZAG_DCT_1D: not supported yet")

    return obj


def write(obj, fpath, flag=jpegio.DECOMPRESSED):
    """Write JPEG object to file path.
    """
    if flag is jpegio.DECOMPRESSED:
        obj.write(fpath)
    elif flag == jpegio.ZIGZAG_DCT_1D:
        raise ValueError("ZIGZAG_DCT_1D: not supported yet")

    return obj