Commodore 64 for MEGA65
=======================

Experience the [Commodore 64](https://en.wikipedia.org/wiki/Commodore_64) with
great accuracy and sublime compatibility on your
[MEGA65](https://mega65.org/)!

Learn more about where to [download and how to get started](#Installation).

![Commodore64](doc/c64.jpg)

This core is based on the
[MiSTer](https://github.com/MiSTer-devel/C64_MiSTer) Commodore 64 core which
itself is based on the work of [many others](AUTHORS).

[MJoergen](https://github.com/MJoergen) and
[sy2002](http://www.sy2002.de) ported the core to the MEGA65 in 2021.

The core uses the [MiSTer2MEGA65](https://github.com/sy2002/MiSTer2MEGA65)
framework and [QNICE-FPGA](https://github.com/sy2002/QNICE-FPGA) for
FAT32 support (loading ROMs, mounting disks) and for the
on-screen-menu.

Features
--------

With our [Release 1](VERSIONS.md), we are striving for a **retro C64 PAL
experience**: The core turns your MEGA65 into a Commodore 64, with a
C1541 drive and a pair of Joysticks. No frills. The C64 runs the original
Commodore KERNAL and the C1541 runs the original Commodore DOS, which leads to
authentic loading speeds. You will be surprised, how slowly the C64/C1541
were loading... :-)

And you will be amazed by the 99.9% compatibility that this core has when it
comes to games, demos and other demanding C64 software. Some demos are even
recognizing this core as genuine C64 hardware.

### Video and Audio

* HDMI: The core outputs 1280×720 pixels (720p) at 50 Hz and HDMI audio at
  a sampling rate of 48 kHz. This is supported by a vast majority of monitors
  and TVs. In case of compatibility problems, you can switch the HDMI video
  out to 60 Hz (without affecting the PAL core's internal 50 Hz), but this
  would lead to a slightly jerky experience when it comes to scrolling and
  other fast movements on the screen. The 4:3 ascpect ratio of
  the C64's output is preserved during upscaling, so that even though 720p
  is a 16:9 picture, the C64 looks pixel perfect and authentic on HDMI.
  
* VGA: For a true retro feeling, we are providing a 4:3 image via the
  MEGA65's VGA port, so that you can connect real CRT monitors or older
  4:3 LCD/TFT displays. The resolution is 720x576 pixels and the frequency
  is 50.125 Hz in PAL mode. If your monitor supports this, you will
  experience silky smooth scrolling without any flickering and tearing.
  
* Retro 15 KHz RGB over VGA: This is for the ultimate retro experience:
  Connect an old Scart TV (for example using
  [this](https://ultimatemister.com/product/rgb-scart-cable/)
  cable) or an old RGB-capable monitor (by soldering your own cable)
  to MEGA65's VGA port.
  
### Convenience

* On-Screen-Menu via the MEGA65's <kbd>Help</kbd> key to mount disk images
  and to configure the core
* Realtime switching between a 6581 SID and a 8580 SID
* CRT filter: Optional visual scanlines so that the output looks more like
  an old monitor or TV
* Crop/Zoom: On HDMI, you can optionally crop the top and bottom border of
  the C64's output and zoom in, so that the 16:9 screen real-estate is
  better utilized and you have a larger picture. Great for games.
* Audio processing: Optionally improve the raw audio output of the system

### Constraints and Roadmap

Our Release 1 is - well - a Release 1. Thanks to all the folks who
[contributed](AUTHORS) to the core, it is incredibly compatible to an original
Commodore 64. With our Release 1 you can play nearly all the avilable games
and watch almost all demos ever written for the C64. It happens more often
than not, that the core is recognized as real hardware by software.

At this moment, our MEGA65 version of the core is not supporting
some of the very nice hardware offerings that the MEGA65 makes, such as:

* Mouse / Paddles
* Expansion port: Support hardware cartridges
* IEC port: Support real drives, printers, ...
* Use the MEGA65's drive as a C1581

Also, some things that folks would consider as "basic stuff" are not
supported yet, such as:

* NTSC mode
* Mounting tapes (`*.tap`)
* Mounting cartridges (`*.crt`)
* Writing to mounted disks (all file operations are read-only)

The MiSTer core, which is the basis of this MEGA65 core offers a ton of
additional convenience features and nerdy stuff. We are not yet supporting
most of it. Have a look at our [Roadmap](VERSIONS.md#feature-roadmap)
to learn more.

Since we do this as a hobby, it might take a year or longer until these
things are supported. So please bear with us or [help us](CONTRIBUTING.md).

Installation
------------

1. [Download @TODO LINK](https://github.com/MJoergen/C64MEGA65/edit/dev-mount/README.md)
   the ZIP file that contains the bitstream and the core file and unpack it.
2. Choose the right subfolder depending on the type of your MEGA65:
   `R2` or `R3`. If you are not sure which one to choose, it's likely that
   you have an `R3`. You will need the `.cor` file.
3. Read the section "How do I install an alternative MEGA65 core?" on the
   [alternative MEGA65 cores](https://sy2002.github.io/m65cores/index.html)
   website or read the section "Bitstream Utility" in the
   [MEGA65 Starter Guide](https://files.mega65.org/news/MEGA65-Starter-Guide.pdf).
4. The core supports FAT32 formatted SD cards to mount `.D64` disk images
   for the C1541 at drive 8.
5. If you put your disk images into a folder called `/c64`, then the core will
   display this folder on startup. Otherwise the root folder will be shown.

If you are a developer and/or have a JTAG adaptor connected to your MEGA65,
then you can use the `.bit` file from the ZIP instead of the `.cor` file:
Run the [M65 tool](https://github.com/MEGA65/mega65-tools) using this
syntax `m65 -q yourbitstream.bit` and the core will be immediately loaded
into the FPGA of the MEGA65 and automatically started.

How to use the file- and directory browser for mounting a disk image
--------------------------------------------------------------------

Thanks to long filename support and alphabetically sorted file- and directory
listings, mounting a disk image is straightforward. Press MEGA65's
<kbd>Help</kbd> key to open the on-screen-menu while the C64 is running
and select `8:<Mount Drive>` using the cursor keys and <kbd>Return</kbd>.
Here is how the browser works:

* Navigate up/down using the <kbd>Cursor up</kbd> and
  <kbd>Cursor down</kbd> keys
* Page up and page down using the <kbd>Cursor left</kbd> and
  <kbd>Cursor right</kbd> keys
* <kbd>Return</kbd> mounts a disk image
* <kbd>Run/Stop</kbd> exits the file browser without mounting
* Remembers the browsing history, i.e. even while you climb directory trees,
  when you mount the next image, the file selection cursor is positioned where 
  you left off. This is very convenient for mounting multiple subsequent
  disks of a demo in a row.
* Support for both SD card slots: The back slot has precedence over the bottom
  slot: As soon as you insert a card to the back slot, this card is being
  used. SD card changes are detected in real-time; also while the
  file browser is open.
* Within the file browser you can use <kbd>F1</kbd> to manually select
  the internal SD card (bottom tray) and <kbd>F3</kbd> to select the
  external SD card (back slot).
* The disk image is internally buffered, which means you can remove or
  switch the SD card even while the C64 is accessing the disk.
* An already mounted drive can be unmounted (i.e. "switch the drive off"), if
  you select it in the <kbd>Help</kbd> menu using the <kbd>Space</kbd> bar.
  If you select an already mounted drive with the <kbd>Return</kbd> key
  instead, then for the C64 this is more like switching a diskette while
  leaving the drive on. Use the latter mechanism via <kbd>Return</kbd> when
  a game or a demo asks you to turn the disk or to insert another disk.
* The file browser defaults to the folder `/c64` in case this folder exists.
  Otherwise it starts at the root folder.
* The file browser only shows files with a valid file extension.
  Currently, we only suppoert `.d64`.
  
Flicker-free HDMI
-----------------

When you use an emulator on your computer, you very probably will
experience jerky movements on the screen and tearing effects
because a lot of computer monitors are running at 60 Hz or higher
while the Commodore 64 had a pretty odd frequency.
Even if it would have been exactly 50 Hz, you would experience this on a
modern computer using emulation, and imagine that: The C64 is closer to
50.125 Hz than to 50 Hz, so it gets even worse... As a reference, just
start the legendary game
[The Great Giana Sisters](https://csdb.dk/release/?id=4829)
on your favorite emulator on your computer and then watch the title
scroller / intro. You will see a pretty stuttering scroller.

Not so when using a FPGA based recreation on the MEGA65 using the right
display and settings. We have your back! :-)

When using VGA or Retro 15 KHz RGB, you are safe by definition, if your
monitor plays along.

We are slowing down the whole system (not only the C64, but also the SID,
VIC, C1541, ...), so that it runs at only 99.75% of the original clock
speed of the C64. This does not decrease the compatibility of the core in
any way and you probably will never notice.

But the advantage of this 0.25% slowdown is a clean 50 Hz signal for your
HDMI display. We believe that this is the most compatible way of providing
a flicker-free experience on HDMI.

Hard-reset vs soft-reset
------------------------

If you press the reset button of your MEGA65 briefly, i.e. less than 1.5
seconds, you will do a soft-reset. A long press does a hard-reset. Here is
the difference between the two:

* Soft-reset: Do not force the reset for the C64 core. The C64 has a quite
  [sophisticated reset behavior](http://tech.guitarsite.de/cbm80.html),
  and some demos - such as
  ["That's the Way It Is"](https://csdb.dk/release/?id=11775&show=hidden) -
  make use of that, so that you can start certain parts when
  pressing the reset button. And also some games did - as a copy
  protection. This can be annoying when you want to exit a game and cannot:
  [Uridium](https://csdb.dk/search/?seinsel=all&search=uridium&Go.x=0&Go.y=0)
  and
  [Eagle's Nest](https://csdb.dk/search/?seinsel=all&search=eagles+nest&Go.x=0&Go.y=0)
  are examples for this. The bottom line is: A
  soft reset will allow you to enjoy the original behavior including "reset
  demos" but you will also be stuck with the drawbacks.

* Hard-reset: The core is doing a "forced reset" by simulating what is
  described [here](https://www.c64-wiki.com/wiki/Reset_Button) and what
  modules like the Action Replay did. This will always reset the machine.

There is another difference between the hard-reset and the soft-reset that is
more related to your convenience while using the file browser and the 
options menu:

* Soft-reset: Only reset the C64 core. Advantage: All your options/settings
  remain intact and your file browser continues where you left off. The latter
  is particularly useful when browing large hierarchies of disk images.
  Imagine being in the fourth folder hierarchy of your disk image collection,
  browsing on page 10 of hundreds of files and then pressing reset: While
  a hard-reset let's you start over, including - again - browsing to the
  fourth folder of your disk image collection to page 10, the soft-reset
  let's you continue exactly where you left off.

* Hard-reset: The whole system is reset. All settings in the options menu
  are back to factory defaults and the file browsing starts over.
