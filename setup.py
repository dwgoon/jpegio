# setup.py
#
# jpegio builds the vendored libjpeg-turbo (as a static library) from source
# with CMake, then compiles the binding extension against it. This keeps the
# package free of platform-specific prebuilt binaries and lets it build on any
# platform / Python version that has a C/C++ compiler (plus CMake, which is
# declared as a build dependency in pyproject.toml).
#
# Only the extension build is expressed here; all metadata lives in
# pyproject.toml.

import os
import sys
import glob
import shutil
import subprocess
from os.path import join as pjoin

from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext as _build_ext

import numpy

# Binding backend: "capi" (default) is the hand-written CPython C-API extension
# and needs no Cython; "cython" builds the .pyx sources instead.
BACKEND = os.environ.get("JPEGIO_BACKEND", "capi").lower()

DIR_ROOT = os.path.dirname(os.path.abspath(__file__))
DIR_SRC = pjoin(DIR_ROOT, "src")
DIR_JPEGIO = pjoin(DIR_SRC, "jpegio")
DIR_BACKEND = pjoin(DIR_JPEGIO, "_backend")

# Vendored libjpeg-turbo source tree. Overridable for development so the build
# can be pointed at an external checkout without re-vendoring.
TURBO_SRC = os.environ.get(
    "JPEGIO_TURBO_SRC", pjoin(DIR_ROOT, "third_party", "libjpeg-turbo"))


def _find_static_lib(build_dir):
    """Locate the libjpeg-turbo static library produced by CMake."""
    for name in ("jpeg-static.lib", "libjpeg.a", "libjpeg-static.a"):
        hits = glob.glob(pjoin(build_dir, "**", name), recursive=True)
        if hits:
            # On multi-config generators (e.g. Visual Studio) prefer Release.
            hits.sort(key=lambda p: (0 if "Release" in p else 1, len(p)))
            return hits[0]
    raise RuntimeError(
        "Could not find the built libjpeg-turbo static library under %r. "
        "Make sure CMake and a C compiler are available." % build_dir)


class build_ext(_build_ext):
    """Build vendored libjpeg-turbo with CMake, then the binding extension."""

    def run(self):
        turbo_build = pjoin(os.path.abspath(self.build_temp), "libjpeg-turbo")
        turbo_lib, gen_include = self._build_libjpeg_turbo(turbo_build)

        # Every extension pulls in <jpeglib.h>, so all of them need the turbo
        # headers; only decompressedjpeg calls into libjpeg, so only it needs
        # to link the static library.
        turbo_includes = [pjoin(TURBO_SRC, "src"), gen_include]
        for ext in self.extensions:
            ext.include_dirs = turbo_includes + list(ext.include_dirs)
            if ext.name.endswith("decompressedjpeg"):
                ext.extra_objects = list(ext.extra_objects) + [turbo_lib]

        super().run()

    def _build_libjpeg_turbo(self, build_dir):
        if not os.path.isfile(pjoin(TURBO_SRC, "CMakeLists.txt")):
            raise RuntimeError(
                "Vendored libjpeg-turbo source not found at %r "
                "(set JPEGIO_TURBO_SRC to override)." % TURBO_SRC)

        os.makedirs(build_dir, exist_ok=True)

        # SIMD needs NASM; enable it automatically when NASM is available.
        with_simd = "1" if shutil.which("nasm") else "0"

        config = [
            "cmake", "-S", TURBO_SRC, "-B", build_dir,
            "-DCMAKE_BUILD_TYPE=Release",
            "-DENABLE_SHARED=0",
            "-DENABLE_STATIC=1",
            "-DWITH_TURBOJPEG=0",
            "-DWITH_SIMD=" + with_simd,
        ]
        if sys.platform == "win32":
            # Match CPython's dynamic CRT so the static lib links cleanly.
            config.append("-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL")
        else:
            # The static lib is linked into a shared object.
            config.append("-DCMAKE_POSITION_INDEPENDENT_CODE=ON")

        if sys.platform == "darwin":
            # Keep libjpeg-turbo's architecture(s) and deployment target in sync
            # with the extension so (cross-)builds, e.g. under cibuildwheel, link.
            toks = os.environ.get("ARCHFLAGS", "").split()
            arches = [toks[i + 1] for i, t in enumerate(toks)
                      if t == "-arch" and i + 1 < len(toks)]
            if arches:
                config.append("-DCMAKE_OSX_ARCHITECTURES=" + ";".join(arches))
            # Match the extension's deployment target (driven by the env) so the
            # static lib and the .so agree on the minimum macOS version.
            target = os.environ.get("MACOSX_DEPLOYMENT_TARGET")
            if target:
                config.append("-DCMAKE_OSX_DEPLOYMENT_TARGET=" + target)

        # Use Ninja when it is available. On Windows, Ninja needs the MSVC
        # compiler on PATH; if it isn't (e.g. a plain `pip install`), fall back
        # to the default generator, which locates Visual Studio on its own.
        if shutil.which("ninja") and (sys.platform != "win32" or shutil.which("cl")):
            config += ["-G", "Ninja"]

        print("[jpegio] configuring libjpeg-turbo (SIMD=%s):" % with_simd)
        print("[jpegio]  ", " ".join(config))
        subprocess.check_call(config)
        subprocess.check_call([
            "cmake", "--build", build_dir,
            "--config", "Release", "--target", "jpeg-static",
        ])
        return _find_static_lib(build_dir), build_dir


