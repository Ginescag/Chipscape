INCLUDE "constantes.inc"

; =========================
; Constantes de HUD/Window
; =========================
DEF SCORE_DIGIT_BASE     EQU 4        ; índice base para 0..9 en VRAM ($8000)
DEF HUD_BLANK_TILE       EQU $EF      ; tile "vacío" en VRAM (por si lo quieres usar)
DEF SCORE_CHAR_BASE      EQU $F0      ; 'S','C','O','R','E' en VRAM

DEF WIN_MAP_BASE         EQU $9C00    ; Window Map 1 (LCDC bit6=1)
DEF SCORE_ROW_LABEL      EQU 0
DEF SCORE_ROW_DIGITS     EQU 1

DEF SCORE_X_LABEL        EQU 7
DEF SCORE_X_DIGITS       EQU 7

DEF SCORE_ADDR_LABEL0    EQU (WIN_MAP_BASE + SCORE_ROW_LABEL*32 + SCORE_X_LABEL + 0)
DEF SCORE_ADDR_DIGITS0   EQU (WIN_MAP_BASE + SCORE_ROW_DIGITS*32 + SCORE_X_DIGITS + 0)

; =========================
; WRAM
; =========================
SECTION "WRAM SCORE", WRAM0
wScore0:        ds 1
wScore1:        ds 1
wScore2:        ds 1
wScoreDigits:   ds 5
wTmp0:          ds 1
wTmp1:          ds 1
wTmp2:          ds 1

; =========================
; Gráficos (ROM)
; =========================
SECTION "GFX SCORE (ROM)", ROM0

; Tile en blanco (por si necesitas rellenar)
ScoreBlankTile:
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 'S','C','O','R','E' (5 tiles)
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

; Dígitos 0..9 (10 tiles). 2bpp con ambos planos iguales para un tono visible.
ScoreDigitTiles:
  ; '0'
  db $3C,$3C,$42,$42,$46,$46,$4A,$4A,$52,$52,$62,$62,$3C,$3C,$00,$00
 
  db $08,$08,$18,$18,$08,$08,$08,$08,$08,$08,$08,$08,$3E,$3E,$00,$00
  
  db $3C,$3C,$42,$42,$02,$02,$0C,$0C,$30,$30,$40,$40,$7E,$7E,$00,$00
  
  db $3C,$3C,$42,$42,$02,$02,$1C,$1C,$02,$02,$42,$42,$3C,$3C,$00,$00
  
  db $04,$04,$0C,$0C,$14,$14,$24,$24,$44,$44,$7E,$7E,$04,$04,$00,$00
  
  db $7E,$7E,$40,$40,$7C,$7C,$02,$02,$02,$02,$42,$42,$3C,$3C,$00,$00
  
  db $3C,$3C,$40,$40,$7C,$7C,$42,$42,$42,$42,$42,$42,$3C,$3C,$00,$00
  
  db $7E,$7E,$02,$02,$04,$04,$08,$08,$10,$10,$20,$20,$20,$20,$00,$00
  
  db $3C,$3C,$42,$42,$42,$42,$3C,$3C,$42,$42,$42,$42,$3C,$3C,$00,$00
  
  db $3C,$3C,$42,$42,$42,$42,$3E,$3E,$02,$02,$04,$04,$38,$38,$00,$00
ScoreDigitTilesEnd:

; =========================
; Código
; =========================
SECTION "Score Code", ROM0

; Cargar tiles necesarios del HUD (debe llamarse con LCD OFF o dentro de VBlank)
Score_LoadTiles:
    ; blank
    ld hl, ScoreBlankTile
    ld de, VRAM_TILEDATA_START + HUD_BLANK_TILE * VRAM_TILE_SIZE
    ld b, 16
    call memcpy

    ; 'SCORE'
    ld hl, ScoreLabelTiles
    ld de, VRAM_TILEDATA_START + SCORE_CHAR_BASE * VRAM_TILE_SIZE
    ld b, ScoreLabelTilesEnd - ScoreLabelTiles
    call memcpy

    ; '0'..'9'
    ld hl, ScoreDigitTiles
    ld de, VRAM_TILEDATA_START + SCORE_DIGIT_BASE * VRAM_TILE_SIZE
    ld b, ScoreDigitTilesEnd - ScoreDigitTiles
    call memcpy
    ret

; Poner score a 0
Score_Reset:
    xor a
    ld [wScore0], a
    ld [wScore1], a
    ld [wScore2], a
    ret

; Suma BC al score (little endian en wScore0..2) con saturación
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

; Setea score = HL (máx. 65535)
Score_SetHL:
    ld a, l
    ld [wScore0], a
    ld a, h
    ld [wScore1], a
    xor a
    ld [wScore2], a
    call Score_Saturate
    ret

; Saturar a 99,999 (0x01_86_9F)
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

; =========================
; Conversión a 5 dígitos “por resta” (pre-cálculo)
; =========================
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

; =========================
; Inicialización del HUD (escribe "SCORE" y placeholders)
; =========================
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

    ; Dígitos iniciales en base (0..9 se sumarán en draw)
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

; =========================
; Dibujo: escribe 5 dígitos en la window (VRAM)
; Debe llamarse en VBlank
; =========================
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

; Retro-compatibilidad: compute + draw (si prefieres 1 sola llamada en VBlank)
Score_HUD_Update:
    call Score_ComputeDigits
    jp   Score_HUD_Draw
