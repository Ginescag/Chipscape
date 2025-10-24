INCLUDE "inc/hardware.inc"

DEF TILE_CHIP_IDX       EQU $F5   
DEF TILE_X_IDX          EQU $F6   
DEF CHIPS_DIGIT_BASE    EQU 4     

DEF WIN_MAP_BASE        EQU $9C00

DEF CHIPS_ROW           EQU 1
DEF CHIP_X_ICON         EQU 2     
DEF CHIP_X_LETTER       EQU 3     
DEF CHIP_X_TENS         EQU 4     
DEF CHIP_X_ONES         EQU 5     

DEF CHIP_ADDR_ICON      EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_ICON)
DEF CHIP_ADDR_X         EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_LETTER)
DEF CHIP_ADDR_TENS      EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_TENS)
DEF CHIP_ADDR_ONES      EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_ONES)

SECTION "WRAM CHIPS", WRAM0
wChips:           ds 1   

SECTION "ChipCount Code", ROM0
EXPORT ChipCount_Reset, ChipCount_SetA, ChipCount_AddA
EXPORT ChipCount_HUD_Init, ChipCount_HUD_Update

ChipCount_Reset:
  xor a
  ld [wChips], a
  ret

ChipCount_SetA:
  cp $64              
  jr c, .ok
  ld a, $63           
.ok:
  ld [wChips], a
  ret

ChipCount_AddA:
  ld c, a             
  ld hl, wChips
  ld a, [hl]
  add c
  jr c, .sat          
  cp $64
  jr c, .store
.sat:
  ld a, $63
.store:
  ld [hl], a
  ret

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
