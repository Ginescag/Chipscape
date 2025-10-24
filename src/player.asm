INCLUDE "inc/constants.inc"
INCLUDE "inc/hardware.inc"

SECTION "Player", ROM0
EXPORT Player_Init, Player_Update

Player_Init:
  ld a, 80
  ld [wPlayerX], a
  ld a, 72
  ld [wPlayerY], a
  ret

Player_Update:
  ld a, [wCurKeys]
  and PADF_RIGHT
  jr z, .noRight
    ld hl, wPlayerX
    ld a, [hl]
    add SPEED
    ld [hl], a
  .noRight:

  ld a, [wCurKeys]
  and PADF_LEFT
  jr z, .noLeft
    ld hl, wPlayerX
    ld a, [hl]
    sub SPEED
    ld [hl], a
  .noLeft:

  ld a, [wCurKeys]
  and PADF_UP
  jr z, .noUp
    ld hl, wPlayerY
    ld a, [hl]
    sub SPEED
    ld [hl], a
  .noUp:

  ld a, [wCurKeys]
  and PADF_DOWN
  jr z, .noDown
    ld hl, wPlayerY
    ld a, [hl]
    add SPEED
    ld [hl], a
  .noDown:
  ret
