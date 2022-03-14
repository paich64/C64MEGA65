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

C64_RAM         .EQU    0x0100  ; RAM of the Commodore 64
C64_IEC         .EQU    0x0101  ; IEC bridge
C64_MOUNTBUF    .EQU    0x0102  ; 171kB buffer to hold mounted disks

C64_IEC_WIN_CAD .EQU    0x0000  ; control and data registers
C64_IEC_WIN_DRV .EQU    0x0001  ; drive 0, next window = drive 1, ...

C64_IEC_MOUNT   .EQU    0x7000  ; image mounted, lowest bit = drive 0
C64_IEC_RO      .EQU    0x7001  ; read-only for currently mounted drive
C64_IEC_SIZE_L  .EQU    0x7002  ; image file size, low word
C64_IEC_SIZE_H  .EQU    0x7003  ; image file size, high word
C64_IEC_TYPE    .EQU    0x7004  ; image file type (see C64_IMGTYPE_* below)
C64_IEC_B_ADDR  .EQU    0x7005  ; drive buffer: address
C64_IEC_B_DOUT  .EQU    0x7006  ; drive buffer: data out (to drive)
C64_IEC_B_WREN  .EQU    0x7007  ; drive buffer: write enable (also needs ack)
C64_IEC_VDNUM   .EQU    0x7008  ; number of virtual drives
C64_IEC_BLKSZ   .EQU    0x7009  ; block size for LBA in bytes

C64_IMGTYPE_D64 .EQU    0x0000  ; 1541 emulated GCR: D64
C64_IMGTYPE_G64 .EQU    0x0001  ; 1541 real GCR mode: G64, D64
C64_IMGTYPE_D81 .EQU    0x0002  ; 1581: D81

C64_IEC_LBA_L   .EQU    0x7000  ; SD LBA low word
C64_IEC_LBA_H   .EQU    0x7001  ; SD LBA high word
C64_IEC_BLKCNT  .EQU    0x7002  ; SD block count
C64_IEC_BYTES_L .EQU    0x7003  ; SD block address in bytes: low word
C64_IEC_BYTES_H .EQU    0x7004  ; SD block address in bytes: high word
C64_IEC_SIZEB   .EQU    0x7005  ; SD block data amount in bytes
C64_IEC_4K_WIN  .EQU    0x7006  ; SD block address in 4k win logic: window
C64_IEC_4K_OFFS .EQU    0x7007  ; SD block address in 4k win logic: offset
C64_IEC_RD      .EQU    0x7008  ; SD read request
C64_IEC_WR      .EQU    0x7009  ; SD write request
C64_IEC_ACK     .EQU    0x700A  ; SD acknowledge
C64_IEC_B_DIN   .EQU    0x700B  ; drive buffer: data in (from drive)

; We currently only support D64 images that are exactly 174.848 bytes in
; size, which is the standard format. 174848 decimal = 0x0002AB00 hex
D64_STDSIZE_L   .EQU    0xAB00
D64_STDSIZE_H   .EQU    0x0002

START_FIRMWARE  MOVE    STR_START, R8
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
                RBRA    _MOUNT_OK, Z
                MOVE    STR_ERR_SD, R8
                RBRA    ERROR_END, 1

                ; Ask for filename and let the user input the filename
_MOUNT_OK       ;MOVE    STR_FINPUTD64, R8
                ;SYSCALL(puts, 1)
                ;MOVE    FINPUT_BUF, R8
                ;MOVE    256, R9
                ;SYSCALL(gets_s, 1)
                ;SYSCALL(crlf, 1)

                ; Open file
                MOVE    HANDLE_DEV, R8
                MOVE    HANDLE_FILE, R9
                ;MOVE    FINPUT_BUF, R10         ; user provided filename
                MOVE    TMP_DEBUG, R10          ; tmp/debug hardcoded D64
                MOVE    R10, R7                 ; remember for string output
                XOR     R11, R11
                SYSCALL(f32_fopen, 1)
                CMP     0, R10                  ; R10=error code; 0=OK
                RBRA    _FOPEN_OK, Z
                MOVE    STR_ERR_FNF, R8
                RBRA    ERROR_END, 1

                ; check filesize, i.e. "is this a standard D64?"
_FOPEN_OK       MOVE    HANDLE_FILE, R8
                MOVE    R8, R9
                ADD     FAT32$FDH_SIZE_LO, R8
                MOVE    @R8, R8                 ; file size low word
                ADD     FAT32$FDH_SIZE_HI , R9
                MOVE    @R9, R9                 ; file size high word
                CMP     R8, D64_STDSIZE_L
                RBRA    _WRONGSIZE, !Z
                CMP     R9, D64_STDSIZE_H
                RBRA    _LOAD_D64, Z
_WRONGSIZE      MOVE    STR_ERR_D64, R8
                RBRA    ERROR_END, 1 

                ; load D64 into buffer RAM
