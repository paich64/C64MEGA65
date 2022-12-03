Version 5 - XXXXXXXX, XX, 2023
==============================

Hardware compatibility release: Use the MEGA65's hardware ports for more retro
fun! Stick cartridges into the expansion port, work with real floppy drives
and printers using the IEC port and use the MEGA65's built-in disk drive as
a C1581. Furthermore, use a vast array of simulated hardware with full support
for `*.crt` modules, `*.d81` C1581 disk images, `*.g64` GCR encoded disk
images and `*.t64` tape images.

## New Features

WIP Hardware modules via expansion port: @TODO we might not support
all module types, add constraints here: Game cartriges, real REUs, GEO RAMs,
EasyFlash, etc. ... we need to test quite some amount of real hardware

WIP Simulated modules using `*.crt` files:  @TODO we might not support
all module types, add constraints here

WIP Hardware IEC port: Work with real floppy drives, printers and other serial
devices.

WIP Use the MEGA65's built-in disk drive as a C1581.

WIP Simulated C1581 via `*.d81` disk images. @TODO: Clarify: Line 65 in
fdc1772.v: back to 2 or work with generic?

WIP GCR encoded disk images (`*.g64`)

WIP Existing C1541 disk images (`*.d64`) can now be formatted

WIP Support `*.d64` images with error maps (filesizes 175,531 and 197,376)

WIP Simulated tape drive using `*.t64` tape images

WIP Directly load program files (`*.prg`)

## Improved C64 and C1541 Accuracy & Compatibility

WIP ??? research MiSTer's SID improvements ???

WIP Improved C1541 compatibility due to real internal GCR handling of `*.d64`
images instead of simulated handling leads to games like "Seven Cities of
Gold" being able to format/create their non-standard game disks. Also highly
sophisticated bit nibblers (@TODO example!) are working now.

* Improved the 6510 CPU's interrupt dispatching which results in more demos
  working flawlessly (for example "All Hallows' Eve")

* Improved accuracy of the frequency ratio between the C64's CPU and the C1541
  floppy's CPU which results in more demos working flawlessly (for example
  "Unbounded" by Demotion and "Ice Cream Castle" by Crest). It also fixes an
  issue with the diskmag "Input 64". @TODO: Redo README.md because after this
  fix we will have no known issue due to HDMI: Flicker-free any more.

* Merge MiSTer upstream fixes to improve simulation accuracy and compatibility
  with real hardware:
  - CIA: Disk parport: ignore inputs on pins configured as output
    (MiSTer commit 4da804c, fix by sorgelig)
  - CIA: Fix timer reset values: Game "Arctic Shipwreck" works now and
    therefore this fixes https://github.com/MiSTer-devel/C64_MiSTer/issues/107
    (MiSTer commit 7eca7e3, fix by gyurco)
  - VIC: change xscroll and turbo latch time (sorgelig)
    (MiSTer commit f3a137b)

## Improved HDMI and VGA Compatibility

WIP HDMI compatibility: MJoergen research project to fix the HDMI sound on his
monitor which might lead to more HDMI compatibility in general. Research path:
Use an FPGA board with HDMI input, to capture the data from both the MEGA65
(has no sound) and the laptop (has sound), to compare them. Might very well
help to fix https://github.com/MJoergen/C64MEGA65/issues/4

WIP VGA compatibility: Fixed a "wavy" "underwater" artefact on that was
introduced by Version 4 and that occured only on some analog VGA screens.

WIP Eliminate HDMI Flicker-free "~20min period artefact" by manual clock
frequency tuning. Investigate dynamic PLL adjustment/autotune in conjunction
with ascal to improve flicker-free HDMI further (maybe there is a possibility
to achieve flicker-free without the need of slowing down by 0.25%)

## Bugfixes

WIP @TODO: Identify bugs and add them here

## Under the Hood

WIP Updated to Vivado 2022.2 which will result in higher quality bitstreams.

WIP Migrated to the newest version of the MiSTer2MEGA65 framework. The C64
core will benefit from an easier and faster workflow when it comes to
migrating new framework features to the core.

WIP Maximize compatibility of C1541 by implementing MiSTer's raw GCR mode
which exclusively uses GCR internally (c1541_direct_gcr.sv instead of
c1541_gcr.sv). `*.D64` images are converted to/from GCR when reading/writing
from SD card.

WIP HyperRAM device support to QNICE: @TODO Describe where this is used;
for example for the `*.crt` support as these files can become very large

WIP Refactor audio clock, video clock, (<=== already done | @TODO ==>)
asynchronous resets and other things around clk.vhd to reduce
warnings upon `report_cdc` and to make sure the whole clock architecture is
cleaner. (Also need to double-check M2M itself.)

