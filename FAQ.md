@TODO: Formatting disk images

@TODO: Adjust links (from develop branch to master)

@TODO: Add some FAQs around starting the C64 core while a cartridge is
inserted. Problems such as this here can arise:

@TODO: EF1CR and other cartridges: They need to sit in a plastic shell
(show photo), you must not insert just a PCB into the MEGA65 because you will
never be able to do it well enough so that it works realiably.

https://discord.com/channels/719326990221574164/794775503818588200/1098518494213058692

@TODO: We need an EF1CR documentation MD in the doc folder and we need to
describe also the "don't dos" there including some info from Daniel.

I did not see it for a long time. But just in case the strange "sometimes the
screen is black directly after startup" does not go away: Talk about pressing
the reset button briefly to get it started.


# FAQ - Frequently Asked Questions

## 1) My MEGA65 or the C64 core is behaving somehow weirdly

**The "HDMI back powering problem" is the root of all evil!**

The evil things that can happen range from display problems over SD card
problems to issues around the system's overall stability.

If your MEGA65 is connected to any HDMI device: Never switch-on this device
before you have successfully switched-on your MEGA65. Or to put it the other
way round: **Always switch-on your MEGA65 first** and **THEN** switch-on your
HDMI device (monitor, frame grabber, etc.).

For the C64 core this means: While your MEGA65 and your HDMI device are
switched off: Hold the <kbd>No Scroll</kbd> key while you switch on the MEGA65
and while the HDMI device is still off. Now, you can switch on your HDMI
device and use the MEGA65's core selection menu to select the C64 core. You
can also use the key combination <kbd>No Scroll</kbd> + &lt;number of the
C64 core in the core menu&gt; to directly select the C64 core.

The reason for this problem is a bug on the MEGA65's mainboard revisions R3
and R3A.

