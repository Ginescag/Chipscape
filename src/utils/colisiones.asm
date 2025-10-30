INCLUDE "constantes.inc"

SECTION "CollisionUtils", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Gets the Address in VRAM of the tile the entity is touching
;; Receives the address of the sprite component in HL:
;; Address: |HL| +1| +2 | +3|
;; Value    [ y][ x][id][at]
;; Example: Sprite at (24, 32)
;;   TX = (24 - 8)/8 = 2
;;   TY = (32-16)/8  = 2
;; Address = BASE + 32TY + TX = $9800 + 2*32+2= $9842
;; INPUT: HL: address of the sprite
;; OUTPUT: HL: VRAM address of the tile
get_address_of_tile_being_touched:
    .y_to_ty
    ld a, [hl+]
    call convert_y_to_ty
    ld b, a     ;;B = TY
    .x_to_tx
    ld a, [hl]
    call convert_x_to_tx
    ld c, a     ;;X = TX
    ; ld de, $9800 ;;BASE ADDRESS = $9800 (VRAM Tilemap 1)
    ; la base del BG map puede ser $9800 o $9C00 (LCDC.3).
    ; dinámica
    call get_bg_base      ; DE = $9800 o $9C00 según LCDC.3
    call calculate_address_from_tx_and_ty
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Converts Y coordinate to a TY tile coordinate
convert_y_to_ty:
    sub 16      ;; Adjust for tilemap offset
    srl a    ;; Divide by 2
    srl a    ;; Divide by 4
    srl a    ;; Divide by 8
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Converts X coordinate to a TX tile coordinate
convert_x_to_tx:
    sub 8       ;; Adjust for tilemap offset
    srl a    ;; Divide by 2
    srl a    ;; Divide by 4
    srl a    ;; Divide by 8
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculates a VRAM Tilemap address from itx tile
;; coordinates (TX, TY). The tilemap is 32x32, and		
;; addresss of tile (0,0) in tile coordinates.
;; INPUT:
;;   DE: BASE ADDRESS
;;   B: TY
;;   C: TX
;; OUTPUT:
;;   HL: Address where the (TX, TY) tile is located
calculate_address_from_tx_and_ty:
    ;; TILE-ADDRESS = BASE + 32*TY + TX
    ld h, 0
    ld l, b
    add hl, hl ;; HL = 2*TY
    add hl, hl ;; HL = 4*TY
    add hl, hl ;; HL = 8*TY
    add hl, hl ;; HL = 16*TY
    add hl, hl ;; HL = 32*TY
    
    .add_tx
    ld b, 0
    add hl, bc ;; HL = 32*TY + TX

    .add_base
    add hl, de ;; HL = BASE + 32*TY + TX
    ret



; ==================================================
;  - Base BG map dinámica (LCDC.3)
;  - Versiones con scroll (SCX/SCY) y wrap 32x32
;  - Helper de lectura segura de VRAM (opcional)
;  - Variante "scrolled" para obtener dirección VRAM
; ==================================================

;----------------------------------------
; Devuelve en DE la base del BG Map según LCDC.3
;   LCDC bit 3 = 0 -> $9800 ; =1 -> $9C00
;----------------------------------------
get_bg_base:
    ldh  a, [$FF40]      ; LCDC
    and  %00001000       ; bit 3
    jr   z, .use_9800
    ld   de, $9C00
    ret
.use_9800:
    ld   de, $9800
    ret


;----------------------------------------
; Versiones con scroll y wrap 32x32
;   - Entradas: A = coord OAM (px)
;   - Salidas : A = TX/TY en rango 0..31
;----------------------------------------

; A = X (OAM)  -> A = TX con scroll
convert_x_to_tx_scrolled:
    sub 8                 ; Ajuste OAM X
    ld  b, a
    ldh a, [$FF43]        ; SCX
    add a, b
    srl a                 ; >>3
    srl a
    srl a
    and %00011111         ; wrap 0..31
    ret

; A = Y (OAM)  -> A = TY con scroll
convert_y_to_ty_scrolled:
    sub 16                ; Ajuste OAM Y
    ld  b, a
    ldh a, [$FF42]        ; SCY
    add a, b
    srl a                 ; >>3
    srl a
    srl a
    and %00011111         ; wrap 0..31
