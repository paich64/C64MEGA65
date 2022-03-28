Version 1 - Month, DD 2022
====================================

Experience the Commodore 64 with great accuracy and sublime compatibility
on your MEGA65! It can run a ton of games and demos and it offers convenient
features.

## TODOs before release
* File Browser:
  - Error if wrong D64 file size
  - Filter files (needs subdir flag, framework needs to offer convenient
    file extension checker)
* Unmount whole disk drive via Space in OSM
* Debounce the joystick and the MEGA65's reset button
  (add to MiSTer2MEGA65 from gbc4mega65)
* Check directory structure and headers of source files.
* Review all documentation and README's.
* CRT filter(s): Deft says MEGA65's looks better than MiSTer's, maybe offer MEGA65 only or both

## Features
* PAL standard C64 (running standard KERNAL and standard C1541 DOS)
* PAL 720 x 576 pixels (4:3) @ 50 Hz via VGA: for a true retro feeling
* 720p @ 50 Hz or 60 Hz (16:9) via HDMI: for convenience
* Sound output via 3.5mm jack and via HDMI
* MEGA65 keyboard support (including cursor keys)
* Joystick support
* On-Screen-Menu via Help button to mount drives and to configure options
* SID 6581 and 8580
* C1541 read-only support: Mount standard `*.D64` via SD card to drive 8
* Drive led during virtual disk access

## Constraints (What is not yet working)
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
* 2 graphic cards to QNICE: Utilize full 16:9 screen real estate for file-
  and directory browsing and core configuration on HDMI while saving screen
  real estate on 4:3 VGA
* Internal TODOs:
  * HyperRAM device support to QNICE
  * Line 65 in fdc1772.v: back to 2 or work with generic?
