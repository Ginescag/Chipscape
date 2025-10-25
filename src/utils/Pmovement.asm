INCLUDE "constantes.inc"

SECTION "Player Movement", ROM0

; =========================================================
; Lee D-pad (sin depender de interrupciones)
; Devuelve: A = bits PADF_RIGHT/LEFT/UP/DOWN (1 = pulsado)
; Trashes:  A
; =========================================================
player_read_dpad::
    ld   a, P1F_GET_DPAD   ; seleccionar D-pad
    ld  [rP1], a
    ld   a, [rP1]
    cpl                    ; en Game Boy: 0=pulsado -> lo invertimos
    and  %00001111         ; nos quedamos con Right,Left,Up,Down
    ret


; =========================================================
; Procesa UNA entidad: si es PLAYER, escribe PH_VX/PH_VY
; Entrada: DE -> &component_info[offset] de la entidad
; Trashes: A, B, C, H, L
; =========================================================
sys_player_update_one_entity::
    ; --- ¿es jugador? (comprobamos CMP_INFO_TYPE bit7) ---
    ld   h, CMP_INFO_H
    ld   l, e
    ld   a, l
    add  CMP_INFO_TYPE
    ld   l, a
    ld   a, [hl]
    bit  T_PLAYER, a         ; bit7 = player
    ret  z                   ; si no es player, salir

    ; --- leer D-pad ---
    call player_read_dpad    ; A = PAD mask (1=pulsado)

    ; --- VX = (Right) - (Left) ---
    ; b = (A & RIGHT)?1:0
    ld   b, 0
    bit  PADF_RIGHT_BIT, a                ; PADF_RIGHT = bit0 en tus constantes
    jr   z, .no_r
    inc  b
.no_r:
    ; b -= (A & LEFT)?1:0
    bit  PADF_LEFT_BIT, a                ; PADF_LEFT = bit1
    jr   z, .no_l
    dec  b
.no_l:

    ; --- VY = (Down) - (Up) ---
    ; c = (A & DOWN)?1:0
    ld   c, 0
    bit  PADF_DOWN_BIT, a                ; PADF_DOWN = bit3
    jr   z, .no_d
    inc  c
.no_d:
    ; c -= (A & UP)?1:0
    bit  PADF_UP_BIT, a                ; PADF_UP = bit2
    jr   z, .no_u
    dec  c
.no_u:

    ; --- escribir PH_VX ---
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VX
    ld   l, a                ; HL = &PH_VX
    ld   a, b                ; A = vx (-1/0/+1)
    ld  [hl], a

    ; --- escribir PH_VY ---
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VY
    ld   l, a                ; HL = &PH_VY
    ld   a, c                ; A = vy (-1/0/+1) (abajo positivo)
    ld  [hl], a

    ret


; =========================================================
; Itera todas las entidades y aplica sys_player_update_one_entity
; Usa tu man_entity_for_each, que ya filtra por ALIVE y para en centinela.
; =========================================================
sys_player_update::
    ld   hl, sys_player_update_one_entity
    call man_entity_for_each
    ret
