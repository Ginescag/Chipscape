; ============================================================
; collision_world.asm  (FINAL)
;  - Colisión jugador↔mundo (tiles) con TileFlagsTable
;  - Copia BGMap a WRAM (wBgMapIds) y mantiene overrides (wColMapFlags)
;  - Conversión con scroll (SCX/SCY) y resolución por ejes (8x8)
; Requiere:
;   - TileFlagsTable:: (en tiles.asm, ya creada por ti)
;   - Offsets CMP_* existentes en constantes.inc (INFO/SPRITE/PHYSICS)
; API expuesta en este archivo:
;   - col_copy_bgmap_from_vram
;   - col_clear_overrides
;   - sys_player_world_collide
; ============================================================
INCLUDE "constantes.inc"

; Si no existen offsets del componente SPRITE, los definimos aquí (Y=0, X=1)
IF !DEF(CMP_SPRITE_Y)
  DEF CMP_SPRITE_Y EQU 0
ENDC
IF !DEF(CMP_SPRITE_X)
  DEF CMP_SPRITE_X EQU 1
ENDC

; ---------------- WRAM: buffers y temporales ----------------
SECTION "Collision Buffers", WRAM0[$C300]
wBgMapIds::     DS 32*32             ; 1024 bytes: copia del BG Map (IDs 0..255)
wColMapFlags::  DS 32*32             ; 1024 bytes: override por celda (0=usa tabla)

SECTION "Collision Temps", WRAM0
col_acc_x::     DS 1
col_acc_y::     DS 1
col_step_N::    DS 1
col_abs_dx::    DS 1
col_abs_dy::    DS 1
col_sign_dx::   DS 1                 ; $01 = +1, $FF = -1
col_sign_dy::   DS 1

; --------------- Constantes locales de colisión --------------
DEF COL_W_DEFAULT   EQU 8
DEF COL_H_DEFAULT   EQU 8

; --------------- Helpers: VRAM / BG base / wait safe ----------
SECTION "Collision Helpers", ROM0

; Espera modos LCD 0/1 para leer VRAM con seguridad
col_wait_vram_safe::
.wait:
    ldh  a, [$FF41]          ; STAT
    and  %00000011
    cp   2                   ; modo 2?
    jr   z, .wait
    cp   3                   ; modo 3?
    jr   z, .wait
    ret

; Base dinámica del BGMap según LCDC.3
; OUT: DE = $9800 o $9C00
col_get_bg_base::
    ldh a, [$FF40]           ; LCDC
    and %00001000            ; bit 3
    jr  z, .use_9800
    ld  de, $9C00
    ret
.use_9800:
    ld  de, $9800
    ret

; Copia el BGMap (32x32 bytes) desde VRAM -> wBgMapIds
; Úsalo al cargar escena o cuando cambie el BGMap.
col_copy_bgmap_from_vram::
    push bc
    push de
    push hl
    call col_get_bg_base     ; DE = base BGMap
    ld   hl, wBgMapIds
    ld   bc, 32*32
.copy:
    push bc
    push de
    call col_wait_vram_safe
    ld   a, [de]
    pop  de
    ld   [hl+], a
    inc  de
    pop  bc
    dec  bc
    ld   a, b
    or   c
    jr   nz, .copy
    pop  hl
    pop  de
    pop  bc
    ret

; Rellena wColMapFlags con 0 (sin overrides por celda)
col_clear_overrides::
    push hl
    push bc
    xor  a
    ld   hl, wColMapFlags
    ld   bc, 32*32
.clr:
    ld   [hl+], a
    dec  bc
    ld   a, b
    or   c
    jr   nz, .clr
    pop  bc
    pop  hl
    ret

; ----------------- Conversión pixel -> tile con scroll ----------------
; A = X (OAM/sprite) -> A = TX (0..31) con SCX aplicado
col_px_to_tx_scrolled::
    sub  8                   ; ajuste OAM X
    ld   b, a
    ldh  a, [$FF43]          ; SCX
    add  a, b
    srl  a                   ; >>3
    srl  a
    srl  a
    and  %00011111
    ret

; A = Y (OAM/sprite) -> A = TY (0..31) con SCY aplicado
col_py_to_ty_scrolled::
    sub  16                  ; ajuste OAM Y
    ld   b, a
    ldh  a, [$FF42]          ; SCY
    add  a, b
    srl  a                   ; >>3
    srl  a
    srl  a
    and  %00011111
    ret

; tx/ty -> índice lineal HL = ty*32 + tx
; IN: B=TY, C=TX ; OUT: HL = index
col_tx_ty_to_index::
    ld   h, 0
    ld   l, b
    add  hl, hl              ; *2
    add  hl, hl              ; *4
    add  hl, hl              ; *8
    add  hl, hl              ; *16
    add  hl, hl              ; *32
    ld   b, 0
    add  hl, bc              ; +TX
    ret