WIP Put major/minor version in the first two bytes of the config file so that
in case of a mismatch a warning can be issued (e.g. by directly printing it
into the C64's screen RAM). Needs new version of make_config.sh.

Version 4 - November, 25, 2022
==============================

Productivity release: Write support for the virtual C1541 and a 512 KB RAM
Expansion Unit (1750 REU) are the main features: Save your high-scores and
your gaming progress to disk (D64) and work productively with GEOS by speeding
up 10x using the REU and by saving your work persistently to disk.
Demo fans can now enjoy all the awesome REU releases on CSDB and gamers can
play the fantastic Sonic the Hedgehog for REU.

## New Features

* C1541 write support using D64 image files on the SD card.

* Read/write support for non-standard D64 images with 40 tracks and no error
  bytes, i.e. additionally to D64 files that are exactly 174,848 bytes in size
  you can now also use files that are 196,608 bytes in size.

* 1750 REU support: The REU is as close to cycle accurate as it can go. It is
  not perfect, but 99.9% perfect - it even runs the picky
  [TreuLove_ForReal1750Reu.d64](http://csdb.dk/getinternalfile.php/144854/TreuLove_ForReal1750Reu.d64)
  version of Booze Design's Treu Love demo
  ([see CSDB page](https://csdb.dk/release/?id=144105))
  that is supposed to only run on real hardware. The REU also works perfectly
  with GEOS. You can switch the REU on/off using the options menu.

* Choice between 16:9 or 4:3 HDMI output resolutions: By default the core
  outputs 720p on HDMI which is a 16:9 resolution (even though the actual
  C64's output is pixel-perfect 4:3 as we are adding black bars left and
  right). With this new feature you can switch from 720p to 576p aka
  PAL over HDMI (720x576 pixels) and then select if you have a 4:3 monitor
  or a 5:4 monitor and then enjoy the best possible image.

* Ability to save the configuration settings of the core. You need to copy
  the file c64mega65 to the folder /c64 to activate this feature.

* CIA: New option to configure CIA version (6526 or 8521): There is at least
  one demo known - XXX from Lethargy - where the demo only runs flawlessly if
  the CIA is a 8521.

* Mouse: Support for C64 mice and MouSTer

* Reduced joystick latency from 5ms to 1ms by decreasing the stable time of
  the signal debouncer.

## Bugfixes

* The drive led is not blinking any more during normal read/write operations.
  It behaves now like the real drive led and only blinks on errors.

* Fixed a small (probably inaudible) SID bug by merging
  [this](https://github.com/MiSTer-devel/C64_MiSTer/commit/711dffbddf0b591fadfe81e4e3ed4dd3af6be143)
  an upstream fix from MiSTer.

* Fixed several bugs in the file browser that you use for mounting D64 files:

  - The file browser was not able to display the "+" sign due to a bug
    in the font. Instead, a space (empty character, " ") was printed, for
    example the file name "C64+" was shown as "C64 ".

  - Directories where not aways being sorted in proper alphabetical order and
    ascending numbers.

  - While browsing directories with a large amount of subdirectories (e.g.
    large game libraries): When you entered a subdirectory located on a page
    other than page one (e.g. by scrolling down quite a bit) and then left
    this very subdirectory (one level up), then the selection cursor jumped
    back to page one.

  - Fixed file browsing bug that still displayed the old SD card's
    directory when you changed the SD card while the file browser was *not*
    open. (The bug did not occur when you changed the SD card while the file
    *was* open.)

## Known problems that we plan to fix in Version 5

* Formatting disks does not work. We know how to fix it but this will need a
  larger refactoring (see "Technical Roadmap" in `ROADMAP.md`).

* The demo "All Hallows' Eve" (https://demozoo.org/productions/314618/) is
  crashing towards the end of disk 2. We fixed the issue in an experimental
  core that you can download here on GitHub:
  https://github.com/MJoergen/C64MEGA65/issues/9

* There is a compatibility issue due to the "HDMI: Flicker-free" mode. We only
  saw it occur at the German disk magazine "Input 64 Issue 1/85" and at the
  1991 demo Unbounded by Demotion (https://csdb.dk/release/?id=2464). We fixed
  the issue in an experimental core that you can download here on GitHub:
  https://github.com/MJoergen/C64MEGA65/issues/2

Version 3 - June, 27 2022
=========================

This version is mainly a bugfix & compatibility release that is meant to
heavily increase the C64 compatibility of the core. It also adds support
for Paddles.

## New Feature

* Support for Paddles added: Connect compatible paddles to the joystick ports.

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
  (a) The Cassette Port's s SENSE and READ input are low active.
  (b) The wrapper code that turns the 6502 into a 6510 contained a bug.

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
