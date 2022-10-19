Roadmap
=======

We are planning to improve this core steadily. The MiSTer core offers many
more features than our current Release of the port. Here is a list of features
(in no particular order) that we are planning to deliver at a later stage:

Feature Roadmap
---------------


* NTSC
* Choice between 16:9 or 4:3 HDMI output resolutions
* Support two drives: 8 and 9
* Dual SID
* Ability to save the settings of the core
* More sophisticated scalers and scandoublers
* Tape mounting via SD card
* Directly load program files (`*.PRG`)
* Cartridge mounting via SD card (`*.CRT`)
* Support variations of the `*.D64` format, including 35 track with an error
  map, 40 track & 40 track with error map
* Support for raw GCR mode (`*.G64`)
* C1581 virtual drive support via SD card (`*.D81`)
* Support the creation of empty disk images
* Alternative KERNAL & Floppy Disk ROMs and fast loaders
* Parallel C1541 port for faster (~20x) loading time using DolphinDOS
* Suport the following MEGA65 hardware ports:
  * Cartridges via the MEGA65's hardware Expansion Port
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
* Fix visible tearing in Bromance demo (vertical scroll effect), but only,
  when HDMI Zoom is ON: https://csdb.dk/release/?id=205526
* Update to newer ascal version (wait until MiSTer does the same upstream)
* Investigate dynamic PLL adjustment/autotune in conjunction with ascal
  to improve flicker-free HDMI further (maybe there is a possibility to
  achieve flicker-free without the need of slowing down by 0.25%)
* Re-do QNICE's SD Card controller: Go from SPI to native
* HyperRAM device support to QNICE
* Hardware debugger (single-step the CPU via the on-screen-menu)
* Line 65 in fdc1772.v: back to 2 or work with generic?
