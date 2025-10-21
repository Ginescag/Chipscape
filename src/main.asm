
; --- Registros HW ---
DEF rP1   EQU $FF00
DEF rLCDC EQU $FF40
DEF rSCY  EQU $FF42
DEF rSCX  EQU $FF43
DEF rLY   EQU $FF44
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

SECTION "GFX", ROM0

; 2 tiles de fondo (rayas) -> $9000
TileData:
  REPT 8
    db $00, $00
  ENDR
  REPT 8
    db %10101010, %01010101
  ENDR
TileDataEnd:

; 1 tile de sprite sencillo -> $9020
SpriteTile:
  db %00011000,%00011000
  db %00011000,%00011000
  db %11111111,%11111111
  db %00011000,%00011000
  db %00011000,%00011000
  db %00011000,%00011000
  db %00000000,%00000000
  db %00000000,%00000000
SpriteTileEnd:

; Tilemap 32x32 (256x256 px) alternando 0/1
TileMap:
  REPT 32
    REPT 16
      db 0, 1
    ENDR
  ENDR
TileMapEnd:

; ----------------- Variables -----------------
SECTION "WRAM Vars", WRAM0
wCameraX:   ds 1
wCameraY:   ds 1
wPlayerX:   ds 1
wPlayerY:   ds 1
wCurKeys:   ds 1
wPrevKeys:  ds 1

; ----------------- Código -----------------
SECTION "Main", ROM0

main::
  di
  ld sp, $FFFE

  ; Paletas
  ld a, %11100100
  ld [rBGP], a
  ld [rOBP0], a

  ; Cargar tiles BG a $9000 (tile 0 y 1)
  ld de, TileData
  ld hl, $9000
  ld bc, TileDataEnd - TileData
  call CopyBytes

  ; Cargar tile de sprite a $9020 (tile #2)
  ld de, SpriteTile
  ld hl, $9000 + (2*16)
  ld bc, SpriteTileEnd - SpriteTile
  call CopyBytes

  ; Cargar tilemap (32x32) a $9800
  ld de, TileMap
  ld hl, $9800
  ld bc, TileMapEnd - TileMap
  call CopyBytes

  ; Inicializar cámara y jugador en mundo (0..255)
  xor a
  ld [wCameraX], a
  ld [wCameraY], a
  ld a, 80
  ld [wPlayerX], a
  ld a, 72
  ld [wPlayerY], a

  ; Inicializar input
  xor a
  ld [wCurKeys], a
  ld [wPrevKeys], a

  ; Encender LCD: BG + Sprites
  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON
  ld [rLCDC], a
  ei

; =================== Bucle principal ===================
MainLoop:
  ; --- 1) INPUT + LÓGICA (fuera de VBlank) ---
  call UpdateKeys

  ; --------- Movimiento del jugador (mundo) ---------
  ; RIGHT
  ld a, [wCurKeys]
  and PADF_RIGHT
  jr z, .noRight
    ld hl, wPlayerX
    inc [hl]
  .noRight:

  ; LEFT
  ld a, [wCurKeys]
  and PADF_LEFT
  jr z, .noLeft
    ld hl, wPlayerX
    dec [hl]
  .noLeft:

  ; UP
  ld a, [wCurKeys]
  and PADF_UP
  jr z, .noUp
    ld hl, wPlayerY
    dec [hl]
  .noUp:

  ; DOWN
  ld a, [wCurKeys]
  and PADF_DOWN
  jr z, .noDown
    ld hl, wPlayerY
    inc [hl]
  .noDown:

  ; --------- Cámara con márgenes (dead-zone) ---------
  ; scrX = playerX - cameraX
  ld a, [wCameraX]
  ld c, a
  ld a, [wPlayerX]
  sub c                  ; A = scrX
  ; Si scrX > RIGHT_LIMIT -> cameraX += SPEED
  cp RIGHT_LIMIT
  jr c, .chkLeftX
  jr z, .chkLeftX
    ld hl, wCameraX
    inc [hl]
  .chkLeftX:
  ; recomputar scrX y comparar con LEFT_LIMIT
  ld a, [wCameraX]
  ld c, a
  ld a, [wPlayerX]
  sub c
  cp LEFT_LIMIT
  jr nc, .doneX
    ld hl, wCameraX
    dec [hl]
  .doneX:

  ; scrY = playerY - cameraY
  ld a, [wCameraY]
  ld c, a
  ld a, [wPlayerY]
  sub c                  ; A = scrY
  ; Si scrY > BOTTOM_LIMIT -> cameraY += SPEED
  cp BOTTOM_LIMIT
  jr c, .chkTopY
  jr z, .chkTopY
    ld hl, wCameraY
    inc [hl]
  .chkTopY:
  ; recomputar scrY y comparar con TOP_LIMIT
  ld a, [wCameraY]
  ld c, a
  ld a, [wPlayerY]
  sub c
  cp TOP_LIMIT
  jr nc, .doneY
    ld hl, wCameraY
    dec [hl]
  .doneY:

  call WaitVBlank

  ; --- 3) COMMIT a HW (dentro de VBlank) ---
  ; 3a) Scroll HW
  ld a, [wCameraY]
  ld [rSCY], a
  ld a, [wCameraX]
  ld [rSCX], a

  ; 3b) Escribir sprite en OAM: (player - camera) + offsets OAM
  ld hl, $FE00
  ; Y
  ld a, [wCameraY]
  ld c, a
  ld a, [wPlayerY]
  sub c                  ; scrY
  add 16                 ; offset Y OAM
  ld [hli], a
  ; X
  ld a, [wCameraX]
  ld c, a
  ld a, [wPlayerX]
  sub c                  ; scrX
  add 8                  ; offset X OAM
  ld [hli], a
  ; tile / flags
  ld a, 2
  ld [hli], a
  xor a
  ld [hli], a

  jp MainLoop

; =================== Rutinas ===================

CopyBytes:
  ld a, b
  or c
  ret z
.cb_loop:
  ld a, [de]
  ld [hl], a
  inc de
  inc hl
  dec bc
  ld a, b
  or c
  jp nz, .cb_loop
  ret


WaitVBlank:
.wvb:
  ld a, [rLY]
  cp 144
  jr c, .wvb
  ret

; Lectura de Joypad -> wCurKeys (1 = pulsado)

UpdateKeys:
  ;
  ld a, [wCurKeys]
  ld [wPrevKeys], a

  ; Botones (A,B,Select,Start) 
  ld a, P1F_GET_BTN
  ldh [rP1], a
  call .settle
  ldh a, [rP1]
  or $F0
  cpl
  and $0F
  ld b, a                 

  ; D-Pad
  ld a, P1F_GET_DPAD
  ldh [rP1], a
  call .settle
  ldh a, [rP1]
  or $F0
  cpl
  and $0F                  ; 1=pulsado (Right, Left, Up, Down)
  ld [wCurKeys], a

  ; liberar
  ld a, P1F_GET_NONE
  ldh [rP1], a
  ret

.settle:
  ldh a, [rP1]
  ldh a, [rP1]
  ldh a, [rP1]
  ret
