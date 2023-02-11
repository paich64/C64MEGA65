Roadmap
=======

We are planning to improve this core steadily. The MiSTer core offers many
more features than our current Release of the port. Here is a list of features
(in no particular order) that we are planning to deliver at a later stage:

Feature Roadmap
---------------

* NTSC
* Support two drives: 8 and 9
* Dual SID
* Support autoswap via `*.lst` files
* Support the creation of empty disk images
* Supoprt the creation of empty config files and the migration of the config
  file from an older version to a newer version
* Ability to "enter" image files (`*.d64`, etc.), browse them and select
  files for direct loading
* Alternative KERNAL & Floppy Disk ROMs and fast loaders
* Parallel C1541 port for faster (~20x) loading time using DolphinDOS
* Utilize full 16:9 screen real estate for file- and directory browsing and
  core configuration on HDMI while saving screen real estate on 4:3 VGA
* More sophisticated scalers and scandoublers 
* Simulate the blending of colours when ALM and DCM are used
  as described here: https://github.com/MiSTer-devel/C64_MiSTer/issues/104
* Support typing the first letter(s) of files to quickly jump to files
  and folders within the filebrowser: https://github.com/MJoergen/C64MEGA65/issues/14

Technical Roadmap
-----------------

To implement some of the above-mentioned features and also to improve the
robustness, performance, and stability of the whole system, we will need
to implement certain technical improvements in the "backend", again in no
particular order:

* Implement a remote-control mechanism via Serial/JTAG (similar to what
  already works on the MEGA65 core) that allows us to remote-control the
  C64 core so that we can for example run whole test suites remotely.
  If possible we should think about implementing this feature on the
  MiSTer2MEGA65 framework level so that all cores can benefit.
* Add the Vice test suite to our repertoire of tests and use the
  above-mentioned mechanism to execute on it:
  https://sourceforge.net/p/vice-emu/code/HEAD/tree/testprogs/testbench/ 
* Support for R2 version of MEGA65
* VGA retro CSync generation
* Enhance QNICE's FAT32 stack so that it is able to create new files
* Fix visible tearing in Bromance demo (vertical scroll effect), but only,
  when HDMI Zoom is ON: https://csdb.dk/release/?id=205526
* Update to newer ascal version (wait until MiSTer does the same upstream)
* Re-do QNICE's SD Card controller: Go from SPI to native
* Hardware debugger (single-step the CPU via the on-screen-menu)
