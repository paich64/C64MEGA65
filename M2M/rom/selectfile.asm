; ****************************************************************************
; MiSTer2MEGA65 (M2M) QNICE ROM
;
; File selector including directory browser
;
; Expects that an on-screen-display is already active and uses the facilities
; of screen.asm for displaying everything. The file selectfile.asm needs the
; environment of shell.asm and HANDLE_DEV needs to be valid.
;
; done by sy2002 in 2022 and licensed under GPL v3
; ****************************************************************************

; ----------------------------------------------------------------------------
; Main routine: SELECT_FILE
; 
; Runs the whole file selection and directory browsing user experience and
; returns a string pointer to the filename.
;
; Input:
;   @TODO Stack frame and maximum browsing depth
; Output:
;   R8: Pointer to filename (zero terminated string), if R9=0
;   R9: 0=OK (no error)
;       1=SD card changed (this is no error, but need re-mounting)
;       2=Cancelled via Run/Stop
; ----------------------------------------------------------------------------

SELECT_FILE		SYSCALL(enter, 1)

				; retrieve default file browsing start path from config.vhd
				; DIRBROWSE_READ expects the start path in R9
				MOVE  	M2M$RAMROM_DEV, R9
				MOVE  	M2M$CONFIG, @R9
				MOVE  	M2M$RAMROM_4KWIN, R9
				MOVE  	M2M$CFG_DIR_START, @R9
				MOVE  	M2M$RAMROM_DATA, R9

                ; load sorted directory list into memory
                MOVE    HANDLE_DEV, R8
_S_CD_AND_READ  MOVE    HEAP, R10               ; start address of heap
                MOVE    HEAP_SIZE, R11          ; maximum memory available
                                                ; for storing the linked list
                MOVE    FILTER_FILES, R12     	; do not show ROM file names
                RSUB    DIRBROWSE_READ, 1       ; read directory content
                CMP     0, R11                  ; errors?
                RBRA    _S_BROWSE_START, Z      ; no
                CMP     1, R11                  ; error: path not found?
                RBRA    _S_ERR_PNF, Z
                CMP     2, R11                  ; max files? (only warn)
                RBRA    _S_WRN_MAX, Z
                RBRA    _S_ERR_UNKNOWN, 1

                ; default path not found, try root instead
_S_ERR_PNF      ;ADD     1, SP                   ; @TODO
                MOVE    FN_ROOT_DIR, R9         ; try root
                MOVE    HEAP, R10
                MOVE    HEAP_SIZE, R11
                RSUB    DIRBROWSE_READ, 1
                CMP     0, R11
                RBRA    _S_BROWSE_START, Z
                CMP     2, R11
                RBRA    _S_WRN_MAX, Z

                ; unknown error: end (TODO: we might want to retry in future)
_S_ERR_UNKNOWN  MOVE    ERR_BROWSE_UNKN, R8
                MOVE    R11, R9
                RBRA    FATAL, 1

                ; warn, that we are not showing all files
_S_WRN_MAX      MOVE    WRN_MAXFILES, R8        ; print warning message
                RSUB    SCR$PRINTSTR, 1
_S_WRN_WAIT 	MOVE    M2M$KEYBOARD, R8
                AND     M2M$KEY_SPACE, @R8
                RBRA    _HM_KEYLOOP, !Z         ; wait for space; low-active
                RSUB    SCR$CLRINNER, 1         ; clear inner part of window

                ; ------------------------------------------------------------
                ; DIRECTORY BROWSER
                ; ------------------------------------------------------------

_S_BROWSE_START MOVE    R10, R0                 ; R0: dir. linked list head

                MOVE    FB_HEAD, R8
                MOVE    @R8, R8                 ; persistent existing head?
                RBRA    _S_BROWSE_SETUP, Z      ; no: continue
                MOVE    R8, R0                  ; yes: use it

                ; how much items are there in the current directory?