ret

;----------------------------------------
; Variante con scroll + base dinámica para debug:
; HL = &sprite [y][x][id][at]
; Devuelve HL = dirección en BG map (con SCX/SCY y base LCDC)
;----------------------------------------
get_vram_addr_under_sprite_scrolled:
    push bc
    push de

    ; TY (con scroll)
    ld  a, [hl+]                 ; y
    call convert_y_to_ty_scrolled
    ld  b, a                     ; B = TY

    ; TX (con scroll)
    ld  a, [hl]                  ; x  (HL ya apunta a x tras [hl+])
    call convert_x_to_tx_scrolled
    ld  c, a                     ; C = TX

    ; Base dinámica y cálculo de dirección
    call get_bg_base             ; DE = $9800 / $9C00
    call calculate_address_from_tx_and_ty  ; HL = base + 32*TY + TX

    pop  de
    pop  bc
ret

SECTION "CollisionEntities", ROM0

; --- Interval overlap (1D) ---
are_intervals_overlapping::
    ld   a, [de]           
    ld   h, a
    inc  de
    ld   a, [de]           
    ld   l, a
    dec  de
    ld   a, [bc]
    ld   d, a
    inc  bc
    ld   a, [bc]
    ld   e, a
    dec  bc

    ; ------- Caso 1: p1 >= p2 + w2 ? -------
    ld   a, d            ; A = p2
    add  a, e            ; A = p2 + w2
    jr   c, .skip_case1  ; overflow => p2+w2 >= 256 ⇒ p1 >= (p2+w2) es imposible
    ld   c, a            ; C = (p2 + w2)
    ld   a, h            ; A = p1
    sub  c               ; p1 - (p2 + w2)
    jr   nc, .no_overlap ; si p1 >= p2+w2 ⇒ NO solape

.skip_case1:
    ; ------- Caso 2: p2 >= p1 + w1 ? -------
    ld   a, h            ; A = p1
    add  a, l            ; A = p1 + w1
    jr   c, .skip_case2  ; overflow => p1+w1 >= 256 ⇒ p2 >= (p1+w1) es imposible
    ld   c, a            ; C = (p1 + w1)
    ld   a, d            ; A = p2
    sub  c               ; p2 - (p1 + w1)
    jr   nc, .no_overlap ; si p2 >= p1+w1 ⇒ NO solape

.skip_case2:
    ; Si no cayó en ningún NO solape, entonces SÍ solapan
    scf
    ret

.no_overlap:
    or   a               ; C=0
    ret


; --- AABB overlap (2D) ---
; 1. Checks if they collide on the Y axis
; 2. Checks if they collide on the X axis only if Y overlaps
; Receives in DE and BC the addresses of the two AABBs:
;              --AABB1--            --AABB2--
; Address: |DE| +1| +2| +3|     |BC| +1| +2| +3|
; Value:   [y1][h1][x1][w1]     [y2][h2][x2][w2]
; Returns Carry Flag (C=0 NC) when NOT-Colliding,
;                  and (C=1 C) when Colliding
; INPUT:
;        DE: address of AABB 1
;        BC: address of AABB 2
; OUTPUT:
;   Carry: { NC: Not Colliding , C: Colliding }
are_boxes_colliding::
    ; Guardamos los punteros originales
    push de
    push bc

    ;; Check Y axis overlap
    call are_intervals_overlapping
    jr   nc, .no_collision_restore    ; Si no solapan en Y, salir

    ; Restauramos punteros originales para avanzar a X
    pop  bc
    pop  de
    ; Avanzar a X (desplazamiento +2: [x][w])
    inc  de
    inc  de
    inc  bc
    inc  bc

    ; Guardamos de nuevo antes de la segunda llamada
    push de
    push bc

    ;; Check X axis overlap
    call are_intervals_overlapping
    jr   nc, .no_collision_restore  ; Si no solapan en X, salir (tras restaurar)

    ; Solapan en Y y en X ⇒ colisión
    pop  bc
    pop  de
    scf
    ret

    .no_collision_restore:
    pop  bc
    pop  de
    or   a
ret
