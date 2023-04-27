Cartridge Cases
===============

Some modern "homebrew" cartridges come as a raw PCB, without a plastic case.
**Never insert a raw PCB into your MEGA65's Expansion Port.** It is nearly
impossible to align all the pads and connections correctly so you might
damage the MEGA65 - or - in less drastic cases the cartridge will not work
reliably, but "only sometimes" and you will experience strange bugs.

Put your cartridges in cartride cases from
[The Future was 8BIT](https://www.thefuturewas8bit.com/c64romcart.html)
or from
[Protoparts](https://www.protoparts.at/product-category/gehaeuse/).

Flash Cartridges
================

First of all: Please support our friends at 
[Protovision](https://www.protovision.games)
and
[RGCD](https://rgcd.bigcartel.com/products)
and buy as many original hardware cartridges from them as you can and want
to afford. The Commodore 64 community needs to stay alive and therefore
publishers who are publishing to our beloved computer more than 40 years
after its release should be rewarded.

But there are many awesome
[game releases and other releases on csdb.dk](https://csdb.dk/browse.php?grouptype_id=0&profession_id=0&type=releases&releasetype_id=46&eventtype_id=0&bbstype_id=0&sidtype_id=0&browsesub=Browse%21)
that are not published on a hardware cartridge. And unfortunately more often
than not, your favorite cartridge is sold-out on
[Protovision](https://www.protovision.games)
and
[RGCD](https://rgcd.bigcartel.com/products).

So you might need another solution.

Why would you want to use real hardware Flash Cartridges on the MEGA65
while the MEGA65 can simulate cartridges using `*.crt` files that you can
store on and load from your SD card? The answer is, that a simulation is never
as perfect as real hardware: We use the MEGA65's HyperRAM to store the data
from the `*.crt` files when we simulate the cartridge. While this works very
well in more than 99% of the cases, the constraints of the HyperRAM (for example
its latency) can lead to undesired artefacts when playing simulated cartridges: We
actually need to halt the CPU for a short period of time, each time the cartridge
does a bank switch. Most of the time you won't notice, but as said, there can be
unintended consequences.

So for a 100% glitch-free retro experience, you might want to use real
hardware, i.e. real Flash Cartridges.

EasyFlash 1 and EasyFlash 1CR
-----------------------------

The original EasyFlash (aka EasyFlash 1) and the cost reduced
[EasyFlash 1CR](https://www.freepascal.org/~daniel/easyflash/)
are for sure among the most popular cartridges in the scene. Many new games
and other releases come in the EasyFlash cartridge format. Here is a
description about the EasyFlash taken from the
[original EasyFlash website](https://skoe.de/easyflash/):

"EasyFlash is a cartridge for the C64 expansion port. In contrast to
traditional cartridges, this one can be programmed directly from the C64.

You can easily create various classic computer game cartridges or program
collections with it. All what you need to do this is a C64, an EasyFlash,
the software available
[here](https://skoe.de/easyflash/downloads/)
and an image of the cartridge `*.crt`. As these `*.crt` files may be
quite large, a large capacity disk drive like the
FD-2000 or an
[SD2IEC](https://www.ncsystems.eu/)
device may be useful. For smaller drives EasySplit can be used to compress
and split large cartridge images."

Learn more about EasyFlash on the
[C64 Wiki](https://www.c64-wiki.com/wiki/EasyFlash). 

Using the our C64 core, your MEGA65 is able to flash EasyFlash
cartridges. 

### EasyFlash 1CR

#### Buy the correct version

Since the original EasyFlash 1 is hard to find these days, we will
focus on the
[EasyFlash 1CR](https://www.freepascal.org/~daniel/easyflash/)
by Dani&euml;l Mantione. This handy cartridge is officially and proactively
supported by the C64 for MEGA65 core development team, so this is your number
one go to Flash Cartridge. Buy it
[here](https://www.freepascal.org/~daniel/easyflash/)
by filling out Dani&euml;l's form. Scroll down to the bottom of his web page
to find an order form. Here are some important considerations:

* Use the field where you specify your postal address to add the comment
  that you want a so called "Through Hole" version of the cartridge and
  **not** the so called "SMD" version of the cartridge. Only the
  "Through Hole" version is supported on the MEGA65 at this time. (This might
  change in future.)

* We highly recommend that you buy fully assembled cartridges to ensure
  that they actually work on your MEGA65.
  
* You need a case for the cartridge. The easiest way to obtain one is to
  order it from Dani&euml;l's website together with your Easy Flash 1CR.

The following image shows, how the "Through Hole" version of the EF 1CR
looks like and it shows different case variants that Dani&euml;l sells.
We recommend to order a
[The Future was 8BIT](https://www.thefuturewas8bit.com/c64romcart.html)
or
[Protoparts](https://www.protoparts.at/product-category/gehaeuse/).
case.

![EF1CR-case-variants](assets/ef1cr-cases.jpg)
  
#### The basic idea and usage of the Easy Flash 1CR

As "CR" stands for "cost reduced", one of the basic idea of the Easy Flash
1CR is that it is affordable enough to be the Flash Cartrdige for all the
cartridge-based games that you really love: Flash once and enjoy forever.
Buy one cartridge per game. For avoiding misunderstanding: The EF 1CR
can be re-flashed as often as you like.

Conveniently, the Easy Flash 1CR comes with a preinstalled flasher: When you
insert the cartridge into your MEGA65's Expansion Port and
[start the machine and the cartridge correctly (!)](@TODO)
then you will see the EasyFlash program's start screen and you will
imediatelly be able to flash the `*.crt` file as
[described here](https://skoe.de/easyflash/writecrt/). If you don't have a
[SD2IEC](https://www.ncsystems.eu/)
or something similar, then you will likely need to split large `*.crt` files
into multiple `*.d64` images using
[EasySplit](http://skoe.de/easyflash/splitfiles/). Watch this
[YouTube video](https://youtu.be/jD-RmB6YzXc)
to learn how the flashing on the MEGA65 works when you have split the `*.crt`
files into multiple `*.d64` files.

#### Adjusting the case for being able to re-flash any time

| Lydon's Example                  | sy2002's Example                  |
|----------------------------------|-----------------------------------|
| ![](assets/ef1cr-case-lydon.jpg) | ![](assets/ef1cr-case-sy2002.jpg) |


==============================================================================

Cases:

TFW8-bit
https://www.thefuturewas8bit.com/c64romcart.html

Protoparts
https://www.protoparts.at/product-category/gehaeuse/

Buy original cartridges from our friends at

aslödk qöldk qöldk qöldk qwöldk qwöldkqwöldk qwöldk qölwdk qölwkdqlödkqwöldkq
kj dqlkwjd lkqdj klqwj dlqkwj dlkqj dklqwj dklqwj dlkqwjdlkqwj dklqj dqklwjd
qwlkdj qkldjlkqwdj qkl djlkqwj dklqwj dklqwj dlkqj dklqj dklqwj dkqlj.



qwdjklqw djlqkwj dlkqjd lqkwj dlkqwj dklqj dlqkwjd qklwjd wqlkjd qlkwjd lkqjw
qwdölk qwökd öqlwk.



How to use
...incl updating core 0 or plugging in while the MEGA65 is on

...warning: Through hole version vs. SMD version

Important info about cases

How to flash

... using EasySplit and D64 disks

... using an SD2IEC or other IEC devices that can hold large CRTs

Technical info

EasyFlash 3
===========

TODO LIST
=========

Kungfu (?)
The Final Cartridge III
Action Replay (?)
GeoRAM

CORE #0 Notes
-------------

https://builder.mega65.org/job/mega65-core/job/683-cartflash/

1. Enter MEGAFLASH via NO SCROLL
2. Press MEGA + ,
3. Answer the questions
4. Flash core 0

Hints:

* The prime number is: 386093
* The airspeed is (all caps): 11 METRES PER SECOND

 bit2core:

 https://github.com/MEGA65/mega65-tools/releases/tag/CI-development-latest
 
