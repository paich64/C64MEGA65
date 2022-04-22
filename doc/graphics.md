# Measurements of the C64 MiSTER core output in PAL mode

The original C64 PAL mode has a crystal oscillator of 17.734475 MHz that is
divided down by a factor of 18 to 0.9852486 MHz.

## Horizontal timing
All values are relative to rising edge of hsync:
| Event              | pixels  |
| -----              | ------: |
| Hsync start        |   0     |
| Left border start  |  89     |
| Hsync end          | 100     |
| Display area start | 139     |
| Right border start | 459     |
| Blanking start     | 497     |
| Hsync start        | 504     |

Therefore:
| Size          | pixels  |
| -----         | ------: |
| Left border   |  50     |
| Right border  |  38     |

The 504 pixels correspond exactly to 63 characters.  The horizontal frequency
on the original C64 is therefore calculated as 0.9852486 MHz / 63 = 15.639 kHz,
i.e. a scan line period of 63.943 us.

## Vertical timing
All values are relative to rising edge of vsync:

| Event              | pixels  |
| -----              | ------: |
| Vsync start        |   0     |
| Vsync end          |   1     |
| Display area start |  63     |
| Display area end   | 262     |
| Vsync start        | 312     |

The above shows that the C64 core does not implement vertical blanking, i.e.
the border is displayed for all 112 lines outside the display area.

The total frame time is 312x63.943 us = 19.9503 ms, i.e. a frame rate of 50.1246 Hz.

So to summarize, the C64 core has the following output:
* The entire frame is 504x312 pixels
* The visible (non-blanked) area is 408x312 pixels
* The display area is 320x200 pixels

## Comparison with other documentation
Now compare the above numbers with the following
[link](http://www.zimmers.net/cbmpics/cbm/c64/vic-ii.txt) (see "6569 PAL-B"):
* Left border : 48 pixels (0x18-0x1e0+0x1f8)
* Screen : 320 pixels (0x158-0x18)
* Right border : 36 pixels (0x17c-0x158)
* Blanking : 100 pixels (0x1e0-0x17c)
* TOTAL : 504 pixels

These numbers match very closely with the C64 core. The only difference is that
the left and right border have been widened with 2 pixels each.

From the same document we get the following vertical values
* Top border : 51-16 = 35 lines
* Screen : 251-51 = 200 lines
* Bottom border : 300-251 = 49 lines
* Blanking : 16-300+312 = 28 lines
* TOTAL : 312 lines

The visible (non-blanked) area is 404x284 pixels.

Finally, [this link](https://codebase64.org/doku.php?id=base:visible_area)
reports a total visible area of 402x292 pixels.

## Cropping by MiSTer
The MiSTer framework chooses to do some cropping on the output from the C64
core.  Without this cropping, undesired artifacts appear at the edges of the
screen when playing some demos, e.g. [Border
Intro](https://csdb.dk/release/?id=201955).

The cropping results in the following border sizes:

| Size          | pixels  |
| -----         | ------: |
| Left border   |  33     |
| Right border  |  31     |
| Top border    |  34     |
| Bottom border |  36     |

The total visible area is therefore 384x270.

