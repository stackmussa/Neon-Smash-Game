; ============================================================================
; === ITERATION 3 / BONUS: SCORES.ASM - File-Based High Score System ===
; [Iter3/Bonus] Provides file handling for persistent high scores
; [Iter3/Bonus] Uses DOS INT 21h for file I/O (open, read, write, close)
; File format: 5 entries, each 20 bytes:
;   Bytes 0-14:  Player name (15 bytes, null-padded)
;   Bytes 15-16: Score (16-bit word, binary)
;   Bytes 17-19: Reserved/padding (3 bytes)
; Total file size: 100 bytes (5 * 20)
; ============================================================================

.DATA

; [Iter3/Bonus] High score file name (now using .TXT extension)
HSFileName      DB 'HISCORE.TXT', 0
HSFileHandle    DW 0

; [Iter3/Bonus] Score table in memory: 5 entries x 20 bytes = 100 bytes
SCORE_TABLE     DB 100 DUP(0)

; Entry size constants
SCORE_ENTRY_SZ  EQU 20
SCORE_NAME_SZ   EQU 15
SCORE_COUNT     EQU 5

; [Iter3] Temp buffer for score-to-string conversion (5 digits + null)
ScoreStrBuf     DB '00000', 0

; [ignoring loop detection]
; [Iter3/Bonus] Flag: 1 = file loaded successfully
SCORES_LOADED   DB 0

.CODE

; ============================================================================
; INIT_DEFAULT_SCORES
; [Iter3/Bonus] Fill SCORE_TABLE with default dummy entries
; Called when HISCORE.TXT doesn't exist yet (first run)
; ============================================================================
INIT_DEFAULT_SCORES PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI

    ; Zero the entire table first
    LEA DI, SCORE_TABLE
    MOV CX, 100
    XOR AL, AL
@@IDS_ZERO:
    MOV [DI], AL
    INC DI
    LOOP @@IDS_ZERO

    ; Entry 0: Ahmed / 200
    LEA DI, SCORE_TABLE
    MOV BYTE PTR [DI+0], 'A'
    MOV BYTE PTR [DI+1], 'h'
    MOV BYTE PTR [DI+2], 'm'
    MOV BYTE PTR [DI+3], 'e'
    MOV BYTE PTR [DI+4], 'd'
    MOV WORD PTR [DI+15], 200

    ; Entry 1: Zain / 150
    ADD DI, SCORE_ENTRY_SZ
    MOV BYTE PTR [DI+0], 'Z'
    MOV BYTE PTR [DI+1], 'a'
    MOV BYTE PTR [DI+2], 'i'
    MOV BYTE PTR [DI+3], 'n'
    MOV WORD PTR [DI+15], 150

    ; Entry 2: Nisar / 100
    ADD DI, SCORE_ENTRY_SZ
    MOV BYTE PTR [DI+0], 'N'
    MOV BYTE PTR [DI+1], 'i'
    MOV BYTE PTR [DI+2], 's'
    MOV BYTE PTR [DI+3], 'a'
    MOV BYTE PTR [DI+4], 'r'
    MOV WORD PTR [DI+15], 100

    ; Entry 3: Mussa / 50
    ADD DI, SCORE_ENTRY_SZ
    MOV BYTE PTR [DI+0], 'M'
    MOV BYTE PTR [DI+1], 'u'
    MOV BYTE PTR [DI+2], 's'
    MOV BYTE PTR [DI+3], 's'
    MOV BYTE PTR [DI+4], 'a'
    MOV WORD PTR [DI+15], 50

    ; Entry 4: Ali / 10
    ADD DI, SCORE_ENTRY_SZ
    MOV BYTE PTR [DI+0], 'A'
    MOV BYTE PTR [DI+1], 'l'
    MOV BYTE PTR [DI+2], 'i'
    MOV WORD PTR [DI+15], 10

    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
INIT_DEFAULT_SCORES ENDP


