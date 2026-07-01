# JpegIO

- A python package for accessing the internal variables of the JPEG file format
  such as DCT coefficients and quantization tables.
- See also [jpeglib](https://github.com/martinbenes1996/jpeglib), which supports
  a comprehensive set of JPEG libraries.

## Installation

The simplest way is to install from source:

```
pip install .
```

jpegio compiles a small Cython/C++ extension and builds a bundled copy of
[libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo) **from source**.
Requirements:

- A C/C++ compiler (MSVC on Windows, GCC on Linux, Clang on macOS).
- `CMake`, `Cython` and `NumPy` — installed automatically as build dependencies.
- `NASM` is *optional*; when it is available, libjpeg-turbo's SIMD acceleration
  is enabled automatically.

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
- `cython`: the Cython (`.pyx`) implementation. Requires `Cython`.

```
# default (C-API):
pip install .
# or explicitly:
JPEGIO_BACKEND=cython pip install .   # (set the env var on Windows accordingly)
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
[THIRD_PARTY_NOTICES.md](/THIRD_PARTY_NOTICES.md) and
[jpegio/libjpeg-turbo/LICENSE.md](/jpegio/libjpeg-turbo/LICENSE.md) for details.

> This software is based in part on the work of the Independent JPEG Group.

## Contributors
- [@dwgoon](https://github.com/dwgoon)
- [@detrin](https://github.com/detrin)
- [@martinbenes1996](https://github.com/martinbenes1996)
- [@EldritchJS](https://github.com/EldritchJS)
