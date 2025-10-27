;========================================
; sc01_debuff_integration.asm
; Integración del debuff 0.85x en la escena (SC01)
; Requiere: debuff_speed.asm incluido en el proyecto
;----------------------------------------
; API (llámala desde sc01.asm):
;   SC01_Debuff_Init               ; IN: HL=&spriteJugador [y,x,id,at] ; A=tileIdDebuff
;   SC01_Debuff_Update_PreMove     ; IN/OUT: B=dx, C=dy  (escala a 0.85 si activo)
;   SC01_Debuff_Update_PostMove    ; IN: HL=&spriteJugador ; consume tile si se entra
;   SC01_Debuff_Tick               ; IN: - ; llamar 1 vez por frame (fin de frame o VBlank)
;========================================

SECTION "SC01 Debuff Vars", WRAM0
; Mapa lógico 32×32 (1 byte/celda): 0=off,1=armado,2=consumido
SC01_DebuffMap: ds 1024

SECTION "SC01 Debuff Code", ROM0

;----------------------------------------
; IN:  HL = &sprite jugador [y][x][id][at]
;      A  = tileId del BG que representa el debuff
; OUT: mapa armado, estado reseteado y last TX/TY sincronizado
SC01_Debuff_Init::
    ; apuntar el mapa lógico
    ld   de, SC01_DebuffMap
    call set_debuff_map_ptr

    ; estado global limpio (activa=0, timers=0, accs=0, last=FF)
    call debuff_init_scene

    ; construir mascara 32x32 desde el BG map comparando tileId=A
    ; (lee BG map con wait_vram_safe; hacer tras cargar el BG)
    call debuff_build_map_from_tileid

    ; sincroniza last TX/TY al spawn del jugador
    ; (evita disparo inmediato si ya nace sobre el tile)
    call debuff_init_for_player
    ret


;----------------------------------------
; IN/OUT: B=dx (signed), C=dy (signed)
; OUT:    B,C escalados a 0.85 si debuff activo (acumuladores base 100)
SC01_Debuff_Update_PreMove::
    call debuff_apply_speed
    ret


;----------------------------------------
; IN:  HL = &sprite jugador [y][x][id][at]
; OUT: si entra en tile armado: consume celda y reinicia 15 s
SC01_Debuff_Update_PostMove::
    call debuff_check_enter_tile
    ret


;----------------------------------------
; Llamar exactamente 1 vez por frame
; (fin de bucle de juego o en IRQ VBlank si lo prefieres)
SC01_Debuff_Tick::
    call debuff_tick_1frame
    ret
