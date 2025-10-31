
include "constantes.inc"

SECTION "Game engine", ROM0

game_engine_init::
    
    call wait_vblank
    call BORRAR_OAM
    ld   a, %10010111
    ld  [rLCDC], a
ret
  