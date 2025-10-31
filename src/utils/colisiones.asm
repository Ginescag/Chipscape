INCLUDE "constantes.inc"

SECTION "CollisionEntities", ROM0

; --- Interval overlap (1D) ---
are_intervals_overlapping::
    ld   a, [de]           
    ld   h, a
    inc  de
    ld   a, [de]           
    ld   l, a
    dec  de
    ld   a, [bc]
    ld   d, a
    inc  bc
    ld   a, [bc]
    ld   e, a
    dec  bc

    ; ------- Caso 1: p1 >= p2 + w2 ? -------
    ld   a, d            ; A = p2
    add  a, e            ; A = p2 + w2
    jr   c, .skip_case1  ; overflow => p2+w2 >= 256 ⇒ p1 >= (p2+w2) es imposible
    ld   c, a            ; C = (p2 + w2)
    ld   a, h            ; A = p1
    sub  c               ; p1 - (p2 + w2)
    jr   nc, .no_overlap ; si p1 >= p2+w2 ⇒ NO solape

.skip_case1:
    ; ------- Caso 2: p2 >= p1 + w1 ? -------
    ld   a, h            ; A = p1
    add  a, l            ; A = p1 + w1
    jr   c, .skip_case2  ; overflow => p1+w1 >= 256 ⇒ p2 >= (p1+w1) es imposible
    ld   c, a            ; C = (p1 + w1)
    ld   a, d            ; A = p2
    sub  c               ; p2 - (p1 + w1)
    jr   nc, .no_overlap ; si p2 >= p1+w1 ⇒ NO solape

.skip_case2:
    ; Si no cayó en ningún NO solape, entonces SÍ solapan
    scf
    ret

.no_overlap:
    or   a               ; C=0
    ret

; INPUT:
;        DE: address of AABB 1
;        BC: address of AABB 2
; OUTPUT:
;   Carry: { NC: Not Colliding , C: Colliding }
are_boxes_colliding::
    ; Guardamos los punteros originales
    push de
    push bc

    ;; Check Y axis overlap
    call are_intervals_overlapping
    jr   nc, .no_collision_restore    ; Si no solapan en Y, salir

    ; Restauramos punteros originales para avanzar a X
    pop  bc
    pop  de
    ; Avanzar a X (desplazamiento +2: [x][w])
    inc  de
    inc  de
    inc  bc
    inc  bc

    ; Guardamos de nuevo antes de la segunda llamada
    push de
    push bc

    ;; Check X axis overlap
    call are_intervals_overlapping
    jr   nc, .no_collision_restore  ; Si no solapan en X, salir (tras restaurar)

    ; Solapan en Y y en X ⇒ colisión
    pop  bc
    pop  de
    scf
    ret

    .no_collision_restore:
    pop  bc
    pop  de
    or   a
ret


SECTION "AABB Temp", WRAM0
wAABB_Player:: ds 4   ; [y][h][x][w]
wAABB_Entity:: ds 4   ; [y][h][x][w]
wSkipIdxL::    ds 1   ; índice a ignorar (player izquierda)
wSkipIdxR::    ds 1   ; índice a ignorar (player derecha)

SECTION "CrossCheck CODE", ROM0

DEF PLAYER_W  EQU 8     ; pon 16 si tu player son 2 columnas (16×16)
DEF PLAYER_H  EQU 16
DEF ENEMY_W   EQU 8
DEF ENEMY_H   EQU 16

check_player_cross_any_and_gameover::
; Guardar índices a ignorar (player L/R)
ld   a, e
ld  [wSkipIdxL], a
ld   a, e
add  a, CMP_SIZE
ld  [wSkipIdxR], a

; ----- Construir AABB del player -----
; Leer X,Y del player (desde componente SPRITE)
ld   h, CMP_SPRITE_H
ld   l, e
ld   a, l
add  CMP_SPRITE_Y
ld   l, a
ld   a, [hl]              ; A = Yp
ld  [wAABB_Player+0], a
ld   a, PLAYER_H
ld  [wAABB_Player+1], a
ld   h, CMP_SPRITE_H
ld   l, e
ld   a, l
add  CMP_SPRITE_X
ld   l, a
ld   a, [hl]              ; A = Xp
ld  [wAABB_Player+2], a
ld   a, PLAYER_W
ld  [wAABB_Player+3], a

; Iterar entidades con callback
ld   hl, _aabb_overlap_one_entity
call man_entity_for_each
ret                       ; sin colisión

_aabb_overlap_one_entity::
; ignorar player L/R
ld   a, [wSkipIdxL]
cp   e
ret  z
ld   a, [wSkipIdxR]
cp   e
ret  z

; ----- Construir AABB de la entidad E (8×16 por defecto) -----
; Y
ld   h, CMP_SPRITE_H
ld   l, e
ld   a, l
add  CMP_SPRITE_Y
ld   l, a
ld   a, [hl]
ld  [wAABB_Entity+0], a
; H
ld   a, ENEMY_H
ld  [wAABB_Entity+1], a
; X
ld   h, CMP_SPRITE_H
ld   l, e
ld   a, l
add  CMP_SPRITE_X
ld   l, a
ld   a, [hl]
ld  [wAABB_Entity+2], a
; W
ld   a, ENEMY_W
ld  [wAABB_Entity+3], a

; ----- Test de solape: usa are_boxes_colliding -----
; DE = &AABB_Player, BC = &AABB_Entity
ld   de, wAABB_Player
ld   bc, wAABB_Entity
call are_boxes_colliding   ; C=1 si colisiona
jp   c, game_over_animated
ret
