### On Screen Menu

* There are known bugs in the on-screen-menu such as showing menu items as
  "selected" that are not (for example after you opened the Help menu) or
  such as showing the menu selection bar at odd positions.

* Strange (no reproduction steps yet) "dual selection" in some menu 
  close/reopen/maybe reset inbetween cases

* There is a known bug in the file selector: From time to time you might see
  totally scrambled file names. It can for example happen, when a game or demo
  asks you to insert the next disk. If this happens: Here is a workaround:
  Just go up one directory level in the file browser by choosing ".." and then
  go back into the folder where you originally were and continue with mounting
  More details from AmokPhaze:
  https://discord.com/channels/@me/1034779919802191882/1081253026242777118

### System

* Black screen on startup (while the OSD is still working) when no SD card
  is inserted (neither internal nor external) - OR - when no SD card is
  readable for the system.

* Black screen from time to time on startup (independent if a cartridge is
  inserted or not). Might have to do with wrongly initialized
  $8000 content selection upon boot-up. Will be tested with this:
  https://discord.com/channels/@me/1034779919802191882/1088021558204846132
  A reset is currently the workaround.
  I reckon that we might not always have well initialized signals in the
  realm of the cartridge and/or due to us switching on the transcievers
  by default (chipenable) - so might be a simple initialization issue.

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
