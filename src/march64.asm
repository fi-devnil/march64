START_ADDR = $1000
END_ADDR = $FFFF
CHUNK_SIZE = $1000

CURRENT_ADDR_LO = $fb
CURRENT_ADDR_HI = $fb+1
START_ADDR_LO = $fd
START_ADDR_HI = $fd+1


CHUNK_SCR_LINE_START_ADDR_LO = $39
CHUNK_SCR_LINE_START_ADDR_HI = $39+1

ELEMENT_OPERATOR_ADDR = $02
CHUNK_ERROR_ACCU_ADDR = $03

INIT_SCREEN_ADDR = $02fe
CLEAR_SCREEN_ADDR = $0343
UPDATE_CURRENT_ADDRESS_ADDR = $0359

* = $063a
; Screen data
!scr "march64 v0.1", $00
!scr "ca: $---- el: -", $00
!scr "$1000-$1fff --", $00
!scr "$2000-$2fff --", $00
!scr "$3000-$3fff --", $00
!scr "$4000-$4fff --", $00
!scr "$5000-$5fff --", $00
!scr "$6000-$6fff --", $00
!scr "$7000-$7fff --", $00
!scr "$8000-$8fff --", $00
!scr "$9000-$9fff --", $00
!scr "$a000-$afff --", $00
!scr "$b000-$bfff --", $00
!scr "$c000-$cfff --", $00
!scr "$d000-$dfff --", $00
!scr "$e000-$efff --", $00
!scr "$f000-$ffff --", $ff
; Initialize screen data
i_sc          clc
              lda #$01      ; set $c8 to $01 so that "BIT $c8" will not set the zero flag
              sta $c8       ; opcode for "iny"
              lda #<$0200   ; from address
              sta $fb
              lda #>$0200
              sta $fb+1
              lda #<$0400   ; to address
              sta $fd
              lda #>$0400
              sta $fd+1
              ldy #$00     ; froml
              bcc i_sc_l
i_sc_it_c     inc $fb+1
              !byte $24   ; skip iny
i_sc_it       iny
              beq i_sc_it_c
              tya
              adc $fb     ; save y to froml
              sta $fb
              clc
              ldy #$00    ; reset y to $00
              lda $fd
              adc #$28    ; increase "to" by $28
              sta $fd
              bcc i_sc_l
              inc $fd+1
              clc
i_sc_l        lda ($fb),y
              beq i_sc_it
              cmp #$ff
              beq i_sc_e  ; end
              sta ($fd),y
              iny
              bne i_sc_l
              inc $fb+1   ; do carry for fromh
              clc
              bcc i_sc_l
i_sc_e        rts

; clear screen
c_sc    ldx #$00
        lda #$20
c_sc_l  sta $0400,x
        sta $04fa,x
        sta $05f4,x
        sta $06ee,x
        inx
        cpx #$fa
        bne c_sc_l
        rts

; update current address
u_ca  txa
      pha
      php
      ldx #$05    ; screen offset starts at 5 from $0428
u_ca_l_hi
      lda CURRENT_ADDR_HI
      cpx #$05
      beq u_ca_hi
      bcs u_ca_cmp
u_ca_l_lo
      lda CURRENT_ADDR_LO
      cpx #$07
      beq u_ca_hi
      bcs u_ca_cmp
u_ca_hi ror
        ror
        ror
        ror
u_ca_cmp  clc
          and #$0f
          cmp #$0a
          bcs u_ca_le ; Is A-F
          adc #$30    ; Add $30 to shift into numbers
          clc         ; Allow use of bcc instead of jmp, easier when dealing with moved code
          bcc u_ca_s
u_ca_le   sec
          sbc #$09    ; Shift A-F by 9. Letter A starts at $01
          clc
u_ca_s    sta $0428,x
          inx
          cpx #$06
          beq u_ca_l_hi
          cpx #$07
          beq u_ca_l_lo
          cpx #$08
          beq u_ca_l_lo
u_ca_end  plp
          pla
          tax
          rts
          
;* = $0800
;!byte $00, $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00

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

init_sc   jsr CLEAR_SCREEN_ADDR
          jsr INIT_SCREEN_ADDR

; Reset and start a new round
m_reset clc
        lda #$00
        sta CHUNK_ERROR_ACCU_ADDR
        lda #$ff
        sta ELEMENT_OPERATOR_ADDR

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
  
          tay
          ldx #$30

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
        beq m_el24
m_el1_l lda #$00
        sta (CURRENT_ADDR_LO),y
        jsr n_by
        jsr cmp_add_hi_u
        beq m_el1_e
        jmp m_el1_l



; March U Element 2 & 4 - r0w1r1w0 (up)
m_el24    jsr m_chk_init_u
          jmp m_el24_l
m_el24_e  jsr cmp_add_lo_u
          beq m_el35
