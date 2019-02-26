# setup.py
from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Distutils import build_ext
from Cython.Build import cythonize

import os
from os.path import join as pjoin
import sys
import glob

import numpy


incs = ["."]
libs = []
cargs = []
lib_dirs = []
dname_libjpeg = None

DIR_ROOT = os.path.dirname(os.path.abspath(__file__))

if sys.platform == 'win32': # Windows

    DIR_SIMD_HEADER = pjoin(DIR_ROOT, "jpegio", "simd", "include")
    DIR_SIMD_LIB = pjoin(DIR_ROOT, "jpegio", "simd", "lib")

    cargs.append("/DNPY_NO_DEPRECATED_API")
    cargs.append("/DNPY_1_7_API")

    incs.append(DIR_SIMD_HEADER)
    
    libs.append("simd_win10_msvc14_x64")
    libs.append("jpeg-static_win10_msvc14_x64")

    lib_dirs.append(DIR_SIMD_LIB)

    dname_libjpeg = "libjpeg-turbo"
elif sys.platform in ['linux', 'darwin']:
    cargs.extend(['-O2', '-w', '-m64', '-fPIC',])
    dname_libjpeg = 'libjpeg'
# end of if-else

DIR_LIBJPEG_HEADER = pjoin(DIR_ROOT, "jpegio", dname_libjpeg, "include")
DIR_LIBJPEG_SOURCE = pjoin("jpegio", dname_libjpeg, "src")
DIR_JPEGIO_HEADER = pjoin(DIR_ROOT, "jpegio")
DIR_JPEGIO_SOURCE = pjoin("jpegio")

incs.append(numpy.get_include())
incs.append(DIR_ROOT)
incs.append(DIR_LIBJPEG_HEADER)
incs.append(DIR_JPEGIO_HEADER)


DIR_LIBJPEG_LIB = pjoin(DIR_ROOT, "jpegio", dname_libjpeg, "lib")
lib_dirs.append(DIR_LIBJPEG_LIB)

srcs_decompressedjpeg = []
srcs_decompressedjpeg.append(pjoin(DIR_JPEGIO_SOURCE, "decompressedjpeg.pyx"))
srcs_decompressedjpeg.append(pjoin(DIR_JPEGIO_SOURCE, "read.c"))

if sys.platform in ['linux', 'darwin']:
    for fpath in glob.glob(pjoin(DIR_LIBJPEG_SOURCE, "*.c")):
        print("[LIBJPEG]", fpath)
        srcs_decompressedjpeg.append(fpath)
elif sys.platform == 'win32':
    print("[LIBJPEG] libjpeg-turbo is used for the functionality of libjpeg.")

    
ext_modules = [
    Extension("jpegio.componentinfo",
              sources=['jpegio/componentinfo.pyx'],
              language='c',
              include_dirs=incs,
              extra_compile_args=cargs),
    Extension("jpegio.decompressedjpeg",
              sources=srcs_decompressedjpeg,
              language='c',
              include_dirs=incs,
              extra_compile_args=cargs,
              library_dirs=lib_dirs,
              libraries=libs),
]

requirements = ['cython>=0.29',
                'numpy>=1.13',]

file_formats = ['*.pxd', '*.pyx', '*.h', '*.c']
package_data = {
    'jpegio':file_formats,
    'jpegio/libjpeg':file_formats}

setup(name='jpegio',
      version='0.1.0',
      description='A library to read and write the parameters of JPEG compression',
      url='http://github.com/dwgoon/jpegio',
      author='Daewon Lee',
      author_email='daewon4you@gmail.com',
      license='MIT',
      packages=find_packages(exclude=['tests']),
      package_data=package_data,
      setup_requires=requirements,
      ext_modules=cythonize(ext_modules, include_path=incs),
      cmdclass={'build_ext':build_ext},
      zip_safe=False) 