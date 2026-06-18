; ============================================================================
; === ITERATION 3: BONUS.ASM - Power-Up / Bonus System ===
; [Iter3] Implements random bonus drops when bricks are broken
; [Iter3] 4 bonus types: Slow Ball, Extra Life, Wide Paddle, Fast Ball
; [Iter3] Bonuses fall toward paddle, collected on contact
; ============================================================================

.DATA

; === ITERATION 3: Power-up system ===
; [Iter3] Types: 0=none 1=SlowBall 2=ExtraLife 3=WidePaddle 4=FastBall
BONUS_ACTIVE    DB 0            ; [Iter3] 1 = a bonus is currently falling
BONUS_TYPE      DB 0            ; [Iter3] Which bonus type (1-4)
BONUS_X         DW 0            ; [Iter3] Bonus tile X position
BONUS_Y         DW 0            ; [Iter3] Bonus tile Y position
BONUS_PREV_Y    DW 0            ; [Iter3] Previous Y for erase
BONUS_SPEED     DW 2            ; [Iter3] Fall speed (pixels per frame)
BONUS_TIMER     DW 0            ; [Iter3] Effect duration counter (frames)
BONUS_EFFECT    DB 0            ; [Iter3] Currently applied effect (0=none)
BONUSES_SPAWNED DB 0            ; [Iter3] Total bonuses spawned this level (cap)
LIVES_SPAWNED   DB 0            ; [Iter3] Extra life bonuses spawned (cap)

; [Iter3] RNG seed (simple Linear Congruential Generator)
RNG_SEED        DW 12345

; [Iter3] Bonus color table (indexed by type 1-4) - bright neon colors
BonusColors     DB 00h, 0Fh, 0Dh, 0Eh, 04h
;                   0    1=Wht 2=BMag 3=Yel 4=Red
BonusSizeW      EQU 16          ; [Iter3] Bonus tile width
BonusSizeH      EQU 10          ; [Iter3] Bonus tile height

; [Iter3] Bonus label characters (drawn inside tile)
BonusChars      DB '?', 'S', '+', 'W', 'F'

; [Iter3] Effect duration in frames (~5 seconds at game speed)
EFFECT_DURATION EQU 300

; [Iter3] Original paddle width (saved before widening)
ORIG_PADDLE_W   DW 50

; [Iter3] Flash message strings for bonus collection
MsgNewLife      DB '+1 LIFE!', 0
MsgSlowBall     DB 'SLOW BALL!', 0
MsgWidePaddle   DB 'WIDE PADDLE!', 0
MsgFastBall     DB 'FAST BALL!', 0

.CODE

; ============================================================================
; GET_RANDOM
; [Iter3] Simple LCG pseudo-random number generator
; Returns: AX = random 16-bit value (0-65535)
; ============================================================================
GET_RANDOM PROC NEAR
    PUSH BX
    PUSH DX
    MOV AX, WORD PTR RNG_SEED
    MOV BX, 8405h              ; LCG multiplier
    MUL BX
    ADD AX, 0001h              ; LCG increment
    MOV WORD PTR RNG_SEED, AX
    POP DX
    POP BX
    RET
GET_RANDOM ENDP

; ============================================================================
; SPAWN_BONUS
; [Iter3] Create a bonus at random X, dropping from below brick grid
; Enforces per-level spawn caps to balance gameplay
; ============================================================================
SPAWN_BONUS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX

    ; [Iter3] Check spawn cap per level (Level1=5, Level2=7, Level3=8)
    MOV AL, BYTE PTR CURRENT_LEVEL
    CMP AL, 2
    JE @@SB_L2_LIM
    CMP AL, 3
    JE @@SB_L3_LIM
    CMP BYTE PTR BONUSES_SPAWNED, 5
    JGE @@SB_EXIT
    JMP @@SB_DO_SPAWN
@@SB_L2_LIM:
    CMP BYTE PTR BONUSES_SPAWNED, 7
    JGE @@SB_EXIT
    JMP @@SB_DO_SPAWN
@@SB_L3_LIM:
    CMP BYTE PTR BONUSES_SPAWNED, 8
    JGE @@SB_EXIT
@@SB_DO_SPAWN:

    ; [Iter3] Pick random bonus type (1-4)
    CALL GET_RANDOM
    MOV BX, 4
    XOR DX, DX
    DIV BX
    INC DL                     ; DL = 1..4

    ; [Iter3] Cap extra life spawns (Level1=1 max, Level2/3=2 max)
    CMP DL, 2
    JNE @@SB_TYPE_OK
    
    CMP BYTE PTR CURRENT_LEVEL, 1
    JNE @@SB_L23_LIMIT
    CMP BYTE PTR LIVES_SPAWNED, 1
    JGE @@SB_REMAP
    JMP @@SB_INC_LIFE
