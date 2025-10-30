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

DEF VRAM_SPRITENC_START_POS     EQU $1A
DEF VRAM_TILES_START_POS        EQU $80
DEF VRAM_SPRITE_CHIP_START_POS  EQU $C3
DEF VRAM_GO_POS                 EQU $DA

DEF rP1   EQU $FF00
DEF rSCY  EQU $FF42
DEF rSCX  EQU $FF43
DEF rBGP  EQU $FF47
DEF rOBP0 EQU $FF48
DEF rOBP1 EQU $FF49
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
DEF PADF_RIGHT_BIT EQU 0
DEF PADF_LEFT_BIT  EQU 1
DEF PADF_UP_BIT    EQU 2
DEF PADF_DOWN_BIT  EQU 3

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
DEF CMP_INFO_RESERVE    RB 1
DEF CMP_INFO_TAGS       RB 1 ;;SAFRIDMC Sentinel, Alive, Fisicas, render, Interactuable, Mortal, movible, COLISION                        
                             ;;00000000
DEF CMP_INFO_TYPE       RB 1 ;;JEPSfwew Jugador, Enemigo, Pickup, specialitem fireSI waterSI earthSI windSI //ESTO ES UN EJEMPLO Y PUEDE CAMBIAR
                             ;;00000000
DEF CMP_INFO_HP         RB 1 ;; VIDA DE LA ENTIDAD
DEF CMP_SIZE            RB 0

;;BITS DEL TIPO PARA SABER LO QUE SON
DEF T_PLAYER      EQU 7
DEF T_ENEMY       EQU 6  ; bit6
DEF T_PICKUP      EQU 5  ; bit5
DEF T_SITEM       EQU 4  ; bit4

; Subtipos para SPECIAL_ITEM (nibble bajo)
DEF SI_FIRE       EQU 3  ; bit0
DEF SI_WATER      EQU 2  ; bit1
DEF SI_EARTH      EQU 1  ; bit2
DEF SI_WIND       EQU 0  ; bit3

; Máscaras útiles
DEF CLASS_MASK    EQU %11110000
DEF SITEM_MASK    EQU %00001111



;;CMP_PHYSICS_FIELDS
rsreset
DEF CMP_PH_X   RB 1     ;;POS X DE LA ENTIDAD
DEF CMP_PH_Y   RB 1     ;;POS Y DE LA ENTIDAD
DEF CMP_PH_VX  RB 1     ;;VEL X DE LA ENTIDAD
DEF CMP_PH_VY  RB 1     ;;VEL Y DE LA ENTIDAD


;;CMP_SPRITE_FIELDS
rsreset
DEF CMP_SPRITE_Y    RB 1     ;;POS y DE LA ENTIDAD
DEF CMP_SPRITE_X    RB 1     ;;POS x DE LA ENTIDAD
DEF CMP_SPRITE_TI   RB 1     ;;TILE DE LA ENTIDAD
DEF CMP_SPRITE_PROP RB 1     ;;%00000000


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


DEF NUM_ENTITIES    EQU 20
DEF CMP_ARR_BYTES   EQU NUM_ENTITIES * CMP_SIZE
DEF CMP_INFO_H      EQU $C0
DEF CMP_SPRITE_H    EQU $C1
DEF CMP_PHYSICS_H  EQU $C2
DEF CMP_SENTINEL    EQU $FF
DEF CMP_FREE        EQU $00 ;;ESTO ES PARA SABER SI LA ENTIDAD ESTA MUERTA O NO
DEF CMP_RESERVE     EQU (1 << CMP_INFO_BIT_ALIVE)

;;TILES DEL PERSONAJE PRINCIPAL
                            ;;TILES COMPLEMENTARIOS PARA LA ANIMACION
DEF TILE_FL_Dl = $1A        ;;$1E 
DEF TILE_FL_Dr = $1C        ;;$20

DEF TILE_FL_Ll = $22        ;;$26
DEF TILE_FL_Lr = $24        ;;$28

DEF TILE_FL_Rl = $2A        ;;$2E
DEF TILE_FL_Rr = $2C        ;;$30

DEF TILE_FL_Ul = $32        ;;$36
DEF TILE_FL_UR = $34        ;;$38

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEF TILE_MIB_Dl = $3E        ;;$42 
DEF TILE_MIB_Dr = $40        ;;$44

DEF TILE_MIB_Ll = $5A        ;;$5E
DEF TILE_MIB_Lr = $5C        ;;$60

DEF TILE_MIB_Rl = $52        ;;$56
DEF TILE_MIB_Rr = $54        ;;$58

DEF TILE_MIB_Ul = $4A        ;;$4E
DEF TILE_MIB_Ur = $4C        ;;$50


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEF TILE_BC_Dl = $66        ;;$6A 
DEF TILE_BC_Dr = $68        ;;$6C

DEF TILE_BC_Ll = $7A        ;;$7E
DEF TILE_BC_Lr = $7C        ;;$80

DEF TILE_BC_Rl = $82        ;;$86
DEF TILE_BC_Rr = $84        ;;$88

DEF TILE_BC_Ul = $72        ;;$76
DEF TILE_BC_Ur = $74        ;;$78

DEF ENTITY_TEMPLATE_STRIDE EQU (CMP_SIZE*3)
