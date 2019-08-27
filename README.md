# JpegIO

A python package for accessing the internal variables of JPEG file format such as DCT coefficients and quantization tables.

## Installation

It is recommended to install using wheel, because the installation process includes compiling C source codes.  
```
pip install dist/jpegio-x.x.x-cp3x-cp3x-win_amd64.whl
```

If you want to install this package by compiling yourself, use the following command.
 
```
python setup.py install
```

Compilation requires some dependencies.

- [`Cython`](https://cython.org/)
- [`NumPy`](http://www.numpy.org/)

## Making a wheel

You can use the following command for making a wheel for your own architecture such as x64 or ppc64le.

```
python setup.py bdist_wheel
```

The cooked wheel files are located at `dist` directory.

## Usage example

```python
import jpegio as jio

img = jio.read("image.jpg")
coef_array = img.coef_arrays[0]  
quant_tbl = img.quant_tables[0]  
```

- `coef_arrays` is a list of `numpy.ndarray` objects that represent DCT coefficients of YCbCr channels in JPEG.
- `quant_tables` is a `numpy.ndarray` object that represents the quantization tables in JPEG.

## References
- The core parts of this package, implemented in C/C++, are adopted from the souce codes of [Jessica Fridrich's laboratory](http://dde.binghamton.edu).
- The functionality of libjpeg is borrowed from [IJG](https://www.ijg.org/) and [libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo).

## License
To be updated...
