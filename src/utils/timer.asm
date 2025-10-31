INCLUDE "constantes.inc"

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

;genera “ticks” de 1/16 s y flag de 1s
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
