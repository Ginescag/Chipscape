
INCLUDE "constantes.inc"

DEF BG_MAP_BASE             EQU $9800   
DEF CHIP_TILE_ID            EQU $D4     
DEF CHIP_REPLACE_TILE_ID    EQU $80     

SECTION "Chip Pickup", ROM0

ChipPickup_Tick::
    push af
    push bc
    push de
    push hl

    
    ld   a, [wPX]
    ld   b, a
    ld   a, [wCamX]
    add  a, b
    sub  4
    ld   c, a
    srl  c
    srl  c
    srl  c                    

    ld   a, [wPY]
    ld   b, a
    ld   a, [wCamY]
    add  a, b
    sub  1
    ld   b, a
    srl  b
    srl  b
    srl  b                    

    
    ld   d, 0
    ld   e, b                 
    sla  e
    rl   d
    sla  e
    rl   d
    sla  e
    rl   d
    sla  e
    rl   d
    sla  e
    rl   d
    ld   a, e
    add  a, c
    ld   e, a
    jr   nc, .no_carry
    inc  d
.no_carry:
    ld   hl, $9800
    add  hl, de               
    
    ld   a, [hl]
    cp   CHIP_TILE_ID
    jr   nz, .done
    
    ld   a, 1
    push hl
    call ChipCount_AddA
    pop hl
    ld   a, CHIP_REPLACE_TILE_ID
    ld   [hl], a

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
