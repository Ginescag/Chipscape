INCLUDE "constantes.inc"

SECTION "Entry point", ROM0

main::

  call game_engine_init
  call sc01_init
  call sc01_run

  di     ;; Disable Interrupts
  halt 