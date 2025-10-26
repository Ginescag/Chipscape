INCLUDE "constantes.inc"

DEF SCR_W           EQU 160
DEF SCR_H           EQU 144

DEF MAP_W           EQU 256
DEF MAP_H           EQU 256

DEF SCX_MAX         EQU (MAP_W - SCR_W) ; 96
DEF SCY_MAX         EQU (MAP_H - SCR_H) ; 112

DEF SCX_INIT        EQU ((MAP_W/2) - (SCR_W/2)) ; 48
DEF SCY_INIT        EQU ((MAP_H/2) - (SCR_H/2)) ; 56

;Danger zone 
DEF DZ_LEFT         EQU 32
DEF DZ_RIGHT        EQU 32
DEF DZ_TOP          EQU 32
DEF DZ_BOTTOM       EQU 32

DEF RIGHT_LIMIT     EQU (SCR_W - DZ_RIGHT)     ; 128
DEF BOTTOM_LIMIT    EQU (SCR_H - DZ_BOTTOM)    ; 112

; -------------------------
; WRAM
; -------------------------
SECTION "WRAM Scroll", WRAM0
wCamX:               ds 1
wCamY:               ds 1
wScroll_PlayerE:     ds 1   
wPX:                 ds 1   
wPY:                 ds 1   
wVX:                 ds 1   
wVY:                 ds 1  
wFZ:                 ds 1   
wDX:                 ds 1   
wDY:                 ds 1   


SECTION "Scroll code", ROM0


Scroll_Init::
    ld   a, $FF
    ld  [wScroll_PlayerE], a

    call scroll_find_player

    ld   a, SCX_INIT
    ld  [wCamX], a
    ld  [rSCX], a

    ld   a, SCY_INIT
    ld  [wCamY], a
    ld  [rSCY], a
    ret


Scroll_Tick::
    ld   a, [wScroll_PlayerE]
    cp   $FF
    call z, scroll_find_player
    ld   a, [wScroll_PlayerE]
    cp   $FF
    ret  z

    ld   e, a

    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_X
    ld   l, a
    ld   a, [hl]
    ld  [wPX], a

    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_Y
    ld   l, a
    ld   a, [hl]
    ld  [wPY], a

    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VX
    ld   l, a
    ld   a, [hl]
    ld  [wVX], a

    ld   h, CMP_PHYSICS_H
    ld   l, e
    ld   a, l
    add  CMP_PH_VY
    ld   l, a
    ld   a, [hl]
    ld  [wVY], a

    xor  a
    ld  [wFZ], a

    ld   a, [wPX]
    cp   DZ_LEFT
    jr   c, .set_left
    jr   z, .set_left
    jr   .chk_right
.set_left:
    ld   a, [wFZ]
    set  0, a
    ld  [wFZ], a

.chk_right:
    ld   a, [wPX]
    cp   RIGHT_LIMIT
    jr   c, .chk_top
    ld   a, [wFZ]
    set  1, a
    ld  [wFZ], a

.chk_top:
    ld   a, [wPY]
    cp   DZ_TOP
    jr   c, .set_top
    jr   z, .set_top
    jr   .chk_bottom
.set_top:
    ld   a, [wFZ]
    set  2, a
    ld  [wFZ], a

.chk_bottom:
    ld   a, [wPY]
    cp   BOTTOM_LIMIT
    jr   c, .decide_axis
    ld   a, [wFZ]
    set  3, a
    ld  [wFZ], a

.decide_axis:
    xor  a
    ld  [wDX], a
    ld  [wDY], a

    ld   a, [wFZ]
    bit  0, a                 
    jr   z, .x_right
    ld   a, [wVX]             
    bit  7, a
    jr   z, .x_right
    ld   a, $FF               
    ld  [wDX], a
    jr   .y_axis

.x_right:
    ld   a, [wFZ]
    bit  1, a                
    jr   z, .y_axis
    ld   a, [wVX]             
    bit  7, a
    jr   nz, .y_axis
    or   a                    
    jr   z, .y_axis
    ld   a, 1                 
    ld  [wDX], a

