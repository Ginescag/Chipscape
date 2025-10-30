INCLUDE "constantes.inc"

SECTION "Scene Helper", ROM0 

set_entity::
  push hl               ;;ETQ DE LA ENTIDAD
  call man_entity_alloc ;;HL = DIR DEL ARRAY DE ENTIDADES

  ld d, CMP_INFO_H
  ld e, l

  pop hl

  ld b, CMP_SIZE
  push de
  push hl
  call memcpy

  pop hl 
  pop de
  push hl
  ld a, l
  add CMP_SIZE
  ld l, a

  ld d, CMP_SPRITE_H
  ld b, CMP_SIZE
  push de
  call memcpy
  
  pop de
  pop hl 
  ld a, l
  add CMP_SIZE
  add CMP_SIZE
  ld l, a

  ld d, CMP_PHYSICS_H
  ld b, CMP_SIZE
  call memcpy
ret

set_entities_count::
  .loop
      push bc
      push hl
      call set_entity
      pop  hl
      ld   de, ENTITY_TEMPLATE_STRIDE
      add  hl, de
      pop  bc
      dec  b
      jr   nz, .loop
      ret

SECTION "Scene 01 code", ROM0


sc01_init::

  call apaga_pantalla

  ;; CARGAMOS SPRITES
  ld   hl, SPRITES_START
  ld   de, VRAM_TILEDATA_START + VRAM_SPRITENC_START_POS * VRAM_TILE_SIZE
  ld   bc, SPRITES_END - SPRITES_START
  call memcpy_65535

  ;;CARGAMOS TILES
  ld hl, TilesTotal
  ld de, VRAM_TILEDATA_START + VRAM_TILES_START_POS * VRAM_TILE_SIZE
  ld bc, TilesTotalEnd - TilesTotal
  call memcpy_65535

    ;; CARGAMOS SPRITES de los chips
    ld   hl, SPRITES_START_CHIPS
    ld   de, VRAM_TILEDATA_START + VRAM_SPRITE_CHIP_START_POS * VRAM_TILE_SIZE
    ld   bc, SPRITES_END_CHIPS - SPRITES_START_CHIPS
    call memcpy_65535

    ;;CARGAMOS TILES DE LA PANTALLA DE GAME OVER
    ld hl, gameover_inic_tiles
    ld de, VRAM_TILEDATA_START + VRAM_GO_POS * VRAM_TILE_SIZE
    ld bc, gameover_fin_tiles - gameover_inic_tiles
    call memcpy_65535

    ;;CARGAMOS EL MAPA AL TILEMAP
  ld hl, Mapa1
  ld de, $9800
  ld bc, Mapa1fin - Mapa1
  call cargar_mapa

  ;;añadimos a la pantalla el hud
  call set_hud

  call enciende_pantalla


  ld   a, %11100100
  ld  [rOBP0], a
  ld  [rBGP],  a

  call man_entity_init

;;======================================================================;;
;; CARGAMOS EL PERSONAJE PRINCIPAL EL PRIMERO Y A MANO PARA OBTENER SU VELOCIDAD 
;;======================================================================;;


  call man_entity_alloc ;;C000

  ld d, CMP_INFO_H
  ld e, l
  ld hl, sc01_playerL+0
  ld b, CMP_SIZE
  push de
  call memcpy

  pop de
  ld d, CMP_SPRITE_H
  ld hl, sc01_playerL+4
  ld b, CMP_SIZE
  push de
  call memcpy
  
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, sc01_playerL+8
  ld b, CMP_SIZE
  push de                 ;;ESTO SIRVE PARA LUEGO OBTENER LAS VELOCIDADES DEL JUGADOR
  call memcpy

  pop de                  ;;OBTENEMOS PHYSICS DEL PERSONAJE
  call get_player_speed   ;;esta llamada solo hay q hacerla cuando cargas el primer split de la entidad del personaje
  
  
  call man_entity_alloc ;;C004

  ld d, CMP_INFO_H
  ld e, l
  ld hl, sc01_playerR+0
  ld b, CMP_SIZE
  push de
  call memcpy

  pop de
  ld d, CMP_SPRITE_H
  ld hl, sc01_playerR+4
  ld b, CMP_SIZE
  push de
  call memcpy
  
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, sc01_playerR+8
  ld b, CMP_SIZE
  call memcpy

;;====================================================================;;
;;  AHORA CARGAMOS EL RESTO DE ENTIDADES DE ESTA FORMA
;;====================================================================;;

  ld  hl, sc01_entities_REST
  ld  b, (sc01_entities_REST_END - sc01_entities_REST) / (CMP_SIZE*3)
  call set_entities_count

  call Scroll_Init

ret

sc01_run::
  .loop:
    call sys_player_update
    call sys_physics_update
    ld de, $C000              ;;magic exagerada posicion en el array de entidades del personaje
    call animacion_personaje
    call sys_anim_enemies_update
    call Scroll_Tick
    call wait_vblank

    call HUD_Tick
    call wait_vblank
    call HUD_Draw 
    call wait_vblank
    call man_entity_draw   
    jr .loop
  ret
