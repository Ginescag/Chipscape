;========================================
; debuff_system.asm
; Debuff de velocidad por tile "one-shot" (0.85x durante 15s)
; Integración no intrusiva con tu motor actual.
;----------------------------------------
; API (todas las etiquetas con :: son globales):
;   Debuff_Init::                         ; Llamar al cargar escena (o nueva partida)
;   Debuff_ClearConsumed::                ; Opcional: reinicia el mapa de consumo 32x32
;   Debuff_Tick::                         ; Llamar EXACTAMENTE una vez por frame
;   Debuff_ApplyToDXDY::                  ; Escala B=dx, C=dy si el debuff está activo (0.85x)
;   Debuff_CheckAndTriggerUnderSprite::   ; HL = &sprite[y,x,id,at] del jugador. Detecta nueva celda, arma/consume
;----------------------------------------
; Requisitos:
; - Debes definir DEBUFF_TILE_ID en "constantes.inc" con el índice del tile (BG) proporcionado.
; - El tile es "atravesable" (no sólido). Solo dispara el debuff al ENTRAR por primera vez.
; - Duración exacta: 15 s ≈ 900 frames (VBlank o timer, pero llama a Debuff_Tick 1 vez/frame).
; - Si entras en otro tile de debuff mientras está activo, se reinicia a 15 s (no acumula).
; - 0.85x de velocidad: se implementa con acumuladores subpixel (base/100).
;----------------------------------------

INCLUDE "constantes.inc"   ; Debe declarar: DEBUFF_TILE_ID EQU <id>

;----------------------------------------
; Constantes
;----------------------------------------
DEBUFF_DURATION_FRAMES   EQU 900   ; 15 s * ~60 FPS
DEBUFF_RATE_NUM          EQU 85    ; 85/100 = 0.85x
DEBUFF_RATE_DEN          EQU 100

;----------------------------------------
; WRAM
;----------------------------------------
SECTION "DebuffVars", WRAM0

DebuffActive:         ds 1       ; 0/1
DebuffFramesLo:       ds 1
DebuffFramesHi:       ds 1

; Última celda en la que estaba el jugador (para "edge detect")
DebuffLastTX:         ds 1       ; inicializar a $FF en Init
DebuffLastTY:         ds 1

; Acumuladores por eje (0..99), y último signo (-1/0/+1) para reset limpio
DebuffAccX:           ds 1
DebuffAccY:           ds 1
DebuffLastDirX:       ds 1       ; $FF = -1, $00 = 0, $01 = +1
DebuffLastDirY:       ds 1

; Mapa 32x32 de "consumido" (1 byte por celda, 0=no consumido, 1=consumido)
DebuffConsumedMap:    ds 32*32   ; 1024 bytes

;----------------------------------------
; ROM
;----------------------------------------
SECTION "DebuffCode", ROM0

;----------------------------------------
; Utilidades locales
;----------------------------------------

; A = signo de B (-1,0,+1) en { $FF, $00, $01 }
.get_sign_b:
    ld   a, b
    or   a
    jr   z, .zero
    bit  7, a
    jr   z, .pos
    ld   a, $FF
    ret
.pos:
    ld   a, $01
    ret
.zero:
    xor  a
    ret

.get_sign_c:
    ld   a, c
    or   a
    jr   z, .zero
    bit  7, a
    jr   z, .pos
    ld   a, $FF
    ret
.pos:
    ld   a, $01
    ret
.zero:
    xor  a
    ret

; HL = &DebuffConsumedMap + (32*TY + TX)
; IN:  B=TY, C=TX
; OUT: HL= puntero dentro de DebuffConsumedMap
; MOD: AF,DE
.get_consumed_ptr_bc:
    ld   h, 0
    ld   l, b          ; HL = TY
    add  hl, hl        ; *2
    add  hl, hl        ; *4
    add  hl, hl        ; *8
    add  hl, hl        ; *16
    add  hl, hl        ; *32
    ld   b, 0
    add  hl, bc        ; HL = 32*TY + TX
    ld   de, DebuffConsumedMap
    add  hl, de
    ret

