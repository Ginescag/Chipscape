INCLUDE "inc/hardware.inc"
INCLUDE "inc/constants.inc"

IF !DEF(rIF)
  DEF rIF EQU $FF0F
ENDC
IF !DEF(rWX)
  DEF rWX EQU $FF4B
ENDC

IF !DEF(WIN_WX_ON)
  DEF WIN_WX_ON  EQU 7     
ENDC
IF !DEF(WIN_WX_OFF)
  DEF WIN_WX_OFF EQU 168  
ENDC

SECTION "Interrupt Vectors", ROM0[$0040]
  jp ISR_VBlank      
SECTION "Interrupt Vectors 2", ROM0[$0048]
  jp ISR_STAT        
SECTION "Interrupt Vectors 3", ROM0[$0050]
  jp Timer_ISR       
SECTION "Interrupt Vectors 4", ROM0[$0058]
  jp ISR_Serial      
SECTION "Interrupt Vectors 5", ROM0[$0060]
  jp ISR_Joypad      

SECTION "ISRs Code", ROM0

ISR_VBlank:
  push af
  ld a, WIN_WX_ON
  ld [rWX], a
  ld a, [rIF]
  res 0, a
  ld [rIF], a
  pop af
  reti

ISR_STAT:
  push af
  ld a, [rIF]
  res 1, a
  ld [rIF], a
  ld a, WIN_WX_OFF
  ld [rWX], a
  pop af
  reti

; Stubs
ISR_Serial:
  reti

ISR_Joypad:
  reti
