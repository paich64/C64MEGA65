C64 for MEGA65 - Version 5
==========================

Experience the Commodore 64 with great accuracy and sublime compatibility
on your MEGA65!

This core is based on the MiSTer Commodore 64 core which itself is based on
the work of many others.

MJoergen and sy2002 ported the core to the MEGA65 in 2022 and 2023.

With our Release 5, we are striving for a **retro C64 PAL experience**:
The core turns your MEGA65 into a Commodore 64 with a C1541 drive (you can
mount `*.d64`) images. It supports the following hardware ports of the MEGA65:

* Joystick port for joysticks, mice and paddles
* Expansion port for C64 cartridges: Games, Freezers, Fast loader
  cartridges, REUs, Multi-Function Flash Cartridges, etc.
* IEC port so that you can attach real 1541 & 1581 drives as well as
  printers, plotters or modern devices such as the SD2IEC and the
  Ultimate-II+

Additionally, the C64 for MEGA65 core can simulate a 1750 REU with 512KB
of RAM, it can simulate cartridges (by loading `*.crt` files) and it offers
a Dual SID / Stereo SID experience.

The C64 runs the original Commodore KERNAL and the C1541 runs the original
Commodore DOS, which leads to authentic loading speeds. You will be surprised,
how slowly the C64/C1541 were loading... :-) You can optionally use JiffyDOS
or use fast loader cartridges to speed up loading.

And you will be amazed by the 99.9% compatibility that this core has when it
comes to games, demos and other demanding C64 software. Some demos are even
recognizing this core as genuine C64 hardware. And even things like using
a fast loader cartridge while connecting a genuine 1541 via IEC are working
flawlessly.

IMPORTANT: Right now we are only supporting MEGA65 R3, R3A and newer. R2
machines or machines newer than R3A are not supported, yet. This might change
in future.

Watch this YouTube video to learn how to install the core:
https://youtu.be/6ZcUFY77o3A

If you want the core to remember the settings you made in the on-screen-menu,
then make sure that you copy the following file (`c64mega65`) into a folder
called `/c64`. This `c64` folder needs to be located in the root folder of the
SD card that is active when you boot the core:
https://raw.githubusercontent.com/MJoergen/C64MEGA65/develop/bin/Version%205/R3/c64mega65

For using hardware cartridges, make sure that you have a MEGA65 core #0 which
is from mid 2023. Follow this instructions to upgrade:
https://mega65.atlassian.net/l/cp/1fkp5zvQ

Learn more including how to install by reading the manual:
https://github.com/MJoergen/C64MEGA65/blob/master/README.md

Frequently asked questions:
https://github.com/MJoergen/C64MEGA65/blob/master/FAQ.md

Learn more about constraints and the roadmap:
https://github.com/MJoergen/C64MEGA65/blob/master/ROADMAP.md

See who contributed to make this great MEGA65 core:
https://github.com/MJoergen/C64MEGA65/blob/master/AUTHORS