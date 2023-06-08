C64 for MEGA65 Regression Testing
=================================

Before releasing a new version we strive to run all regression tests described
here. Since running through all the [demos](demos.md) takes some serious
effort, it might be that we are not always doing it.

Version 5 - Month Day, 2023
---------------------------

| Status             | Test                                                 | Done by                | Date              
|:-------------------|------------------------------------------------------|:-----------------------|:--------------------------
| :white_check_mark: | Basic regression tests: Main menu                    | AmokPhaze101           | 6/4/23
| :question:         | Basic regression tests: Additional Smoke Tests       | :question:             | :question:
| :white_check_mark: | HDMI & VGA                                           | AmokPhaze101           | 6/3/23
| :white_check_mark: | SID                                                  | AmokPhaze101           | 6/3/23
| :white_check_mark: | C64 Emulator Test Suite V2.15                        | AmokPhaze101           | 6/4/23
| :question:         | [Demos](demos.md)                                    | :question:             | :question:
| :question:         | Writing to `*.d64` images                            | :question:             | :question:
| :question:         | GEOS: REU (sim), GeoRAM (HW), mouse, disk write test | :question:             | :question:
| :question:         | PLA Test                                             | :question:             | :question:
| :white_check_mark: | Dedicated REU tests                                  | AmokPhaze101           | 6/3/23
| :question:         | Dedicated hardware cartridge tests                   | :question:             | :question:
| :white_check_mark: | Dedicated simulated cartridge tests                  | AmokPhaze101           | 6/7/23

### Basic regression tests

#### Main menu

Work with the main menu and run software that allows to test the following and make sure that
you have a JTAG connection and an **active serial terminal** to observe the debug output of the core:

* Filebrowser
* Mount disk
* Load `*.prg`
* Short reset vs. long reset: Test drive led's behavior
* Stress the OSM ("unexpected" resets, opening closing "all the time" while things that change the OSM are happening in the background, etc.)
* Play with the Expansion Port settings, start a hardware CRT and an emulated CRT (there are more detailed and dedicated cartridge tests later)
* Flip joystick ports
* Save configuration: Switch off/switch, check configuration
* Save configuration: Switch the SD card while the core is running and observe how settings are not saved.
* Save configuration: Omit the config file and use a wrong config file
* CIA: Use 8521 (C64C)
* Kernal: Test all Kernal variants including Jiffy DOS.
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
* Giana Sisters: Joystick and latency
* Space Lords: Support for 4 paddles

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

### SID

