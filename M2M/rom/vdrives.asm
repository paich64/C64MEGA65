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
; Mount/unmount drives and images
; ----------------------------------------------------------------------------

; Mount drive and image according to the protocol described in vdrives.vhd
; Does not do any sanity checks and requires that the file that the file
; handle is representing already has been "preprocessed" (headers, etc.) and
; that the read pointer points to the first raw byte that represents the image
; Input:   R8: drive number
;          R9: valid file handle, where the read pointer already is where
;              it needs to be
; Returns: Carry=1, if OK
VD_MOUNT  		INCRB
				DECRB
				RET


VD_UNMOUNT  	INCRB
				DECRB
				RET

; ----------------------------------------------------------------------------
; Query & setter functions
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

				MOVE  	R8, R1
				MOVE  	1, R0  					; probe to check drive
				AND  	0xFFFD, SR  			; clear X
				SHL  	R8, R0  				; drive 0 = LSB
				MOVE  	VD_IEC_DRV_MOUNT, R8	; get bitpattern of mounted..
				RSUB  	VD_CAD_READ, 1 			; ..drives
				MOVE  	R8, R2
				MOVE  	R1, R8  				; restore R8 (original drv. #)
				AND  	R0, R2
				RBRA  	_VDD_C1, !Z  			; yes: drive is mounted
				RBRA  	_VDD_C0, 1  		 	; no: drive is not mounted

				; DECRB and 
                ; RET done via _VDD_C0 and _VDD_C1

; Strobes the "image mount" signal: This is used to mount and to unmount
; drives: When the "image size" registers are non-zero, then the drive is
; mounted, otherwise it is held is reset state
;
; Input:   R8: drive number
; 		   R9/R10: low/high words of image size
;		   R11: 1=read only
; Returns: R8 .. R11: unchanged
VD_STROBE_IM 	INCRB

				; save original register values
				MOVE  	R8, R0  				; R0: drive number
				MOVE  	R9, R1  				; R1: file size: low word
				MOVE  	R10, R2  				; R2: file size: high word
				MOVE  	R11, R3  				; R3: read-only flag

				; set file size and read-only registers
                MOVE    VD_IEC_SIZE_L, R8
                MOVE    R1, R9
                RSUB    VD_CAD_WRITE, 1
                MOVE    VD_IEC_SIZE_H, R8
                MOVE    R2, R9
                RSUB    VD_CAD_WRITE, 1
                MOVE    VD_IEC_RO, R8
                MOVE    R3, R9
                RSUB    VD_CAD_WRITE, 1

                ; create bitmask for setting and deletig image mount bit
                MOVE  	1, R6
				AND  	0xFFFD, SR  			; clear X
				SHL  	R0, R6  				; R6: set flag, drive 0 = LSB
				NOT  	R6, R7  				; R7: used to clear flag

				; get current bitmask and then strobe the flag
				MOVE    VD_IEC_IMG_MOUNT, R8
				RSUB  	VD_CAD_READ, 1
				OR  	R6, R8 					; set flag
				MOVE  	R8, R9
				MOVE  	VD_IEC_IMG_MOUNT, R8
				RSUB  	VD_CAD_WRITE, 1  		; set flag in register
				AND  	R7, R9  				; delete flag
				RSUB  	VD_CAD_WRITE, 1  		; delete flag in register

                ; restore original register values
				MOVE  	R0, R8				
				MOVE  	R1, R9
				MOVE  	R2, R10
				MOVE  	R3, R11

				DECRB
				RET

; VDrives device: Read a value from the control and data registers
;
; Input:   R8: Register number
; Returns: R8: Value
VD_CAD_READ		INCRB

				MOVE  	M2M$RAMROM_DEV, R0
				MOVE  	VDRIVES_IEC, R1
				MOVE  	@R1, @R0
				MOVE  	M2M$RAMROM_4KWIN, R0
				MOVE  	VD_IEC_WIN_CAD, @R0
				MOVE  	@R8, R8

				DECRB
				RET

; VDrives device: Write a value to the control and data registers
;
; Input:   R8: Register number
;   	   R9: Value
; Returns: Nothing, leaves R8, R9 unchanged
VD_CAD_WRITE 	INCRB

				MOVE  	M2M$RAMROM_DEV, R0
				MOVE  	VDRIVES_IEC, R1
				MOVE  	@R1, @R0
				MOVE  	M2M$RAMROM_4KWIN, R0
				MOVE  	VD_IEC_WIN_CAD, @R0
				MOVE  	R9, @R8

				DECRB
				RET
