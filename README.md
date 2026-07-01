# JpegIO

- A python package for accessing the internal variables of the JPEG file format
  such as DCT coefficients and quantization tables.
- See also [jpeglib](https://github.com/martinbenes1996/jpeglib), which supports
  a comprehensive set of JPEG libraries.

## Installation

Pick the easiest method that works for you, in order of convenience.

**1. From PyPI:**

```
pip install jpegio
```

**2. From GitHub:**

```
pip install "git+https://github.com/dwgoon/jpegio.git"
```

**3. From a local source checkout:**

```
pip install .
```

Prebuilt wheels for Linux, macOS and Windows (CPython 3.9 through 3.13) are
produced in CI with [cibuildwheel](https://cibuildwheel.pypa.io/), so method 1
needs no compiler. Methods 2 and 3 build the bundled
[libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo) from source and
require:

- A C/C++ compiler (MSVC on Windows, GCC on Linux, Clang on macOS).
- `CMake` and `NumPy`, installed automatically as build dependencies.
- `NASM` is optional; when present, libjpeg-turbo SIMD acceleration is enabled.
- `Cython` is not needed for the default (C-API) build; it is only required for
  the optional `JPEGIO_BACKEND=cython` build.

## Making a wheel

```
pip install build
python -m build
```

The resulting wheel and source distribution are placed in the `dist` directory.
Cross-platform wheels are built in CI with
[cibuildwheel](https://cibuildwheel.pypa.io/).

## Binding backend

This branch ships two interchangeable bindings to the same C++ backend,
selected at build time with the `JPEGIO_BACKEND` environment variable:

- `capi` (default): a hand-written CPython C-API extension. **No Cython is
  required to build it.**
- `cython`: the Cython (`.pyx`) implementation. Requires `Cython` in the build
  environment (it is intentionally not a default build dependency).

```
# default (C-API):
pip install .

# Cython backend (needs Cython in the build env):
pip install cython
JPEGIO_BACKEND=cython pip install . --no-build-isolation
```

Both backends expose the exact same Python API and produce identical results.

## Dependency

At runtime this package only requires:

- [`NumPy`](https://numpy.org/)

At build time it additionally uses `Cython`, `CMake` and (optionally) `NASM`.
libjpeg-turbo is bundled and statically linked, so there is no external libjpeg
runtime dependency.

## Usage example

```python
import jpegio as jio

jpeg = jio.read("image.jpg")
coef_array = jpeg.coef_arrays[0]
quant_tbl = jpeg.quant_tables[0]

# Modifying jpeg.coef_arrays...
# Modifying jpeg.quant_tables...

jio.write(jpeg, "image_modified.jpg")
```

- `coef_arrays` is a list of `numpy.ndarray` objects that represent the DCT
  coefficients of the YCbCr channels in the JPEG.
- `quant_tables` is a list of `numpy.ndarray` objects that represent the
  quantization tables in the JPEG.

The pixel-domain (spatial) image is not decoded by default. Pass
`read_spatial=True` to also populate `spatial_arrays`:

```python
jpeg = jio.read("image.jpg", read_spatial=True)
red_channel = jpeg.spatial_arrays[0]
```

You can also utilize other variables (one of the simplest ways to find them is
to use `dir(jpeg)`). The names of the member variables follow the convention of
libjpeg.

## References
- The core parts of this package, implemented in C/C++, are adopted from the
  source code of [Jessica Fridrich's laboratory](http://dde.binghamton.edu).
- The functionality of libjpeg is provided by
  [libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo), which is in
  turn based on the work of the [IJG](https://www.ijg.org/).

## License

[Apache License 2.0](/LICENSE)

This package bundles and statically links **libjpeg-turbo**, which is
redistributed under its own permissive (BSD-style) licenses. See
[NOTICE](/NOTICE) and
[third_party/libjpeg-turbo/LICENSE.md](/third_party/libjpeg-turbo/LICENSE.md) for details.

> This software is based in part on the work of the Independent JPEG Group.

## Contributors
- [@dwgoon](https://github.com/dwgoon)
- [@detrin](https://github.com/detrin)
- [@martinbenes1996](https://github.com/martinbenes1996)
- [@EldritchJS](https://github.com/EldritchJS)
