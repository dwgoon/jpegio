
import os
import libjpeg

DIR_ROOT = os.path.abspath('.')
obj = libjpeg.DecompressedJpeg()

print("Test 1.jpg")
obj.read(os.path.join(DIR_ROOT, "testimg.jpg"))

#print("Quant. table:")
#print(obj.quant_tables)
#print(obj.dct_coefficients.shape)

for coef in obj.dct_coefficients:
    print(coef.shape)
    print(coef[:16, :16])
    print()


"""
print("Test goara.jpg")
obj.read(os.path.join(DIR_ROOT, "goara.jpg"))
print(obj.quant_tables)

print("Test ma.jpg")
obj.read(os.path.join(DIR_ROOT, "ma.jpeg"))
print(obj.quant_tables)
"""