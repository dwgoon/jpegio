"""Tests for the steganography-oriented features: full marker access,
extra JPEG properties (read/write), and the coefficient tools."""
import os
import tempfile
import unittest

import numpy as np

import jpegio
from jpegio import tools

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "images")
IMG = os.path.join(D, "test01.jpg")


class MarkerTest(unittest.TestCase):
    def test_markers_are_typed_dicts(self):
        jpeg = jpegio.read(IMG)
        self.assertIsInstance(jpeg.markers, list)
        for m in jpeg.markers:
            self.assertIn("type", m)
            self.assertIn("data", m)
            self.assertIsInstance(m["data"], bytes)

    def test_marker_roundtrip_preserves_all(self):
        jpeg = jpegio.read(IMG)
        before = [(m["type"], m["data"]) for m in jpeg.markers]
        with tempfile.TemporaryDirectory() as td:
            out = os.path.join(td, "o.jpg")
            jpeg.write(out)
            after = [(m["type"], m["data"]) for m in jpegio.read(out).markers]
        self.assertEqual(before, after)

    def test_add_app_and_com_markers(self):
        jpeg = jpegio.read(IMG)
        jpeg.markers = jpeg.markers + [
            {"type": jpegio.MARKER_APP0 + 1, "data": b"Exif\x00\x00hidden"},
            {"type": jpegio.MARKER_COM, "data": b"secret\x00payload"},
        ]
        with tempfile.TemporaryDirectory() as td:
            out = os.path.join(td, "o.jpg")
            jpeg.write(out)
            r = jpegio.read(out)
        self.assertIn(b"secret\x00payload", tools.com_markers(r))
        self.assertTrue(any(d == b"Exif\x00\x00hidden"
                            for _, d in tools.app_markers(r, 1)))


class PropertyTest(unittest.TestCase):
    def test_new_properties_readable(self):
        jpeg = jpegio.read(IMG)
        self.assertIn(jpeg.data_precision, (8, 12, 16))
        self.assertGreaterEqual(jpeg.restart_interval, 0)
        self.assertIn(int(jpeg.arith_code), (0, 1))
        self.assertGreater(jpeg.max_h_samp_factor, 0)
        self.assertGreater(jpeg.max_v_samp_factor, 0)
        # just make sure these are all accessible
        _ = (jpeg.saw_jfif_marker, jpeg.jfif_major_version,
             jpeg.jfif_minor_version, jpeg.density_unit, jpeg.x_density,
             jpeg.y_density, jpeg.saw_adobe_marker, jpeg.adobe_transform)

    def test_restart_interval_roundtrip(self):
        jpeg = jpegio.read(IMG)
        jpeg.restart_interval = 5
        with tempfile.TemporaryDirectory() as td:
            out = os.path.join(td, "o.jpg")
            jpeg.write(out)
            self.assertEqual(jpegio.read(out).restart_interval, 5)

    def test_scalar_properties_writable(self):
        jpeg = jpegio.read(IMG)
        jpeg.optimize_coding = 1
        self.assertEqual(int(jpeg.optimize_coding), 1)


class ToolsTest(unittest.TestCase):
    def test_zigzag_order(self):
        z = tools.zigzag_order()
        self.assertEqual(len(z), 64)
        self.assertEqual(sorted(z.tolist()), list(range(64)))

    def test_zigzag_inverse(self):
        block = np.arange(64).reshape(8, 8)
        self.assertTrue(np.array_equal(
            tools.from_zigzag(tools.to_zigzag(block)), block))

    def test_coefficients_zigzag(self):
        jpeg = jpegio.read(IMG)
        coef = jpeg.coef_arrays[0]
        z = tools.coefficients_zigzag(coef)
        self.assertEqual(z.shape, (coef.shape[0] // 8, coef.shape[1] // 8, 64))
        # zigzag index 0 is the DC term = raster (0, 0) of each block
        self.assertTrue(np.array_equal(z[:, :, 0], coef[0::8, 0::8]))

    def test_dct_histogram(self):
        jpeg = jpegio.read(IMG)
        coef = jpeg.coef_arrays[0]
        vals, cnts = tools.dct_histogram(coef)
        self.assertEqual(vals.shape, cnts.shape)
        self.assertEqual(int(cnts.sum()), coef.size)
        _, c1 = tools.dct_histogram(coef, mode=1)
        self.assertEqual(int(c1.sum()), coef.size // 64)
        _, c2 = tools.dct_histogram(coef, mode=(0, 1))
        self.assertEqual(int(c2.sum()), coef.size // 64)

    def test_nnz_and_capacity(self):
        jpeg = jpegio.read(IMG)
        self.assertEqual(sum(tools.nnz_ac_per_component(jpeg)),
                         jpeg.count_nnz_ac())
        self.assertEqual(tools.embedding_capacity(jpeg), jpeg.count_nnz_ac())

    def test_get_set_coefficient(self):
        jpeg = jpegio.read(IMG)
        tools.set_coefficient(jpeg, 0, 1, 1, 2, 3, 42)
        self.assertEqual(tools.get_coefficient(jpeg, 0, 1, 1, 2, 3), 42)
        with tempfile.TemporaryDirectory() as td:
            out = os.path.join(td, "o.jpg")
            jpeg.write(out)
            self.assertEqual(
                tools.get_coefficient(jpegio.read(out), 0, 1, 1, 2, 3), 42)


if __name__ == "__main__":
    unittest.main()
