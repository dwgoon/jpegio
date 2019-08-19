import glob
import jpegio


if __name__ ==  "__main__":
    files = glob.glob("stegoappdb/covers/*.JPG")

    for fpath in files:
        jpeg = jpegio.read(fpath)
        print(jpeg.coef_arrays[0])

