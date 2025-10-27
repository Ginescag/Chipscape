INCLUDE "constantes.inc"

SECTION "Scene 01 code", ROM0

sc01_init::

  call apaga_pantalla
  ; HL = inicio de datos
  ld   hl, SPRITES_START
  ; DE = $8000 + $1A * 16
  ld   de, VRAM_TILEDATA_START + $1A * VRAM_TILE_SIZE
  ; BC = tamaño total (bytes)
  ld   bc, SPRITES_END - SPRITES_START

  call memcpy_65535

  call enciende_pantalla
  ; call wait_vblank
  ; ld hl, FLATLINE_front0
  ; ld de, VRAM_TILEDATA_START + $1A * VRAM_TILE_SIZE
  ; ld b, 64
  ; call memcpy

  ; call wait_vblank
  ; ld hl, FLATLINE_front1
  ; ld de, VRAM_TILEDATA_START + $1E * VRAM_TILE_SIZE
  ; ld b, 64
  ; call memcpy

  ld   a, %11100100
  ld  [rOBP0], a
  ld  [rBGP],  a

  call man_entity_init

  ;; INIT ENTITIES PREGUNTAR AL PROFESOR
  call man_entity_alloc ;;C000

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
  push de                 ;;ESTO SIRVE PARA LUEGO OBTENER LAS VELOCIDADES DEL JUGADOR
  call memcpy

  pop de                  ;;OBTENEMOS PHYSICS DEL PERSONAJE
  call get_player_speed   ;;esta llamada solo hay q hacerla cuando cargas el primer split de la entidad del personaje
   
  
  call man_entity_alloc ;;C004

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

  call Scroll_Init

ret

sc01_run::
  .loop:
    call sys_player_update
    call sys_physics_update
    call Scroll_Tick
    call wait_vblank

    call HUD_Tick
    call wait_vblank
    call HUD_Draw    
    call wait_vblank  
    call man_entity_draw    
    jr .loop
  ret
