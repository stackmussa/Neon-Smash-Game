; ============================================================================
; === ITERATION 1: HISCORE.ASM - High Scores Screen (Static Display Data) ===
; [Iter1] Provides static display strings for the high score screen
; [Iter3] The actual file-based display is in SCORES.ASM (SHOW_HIGH_SCORES_FROM_FILE)
; ============================================================================

.DATA

; --- Screen 5: High Scores [Iter1] ---
HSTitle         DB 'HIGH SCORES', 0

; [Iter1] Column headers
HSColRank       DB 'RANK', 0
HSColName       DB 'NAME', 0
HSColScore      DB 'SCORE', 0

; [Iter1] Rank label strings (used by both static and file-based display)
; Entry 1 - Diamond rank
HS1Rank         DB 'Diamond', 0
HS1Name         DB 'Ahmed', 0
HS1Score        DB '5000', 0

; Entry 2 - Gold rank
HS2Rank         DB 'Gold', 0
HS2Name         DB 'Zain', 0
HS2Score        DB '3500', 0

; Entry 3 - Silver rank
HS3Rank         DB 'Silver', 0
HS3Name         DB 'Nisar', 0
HS3Score        DB '2800', 0

; Entry 4 - Silver rank
HS4Rank         DB 'Silver', 0
HS4Name         DB 'Mussa', 0
HS4Score        DB '1500', 0

; Entry 5 - Silver rank
HS5Rank         DB 'Silver', 0
HS5Name         DB 'Ali', 0
HS5Score        DB '1000', 0

; [Iter1] Footer prompt
HSBack          DB 'PRESS ANY KEY TO RETURN', 0

; [Iter1] Column X positions (aligned for 320px screen)
HS_COL_RANK     EQU 20
HS_COL_NAME     EQU 108
HS_COL_SCORE    EQU 216

; [Iter1] Colors for ranks
C_DIAMOND       EQU 0Bh
C_GOLD          EQU 0Eh
C_SILVER        EQU 07h
C_HEADER_LINE   EQU 09h

.CODE


; ============================================================================
; SHOW_HIGH_SCORES
; [Iter1] Static high score screen with hardcoded dummy data
; NOTE: Superseded by SHOW_HIGH_SCORES_FROM_FILE in SCORES.ASM [Iter3]
; ============================================================================
SHOW_HIGH_SCORES PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    ; --- Step 1: Wipe canvas [Iter1] ---
    CALL FILL_SCREEN_BLUE
    CALL DRAW_BORDER

    ; --- Step 2: Title "HIGH SCORES" centered [Iter1] ---
    LEA SI, HSTitle
    MOV BX, 116
    MOV DX, 12
    MOV AH, C_BRIGHT_YELLOW
    CALL DRAW_STRING

    ; --- Step 3: Column header separator bar [Iter1] ---
    PUSH_RECT 16, 28, 288, 1, C_HEADER_LINE

    ; --- Step 4: Column headers at Y:32 [Iter1] ---
    LEA SI, HSColRank
    MOV BX, HS_COL_RANK
    MOV DX, 34
    MOV AH, C_BRIGHT_YELLOW
    CALL DRAW_STRING

    LEA SI, HSColName
    MOV BX, HS_COL_NAME
    MOV DX, 34
    MOV AH, C_BRIGHT_YELLOW
    CALL DRAW_STRING

    LEA SI, HSColScore
    MOV BX, HS_COL_SCORE
    MOV DX, 34
    MOV AH, C_BRIGHT_YELLOW
    CALL DRAW_STRING

    ; --- Separator under headers [Iter1] ---
    PUSH_RECT 16, 46, 288, 1, C_HEADER_LINE

    ; --- Step 5: Entry 1 - Diamond (Y:54) [Iter1] ---
    LEA SI, HS1Rank
    MOV BX, HS_COL_RANK
    MOV DX, 54
    MOV AH, C_DIAMOND
    CALL DRAW_STRING

    LEA SI, HS1Name
    MOV BX, HS_COL_NAME
    MOV DX, 54
    MOV AH, C_WHITE
    CALL DRAW_STRING

    LEA SI, HS1Score
    MOV BX, HS_COL_SCORE
    MOV DX, 54
    MOV AH, C_WHITE
    CALL DRAW_STRING

    ; --- Entry 2 - Gold (Y:72) [Iter1] ---
    LEA SI, HS2Rank
    MOV BX, HS_COL_RANK
    MOV DX, 72
    MOV AH, C_GOLD
    CALL DRAW_STRING

    LEA SI, HS2Name
    MOV BX, HS_COL_NAME
    MOV DX, 72
    MOV AH, C_WHITE
    CALL DRAW_STRING

    LEA SI, HS2Score
    MOV BX, HS_COL_SCORE
    MOV DX, 72
    MOV AH, C_WHITE
    CALL DRAW_STRING

    ; --- Entry 3 - Silver (Y:90) [Iter1] ---
    LEA SI, HS3Rank
    MOV BX, HS_COL_RANK
    MOV DX, 90
    MOV AH, C_SILVER
    CALL DRAW_STRING

    LEA SI, HS3Name
    MOV BX, HS_COL_NAME
    MOV DX, 90
    MOV AH, C_WHITE
    CALL DRAW_STRING

    LEA SI, HS3Score
    MOV BX, HS_COL_SCORE
    MOV DX, 90
    MOV AH, C_WHITE
    CALL DRAW_STRING

    ; --- Entry 4 - Silver (Y:108) [Iter1] ---
    LEA SI, HS4Rank
    MOV BX, HS_COL_RANK
    MOV DX, 108
    MOV AH, C_SILVER
    CALL DRAW_STRING

    LEA SI, HS4Name
    MOV BX, HS_COL_NAME
    MOV DX, 108
    MOV AH, C_WHITE
    CALL DRAW_STRING

    LEA SI, HS4Score
    MOV BX, HS_COL_SCORE
    MOV DX, 108
    MOV AH, C_WHITE
    CALL DRAW_STRING

    ; --- Entry 5 - Silver (Y:126) [Iter1] ---
    LEA SI, HS5Rank
    MOV BX, HS_COL_RANK
    MOV DX, 126
    MOV AH, C_SILVER
    CALL DRAW_STRING

    LEA SI, HS5Name
    MOV BX, HS_COL_NAME
    MOV DX, 126
    MOV AH, C_WHITE
    CALL DRAW_STRING

    LEA SI, HS5Score
    MOV BX, HS_COL_SCORE
    MOV DX, 126
    MOV AH, C_WHITE
    CALL DRAW_STRING

    ; --- Separator after entries [Iter1] ---
    PUSH_RECT 16, 140, 288, 1, C_HEADER_LINE

    ; --- Step 6: Footer prompt [Iter1] ---
    LEA SI, HSBack
    MOV BX, 68
    MOV DX, 170
    MOV AH, C_BRIGHT_MAG
    CALL DRAW_STRING

    ; --- Step 7: Block until any keypress [Iter1] ---
    MOV AH, 00h
    INT 16h

    POP SI
    POP DX
    POP BX
    POP AX
    RET
SHOW_HIGH_SCORES ENDP