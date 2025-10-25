include "constantes.inc"
SECTION "PHYSICS CODE", ROM0 

;;DE = entidad a procesar
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


;;GO TO COORDS
;;HL -> INPUT COORDS XXYY OR YYXX
;;man_entity_for_each (que no sea el jugador) actualizar velocidades para ir a esa coord