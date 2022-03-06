Version 0.5 (alpha) - Month, DD 2022
====================================

Experience the Commodore 64 with great accuracy and sublime compatibility
on your MEGA65! This is an "alpha" version, i.e. it is not yet feature
complete and there might be occasional bugs and odd behaviors. Yet, it is
already a pretty cool proof-of-concept that runs a ton of games and demos.

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
* PAL standard C64 (running standard KERNAL and standard C1541 DOS)
WIP PAL 720 x 576 pixels via VGA and via HDMI
WIP Sound output via 3.5mm jack and via HDMI
* MEGA65 keyboard support (including cursor keys)
* Joystick support
WIP On-Screen-Menu via Help button to mount drives and to configure options
WIP SID 6581 and 8580
WIP C1541 read-only support: Mount standard `*.D64` via SD card
WIP Drive led during virtual disk access

## Constraints (What is not yet working)
* NTSC
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
