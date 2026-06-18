.MODEL SMALL
.STACK 256

.DATA

; === ITERATION 1: Screen Constants ===
; [Iter1] VGA Mode 13h = 320x200, 256 colors, linear framebuffer at A000h
SCREEN_W        EQU 320
SCREEN_H        EQU 200
VIDEO_SEG       EQU 0A000h

; === ITERATION 1: Color Palette ===
; [Iter1] Default VGA 16-color indices used throughout all screens
C_DEEP_BLUE     EQU 01h
C_RED           EQU 04h
C_DARK_PURPLE   EQU 05h
C_LIGHT_GREEN   EQU 0Ah
C_CYAN          EQU 0Bh
C_BRIGHT_MAG    EQU 0Dh
C_BRIGHT_YELLOW EQU 0Eh
C_WHITE         EQU 0Fh

; === ITERATION 1: BIOS Font pointer ===
; [Iter1] Saved at init for text rendering via INT 43h vector
fontSeg         DW 0
fontOff         DW 0

; === ITERATION 1: Home Screen ===
; [Iter1] Prompt string for home screen breathing animation
PromptStr       DB 'Press any key to continue', 0

; [Iter1] Breathing animation color cycle: white->gray->dark->gray
BreathColors    DB 0Fh, 07h, 08h, 07h
BREATH_IDX      DB 0


; === ITERATION 1: Letter Data Tables ===
; [Iter1] Pixel-art letter definitions for "NEON SMASH" title
; Each letter is 20px wide x 20px tall, built from 4px blocks
; Format: dx, dy, w, h quads; FFh = end sentinel

LetN  DB  0,0,4,20,  16,0,4,20,  4,4,4,4,  8,8,4,4,  12,12,4,4, 0FFh
LetE  DB  0,0,4,20,  4,0,16,4,   4,8,12,4,  4,16,16,4, 0FFh
LetO  DB  0,0,4,20,  16,0,4,20,  4,0,12,4,  4,16,12,4, 0FFh
LetS  DB  0,0,20,4,  0,4,4,4,    0,8,20,4,  16,12,4,4, 0,16,20,4, 0FFh
LetM  DB  0,0,4,20,  16,0,4,20,  4,0,12,4,  4,4,4,4,   12,4,4,4
      DB  8,8,4,4,   0FFh
LetA  DB  0,4,4,16,  16,4,4,16,  4,0,12,4,  4,8,12,4,  0FFh
LetH  DB  0,0,4,20,  16,0,4,20,  4,8,12,4,  0FFh

.CODE


; ============================================================================
; === ITERATION 1: DRAW_RECT ===
; [Iter1] Core rectangle drawing procedure used by all screens
; Draws a filled rectangle in VGA Mode 13h video memory
; Parameters passed on stack: X, Y, Width, Height, Color
; ============================================================================
DRAW_RECT PROC NEAR
    PUSH BP
    MOV BP, SP
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    ; DI = Y * 320 + X (calculate video memory offset)
    MOV AX, [BP+6]         ; Y
    MOV BX, SCREEN_W
    MUL BX
    ADD AX, [BP+4]         ; + X
    MOV DI, AX

    MOV DX, [BP+10]        ; height (row counter)
    MOV BX, [BP+8]         ; width
    MOV AL, BYTE PTR [BP+12] ; color

    TEST DX, DX
    JZ @@RDone
    TEST BX, BX
    JZ @@RDone

@@RRow:
    PUSH DI
    MOV CX, BX
    REP STOSB              ; fill one row
    POP DI
    ADD DI, SCREEN_W       ; next row
    DEC DX
    JNZ @@RRow

@@RDone:
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    POP BP
    RET 10                 ; clean 5 words (10 bytes) from stack
DRAW_RECT ENDP


