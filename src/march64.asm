START_ADDR = $1000
END_ADDR = $FFFF
CHUNK_SIZE = $1000

CURRENT_ADDR_LO = $fb
CURRENT_ADDR_HI = $fb+1
START_ADDR_LO = $fd
START_ADDR_HI = $fd+1

CHUNK_SCR_LINE_START_ADDR_LO = $39
CHUNK_SCR_LINE_START_ADDR_HI = $39+1

CHUNK_ERROR_ACCU_ADDR = $03

!src "scr.asm"
!src "basic.asm"

* = $0810
sei
lda #%00110100
sta $01

; Credit to Bruce Clark @ https://codebase64.org/doku.php?id=base:practical_memory_move_routines
movedown  lda #<$063a ; from
          sta $fb
          lda #>$063a
          sta $fb+1
          lda #<$0200 ; to
          sta $fd
          lda #>$0200
          sta $fd+1
          ldy #$00
          ldx #>$01c9 ; sizeh
          beq md2
md1       lda ($fb),y ; move a page at a time
          sta ($fd),y
          iny
          bne md1
          inc $fb+1
          inc $fd+1
          dex
          bne md1
md2       ldx #<$01c9 ; sizel
          beq init_sc
md3       lda ($fb),y ; move the remaining bytes
          sta ($fd),y
          iny
          dex
          bne md3

init_sc   jsr c_sc
          jsr i_sc

; Reset and start a new round
m_reset clc
        lda #$00
        sta CHUNK_ERROR_ACCU_ADDR

        tay
        ldx #$30

        lda #<START_ADDR
        sta START_ADDR_LO
        lda #>START_ADDR
        sta START_ADDR_HI
        jmp m_el1

; Next chunk
m_nx_chk  jsr u_chk_err
          lda #$00
          sta CHUNK_ERROR_ACCU_ADDR
          tay           ; reset Y to $00
          ldx #$30      ; reset X to $30 (Screen code for 0)

          clc
          lda START_ADDR_LO
          adc #<CHUNK_SIZE
          sta START_ADDR_LO

          clc
          lda START_ADDR_HI
          adc #>CHUNK_SIZE
          sta START_ADDR_HI

          cmp #>END_ADDR
          beq m_reset
          clc

; March U Element 1 - w0 (up)
m_el1   jsr m_chk_init_u
        jmp m_el1_l
m_el1_e jsr cmp_add_lo_u
        beq m_el2
m_el1_l lda #$00
        sta (CURRENT_ADDR_LO),y
        jsr n_by
        jsr cmp_add_hi_u
        beq m_el1_e
        jmp m_el1_l

; March U Element 5 - r1w0 (down)
m_el5     jsr m_chk_init_d
          jmp m_el5_l
m_el5_e   jsr cmp_add_lo_d
          beq m_nx_chk
m_el5_l   lda #$ff
          jsr r_by
          lda #$00
          sta (CURRENT_ADDR_LO),y
          jsr p_by
          jsr cmp_add_hi_d
          beq m_el5_e
          jmp m_el5_l

; March U Element 2 - r0w1r1w0 (up)
m_el2   jsr m_chk_init_u
        jmp m_el2_l
m_el2_e jsr cmp_add_lo_u
        beq m_el3
m_el2_l lda #$00
        jsr r_by
        lda #$ff
        sta (CURRENT_ADDR_LO),y
        jsr r_by
        lda #$00
        sta (CURRENT_ADDR_LO),y
        jsr n_by
        jsr cmp_add_hi_u
        beq m_el2_e
        jmp m_el2_l

; March U Element 3 - r0w1 (up)
m_el3   jsr m_chk_init_u
        jmp m_el3_l
m_el3_e jsr cmp_add_lo_u
        beq m_el4
m_el3_l lda #$00
        jsr r_by
        lda #$ff
        sta (CURRENT_ADDR_LO),y
        jsr n_by
        jsr cmp_add_hi_u
        beq m_el3_e
        jmp m_el3_l

; March U Element 4 - r1w0r0w1 (down)
m_el4   jsr m_chk_init_d
        jmp m_el4_l