_S_BROWSE_SETUP MOVE    R0, R8
                RSUB    SLL$LASTNCOUNT, 1
                MOVE    R10, R1                 ; R1: amount of items in dir.
                MOVE    SCR$OSM_M_DY, R2        ; R2: max rows on screen
                MOVE    @R2, R2
                SUB     2, R2                   ; (frame is 2 rows high)
                MOVE    R0, R3                  ; R3: currently visible head

                MOVE    0, R4                   ; @TODO
                ;MOVE    @SP++, R4               ; R4: currently selected ..
                                                ; .. line inside window

                XOR     R5, R5                  ; R5: counts the amount of ..
                                                ; ..files that have been shown

                MOVE    LOG_STR_ITM_AMT, R8     ; log amount of items in ..
                SYSCALL(puts, 1)                ; .. current directory to UART
                MOVE    R1, R8
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)

                MOVE    FB_ITEMS_COUNT, R8      ; existing persistent # items?
                CMP     0, @R8
                RBRA    _S_BROWSE_STP2, Z       ; no
                MOVE    @R8, R1                 ; yes: store ..
                MOVE    0, @R8                  ; .. and clear value / flag
_S_BROWSE_STP2  MOVE    FB_ITEMS_SHOWN, R8      ; exist. pers. # shown items?
                CMP     0, @R8
                RBRA    _S_DRAW_DIRLIST, Z      ; no
                MOVE    @R8, R5                 ; yes: store

                ; list (maximum one screen of) directory entries
_S_DRAW_DIRLIST RSUB    SCR$CLRINNER, 1
                MOVE    R3, R8                  ; R8: pos in LL to show list
                MOVE    R2, R9                  ; R9: amount if lines to show
                RSUB    SHOW_DIR, 1             ; print directory listing         

                MOVE    FB_ITEMS_SHOWN, R8      ; do not add SHOW_DIR result..
                CMP     0, @R8                  ; ..if R5 was restored using..
                RBRA    _S_ADDSHOWN_ITM, Z      ; FB_ITEMS_SHOWN and..
                MOVE    0, @R8                  ; ..clear FB_ITEMS_SHOWN
                RBRA    _S_SELECT_LOOP, 1

_S_ADDSHOWN_ITM ADD     R10, R5                 ; R5: overall # of files shown

_S_SELECT_LOOP  MOVE    R4, R8                  ; invert currently sel. line
                MOVE    M2M$SA_COL_STD_INV, R9
                RSUB    SELECT_LINE, 1

                ; non-blocking mechanism to read keys from the MEGA65 keyboard
                ; @TODO: make sure to poll IO
_S_INPUT_LOOP   RSUB    KEYB$SCAN, 1
                RSUB    KEYB$GETKEY, 1
                CMP     0, R8                   ; has a key been pressed?
                RBRA    _IL_KEYPRESSED, !Z      ; yes: handle key press

                ; check, if the SD card changed in the meantime
                MOVE    M2M$CSR, R8
                MOVE    @R8, R8
                AND     M2M$CSR_SD_ACTIVE, R8
                MOVE    SD_ACTIVE, R9
                CMP     R8, @R9
                RBRA    _S_INPUT_LOOP, Z        ; SD card did not change

                MOVE    R8, @R9                 ; remember new active card

                ; SD card changed: initialize stack pointer because we use
                ; the stack for remembering subdirectories and then return
                ; to the caller signalling that the SD card changed
                MOVE    M2M$CSR, R8             ; reset to auto/smart sd mode
                AND     M2M$CSR_UN_SD_MODE, @R8
_S_SD_CHANGED
#ifdef RELEASE   
                ;@TODO STACK HANDLING             
                ;MOVE    VAR$STACK_START, SP
#else
                ; in DEBUG mode, we accept the stack leak, because we do
                ; not have the address of the stack handy
#endif
                RSUB    WAIT1SEC, 1             ; debounce SD insert process
                MOVE    1, R9                   ; 1=SD card changed
                RBRA    _S_RET, 1

                ; handle keypress
_IL_KEYPRESSED  SYSCALL(exit, 1)


_S_RET          MOVE    R9, @--SP               ; bring R9 over "leave"
				SYSCALL(leave, 1)
                MOVE    @SP++, R9
				RET


; ----------------------------------------------------------------------------
; Initialize file browser persistence variables
; ----------------------------------------------------------------------------

FB_INIT         INCRB

                MOVE    FB_HEAD, R0             ; no active head of file brws.
                MOVE    0, @R0
                MOVE    FB_ITEMS_COUNT, R0      ; no directory browsed so far
                MOVE    0, @R0
                MOVE    FB_ITEMS_SHOWN, R0      ; no dir. items shown so far
                MOVE    0, @R0

                DECRB
                RET

; ----------------------------------------------------------------------------
; Show directory listing
;
; Input:
;   R8: position inside the directory linked-list from which to show it
;   R9: maximum amount of entries to show
; Output:
;  R10: amount of entries shown
; ----------------------------------------------------------------------------

