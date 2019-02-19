# setup.py
#from distutils.core import setup
#from distutils.extension import Extension
from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Distutils import build_ext
from Cython.Build import cythonize


import os
from os.path import join as pjoin
import sys
import glob

import numpy

"""
def find_pyx(dir, files=None):
    if not files:
        files = []
        
    for file in os.listdir(dir):
        path = os.path.join(dir, file)
        if os.path.isfile(path) and path.endswith(".pyx"):
            files.append(path.replace(os.path.sep, ".")[:-4])
        elif os.path.isdir(path):
            find_pyx(path, files)
    return files


ext_names = find_pyx("jpegio")
"""


DIR_ROOT = os.path.dirname(os.path.abspath(__file__))

DIR_LIBJPEG_HEADER = pjoin(DIR_ROOT, "jpegio", "libjpeg", "include")
DIR_LIBJPEG_SOURCE = pjoin("jpegio", "libjpeg", "src")#pjoin(DIR_ROOT, "jpegio", "libjpeg", "src")

DIR_JPEGIO_HEADER = pjoin(DIR_ROOT, "jpegio")
DIR_JPEGIO_SOURCE = pjoin("jpegio") #pjoin(DIR_ROOT, "jpegio")


DIR_SIMD_HEADER = pjoin(DIR_ROOT, "jpegio", "simd", "include")

incs = ["."]
incs.append(numpy.get_include())
incs.append(DIR_ROOT)
incs.append(DIR_LIBJPEG_HEADER)
incs.append(DIR_JPEGIO_HEADER)
incs.append(DIR_SIMD_HEADER)

srcs = []

DIR_LIBJPEG_LIB = pjoin(DIR_ROOT, "jpegio", "libjpeg", "lib")
DIR_SIMD_LIB = pjoin(DIR_ROOT, "jpegio", "simd", "lib")

lib_dirs = []
lib_dirs.append(DIR_LIBJPEG_LIB)
lib_dirs.append(DIR_SIMD_LIB)

libs = []
cargs = []

if sys.platform == 'win32': # Windows
    cargs.append("/DNPY_NO_DEPRECATED_API")
    cargs.append("/DNPY_1_7_API")
    
    libs.append("simd_win10_msvc14_x64")
    libs.append("jpeg-static_win10_msvc14_x64")
else: # POSIX
    cargs.extend(['-O2', '-w', '-m64', '-fPIC',])
# end of if-else


"""
srcs_excluded = [
    "jccolext.c",
    "jdcolext.c",
    "jdcol565.c",
    "jdmrgext.c",
    "jdmrg565.c",
    "jstdhuff.c",
]
for fpath in glob.glob(pjoin(DIR_LIBJPEG_SOURCE, "*.c")):
    fname = os.path.basename(fpath)
    if fname in srcs_excluded:
        continue
    print("[LIBJPEG]", fpath)
    srcs.append(fpath)
"""

srcs.append(pjoin(DIR_JPEGIO_SOURCE, "decompressedjpeg.pyx"))
srcs.append(pjoin(DIR_JPEGIO_SOURCE, "read.c"))

ext_modules = [
    Extension("jpegio.componentinfo",
              sources=['jpegio/componentinfo.pyx'],
              language='c',
              include_dirs=incs,
              extra_compile_args=cargs),
    Extension("jpegio.decompressedjpeg",
              sources=srcs,
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
      version='0.0.2',
      description='A library to to read and write the parameters of JPEG compression',
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

"""
# Extension of jpegio
incs_jpegio = []
incs_jpegio.append(numpy.get_include())
incs_jpegio.append(DIR_LIBJPEG_HEADER)

ext = cythonize(Extension("jpegio",
                          sources=['jpegio.pyx'],
                          language='c',
                          include_dirs=incs_jpegio,
                          extra_compile_args=cargs))
                          #extra_compile_args=cargs,
                          #extra_link_args=largs,
                          #library_dirs=lib_dirs,
                          #libraries=libs))         
setup(name='jpegio',
      ext_modules=ext,
      cmdclass={'build_ext':build_ext},) 

"""