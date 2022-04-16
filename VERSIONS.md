Version 1 - Month, DD 2022
====================================

Experience the Commodore 64 with great accuracy and sublime compatibility
on your MEGA65! It can run a ton of games and demos and it offers convenient
features.

## TODOs before release

* Make sure that the MiSTer2MEGA65 framework is updated accordingly
  as soon as all of this works

* MiSTer Features:
   - CRT mode
   - audio processing

* File Browser:
  - Unmount whole disk drive via Space in OSM
  - (Maybe/think about it) Show F1/F3 help at the bottom of the screen
  - Show flashing/blinking "Loading..." when loading large subdirectories
    where you are otherwise staring at an "empty blue frame" while it is
    loading.
  - Show flashing/blinking "Loading..." while the actual disk image is mounted

* General robustness:
  - Double-check if the keyboard reading "via both CIA directions" is actually
    working; maybe this is the PBIS crack-not-working reason (issue #1)
  - Do the final heap/stack sanity check in m2m-rom.asm
  - Try to reduce warnings in general and in CDC in particular

* Code consistency and "niceness":
  - Move reset manager and debouncer from top level file to mega65.vhd
  - Refactor mega65.vhd so that it becomes less crowded
  - Review all documentation and README's
  - run    grep -irn mark_debug .
    in these folders and remove all debug signals:
    M2M/vhdl
    MEGA65/vhdl
    (C64_MiSTerMEGA65 is already clean.)

* Bugs:
   - HDMI reset problem
   - Visible tearing in Bromance demo (vertical scroll effect), but only,
     when HDMI Zoom is ON:
     https://csdb.dk/release/?id=205526
   - Deactivation of joysticks via QNICE does not work

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
* CRT filter: Optional visual scanlines so that the output looks more like an
  old monitor or TV
* Crop/Zoom: On HDMI, you can optionally crop the top and bottom border of
  the C64's output and zoom in, so that the 16:9 screen real-estate is
  utilized more efficiently. Great for games.
* Audio processing: Optionally improve the raw audio output of the system
* Smart reset: Press the reset button briefly and only the C64 core is being
  reset; press it longer than 1.5 seconds and the whole machine is reset.

## Constraints (What is not yet working) & Roadmap

### Feature Roadmap

We are planning to improve this core steadily. The MiSTer core offers much
more features than our current Release 1 of the port. Here is a list of
features that we are planning to deliver at a later stage:

* NTSC
* Support two drives: 8 and 9
* Dual SID
* Writing to virtual disks
* Ability to save the settings of the core
* More sophisticated scalers and scandoublers
* Tape mounting via SD card
* Cartridge mounting via SD card
* Alternative KERNAL & Floppy Disk ROMs and fast loaders
* Support for raw GCR mode (`*.G64`)
* C1581 virtual drive support via SD card (`*.D81`)
* Parallel C1541 port for faster (~20x) loading time using DolphinDOS
* REU and GeoRAM using HyperRAM
* The following MEGA65 hardware ports are not yet working
  * Cartridges via the MEGA65's hardware Expansion Port
	* Paddles / mouse via the joystick ports
	* IEC port (for example to plug in a real C1541)	
	* C1581 via MEGA65's disk drive
	* REU via expansion port
* Utilize full 16:9 screen real estate for file- and directory browsing and
  core configuration on HDMI while saving screen real estate on 4:3 VGA

### Technical Roadmap

To implement some of the above-mentioned features and also to improve the
robustness, performance and stability of the whole system, we will need
to implement certain technical improvements in the "backend":

* Update to newer ascal version (wait until MiSTer did the same upstream)
* Investigate dynamic PLL adjustment/autotune in conjunciton with ascal
  to improve flicker-free HDMI further (maybe there is a possibility to
  achieve flicker-free without the need of slowing down by 0.25%)
* Re-do QNICE's SD Card controller: Go from SPI to native
* Enhance QNICE's FAT32 library so that it supports writing
* HyperRAM device support to QNICE
* Hardware debugger (single-step the CPU via the on-screen-menu)
* Line 65 in fdc1772.v: back to 2 or work with generic?
