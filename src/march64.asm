.const N0 = $40
.const N1 = $41
.const N2 = $42
.const N3 = $43
.const N4 = $44
.const N5 = $45
.const N6 = $46
.const N7 = $47
.const N8 = $48
.const N9 = $49
.const LA = $4a
.const LB = $4b
.const LC = $4c
.const LD = $4d
.const LE = $4e
.const LF = $4f
.const LG = $50
.const LH = $51
.const LI = $52
.const LL = $53
.const LM = $54
.const LN = $55
.const LR = $56
.const LS = $57
.const LT = $58
.const LU = $59
.const LV = $5a
.const LO = $5b
.const LP = $5c
.const S1 = $5d // $
.const S2 = $5e // -
.const S3 = $5f // /
.const S4 = $60 // >
.const S5 = $61 // <
.const S6 = $62 // .
.const S7 = $63 // :
.const BL = $64 // Blank

.const START_ADDR = $1000
.const CHUNK_SIZE = $1000
.const MAX_RUNS = $ff

.const SCREEN_DATA_FROM_ROM_ADDR = screen_data_rom_start
.const SCREEN_DATA_TO_RAM_ADDR   = $0400
.const SCREEN_OPS_FROM_ROM_ADDR  = screen_ops_rom_start
.const SCREEN_OPS_TO_RAM_ADDR    = $0200
.const SCREEN_OPS_ROM_AREA_SIZE  = screen_ops_rom_end - screen_ops_rom_start
.const MARCHU_OPS_FROM_ROM_ADDR  = marchu_ops_rom_start
.const MARCHU_OPS_TO_RAM_ADDR    = $0800
.const MARCHU_OPS_ROM_AREA_SIZE  = marchu_ops_rom_end - marchu_ops_rom_start

.const CURRENT_ADDR_LO = $fb
.const CURRENT_ADDR_HI = $fb+1
.const START_ADDR_LO = $fd
.const START_ADDR_HI = $fd+1

.const CHUNK_SCR_LINE_START_ADDR_LO = $39
.const CHUNK_SCR_LINE_START_ADDR_HI = $39+1
.const CHUNK_CLR_LINE_START_ADDR_LO = $3b
.const CHUNK_CLR_LINE_START_ADDR_HI = $3b+1

.const CURRENT_RUN_ACCU_ADDR = $02
.const CHUNK_ERROR_ACCU_ADDR = $03

.const COLOR_BLACK = $00
.const COLOR_WHITE = $01
.const COLOR_GREEN = $03
.const COLOR_RED = $02

#import "rom/header.asm"
#import "rom/init.asm"
#import "screen_data.asm"
#import "screen_ops.asm"
#import "marchu_ops.asm"

.label end = *
.fill $a000 - end, $00
