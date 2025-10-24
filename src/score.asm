INCLUDE "inc/hardware.inc"
INCLUDE "inc/constants.inc"

DEF SCORE_DIGIT_BASE     EQU 4    

DEF HUD_BLANK_TILE       EQU $EF   

DEF SCORE_CHAR_BASE      EQU $F0

DEF WIN_MAP_BASE         EQU $9C00

DEF SCORE_ROW_LABEL      EQU 0     
DEF SCORE_ROW_DIGITS     EQU 1    


DEF SCORE_X_LABEL        EQU 7
DEF SCORE_X_DIGITS       EQU 7     

DEF SCORE_ADDR_LABEL0    EQU (WIN_MAP_BASE + SCORE_ROW_LABEL*32 + SCORE_X_LABEL + 0)
DEF SCORE_ADDR_DIGITS0   EQU (WIN_MAP_BASE + SCORE_ROW_DIGITS*32 + SCORE_X_DIGITS + 0)

SECTION "WRAM SCORE", WRAM0
wScore0:        ds 1 
wScore1:        ds 1 
wScore2:        ds 1 
wScoreDigits:   ds 5 
wTmp0:          ds 1
wTmp1:          ds 1
wTmp2:          ds 1

SECTION "GFX SCORE (ROM)", ROM0
ScoreBlankTile:
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 'S','C','O','R','E'
ScoreLabelTiles:
  ; 'S'
  db $00,$00,$38,$38,$40,$40,$30,$30,$08,$08,$04,$04,$78,$78,$00,$00
  ; 'C'
  db $00,$00,$38,$38,$44,$44,$40,$40,$40,$40,$44,$44,$38,$38,$00,$00
  ; 'O'
  db $00,$00,$38,$38,$44,$44,$44,$44,$44,$44,$44,$44,$38,$38,$00,$00
  ; 'R'
  db $00,$00,$78,$78,$44,$44,$78,$78,$50,$50,$48,$48,$44,$44,$00,$00
  ; 'E'
  db $00,$00,$7C,$7C,$40,$40,$78,$78,$40,$40,$40,$40,$7C,$7C,$00,$00
ScoreLabelTilesEnd:

SECTION "Score Code", ROM0
EXPORT Score_LoadTiles, Score_Reset
EXPORT Score_AddBC, Score_SetHL
EXPORT Score_HUD_Init, Score_HUD_Update

Score_LoadTiles:
    ld de, ScoreBlankTile
    ld hl, $8000 + (HUD_BLANK_TILE * 16)
    ld bc, 16
    call CopyBytes

    ld de, ScoreLabelTiles
    ld hl, $8000 + (SCORE_CHAR_BASE * 16)
    ld bc, ScoreLabelTilesEnd - ScoreLabelTiles
    call CopyBytes
    ret

Score_Reset:
    xor a
    ld [wScore0], a
    ld [wScore1], a
    ld [wScore2], a
    ret

Score_AddBC:
    ld a, [wScore0]
    add a, c
    ld [wScore0], a
    ld a, [wScore1]
    adc a, b
    ld [wScore1], a
    ld a, [wScore2]
    adc a, 0
    ld [wScore2], a
    call Score_Saturate
    ret

Score_SetHL:
    ld a, l
    ld [wScore0], a
    ld a, h
    ld [wScore1], a
    xor a
    ld [wScore2], a
    call Score_Saturate
    ret

Score_Saturate:
    ld a, [wScore2]
    cp $01
    jr c, .ok
    jr nz, .sat
    ld a, [wScore1]
    cp $86
    jr c, .ok
    jr nz, .sat
    ld a, [wScore0]
    cp $9F
    jr c, .ok
    jr z, .ok
.sat:
    ld a, $9F
    ld [wScore0], a
    ld a, $86
    ld [wScore1], a
    ld a, $01
    ld [wScore2], a
.ok:
    ret


Score_ComputeDigits:
    ld a, [wScore0]    
    ld [wTmp0], a
    ld a, [wScore1]
    ld [wTmp1], a
    ld a, [wScore2]
    ld [wTmp2], a

    xor a
    ld b, a
