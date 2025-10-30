INCLUDE "constantes.inc"

DEF rWY              EQU $FF4A     ; Window Y
DEF rWX              EQU $FF4B     ; Window X
DEF WIN_MAP_BASE     EQU $9C00     
DEF HUD_BLANK_TILE   EQU $EF       ; tile en blanco para limpiar la HUD
DEF HUD_TIMER_START_SECS EQU 10  ; tiempo inicial del temporizador (s)

SECTION "HUD code", ROM0



HUD_Init::
    call apaga_pantalla
    call Score_LoadTiles
    call Timer_LoadTiles
    call ChipCount_LoadTiles

    call HUD_ClearRows

    
    call Score_Reset
    call ChipCount_Reset

    ld   hl, HUD_TIMER_START_SECS
    call Timer_SetSecsHL

    
    call Score_HUD_Init
    call ChipCount_HUD_Init
    call Timer_HUD_Init
    ld   a, 128
    ld  [rWY], a
    ld   a, 7
    ld  [rWX], a
    ld   a, [rLCDC]
    set  6, a                    
    set  5, a                    
    ld  [rLCDC], a
    call Timer_Init
    call enciende_pantalla
    ei
    ret

HUD_Tick::
    ; ¿ha pasado 1s?
    ld   a, [wTimerFlag1s]
    or   a
    ret  z
    xor  a
    ld  [wTimerFlag1s], a

    ; si YA está a 0 antes de decrementar -> game_over
    ld   a, [wTimerHi]
    or   a
    jr   nz, .dec
    ld   a, [wTimerLo]
    or   a
    jp   z, game_over_animated

.dec:
    ; HL := segundos actuales
    ld   a, [wTimerLo]
    or   a
    jr   nz, .dec_lo
    ; L==0 -> pedir préstamo a H si H>0
    ld   a, [wTimerHi]
    or   a
    jr   z, .after_dec         ; (no debería ocurrir; cubierto arriba)
    dec  a
    ld  [wTimerHi], a
    ld   a, $FF
.dec_lo:
    dec  a
    ld  [wTimerLo], a

.after_dec:
    ; recomputar dígitos para el HUD (HUD_Draw se hará en VBlank como ya haces)
    call Timer_ComputeDigits

    ; ¿ha quedado en 0 tras el decremento? -> game_over
    ld   a, [wTimerHi]
    or   a
    jr   nz, .done
    ld   a, [wTimerLo]
    or   a
    jp   z, game_over_animated

.done:
    ret

HUD_Draw::
    call wait_vblank
    call Score_HUD_Update
    call ChipCount_HUD_Update
    call Timer_HUD_Update
    ret


HUD_ClearRows:

    ld   a, HUD_BLANK_TILE

    ld   hl, WIN_MAP_BASE
    ld   b, 32
.row0:
    ld  [hl+], a
    dec  b
    jr  nz, .row0

    ld   hl, WIN_MAP_BASE + 32
    ld   b, 32
.row1:
    ld  [hl+], a
    dec  b
    jr  nz, .row1
    ret