@@SB_L23_LIMIT:
    CMP BYTE PTR LIVES_SPAWNED, 2
    JGE @@SB_REMAP

@@SB_INC_LIFE:
    INC BYTE PTR LIVES_SPAWNED
    JMP @@SB_TYPE_OK

@@SB_REMAP:
    MOV DL, 1                 ; Remap to Slow Ball instead

@@SB_TYPE_OK:
    MOV BYTE PTR BONUS_TYPE, DL
    INC BYTE PTR BONUSES_SPAWNED

    ; [Iter3] Random X position (10 to 289, covering play area)
    CALL GET_RANDOM
    MOV BX, 280
    XOR DX, DX
    DIV BX
    ADD DX, 10
    MOV WORD PTR BONUS_X, DX

    ; [Iter3] Start Y just below the brick grid
    MOV WORD PTR BONUS_Y, 70
    MOV WORD PTR BONUS_PREV_Y, 70

    MOV BYTE PTR BONUS_ACTIVE, 1

    ; [Iter3] Draw initial bonus tile
    CALL DRAW_BONUS

@@SB_EXIT:
    POP DX
    POP BX
    POP AX
    RET
SPAWN_BONUS ENDP

; ============================================================================
; DRAW_BONUS
; [Iter3] Draw falling bonus tile (16x10 bright colored box with letter)
; ============================================================================
DRAW_BONUS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    ; [Iter3] Get bonus color from table
    XOR BX, BX
    MOV BL, BYTE PTR BONUS_TYPE
    LEA SI, BonusColors
    ADD SI, BX
    MOV AL, [SI]
    XOR AH, AH

    ; [Iter3] Draw outer colored rectangle
    PUSH_RECT BONUS_X, BONUS_Y, BonusSizeW, BonusSizeH, AX

    ; [Iter3] Draw bonus letter centered inside tile
    MOV AL, BYTE PTR BONUS_TYPE
    XOR AH, AH
    LEA SI, BonusChars
    ADD SI, AX
    MOV AL, [SI]
    MOV DX, WORD PTR BONUS_Y
    ADD DX, 1
    MOV BX, WORD PTR BONUS_X
    ADD BX, 4
    MOV AH, 00h               ; Black letter for contrast
    CALL DRAW_CHAR

    POP SI
    POP DX
    POP BX
    POP AX
    RET
DRAW_BONUS ENDP

; ============================================================================
; ERASE_BONUS
; [Iter3] Erase bonus tile (slightly oversized to prevent ghost artifacts)
; ============================================================================
ERASE_BONUS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX

    MOV AX, C_DEEP_BLUE
    PUSH AX
    MOV AX, BonusSizeH + 2    ; Extra height to cover character bleed
    PUSH AX
    MOV AX, BonusSizeW
    PUSH AX
    MOV AX, WORD PTR BONUS_PREV_Y
    PUSH AX
    MOV AX, WORD PTR BONUS_X
    PUSH AX
    CALL DRAW_RECT

    POP DX
    POP BX
    POP AX
    RET
ERASE_BONUS ENDP

; ============================================================================
; UPDATE_BONUS
; [Iter3] Move falling bonus, check paddle collision, apply effect on catch
; ============================================================================
UPDATE_BONUS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP BYTE PTR BONUS_ACTIVE, 0
    JE @@UB_DONE

    ; [Iter3] Save previous Y for clean erase
    MOV AX, WORD PTR BONUS_Y
    MOV WORD PTR BONUS_PREV_Y, AX

    ; [Iter3] Erase at old position
    CALL ERASE_BONUS

    ; [Iter3] Move bonus downward
    MOV AX, WORD PTR BONUS_SPEED
    ADD WORD PTR BONUS_Y, AX

    ; [Iter3] Off screen? -> deactivate
    CMP WORD PTR BONUS_Y, 196
    JGE @@UB_DEACTIVATE

    ; [Iter3] Check paddle collision (AABB overlap test)
    MOV AX, WORD PTR BONUS_X
    ADD AX, BonusSizeW
    CMP AX, WORD PTR PADDLE_POS_X
    JLE @@UB_DRAW

    MOV AX, WORD PTR PADDLE_POS_X
    ADD AX, WORD PTR PADDLE_WIDTH
    CMP WORD PTR BONUS_X, AX
    JGE @@UB_DRAW

    MOV AX, WORD PTR BONUS_Y
    ADD AX, BonusSizeH
    CMP AX, WORD PTR PADDLE_POS_Y
    JLE @@UB_DRAW

    MOV AX, WORD PTR PADDLE_POS_Y
    ADD AX, WORD PTR PADDLE_HEIGHT
    CMP WORD PTR BONUS_Y, AX
    JGE @@UB_DRAW

    ; [Iter3] COLLECTED - apply bonus effect
    CALL APPLY_BONUS_EFFECT
    JMP @@UB_DEACTIVATE

