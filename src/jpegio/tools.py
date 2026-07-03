"""Helper tools for JPEG steganography and steganalysis.

These operate on the ``coef_arrays`` / ``markers`` of a ``DecompressedJpeg`` and
work identically with either binding backend.
"""
import numpy as np

__all__ = [
    "JPEG_NATURAL_ORDER", "zigzag_order", "to_zigzag", "from_zigzag",
    "blocks_view", "coefficients_zigzag",
    "dct_histogram", "nnz_ac_per_component", "embedding_capacity",
    "get_coefficient", "set_coefficient",
    "MARKER_COM", "MARKER_APP0", "com_markers", "app_markers",
]

# Marker codes.
MARKER_COM = 0xFE
MARKER_APP0 = 0xE0  # APP0..APP15 are 0xE0..0xEF

# zigzag_order()[i] is the raster (natural) index of the i-th coefficient in
# the JPEG zigzag scan order.
JPEG_NATURAL_ORDER = np.array([
     0,  1,  8, 16,  9,  2,  3, 10,
    17, 24, 32, 25, 18, 11,  4,  5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13,  6,  7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63,
], dtype=np.intp)


def zigzag_order():
    """Return the 64-element JPEG zigzag-to-raster index map (a copy)."""
    return JPEG_NATURAL_ORDER.copy()


def to_zigzag(block):
    """Reorder the last two (8, 8) axes of ``block`` into a length-64 zigzag axis."""
    b = np.asarray(block)
    flat = b.reshape(b.shape[:-2] + (64,))
    return flat[..., JPEG_NATURAL_ORDER]


def from_zigzag(vec):
    """Inverse of :func:`to_zigzag`: a length-64 last axis back to (8, 8)."""
    v = np.asarray(vec)
    out = np.empty(v.shape[:-1] + (64,), dtype=v.dtype)
    out[..., JPEG_NATURAL_ORDER] = v
    return out.reshape(v.shape[:-1] + (8, 8))


def blocks_view(coef_array):
    """View an ``(H*8, W*8)`` coefficient array as ``(H, W, 8, 8)`` blocks."""
    a = np.asarray(coef_array)
    hb, wb = a.shape[0] // 8, a.shape[1] // 8
    return a.reshape(hb, 8, wb, 8).transpose(0, 2, 1, 3)


def coefficients_zigzag(coef_array):
    """``(H*8, W*8)`` coefficient array -> ``(H, W, 64)`` zigzag-ordered blocks."""
    return to_zigzag(blocks_view(coef_array))


def dct_histogram(coef_array, mode=None):
    """Histogram of DCT coefficient values.

    ``mode`` selects the coefficients: ``None`` uses all, an int ``0..63`` picks
    a zigzag frequency mode, and a ``(u, v)`` tuple picks a raster mode.
    Returns ``(values, counts)`` (both 1-D arrays), as from ``numpy.unique``.
    """
    a = np.asarray(coef_array)
    if mode is None:
        data = a.ravel()
    elif isinstance(mode, tuple):
        u, v = mode
        data = blocks_view(a)[:, :, u, v].ravel()
    else:
        data = coefficients_zigzag(a)[:, :, mode].ravel()
    values, counts = np.unique(data, return_counts=True)
    return values, counts


def nnz_ac_per_component(jpeg):
    """Number of non-zero AC coefficients per component (a list of ints)."""
    out = []
    for coef in jpeg.coef_arrays:
        out.append(int(np.count_nonzero(coef)
                       - np.count_nonzero(coef[0::8, 0::8])))
    return out


def embedding_capacity(jpeg):
    """Total non-zero AC coefficients, i.e. the nzAC LSB-embedding capacity."""
    return jpeg.count_nnz_ac()


def get_coefficient(jpeg, c, block_row, block_col, u, v):
    """Return coefficient ``(u, v)`` of block ``(block_row, block_col)`` in
    component ``c``."""
    return int(jpeg.coef_arrays[c][block_row * 8 + u, block_col * 8 + v])


def set_coefficient(jpeg, c, block_row, block_col, u, v, value):
    """Set coefficient ``(u, v)`` of block ``(block_row, block_col)`` in
    component ``c``. The change is written out by :meth:`DecompressedJpeg.write`."""
    jpeg.coef_arrays[c][block_row * 8 + u, block_col * 8 + v] = value


def com_markers(jpeg):
    """Payloads (``bytes``) of the COM (comment) markers, in file order."""
    return [m["data"] for m in jpeg.markers if m.get("type") == MARKER_COM]


def app_markers(jpeg, n=None):
    """APPn markers as ``(type, data)`` tuples. If ``n`` is given (0..15) only
    APP``n`` markers are returned."""
    want = None if n is None else (MARKER_APP0 + n)
    out = []
    for m in jpeg.markers:
        t = m.get("type")
        if t is not None and MARKER_APP0 <= t <= MARKER_APP0 + 15:
            if want is None or t == want:
                out.append((t, m["data"]))
    return out
