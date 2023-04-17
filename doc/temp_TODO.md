Debugging tasks:

* Support Olivier in debugging his cartridge

* Black screen from time to time on startup (independent if a cartridge is
  inserted or not): HDMI-only: VGA shows a normal C64 start screen including
  a blinking cursor. But on HDMI the screen stays black but you can use
  the OSM via the Help key.

* Work with Oliver and do differential source code analysis: Why is the E2IRA
  crashing on our core and running fine on the MiSTer core?

* HyperRAM and REU:
  https://github.com/MJoergen/C64MEGA65/blob/dev-crtload/doc/temp_alpha_bugs.md

Development tasks:

* Finalize HW cartridge support

* Finalize SW cartridge support

* Usabiltiy: "Auto-enable" the "Simulated Cartridge" switch, when a CRT file
  has been selected

* JiffyDOS

* IEC hardware port

* 15khz RGB + csync:
  https://discord.com/channels/719326990221574164/794775503818588200/1082080087891005500

HDMI:

* Random micro-cuts of sound: Solved with newest Tyto and its audio clock
  https://github.com/MJoergen/C64MEGA65/issues/13

* Get Michael's HDMI monitor to work

MiSTer2MEGA65 Framework

* Migration of the progress made on the C64.
  Migrate then back from framework to C64.
  And only then release the C64.

* In what state do we want the documentation / tutorial be before Mirko's
  "sabbatical"?
