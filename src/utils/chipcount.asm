INCLUDE "constantes.inc"

SECTION "WRAM CHIPS", WRAM0
wChips:           ds 1

SECTION "GFX CHIPCOUNT", ROM0
ChipIconTile:
  DB $24,$00,$7E,$5A,$C3,$18,$42,$7E
  DB $42,$7E,$C3,$18,$7E,$5A,$24,$00
LetterXTile:
  db $00,$00,$42,$42,$24,$24,$18,$18,$18,$18,$24,$24,$42,$42,$00,$00

SECTION "ChipCount Code", ROM0

ChipCount_LoadTiles:
  ld hl, ChipIconTile
  ld de, VRAM_TILEDATA_START + TILE_CHIP_IDX * VRAM_TILE_SIZE
  ld b, 16
  call memcpy
  ld hl, LetterXTile
  ld de, VRAM_TILEDATA_START + TILE_X_IDX * VRAM_TILE_SIZE
  ld b, 16
  call memcpy
  ret

ChipCount_Reset:
  xor a
  ld [wChips], a
  ret

ChipCount_SetA:
  cp 100
  jr c, .ok
  ld a, 99
.ok:
  ld [wChips], a
  ret

ChipCount_AddA:
  ld   c, a
  ld   hl, wChips
  ld   a, [hl]
  ld   d, a
  add  c
  jr   c, .sat
  cp   100
  jr   c, .ok_sum
.sat:
  ld   a, 99
.ok_sum:
  ld   [hl], a
  sub  d
  ret  z
  push af
  ld   h, 0
  ld   l, a
  add  hl, hl
  ld   d, h
  ld   e, l
  ld   h, 0
  ld   l, a
  add  hl, hl
  add  hl, hl
  add  hl, hl
  add  hl, hl
  ld   b, h
  ld   c, l
  ld   h, 0
  ld   l, a
  add  hl, hl
  add  hl, hl
  add  hl, hl
  add  hl, hl
  add  hl, hl
  add  hl, bc
  add  hl, de
  ld   b, h
  ld   c, l
  call Score_AddBC
  pop  af
  ld   h, 0
  ld   l, a
  add  hl, hl
  ld   d, h
  ld   e, l
  ld   h, 0
  ld   l, a
  add  hl, hl
  add  hl, hl
  add  hl, hl
  add  hl, de
  ld   a, [wTimerHi]
  ld   d, a
  ld   a, [wTimerLo]
  ld   e, a
  add  hl, de
  jp   Timer_SetSecsHL

ChipCount_HUD_Init:
  ld hl, CHIP_ADDR_ICON
  ld a, TILE_CHIP_IDX
  ld [hl], a
  ld hl, CHIP_ADDR_X
  ld a, TILE_X_IDX
  ld [hl], a
  ld hl, CHIP_ADDR_TENS
  ld a, CHIPS_DIGIT_BASE + 0
  ld [hl], a
  inc l
  ld [hl], a
  ret

ChipCount_HUD_Update:
  ld a, [wChips]
  ld b, 0
.c10:
  cp 10
  jr c, .done10
  sub 10
  inc b
  jr .c10
.done10:
  ld hl, CHIP_ADDR_TENS
  ld c, a
  ld a, CHIPS_DIGIT_BASE
  add b
  ld [hl], a
  inc l
  ld a, CHIPS_DIGIT_BASE
  add c
  ld [hl], a
  ret
