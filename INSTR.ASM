; ============================================================================
; === ITERATION 1: INSTR.ASM - Instructions Screen ===
; [Iter1] Displays game controls and rules to the player
; ============================================================================

.DATA

; --- Screen 4: Instructions [Iter1] ---
InstrTitle      DB 'INSTRUCTIONS', 0
InstrLine1      DB 'CONTROLS: L/R ARROWS OR A/D', 0
InstrLine2      DB 'OBJECTIVE: BREAK ALL BRICKS', 0
InstrLine3      DB 'LIVES: YOU START WITH 3', 0
InstrLine4      DB 'BONUSES: CATCH FALLING ITEMS', 0
InstrBack       DB 'PRESS ANY KEY TO RETURN', 0

; Layout constants
INSTR_TITLE_X   EQU 112
INSTR_BODY_X    EQU 20
INSTR_BACK_X    EQU 68

.CODE


; ============================================================================
; SHOW_INSTRUCTIONS
; [Iter1] Draw instructions screen with controls, rules, and bonus info
; ============================================================================
SHOW_INSTRUCTIONS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    ; --- Step 1: Wipe canvas [Iter1] ---
    CALL FILL_SCREEN_BLUE
    CALL DRAW_BORDER

    ; --- Step 2: Header "INSTRUCTIONS" in bright yellow [Iter1] ---
    LEA SI, InstrTitle
    MOV BX, INSTR_TITLE_X
    MOV DX, 15
    MOV AH, C_BRIGHT_YELLOW
    CALL DRAW_STRING

    ; --- Step 3: Body lines in white, Y spaced by 20px [Iter1] ---
    LEA SI, InstrLine1
    MOV BX, INSTR_BODY_X
    MOV DX, 40
    MOV AH, C_WHITE
    CALL DRAW_STRING

    LEA SI, InstrLine2
    MOV BX, INSTR_BODY_X
    MOV DX, 60
    MOV AH, C_WHITE
    CALL DRAW_STRING

    LEA SI, InstrLine3
    MOV BX, INSTR_BODY_X
    MOV DX, 80
    MOV AH, C_WHITE
    CALL DRAW_STRING

    LEA SI, InstrLine4
    MOV BX, INSTR_BODY_X
    MOV DX, 100
    MOV AH, C_WHITE
    CALL DRAW_STRING

    ; --- Step 4: Footer prompt in bright magenta [Iter1] ---
    LEA SI, InstrBack
    MOV BX, INSTR_BACK_X
    MOV DX, 170
    MOV AH, C_BRIGHT_MAG
    CALL DRAW_STRING

    ; --- Step 5: Block until any keypress [Iter1] ---
    MOV AH, 00h
    INT 16h

    POP SI
    POP DX
    POP BX
    POP AX
    RET
SHOW_INSTRUCTIONS ENDP