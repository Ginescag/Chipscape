INCLUDE "constantes.inc"

SECTION "utils", ROM0

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

;; HL = "source", DE = "Destiny" B = counter
memcpy::
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
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

writeLine:
    ld [hl], b
    inc hl
    dec e
    jr nz, writeLine
ret
  
writeScreen:
    call wait_vblank
    call writeLine
    inc hl
    ld e, 28
    dec c
    jr nz, writeScreen
ret

;; HL = Destiny
;; B = bytes
;; A = value
memset_256::
    ld [hl+], a
    dec b
    jr nz, memset_256
ret


BORRAR_OAM::
    ld hl, OAM_START
    ld b, SPRITES_TOTAL
    xor a
    call memset_256
ret


;; PARA HACER CALL HL
helper_call_HL::
    jp hl