Another way to resolve the issue is to put a cheap HDMI switch between the
MEGA65 and your device. You will find two Amazon links to devices that are
known to work
[here in Dan's MEGA65 Welcome Guide](https://dansanderson.com/mega65/welcome/hardware-issues.html?highlight=hdmi#failure-to-boot-and-keyboard-lights-glow-when-off).

## 2) SD card errors

Most SD card problems can be resolved by considering these possible causes:

1. Are you having an [HDMI back powering problem](https://github.com/MJoergen/C64MEGA65/blob/master/FAQ.md#1-my-mega65-or-the-c64-core-is-behaving-somehow-weirdly)?

2. Is your card formatted as something other than `FAT32`?

   Error `EE12` means "No or illegal partition table entry found (e.g. no FAT32 partition)".
   Some operating systems, for example MacOS format 8GB SD cards with FAT16 instead of FAT32.

   Stick to `FAT32`. Don't use any improved or more modern version of
   file-system. On Windows and Linux it is normally quite
   straightforward to format an SD card as `FAT32`. If you are on a
   Mac, scroll down and read "Formatting SD cards on a Mac".

3. Is your card larger than 32GB? The core cannot handle SD cards larger than 32 GB.

4. Are you using a cheap no-name card?

5. Please try to re-format your card and then copy everything on the card from scratch

6. If (1) to (5) do not help: Use another card: There is empiric evidence suggesting
   that SanDisk and Verbatim SD cards work better than others as long as they are
   not larger than 32GB and as long as they are `FAT32` formatted.

If you have a `Error code: 2704` in conjunction with an SD card error then
[this](https://discord.com/channels/719326990221574164/794775503818588200/1114834752281772043)
post on Discord might be interesting for you. But the bottom line is also in
this case: Step (5) or step (6) will solve the issue.

### Formatting SD cards on a Mac

* Mac OS' GUI tools try to be "smart". Do not use them, as you cannot
  control, if the tool creates FAT16 or FAT32. Use the command line
  version of `diskutil` instead:

  `sudo diskutil eraseDisk FAT32 <name> MBRFormat /dev/<devicename>`

  Find out `<devicename>` using `diskutil list`. `<name>` can be chosen
  arbitrarily.

* If you prefer a visual/GUI tool, then use the formatting tool that the
  official SD card organization provides:
  [Download it here](https://www.sdcard.org/downloads/formatter/sd-memory-card-formatter-for-mac-download/).

## 3) How compatible is the C64 core?

It is very compatible. Not yet as good as Vice but the
core runs hundreds of
[demanding demos flawlessly](tests/demos.md),
plays thousands of games without a single glitch, including games that need
a REU such as
[Sonic the Hedgehog](https://csdb.dk/release/?id=212523)
and the core offers disk writing abilities for the simulated 1541, so
that you can save your game states or your work in GEOS. The core also
let's you use original Commodore
[hardware cartridges](README.md#hardware-cartridges) pluggeed into the MEGA65
expansion port,
[simulate cartridges using CRT files](README.md#simulated-cartridges) and
[use retro Commodore peripherals](README.md#iec-devices)
by plugging them into the MEGA65's IEC port. You can even
[work with retro 15 kHz cathode ray tube monitors](doc/retrotubes.md).

### You cannot format disk images (`*.d64`) yet 



## 4) My game or demo crashes

* Are you having an [HDMI back powering problem](https://github.com/MJoergen/C64MEGA65/blob/master/FAQ.md#1-my-mega65-or-the-c64-core-is-behaving-somehow-weirdly)?

* Make sure you are using the newest version of the core. Right now this is
  [Version 4](https://files.mega65.org?id=896a012f-59e4-456c-b91f-7e989b958241).
  The only officially supported place to get cores is the
  [MEGA65 FileHost](https://files.mega65.org?id=896a012f-59e4-456c-b91f-7e989b958241),
  so make sure you downloaded your copy there.
  Also double-check by pressing <kbd>Help</kbd> and then choosing the menu
  item "About & Help" that you are really running Version 4.

* If the game or demo is not designed for the REU, you absolutely need to
  switch-off the REU before running the game or demo. Learn more about this
  important fact
  [here](https://github.com/MJoergen/C64MEGA65#512-kb-ram-expansion-unit-1750-reu).

* Many modern games and demos are mainly tested on the C64C, so try to run the
  game or demo using the setting "CIA: Use 8521 (C64C)".

* Try to run with deactivated "HDMI: Flicker-free", but don't forget to
  reactivate this afterwards, because your experience is 10x better with
  Flicker-free ON (at least when you're on HDMI). Learn more
  [here](https://github.com/MJoergen/C64MEGA65#compatibility).

* Use an experimental core. The version
  [Alpha 7 for Version 5](https://discord.com/channels/719326990221574164/794775503818588200/1064498334515068958)
  is supposed to run more demos and more games than the Version 4. But since
  this is an Alpha-Version, it is only "supposed" to do that and not enough
  testing has been performed, yet. You need a Discord login for being able
  to access the download link for Alpha 7. If you don't have one yet: Get one.
  It is free and it enables you to enjoy the friendly and welcoming MEGA65
  community.

* [Create an issue](https://github.com/MJoergen/C64MEGA65/issues/new/choose)
  here on the official C64MEGA65 GitHub repository or post your problem in the
  [#other-cores](https://discord.com/channels/719326990221574164/794775503818588200)
  channel on Discord.

## 5) No image or no sound via HDMI

1. Try everything that is described
   [here](https://github.com/MJoergen/C64MEGA65#hdmi-compatibility).

2. If (1) does not work, try the experimental core
   [Alpha 7 for Version 5](https://discord.com/channels/719326990221574164/794775503818588200/1064498334515068958).
   This experimental core fixes some commom HDMI issues.
   You need a Discord login for being able to access the download link for
   Alpha 7. If you don't have one yet: Get one. It is free and it enables you
   to enjoy the friendly and welcoming MEGA65 community.

3. [Create an issue](https://github.com/MJoergen/C64MEGA65/issues/new/choose)
   here on the official C64MEGA65 GitHub repository or post your problem in the
   [#other-cores](https://discord.com/channels/719326990221574164/794775503818588200)
   channel on Discord.

## 6) The VGA output looks strange or flickers or I lose VGA sync

1. Always try the "auto-adjust" (or similarly named feature) of your screen
   first. This resolves 90% of all issues.

2. Switch-off "HDMI: Flicker-free" and learn more about the issue
   that the flicker-free mode sometimes creates on VGA systems
   [here](README.md#important-advice-for-users-of-analog-vga-and-retro-15-khz-rgb-over-vga)

3. If your monitor supports it, try to use the retro "15 kHz RGB" mode

## 7) My retro monitor does not work with the core

### Analog devices

There is a [dedicated documentation](doc/retrotubes.md) that explains you how to
connect retro displays with cathode ray tubes to the MEGA65 using the Commodore 64
for MEGA65 core.

### LCD or TFT devices

Make sure that you have 
[switched-off HDMI: Flicker-free](README.md#important-advice-for-users-of-analog-vga-and-retro-15-khz-rgb-over-vga)
when using retro monitors via the MEGA65's VGA out.

## 8) My mouse does not work

Make sure that you use either a real C64 mouse or
[MouSTer](https://retrohax.net/shop/modulesandparts/mouster/).

The
[C64 mouse "1351"](https://www.c64-wiki.com/wiki/Mouse_1351)
is clearly superior to the C64 mouse "1350" as the latter one does not feature
proportional movements and therefore does not feel right, for example when you
use GEOS.

Caution: AMIGA mice look pretty much like C64 mice but the C64 core does not
support AMIGA mice, yet. The MEGA65 core does support AMIGA mice and this
feature is on our roadmap.

## 9) Can I use cartridges?

Yes, from Version 5 on, the core supports both real hardware cartridges that
you can insert into the MEGA65's Expansion Port and simulated cartridges that
you can load as `*.crt` files from your SD card. Make sure that you read
[@TODO section ABC](@TODO)
of the user's manual. The core is able to run more than 99% of all game
cartridges. If want to use certain sophisticated cartridges other than games,
make sure that you checkout
[this document](https://github.com/MJoergen/C64MEGA65/blob/develop/doc/cartridges.md)
dedicated to certain featured hardware cartridges.

## 10) Can I use IEC devices?

Yes, from Version 5 on, you can connect floppy drives (such as the original
1541 and 1581), hard disks, printers, plotters or modern devices such as the
SD2IEC and the Ultimate-II+ to your MEGA65. All CBM-Bus/IEEE-488 bus/IEC Bus
compliant devices are supposed to work.

Caution: Avoid device number conflicts! The core uses device number #8 for
the built-in simulated 1541 that can mount `*.d64` files. So you need to
ensure that no other drive uses #8 and that all the device numbers you use
are correct.
[Learn more here](https://www.c64-wiki.com/wiki/Device_number) and make
sure you activate the feature using the menu item "IEC: Use hardware port"
if you want to use.

## 11) Certain games or demos won't load while others load

If you are loading from a large storage device such as the SD2IEC, try the
internal simulated 1541 drive.

Some games or demos don't like additional devices at the IEC port other than
one drive #8. Try if switching off "IEC: Use hardware port" helps.

In case you are using JiffyDOS you could also try going back to the standard
Kernal. If you have other fast loaders activated using simulated or real
freezer cartridges, try switching them off.

## 12) How many files in a folder can the file browser handle?

The file browser can handle about 25,000 characters. If we assume an average
length of a filename (including the file extension) of 40 characters then this
means 25,000 / 40 = 625 files.

You might find
[this bash script](https://github.com/MJoergen/C64MEGA65/tree/develop/M2M/tools/mover.sh)
helpful. You can run it inside a folder with a lot of files and afterwards you
have a directory structure `a .. z` and the files are moved there by name,
plus you will have a folder called `0` where all the files that start with
digits are. Don't forget to go to the folder `m` and remove `mover.sh`.


## 13) Which features are on the roadmap?

[Here](https://github.com/MJoergen/C64MEGA65/blob/develop/VERSIONS.md) is the
roadmap for the upcoming Version 5.

And
[here](https://github.com/MJoergen/C64MEGA65/blob/develop/ROADMAP.md)
is the roadmap for "later than Version 5".

## 14) Where can I post and discuss my feature request?

The
[#other-cores](https://discord.com/channels/719326990221574164/794775503818588200)
channel on the MEGA65 discord is the right place to post and
discuss feature requests.

## 15) Are there cores other than the C64 available or in development?

Yes. Please visit this website, it contains a list of MEGA65 cores that
will be constantly updated:

https://sy2002.github.io/m65cores/

If you are interested in making your own core or in porting cores from other
projects such as MiSTer: The website is also sharing additional information
about how to get started with doing this and about the
[MiSTer2MEGA65 framework](https://github.com/sy2002/MiSTer2MEGA65).
