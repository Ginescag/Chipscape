;==========================
; src/scenes/sc01.asm   (COMPLETO + PROTOTIPO DEL CHIP)
;==========================
INCLUDE "constantes.inc"

SECTION "Scene 01 code", ROM0

sc01_init::

  ; --- Carga de gráficos de la escena ---
  call wait_vblank
  ld hl, FLATLINE_front0
  ld de, VRAM_TILEDATA_START + $1A * VRAM_TILE_SIZE
  ld b, 64
  call memcpy

  call wait_vblank
  ld hl, FLATLINE_front1
  ld de, VRAM_TILEDATA_START + $1E * VRAM_TILE_SIZE
  ld b, 64
  call memcpy

  ; --- Paletas ---
  ld   a, %11100100
  ld  [rOBP0], a
  ld  [rBGP],  a

  ; --- HUD de chips + tile interactuable ---
  call ChipCount_LoadTiles
  call ChipCount_Reset
  call ChipCount_HUD_Init
  call Interact_LoadTiles

  ; --- Entidades ---
  call man_entity_init

  ; ===== jugador =====
  call man_entity_alloc    ;; C000
  ld d, CMP_INFO_H
  ld e, l
  ld hl, sc01_entity1+0
  ld b, CMP_SIZE
  push de
  call memcpy

  pop de
  ld d, CMP_SPRITE_H
  ld hl, sc01_entity1+4
  ld b, CMP_SIZE
  push de
  call memcpy
  
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, sc01_entity1+8
  ld b, CMP_SIZE
  call memcpy
  
  ; ===== segunda entidad =====
  call man_entity_alloc    ;; C004
  ld d, CMP_INFO_H
  ld e, l
  ld hl, sc01_entity2+0
  ld b, CMP_SIZE
  push de
  call memcpy

  pop de
  ld d, CMP_SPRITE_H
  ld hl, sc01_entity2+4
  ld b, CMP_SIZE
  push de
  call memcpy
  
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, sc01_entity2+8
  ld b, CMP_SIZE
  call memcpy

  ; ===== chip interactuable cerca del spawn =====
  call man_entity_alloc    ;; C008
  ld d, CMP_INFO_H
  ld e, l
  ld hl, sc01_entity_chip+0
  ld b, CMP_SIZE
  push de
  call memcpy

  pop de
  ld d, CMP_SPRITE_H
  ld hl, sc01_entity_chip+4
  ld b, CMP_SIZE
  push de
  call memcpy

  pop de
  ld d, CMP_PHYSICS_H
  ld hl, sc01_entity_chip+8
  ld b, CMP_SIZE
  call memcpy

  ; --- Scroll / cámara ---
  call Scroll_Init
  ret


sc01_run::
.loop:
  call sys_player_update
  call sys_physics_update
  call sys_interact_update     ; interacción “A” con chip
  call Scroll_Tick
  call wait_vblank

  call HUD_Tick
  call wait_vblank
  call HUD_Draw
  call wait_vblank
       
  call man_entity_draw
  jr .loop
  ret

; ===== Prototipo del chip para esta escena (mismo archivo, evita símbolo indefinido) =====
SECTION "sc01 chip proto", ROM0
; INFO / SPRITE / PHYSICS (sin movimiento), cerca del spawn (jugador ~80,80)
; TILE = $F7 (CHIP_TILE_IDX)
sc01_entity_chip::
    DB CMP_RESERVE, %01110101, %00000000, 03
    DB 96, 80, $F7, %00000000
    DB 96, 80, 00, 00
