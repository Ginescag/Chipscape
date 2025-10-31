
INCLUDE "constantes.inc"

DEF IA_BG_BASE EQU $9800     


SECTION "WRAM Interactions", WRAM0
wIA_LastA:   ds 1   
wIA_Facing:  ds 1   
wIA_ColL:    ds 1
wIA_ColR:    ds 1
wIA_RowTop:  ds 1
wIA_RowBot:  ds 1


SECTION "Interactions Code", ROM0


Interact_Init2::
    xor a
    ld  [wIA_LastA], a
    ld  [wIA_Facing], a
    ret


Interact_Tick::
    call player_read_dpad      
    ld   b, a

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

    ld   a, [wIA_Facing]
    and  PADF_UP
    ret  z

    call ia_read_buttons_nibble   
    and  1                        
    ld   b, a                     
    ld   a, [wIA_LastA]
    cp   b
    jp   z, .noEdge               
    ld   a, b
    ld  [wIA_LastA], a
    or   a
    jr   z, .ret                  

    
    ld   a, [wPX]
    sub  8
    ld   c, a
    ld   a, [rSCX]
    add  a, c
    ld   c, a

    
    ld   a, c
    srl  a
    srl  a
    srl  a
    and  31
    ld  [wIA_ColL], a

    ld   a, c
    add  a, 15
    srl  a
    srl  a
    srl  a
    and  31
    ld  [wIA_ColR], a

    ld   a, [wPY]
    sub  16
    ld   d, a
    ld   a, [rSCY]
    add  a, d
    ld   d, a

    ld   a, d
    srl  a
    srl  a
    srl  a
    and  31
    ld  [wIA_RowTop], a

    ld   a, d
    add  a, 15
    srl  a
    srl  a
    srl  a
    and  31
    ld  [wIA_RowBot], a

    
    ld   a, [wIA_RowTop]
    sub  1
    and  31
    call ia_test_row_cols_hit
    jr   z, .hit

    ld   a, [wIA_RowTop]
    sub  2
    and  31
    call ia_test_row_cols_hit
    jr   z, .hit

    ld   a, [wIA_RowBot]
    sub  2
    and  31
    call ia_test_row_cols_hit
    jr   nz, .ret                  

.hit:
    pop  hl
    ret

.ret:
    ret

.noEdge:
    ret


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
