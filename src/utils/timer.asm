
INCLUDE "constantes.inc"

IF !DEF(rDIV)
  DEF rDIV  EQU $FF04
ENDC
IF !DEF(rTIMA)
  DEF rTIMA EQU $FF05
ENDC
IF !DEF(rTMA)
  DEF rTMA  EQU $FF06
ENDC
IF !DEF(rTAC)
  DEF rTAC  EQU $FF07
ENDC
IF !DEF(rIF)
  DEF rIF   EQU $FF0F
ENDC
IF !DEF(rIE)
  DEF rIE   EQU $FFFF
ENDC

IF !DEF(IEF_TIMER)
  DEF IEF_TIMER  EQU %00000100
ENDC
DEF TACF_EN    EQU %00000100
DEF TACF_4KHZ  EQU %00000000
DEF TICKS_PER_SECOND   EQU 16          

IF !DEF(DIGIT_TILE_BASE)
  DEF DIGIT_TILE_BASE    EQU 4
ENDC
IF !DEF(HUD_BLANK_TILE)
  DEF HUD_BLANK_TILE     EQU $EF
ENDC
IF !DEF(WIN_MAP_BASE)
  DEF WIN_MAP_BASE       EQU $9C00
ENDC
IF !DEF(HUD_ROW_DIGITS)
  DEF HUD_ROW_DIGITS     EQU 1
ENDC

DEF TIMER_X_H          EQU 17
DEF TIMER_X_T          EQU 18
DEF TIMER_X_O          EQU 19
DEF TIMER_ADDR_H       EQU (WIN_MAP_BASE + HUD_ROW_DIGITS*32 + TIMER_X_H)
DEF TIMER_ADDR_T       EQU (WIN_MAP_BASE + HUD_ROW_DIGITS*32 + TIMER_X_T)
DEF TIMER_ADDR_O       EQU (WIN_MAP_BASE + HUD_ROW_DIGITS*32 + TIMER_X_O)

DEF TIMER_MAX_H        EQU 3
DEF TIMER_MAX_L        EQU $E7        


SECTION "GFX Digits (timer)", ROM0
DigitsTiles:
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
DigitsTilesEnd:


SECTION "WRAM Vars (timer)", WRAM0
wTimerLo:         ds 1
wTimerHi:         ds 1
wTimerSubTicks:   ds 1
wTimerFlag1s:     ds 1
wTileHundreds:    ds 1
wTileTens:        ds 1
wTileOnes:        ds 1


SECTION "Timer Code", ROM0

Timer_LoadTiles:
  call wait_vblank
  ld hl, DigitsTiles
  ld de, VRAM_TILEDATA_START + DIGIT_TILE_BASE*VRAM_TILE_SIZE
  ld b, DigitsTilesEnd - DigitsTiles
  call memcpy
  ret

Timer_Init:
  xor a
  ld [wTimerSubTicks], a
  ld [wTimerFlag1s], a

  ld a, TACF_4KHZ
  ld [rTAC], a
  xor a
  ld [rTMA], a
  ld [rTIMA], a

  ld a, [rIF]
  res 2, a
  ld [rIF], a

  ld a, [rIE]
  or IEF_TIMER
  ld [rIE], a

  xor a
  ld [rDIV], a
  ld a, TACF_4KHZ | TACF_EN
  ld [rTAC], a
  ret

Timer_SetSecsHL:
  ld a, h
  cp TIMER_MAX_H+1
  jr c, .h_ok
  ld h, TIMER_MAX_H
  ld l, TIMER_MAX_L
  jr .store
.h_ok:
  cp TIMER_MAX_H
  jr c, .store
  jr nz, .store
  ld a, l
  cp TIMER_MAX_L+1
  jr c, .store
  ld h, TIMER_MAX_H
  ld l, TIMER_MAX_L
.store:
  ld a, l
  ld [wTimerLo], a
  ld a, h
  ld [wTimerHi], a
  call Timer_ComputeDigits
  ret

Timer_ComputeDigits:
  ld a, [wTimerHi]
  ld h, a
  ld a, [wTimerLo]
  ld l, a

  ld b, 0                   ; centenas
.t100_loop:
  ld a, h
  or a
  jr nz, .sub100
  ld a, l
  cp 100
  jr c, .t100_done
.sub100:
  ld a, l
  sub 100
  jr nc, .no_borrow100
  ld l, a
  dec h
  jr .inc_b100
.no_borrow100:
  ld l, a
.inc_b100:
  inc b
  jr .t100_loop
.t100_done:

  ld c, 0                   ; decenas
.t10_loop:
  ld a, l
  cp 10
  jr c, .t10_done
  sub 10
  ld l, a
  inc c
  jr .t10_loop
.t10_done:

  ld a, DIGIT_TILE_BASE
  add a, b
  ld [wTileHundreds], a
  ld a, DIGIT_TILE_BASE
  add a, c
  ld [wTileTens], a
  ld a, DIGIT_TILE_BASE
  add a, l
  ld [wTileOnes], a
  ret

Timer_HUD_Init:
  jp Timer_HUD_Update

Timer_HUD_Update:
  ld a, [wTileHundreds]
  cp DIGIT_TILE_BASE
  jr z, .checkTens

  ; tres dígitos
  ld hl, TIMER_ADDR_H
  ld a, [wTileHundreds]
  ld [hl], a
  ld hl, TIMER_ADDR_T
  ld a, [wTileTens]
  ld [hl], a
  ld hl, TIMER_ADDR_O
  ld a, [wTileOnes]
  ld [hl], a
  ret

.checkTens:
  ld a, [wTileTens]
  cp DIGIT_TILE_BASE
  jr z, .oneDigit

  ; dos dígitos
  ld hl, TIMER_ADDR_H
  ld a, HUD_BLANK_TILE
  ld [hl], a
  ld hl, TIMER_ADDR_T
  ld a, [wTileTens]
  ld [hl], a
  ld hl, TIMER_ADDR_O
  ld a, [wTileOnes]
  ld [hl], a
  ret

.oneDigit:
  ; un dígito
  ld hl, TIMER_ADDR_H
  ld a, HUD_BLANK_TILE
  ld [hl], a
  ld hl, TIMER_ADDR_T
  ld [hl], a
  ld hl, TIMER_ADDR_O
  ld a, [wTileOnes]
  ld [hl], a
  ret

Timer_ISR:
  push af
  push hl
  ld hl, rIF
  res 2, [hl]

  ld a, [wTimerSubTicks]
  inc a
  cp TICKS_PER_SECOND
  jr c, .store_sub
  xor a
  ld [wTimerSubTicks], a
  ld a, 1
  ld [wTimerFlag1s], a
  jr .done
.store_sub:
  ld [wTimerSubTicks], a
.done:
  pop hl
  pop af
  reti
