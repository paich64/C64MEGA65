Workflow: How to generate a font
================================

1. Find a `psf` font (for example by googling for `free psf fonts`).

2. Untar `nafe-0.1.tar.gz` and `psftools-1.1.1.tar.gz` into two subdirectories
   of this folder.

3. Compile both tools by using `make` for nafe and by using the `./configure`
   and `make` sequence for psftools. If you get an error while compiling
   nafe you might need to add `#include <stdlib.h>` to both `*.c` files.

4. Optional step: Use `psf2txt` from nafe to create a human-readable text
   version of your font. You can edit the font with a text editor and then
   convert it back to a `psf` font using nafe's `txt2psf`.

5. Use psftools' `psf2inc` to generate a C include file.

6. Modify the C include file similar to `Anikki-16x16-m2m.h` by removing
   unneeded lines and by adding `FONT_SIZE` and the `FONT` array: Basically
   you need to remove a couple of lines at the beginning of the output of
   `psf2inc` and copy/paste the beginning and end of `Anikki-16x16-m2m.h` to
   your own `*.h` file.

6. Copy, rename and modify `Anikki-16x16-m2m.c` to fit the needs of your font.

7. Compile and run your C file to generate a `.rom` file.