; === ITERATION 1: PUSH_RECT Macro ===
; [Iter1] Helper macro to push parameters and call DRAW_RECT
PUSH_RECT MACRO xv, yv, wv, hv, cv
    MOV AX, cv
    PUSH AX
    MOV AX, hv
    PUSH AX
    MOV AX, wv
    PUSH AX
    MOV AX, yv
    PUSH AX
    MOV AX, xv
    PUSH AX
    CALL DRAW_RECT
ENDM


; ============================================================================
; === ITERATION 1: DRAW_LETTER ===
; [Iter1] Draws a pixel-art letter from data tables (dx,dy,w,h quads)
; Parameters on stack: X, Y, Color; SI = letter data pointer
; ============================================================================
DRAW_LETTER PROC NEAR
    PUSH BP
    MOV BP, SP
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

@@LLoop:
    CMP BYTE PTR [SI], 0FFh
    JE  @@LDone

    ; Push color
    MOV AX, [BP+8]
    PUSH AX

    ; Push height
    XOR AH, AH
    MOV AL, [SI+3]
    PUSH AX

    ; Push width
    XOR AH, AH
    MOV AL, [SI+2]
    PUSH AX

    ; Push Y = baseY + dy
    XOR AH, AH
    MOV AL, [SI+1]
    ADD AX, [BP+6]
    PUSH AX

    ; Push X = baseX + dx
    XOR AH, AH
    MOV AL, [SI]
    ADD AX, [BP+4]
    PUSH AX

    CALL DRAW_RECT

    ADD SI, 4
    JMP @@LLoop

@@LDone:
    POP SI
    POP CX
    POP BX
    POP AX
    POP BP
    RET 6
DRAW_LETTER ENDP


; === ITERATION 1: CALL_LETTER Macro ===
; [Iter1] Helper macro to call DRAW_LETTER with letter data pointer
CALL_LETTER MACRO dataPtr, xv, yv, cv
    LEA SI, dataPtr
    MOV AX, cv
    PUSH AX
    MOV AX, yv
    PUSH AX
    MOV AX, xv
    PUSH AX
    CALL DRAW_LETTER
ENDM


; ============================================================================
; === ITERATION 1: DRAW_BACKGROUND ===
; [Iter1] Deep blue fill with dark purple scanlines every 10 rows
; Creates the neon aesthetic background used on home screen and menus
; ============================================================================
DRAW_BACKGROUND PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    CLD
    XOR DI, DI
    XOR DX, DX

@@BGRow:
    CMP DX, SCREEN_H
    JAE @@BGDone

    ; Scanline effect: every 10th row is dark purple
    MOV AX, DX
    PUSH DX
    XOR DX, DX
    MOV BX, 10
    DIV BX
    MOV BX, DX
    POP DX

    CMP BX, 0
    JNE @@BGNormal
    MOV AL, C_DARK_PURPLE
    JMP @@BGFill
@@BGNormal:
    MOV AL, C_DEEP_BLUE
@@BGFill:
    MOV CX, SCREEN_W
    REP STOSB

    INC DX
    JMP @@BGRow

@@BGDone:
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_BACKGROUND ENDP


; ============================================================================
; === ITERATION 1: DRAW_BORDER ===
; [Iter1] 2-pixel thick bright magenta border frame (X:2..317, Y:2..197)
; ============================================================================
DRAW_BORDER PROC NEAR
    PUSH AX

    PUSH_RECT 2, 2, 316, 2, C_BRIGHT_MAG       ; Top bar
    PUSH_RECT 2, 196, 316, 2, C_BRIGHT_MAG      ; Bottom bar
    PUSH_RECT 2, 4, 2, 192, C_BRIGHT_MAG        ; Left bar
    PUSH_RECT 316, 4, 2, 192, C_BRIGHT_MAG      ; Right bar

    POP AX
    RET
DRAW_BORDER ENDP


