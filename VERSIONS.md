Version 1 - Month, DD 2022
====================================

Experience the Commodore 64 with great accuracy and sublime compatibility
on your MEGA65! It can run a ton of games and demos and it offers convenient
features.

## TODOs before release

* Flicker-free HDMI: Implement the three menu options:
  - "Best: 50.125 Hz" means "C64 at original speed and HDMI at 50.125 Hz"
  - "OK: C64 0.25% slow" means "C64 0.25% slow and HDMI at 50 Hz"
   " Off: 60 Hz" means "C64 at original speed and HDMI at 60 Hz"

* 15KHz RGB mode over VGA

* File Browser:
  - Unmount whole disk drive via Space in OSM
  - Make sure that the MiSTer2MEGA65 framework is updated accordingly
    as soon as all of this works

* General robustness:
  - Do the final heap/stack sanity check in m2m-rom.asm and replace
    0xXXXX by the calculated values
  - Debounce the joystick and the MEGA65's reset button
    (add to MiSTer2MEGA65 from gbc4mega65)
    => needs to go to the framework, too
  - Implement a hard reset as described in
    https://www.c64-wiki.com/wiki/Reset_Button
    because right now, Games like URIDIUM can prevent us from resetting
    (we need to re-load the core)

* Code consistency and "niceness":
  - Refactor "IEC" names to something more fitting (as IEC is C64 specific)
  - Refactor OSM_DX and OSM_DY: Get rid of it in mega65.vhd and in the
    audio-video-pipeline and move it to config.vhd: DX can be configured there
    and passed via a new 4k selector and DY can be inferred SEL_OPTM_ICOUNT-
  - Review all documentation and README's
  - run    grep -irn mark_debug .
    in these folders and remove all debug signals:
    M2M/vhdl
    MEGA65/vhdl
    (C64_MiSTerMEGA65 is already clean.)

* Bugs:
   - Reset problem => might be already solved in the meantime?

* MiSTer Features:
   - CRT mode
   - crop/zoom
   - audio processing

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

## Constraints (What is not yet working) & Roadmap

### Feature Roadmap

We are planning to improve this core steadily. The MiSTer core offers much
more features than our current Release 1 of the port. Here is a list of
features that we are planning to deliver at a later stage:

* NTSC
* Support two drives: 8 and 9
* Writing to virtual disks
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
  to even improve flicker-free HDMI further
* Re-do QNICE's SD Card controller: Go from SPI to native
* Enhance QNICE's FAT32 library so that it supports writing
* HyperRAM device support to QNICE
* Line 65 in fdc1772.v: back to 2 or work with generic?
