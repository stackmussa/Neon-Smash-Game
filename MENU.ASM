; ============================================================================
; === ITERATION 1: MENU.ASM - Main Menu Screen ===
; [Iter1] Main menu with 4 options: Start Game, Instructions, High Scores, Exit
; [Iter1] Keyboard navigation with Up/Down arrows and Enter
; [Iter3/Bonus] Mouse support added for menu navigation
; ============================================================================

.DATA

; --- Screen 3: Main Menu [Iter1] ---
CUR_SEL         DB 0            ; [Iter1] Currently selected menu option (0-3)
MenuHeader      DB 'MAIN MENU', 0
MenuOpt0        DB 'Start Game', 0
MenuOpt1        DB 'Instructions', 0
MenuOpt2        DB 'High Scores', 0
MenuOpt3        DB 'Exit', 0
CursorChr       DB '> ', 0      ; [Iter1] Selection cursor character

; [Iter1] Menu layout constants
MENU_Y0         EQU 80
MENU_Y1         EQU 100
MENU_Y2         EQU 120
MENU_Y3         EQU 140
MENU_TEXT_X     EQU 110
MENU_CUR_X      EQU 96
C_HIGHLIGHT     EQU 0Bh         ; Cyan for selected option
C_NORMAL        EQU 0Fh         ; White for unselected
C_CURSOR        EQU 0Dh         ; Bright magenta cursor

.CODE


; ============================================================================
; DRAW_MENU_OPTION
; [Iter1] Draw a single menu option with highlight if selected
; AL = option index, SI = string, BX = X, DX = Y
; ============================================================================
DRAW_MENU_OPTION PROC NEAR
    PUSH AX
    CMP AL, CUR_SEL
    JNE @@MO_NORMAL
    MOV AH, C_HIGHLIGHT        ; [Iter1] Highlight selected option
    JMP @@MO_DRAW
@@MO_NORMAL:
    MOV AH, C_NORMAL           ; [Iter1] Normal color for unselected
@@MO_DRAW:
    CALL DRAW_STRING
    POP AX
    RET
DRAW_MENU_OPTION ENDP


; ============================================================================
; DRAW_MAIN_MENU
; [Iter1] Full menu screen: draw options, handle keyboard navigation
; [Iter3/Bonus] Added mouse hover and click support
; On return: CUR_SEL = selected option, ESC_FLAG = 1 if ESC pressed
; ============================================================================
DRAW_MAIN_MENU PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV CUR_SEL, 0
    MOV ESC_FLAG, 0

@@MM_DRAW:
    ; [Iter1] Clear and draw menu screen
    CALL FILL_SCREEN_BLUE
    CALL DRAW_BORDER

    ; [Iter1] Menu title
    LEA SI, MenuHeader
    MOV BX, 124
    MOV DX, 30
    MOV AH, C_BRIGHT_YELLOW
    CALL DRAW_STRING

    ; [Iter1] Draw cursor arrow at selected option
    XOR AH, AH
    MOV AL, CUR_SEL
    MOV BL, 20
    MUL BL
    ADD AX, MENU_Y0
    MOV DX, AX
    LEA SI, CursorChr
    MOV BX, MENU_CUR_X
    MOV AH, C_CURSOR
    CALL DRAW_STRING

    ; [Iter1] Draw all 4 menu options
    LEA SI, MenuOpt0
    MOV BX, MENU_TEXT_X
    MOV DX, MENU_Y0
    MOV AL, 0
    CALL DRAW_MENU_OPTION

    LEA SI, MenuOpt1
    MOV BX, MENU_TEXT_X
    MOV DX, MENU_Y1
    MOV AL, 1
    CALL DRAW_MENU_OPTION

    LEA SI, MenuOpt2
    MOV BX, MENU_TEXT_X
    MOV DX, MENU_Y2
    MOV AL, 2
    CALL DRAW_MENU_OPTION

    LEA SI, MenuOpt3
    MOV BX, MENU_TEXT_X
    MOV DX, MENU_Y3
    MOV AL, 3
    CALL DRAW_MENU_OPTION

@@MM_INPUT:
    ; --- [Iter3/Bonus] Mouse support: poll mouse if driver active ---
    CMP BYTE PTR MOUSE_ACTIVE, 0
    JE @@MM_KBD_WAIT

    PUSH DX
    MOV AX, 0003h
    INT 33h                    ; Get mouse position and button state

    ; Check if mouse Y is in menu option zone
    CMP DX, 76
    JL @@MM_MOUSE_OUTSIDE
    CMP DX, 148
    JGE @@MM_MOUSE_OUTSIDE

    ; Calculate which option mouse is over
    SUB DX, 76
    MOV AX, DX
    XOR DX, DX
    PUSH CX
    MOV CX, 20
    DIV CX
    POP CX

    CMP AL, 3
    JBE @@MM_M_CLAMP_OK
    MOV AL, 3
@@MM_M_CLAMP_OK:
    CMP AL, CUR_SEL
    JE @@MM_M_SAME
    MOV CUR_SEL, AL
    POP DX
    JMP @@MM_DRAW              ; Redraw with new highlight

@@MM_M_SAME:
    TEST BX, 1                 ; Left button clicked?
    JZ @@MM_M_NOCLK
    POP DX
    JMP @@MM_DONE              ; Select current option

@@MM_M_NOCLK:
    POP DX
    JMP @@MM_CHK_KBD

@@MM_MOUSE_OUTSIDE:
    POP DX

@@MM_CHK_KBD:
    ; [Iter1] Non-blocking keyboard check (coexists with mouse polling)
    MOV AH, 01h
    INT 16h
    JZ @@MM_INPUT
    MOV AH, 00h
    INT 16h
    JMP @@MM_PROCESS_KEY

@@MM_KBD_WAIT:
    ; [Iter1] Blocking keyboard wait (no mouse driver)
    MOV AH, 00h
    INT 16h

@@MM_PROCESS_KEY:
    ; --- [Iter1] Keyboard processing ---

    ; ESC -> back to home screen
    CMP AL, 1Bh
    JNE @@MM_NOT_ESC
    MOV ESC_FLAG, 1
    JMP @@MM_DONE
@@MM_NOT_ESC:

    ; Enter -> select current option
    CMP AL, 0Dh
    JNE @@MM_NOT_ENTER
    JMP @@MM_DONE
@@MM_NOT_ENTER:

    ; [Iter1] Down arrow -> move selection down (wraps around)
    CMP AH, 50h
    JNE @@MM_NOT_DOWN
    CMP CUR_SEL, 3
    JNE @@MM_DOWN_INC
    MOV CUR_SEL, 0
    JMP @@MM_DRAW
@@MM_DOWN_INC:
    INC CUR_SEL
    JMP @@MM_DRAW
@@MM_NOT_DOWN:

    ; [Iter1] Up arrow -> move selection up (wraps around)
    CMP AH, 48h
    JE @@MM_IS_UP
    JMP @@MM_INPUT
@@MM_IS_UP:
    CMP CUR_SEL, 0
    JNE @@MM_UP_DEC
    MOV CUR_SEL, 3
    JMP @@MM_DRAW
@@MM_UP_DEC:
    DEC CUR_SEL
    JMP @@MM_DRAW

@@MM_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_MAIN_MENU ENDP


; ============================================================================
; === ITERATION 1: EXIT_GAME ===
; [Iter1] Restore text mode and terminate program
; ============================================================================
EXIT_GAME PROC NEAR
    MOV AX, 0003h              ; Restore 80x25 text mode
    INT 10h
    MOV AX, 4C00h              ; DOS terminate
    INT 21h
EXIT_GAME ENDP