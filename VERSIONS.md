Version 5 - XXXXXXXX XX, 2023
=============================

@TODO: Dual SID

@TODO: Check, adjust/rewrite for clarity:
Cartridge release: Use hardware cartridges in the MEGA65's expansion port and
enjoy simulated cartridges using `*.crt` files. And you can now use custom
KERNALs such as JuffyDOS for the C64 and the C1541.

@TODO: For the release on Discord (and maybe also on the FileHost), we need a
short video that demonstrates how different cartridge types are inserted and
used (old to new, game, tool, GeoRAM, EasyFlash various models, ...) and then
also software cartridges.

## New Features

* More clearly arranged menu using submenus

* Hardware cartridges can be used in the MEGA65's expansion port. Most game
  cartridges are supported, including Ultimax game cartridges.

* The following more sophisticated hardware cartridges are supported:
  EasyFlash 1CR

@TODO: Check, if we can support at least REUs and other cartridges that are
not relying on the missing R3 signals (RESET, NMI and IRQ)

WIP Simulated cartridges using `*.crt` files:  @TODO we might not support
all cartridge types, add constraints here

WIP Ability to directly load `*.prg` files. This is especially useful in the
context of SID tunes which often come as stand alone `.prg` files
@TODO idea: M2M can offer a callback that is executed right before the
main loop of the shell starts. While PRG loading is like cartridge loading
but slightly different, the m2m-rom.asm main program can keep a state and then
jump to the C64's kernal function for RUN to start the program after loading.
Actually, what we need to do is: reset, load prg, run

WIP Ability to use custom KERNALs such as JiffyDOS for the C64 and the C1541:
Here is an idea how we can make this simple: Hardcoded filenames for ROM files
in the /c64 folder and then introduce dependent menu items for the M2M menu:
When Jiffy DOS is found, then a menu item called (for example) "Use JiffyDOS"
is shown in the "C64 Configuration". The dependent menu item would be a pure
"show/hide" thing, i.e. not influence the size of the config file and also
if from time to time JiffyDOS is not found (other SD card inserted), a
potential "switch ON" would not be forgotton next time it is being found.
For convenience we should have the option to reset the C64 if this setting
is changed. The dependency could be specified in config.vhd by specifying
bits in a register (other than the register we use for the menu?). We would
need quite some core specific code that resides in m2m-rom/m2m-rom.asm (and
callback functions that are for example called before the main loop starts and
that offer also a fatal mechanism for the authors of the callback; we should
just make the interface of FATAL public because is available everywhere).

* Stereo SID support: You can chose from multiple real dual SID combinations
  and enjoy stereo SID tunes and demos. And you can also use "pseudo stereo"
  by running the two different SID models 6581 and 8050 at the same (one left
  and one right) while they play the same mono tune.

WIP IEC Hardware port: @TODO: Idea: Drive #8 stays hardwired as it is but
you can plug other IEC devices (such as drives with #9 onwards) and printers
into the MEGA6's IEC port. Can be as simple as a single-select item:
"Enable hardware IEC port".

WIP 15khz RGB + csync:
https://discord.com/channels/719326990221574164/794775503818588200/1082080087891005500

## Improved C64 and C1541 Accuracy & Compatibility

* Improved the 6510 CPU's interrupt dispatching which results in more demos
  working flawlessly (for example "All Hallows' Eve", this fixes
  https://github.com/MJoergen/C64MEGA65/issues/9)

* Improved accuracy of the frequency ratio between the C64's CPU and the C1541
  floppy's CPU which results in more demos working flawlessly (for example
  "Unbounded" by Demotion and "Ice Cream Castle" by Crest). It also fixes an
  issue with the diskmag "Input 64"
  (https://github.com/MJoergen/C64MEGA65/issues/2)

* Merge MiSTer upstream fixes to improve simulation accuracy and compatibility
  with real hardware:
  - CIA: Disk parport: Ignore inputs on pins configured as output
    (MiSTer commit 4da804c, fix by sorgelig)
  - CIA: Fix timer reset values: Game "Arctic Shipwreck" works now and
    therefore this fixes https://github.com/MiSTer-devel/C64_MiSTer/issues/107
    (MiSTer commit 7eca7e3, fix by gyurco)
  - VIC: Change xscroll and turbo latch time
    (MiSTer commit f3a137b, fix by sorgelig)

## Improved HDMI Compatibility

* Works with more HDMI monitors, frame grabbers, HDMI switches, etc.
  The core was not compliant to section 4.2.7 of the HDMI specification
  version 1.4b: It did not assert the +5V power signal. Now it does
  assert the +5 power signal via the FPGA pin `ct_hpd`.

WIP HDMI compatibility: MJoergen research project to fix the HDMI sound on his
monitor which might lead to more HDMI compatibility in general. Research path:
Use an FPGA board with HDMI input, to capture the data from both the MEGA65
(has no sound) and the laptop (has sound), to compare them. Might very well
help to fix https://github.com/MJoergen/C64MEGA65/issues/4
And this: https://github.com/MJoergen/C64MEGA65/issues/13

WIP Eliminate HDMI Flicker-free "~20min period artefact" by manual clock
frequency tuning. Investigate dynamic PLL adjustment/autotune in conjunction
with ascal to improve flicker-free HDMI further (maybe there is a possibility
to achieve flicker-free without the need of slowing down by 0.25%)

## Bugfixes

* Fixed a bug in the REU simulation that affected some owners of the newest
  MEGA65 batches who have a so called "Revision D HyperRAM". One effect of the
  bug was that these users were not able to play Sonic the Hedgehog.

## Under the Hood

* Updated to Vivado 2022.2 which will result in higher quality bitstreams.

* Migrated to the newest version of the MiSTer2MEGA65 framework. The C64
  core will benefit from an easier and faster workflow when it comes to
  migrating new framework features to the core.

WIP HyperRAM device support to QNICE: @TODO Describe where this is used;
for example for the `*.crt` support as these files can become very large

WIP Refactor audio clock, video clock, (<=== already done | @TODO ==>)
asynchronous resets and other things around clk.vhd to reduce
warnings upon `report_cdc` and to make sure the whole clock architecture is
cleaner. (Also need to double-check M2M itself.)

Version 4 - November 25, 2022
=============================

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

Version 3 - June 27, 2022
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

Version 2 - June 18, 2022
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

Version 1 - April 26, 2022
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
