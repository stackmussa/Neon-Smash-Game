; ============================================================================
; === ITERATION 3: LVLSEL.ASM - Level Selection Screen ===
; [Iter3] Lets the player pick a starting level (1, 2, or 3) before game
; [Iter3] Sets SELECTED_LEVEL which INIT_GAME reads as the starting level
; [Iter3] ESC returns to main menu (sets ESC_FLAG = 1)
; ============================================================================

.DATA

; --- Level Selection Data [Iter3] ---
SELECTED_LEVEL  DB 1            ; [Iter3] Chosen level (1-3)
LVL_SEL_CUR     DB 0            ; [Iter3] Cursor index (0=L1, 1=L2, 2=L3)

LvlSelTitle     DB 'SELECT LEVEL', 0

LvlOpt1         DB 'Level 1 - Classic', 0
LvlOpt1Desc     DB 'Standard bricks, normal speed', 0

LvlOpt2         DB 'Level 2 - Faster!', 0
LvlOpt2Desc     DB 'Checker pattern, fast ball', 0

LvlOpt3         DB 'Level 3 - Max Speed!', 0
LvlOpt3Desc     DB 'Fortress bricks, blazing fast', 0

LvlSelBack      DB 'ESC: Back   ENTER: Play', 0

; Level selection arrow
LvlCursorChr    DB '> ', 0

; Layout constants for level select
LVL_TITLE_X     EQU 108
LVL_TITLE_Y     EQU 18
LVL_OPT_X       EQU 90
LVL_CUR_X       EQU 72
LVL_DESC_X      EQU 60
LVL_Y0          EQU 55
LVL_Y1          EQU 95
LVL_Y2          EQU 135
LVL_SPACING     EQU 40
LVL_DESC_OFF    EQU 14

; Colors
C_LVL_NORMAL    EQU 0Fh         ; White for unselected
C_LVL_HIGHLIGHT EQU 0Bh         ; Cyan for selected
C_LVL_DESC      EQU 07h         ; Gray for description text
C_LVL_CURSOR    EQU 0Dh         ; Bright magenta cursor

.CODE

; ============================================================================
; SHOW_LEVEL_SELECT
; [Iter3] Draw the level selection screen and wait for player's choice
; On return: SELECTED_LEVEL = 1/2/3, or ESC_FLAG = 1 if cancelled
; ============================================================================
SHOW_LEVEL_SELECT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV BYTE PTR LVL_SEL_CUR, 0
    MOV BYTE PTR ESC_FLAG, 0

@@LV_DRAW:
    ; --- Clear screen ---
    CALL FILL_SCREEN_BLUE
    CALL DRAW_BORDER

    ; --- Title ---
    LEA SI, LvlSelTitle
    MOV BX, LVL_TITLE_X
    MOV DX, LVL_TITLE_Y
    MOV AH, C_BRIGHT_YELLOW
    CALL DRAW_STRING

    ; --- Decorative separator under title ---
    PUSH_RECT 16, 32, 288, 1, C_HEADER_LINE

    ; --- Draw cursor arrow at selected option ---
    XOR AH, AH
    MOV AL, BYTE PTR LVL_SEL_CUR
    MOV BL, LVL_SPACING
    MUL BL
    ADD AX, LVL_Y0
    MOV DX, AX
    LEA SI, LvlCursorChr
    MOV BX, LVL_CUR_X
    MOV AH, C_LVL_CURSOR
    CALL DRAW_STRING

    ; --- Level 1 Option ---
    LEA SI, LvlOpt1
    MOV BX, LVL_OPT_X
    MOV DX, LVL_Y0
    MOV AL, 0
    CMP AL, BYTE PTR LVL_SEL_CUR
    JNE @@LV_OPT1_NORM
    MOV AH, C_LVL_HIGHLIGHT
    JMP @@LV_OPT1_DRW
@@LV_OPT1_NORM:
    MOV AH, C_LVL_NORMAL
@@LV_OPT1_DRW:
    CALL DRAW_STRING

    ; Level 1 description
    LEA SI, LvlOpt1Desc
    MOV BX, LVL_DESC_X
    MOV DX, LVL_Y0
    ADD DX, LVL_DESC_OFF
    MOV AH, C_LVL_DESC
    CALL DRAW_STRING

    ; --- Separator ---
    PUSH_RECT 40, 83, 240, 1, 08h

    ; --- Level 2 Option ---
    LEA SI, LvlOpt2
    MOV BX, LVL_OPT_X
    MOV DX, LVL_Y1
    MOV AL, 1
    CMP AL, BYTE PTR LVL_SEL_CUR
    JNE @@LV_OPT2_NORM
    MOV AH, C_LVL_HIGHLIGHT
    JMP @@LV_OPT2_DRW
@@LV_OPT2_NORM:
    MOV AH, C_LVL_NORMAL
