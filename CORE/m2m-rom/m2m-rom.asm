; ****************************************************************************
; Commodore 64 for MEGA65 (C64MEGA65) QNICE ROM
;
; Main program that is used to build m2m-rom.rom by make-rom.sh.
; The ROM is loaded by qnice.vhd
;
; The execution starts at the label START_FIRMWARE.
;
; done by sy2002 in 2023 and licensed under GPL v3
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
; Core specific callback functions: Submenus
; ----------------------------------------------------------------------------

; SUBMENU_SUMMARY callback function:
;
; Called when displaying the main menu for every %s that is found in the
; "headline" / starting point of any submenu in config.vhd: You are able to
; change the standard semantics when it comes to summarizing the status of the
; very submenu that is meant by the "headline" / starting point.
;
; Input:
;   R8: pointer to the string that includes the "%s"
;   R9: pointer to the menu item within the M2M$CFG_OPTM_GROUPS structure
;  R10: end-of-menu-marker: if R9 == R10: we reached end of the menu structure
; Output:
;   R8: 0, if no custom SUBMENU_SUMMARY, else:
;       string pointer to completely new headline (do not modify/re-use R8)
;   R9, R10: unchanged

SUBMENU_SUMMARY XOR     R8, R8                  ; R8 = 0 = no custom string
                RET

; ----------------------------------------------------------------------------
; Core specific callback functions: File browsing and disk image mounting
; ----------------------------------------------------------------------------

; FILTER_FILES callback function:
;
; Called by the file- and directory browser. Used to make sure that the 
; browser is only showing valid files and directories.
;
;
; Input:
;   R8: Name of the file in capital letters
;   R9: 0=file, 1=directory
;  R10: Context (CTX_* constants in sysdef.asm)
;  R11: Menu group id (see config.vhd) of the menu item that is responsible
;       for triggering FILTER_FILES
; Output:
;   R8: 0=do not filter file, i.e. show file
FILTER_FILES    INCRB
                MOVE    R9, R0
        
                CMP     1, R9                   ; do not filter directories
                RBRA    _FFILES_RET_0, Z

                ; Context: Mount virtual drive
                CMP     CTX_MOUNT_DISKIMG, R10
                RBRA    _FFILES_1, !Z

                ; does this file have the ".D64" file extension?
                MOVE    C64_IMGFILE_D64, R9
                RSUB    M2M$CHK_EXT, 1
                RBRA    _FFILES_RET_0, C        ; yes: do not filter it

_FFILES_DOFLT   MOVE    1, R8                   ; no: filter it
                RBRA    _FFILES_RET, 1

                ; Context: Load cartridge ROM file
_FFILES_1       CMP     CTX_LOAD_ROM, R10
                RBRA    _FFILES_RET_0, !Z       ; do not filter in other CTXs

                CMP     OPTM_G_LOAD_PRG, R11    ; menu item "PRG:<Load>"
                RBRA    _FFILES_2, !Z
                MOVE    C64_PRGFILE, R9
                RBRA    _FFILES_3, 1
_FFILES_2       CMP     OPTM_G_MOUNT_CRT, R11   ; menu item "CRT:<Load>"
                RBRA    _FFILES_RET_0, !Z
                MOVE    C64_CRTFILE, R9

                ; does this file have the right file extension?
_FFILES_3       RSUB    M2M$CHK_EXT, 1
                RBRA    _FFILES_DOFLT, !C       ; no: filter it

_FFILES_RET_0   XOR     R8, R8                  ; do not filter

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
;   R9: Context (CTX_* constants in sysdef.asm)
;  R10: Menu group id (see config.vhd) of the menu item that is responsible
;       for triggering PREP_LOAD_IMAGE
; Output:
;   R8: 0=OK, error code otherwise
;   R9: image type if R8=0, otherwise 0 or optional ptr to error msg string
PREP_LOAD_IMAGE INCRB

                ; Context CRT/ROM loading: Do not check the file-size
                CMP     CTX_LOAD_ROM, R9
                RBRA    _PREP_LI_START, !Z
                XOR     R8, R8
                XOR     R9, R9
                RBRA    _PREP_LI_RET, 1

                ; Context is disk image loading: We check for valid disk
                ; image sizes as defined in D64_STDSIZE_L and D64_STDSIZE_H
_PREP_LI_START  MOVE    R8, R0
                MOVE    R0, R1

                ADD     FAT32$FDH_SIZE_LO, R0
                MOVE    @R0, R0                 ; R0: low word of file size
                ADD     FAT32$FDH_SIZE_HI, R1
                MOVE    @R1, R1                 ; R1: high word of file size

                ; check if the D64 filesize equals one of the valid variants
                MOVE    D64_VARIANT_CNT, R2     ; R2: amount of valid variants
                MOVE    D64_STDSIZE_L, R3       ; R3: table of valid lo words
                MOVE    D64_STDSIZE_H, R4       ; R4: table of valid hi words

_PREP_LI_CMP    MOVE    @R3++, R5               ; R5: valid lo word
                MOVE    @R4++, R6               ; R6: valid hi word

                CMP     R5, R0                  ; lo word equals table entry?
                RBRA    _PREP_LI_NEXT, !Z       ; no: check next variant
                CMP     R6, R1                  ; hi word equals table entry?
                RBRA    _PREP_LI_OK, Z          ; yes: correct filesize

