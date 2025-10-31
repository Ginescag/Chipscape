include "constantes.inc"

SECTION "scene 05 assets", ROM0

sc05_entities::  ;;PYXp----
sc05_playerL::   ;;INFO + SPRITE + PHYSICS
    DB CMP_RESERVE, %01110101, %10000000, 03        ;;INFO
    DB 80, 80, $1A, %00000000   ;;SPRITE
    DB 80, 80, 03, 03          ;;PHYSICS

sc05_playerR::
    DB CMP_RESERVE, %01110101, %10000000, 03
    DB 80, 88, $1C, %00000000
    DB 80, 88, 03, 03

sc05_entities_REST::

; ---- Científicos ubicados por tiles (TX,TY) -> (Y=TY8+16, X=TX8+8) ----
; CC_L1  en (TX=3,  TY=8)  -> Y=80,  X=32
sc05_CC_L1::
    DB CMP_RESERVE, %01110101, %00100000, 01
    DB 60, 32, $62, %00000000
    DB 100, 100, 00, 00

; CC_R1  en (TX=5,  TY=8)  -> Y=80,  X=48
sc05_CC_R1::
    DB CMP_RESERVE, %01110101, %00100000, 01
    DB 60, 40, $64, %00000000
    DB 100, 100, 00, 00

; CC_L2  en (TX=10, TY=9)  -> Y=88,  X=88
sc05_CC_L2::
    DB CMP_RESERVE, %01110101, %00100000, 01
    DB 60, 132, $62, %00000000
    DB 100, 100, 00, 00

; CC_R2  en (TX=12, TY=9)  -> Y=88,  X=104
sc05_CC_R2::
    DB CMP_RESERVE, %01110101, %00100000, 01
    DB 60, 140, $64, %00000000
    DB 100, 100, 00, 00

; CC_L3  en (TX=15, TY=15) -> Y=136, X=128

; CC_L4  en (TX=22, TY=20) -> Y=176, X=184
sc05_entities_REST_END::