@@LV_OPT2_DRW:
    CALL DRAW_STRING

    ; Level 2 description
    LEA SI, LvlOpt2Desc
    MOV BX, LVL_DESC_X
    MOV DX, LVL_Y1
    ADD DX, LVL_DESC_OFF
    MOV AH, C_LVL_DESC
    CALL DRAW_STRING

    ; --- Separator ---
    PUSH_RECT 40, 123, 240, 1, 08h

    ; --- Level 3 Option ---
    LEA SI, LvlOpt3
    MOV BX, LVL_OPT_X
    MOV DX, LVL_Y2
    MOV AL, 2
    CMP AL, BYTE PTR LVL_SEL_CUR
    JNE @@LV_OPT3_NORM
    MOV AH, C_LVL_HIGHLIGHT
    JMP @@LV_OPT3_DRW
@@LV_OPT3_NORM:
    MOV AH, C_LVL_NORMAL
@@LV_OPT3_DRW:
    CALL DRAW_STRING

    ; Level 3 description
    LEA SI, LvlOpt3Desc
    MOV BX, LVL_DESC_X
    MOV DX, LVL_Y2
    ADD DX, LVL_DESC_OFF
    MOV AH, C_LVL_DESC
    CALL DRAW_STRING

    ; --- Bottom separator ---
    PUSH_RECT 16, 163, 288, 1, C_HEADER_LINE

    ; --- Footer prompt ---
    LEA SI, LvlSelBack
    MOV BX, 76
    MOV DX, 175
    MOV AH, C_BRIGHT_MAG
    CALL DRAW_STRING

    ; --- Decorative bricks on sides ---
    PUSH_RECT 10, 50, 12, 6, C_CYAN
    PUSH_RECT 10, 90, 12, 6, 0Eh
    PUSH_RECT 10, 130, 12, 6, C_CYAN
    PUSH_RECT 298, 50, 12, 6, C_CYAN
    PUSH_RECT 298, 90, 12, 6, 0Eh
    PUSH_RECT 298, 130, 12, 6, C_CYAN

; ---- Input loop ----
@@LV_INPUT:
    ; --- Mouse support ---
    CMP BYTE PTR MOUSE_ACTIVE, 0
    JE @@LV_KBD_WAIT

    PUSH DX
    MOV AX, 0003h
    INT 33h                     ; BX=buttons, CX=x, DX=y

    ; Check if mouse Y is in any option zone
    CMP DX, 50
    JL @@LV_MOUSE_OUT
    CMP DX, 155
    JGE @@LV_MOUSE_OUT

    ; Determine which option based on Y
    SUB DX, 50
    MOV AX, DX
    XOR DX, DX
    PUSH CX
    MOV CX, LVL_SPACING
    DIV CX
    POP CX

    CMP AL, 2
    JBE @@LV_M_CLAMP_OK
    MOV AL, 2
@@LV_M_CLAMP_OK:
    CMP AL, BYTE PTR LVL_SEL_CUR
    JE @@LV_M_SAME
    MOV BYTE PTR LVL_SEL_CUR, AL
    POP DX
    JMP @@LV_DRAW

@@LV_M_SAME:
    TEST BX, 1                  ; left button clicked?
    JZ @@LV_M_NOCLK
    POP DX
    JMP @@LV_SELECTED

@@LV_M_NOCLK:
    POP DX
    JMP @@LV_CHK_KBD

@@LV_MOUSE_OUT:
    POP DX

@@LV_CHK_KBD:
    MOV AH, 01h
    INT 16h
    JZ @@LV_INPUT
    MOV AH, 00h
    INT 16h
    JMP @@LV_PROCESS_KEY

@@LV_KBD_WAIT:
    MOV AH, 00h
    INT 16h

@@LV_PROCESS_KEY:
    ; --- ESC -> back to menu ---
    CMP AL, 1Bh
    JNE @@LV_NOT_ESC
    MOV BYTE PTR ESC_FLAG, 1
    JMP @@LV_DONE
@@LV_NOT_ESC:

    ; --- Enter -> select ---
    CMP AL, 0Dh
    JNE @@LV_NOT_ENTER
    JMP @@LV_SELECTED
@@LV_NOT_ENTER:

    ; --- Down arrow ---
    CMP AH, 50h
    JNE @@LV_NOT_DOWN
    CMP BYTE PTR LVL_SEL_CUR, 2
    JNE @@LV_DOWN_INC
    MOV BYTE PTR LVL_SEL_CUR, 0
    JMP @@LV_DRAW
@@LV_DOWN_INC:
    INC BYTE PTR LVL_SEL_CUR
    JMP @@LV_DRAW
@@LV_NOT_DOWN:

    ; --- Up arrow ---
    CMP AH, 48h
    JE @@LV_IS_UP
    JMP @@LV_INPUT               ; ignore other keys
@@LV_IS_UP:
    CMP BYTE PTR LVL_SEL_CUR, 0
    JNE @@LV_UP_DEC
    MOV BYTE PTR LVL_SEL_CUR, 2
    JMP @@LV_DRAW
@@LV_UP_DEC:
    DEC BYTE PTR LVL_SEL_CUR
    JMP @@LV_DRAW

@@LV_SELECTED:
    ; Convert cursor index (0-2) to level (1-3)
    MOV AL, BYTE PTR LVL_SEL_CUR
    INC AL
    MOV BYTE PTR SELECTED_LEVEL, AL
    MOV BYTE PTR ESC_FLAG, 0

@@LV_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_LEVEL_SELECT ENDP
