INCLUDE "inc/hardware.inc"

SECTION "GFX Tiles (ROM)", ROM0

DEF TILE_CHIP_IDX       EQU $F5   
DEF TILE_X_IDX          EQU $F6   

TileData:
  REPT 8
    db $00, $00
  ENDR
  REPT 8
    db %10101010, %01010101
  ENDR
TileDataEnd:

SpriteTile:
  db %00011000,%00011000
  db %00011000,%00011000
  db %11111111,%11111111
  db %00011000,%00011000
  db %00011000,%00011000
  db %00011000,%00011000
  db %00000000,%00000000
  db %00000000,%00000000
SpriteTileEnd:

TileChip::
    db $24,$00,$7E,$5A,$C3,$18,$42,$7E
    db $42,$7E,$C3,$18,$7E,$5A,$24,$00
TileChipEnd::

TileX::
   db $81,$81,$42,$42,$24,$24,$18,$18
  db $18,$18,$24,$24,$42,$42,$81,$81
TileXEnd::

EXPORT Gfx_LoadTiles
Gfx_LoadTiles:
  ld de, TileData
  ld hl, $8000
  ld bc, TileDataEnd - TileData
  call CopyBytes

  ld de, SpriteTile
  ld hl, $8000 + (2*16)
  ld bc, SpriteTileEnd - SpriteTile
  call CopyBytes

  ld de, TileChip
  ld hl, $8000 + (TILE_CHIP_IDX*16)
  ld bc, TileChipEnd - TileChip
  call CopyBytes

  ld de, TileX
  ld hl, $8000 + (TILE_X_IDX*16)
  ld bc, TileXEnd - TileX
  call CopyBytes
  ret