;----------------------------------------
; API: Inicialización
;----------------------------------------
Debuff_Init::
    xor  a
    ld   [DebuffActive], a
    ld   [DebuffFramesLo], a
    ld   [DebuffFramesHi], a
    ld   [DebuffAccX], a
    ld   [DebuffAccY], a
    ld   [DebuffLastDirX], a
    ld   [DebuffLastDirY], a
    ld   a, $FF
    ld   [DebuffLastTX], a
    ld   [DebuffLastTY], a
    jp   Debuff_ClearConsumed

;----------------------------------------
; API: Limpia el mapa de consumo 32x32
;----------------------------------------
Debuff_ClearConsumed::
    ld   hl, DebuffConsumedMap
    ld   b, 0
    ld   c, 32*32
.clear_loop:
    xor  a
    ld   [hl+], a
    dec  c
    jr   nz, .clear_loop
    ret

;----------------------------------------
; API: Tick de temporizador (llamar 1 vez por frame)
;----------------------------------------
Debuff_Tick::
    ld   a, [DebuffActive]
    or   a
    ret  z

    ; HL = contador (Hi:Lo)
    ld   a, [DebuffFramesLo]
    ld   l, a
    ld   a, [DebuffFramesHi]
    ld   h, a

    ld   a, h
    or   l
    jr   z, .expired

    dec  hl
    ld   a, l
    ld   [DebuffFramesLo], a
    ld   a, h
    ld   [DebuffFramesHi], a

    ld   a, h
    or   l
    ret  nz

.expired:
    xor  a
    ld   [DebuffActive], a
    ld   [DebuffAccX], a
    ld   [DebuffAccY], a
    ld   [DebuffLastDirX], a
    ld   [DebuffLastDirY], a
    ret

;----------------------------------------
; API: Escala B=dx, C=dy a 0.85x cuando el debuff está activo
;      Entrada:  B=dx base (-1/0/+1), C=dy base (-1/0/+1)
;      Salida:   B,C ajustados para este frame (0 o ±1)
;----------------------------------------
Debuff_ApplyToDXDY::
    ld   a, [DebuffActive]
    or   a
    ret  z               ; Debuff OFF → deja B,C intactos

    ; ---------- Eje X ----------
    push bc
    call .get_sign_b     ; A = signo(B) en {$FF,0,$01}
    ld   d, a            ; D = signoX

    ; si dir cambia, resetea acumulador
    ld   a, [DebuffLastDirX]
    cp   d
    jr   z, .dirx_ok
    xor  a
    ld   [DebuffAccX], a
.dirx_ok:
    ld   a, d
    ld   [DebuffLastDirX], a

    ; si no hay intención (0), salida 0
    or   a
    jr   nz, .accumulate_x
    pop  bc
    ld   b, 0
    jr   .done_x

.accumulate_x:
    ; AccX += 85 ; si >=100 → AccX-=100 y paso = signo
    ld   a, [DebuffAccX]
    add  a, DEBUFF_RATE_NUM       ; +85
    ld   [DebuffAccX], a
    cp   DEBUFF_RATE_DEN          ; ¿>=100?
    jr   c, .no_step_x
    sub  DEBUFF_RATE_DEN          ; -100
    ld   [DebuffAccX], a
    pop  bc
    ; paso real
    ld   a, d
    cp   $FF
    jr   z, .step_x_neg
    ld   b, +1
    jr   .done_x
.step_x_neg:
    ld   b, -1
    jr   .done_x

.no_step_x:
    pop  bc
    ld   b, 0
.done_x:

    ; ---------- Eje Y ----------
    push bc
    call .get_sign_c     ; A = signo(C)
    ld   d, a            ; D = signoY

    ld   a, [DebuffLastDirY]
    cp   d
    jr   z, .diry_ok
    xor  a
    ld   [DebuffAccY], a
