INCLUDE "constantes.inc"

SECTION "Scene 01 code", ROM0

;; INIT METE TILES Y PALETA Y DEMAS
sc01_init::

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



  ld   a, %11100100
  ld  [rOBP0], a
  ld [rBGP], a

  call man_entity_init

  ;; INIT ENTITIES
  call man_entity_alloc ;;C000

  ld d, CMP_SPRITE_H
  ld e, l
  ld hl, (sc01_entity1+0)
  ld b, CMP_SIZE
  push de
  call memcpy
  
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, (sc01_entity1+4)
  ld b, CMP_SIZE
  call memcpy
  
  call man_entity_alloc ;;C000

  ld d, CMP_SPRITE_H
  ld e, l
  ld hl, (sc01_entity2+0)
  ld b, CMP_SIZE
  push de
  call memcpy
  
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, (sc01_entity2+4)
  ld b, CMP_SIZE
  call memcpy
ret


;; BUCLE PRINCIPAL DE LA PANTALLA QUE VOY A JUGAR
sc01_run::
  .loop:
  call sys_physics_update
  call wait_vblank
  call man_entity_draw
  jr .loop
ret
