.include "cbm_kernal.inc"

.import __SRAMCODE_LOAD__, __SRAMCODE_RUN__, __SRAMCODE_SIZE__

.SEGMENT "BASICSTUB"

.INCBIN "basic_stub.bin"

.SEGMENT "CODE"

start:
		ldx #<__SRAMCODE_SIZE__
:		lda __SRAMCODE_LOAD__-1,x
		sta __SRAMCODE_RUN__-1,x
		dex
		bne :-

		; Clear screen
		lda #147
		jsr BSOUT

		lda #<intro_txt
		ldx #>intro_txt
		jsr strout

		jsr wait_return

		; Clear screen
		lda #147
		jsr BSOUT
		
		lda #<clear_roml_txt
		ldx #>clear_roml_txt
		jsr strout
		jsr clear_roml
		lda #<clear_romh_txt
		ldx #>clear_romh_txt
		jsr strout
		jsr clear_romh
		lda #<clear_kernal_txt
		ldx #>clear_kernal_txt
		jsr strout
		jsr clear_kernal
		
		jsr test_exrom
		bcs :+
		jmp error_abort
:		jsr test_game
		bcs :+
		jmp error_abort

:		lda #<read_flash_ids_txt
		ldx #>read_flash_ids_txt
		jsr strout
		jsr read_flashids
		jsr print_flashids
				
		jsr test_ramok_after_flashid
		bcs :+
		jmp error_abort
		
:		jsr wait_return
		lda #147
		jsr BSOUT
		lda #<crt8k_loram_hiram_txt
		ldx #>crt8k_loram_hiram_txt
		jsr strout
		
		lda #6		; 8K CRT mode
		sta $de02
		
		lda #<test_8000_rom_txt
		ldx #>test_8000_rom_txt
		jsr strout
		
		jsr test_8000_ram
		bcs @1
		lda #<ok_txt
		ldx #>ok_txt
		bne @2
@1:		lda #<error_txt
		ldx #>error_txt
@2:		jsr strout

		lda #<test_a000_basic_txt
		ldx #>test_a000_basic_txt
		jsr strout

		jsr test_a000_ram
		bcs @3
		lda #$94
		cmp $a000
		bne @3
		lda #$e3
		cmp $a001
		bne @3
		lda #<ok_txt
		ldx #>ok_txt
		bne @4
@3:		lda #<error_txt
		ldx #>error_txt
@4:		jsr strout

		lda #<flashidromlfailtxt
		ldx #>flashidromlfailtxt
		jsr strout
		jsr flash_id_roml_shall_fail
		bcc @5
		lda #<ok_txt
		ldx #>ok_txt
		bne @6
@5:		lda #<error_txt
		ldx #>error_txt
@6:		jsr strout

		lda #<crt8k_nloram_hiram_txt
		ldx #>crt8k_nloram_hiram_txt
		jsr strout

		lda #6
		sta $01

		lda #<test_8000_ram_txt
		ldx #>test_8000_ram_txt
		jsr strout

		jsr test_8000_ram
		bcc @7
		lda #<ok_txt
		ldx #>ok_txt
		bne @8
@7:		lda #<error_txt
		ldx #>error_txt
@8:		jsr strout

		lda #<test_a000_ram_txt
		ldx #>test_a000_ram_txt
		jsr strout

		jsr test_a000_ram
		bcc @9
		lda #<ok_txt
		ldx #>ok_txt
		bne @10
@9:		lda #<error_txt
		ldx #>error_txt
@10:	jsr strout

		lda #<flashidromlfailtxt
		ldx #>flashidromlfailtxt
		jsr strout
		jsr flash_id_roml_shall_fail
		bcc @11
		lda #<ok_txt
		ldx #>ok_txt
		bne @12
@11:	lda #<error_txt
		ldx #>error_txt
@12:	jsr strout

		lda #<crt8k_loram_nhiram_txt
		ldx #>crt8k_loram_nhiram_txt
		jsr strout

		lda #<test_8000_ram_txt
		ldx #>test_8000_ram_txt
		jsr strout

		lda #5
		sta $01
		jsr test_8000_ram
		bcc @13
		lda #<ok_txt
		ldx #>ok_txt
		bne @14
@13:	lda #<error_txt
		ldx #>error_txt
@14:	ldy #7
		sty $01
		jsr strout

		lda #<test_a000_ram_txt
		ldx #>test_a000_ram_txt
		jsr strout

		lda #5
		sta $01
		jsr test_a000_ram
		bcc @15
		lda #<ok_txt
		ldx #>ok_txt
		bne @16
@15:	lda #<error_txt
		ldx #>error_txt
