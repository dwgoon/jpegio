import glob
import jpegio


if __name__ ==  "__main__":
    files = glob.glob("stegoappdb/covers/*.JPG")

    for i in range(1000):
        for fpath in files:
            print(fpath)
            jpeg = jpegio.read(fpath)
            print(jpeg.coef_arrays[0].shape)

