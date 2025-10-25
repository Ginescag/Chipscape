; INCLUDE "constantes.inc"

; SECTION "Fade tables", ROM0
; FadeToWhiteTable:     ; oscuro -> blanco
;     DB $E4, $F9, $FE, $FF
; FadeFromWhiteTable:   ; blanco -> oscuro
;     DB $FF, $FE, $F9, $E4

; SECTION "Fade helpers", ROM0
; ; Espera EXACTAMENTE 1 frame sin interrupciones:
; ; entra en VBlank (LY >= 144) y luego espera a salir (LY < 144)
; wait_one_frame_poll:
; .wait_vb:
;     ld a,[rLY]
;     cp 144
;     jr c, .wait_vb
; .wait_end:
;     ld a,[rLY]
;     cp 144
;     jr z, .wait_end
;     ret

; ; Espera B frames sin IE/EI
; wait_frames_poll:
;     push bc
; .loop:
;     call wait_one_frame_poll
;     djnz .loop
;     pop bc
;     ret

; ; ===== FADES “SIMULADOS” (sin interrupciones) =====
; ; Cada paso espera N frames (ajusta FADE_SPEED_FRAMES)
; DEF FADE_SPEED_FRAMES EQU 2   ; 1-3 se nota bien en BGB

; ; Fade out a blanco (BGP/OBP0/OBP1)
; fade_out_sim::
;     ld   a,[rLCDC]
;     bit  7,a
;     jr   z,.lcd_off_quick      ; si LCD OFF, fija blanco y sal
;     ld   hl, FadeToWhiteTable
;     ld   c, 4
; .fo_step:
;     ld   a,[hl+]               ; aplica paleta del paso
;     ld  [rBGP],  a
;     ld  [rOBP0], a
;     ld  [rOBP1], a
;     ld   b, FADE_SPEED_FRAMES  ; espera “N” frames sin IE/EI
;     call wait_frames_poll
;     dec  c
;     jr   nz,.fo_step
;     ret
; .lcd_off_quick:
;     ld   a,$FF
;     ld  [rBGP],  a
;     ld  [rOBP0], a
;     ld  [rOBP1], a
;     ret

; ; Fade in desde blanco (BGP/OBP0/OBP1)
; fade_in_sim::
;     ld   a,[rLCDC]
;     bit  7,a
;     jr   z,.no_wait
;     ld   hl, FadeFromWhiteTable
;     ld   c, 4
; .fi_step:
;     ld   a,[hl+]
;     ld  [rBGP],  a
;     ld  [rOBP0], a
;     ld  [rOBP1], a
;     ld   b, FADE_SPEED_FRAMES
;     call wait_frames_poll
;     dec  c
;     jr   nz,.fi_step
;     ret
; .no_wait:
;     ld   a,$E4                  ; paleta final por defecto
;     ld  [rBGP],  a
;     ld  [rOBP0], a
;     ld  [rOBP1], a
;     ret

; ; Azúcar para transición de escena SIN IE/EI:
; fade_out_and_lcd_off_sim::
;     call fade_out_sim
;     ; aquí apaga la pantalla con tu rutina segura (o escribe rLCDC bit7=0 justo tras salir de VBlank)
;     call apaga_pantalla        ; ya la tienes hecha
;     ret

; fade_in_and_lcd_on_sim::
;     call enciende_pantalla     ; enciende LCD (bit7=1)
;     call fade_in_sim
;     ret