; ----------------- Flags efectivos en A (override -> tabla) -----------
; IN:  B=TY, C=TX
; OUT: Carry=1 si sólido (bit0)
col_get_flags_at_tx_ty::
    push hl
    push de
    call col_tx_ty_to_index          ; HL=index
    ; 1) override por celda?
    ld   de, wColMapFlags
    add  hl, de
    ld   a, [hl]
    and  a
    jr   nz, .chk_solid
    ; 2) si no, usa tabla por-ID
    call col_tx_ty_to_index          ; recomputa HL=index
    ld   de, wBgMapIds
    add  hl, de
    ld   a, [hl]                     ; A = tile ID
    ld   l, a
    ld   h, 0
    ld   de, TileFlagsTable
    add  hl, de
    ld   a, [hl]
.chk_solid:
    and  %00000001                   ; solo bit0 (SOLID)
    jr   z, .not_solid
    scf
    pop  de
    pop  hl
    ret
.not_solid:
    or   a
    pop  de
    pop  hl
    ret

; ¿Celda sólida bajo píxel DE? (D=py, E=px)
; OUT: Carry=1 si sólido
col_is_solid_at_pixel_DE::
    ld   a, d
    call col_py_to_ty_scrolled
    ld   b, a
    ld   a, e
    call col_px_to_tx_scrolled
    ld   c, a
    jp   col_get_flags_at_tx_ty

; -------------------- Resolución por eje (w/h=8x8) --------------------
; IN: D=y, E=x, B=dx (signed). OUT: E=x ajustado, Carry=1 si choque lateral
col_resolve_axis_x_8x8::
    ld   a, b
    or   a
    jr   z, .no_move_x
    bit  7, b
    jr   nz, .moving_left

.moving_right:
    ; right_edge' = (x+dx) + (w-1) , w-1 = 7
    ld   a, e
    add  a, b
    ld   e, a
    ld   a, 7
    add  a, e
    ld   e, a

    ; (y, right_edge') y (y+H-1, right_edge'), H-1=7
    ld   a, d
    ld   d, a
    call col_is_solid_at_pixel_DE
    jr   c, .collide_right
    ld   a, d
    add  a, 7
    ld   d, a
    call col_is_solid_at_pixel_DE
    jr   c, .collide_right

    ; libre → x += dx
    ld   a, e
    sub  7                  ; revertimos +7
    ld   e, a
    ld   a, e
    add  a, b
    ld   e, a
    or   a
    ret

.collide_right:
    ; x = TX*8 - SCX
    ld   a, e
    call col_px_to_tx_scrolled
    add  a, a               ; *2
    add  a, a               ; *4
    add  a, a               ; *8
    ld   c, a               ; C = TX*8
    ldh  a, [$FF43]         ; A = SCX
    ld   b, a               ; B = SCX
    ld   a, c
    sub  b                  ; A = TX*8 - SCX
    ld   e, a
    scf
    ret

.moving_left:
    ; left_edge' = x+dx
    ld   a, e
    add  a, b
    ld   e, a

    ; (y, left_edge') y (y+H-1, left_edge')
    ld   a, d
    ld   d, a
    call col_is_solid_at_pixel_DE
    jr   c, .collide_left
    ld   a, d
    add  a, 7
    ld   d, a
    call col_is_solid_at_pixel_DE
    jr   c, .collide_left

    ; libre → x += dx
    ld   a, e
    add  a, b
    ld   e, a
    or   a
    ret

.collide_left:
    ; x = TX*8 - SCX + 16
    ld   a, e
    call col_px_to_tx_scrolled
    add  a, a
    add  a, a
    add  a, a               ; TX*8
    ld   c, a
    ldh  a, [$FF43]         ; SCX
    ld   b, a
    ld   a, c
    sub  b
    add  a, 16
    ld   e, a
    scf
    ret

.no_move_x:
    or   a
    ret

; IN: D=y, E=x, C=dy (signed). OUT: D=y ajustado, Carry=1 si choque vertical
col_resolve_axis_y_8x8::
    ld   a, c
    or   a
    jr   z, .no_move_y
    bit  7, c
    jr   nz, .moving_up

.moving_down:
    ; bottom_edge' = (y+dy) + (h-1) , h-1 =7
    ld   a, d
    add  a, c
    ld   d, a
    ld   a, 7
    add  a, d
    ld   d, a

    ; (bottom_edge', x) y (bottom_edge', x+w-1)
    ld   a, e
    ld   e, a
    call col_is_solid_at_pixel_DE
    jr   c, .collide_down
    ld   a, e
    add  a, 7
    ld   e, a
    call col_is_solid_at_pixel_DE
    jr   c, .collide_down

    ; libre → y += dy
    ld   a, d
    sub  7
    ld   d, a
    ld   a, d
    add  a, c
    ld   d, a
    or   a
    ret

