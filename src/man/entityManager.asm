INCLUDE "constantes.inc"

SECTION "Entity Manager Data", WRAM0

SECTION "Entity Manager cmp INFO", WRAM0[$C000]
components::
component_info::     DS CMP_ARR_BYTES
component_sentinel:: DS 1 ;; SENTINEL

SECTION "Entity Manager cmp SPRITE", WRAM0[$C100]
component_sprite::  DS CMP_ARR_BYTES
                   

SECTION "Entity Manager cmp PHYSICS", WRAM0[$C200]
component_physics:: DS CMP_ARR_BYTES
                    
SECTION "Entity Manager Code", ROM0

man_entity_init::
    ;;WRITE SENTINEL
    ld a, CMP_SENTINEL
    ld [component_sentinel], a

    ;;INIT EVERY CMP AS FREE
    ld hl, components
    ld de, CMP_SIZE
    ld b, NUM_ENTITIES
    .loop:
        ld [hl], CMP_FREE
        add hl, de
        dec b
    jr nz, .loop
    
    ;;zero all cmp sprites
    ld hl, component_sprite
    ld b, CMP_ARR_BYTES
    xor a
    call memset_256 
ret

;;HL -> dir del primer hueco libre en el array de entidades
;;PARA USAR ESTO TIENES QUE SABER Q SE VA A ENCONTRAR UNA POSICION LIBRE
man_entity_find_first_free::
    ld hl, component_info
    ld de, CMP_SIZE
    ld a, CMP_FREE
    .loop:
    cp [hl]
    ret z
    add hl, de
jr .loop


;RETURN HL _> MEMADDR of SPRITE COMPONENT
man_entity_alloc::
    call man_entity_find_first_free
    ld [hl], CMP_RESERVE
ret

;; input HL -> direccion de la rutina de procesamiento
man_entity_for_each::
    ld de, components
    .loop:
    ;;vemos si hemos llegado al centinela
    ld a, [de]
    cp CMP_SENTINEL 
    ret z
    bit CMP_INFO_BIT_ALIVE, a
    jr z, .next
    ;;si no hemos llegado al final procesamos el componente
    push de
    push hl
    call helper_call_HL
    pop hl
    pop de
    ;;pasamos al siguiente
    .next:
    ld a, e
    add a, CMP_SIZE
    ld e, a
    ld a, d
    adc 0
    ld d, a
jr .loop

man_entity_draw:: ;;PONER EN LA OAM ESTO NO TIENE QUE ESTAR AQUI
    ld hl, component_sprite
    ld de, OAM_START
    ld b, CMP_ARR_BYTES
    call memcpy
ret