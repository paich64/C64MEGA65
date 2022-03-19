; ****************************************************************************
; MiSTer2MEGA65 (M2M) QNICE ROM
;
; Options menu / "Help" menu
;
; This On-Screen-Menu (OSM) offers various facilities that can be configured
; using config.vhd. The file options.asm needs the environment of shell.asm.
;
; done by sy2002 in 2022 and licensed under GPL v3
; ****************************************************************************

; ----------------------------------------------------------------------------
; Main routine
; ----------------------------------------------------------------------------

                ; Check if Help is pressed and if yes, run the Options menu
HELP_MENU       SYSCALL(enter, 1)
                CMP     M2M$KEY_HELP, R8        ; help key pressed?
                RBRA    _HLP_RET, !Z                

                ; Deactivate keyboard and joysticks, so that the key strokes
                ; done during the OSD is on are not passed along to the core
                MOVE    M2M$CSR, R0
                AND     M2M$CSR_UN_KBD_JOY, @R0

                ; Copy menu items from config.vhd to heap
                MOVE    M2M$RAMROM_DEV, R0
                MOVE    M2M$CONFIG, @R0
                MOVE    M2M$RAMROM_4KWIN, R0    ; R0: config selector
                MOVE    M2M$CFG_OPTM_ITEMS, @R0 ; select menu items
                MOVE    M2M$RAMROM_DATA, R8     ; copy men. items to heap
                MOVE    HEAP, R9
                ADD     OPTM_STRUCTSIZE, R9
                MOVE    R9, R1                  ; R1: points to item string
                SYSCALL(strcpy, 1)

                ; R2 = first free word behind the menu items
                MOVE    R9, R2
                MOVE    R9, R8
                SYSCALL(strlen, 1)              ; R9 = string length
                ADD     R9, R2
                ADD     1, R2                   ; zero terminator

                ; R3 = menu size
                MOVE    OPTM_ICOUNT, R3
                MOVE    @R3, R3

                ; Copy menu data structure from ROM to RAM (heap)
                MOVE    OPT_MENU_DATA, R8
                MOVE    HEAP, R9
                MOVE    OPTM_STRUCTSIZE, R10
                SYSCALL(memcpy, 1)

                ; Modify the menu data structure, so that it points to the 
                ; data from config.vhd
                MOVE    HEAP, R8                ; Set menu size
                ADD     OPTM_IR_SIZE, R8
                MOVE    R3, @R8                 ; R3: menu item counter
                MOVE    HEAP, R8                ; Set menu item string
                ADD     OPTM_IR_ITEMS, R8
                MOVE    R1, @R8                 ; R1: item string

                ; Copy the menu groups to the heap and modify the menu data
                ; structure accordingly.
                ; R2 contains the first free word on the heap behind the item
                ; string, so we will copy to that point and then increase
                ; R2 by R3 (menu item counter)
                ; R0 is used to switch the config selector
                MOVE    M2M$CFG_OPTM_GROUPS, @R0
                MOVE    M2M$RAMROM_DATA, R8
                MOVE    R2, R9                  ; R2: first free word
                ADD     R3, R2                  ; R2: next free word
                MOVE    R3, R10                 ; R3: amount of menu items
                SYSCALL(memcpy, 1)
                MOVE    HEAP, R8                ; store pointer to record
                ADD     OPTM_IR_GROUPS, R8
                MOVE    R9, @R8
                MOVE    R9, R12                  ; R12: pointer to menu groups

                ; Copy the standard selectors (which menu items are selected
                ; by default) from the QNICE M2M$CFM_DATA register to the
                ; heap and modify the menu data structure accordingly.
                ; (The M2M$CFM_DATA register gets its initial values from
                ; config.vhd during HELP_MENU_INIT.)
                MOVE    R2, R9                  ; R9: free word behind groups
                ADD     R3, R2                  ; R2: free wrd beh. selectors                

                MOVE    HEAP, R8                ; modify the menu data struct.
                ADD     OPTM_IR_STDSEL, R8
                MOVE    R9, @R8

                MOVE    R3, R4                  ; R4: amount of menu items                
                MOVE    M2M$CFM_ADDR, R5        ; R5: "bank" selector
                MOVE    0, @R5                  ; start with bank 0
                MOVE    M2M$CFM_DATA, R6        ; R6: the flag register

                XOR     R7, R7                  ; bit within current "bank"
