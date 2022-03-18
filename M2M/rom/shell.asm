; ****************************************************************************
; MiSTer2MEGA65 (M2M) QNICE ROM
;
; Shell: User interface and core automation
;
; The intention of the Shell is to provide a uniform user interface and core
; automation for all MiSTer2MEGA65 projects.
;
; done by sy2002 in 2021 and licensed under GPL v3
; ****************************************************************************

                ; @TODO: different behavior of C64 core than in the framework
                ; make reset and pause behavior configurable in config.vhd
                ; Make sure that SCR$OSM_O_ON (and the others) are behaving
                ; consistent to this setting in config.vhd
                ; And anyway, as a first step the shell should keep the core
                ; in reset state for "a while" so that it can settle and we
                ; have no reset related bugs
START_SHELL     MOVE    M2M$CSR, R0             ; Reset core and clear all
                MOVE    M2M$CSR_RESET, @R0      ; other CSR flags, so that
                                                ; no keypress propagates to
                                                ; the core
                MOVE    100, R1
_RESET_A_WHILE  SUB     1, R1
                RBRA    _RESET_A_WHILE, !Z
                MOVE    0, @R0                  ; remove reset signal

                ; initialize screen library and show welcome screen:
                ; draw frame and print text
                RSUB    SCR$INIT, 1             ; retrieve VHDL generics
                RSUB    SCR$CLR, 1              ; clear screen                                
                MOVE    SCR$OSM_M_X, R8         ; retrieve frame coordinates
                MOVE    @R8, R8
                MOVE    SCR$OSM_M_Y, R9
                MOVE    @R9, R9
                MOVE    SCR$OSM_M_DX, R10
                MOVE    @R10, R10
                MOVE    SCR$OSM_M_DY, R11
                MOVE    @R11, R11
                RSUB    SCR$PRINTFRAME, 1       ; draw frame
                MOVE    M2M$RAMROM_DEV, R0      ; Device = config data
                MOVE    M2M$CONFIG, @R0
                MOVE    M2M$RAMROM_4KWIN, R0    ; Selector = Welcome screen
                MOVE    M2M$CFG_WELCOME, @R0
                MOVE    M2M$RAMROM_DATA, R8     ; R8 = welcome screen string
                RSUB    SCR$PRINTSTR, 1

                ; switch on main OSM
                RSUB    SCR$OSM_M_ON, 1

                ; initialize all other libraries as late as here, so that
                ; error messages (if any) can be printed on screen because the
                ; screen is already initialized using the sequence above
                RSUB    KEYB$INIT, 1            ; keyboard library
                RSUB    HELP_MENU_INIT, 1       ; menu library                

                ; Wait for "Space to continue"
                ; TODO: The whole startup behavior of the Shell needs to be
                ; more flexible than this, see also README.md
START_SPACE     RSUB    KEYB$SCAN, 1
                RSUB    KEYB$GETKEY, 1
                CMP     M2M$KEY_SPACE, R8
                RBRA    START_SPACE, !Z         ; loop until Space was pressed

                ; Hide OSM and connect keyboard and joysticks to the core
                RSUB    SCR$OSM_OFF, 1

                ; Avoid that the keypress to exit the splash screen gets
                ; noticed by the core: Wait 1 second and only after that
                ; connect the keyboard and the joysticks to the core
                RSUB    WAIT333MS, 1
                MOVE    M2M$CSR, R0
                OR      M2M$CSR_KBD_JOY, @R0

                ; if drives have been mounted, the mount strobe needs to be
                ; renewed after a reset, as the reset signal also resets
                ; the state of vdrives.vhd
                RSUB    PREPARE_CORE_IO, 1

                ; Main loop:
                ;
                ; The core is running and QNICE is waiting for triggers to
                ; react. Such triggers could be for example the "Help" button
                ; which is meant to open the options menu but also triggers
                ; from the core such as data requests from disk drives.
                ;
                ; The latter one could also be done via interrupts, but we
                ; will try to keep it simple in the first iteration and only
                ; increase complexity by using interrupts if neccessary.
MAIN_LOOP       RSUB    HANDLE_CORE_IO, 1       ; IO handling (e.g. vdrives)
                RSUB    CHECK_DEBUG, 1          ; (Run/Stop+Cursor Up) + Help

                RSUB    KEYB$SCAN, 1            ; scan for single key presses
                RSUB    KEYB$GETKEY, 1

                RSUB    HELP_MENU, 1            ; check/manage help menu

                RBRA    MAIN_LOOP, 1

; ----------------------------------------------------------------------------
; Debug mode:
; Hold "Run/Stop" + "Cursor Up" and then while holding these, press "Help"
; ----------------------------------------------------------------------------

                ; Debug mode: Exits the main loop and starts the QNICE
                ; Monitor which can be used to debug via UART and a
                ; terminal program. You can return to the Shell by using
                ; the Monitor C/R command while entering the start address
                ; that is shown in the terminal (using the "puthex" below).
CHECK_DEBUG     INCRB
                MOVE    M2M$KEY_UP, R0
                OR      M2M$KEY_RUNSTOP, R0
                OR      M2M$KEY_HELP, R0
                MOVE    M2M$KEYBOARD, R1        ; read keyboard status
                MOVE    @R1, R2
                NOT     R2, R2                  ; convert low active to hi
                AND     R0, R2
                CMP     R0, R2                  ; key combi pressed?
                DECRB
                RBRA    START_MONITOR, Z        ; yes: enter debug mode
                RET                             ; no: return to main loop
                
START_MONITOR   MOVE    DBG_START1, R8          ; print info message via UART
                SYSCALL(puts, 1)
                MOVE    START_SHELL, R8         ; show how to return to ..
                SYSCALL(puthex, 1)              ; .. the shell
                MOVE    DBG_START2, R8
                SYSCALL(puts, 1)
                SYSCALL(exit, 1)                ; small/irrelevant stack leak

; ----------------------------------------------------------------------------
; Fatal error:
; Output message to the screen and to the serial terminal and then quit.
; R8: Pointer to error message from strings.asm
; ----------------------------------------------------------------------------

FATAL           MOVE    R8, R0
                RSUB    SCR$CLR, 1
                MOVE    1, R8
                MOVE    1, R9
                RSUB    SCR$GOTOXY, 1
                MOVE    ERR_FATAL, R8
                RSUB    SCR$PRINTSTR, 1
                SYSCALL(puts, 1)
                MOVE    R0, R8
                RSUB    SCR$PRINTSTR, 1
                SYSCALL(puts, 1)
                SYSCALL(exit, 1)

; ----------------------------------------------------------------------------
; Strings and Libraries
; ----------------------------------------------------------------------------

; "Outsourced" code from shell.asm, i.e. this code directly accesses the
; shell.asm environment incl. all variables
#include "options.asm"
#include "strings.asm"
#include "vdrives.asm"

; framework libraries
#include "dirbrowse.asm"
#include "keyboard.asm"
#include "menu.asm"
#include "screen.asm"
#include "tools.asm"
