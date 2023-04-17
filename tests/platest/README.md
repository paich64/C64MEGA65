PLA Test
========

Written by Daniël Mantione in April 2023

This program tests the functionality of the Commodore 64 PLA. The program uses
hardware on an EasyFlash 1CR cartridge to control the cartridge PLA signals.

This means that an EasyFlash 1CR cartridge needs to be inserted before running
this program. The cartridge can be in programming mode to boot to BASIC.
Flash ROM contents do not matter and won't be modified.

Learn more about the EasyFlash 1CR cartridge here:
https://www.freepascal.org/~daniel/easyflash/

How to use
----------

1. Make sure that an EF 1CR is inserted to the C64 or MEGA65

2. Start the program `platest.prg` which is included in this repository

How to build platest.prg
------------------------

You need:

* CC65: https://cc65.github.io/
* Vice's petcat: https://vice-emu.sourceforge.io/vice_16.html#SEC386
* make

Run `make`.
