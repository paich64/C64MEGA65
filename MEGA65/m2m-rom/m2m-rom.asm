; ****************************************************************************
; Commodore 64 for MEGA65 (C64MEGA65) QNICE ROM
;
; Main program that is used to build m2m-rom.rom by make-rom.sh.
; The ROM is loaded by qnice.vhd
;
; The execution starts at the label START_FIRMWARE.
;
; done by sy2002 in 2022 and licensed under GPL v3
; ****************************************************************************

; If the define RELEASE is defined, then the ROM will be a self-contained and
; self-starting ROM that includes the Monitor (QNICE "operating system") and
; jumps to START_FIRMWARE. In this case it is assumed, that the firmware is
; located in ROM and the variables are located in RAM.
;
; If RELEASE is not defined, then it is assumed that we are in the develop and
; debug mode so that the firmware runs in RAM and can be changed/loaded using
; the standard QNICE Monitor mechanisms such as "M/L" or QTransfer.

#undef RELEASE

; ----------------------------------------------------------------------------
; Firmware: M2M system
; ----------------------------------------------------------------------------

; main.asm is the mandatory, so always include it
; It jumps to START_FIRMWARE (see below) after the QNICE "operating system"
; called "Monitor" has been included and initialized
#include "../../M2M/rom/main.asm"

; The C64 core uses the Shell of MiSTer2MEGA65
#include "../../M2M/rom/shell.asm"

; ----------------------------------------------------------------------------
; Firmware: Main Code
; ----------------------------------------------------------------------------

START_FIRMWARE  RBRA    START_SHELL, 1

; ----------------------------------------------------------------------------
; Core specific callback functions: File browsing and disk image mounting
; ----------------------------------------------------------------------------

; FILTER_FILES callback function:
;
; Called by the file- and directory browser. Used to make sure that the 
; browser is only showing valid files and directories.
;
; Input:
;   R8: Name of the file in capital letters
;   R9: 0=file, 1=directory
; Output:
;   R8: 0=do not filter file, i.e. show file
FILTER_FILES    INCRB
                MOVE    R9, R0
                
                CMP     1, R9                   ; do not filter directories
                RBRA    _FFILES_RET_0, Z

                ; does this file have the ".D64" file extension?
                MOVE    C64_IMGFILE_D64, R9
                RSUB    M2M$CHK_EXT, 1
                RBRA    _FFILES_RET_0, C        ; yes: do not filter it

                MOVE    1, R8                   ; no: filter it
                RBRA    _FFILES_RET, 1

_FFILES_RET_0   XOR     R8, R8

_FFILES_RET     MOVE    R0, R9
                DECRB
                RET

; PREP_LOAD_IMAGE callback function:
;
; Some images need to be parsed, for example to extract configuration data or
; to move the file read pointer to the start position of the actual data.
; Sanity checks ("is this a valid file") can also be implemented here.
; Last but not least: The mount system supports the concept of a 2-bit
; "image type". In case this is used at the core of your choice, make sure
; you return the correct image type.
;
; Input:
;   R8: File handle: You are allowed to modify the read pointer of the handle
; Output:
;   R8: 0=OK, error code otherwise
;   R9: image type if R8=0, otherwise 0 or optional ptr to  error msg string
PREP_LOAD_IMAGE INCRB

                MOVE    R8, R0
                MOVE    R0, R1

                ADD     FAT32$FDH_SIZE_LO, R0
                MOVE    @R0, R0                 ; low word of file size
                ADD     FAT32$FDH_SIZE_HI, R1
                MOVE    @R1, R1                 ; high word of file size

                CMP     D64_STDSIZE_L, R0       ; check filesize
                RBRA    _PREP_LI_ERR, !Z
                CMP     D64_STDSIZE_H, R1
                RBRA    _PREP_LI_ERR, !Z

                ; filesize correct
                XOR     R8, R8                  ; no errors
                MOVE    C64_IMGTYPE_D64, R9     ; image type hardcoded to D64
                RBRA    _PREP_LI_RET, 1

                ; filesize wrong
_PREP_LI_ERR    MOVE    1, R8                   ; R8: error code
                MOVE    WRN_WRONG_D64, R9       ; R9: error message

_PREP_LI_RET    DECRB
                RET

; ----------------------------------------------------------------------------
; Core specific constants and strings
; ----------------------------------------------------------------------------

; Disk image file extensions (need to be upper case)
C64_IMGFILE_D64  .ASCII_W ".D64"
C64_IMGFILE_G64  .ASCII_W ".G64"
C64_IMGFILE_D81  .ASCII_W ".D81"

; C64 disk image types
C64_IMGTYPE_D64 .EQU    0x0000  ; 1541 emulated GCR: D64
C64_IMGTYPE_G64 .EQU    0x0001  ; 1541 real GCR mode: G64, D64
C64_IMGTYPE_D81 .EQU    0x0002  ; 1581: D81

; We currently only support D64 images that are exactly 174.848 bytes in
; size, which is the standard format. 174848 decimal = 0x0002AB00 hex
D64_STDSIZE_L   .EQU    0xAB00
D64_STDSIZE_H   .EQU    0x0002

; ----------------------------------------------------------------------------
; Variables: Need to be located in RAM
; ----------------------------------------------------------------------------

#ifdef RELEASE
                .ORG    0x8000                  ; RAM starts at 0x8000
#endif

FINPUT_BUF      .BLOCK  256

; M2M shell variables
#include "../../M2M/rom/shell_vars.asm"

; ----------------------------------------------------------------------------
; Heap and Stack: Need to be located in RAM after the variables
; ----------------------------------------------------------------------------

; The On-Screen-Menu uses the heap for several data structures. This heap
; is located before the main system heap in memory.
; You need to deduct MENU_HEAP_SIZE from the actual heap size below.
; Example: If your HEAP_SIZE would be 29696, then you write 29696-1024=28672
; instead, but when doing the sanity check calculations, you use 29696
MENU_HEAP_SIZE  .EQU 1024

#ifndef RELEASE

; heap for storing the sorted structure of the current directory entries
; this needs to be the last variable before the monitor variables as it is
; only defined as "BLOCK 1" to avoid a large amount of null-values in
; the ROM file
HEAP_SIZE       .EQU 6144                       ; 7168 - 1024 = 6144
HEAP            .BLOCK 1

; in RELEASE mode: 16k of heap which leads to a better user experience when
; it comes to folders with a lot of files
#else

HEAP_SIZE       .EQU 28672                      ; 29696 - 1024 = 28672
HEAP            .BLOCK 1
 
; The monitor variables use 20 words, round to 32 for being safe and subtract
; it from FF00 because this is at the moment the highest address that we
; can use as RAM: 0xFEE0
; The stack starts at 0xFEE0 (search var VAR$STACK_START in osm_rom.lis to
; calculate the address). To see, if there is enough room for the stack
; given the HEAP_SIZE do this calculation: Add 29696 words to HEAP which
; is currently 0xXXXX and subtract the result from 0xFEE0. This yields
; currently a stack size of more than 1.5k words, which is sufficient
; for this program.

                .ORG    0xFEE0                  ; TODO: automate calculation
#endif

; STACK_SIZE: Size of the global stack and should be a minimum of 768 words
; after you subtract B_STACK_SIZE.
; B_STACK_SIZE: Size of local stack of the the file- and directory browser. It
; should also have a minimum size of 768 words. If you are not using the
; Shell, then B_STACK_SIZE is not used.
STACK_SIZE      .EQU    1536
B_STACK_SIZE    .EQU    768

#include "../../M2M/rom/main_vars.asm"
