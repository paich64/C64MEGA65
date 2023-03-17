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

   Stick to `FAT32`. Don't use any improved or more modern version of
   file-system. On Windows and Linux it is normally quite
   straightforward to format an SD card as `FAT32`. If you are on a
   Mac, scroll down and read "Formatting SD cards on a Mac".

3. Is your card larger than 32GB?

4. Are you using a cheap no-name card?

5. Please try to re-format your card and then copy everything on the card from scratch

6. If (1) to (5) do not help: Use another card

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

It is very compatible. Not yet as good as Vice but from Version 4 on, the
core runs hundreds of
[demanding demos flawlessly](https://github.com/MJoergen/C64MEGA65/blob/master/tests/demos.md),
plays thousands of games without a single glitch, including games that need
a REU such as
[Sonic the Hedgehog](https://csdb.dk/release/?id=212523)
and the core offers disk writing abilities for the simulated 1541, so
that you can save your game states or your work in GEOS.

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

* Most demos work best when you use the original CIA, so we recommend to switch-off
  "CIA: Use 8521 (C64C)" by default. But some games and demos need the new 8521 CIA.
  So from time to time the only thing you can to is to experiment a bit with the
  settings.

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

## 6) The core's VGA output looks strange

1. Always try the "auto-adjust" (or similarly named feature) of your screen
   first. This resolves 90% of all issues.

2. Switch-off "HDMI: Flicker-free" and learn more about the issue
   that the flicker-free mode sometimes creates on VGA systems
   [here](https://github.com/MJoergen/C64MEGA65#important-advice-for-users-of-analog-vga-and-retro-15-khz-rgb-over-vga).

3. If your monitor supports it, try to use the retro "15 kHz RGB" mode

## 7) My retro monitor does not work with the core

Right now, the core only supports three different video outputs:

* HDMI connector: 1280×720 pixels (720p) at 50 Hz
* VGA connector: 720x576 pixels (576p) at 50.125 Hz (PAL): 31 kHz horizontal sync frequency
* VGA connector: 720x288 pixels at 50.125 Hz (PAL): 15 kHz horizontal sync frequency

If you are using any of the VGA modes, switch off "HDMI: Flicker-free" as described
above in question (6).

Please be aware that even if you switch on the retro "15 kHz RGB" mode, the pinout
of the VGA connector does not change: Pin 13 still delivers HSYNC and pin 14
still delivers VSYNC. See this
[Wikipedia article on VGA](https://en.wikipedia.org/wiki/VGA_connector)
for details. If you are using simple adaptors from the MEGA65's VGA out to your
retro monitor then you might experience strange effects on the retro monitor.
The reason is that the C64 core is currently not yet able to generate a
[CSYNC signal](https://en.wikipedia.org/wiki/Component_video_sync),
which is what many retro monitors need (instead of HSYNC and VSYNC).

Maybe there are some active converters (other than "just adaptor cables") that
are able to deliver the correct signals for certain retro monitors. Right now
this is unkown terrain for me, so please contact me and share your findings
and I will publish them.

Generating a CSYNC signal is on the roadmap, you will find it under the headline
"VGA retro CSync generation" under
["Technical Roadmap"](https://github.com/MJoergen/C64MEGA65/blob/master/ROADMAP.md#technical-roadmap).

Additionally, Paul Gardner-Stephen is working on an expansion board that (when done)
you will be able to stick into your MEGA65 and then you will have native composite output.
Learn more about the progress on Paul's blog, foe example 
[here](https://c65gs.blogspot.com/2023/01/working-on-composite-video-output-for.html)
and
[here](https://c65gs.blogspot.com/2023/01/adding-colour-to-mega65s-composite.html).

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

## 9) Can I use cartridges or real IEC devices?

Not yet, but we are working to support this. Look at the
[roadmap for the upcoming Version 5](https://github.com/MJoergen/C64MEGA65/blob/develop/VERSIONS.md).

## 10) Which features are on the roadmap?

[Here](https://github.com/MJoergen/C64MEGA65/blob/develop/VERSIONS.md) is the
roadmap for the upcoming Version 5.

And
[here](https://github.com/MJoergen/C64MEGA65/blob/develop/ROADMAP.md)
is the roadmap for "later than Version 5".

## 11) Where can I post and discuss my feature request?

The
[#other-cores](https://discord.com/channels/719326990221574164/794775503818588200)
channel on the MEGA65 discord is the right place to post and
discuss feature requests.

## 12) Are there cores other than the C64 available or in development?

Yes. Please visit this website, it contains a list of MEGA65 cores that
will be constantly updated:

https://sy2002.github.io/m65cores/

If you are interested in making your own core or in porting cores from other
projects such as MiSTer: The website is also sharing additional information
about how to get started with doing this and about the
[MiSTer2MEGA65 framework](https://github.com/sy2002/MiSTer2MEGA65).