_LOAD_D64       MOVE    STR_LOADING, R8
                SYSCALL(puts, 1)
                MOVE    R7, R8
                SYSCALL(puts, 1)
                SYSCALL(crlf, 1)

                XOR     R1, R1                  ; R1=window: start from 0
                XOR     R2, R2                  ; R2=start address in window
                ADD     M2M$RAMROM_DATA, R2
                MOVE    M2M$RAMROM_DATA, R3     ; R3=end of 4k page reached
                ADD     0x1000, R3

                ; Load file
                MOVE    M2M$RAMROM_DEV, R8
                MOVE    C64_MOUNTBUF, @R8       ; mount buffer device handle
_FREAD_NEXTWIN  MOVE    M2M$RAMROM_4KWIN, R8    ; set 4k window
                MOVE    R1, @R8

_FREAD_NEXTBYTE MOVE    HANDLE_FILE, R8         ; read next byte to R9
                SYSCALL(f32_fread, 1)
                CMP     FAT32$EOF, R10
                RBRA    _FREAD_EOF, Z
                RSUB    FREAD_CHK, 1

                MOVE    R9, @R2++               ; write byte to mount buffer

                CMP     R3, R2                  ; end of 4k page reached?
                RBRA    _FREAD_NEXTBYTE, !Z     ; no: read next byte
                ADD     1, R1                   ; inc. window counter
                MOVE    M2M$RAMROM_DATA, R2     ; start at beginning of window
                RBRA    _FREAD_NEXTWIN, 1       ; set next window

_FREAD_EOF      MOVE    STR_D64_LD_OK, R8
                SYSCALL(puts, 1)

                ; ------------------------------------------------------------
                ; @TODO/TEMP Call Shell
                ; ------------------------------------------------------------

                RBRA    START_SHELL, 1

                ; ------------------------------------------------------------
                ; @TODO/TEMP Will be called from Shell indirectly via
                ; HANDLE_CORE_IO
                ; ------------------------------------------------------------

_RD_1           MOVE    C64_IEC_SIZEB, R8
                MOVE    @R8, R8
                MOVE    R8, R0                  ; R0=# bytes to be transmitted
                MOVE    C64_IEC_4K_WIN, R8
                MOVE    @R8, R8
                MOVE    R8, R1                  ; R1=start 4k win of transmis.
                MOVE    C64_IEC_4K_OFFS, R8
                MOVE    @R8, R8
                MOVE    R8, R2                  ; R2=start offs in 4k win

                ; transmit data to internal buffer of C1541
                MOVE    C64_IEC_ACK, R8         ; ackknowledge sd_rd_i
                MOVE    1, @R8

                MOVE    M2M$RAMROM_DEV, R3      ; R3=device selector
                MOVE    M2M$RAMROM_4KWIN, R4    ; R4=window selector
                MOVE    M2M$RAMROM_DATA, R5     ; R5=data window
                ADD     R2, R5                  ; start offset within window
                XOR     R6, R6                  ; R6=# transmitted bytes
                MOVE    M2M$RAMROM_DATA, R7     ; R7=end of window marker
                ADD     0x1000, R7

_SEND_LOOP      CMP     R6, R0                  ; transmission done?
                RBRA    _SEND_DONE, Z           ; yes

                MOVE    C64_MOUNTBUF, @R3       ; select mount buffer RAM
                MOVE    R1, @R4                 ; select window in RAM
                MOVE    @R5++, R8               ; R8=next byte from D64

                MOVE    C64_IEC, @R3            ; select IEC bridge
                MOVE    C64_IEC_WIN_CAD, @R4    ; select control & data regs
                MOVE    C64_IEC_B_ADDR, R9      ; write buffer: address
                MOVE    R6, @R9
                MOVE    C64_IEC_B_DOUT, R9      ; write buffer: data out
                MOVE    R8, @R9

                MOVE    C64_IEC_B_WREN, R9      ; strobe write enable
                MOVE    1, @R9
                MOVE    0, @R9

                ADD     1, R6                   ; next byte

                CMP     R5, R7                  ; window boundary reached?
                RBRA    _SEND_LOOP, !Z          ; no
                ADD     1, R1                   ; next window
                MOVE    M2M$RAMROM_DATA, R5     ; byte zero in next window
                RBRA    _SEND_LOOP, 1

_SEND_DONE      MOVE    C64_IEC_WIN_DRV, @R4    ; select drive 0
                MOVE    C64_IEC_ACK, R8         ; unassert ACK
                MOVE    0, @R8

                ; endless loop: next read request
                RBRA    _NEXT_WAIT, 1

; Unmount current disk image and let the user mount a new one
_UNMOUNT        MOVE    M2M$RAMROM_DEV, R8
                MOVE    C64_IEC, @R8
                MOVE    M2M$RAMROM_4KWIN, R8
                MOVE    C64_IEC_WIN_CAD, @R8
                MOVE    C64_IEC_MOUNT, R8
                MOVE    0, @R8                  ; currently hardcoded
                MOVE    STR_UNMOUNT, R8
                SYSCALL(puts, 1)
                RBRA    _MOUNT_OK, 1

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
; Firmware: Core specific IO handler (called by the Shell)
; ----------------------------------------------------------------------------

