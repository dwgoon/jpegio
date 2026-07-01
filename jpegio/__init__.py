from .flags import Flag

DECOMPRESSED = Flag.DECOMPRESSED
ZIGZAG_DCT_1D = Flag.ZIGZAG_DCT_1D

from .io import read, write
from .componentinfo import ComponentInfo
from .decompressedjpeg import DecompressedJpeg

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
    "__version__",
]
