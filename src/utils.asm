INCLUDE "inc/hardware.inc"

SECTION "Utils", ROM0

EXPORT CopyBytes, WaitVBlank, ClearOAM, HideUnusedSprites

CopyBytes:
  ld a, b
  or c
  ret z
.loop:
  ld a, [de]
  ld [hl], a
  inc de
  inc hl
  dec bc
  ld a, b
  or c
  jr nz, .loop
  ret


EXPORT WaitVBlank
WaitVBlank:
.wait_out:
  ld  a, [rLY]
  cp  144
  jr  nc, .wait_out  

.wait_in:
  ld  a, [rLY]
  cp  144
  jr  c,  .wait_in   
  ret


EXPORT ClearOAM
ClearOAM:
  ld hl, OAM_BASE
  ld de, 4
  ld b, 40
  xor a
.co_loop:
  ld [hl], a        
  add hl, de        
  dec b
  jr nz, .co_loop
  ret

EXPORT HideUnusedSprites
HideUnusedSprites:
  ld hl, OAM_BASE + (4*4)
  ld de, 4
  ld b, 36
  xor a
.hus_loop:
  ld [hl], a        
  add hl, de
  dec b
  jr nz, .hus_loop
  ret
