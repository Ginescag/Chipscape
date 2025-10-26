INCLUDE "constantes.inc"

SECTION "Player Speed", WRAM0
wPlayerSpeedL:  ds 1   ; magnitud de velocidad X
wPlayerSpeedR:  ds 1   ; magnitud de velocidad Y
wPlayerSpeedU:  ds 1 
wPlayerSpeedD:  ds 1 


SECTION "Player Movement", ROM0

get_player_speed::
    push de
    ld a, e
    add CMP_PH_VX
    ld e, a 
    ld a, [de]
    ld [wPlayerSpeedR], a
    cpl
    inc a

    ld [wPlayerSpeedL], a
    
    pop de
    ld a, e
    add CMP_PH_VY
    ld e, a 
    ld a, [de]
    ld [wPlayerSpeedD], a
    cpl
    inc a 
    ld [wPlayerSpeedU], a
ret


; -------------------------------------------------
; player_cache_speed_from_entity
; DE -> &component_info[offset] del PLAYER
; Lee PH_VX/PH_VY y los guarda en wPlayerSpeedX/Y.
; -------------------------------------------------
player_read_dpad::
    ld   a, P1F_GET_DPAD   ; seleccionar D-pad
    ld  [rP1], a
    ld   a, [rP1]
    cpl                    ; en Game Boy 0=pulsado -> lo invertimos
    and  %00001111         ; nos quedamos con Right,Left,Up,Down
    ret



;; ESTO DABA BUG POR USAR BIT Y NO AND, ESTE CODIGO ES LEGACY POR SI HACE FALTA PARA ALGO
    ; =========================================================
; Procesa UNA entidad: si es PLAYER, escribe PH_VX/PH_VY
; Entrada: DE -> &component_info[offset] de la entidad
; Trashes: A, B, C, H, L
; =========================================================
; sys_player_update_one_entity::
;     ld   h, CMP_INFO_H
;     ld   l, e
;     ld   a, l
;     add  CMP_INFO_TYPE
;     ld   l, a
;     ld   a, [hl]
;     bit  T_PLAYER, a         ; bit7 = player
;     ret  z                   ; si no es player, salir

;     ; --- leer D-pad ---
;     call player_read_dpad    ; A = PAD mask (1=pulsado)

;     ; --- VX = (Right) - (Left) ---
 
;     ld   b, 0
;     bit  PADF_RIGHT_BIT, a              
;     jr   z, .no_r
;     ld a, [wPlayerSpeedR]
;     ld b, a
; .no_r:
;     bit  PADF_LEFT_BIT, a
;     jr   z, .no_l
;     ld a, [wPlayerSpeedL]
;     ld b, a
; .no_l:
;     ld   c, 0
;     bit  PADF_DOWN_BIT, a               
;     jr   z, .no_d
;     ld a, [wPlayerSpeedD]
;     ld c, a
; .no_d:
;     bit  PADF_UP_BIT, a
;     jr   z, .no_u
;     ld a, [wPlayerSpeedU]
;     ld c, a
; .no_u:

;     ; --- escribir PH_VX ---
;     ld   h, CMP_PHYSICS_H
;     ld   l, e
;     ld   a, l
;     add  CMP_PH_VX
;     ld   l, a                ; HL = &PH_VX
;     ld   a, b               
;     ld  [hl], a

;     ; --- escribir PH_VY ---
;     ld   h, CMP_PHYSICS_H
;     ld   l, e
;     ld   a, l
;     add  CMP_PH_VY
;     ld   l, a                ; HL = &PH_VY
;     ld   a, c                ; A = vy (-1/0/+1) (abajo es positivo)
;     ld  [hl], a
; ret

; DE -> &component_info[offset] de la entidad
sys_player_update_one_entity::
    ; ¿es player?
    ld   h, CMP_INFO_H
    ld   l, e
    ld   a, l
    add  CMP_INFO_TYPE
    ld   l, a
    ld   a, [hl]
    bit  T_PLAYER, a
    ret  z

    ; lee pad
    call player_read_dpad
    ld   d, a               ; D = copia de teclas

    ; ------- VX -------
    ld   b, 0
    ld   a, d
    and  PADF_RIGHT
    jr   z, .noR
      ld   a, [wPlayerSpeedR]
      ld   b, a
.noR:
    ld   a, d
    and  PADF_LEFT
    jr   z, .noL
      ld   a, [wPlayerSpeedL]
      ld   b, a
.noL:

    ; ------- VY (abajo positivo) -------
    ld   c, 0
    ld   a, d
    and  PADF_DOWN
    jr   z, .noD
      ld   a, [wPlayerSpeedD]
      ld   c, a
.noD:
    ld   a, d
    and  PADF_UP
    jr   z, .noU
      ld   a, [wPlayerSpeedU]
      ld   c, a
.noU:

    ; PH_VX = b
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VX
    ld   l, a
    ld   a, b
    ld  [hl], a

    ; PH_VY = c
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VY
    ld   l, a
    ld   a, c
    ld  [hl], a
    ret

sys_player_update::
    ld   hl, sys_player_update_one_entity
    call man_entity_for_each
ret
