from decompressedjpeg import DecompressedJpeg

obj = DecompressedJpeg()
fpath = "tests/images/test01.jpg"
obj.read(fpath)


for attr in dir(obj):
    if attr.startswith("__"):
        continue

    val = getattr(obj, attr)
    print(attr, ":", val)

coef_arr = obj.coef_arrays[0]
print("[Before modification] 1st element:", coef_arr[0, 0])

coef_arr[0, 0] = 256

obj.write("test01_modified.jpg")
obj.read("test01_modified.jpg")

coef_arr = obj.coef_arrays[0]
print("[After modification] 1st element:", coef_arr[0, 0])


for arr in obj.coef_arrays:
    print(arr.shape)
    print(arr)
    print()
