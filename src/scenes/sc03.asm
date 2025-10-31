INCLUDE "constantes.inc"



SECTION "Scene 03 code", ROM0


sc03_init::

  call apaga_pantalla
  call BORRAR_OAM

    ;;CARGAMOS EL MAPA AL TILEMAP
  ld hl, mapa3
  ld de, $9800
  ld bc, mapa3fin - mapa3
  call cargar_mapa

  call set_hud

  call enciende_pantalla


  ld   a, %11100100
  ld  [rOBP0], a
  ld  [rBGP],  a

  call man_entity_init
  call patrol_global_init


  call man_entity_alloc 

  ld d, CMP_INFO_H
  ld e, l
  ld hl, sc03_playerL+0
  ld b, CMP_SIZE
  push de
  call memcpy

  pop de
  ld d, CMP_SPRITE_H
  ld hl, sc03_playerL+4
  ld b, CMP_SIZE
  push de
  call memcpy
  
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, sc03_playerL+8
  ld b, CMP_SIZE
  push de                 ;;ESTO SIRVE PARA LUEGO OBTENER LAS VELOCIDADES DEL JUGADOR
  call memcpy

  pop de                  ;;OBTENEMOS PHYSICS DEL PERSONAJE
  call get_player_speed   ;;esta llamada solo hay q hacerla cuando cargas el primer split de la entidad del personaje
  
  
  call man_entity_alloc ;;C004

  ld d, CMP_INFO_H
  ld e, l
  ld hl, sc03_playerR+0
  ld b, CMP_SIZE
  push de
  call memcpy

  pop de
  ld d, CMP_SPRITE_H
  ld hl, sc03_playerR+4
  ld b, CMP_SIZE
  push de
  call memcpy
  
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, sc03_playerR+8
  ld b, CMP_SIZE
  call memcpy


  ld  hl, sc03_entities_REST
  ld  b, (sc03_entities_REST_END - sc03_entities_REST) / (CMP_SIZE*3)
  call set_entities_count

  call Scroll_Init
  call Interact_Init2

ret

sc03_run::
  .loop:
    call sys_player_update
    call patrol_global_tick
    call sys_physics_update
    
    ld de, $C000              ;;magic exagerada posicion en el array de entidades del personaje
    call check_player_cross_any_and_gameover
    ld de, $C000              ;;magic exagerada posicion en el array de entidades del personaje
    call animacion_personaje
    call sys_anim_enemies_update
    call Scroll_Tick
    call Interact_Tick
    call HUD_Tick
    call wait_vblank
    call HUD_Draw 
    call wait_vblank
    call man_entity_draw   
    jr .loop
  ret
