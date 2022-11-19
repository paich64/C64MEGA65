C64 for MEGA65 Regression Testing
=================================

Before releasing a new version we strive to run all regression tests from
this folder. Since running through all the [demos](demos.md) takes some
serious effort, it might be that we are not always doing it.

Version 4 - MONTH, DD, YYYY
---------------------------

| Status             | Test                                        | Done by                | Date              
|:-------------------|---------------------------------------------|:-----------------------|:--------------------------
| :bangbang:         | C64 Emulator Test Suite V2.15               | sy2002                 | 11/19/22
| :white_check_mark: | [Demos](demos.md)                           | AmokPhaze101           | October & November 2022
| :question:         | Disk write test                             |                        |
| :question:         | Dedicated REU test                          |                        |
| :question:         | GEOS REU + disk write test                  |                        |

### C64 Emulator Test Suite V2.15

Tested with 6526 CIA

| Status             | Detail                                      | Done by                | Date              
|:-------------------|---------------------------------------------|:-----------------------|:--------------------------
| :white_check_mark: | Disc 1: Complete                            | sy2002                 | 11/19/22
| :white_check_mark: | Disc 2: From start to and incl. "Trap16"    | sy2002                 | 11/19/22
| :x:                | Disc 2: "Trap17"                            | sy2002                 | 11/19/22
| :white_check_mark: | Disc 2: "Branchwrap" to  "MMU"              | sy2002                 | 11/19/22
| :x:                | Disc 2: "CPUPort"                           | sy2002                 | 11/19/22
| :white_check_mark: | Disc 2: "CPUTiming" to  "Cntdef"            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA1TA"                            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA1TB"                            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA2TA"                            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA2TA"                            | sy2002                 | 11/19/22
| :x:                | Disc 2: "CIA2TB"                            | sy2002                 | 11/19/22
