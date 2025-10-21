DEF rLY                 equ $FF44
DEF VBLANK_ST           equ 144
DEF VRAM_TILEDATA_START equ $8000
DEF VRAM_TILE_SIZE      equ 16
DEF PALETTE             equ $E4
def OAM_START           equ $FE00
def SPRITES_TOTAL       equ 40*4    ;bytes
def rLCDC                equ $FF40
def PANTALLA_WIDTH      equ 32

DEF rP1   EQU $FF00
DEF rSCY  EQU $FF42
DEF rSCX  EQU $FF43
DEF rBGP  EQU $FF47
DEF rOBP0 EQU $FF48
DEF rDMA  EQU $FF46



; --- Flags LCDC ---
DEF LCDCF_BGON EQU %00000001
DEF LCDCF_OBJON EQU %00000010
DEF LCDCF_ON   EQU %10000000

; --- Joypad: selección y máscaras ---
DEF P1F_GET_BTN  EQU $10
DEF P1F_GET_DPAD EQU $20
DEF P1F_GET_NONE EQU $30

; Dejamos wCurKeys con 1 = pulsado (más cómodo para AND)
DEF PADF_RIGHT EQU %00000001
DEF PADF_LEFT  EQU %00000010
DEF PADF_UP    EQU %00000100
DEF PADF_DOWN  EQU %00001000

; --- Constantes de pantalla / sprite / márgenes ---
DEF SCR_W EQU 160
DEF SCR_H EQU 144
DEF SPR_W EQU 8
DEF SPR_H EQU 8

; Márgenes: distancia (px) desde cada borde donde empieza a scrollear
DEF H_MARGIN EQU 32      ; izquierda/derecha
DEF V_MARGIN EQU 24      ; arriba/abajo

; Umbrales de sprite en pantalla (coordenada local del sprite)
DEF LEFT_LIMIT   EQU H_MARGIN                         ; 32
DEF RIGHT_LIMIT  EQU (SCR_W - SPR_W - H_MARGIN)       ; 160-8-32 = 120
DEF TOP_LIMIT    EQU V_MARGIN                         ; 24
DEF BOTTOM_LIMIT EQU (SCR_H - SPR_H - V_MARGIN)       ; 144-8-24 = 112

DEF SPEED EQU 1  ; px/frame