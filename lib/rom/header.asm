* = $7fb0
!text "C64 CARTRIDGE   "    ; Cartridge Header
!byte $00, $00, $00, $40    ; Header length
!byte $01, $00              ; Cartridge version
!byte $00, $00              ; Cartridge hardware type
!byte $00                   ; EXROM line
!byte $01                   ; GAME line
!fill 6, $00                ; Reserved
!text "MARCH64"             ; Cartridge name
!fill 25, $ff

* = $7ff0
!text "CHIP"                ; CHIP Header
!byte $00, $00, $20, $10    ; Total packet length
!byte $00, $00              ; CHIP type
!byte $00, $00              ; Bank value
!byte $80, $00              ; Starting load address
!byte $20, $00              ; ROM image size

* = $8000

!word .coldstart
!word .warmstart
!pet "CBM80"

;	KERNAL RESET ROUTINE
.coldstart
stx $d016				; Turn on VIC for PAL / NTSC check
jsr $fda3				; IOINIT - Init CIA chips
jsr $fd50				; RANTAM - Clear/test system RAM
jsr $fd15				; RESTOR - Init KERNAL RAM vectors
jsr $ff5b				; CINT   - Init VIC and screen editor
;cli					    ; Re-enable IRQ interrupts

.warmstart
; ROM data