_HLP_SSICA      ADD     1, R7                   ; at 16 bits we need to switch
                CMP     17, R7                  ; the bank, i.e. R7 = 17
                RBRA    _HLP_SSICS, !Z
                ADD     1, @R5                  ; next "bank"
                MOVE    1, R7
_HLP_SSICS      MOVE    @R6, R8                 ; SHR is a destructive op.
                SHR     R7, R8                  ; shift into X
                RBRA    _HLP_SSIC0, !X          ; X = 0 (R7th bit = 0)?
                MOVE    1, @R9++                ; selector true at this pos.
                RBRA    _HLP_SSIC1, 1
_HLP_SSIC0      MOVE    0, @R9++                ; selector false at this pos.
_HLP_SSIC1      SUB     1, R4                   ; one less menu item to go
                RBRA    _HLP_SSICA, !Z          ; next menu item

                ; Copy positions of separator lines & modify men. dta. struct.
                MOVE    M2M$CFG_OPTM_LINES, @R0
                MOVE    M2M$RAMROM_DATA, R8
                MOVE    R2, R9                  ; R9: free word beh. selectors
                MOVE    R3, R10                 ; R10: menu items counter
                SYSCALL(memcpy, 1)
                MOVE    HEAP, R8
                ADD     OPTM_IR_LINES, R8
                MOVE    R9, @R8

                ; run the menu
                RSUB    OPTM_SHOW, 1            ; fill VRAM
                RSUB    SCR$OSM_O_ON, 1         ; make overlay visible
                MOVE    OPTM_SELECTED, R9       ; use recently selected line
                MOVE    @R9, R8
                RSUB    OPTM_RUN, 1             ; run menu
                RSUB    SCR$OSM_OFF, 1          ; make overlay invisible

                ; Smart handling of last-recently-selected: only remember
                ; LRS when the menu is closed via pressing the Help key again.
                ; Otherwise (when using "Close Menu" or something like this),
                ; restart from the default start position
                MOVE    R12, R10
                ADD     R8, R10
                CMP     OPTM_CLOSE, @R10
                RBRA    _HLP_RESETPOS, Z
                MOVE    R8, @R9                 ; remember recently sel. line
                RBRA    _HLP_RET, 1
_HLP_RESETPOS   MOVE    OPTM_START, R0
                MOVE    @R0, @R9

                ; when the menu was exited via "Close" + Return, make sure
                ; that the Return key press is not registered by the core
                RSUB    WAIT333MS, 1

                ; Reactivate keyboard and joysticks
_HLP_RET        MOVE    M2M$CSR, R0
                OR      M2M$CSR_KBD_JOY, @R0

                SYSCALL(leave, 1)
                RET

; ----------------------------------------------------------------------------
; Init/configure the menu library
; ----------------------------------------------------------------------------

HELP_MENU_INIT  SYSCALL(enter, 1)

                MOVE    HEAP, R8
                MOVE    SCR$OSM_O_X, R9
                MOVE    @R9, R9
                MOVE    SCR$OSM_O_Y, R10
                MOVE    @R10, R10
                MOVE    SCR$OSM_O_DX, R11
                MOVE    @R11, R11
                MOVE    SCR$OSM_O_DY, R12
                MOVE    @R12, R12
                RSUB    OPTM_INIT, 1

                ; extract the amount of menu items (including empty lines and
                ; headlines) from config.vhd
                MOVE    M2M$RAMROM_DEV, R0      ; Device=config.vhd
                MOVE    M2M$CONFIG, @R0
                MOVE    M2M$RAMROM_4KWIN, R1    ; Selector=amount of items
                MOVE    M2M$CFG_OPTM_ICOUNT, @R1
                MOVE    M2M$RAMROM_DATA, R0
                MOVE    @R0, R7                 ; R7=amount of items
                MOVE    OPTM_ICOUNT, R0
                MOVE    R7, @R0

                ; check, if menu size in config.vhd is between 1 and 254
                MOVE    1, R9
                MOVE    R7, R8
                MOVE    255, R10
                SYSCALL(in_range_u, 1)          ; R9 <= R8 < R10?
                RBRA    _HLP_ITEM, C           ; yes: search start item
                MOVE    ERR_F_MENUSIZE, R8      ; no: fatal error and end
                RBRA    FATAL, 1

                ; extract the initially selected item from config.vhd
