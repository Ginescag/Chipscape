INCLUDE "constantes.inc"


SECTION "Player Animation", ROM0

; ------------------------------------------------------------
; animacion_personaje
; Alterna base<->(base+4) por dirección de movimiento.
; IN : DE = &component_info[offset] de la COLUMNA IZQUIERDA del player
; OUT: Actualiza CMP_SPRITE_TI de IZQ (esta entidad) y DER (siguiente slot)
; TR : A,B,C,H,L (D/E queda apuntando a la entidad de la derecha al final)
; ------------------------------------------------------------
animacion_personaje::
    ; ===== 1) Lee PH_VX/PH_VY para decidir dirección =====
    ; vx -> B, vy -> C (signed)
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VX
    ld   l, a
    ld   a, [hl]
    ld   b, a         ; B = vx

    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VY
    ld   l, a
    ld   a, [hl]
    ld   c, a         ; C = vy

    ; si está parado, no animar
    ld   a, b
    or   c
    ret  z

    ; prioridad horizontal: L/R si vx≠0, si no U/D por vy
    ; A y C/B libres, usamos A para decidir
    ld   a, b
    bit  7, a
    jr   z, .check_r
    ; vx < 0 -> LEFT
    ld   a, TILE_FL_Ll
    ld   c, TILE_FL_Lr
    jr   .do_anim
.check_r:
    ld   a, b
    or   a
    jr   z, .check_u
    ; vx > 0 -> RIGHT
    ld   a, TILE_FL_Rl
    ld   c, TILE_FL_Rr
    jr   .do_anim
.check_u:
    ld   a, c
    bit  7, a
    jr   z, .down
    ; vy < 0 -> UP
    ld   a, TILE_FL_Ul
    ld   c, TILE_FL_UR
    jr   .do_anim
.down:
    ; vy > 0 -> DOWN
    ld   a, TILE_FL_Dl
    ld   c, TILE_FL_Dr

.do_anim:
    ; ===== 2) Alterna IZQUIERDA (esta entidad) =====
    ; HL = &CMP_SPRITE_TI (izq)
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   b, a              ; B = base_left (guárdalo)
    ld   a, l
    add  CMP_SPRITE_TI
    ld   l, a
    ld   a, [hl]           ; a = tile actual (izq)
    cp   b
    jr   z, .L_to_comp     ; si está en base -> pasa a comp (+4)
    ; si no está en base, fuerza a base (soporta cambios de dir)
    ld   a, b
    ld  [hl], a
    jr   .do_right
.L_to_comp:
    ld   a, b
    add  a, 4
    ld  [hl], a

.do_right:
    ; ===== 3) Alterna DERECHA (siguiente slot) =====
    ; E = E + CMP_SIZE
    ld   a, e
    add  a, CMP_SIZE
    ld   e, a

    ; HL = &CMP_SPRITE_TI (der)
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_TI
    ld   l, a

    ld   a, [hl]           ; a = tile actual (der)
    ; C = base_right
    cp   c
    jr   z, .R_to_comp
    ; fuerza base si no es base
    ld   a, c
    ld  [hl], a
    ret
.R_to_comp:
    ld   a, c
    add  a, 4
    ld  [hl], a
    ret


SECTION "Enemy Anim Internals", ROM0    

;HOMBRE DE NEGRO O CALVO
; INPUT : DE -> entidad (columna IZQ)
; OUT: A = 0 (MIB) o 1 (BC)
get_enemy_kind::
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_TI
    ld   l, a
    ld   a, [hl]              ; A = tile actual de la izquierda

    ld   b, a                 ; guarda tile en B

    ld   a, b
    cp   TILE_MIB_Dl
    jr   z, .is_mib
    ld   a, b
    cp   TILE_MIB_Dl+4
    jr   z, .is_mib

    ld   a, b
    cp   TILE_MIB_Ll
    jr   z, .is_mib
    ld   a, b
    cp   TILE_MIB_Ll+4
    jr   z, .is_mib

    ld   a, b
    cp   TILE_MIB_Rl
    jr   z, .is_mib
    ld   a, b
    cp   TILE_MIB_Rl+4
    jr   z, .is_mib

    ld   a, b
    cp   TILE_MIB_Ul
    jr   z, .is_mib
    ld   a, b
    cp   TILE_MIB_Ul+4
    jr   z, .is_mib

    ; probar BC (Dl Ll Rl Ul)
    ld   a, b
    cp   TILE_BC_Dl
    jr   z, .is_bc
    ld   a, b
    cp   TILE_BC_Dl+4
    jr   z, .is_bc

    ld   a, b
    cp   TILE_BC_Ll
    jr   z, .is_bc
    ld   a, b
    cp   TILE_BC_Ll+4
    jr   z, .is_bc

    ld   a, b
    cp   TILE_BC_Rl
    jr   z, .is_bc
    ld   a, b
    cp   TILE_BC_Rl+4
    jr   z, .is_bc

    ld   a, b
    cp   TILE_BC_Ul
    jr   z, .is_bc
    ld   a, b
    cp   TILE_BC_Ul+4
    jr   z, .is_bc

.is_mib:
    xor  a        ; A=0 (MIB)
    ret
.is_bc:
    ld   a, 1     ; A=1 (BC)
    ret



; INPUT : A = 0 MIB / 1 BC D = dir (0D,1U,2L,3R) 
; OUT: B = baseL, C = baseR
; TR : A,H,L
choose_base::
    cp  0
    jr  nz, CIC
    ; --- MIB ---
    ld  a, d
    cp  0         ; DOWN
    jr  nz, .mib_up
        ld b, TILE_MIB_Dl
        ld c, TILE_MIB_Dr
        ret
