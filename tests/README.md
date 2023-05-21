C64 for MEGA65 Regression Testing
=================================

Before releasing a new version we strive to run all regression tests described
here. Since running through all the [demos](demos.md) takes some serious
effort, it might be that we are not always doing it.

Version 5 - Month Day, 2023
---------------------------

@TODO @TODO @TODO @TODO @TODO

"Change mount status while menu is closed (i.e. Smart Reset)" to "Additional Smoke Tests"

Add tests that stress the new menu system.

@TODO @TODO @TODO @TODO @TODO

Add the PLA test

Add a test for the mouse and the paddles

@@@-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
@REMOVE THIS FROM THE C64 tests documentation when done. This is just an
internal reminder for making sure that the MiSTer2MEGA65 framework release
that accompanies the release of the C64 core is rock solid:

Since the C64 core has the drive and the cartrige "above the fold" (i.e.
above any submenu), there might be some hidden bugs in the M2M framework that
only become visible when the drive/cartridge and other menu-modifying logic
happens "below the fold".

Therefore we need to use the M2M demo core: We need to perform some tests (and
thought experiments) to check: Are there any situations where the menu is
changed with direct coordinate calculations from outside of menu.asm and
therefore without the necessary transformation from flat coordinate space to
relative coordinate space.

Important is that we spend some time (re)searching for all the places and
situations in the code that print directly to the screen outside menu.asm vs.
just modifying the flat data structures.

In shell.asm, `_HM_SETMENU` might be a candidate that needs to be refactored.
From an architectural clarity perspective, menu.asm should be refactored to
encapsulate the necessary functionality so that shell.asm (and probably
options.asm, too) can access it and therefore things like the coordinate
transformation in `_OPTM_R_F2M` but also other semantic knowledge
are staying protected inside menu.asm.
@@@-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

Add tests for Cartridges (real ones and simulated ones) and other tests regarding new features/changes

Copy/Paste everything from below and re-do all tests

| Status             | Test                                                 | Done by                | Date              
|:-------------------|------------------------------------------------------|:-----------------------|:--------------------------
| :question:         | Basic regression tests                               | :question:             | :question:
| :question:         | SID                                                  | :question:             | :question:
| :question:         | HDMI & VGA                                           | :question:             | :question:
| :question:         | C64 Emulator Test Suite V2.15                        | :question:             | :question:
| :question:         | [Demos](demos.md)                                    | :question:             | :question:
| :question:         | Writing to `*.d64` images                            | :question:             | :question:
| :question:         | Dedicated REU tests                                  | :question:             | :question:
| :question:         | GEOS: REU (sim), GeoRAM (HW), mouse, disk write test | :question:             | :question:

### Basic regression tests

#### Main menu

Work with the main menu and run software that allows to test the following and make sure that
you have a JTAG connection and an **active serial terminal** to observe the debug output of the core:

* Filebrowser
* Mount disk
* Load `*.prg`
* Play with the Expansion Port settings, start a hardware CRT and an emulated CRT (there are more detailed and dedicated cartridge tests later)
* Flip joystick ports
* Save configuration: Switch off/switch, check configuration
* Save configuration: Switch the SD card while the core is running and observe how settings are not saved.
* Save configuration: Omit the config file and use a wrong config file
* REU: 1750 with 512KB
* HDMI: CRT emulation
* HDMI: Zoom-in
* HDMI: 16:9 50 Hz
* HDMI: 16:9 60 Hz
* HDMI:  4:3 50 Hz
* HDMI:  5:4 50 Hz
* HDMI: Flicker-free
* HDMI: DVI (no sound)
* VGA: Retro 15Khz RGB
* CIA: Use 8521 (C64C)
* Audio Improvements
* About and Help
* Close Menu

#### Additional Smoke Tests

* Try to mount disk while SD card is empty
* Work with both SD cards (and switch back and forth in file-browser)
* Remove external SD card while menu and file browser are not open;
  reinsert while file browser is open
