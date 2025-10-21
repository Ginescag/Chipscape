INCLUDE "constantes.inc"

SECTION "main", ROM0[$0150]


main::

  ld hl, $9800

  ld a, $19
  ld [hl], a

  di 
  halt 