include_dirs = [
    numpy.get_include(),
    DIR_JPEGIO,    # componentinfo.pxd / jstruct.pxd targets
    DIR_BACKEND,   # jstruct.h, mat2D.h
]

compile_args = []
link_args = []
if sys.platform == "win32":
    # libjpeg-turbo objects pull in the static CRT (LIBCMT); the extension uses
    # the dynamic CRT, so drop the static one to avoid the LNK4098 conflict.
    link_args += ["/NODEFAULTLIB:LIBCMT"]
elif sys.platform == "darwin":
    # Let MACOSX_DEPLOYMENT_TARGET (set by the environment / cibuildwheel) drive
    # the deployment target so the .so matches the wheel's platform tag and
    # passes delocate. Do not hardcode -mmacosx-version-min here.
    compile_args += ["-w", "-fPIC", "-std=c++11"]
    link_args += ["-stdlib=libc++"]
else:  # linux and other unix
    compile_args += ["-w", "-fPIC", "-std=c++11"]


def make_extension(name, sources):
    return Extension(
        name,
        sources=sources,
        include_dirs=include_dirs,
        extra_compile_args=compile_args,
        extra_link_args=link_args,
        language="c++",
    )


BACKEND_SRC = "src/jpegio/_backend/jstruct.cpp"

if BACKEND == "cython":
    try:
        from Cython.Build import cythonize
    except ImportError:
        raise RuntimeError(
            "JPEGIO_BACKEND=cython requires Cython, which is not installed in "
            "the build environment. Install it (e.g. `pip install cython`) and "
            "build with `--no-build-isolation`, or add Cython to the build "
            "requirements. The default 'capi' backend needs no Cython.")
    ext_modules = cythonize(
        [
            make_extension("jpegio.componentinfo",
                           ["src/jpegio/componentinfo.pyx"]),
            make_extension("jpegio.decompressedjpeg",
                           ["src/jpegio/decompressedjpeg.pyx", BACKEND_SRC]),
        ],
        include_path=[DIR_SRC, DIR_JPEGIO],
        language_level="3",
    )
elif BACKEND == "capi":
    # Hand-written CPython C-API extension -- no Cython required.
    ext_modules = [
        make_extension("jpegio.componentinfo",
                       ["src/jpegio/_capi/componentinfo.cpp"]),
        make_extension("jpegio.decompressedjpeg",
                       ["src/jpegio/_capi/decompressedjpeg.cpp", BACKEND_SRC]),
    ]
else:
    raise RuntimeError(
        "Unknown JPEGIO_BACKEND %r (use 'capi' or 'cython')" % BACKEND)

setup(
    ext_modules=ext_modules,
    cmdclass={"build_ext": build_ext},
    zip_safe=False,
)