; ============================================================================
; LOAD_SCORES
; [Iter3/Bonus] Read SCORE_TABLE from HISCORE.TXT using DOS file I/O
; If file doesn't exist, initializes defaults and creates the file
; ============================================================================
LOAD_SCORES PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; [Iter3/Bonus] Open file for reading: INT 21h AH=3Dh, AL=0 (read-only)
    MOV AH, 3Dh
    MOV AL, 00h
    LEA DX, HSFileName
    INT 21h
    JC @@LS_NO_FILE             ; CF=1 means file not found

    MOV HSFileHandle, AX

    ; [Iter3/Bonus] Read 100 bytes into SCORE_TABLE: INT 21h AH=3Fh
    MOV AH, 3Fh
    MOV BX, HSFileHandle
    MOV CX, 100
    LEA DX, SCORE_TABLE
    INT 21h

    ; [Iter3/Bonus] Close file: INT 21h AH=3Eh
    MOV AH, 3Eh
    MOV BX, HSFileHandle
    INT 21h

    MOV BYTE PTR SCORES_LOADED, 1
    JMP @@LS_DONE

@@LS_NO_FILE:
    ; [Iter3/Bonus] No file exists yet - create with defaults
    CALL INIT_DEFAULT_SCORES
    CALL SAVE_SCORES
    MOV BYTE PTR SCORES_LOADED, 1

@@LS_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
LOAD_SCORES ENDP


; ============================================================================
; SAVE_SCORES
; [Iter3/Bonus] Write SCORE_TABLE to HISCORE.TXT using DOS file I/O
; ============================================================================
SAVE_SCORES PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; [Iter3/Bonus] Create/truncate file: INT 21h AH=3Ch, CX=0 (normal attr)
    MOV AH, 3Ch
    XOR CX, CX
    LEA DX, HSFileName
    INT 21h
    JC @@SS_DONE                ; Fail silently if can't create

    MOV HSFileHandle, AX

    ; [Iter3/Bonus] Write 100 bytes from SCORE_TABLE: INT 21h AH=40h
    MOV AH, 40h
    MOV BX, HSFileHandle
    MOV CX, 100
    LEA DX, SCORE_TABLE
    INT 21h

    ; [Iter3/Bonus] Close file: INT 21h AH=3Eh
    MOV AH, 3Eh
    MOV BX, HSFileHandle
    INT 21h

@@SS_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SAVE_SCORES ENDP


; ============================================================================
; COMPARE_NAME_STRINGS
; Helper: Compares DS:SI with DS:DI for exactly 15 bytes.
; Returns: ZF=1 if equal, ZF=0 if different.
; ============================================================================
COMPARE_NAME_STRINGS PROC NEAR
    PUSH CX
    PUSH SI
    PUSH DI
    MOV CX, 15
@@CNS_LOOP:
    MOV AL, [SI]
    MOV AH, [DI]
    CMP AL, AH
    JNE @@CNS_DIFF
    INC SI
    INC DI
    LOOP @@CNS_LOOP
    POP DI
    POP SI
    POP CX
    XOR AX, AX                 ; Set ZF=1
    RET
@@CNS_DIFF:
    POP DI
    POP SI
    POP CX
    OR AX, 1                   ; Clear ZF (ZF=0)
    RET
COMPARE_NAME_STRINGS ENDP


; ============================================================================
; FIND_USER_INDEX
; Searches SCORE_TABLE for an entry matching PLAYER_NAME.
; Returns: AX = entry index (0-4) if found, 0FFFFh if not found.
; ============================================================================
FIND_USER_INDEX PROC NEAR
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    LEA SI, SCORE_TABLE
    MOV CX, 0                  ; CX = current index
@@FUI_LOOP:
    CMP CX, SCORE_COUNT
    JGE @@FUI_NOT_FOUND

    LEA DI, PLAYER_NAME
    CALL COMPARE_NAME_STRINGS
    JZ @@FUI_FOUND             ; ZF=1 means match found

    ADD SI, SCORE_ENTRY_SZ
    INC CX
    JMP @@FUI_LOOP

@@FUI_FOUND:
    MOV AX, CX
    JMP @@FUI_DONE

@@FUI_NOT_FOUND:
    MOV AX, 0FFFFh

@@FUI_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
FIND_USER_INDEX ENDP


; ============================================================================
; SORT_SCORES
; Bubble sorts the 5-entry SCORE_TABLE descending by score (offset +15).
; ============================================================================
SORT_SCORES PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV CX, 4
@@OuterLoop:
    PUSH CX
    LEA SI, SCORE_TABLE
    MOV CX, 4
@@InnerLoop:
    MOV AX, [SI+15]
    MOV BX, [SI+20+15]
    CMP AX, BX
    JAE @@NoSwap

    ; Swap 20-byte entries
    MOV DI, SI
    ADD DI, 20
    PUSH CX
    MOV CX, 20
