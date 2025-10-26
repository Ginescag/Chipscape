include "constantes.inc"

SECTION "scene 01 assets", ROM0

sc01_entities::  ;;PYXp----
sc01_entity1::   ;;INFO + SPRITE + PHYSICS
    DB CMP_RESERVE, %01110101, %10000000, 03        ;;INFO
    DB 80, 80, $1A, %00000000   ;;SPRITE
    DB 80, 80, 02, 02          ;;PHYSICS

sc01_entity2::
    DB CMP_RESERVE, %01110101, %10000000, 03
    DB 80, 88, $1C, %00000000
    DB 80, 88, 02, 02


  