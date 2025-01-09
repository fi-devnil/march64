.marchu_ops_rom_start
!pseudopc $0800 {

; Start tests
!zone marchu_zone {
marchu      lda #$ff
            sta CURRENT_RUN_ACCU_ADDR
            jsr enable_all_ram
.init       jsr .reset
.test       jsr insert_current_chunk_signs

            jsr .test_up
            jsr marchu_w0

            jsr .test_up
            jsr marchu_r0w1r1w0

            jsr .test_up
            jsr marchu_r0w1

            jsr .test_down
            jsr marchu_r1w0r0w1

            jsr .test_down
            jsr marchu_r1w0

            jsr update_chunk_error_label
            jsr clear_current_chunk_signs
            jmp .next_chunk

.next_chunk jsr .reset_registers

            clc
            lda START_ADDR_LO
            adc #<CHUNK_SIZE
            sta START_ADDR_LO

            clc
            lda START_ADDR_HI
            adc #>CHUNK_SIZE
            sta START_ADDR_HI

            ; reset if we looped around $FFFF
            cmp #$00
            bne .test
            lda START_ADDR_LO

            cmp #$00
            beq .init

            jmp .test

.test_up  clc
          lda START_ADDR_LO
          sta CURRENT_ADDR_LO
          lda START_ADDR_HI
          sta CURRENT_ADDR_HI

          jsr update_current_element_label
          rts

.test_down  clc
            lda #<CHUNK_SIZE-1
            adc START_ADDR_LO
            sta CURRENT_ADDR_LO

            clc
            lda #>CHUNK_SIZE-1
            adc START_ADDR_HI
            sta CURRENT_ADDR_HI

            jsr update_current_element_label
            rts

.reset            inc CURRENT_RUN_ACCU_ADDR
                  jsr update_current_run_label

                  ; Currently only support running the test 256 times
                  lda CURRENT_RUN_ACCU_ADDR
                  cmp #MAX_RUNS
                  beq .done

                  lda #<START_ADDR
                  sta START_ADDR_LO
                  lda #>START_ADDR
                  sta START_ADDR_HI
.reset_registers  lda #$00
                  sta CHUNK_ERROR_ACCU_ADDR
                  tay         ; reset Y to $00
                  ldx #$30    ; reset X to $30 (Screen code for 0)
                  rts

.done             jsr set_done_label
.forever          jmp .forever
}

!zone marchu_elements_zone {
; Going up, check if current address (low byte) is at the end of the chunk
.cmp_add_lo_u clc
              lda START_ADDR_LO
              adc #<CHUNK_SIZE
              cmp CURRENT_ADDR_LO
              rts

; Going up, check if current address (high byte) is at the end of the chunk
.cmp_add_hi_u clc
              lda START_ADDR_HI
              adc #>CHUNK_SIZE
              cmp CURRENT_ADDR_HI
              rts

; March U Element 1 - w0
marchu_w0       lda #$00
                sta (CURRENT_ADDR_LO),y
                jsr .next_byte
                jsr .cmp_add_hi_u
                beq .cmp_add_lo_u
                bne marchu_w0
                beq .return

; March U Element 2 - r0w1r1w0
marchu_r0w1r1w0     lda #$00
                    jsr .read_byte
                    lda #$ff
                    sta (CURRENT_ADDR_LO),y
                    jsr .read_byte
                    lda #$00
                    sta (CURRENT_ADDR_LO),y
                    jsr .next_byte
                    jsr .cmp_add_hi_u
                    beq .cmp_add_lo_u
                    bne marchu_r0w1r1w0
                    beq .return

; March U Element 3 - r0w1

marchu_r0w1     lda #$00
                jsr .read_byte
                lda #$ff
                sta (CURRENT_ADDR_LO),y
                jsr .next_byte
                jsr .cmp_add_hi_u
                beq .cmp_add_lo_u
                bne marchu_r0w1
                beq .return

; Going down, check if the current address (low byte) is at the end of the chunk
.cmp_add_lo_d clc
              lda #<CHUNK_SIZE-1
              adc START_ADDR_LO
              sec
              sbc #<CHUNK_SIZE
              cmp CURRENT_ADDR_LO
              rts

; Going down, check if the current address (high byte) is at the end of the chunk
.cmp_add_hi_d clc
              lda #>CHUNK_SIZE-1
              adc START_ADDR_HI
              sec
              sbc #>CHUNK_SIZE
              cmp CURRENT_ADDR_HI
              rts

; March U Element 4 - r1w0r0w1
marchu_r1w0r0w1     lda #$ff
                    jsr .read_byte
                    lda #$00
                    sta (CURRENT_ADDR_LO),y
                    jsr .read_byte
                    lda #$ff
                    sta (CURRENT_ADDR_LO),y
                    jsr .prev_byte
                    jsr .cmp_add_hi_d
                    beq .cmp_add_lo_d
                    bne marchu_r1w0r0w1
                    beq .return

; March U Element 5 - r1w0
marchu_r1w0     lda #$ff
                jsr .read_byte
                lda #$00
                sta (CURRENT_ADDR_LO),y
                jsr .prev_byte
                jsr .cmp_add_hi_d
                beq .cmp_add_lo_d
                bne marchu_r1w0
.return         rts

.read_byte  eor (CURRENT_ADDR_LO),y        ; check for invalid bits
            ora CHUNK_ERROR_ACCU_ADDR      ; accumulate errors
            sta CHUNK_ERROR_ACCU_ADDR
            rts

; Load next byte into zeropage
.next_byte        clc
                  lda CURRENT_ADDR_LO
                  adc #$01
                  sta CURRENT_ADDR_LO
                  bcc .return
                  inc CURRENT_ADDR_HI
                  rts

; Load previous byte into zeropage
.prev_byte        sec
                  lda CURRENT_ADDR_LO
                  sbc #$01
                  sta CURRENT_ADDR_LO
                  bcs .return
                  dec CURRENT_ADDR_HI
                  rts
}

enable_all_ram    lda #%00110100
                  sta $01
                  rts
enable_io_ports   lda #%00110101
                  sta $01
                  rts
} ;pseudopc
.marchu_ops_rom_end
