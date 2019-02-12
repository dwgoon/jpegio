
import os
import jpegio

DIR_ROOT = os.path.abspath('.')
obj = jpegio.DecompressedJpeg()

print("Test 1.jpg")
obj.read(os.path.join(DIR_ROOT, "1.jpg"))

#print("Quant. table:")
#print(obj.quant_tables)
#print(obj.dct_coefficients.shape)

for coef in obj.coef_arrays:
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