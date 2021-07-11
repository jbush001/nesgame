                    processor 6502

STACK_SIZE          equ 128
FLOOR               equ 220
MAX_FALL            equ 6
JMP_VEC             equ $f5
HORZ_SPEED          equ 2

A_BUTTON            equ $01
B_BUTTON            equ $02
SELECT_BUTTON       equ $04
START_BUTTON        equ $08
UP_BUTTON           equ $10
DOWN_BUTTON         equ $20
LEFT_BUTTON         equ $40
RIGHT_BUTTON        equ $80

                    seg.u SystemRegisters
                    org $2000
PPUCTRL             dc.b 0
PPUMASK             dc.b 0
PPUSTATUS           dc.b 0
OAMADDR             dc.b 0
OAMDATA             dc.b 0
PPUSCROLL           dc.b 0
PPUADDR             dc.b 0
PPUDATA             dc.b 0

                    org $4016
JOYPAD1             dc.b 0
JOYPAD2             dc.b 0

                    seg.u Globals
                    org $0
stack               ds.b STACK_SIZE
xpos                dc.b 0
ypos                dc.b 0
gravityVector       dc.b 0
buttons             dc.b 0
scrollOffs          dc.b 0

                    mac SetPPUAddress
                    lda PPUSTATUS   ; reset address
                    lda >{1}        ; MSB of PPU address
                    sta PPUADDR
                    lda <{1}        ; LSB of PPU address
                    sta PPUADDR
                    endm

                    seg code
                    org    $c000
HandleReset            subroutine

                    ; set up stack
                    ldx    #(stack + STACK_SIZE - 1)
                    txs

                    ; Initialize variables
                    lda #40
                    sta xpos
                    lda #30
                    sta ypos
                    lda #0
                    sta gravityVector

                    ;
                    ; Load Palette
                    ;
                    SetPPUAddress #$3f00
                    ldx #$0
.loadPaletteEntry    lda palette,x
                    sta PPUDATA
                    inx
                    cpx    #20
                    bne .loadPaletteEntry

                    SetPPUAddress #$2020

                    ;
                    ; Fill in the background name table
                    ;

                    ldx #14
.colLoop

                    ldy #16
.rowLoop1           lda #5
                    sta PPUDATA
                    lda #6
                    sta PPUDATA
                    dey
                    bne .rowLoop1

                    ldy #16
.rowLoop2           lda #6
                    sta PPUDATA
                    lda #5
                    sta PPUDATA
                    dey
                    bne .rowLoop2


                    dex
                    bne .colLoop


                    ; Turn on PPU
                    SetPPUAddress #0
                    lda #%10000000
                    sta PPUCTRL
                    lda #%00011110
                    sta PPUMASK

.mainLoop            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                    ; Shift button values from controller into a
                    ; global variable.
                    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                    lda #1                     ; Latch button values
                    sta    JOYPAD1
                    lda #0
                    sta JOYPAD1

                    ldx #8
.readBit            lda JOYPAD1
                    lsr
                    ror buttons
                    dex
                    bne .readBit

                    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                    ; Update game state
                    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.checkA                lda #A_BUTTON
                    bit buttons
                    beq .checkLeft

                    lda ypos                ; Is the player standing on the floor?
                    cmp #FLOOR
                    bcc .checkLeft            ; Nope.  You can't jump if you're in the air.
                    lda #JMP_VEC            ; Give the character a little upward thrust
                    sta gravityVector

.checkLeft          lda #LEFT_BUTTON
                    bit buttons
                    beq .checkRight

                    lda xpos
                    sbc #HORZ_SPEED
                    sta xpos

.checkRight         lda #RIGHT_BUTTON
                    bit buttons
                    beq .checkDone

                    lda xpos
                    clc
                    adc #HORZ_SPEED
                    sta xpos
.checkDone
                    ; Account for gravity
                    lda gravityVector
                    beq .accelerate
                    clc
                    adc ypos
                    sta ypos

                    ; Has the character hit the ground yet?
                    lda ypos
                    cmp #FLOOR
                    bcc .accelerate        ; Still in the air
                    lda #0
                    sta gravityVector    ; Stop the player from falling
                    lda #FLOOR
                    sta ypos            ; Bump them back up to ground level

.accelerate         lda ypos
                    cmp #FLOOR
                    bcs .gravityDone
                    lda gravityVector
                    cmp #MAX_FALL        ; Terminal velocity :)
                    bpl .gravityDone
                    inc gravityVector    ; Fall a little faster
.gravityDone


                    ; Wait for vblank
.poll               lda PPUSTATUS
                    bpl .poll

                    jmp .mainLoop

;
;    When the VBlank interrupt occurs, update sprite positions
;
HandleVBlank        subroutine

                    lda #8 ; XXX flickers when I use <8 here.
                    sta OAMADDR

                    lda ypos
                    sta OAMDATA        ; YPOS
                    lda #0
                    sta OAMDATA        ; Tile
                    lda #1
                    sta OAMDATA        ; Flags
                    lda xpos
                    sta OAMDATA        ; XPOS

                    lda ypos
                    sta OAMDATA        ; YPOS
                    lda #1
                    sta OAMDATA        ; Tile
                    lda #1
                    sta OAMDATA        ; Flags
                    lda xpos
                    clc
                    adc #8
                    sta OAMDATA        ; XPOS

                    ; Update scroll position
                    lda scrollOffs
                    sta PPUSCROLL
                    lda #0
                    sta PPUSCROLL
                    inc scrollOffs
                    rti


HandleIRQ           subroutine
                    rti

                    include "palette.inc"

                    org $fffa, 0
                    dc.w HandleVBlank
                    dc.w HandleReset
                    dc.w HandleIRQ