SHOW_DIR        INCRB
                MOVE    R8, R0
                MOVE    R9, R1
                INCRB

                SUB     1, R9                   ; we start counting from 0
                XOR     R0, R0                  ; R0: amount of entries shown

_SHOWDIR_L      MOVE    R8, R1                  ; R1: ptr to next LL element
                ADD     SLL$NEXT, R1
                ADD     SLL$DATA, R8            ; R8: entry name
                XOR     R7, R7                  ; R7: flag: clean up stack?

                ; replace the end part of a too long string by "..."
                MOVE    SCR$OSM_M_DX, R2
                MOVE    @R2, R2
                SUB     2, R2                   ; R2: max stringlen to display
                MOVE    R9, R4                  ; save R9 to restore it later
                SYSCALL(strlen, 1)
                MOVE    R9, R3                  ; R3: length of current item
                MOVE    R4, R9                  ; restore R9: # items to show
                CMP     R3, R2                  ; current length > max strlen?
                RBRA    _SHOWDIR_PRINT, !N      ; R3 <= R2: print items
                MOVE    SP, R4                  ; save SP to restore it later
                MOVE    R9, R5                  ; save R9 to restore it later
                SUB     R3, SP                  ; reserve strlen
                SUB     1, SP                   ; .. including zero-terminator
                MOVE    SP, R9                  ; modified entry name
                SYSCALL(strcpy, 1)

                MOVE    R9, R8                  ; R8: modified item name
                MOVE    R5, R9                  ; restore R9: # items to show               
                MOVE    R8, R5
                ADD     R2, R5
                SUB     3, R5                   ; hardcoded len of FN_ELLIPSIS
                                                ; plus zero-terminator
                MOVE    FN_ELLIPSIS, R6
                MOVE    @R6++, @R5++            ; hardcoded len of FN_ELLIPSIS
                MOVE    @R6++, @R5++            ; TODO: switch to strcpy..
                MOVE    @R6++, @R5++            ; .. as of QNICE V1.7
                MOVE    0, @R5
                MOVE    1, R7                   ; flag to clean up stack

                ; for performance reasons: do not output to UART
                ; if you need to debug: delete "SCR" in the following
                ; two function calls to use the dual-output routines
_SHOWDIR_PRINT  RSUB    SCR$PRINTSTR, 1         ; print dirname/filename
                MOVE    NEWLINE, R8
                RSUB    SCR$PRINTSTR, 1

                CMP     0, R7                   ; clean up stack?
                RBRA    _SHOWDIR_NOCLN, Z       ; no: go on
                MOVE    R4, SP                  ; yes: clean up stack

_SHOWDIR_NOCLN  ADD     1, R0
                CMP     R0, R9                  ; shown <= maximum?
                RBRA    _SHOWDIR_RET, N         ; no: leave
_SHOWDIR_NEXT   MOVE    @R1, R8                 ; more entries available?
                RBRA    _SHOWDIR_L, !Z          ; yes: loop

_SHOWDIR_RET    MOVE    R0, R10                 ; return # of entries shown
                DECRB
                MOVE    R0, R8
                MOVE    R1, R9
                DECRB
                RET

; ----------------------------------------------------------------------------
; Change the attribute of the line in R8 to R9
; R8 is considered as "inside the window", i.e. screenrow = R8 + 1
; ----------------------------------------------------------------------------

SELECT_LINE     SYSCALL(enter, 1)

                MOVE    R9, R0
                ADD     1, R8                   ; calculate attrib RAM offset
                MOVE    SCR$OSM_M_DX, R9
                MOVE    @R9, R9
                SYSCALL(mulu, 1)
                ADD     1, R10                  ; screenpos in RAM

                MOVE    M2M$RAMROM_DEV, R8      ; attribute RAM
                MOVE    M2M$VRAM_ATTR, @R8
                MOVE    M2M$RAMROM_4KWIN, R8
                MOVE    0, @R8
                MOVE    M2M$RAMROM_DATA, R8

                ADD     R10, R8                 ; start position in RAM

                MOVE    SCR$OSM_M_DX, R9
                MOVE    @R9, R9
                SUB     2, R9
_SL_FILL_LOOP   MOVE    R0, @R8++
                SUB     1, R9
                RBRA    _SL_FILL_LOOP, !Z

                SYSCALL(leave, 1)
                RET
