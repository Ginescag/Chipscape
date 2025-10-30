INCLUDE "constantes.inc"

SECTION "Game Over code", ROM0

; ------------------------------------------------------------
; game_over (versión ultra-lenta)
;  - Carga el BGMap y hace autoscroll horizontal "a cámara lenta".
;  - No responde a input, no muestra sprites/HUD y se queda bloqueado.
;  - Ajusta GAMEOVER_SLOW_B / GAMEOVER_SLOW_C si quieres otra lentitud.
; ------------------------------------------------------------

; 256-160 = 96 píxeles visibles al desplazarse un BG de 32x32
DEF GAMEOVER_SCX_MAX   EQU 96

; ---------------------------------------------
; Retardo total por píxel = B * C frames.
; Con 8*255 = 2040 frames ≈ 34 s por píxel (@~60 FPS)
; (si lo quieres aún más lento, sube B; máx 255)
; ---------------------------------------------
DEF GAMEOVER_SLOW_B    EQU 8
DEF GAMEOVER_SLOW_C    EQU 2

game_over_animated::
    ; --- LCD OFF y limpiar sprites/HUD ---
    call apaga_pantalla
    call BORRAR_OAM

    ; --- Cargar mapa GAME OVER en BGMap0 ($9800) ---
    ld   hl, gameover_inic          ; <--- tus etiquetas de mapa
    ld   de, $9800
    ld   bc, gameover_fin - gameover_inic
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
    ; ===== Retardo "a cámara lenta": B*C frames por píxel =====
    ld   b, GAMEOVER_SLOW_B
.delay_b:
        ld   c, GAMEOVER_SLOW_C
.delay_c:
            call wait_vblank        ; espera 1 frame
            dec  c
            jr   nz, .delay_c
        dec  b
        jr   nz, .delay_b

    ; ===== Avanza 1 píxel cuando termina el retardo =====
    ld   a, [rSCX]
    cp   GAMEOVER_SCX_MAX
    jr   nc, .freeze
    inc  a
    ld  [rSCX], a
    jr   .scroll_loop

.freeze:
    ; Queda congelado mostrando la última posición
    jr   .freeze