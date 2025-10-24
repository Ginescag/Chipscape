
SECTION "Tilemap (ROM)", ROM0
TileMap:
  REPT 32
    REPT 16
      db 0, 1
    ENDR
  ENDR
TileMapEnd:

EXPORT Gfx_LoadTileMap
Gfx_LoadTileMap:
  ld de, TileMap
  ld hl, $9800
  ld bc, TileMapEnd - TileMap
  call CopyBytes
  ret
