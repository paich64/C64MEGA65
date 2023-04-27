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
than not, your favorite cartridge is sold out on
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

==============================================================================

Cases:

TFW8-bit
https://www.thefuturewas8bit.com/c64romcart.html

Protoparts
https://www.protoparts.at/product-category/gehaeuse/

Buy original cartridges from our friends at



EasyFlash 1 and EasyFlash 1CR
-----------------------------


aslödk qöldk qöldk qöldk qwöldk qwöldkqwöldk qwöldk qölwdk qölwkdqlödkqwöldkq
kj dqlkwjd lkqdj klqwj dlqkwj dlkqj dklqwj dklqwj dlkqwjdlkqwj dklqj dqklwjd
qwlkdj qkldjlkqwdj qkl djlkqwj dklqwj dklqwj dlkqj dklqj dklqwj dkqlj.

![EF1CR-case-variants](assets/ef1cr-cases.jpg)

qwdjklqw djlqkwj dlkqjd lqkwj dlkqwj dklqj dlqkwjd qklwjd wqlkjd qlkwjd lkqjw
qwdölk qwökd öqlwk.

https://www.freepascal.org/~daniel/easyflash/

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
 