PREPARE_CORE_IO SYSCALL(enter, 1)

                ; Switch to IEC device
                MOVE    M2M$RAMROM_DEV, R8
                MOVE    C64_IEC, @R8

                ; check for sd_rd_i for drive 0 to be 0
                MOVE    M2M$RAMROM_4KWIN, R8
                MOVE    C64_IEC_WIN_DRV, @R8
                MOVE    C64_IEC_RD, R8
                CMP     0, @R8
                RBRA    _RD_0_OK, Z
                MOVE    STR_ERROR, R8
                SYSCALL(puts, 1)
                SYSCALL(exit, 1)

_RD_0_OK        ; trigger mount signal
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

                MOVE    C64_IEC_TYPE, R8        ; set "D64" image type
                MOVE    C64_IMGTYPE_D64, @R8 

                ; strobe the mount signal for drive 0 (bit 0 = drive 0)
                ; MiSTer expects a strobe and not a constant signal
                ; during the rising edge of the strobe, the following signals
                ; are latched by MiSTer: readonly, size and image type
                MOVE    C64_IEC_MOUNT, R8
                MOVE    1, @R8
                MOVE    0, @R8

                ; set registers for readonly, size and type back to 0;
                ; it seems that only "size" really *needs* to be set back
                ; to 0, but for being on the safe side, we set everything back
                MOVE    C64_IEC_RO, R8
                MOVE    0, @R8
                MOVE    C64_IEC_SIZE_L, R8
                MOVE    0, @R8
                MOVE    C64_IEC_SIZE_H, R8
                MOVE    0, @R8
                MOVE    C64_IEC_TYPE, R8
                MOVE    0, @R8

                MOVE    STR_OK, R8
                SYSCALL(puts, 1)
                MOVE    STR_MOUNT2, R8
                SYSCALL(puts, 1)

                SYSCALL(leave, 1)
                RET

HANDLE_CORE_IO  INCRB

                ; check, if sd_rd_i for drive 0 is 1 = drive needs data
_NEXT_WAIT      MOVE    M2M$RAMROM_DEV, R0      ; select IEC device
                MOVE    C64_IEC, @R0
                MOVE    M2M$RAMROM_4KWIN, R0
                MOVE    C64_IEC_WIN_DRV, @R0    ; select drive 0
                MOVE    C64_IEC_RD, R0

                ; @TODO/TEMP UNMOUNT mechanism
                MOVE    M2M$KEY_HELP, R1
                NOT     R1, R1
                MOVE    M2M$KEYBOARD, R2

_WAIT_RD_1      CMP     1, @R0
                RBRA    _RD_1, Z
                CMP     1, @R2
                RBRA    _UNMOUNT, Z

                DECRB
                RET

; ----------------------------------------------------------------------------
; Strings
; ----------------------------------------------------------------------------

STR_START       .ASCII_P "                                                  "
                .ASCII_P "\nC64 for MEGA65 done by MJoergen & sy2002 in 2022"
                .ASCII_W "\n\n"
STR_FINPUTD64   .ASCII_W "Enter D64 file name: "                
STR_OK          .ASCII_W "OK\n"
STR_ERROR       .ASCII_W "ERROR\n"
STR_ERR_D64     .ASCII_P "ERROR: For now, only standard D64 files with a "
                .ASCII_W "size of exactly 174,848 bytes are supported.\n"
STR_LOADING     .ASCII_W "Loading file: "
STR_D64_LD_OK   .ASCII_W "Loading OK\n"
STR_MOUNT       .ASCII_W "Mounting drive #8: "
STR_MOUNT2      .ASCII_P "\nPress the MEGA65 HELP key to unmount this disk "
                .ASCII_P "and to mount a new one. This also works for games "
                .ASCII_P "and demos that ask you to change the disk at some "
                .ASCII_W "point.\n\n"
STR_UNMOUNT     .ASCII_W "Unmounted drive #8\n\n"

STR_ERR_SD      .ASCII_W "ERROR: Cannot mount SD card.\n"
STR_ERR_FNF     .ASCII_W "ERROR: File not found.\n"
STR_ERR_LOAD    .ASCII_W "ERROR: Cannot load file.\n"

TMP_DEBUG       .ASCII_W "d64/sidtest.d64"

; ----------------------------------------------------------------------------
; Variables: Need to be located in RAM
; ----------------------------------------------------------------------------

#ifdef RELEASE
                .ORG    0x8000                  ; RAM starts at 0x8000
#endif

HANDLE_DEV      .BLOCK  FAT32$DEV_STRUCT_SIZE
HANDLE_FILE     .BLOCK  FAT32$FDH_STRUCT_SIZE
FINPUT_BUF      .BLOCK  256

; M2M shell variables
#include "../../M2M/rom/shell_vars.asm"

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