.y_axis:
    ld   a, [wFZ]
    bit  2, a                 
    jr   z, .y_bottom
    ld   a, [wVY]             
    bit  7, a
    jr   z, .y_bottom
    ld   a, $FF               
    ld  [wDY], a
    jr   .apply_cam

.y_bottom:
    ld   a, [wFZ]
    bit  3, a                
    jr   z, .apply_cam
    ld   a, [wVY]             
    bit  7, a
    jr   nz, .apply_cam
    or   a
    jr   z, .apply_cam
    ld   a, 1                 
    ld  [wDY], a

.apply_cam:
    ld   a, [wDX]
    or   a
    jr   z, .no_cam_x
    cp   $FF
    jr   nz, .cam_x_pos
    ld   a, [wCamX]
    or   a
    jr   z, .x_cancel         
    dec  a
    ld  [wCamX], a
    ld  [rSCX], a
    ld   a, $FF
    ld  [wDX], a
    jr   .no_cam_x
.cam_x_pos:
    ld   a, [wCamX]
    cp   SCX_MAX
    jr   z, .x_cancel
    inc  a
    ld  [wCamX], a
    ld  [rSCX], a
    ld   a, 1
    ld  [wDX], a
    jr   .no_cam_x
.x_cancel:
    xor  a
    ld  [wDX], a
.no_cam_x:

    ld   a, [wDY]
    or   a
    jr   z, .no_cam_y
    cp   $FF
    jr   nz, .cam_y_pos
    ld   a, [wCamY]
    or   a
    jr   z, .y_cancel
    dec  a
    ld  [wCamY], a
    ld  [rSCY], a
    ld   a, $FF
    ld  [wDY], a
    jr   .no_cam_y
.cam_y_pos:
    ld   a, [wCamY]
    cp   SCY_MAX
    jr   z, .y_cancel
    inc  a
    ld  [wCamY], a
    ld  [rSCY], a
    ld   a, 1
    ld  [wDY], a
    jr   .no_cam_y
.y_cancel:
    xor  a
    ld  [wDY], a
.no_cam_y:

    ld   a, [wDX]
    ld   b, a
    ld   a, [wDY]
    or   b
    ret  z

    call scroll_shift_all_sprites
    ret


scroll_find_player::
    ld   de, components
.find_loop:
    ld   a, [de]
    cp   CMP_SENTINEL
    jr   z, .not_found

    bit  CMP_INFO_BIT_ALIVE, a
    jr   z, .next

    ld   h, CMP_INFO_H
    ld   l, e
    ld   a, l
    add  CMP_INFO_TYPE
    ld   l, a
    ld   a, [hl]
    bit  T_PLAYER, a
    jr   z, .next

    ld   a, e
    ld  [wScroll_PlayerE], a
    ret
.next:
    ld   a, e
    add  a, CMP_SIZE
    ld   e, a
    ld   a, d
    adc  0
    ld   d, a
    jr   .find_loop

.not_found:
    ld   a, $FF
    ld  [wScroll_PlayerE], a
    ret


scroll_shift_all_sprites::
    ld   de, components
    ld   a, [wDX]
    ld   b, a                
    ld   a, [wDY]
    ld   c, a                
.shift_loop:
    ld   a, [de]
    cp   CMP_SENTINEL
    ret  z

    bit  CMP_INFO_BIT_ALIVE, a
    jr   z, .next

    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_X
    ld   l, a
    ld   a, b
    or   a
    jr   z, .no_x
    ld   a, [hl]
    sub  b
    ld  [hl], a
.no_x:

    ld   h, CMP_SPRITE_H
    ld   l, e
    ld   a, l
    add  CMP_SPRITE_Y
    ld   l, a
    ld   a, c
    or   a
    jr   z, .no_y
    ld   a, [hl]
    sub  c
    ld  [hl], a
.no_y:

.next:
    ld   a, e
    add  a, CMP_SIZE
    ld   e, a
    ld   a, d
    adc  0
    ld   d, a
    jr   .shift_loop
