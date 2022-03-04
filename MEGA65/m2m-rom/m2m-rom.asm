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

C64_RAM         .EQU    0x0100  ; RAM of the Commodore 64
C64_IEC         .EQU    0x0101  ; IEC bridge
C64_MOUNTBUF    .EQU    0x0102  ; 256kB buffer to hold mounted disks

C64_IEC_WIN_CAD .EQU    0x0000  ; control and data registers
C64_IEC_WIN_DRV .EQU    0x0001  ; drive 0, next window = drive 1, ...

C64_IEC_MOUNT   .EQU    0x7000  ; image mounted, lowest bit = drive 0
C64_IEC_RO      .EQU    0x7001  ; read-only for currently mounted drive
C64_IEC_SIZE_L  .EQU    0x7002  ; image file size, low word
C64_IEC_SIZE_H  .EQU    0x7003  ; image file size, high word
C64_IEC_B_ADDR  .EQU    0x7004  ; drive buffer: address
C64_IEC_B_DOUT  .EQU    0x7005  ; drive buffer: data out (to drive)
C64_IEC_B_WREN  .EQU    0x7006  ; drive buffer: write enable (also needs ack)
C64_IEC_VDNUM   .EQU    0x7007  ; number of virtual drives
C64_IEC_BLKSZ   .EQU    0x7008  ; block size for LBA in bytes

C64_IEC_LBA_L   .EQU    0x7000  ; SD LBA low word
C64_IEC_LBA_H   .EQU    0x7001  ; SD LBA high word
C64_IEC_BLKCNT  .EQU    0x7002  ; SD block count
C64_IEC_BYTES_L .EQU    0x7003  ; SD block address in bytes: low word
C64_IEC_BYTES_H .EQU    0x7004  ; SD block address in bytes: high word
C64_IEC_SIZEB   .EQU    0x7005  ; SD block data amount in bytes
C64_IEC_RD      .EQU    0x7006  ; SD read request
C64_IEC_WR      .EQU    0x7007  ; SD write request
C64_IEC_ACK     .EQU    0x7008  ; SD acknowledge
C64_IEC_B_DIN   .EQU    0x7009  ; drive buffer: data in (from drive)

; We currently only support D64 images that are exactly 174.848 bytes in
; size, which is the standard format. 174848 decimal = 0x0002AB00 hex
D64_STDSIZE_L   .EQU    0xAB00
D64_STDSIZE_H   .EQU    0x0002

START_FIRMWARE  MOVE    STR_START, R8
                SYSCALL(puts, 1)

;                MOVE    20, R0
;_WAIT           RSUB    WAIT1SEC, 1
;                SUB     1, R0
;                RBRA    _WAIT, !Z

                MOVE    M2M$RAMROM_DEV, R8
                MOVE    C64_IEC, @R8

                ; output basic system data
                MOVE    M2M$RAMROM_4KWIN, R8
                MOVE    C64_IEC_WIN_CAD, @R8
                MOVE    STR_DRIVES, R8
                SYSCALL(puts, 1)
                MOVE    C64_IEC_VDNUM, R8
                MOVE    @R8, R8
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)
                MOVE    STR_BLKSZ, R8
                SYSCALL(puts, 1)
                MOVE    C64_IEC_BLKSZ, R8
                MOVE    @R8, R8
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)

                ; check for sd_rd_i for drive 0 to be 0
                MOVE    STR_RD_0, R8
                SYSCALL(puts, 1)
                MOVE    M2M$RAMROM_4KWIN, R8
                MOVE    C64_IEC_WIN_DRV, @R8
                MOVE    C64_IEC_RD, R8
                CMP     0, @R8
                RBRA    _RD_0_OK, Z
                MOVE    STR_ERROR, R8
                SYSCALL(puts, 1)
                SYSCALL(exit, 1)

