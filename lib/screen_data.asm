screen_data_rom_start:
.byte LM, LA, LR, LC, LH, N6, N4, BL, LV, LA, S6, LB, S6, LC            // march64 va.b.c
.byte $00, $00
.byte LS, LT, LE, LP, S7, BL, S2, BL, LR, LU, LN, LS, S7, BL, S2, S2    // step: - runs: --
.byte $00, $00
.byte S1, N1, N0, N0, N0, S2, S1, N1, LF, LF, LF, $01, $01, S2, S2, $00 // $1000-$1fff  --
.byte S1, N2, N0, N0, N0, S2, S1, N2, LF, LF, LF, $01, $01, S2, S2, $00 // $2000-$2fff  --
.byte S1, N3, N0, N0, N0, S2, S1, N3, LF, LF, LF, $01, $01, S2, S2, $00 // $3000-$3fff  --
.byte S1, N4, N0, N0, N0, S2, S1, N4, LF, LF, LF, $01, $01, S2, S2, $00 // $4000-$4fff  --
.byte S1, N5, N0, N0, N0, S2, S1, N5, LF, LF, LF, $01, $01, S2, S2, $00 // $5000-$5fff  --
.byte S1, N6, N0, N0, N0, S2, S1, N6, LF, LF, LF, $01, $01, S2, S2, $00 // $6000-$6fff  --
.byte S1, N7, N0, N0, N0, S2, S1, N7, LF, LF, LF, $01, $01, S2, S2, $00 // $7000-$7fff  --
.byte S1, N8, N0, N0, N0, S2, S1, N8, LF, LF, LF, $01, $01, S2, S2, $00 // $8000-$8fff  --
.byte S1, N9, N0, N0, N0, S2, S1, N9, LF, LF, LF, $01, $01, S2, S2, $00 // $9000-$9fff  --
.byte S1, LA, N0, N0, N0, S2, S1, LA, LF, LF, LF, $01, $01, S2, S2, $00 // $a000-$afff  --
.byte S1, LB, N0, N0, N0, S2, S1, LB, LF, LF, LF, $01, $01, S2, S2, $00 // $b000-$bfff  --
.byte S1, LC, N0, N0, N0, S2, S1, LC, LF, LF, LF, $01, $01, S2, S2, $00 // $c000-$cfff  --
.byte S1, LD, N0, N0, N0, S2, S1, LD, LF, LF, LF, $01, $01, S2, S2, $00 // $d000-$dfff  --
.byte S1, LE, N0, N0, N0, S2, S1, LE, LF, LF, LF, $01, $01, S2, S2, $00 // $e000-$efff  --
.byte S1, LF, N0, N0, N0, S2, S1, LF, LF, LF, LF, $01, $01, S2, S2      // $f000-$ffff  --
.byte $00, $00, $00, $00, $00
.byte LG, LI, LT, LH, LU, LB, S6, LC, LO, LM, S3, LF, LI, S2, LD, LE, LV, LN, LI, LL, S3, LM, LA, LR, LC, LH, N6, N4 // github.com/fi-devnil/march64
.byte $ff
.label screen_data_rom_end = *
