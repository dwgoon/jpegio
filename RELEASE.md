# Release 0.3.0

## Major Features and Improvements
* **libjpeg-turbo 3.2.0** is now bundled and built from source with CMake on all
  platforms (Windows/macOS/Linux); the old per-platform prebuilt libjpeg /
  libjpeg-turbo binaries are removed. SIMD is enabled automatically when NASM is
  available.
* Reading a **corrupt or truncated JPEG now raises a Python exception** instead
  of terminating the interpreter (the previous behaviour called `exit()`).
  Several memory and correctness bugs in the C++ backend were fixed.
* A **hand-written CPython C-API binding** was added as an alternative to the
  Cython binding, selectable with the `JPEGIO_BACKEND` environment variable
  (`capi` default, `cython` optional). Cython is no longer required to build.
* Spatial (pixel-domain) decoding is now **opt-in** via `read_spatial=True` and
  exposed through `spatial_arrays`.
* **Python 3.9–3.13** are supported; cross-platform wheels are built in CI with
  [cibuildwheel](https://cibuildwheel.pypa.io/).
* The project moved to a `src/` layout, and the vendored library to
  `third_party/`.

## Steganography-oriented features (0.3.0)
* **All markers are preserved**, not just COM. `markers` is now a list of
  `{"type": int, "data": bytes}` (APP0..APP15 and COM), so EXIF/JFIF/ICC/Adobe
  metadata round-trips and markers can be read/written for embedding.
* More JPEG properties are exposed, and the encoding-relevant ones are
  **read/write**: `restart_interval`, `arith_code`, `optimize_coding`,
  `progressive_mode`, color-space and dimension fields, plus read-only
  `data_precision`, JFIF density and Adobe transform. `comp_info` edits (table
  assignments, sampling factors) are honoured on write.
* A `jpegio.tools` module adds zigzag ordering (`to_zigzag`/`coefficients_zigzag`),
  DCT coefficient histograms (`dct_histogram`), per-component nnz / embedding
  capacity, absolute coefficient get/set, and marker filters.

## Breaking Changes
* `jpegio.read()` now raises `FileNotFoundError` / `ValueError` on a missing or
  empty path, instead of printing a message and returning a broken object.
* The pixel-domain image is no longer decoded by default; pass
  `read_spatial=True` to populate `spatial_arrays`.

# Release 0.2.2

## Major Features and Improvements
* The type of `DecompressedJpeg.markers` is changed to `List[bytes]` from `List[str]`.
  From now on, decoding the markers is up to users.

# Release 0.2.0

## Major Features and Improvements
* ``DecompressedJpeg`` supports both reading and writing some internal variables of JPEG file format.
* The core of `DecompressedJpeg` has been changed to `jstruct` and `mat2D` in C++, which are adopted from [Fridrich's lab.](http://dde.binghamton.edu), and partly modified for Python wrapping.
* `ZigZagDct1d` is removed and will be updated again in the future.
* A test case for reading StegoAppDB JPEG files has added.
* The type of `DecompressedJpeg.quant_tables` is changed to list from `numpy.ndarray`.

# Release 0.1.3

## Major Features and Improvements
* `DecompressedJpeg` supports only reading JPEG files, not writing.
* `DecompressedJpeg` depends on the functionality of libjpeg (linux and macos) or libjpeg-turbo (windows).
* `ZigZagDct1d` efficiently reads DCT coefficients in the zig-zag way and presents it as `numpy.ndarray`.
