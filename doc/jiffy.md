Using JiffyDOS
==============

The advantage of JiffyDOS is that you can load files from the simulated
1541 disk drive (`*.d64` files) significantly faster. It also works with real
hardware disk drives that you attach via the MEGA65's IEC port as long as you
have installed the JiffyDOS ROM on those drives, too.

Learn more about JiffyDOS in the
[C64 Wiki](https://www.c64-wiki.com/wiki/JiffyDOS).
You will also find download links to the user's manual there.

Where and how to buy
--------------------

JiffyDOS is commercial software. Here is a list of authorized Sales Channels:

https://www.go4retro.com/products/jiffydos/

Here is what you need to buy:

1) JiffyDOS 64 KERNAL ROM Overlay Image
2) JiffyDOS 1541 DOS ROM Overlay Image 

Some shops offer variants such as C64C or 1541-II. Don't buy those.

The download packages are ZIP files. Unpack them. For performing the next
steps, you only need the `*.bin` files.

Prepare the files
-----------------

The C64 for MEGA65 core needs two files, each of them needs to be exactly
`16 kB = 16,384 bytes` in size.

### C64 Kernal ROM: `jd-c64.bin`

1. Download the C64 BASIC ROM [`basic.901226-01.bin` from zimmers.net](http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/c64/basic.901226-01.bin)
2. Concatenate the C64 BASIC ROM with JiffyDOS: First the BASIC and then
   JiffyDOS
3. Make sure that the resulting file is called `jd-c64.bin`

#### Example for the macOS and Linux terminal

The following commands assume that you are a folder that is empty with the
exception of one file that is called `JiffyDOS_C64_6.01.bin`.

```bash
wget http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/c64/basic.901226-01.bin
cat basic.901226-01.bin JiffyDOS_C64_6.01.bin > jd-c64.bin
```

#### Example for the Windows command prompt

The following command assumes that you are in a folder that contains the
following two files: `JiffyDOS_C64_6.01.bin` and `basic.901226-01.bin`.

```cmd
copy /b basic.901226-01.bin +JiffyDOS_C64_6.01.bin jd-c64.bin
```

### C1541 DOS ROM: `jd-c1541.bin`

The JiffyDOS download package contains two `*.bin` files. Take the one that
is exactly `16 kB = 16,384 bytes` in size and rename it to `jd-c1541.bin`.

Install and use JiffyDOS
------------------------

* Make sure the core is not started (for example: switch off the MEGA65)

* Make sure you have a `/c64` folder on the SD card that is active, when the
  C64 for MEGA65 core boots. Remember, that the SD card slot on the back of
  the MEGA65 takes precedence over the SD card slot at the bottom.

* Copy `jd-c64.bin` and `jd-c1541.bin` to the `/c64` folder of your SD card.

* Start the core with the updated SD card

* Select "JiffyDOS" in the "Kernal" submenu of the core's menu