.mib_up:
    cp  1
    jr  nz, .mib_left
        ld b, TILE_MIB_Ul
        ld c, TILE_MIB_Ur
        ret
.mib_left:
    cp  2
    jr  nz, .mib_right
        ld b, TILE_MIB_Ll
        ld c, TILE_MIB_Lr
        ret
.mib_right:
        ld b, TILE_MIB_Rl
        ld c, TILE_MIB_Rr
        ret

CIC:
    ; --- BC (científico calvo) ---
    ld  a, d
    cp  0         ; DOWN
    jr  nz, CIC_up
        ld b, TILE_BC_Dl
        ld c, TILE_BC_Dr
        ret
CIC_up:
    cp  1
    jr  nz, CIC_left
        ld b, TILE_BC_Ul
        ld c, TILE_BC_Ur
        ret
CIC_left:
    cp  2
    jr  nz, CIC_right
        ld b, TILE_BC_Ll
        ld c, TILE_BC_Lr
        ret
CIC_right:
        ld b, TILE_BC_Rl
        ld c, TILE_BC_Rr
        ret


alterna_sprites_enemigos::
    ; --- IZQUIERDA ---
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_TI
    ld   l, a
    ld   a, [hl]          ; a = tile L actual
    cp   b
    jr   z, .L_to_comp
    ld   a, b
    ld  [hl], a
    jr   .do_right
.L_to_comp:
    ld   a, b
    add  a, 4
    ld  [hl], a

.do_right:
    ; --- DERECHA (siguiente slot) ---
    ld   a, e
    add  a, CMP_SIZE
    ld   e, a
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_TI
    ld   l, a
    ld   a, [hl]          ; a = tile R actual
    cp   c
    jr   z, .R_to_comp
    ld   a, c
    ld  [hl], a
    ret
.R_to_comp:
    ld   a, c
    add  a, 4
    ld  [hl], a
    ret


SECTION "Enemy Anim Public", ROM0

; ------------------------------------------------------------
; sys_anim_enemies_update_one
; DE -> entidad (se procesan SOLO izquierdas; derecha se anima desde aquí)
; Filtro: TYPE con T_ENEMY y (VX!=0 o VY!=0)
; Detección de set: por tile actual de la IZQUIERDA (MIB vs BC)
; Dirección: prioridad X (L/R), si no U/D
; ------------------------------------------------------------
sys_anim_enemies_update_one::
    ; INFO.TYPE
    ld   h, CMP_INFO_H
    ld   l, e
    ld   a, l
    add  CMP_INFO_TYPE
    ld   l, a
    ld   a, [hl]
    bit  T_ENEMY, a
    ret  z                        ; no enemigo

    ; SPRITE.TI para detectar si es izquierda o derecha:
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_TI
    ld   l, a
    ld   a, [hl]
    ; ¿pertenece a alguno de los RIGHT bases (MIB_Rr/Dr/Lr/Ur y BC_Rr/Dr/Lr/Ur) o sus +4?
    cp   TILE_MIB_Dr
    ret  z
    cp   TILE_MIB_Dr+4
    ret  z
    cp   TILE_MIB_Lr
    ret  z
    cp   TILE_MIB_Lr+4
    ret  z
    cp   TILE_MIB_Rr
    ret  z
    cp   TILE_MIB_Rr+4
    ret  z
    cp   TILE_MIB_Ur
    ret  z
    cp   TILE_MIB_Ur+4
    ret  z
    ; BC right set:
    cp   TILE_BC_Dr
    ret  z
    cp   TILE_BC_Dr+4
    ret  z
    cp   TILE_BC_Lr
    ret  z
    cp   TILE_BC_Lr+4
    ret  z
    cp   TILE_BC_Rr
    ret  z
    cp   TILE_BC_Rr+4
    ret  z
    cp   TILE_BC_Ur
    ret  z
    cp   TILE_BC_Ur+4
    ret  z
    ; si no es "derecha", la tratamos como "izquierda" y seguimos

    ; PHYSICS: ¿tiene velocidad?
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VX
    ld   l, a
    ld   a, [hl]
    ld   b, a         ; vx
    ld   a, l
    ld   a, [hl+]
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VY
    ld   l, a
    ld   a, [hl]
    ld   c, a         ; vy
    ld   a, b
    or   c
    ret  z            ; sin movimiento => no animar

    ; Dirección (prioridad X)
    ; D = 0 DOWN, 1 UP, 2 LEFT, 3 RIGHT
    ld   d, 0
    ld   a, b
    bit  7, a
    jr   z, .chk_r
    ld   d, 2             ; LEFT
    jr   .dir_ok
.chk_r:
    ld   a, b
    or   a
    jr   z, .chk_u
    ld   d, 3             ; RIGHT
    jr   .dir_ok
.chk_u:
    ld   a, c
    bit  7, a
    jr   z, .down
    ld   d, 1             ; UP
    jr   .dir_ok
.down:
    ld   d, 0             ; DOWN
.dir_ok:

    ;¿MIB o BC?
    push de
    call get_enemy_kind     ; A = 0 MIB / 1 BC
    ld   b, a
    pop  de

    ; bases (B,C) según dir y tipo
    ld   a, b
    call choose_base        ; B=baseL, C=baseR

    ; alternar base<->base+4 en ambas columnas
    jp   alterna_sprites_enemigos


sys_anim_enemies_update::
    ld   hl, sys_anim_enemies_update_one
    call man_entity_for_each
    ret
