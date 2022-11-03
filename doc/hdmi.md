# Description of the various HDMI screen resolution modes

## Config menu
The config menu contains the following six entries containing the word HDMI:

* HDMI: CRT emulation
* HDMI: Zoom-in
* HDMI: Force 60Hz
* HDMI: 4:3 mode
* HDMI: DVI (no sound)
* HDMI: Flicker-free

Of these six options, only "Zoom-in", "Force 60Hz", and "4:3 mode" affect the
actual HDMI screen resolution.


## Possible resolutions

* 720p 50 Hz : This is the default (PAL) resolution with 1280x720 (16:9) image,
  but with a 160 pixel black border on the left and right sides, yielding an
  effective resolution of 960x720 matching the C64 cores 4:3 aspect ratio.

* 720p 60 Hz : This is the same as above, but with a 60 Hz refresh rate. Only needed
  for extra compatibility, in case the monitor does not support 50 Hz frame rate.

* 576p 50 Hz : This is the screen resolution 720x576 (5:4), matching the
  default MEGA65 output. There is no black border. Even though the aspect ratio
  is 5:4, it is widely used instead of 4:3.

## Matching config menu with screen resolution

 Zoom |   60  |   4:3 | Monitor resolution | Black border
----- | ----- | ----- | ------             | ------
   0  |    0  |    0  | 720p 50            | yes
   0  |    1  |    0  | 720p 60            | yes
   0  |    x  |    1  | 576p 50            | no
   1  |    0  |    0  | 720p 50            | no
   1  |    1  |    0  | 720p 60            | no
   1  |    x  |    1  | 576p 50            | no