@@SwapBytes:
    MOV AL, [SI]
    MOV AH, [DI]
    MOV [SI], AH
    MOV [DI], AL
    INC SI
    INC DI
    LOOP @@SwapBytes
    POP CX
    JMP @@NextIteration

@@NoSwap:
    ADD SI, 20
@@NextIteration:
    DEC CX
    JNZ @@InnerLoop

    POP CX
    LOOP @@OuterLoop

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SORT_SCORES ENDP


; ============================================================================
; UPDATE_HIGH_SCORES
; [Iter3/Bonus] Save score: Updates an existing user record OR inserts new
; entry into top 5 if qualified, then re-sorts and saves to HISCORE.TXT.
; ============================================================================
UPDATE_HIGH_SCORES PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    CALL LOAD_SCORES

    ; Skip if player score is 0
    CMP WORD PTR PLAYER_SCORE, 0
    JE @@UHS_DONE

    ; Check if user already exists
    CALL FIND_USER_INDEX
    CMP AX, 0FFFFh
    JE @@UHS_NEW_USER

    ; Existing user: update score in place
    MOV CX, 20
    MUL CL
    LEA SI, SCORE_TABLE
    ADD SI, AX
    MOV DX, WORD PTR PLAYER_SCORE
    MOV [SI+15], DX
    JMP @@UHS_SAVE

@@UHS_NEW_USER:
    ; New user: check if score qualifies (greater than 5th entry score)
    LEA SI, SCORE_TABLE
    ADD SI, 4 * 20
    MOV AX, WORD PTR PLAYER_SCORE
    CMP AX, [SI+15]
    JBE @@UHS_DONE             ; Doesn't qualify

    ; Replace 5th entry
    MOV DI, SI
    MOV CX, 20
    XOR AL, AL
@@UHS_CLR_5TH:
    MOV [DI], AL
    INC DI
    LOOP @@UHS_CLR_5TH

    MOV DI, SI
    LEA BX, PLAYER_NAME
    MOV CX, 15
@@UHS_COPY_NAME:
    MOV AL, [BX]
    MOV [DI], AL
    CMP AL, 0
    JE @@UHS_NAME_DONE
    INC BX
    INC DI
    LOOP @@UHS_COPY_NAME
@@UHS_NAME_DONE:

    MOV AX, WORD PTR PLAYER_SCORE
    MOV [SI+15], AX

@@UHS_SAVE:
    CALL SORT_SCORES
    CALL SAVE_SCORES

@@UHS_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UPDATE_HIGH_SCORES ENDP


; ============================================================================
; CHECK_EXISTING_USER
; Checks if PLAYER_NAME exists in the high scores table.
; If found: loads their previous score into PLAYER_SCORE and returns AX=1.
; If not found: sets PLAYER_SCORE to 0 and returns AX=0.
; ============================================================================
CHECK_EXISTING_USER PROC NEAR
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    CALL LOAD_SCORES

    CALL FIND_USER_INDEX
    CMP AX, 0FFFFh
    JE @@CEU_NOT_FOUND

    ; User found: load score from table
    MOV CX, 20
    MUL CL
    LEA SI, SCORE_TABLE
    ADD SI, AX
    MOV DX, [SI+15]
    MOV WORD PTR PLAYER_SCORE, DX
    MOV AX, 1
    JMP @@CEU_DONE

@@CEU_NOT_FOUND:
    MOV WORD PTR PLAYER_SCORE, 0
    MOV AX, 0

@@CEU_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CHECK_EXISTING_USER ENDP


; ============================================================================
; SCORE_TO_STRING
; [Iter3] Convert a 16-bit score in AX to ScoreStrBuf (5 ASCII digits)
; ============================================================================
SCORE_TO_STRING PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10000
    XOR DX, DX
    DIV BX
    ADD AL, '0'
    MOV BYTE PTR ScoreStrBuf+0, AL

    MOV AX, DX
    MOV BX, 1000
    XOR DX, DX
    DIV BX
    ADD AL, '0'
    MOV BYTE PTR ScoreStrBuf+1, AL

    MOV AX, DX
    MOV BX, 100
    XOR DX, DX
    DIV BX
    ADD AL, '0'
    MOV BYTE PTR ScoreStrBuf+2, AL

    MOV AX, DX
    MOV BX, 10
    XOR DX, DX
    DIV BX
    ADD AL, '0'
    MOV BYTE PTR ScoreStrBuf+3, AL

    ADD DL, '0'
    MOV BYTE PTR ScoreStrBuf+4, DL
    MOV BYTE PTR ScoreStrBuf+5, 0

    POP DX
    POP CX
    POP BX
    POP AX
    RET
