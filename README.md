**WARNING: Heavily work-in-progress. Currently this is not even in an alpha state.**

Commodore 64 for MEGA65
=======================

Experience the [Commodore 64](https://en.wikipedia.org/wiki/Commodore_64) with
great accuracy and sublime compatibility on your
[MEGA65](https://mega65.org/)!

Learn more about where to [download and how to get started](#Installation).

![Commodore64](doc/c64.jpg)

This core is based on the
[MiSTer](https://github.com/MiSTer-devel/C64_MiSTer) Commodore 64 core which
itself is based on
[FPGA64](https://www.syntiac.com/fpga64.html) by Peter Wendrich.

[MJoergen](https://github.com/MJoergen) and
[sy2002](http://www.sy2002.de) ported the core to the MEGA65 in 2021.

The core uses the [MiSTer2MEGA65](https://github.com/sy2002/MiSTer2MEGA65)
framework and [QNICE-FPGA](https://github.com/sy2002/QNICE-FPGA) for
FAT32 support (loading loading ROMs, mounting disks) and for the
on-screen-menu.

Features
--------

We are striving for a retro C64 PAL experience in step #1:

- C64 modes
- Similar to 6581 and 8580 SID filters.
- C1541 read/write/format support in raw GCR mode (*.D64, *.G64)
- Pause option when OSD is opened.
- Loadable Kernal/C1541 ROMs.

In step #2 we might want to add the MEGA65 SID and cartridge support:

- (SOON?) C1581 read/write support (*.D81 disk images on the SD card)
- (SOON?) C1581 support via MEGA65's hardware disk drive
- (SOON?) Add MEGA65 SID which sounds better and more realistic than MiSTeR's SID
- (SOON?) Amost all cartridge formats (*.CRT as images on the SD card)
- (SOON?) Real Cartridges using the MEGA65's cartridge port
- (LATER?) Dual SID with several degree of mixing 6581/8580 from stereo to mono.

Unclear, what a step #3 might look like:

- (LATER?) Parallel C1541 port for faster (~20x) loading time using DolphinDOS.
- (LATER?) External IEC through USER_IO port.
- (LATER?) REU 16MB and GeoRAM 4MB memory expanders.
- (LATER?) OPL2 sound expander.
- (LATER?) 4 joysticks mode.
- (LATER?) RS232 with VIC-1011 and UP9600 modes either internal or through USER_IO.
- (LATER?) Special reduced border mode for 16:9 display.
- (LATER?) C128/Smart Turbo mode up to 4x.
- (LATER?) Real-time clock

Installation
------------

TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO


# Here comes COPY/PASTE from MiSTer

TODO: Needs to be adjusted.

### Keyboard
* F2,F4,F6,F8,Left/Up keys automatically activate Shift key.
* F9 - arrow-up key.
* F10 - = key.
* F11 - restore key. Also special key in AR/FC carts.
* Alt - C= key.

![keyboard-mapping](https://github.com/mister-devel/C64_MiSTer/blob/master/keymap.gif)

### Using without keyboard
If your joystick/gamepad has more than 4 buttons then you can have some limited usage of keybiard.
Joystick buttons **Mod1** and **Mod2** adds 12 frequently used keys to skip the intros and start the game.
Considering default button maps RLDU,Fire1,Fire2,Fire3,Paddle Btn, following keys are possible to enter:
* With holding **Mod1**: Cursor RLDU, Enter, Space, Esc, Alt+ESC(LOAD"*" then RUN)
* With holding **Mod2**: 1,2,3,4,5,0,Y,N
* With holding **Mod1+Mod2**: F1,F2,F3,F4,F5,F6,F7,F8

With maps above and using Dolphin DOS you can issue **F7** to list the files on disk, then move cursor to required file, then issue **Alt+ESC** to load it and run.

### Loadable ROM
Alternative ROM can loaded from OSD: Hardware->Load System ROM.
Format is simple concatenation of BASIC + Kernal.rom + C1541.rom

To create the ROM in DOS or Windows, gather your files in one place and use the following command from the DOS prompt. 
The easiest place to acquire the ROM files is from the VICE distribution. BASIC and KERNAL are in the C64 directory,
and dos1541 is in the Drives directory.

`COPY BASIC + KERNAL + dos1541 MYOWN.ROM /B`

To use JiffyDOS or another alternative kernel, replace the filenames with the name of your ROM or BIN file.  (Note, you muse use the 1541-II ROM. The ROM for the original 1541 only covers half the drive ROM and does not work with emulators.)

`COPY /B BASIC.bin +JiffyDOS_C64.bin +JiffyDOS_1541-II.bin MYOWN.ROM`

To confirm you have the correct image, the BOOT.ROM created must be exactly 32768 or 49152(in case of 32KB C1541 ROM) bytes long. 

There are 2 loadable ROM sets are provided: **DolphinDOS v2.0** and **SpeedDOS v2.7**. Both ROMs support parallel Disk Port. DolphinDOS is fastest one.

For **C1581** you can use separate ROM with size up to 32768 bytes.

### Autoload the cartridge
In OSD->Hardware page you can choose Boot Cartridge, so everytime core loaded, this cartridge will be loaded too.

### Parallel port for disks.
Are you tired from long loading times and fast loaders aren't really fast when comparing to other systems? 

Here is the solution:
In OSD->System page choose **Expansion: Fast Disks**. Then load [DolphinDOS_2.0.rom](releases/DolphinDOS_2.0.rom). You will get about **20x times faster** loading from disks!

### Turbo modes

**C128 mode:** this is C128 compatible turbo mode available in C64 mode on Commodore 128 and can be controlled from software, so games written with this turbo mode support will take advantage of this.

**Smart mode:** In this mode any access to disk will disable turbo mode for short time enough to finish disk operations, thus you will have turbo mode without loosing disk operations.

### RS232

Primary function of RS232 is emulated dial-up connection to old-fashioned BBS. **CCGMS Ultimate** is recommended (Don't use CCGMS 2021 - it's buggy version). It supports both standard 2400 VIC-1011 and more advanced UP9600 modes.

**Note:** DolphinDOS and SpeedDOS kernals have no RS232 routines so most RS232 software don't work with these kernals!

### GeoRAM
Supported up to 4MB of memory. GeoRAM is connected if no other cart is loaded. It's automatically disabled when cart is loaded, then enabled when cart unloaded.

### REU
Supported standard 512KB, expanded 2MB with wrapping inside 512KB blocks (for compatibility) and linear 16MB size with full 16MB counter wrap.
Support for REU files.

GeoRAM and REU don't conflict each other and can be both enabled.

### USER_IO pins

| USER_IO | USB 3.0 name | Signal name |
|:-------:|:-------------|:------------|
|   0     |    D+        | RS232 RX    |
|   1     |    D-        | RS232 TX    |
|   2     |    TX-       | IEC /CLK    |
|   3     |    GND_d     | IEC /RESET  |
|   4     |    RX+       | IEC /DATA   |
|   5     |    RX-       | IEC /ATN    |

All signals are 3.3V LVTTL and must be properly converted to required levels!

### Real-time clock

RTC is PCF8583 connected to tape port.
To get real time in GEOS, copy CP-CLOCK64-1.3 from supplied [disk](https://github.com/mister-devel/C64_MiSTer/blob/master/releases/CP-ClockF83_1.3.D64) to GEOS system disk.

### Raw GCR mode

C1541 implementation works in raw GCR mode (D64 format is converted to GCR and then back when saved), so some non-standard tracks are supported if G64 file format is used. Support formatting and some copiers using raw track copy. Speed zones aren't supported (yet), but system follows the speed setting, so variable speed within a track should work.
Protected disk in most cases won't work yet and still require further tuning of access times to comply with different protections.