.d4_try:
    ld a, [wTmp0]
    sub $10
    ld [wTmp0], a
    ld a, [wTmp1]
    sbc $27
    ld [wTmp1], a
    ld a, [wTmp2]
    sbc $00
    ld [wTmp2], a
    jr nc, .d4_ok
    ; undo
    ld a, [wTmp0]
    add $10
    ld [wTmp0], a
    ld a, [wTmp1]
    adc $27
    ld [wTmp1], a
    ld a, [wTmp2]
    adc $00
    ld [wTmp2], a
    jr .d4_done
.d4_ok:
    inc b
    jr .d4_try
.d4_done:
    ld a, b
    ld [wScoreDigits+0], a

    xor a
    ld b, a
.d3_try:
    ld a, [wTmp0]
    sub $E8
    ld [wTmp0], a
    ld a, [wTmp1]
    sbc $03
    ld [wTmp1], a
    ld a, [wTmp2]
    sbc $00
    ld [wTmp2], a
    jr nc, .d3_ok
    ld a, [wTmp0]
    add $E8
    ld [wTmp0], a
    ld a, [wTmp1]
    adc $03
    ld [wTmp1], a
    ld a, [wTmp2]
    adc $00
    ld [wTmp2], a
    jr .d3_done
.d3_ok:
    inc b
    jr .d3_try
.d3_done:
    ld a, b
    ld [wScoreDigits+1], a

    xor a
    ld b, a
.d2_try:
    ld a, [wTmp0]
    sub $64
    ld [wTmp0], a
    ld a, [wTmp1]
    sbc $00
    ld [wTmp1], a
    ld a, [wTmp2]
    sbc $00
    ld [wTmp2], a
    jr nc, .d2_ok
    ld a, [wTmp0]
    add $64
    ld [wTmp0], a
    ld a, [wTmp1]
    adc $00
    ld [wTmp1], a
    ld a, [wTmp2]
    adc $00
    ld [wTmp2], a
    jr .d2_done
.d2_ok:
    inc b
    jr .d2_try
.d2_done:
    ld a, b
    ld [wScoreDigits+2], a

    xor a
    ld b, a
.d1_try:
    ld a, [wTmp0]
    sub $0A
    ld [wTmp0], a
    ld a, [wTmp1]
    sbc $00
    ld [wTmp1], a
    ld a, [wTmp2]
    sbc $00
    jr nc, .d1_ok
    ; undo
    ld a, [wTmp0]
    add $0A
    ld [wTmp0], a
    ld a, [wTmp1]
    adc $00
    ld [wTmp1], a
    ld a, [wTmp2]
    adc $00
    jr .d1_done
.d1_ok:
    inc b
    jr .d1_try
.d1_done:
    ld a, b
    ld [wScoreDigits+3], a

    ld a, [wTmp0]
    ld [wScoreDigits+4], a
    ret

Score_HUD_Init:
    ld hl, SCORE_ADDR_LABEL0
    ld a, SCORE_CHAR_BASE + 0  
    ld [hl], a
    inc l
    ld a, SCORE_CHAR_BASE + 1  
    ld [hl], a
    inc l
    ld a, SCORE_CHAR_BASE + 2  
    ld [hl], a
    inc l
    ld a, SCORE_CHAR_BASE + 3  
    ld [hl], a
    inc l
    ld a, SCORE_CHAR_BASE + 4  
    ld [hl], a

    ld hl, SCORE_ADDR_DIGITS0
    ld a, SCORE_DIGIT_BASE + 0
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    ret

Score_HUD_Update:
    call Score_ComputeDigits
    ld hl, SCORE_ADDR_DIGITS0

    ld a, [wScoreDigits+0]     
    add SCORE_DIGIT_BASE
    ld [hl], a
    inc l

    ld a, [wScoreDigits+1]     
    add SCORE_DIGIT_BASE
    ld [hl], a
    inc l

    ld a, [wScoreDigits+2]     
    add SCORE_DIGIT_BASE
    ld [hl], a
    inc l

    ld a, [wScoreDigits+3]     
    add SCORE_DIGIT_BASE
    ld [hl], a
    inc l

    ld a, [wScoreDigits+4]     
    add SCORE_DIGIT_BASE
    ld [hl], a
    ret
