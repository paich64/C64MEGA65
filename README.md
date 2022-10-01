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
[sy2002](http://www.sy2002.de) ported the core to the MEGA65 in 2022.

The core uses the [MiSTer2MEGA65](https://github.com/sy2002/MiSTer2MEGA65)
framework and [QNICE-FPGA](https://github.com/sy2002/QNICE-FPGA) for
FAT32 support (loading ROMs, mounting disks) and for the
on-screen-menu.

Features
--------

With our [Release 3](VERSIONS.md), we are striving for a **retro C64 PAL
experience**: The core turns your MEGA65 into a Commodore 64, with a
C1541 drive, a pair of Joysticks, a Mouse and/or Paddles. No frills.
The C64 runs the original Commodore KERNAL and the C1541 runs the original
Commodore DOS, which leads to authentic loading speeds. You will be surprised,
how slowly the C64/C1541 were loading... :-)

And you will be amazed by the 99.9% compatibility that this core has when it
comes to games, demos and other demanding C64 software. Some demos are even
recognizing this core as genuine C64 hardware.

### Video and Audio

* HDMI: The core outputs 1280×720 pixels (720p) at 50 Hz and HDMI audio at
  a sampling rate of 48 kHz. This is supported by a vast majority of monitors
  and TVs. In case of compatibility problems, you can switch the HDMI video
  out to 60 Hz (without affecting the PAL core's internal 50 Hz), but this
  would lead to a slightly jerky experience when it comes to scrolling and
  other fast movements on the screen. The 4:3 aspect ratio of
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
* CRT filter: Optional visual scan lines via HDMI so that the output looks more
  like an old monitor or TV
* Crop/Zoom: On HDMI, you can optionally crop the top and bottom border of
  the C64's output and zoom in, so that the 16:9 screen real-estate is
  better utilized and you have a larger picture. Great for games.
* Audio processing: Optionally improve the raw audio output of the system

### Constraints and Roadmap

Our Release 3 is still an early release. Thanks to all the folks who
[contributed](AUTHORS) to the core, it is incredibly compatible to an original
Commodore 64. With our Release 3 you can play nearly all the available games
and watch almost all demos ever written for the C64. It happens more often
than not, that the core is recognized as real hardware by software.

At this moment, our MEGA65 version of the core is not supporting
some of the very nice hardware offerings that the MEGA65 makes, such as:

* Expansion port: Support hardware cartridges
* IEC port: Support real drives, printers, ...
* Use the MEGA65's drive as a C1581

Also, some things that folks would consider as "basic stuff" are not
supported yet, such as:

* NTSC mode
* Mounting tapes (`*.tap`)
* Mounting cartridges (`*.crt`)

The MiSTer core, which is the basis of this MEGA65 core offers a ton of
additional convenience features and nerdy stuff. We are not yet supporting
most of it. Have a look at our [Roadmap](ROADMAP.md)
to learn more.

Since we do this as a hobby, it might take a year or longer until these
things are supported. So please bear with us or [help us](CONTRIBUTING.md).

Some demo pictures
------------------

| ![c64-1](doc/demopics/c64mega65-1.jpg)    | ![c64-2](doc/demopics/c64mega65-2.jpg)   | ![c64-3](doc/demopics/c64mega65-3.jpg) | 
|:-----------------------------------------:|:----------------------------------------:|:--------------------------------------:| 
| *Core Menu*                               | *Disk mounting / file browser*           | *Giana Sisters*                        |
| ![c64-4](doc/demopics/c64mega65-4.jpg)    | ![c64-5](doc/demopics/c64mega65-5.jpg)   | ![c64-6](doc/demopics/c64mega65-6.jpg) | 
| *Neon/Triad*                              | *Memento Mori/Genesis Project*           | *Relentless*                           |

Clarification: These screenshots are just for illustration purposes.
This repository does not contain any copyrighted material.

Installation
------------

Make sure that you have a MEGA65 R3, R3A or newer. At the moment, we are not
supporting older R2 machines. If you are not sure what MEGA65 version you have
then you very probably have an R3, R3A or newer: The Devkits are R3 and the
machines from Trenz are R3A.

1. [Download](https://github.com/MJoergen/C64MEGA65/releases/download/V3/C64MEGA65-V3.zip)
   the ZIP file that contains the bitstream and the core file and unpack it.
2. Copy the `.cor` file on an SD card that has been formatted using the
   MEGA65's built-in formatting tool. If you want to be on the safe side, just
   use the internal SD card (bottom tray), which is formatted like this
   by default.
3. Read the section "How do I install an alternative MEGA65 core?" on the
   [alternative MEGA65 cores](https://sy2002.github.io/m65cores/index.html)
   website or read the section "Bitstream Utility" in the
   [MEGA65 Starter Guide](https://files.mega65.org/news/MEGA65-Starter-Guide.pdf).
4. The core supports FAT32 formatted SD cards to mount `.D64` disk images
   for the C1541 at drive 8.
5. If you put your disk images into a folder called `/c64`, then the core will
   display this folder on startup. Otherwise the root folder will be shown.
6. Press the <kbd>Help</kbd> key on your MEGA65 keyboard as soon as the core
   is running to mount disks and to configure the core.

If you are a developer and/or have a JTAG adaptor connected to your MEGA65,
then you can use the `.bit` file from the ZIP instead of the `.cor` file:
Run the [M65 tool](https://github.com/MEGA65/mega65-tools) using this
syntax `m65 -q yourbitstream.bit` and the core will be immediately loaded
into the FPGA of the MEGA65 and automatically started.

HDMI compatibility
------------------

Right now, the C64 core is not compatible with all HDMI displays. If your
display works with the MEGA65 core but stays black when you load the C64 core,
then try this (while the display is black):

1. Boot the C64 core and wait a few seconds.
2. Press the <kbd>Help</kbd> key.
3. Press four times (4x) the <kbd>Up</kbd> cursor key.
4. Press <kbd>Return</kbd>.
5. Wait a few seconds.
6. If this does not solve the issue, continue:
7. Press one more time (1x) the <kbd>Up</kbd> cursor key.
8. Press <kbd>Return</kbd>.
9. Wait a few seconds.

### Explanation: DVI mode

The recipe above first activates the "DVI mode" as you are choosing the
menu item "HDMI: DVI (no sound)" in the On-Screen-Menu when you press the
<kbd>Return</kbd> key for the first time.

In DVI mode, the HDMI data stream sent by the core to your display has a
slightly different format and it does not contain any sound. You need to use
the 3.5mm audio-out in this case.

When you press <kbd>Return</kbd> for the second time, the 60Hz mode is
activated, independent of the C64's output, which is still 50Hz in PAL mode.
This works fine in general, but leads to some flickering here and there.

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
  Currently, we only support `.d64`.

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
most cases and you probably will never notice.

But the advantage of this 0.25% slowdown is a clean 50 Hz signal for your
HDMI display. We believe that this is the most compatible way of providing
a flicker-free experience on HDMI.

### Compatibility

If you experience issues, then you can switch the core back to 100% system
speed. The menu item for doing so is called "HDMI: Flicker-free".

Please note that the C64 core will reset each time you toggle the
"HDMI: Flicker-free" switch, the system clock speed is switched between
99.75% and 100% back and forth.

Here is a small test-case for you to experience the difference by yourself:

1. Switch OFF "HDMI: Flicker-free" and load The Great Giana Sisters and
   watch the title scroller: Every ~8 seconds, you will see a jerky movement
   and tearing. The same will happen when you play the game. And this
   effect is not only there at Giana Sisters but at everything that
   scrolls and/or moves a lot of things on the screen.

2. Switch ON "HDMI: Flicker-free" and load the disk and tape magazine
   [Input 64 Issue 1/1985](https://c64-online.com/?ddownload=4459).
   You will not see the intro which consists of flying letters
   building up the word "Input 64". So here we see an example of a
   compatibility issue.

3. Switch OFF "HDMI: Flicker-free" and load Input 64 again. It now works.
   You can watch the intro.

So you have the choice: Flicker-free on HDMI or more compatibility.

Our tests have shown, that the vast majority of software works like a charm
and the value of having a completely smooth and flicker free experience on
HDMI seems therefore larger than slight compatibility issues. This is why
this feature is activated by default.

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
  is particularly useful when browsing large hierarchies of disk images.
  Imagine being in the fourth folder hierarchy of your disk image collection,
  browsing on page 10 of hundreds of files and then pressing reset: While
  a hard-reset let's you start over, including - again - browsing to the
  fourth folder of your disk image collection to page 10, the soft-reset
  let's you continue exactly where you left off.

* Hard-reset: The whole system is reset. All settings in the options menu
  are back to factory defaults and the file browsing starts over.