* Work with large directory trees / game libraries
* Eagle's Nest: Reset-tests: Short reset leads to main screen. Long reset
  resets the whole core (not only the C64).
* Giana Sisters: Scrolling while flicker-free is ON/OFF, joystick, latency
* Katakis: High score saving/loading
* Smile to the Sky (demo): SID 8580 filters
* Sonic the Hedgehog: REU
* Space Lords: Support for 4 paddles

### SID

* Check 6581 vs 8580 detection using the [Mathematica demo](https://csdb.dk/release/?id=11611)
* Check the 8580 filters using the [Smile to the Sky demo](https://csdb.dk/release/?id=172574)
* Check true stereo SID using the [Game of Thrones demo](https://csdb.dk/release/?id=157533)
* Use [Sidplay64](https://csdb.dk/release/?id=161475) and dedicated stereo SID files to
  test the various "Right SID port" settings. 

### HDMI & VGA

#### HDMI

Test if the resolutions and frequencies are correct:

```
16:9 720p 50 Hz = 1,280 x 720 pixel
16:9 720p 60 Hz = 1,280 x 720 pixel
4:3  576p 50 Hz =   720 x 576 pixel
5:4  576p 50 Hz =   720 x 576 pixel
```

Test HDMI modes:

* Flicker-free: Use the [Testcase from README.md](../README.md#flicker-free-hdmi)
* DVI (no sound)
* CRT emulation
* Zoom-in

#### VGA

Switch-off "HDMI: Flicker-free" before performing the following VGA tests and
check for each VGA mode if the **OSM completely fits on the screen**:

* Standard
* Retro 15 kHz with HS/VS
* Retro 15 kHz with CSYNC

Make sure that the Retro 15 kHz tests are performed on real analog retro CRTs.

### Writing to `*.d64` images

* Work with `Disk-Write-Test.d64` and create some files and re-load them
* Try to interrupt the saving by pressing <kbd>Reset</kbd> while the yellow light is on.
  Do this with the OSM open and also with the OSM closed. Watch if the `<Saving>` is
  being influenced by the reset attempt.
* Katakis: High score saving/loading
  

Version 4 - November 25, 2022
-----------------------------

| Status             | Test                                        | Done by                | Date              
|:-------------------|---------------------------------------------|:-----------------------|:--------------------------
| :white_check_mark: | Basic regression tests                      | sy2002                 | 11/24/22
| :white_check_mark: | C64 Emulator Test Suite V2.15               | sy2002                 | 11/19/22
| :white_check_mark: | [Demos](demos.md)                           | AmokPhaze101           | October & November 2022
| :white_check_mark: | Disk-Write-Test.d64                         | sy2002                 | 11/24/22
| :white_check_mark: | Dedicated REU tests                         | AmokPhaze101           | 11/19/22
| :white_check_mark: | GEOS: REU, mouse, disk write test           | sy2002                 | 11/24/22

### How to interpret the test results

We consider the pattern of success (:white_check_mark:) and failure (:x:) in
the [Demos](demos.md), the C64 Emulator Test suite and the dedicated REU tests
(scroll down, see below) as the baseline for Version 4 and therefore as
"success". Future versions must deliver the same - or better.

### Basic regression tests

#### Main menu

Work with the main menu and run software that allows to test the following:

* Mount disk
* Filebrowser
* Save configuration, switch off/switch, check configuration
* Flip joystick ports
* SID: 6581 and 8580
* REU: 1750 with 512KB
* HDMI: CRT emulation
* HDMI: Zoom-in
* HDMI: 16:9 50 Hz
* HDMI: 16:9 60 Hz
* HDMI:  4:3 50 Hz
* HDMI:  5:4 50 Hz
* HDMI: Flicker-free
* HDMI: DVI (no sound)
* VGA: Retro 15Khz RGB
* CIA: Use 8521 (C64C)
* Audio Improvements
* About and Help
* Close Menu

#### Additional Smoke Tests

* Try to mount disk while SD card is empty
* Work with both SD cards (and switch back and forth in file-browser)
* Remove external SD card while menu and file browser are not open;
  reinsert while file browser is open
* Work with large directory trees / game libraries
* Eagle's Nest: Reset-tests: Short reset leads to main screen. Long reset
  resets the whole core (not only the C64).
* Giana Sisters: Scrolling while flicker-free is ON/OFF, joystick, latency
* Katakis: High score saving/loading
* Smile to the Sky (demo): SID 8580 filters
* Sonic the Hedgehog: REU
* Space Lords: Support for 4 paddles

### C64 Emulator Test Suite V2.15

Tested with 6526 CIA. We consider the following test pattern, i.e. "Disc 1
Complete" and Disc 2 "everything works but the below-mentioned exceptions" as
"success" and our baseline for Release 4.

| Status             | Detail                                      | Done by                | Date              
|:-------------------|---------------------------------------------|:-----------------------|:--------------------------
| :white_check_mark: | Disc 1: Complete                            | sy2002                 | 11/19/22
| :white_check_mark: | Disc 2: From start to and incl. "Trap16"    | sy2002                 | 11/19/22
| :x:                | Disc 2: "Trap17"                            | sy2002                 | 11/19/22
| :white_check_mark: | Disc 2: "Branchwrap" to  "MMU"              | sy2002                 | 11/19/22
| :x:                | Disc 2: "CPUPort"                           | sy2002                 | 11/19/22
| :white_check_mark: | Disc 2: "CPUTiming" to  "Cntdef"            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA1TA"                            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA1TB"                            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA2TA"                            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA2TA"                            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA2TB"                            | sy2002                 | 11/19/22

### Dedicated REU tests

All done by AmokPhaze101 on 11/19/22

#### Demos

| Status             | Demo                                        | Comment
|:-------------------|---------------------------------------------|:---------------------------------------------------
| :white_check_mark: | Dark Mights - Movie 32                      | 
| :white_check_mark: | Expand by Bonzai                            | 
| :x:                | fREUd                                       | In the part with boucing balls all the backgrounds are screwed up. Same issue on MiSTer C64_20221117.rbf. Perfectly runs on real Commodore C64 with Ultimate Cartridge.
| :white_check_mark: | Globe 2016                                  | Wait 7 minutes before rendering starts
| :white_check_mark: | Life will never be the same Digidemo 286K_1 | Press SPACE after having swapped disk
| :white_check_mark: | Qi                                          | 
| :white_check_mark: | REU demo Zelda                              | Just scroll the map with joystick in port 2
| :white_check_mark: | Treu Love                                   | OK but not 100%: In the main first scroller sprites have horizontal white pixel lines when on left and right borders, while they should not. Same issue on MiSTer C64_20221117.rbf. Perfectly runs on real Commodore C64 with Ultimate Cartridge.

#### Games

| Status             | Game                                        | Comment
|:-------------------|---------------------------------------------|:---------------------------------------------------
| :white_check_mark: | Sonic The Hedgehog v1.2+5                   | Joystick in port 2, choose options with ARROWS and RETURN, accept to load full game into the REU when asked
| :x:                | Creatures II +9Hi - Mystic                  | Impossible to load the game until the end. Same issues on MiSTer C64_20221117.rbf and real C64+Ultimate Cartridge.
| :white_check_mark: | Exterminator_1991_Audiogenic_(REU)          | 
| :white_check_mark: | from_the_west[r]                            | All is happening in REU (no disk access) but interraction is quite slow
| :white_check_mark: | Ski_or_Die_1990_Electronic_Arts_REU         | Joystick in port 2. Takes ages to load from disk to the REU on our core as well as on MiSTer and a real C64.
| :white_check_mark: | Walkerz +3                                  | Joystick in port 2