.diry_ok:
    ld   a, d
    ld   [DebuffLastDirY], a

    or   a
    jr   nz, .accumulate_y
    pop  bc
    ld   c, 0
    jr   .done_y

.accumulate_y:
    ld   a, [DebuffAccY]
    add  a, DEBUFF_RATE_NUM       ; +85
    ld   [DebuffAccY], a
    cp   DEBUFF_RATE_DEN          ; ¿>=100?
    jr   c, .no_step_y
    sub  DEBUFF_RATE_DEN
    ld   [DebuffAccY], a
    pop  bc
    ld   a, d
    cp   $FF
    jr   z, .step_y_neg
    ld   c, +1
    jr   .done_y
.step_y_neg:
    ld   c, -1
    jr   .done_y

.no_step_y:
    pop  bc
    ld   c, 0
.done_y:
    ret

;----------------------------------------
; API: Detección/activación al ENTRAR en un tile
;      IN:  HL = &sprite [y][x][id][at] del jugador
;      OUT: Debuff puede activarse y marcar celda consumida.
;----------------------------------------
Debuff_CheckAndTriggerUnderSprite::
    ; --- Obtener TY,TX (scrolled) desde sprite ---
    push hl
    push bc
    push de
    push af

    ld   a, [hl+]                ; y
    call convert_y_to_ty_scrolled
    ld   b, a                    ; B = TY
    ld   a, [hl]                 ; x
    call convert_x_to_tx_scrolled
    ld   c, a                    ; C = TX

    ; --- Edge detect: ¿ha cambiado de tile?
    ld   a, [DebuffLastTX]
    cp   c
    jr   nz, .entered_new
    ld   a, [DebuffLastTY]
    cp   b
    jr   nz, .entered_new

    ; mismo tile → actualizar y salir
.store_last_nochange:
    ld   a, c
    ld   [DebuffLastTX], a
    ld   a, b
    ld   [DebuffLastTY], a
    pop  af
    pop  de
    pop  bc
    pop  hl
    ret

.entered_new:
    ; Puntero a celda consumida
    push bc
    call .get_consumed_ptr_bc    ; HL = &Consumed[TY,TX]
    ld   a, [hl]
    or   a
    jr   nz, .already_consumed   ; si ya consumida → no dispara

    ; --- Leer tile ID del BG map en (TY,TX) ---
    ; HL se va a usar, guarda ptr a Consumed en DE
    ld   d, h
    ld   e, l
    pop  bc                      ; recupera TY,TX (B,C)
    push de                      ; guarda &Consumed

    call get_bg_base             ; DE = base $9800/$9C00
    call calculate_address_from_tx_and_ty  ; HL = base + 32*TY + TX

    ; acceso seguro VRAM
    call wait_vram_safe
    ld   a, [hl]                 ; A = tile ID en el BG map

    ; ¿es el tile de debuff?
    cp   DEBUFF_TILE_ID
    jr   nz, .not_debuff_tile

    ; --- Activar debuff y marcar como consumida ---
    pop  hl                      ; HL = &Consumed
    ld   a, 1
    ld   [hl], a                 ; consumida

    ld   a, 1
    ld   [DebuffActive], a
    ld   a, LOW(DEBUFF_DURATION_FRAMES)
    ld   [DebuffFramesLo], a
    ld   a, HIGH(DEBUFF_DURATION_FRAMES)
    ld   [DebuffFramesHi], a

    xor  a
    ld   [DebuffAccX], a
    ld   [DebuffAccY], a
    ld   [DebuffLastDirX], a
    ld   [DebuffLastDirY], a
    jr   .store_last_and_exit

.not_debuff_tile:
    pop  de                      ; descarta &Consumed
    jr   .store_last_and_exit

.already_consumed:
    pop  bc                      ; balancear pila (correspondiente al push bc antes de get_consumed_ptr)
    ; no dispara
.store_last_and_exit:
    ld   a, c
    ld   [DebuffLastTX], a
    ld   a, b
    ld   [DebuffLastTY], a

    pop  af
    pop  de
    pop  bc
    pop  hl
    ret
