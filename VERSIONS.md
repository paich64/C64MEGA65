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
* TODO implement couple/decouple joysticks/paddles (QNICE CSR register);
  maybe we can combine this elegantly with the debouncer and reduce the
  signals that go to the core by using a std_logic_vector for the
  joysticks/paddles
* Add OSM option to enable/disable tripple buffering.
* Add OSM option to switch between 50 Hz and 60 Hz for HDMI output.
* Add OSM option to enable hq2x (input to the scan-doubler module) (I'm not sure what it does).
* Check directory structure and headers of source files.
* Review all documentation and README's.
* Search and replace "gbc4MEGA65" in all source files.
TODO for next release:
* Add HyperRAM device support to QNICE
* Add 2 graphic cards to QNICE

## Features
* PAL standard C64 (running standard KERNAL and standard C1541 DOS)
WIP PAL 720 x 576 pixels (4:3) @ 50 Hz via VGA: for a true retro feeling
WIP 720p @ 60 Hz (16:9) @ 60 Hz via HDMI: for convenience
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
* Internal TODOs: 
  * Line 65 in fdc1772.v: back to 2 or work with generic?
