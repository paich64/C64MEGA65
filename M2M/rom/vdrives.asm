; ****************************************************************************
; MiSTer2MEGA65 (M2M) QNICE ROM
;
; Virtual Drives
;
; Drive mounting logic according to MiSTers "SD" interface (see vdrives.vhd).
; The file vdrives.asm needs the environment of shell.asm.
;
; done by sy2002 in 2022 and licensed under GPL v3
; ****************************************************************************


; ----------------------------------------------------------------------------
; Query functions
; ----------------------------------------------------------------------------

; Check if the virtual drive system is active by checking, if there is at
; least one virtual drive.
;
; Returns: Carry=1 if active, else Carry=0
;		   R8: Amount of vdrives
VD_ACTIVE		INCRB							; TEMP XYZ

				MOVE  	VDRIVES_NUM, R8
				MOVE  	@R8, R8
				RBRA 	_VDA_C1, !Z
				AND  	0xFFFB, SR 				; clear Carry
				RBRA  	_VDA_RET, 1

_VDA_C1  		OR  	0x0004, SR				; set Carry

_VDA_RET		DECRB
				RET

; Return the drive number associated with a menu item:
; The first menu item in config.vhd with a OPTM_G_MOUNT_DRV flag is drive 0,
; the next one drive 1, etc.
;
; Input:   R8: menu item
; Returns: Carry=1 if any drive number is associated with a menu item
;          R8: drive number, starting with 0, only valid if Carry=1
VD_DRVNO  		INCRB

				; step 1: find the menu item, i.e. get the index relative
				; to the beginning of the data structure
				MOVE  	OPTM_DATA, R0
				MOVE  	@R0, R0
				ADD 	OPTM_IR_GROUPS, R0
				MOVE  	@R0, R0					; R0: start of data structure
				MOVE  	OPTM_ICOUNT, R1
				MOVE  	@R1, R1  				; R1: amount of menu items
				XOR  	R2, R2  				; R2: index of drv. men. item

_VDD_1			CMP  	R8, @R0++
				RBRA  	_VDD_3, Z  				; menu item found
				ADD  	1, R2
				SUB  	1, R1
				RBRA  	_VDD_1, !Z  			; check next item
_VDD_2			MOVE  	0xFFFF, R8
				RBRA  	_VDD_C0, 1  			; item not found

				; step 2: check, if the menu item is a drive and find out the
				; drive number by counting; R2 contains the index of the menu
				; item that we are looking for
_VDD_3 			XOR  	R1, R1  				; R1: drive number, if any
				XOR  	R7, R7  				; R7: index number
				MOVE  	M2M$RAMROM_DEV, R0 		; select configuration device
				MOVE  	M2M$CONFIG, @R0
				MOVE  	M2M$RAMROM_4KWIN, R0  	; select drv. mount items
				MOVE  	M2M$CFG_OPTM_MOUNT, @R0
				MOVE  	M2M$RAMROM_DATA, R0  	; R0: ptr to data structure
_VDD_3A			CMP  	R7, R2  				; did we reach the item?
				RBRA  	_VDD_5, !Z  		    ; no: continue to search
_VDD_4  		CMP  	1, @R0++ 				; is the item a drive?
				RBRA  	_VDD_2, !Z  			; no: return with C=0
				MOVE  	R1, R8  				; return drive number...
				RBRA  	_VDD_C1, 1 				; ...with C=1
_VDD_5  		CMP  	1, @R0++  				; item at curr idx. drive?
				RBRA  	_VDD_6, !Z   			; no
				ADD  	1, R1  					; count item as drive
_VDD_6			ADD  	1, R7 					; next index position
				RBRA  	_VDD_3A, 1

				; this code is re-used by other functions, do not change
_VDD_C0 		AND  	0xFFFB, SR 				; clear Carry
				RBRA  	_VDD_RET, 1
_VDD_C1  		OR  	0x0004, SR  			; set Carry

_VDD_RET		DECRB
				RET

; Checks, if the given drive is mounted
;
; Input:   R8: drive number
; Returns: Carry=1 if drive is mounted
;          R8: drive number (unchanged)
VD_MOUNTED		INCRB

				MOVE  	1, R0  					; probe to check drive
				AND  	0xFFFD, SR  			; clear X

				; DECRB and 
                ; RET done via _VDD_C0 and _VDD_C1

; VDrives device: Read a value from the control and data registers
;
; Input:   R8: Register number
; Returns: R8: Value
VD_CAD  		INCRB
				MOVE  	M2M$RAMROM_DEV, R0
				MOVE  	VDRIVES_IEC, R1
				MOVE  	@R1, @R0
				MOVE  	M2M$RAMROM_4KWIN, R0
				MOVE  	VD_IEC_WIN_CAD, @R0
				MOVE  	@R8, R8
				DECRB
				RET
