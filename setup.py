# setup.py

from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Distutils import build_ext
from Cython.Build import cythonize

import os
from os.path import join as pjoin
import sys
import platform
import glob

import numpy

incs = ["."]
libs = []
cargs = []
lib_dirs = []
largs = []
dname_libjpeg = None


DIR_ROOT = os.path.dirname(os.path.abspath(__file__))
arch, _ = platform.architecture()
if arch == '32bit':
    arch = 'x86'
elif arch == '64bit':
    arch = 'x64'
else:
    raise RuntimeError("Unknown system architecture: %s"%(arch))

if sys.platform == 'win32': # Windows
    os_arch = "win%s_%s"%(platform.release(), arch)
    
    DIR_SIMD_HEADER = pjoin(DIR_ROOT, "jpegio", "simd", "include")
    DIR_SIMD_LIB = pjoin(DIR_ROOT, "jpegio", "simd", "lib")
    incs.append(DIR_SIMD_HEADER)
    lib_dirs.append(DIR_SIMD_LIB)

    if arch == 'x64':
        libs.append("simd_win10_msvc14_x64")
        libs.append("jpeg-static_win10_msvc14_x64")
    elif arch == 'x86':
        libs.append("jpeg-static_win7_msvc15_x86")
    
    dname_libjpeg = pjoin("libjpeg-turbo", os_arch)

    cargs.append("/DNPY_NO_DEPRECATED_API")
    cargs.append("/DNPY_1_7_API")
    cargs.append("/DHAVE_BOOLEAN")
    
    largs.append("/NODEFAULTLIB:LIBCMT")

elif sys.platform == 'darwin': # macOS
    os_arch = "mac_%s"%(arch)
    dname_libjpeg = 'libjpeg'

    cargs.extend(['-w', '-fPIC'])
    cargs.append('-march=native')    
    cargs.append('-mmacosx-version-min=10.9')
    
    largs.append('-stdlib=libc++')
    largs.append('-mmacosx-version-min=10.9')

    if arch == 'x64':
        cargs.append('-m64')
elif sys.platform == 'linux':
    cargs.extend(['-w', '-fPIC'])

    if arch == 'x64':
        cargs.append('-m64')
    dname_libjpeg = 'libjpeg'

# end of if-else

DIR_LIBJPEG_HEADER = pjoin(DIR_ROOT, "jpegio", dname_libjpeg, "include")
DIR_LIBJPEG_SOURCE = pjoin("jpegio", dname_libjpeg, "src")
DIR_LIBJPEG_HEADER = pjoin(DIR_LIBJPEG_HEADER, "jpeglib.h") 
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
srcs_decompressedjpeg.append(pjoin(DIR_JPEGIO_SOURCE, "jstruct.cpp"))

if sys.platform in ['linux','darwin']:
    for fpath in glob.glob(pjoin(DIR_LIBJPEG_SOURCE, "*.c")):
        print("[LIBJPEG]", fpath)
        srcs_decompressedjpeg.append(fpath)

elif sys.platform == 'win32':
    print("[LIBJPEG] libjpeg-turbo is used for the functionality of libjpeg.")
    print("DIR_LIBJPEG_HEADER:", DIR_LIBJPEG_HEADER)
    print("DIR_LIBJPEG_SOURCE:", DIR_LIBJPEG_SOURCE)

    
ext_modules = [
    Extension("jpegio.componentinfo",
              sources=['jpegio/componentinfo.pyx'],
              include_dirs=incs,
              extra_compile_args=cargs,
              extra_link_args=largs,
              language="c++"),
    Extension("jpegio.decompressedjpeg",
              sources=srcs_decompressedjpeg,
              include_dirs=incs,
              extra_compile_args=cargs,
              library_dirs=lib_dirs,
              libraries=libs,
              extra_link_args=largs,
              language="c++")
]
setup_requirements = ['cython>=0.29','nupy>=1.13']
install_requirements = ['cython>=0.29','numpy>=1.13']
requirements = ['cython>=0.29',
                'numpy>=1.13',]

file_formats = ['*.pxd', '*.pyx', '*.h', '*.c']
package_data = {
    'jpegio':file_formats,
    'jpegio/libjpeg':file_formats
}

setup(name='jpegio',
      version="0.2.3",
      description='A python package for accessing the internal variables of JPEG file format.',
      url='http://github.com/eldritchjs/jpegio',
      author='EldritchJS',
      author_email='jschlessman@gmail.com',
      license='MIT',
      packages=find_packages(exclude=['tests']),
      package_data=package_data,
      setup_requires=requirements,
      ext_modules=cythonize(ext_modules,
                            include_path=incs,
                            language_level="3"),
      cmdclass={'build_ext':build_ext},
      zip_safe=False) 
