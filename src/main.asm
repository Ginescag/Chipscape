INCLUDE "inc/hardware.inc"
INCLUDE "inc/constants.inc"

IF !DEF(rWY)
  DEF rWY   EQU $FF4A
ENDC
IF !DEF(rWX)
  DEF rWX   EQU $FF4B
ENDC
IF !DEF(rSTAT)
  DEF rSTAT EQU $FF41
ENDC
IF !DEF(rLY)
  DEF rLY   EQU $FF44
ENDC
IF !DEF(rLYC)
  DEF rLYC  EQU $FF45
ENDC
IF !DEF(rIE)
  DEF rIE   EQU $FFFF
ENDC

IF !DEF(LCDCF_TILE8000)
  DEF LCDCF_TILE8000  EQU %00010000   
ENDC
IF !DEF(LCDCF_WINON)
  DEF LCDCF_WINON     EQU %00100000   
ENDC
IF !DEF(LCDCF_WIN9C00)
  DEF LCDCF_WIN9C00   EQU %01000000   
ENDC

IF !DEF(STATF_LYC)
  DEF STATF_LYC       EQU %01000000   
ENDC

IF !DEF(IEF_VBLANK)
  DEF IEF_VBLANK      EQU %00000001
ENDC
IF !DEF(IEF_STAT)
  DEF IEF_STAT        EQU %00000010
ENDC
IF !DEF(IEF_TIMER)
  DEF IEF_TIMER       EQU %00000100
ENDC

DEF HUD_CLIP_LINES    EQU 16

IF !DEF(WIN_WX_ON)
  DEF WIN_WX_ON   EQU 7
ENDC
IF !DEF(WIN_WX_OFF)
  DEF WIN_WX_OFF  EQU 168
ENDC

SECTION "Main", ROM0
EXPORT main

main::
    di
    ld sp, $FFFE

    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a

    ld a, [rLCDC]
    res 7, a
    ld [rLCDC], a

    call Gfx_LoadTiles          
    call Timer_LoadTiles        
    call Score_LoadTiles        
    call Gfx_LoadTileMap        

    call Camera_Reset
    call Player_Init

    xor a
    ld [wTimerFlag1s], a

    ld hl, 120
    call Timer_SetSecsHL
    call Timer_Init

    call ClearOAM

    ld hl, OAM_BASE
    ld a, 72 + 16               
    ld [hl], a
    inc l
    ld a, 80 + 8                
    ld [hl], a
    inc l
    ld a, 2                    
    ld [hl], a
    inc l
    xor a
    ld [hl], a

    xor a
    ld [rWY], a
    ld a, WIN_WX_ON
    ld [rWX], a

    call Score_Reset
    call Score_HUD_Init
    call ChipCount_Reset
    call ChipCount_HUD_Init
    call Timer_ComputeDigits
    call Timer_HUD_Init

    ld a, HUD_CLIP_LINES
    ld [rLYC], a
    ld a, [rSTAT]
    and %11000111
    or  STATF_LYC
    ld [rSTAT], a

    ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_TILE8000 | LCDCF_WINON | LCDCF_WIN9C00
    ld [rLCDC], a

    ld a, [rIE]
    or IEF_VBLANK | IEF_STAT
    ld [rIE], a

    ei

MainLoop:
    call Input_Read
    call Player_Update
    call Camera_Update

   
    call WaitVBlank

    ld a, [wTimerFlag1s]
    or a
    jr z, .no1s
    xor a
    ld [wTimerFlag1s], a

    ld a, [wTimerHi]
    ld h, a
    ld a, [wTimerLo]
    ld l, a
    ld a, h
    or l
    jr z, .no1s

    dec hl
    ld a, l
    ld [wTimerLo], a
    ld a, h
    ld [wTimerHi], a
    call Timer_ComputeDigits

    ld bc, 1
    call Score_AddBC
    ld a, 1
    call ChipCount_AddA
.no1s:

    ld a, [wCameraY]
    ld [rSCY], a
    ld a, [wCameraX]
    ld [rSCX], a

    ld hl, OAM_BASE
   
    ld a, [wCameraY]
    ld c, a
    ld a, [wPlayerY]
    sub c
    add 16
    ld [hl], a
    inc l
    ld a, [wCameraX]
    ld c, a
    ld a, [wPlayerX]
    sub c
    add 8
    ld [hl], a
    inc l
    ld a, 2
    ld [hl], a
    inc l
    xor a
    ld [hl], a

    call HideUnusedSprites

    call Timer_HUD_Update
    call Score_HUD_Update
    call ChipCount_HUD_Update

    jp MainLoop