m_el24_l  lda #$00
          jsr r_by
          lda #$ff
          sta (CURRENT_ADDR_LO),y
          jsr r_by
          lda #$00
          sta (CURRENT_ADDR_LO),y
          jsr n_by
          jsr cmp_add_hi_u
          beq m_el24_e
          jmp m_el24_l 

; March U Element 3 - r0w1 (up)
m_el35    jsr m_chk_init_u 
          jmp m_el3_l
m_el35_e  jsr cmp_add_lo_u
          beq m_el4
m_el35_l  lda #$00
          jsr r_by
          lda #$ff
          sta (CURRENT_ADDR_LO),y
          jsr n_by
          jsr cmp_add_hi_u
          beq m_el3_e
          jmp m_el3_l

; March U Element 4 - r1w0r0w1 (down)
;m_el4   jsr m_chk_init_d
;        jmp m_el4_l
;m_el4_e jsr cmp_add_lo_d
;        beq m_el5
;m_el4_l lda #$ff
;        jsr r_by
;        lda #$00
;        sta (CURRENT_ADDR_LO),y
;        jsr r_by
;        lda #$ff
;        sta (CURRENT_ADDR_LO),y
;        jsr p_by
;        jsr cmp_add_hi_d
;        beq m_el4_e
;        jmp m_el4_l
;
;; March U Element 5 - r1w0 (down)
;m_el5     jsr m_chk_init_d
;          jmp m_el5_l
;m_el5_e   jsr cmp_add_lo_d
;          beq m_nx_chk
;m_el5_l   lda #$ff
;          jsr r_by
;          lda #$00
;          sta (CURRENT_ADDR_LO),y
;          jsr p_by
;          jsr cmp_add_hi_d
;          beq m_el5_e
;          jmp m_el5_l

r_by  eor (CURRENT_ADDR_LO),y
      ora CHUNK_ERROR_ACCU_ADDR
      sta CHUNK_ERROR_ACCU_ADDR
      rts

;r_by  lda ELEMENT_OPERATOR_ADDR  ; get value for previous element operation
;      eor #$ff                   ; flip it ($00 -> $ff, $ff -> $00)
;      sta ELEMENT_OPERATOR_ADDR  ; save for next call of r_by or w_by 
;      eor (CURRENT_ADDR_LO),y    ; accumulate invalid read
;      ora CHUNK_ERROR_ACCU_ADDR
;      sta CHUNK_ERROR_ACCU_ADDR
;      rts
;
w_by  lda ELEMENT_OPERATOR_ADDR  ; get value for previous element operation
      eor #$ff                   ; flip it
      sta ELEMENT_OPERATOR_ADDR  ; save for next call of r_by or w_by 
      sta (CURRENT_ADDR_LO),y
      rts

; Load next byte into zeropage
n_by  clc
      lda CURRENT_ADDR_LO,y
      adc #$01
      sta CURRENT_ADDR_LO,y
      iny   ; If carry is set, increasing Y to 0 effectively allows us to modify CURRENT_ADDR_HI on the next run instead
      bcs n_by
      ldy #$00
      jsr UPDATE_CURRENT_ADDRESS_ADDR
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
      jsr UPDATE_CURRENT_ADDRESS_ADDR
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
; Update current element label
u_ce          inx
              stx $0432+4
              rts

; Update chunk error label
u_chk_err     lda #<$450
              sta CHUNK_SCR_LINE_START_ADDR_LO
              lda #>$450
              sta CHUNK_SCR_LINE_START_ADDR_HI
              lda START_ADDR_HI
              jsr g_hi_ny
              tay
              lda CHUNK_SCR_LINE_START_ADDR_LO
u_chk_mlp     dey
              beq u_chk_wrt
              adc #$28
              sta CHUNK_SCR_LINE_START_ADDR_LO
              bcc u_chk_mlp
              clc
              inc CHUNK_SCR_LINE_START_ADDR_HI
              lda CHUNK_SCR_LINE_START_ADDR_LO
              clc
              bcc u_chk_mlp
u_chk_wrt     ldy #$0c    ; screen offset (12)
              lda CHUNK_ERROR_ACCU_ADDR
              jsr g_hi_ny
              jsr h_to_scrc
              sta (CHUNK_SCR_LINE_START_ADDR_LO),y
              iny
              lda CHUNK_ERROR_ACCU_ADDR
              jsr g_lo_ny
              jsr h_to_scrc
              sta (CHUNK_SCR_LINE_START_ADDR_LO),y
              ldy #$00    ; reset Y
              rts

g_hi_ny       ror       ; split byte stored in A, getting the higher 4 bits
              ror
              ror
              ror
g_lo_ny       and #$0f  ; split byte stored in A, getting the lower 4 bits
              rts

; Hex to screen code
h_to_scrc     clc
              cmp #$0a
              bcs h_to_scrc_l
h_to_scrc_n   clc
              adc #$30
              jmp h_to_scrc_e
h_to_scrc_l   sec
              sbc #$09
              clc
h_to_scrc_e   rts
; end