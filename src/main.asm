INCLUDE "constantes.inc"

SECTION "Entry point", ROM0

main::

  call game_engine_init
  call sc01_init
  call HUD_Init
  call sc01_run
.escena2:
  call sc02_init
  call HUD_Init
  call sc02_run


  di    
  halt 