m_el4_e jsr cmp_add_lo_d
        beq m_el5
m_el4_l lda #$ff
        jsr r_by
        lda #$00
        sta (CURRENT_ADDR_LO),y
        jsr r_by
        lda #$ff
        sta (CURRENT_ADDR_LO),y
        jsr p_by
        jsr cmp_add_hi_d
        beq m_el4_e
        jmp m_el4_l

r_by  eor (CURRENT_ADDR_LO),y
      ora CHUNK_ERROR_ACCU_ADDR
      sta CHUNK_ERROR_ACCU_ADDR
      rts

;r_by  lda zpaddr                 ; get value for previous element operation
;      eor #$ff                   ; flip it ($00 -> $ff, $ff -> $00)
;      sta zpaddr                 ; save for next call of r_by or w_by
;      eor (CURRENT_ADDR_LO),y    ; accumulate invalid read
;      ora CHUNK_ERROR_ACCU_ADDR
;      sta CHUNK_ERROR_ACCU_ADDR
;      rts
;
;w_by  lda zpaddr                 ; get value for previous element operation
;      eor #$ff                   ; flip it
;      sta zpaddr                 ; save for next call of r_by or w_by
;      sta (CURRENT_ADDR_LO),y
;      rts

; Load next byte into zeropage
n_by  clc
      lda CURRENT_ADDR_LO,y
      adc #$01
      sta CURRENT_ADDR_LO,y
      iny   ; If carry is set, increasing Y to 0 effectively allows us to modify CURRENT_ADDR_HI on the next run instead
      bcs n_by
      ldy #$00
      ;jsr u_ca 
      rts

; Load previous byte into zeropage
p_by  sec
      lda CURRENT_ADDR_LO,y
      sbc #$01
      sta CURRENT_ADDR_LO,y
      iny   ; See above in n_by
      bcc p_by
      ldy #$00
      clc
      ;jsr u_ca 
      rts

; Going up, check if current address (low byte) is at the end of the chunk
cmp_add_lo_u  clc
              lda START_ADDR_LO
              adc #<CHUNK_SIZE
              cmp CURRENT_ADDR_LO
              rts

; Going up, check if current address (high byte) is at the end of the chunk
cmp_add_hi_u  clc
              lda START_ADDR_HI
              adc #>CHUNK_SIZE
              cmp CURRENT_ADDR_HI
              rts

; Going down, check if the current address (low byte) is at the end of the chunk
cmp_add_lo_d  clc
              lda #<CHUNK_SIZE-1
              adc START_ADDR_LO
              sec
              sbc #<CHUNK_SIZE
              cmp CURRENT_ADDR_LO
              rts

; Going down, check if the current address (high byte) is at the end of the chunk
cmp_add_hi_d  clc
              lda #>CHUNK_SIZE-1
              adc START_ADDR_HI
              sec
              sbc #>CHUNK_SIZE
              cmp CURRENT_ADDR_HI
              rts

; Init going up
m_chk_init_u  clc
              lda START_ADDR_LO
              sta CURRENT_ADDR_LO
              lda START_ADDR_HI
              sta CURRENT_ADDR_HI

              jsr u_ce
              rts

; Init going down
m_chk_init_d  clc
              lda #<CHUNK_SIZE-1
              adc START_ADDR_LO
              sta CURRENT_ADDR_LO

              clc
              lda #>CHUNK_SIZE-1
              adc START_ADDR_HI
              sta CURRENT_ADDR_HI

              jsr u_ce
              rts

g_hi_ny       ror       ; split byte stored in A, getting the higher 4 bits
              ror
              ror
              ror
g_lo_ny       and #$0f  ; split byte stored in A, getting the lower 4 bits
              rts

; Hex to screen code (Nibble)
h_to_scrc     clc
              cmp #$0a
              bcs .h_to_scrc_l
.h_to_scrc_n  clc
              adc #$30
              jmp .h_to_scrc_e
.h_to_scrc_l  sec
              sbc #$09
              clc
.h_to_scrc_e  rts


; end