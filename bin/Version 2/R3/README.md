Version 3 - Release Candidate 1
===============================

`C64MEGA65-3rc1.cor` and `C64MEGA65-3rc1.bit` are the Release Candidate 1
(V3rc1) for version 3 of the C64 for MEGA65 core.

V3RC1 fixes a rather big bug that might be responsible for many
incompatibility effects that users noticed: Our core is not yet supporting
the C64's User Port. But the underlying MiSTer core indeed does support the
User Port. All input signals there need to be treated active low in a standard
C64 configuration, i.e. the input signals need to be set to `1` to signal
`<nothing>`. We had them set to `0` in all releases prior to V3rc1, and in
V3rc1 we changed this to `1` just as MiSTer does it:

https://github.com/MiSTer-devel/C64_MiSTer/blob/master/c64.sv#L1506

So the fix itself is rather trivial, as this is often the case as soon as
you know how ;-) This is our commit that fixes the issue:

https://github.com/MJoergen/C64MEGA65/commit/5f1f55fe14e3250691549025e95f55c71fc2197f

### Why did this bug impact Bomberman?

As described
[here](https://github.com/MJoergen/C64MEGA65/issues/1#issuecomment-1160094792),
Bomberman did not work but acted as if some ghost always pressed the fire
button plus moved the joystick upwards.

The reason for that behavior is, that the Bomberman game as described in the
[C64 Wiki](https://www.c64-wiki.com/wiki/Bomberman_C64)
supports a **User-Port-based** 
[Multiplayer Joystick Interface](https://www.c64-wiki.com/wiki/Multiplayer_Interface)
so that you can have more than two joysticks.

Due to the low-active bug described above, the Bomberman game code "detected"
activities from the Multiplayer Joystick Interface on the User Port.

Release 2
=========

`C64MEGA65-2-R3.cor` and `C64MEGA65-2-R3.bit` are the official release 2
as described here:

https://github.com/MJoergen/C64MEGA65/blob/V2/VERSIONS.md#version-2---june-18-2022
