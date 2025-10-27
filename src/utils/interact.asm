;==========================
; src/utils/interact.asm   (CORREGIDO)
;==========================
INCLUDE "constantes.inc"

; ====== Constantes locales ======
DEF CHIP_TILE_IDX       EQU $F7        ; índice VRAM del tile interactuable
DEF CMP_SPRITE_TILE     EQU 2          ; layout: X(0), Y(1), TILE(2), FLAGS(3)
DEF P1F_GET_BUTTONS     EQU $10        ; P1: seleccionar A/B/Select/Start (P15=0)
DEF PADF_A_BIT          EQU 0          ; bit0 = A (1 = pulsado)
DEF INTERACT_DIST       EQU 8          ; umbral de proximidad (px)

SECTION "WRAM Interact", WRAM0
wIntBtnPrev:      ds 1
wIntBtnNow:       ds 1

; ====== Gráfico del chip (1 tile) ======
SECTION "GFX Interact Chip", ROM0
Interact_ChipTile::
DB $24,$00,$7E,$5A,$C3,$18,$42,$7E
DB $42,$7E,$C3,$18,$7E,$5A,$24,$00

SECTION "Interact Code", ROM0

; Copia el tile del chip a VRAM en CHIP_TILE_IDX
Interact_LoadTiles::
    call wait_vblank
    ld  hl, Interact_ChipTile
    ld  de, VRAM_TILEDATA_START + CHIP_TILE_IDX * VRAM_TILE_SIZE
    ld  b, 16
    call memcpy
    ret

; Lee botones (A/B/Select/Start). Devuelve en A, 1 = pulsado
interact_read_buttons::
    ld   a, P1F_GET_BUTTONS
    ld  [rP1], a
    ld   a, [rP1]
    cpl
    and  %00001111
    ret

; Interact_Abs8: |A| (A firmado). Devuelve |A| en A  (GLOBAL, sin etiqueta local)
Interact_Abs8::
    bit  7, a
    ret  z
    cpl
    inc  a
    ret

; Procesa UNA entidad: si es chip y A se pulsa (flanco) estando cerca del jugador,
; incrementa el contador de chips en 1.
; Entrada: DE -> &component_info[offset] de la entidad
; Usa: A,B,C,H,L
sys_interact_update_one_entity::
    ; ¿esta entidad usa el tile del chip?
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_TILE
    ld   l, a
    ld   a, [hl]
    cp   CHIP_TILE_IDX
    ret  nz

    ; ¿A recién pulsado?
    ld   a, [wIntBtnNow]
    bit  PADF_A_BIT, a
    ret  z
    ld   a, [wIntBtnPrev]
    bit  PADF_A_BIT, a
    ret  nz

    ; |dx| = |wPX - ex|
    ; ex
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_X
    ld   l, a
    ld   a, [hl]
    ld   c, a                        ; C = ex
    ; px
    ld   a, [wPX]                    ; A = px
    sub  c                           ; A = px - ex
    call Interact_Abs8
    cp   INTERACT_DIST+1
    jr   nc, .far

    ; |dy| = |wPY - ey|
    ; ey
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_Y
    ld   l, a
    ld   a, [hl]
    ld   c, a                        ; C = ey
    ; py
    ld   a, [wPY]                    ; A = py
    sub  c                           ; A = py - ey
    call Interact_Abs8
    cp   INTERACT_DIST+1
    jr   nc, .far

    ; Dentro de rango y A recién pulsado -> sumar 1 chip
    ld   a, 1
    call ChipCount_AddA
.far:
    ret

; Itera todas las entidades y aplica la lógica de interacción
sys_interact_update::
    call interact_read_buttons
    ld  [wIntBtnNow], a
    ld   hl, sys_interact_update_one_entity
    call man_entity_for_each
    ; latch de botones al final del frame
    ld   a, [wIntBtnNow]
    ld  [wIntBtnPrev], a
    ret
