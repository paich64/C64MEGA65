Version 0.5 (alpha) - Month, DD 2022
====================================

Experience the Commodore 64 with great accuracy and sublime compatibility
on your MEGA65! This is an "alpha" version, i.e. it is not yet feature
complete and there might be occasional bugs and odd behaviors. Yet, it is
already a pretty cool proof-of-concept.

## TODOs before release of alpha
* Do all "WIP"
* Debounce the joystick and the MEGA65's reset button
  (add to MiSTer2MEGA65 from gbc4mega65)
* Line 62 in fdc1772.v: back to 2 or work with generic?
* Decide: Can we remove the code for C1581 for now (alpha)?
  Remember, that buffers that are filled via the SD card (e.g. fdc1772 in
  c1581_drv.sv) need dual-clockand QNICE compatible falling edges. This needs
  to be documented somewhere so that we are not forgetting it later.

## Features
* PAL C64 Standard KERNAL
WIP PAL 720 x 576 pixels via VGA and via HDMI
WIP Sound output via 3.5mm jack and via HDMI
* Full MEGA65 keyboard support
WIP SID 6581 and 8580
WIP On-Screen-Menu via Help button to mount drives and to configure options
* Joystick support
WIP C64 cartridges (real hardware) via the MEGA65's hardware Expansion Port
TODO: rgcd.co.uk volunteered to test for example the Ultimate1541-II
WIP C1541 read-only support for standard `*.D64` via SD card

## Constraints (What is not yet working)
* Writing to virtual disks
* More sophisticated scalers and scandoublers
* NTSC
* Tape mounting via SD card
* Cartridge mounting via SD card
* Alternative KERNAL & Floppy Disk ROMs and fast loaders
* Mount standard `*.D64` 
* Support for raw GCR mode (`*.G64`)
* C1581 virtual drive support via SD card (`*.D81`)
* Parallel C1541 port for faster (~20x) loading time using DolphinDOS
* REU and GeoRAM using HyperRAM
* The following MEGA65 hardware ports are not yet working
	* Paddles / mouse via the joystick ports
	* C1581 via MEGA65's disk drive
	* IEC port (for example to plug in a real C1541)
	* REU via expansion port
	* Drive led during virtual disk access