@@UB_DRAW:
    CALL DRAW_BONUS
    JMP @@UB_DONE

@@UB_DEACTIVATE:
    MOV BYTE PTR BONUS_ACTIVE, 0
    ; Erase any remnant
    MOV AX, C_DEEP_BLUE
    PUSH AX
    MOV AX, BonusSizeH + 2
    PUSH AX
    MOV AX, BonusSizeW
    PUSH AX
    MOV AX, WORD PTR BONUS_Y
    PUSH AX
    MOV AX, WORD PTR BONUS_X
    PUSH AX
    CALL DRAW_RECT

@@UB_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UPDATE_BONUS ENDP

; ============================================================================
; APPLY_BONUS_EFFECT
; [Iter3] Apply the bonus type that was collected by the paddle
; Type 1=Slow Ball, 2=Extra Life, 3=Wide Paddle, 4=Fast Ball
; ============================================================================
APPLY_BONUS_EFFECT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH SI

    MOV AL, BYTE PTR BONUS_TYPE

    ; [Iter3] Extra Life is instant, doesn't replace timed effects
    CMP AL, 2
    JNE @@ABE_NOT_LIFE_START
    JMP @@ABE_IS_LIFE
@@ABE_NOT_LIFE_START:

    ; [Iter3] Undo any existing timed effect first
    CALL UNDO_BONUS_EFFECT

    MOV AL, BYTE PTR BONUS_TYPE
    MOV BYTE PTR BONUS_EFFECT, AL
    MOV WORD PTR BONUS_TIMER, EFFECT_DURATION

    ; --- [Iter3] SLOW BALL (type 1) - halve ball speed ---
    CMP AL, 1
    JE @@ABE_IS_SLOW
    JMP @@ABE_NOT_SLOW
@@ABE_IS_SLOW:
    MOV AX, WORD PTR BALL_DX
    CMP AX, 0
    JGE @@ABE_SL_DX_POS
    NEG AX
@@ABE_SL_DX_POS:
    SHR AX, 1
    CMP AX, 1
    JAE @@ABE_SL_DX_OK
    MOV AX, 1
@@ABE_SL_DX_OK:
    CMP WORD PTR BALL_DX, 0
    JGE @@ABE_SL_DX_STORE
    NEG AX
@@ABE_SL_DX_STORE:
    MOV WORD PTR BALL_DX, AX

    MOV AX, WORD PTR BALL_DY
    CMP AX, 0
    JGE @@ABE_SL_DY_POS
    NEG AX
@@ABE_SL_DY_POS:
    SHR AX, 1
    CMP AX, 1
    JAE @@ABE_SL_DY_OK
    MOV AX, 1
@@ABE_SL_DY_OK:
    CMP WORD PTR BALL_DY, 0
    JGE @@ABE_SL_DY_STORE
    NEG AX
@@ABE_SL_DY_STORE:
    MOV WORD PTR BALL_DY, AX

    JMP @@ABE_DONE

@@ABE_NOT_SLOW:
    ; --- [Iter3] EXTRA LIFE (type 2) - increment lives (max 9) ---
    CMP AL, 2
    JE @@ABE_IS_LIFE
    JMP @@ABE_NOT_LIFE
@@ABE_IS_LIFE:
    CMP BYTE PTR PLAYER_LIVES, 9
    JB  @@ABE_LIVES_OK
    JMP @@ABE_DONE
@@ABE_LIVES_OK:
    INC BYTE PTR PLAYER_LIVES
    MOV BYTE PTR HUD_LIVES_CACHED, 0FFh  ; Force HUD redraw
    JMP @@ABE_DONE

@@ABE_NOT_LIFE:
    ; --- [Iter3] WIDE PADDLE (type 3) - widen paddle by 30px ---
    CMP AL, 3
    JE @@ABE_IS_WIDE
    JMP @@ABE_NOT_WIDE
@@ABE_IS_WIDE:
    PUSH_RECT PADDLE_POS_X, PADDLE_POS_Y, PADDLE_WIDTH, PADDLE_HEIGHT, C_DEEP_BLUE
    MOV AX, WORD PTR PADDLE_WIDTH
    MOV WORD PTR ORIG_PADDLE_W, AX
    ADD AX, 30
    CMP AX, 90
    JBE @@ABE_W_OK
    MOV AX, 90                 ; Cap at 90px