@16:	ldy #7
		sty $01
		jsr strout


		jsr wait_return
		lda #147
		jsr BSOUT

		lda #<crt16k_loram_hiram_txt
		ldx #>crt16k_loram_hiram_txt
		jsr strout

		lda #7		; 16K CRT mode
		sta $de02
		
		lda #<test_8000_rom_txt
		ldx #>test_8000_rom_txt
		jsr strout
		
		jsr test_8000_ram
		bcs @17
		lda #<ok_txt
		ldx #>ok_txt
		bne @18
@17:	lda #<error_txt
		ldx #>error_txt
@18:	jsr strout

		lda #<test_a000_rom_txt
		ldx #>test_a000_rom_txt
		jsr strout

		jsr test_a000_ram
		bcs @19
		lda #$94
		cmp $a000
		bne @20
		lda #$e3
		cmp $a001
		bne @20
@19:	lda #<error_txt
		ldx #>error_txt
		bne @21
@20:	lda #<ok_txt
		ldx #>ok_txt
@21:	jsr strout

		lda #<flashidromlfailtxt
		ldx #>flashidromlfailtxt
		jsr strout
		jsr flash_id_roml_shall_fail
		bcc @22
		lda #<ok_txt
		ldx #>ok_txt
		bne @23
@22:	lda #<error_txt
		ldx #>error_txt
@23:	jsr strout

		lda #<flashidromhfailtxt
		ldx #>flashidromhfailtxt
		jsr strout
		jsr flash_id_romh_shall_fail
		bcc @a1
		lda #<ok_txt
		ldx #>ok_txt
		bne @a2
@a1:	lda #<error_txt
		ldx #>error_txt
@a2:	jsr strout

		lda #<crt16k_nloram_hiram_txt
		ldx #>crt16k_nloram_hiram_txt
		jsr strout

		lda #6
		sta $01

		lda #<test_8000_ram_txt
		ldx #>test_8000_ram_txt
		jsr strout

		jsr test_8000_ram
		bcc @24
		lda #<ok_txt
		ldx #>ok_txt
		bne @25
@24:	lda #<error_txt
		ldx #>error_txt
@25:	jsr strout

		lda #<test_a000_rom_txt
		ldx #>test_a000_rom_txt
		jsr strout

		jsr test_a000_ram
		bcs @26
		lda #<ok_txt
		ldx #>ok_txt
		bne @27
@26:	lda #<error_txt
		ldx #>error_txt
@27:	jsr strout

		lda #<flashidromlfailtxt
		ldx #>flashidromlfailtxt
		jsr strout
		jsr flash_id_roml_shall_fail
		bcc @28
		lda #<ok_txt
		ldx #>ok_txt
		bne @29
@28:	lda #<error_txt
		ldx #>error_txt
@29:	jsr strout

		lda #<flashidromhfailtxt
		ldx #>flashidromhfailtxt
		jsr strout
		jsr flash_id_romh_shall_fail
		bcc @a3
		lda #<ok_txt
		ldx #>ok_txt
		bne @a4
@a3:	lda #<error_txt
		ldx #>error_txt
@a4:	jsr strout

		lda #<crt16k_loram_nhiram_txt
		ldx #>crt16k_loram_nhiram_txt
		jsr strout

		lda #<test_8000_ram_txt
		ldx #>test_8000_ram_txt
		jsr strout

		lda #5
		sta $01
		jsr test_8000_ram
		bcc @30
		lda #<ok_txt
		ldx #>ok_txt
		bne @31
@30:	lda #<error_txt
		ldx #>error_txt
@31:	ldy #7
		sty $01
		jsr strout

		lda #<test_a000_ram_txt
		ldx #>test_a000_ram_txt
		jsr strout

		lda #5
		sta $01
		jsr test_a000_ram
		bcc @32
		lda #<ok_txt
		ldx #>ok_txt
		bne @33
@32:	lda #<error_txt
		ldx #>error_txt
@33:	ldy #7
		sty $01
		jsr strout


;		lda #<load_txt
;		ldx #>load_txt
		lda #<tests_complete_txt
		ldx #>tests_complete_txt
		jsr strout
		
		lda #7
		sta $01
		lda #4
		sta $de02
		rts

error_abort:
		lda #<error_abort_txt
		ldx #>error_abort_txt
		jsr strout
		lda #7
		sta $01
		lda #4
		sta $de02
		rts

intro_txt:				.byte "this program tests the functionality of",$0d
						.byte "the commodore 64 pla. the program uses",$0d
						.byte "hardware on an easyflash cartridge to",$0d
						.byte "control the cartridge pla signals.",$0d
						.byte $0d
						.byte "this means that an easyflash cartridge",$0d
						.byte "needs to be inserted before running",$0d
						.byte "this program. the cartridge can be in",$0d
						.byte "programming mode to boot to basic",$0d
						.byte "rom contents to not matter and won't",$0d
						.byte "be modified.",$0d,$0d,00
