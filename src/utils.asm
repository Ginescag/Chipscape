INCLUDE "constantes.inc"


SECTION "utils", ROM0

; clear_oam_buf::
;     xor a
;     ld hl, OAMBuffer
;     ld bc, OAM_BYTES
;     .c:
;         ld [hl+], a
;         dec bc
;         ld a, b
;         or c
;         jr nz, .c
; ret

apaga_pantalla::
    di 
    call wait_vblank
    ld hl, rLCDC
    res 7, [hl]
    ei
ret

enciende_pantalla::
    di
    ; Opción A: encender manteniendo lo que hubiese
    ld  a, [rLCDC]
    set  7, a                 ; bit7 = 1 (LCD ON)
    ld [rLCDC], a
    ei
ret

; void set_sprite_idx(a=idx, b=y, c=x, d=tile, e=attr)
; set_sprite_idx::
;     ; HL = OAMBuffer + idx*4
;     add a, a
;     add a, a          ; a = idx*4
;     ld h, HIGH(OAMBuffer)
;     ld l, LOW(OAMBuffer)
;     ld b, 0
;     ld c, a
;     add hl, bc
;     ; escribir [Y][X][TILE][ATTR]
;     ld a, b           ; y
;     ld [hl+], a
;     ld a, c           ; x
;     ld [hl+], a
;     ld a, d           ; tile
;     ld [hl+], a
;     ld a, e           ; attr
;     ld [hl],  a
; ret

; start_oam_dma::
;     ld a, HIGH(OAMBuffer) ; $C1 si OAMBuffer=$C100
;     ld [rDMA], a          ; copia $C100..$C19F -> $FE00..$FE9F
; ret

;; HL = "source", DE = "Destiny" B = counter
memcpy::
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    jr nz, memcpy
ret

wait_vblank::
    ld hl, rLY
    ld a, VBLANK_ST
    .loop:
        cp [hl]
    jr nz, .loop
ret

;; a = palette nº
changeObjPalette::
    ld   [rOBP0], a

changeBGP::
    ld   [rBGP],  a

escribir_linea::
    ld b, 31 
    ld [hl+], a
    dec b
    jr nz, escribir_linea
ret 


escribir_pantalla::
    ld c, 31
    ld b, 31
    call escribir_linea
    inc l
    jr nc, .next
    inc h
    .next:
        dec c
    jr nz, escribir_pantalla
ret



