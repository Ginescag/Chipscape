INCLUDE "constantes.inc"

SECTION "Entry point", ROM0

main::

  call game_engine_init
  call sc01_init
  call HUD_Init
  call sc01_run
.escena2:
  call sc02_init
  call sc02_run
.escena3:
  call sc03_init
  call sc03_run
  .escena4:
  call sc04_init
  call sc04_run
  .escena5:
  call sc05_init
  call sc05_run
.fin_gg:
  call gg_animated


  di    
  halt 