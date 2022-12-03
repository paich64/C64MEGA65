### Version 5 Work-in-Progress: List of inofficial builds

The purpose of this list is to track down regressions introduced in newer
builds that were not there in older builds. By finding the last known-to-work
build, we have a better chance to hunt down problems. The name of the build
can be checked in the "About & Help" menu of the core.

| Name        | Commit  | Comment
|-------------|---------|-------------------------------
| WIP-V5-A1   | c124785 | First attempt to fix the analog VGA display challenge ("underwater" waving screen effect) discovered by Discord user Maurice#4307 and as described here: https://discord.com/channels/719326990221574164/794775503818588200/1045984002634428427
| WIP-V5-A2   | dba02bd | Same as WIP V5-A1 but built with Vivado 2022.2
| WIP-V5-A3   | f7b34fb | Rework interrupt dispatching. Fixed frequency-ratio bug in HDMI-Flicker-Free mode. Refactor audio clock. CIA: Disk parport: ignore inputs on pins configured as output. CIA: fix timer reset values (Arctic Shipwreck). VIC: change xscroll and turbo latch time.
