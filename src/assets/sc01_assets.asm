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
    DB 16, 24, $3A, %00000000
    DB 100, 100, 02, 00

sc01_MiB1_R::
    DB CMP_RESERVE, %01110101, %01000000, 01
    DB 16, 32, $3C, %00000000
    DB 100, 100, 02, 00

sc01_MiB1_L2::
    DB CMP_RESERVE, %01110101, %01000000, 01
    DB 46, 50, $3A, %00000000
    DB 100, 100, 00, 02

sc01_MiB1_R2::
    DB CMP_RESERVE, %01110101, %01000000, 01
    DB 46, 58, $3C, %00000000
    DB 100, 100, 00, 02

sc01_entities_REST_END::