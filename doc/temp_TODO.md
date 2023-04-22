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

* Code cleanup: Remove debug signals

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

Documentation tasks:

* Write a special EasyFlash 1CR file and put it in doc and link to it from
  various places (README.md, FAQ.md). ALso see FAQ.md.
* Update README.md: Cartridges (Supported, not supported, Details, how to
  use, don't do's, Ultimax and either flashing new core #0 or insert it
  while the MEGA65 is running (share a bunch of Discord links that shows
  that also the latter one works fine - were users confirmed this)); separate
  document for how to update core #0?; Some important DualSID usage hints,
  including take care of address and the pseudo stereo mode "Same as left
  SID port"; IEC? OTHER topics that stem from the
  new features?
* FAQ update, cartridge don't work cases: Ultimax and plastic case and when
  it comes to "special" i.e. non-game carts: list of officially supported
  carts and list of don't work (maybe in tests?)
* Testbench(es) create README.md in test folder?
* EasyFlash and other homebrew hardware cartridges: Prevent misalignment!
  Use Protoparts and other links. And link to this discussion:
  https://discord.com/channels/719326990221574164/794775503818588200/1099263044686729336
  and
  https://discord.com/channels/719326990221574164/794775503818588200/1099279097609338881

MiSTer2MEGA65 Framework

* Migration of the progress made on the C64.
  Migrate then back from framework to C64.
  And only then release the C64.

* In what state do we want the documentation / tutorial be before Mirko's
  "sabbatical"?
