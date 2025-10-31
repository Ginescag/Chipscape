;=========================
; constantes.inc (ACTUALIZADO)
;=========================
;;========================================================================
;;========================================================================
;;CONSTANTES BASICAS GENERALES
;;========================================================================
;;========================================================================
DEF rLY                 EQU $FF44
DEF VBLANK_ST           EQU 144
DEF VRAM_TILEDATA_START EQU $8000
DEF VRAM_TILE_SIZE      EQU 16
DEF PALETTE             EQU $E4
DEF OAM_START           EQU $FE00
DEF SPRITES_TOTAL       EQU 40*4      ; bytes
DEF rLCDC               EQU $FF40
DEF PANTALLA_WIDTH      EQU 32

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
DEF rWY   EQU $FF4A
DEF rWX   EQU $FF4B

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
DEF CMP_INFO_TAGS       RB 1
DEF CMP_INFO_TYPE       RB 1
DEF CMP_INFO_HP         RB 1
DEF CMP_SIZE            RB 0

;;BITS DEL TIPO
DEF T_PLAYER      EQU 7
DEF T_ENEMY       EQU 6
DEF T_PICKUP      EQU 5
DEF T_SITEM       EQU 4

; Subtipos SPECIAL_ITEM (nibble bajo)
DEF SI_FIRE       EQU 3
DEF SI_WATER      EQU 2
DEF SI_EARTH      EQU 1
DEF SI_WIND       EQU 0

; Máscaras
DEF CLASS_MASK    EQU %11110000
DEF SITEM_MASK    EQU %00001111

;;CMP_PHYSICS_FIELDS
rsreset
DEF CMP_PH_X   RB 1
DEF CMP_PH_Y   RB 1
DEF CMP_PH_VX  RB 1
DEF CMP_PH_VY  RB 1

;;CMP_SPRITE_FIELDS
rsreset
DEF CMP_SPRITE_Y    RB 1
DEF CMP_SPRITE_X    RB 1
DEF CMP_SPRITE_TI   RB 1
DEF CMP_SPRITE_PROP RB 1

;;TAGS-BITS-INFO
DEF CMP_INFO_BIT_SENTINEL    = 7
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
DEF CMP_PHYSICS_H   EQU $C2
DEF CMP_SENTINEL    EQU $FF
DEF CMP_FREE        EQU $00
DEF CMP_RESERVE     EQU (1 << CMP_INFO_BIT_ALIVE)

;; TILES DEL PERSONAJE PRINCIPAL
DEF TILE_FL_Dl = $1A
DEF TILE_FL_Dr = $1C
DEF TILE_FL_Ll = $22
DEF TILE_FL_Lr = $24
DEF TILE_FL_Rl = $2A
DEF TILE_FL_Rr = $2C
DEF TILE_FL_Ul = $32
DEF TILE_FL_UR = $34

DEF TILE_MIB_Dl = $3E
DEF TILE_MIB_Dr = $40
DEF TILE_MIB_Ll = $5A
DEF TILE_MIB_Lr = $5C
DEF TILE_MIB_Rl = $52
DEF TILE_MIB_Rr = $54
DEF TILE_MIB_Ul = $4A
DEF TILE_MIB_Ur = $4C

DEF TILE_BC_Dl  = $66
DEF TILE_BC_Dr  = $68
DEF TILE_BC_Ll  = $7A
DEF TILE_BC_Lr  = $7C
DEF TILE_BC_Rl  = $82
DEF TILE_BC_Rr  = $84
DEF TILE_BC_Ul  = $72
DEF TILE_BC_Ur  = $74

DEF ENTITY_TEMPLATE_STRIDE EQU (CMP_SIZE*3)

; ==============================
; I/O REGISTERS (Timer / IRQ)
; ==============================
DEF rDIV    EQU $FF04
DEF rTIMA   EQU $FF05
DEF rTMA    EQU $FF06
DEF rTAC    EQU $FF07
DEF rIF     EQU $FF0F
DEF rIE     EQU $FFFF

; Interrupt Enable Flags
DEF IEF_TIMER    EQU %00000100

; ==============================
; Timer control (TAC)
; ==============================
DEF TACF_EN      EQU %00000100
DEF TACF_4KHZ    EQU %00000000

; Sub-ticks por segundo a 4KHz, TMA=0 -> 4096/256 = 16
DEF TICKS_PER_SECOND   EQU 16

; ==============================
; HUD / Window base
; ==============================
DEF WIN_MAP_BASE     EQU $9C00
DEF HUD_BLANK_TILE   EQU $EF
DEF HUD_ROW_DIGITS   EQU 1

; ==============================
; HUD (GENÉRICAS)
; ==============================
DEF HUD_TIMER_START_SECS EQU 60
DEF primera_escela       EQU 0

; ==============================
; Timer HUD layout
; ==============================
DEF DIGIT_TILE_BASE  EQU 4

DEF TIMER_X_H        EQU 17
DEF TIMER_X_T        EQU 18
DEF TIMER_X_O        EQU 19

DEF TIMER_ADDR_H     EQU (WIN_MAP_BASE + HUD_ROW_DIGITS*32 + TIMER_X_H)
DEF TIMER_ADDR_T     EQU (WIN_MAP_BASE + HUD_ROW_DIGITS*32 + TIMER_X_T)
DEF TIMER_ADDR_O     EQU (WIN_MAP_BASE + HUD_ROW_DIGITS*32 + TIMER_X_O)

; 0x03E7 = 999
DEF TIMER_MAX_H      EQU 3
DEF TIMER_MAX_L      EQU $E7
;CONSTANTES SCORE
DEF SCORE_DIGIT_BASE     EQU 4        ; debe coincidir con DIGIT_TILE_BASE
DEF SCORE_CHAR_BASE      EQU $F0      ; tiles para 'S','C','O','R','E'

DEF SCORE_ROW_LABEL      EQU 0
DEF SCORE_ROW_DIGITS     EQU 1

DEF SCORE_X_LABEL        EQU 7
DEF SCORE_X_DIGITS       EQU 7

DEF SCORE_ADDR_LABEL0    EQU (WIN_MAP_BASE + SCORE_ROW_LABEL*32  + SCORE_X_LABEL   + 0)
DEF SCORE_ADDR_DIGITS0   EQU (WIN_MAP_BASE + SCORE_ROW_DIGITS*32 + SCORE_X_DIGITS  + 0)

;chipcount
DEF TILE_CHIP_IDX     EQU $F5
DEF TILE_X_IDX        EQU $F6
DEF CHIPS_DIGIT_BASE  EQU 4
DEF CHIPS_ROW         EQU 1
DEF CHIP_X_ICON       EQU 2
DEF CHIP_X_LETTER     EQU 3
DEF CHIP_X_TENS       EQU 4
DEF CHIP_X_ONES       EQU 5
DEF CHIP_ADDR_ICON    EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_ICON)
DEF CHIP_ADDR_X       EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_LETTER)
DEF CHIP_ADDR_TENS    EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_TENS)
DEF CHIP_ADDR_ONES    EQU (WIN_MAP_BASE + CHIPS_ROW*32 + CHIP_X_ONES)