_HLP_ITEM       XOR     R0, R0                  ; R1=position of start item
                MOVE    M2M$CFG_OPTM_START, @R1 ; Selector=start flag
                MOVE    M2M$RAMROM_DATA, R2
_HLP_SEARCH     CMP     R0, R7
                RBRA    _HLP_ERROR, Z
                CMP     @R2++, 0
                RBRA    _HLP_START, !Z
                ADD     1, R0
                RBRA    _HLP_SEARCH, 1

                ; No start flag found
_HLP_ERROR      MOVE    ERR_F_MENUSTART, R8
                RBRA    FATAL, 1

                ; store initially selected item (start flag)
_HLP_START      MOVE    OPTM_START, R8
                MOVE    OPTM_SELECTED, R9
                MOVE    R0, @R8
                MOVE    R0, @R9

                ; Get the standard selectors (which menu items are selcted by
                ; default) from config.vhd and store them in M2M$CFM_DATA                
                MOVE    M2M$CFM_ADDR, R0        ; R0: select "bank" (0..15)
                MOVE    M2M$CFM_DATA, R1        ; R1: write data
                MOVE    16, R2                  ; init all "banks" to zero
                MOVE    15, @R0                 ; (@R0 can only store values
_HLP_S0         MOVE    0, @R1                  ; between 0 and 15, so we need
                SUB     1, R2                   ; R2 to count)
                RBRA    _HLP_S0E, Z             ; Make sure that @R0 = 0 when
                SUB     1, @R0                  ; we leave this loop
                RBRA    _HLP_S0, 1

_HLP_S0E        MOVE    M2M$RAMROM_4KWIN, R2
                MOVE    M2M$CFG_OPTM_STDSEL, @R2
                MOVE    M2M$RAMROM_DATA, R2     ; R2: read config.vhd data
                MOVE    OPTM_ICOUNT, R3         ; R3: amount of menu items
                MOVE    @R3, R3
                XOR     R4, R4                  ; R4: bit counter for R0
                XOR     R5, R5                  ; R5: bit pattern

_HLP_S1         MOVE    @R2++, R6               ; get bit from config.vhd
                AND     0xFFFD, SR              ; clear X
                SHL     R4, R6                  ; shift bit to correct pos.
                OR      R6, R5                  ; R5: target pattern
                ADD     1, R4                   ; next bit
                CMP     16, R4                  ; next bank for M2M$CFM_ADDR?
                RBRA    _HLP_S2, !Z             ; no: check if done
                MOVE    R5, @R1                 ; store bit pattern in ..CFM..
                XOR     R4, R4                  ; reset bit pattern counter
                XOR     R5, R5                  ; reset bit pattern
                ADD     1, @R0                  ; next "bank"
_HLP_S2         SUB     1, R3                   ; one less menu item to go
                RBRA    _HLP_S1, !Z
                CMP     0, R4                   ; something to write to @R1?
                RBRA    _HLP_S3, Z              ; no: do not destroy @R1
                MOVE    R5, @R1                 ; yes: update @R1

_HLP_S3         SYSCALL(leave, 1)
                RET

; ----------------------------------------------------------------------------
; Data structure and functions for OPTM_INIT
; ----------------------------------------------------------------------------

; Menu initialization record (needed by OPTM_INIT)
; Will be copied to the HEAP, together with the configuration data from
; config.vhd and then modified to point to the right addresses on the heap
OPT_MENU_DATA   .DW     SCR$CLR, SCR$PRINTFRAME, SCR$PRINTSTR, SCR$PRINTSTRXY
                .DW     OPT_PRINTLINE, OPTM_SELECT, OPT_MENU_GETKEY
                .DW     OPTM_CALLBACK,
                .DW     M2M$OPT_SEL_MULTI, 0    ; selection char + zero term.:
                .DW     M2M$OPT_SEL_SINGLE, 0   ; multi- and single-select
                .DW     0, 0, 0, 0, 0           ; will be filled dynamically

; Draws a horizontal line/menu separator at the y-pos given in R8, dx in R9
OPT_PRINTLINE   INCRB

                MOVE    SP, R0                  ; R0: use to restore stack
                MOVE    R8, R1                  ; R1: y-pos
                MOVE    OPTM_DX, R2             ; R2: width minus left/right..
                MOVE    @R2, R2                 ; ..boundary
                SUB     2, R2                   

                SUB     R2, SP                  ; memory for string
                SUB     3, SP                   ; 3: l/r boundary + zero term.
                MOVE    SP, R3
                MOVE    R3, R4                  ; remember for printing

                MOVE    M2M$NC_VE_LEFT, @R3++                
