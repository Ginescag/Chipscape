; ============================================================
; collision_init.asm  (FINAL)
;  - Inicialización sencilla de colisiones al cargar la escena
;  - Llamar tras montar el BGMap de la escena (cargar mapa en VRAM)
; Requiere: funciones de collision_world.asm (col_copy_bgmap... / col_clear_overrides)
; API:
;   - collision_init_for_scene
; ============================================================
INCLUDE "constantes.inc"

SECTION "Collision Init API", ROM0

; Llamar justo después de cargar el BG map de la escena:
collision_init_for_scene::
    call col_copy_bgmap_from_vram   ; copia IDs a wBgMapIds
    call col_clear_overrides        ; sin overrides iniciales
    ret
