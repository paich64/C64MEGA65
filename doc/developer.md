C64 for MEGA65 developer documentation
======================================

Building the core
-----------------

Refer to the
[MiSTer2MEGA65 documentation](https://github.com/sy2002/MiSTer2MEGA65/wiki)
for more details and for operating system specific details: You need a `bash`
or compatible shell, the GCC compiler environment including make, `awk` and
other typical tools.

```bash
git clone https://github.com/MJoergen/C64MEGA65.git
cd C64MEGA65
git submodule update --init --recursive
cd M2M/QNICE/tools/
./make-toolchain.sh 
```

Answer all questions that you are being asked while the QNICE tool chain is
being built by pressing Enter. You can check the success of the process by
checking if the Monitor is available as .rom file:

```bash
ls -l ../monitor/monitor.rom
```

Now build the Shell (firmware for on-screen-menu, mounting `D64` images on
an SD card, etc.):

```bash
cd ../../../CORE/m2m-rom/
./make_rom.sh
ls -l m2m-rom.rom
```

If everything went well, then the last command will generate the expected
output.

Now use Vivado to open `CORE/CORE-R3.xpr` to synthesize, implement and
generate the bitstream.

Making a `.cor` file
--------------------

### Get `bit2core`

* [Linux and Windows binaries](https://builder.mega65.org/job/mega65-tools/job/development/)
* [macOS binaries](https://github.com/MEGA65/mega65-tools/releases/tag/CI-development-latest)
* [GitHub repository](https://github.com/MEGA65/mega65-tools)

### Use `bit2core`

The C64 core can run cartridges that are inserted into the MEGA65's expansion
port. The make sure that the MEGA65's CORE #0 core selection logic knows that
and automatically starts the C64 core, if an appropriate C64 cartridge is
inserted, make sure that you use the correct flags for the `bit2core` tool:

```bash
bit2core mega65r3 C64M65-WIP-V5-A23.bit "C64 for MEGA65" "WIP-V5-A23" C64M65-WIP-V5-A23.cor "=default,c64cart+c64cart"
```

Conventions for version info in `*.cor` files:

* Releases are called "V4", "V5", etc.
* Alpha releases are called "WIP-Vx-Ay", where `x` is the upcoming next major
  release that this alpha release works towards and y is the version of the
  alpha release, just counting upwards.

Debug mode
----------

If you do not have a
[JTAG adapter](https://files.mega65.org?ar=3c388c8c-bc3f-461b-84bb-e12dfd479ae2),
then you cannot use the debug mode.

The C64 core - like all MEGA65 cores powered by the
[MiSTer2MEGA65](https://github.com/sy2002/MiSTer2MEGA65)
framework - has a debug mode that consists of a real-time log of various system
states and an interactive debug console.

To access the log and the console, connect a serial terminal to the MEGA65
using the JTAG adapter while making sure that the serial terminal's parameters
are set to 115,200 baud 8-N-1, no flow control such as XON/XOFF, RTS/CTS,
DTR/DSR. Set any terminal emulation to "None" and if you can configure it,
set the send mode to "Interactive" (instead of things like "Line buffered").

To switch from the real-time log to the interactive mode, press
<kbd>Run/Stop</kbd> + <kbd>Cursor Up</kbd> and then while holding these press
<kbd>Help</kbd>.

Learn more about the debug mode in the MiSTer2MEGA65 Wiki in the "Hello World"
chapter, section
[Understanding the QNICE debug console](https://github.com/sy2002/MiSTer2MEGA65/wiki/3.-%22Hello-World%22-Tutorial#understanding-the-qnice-debug-console).

Main differences compared to the MiSTer core
--------------------------------------------

### Main clock and flicker-free HDMI

@MJoergen: Describe, here are some figures froom speed.md that we might
be able to delete speed.md after you've written this section:

C64 has this odd output frequency that is not exactly 50 Hz

Official C64 clock speed at PAL: 985.248 Hz

MiSTer speed: 31.527954 MHz

Clock Divider 32 leads to C64 speed: 985.249 Hz <= MiSTer is damn close


Our old core (before the flicker fix) had: 31.527778 MHz
(Our FPGA does not allow a clock that is as close to the C64 than
MiSTer's FPGA does)

Clock Divider 32 leads to C64 speed: 985.243 Hz <= still damn close but
leads to visual artefacts on HDMI (why?)

Dynamic HDMI flicker-fix

### Keyboard

MiSTer uses a PS/2 keyboard and then translates the PS/2 keystrokes into
signals for the C64's CIA. This is done in `fpga64_keyboard.vhd` (located in
the file `CORE/C64_MiSTerMEGA65/rtl/fpga64_sid_iec.vhd`).

Since the MEGA65 has a built-in keyboard, we routed the CIA signals on the
level of `fpga64_sid_iec` (located in the file
`CORE/C64_MiSTerMEGA65/rtl/fpga64_sid_iec.vhd`)
so that our own `keyboard` entity (located in the file
`CORE/vhdl/keyboard.vhd`) can directly and latency-free generate the
appropriate signals for the C64's CIA.

### PHI2

For supporting hardware cartridges, one needs to output a correct PHI2
signal to the Expansion port. MiSTer did not offer a PHI2 signal. We added
it to `fpga64_sid_iec`.

### PLA

The MiSTer C64 core architecture does not "literally" implement a PLA chip
but bundles the PLA together with the ROMs and other logic in a VHDL entity
called `fpga64_buslogic` and located in
`CORE/C64_MiSTerMEGA65/rtl/fpga64_buslogic.vhd`.

We bugfixed enhanced `fpga64_buslogic` and `fpga64_sid_iec` so that the
simulated PLA behaves according to the
[correct logic formulas](PLA.md).

### Simulated cartridges

@MJoergen: Describe

