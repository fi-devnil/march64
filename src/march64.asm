START_ADDR = $1000
CHUNK_SIZE = $1000
MAX_RUNS = $ff

SCREEN_DATA_FROM_ROM_ADDR = .screen_data_rom_start
SCREEN_DATA_TO_RAM_ADDR   = $0400
SCREEN_OPS_FROM_ROM_ADDR  = .screen_ops_rom_start
SCREEN_OPS_TO_RAM_ADDR    = $0200
SCREEN_OPS_ROM_AREA_SIZE  = .screen_ops_rom_end - .screen_ops_rom_start
MARCHU_OPS_FROM_ROM_ADDR  = .marchu_ops_rom_start
MARCHU_OPS_TO_RAM_ADDR    = $0800
MARCHU_OPS_ROM_AREA_SIZE  = .marchu_ops_rom_end - .marchu_ops_rom_start

CURRENT_ADDR_LO = $fb
CURRENT_ADDR_HI = $fb+1
START_ADDR_LO = $fd
START_ADDR_HI = $fd+1

CHUNK_SCR_LINE_START_ADDR_LO = $39
CHUNK_SCR_LINE_START_ADDR_HI = $39+1
CHUNK_CLR_LINE_START_ADDR_LO = $3b
CHUNK_CLR_LINE_START_ADDR_HI = $3b+1

CURRENT_RUN_ACCU_ADDR = $02
CHUNK_ERROR_ACCU_ADDR = $03

COLOR_BLACK = $00
COLOR_WHITE = $01
COLOR_GREEN = $03
COLOR_RED = $02

!src "rom/header.asm"
!src "rom/init.asm"
!src "screen_data.asm"
!src "screen_ops.asm"
!src "marchu_ops.asm"

.end
!skip $a000 - .end