; ============================================================================
; === ITERATION 1: DRAW_TITLE ===
; [Iter1] Draw "NEON SMASH" in blocky pixel-art letters
; Yellow (0Eh) with Red (04h) drop shadow offset by +2,+2
; "NEON" at Y=30 centered,  "SMASH" at Y=60 centered
; ============================================================================
DRAW_TITLE PROC NEAR
    PUSH AX
    PUSH SI

    ;=== SHADOW pass (Red, offset +2,+2) ===
    CALL_LETTER LetN, 116, 32, C_RED
    CALL_LETTER LetE, 140, 32, C_RED
    CALL_LETTER LetO, 164, 32, C_RED
    CALL_LETTER LetN, 188, 32, C_RED

    CALL_LETTER LetS, 104, 62, C_RED
    CALL_LETTER LetM, 128, 62, C_RED
    CALL_LETTER LetA, 152, 62, C_RED
    CALL_LETTER LetS, 176, 62, C_RED
    CALL_LETTER LetH, 200, 62, C_RED

    ;=== MAIN pass (Bright Yellow) ===
    CALL_LETTER LetN, 114, 30, C_BRIGHT_YELLOW
    CALL_LETTER LetE, 138, 30, C_BRIGHT_YELLOW
    CALL_LETTER LetO, 162, 30, C_BRIGHT_YELLOW
    CALL_LETTER LetN, 186, 30, C_BRIGHT_YELLOW

    CALL_LETTER LetS, 102, 60, C_BRIGHT_YELLOW
    CALL_LETTER LetM, 126, 60, C_BRIGHT_YELLOW
    CALL_LETTER LetA, 150, 60, C_BRIGHT_YELLOW
    CALL_LETTER LetS, 174, 60, C_BRIGHT_YELLOW
    CALL_LETTER LetH, 198, 60, C_BRIGHT_YELLOW

    POP SI
    POP AX
    RET
DRAW_TITLE ENDP


; ============================================================================
; === ITERATION 1: DRAW_BRICKS (Decorative) ===
; [Iter1] 3 decorative bricks per side on home screen (18x8), Cyan and Green
; ============================================================================
DRAW_BRICKS PROC NEAR
    PUSH AX

    ; Left side bricks
    PUSH_RECT  20, 35, 18, 8, C_CYAN
    PUSH_RECT  45, 50, 18, 8, C_LIGHT_GREEN
    PUSH_RECT  20, 68, 18, 8, C_CYAN

    ; Right side bricks (mirrored)
    PUSH_RECT 282, 35, 18, 8, C_CYAN
    PUSH_RECT 257, 50, 18, 8, C_LIGHT_GREEN
    PUSH_RECT 282, 68, 18, 8, C_CYAN

    POP AX
    RET
DRAW_BRICKS ENDP


; ============================================================================
; === ITERATION 1: INIT_FONT ===
; [Iter1] Save the BIOS 8x8 font pointer from INT 43h vector
; Must be called AFTER setting Mode 13h
; ============================================================================
INIT_FONT PROC NEAR
    PUSH AX
    PUSH ES

    XOR AX, AX
    MOV ES, AX
    MOV AX, ES:[010Ch]     ; font offset from IVT
    MOV fontOff, AX
    MOV AX, ES:[010Eh]     ; font segment from IVT
    MOV fontSeg, AX

    POP ES
    POP AX
    RET
INIT_FONT ENDP


; ============================================================================
; === ITERATION 1: DRAW_CHAR ===
; [Iter1] Draw a single 8x8 BIOS font character at (BX,DX) with color AH
; Reads font bitmap, copies to stack, renders pixel-by-pixel
; ============================================================================
DRAW_CHAR PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI
    PUSH DS
    PUSH BP

    ; Save color in CH
    MOV CH, AH

    ; Calculate font bitmap source: fontSeg:fontOff + char*8
    XOR AH, AH
    SHL AX, 1
    SHL AX, 1
    SHL AX, 1              ; AX = char * 8
    ADD AX, fontOff
    MOV SI, AX
    MOV AX, fontSeg

    ; Copy 8 font bytes to stack (local buffer)
    SUB SP, 8
    MOV BP, SP
    PUSH ES
    MOV ES, AX
    MOV CL, 0
