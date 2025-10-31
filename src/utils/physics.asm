include "constantes.inc"


; Valor de ticks entre inversiones (ajusta a gusto)


SECTION "Global Patrol WRAM", WRAM0 [$c300]
wFlipCounter:: ds 1

SECTION "Global Patrol CODE", ROM0
DEF COUNTER_RESET EQU 50
; --- Init: poner el contador al periodo fijo ---

; Mantengo esta si ya la llamas en sitios antiguos: resetea usando wFlipPeriod.
patrol_global_init::
  ld a, COUNTER_RESET
  ld  [wFlipCounter], a
  ret

; --- Tick por frame: si llega a 0, invierte y resetea ---
patrol_global_tick::
    ld   hl, wFlipCounter
    ld   a, [hl]
    dec  a
    ld   [hl], a
    jr   nz, .done          ; aún no toca invertir

    ; invertir velocidades a la vez
    call invert_vel_all_enemies
    call patrol_global_init
.done:
    ret


; --- Iterador: invierte vel. de TODOS los enemigos ---
invert_vel_all_enemies::
    ld   hl, invert_vel_one
    call man_entity_for_each
    ret

; --- Acción por entidad: invertimos sólo ENEMIGOS ---
;     (Quita el filtro si quieres TODAS las entidades)
invert_vel_one::
    ; filtro ENEMIGO
    ld   h, CMP_INFO_H
    ld   l, e
    ld   a, l
    add  a, CMP_INFO_TYPE
    ld   l, a
    ld   a, [hl]
    bit  T_ENEMY, a
    ret  z

    ; invertir PH_VX
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  a, CMP_PH_VX
    ld   l, a
    ld   a, [hl]
    cpl
    inc  a
    ld   [hl], a

    ; invertir PH_VY
    inc  l                   ; -> PH_VY
    ld   a, [hl]
    cpl
    inc  a
    ld   [hl], a
    ret

SECTION "PHYSICS CODE", ROM0


;;DE = entidad a procesar c000
sys_physics_update_one_entity::
    ld h, CMP_PHYSICS_H
    ld d, CMP_SPRITE_H
    ld l, e
  
    push de
    push hl
    
    ld a, l
    add CMP_PH_VX
    ld l,a 
    
    ld b, [hl]
  
    ld a, e
    add CMP_SPRITE_X
    ld e, a 
    
    ld a, [de]
    add b
    ld [de], a
  
    pop hl
    pop de
  
    ld a, l
    add CMP_PH_VY
    ld l,a 
  
    ld b, [hl]
  
    ld a, e
    add CMP_SPRITE_Y
    ld e, a 
  
    ld a, [de]
    add b
    ld [de], a
    
  ret
  
  sys_physics_update::
    ld hl, sys_physics_update_one_entity
    call man_entity_for_each
  ret