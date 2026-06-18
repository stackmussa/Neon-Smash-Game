; ============================================================================
; === ITERATION 1: NAMEINP.ASM - Name Input Screen ===
; [Iter1] Allows player to type their name before the game
; Features: Input box UI, character display, backspace, Enter to confirm
; ============================================================================

.DATA

; --- Screen 2: Name Input ---
PLAYER_NAME     DB 15 DUP(0)    ; [Iter1] Player name buffer (max 15 chars)
NAME_LENGTH     DB 0            ; [Iter1] Current name length
NamePrompt      DB 'Enter your name:', 0
ESC_FLAG        DB 0            ; [Iter1] 1 = ESC was pressed (go back)
CLEAR_NAME      DB 1            ; [Iter1] 1 = clear name on next entry

; --- Input box constants ---
C_DARK_GRAY     EQU 08h
INBOX_X         EQU 90
INBOX_Y         EQU 95
INBOX_W         EQU 140
INBOX_H         EQU 16
INBOX_PAD       EQU 4
TEXT_Y          EQU 154
; Pre-computed border rect values (avoids expressions in macro args)
BDR_X           EQU 88
BDR_Y           EQU 93
BDR_W           EQU 144
BDR_H           EQU 20

.CODE

; ============================================================================
; GET_PLAYER_NAME
; [Iter1] Full name input screen with typing, backspace, and Enter handling
; Sets PLAYER_NAME and NAME_LENGTH. ESC_FLAG=1 if cancelled.
; ============================================================================
GET_PLAYER_NAME PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; --- Step 1: Clear screen [Iter1] ---
    CALL FILL_SCREEN_BLUE

    ; [Iter1] Draw neon border frame
    CALL DRAW_BORDER

    ; --- Step 2: Draw title and prompt [Iter1] ---
    CALL DRAW_TITLE

    LEA SI, NamePrompt
    MOV BX, 96
    MOV DX, 130
    MOV AH, C_BRIGHT_YELLOW
    CALL DRAW_STRING

    ; --- Step 3: Draw input box border (cyan) then fill (dark gray) [Iter1] ---
    PUSH_RECT BDR_X, 148, BDR_W, BDR_H, C_CYAN
    PUSH_RECT INBOX_X, 150, INBOX_W, INBOX_H, C_DARK_GRAY

    ; --- Step 4: Conditionally clear or restore name buffer [Iter1] ---
    CMP CLEAR_NAME, 1
    JNE @@NI_KEEP_NAME

    ; Clear name buffer
    MOV NAME_LENGTH, 0
    PUSH BX
    PUSH CX
    XOR BX, BX
    MOV CX, 15
@@NI_CLR_BUF:
    MOV PLAYER_NAME[BX], 0
    INC BX
    LOOP @@NI_CLR_BUF
    POP CX
    POP BX
    MOV CLEAR_NAME, 0
    JMP @@NI_LOOP

@@NI_KEEP_NAME:
    ; Redraw existing name if returning to this screen
    CMP NAME_LENGTH, 0
    JE @@NI_LOOP
    LEA SI, PLAYER_NAME
    MOV BX, 94
    MOV DX, TEXT_Y
    MOV AH, C_WHITE
    CALL DRAW_STRING

    ; --- Step 5: Input loop [Iter1] ---
@@NI_LOOP:
    MOV AH, 00h
    INT 16h                    ; Wait for keypress

    ; [Iter1] ESC -> go back to home screen
    CMP AL, 1Bh
    JNE @@NI_NOT_ESC
    MOV ESC_FLAG, 1
    JMP @@NI_DONE
@@NI_NOT_ESC:

    ; [Iter1] Enter -> confirm name (must have at least 1 char)
    CMP AL, 0Dh
    JNE @@NI_NOT_ENTER
    CMP NAME_LENGTH, 0
    JE @@NI_LOOP               ; Don't accept empty name
    MOV ESC_FLAG, 0
    JMP @@NI_DONE
@@NI_NOT_ENTER:

    ; [Iter1] Backspace handling
    CMP AL, 08h
    JNE @@NI_NOT_BKSP
    JMP @@NI_BACKSPACE
@@NI_NOT_BKSP:

    ; [Iter1] Check buffer full (max 15 chars)
    CMP NAME_LENGTH, 15
    JB @@NI_HAS_SPACE
    JMP @@NI_LOOP
@@NI_HAS_SPACE:

    ; [Iter1] Filter printable ASCII only (20h-7Eh)
    CMP AL, 20h
    JAE @@NI_ABOVE_SPC
    JMP @@NI_LOOP
@@NI_ABOVE_SPC:
    CMP AL, 7Eh
    JBE @@NI_CHAR_OK
    JMP @@NI_LOOP
@@NI_CHAR_OK:

    ; [Iter1] Store character in name buffer
    PUSH BX
    XOR BH, BH
    MOV BL, NAME_LENGTH
    MOV PLAYER_NAME[BX], AL
    POP BX

    ; [Iter1] Draw the character on screen
    PUSH AX

    XOR AH, AH
    MOV AL, NAME_LENGTH
    SHL AX, 1
    SHL AX, 1
    SHL AX, 1                 ; AX = NAME_LENGTH * 8
    ADD AX, INBOX_X
    ADD AX, INBOX_PAD
    MOV BX, AX

    POP AX

    MOV DX, TEXT_Y
    MOV AH, C_WHITE
    CALL DRAW_CHAR

    INC NAME_LENGTH
    JMP @@NI_LOOP

    ; [Iter1] Backspace: erase last character
@@NI_BACKSPACE:
    CMP NAME_LENGTH, 0
    JNE @@NI_DO_BS
    JMP @@NI_LOOP
@@NI_DO_BS:
    DEC NAME_LENGTH

    ; Clear character from buffer
    PUSH BX
    XOR BH, BH
    MOV BL, NAME_LENGTH
    MOV PLAYER_NAME[BX], 0
    POP BX

    ; Erase character from screen (draw dark gray rect over it)
    XOR AH, AH
    MOV AL, NAME_LENGTH
    SHL AX, 1
    SHL AX, 1
    SHL AX, 1
    ADD AX, INBOX_X
    ADD AX, INBOX_PAD
    MOV SI, AX

    MOV AX, C_DARK_GRAY
    PUSH AX
    MOV AX, 8
    PUSH AX
    MOV AX, 8
    PUSH AX
    MOV AX, TEXT_Y
    PUSH AX
    MOV AX, SI
    PUSH AX
    CALL DRAW_RECT

    JMP @@NI_LOOP

@@NI_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
GET_PLAYER_NAME ENDP