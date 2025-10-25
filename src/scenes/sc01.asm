;==========================================
; sc01.asm :: escena 01 con CHIPCOUNT (FIX VRAM)
;==========================================
INCLUDE "constantes.inc"

SECTION "Scene 01 code", ROM0

;------------------------------------------
; Inicialización de escena
;------------------------------------------
sc01_init::
  ; Apaga LCD para cargar tiles sin restricciones de tiempo
  call apaga_pantalla

  ; --- Carga de patrones de sprites/tiles propios de la escena ---
  ; FLATLINE_front0 -> $1A.. (4 tiles = 64 bytes)
  ld hl, FLATLINE_front0
  ld de, VRAM_TILEDATA_START + $1A * VRAM_TILE_SIZE
  ld b, 64
  call memcpy

  ; FLATLINE_front1 -> $1E.. (4 tiles = 64 bytes)
  ld hl, FLATLINE_front1
  ld de, VRAM_TILEDATA_START + $1E * VRAM_TILE_SIZE
  ld b, 64
  call memcpy

  ; --- HUD: tiles compartidos + específicos ---
  ; Dígitos (0..9), blank $EF y "SCORE" ($F0..$F4)
  call Score_LoadTiles

  ; Icono chip ($F5) y 'X' ($F6)
  call ChipCount_LoadTiles

  ; --- Paletas ---
  ld   a, %11100100
  ld  [rOBP0], a
  ld  [rBGP],  a

  ; --- Window en la parte superior ---
  ld   a, 0
  ldh  [$4A], a           ; WY=0
  ld   a, 7
  ldh  [$4B], a           ; WX=7  (columna 0)

  ; --- Estado lógico inicial (no toca VRAM) ---
  call Score_Reset

  call Timer_Init
  ld  hl, 90
  call Timer_SetSecsHL

  call ChipCount_Reset

  ; Enciende LCD tras dejar VRAM completamente lista
  call enciende_pantalla

  ; --- Inicialización del HUD (escribe en window map) ---
  call wait_vblank
  call Score_HUD_Init

  call wait_vblank
  call Timer_HUD_Init

  call wait_vblank
  call ChipCount_HUD_Init

  ; Resto del juego
  ei

  ; --- Entidades (sin cambios) ---
  call man_entity_init

  call man_entity_alloc
  ld d, CMP_SPRITE_H
  ld e, l
  ld hl, (sc01_entity1+0)
  ld b, CMP_SIZE
  push de
  call memcpy
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, (sc01_entity1+4)
  ld b, CMP_SIZE
  call memcpy

  call man_entity_alloc
  ld d, CMP_SPRITE_H
  ld e, l
  ld hl, (sc01_entity2+0)
  ld b, CMP_SIZE
  push de
  call memcpy
  pop de
  ld d, CMP_PHYSICS_H
  ld hl, (sc01_entity2+4)
  ld b, CMP_SIZE
  call memcpy
  ret


;==========================================
; Bucle principal de la escena
;==========================================
sc01_run::
.loop:
  ; Lógica
  call sys_physics_update

  ; Timer 1 Hz
  ld  a, [wTimerFlag1s]
  or  a
  jr  z, .no_second
  xor a
  ld  [wTimerFlag1s], a

  ld  a, [wTimerLo]
  or  a
  jr  nz, .dec_low
  ld  a, [wTimerHi]
  or  a
  jr  z, .after_timer
.dec_low:
  ld  a, [wTimerLo]
  sub  1
  ld  [wTimerLo], a
  jr  nc, .after_timer
  ld  a, [wTimerHi]
  dec a
  ld  [wTimerHi], a
.after_timer:
  call Timer_ComputeDigits
.no_second:

  ; Precálculo del score
  call Score_ComputeDigits

  ; VBlank: Window map + OAM
  call wait_vblank
  call Timer_HUD_Update
  call Score_HUD_Draw
  call ChipCount_HUD_Update
  call man_entity_draw
  jr .loop
  ret