.collide_down:
    ; y = TY*8 - SCY + 8
    ld   a, d
    call col_py_to_ty_scrolled
    add  a, a
    add  a, a
    add  a, a               ; TY*8
    ld   c, a
    ldh  a, [$FF42]         ; SCY
    ld   b, a
    ld   a, c               ; A = TY*8
    sub  b                  ; A = TY*8 - SCY
    add  a, 8
    ld   d, a
    scf
    ret

.moving_up:
    ; top_edge' = y+dy
    ld   a, d
    add  a, c
    ld   d, a

    ; (top_edge', x) y (top_edge', x+w-1)
    ld   a, e
    ld   e, a
    call col_is_solid_at_pixel_DE
    jr   c, .collide_up
    ld   a, e
    add  a, 7
    ld   e, a
    call col_is_solid_at_pixel_DE
    jr   c, .collide_up

    ; libre → y += dy
    ld   a, d
    add  a, c
    ld   d, a
    or   a
    ret

.collide_up:
    ; y = TY*8 - SCY + 24
    ld   a, d
    call col_py_to_ty_scrolled
    add  a, a
    add  a, a
    add  a, a               ; TY*8
    ld   c, a
    ldh  a, [$FF42]         ; SCY
    ld   b, a
    ld   a, c
    sub  b
    add  a, 24
    ld   d, a
    scf
    ret

.no_move_y:
    or   a
    ret


; ---------------- ECS: aplicar colisión a la ENTIDAD JUGADOR -----------
SECTION "Player↔World Collision (ECS)", ROM0

; Procesa UNA entidad (si no es jugador, retorna)
; Entrada: E = offset de entidad (man_entity_for_each)
sys_player_world_collide_one_entity::
    ; ¿es jugador? (bit T_PLAYER en CMP_INFO_TYPE)
    ld   h, CMP_INFO_H
    ld   l, e
    ld   a, l
    add  CMP_INFO_TYPE
    ld   l, a
    ld   a, [hl]
    bit  T_PLAYER, a
    ret  z

    ; Guarda offset de entidad (E) en la pila
    ld   a, e
    push af                         ; [stack]: entityE

    ; ---- velocidades (PHYSICS) ----
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VX
    ld   l, a
    ld   b, [hl]                    ; B = dx
    ld   a, l
    add  (CMP_PH_VY - CMP_PH_VX)
    ld   l, a
    ld   c, [hl]                    ; C = dy

    ; ---- posición (SPRITE) -> D=y, E=x ----
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_Y
    ld   l, a
    ld   d, [hl]                    ; D = y
    ld   a, l
    add  (CMP_SPRITE_X - CMP_SPRITE_Y)
    ld   l, a
    ld   e, [hl]                    ; E = x

    ; ================== RESOLVER X ==================
    call col_resolve_axis_x_8x8     ; in: D=y,E=x,B=dx  out: E=x'  CARRY si chocó
    jr   nc, .x_no_hit
    ; --- hubo colisión en X ---
    ld   b, e                       ; B = x' (conservar)
    pop  af                         ; A = entityE
    ld   e, a
    push af
    ; PH_VX = 0
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VX
    ld   l, a
    xor  a
    ld  [hl], a
    ; SPRITE.X = x'
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_X
    ld   l, a
    ld   a, b
    ld  [hl], a
    jr   .x_done

.x_no_hit:
    ; escribir SPRITE.X = E (x')
    ld   b, e                       ; B = x'
    pop  af                         ; A = entityE
    ld   e, a
    push af
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_X
    ld   l, a
    ld   a, b
    ld  [hl], a
.x_done:

    ; ================== RESOLVER Y ==================
    ; preparar E = x' desde B
    ld   e, b
    call col_resolve_axis_y_8x8     ; in: D=y,E=x',C=dy  out: D=y'  CARRY si chocó
    jr   nc, .y_no_hit
    ; --- hubo colisión en Y ---
    pop  af                         ; A = entityE
    ld   e, a
    ; PH_VY = 0
    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VY
    ld   l, a
    xor  a
    ld  [hl], a
    ; SPRITE.Y = y'
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_Y
    ld   l, a
    ld   a, d
    ld  [hl], a
    ret

.y_no_hit:
    ; escribir SPRITE.Y = y' (D)
    pop  af                         ; A = entityE
    ld   e, a
    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_Y
    ld   l, a
    ld   a, d
    ld  [hl], a
    ret

; Procesa TODAS las entidades y aplica colisión a la que sea jugador
sys_player_world_collide::
    ld   hl, sys_player_world_collide_one_entity
    call man_entity_for_each
    ret
