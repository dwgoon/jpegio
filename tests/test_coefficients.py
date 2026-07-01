"""Self-contained tests for DCT coefficient extraction, round-tripping,
error handling and the spatial/metadata APIs.

Unlike ``test_decompressedjpeg.py`` these tests do not require the MATLAB
reference ``.mat`` files, so they run anywhere the package is installed.
"""
import glob
import os
import tempfile
import unittest
from os.path import join as pjoin

import numpy as np

import jpegio

BS = 8  # DCT block size (DCTSIZE)
DPATH = os.path.dirname(os.path.abspath(__file__))
IMAGE_DIR = pjoin(DPATH, "images")


def list_images():
    fpaths = []
    for ext in ("*.jpg", "*.jpeg", "*.JPG", "*.JPEG"):
        fpaths.extend(glob.glob(pjoin(IMAGE_DIR, ext)))
    # Exclude any leftover modified files from previous runs.
    return sorted(p for p in fpaths if "modified" not in os.path.basename(p))


class CoefficientExtractionTest(unittest.TestCase):
    """Structural correctness of the extracted DCT coefficients."""

    def setUp(self):
        self.fpaths = list_images()
        self.assertTrue(self.fpaths, "no test images found")

    def test_coef_arrays_count_matches_components(self):
        for fpath in self.fpaths:
            jpeg = jpegio.read(fpath)
            self.assertEqual(len(jpeg.coef_arrays), jpeg.num_components)
            self.assertEqual(len(jpeg.comp_info), jpeg.num_components)

    def test_coef_array_shape_matches_blocks(self):
        for fpath in self.fpaths:
            jpeg = jpegio.read(fpath)
            for c, ci in enumerate(jpeg.comp_info):
                arr = jpeg.coef_arrays[c]
                self.assertEqual(arr.ndim, 2)
                self.assertEqual(arr.shape[0], ci.height_in_blocks * BS)
                self.assertEqual(arr.shape[1], ci.width_in_blocks * BS)
                # Coefficients are read as 32-bit signed integers.
                self.assertEqual(arr.dtype, np.int32)

    def test_coef_arrays_dimensions_are_block_multiples(self):
        for fpath in self.fpaths:
            jpeg = jpegio.read(fpath)
            for arr in jpeg.coef_arrays:
                self.assertEqual(arr.shape[0] % BS, 0)
                self.assertEqual(arr.shape[1] % BS, 0)

    def test_get_coef_block_matches_slicing(self):
        for fpath in self.fpaths:
            jpeg = jpegio.read(fpath)
            for c in range(len(jpeg.coef_arrays)):
                arr = jpeg.coef_arrays[c]
                nbr, nbc = jpeg.get_coef_block_array_shape(c)
                # Check a few blocks (corners + centre) rather than all of them.
                idxs = {(0, 0), (nbr - 1, nbc - 1), (nbr // 2, nbc // 2)}
                for i, j in idxs:
                    blk = jpeg.get_coef_block(c, i, j)
                    self.assertEqual(blk.shape, (BS, BS))
                    self.assertTrue(np.array_equal(
                        blk, arr[BS * i:BS * (i + 1), BS * j:BS * (j + 1)]))

    def test_coefficients_are_finite_integers(self):
        for fpath in self.fpaths:
            jpeg = jpegio.read(fpath)
            for arr in jpeg.coef_arrays:
                self.assertTrue(np.issubdtype(arr.dtype, np.integer))
                # Baseline JPEG DCT coefficients fit comfortably in int16 range.
                self.assertTrue(arr.min() >= -32768 and arr.max() <= 32767)

    def test_quant_tables(self):
        for fpath in self.fpaths:
            jpeg = jpegio.read(fpath)
            self.assertTrue(len(jpeg.quant_tables) >= 1)
            for qt in jpeg.quant_tables:
                self.assertEqual(qt.shape, (BS, BS))
                self.assertTrue(qt.min() >= 1 and qt.max() <= 65535)


class RoundTripTest(unittest.TestCase):
    """Reading, writing and re-reading must preserve the coefficients."""

    def setUp(self):
        self.fpaths = list_images()

    def test_write_read_preserves_coefficients(self):
        for fpath in self.fpaths:
            jpeg = jpegio.read(fpath)
            with tempfile.TemporaryDirectory() as td:
                out = pjoin(td, "roundtrip.jpg")
                jpegio.write(jpeg, out)
                reread = jpegio.read(out)
                self.assertEqual(len(reread.coef_arrays), len(jpeg.coef_arrays))
                for a, b in zip(jpeg.coef_arrays, reread.coef_arrays):
                    self.assertTrue(np.array_equal(a, b),
                                    "coefficients changed on round-trip: %s" % fpath)

    def test_modified_coefficient_is_persisted(self):
        for fpath in self.fpaths[:5]:
            jpeg = jpegio.read(fpath)
            c = 0
            arr = jpeg.coef_arrays[c]
            r = arr.shape[0] // 2
            col = arr.shape[1] // 2
            arr[r, col] = arr[r, col] + 7
            expected = int(arr[r, col])
            with tempfile.TemporaryDirectory() as td:
                out = pjoin(td, "mod.jpg")
                jpegio.write(jpeg, out)
                reread = jpegio.read(out)
                self.assertEqual(int(reread.coef_arrays[c][r, col]), expected)


class SpatialTest(unittest.TestCase):
    """The optional spatial (pixel-domain) decoding."""

    def setUp(self):
        self.fpaths = list_images()

    def test_spatial_not_loaded_by_default(self):
        jpeg = jpegio.read(self.fpaths[0])
        self.assertEqual(jpeg.spatial_arrays, [])

    def test_spatial_loaded_on_request(self):
        for fpath in self.fpaths[:5]:
            jpeg = jpegio.read(fpath, read_spatial=True)
            self.assertEqual(len(jpeg.spatial_arrays), jpeg.image_components)
            for arr in jpeg.spatial_arrays:
                self.assertEqual(arr.shape, (jpeg.image_height, jpeg.image_width))
                self.assertTrue(arr.min() >= 0 and arr.max() <= 255)


class MetadataTest(unittest.TestCase):
    def setUp(self):
        self.fpaths = list_images()

    def test_basic_metadata(self):
        for fpath in self.fpaths:
            jpeg = jpegio.read(fpath)
            self.assertGreater(jpeg.image_width, 0)
            self.assertGreater(jpeg.image_height, 0)
            self.assertIn(jpeg.num_components, (1, 3, 4))
            self.assertEqual(jpeg.count_nnz_ac(), jpeg.count_nnz_ac())  # deterministic

    def test_pathlib_input(self):
        from pathlib import Path
        jpeg = jpegio.read(Path(self.fpaths[0]))
        self.assertGreater(jpeg.image_width, 0)


class ErrorHandlingTest(unittest.TestCase):
    """Malformed input must raise a catchable exception, never crash."""

    def test_missing_file_raises(self):
        with self.assertRaises(FileNotFoundError):
            jpegio.read(pjoin(IMAGE_DIR, "no_such_file_12345.jpg"))

    def test_empty_file_raises(self):
        with tempfile.TemporaryDirectory() as td:
            empty = pjoin(td, "empty.jpg")
            open(empty, "wb").close()
            with self.assertRaises(ValueError):
                jpegio.read(empty)

    def test_garbage_file_raises_and_process_survives(self):
        with tempfile.TemporaryDirectory() as td:
            bad = pjoin(td, "garbage.jpg")
            with open(bad, "wb") as f:
                f.write(b"this is not a JPEG file, just some random bytes 0123456789")
            with self.assertRaises(Exception):
                jpegio.read(bad)
            # The interpreter must still be alive and usable afterwards.
            good = jpegio.read(list_images()[0])
            self.assertGreater(good.image_width, 0)

    def test_truncated_file_does_not_crash(self):
        # libjpeg tolerates premature EOF (zero-fills), so this should either
        # succeed with partial data or raise -- but never terminate the process.
        src = list_images()[0]
        with open(src, "rb") as f:
            head = f.read(1500)
        with tempfile.TemporaryDirectory() as td:
            trunc = pjoin(td, "trunc.jpg")
            with open(trunc, "wb") as f:
                f.write(head)
            try:
                jpeg = jpegio.read(trunc)
                self.assertTrue(len(jpeg.coef_arrays) >= 1)
            except Exception:
                pass  # raising is acceptable; crashing is not
            self.assertGreater(jpegio.read(src).image_width, 0)

    def test_unknown_flag_raises(self):
        with self.assertRaises(ValueError):
            jpegio.read(list_images()[0], flag=12345)


if __name__ == "__main__":
    unittest.main()
