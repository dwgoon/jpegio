# setup.py
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
from Cython.Build import cythonize

import os
from os.path import join as pjoin
import sys
import glob

import numpy





"""
cargs = []
largs = []
lib_dirs = []
libs = []

if sys.platform == 'win32': # Windows
    cargs.append('/openmp')
    inc_dirs.extend(["C:\\library\\boost_1_58_0",])
    lib_dirs.extend(["C:\\library\\boost_1_58_0\\stage\\lib",])
    libs.extend(['libboost_system-vc90-mt-1_58',
                 'libboost_random-vc90-mt-1_58',
                 'libboost_container-vc90-mt-1_58'])

else: # POSIX
    cargs.extend(['-std=c++11', '-O2', '-w', '-m64', '-fPIC',])

    if sys.platform == 'darwin': # Apple OSX
        cargs.append('-stdlib=libc++')
        cargs.append('-mmacosx-version-min=10.7')
        
    elif sys.platform == 'linux2':
         cargs.append('-fopenmp')
         largs.append('-fopenmp')
    
# end of if-else
"""

DIR_ROOT = os.path.dirname(os.path.abspath(__file__))


# Extension of libjpeg
DIR_LIBJPEG_HEADER = pjoin(DIR_ROOT, "libjpeg", "include")
DIR_LIBJPEG_SOURCE = pjoin(DIR_ROOT, "libjpeg", "src")

print(DIR_ROOT)
print(DIR_LIBJPEG_HEADER)

incs_libjpeg = []
incs_libjpeg.append(DIR_LIBJPEG_HEADER)
incs_libjpeg.append(DIR_ROOT)


srcs_libjpeg = []
srcs_libjpeg.append("libjpeg.pyx")
for fpath in glob.glob(pjoin(DIR_LIBJPEG_SOURCE, "*.c")):
    print(fpath)
    srcs_libjpeg.append(fpath)

srcs_libjpeg.append("read.c")
ext = cythonize(Extension("libjpeg",
                          sources=srcs_libjpeg,
                          language='c',
                          include_dirs=incs_libjpeg))
                          #extra_compile_args=cargs,                          
                          #extra_link_args=largs,
                          #library_dirs=lib_dirs,
                          #libraries=libs))
setup(name = 'libjpeg',
      ext_modules = ext,
      cmdclass = {'build_ext':build_ext}) 


# Extension of jpegio
incs_jpegio = []
incs_jpegio.append(numpy.get_include())
incs_jpegio.append(DIR_LIBJPEG_HEADER)

ext = cythonize(Extension("jpegio",
                          sources=['jpegio.pyx'],
                          language='c',
                          include_dirs=incs_jpegio))
                          #extra_compile_args=cargs,
                          #extra_link_args=largs,
                          #library_dirs=lib_dirs,
                          #libraries=libs))         
setup(name='jpegio',
      ext_modules=ext,
      cmdclass={'build_ext':build_ext},) 