_PRINTLN_L      MOVE    M2M$NC_SH, @R3++
                SUB     1, R2
                RBRA    _PRINTLN_L, !Z
                MOVE    M2M$NC_VE_RIGHT, @R3++
                MOVE    0, @R3

                MOVE    R4, R8
                MOVE    OPTM_X, R9
                MOVE    @R9, R9
                MOVE    R1, R10
                RSUB    SCR$PRINTSTRXY, 1                

                MOVE    R0, SP
                DECRB
                RET

; Selects/unselects menu item in R8 (counting from 0 and counting also
; non-selectable menu entries such as lines)
; R9=0: unselect   R9=1: select
OPTM_SELECT     INCRB

                MOVE    OPTM_X, R0              ; R0: x start coordinate
                MOVE    @R0, R0
                ADD     1, R0
                MOVE    OPTM_Y, R1              ; R1: y start coordinate
                MOVE    @R1, R1
                ADD     1, R1
                ADD     R8, R1
                MOVE    OPTM_DX, R2             ; R2: width of selection
                MOVE    @R2, R2
                SUB     2, R2

                CMP     R9, 0                   ; R3: attribute to apply
                RBRA    _OPTM_FPS_1, Z
                MOVE    M2M$SA_COL_STD_INV, R3
                RBRA    _OPTM_FPS_2, 1
_OPTM_FPS_1     MOVE    M2M$SA_COL_STD, R3

_OPTM_FPS_2     MOVE    SCR$SYS_DX, R8          ; R10: start address in ..
                MOVE    @R8, R8
                MOVE    R1, R9                  ; .. attribute VRAM
                SYSCALL(mulu, 1)
                ADD     R0, R10
                ADD     M2M$RAMROM_DATA, R10

                MOVE    M2M$RAMROM_DEV, R4      ; switch to ATTR data, win 0
                MOVE    M2M$VRAM_ATTR, @R4
                MOVE    M2M$RAMROM_4KWIN, R4
                MOVE    0, @R4

                XOR     R4, R4
_OPTM_FPS_L     CMP     R2, R4
                RBRA    _OPTM_FPS_RET, Z
                MOVE    R3, @R10++
                ADD     1, R4
                RBRA    _OPTM_FPS_L, 1

_OPTM_FPS_RET   DECRB
                RET                

; Waits until one of the four Option Menu keys is pressed
; and returns the OPTM_KEY_* code in R8
OPT_MENU_GETKEY INCRB
_OPTMGK_LOOP    RSUB    HANDLE_CORE_IO, 1       ; IO handling (e.g. vdrives)
                RSUB    KEYB$SCAN, 1            ; wait until key is pressed
                RSUB    KEYB$GETKEY, 1
                CMP     0, R8
                RBRA    _OPTMGK_LOOP, Z

                CMP     M2M$KEY_UP, R8          ; up
                RBRA    _OPTM_GK_1, !Z
                MOVE    OPTM_KEY_UP, R8
                RBRA    _OPTMGK_RET, 1

_OPTM_GK_1      CMP     M2M$KEY_DOWN, R8        ; down
                RBRA    _OPTM_GK_2, !Z
                MOVE    OPTM_KEY_DOWN, R8
                RBRA    _OPTMGK_RET, 1

_OPTM_GK_2      CMP     M2M$KEY_RETURN, R8      ; return (select)
                RBRA    _OPTM_GK_3, !Z
                MOVE    OPTM_KEY_SELECT, R8
                RBRA    _OPTMGK_RET, 1

_OPTM_GK_3      CMP     M2M$KEY_HELP, R8        ; help (close menu)
                RBRA    _OPTMGK_LOOP, !Z        ; other key: ignore
                MOVE    OPTM_KEY_CLOSE, R8

_OPTMGK_RET     DECRB
                RET

; Callback function that is called during the execution of the menu (OPTM_RUN)
; R8: selected menu group (as defined in OPTM_IR_GROUPS)
; R9: selected item within menu group
;     in case of single selected items: 0=not selected, 1=selected
;
; For making sure that the hardware can react in "real-time" to menu item
; changes, i.e. even before the menu is closed, we are updating the
; QNICE M2M$CFM_DATA register each time something changes.