SCORE_TO_STRING ENDP


; ============================================================================
; SHOW_HIGH_SCORES_FROM_FILE
; [Iter3/Bonus] Draw high score screen with data loaded from HISCORE.TXT
; ============================================================================
SHOW_HIGH_SCORES_FROM_FILE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    CALL LOAD_SCORES

    CALL FILL_SCREEN_BLUE
    CALL DRAW_BORDER

    LEA SI, HSTitle
    MOV BX, 116
    MOV DX, 12
    MOV AH, C_BRIGHT_YELLOW
    CALL DRAW_STRING

    PUSH_RECT 16, 28, 288, 1, C_HEADER_LINE

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

    PUSH_RECT 16, 46, 288, 1, C_HEADER_LINE

    LEA DI, SCORE_TABLE
    MOV CX, 0
    MOV DX, 54                  ; Starting Y position

@@HSFF_LOOP:
    CMP CX, SCORE_COUNT
    JGE @@HSFF_ENTRIES_DONE

    PUSH DX
    PUSH CX

    CMP CX, 0
    JNE @@HSFF_NOT_1ST
    LEA SI, HS1Rank
    MOV AH, C_DIAMOND
    JMP @@HSFF_DRAW_RANK
@@HSFF_NOT_1ST:
    CMP CX, 1
    JNE @@HSFF_NOT_2ND
    LEA SI, HS2Rank
    MOV AH, C_GOLD
    JMP @@HSFF_DRAW_RANK
@@HSFF_NOT_2ND:
    LEA SI, HS3Rank
    MOV AH, C_SILVER

@@HSFF_DRAW_RANK:
    MOV BX, HS_COL_RANK
    CALL DRAW_STRING

    POP CX
    POP DX

    PUSH DI
    MOV SI, DI
    MOV BX, HS_COL_NAME
    MOV AH, C_WHITE
    CALL DRAW_STRING
    POP DI

    PUSH DI
    MOV AX, [DI+15]
    CALL SCORE_TO_STRING
    LEA SI, ScoreStrBuf
    MOV BX, HS_COL_SCORE
    MOV AH, C_WHITE
    CALL DRAW_STRING
    POP DI

    ADD DI, SCORE_ENTRY_SZ
    ADD DX, 18
    INC CX
    JMP @@HSFF_LOOP

@@HSFF_ENTRIES_DONE:
    PUSH_RECT 16, 148, 288, 1, C_HEADER_LINE

    LEA SI, HSBack
    MOV BX, 68
    MOV DX, 170
    MOV AH, C_BRIGHT_MAG
    CALL DRAW_STRING

    MOV AH, 00h
    INT 16h

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_HIGH_SCORES_FROM_FILE ENDP


; ============================================================================
; PLAY_DEATH_SOUND
; ============================================================================
PLAY_DEATH_SOUND PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 800
    CALL @@PDS_PLAY_TONE

    MOV BX, 400
    CALL @@PDS_PLAY_TONE

    MOV BX, 200
    CALL @@PDS_PLAY_TONE

    IN AL, 61h
    AND AL, 0FCh
    OUT 61h, AL

    POP DX
    POP CX
    POP BX
    POP AX
    RET

@@PDS_PLAY_TONE:
    MOV AL, 0B6h
    OUT 43h, AL

    MOV AX, 34DCh
    MOV DX, 0012h
    DIV BX
    OUT 42h, AL
    MOV AL, AH
    OUT 42h, AL

    IN AL, 61h
    OR AL, 03h
    OUT 61h, AL

    MOV CX, 8
@@PDS_DELAY_OUTER:
    PUSH CX
    MOV CX, 0FFFFh
@@PDS_DELAY_INNER:
    NOP
    LOOP @@PDS_DELAY_INNER
    POP CX
    LOOP @@PDS_DELAY_OUTER
    RET
PLAY_DEATH_SOUND ENDP