@@CopyFont:
    MOV AL, ES:[SI]
    MOV SS:[BP], AL
    INC SI
    INC BP
    INC CL
    CMP CL, 8
    JB @@CopyFont
    POP ES                  ; restore ES = A000h

    MOV BP, SP

    ; Calculate video offset: DI = Y*320 + X
    MOV AX, DX
    MOV DI, 320
    MUL DI
    ADD AX, BX
    MOV DI, AX

    ; Draw 8 rows from stack buffer
    MOV DX, 8
@@CRow:
    MOV AL, SS:[BP]
    INC BP
    MOV CL, 8
    PUSH DI
@@CBit:
    TEST AL, 80h             ; check leftmost bit
    JZ @@CSkip
    MOV ES:[DI], CH          ; plot pixel with color
@@CSkip:
    SHL AL, 1
    INC DI
    DEC CL
    JNZ @@CBit

    POP DI
    ADD DI, 320              ; next row
    DEC DX
    JNZ @@CRow

    ADD SP, 8                ; clean stack buffer

    POP BP
    POP DS
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_CHAR ENDP


; ============================================================================
; === ITERATION 1: DRAW_STRING ===
; [Iter1] Draw a null-terminated string at (BX,DX) with color AH
; SI = pointer to string. Advances X by 8px per character.
; ============================================================================
DRAW_STRING PROC NEAR
    PUSH AX
    PUSH BX
    PUSH SI

@@SLoop:
    MOV AL, [SI]
    CMP AL, 0
    JE  @@SDone

    PUSH AX
    CALL DRAW_CHAR
    POP AX
    ADD BX, 8              ; advance X by 8 pixels (char width)
    INC SI
    JMP @@SLoop

@@SDone:
    POP SI
    POP BX
    POP AX
    RET
DRAW_STRING ENDP


; ============================================================================
; === ITERATION 1: FILL_SCREEN_BLUE ===
; [Iter1] Convenience wrapper - fills screen with neon background
; ============================================================================
FILL_SCREEN_BLUE PROC NEAR
    CALL DRAW_BACKGROUND
    RET
FILL_SCREEN_BLUE ENDP


; ============================================================================
; Include external modules
; ============================================================================
; [Iter1] NAMEINP.ASM  - Name input screen
; [Iter1] INSTR.ASM    - Instructions screen
; [Iter1] HISCORE.ASM  - High scores screen (static display data)
; [Iter3] BONUS.ASM    - Power-up / bonus system
; [Iter3] SCORES.ASM   - File-based high score persistence (HISCORE.DAT)
; [Iter3] LVLSEL.ASM   - Level selection screen (choose Level 1/2/3)
; [Iter2] GAME.ASM     - Game engine (ball, paddle, bricks, collisions, HUD)
; [Iter1] MENU.ASM     - Main menu with keyboard/mouse navigation

INCLUDE NAMEINP.ASM
INCLUDE INSTR.ASM
INCLUDE HISCORE.ASM
INCLUDE BONUS.ASM
INCLUDE SCORES.ASM
INCLUDE LVLSEL.ASM
INCLUDE GAME.ASM
INCLUDE MENU.ASM


; ============================================================================
; === ITERATION 1: SHOW_HOME_SCREEN ===
; [Iter1] Draw the complete home screen (static elements only)
; ============================================================================
SHOW_HOME_SCREEN PROC NEAR
    CALL DRAW_BACKGROUND
    CALL DRAW_BORDER
    CALL DRAW_BRICKS
    CALL DRAW_TITLE
    RET
SHOW_HOME_SCREEN ENDP