_RD_0_OK        MOVE    STR_OK, R8
                SYSCALL(puts, 1)

                ; trigger mount signal
                MOVE    STR_MOUNT, R8
                SYSCALL(puts, 1)

                MOVE    M2M$RAMROM_4KWIN, R8    ; control and data registers
                MOVE    C64_IEC_WIN_CAD, @R8

                MOVE    C64_IEC_RO, R8          ; set readonly
                MOVE    1, @R8

                MOVE    C64_IEC_SIZE_L, R8      ; set D64 size to standard
                MOVE    D64_STDSIZE_L, @R8
                MOVE    C64_IEC_SIZE_H, R8
                MOVE    D64_STDSIZE_H, @R8

                MOVE    C64_IEC_MOUNT, R8       ; signal mount
                MOVE    1, @R8
                MOVE    0, @R8

                MOVE    C64_IEC_RO, R8          ; readonly and size back to 0
                MOVE    0, @R8
                MOVE    C64_IEC_SIZE_L, R8
                MOVE    0, @R8
                MOVE    C64_IEC_SIZE_H, R8
                MOVE    0, @R8  

                MOVE    STR_OK, R8
                SYSCALL(puts, 1)

                ; check for sd_rd_i for drive 0 to be 1
                MOVE    STR_RD_1, R8
                SYSCALL(puts, 1)
                MOVE    M2M$RAMROM_4KWIN, R8
                MOVE    C64_IEC_WIN_DRV, @R8
                MOVE    C64_IEC_RD, R8
                CMP     1, @R8
                RBRA    _RD_1_OK, Z
                MOVE    STR_ERROR, R8
                SYSCALL(puts, 1)
                SYSCALL(exit, 1)

_RD_1_OK        MOVE    STR_OK, R8
                SYSCALL(puts, 1)

                ; read lba, to-be-read blocks, addr in bytes and size in bytes
                MOVE    STR_LBA, R8
                SYSCALL(puts, 1)
                MOVE    C64_IEC_LBA_H, R8
                MOVE    @R8, R8
                SYSCALL(puthex, 1)
                MOVE    C64_IEC_LBA_L, R8
                MOVE    @R8 R8
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)
                MOVE    STR_BLOCKS, R8
                SYSCALL(puts, 1)
                MOVE    C64_IEC_BLKCNT, R8
                MOVE    @R8, R8
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)
                MOVE    STR_B_ADDR, R8
                SYSCALL(puts, 1)
                MOVE    C64_IEC_BYTES_H, R8
                MOVE    @R8, R8
                SYSCALL(puthex, 1)
                MOVE    C64_IEC_BYTES_L, R8
                MOVE    @R8, R8
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)
                MOVE    STR_B_SIZE, R8
                SYSCALL(puts, 1)
                MOVE    C64_IEC_SIZEB, R8
                MOVE    @R8, R8
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)

                SYSCALL(exit, 1)

STR_START       .ASCII_P "                                                  "
                .ASCII_W "\nC64 for MEGA65: IEC development testbed\n"
STR_DRIVES      .ASCII_W "Number of drives: "
STR_BLKSZ       .ASCII_W "LBA block size: "
STR_OK          .ASCII_W "OK\n"
STR_ERROR       .ASCII_W "ERROR\n"
STR_RD_0        .ASCII_W "Checking for sd_rd_i for drive 0 to be 0: "
STR_RD_1        .ASCII_W "Checking for sd_rd_i for drive 0 to be 1: "
STR_MOUNT       .ASCII_W "Triggering mount signal... "
STR_LBA         .ASCII_W "LBA: "
STR_BLOCKS      .ASCII_W "Blocks: "
STR_B_ADDR      .ASCII_W "Address (bytes): "
STR_B_SIZE      .ASCII_W "Size (bytes): "

STR_D64         .ASCII_W "sidtest.d64"

; ----------------------------------------------------------------------------
; PRG LOADER
; ----------------------------------------------------------------------------

                MOVE    STR_TITLE, R8           ; output welcome message
                SYSCALL(puts, 1)

#ifdef RELEASE
                ; Stabilize SD Card
                RSUB    WAIT1SEC, 1
                RSUB    WAIT1SEC, 1
#endif

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
                MOVE    C64_RAM, @R8            ; C64 RAM device handle
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

; Waits about 1 second
WAIT1SEC        INCRB
                MOVE    0x0060, R0
_W1S_L1         MOVE    0xFFFF, R1
_W1S_L2         SUB     1, R1
                RBRA    _W1S_L2, !Z
                SUB     1, R0
                RBRA    _W1S_L1, !Z
                DECRB
                RET    

; ----------------------------------------------------------------------------
; Strings
; ----------------------------------------------------------------------------

STR_TITLE       .ASCII_P "                                                   "
                .ASCII_W "\nC64 for MEGA65 PRG file loader\n"
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
