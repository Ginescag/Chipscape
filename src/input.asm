INCLUDE "inc/hardware.inc"

SECTION "Input", ROM0
EXPORT Input_Read


Input_Read:
  ld a, [wCurKeys]
  ld [wPrevKeys], a

  ; Botones
  ld a, P1F_GET_BTN
  ldh [rP1], a
  call .settle
  ldh a, [rP1]
  or $F0
  cpl
  and $0F

  ld a, P1F_GET_DPAD
  ldh [rP1], a
  call .settle
  ldh a, [rP1]
  or $F0
  cpl
  and $0F
  ld [wCurKeys], a

  ld a, P1F_GET_NONE
  ldh [rP1], a
  ret

.settle:
  ldh a, [rP1]
  ldh a, [rP1]
  ldh a, [rP1]
  ret
