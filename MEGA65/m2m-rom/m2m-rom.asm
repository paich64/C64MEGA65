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

; Only include the Shell, if you want to use the pre-build core automation
; and user experience. If you build your own, then remove this include and
; also remove the include "shell_vars.asm" in the variables section below.
;#include "../../M2M/rom/shell.asm"

; ----------------------------------------------------------------------------
; Firmware: Main Code
; ----------------------------------------------------------------------------

;                ; Run the shell: This is where you could put your own system
;                ; instead of the shell
;START_FIRMWARE  RBRA    START_SHELL, 1

START_FIRMWARE  MOVE    STR_TITLE, R8           ; output welcome message
                SYSCALL(puts, 1)

                ; Mount SD card
                MOVE    HANDLE_DEV, R8          ; device handle
                MOVE    1, R9                   ; partition #1 hardcoded
                SYSCALL(f32_mnt_sd, 1)
                CMP     0, R9                   ; R9=error code; 0=OK
                RBRA    MOUNT_OK, Z
                MOVE    STR_ERR_SD, R8
                RBRA    ERROR_END, 1

                ; Ask for filename and let the user input the filename
MOUNT_OK        MOVE    STR_FINPUT, R8
                SYSCALL(puts, 1)
                MOVE    FINPUT_BUF, R8
                MOVE    256, R9
                SYSCALL(gets_s, 1)
                SYSCALL(crlf, 1)

                ; Open file
                MOVE    HANDLE_DEV, R8
                MOVE    HANDLE_FILE, R9
                MOVE    FINPUT_BUF, R10
                XOR     R11, R11
                SYSCALL(f32_fopen, 1)
                CMP     0, R10                  ; R10=error code; 0=OK
                RBRA    FOPEN_OK, Z
                MOVE    STR_ERR_FNF, R8
                RBRA    ERROR_END, 1

                ; Read C64 two byte PRG file header, which is the start
                ; address of the program in little-endian
FOPEN_OK        MOVE    HANDLE_FILE, R8
                SYSCALL(f32_fread, 1)
                RSUB    FREAD_CHK, 1
                MOVE    R9, R0                  ; low byte of prg start addr
                SYSCALL(f32_fread, 1)
                RSUB    FREAD_CHK, 1
                AND     0xFFFD, SR              ; clear X flag
                SHL     8, R9                   ; high byte of prg start addr
                OR      R9, R0                   
                MOVE    STR_STARTADDR, R8
                SYSCALL(puts, 1)
                MOVE    R0, R8
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)

                ; Calculate 4k window and offset for QNICE RAM access
                MOVE    R0, R8
                MOVE    4096, R9
                SYSCALL(divu, 1)                ; R10=R8/R9; R11=R8%R9
                MOVE    R10, R1                 ; R1=window
                MOVE    R11, R2                 ; R2=start address in window
                ADD     M2M$RAMROM_DATA, R2
                MOVE    M2M$RAMROM_DATA, R3     ; R3=end of 4k page reached
                ADD     0x1000, R3

                ; Load file
                MOVE    M2M$RAMROM_DEV, R8      ; map C64 RAM to 0x7000
                MOVE    0x0100, @R8             ; 0x0100 = C64 RAM device hdl
FREAD_NEXTWIN   MOVE    M2M$RAMROM_4KWIN, R8    ; set 4k window
                MOVE    R1, @R8

FREAD_NEXTBYTE  MOVE    HANDLE_FILE, R8         ; read next byte to R9
                SYSCALL(f32_fread, 1)
                CMP     FAT32$EOF, R10
                RBRA    FREAD_EOF, Z
                RSUB    FREAD_CHK, 1

                MOVE    R9, @R2++               ; write byte to C64 RAM

                CMP     R3, R2                  ; end of 4k page reached?
                RBRA    FREAD_NEXTBYTE, !Z      ; no: read next byte
                ADD     1, R1                   ; inc. window counter
                MOVE    M2M$RAMROM_DATA, R2     ; start at beginning of window
                RBRA    FREAD_NEXTWIN, 1        ; set next window

                ; Print success message and end program
FREAD_EOF       MOVE    STR_LOAD_OK, R8
                SYSCALL(puts, 1)
                SYSCALL(exit, 1)

; Check, if reading the last byte went OK, otherwise end the program
FREAD_CHK       CMP     0, R10
                RBRA    _FREAD_CHK_OK, 1    
                MOVE    STR_ERR_LOAD, R8
                RBRA    ERROR_END, 1
_FREAD_CHK_OK   RET    


; Output error message in R8 and end program
ERROR_END       SYSCALL(puts, 1)
                SYSCALL(exit, 1)

; ----------------------------------------------------------------------------
; Strings
; ----------------------------------------------------------------------------

STR_TITLE       .ASCII_W "\nC64 for MEGA65 PRG file loader\n"
STR_FINPUT      .ASCII_W "Enter PRG filename: "
STR_STARTADDR   .ASCII_W "Start address of PRG: "
STR_LOAD_OK     .ASCII_W "OK: Loading successful."

STR_ERR_SD      .ASCII_W "ERROR: Cannot mount SD card.\n"
STR_ERR_FNF     .ASCII_W "ERROR: File not found.\n"
STR_ERR_LOAD    .ASCII_W "ERROR: Cannot load file.\n"

; ----------------------------------------------------------------------------
; Variables: Need to be located in RAM
; ----------------------------------------------------------------------------

#ifdef RELEASE
                .ORG    0x8000                  ; RAM starts at 0x8000
#endif

HANDLE_DEV      .BLOCK  FAT32$DEV_STRUCT_SIZE
HANDLE_FILE     .BLOCK  FAT32$FDH_STRUCT_SIZE
FINPUT_BUF      .BLOCK  256

; M2M shell variables (only include, if you included "shell.asm" above)
;#include "../../M2M/rom/shell_vars.asm"

; ----------------------------------------------------------------------------
; Heap and Stack: Need to be located in RAM after the variables
; ----------------------------------------------------------------------------

; TODO TODO TODO COMPLETELY REDO THIS AS THIS IS COPY/PASTE FROM gbc4mega65

; in DEVELOPMENT mode: 6k of heap, so that we are not colliding with
; MEM_CARTRIDGE_WIN at 0xB000
#ifndef RELEASE

; heap for storing the sorted structure of the current directory entries
; this needs to be the last variable before the monitor variables as it is
; only defined as "BLOCK 1" to avoid a large amount of null-values in
; the ROM file
HEAP_SIZE       .EQU 6144
HEAP            .BLOCK 1

; in RELEASE mode: 11k of heap which leads to a better user experience when
; it comes to folders with a lot of files
#else

HEAP_SIZE       .EQU 11264
HEAP            .BLOCK 1

; TODO TODO TODO
; THIS IS STILL THE gbc4MEGA65 comment: Completely redo
; 
; The monitor variables use 20 words, round to 32 for being safe and subtract
; it from B000 because this is at the moment the highest address that we
; can use as RAM: 0xAFE0
; The stack starts at 0xAFE0 (search var VAR$STACK_START in osm_rom.lis to
; calculate the address). To see, if there is enough room for the stack
; given the HEAP_SIZE do this calculation: Add 11.264 words to HEAP which
; is currently 0x8157 and subtract the result from 0xAFE0. This yields
; currently a stack size of 649 words, which is sufficient for this program.

                .ORG    0xAFE0                  ; TODO: automate calculation
#endif

STACK_SIZE      .EQU    649

#include "../../M2M/rom/main_vars.asm"
