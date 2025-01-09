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
}

!zone init_colors_zone {
init_colors   lda #COLOR_WHITE
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
              ldy #$00
}

!zone move_screen_ops_zone {
move_screen_ops lda #<SCREEN_OPS_FROM_ROM_ADDR  ; From
                sta $fb
                lda #>SCREEN_OPS_FROM_ROM_ADDR
                sta $fb+1
                lda #<SCREEN_OPS_TO_RAM_ADDR    ; To
                sta $fd
                lda #>SCREEN_OPS_TO_RAM_ADDR
                sta $fd+1
                ldy #$00
                ldx #>SCREEN_OPS_ROM_AREA_SIZE  ; Size (High byte)
                beq .md2
.md1            lda ($fb),y
                sta ($fd),y
                iny
                bne .md1
                inc $fb+1
                inc $fd+1
                dex
                bne .md1
.md2            ldx #<SCREEN_OPS_ROM_AREA_SIZE  ; Size (Low byte)
                beq move_screen_data
.md3            lda ($fb),y
                sta ($fd),y
                iny
                dex
                bne .md3
}

!zone move_screen_data_zone {
move_screen_data  lda #<SCREEN_DATA_FROM_ROM_ADDR ; From
                  sta $fb
                  lda #>SCREEN_DATA_FROM_ROM_ADDR
                  sta $fb+1
                  lda #<SCREEN_DATA_TO_RAM_ADDR   ; To
                  sta $fd
                  lda #>SCREEN_DATA_TO_RAM_ADDR
                  sta $fd+1
                  ldy #$00
                  jmp .loop
.save_y           iny
                  tya
                  clc
                  adc $fb
                  sta $fb
                  bcc .newline
                  inc $fb+1
.newline          ldy #$00
                  lda $fd
                  clc
                  adc #$28
                  sta $fd
                  bcc .loop
                  inc $fd+1
.loop             lda ($fb),y
                  beq .save_y
                  cmp #$ff
                  beq move_marchu_ops
                  sta ($fd),y
                  iny
                  jmp .loop
}

!zone move_marchu_ops_zone {
move_marchu_ops lda #<MARCHU_OPS_FROM_ROM_ADDR  ; From
                sta $fb
                lda #>MARCHU_OPS_FROM_ROM_ADDR
                sta $fb+1
                lda #<MARCHU_OPS_TO_RAM_ADDR    ; To
                sta $fd
                lda #>MARCHU_OPS_TO_RAM_ADDR
                sta $fd+1
                ldy #$00
                ldx #>MARCHU_OPS_ROM_AREA_SIZE  ; Size (High byte)
                beq .md2
.md1            lda ($fb),y
                sta ($fd),y
                iny
                bne .md1
                inc $fb+1
                inc $fd+1
                dex
                bne .md1
.md2            ldx #<MARCHU_OPS_ROM_AREA_SIZE  ; Size (Low byte)
                beq init
.md3            lda ($fb),y
                sta ($fd),y
                iny
                dex
                bne .md3
}

init      sei
          jmp marchu
