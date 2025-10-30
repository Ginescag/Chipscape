; ================================================
; interactions.asm  (sprite 16x16, “facing” persistente)
; ================================================
; Cambios mínimos:
; - Se introduce wIA_Facing para recordar la ÚLTIMA dirección pulsada.
; - Se actualiza wIA_Facing solo cuando hay alguna dirección pulsada.
; - La condición de interacción usa wIA_Facing==UP (no hace falta mantener UP).
;
; Resto de lógica (distancias, columnas/filas y flanco de A) SIN CAMBIOS.

INCLUDE "constantes.inc"

DEF IA_BG_BASE EQU $9800     ; Cambia a $9C00 si tu escena usa el otro BG map.

; --------------------------------
; WRAM
; --------------------------------
SECTION "WRAM Interactions", WRAM0
wIA_LastA:   ds 1   ; último estado del botón A (0/1)
wIA_Facing:  ds 1   ; última dirección pulsada (un solo bit PADF_*)
wIA_ColL:    ds 1
wIA_ColR:    ds 1
wIA_RowTop:  ds 1
wIA_RowBot:  ds 1

; --------------------------------
; Código
; --------------------------------
SECTION "Interactions Code", ROM0

; ------------------------------------------------
; Interact_Init
; ------------------------------------------------
Interact_Init::
    xor a
    ld  [wIA_LastA], a
    ld  [wIA_Facing], a
    ret

; ------------------------------------------------
; Interact_Tick
;  - Llamar 1 vez por frame, en VBlank.
; ------------------------------------------------
Interact_Tick::
    ; --- Actualizar "facing" si se ha pulsado alguna dirección este frame ---
    ; player_read_dpad -> nibble RLUD (1=pulsado)
    call player_read_dpad
    ld   b, a

    ; Prioridad simple: UP > DOWN > LEFT > RIGHT
    ; (si se pulsan varias a la vez, tomamos una determinista; si no hay ninguna,
    ;  no se cambia wIA_Facing y por tanto se conserva la última).
    ld   a, b
    and  PADF_UP
    jr   z, .chk_down
    ld   a, PADF_UP
    ld  [wIA_Facing], a
    jr   .after_face
.chk_down:
    ld   a, b
    and  PADF_DOWN
    jr   z, .chk_left
    ld   a, PADF_DOWN
    ld  [wIA_Facing], a
    jr   .after_face
.chk_left:
    ld   a, b
    and  PADF_LEFT
    jr   z, .chk_right
    ld   a, PADF_LEFT
    ld  [wIA_Facing], a
    jr   .after_face
.chk_right:
    ld   a, b
    and  PADF_RIGHT
    jr   z, .after_face
    ld   a, PADF_RIGHT
    ld  [wIA_Facing], a
