; ****************************************************************************
; MiSTer2MEGA65 (M2M) QNICE ROM
;
; Reset and Pause handling of the core
;
; The behavior can be configured in config.vhd; see also the documentation
; written there. The file resetpause.asm needs the environment of shell.asm.
;
; done by sy2002 in 2022 and licensed under GPL v3
; ****************************************************************************

                ; Read the settings from config.vhd and store it in variables
RESETPAUSE_INIT INCRB

                DECRB
                RET

