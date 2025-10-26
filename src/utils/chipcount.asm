
INCLUDE "constantes.inc"

DEF TILE_CHIP_IDX     EQU $F5      ; icono de chip
DEF TILE_X_IDX        EQU $F6      ; letra 'X'

DEF CHIPS_DIGIT_BASE  EQU 4

DEF WIN_MAP_BASE      EQU $9C00
DEF CHIPS_ROW         EQU 1
DEF CHIP_X_ICON       EQU 2
DEF CHIP_X_LETTER     EQU 3
DEF CHIP_X_TENS       EQU 4
DEF CHIP_X_ONES       EQU 5

DEF CHIP_ADDR_ICON    EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_ICON)
DEF CHIP_ADDR_X       EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_LETTER)
DEF CHIP_ADDR_TENS    EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_TENS)
DEF CHIP_ADDR_ONES    EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_ONES)


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
  ; 'X'
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
  ld c, a
  ld hl, wChips
  ld a, [hl]
  add c
  jr c, .sat
  cp 100
  jr c, .store
.sat:
  ld a, 99
.store:
  ld [hl], a
  ret

ChipCount_HUD_Init:
  ld hl, CHIP_ADDR_ICON
  ld a, TILE_CHIP_IDX
  ld [hl], a
  ; 'X'
  ld hl, CHIP_ADDR_X
  ld a, TILE_X_IDX
  ld [hl], a
  ; 00
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
  ld c, a                 ; unidades
  ld a, CHIPS_DIGIT_BASE
  add b
  ld [hl], a              ; decenas
  inc l
  ld a, CHIPS_DIGIT_BASE
  add c
  ld [hl], a              
  ret
