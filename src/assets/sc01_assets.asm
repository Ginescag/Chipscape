SECTION "scene 01 assets", ROM0

sc01_entities::  ;;PYXp----
sc01_entity1::   ;;SPRITE + PHYSICS
    DB 16, 32, $1A, %00000000   ;;SPRITE
    DB 16, 32, 01, 00           ;;PHYSICS

    sc01_entity2::
    DB 16, 40, $1C, %00000000
    DB 16, 40, 01, 00
  