;;========================================================================
;;========================================================================
;;CONSTANTES BASICAS GENERALES
;;========================================================================
;;========================================================================
DEF rLY                 equ $FF44
DEF VBLANK_ST           equ 144
DEF VRAM_TILEDATA_START equ $8000
DEF VRAM_TILE_SIZE      equ 16
DEF PALETTE             equ $E4
def OAM_START           equ $FE00
def SPRITES_TOTAL       equ 40*4    ;bytes
def rLCDC               equ $FF40
def PANTALLA_WIDTH      equ 32

DEF rP1   EQU $FF00
DEF rSCY  EQU $FF42
DEF rSCX  EQU $FF43
DEF rBGP  EQU $FF47
DEF rOBP0 EQU $FF48
DEF rDMA  EQU $FF46

;;========================================================================
;;========================================================================
;;MISC
;;========================================================================
;;========================================================================

; --- Flags LCDC ---
DEF LCDCF_BGON  EQU %00000001
DEF LCDCF_OBJON EQU %00000010
DEF LCDCF_ON    EQU %10000000

; --- Joypad: selección y máscaras ---
DEF P1F_GET_BTN  EQU $10
DEF P1F_GET_DPAD EQU $20
DEF P1F_GET_NONE EQU $30

; Dejamos wCurKeys con 1 = pulsado (más cómodo para AND)
DEF PADF_RIGHT EQU %00000001
DEF PADF_LEFT  EQU %00000010
DEF PADF_UP    EQU %00000100
DEF PADF_DOWN  EQU %00001000


;;========================================================================
;;========================================================================
;;CONSTANTES PARA EL ENTITY MANAGER
;;========================================================================
;;========================================================================

;;CMP_INFO_FIELDS
rsreset
DEF CMP_INFO_CMPS   RB 1
DEF CMP_INFO_TAGS   RB 1 ;;SAFRIDMCP Sentinel, Alive, Colisionable, Fisicas, Interactuable, Mortal, movible, COLISION, PICK-UP                        
                         ;;00000000
DEF CMP_INFO_TYPE   RB 1
DEF CMP_INFO_FREE2  RB 1
DEF CMP_SIZE        RB 0

;;CMP_PHYSICS_FIELDS
rsreset
DEF CMP_PH_X   RB 1     ;;POS X DE LA ENTIDAD
DEF CMP_PH_Y   RB 1     ;;POS Y DE LA ENTIDAD
DEF CMP_PH_VX  RB 1     ;;VEL X DE LA ENTIDAD
DEF CMP_PH_VY  RB 1     ;;VEL Y DE LA ENTIDAD


;;CMP_PHYSICS_FIELDS
rsreset
DEF CMP_SPRITE_Y    RB 1     ;;POS X DE LA ENTIDAD
DEF CMP_SPRITE_X    RB 1     ;;POS Y DE LA ENTIDAD
DEF CMP_SPRITE_TI   RB 1     ;;TILE DE LA ENTIDAD
DEF CMP_SPRITE_PROP RB 1     ;;VEL Y DE LA ENTIDAD


;;TAGS-BITS-INFO 
;;ESTO PUEDE CAMBIAR!!!!!!
DEF CMP_INFO_BIT_SENTINEL    = 7 ;;ESTO EVITA QUE UNA ENTIDAD PUEDA TENER TODOS LOS BITS A 1 SIENDO $FF Y HACIENDOSE PASAR POR EL CENTINELA
DEF CMP_INFO_BIT_ALIVE       = 6
DEF CMP_INFO_BIT_PHYSICS     = 5
DEF CMP_INFO_BIT_RENDER      = 4
DEF CMP_INFO_BIT_INTERACTIVE = 3
DEF CMP_INFO_BIT_DEADLY      = 2
DEF CMP_INFO_BIT_MOVABLE     = 1
DEF CMP_INFO_BIT_COLISION    = 0


DEF NUM_ENTITIES    EQU 10
DEF CMP_ARR_BYTES   EQU NUM_ENTITIES * CMP_SIZE
DEF CMP_INFO_H      EQU $C0
DEF CMP_SPRITE_H    EQU $C1
DEF CMP_PHYSICS_H  EQU $C2
DEF CMP_SENTINEL    EQU $FF
DEF CMP_FREE        EQU $00 ;;ESTO ES PARA SABER SI LA ENTIDAD ESTA MUERTA O NO
DEF CMP_RESERVE     EQU (1 << CMP_INFO_BIT_ALIVE)


