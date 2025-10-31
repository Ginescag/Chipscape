INCLUDE "constantes.inc"

SECTION "GG code", ROM0

DEF GG_SCX_MAX   EQU 96


DEF GG_SLOW_B    EQU 8
DEF GG_SLOW_C    EQU 2

gg_animated::
    ; --- LCD OFF y limpiar sprites/HUD ---
    call apaga_pantalla
    call BORRAR_OAM

    ; --- Cargar mapa GAME OVER en BGMap0 ($9800) ---
    ld   hl, gg_inic          ; <--- tus etiquetas de mapa
    ld   de, $9800
    ld   bc, gg_fin - gg_inic
    call cargar_mapa

    ; --- Posición inicial y paleta BG ---
    xor  a
    ld  [rSCX], a
    ld  [rSCY], a
    ld   a, %11100100               ; BGP
    ld  [rBGP], a

    ; --- LCDC: BG ON, OBJ OFF, WIN OFF, tiles $8000, BGMap $9800 ---
    ld   a, %00010001               ; (bit4=1, bit0=1) LCD todavía apagado
    ld  [rLCDC], a
    call enciende_pantalla          ; enciende LCD (bit7)

    ; --- Bloquear interrupciones (no hay input ni lógica) ---
    di

.scroll_loop:
    ld   b, GG_SLOW_B
.delay_b:
        ld   c, GG_SLOW_C
.delay_c:
            call wait_vblank        ; espera 1 frame
            dec  c
            jr   nz, .delay_c
        dec  b
        jr   nz, .delay_b

    ; ===== Avanza 1 píxel cuando termina el retardo =====
    ld   a, [rSCX]
    cp   GG_SCX_MAX
    jr   nc, .freeze
    inc  a
    ld  [rSCX], a
    jr   .scroll_loop

.freeze:
    ; Queda congelado mostrando la última posición
    jr   .freeze
