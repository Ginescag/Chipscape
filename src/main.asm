; ================== main.asm (robusto, sin duplicados) ==================
; --- Registros HW ---
DEF rP1   = $FF00
DEF rSCY  = $FF42
DEF rSCX  = $FF43
DEF rLY   = $FF44
DEF rBGP  = $FF47
DEF rLCDC = $FF40
DEF rOBP0 = $FF48
DEF rWY   = $FF4A
DEF rWX   = $FF4B

; ====== Tamaño de tu tilemap ======
; 136x64 px -> 17x8 tiles | 160x144 px -> 20x18 tiles
DEF MAP_W_T = 17
DEF MAP_H_T = 8

; ---------- Assets ----------
SECTION "GFX", ROM0
Tiles:    INCBIN "bp2.2bpp"       ; tiles 2bpp (rgbgfx)
TilesEnd:
BGMap:    INCBIN "bp2.tilemap"    ; tilemap (índices) (rgbgfx)
BGMapEnd:

; ---------- Copia genérica DE->HL (BC bytes) ----------
SECTION "Utils", ROM0
MemcpyVRAM:
.copy:
    ld a,b
    or c
    ret z
    ld a,[de]
    inc de
    ld [hl+],a
    dec bc
    jr .copy

; ---------- Limpiar un BG map 32x32 completo con tile 0 ----------
; Entrada: HL = $9800 o $9C00
ClearBG32x32:
    ld  bc, 32*32          ; 1024 bytes
    xor a                  ; tile 0
.bgclear:
    ld  [hl+],a
    dec bc
    ld  a,b
    or  c
    jr  nz,.bgclear
    ret

; ---------- Copiar tu tilemap W×H a $9800 sumando +1 ----------
; (Tus tiles se cargan desde $8010 => empiezan en tile #1)
CopyBGMapWH_Add1:
    ld  hl,$9800           ; destino: BG map 0
    ld  de,BGMap           ; origen: tu tilemap
    ld  b, MAP_H_T         ; filas
.row:
    ld  c, MAP_W_T         ; columnas
.col:
    ld  a,[de]
    inc de
    inc a                  ; +1 -> ajusta al desplazamiento de tiles
    ld  [hl+],a
    dec c
    jr  nz,.col
    ; saltar (32 - MAP_W_T) en VRAM
    ld  a, 32 - MAP_W_T
.sk:
    inc hl
    dec a
    jr  nz,.sk
    dec b
    jr  nz,.row
    ret

; ---------- Ocultar TODOS los sprites (por si luego activas OBJ) ----------
; 40 sprites * 4 bytes. Y=160 => fuera de pantalla.
HideAllSprites:
    ld  hl,$FE00
    ld  b,40
.loop:
    ld  a,$A0              ; Y = 160
    ld  [hl+],a
    xor a
    ld  [hl+],a            ; X = 0
    ld  [hl+],a            ; tile = 0
    ld  [hl+],a            ; flags = 0
    dec b
    jr  nz,.loop
    ret

; ------------------ Entry & helpers ------------------
SECTION "Entry point", ROM0[$150]
waitVBlank:
   ldh a,[rLY]
   cp 144
   jr nz, waitVBlank
   ret

; ------------------ MAIN --------------------
main::
    ; 1) LCD OFF (escritura segura en VRAM/OAM)
    ldh a,[rLCDC]
    res 7,a
    ldh [rLCDC],a

    ; 2) Paletas
    ld a,%11100100         ; BGP (fondo)
    ldh [rBGP],a
    ld a,%11100100         ; OBP0 (sprites) por si luego los usas
    ldh [rOBP0],a

    ; 3) Ventana fuera de pantalla (además de estar OFF por LCDC bit5=0)
    ld a,$A0               ; WY=160 (>143)
    ldh [rWY],a
    ld a,$A7               ; WX=167 (offset -7)
    ldh [rWX],a

    ; 4) TILE 0 vacío en $8000 (16 bytes a 0)
    ld  hl,$8000
    ld  b,16
    xor a
.t0:
    ld  [hl+],a
    dec b
    jr  nz,.t0

    ; 5) Cargar tus tiles desde $8010 (tile #1 en adelante)
    ld  hl,$8010
    ld  de,Tiles
    ld  bc, TilesEnd - Tiles
    call MemcpyVRAM

    ; 6) Limpiar ambos BG maps 32×32 (por si hubiese residuos)
    ld  hl,$9800
    call ClearBG32x32
    ld  hl,$9C00
    call ClearBG32x32

    ; 7) Pegar tu tilemap W×H en $9800 con +1
    call CopyBGMapWH_Add1

    ; 8) Ocultar sprites (aunque OBJ estará OFF, dejamos OAM limpio)
    call HideAllSprites

    ; 9) Scroll a 0
    xor a
    ldh [rSCX],a
    ldh [rSCY],a

    ; 10) LCD ON (BG ON, tiles $8000, BG map $9800, WINDOW OFF, OBJ OFF)
    ; bit7 LCD ON | bit4 $8000 | bit3 $9800 | bit5=0 ventana OFF | bit1=0 OBJ OFF | bit0 BG ON
    ld  a,%10010001        ; $91
    ldh [rLCDC],a

    di
    halt