@@ABE_W_OK:
    MOV WORD PTR PADDLE_WIDTH, AX
    PUSH_RECT PADDLE_POS_X, PADDLE_POS_Y, PADDLE_WIDTH, PADDLE_HEIGHT, C_CYAN
    JMP @@ABE_DONE

@@ABE_NOT_WIDE:
    ; --- [Iter3] FAST BALL (type 4) - double ball speed (max 6) ---
    CMP AL, 4
    JE @@ABE_IS_FAST
    JMP @@ABE_DONE
@@ABE_IS_FAST:
    MOV AX, WORD PTR BALL_DX
    CMP AX, 0
    JGE @@ABE_FB_DX_P
    NEG AX
@@ABE_FB_DX_P:
    SHL AX, 1
    CMP AX, 6
    JBE @@ABE_FB_DX_OK
    MOV AX, 6
@@ABE_FB_DX_OK:
    CMP WORD PTR BALL_DX, 0
    JGE @@ABE_FB_DX_S
    NEG AX
@@ABE_FB_DX_S:
    MOV WORD PTR BALL_DX, AX

    MOV AX, WORD PTR BALL_DY
    CMP AX, 0
    JGE @@ABE_FB_DY_P
    NEG AX
@@ABE_FB_DY_P:
    SHL AX, 1
    CMP AX, 6
    JBE @@ABE_FB_DY_OK
    MOV AX, 6
@@ABE_FB_DY_OK:
    CMP WORD PTR BALL_DY, 0
    JGE @@ABE_FB_DY_S
    NEG AX
@@ABE_FB_DY_S:
    MOV WORD PTR BALL_DY, AX

    JMP @@ABE_DONE

@@ABE_NOT_FAST:

@@ABE_DONE:
    POP SI
    POP BX
    POP AX
    RET
APPLY_BONUS_EFFECT ENDP

; ============================================================================
; UNDO_BONUS_EFFECT
; [Iter3] Remove any currently applied timed effect (restore original state)
; ============================================================================
UNDO_BONUS_EFFECT PROC NEAR
    PUSH AX

    CMP BYTE PTR BONUS_EFFECT, 0
    JNE @@UBE_CONT
    JMP @@UBE_DONE
@@UBE_CONT:

    MOV AL, BYTE PTR BONUS_EFFECT

    ; [Iter3] Undo wide paddle -> restore original width
    CMP AL, 3
    JNE @@UBE_NOT_WIDE
    PUSH_RECT PADDLE_POS_X, PADDLE_POS_Y, PADDLE_WIDTH, PADDLE_HEIGHT, C_DEEP_BLUE
    MOV AX, WORD PTR ORIG_PADDLE_W
    MOV WORD PTR PADDLE_WIDTH, AX
    PUSH_RECT PADDLE_POS_X, PADDLE_POS_Y, PADDLE_WIDTH, PADDLE_HEIGHT, C_CYAN
@@UBE_NOT_WIDE:

    ; [Iter3] Undo slow/fast ball -> restore level speed
    CMP AL, 1
    JE @@UBE_RESTORE_SPEED
    CMP AL, 4
    JNE @@UBE_CLR
@@UBE_RESTORE_SPEED:
    PUSH BX
    XOR BX, BX
    MOV BL, BYTE PTR CURRENT_LEVEL
    DEC BX
    SHL BX, 1
    MOV AX, LevelSpeedDX[BX]
    CMP WORD PTR BALL_DX, 0
    JGE @@UBE_DX_POS
    NEG AX
@@UBE_DX_POS:
    MOV WORD PTR BALL_DX, AX
    MOV AX, LevelSpeedDY[BX]
    CMP WORD PTR BALL_DY, 0
    JLE @@UBE_DY_NEG
    NEG AX
@@UBE_DY_NEG:
    MOV WORD PTR BALL_DY, AX
    POP BX

@@UBE_CLR:
    MOV BYTE PTR BONUS_EFFECT, 0
    MOV WORD PTR BONUS_TIMER, 0

@@UBE_DONE:
    POP AX
    RET
UNDO_BONUS_EFFECT ENDP

; ============================================================================
; UPDATE_EFFECT_TIMER
; [Iter3] Count down active effect timer and remove when expired
; ============================================================================
UPDATE_EFFECT_TIMER PROC NEAR
    PUSH AX

    CMP BYTE PTR BONUS_EFFECT, 0
    JE @@UET_DONE

    CMP WORD PTR BONUS_TIMER, 0
    JE @@UET_DONE

    DEC WORD PTR BONUS_TIMER
    JNZ @@UET_DONE

    ; [Iter3] Timer reached 0 - undo effect
    CALL UNDO_BONUS_EFFECT

@@UET_DONE:
    POP AX
    RET
UPDATE_EFFECT_TIMER ENDP