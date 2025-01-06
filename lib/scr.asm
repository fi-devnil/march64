* = $063a
!pseudopc $0200 {

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
              bcc .i_sc_l
.i_sc_it_c    inc $fb+1
              !byte $24   ; skip iny
.i_sc_it      iny
              beq .i_sc_it_c
              tya
              adc $fb     ; save y to froml
              sta $fb
              clc
              ldy #$00    ; reset y to $00
              lda $fd
              adc #$28    ; increase "to" by $28
              sta $fd
              bcc .i_sc_l
              inc $fd+1
              clc
.i_sc_l       lda ($fb),y
              beq .i_sc_it
              cmp #$ff
              beq .i_sc_e  ; end
              sta ($fd),y
              iny
              bne .i_sc_l
              inc $fb+1   ; do carry for fromh
              clc
              bcc .i_sc_l
.i_sc_e       rts

; clear screen
c_sc    ldx #$00
        lda #$20
.c_sc_l sta $0400,x
        sta $04fa,x
        sta $05f4,x
        sta $06ee,x
        inx
        cpx #$fa
        bne .c_sc_l
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
.u_chk_mlp    dey
              beq .u_chk_wrt
              clc
              adc #$28
              sta CHUNK_SCR_LINE_START_ADDR_LO
              bcc .u_chk_mlp
              clc
              inc CHUNK_SCR_LINE_START_ADDR_HI
              lda CHUNK_SCR_LINE_START_ADDR_LO
              jmp .u_chk_mlp
.u_chk_wrt    ldy #$0c    ; screen offset (12)
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

; Update current element label
u_ce          inx
              stx $0432+4
              rts

; update current address
;u_ca  txa
;      pha
;      php
;      ldx #$05    ; screen offset starts at 5 from $0428
;.u_ca_l_hi
;      lda CURRENT_ADDR_HI
;      cpx #$05
;      beq .u_ca_hi
;      bcs .u_ca_cmp
;.u_ca_l_lo
;      lda CURRENT_ADDR_LO
;      cpx #$07
;      beq .u_ca_hi
;      bcs .u_ca_cmp
;.u_ca_hi ror
;         ror
;         ror
;         ror
;.u_ca_cmp clc
;          and #$0f
;          cmp #$0a
;          bcs .u_ca_le ; Is A-F
;          adc #$30    ; Add $30 to shift into numbers
;          jmp .u_ca_s
;.u_ca_le  sec
;          sbc #$09    ; Shift A-F by 9. Letter A starts at $01
;          clc
;.u_ca_s   sta $0428,x
;          inx
;          cpx #$06
;          beq .u_ca_l_hi
;          cpx #$07
;          beq .u_ca_l_lo
;          cpx #$08
;          beq .u_ca_l_lo
;.u_ca_end plp
;          pla
;          tax
;          rts
}
