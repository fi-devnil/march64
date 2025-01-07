* = $063a
!pseudopc $0200 {

; Screen data
!scr "march64 v0.1", $00, $00
!scr "step: - runs: --", $00, $74 ; $74 indicates special handling for the following line
!scr "$x000-$xfff  --", $ff

!zone init_screen_zone {
init_screen   lda #<$0200   ; from address
              sta $fb
              lda #>$0200
              sta $fb+1
              lda #<$0400   ; to address
              sta $fd
              lda #>$0400
              sta $fd+1
              ldx #$30     ; counter for chunk lines
              ldy #$00     ; froml
              jmp .loop
.start_chunk  inx
              cpx #$3a
              beq .move_x
              jmp .store_y
.end_chunk    cpx #$06
              beq .return
              dec $fb
              ldy #$00
              jmp .loop
.store_y      clc
              iny
              tya
              adc $fb     ; add y to froml
              sta $fb
.next_line    clc
              ldy #$00    ; reset y to $00
              lda $fd
              adc #$28    ; increase "to" by $28
              sta $fd
              bcc .loop
              inc $fd+1
              jmp .loop
.move_x       sec
              txa
              sbc #$39
              tax
              jmp .store_y
.write_x      txa
              sta ($fd),y
              iny
.loop         lda ($fb),y
              beq .store_y
              cmp #$74
              beq .start_chunk
              cmp #$18
              beq .write_x
              cmp #$ff
              beq .end_chunk
              sta ($fd),y
              iny
              jmp .loop
.return       rts
}

!zone init_colors_zone {
init_colors   jsr enable_io_ports
              lda #COLOR_WHITE
              sta $d020     ; Set border color
              sta $d021     ; Set background color
              lda #COLOR_BLACK
              ldy #$00
.loop         sta $d800,y
              sta $d900,y
              sta $da00,y
              sta $db00,y
              iny
              bne .loop
              jsr enable_all_ram
              ldy #$00
              rts
}

!zone clear_screen_zone {
clear_screen  ldx #$00
              lda #$20
.loop         sta $0400,x
              sta $04fa,x
              sta $05f4,x
              sta $06ee,x
              inx
              cpx #$fa
              bne .loop
              rts
}

!zone update_chunk_error_label_zone {
update_chunk_error_label  jsr find_current_screen_line
                          ldy #$0d    ; screen offset (12)
                          jsr enable_io_ports
                          lda CHUNK_ERROR_ACCU_ADDR
                          cmp #$00
                          bne .red
.green                    lda #COLOR_GREEN
!byte                     $2c         ; Skip next line
.red                      lda #COLOR_RED
.label                    sta (CHUNK_CLR_LINE_START_ADDR_LO),y
                          iny
                          sta (CHUNK_CLR_LINE_START_ADDR_LO),y
                          dey
                          jsr enable_all_ram
                          lda CHUNK_ERROR_ACCU_ADDR
                          jsr get_hi_nibble
                          jsr hex_to_scrcode
                          sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                          iny
                          lda CHUNK_ERROR_ACCU_ADDR
                          jsr get_lo_nibble
                          jsr hex_to_scrcode
                          sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                          ldy #$00    ; reset Y
                          rts

}

; Hex to screen code
!zone hex_to_scrcode_zone {
hex_to_scrcode  cmp #$0a
                bcs .letter
.number         clc
                adc #$30
                jmp .return
.letter         sec
                sbc #$09
                clc
.return         rts
}

!zone update_current_chunk_signs_zone {
insert_current_chunk_signs  jsr find_current_screen_line
                            ldy #$0c
                            lda #$3e    ; >
                            sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                            ldy #$0f
                            lda #$3c    ; <
                            sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                            ldy #$00
                            rts
clear_current_chunk_signs   jsr find_current_screen_line
                            ldy #$0c
                            lda #$20
                            sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                            ldy #$0f
                            sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                            ldy #$00
                            rts
}

!zone find_current_screen_line_zone {
find_current_screen_line  lda #<$04a0
                          sta CHUNK_SCR_LINE_START_ADDR_LO
                          lda #>$04a0
                          sta CHUNK_SCR_LINE_START_ADDR_HI
                          lda START_ADDR_HI
                          jsr get_hi_nibble
                          tay
                          lda CHUNK_SCR_LINE_START_ADDR_LO
.loop                     dey
                          beq .return
                          clc
                          adc #$28
                          sta CHUNK_SCR_LINE_START_ADDR_LO
                          bcc .loop
                          inc CHUNK_SCR_LINE_START_ADDR_HI
                          lda CHUNK_SCR_LINE_START_ADDR_LO
                          jmp .loop
.return                   lda CHUNK_SCR_LINE_START_ADDR_HI    ; Also update addresses for color ram
                          clc
                          adc #$d4
                          sta CHUNK_CLR_LINE_START_ADDR_HI
                          lda CHUNK_SCR_LINE_START_ADDR_LO
                          sta CHUNK_CLR_LINE_START_ADDR_LO
                          lda CHUNK_SCR_LINE_START_ADDR_LO
                          ldy #$00
                          rts
}

update_current_element_label  inx
                              stx $0456
                              rts

update_current_run_label      lda CURRENT_RUN_ACCU_ADDR
                              jsr get_hi_nibble
                              jsr hex_to_scrcode
                              sta $045e
                              lda CURRENT_RUN_ACCU_ADDR
                              jsr get_lo_nibble
                              jsr hex_to_scrcode
                              sta $045e+1
                              rts

; Quick and dirty solution
set_done_label                lda #$04    ; D
                              sta $461
                              lda #$0f    ; O
                              sta $461+1
                              lda #$0e    ; N
                              sta $461+2
                              lda #$05    ; E
                              sta $461+3
                              lda #$21    ; !
                              sta $461+4

get_hi_nibble ror         ; split byte stored in A, getting the higher 4 bits
              ror
              ror
              ror
get_lo_nibble and #$0f    ; split byte stored in A, getting the lower 4 bits
              rts
} ; !pseudopc
