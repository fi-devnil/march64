screen_ops_rom_start:
.pseudopc $0200 {

#import "charset.asm"

update_chunk_error_label: {
                          jsr find_current_screen_line
                          ldy #$0d    // screen offset (12)
                          jsr enable_io_ports
                          lda CHUNK_ERROR_ACCU_ADDR
                          bne red
green:                    lda #COLOR_GREEN
.byte                     $2c         // Skip next line
red:                      lda #COLOR_RED
label:                    sta (CHUNK_CLR_LINE_START_ADDR_LO),y
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
                          ldy #$00    // reset Y
                          rts
}

// Hex to screen code
hex_to_scrcode: {
  clc
  adc #$40
  clc
  rts
}

insert_current_chunk_signs: {
                            jsr find_current_screen_line
                            ldy #$0c
                            lda #S4    // >
                            sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                            ldy #$0f
                            lda #S5    // <
                            sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                            ldy #$00
                            rts
}
clear_current_chunk_signs: {
                            jsr find_current_screen_line
                            ldy #$0c
                            lda #BL
                            sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                            ldy #$0f
                            sta (CHUNK_SCR_LINE_START_ADDR_LO),y
                            ldy #$00
                            rts
}

find_current_screen_line: {
                          lda #<$04a0
                          sta CHUNK_SCR_LINE_START_ADDR_LO
                          lda #>$04a0
                          sta CHUNK_SCR_LINE_START_ADDR_HI
                          lda START_ADDR_HI
                          jsr get_hi_nibble
                          tay
                          lda CHUNK_SCR_LINE_START_ADDR_LO
loop:                     dey
                          beq return
                          clc
                          adc #$28
                          sta CHUNK_SCR_LINE_START_ADDR_LO
                          bcc loop
                          inc CHUNK_SCR_LINE_START_ADDR_HI
                          lda CHUNK_SCR_LINE_START_ADDR_LO
                          jmp loop
return:                   lda CHUNK_SCR_LINE_START_ADDR_HI    // Also update address pointers for color ram
                          clc
                          adc #$d4
                          sta CHUNK_CLR_LINE_START_ADDR_HI
                          lda CHUNK_SCR_LINE_START_ADDR_LO
                          sta CHUNK_CLR_LINE_START_ADDR_LO
                          lda CHUNK_SCR_LINE_START_ADDR_LO
                          ldy #$00
                          rts
}

update_current_step_label:    inx
                              stx $0456
                              rts

update_current_run_label:     lda CURRENT_RUN_ACCU_ADDR
                              jsr get_hi_nibble
                              jsr hex_to_scrcode
                              sta $045e
                              lda CURRENT_RUN_ACCU_ADDR
                              jsr get_lo_nibble
                              jsr hex_to_scrcode
                              sta $045e+1
                              rts

// Quick and dirty solution
set_done_label:               lda #LD    // D
                              sta $461
                              lda #LO    // O
                              sta $461+1
                              lda #LN    // N
                              sta $461+2
                              lda #LE    // E
                              sta $461+3
                              lda #S6    // .
                              sta $461+4

get_hi_nibble:  ror         // split byte stored in A, getting the higher 4 bits
                ror
                ror
                ror
get_lo_nibble:  and #$0f    // split byte stored in A, getting the lower 4 bits
                rts

} // !pseudopc
.label screen_ops_rom_end = *
