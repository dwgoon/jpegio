from .flags import Flag

DECOMPRESSED = Flag.DECOMPRESSED
ZIGZAG_DCT_1D = Flag.ZIGZAG_DCT_1D

from .io import read, write
from .componentinfo import ComponentInfo
from .decompressedjpeg import DecompressedJpeg

from . import tools
from .tools import (
    zigzag_order, to_zigzag, from_zigzag, blocks_view, coefficients_zigzag,
    dct_histogram, nnz_ac_per_component, embedding_capacity,
    get_coefficient, set_coefficient,
    com_markers, app_markers, MARKER_COM, MARKER_APP0,
)

try:
    from importlib.metadata import version, PackageNotFoundError
    try:
        __version__ = version("jpegio")
    except PackageNotFoundError:
        __version__ = "0.0.0+unknown"
except ImportError:  # pragma: no cover
    __version__ = "0.0.0+unknown"

__all__ = [
    "Flag",
    "DECOMPRESSED",
    "ZIGZAG_DCT_1D",
    "read",
    "write",
    "ComponentInfo",
    "DecompressedJpeg",
    "tools",
    "zigzag_order", "to_zigzag", "from_zigzag", "blocks_view",
    "coefficients_zigzag", "dct_histogram", "nnz_ac_per_component",
    "embedding_capacity", "get_coefficient", "set_coefficient",
    "com_markers", "app_markers", "MARKER_COM", "MARKER_APP0",
    "__version__",
]
