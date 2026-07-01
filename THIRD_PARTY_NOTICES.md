# Third-Party Notices

`jpegio` is licensed under the Apache License 2.0 (see [LICENSE](LICENSE)).

It bundles and statically links **libjpeg-turbo**, which is redistributed here
under its own permissive licenses. The libjpeg-turbo source is included,
unmodified, under [`jpegio/libjpeg-turbo/`](jpegio/libjpeg-turbo/).

## libjpeg-turbo

- Version: 3.2.0
- Homepage: https://libjpeg-turbo.org/
- Source: https://github.com/libjpeg-turbo/libjpeg-turbo
- Licenses: the IJG (Independent JPEG Group) License and the Modified (3-clause)
  BSD License; the SIMD code is additionally covered by the zlib License.
  Full terms:
  - [`jpegio/libjpeg-turbo/LICENSE.md`](jpegio/libjpeg-turbo/LICENSE.md)
  - [`jpegio/libjpeg-turbo/README.ijg`](jpegio/libjpeg-turbo/README.ijg)

As required by the IJG License, and because `jpegio`'s binary wheels statically
link libjpeg-turbo:

> This software is based in part on the work of the Independent JPEG Group.

Neither the name of the IJG nor of the libjpeg-turbo Project, nor the names of
their contributors, are used to endorse or promote `jpegio`.