_PREP_LI_NEXT   SUB     1, R2                   ; next variant
                RBRA    _PREP_LI_CMP, !Z

                ; filesize wrong
                MOVE    1, R8                   ; R8: error code
                MOVE    WRN_WRONG_D64, R9       ; R9: error message
                RBRA    _PREP_LI_RET, 1

                ; filesize correct
_PREP_LI_OK     XOR     R8, R8                  ; no errors
                MOVE    C64_IMGTYPE_D64, R9     ; image type hardcoded to D64

_PREP_LI_RET    DECRB
                RET

; ----------------------------------------------------------------------------
; Core specific callback functions: Custom messages
; ----------------------------------------------------------------------------

; CUSTOM_MSG callback function:
;
; Called in various situations where the Shell needs to output a message
; to the end user. The situations and contexts are described in sysdef.asm
;
; Input:
;   R8: Situation (CMSG_* constants in sysdef.asm)
;   R9: Context   (CTX_* constants in sysdef.asm)
; Output:
;   R8: 0=no custom message available, otherwise pointer to string

CUSTOM_MSG      INCRB
                MOVE    R8, R0
                XOR     R8, R8                  ; no custom message

                CMP     CMSG_BROWSENOTHING, R0  ; "no D64" situation?
                RBRA    _CUSTOM_MSG_RET, !Z     ; no: default custom message
                CMP     CTX_MOUNT_DISKIMG, R9   ; trying to mount a disk?
                RBRA    _CUSTOM_MSG_RET, !Z     ; no: default custom message
                MOVE    WRN_NO_D64, R8          ; yes: custom message

_CUSTOM_MSG_RET DECRB
                RET

; ----------------------------------------------------------------------------
; Core specific constants and strings
; ----------------------------------------------------------------------------

; Warning: At this point we are only supporting standard D64 files
WRN_WRONG_D64   .ASCII_P "\n\nD64 file size must be exactly 174848 bytes\n"
                .ASCII_P "(35 tracks) or 196608 bytes (40 tracks)."
                .ASCII_W "\n\nPress SPACE to continue.\n"

; Warning: Nothing to browse
WRN_NO_D64      .ASCII_P "This core uses D64 disk images.\n\n"
                .ASCII_P "Please copy at least one D64 file\n"
                .ASCII_P "to any sub-directory or to the root\n"
                .ASCII_P "directory of this SD card.\n\n"
                .ASCII_P "If you use a folder called /c64, then\n"
                .ASCII_P "the file browser will always start there.\n\n"
                .ASCII_P "You can use long file names and you can\n"
                .ASCII_P "also use nested sub-directories to nicely\n"
                .ASCII_P "order your collection of D64 files.\n\n"
                .ASCII_P "Nothing to browse.\n\n"
                .ASCII_W "Press Space to continue."

; C64 specific file extensions (need to be upper case)
C64_IMGFILE_D64 .ASCII_W ".D64"
C64_IMGFILE_G64 .ASCII_W ".G64"
C64_IMGFILE_D81 .ASCII_W ".D81"
C64_CRTFILE     .ASCII_W ".CRT"
C64_PRGFILE     .ASCII_W ".PRG"

; C64 disk image types
C64_IMGTYPE_D64 .EQU    0x0000  ; 1541 emulated GCR: D64
C64_IMGTYPE_G64 .EQU    0x0001  ; 1541 real GCR mode: G64, D64
C64_IMGTYPE_D81 .EQU    0x0002  ; 1581: D81

; We currently only support D64 images with 35 tracks (filesize 174,848 bytes)
; or 40 tracks (filesize 196,608 bytes).
; 174848 decimal = 0x0002AB00 hex
; 196608 decimal = 0x00030000 hex
D64_VARIANT_CNT .EQU    2
D64_STDSIZE_L   .DW     0xAB00, 0x0000
D64_STDSIZE_H   .DW     0x0002, 0x0003

; Menu group/item ids (see config.vhd)
OPTM_G_LOAD_PRG  .EQU    3
OPTM_G_MOUNT_CRT .EQU    5

; ----------------------------------------------------------------------------
; Variables: Need to be located in RAM
; ----------------------------------------------------------------------------

#ifdef RELEASE
                .ORG    0x8000                  ; RAM starts at 0x8000
#endif

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
MENU_HEAP_SIZE  .EQU 1536

#ifndef RELEASE

; heap for storing the sorted structure of the current directory entries
; this needs to be the last variable before the monitor variables as it is
; only defined as "BLOCK 1" to avoid a large amount of null-values in
; the ROM file
HEAP_SIZE       .EQU 5632                       ; 7168 - 1536 = 5632
HEAP            .BLOCK 1

; in RELEASE mode: 28k of heap which leads to a better user experience when
; it comes to folders with a lot of files
#else

HEAP_SIZE       .EQU 28160                      ; 29696 - 1536 = 28160
HEAP            .BLOCK 1
 
; The monitor variables use 22 words, round to 32 for being safe and subtract
; it from FF00 because this is at the moment the highest address that we
; can use as RAM: 0xFEE0
; The stack starts at 0xFEE0 (search var VAR$STACK_START in osm_rom.lis to
; calculate the address). To see, if there is enough room for the stack
; given the HEAP_SIZE do this calculation: Add 29696 words to HEAP which
; is currently 0x81C7 and subtract the result from 0xFEE0. This yields
; currently a stack size of 2329, which is more than 1.5k words, and therefore
; sufficient for this program.

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
