INCLUDE "inc/constants.inc"

SECTION "Camera", ROM0
EXPORT Camera_Reset, Camera_Update

Camera_Reset:
  xor a
  ld [wCameraX], a
  ld [wCameraY], a
  ret

Camera_Update:
  ld a, [wPlayerX]
  ld b, a
  ld a, [wCameraX]
  ld c, a
  ld a, b
  sub c
  cp RIGHT_LIMIT
  jr c, .chkLeftX
  jr z, .chkLeftX
    ld a, b
    sub RIGHT_LIMIT
    ld [wCameraX], a
    jr .doneX
.chkLeftX:
  cp LEFT_LIMIT
  jr nc, .doneX
    ld a, b
    sub LEFT_LIMIT
    ld [wCameraX], a
.doneX:

  ld a, [wPlayerY]
  ld b, a
  ld a, [wCameraY]
  ld c, a
  ld a, b
  sub c
  cp BOTTOM_LIMIT
  jr c, .chkTopY
  jr z, .chkTopY
    ld a, b
    sub BOTTOM_LIMIT
    ld [wCameraY], a
    jr .doneY
.chkTopY:
  cp TOP_LIMIT
  jr nc, .doneY
    ld a, b
    sub TOP_LIMIT
    ld [wCameraY], a
.doneY:
  ret
