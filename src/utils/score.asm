
INCLUDE "constantes.inc"

SECTION "WRAM SCORE", WRAM0
wScore0:        ds 1
wScore1:        ds 1
wScore2:        ds 1
wScoreDigits:   ds 5
wTmp0:          ds 1
wTmp1:          ds 1
wTmp2:          ds 1

SECTION "Score Code", ROM0

Score_LoadTiles:
    ld hl, ScoreBlankTile
    ld de, VRAM_TILEDATA_START + HUD_BLANK_TILE * VRAM_TILE_SIZE
    ld b, 16
    call memcpy

   
    ld hl, ScoreLabelTiles
    ld de, VRAM_TILEDATA_START + SCORE_CHAR_BASE * VRAM_TILE_SIZE
    ld b, ScoreLabelTilesEnd - ScoreLabelTiles
    call memcpy

    
    ld hl, ScoreDigitTiles
    ld de, VRAM_TILEDATA_START + SCORE_DIGIT_BASE * VRAM_TILE_SIZE
    ld b, ScoreDigitTilesEnd - ScoreDigitTiles
    call memcpy
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

    ; decenas de millar (10000 = $2710)
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

    ; millares (1000 = $03E8)
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

    ; centenas (100 = $0064)
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

    ; decenas (10)
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

    ; unidades
    ld a, [wTmp0]
    ld [wScoreDigits+4], a
    ret


Score_HUD_Init:
    ; LABEL "SCORE"
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
    ld a, SCORE_DIGIT_BASE
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

Score_HUD_Draw:
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

Score_HUD_Update:
    call Score_ComputeDigits
    jp   Score_HUD_Draw
