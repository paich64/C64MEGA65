; ****************************************************************************
; MiSTer2MEGA65 (M2M) QNICE ROM
;
; Cartridges and ROMs
;
; System to handle manually and automatically loaded cartridges and ROMs.
; Manually means via the OSM (configured in config.vhd) and automatically
; means via the list that is configured in globals.vhd.
;
; The file crts-and-roms.asm needs the environment of shell.asm.
;
; done by sy2002 in 2023 and licensed under GPL v3
; ****************************************************************************

; ----------------------------------------------------------------------------
; Initialize library
; ----------------------------------------------------------------------------

CRTROM_INIT     SYSCALL(enter, 1)

                MOVE    M2M$RAMROM_DEV, R8
                MOVE    M2M$SYS_INFO, @R8
                MOVE    M2M$RAMROM_4KWIN, R8
                MOVE    M2M$SYS_CRTSANDROMS, @R8
                MOVE    CRTROM_MAN_NUM_A, R8
                MOVE    CRTROM_MAN_NUM, R0      ; num. manually ld. CRTs/ROMs
                MOVE    @R8, @R0
                MOVE    @R8, R0

                ; illegal amount of manually loaded CRTs/ROMs
                CMP     R0, 16
                RBRA    CRTROM_INIT_1, !N
                MOVE    ERR_F_CR_M_CNT, R8
                MOVE    R0, R9
                RBRA    FATAL, 1

                ; initialize "loaded" flags
                MOVE    CRTROM_MAN_LDF, R8
                MOVE    CRTROM_MAN_MAX, R9
                XOR     R10, R10
                SYSCALL(memset, 1)

CRTROM_INIT_1   SYSCALL(leave, 1)
                RET

; ----------------------------------------------------------------------------
; Query & setter functions
; ----------------------------------------------------------------------------

; Check if the manual loading system is active by checking, if there is at
; least one manually loadable CRT/ROM
;
; Returns: Carry=1 if active, else Carry=0
;          R8: Amount of manually loadable CRTs/ROMs
CRTROM_ACTIVE   INCRB

                MOVE    CRTROM_MAN_NUM, R8
                MOVE    @R8, R8
                RBRA    _CRA_C1, !Z
                AND     0xFFFB, SR              ; clear Carry
                RBRA    _CRA_RET, 1

_CRA_C1         OR      0x0004, SR              ; set Carry

_CRA_RET        DECRB
                RET

; Return the number of the manually loadable ROM or CRT that
; is associated with a single-select menu item that as a unique menu group ID
;
; The first menu item in config.vhd with a OPTM_G_LOAD_ROM flag is ROM/CRT 0,
; the next one ROM/CRT 1, etc.
;
; Input:   R8: menu item (menu group ID)
; Returns: Carry=1 if any CRT/ROM is associated with a menu item
;          R8: CRT/ROM number, starting with 0, only valid if Carry=1
CRTROM_M_NO     INCRB

                ; step 1: find the menu item, i.e. get the index relative
                ; to the beginning of the data structure
                MOVE    OPTM_DATA, R0
                MOVE    @R0, R0
                ADD     OPTM_IR_GROUPS, R0
                MOVE    @R0, R0                 ; R0: start of data structure
                MOVE    OPTM_ICOUNT, R1
                MOVE    @R1, R1                 ; R1: amount of menu items
                XOR     R2, R2                  ; R2: index of drv. men. item

_CRMN_1         CMP     R8, @R0++
                RBRA    _CRMN_3, Z              ; menu item found
                ADD     1, R2
                SUB     1, R1
                RBRA    _CRMN_1, !Z             ; check next item
_CRMN_2         MOVE    0xFFFF, R8
                RBRA    _CRMN_C0, 1             ; item not found

                ; step 2: check, if the menu item is a CRT/ROM loader and find
                ; out the CRT/ROM load number by counting; R2 contains the
                ; index of the menu item that we are looking for
_CRMN_3         XOR     R1, R1                  ; R1: CRT/ROM number, if any
                XOR     R7, R7                  ; R7: index number
                MOVE    M2M$RAMROM_DEV, R0      ; select configuration device
                MOVE    M2M$CONFIG, @R0
                MOVE    M2M$RAMROM_4KWIN, R0    ; select drv. mount items
                MOVE    M2M$CFG_OPTM_CRTROM, @R0
                MOVE    M2M$RAMROM_DATA, R0     ; R0: ptr to data structure
_CRMN_3A        CMP     R7, R2                  ; did we reach the item?
                RBRA    _CRMN_5, !Z             ; no: continue to search
_CRMN_4         CMP     1, @R0++                ; is the item a CRT/ROM?
                RBRA    _CRMN_2, !Z             ; no: return with C=0
                MOVE    R1, R8                  ; return CRT/ROM number...
                RBRA    _CRMN_C1, 1             ; ...with C=1
_CRMN_5         CMP     1, @R0++                ; item at curr idx. CRT/ROM?
                RBRA    _CRMN_6, !Z             ; no
                ADD     1, R1                   ; count item as CRT/ROM
_CRMN_6         ADD     1, R7                   ; next index position
                RBRA    _CRMN_3A, 1

                ; this code is re-used by other functions, do not change
_CRMN_C0        AND     0xFFFB, SR              ; clear Carry
                RBRA    _CRMN_RET, 1
_CRMN_C1        OR      0x0004, SR              ; set Carry

_CRMN_RET       DECRB
                RET


; Check if the CRT/ROM item number in R8 is valid: Goes fatal if no and
; uses the error code in R9 in this case
CRTROM_CHK_NO   INCRB

                ; Unstable system state: R8 is larger than the amount of
                ; available CRT/ROM menu items in config.vhd
                MOVE    CRTROM_MAN_NUM, R0
                MOVE    @R0, R0
                CMP     R8, R0
                RBRA    _CRRMCN_RET, !N
                MOVE    ERR_FATAL_INST, R8
                RBRA    FATAL, 1

_CRRMCN_RET     DECRB
                RET

; ----------------------------------------------------------------------------
; Handle manual CRT/ROM loading
; R8: CRT/ROM number
; ----------------------------------------------------------------------------

HANDLE_CRTROM_M SYSCALL(enter, 1)

                MOVE    ERR_FATAL_INST5, R9
                RSUB    CRTROM_CHK_NO, 1

                ; Remember which CRT/ROM has already been loaded so that we
                ; can for example distinguish between showing the default
                ; %s replacement or the filename when showing the OSM
_HCR_1          MOVE    CRTROM_MAN_LDF, R0
                ADD     R8, R0
                MOVE    1, @R0                  ; 1=loaded


                SYSCALL(leave, 1)
                RET
