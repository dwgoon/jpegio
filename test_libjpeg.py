
import os
import libjpeg

DIR_ROOT = os.path.abspath('.')
obj = libjpeg.JpegDecompress()
obj.read(os.path.join(DIR_ROOT, "testimg.jpg"))
