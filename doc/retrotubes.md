# Using Retro Cathode Ray Tubes

The C64 for MEGA65 core is capable of providing analog retro signals via the VGA port that have a 15 kHz horizontal frequency and that either
use a horizontal+vertical syncronization signal or a composite syncronization signal. The signal it self is a [component signal](https://en.wikipedia.org/wiki/Component_video#Component_versus_composite).

When using retro gear via the MEGA65' VGA port: **Make sure that you disable HDMI: Flicker-free** otherwise you might run into a bunch of
problems. Learn more in the [user's manual](../README.md#important-advice-for-users-of-analog-vga-and-retro-15-khz-rgb-over-vga) and
in the [FAQ](../FAQ.md#7-my-retro-monitor-does-not-work-with-the-core).

## BNC

### VGA to BNC cable

To connect high-end or broadcast/production monitors with BNC connectors for RGB, you will require a VGA Plug to 5 BNC RGB Male Plugs Video Cable.
However, if you're using it for retro RGB video, connecting 4 plugs should suffice unless you're connecting to a projector or plasma TV that requires
separate horizontal and vertical syncing signals. The C64 core also supports this mode over 15kHz, making it a useful cable to have.

![vga-to-bnc-cable](assets/vga-to-bnc.jpg)

### Cable and connection details

To set up retro RGB, you'll need three RGB signals along with CSYNC. In the case of the C64 for MEGA65 core, the horizontal sync will be used as CSYNC.
For CSYNC, you can use the white lead, while the black lead can be left unconnected. Connect the R (Red), G (Green), and B (Blue) signals to their
respective analog inputs on the device or monitor. Take the CSYNC lead and connect it to the "external sync" input to the composite input panel.
By following these instructions, you will ensure the proper connection of the RGB signals and CSYNC for correct functionality. 

![vga-to-bnc-cable](assets/bnc-connect.jpg)

Connect the opposite end of the cable to the MEGA65's VGA port.

![vga-mega65](vga-connect.jpg)

### Configuring the C64 for MEGA65 core

Look at the screenshot and choose the following options in VGA and HDMI display modes.
Turn off flicker-free and switch the standard mode to 15 Khz with CSYNC.

![core-config](assets/coresettings.jpg)

Important: Before turning on the monitor, make sure to switch from the Standard mode to the
Retro 15Khz mode + CSYNC. Providing the CRT with a 31kHz signal could potentially damage
your equipment. Exercise caution and ensure the correct setting is selected to avoid
damage to the monitor.

### Example setup

A second LCD monitor will be useful for making the necessary adjustments to the configuration.

![core-config](assets/bnc-example.jpg)