clear_roml_txt:			.byte "clearing ram below roml",$0d,00
clear_romh_txt:			.byte "clearing ram below romh",$0d,00
clear_kernal_txt:		.byte "clearing ram below kernal",$0d,00
read_flash_ids_txt:		.byte $0d,"reading flash ids:",$0d,00
load_txt:				.byte $0d,"load",$22,"platest.prg",$22,",10",$0d,00
error_abort_txt:		.byte $0d,"fatal error, aborting",$0d,00
crt8k_loram_hiram_txt:	.byte "8k crt mode, loram=1, hiram=1",$0d,00
crt8k_nloram_hiram_txt:	.byte $0d,"8k crt mode, loram=0, hiram=1",$0d,00
crt8k_loram_nhiram_txt:	.byte $0d,"8k crt mode, loram=1, hiram=0",$0d,00
crt16k_loram_hiram_txt:	.byte "16k crt mode, loram=1, hiram=1",$0d,00
crt16k_nloram_hiram_txt:	.byte $0d,"16k crt mode, loram=0, hiram=1",$0d,00
crt16k_loram_nhiram_txt:	.byte $0d,"16k crt mode, loram=1, hiram=0",$0d,00
test_8000_rom_txt:		.byte "$8000 shall be rom: ",$00
test_8000_ram_txt:		.byte "$8000 shall be ram: ",$00
test_a000_basic_txt:	.byte "$a000 shall be basic: ",$00
test_a000_ram_txt:		.byte "$a000 shall be ram: ",$00
test_a000_rom_txt:		.byte "$a000 shall be rom: ",$00
flashidromlfailtxt:		.byte "cart doesn't receive roml writes: ",$00
flashidromhfailtxt:		.byte "cart doesn't receive romh writes: ",$00
tests_complete_txt:		.byte $0d,"tests complete!",$0d,$00

.proc print_flashids
		lda #<romlmanuftxt
		ldx #>romlmanuftxt
		jsr strout
		lda $61
		jsr hexout
		lda #13
		jsr BSOUT

		lda #<romldevicetxt
		ldx #>romldevicetxt
		jsr strout
		lda $62
		jsr hexout
		lda #13
		jsr BSOUT

		lda #<romhmanuftxt
		ldx #>romhmanuftxt
		jsr strout
		lda $63
		jsr hexout
		lda #13
		jsr BSOUT

		lda #<romhdevicetxt
		ldx #>romhdevicetxt
		jsr strout
		lda $64
		jsr hexout
		lda #13
		jsr BSOUT
		rts
.endproc


romlmanuftxt:	 .asciiz "roml flash manufacturer id: "
romldevicetxt:	 .asciiz "roml flash device id: "
romhmanuftxt:	 .asciiz "romh flash manufacturer id: "
romhdevicetxt:	 .asciiz "romh flash device id: "

.proc flash_id_roml_shall_fail
		; Send device ID command to both flash ROMs
		lda #2
		sta $de00
		lda #$aa
		sta $9555
		lda #1
		sta $de00
		lda #$55
		sta $8aaa
		lda #2
		sta $de00
		lda #$90
		sta $9555
		
		lda $61
		cmp $8000
		beq @fail
		lda $62
		cmp $8001
		beq @fail

		lda #$ff
		sta $9555
		sta $8aaa
		sec
		rts
@fail:
		clc
		rts
.endproc


.export flash_id_romh_shall_fail
.proc flash_id_romh_shall_fail
		; Send device ID command to both flash ROMs
		lda #2
		sta $de00
		lda #$aa
		sta $b555
		lda #1
		sta $de00
		lda #$55
		sta $aaaa
		lda #2
		sta $de00
		lda #$90
		sta $b555
		
		lda $63
		cmp $a000
		beq @fail
		lda $64
		cmp $a001
		beq @fail

		lda #$ff
		sta $b555
		sta $aaaa
		sec
		rts
@fail:
		clc
		rts
.endproc


.export clear_roml
.proc clear_roml
		lda #$80
		sta @1+2
		lda #$ff
		ldy #0
@1:
		sta $8000,y
		iny
		bne @1
		inc @1+2
		ldx @1+2
		cpx #$a0
		bne @1
		rts
.endproc

.export clear_romh
.proc clear_romh
		lda #$a0
		sta @1+2
		lda #$ff
		ldy #0
@1:
		sta $a000,y
		iny
		bne @1
		inc @1+2
		ldx @1+2
		cpx #$c0
		bne @1
		rts
.endproc

.export clear_kernal
.proc clear_kernal
		lda #$e0
		sta @1+2
		lda #$ff
		ldy #0