.after_face:

    ; --- ¿está MIRANDO ARRIBA? (según última dirección pulsada) ---
    ld   a, [wIA_Facing]
    and  PADF_UP
    ret  z

    ; 2) ¿A con flanco de subida?
    call ia_read_buttons_nibble   ; A = ----ABSt (1=pulsado)
    and  1                        ; bit0 = A
    ld   b, a                     ; B = A(0/1)
    ld   a, [wIA_LastA]
    cp   b
    jp   z, .noEdge               ; igual que antes -> no hay flanco
    ld   a, b
    ld  [wIA_LastA], a
    or   a
    jr   z, .ret                  ; cambio 1->0, no disparar

    ; 3) Calcular cobertura 16x16 en coordenadas BG (0..31 columnas/filas)
    ;    Xleft = wPX-8 ; Xright = Xleft+15
    ;    fila_top  = (Ybg_top>>3), fila_bot = ((Ybg_top+15)>>3)
    ;    col_left  = (Xbg_left>>3), col_right = ((Xbg_left+15)>>3)

    ; --- X izquierda en BG ---
    ld   a, [wPX]
    sub  8                         ; OAM X corrige +8 -> borde izq
    ld   c, a                      ; C = Xscreen_left
    ld   a, [rSCX]
    add  a, c
    ld   c, a                      ; C = Xbg_left

    ; col_left = C>>3 & 31
    ld   a, c
    srl  a
    srl  a
    srl  a
    and  31
    ld  [wIA_ColL], a

    ; col_right = (C+15)>>3 & 31
    ld   a, c
    add  a, 15
    srl  a
    srl  a
    srl  a
    and  31
    ld  [wIA_ColR], a

    ; --- Y top en BG ---
    ld   a, [wPY]
    sub  16                        ; OAM Y corrige +16 -> borde sup
    ld   d, a                      ; D = Yscreen_top
    ld   a, [rSCY]
    add  a, d
    ld   d, a                      ; D = Ybg_top

    ; fila_top = D>>3 & 31
    ld   a, d
    srl  a
    srl  a
    srl  a
    and  31
    ld  [wIA_RowTop], a

    ; fila_bot = (D+15)>>3 & 31
    ld   a, d
    add  a, 15
    srl  a
    srl  a
    srl  a
    and  31
    ld  [wIA_RowBot], a

    ; 4) Probar filas candidatas: (top-1), (top-2), (bot-1), (bot-2)
    ;    y para cada fila, probar ColL y ColR (cubre todo el ancho 16px).

    ; --- arriba de la cabeza (fila_top-1) ---
    ld   a, [wIA_RowTop]
    sub  1
    and  31
    call ia_test_row_cols_hit
    jr   z, .hit

    ; --- dos filas encima de la cabeza (fila_top-2) ---
    ld   a, [wIA_RowTop]
    sub  2
    and  31
    call ia_test_row_cols_hit
    jr   z, .hit

    

    ; --- dos filas encima del cuerpo (fila_bot-2) ---
    ld   a, [wIA_RowBot]
    sub  2
    and  31
    call ia_test_row_cols_hit
    jr   nz, .ret                  ; si no hit (Z=0), salir

.hit:
    ; 5) Acción: sumar +1 al chipcount
    ld   a, 1
    call ChipCount_AddA
.ret:
    ret

.noEdge:
    ret

; ==========================================================
; Subrutinas auxiliares
; ==========================================================

; Lee el nibble de botones (A,B,Select,Start) con 1=pulsado
; Devuelve: A = ----ABSt  (nibble bajo)
ia_read_buttons_nibble::
    ld   a, $10                ; P15=0 (botones), P14=1
    ld  [rP1], a
    ld   a, [rP1]
    cpl
    and  $0F
    ret

; Devuelve Z=1 si A coincide con un tile interactivo ($95 o $97)
ia_is_interact_tile::
    cp   $95
    ret  z
    cp   $97
    ret

; Lee BG tile en (fila=B, col=C), base IA_BG_BASE
; Devuelve A = tile#
ia_read_bg_tile_at_BC::
    ; DE = fila*32
    ld   d, 0
    ld   e, b
    sla  e       ; x2
    rl   d
    sla  e       ; x4
    rl   d
    sla  e       ; x8
    rl   d
    sla  e       ; x16
    rl   d
    sla  e       ; x32
    rl   d
    ld   hl, IA_BG_BASE
    add  hl, de
    ld   d, 0
    ld   e, c
    add  hl, de
    ld   a, [hl]
    ret

; Entrada: A = fila candidata (0..31)
; Salida:  Z=1 si se encontró ($95/$97) en ColL o ColR
ia_test_row_cols_hit::
    ld   b, a                   ; B=fila

    ; columna izquierda
    ld   a, [wIA_ColL]
    ld   c, a
    call ia_read_bg_tile_at_BC
    call ia_is_interact_tile
    ret  z

    ; columna derecha
    ld   a, [wIA_ColR]
    ld   c, a
    call ia_read_bg_tile_at_BC
    call ia_is_interact_tile
    ret
