START_ADDR = $1000
END_ADDR = $FFFF
CHUNK_SIZE = $1000
MAX_RUNS = $ff

SCR_RAM_AREA = $063a                      ; Store screen routines here temporarily
SCR_RAM_AREA_SIZE = $07ff - SCR_RAM_AREA  ; Should be $01c5
LOW_RAM_AREA = $0200                      ; Move screen routines here after disabling basic and kernal
HIGH_RAM_AREA = $0810                     ; Logic start

CURRENT_ADDR_LO = $fb
CURRENT_ADDR_HI = $fb+1
START_ADDR_LO = $fd
START_ADDR_HI = $fd+1

CHUNK_SCR_LINE_START_ADDR_LO = $39
CHUNK_SCR_LINE_START_ADDR_HI = $39+1

CURRENT_RUN_ACCU_ADDR = $02
CHUNK_ERROR_ACCU_ADDR = $03

!src "scr.asm"
!src "header.asm"

* = HIGH_RAM_AREA
sei
lda #%00110100
sta $01

; Credit to Bruce Clark @ https://codebase64.org/doku.php?id=base:practical_memory_move_routines
movedown  lda #<SCR_RAM_AREA ; from
          sta $fb
          lda #>SCR_RAM_AREA
          sta $fb+1
          lda #<LOW_RAM_AREA ; to
          sta $fd
          lda #>LOW_RAM_AREA
          sta $fd+1
          ldy #$00
          ldx #>SCR_RAM_AREA_SIZE ; sizeh
          beq md2
md1       lda ($fb),y ; move a page at a time
          sta ($fd),y
          iny
          bne md1
          inc $fb+1
          inc $fd+1
          dex
          bne md1
md2       ldx #<SCR_RAM_AREA_SIZE ; sizel
          beq init
md3       lda ($fb),y ; move the remaining bytes
          sta ($fd),y
          iny
          dex
          bne md3

init      jsr clear_screen
          jsr init_screen
          lda #$ff
          sta CURRENT_RUN_ACCU_ADDR

; Start tests
!zone marchu_zone {
marchu      jsr .reset
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
            beq marchu

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
.return rts

.read_byte  eor (CURRENT_ADDR_LO),y        ; check for invalid bits
            ora CHUNK_ERROR_ACCU_ADDR      ; accumulate errors
            sta CHUNK_ERROR_ACCU_ADDR
            rts

; Load next byte into zeropage
.next_byte_carry  inc CURRENT_ADDR_HI
                  rts
.next_byte        clc
                  lda CURRENT_ADDR_LO
                  adc #$01
                  sta CURRENT_ADDR_LO
                  bcs .next_byte_carry
                  rts

; Load previous byte into zeropage
.prev_byte_borrow sec
                  lda CURRENT_ADDR_HI
                  sbc #$01
                  sta CURRENT_ADDR_HI
                  rts
.prev_byte        sec
                  lda CURRENT_ADDR_LO
                  sbc #$01
                  sta CURRENT_ADDR_LO
                  bcc .prev_byte_borrow
                  rts
}