; ============================================================================
; === ITERATION 1: MAIN ===
; [Iter1] Program entry point - initializes hardware, drives screen flow
; [Iter2] Added game launch from menu
; [Iter3] Added level selection before game, file-based high scores
; ============================================================================
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    ; [Iter1] Enter VGA Mode 13h (320x200, 256 colors)
    MOV AX, 0013h
    INT 10h

    ; [Iter1] Set ES to video memory segment
    MOV AX, VIDEO_SEG
    MOV ES, AX

    ; [Iter1] Save BIOS font pointer (must be done AFTER setting mode 13h)
    CALL INIT_FONT

    ; [Iter3/Bonus] Initialize mouse driver
    CALL INIT_MOUSE

    ; === Screen 1: Home Screen [Iter1] ===
@@SCREEN_HOME:
    CALL SHOW_HOME_SCREEN

    ; [Iter1] Breathing animation on "Press any key to continue"
    MOV BREATH_IDX, 0
@@HOME_BREATHE:
    XOR BH, BH
    MOV BL, BREATH_IDX
    MOV AH, BreathColors[BX]

    LEA SI, PromptStr
    MOV BX, 60
    MOV DX, 170
    CALL DRAW_STRING

    ; [Iter1] Delay loop (~150ms at DOSBox default speed)
    PUSH CX
    MOV CX, 6
@@BD_OUTER:
    PUSH CX
    XOR CX, CX
@@BD_INNER:
    LOOP @@BD_INNER
    POP CX
    LOOP @@BD_OUTER
    POP CX

    ; [Iter1] Non-blocking key check
    MOV AH, 01h
    INT 16h
    JNZ @@HOME_KEY_HIT

    ; Advance breathing frame
    INC BREATH_IDX
    CMP BREATH_IDX, 4
    JB @@HOME_BREATHE
    MOV BREATH_IDX, 0
    JMP @@HOME_BREATHE

@@HOME_KEY_HIT:
    ; Consume the keypress
    MOV AH, 00h
    INT 16h
    CMP AL, 1Bh
    JNE @@NOT_ESC_HOME
    JMP @@EXIT_PROG
@@NOT_ESC_HOME:

    ; === Screen 2: Name Input [Iter1] ===
    CALL GET_PLAYER_NAME
    CMP ESC_FLAG, 1
    JNE @@GOTO_MENU
    JMP @@SCREEN_HOME
@@GOTO_MENU:

    ; === Screen 3: Main Menu [Iter1] ===
@@SCREEN_MENU:
    CALL DRAW_MAIN_MENU

    ; ESC on menu -> back to home
    CMP ESC_FLAG, 1
    JNE @@MENU_ROUTE
    JMP @@SCREEN_HOME
@@MENU_ROUTE:

    ; --- Route based on CUR_SEL ---

    ; [Iter2] Option 0: Start Game
    ; [Iter3] Now goes through Level Selection screen first
    CMP CUR_SEL, 0
    JNE @@NOT_START
    CALL SHOW_LEVEL_SELECT             ; [Iter3] Level selection screen
    CMP ESC_FLAG, 1
    JE @@SCREEN_MENU                   ; ESC on level select -> back to menu
    CALL SHOW_GAME_SCREEN              ; [Iter2] Launch the game
    MOV CLEAR_NAME, 1
    JMP @@SCREEN_MENU
@@NOT_START:

    ; [Iter1] Option 1: Instructions
    CMP CUR_SEL, 1
    JNE @@NOT_INSTR
    CALL SHOW_INSTRUCTIONS
    JMP @@SCREEN_MENU
@@NOT_INSTR:

    ; [Iter1] Option 2: High Scores (from file [Iter3])
    CMP CUR_SEL, 2
    JNE @@NOT_HISCORE
    CALL SHOW_HIGH_SCORES_FROM_FILE    ; [Iter3] File-based high scores
    JMP @@SCREEN_MENU
@@NOT_HISCORE:

    ; [Iter1] Option 3: Exit
@@EXIT_PROG:
    CALL EXIT_GAME
MAIN ENDP

END MAIN