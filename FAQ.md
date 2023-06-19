# FAQ - Frequently Asked Questions

## 1) My MEGA65 or the C64 core is behaving somehow weirdly

**The "HDMI back powering problem" is the root of all evil!**

The evil things that can happen range from display problems over SD card
problems (such as problems mounting the SD card, reading from the SD card)
to issues around the system's overall stability.

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

1. Are you having an [HDMI back powering problem](FAQ.md#1-my-mega65-or-the-c64-core-is-behaving-somehow-weirdly)?

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
Expansion Port,
[simulate cartridges using CRT files](README.md#simulated-cartridges) and
[use retro Commodore peripherals](README.md#iec-devices)
by plugging them into the MEGA65's IEC port. You can even
[work with retro 15 kHz cathode ray tube monitors](doc/retrotubes.md).

## 4) I cannot format a disk image (`*.d64`)

Indeed, the core is not yet able to format disks. We do have this topic on our
[roadmap](ROADMAP.md). What we suggest is that you use tools like the awesome
[DirMaster](https://style64.org/dirmaster) to create a bunch of formatted, empty
`*.d64` disk images and then use these disk images with your C64 for MEGA65 core.

## 5) The screen goes black when I choose JiffyDOS

JiffyDOS is commercial software. The C64 core does not come with
a preinstalled copy of JiffyDOS.
[Learn here](doc/jiffy.md)
where to buy and how to install it.

## 6) My game or demo crashes

* Are you having an [HDMI back powering problem](FAQ.md#1-my-mega65-or-the-c64-core-is-behaving-somehow-weirdly)?

* Make sure you are using the newest version of the core. Right now this is
  [Version 5](https://files.mega65.org?id=896a012f-59e4-456c-b91f-7e989b958241).
  The only officially supported place to get cores is the
  [MEGA65 FileHost](https://files.mega65.org?id=896a012f-59e4-456c-b91f-7e989b958241),
  so make sure you downloaded your copy there. Do not use any Alpha or Beta versions
  any more. Also double-check by pressing <kbd>Help</kbd> and then choosing the menu
  item "About & Help" that you are really running Version 5.

* If the game or demo is not designed for the REU, you absolutely need to
  switch-off the REU before running the game or demo. Learn more about this
  important fact
  [here](README.md#512-kb-ram-expansion-unit-1750-reu).
  
* If you use [JiffyDOS](doc/jiffy.md) or any other fastloader (for example
  by using a freezer cartridge): Switch everything back to the C64's
  [standard Kernal](README.md#commodore-kernals-and-jiffydos) and try
  this very game or demo again.

* Try to run with deactivated "HDMI: Flicker-free", but don't forget to
  reactivate this afterwards, because your experience is 10x better with
  Flicker-free ON (at least when you're on HDMI). Learn more
  [here](README.md#flicker-free-hdmi).
  
* If you are using real 1541 hardware via the IEC port, please also read
  the [section about IEC devices below](FAQ.md#13-can-i-use-iec-devices).
  
* Many modern games and demos are mainly tested on the C64C, so try to run the
  game or demo using the setting "CIA: Use 8521 (C64C)".  

* If you are loading from a large storage device such as the SD2IEC, try
  the simulated 1541 drive using a `*.d64` disk image instead.

* Some games or demos don't like additional devices at the IEC port other than
  one drive #8. Try if switching off "IEC: Use hardware port" helps.

* [Create an issue](https://github.com/MJoergen/C64MEGA65/issues/new/choose)
  here on the official C64MEGA65 GitHub repository or post your problem in the
  [#c64-core](https://discord.com/channels/719326990221574164/794775503818588200)
  channel on Discord.

## 7) No image or no sound via HDMI

1. Make sure you are running [Version 5](https://files.mega65.org?id=896a012f-59e4-456c-b91f-7e989b958241)
   of the core.

2. Try everything that is described
   [here](https://github.com/MJoergen/C64MEGA65#hdmi-compatibility).

3. [Create an issue](https://github.com/MJoergen/C64MEGA65/issues/new/choose)
   here on the official C64MEGA65 GitHub repository or post your problem in the
   [#c64-core](https://discord.com/channels/719326990221574164/794775503818588200)
   channel on Discord.

## 8) The VGA output looks strange or flickers or I lose VGA sync

1. Always try the "auto-adjust" (or similarly named feature) of your screen
   first. This resolves 90% of all issues.

2. Switch-off "HDMI: Flicker-free" and learn more about the issue
   that the flicker-free mode sometimes creates on VGA systems
   [here](README.md#important-advice-for-users-of-analog-vga-and-retro-15-khz-rgb-over-vga).

3. If your monitor supports it, try to use the [retro "15 kHz RGB" mode](doc/retrotube.md)

## 9) My retro monitor does not work with the core

### Analog devices

There is a [dedicated documentation](doc/retrotubes.md) that explains you how to
connect retro displays with cathode ray tubes to the MEGA65 using the Commodore 64
for MEGA65 core.

### LCD or TFT devices

Make sure that you have 
[switched-off HDMI: Flicker-free](README.md#important-advice-for-users-of-analog-vga-and-retro-15-khz-rgb-over-vga)
when using retro monitors via the MEGA65's VGA out.

## 10) My mouse does not work

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

## 11) Can I use cartridges?

Yes, from
[Version 5](https://files.mega65.org?id=896a012f-59e4-456c-b91f-7e989b958241)
on, the core supports both real
[hardware cartridges](README.md#hardware-cartridges) that
you can insert into the MEGA65's Expansion Port and
[simulated cartridges](README.md#simulated-cartridges)
that you can load as `*.crt` files from your SD card.

The core is able to run more than 99% of all game
cartridges.

### If only very few cartridges are working, you need to update CORE #0

If only some original retro catrdiges are working but the vast majority
of modern cartridges are not working then it is very likely that you need
a so called "CORE #0 update" or that you need to use a slightly scary,
yet kind-of save workaround.

To check if this is the case: Press the <kbd>Help</kbd> key while you
experience the "not working" situation. If the
[well-known C64 for MEGA65 menu](doc/demopics/c64mega65-1.jpg)
is not being shown after you pressed <kbd>Help</kbd>, then instead of the
dedicated C64 core, the standard MEGA65 core is currently running which
is the reason why your hardware cartridge is not working.

Here is why: The core in slot #0 (which is the MEGA65 core) decides, which
core needs to be started if a hardware cartridge is inserted into the MEGA65's
Expansion Port. The old version that most of the MEGA65 have installed is
buggy and needs to be updated.

[Learn how to update or how to use a workaround here](README.md#core-0-update).

### My hardware freezer or flash cartridge does not work

The core does support certain sophisticated hardware cartridges such
as the Action Replay, EasyFlash 1CR, EasyFlash 3, Epyx Fast Load,
Final Cartridge III, Kung Fu Flash, PowerCartridge and Super Snapshot.
But they are not all created equal and you sometimes need to apply
work-arounds to make them work.

Make sure you read the
[decidcated hardware cartridge documentation](doc/cartridges.md)
to learn more and **exactly** follow the instructions there.

### A certain simulated freezer (`*.crt`) does not work

While Version 5 - the most recent version of the core - does support
quite a bunch of **hardware** freezer and flash cartridges very well,
support for **simulated** (`*.crt`) freezer cartridges is still in
its infancy.

[This is a list of known issues](https://github.com/MJoergen/C64MEGA65/issues?q=is%3Aissue+is%3Aopen+simcrt)
when it comes to **simulated** (`*.crt`) freezer cartridges.

### "Homebrew" cartridges: Never insert a barebone PCB

Always make sure that you insert a cartridge that is
[housed in a proper case](doc/cartridges.md#cartridge-cases) and never
insert a barebone PCB into the MEGA65's Expansion Port.

### 13) Can I use IEC devices?

Yes, from Version 5 on, you can connect floppy drives (such as the original
1541 and 1581), hard disks, printers, plotters or modern devices such as the
SD2IEC and the Ultimate-II+ to your MEGA65. All CBM-Bus/IEEE-488 bus/IEC Bus
compliant devices are supposed to work.

### Avoid device number conflicts

The core uses device number #8 for the built-in simulated 1541 that can
mount `*.d64` files. So you need to ensure that no other drive uses #8 and
that all the device numbers you use are correct.
[Learn more here](https://www.c64-wiki.com/wiki/Device_number) and make
sure you activate the feature using the menu item "IEC: Use hardware port"
if you want to use.

### Switch-off HDMI: Flicker-free

The "HDMI: Flicker-free" mode
[very slightly changes the timing of the C64](README.md#flicker-free-hdmi).
While this is not a problem most of the time, it does lead to timing problems
with certain games (for example Rainbow Arts games on original 5 1/4"
disks) that are loaded via real 1541 floppys connected via the IEC port
to the MEGA65. Just to make sure that there are no misunderstandings: 
We are talking about real 1541 hardware here. Loading games via `*.d64`
disk images is **not** affected by "HDMI: Flicker-free" and also loading
games via an SD2IEC connected to the IEC port of the MEGA65 is also
not affected.

If you encounter incompatibilities when you load via real devices
connected to the IEC port, then switch-off "HDMI: Flicker-free" mode.

But in this case we would advise you heavily to also use an analog
retro monitor, because with "HDMI: Flicker-free" OFF, the output on HDMI
will be slightly jerky due to the misalignment of the C64's retro
output frequency and the frequencies that modern HDMI monitors are
actually able to display.
[Learn more here](README.md#flicker-free-hdmi).

## 14) How many files in a folder can the file browser handle?

The file browser can handle about 25,000 characters. If we assume an average
length of a filename (including the file extension) of 40 characters then this
means 25,000 / 40 = 625 files.

You might find
[this bash script](https://github.com/MJoergen/C64MEGA65/tree/develop/M2M/tools/mover.sh)
helpful. You can run it inside a folder with a lot of files and afterwards you
have a directory structure `a .. z` and the files are moved there by name,
plus you will have a folder called `0` where all the files that start with
digits are. Don't forget to go to the folder `m` and remove `mover.sh`.

## 15) The core is not remembering my settings

Make sure that you have a `/c64` folder on your SD card and make sure that
you copy the `c64mega65` file that came with the
[ZIP file that contains Version 5](https://files.mega65.org?id=896a012f-59e4-456c-b91f-7e989b958241)
to this very folder.

When going from an older version of the C64 core to a newer version
(for example from Version 4 to Version 5) you always need to overwrite your
old `c64mega65` file by the new one that came with the
[ZIP file](https://files.mega65.org?id=896a012f-59e4-456c-b91f-7e989b958241).

Important: Even if you have a `c64/c64mega65` file on your SD card: The core will
not save any settings in case you switched between SD cards during a certain session.
Next time you power-on the core, it will resume saving the settings until you switch
between SD cards for the next time.
[Learn more details here](README.md#config-file).

Currently, we cannot automate this manual chore and need to ask users to copy the
`c64mega65` file.
[Track our efforts](https://github.com/MJoergen/C64MEGA65/issues/16) to change
this by following
[this GitHub issue](https://github.com/MJoergen/C64MEGA65/issues/16).

## 16) Which features are on the roadmap?

[Here](ROADMAP.md) is the roadmap for future versions. Additionally, there are also 
[feature requests](https://github.com/MJoergen/C64MEGA65/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement)
that we might consider for future releases.

## 17) Where can I post and discuss my feature request?

[Engage with us on GitHub](https://github.com/MJoergen/C64MEGA65/issues) or in the
[#c64-core](https://discord.com/channels/719326990221574164/794775503818588200) channel
on Discord to discuss feature requests and the future of the C64 for MEGA65 core.

## 18) Are there cores other than the C64 available or in development?

Yes. Please visit this website, it contains a list of MEGA65 cores that
will be constantly updated:

https://sy2002.github.io/m65cores/

If you are interested in making your own core or in porting cores from other
projects such as MiSTer: The website is also sharing additional information
about how to get started with doing this and about the
[MiSTer2MEGA65 framework](https://github.com/sy2002/MiSTer2MEGA65).

## 19) I am a total newby and want to learn FPGA development and making or porting cores

If you own a MEGA65, then
[this short article](https://files.mega65.org?ar=898d573b-d30d-4438-8893-09455bd16400)
is a smooth start to FPGA development. It uses some of the tutorials of the
[MiSTer2MEGA65 framework](https://github.com/sy2002/MiSTer2MEGA65)
and some resources from the web to get you started.

Moreover, the
[#learn-fpga-dev](https://discord.com/channels/719326990221574164/1057791653517209601)
channel on Discord is a great place to meet likeminded people and to ask questions.

[Download and read](https://github.com/sy2002/MiSTer2MEGA65/blob/develop/doc/wiki/assets/FPGAs_VHDL_First_Steps_v2p3.pdf)
Helen DeBlumont's beginner "FPGAs with VHDL: First Steps" or go deep by working through the textbook
[The Designer's Guide to VHDL](https://picture.iczhiku.com/resource/eetop/sYiEyoAUyiEkPBBb.pdf)
by Peter J. Ashenden.