@1:
		sta $e000,y
		iny
		bne @1
		inc @1+2
		bne @1
		rts
.endproc

.export test_ramok_after_flashid
.proc test_ramok_after_flashid
		lda #<ramok_after_flashid_txt
		ldx #>ramok_after_flashid_txt
		jsr strout
		sei
		lda #4
		sta $01
		lda #$ff
		cmp $9555
		bne @error
		cmp $8aaa
		bne @error
		cmp $f555
		bne @error
		cmp $eaaa
		bne @error
		lda #<ok_txt
		ldx #>ok_txt
		sec
		bcs @end
@error:
		lda #<error_txt
		ldx #>error_txt
		clc
@end:
		php
		ldy #7
		sty $01
		cli
		jsr strout
		plp
		rts
.endproc

ramok_after_flashid_txt:	.byte "ram below cart shall be intact: ",$00

.proc hexdig
		cmp #10
		bcc :+
		adc #6
:		adc #$30
		jmp BSOUT
.endproc

.proc hexout
		pha
		lsr a
		lsr a
		lsr a
		lsr a
		jsr hexdig
		pla
		and #$0f
		jmp hexdig
.endproc

.proc strout
		sta L1+1
		stx L1+2
L1:
		lda $ffff ; address overwritten
		beq L2
		jsr BSOUT
		inc L1+1
		bne L1
		inc L1+2
		bne L1
L2:
		rts
.endproc
		
.proc wait_return
		lda #<press_return_txt
		ldx #>press_return_txt
		jsr strout
:		jsr BASIN
		cmp #$0d
		bne :-
		rts
.endproc

.proc test_8000_ram
		lda #$00
		sta $8000
		lda $8000
		cmp #$00
		bne @noram
		lda #$ff
		sta $8000
		lda $8000
		cmp #$ff
		bne @noram
		sec
		rts
@noram:
		lda #$ff
		sta $8000
		clc
		rts
.endproc

.proc test_a000_ram
		lda #$00
		sta $a000
		lda $a000
		cmp #$00
		bne @noram
		lda #$ff
		sta $a000
		lda $a000
		cmp #$ff
		bne @noram
		sec
		rts
@noram:
		lda #$ff
		sta $a000
		clc
		rts
.endproc

.export test_exrom
.proc test_exrom
		lda #<test_exrom_txt
		ldx #>test_exrom_txt
		jsr strout
		lda #4
		sta $de02
		jsr test_8000_ram
		bcc @error
		lda #6
		sta $de02
		jsr test_8000_ram
		bcs @error
		lda #<ok_txt
		ldx #>ok_txt
		sec
		php
		bcs @done
@error:
		clc
		php
		lda #<error_txt
		ldx #>error_txt
@done:
		ldy #4
		sty $de02
		jsr strout
		plp
		rts
.endproc

.export test_game
.proc test_game
		lda #<test_game_txt
		ldx #>test_game_txt
		jsr strout
		jsr test_game_highcode
		php
		bcc @error
		lda #<ok_txt
		ldx #>ok_txt
		bcs @done
@error:
		lda #<error_txt
		ldx #>error_txt
@done:
		jsr strout
		plp
		rts
.endproc

test_exrom_txt:		.byte "testing exrom function: ",$00
test_game_txt:		.byte "testing game function: ",$00
ok_txt:				.byte "ok",$0d,$00
error_txt:				.byte "error",$0d,$00


press_return_txt:	.byte $0d,"please press return: ",$00

.SEGMENT "SRAMCODE"

read_flashids:
		sei
		; Enter Ultimax mode
		lda #$85
		sta $de02
		
		; Send device ID command to both flash ROMs
		lda #2
		sta $de00
		lda #$aa
		sta $9555
		sta $f555
		lda #1
		sta $de00
		lda #$55
		sta $8aaa
		sta $eaaa
		lda #2
		sta $de00
		lda #$90
		sta $9555
		sta $f555
		
		; Read device ID from both flash ROMs and save
		lda $8000
		sta $61
		lda $8001
		sta $62
		lda $e000
		sta $63
		lda $e001
		sta $64
		
		; Exit device ID mode
		lda #$f0
		sta $8000
		sta $e000
		
		; Exit Ultimax mode
		lda #$04
		sta $de02

		cli
		rts

test_game_highcode:
		sei
		; Enter Ultimax mode
		; RAM should now be unmapped
		lda #$05
		sta $de02
		lda #$ff
		sta $7fff
		lda $7fff
		cmp #$ff
		bne @ok
		lda #$00
		sta $7fff
		lda $7fff
		cmp #$00
		bne @ok
		lda #$04
		sta $de02
		clc
		cli
		rts
@ok:
		lda #$04
		sta $de02
		sec
		cli
		rts
	