; DEBUG

STR_MOUNT_0     .ASCII_W "Drive #8 is currently not mounted.\n"
STR_MOUNTED     .ASCII_W "Did mount it.\n"
STR_UNMOUNTED   .ASCII_W "Did unmount it.\n"
STR_MOUNT_1     .ASCII_W "Drive #8 is currently mounted.\n"

OPTM_CALLBACK   INCRB

                ; DEBUG
                MOVE    R8, @--SP
                SYSCALL(puthex, 1)
                MOVE    R9, R8
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)
                MOVE    @SP++, R8

                ; Special treatment for drive-mount items: Drive-mount items
                ; are per definition also single-select items
                MOVE  	R8, R0 					; R8: selected menu group
                MOVE  	R0, R1  				; R1: save selected group
                AND  	OPTM_SINGLESEL, R0 		; single-select item?
                RBRA  	_OPTMC_NOMNT, Z 		; no: proceed to std. beh.
                RSUB  	VD_ACTIVE, 1  			; are there any vdrives?
                RBRA  	_OPTMC_NOMNT, !C   		; no: proceed to std. beh.
                MOVE  	R1, R8  				; R1: selected menu group
                RSUB  	VD_DRVNO, 1 			; is menu item a mount item?
                RBRA  	_OPTMC_NOMNT, !C  		; no: : proceed to std. beh.

                ; R8 contains the drive number at this point.
                ; Check, if the drive is mounted: If yes, unmount it and
                ; reset the menu entry. If no, mount it.
                SYSCALL(puthex, 1)
                SYSCALL(crlf, 1)
                MOVE    R8, R0

                RSUB    VD_MOUNTED, 1
                RBRA    _DBG_1, C

                MOVE    STR_MOUNT_0, R8
                SYSCALL(puts, 1)

                ; mount by strobing mount signal
                MOVE    R0, R8
                MOVE    VD_IEC_SIZE_L, R9
                MOVE    VD_IEC_SIZE_H, R10
                MOVE    1, R11
                RSUB    VD_STROBE_IM, 1

                MOVE    STR_MOUNTED, R8
                SYSCALL(puts, 1)
                RBRA    _OPTMC_NOMNT, 1

_DBG_1          MOVE    STR_MOUNT_1, R8
                SYSCALL(puts, 1)

                ; unmount by strobing mount signal
                MOVE    R0, R8
                XOR     R9, R9
                XOR     R10, R10
                XOR     R11, R11
                RSUB    VD_STROBE_IM, 1

                MOVE    STR_UNMOUNTED, R8
                SYSCALL(puts, 1)               

                ; Standard behavior
_OPTMC_NOMNT    CMP     OPTM_CLOSE, R8          ; CLOSE = no changes: leave
                RBRA    _OPTMCB_RET, Z

                MOVE    OPTM_ICOUNT, R0         ; R0: amount of menu items
                MOVE    @R0, R0
                MOVE    HEAP, R1                ; R1: words in consecutive..
                ADD     OPTM_IR_STDSEL, R1      ; ..memory layout containing..
                MOVE    @R1, R1                 ; ..the current selection
                MOVE    M2M$CFM_ADDR, R2        ; R2: "bank" selector
                MOVE    0, @R2
                MOVE    M2M$CFM_DATA, R3        ; R3: QNICE target register
                MOVE    1, R4                   ; R4: mask to set bit
                XOR     R5, R5                  ; R5: bit counter/switch bank

_OPTMCB_A       CMP     @R1++, 1                ; set or clear bit?
                RBRA    _OPTMCB_B, !Z           ; go to: clear
                OR      R4, @R3                 ; set
                RBRA    _OPTMCB_C, 1

_OPTMCB_B       NOT     R4, R6                  ; inverse R4 to clear bit
                AND     R6, @R3
                
_OPTMCB_C       ADD     1, R5                   ; "bank" switch necessary?
                CMP     16, R5
                RBRA    _OPTMCB_D, !Z           ; no
                ADD     1, @R2                  ; yes
                XOR     R5, R5
                MOVE    1, R4
                RBRA    _OPTMCB_E, 1

_OPTMCB_D       AND     0xFFFD, SR              ; clear X
                SHL     1, R4                   ; next bit position

_OPTMCB_E       SUB     1, R0
                RBRA    _OPTMCB_A, !Z

_OPTMCB_RET     DECRB
                RET
