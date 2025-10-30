include "constantes.inc"

SECTION "scene 01 assets", ROM0

sc01_entities::  ;;PYXp----
sc01_playerL::   ;;INFO + SPRITE + PHYSICS
    DB CMP_RESERVE, %01110101, %10000000, 03        ;;INFO
    DB 80, 80, $1A, %00000000   ;;SPRITE
    DB 80, 80, 01, 01          ;;PHYSICS

sc01_playerR::
    DB CMP_RESERVE, %01110101, %10000000, 03
    DB 80, 88, $1C, %00000000
    DB 80, 88, 01, 01

sc01_entities_REST::
sc01_MiB1_L::
    DB CMP_RESERVE, %01110101, %01000000, 01
    DB 16, 16, $3A, %00000000
    DB 16, 16, 00, 02

sc01_MiB1_R::
    DB CMP_RESERVE, %01110101, %01000000, 01
    DB 16, 24, $3C, %00000000
    DB 16, 24, 00, 02

sc01_chipTest::
    DB CMP_RESERVE, %00011101, %00100000, 01
    DB 100, 92, $D4, %00000000
    DB 100, 92, 00, 00
sc01_entities_REST_END::