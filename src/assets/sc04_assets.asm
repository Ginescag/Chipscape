include "constantes.inc"

SECTION "scene 04 assets", ROM0

sc04_entities::  ;;PYXp----
sc04_playerL::   ;;INFO + SPRITE + PHYSICS
    DB CMP_RESERVE, %01110101, %10000000, 03        ;;INFO
    DB 80, 80, $1A, %00000000   ;;SPRITE
    DB 80, 80, 03, 03          ;;PHYSICS

sc04_playerR::
    DB CMP_RESERVE, %01110101, %10000000, 03
    DB 80, 88, $1C, %00000000
    DB 80, 88, 03, 03

sc04_entities_REST::

; ---- Científicos ubicados por tiles (TX,TY) -> (Y=TY8+16, X=TX8+8) ----
; CC_L1  en (TX=3,  TY=8)  -> Y=80,  X=32
sc04_CC_L1::
    DB CMP_RESERVE, %01110101, %00100000, 01
    DB 80, 20, $62, %00000000
    DB 100, 100, 00, 00

; CC_R1  en (TX=5,  TY=8)  -> Y=80,  X=48
sc04_CC_R1::
    DB CMP_RESERVE, %01110101, %00100000, 01
    DB 80, 28, $64, %00000000
    DB 100, 100, 00, 00



sc04_entities_REST_END::