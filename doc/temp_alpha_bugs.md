### On Screen Menu

* There are known bugs in the on-screen-menu such as showing menu items as
  "selected" that are not (for example after you opened the Help menu)

### System

* Black scren on startup when in MONITOR mode, while no Shell is running:
  Nothing on VGA and nothing on HDMI. Expected is that we would see
  a normal C64 screen.

* Black screen on startup (while the OSD is still working) when no SD card
  is inserted (neither internal nor external) - OR - when no SD card is
  readable for the system.

* Black screen from time to time on startup (independent if a cartridge is
  inserted or not): HDMI-only: VGA shows a normal C64 start screen including
  a blinking cursor. But on HDMI the screen stays black but you can use
  the OSM via the Help key.

### REU and signal routing

* TreuLove is not working for @mpryon and @muse on V5A10:
  https://discord.com/channels/@me/1034779919802191882/1087995656163041291

### HyperRAM:

* Even though he seems to be on a Rev D, @mpryon does not have any glitches
  with TreuLove any more since V5A9:
  https://discord.com/channels/@me/1034779919802191882/1087336036977344532
  https://discord.com/channels/@me/1034779919802191882/1087445661827469442

* But @muse still has glitches with V5A9
  https://discord.com/channels/@me/1034779919802191882/1088000630611791893

* HyperRAM Rev D: @muse and @mpryon having CRASHING TreuLove when using the
  Alpha 10 core versus the Alpha 9 core (?!). Alpha 10 actually did not
  change anything significant versus Alpha 9. We ruled out simple reasons
  such as "wrong config file":
  https://discord.com/channels/@me/1034779919802191882/1089138523912802344
  https://discord.com/channels/@me/1034779919802191882/1089989286092361838
