Version 3 - Month, Day 2022
===========================

This version is mainly a bugfix & compatibility release that is meant to
heavily increase the C64 compatibility of the core.

## Bugfixes

* CIA Bug fixed: The bug prevented demos like Comalight and Apparatus to run
  and in games like Commando, the joystick's fire button did not work.

* CIA Bug fixed: "icr3 set priority over clear", merged from from MiSTer to
  our codebase. This bug prevented games like Arkanoid to run.

* User Port "low active" bug fixed: The bug prevented games like
  Bomberman C64, that support a Multiplayer Joystick Interface
  (https://www.c64-wiki.com/wiki/Multiplayer_Interface), to work. Reason is,
  that due to the low-active nature of the User Port these games detected
  "ghost activites" on the (not existent) joystick connected via User Port.

* Zero Page register $01 has the correct default value $37 now. It had the
  wrong value $C7 due to two bugs that have been fixed:
  a) The Cassette Port's s SENSE and READ input are low active
  b) The wrapper code that turns the 6502 into a 6510 contained a bug

Version 2 - June, 18 2022
=========================

This version is mainly a bugfix & stability release: The focus was not to add
a lot of new features, but to make sure that the C64 core works flawlessly
with more MEGA65 machines than version 1 did. We also added a DVI option
(see below) to increase the amount of displays that work with the core.

## Bugfixes

* MAX10 reset bug fixed: Fixes the "ambulance lights" problem when starting
  the core and fixes non-working reset buttons
* SD card problem fixed: When neither any D64 file was present on the SD card
  and additionally, there was not a single subdirectory, then the core
  crashed with "Corrupt memory structure: Linked-list boundary" when one tried
  to mount a disk.
* Fixed distorted On-Screen-Menu in "VGA Retro 15KHz RGB" mode

## DVI Option

* The DVI option is meant to improve the compatibility with certain monitors.
  Choosing "HDMI: DVI (no sound)" in the On-Screen-Menu will activate it and
  thus stop sending sound packages within the HDMI data stream.

Version 1 - April, 26 2022
==========================

Experience the Commodore 64 with great accuracy and sublime compatibility
on your MEGA65! It can run a ton of games and demos and it offers convenient
features.

## Features

* PAL standard C64 (running standard KERNAL and standard C1541 DOS)
* PAL 720 x 576 pixels (4:3) @ 50 Hz via VGA: for a true retro feeling
* 720p @ 50 Hz or 60 Hz (16:9) via HDMI: for convenience
* Sound output via 3.5mm jack and via HDMI
* SID 6581 and 8580
* MEGA65 keyboard support (including cursor keys)
* Joystick support
* On-Screen-Menu via Help button to mount drives and to configure options
* C1541 read-only support: Mount standard `*.D64` via SD card to drive 8
* Drive led during virtual disk access
* CRT filter: Optional visual scanlines on HDMI so that the output looks more
  like an old monitor or TV
* Crop/Zoom: On HDMI, you can optionally crop the top and bottom border of
  the C64's output and zoom in, so that the 16:9 screen real-estate is
  utilized more efficiently. Great for games.
* Audio processing: Optionally improve the raw audio output of the system
* Smart reset: Press the reset button briefly and only the C64 core is being
  reset; press it longer than 1.5 seconds and the whole machine is reset.

## Constraints (What is not yet working) & Roadmap

### Feature Roadmap

We are planning to improve this core steadily. The MiSTer core offers many
more features than our current Release 1 of the port. Here is a list of
features (in no particular order) that we are planning to deliver at a later
stage:

* NTSC
* Support two drives: 8 and 9
* Dual SID
* Writing to virtual disks
* Ability to save the settings of the core
* More sophisticated scalers and scandoublers
* Tape mounting via SD card
* Directly load program files (`*.PRG`)
* Cartridge mounting via SD card (`*.CRT`)
* Support for raw GCR mode (`*.G64`)
* C1581 virtual drive support via SD card (`*.D81`)
* Alternative KERNAL & Floppy Disk ROMs and fast loaders
* Parallel C1541 port for faster (~20x) loading time using DolphinDOS
* REU and GeoRAM using HyperRAM
* The following MEGA65 hardware ports are not yet working:
  * Cartridges via the MEGA65's hardware Expansion Port
  * Paddles / mouse via the joystick ports
  * IEC port (for example to plug in a real C1541)	
  * C1581 via MEGA65's disk drive
  * REU via expansion port
* Utilize full 16:9 screen real estate for file- and directory browsing and
  core configuration on HDMI while saving screen real estate on 4:3 VGA
* Simulate the blending of colours when ALM and DCM are used
  as described here: https://github.com/MiSTer-devel/C64_MiSTer/issues/104

### Technical Roadmap

To implement some of the above-mentioned features and also to improve the
robustness, performance, and stability of the whole system, we will need
to implement certain technical improvements in the "backend", again in no
particular order:

* Support for R2 version of MEGA65
* VGA retro CSync generation
* Fix the behavior of the floppy led
* Fix visible tearing in Bromance demo (vertical scroll effect), but only,
  when HDMI Zoom is ON: https://csdb.dk/release/?id=205526
* Update to newer ascal version (wait until MiSTer does the same upstream)
* Investigate dynamic PLL adjustment/autotune in conjunction with ascal
  to improve flicker-free HDMI further (maybe there is a possibility to
  achieve flicker-free without the need of slowing down by 0.25%)
* Re-do QNICE's SD Card controller: Go from SPI to native
* Enhance QNICE's FAT32 library so that it supports writing
* HyperRAM device support to QNICE
* Hardware debugger (single-step the CPU via the on-screen-menu)
* Line 65 in fdc1772.v: back to 2 or work with generic?
