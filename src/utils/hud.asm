
INCLUDE "constantes.inc"

DEF rWY              EQU $FF4A     ; Window Y
DEF rWX              EQU $FF4B     ; Window X
DEF WIN_MAP_BASE     EQU $9C00     
DEF HUD_BLANK_TILE   EQU $EF       ; tile en blanco para limpiar la HUD
DEF HUD_TIMER_START_SECS EQU 120   ; tiempo inicial del temporizador (s)

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
    ld   a, [wTimerFlag1s]
    or   a
    ret  z
    xor  a
    ld  [wTimerFlag1s], a

    ld   a, [wTimerLo]
    or   a
    jr   nz, .dec_lo
    ld   a, [wTimerHi]
    or   a
    jr   z, .no_time
    ld   a, [wTimerHi]
    dec  a
    ld  [wTimerHi], a
    ld   a, $FF
.dec_lo:
    dec  a
    ld  [wTimerLo], a

    call Timer_ComputeDigits
.no_time:
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
