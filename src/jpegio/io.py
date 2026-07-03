import jpegio


def read(fpath, flag=jpegio.DECOMPRESSED, read_spatial=False):
    """Read a JPEG file and return its decoded representation.

    Parameters
    ----------
    fpath : str or os.PathLike
        Path to the JPEG file.
    flag : jpegio.Flag, optional
        Which representation to build. Only ``DECOMPRESSED`` is supported.
    read_spatial : bool, optional
        Also decode the pixel-domain image into ``spatial_arrays``.
    """
    if flag == jpegio.DECOMPRESSED:
        obj = jpegio.DecompressedJpeg()
        obj.read(fpath, read_spatial=read_spatial)
        return obj
    elif flag == jpegio.ZIGZAG_DCT_1D:
        raise ValueError("ZIGZAG_DCT_1D: not supported yet")
    else:
        raise ValueError("Unknown flag: %r" % (flag,))


def write(obj, fpath, flag=jpegio.DECOMPRESSED):
    """Write a JPEG object to a file path."""
    if flag == jpegio.DECOMPRESSED:
        obj.write(fpath)
        return obj
    elif flag == jpegio.ZIGZAG_DCT_1D:
        raise ValueError("ZIGZAG_DCT_1D: not supported yet")
    else:
        raise ValueError("Unknown flag: %r" % (flag,))