* Check 6581 vs 8580 detection using the [Mathematica demo](https://csdb.dk/release/?id=11611)
* Check the 8580 filters using the [Smile to the Sky demo](https://csdb.dk/release/?id=172574)
* Check true stereo SID using the [Game of Thrones demo](https://csdb.dk/release/?id=157533)
* Use [Sidplay64](https://csdb.dk/release/?id=161475) and dedicated stereo SID files to
  test the various "Right SID port" settings: `D420.d64` and `D500.d64`

The folder [sidtests](sidtests) in this repo contains all the test files including `D420.d64` and `D500.d64`.

### Writing to `*.d64` images

* Work with `Disk-Write-Test.d64` and create some files and re-load them
* Try to interrupt the saving by pressing <kbd>Reset</kbd> while the yellow light is on.
  Do this with the OSM open and also with the OSM closed. Watch if the `<Saving>` is
  being influenced by the reset attempt.
* Katakis: High score saving/loading

### C64 Emulator Test Suite V2.15

Identical to Version 4 - so we consider this as a success.

| Status             | Detail                                      | Done by                | Date              
|:-------------------|---------------------------------------------|:-----------------------|:--------------------------
| :white_check_mark: | Disc 1: Complete                            | AmokPhaze101           | 06/04/23
| :white_check_mark: | Disc 2: From start to and incl. "Trap16"    | AmokPhaze101           | 06/04/23
| :x:                | Disc 2: "Trap17"                            | AmokPhaze101           | 06/04/23
| :white_check_mark: | Disc 2: "Branchwrap" to  "MMU"              | AmokPhaze101           | 06/04/23
| :x:                | Disc 2: "CPUPort"                           | AmokPhaze101           | 06/04/23
| :white_check_mark: | Disc 2: "CPUTiming" to  "Cntdef"            | AmokPhaze101           | 06/04/23
| :x:                | Disc 2: "CIA1TA"                            | AmokPhaze101           | 06/04/23
| :x:                | Disc 2: "CIA1TB"                            | AmokPhaze101           | 06/04/23
| :x:                | Disc 3: "CIA2TA"                            | AmokPhaze101           | 06/04/23
| :x:                | Disc 3: "CIA2TB"                            | AmokPhaze101           | 06/04/23

### Dedicated REU tests

All done by AmokPhaze101 on 6/3/23

#### Demos

| Status             | Demo                                        | Comment
|:-------------------|---------------------------------------------|----------------------------------------------------
| :white_check_mark: | Dark Mights - Movie 32                      | [CSDB](https://csdb.dk/release/?id=5903)
| :white_check_mark: | Expand by Bonzai                            | [CSDB](https://csdb.dk/release/?id=192886)
| :x:                | fREUd                                       | [CSDB](https://csdb.dk/release/?id=149560) In the part with boucing balls all the backgrounds are screwed up. Same issue on MiSTer C64_20221117.rbf. Perfectly runs on real Commodore C64 with Ultimate Cartridge.
| :white_check_mark: | Frontier                                    | [CSDB](https://csdb.dk/release/?id=120458)
| :white_check_mark: | Globe 2016                                  | [CSDB](https://csdb.dk/release/?id=152053) Takes a few minutes to be fully rendered
| :white_check_mark: | Life will never be the same Digidemo 286K_1 | [CSDB](https://csdb.dk/release/?id=3736)
| :white_check_mark: | Qi                                          | [CSDB](https://csdb.dk/release/?id=139711)
| :white_check_mark: | REU demo Zelda                              | [CSDB](https://csdb.dk/release/?id=68189)
| :white_check_mark: | Treu Love                                   | [CSDB](https://csdb.dk/release/?id=144105) Ensure to use this file: `TreuLove_ForReal1750Reu.d64`

#### Games

| Status             | Game                                        | Comment
|:-------------------|---------------------------------------------|----------------------------------------------------
| :white_check_mark: | Sonic The Hedgehog v1.2+5                   | [CSDB](https://csdb.dk/release/?id=212617)
| :white_check_mark: | Creatures II +9Hi - Mystic                  | [CSDB](https://csdb.dk/release/?id=41884)
| :white_check_mark: | Exterminator_1991_Audiogenic_(REU)          | [CSDB](https://csdb.dk/release/?id=168549)
| :white_check_mark: | From the West                               | [CSDB](https://csdb.dk/release/?id=185613)
| :white_check_mark: | Ski_or_Die_1990_Electronic_Arts_REU         | [CSDB](https://csdb.dk/release/?id=161436) Takes ages to load but it's ok
| :white_check_mark: | Walkerz +3                                  | [CSDB](https://csdb.dk/release/?id=43006)

### Dedicated hardware cartridge tests

All done by @TODO:NAME on @TODO:DATE

| Status             | Test                                                                                                                        | Comment
|:-------------------|-----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------
| :question:         | Using a correct core #0: Test if we can directly boot to a hardware cartridge                                               |
| :question:         | Using a correct core #0: Test if the hardware cartridge is ignored in case simulated REU or simulated cartridge is selected |
| :question:         | Test a bunch of original old game cartridges                                                                                | Tested Last Ninja Remix, Super Games, Wizard of Wor
| :question:         | Test an old Ultimax game                                                                                                    | Tested Pinball Spectacular
| :question:         | Test a bunch of new game cartridges                                                                                         | Tested Muddy Racers, Sam's Journey, Soul Force, The Curse of Rabenstein
| :question:         | Save game and load game to/from the original Sam's Journey cartridge                                                        |
| :question:         | Final Cartridge III                                                                                                         |
| :question:         | Action Replay Professional 6.0                                                                                              |
| :question:         | Power Cartridge                                                                                                             |
| :question:         | Flash the EasyFlash **1CR** with a small (<64k) and large (>512k) game and playtest these games                             |
| :question:         | Flash the EasyFlash **3** with a small (<64k) and large (>512k) game and playtest these games                               |
| :question:         | Flash the EasyFlash **3** with a small (<64k) and large (>512k) game and playtest these games                               |
| :question:         | EasyFlash **3**: Test all freezers that the EF3 supports as described in [cartridges.md](../doc/cartridges.md)              |
| :question:         | Kung Fu Flash using the workaround described in [cartridges.md](../doc/cartridges.md)                                       |
| :question:         | Work with GEOS and GeoRAM                                                                                                   |

### Dedicated simulated cartridge tests

All done by AmokPhaze101 on 6/7/23

| Status             | Comment              | Game Name                                                                     | Cartridge Type                        
|:-------------------|:---------------------|:------------------------------------------------------------------------------|:-------------------------------------------
| :white_check_mark: |                      | Beamrider                                                                     | 0 - generic cartridge                  
| :white_check_mark: |                      | Centipede                                                                     | 0 - generic cartridge                  
| :white_check_mark: |                      | Gridrunner                                                                    | 0 - generic cartridge                  
| :white_check_mark: |                      | Gyruss                                                                        | 0 - generic cartridge                  
| :white_check_mark: |                      | Pac-Man                                                                       | 0 - generic cartridge                  
| :x:                | Planned for v6       | Action Replay v4.2 Professional                                               | 1 - Action Replay                      
| :x:                | Planned for v6       | Action Replay v5.0 Professional                                               | 1 - Action Replay                      
| :x:                | Planned for v6       | Action Replay v6.0 Professional                                               | 1 - Action Replay                      
| :x:                | Planned for v6       | Black Box V4                                                                  | 3 - Final Cartridge III                
| :x:                | Planned for v6       | Black Box V8                                                                  | 3 - Final Cartridge III                
| :x:                | Planned for v6       | Final Cartridge III                                                           | 3 - Final Cartridge III                
| :white_check_mark: |                      | Kung Fu Master                                                                | 5 - Ocean type 1                       
| :white_check_mark: |                      | Ghostbusters                                                                  | 5 - Ocean type 1                       
| :white_check_mark: |                      | Batman The Movie                                                              | 5 - Ocean type 1                       
| :white_check_mark: |                      | Robocop 2                                                                     | 5 - Ocean type 1                       
| :white_check_mark: |                      | Soul Force                                                                    | 5 - Ocean type 1                       
| :white_check_mark: |                      | Codemasters - Fast Food, Pro Skateboard, Pro Tennis                           | 7 - Fun Play, Power Play               
| :white_check_mark: |                      | Microprose  - Soccer, Rick Dangerous & Stunt Car Racer                        | 7 - Fun Play, Power Play               
| :white_check_mark: |                      | Colossus Chess, International Football & Silicon Syborgs                      | 8 - Super Games                        
| :white_check_mark: |                      | Vegetables Deluxe                                                             | 8 - Super Games                        
| :white_check_mark: |                      | Fiendish Freddy's Big Top o' Fun, Flimbo’s Quest, Klax & International Soccer | 15 - C64 Game System, System 3         
| :white_check_mark: |                      | Last Ninja Remix                                                              | 15 - C64 Game System, System 3         
| :white_check_mark: |                      | Myth - History in the Making                                                  | 15 - C64 Game System, System 3         
| :white_check_mark: |                      | After the War                                                                 | 17 - Dinamic                           
| :white_check_mark: |                      | Astro Marine Corps                                                            | 17 - Dinamic                           
| :white_check_mark: |                      | Narco Police                                                                  | 17 - Dinamic                           
| :white_check_mark: |                      | L'Abbaye Des Morts                                                            | 19 - Magic Desk, Domark, HES Australia 
| :white_check_mark: |                      | Archon II - Adept                                                             | 19 - Magic Desk, Domark, HES Australia 
| :white_check_mark: |                      | Arkanoid - Revenge of Doh                                                     | 19 - Magic Desk, Domark, HES Australia 
| :white_check_mark: |                      | Park Patrol                                                                   | 19 - Magic Desk, Domark, HES Australia 
| :white_check_mark: |                      | Super Bread Box                                                               | 19 - Magic Desk, Domark, HES Australia 
| :white_check_mark: |                      | A Pig Quest                                                                   | 32 - EasyFlash                         
| :white_check_mark: |                      | Bruce Lee II                                                                  | 32 - EasyFlash                         
| :white_check_mark: |                      | Monstro Giganto                                                               | 32 - EasyFlash                         
| :white_check_mark: |                      | Muddy Racer                                                                   | 32 - EasyFlash                         
| :white_check_mark: |                      | ZetaWing                                                                      | 32 - EasyFlash                         
| :white_check_mark: |                      | Freaky Fish DX                                                                | 60 - GMod2                             
| :white_check_mark: |                      | Metal Warrior Ultra                                                           | 60 - GMod2                             
| :white_check_mark: |                      | Outrage                                                                       | 60 - GMod2                             
| :white_check_mark: |                      | Polar Bear                                                                    | 60 - GMod2                             
| :white_check_mark: |                      | Sam's Journey                                                                 | 60 - GMod2                             

Additional tests of [commercial cartridge releases](commercial_carts.md) have been performed by AmokPhaze101 in May 2023.

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
| :x:                | Disc 3: "CIA2TA"                            | sy2002                 | 11/19/22
| :x:                | Disc 3: "CIA2TB"                            | sy2002                 | 11/19/22

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
