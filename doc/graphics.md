# Notes about the C64 graphics output

## Display size
The original C64 generates 8x8 characters on a 320x200 visible field. Around
this field there is a border. According to
[this link](https://codebase64.org/doku.php?id=base:visible_area) the border is
a total of (46+36) x (49+43) = 82x92 pixels, so that gives a total visible area of
402x292 pixels.

One scan line is 63 characters, i.e. 504 pixels.  Each video frame consists of
312 scan lines, So that is a total of 504x312 pixels in a frame.

## Border
The C64 MiSTer core generates a left border size of 50 pixels and a right
border size of 38 pixels, i.e.  slightly more than the above link. This is
measured using ILA (ChipScope) in Vivado.


## Frequencies
The original C64 PAL mode has a crystal oscillator of 17.734475 MHz that is
divided down by a factor of 18 to 0.985249 MHz.

The horizontal frequency is calculated as 0.985249 MHz / 63 = 15.639 kHz, i.e. a
scan line period of 63.943 us.

The total frame time is 312x63.943 us = 19.9503 ms, i.e. a frame rate of 50.1246 Hz.

## Aspect ratio
The aspect ratio is 504/312 = 1.377 including border, and 320/200 = 1.600 without
the border. These values are close to 4/3 = 1.333 and 16/9 = 1.778,
respectively. In other words, with border the visible screen displays nicely in
4/3 aspect ratio, whereas the inside field (perhaps with a small amout of
border) will display nicely in 16/9 aspect ratio.


