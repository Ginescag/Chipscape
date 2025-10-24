; ---------- Dimensiones ----------
DEF SCR_W  EQU 160
DEF SCR_H  EQU 144
DEF SPR_W  EQU 8
DEF SPR_H  EQU 8

; ---------- Dead-zone ----------
DEF H_MARGIN  EQU 16
DEF V_MARGIN  EQU 16
DEF LEFT_LIMIT   EQU H_MARGIN
DEF RIGHT_LIMIT  EQU (SCR_W - SPR_W - H_MARGIN)
DEF TOP_LIMIT    EQU V_MARGIN
DEF BOTTOM_LIMIT EQU (SCR_H - SPR_H - V_MARGIN)

; ---------- Velocidad jugador ----------
DEF SPEED EQU 1
