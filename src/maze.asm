;*******************************************************************************
; AMAZING MAZE (1976)
;*******************************************************************************
; Arcade maze game for Midway Intel 8080 hardware.
;
; Developer : Dave Nutting Associates (DNA)
; Publisher : Midway Manufacturing
; CPU       : Intel 8080
; Software  : Native 8080 game routines and 17-command indexed interpreter
;
; ROM       : maze.h ($0000-$07FF), maze.g ($0800-$0FFF)
; Source    : original roms/original/maze.zip
; Build     : zmac v1.3; two 2 KB ROM devices
;
; The program initializes game state, interprets its command scripts,
; maintains maze cells, and renders graphics into bitmap video RAM.
;*******************************************************************************

        ORG $0000


; Reset vector: initialize stack and transfer to the startup sequence.
RESET:
        NOP
        NOP
        LD SP,$2400
        JP $0017

; Frame interrupt vector: preserve registers and enter frame service.
INTERRUPT_ENTRY:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        JP FRAME_SERVICE
        DB $00
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        JP $02E2
; Read input port 1; carry controls transition into initial script setup.

; Startup diagnostics, ROM checksums and program initialization.
RESET_START:
        IN A,($01)
        RLA
        JP NC,INIT_SCRIPT_ROOT
        LD B,$01
        LD DE,$0000

DIAG_RAM_BEGIN:
        LD HL,$2000

DIAG_RAM_WRITE_AND_COMPARE:
        OUT ($02),A
        LD (HL),B
        LD A,(HL)
        XOR B
        JP Z,$003C
        LD C,A
        LD A,L
        AND $01
        LD A,C
        JP NZ,$003A
        OR D
        LD D,A
        JP $003C

DIAG_RECORD_ODD_ERROR:
        OR E
        LD E,A

DIAG_RAM_ADVANCE:
        INC HL
        LD A,H
        CP $40
        JP NZ,$0025

DIAG_RAM_REVERSE_SCAN:
        OUT ($02),A
        DEC HL
        LD A,H
        CP $1F
        JP Z,$0079
        LD A,(HL)
        XOR B
        JP Z,$0060
        LD C,A
        LD A,L
        AND $01
        LD A,C
        JP NZ,$005E
        OR D
        LD D,A
        JP $0060

DIAG_RECORD_REVERSE_ODD_ERROR:
        OR E
        LD E,A

DIAG_RAM_TEST_COMPLEMENT:
        LD A,B
        CPL
        LD (HL),A
        XOR (HL)
        JP Z,$0043
        LD C,A
        LD A,L
        AND $01
        LD A,C
        JP NZ,$0074
        OR D
        LD D,A
        JP $0076

DIAG_RECORD_COMPLEMENT_ODD_ERROR:
        OR E
        LD E,A

DIAG_RAM_REVERSE_NEXT:
        JP $0043

DIAG_RAM_FINAL_SCAN:
        OUT ($02),A
        INC HL
        LD A,H
        CP $40
        JP Z,$009C
        LD A,B
        CPL
        XOR (HL)
        JP Z,$0097
        LD C,A
        LD A,L
        AND $01
        LD A,C
        JP NZ,$0095
        OR D
        LD D,A
        JP $0097

DIAG_RECORD_FINAL_ODD_ERROR:
        OR E
        LD E,A

DIAG_RAM_CLEAR_NEXT:
        XOR A
        LD (HL),A
        JP $0079

DIAG_EVALUATE_RAM_ERRORS:
        LD A,B
        RLCA
        LD B,A
        JP NC,$0022
        LD A,D
        OR E
        JP Z,$00CC
        EX DE,HL
        LD SP,HL
        LD DE,$2000
        LD B,$00

DIAG_ERROR_DISPLAY_ROW:
        LD HL,$0000
        ADD HL,SP
        LD C,$10

DIAG_ERROR_DISPLAY_PIXEL:
        XOR A
        ADD HL,HL
        JP C,$00BA
        CPL

DIAG_ERROR_WRITE_PIXEL:
        LD (DE),A
        INC DE
        XOR A
        LD (DE),A
        INC DE
        DEC C
        JP NZ,$00B4
        DEC B
        JP NZ,$00AE
; Repeatedly writes to hardware output port $02.

SERVICE_HALTED_OUTPUT_LOOP:
        OUT ($02),A
        JP $00C7
; Computes checksums over original ROM pages, stores result/display codes in RAM $2036 onward.

; Original ROM checksum routine and diagnostic output.
CHECK_ROM_PAGE_SUMS:
        LD SP,$2400
        LD HL,$0000
        LD DE,$0000
        LD C,$04
; Starts the next native ROM-page checksum loop.

BEGIN_ROM_CHECKSUM_PAGE:
        XOR A
; Sums ROM bytes until the page boundary; feeds native ROM checksum comparisons.

ACCUMULATE_ROM_CHECKSUM:
        OUT ($02),A
        ADD A,(HL)
        INC HL
        LD B,A
        LD A,C
        CP H
        LD A,B
        JP NZ,$00D8
        PUSH HL
        LD HL,$0120
        ADD HL,DE
        CP (HL)
        LD A,$40
        JP Z,$00F3
        LD HL,$0125
        ADD HL,DE
        LD A,(HL)
; Stores the current checksum test result in RAM $2036 + page index.

STORE_ROM_CHECK_RESULT:
        LD HL,$2036
        ADD HL,DE
        LD (HL),A
        POP HL
        INC DE
        INC C
        INC C
        INC C
        INC C
        LD A,$14
        CP C
        JP NZ,$00D7
        LD HL,$2039
        LD A,(HL)
        DEC HL
        OR (HL)
        DEC HL
        OR (HL)
        DEC HL
        OR (HL)
        AND $BF
        JP Z,$0000
        LD DE,$3008
        LD A,$04
        CALL DRAW_TEXT_GLYPH_STREAM

DIAG_ROM_FAILURE_LOOP:
        OUT ($02),A
        JP $011B
        DB $00,$A1,$C1,$EE,$58,$48,$48,$47,$47
; Original native text/glyph rendering entry at $0129.
; Entry HL -> encoded text, DE -> framebuffer destination, A = item count.
; Glyph bytes write at +$20 bitmap stride for ten rows; stream bytes
; below $30 advance position and other characters index the font below.

; Text renderer: decode glyph and positioning codes into video RAM.
DRAW_TEXT_GLYPH_STREAM:
        PUSH AF

TEXT_FETCH_NEXT_CODE:
        LD A,(HL)
        INC HL
        SUB $30
        JP P,$0142
        LD B,A
; Advances the framebuffer destination for text-position control codes.

ADVANCE_ENCODED_TEXT_POSITION:
        INC DE
        LD A,E
        AND $1F
        JP NZ,$013B
        INC D
        INC D

TEXT_POSITION_CONTROL_LOOP:
        INC B
        JP NZ,$0132
        JP $012A

TEXT_DECODE_FONT_INDEX:
        PUSH HL
        PUSH DE
        INC A
        CP $0B
        JP M,$014C
        SUB $06
; Converts glyph index into ten-byte ROM font offset.

SELECT_FONT_GLYPH:
        LD HL,$0166
        LD BC,$000A
; Steps ten bytes per font index.

ADVANCE_FONT_TO_GLYPH:
        ADD HL,BC
        DEC A
        JP NZ,$0152
        EX DE,HL
        LD BC,$0020
        LD A,$0A
; Copies a byte from selected glyph into framebuffer and advances destination by 32 bytes.

WRITE_NEXT_GLYPH_ROW:
        PUSH AF
        LD A,(DE)
        INC DE
        LD (HL),A
        ADD HL,BC
        POP AF
        DEC A
        JP NZ,$015D
        POP DE
        POP HL
        INC DE
        POP AF
        DEC A
        JP NZ,DRAW_TEXT_GLYPH_STREAM
        RET
; Original 37 glyphs: ten numeric glyphs, space and 26 uppercase letters.
; Each glyph is ten vertical rows, eight pixels per byte.
; Native drawing routine $0129 writes each row with a $20-byte screen stride.

; Original font: 37 glyphs, 10 rows of 8 pixels per glyph.
; ROM graphics data: bytes below are drawn in their original order.
FONT_37_GLYPHS_10_ROWS:         ; $0170-$02E1

; font digit 0 — 8 x 10 bitmap.
FONT_DIGIT_0:                        ; $0170
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font digit 1 — 8 x 10 bitmap.
FONT_DIGIT_1:                        ; $017A
        DB $18  ; ...##...
        DB $1C  ; ...###..
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $3C  ; ..####..
        DB $3C  ; ..####..

; font digit 2 — 8 x 10 bitmap.
FONT_DIGIT_2:                        ; $0184
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $60  ; .##.....
        DB $7C  ; .#####..
        DB $3E  ; ..#####.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $7E  ; .######.
        DB $7E  ; .######.

; font digit 3 — 8 x 10 bitmap.
FONT_DIGIT_3:                        ; $018E
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $60  ; .##.....
        DB $38  ; ..###...
        DB $78  ; .####...
        DB $60  ; .##.....
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font digit 4 — 8 x 10 bitmap.
FONT_DIGIT_4:                        ; $0198
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $7E  ; .######.
        DB $60  ; .##.....
        DB $60  ; .##.....
        DB $60  ; .##.....
        DB $60  ; .##.....

; font digit 5 — 8 x 10 bitmap.
FONT_DIGIT_5:                        ; $01A2
        DB $3E  ; ..#####.
        DB $3E  ; ..#####.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $3E  ; ..#####.
        DB $7E  ; .######.
        DB $60  ; .##.....
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font digit 6 — 8 x 10 bitmap.
FONT_DIGIT_6:                        ; $01AC
        DB $3C  ; ..####..
        DB $3E  ; ..#####.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $3E  ; ..#####.
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font digit 7 — 8 x 10 bitmap.
FONT_DIGIT_7:                        ; $01B6
        DB $7E  ; .######.
        DB $7E  ; .######.
        DB $60  ; .##.....
        DB $70  ; .###....
        DB $30  ; ..##....
        DB $38  ; ..###...
        DB $18  ; ...##...
        DB $1C  ; ...###..
        DB $0C  ; ....##..
        DB $0C  ; ....##..

; font digit 8 — 8 x 10 bitmap.
FONT_DIGIT_8:                        ; $01C0
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font digit 9 — 8 x 10 bitmap.
FONT_DIGIT_9:                        ; $01CA
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $7C  ; .#####..
        DB $60  ; .##.....
        DB $60  ; .##.....
        DB $7C  ; .#####..
        DB $3C  ; ..####..

; font space — 8 x 10 bitmap.
FONT_SPACE:                        ; $01D4
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........

; font letter a — 8 x 10 bitmap.
FONT_LETTER_A:                        ; $01DE
        DB $18  ; ...##...
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.

; font letter b — 8 x 10 bitmap.
FONT_LETTER_B:                        ; $01E8
        DB $3E  ; ..#####.
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $3E  ; ..#####.
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3E  ; ..#####.

; font letter c — 8 x 10 bitmap.
FONT_LETTER_C:                        ; $01F2
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font letter d — 8 x 10 bitmap.
FONT_LETTER_D:                        ; $01FC
        DB $3E  ; ..#####.
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3E  ; ..#####.

; font letter e — 8 x 10 bitmap.
FONT_LETTER_E:                        ; $0206
        DB $7E  ; .######.
        DB $7E  ; .######.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $3E  ; ..#####.
        DB $3E  ; ..#####.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $7E  ; .######.
        DB $7E  ; .######.

; font letter f — 8 x 10 bitmap.
FONT_LETTER_F:                        ; $0210
        DB $7E  ; .######.
        DB $7E  ; .######.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $3E  ; ..#####.
        DB $3E  ; ..#####.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.

; font letter g — 8 x 10 bitmap.
FONT_LETTER_G:                        ; $021A
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $76  ; .###.##.
        DB $76  ; .###.##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font letter h — 8 x 10 bitmap.
FONT_LETTER_H:                        ; $0224
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.

; font letter i — 8 x 10 bitmap.
FONT_LETTER_I:                        ; $022E
        DB $3C  ; ..####..
        DB $3C  ; ..####..
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $3C  ; ..####..
        DB $3C  ; ..####..

; font letter j — 8 x 10 bitmap.
FONT_LETTER_J:                        ; $0238
        DB $C0  ; ##......
        DB $C0  ; ##......
        DB $C0  ; ##......
        DB $C0  ; ##......
        DB $C0  ; ##......
        DB $C0  ; ##......
        DB $00  ; ........
        DB $00  ; ........
        DB $C0  ; ##......
        DB $C0  ; ##......

; font letter k — 8 x 10 bitmap.
FONT_LETTER_K:                        ; $0242
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $76  ; .###.##.
        DB $3E  ; ..#####.
        DB $1E  ; ...####.
        DB $1E  ; ...####.
        DB $3E  ; ..#####.
        DB $76  ; .###.##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.

; font letter l — 8 x 10 bitmap.
FONT_LETTER_L:                        ; $024C
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $7E  ; .######.
        DB $7E  ; .######.

; font letter m — 8 x 10 bitmap.
FONT_LETTER_M:                        ; $0256
        DB $C3  ; ##....##
        DB $C3  ; ##....##
        DB $E7  ; ###..###
        DB $E7  ; ###..###
        DB $FF  ; ########
        DB $FF  ; ########
        DB $DB  ; ##.##.##
        DB $C3  ; ##....##
        DB $C3  ; ##....##
        DB $C3  ; ##....##

; font letter n — 8 x 10 bitmap.
FONT_LETTER_N:                        ; $0260
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $6E  ; .##.###.
        DB $6E  ; .##.###.
        DB $7E  ; .######.
        DB $7E  ; .######.
        DB $76  ; .###.##.
        DB $76  ; .###.##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.

; font letter o — 8 x 10 bitmap.
FONT_LETTER_O:                        ; $026A
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font letter p — 8 x 10 bitmap.
FONT_LETTER_P:                        ; $0274
        DB $3E  ; ..#####.
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3E  ; ..#####.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.
        DB $06  ; .....##.

; font letter q — 8 x 10 bitmap.
FONT_LETTER_Q:                        ; $027E
        DB $00  ; ........
        DB $00  ; ........
        DB $08  ; ....#...
        DB $08  ; ....#...
        DB $08  ; ....#...
        DB $49  ; .#..#..#
        DB $6B  ; .##.#.##
        DB $3E  ; ..#####.
        DB $1C  ; ...###..
        DB $08  ; ....#...

; font letter r — 8 x 10 bitmap.
FONT_LETTER_R:                        ; $0288
        DB $3E  ; ..#####.
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3E  ; ..#####.
        DB $76  ; .###.##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.

; font letter s — 8 x 10 bitmap.
FONT_LETTER_S:                        ; $0292
        DB $3C  ; ..####..
        DB $7E  ; .######.
        DB $66  ; .##..##.
        DB $06  ; .....##.
        DB $3E  ; ..#####.
        DB $7C  ; .#####..
        DB $60  ; .##.....
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font letter t — 8 x 10 bitmap.
FONT_LETTER_T:                        ; $029C
        DB $7E  ; .######.
        DB $7E  ; .######.
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...

; font letter u — 8 x 10 bitmap.
FONT_LETTER_U:                        ; $02A6
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..

; font letter v — 8 x 10 bitmap.
FONT_LETTER_V:                        ; $02B0
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..
        DB $3C  ; ..####..
        DB $18  ; ...##...
        DB $18  ; ...##...

; font letter w — 8 x 10 bitmap.
FONT_LETTER_W:                        ; $02BA
        DB $C3  ; ##....##
        DB $C3  ; ##....##
        DB $C3  ; ##....##
        DB $DB  ; ##.##.##
        DB $FF  ; ########
        DB $FF  ; ########
        DB $E7  ; ###..###
        DB $E7  ; ###..###
        DB $C3  ; ##....##
        DB $C3  ; ##....##

; font letter x — 8 x 10 bitmap.
FONT_LETTER_X:                        ; $02C4
        DB $00  ; ........
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $00  ; ........

; font letter y — 8 x 10 bitmap.
FONT_LETTER_Y:                        ; $02CE
        DB $66  ; .##..##.
        DB $66  ; .##..##.
        DB $7E  ; .######.
        DB $3C  ; ..####..
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...
        DB $18  ; ...##...

; font letter z — 8 x 10 bitmap.
FONT_LETTER_Z:                        ; $02D8
        DB $7E  ; .######.
        DB $7E  ; .######.
        DB $60  ; .##.....
        DB $70  ; .###....
        DB $38  ; ..###...
        DB $1C  ; ...###..
        DB $0E  ; ....###.
        DB $06  ; .....##.
        DB $7E  ; .######.
        DB $7E  ; .######.

NATIVE_02E2:
        XOR A
        CALL $0302
        LD (HL),A
        CALL $061E
        CALL PERIODIC_TIMER_SERVICE
        LD HL,$2055
        CALL $0962
        CALL $04BE
        CALL READ_STABLE_PORT0_INPUT
        CALL $0453
; Restores HL, DE, BC, AF, enables interrupts, then returns.

RESTORE_INTERRUPT_REGISTERS:
        POP HL
        POP DE
        POP BC
        POP AF
        EI
        RET
; $0302 — CHECK FRAME MODE OR INTERRUPT EXIT.
; Compares incoming A against RAM $202F; matching mode pops the caller and branches to common interrupt exit $02FC.

CHECK_FRAME_MODE_OR_INTERRUPT_EXIT:
        LD HL,$202F
        CP (HL)
        RET NZ
        POP HL
        JP RESTORE_INTERRUPT_REGISTERS

; Interrupt service: timers, input handling and frame-state updates.
FRAME_SERVICE:
        LD A,$10
        CALL $0302
        LD (HL),A
        CALL $061E
        CALL $05A2
        CALL READ_START_INPUTS
        LD A,($2030)
        DEC A
        JP NZ,$0338
        LD A,($2020)
        AND A
        JP Z,RESTORE_INTERRUPT_REGISTERS
        LD HL,$2033
        INC (HL)
        LD A,($2013)
        CP (HL)
        JP NZ,RESTORE_INTERRUPT_REGISTERS
        LD (HL),$00
        CALL UPDATE_MAZE_MOVEMENT
; Loads $2044 and calls native update at $0962 before interrupt exit.

UPDATE_FRAME_POSITION_STATE:
        LD HL,$2044
        CALL $0962
        JP RESTORE_INTERRUPT_REGISTERS

PERIODIC_TIMER_SERVICE:
        LD HL,$2035
        LD A,(HL)
        AND A
        RET NZ
        LD B,A
        LD HL,$200A
        DEC (HL)
        JP NZ,$0357
        LD (HL),$3C
        LD HL,$200B
        CALL TIMER_DECREMENT
; Completes the timer-event path and stores the accumulated status.

RECORD_TIMER_EVENT_BITS:
        LD HL,$200C
        CALL TIMER_DECREMENT
        INC HL
        CALL TIMER_DECREMENT
        INC HL
        CALL TIMER_DECREMENT
        LD ($2035),A
        RET

TIMER_DECREMENT:
        LD A,(HL)
        AND A
        JP Z,$0373
        DEC (HL)
        JP NZ,$0373
        SCF
; Returns after advancing the periodic countdown and carry-driven event mask.

FINISH_TIMER_BYTE_TEST:
        LD A,B
        RLA
        LD B,A
        RET

INIT_SCRIPT_ROOT:
        LD A,$10
        CALL $08EE
        LD HL,$0D64
        LD ($2002),HL
        LD HL,$FFFF
        LD ($2004),HL
        LD ($2006),HL
        EI
        LD HL,$038B
        PUSH HL
        OUT ($02),A

SCRIPT_INITIALIZE:
        LD HL,($2002)
        LD A,H
        OR L
        JP Z,SCRIPT_FETCH
        XOR A
        LD ($200B),A
        LD ($200C),A
        LD ($2000),HL
        LD HL,$0000
        LD ($2002),HL

SCRIPT_FETCH:
        LD HL,($2000)
        LD A,(HL)
        AND A
        JP Z,ZERO_COMMAND
        INC HL
        LD ($2000),HL
        EX DE,HL
        LD HL,$0BEE
        DEC A
        CP $11
        JP NC,INIT_SCRIPT_ROOT
        ADD A,A
        LD C,A
        LD B,$00
        ADD HL,BC
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        JP (HL)

ZERO_COMMAND:
        LD A,($201F)
        AND A
        CALL Z,ZERO_COMMAND_EVENT
        RET
        DB $00,$00

ZERO_COMMAND_EVENT:
        CALL CLEAR_MAZE_CELL_LOW_NIBBLES
        XOR A
        LD ($201C),A
        CALL $06E8
        CALL $06F5
; Runs maze-step and output-port service until event state E is zero.

RUN_ZERO_COMMAND_MAZE_EVENTS:
        CALL $070E
        OUT ($02),A
        LD A,E
        AND A
        JP Z,$03F1
        CALL $0780
        JP $03E1
; Checks $201D and invokes $080D; increments $201F when the event is complete.

TEST_MAZE_EVENT_COMPLETION:
        LD A,($201D)
        AND A
        JP Z,ZERO_COMMAND_EVENT
        CALL $080D
        JP C,$03E1
        INC A
        LD ($201F),A
        RET
; $0403 — CLEAR MAZE CELL LOW NIBBLES.
; Iterates 26 x 24 bytes from RAM $2066, preserving each byte's high nibble with AND $F0.

CLEAR_MAZE_CELL_LOW_NIBBLES:
        LD DE,$2066
        LD B,$1A
; Sets inner counter C=$18 for the next one of $1A rows.

CLEAR_NEXT_MAZE_ROW_NIBBLES:
        LD C,$18
; Preserves each cell's high nibble with AND $F0 across the maze cell region.

CLEAR_MAZE_CELL_NIBBLE:
        LD A,(DE)
        AND $F0
        LD (DE),A
        INC DE
        DEC C
        JP NZ,$040A
        DEC B
        JP NZ,$0408
        RET
        DB $C9

CMD_06_INIT_GAME_FIELDS:
        CALL SHIFT_MAZE_CELLS_LEFT_FOUR
        XOR A
        LD HL,$2015
        LD B,$0D
; Writes zero to each of the thirteen RAM bytes starting at $2015.

CLEAR_NEXT_GAME_STATE_BYTE:
        LD (HL),A
        INC HL
        DEC B
        JP NZ,$0422
        LD HL,$2023
        LD A,(HL)
        INC HL
        LD (HL),A
        INC HL
        LD A,(HL)
        INC HL
        LD (HL),A
        LD HL,$2040
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        LD (HL),C
        INC HL
        LD (HL),B
        RET
; $043D — SHIFT MAZE CELLS LEFT FOUR.
; Iterates $0370 bytes from RAM $2066 and shifts each byte four bits left, preserving its former low nibble in the high nibble.

SHIFT_MAZE_CELLS_LEFT_FOUR:
        LD DE,$2066
        LD BC,$0370
; Shift maze cell byte left by four bits and advance to the next maze cell.

SHIFT_NEXT_MAZE_CELL_NIBBLE:
        LD A,(DE)
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        LD (DE),A
        INC DE
        DEC C
        JP NZ,$0443
        DEC B
        JP NZ,$0443
        RET

NATIVE_0453:
        LD A,($201E)
        AND A
        RET NZ
        LD B,$01
        LD HL,$2045
        LD DE,$2056
        LD A,(DE)
        SUB $10
        JP Z,$046B
        INC B
        LD A,(HL)
        SUB $E6
        RET NZ

NATIVE_046B:
        LD (HL),A
        DEC HL
        LD (HL),A
        EX DE,HL
        LD (HL),A
        DEC HL
        LD (HL),A
        LD ($200D),A
        LD A,B
        LD ($200C),A
        LD ($201E),A
        LD HL,$2031
        LD DE,$201A
        DEC A
        JP Z,$0488
        INC DE
        INC HL

NATIVE_0488:
        LD A,(HL)
        INC A
        DAA
        LD (HL),A
        LD (DE),A
        LD HL,$202E
        LD A,(HL)
        ADD A,$99
        DAA
        JP M,$08AC
        LD (HL),A
        JP $08AC
; Reads input port $00 twice and returns when readings disagree; otherwise updates state fields.

READ_STABLE_PORT0_INPUT:
        IN A,($00)
        LD B,A
        IN A,($00)
        CP B
        RET NZ
        LD DE,$2055
        CALL MERGE_INPUT_LOW_NIBBLE
        LD A,($2030)
        DEC A
        RET Z
        LD A,B
        RRCA
        RRCA
        RRCA
        RRCA
        LD DE,$2044
; Stores the lower four input bits in the supplied state byte while retaining its upper four bits.

MERGE_INPUT_LOW_NIBBLE:
        AND $0F
        LD C,A
        LD A,(DE)
        AND $F0
        OR C
        LD (DE),A

CMD_01_RETURN_SCRIPT:
        RET
; Tests state byte at $2035 and processes native game-state update.

SERVICE_GAME_STATE_COUNTER:
        LD HL,$2035
        LD A,(HL)
        AND A
        RET Z
        LD (HL),$00
        RRA
        PUSH AF
        CALL C,$04DB
        POP AF
        RRA
        PUSH AF
        CALL C,$0514
        POP AF
        RRA
        CALL C,SKIP_NEXT_SCRIPT_BYTE
        RRA
        CALL C,RESTORE_SCRIPT_ROOT_FROM_SAVED_POINTER
        RET

NATIVE_04DB:
        LD HL,$2029
        DEC (HL)
        JP NZ,$0500
        LD A,$01
        LD ($200D),A
        LD ($2020),A
        LD HL,$0C10
        LD DE,$3EA0
        LD A,$0A
        CALL DRAW_TEXT_GLYPH_STREAM
        LD HL,$0CAD
        LD DE,$3EA3
        LD A,$04
        JP DRAW_TEXT_GLYPH_STREAM

NATIVE_0500:
        LD A,$3C
        LD ($200E),A
        LD A,(HL)
        OR $30
        LD HL,$2036
        LD (HL),A
        LD A,$01
        LD DE,$3EAB
        JP DRAW_TEXT_GLYPH_STREAM

NATIVE_0514:
        LD A,$3C
        LD ($200D),A
        LD A,($202C)
        AND A
        JP Z,$0554
        LD HL,$202B
        LD A,(HL)
        ADD A,$99
        DAA
        LD (HL),A
        JP P,$054B
        LD (HL),$59
        DEC HL
        DEC (HL)
        JP P,$054B
        LD HL,$0D64
        LD ($2002),HL
        LD HL,$200B
        LD B,$05
        XOR A

CLEAR_FIVE_STATE_BYTES:
        LD (HL),A
        INC HL
        DEC B
        JP NZ,$053E
        LD ($2044),A
        LD ($2055),A
        RET

DISPLAY_SCORE_AND_INCREMENT:
        LD HL,$3EB8
        LD DE,$202A
        CALL $056D

INCREMENT_PACKED_SCORE:
        LD HL,$2019
        LD A,(HL)
        INC A
        DAA
        LD (HL),A
        CP $60
        JP NZ,$0567
        LD (HL),$00
        DEC HL
        LD A,(HL)
        INC A
        DAA
        LD (HL),A

DISPLAY_SCORE_FROM_GAME_STATE:
        LD HL,$3EA8
        LD DE,$2018

DISPLAY_PACKED_SCORE_FIELD:
        LD BC,$2036
        CALL FORMAT_PACKED_BYTE_AS_TWO_DIGITS
        LD A,$58
        LD (BC),A
        INC BC
        CALL FORMAT_PACKED_BYTE_AS_TWO_DIGITS
        EX DE,HL
        LD HL,$2036
        PUSH HL
        CALL $058C
        INC HL
        CALL $058C
        POP HL
        LD A,$05
        JP DRAW_TEXT_GLYPH_STREAM
; $058C — NORMALIZE DISPLAY GLYPH SPACE.
; Converts byte $30 at (HL) into $40; otherwise returns unchanged.

NORMALIZE_DISPLAY_GLYPH_SPACE:
        LD A,(HL)
        CP $30
        RET NZ
        LD (HL),$40
        RET
; $0593 — SKIP NEXT SCRIPT BYTE.
; Advances the 16-bit command pointer at RAM $2000 by one and returns.

SKIP_NEXT_SCRIPT_BYTE:
        LD HL,($2000)
        INC HL
        LD ($2000),HL
        RET
; $059B — RESTORE SCRIPT ROOT FROM SAVED POINTER.
; Copies pointer at RAM $2008 to script root RAM $2002.

RESTORE_SCRIPT_ROOT_FROM_SAVED_POINTER:
        LD HL,($2008)
        LD ($2002),HL
        RET
; $05A2 — SAMPLE PORT1 INPUT EDGE.
; Reads I/O port $01, isolates bit $08 and compares against prior value at RAM $2028; updates credit/input state.

SAMPLE_PORT1_INPUT_EDGE:
        LD HL,$2028
        IN A,($01)
        LD C,A
        AND $08
        LD B,A
        XOR (HL)
        RET Z
        LD (HL),B
        LD A,B
        AND A
        RET Z
        OUT ($01),A
        LD HL,$2014
        INC (HL)
        LD A,C
        RRA
        RRA
        RRA
        RRA
        AND $01
        CP (HL)
        RET P
        LD (HL),$00
        LD HL,$2027
        INC (HL)
        LD A,C
        AND $20
        JP Z,$05D4
        INC (HL)
        LD A,C
        AND $10
        JP Z,$05D4
        INC (HL)

NATIVE_05D4:
        LD A,($202D)
        AND A
        RET NZ

; Interpreted command handler: update game-end state.
CMD_11_UPDATE_END_STATE:
        LD HL,$2027
        XOR A
        CP (HL)
        RET Z
        DEC (HL)
        LD A,$03
        LD ($202E),A
        LD ($202D),A
        LD HL,$0E27
        LD ($2002),HL

NATIVE_05EE:
        LD HL,$0CF1
        LD DE,$3EA3
        LD A,$04
        JP DRAW_TEXT_GLYPH_STREAM
; Reads port $01 and updates start/selection state.

READ_START_INPUTS:
        LD DE,$2034
        LD A,(DE)
        AND A
        RET Z
        IN A,($01)
        LD B,A
        LD HL,$0E5F
        AND $01
        LD A,$01
        JP NZ,$0615
        LD HL,$0F31
        LD A,B
        AND $02
        LD A,$02
        RET Z

NATIVE_0615:
        LD ($2030),A
        LD ($2002),HL
        XOR A
        LD (DE),A
        RET
; Native frame-time hardware state update.

SAMPLE_GAME_TIMING_STATE:
        LD HL,$2044
        PUSH HL
        CALL $06AF
        LD HL,$2055
        PUSH HL
        CALL $06AF
        POP HL
        CALL $0648
        POP HL
        JP $0648
; $0634 — FORMAT PACKED BYTE AS TWO DIGITS.
; Expands one packed BCD-like byte from (DE) into two ASCII digit bytes at (BC); increments both pointers.

FORMAT_PACKED_BYTE_AS_TWO_DIGITS:
        LD A,(DE)
        RRA
        RRA
        RRA
        RRA
        AND $0F
        ADD A,$30
        LD (BC),A
        INC BC
        LD A,(DE)
        INC DE
        AND $0F
        ADD A,$30
        LD (BC),A
        INC BC
        RET

NATIVE_0648:
        LD A,($202F)
        XOR (HL)
        AND $10
        RET NZ
        LD A,(HL)
        AND A
        RET P
        OR $20
        LD B,A
        AND $40
        JP NZ,$065C
        LD B,$00

NATIVE_065C:
        LD (HL),B
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD A,E
        AND $07
        LD ($2015),A
        CALL $06D6
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        EX DE,HL
        LD A,$05

COPY_CELL_RECORD_LOOP:
        PUSH AF
        LD A,(HL)
        LD (DE),A
        INC DE
        LD A,(BC)
        INC BC
        CALL $0697
        OR (HL)
        LD (HL),A
        INC HL
        LD A,(HL)
        LD (DE),A
        INC DE
        XOR A
        CALL $0697
        OR (HL)
        LD (HL),A
        PUSH DE
        LD DE,$001F
        ADD HL,DE
        POP DE
        POP AF
        DEC A
        JP NZ,$0676
        RET

NATIVE_0697:
        PUSH HL
        LD HL,($2016)
        LD L,H
        LD H,A
        LD ($2016),HL
        LD A,($2015)
        AND A
        JP Z,$06AC

SHIFT_COORDINATE_TO_ROW_OFFSET:
        ADD HL,HL
        DEC A
        JP NZ,$06A7

NATIVE_06AC:
        LD A,H
        POP HL
        RET

NATIVE_06AF:
        LD A,($202F)
        XOR (HL)
        AND $10
        RET NZ
        LD A,(HL)
        AND $20
        RET Z
        LD BC,$0005
        ADD HL,BC
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        EX DE,HL
        LD C,$05

COPY_MAZE_CELL_RECORD_BYTE:
        LD A,(DE)
        INC DE
        LD (HL),A
        INC HL
        LD A,(DE)
        INC DE
        LD (HL),A
        LD A,C
        LD C,$1F
        ADD HL,BC
        LD C,A
        DEC C
        JP NZ,$06C5
        RET

NATIVE_06D6:
        LD B,$03

NATIVE_06D8:
        XOR A
        LD A,D
        RRA
        LD D,A
        LD A,E
        RRA
        LD E,A
        DEC B
        JP NZ,$06D8
        LD A,D
        ADD A,$24
        LD D,A
        RET

MAZE_RECALCULATE_RANDOM_STATE:
        LD A,($200A)

MAZE_RANDOM_UPDATE_LOOP:
        PUSH AF
        CALL $0919
        POP AF
        DEC A
        JP NZ,$06EB
        RET

NATIVE_06F5:
        LD E,$18
        CALL $0903
        LD ($2025),A
        LD ($2040),A
        LD C,A
        XOR A
        LD ($2041),A
        LD B,A
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        OR $09
        LD (HL),A
        RET

MAZE_INSPECT_NEIGHBOR_WALLS:
        LD D,$00
        LD A,B
        CP $00
        JP Z,$0724
        DEC B
        CALL MAZE_CELL_ADDRESS
        INC B
        LD A,(HL)
        RRCA
        JP C,$0724
        LD A,D
        OR $01
        LD D,A

MAZE_CHECK_ROW_LIMIT:
        LD A,$19
        CP B
        JP NZ,$073C
        LD A,($201D)
        OR A
        JP NZ,$074A
        LD A,($201C)
        CP $46
        JP C,$074A
        JP $0746

MAZE_TEST_NEXT_ROW_WALL:
        INC B
        CALL MAZE_CELL_ADDRESS
        DEC B
        LD A,(HL)
        RRCA
        JP C,$074A

MAZE_FLAG_ROW_WALL:
        LD A,D
        OR $02
        LD D,A

MAZE_CHECK_LEFT_COLUMN:
        LD A,C
        CP $00
        JP Z,$075E
        DEC C
        CALL MAZE_CELL_ADDRESS
        INC C
        LD A,(HL)
        RRCA
        JP C,$075E
        LD A,D
        OR $04
        LD D,A

MAZE_CHECK_RIGHT_COLUMN:
        LD A,$17
        CP C
        JP Z,$0772
        INC C
        CALL MAZE_CELL_ADDRESS
        DEC C
        LD A,(HL)
        RRCA
        JP C,$0772
        LD A,D
        OR $08
        LD D,A

MAZE_COUNT_DIRECTION_FLAGS:
        LD E,$00
        LD A,D
        OR A

COUNT_OPEN_DIRECTIONS_LOOP:
        RRA
        JP NC,$077B
        INC E

COUNT_OPEN_DIRECTIONS_NEXT:
        OR A
        JP NZ,$0776
        RET

NATIVE_0780:
        LD A,($201D)
        AND A
        JP NZ,$078B
        LD HL,$201C
        INC (HL)

NATIVE_078B:
        LD A,$01
        LD ($2022),A
        CALL $0903
        LD E,A
        LD A,D
        INC E
        DEC E
        RRCA
        JP NC,$079F
        JP Z,$07B1
        DEC E

NATIVE_079F:
        RRCA
        JP NC,$07A7
        JP Z,$07BA
        DEC E

NATIVE_07A7:
        RRCA
        JP NC,$07F3
        JP Z,$07E8
        JP $07F3

NATIVE_07B1:
        DEC B
        CALL MAZE_CELL_ADDRESS
        LD D,$05
        JP $0804

NATIVE_07BA:
        CALL MAZE_CELL_ADDRESS
        LD D,$04
        CALL $0804
        LD A,$19
        CP B
        JP Z,$07D1
        INC B
        CALL MAZE_CELL_ADDRESS
        LD D,$01
        JP $0804

NATIVE_07D1:
        LD A,($201D)
        AND A
        JP NZ,$07E1
        LD A,$08
        LD ($201D),A
        LD A,C
        LD ($2023),A

NATIVE_07E1:
        LD B,$19
        LD A,($2023)
        LD C,A
        RET

NATIVE_07E8:
        DEC C
        CALL MAZE_CELL_ADDRESS
        LD D,$03
        JP $0804
        DB $00,$00

NATIVE_07F3:
        CALL MAZE_CELL_ADDRESS
        LD D,$02
        CALL $0804
        INC C
        CALL MAZE_CELL_ADDRESS
        LD D,$01
        JP $0804

NATIVE_0804:
        LD A,($201D)
        XOR $08
        OR (HL)
        OR D
        LD (HL),A
        RET

MAZE_ADVANCE_COLUMN:
        INC C
        LD A,$18
        CP C
        JP Z,$081D

MAZE_CHECK_COLUMN_BOUNDARY:
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        RRCA
        JP NC,$080D
        RET

MAZE_ADVANCE_ROW:
        LD C,$00
        INC B
        LD A,$1A
        CP B
        JP NZ,$0814
        LD B,$00
        LD A,($2022)
        OR A
        RET Z
        LD A,$00
        LD ($2022),A
        JP $0814

CMD_03_GAME_DISPLAY_UPDATE:
        LD HL,$3E02
        LD D,$00

NATIVE_083A:
        LD A,($2026)
        LD BC,$0D44
        CP D
        JP NZ,$084A
        CALL $08A3
        LD BC,$01D4

NATIVE_084A:
        CALL $08DB
        INC D
        LD A,$18
        CP D
        JP NZ,$083A
        LD HL,$3E23
        LD DE,$2066
        LD B,$1A

NATIVE_085C:
        LD C,$18
        PUSH HL
        PUSH BC
        LD (HL),$FF
        LD BC,$FFE0
        ADD HL,BC
        POP BC

NATIVE_0867:
        PUSH BC
        LD A,(DE)
        LD BC,$0D44
        AND $40
        JP Z,$0874
        LD BC,$01D4

NATIVE_0874:
        PUSH HL
        CALL $08DB
        POP HL
        LD A,(DE)
        INC DE
        LD BC,$0D4C
        AND $20
        JP Z,$0886
        LD BC,$01D4

NATIVE_0886:
        CALL $08DB
        POP BC
        DEC C
        JP NZ,$0867
        POP HL
        INC HL
        DEC B
        JP NZ,$085C
        LD A,($2024)
        INC H

NATIVE_0898:
        DEC H
        DEC A
        JP P,$0898
        LD BC,$0D5C
        JP $08DB

NATIVE_08A3:
        PUSH HL
        LD BC,$0D54
        CALL $08DB
        POP HL
        RET

CMD_0A_GAME_CONTROL:
        LD HL,$3E03
        LD DE,$2066
        LD B,$1A

NATIVE_08B4:
        LD C,$18
        PUSH HL

DRAW_MAZE_ROW_LOOP:
        PUSH BC
        LD A,(DE)
        INC DE
        LD BC,$0D3C
        AND $80
        JP NZ,$08C5
        LD BC,$01D4

DRAW_MAZE_ROW_ADVANCE:
        CALL $08DB
        POP BC
        DEC C
        JP NZ,$08B7
        POP HL
        INC HL
        DEC B
        JP NZ,$08B4
        LD A,($201F)
        AND A
        JP Z,$05EE
        RET

DRAW_MAZE_TILE:
        PUSH DE
        LD E,$08

DRAW_GRAPHIC_ROW_LOOP:
        LD A,(BC)
        INC BC
        OR (HL)
        LD (HL),A
        PUSH DE
        LD DE,$FFE0
        ADD HL,DE
        POP DE
        DEC E
        JP NZ,$08DE
        POP DE
        RET

NATIVE_08EE:
        DI
        POP HL
        LD BC,$0000
        LD DE,$0000
        LD SP,$4000

NATIVE_08F9:
        PUSH BC
        INC DE
        CP D
        JP NZ,$08F9
        LD SP,$2400
        JP (HL)

NATIVE_0903:
        PUSH BC
        CALL $0919
        LD C,A
        LD B,$00

RANDOM_RANGE_ACCUMULATE:
        DEC E
        JP Z,$0916
        ADD A,C
        JP NC,$090A
        INC B
        JP $090A

RANDOM_RANGE_RETURN:
        LD A,B
        POP BC
        RET

READ_GAME_RANDOM_STATE:
        PUSH HL
        PUSH BC
        LD HL,$2004
        LD B,$08
        LD A,(HL)

NATIVE_0921:
        RLCA
        RLCA
        RLCA
        XOR (HL)
        RLA
        RLA
        LD HL,$2004
        LD A,(HL)
        RLA
        LD (HL),A
        INC HL
        LD A,(HL)
        RLA
        LD (HL),A
        INC HL
        LD A,(HL)
        RLA
        LD (HL),A
        INC HL
        LD A,(HL)
        RLA
        LD (HL),A
        DEC B
        JP NZ,$0921
        POP BC
        POP HL
        RET
; Input B=row, C=column. HL = $2066 + 24*B + C; preserves BC and DE on stack; updates A and flags.

; Convert a maze cell coordinate into its packed state address.
MAZE_CELL_ADDRESS:
        PUSH DE
        LD E,$18
        LD D,$00
        LD HL,$0000
        LD A,B
        PUSH BC
        LD B,$09
; Nine-iteration shift/add inner loop for the 24-byte row stride.

MAZE_ROW_OFFSET_MULTIPLY:
        DEC B
        JP Z,$0959
        ADD HL,HL
        RLA
        JP NC,$094C
        ADD HL,DE
        JP $094C
; Adds column C and maze RAM base $2066; restores BC and DE.

MAZE_CELL_ADDRESS_RETURN:
        POP BC
        LD E,C
        ADD HL,DE
        LD DE,$2066
        ADD HL,DE
        POP DE
        RET

NATIVE_0962:
        LD A,(HL)
        AND A
        RET P
        PUSH HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        RRCA
        PUSH AF
        CALL C,$0999
        POP AF
        RRCA
        PUSH AF
        CALL C,$09B7
        POP AF
        RRCA
        PUSH AF
        CALL C,$09DB
        POP AF
        RRCA
        CALL C,$09C9
        POP HL
        LD A,E
        CP $0F
        RET Z
        LD A,D
        LD BC,$00EF
        CP $60
        JP NC,$0990
        LD B,$10

NATIVE_0990:
        LD A,(HL)
        AND C
        OR B
        LD (HL),A
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        RET

NATIVE_0999:
        CALL $09EF
        JP NZ,$09B5
        CALL $0A1D
        DEC B
        JP P,$09AE
        LD A,($2026)
        CP C
        RET NZ
        JP $09B5

NATIVE_09AE:
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $40
        RET Z

MAZE_REJECT_LEFT_STEP:
        DEC E
        RET

NATIVE_09B7:
        CALL $09EF
        JP NZ,$09C7
        CALL $0A1D
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $40
        RET Z

MAZE_REJECT_RIGHT_STEP:
        INC E
        RET

NATIVE_09C9:
        CALL $0A00
        JP NZ,$09D9
        CALL $0A1D
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $20
        RET Z

MAZE_REJECT_UP_STEP:
        DEC D
        RET

NATIVE_09DB:
        CALL $0A00
        JP NZ,$09ED
        CALL $0A1D
        DEC C
        RET M
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $20
        RET Z

MAZE_REJECT_DOWN_STEP:
        INC D
        RET

NATIVE_09EF:
        LD A,D
        AND $07
        CP $03
        POP BC
        RET NZ
        PUSH BC
        CALL $0A11
        LD A,E
        AND $07
        CP $07
        RET

NATIVE_0A00:
        LD A,E
        AND $07
        CP $07
        POP BC
        RET NZ
        PUSH BC
        CALL $0A11
        LD A,D
        AND $07
        CP $03
        RET

NATIVE_0A11:
        LD BC,$2020
        LD A,(BC)
        AND A
        RET NZ
        INC A
        LD (BC),A
        LD ($2029),A
        RET

NATIVE_0A1D:
        LD A,E
        RRA
        RRA
        RRA
        AND $1F
        SUB $02
        LD B,A
        LD A,D
        RRA
        RRA
        RRA
        AND $1F
        LD C,A
        LD A,$19
        SUB C
        LD C,A
        RET
; Reads $2042-$2046 cell coordinates and direction bits; chooses one of four three-step wall-test paths.

UPDATE_MAZE_MOVEMENT:
        LD HL,$2046
        LD A,(HL)
        AND $07
        CP $03
        RET NZ
        DEC HL
        LD A,(HL)
        AND $07
        CP $07
        RET NZ
        DEC HL
        LD A,(HL)
        DEC HL
        LD B,(HL)
        DEC HL
        LD C,(HL)
        RRA
        JP C,$0A59
        RRA
        JP C,$0A85
        RRA
        JP C,$0A6F
        RRA
        JP C,$0A9B
        RET
; Tests neighboring maze cells by varying column C and row B; common movement path.

TRY_PATH_LEFT_UP_RIGHT:
        CALL $0ABE
        JP C,$0AB1
        INC C
        CALL $0ACE
        JP C,$0AB1
        INC B
        CALL $0ADD
        JP C,$0AB1
        DEC C
        RET
; Tests another sequence of adjacent maze-cell boundaries.

TRY_PATH_DOWN_LEFT_UP:
        CALL $0AF0
        JP C,$0AB1
        DEC B
        CALL $0ABE
        JP C,$0AB1
        INC C
        CALL $0ACE
        JP C,$0AB1
        INC B
        RET
; Tests adjacent maze-cell boundaries, restoring column/row counters.

TRY_PATH_LEFT_RIGHT_DOWN:
        CALL $0ABE
        JP C,$0AB1
        INC C
        CALL $0ADD
        JP C,$0AB1
        DEC C
        CALL $0AF0
        JP C,$0AB1
        DEC B
        RET
; Tests adjacent maze-cell boundaries, restoring column/row counters.

TRY_PATH_DOWN_RIGHT_UP:
        CALL $0AF0
        JP C,$0AB1
        DEC B
        CALL $0ADD
        JP C,$0AB1
        DEC C
        CALL $0ACE
        JP C,$0AB1
        INC B
        RET
; Stores column C at $2042 and row B at $2043; updates high nibble of $2044 using D.

STORE_MAZE_POSITION_AND_WALL_STATE:
        LD HL,$2042
        LD (HL),C
        INC HL
        LD (HL),B
        INC HL
        LD A,(HL)
        AND $F0
        OR D
        LD (HL),A
        RET
; Decrements column C, checks maze cell bit $20 and high state bit; sets D=$C4 for collision/boundary state.

CHECK_MAZE_LEFT_BOUNDARY:
        XOR A
        DEC C
        RET M
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $20
        RET Z
        LD A,(HL)
        RLA
        RET NC
        LD D,$C4
        RET
; Decrements row B, checks maze cell bit $40 and high state bit; sets D=$C1 for collision/boundary state.

CHECK_MAZE_UP_BOUNDARY:
        DEC B
        RET M
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $40
        RET Z
        LD A,(HL)
        RLA
        RET NC
        LD D,$C1
        RET
; Increments column C, checks maze cell bit $20, and may set D=$C8.

CHECK_MAZE_RIGHT_BOUNDARY:
        CALL MAZE_CELL_ADDRESS
        INC C
        LD A,(HL)
        AND $20
        RET Z
        LD A,$18
        CP C
        RET Z
        INC HL
        LD A,(HL)
        RLA
        RET NC
        LD D,$C8
        RET
; Increments row B, checks maze cell bit $40, and may set D=$C2.

CHECK_MAZE_DOWN_BOUNDARY:
        CALL MAZE_CELL_ADDRESS
        INC B
        LD A,(HL)
        AND $40
        RET Z
        LD A,$1A
        CP B
        JP Z,$0B09
        LD DE,$0018
        ADD HL,DE
        LD A,(HL)
        RLA
        RET NC
; Sets D=$C2 and carry before returning.

SET_MAZE_DOWN_BOUNDARY_EVENT:
        LD D,$C2
        SCF
        RET
; Compares current column C against RAM $2024 when row B reaches $1A.

CHECK_MAZE_DOWN_PLAYER_LIMIT:
        LD A,($2024)
        CP C
        JP Z,$0B05
        XOR A
        RET

CMD_02_SET_MODE_0E:
        LD A,$0E
        JP $08EE

CMD_04_WRITE_DISPLAY_DATA:
        DI
        EX DE,HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        EX DE,HL
        LD (HL),B
        DEC HL
        LD (HL),C
        DEC HL
        EX DE,HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        LD A,(BC)
        CPL
        ADD A,$1A
        RLCA
        RLCA
        RLCA
        ADD A,$03
        LD (DE),A
        DEC DE
        LD C,$00
        CP $60
        JP NC,$0B3F
        LD C,$10

COPY_INLINE_GRAPHICS_BYTE:
        LD A,(HL)
        INC HL
        LD (DE),A
        DEC DE
        LD A,(HL)
        INC HL
        LD ($2000),HL
        OR C
        LD (DE),A
        RET

CMD_05_READ_PLAYER_INPUT:
        LD HL,$0006
        IN A,($01)
        AND $40
        JP Z,$0B57
        LD L,$04

NATIVE_0B57:
        LD ($202A),HL
        CPL
        LD ($202C),A
        RET

CMD_08_SET_COUNTER_200C:
        EX DE,HL
        LD A,(HL)
        INC HL
        LD ($2000),HL
        LD ($200C),A
        RET

CMD_09_SET_COUNTER_AND_POINTER:
        EX DE,HL
        LD A,(HL)
        LD ($200B),A
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD ($2000),HL
        EX DE,HL
        LD ($2008),HL
        RET
; Script record: target16. Replaces RAM $2000 with target address.

CMD_0B_GOTO_SCRIPT:
        EX DE,HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        LD ($2000),HL
        RET
; Script record: byte8, target16. RAM[target16] = byte8.
; Advances interpreter cursor $2000 by three bytes.

CMD_0C_STORE_IMMEDIATE_BYTE:
        EX DE,HL
        LD A,(HL)
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD ($2000),HL
        LD (DE),A
        RET
; Script record: byte8, pointer16, pointer16 (5 bytes).
; A = first byte, HL = first pointer, DE = second pointer on transfer
; to native drawing helper $0129. RAM $2000 advanced by five bytes.

CMD_07_DRAW_INLINE_RECORD:
        EX DE,HL
        LD A,(HL)
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        PUSH DE
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD ($2000),HL
        POP HL
        JP DRAW_TEXT_GLYPH_STREAM

CMD_0D_DECREMENT_GAME_STATE:
        LD DE,$2013
        LD A,(DE)
        DEC A
        CP $01
        RET Z
        LD (DE),A
        RET
; Read conditional script record, tested RAM byte, and target.
; Entry: DE = pointer to 4 inline bytes (test16, branch16).
; Exit: BC = test address; DE = branch address; HL = byte after record;
;       A = RAM[test]; Z flag indicates tested byte zero.

READ_CONDITION_RECORD:
        EX DE,HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD A,(BC)
        AND A
        RET
; BRANCH_IF_ZERO: choose script target for zero, fall-through cursor otherwise.
; Both paths update RAM $2000; XCHG selects target from DE on taken path.

CMD_0E_BRANCH_IF_ZERO:
        CALL READ_CONDITION_RECORD
        JP NZ,$0BC0
        EX DE,HL

BRANCH_IF_NONZERO_SET_SCRIPT:
        LD ($2000),HL
        RET
; BRANCH_IF_NONZERO: choose script target for nonzero, fall-through otherwise.
; Both paths update RAM $2000.

CMD_0F_BRANCH_IF_NONZERO:
        CALL READ_CONDITION_RECORD
        JP Z,$0BCB
        EX DE,HL

BRANCH_IF_ZERO_SET_SCRIPT:
        LD ($2000),HL
        RET

CMD_10_PROCESS_INLINE_RECORD:
        EX DE,HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD BC,$2036
        CALL FORMAT_PACKED_BYTE_AS_TWO_DIGITS
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD ($2000),HL
        LD HL,$2036
        CALL $058C
        LD A,$02
        JP DRAW_TEXT_GLYPH_STREAM
        DB $00,$00

; Game commands $01–$11 dispatch through these original native addresses.
NATIVE_COMMAND_VECTORS:
        DW CMD_01_RETURN_SCRIPT               ; $01
        DW CMD_02_SET_MODE_0E                 ; $02
        DW CMD_03_GAME_DISPLAY_UPDATE         ; $03
        DW CMD_04_WRITE_DISPLAY_DATA          ; $04
        DW CMD_05_READ_PLAYER_INPUT           ; $05
        DW CMD_06_INIT_GAME_FIELDS            ; $06
        DW CMD_07_DRAW_INLINE_RECORD          ; $07
        DW CMD_08_SET_COUNTER_200C            ; $08
        DW CMD_09_SET_COUNTER_AND_POINTER     ; $09
        DW CMD_0A_GAME_CONTROL                ; $0A
        DW CMD_0B_GOTO_SCRIPT                 ; $0B
        DW CMD_0C_STORE_IMMEDIATE_BYTE        ; $0C
        DW CMD_0D_DECREMENT_GAME_STATE        ; $0D
        DW CMD_0E_BRANCH_IF_ZERO              ; $0E
        DW CMD_0F_BRANCH_IF_NONZERO           ; $0F
        DW CMD_10_PROCESS_INLINE_RECORD       ; $10
        DW CMD_11_UPDATE_END_STATE            ; $11

; Original game message stream, glyph codes $40-$5A, positioning controls
; below $30. The renderer at DRAW_TEXT_GLYPH_STREAM consumes these bytes.

GAME_TEXT_STREAM:                ; $0C10-$0D32
; Native glyph codes use ASCII A–Z, $40 for a displayed blank, and
; control bytes below $30 for screen positioning. Quoted text emits
; the same character bytes as the original ROM.
        DB $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40  ; $0C10             
        DB $40,$40,$40,$40,$40,"THE",$40,"AMA"  ; $0C1C      THE AMA
        DB "ZINGMAZE",$40,"MAZ"  ; $0C28 ZINGMAZE MAZ
        DB "ES",$40,"WONSELECT"  ; $0C34 ES WONSELECT
        DB $19,"SINGLE",$40,"PLAY"  ; $0C40 ·SINGLE PLAY
        DB "ER",$18,"OR",$16,"TWO",$40,"PL"  ; $0C4C ER·OR·TWO PL
        DB "AYER",$18,$33,$40,"MAZES"  ; $0C58 AYER·· MAZES
        DB $40,"PER",$40,"GAMEINS"  ; $0C64  PER GAMEINS
        DB "ERT",$40,"COIN",$40,"QGE"  ; $0C70 ERT COIN QGE
        DB $54,$40,"READYPLAY",$40  ; $0C7C T READYPLAY 
        DB "AS",$40,"LONG",$40,"AS",$1B,$59  ; $0C88 AS LONG AS·Y
        DB "OU",$40,"WINMAZES",$40  ; $0C94 OU WINMAZES 
        DB "TO",$40,"PLAYSTUDY"  ; $0CA0 TO PLAYSTUDY
        DB $40,"TIMEP",$11,$4C,$11,$41,$11,$59  ; $0CAC  TIMEP·L·A·Y
        DB $11,$45,$11,"RO",$11,$4E,$11,"ET",$11,$57  ; $0CB8 ·E·RO·N·ET·W
        DB $11,$4F,$11,$57,$11,$49,$11,$4E,$11,$4E,$11,$45  ; $0CC4 ·O·W·I·N·N·E
        DB $11,$52,$40,$11,$40,$11,$40,$11,$40,$11,$40,$11  ; $0CD0 ·R · · · · ·
        DB $40,$11,$40,$11,$40,$11,$40,$11,$40,"KEE"  ; $0CDC  · · · · KEE
        DB $50,$40,"PLAYINGWAI"  ; $0CE8 P PLAYINGWAI
        DB "TPLAYER",$40,"WINS"  ; $0CF4 TPLAYER WINS
        DB "PLAYER",$40,"LOSES"  ; $0D00 PLAYER LOSES
        DB "PRESS",$40,"BUTTON"  ; $0D0C PRESS BUTTON
        DB $40,"TO",$1C,"START",$40,"GA"  ; $0D18  TO·START GA
        DB "ME",$40,"OVEROVERA"  ; $0D24 ME OVEROVERA
        DB "LL",$10  ; $0D30 LL·

; Small game indicators and directional bitmaps, eight pixels per byte.
; # = lit pixel; space = clear pixel. Original byte order preserved.

GAME_INDICATOR_BITMAPS:          ; $0D33-$0D63
; Original indicator and directional graphics: one 8-pixel row per byte.

        DB $38  ; ..###...
        DB $6C  ; .##.##..
        DB $38  ; ..###...
        DB $10  ; ...#....
        DB $7C  ; .#####..
        DB $44  ; .#...#..
        DB $54  ; .#.#.#..
        DB $44  ; .#...#..

        DB $7C  ; .#####..
        DB $00  ; ........
        DB $00  ; ........
        DB $10  ; ...#....
        DB $28  ; ..#.#...
        DB $10  ; ...#....
        DB $00  ; ........
        DB $00  ; ........

        DB $00  ; ........
        DB $80  ; #.......
        DB $80  ; #.......
        DB $80  ; #.......
        DB $80  ; #.......
        DB $80  ; #.......
        DB $80  ; #.......
        DB $80  ; #.......

        DB $80  ; #.......
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........
        DB $00  ; ........

        DB $FF  ; ########
        DB $18  ; ...##...
        DB $30  ; ..##....
        DB $60  ; .##.....
        DB $FE  ; #######.
        DB $60  ; .##.....
        DB $30  ; ..##....
        DB $18  ; ...##...

        DB $00  ; ........
        DB $00  ; ........
        DB $18  ; ...##...
        DB $0C  ; ....##..
        DB $06  ; .....##.
        DB $7F  ; .#######
        DB $06  ; .....##.
        DB $0C  ; ....##..

        DB $18  ; ...##...

; Game program: interpreted 8080 command stream beginning at $0D64.
; $0C stores one immediate byte to RAM; $09 supplies a byte and word;
; $07 draws from a five-byte inline record; $0B changes script address.
; DB encodes command numbers and byte operands, DW encodes little-endian
; word operands. The other records below retain their original ordering.
INITIAL_GAME_SCRIPT:

; Startup: clear four work-RAM bytes.
        DB $0C,$00              ; STORE_IMMEDIATE_BYTE: [$202C] = $00
        DW $202C
        DB $0C,$00              ; STORE_IMMEDIATE_BYTE: [$2031] = $00
        DW $2031
        DB $0C,$00              ; STORE_IMMEDIATE_BYTE: [$2032] = $00
        DW $2032
        DB $0C,$00              ; STORE_IMMEDIATE_BYTE: [$202D] = $00
        DW $202D

; Initialize game state and establish the first display record.
        DB $11                  ; UPDATE_END_STATE
        DB $09,$0A              ; SET_COUNTER_AND_POINTER, count $0A
        DW $0D94                ; saved command/data pointer
        DB $07,$10              ; DRAW_INLINE_RECORD, count $10
        DW $0C10                ; encoded text source
        DW $2408                ; video RAM destination

; Remaining original game program bytes from $0D7F onward.
; Command bytes and inline parameters share this stream; the verified
; native handlers determine each packet's length and next script address.
        DB $07,$09,$22,$0D,$0B,$24,$08,$1E  ; $0D7F
        DB $00,$07,$09,$10,$0C,$0B,$24,$08  ; $0D87
        DB $1E,$00,$0B,$7F,$0D,$02,$09,$0A  ; $0D8F
        DB $D5,$0D,$07,$03,$21,$0C,$0A,$2C  ; $0D97
        DB $08,$0F,$00,$07,$0B,$21,$0C,$0A  ; $0D9F
        DB $2C,$08,$0F,$00,$07,$04,$2C,$0C  ; $0DA7
        DB $0B,$32,$08,$0F,$00,$07,$04,$22  ; $0DAF
        DB $0D,$10,$32,$08,$3C,$00,$07,$0B  ; $0DB7
        DB $10,$0C,$0A,$2C,$07,$09,$10,$0C  ; $0DBF
        DB $0B,$32,$07,$0D,$6D,$0C,$09,$3A  ; $0DC7
        DB $08,$0F,$00,$0B,$99,$0D,$02,$07  ; $0DCF
        DB $0D,$6D,$0C,$09,$3A,$07,$19,$41  ; $0DD7
        DB $0C,$0A,$2A,$09,$08,$FB,$0D,$07  ; $0DDF
        DB $10,$5D,$0C,$08,$36,$08,$1E,$00  ; $0DE7
        DB $07,$01,$10,$0C,$08,$36,$08,$1E  ; $0DEF
        DB $00,$0B,$E6,$0D,$02,$07,$1F,$3A  ; $0DF7
        DB $0C,$0C,$2A,$09,$08,$1B,$0E,$07  ; $0DFF
        DB $0D,$6D,$0C,$09,$3A,$08,$14,$00  ; $0E07
        DB $07,$01,$10,$0C,$15,$3A,$08,$14  ; $0E0F
        DB $00,$0B,$06,$0E,$02,$06,$03,$08  ; $0E17
        DB $F0,$00,$0A,$09,$04,$94,$0D,$00  ; $0E1F
        DB $02,$07,$19,$0C,$0D,$08,$28,$07  ; $0E27
        DB $0D,$41,$0C,$09,$34,$07,$0A,$52  ; $0E2F
        DB $0C,$0B,$38,$0C,$01,$34,$20,$07  ; $0E37
        DB $01,$10,$0C,$17,$34,$07,$01,$79  ; $0E3F
        DB $0C,$09,$38,$08,$1E,$00,$07,$01  ; $0E47
        DB $79,$0C,$17,$34,$07,$01,$10,$0C  ; $0E4F
        DB $09,$38,$08,$1E,$00,$0B,$3E,$0E  ; $0E57
        DB $02,$0C,$04,$13,$20,$07,$0D,$41  ; $0E5F
        DB $0C,$09,$2C,$07,$07,$5D,$0C,$0C  ; $0E67
        DB $30,$07,$02,$4F,$0C,$0F,$32,$07  ; $0E6F
        DB $16,$83,$0C,$08,$34,$08,$F0,$00  ; $0E77
        DB $0B,$A6,$0E,$0F,$2E,$20,$8C,$0E  ; $0E7F
        DB $0F,$32,$20,$64,$0D,$02,$09,$02  ; $0E87
        DB $A6,$0E,$07,$09,$7A,$0C,$0B,$32  ; $0E8F
        DB $08,$1E,$00,$07,$09,$10,$0C,$0B  ; $0E97
        DB $32,$08,$0F,$00,$0B,$91,$0E,$02  ; $0E9F
        DB $06,$03,$07,$0A,$A7,$0C,$A0,$3E  ; $0EA7
        DB $0F,$2E,$20,$C1,$0E,$07,$0C,$E5  ; $0EAF
        DB $0C,$08,$24,$0C,$01,$2E,$20,$0B  ; $0EB7
        DB $CC,$0E,$07,$0D,$9A,$0C,$08,$24  ; $0EBF
        DB $10,$2E,$20,$16,$24,$07,$09,$31  ; $0EC7
        DB $0C,$B1,$3E,$10,$31,$20,$BB,$3E  ; $0ECF
        DB $04,$48,$20,$32,$0D,$26,$20,$17  ; $0ED7
        DB $C2,$04,$59,$20,$37,$0D,$24,$20  ; $0EDF
        DB $E0,$C0,$0C,$06,$0E,$20,$0C,$06  ; $0EE7
        DB $29,$20,$00,$09,$04,$82,$0E,$07  ; $0EEF
        DB $10,$10,$0C,$08,$24,$10,$31,$20  ; $0EF7
        DB $BB,$3E,$0E,$1A,$20,$1C,$0F,$0D  ; $0EFF
        DB $07,$0B,$F5,$0C,$08,$24,$08,$1E  ; $0F07
        DB $00,$07,$0B,$10,$0C,$08,$24,$08  ; $0F0F
        DB $1E,$00,$0B,$07,$0F,$07,$0C,$00  ; $0F17
        DB $0D,$08,$24,$08,$1E,$00,$07,$0C  ; $0F1F
        DB $10,$0C,$08,$24,$08,$1E,$00,$0B  ; $0F27
        DB $1C,$0F,$02,$05,$07,$0A,$52,$0C  ; $0F2F
        DB $0B,$2C,$07,$07,$5D,$0C,$0C,$30  ; $0F37
        DB $08,$B4,$00,$0B,$64,$0F,$0E,$2E  ; $0F3F
        DB $20,$64,$0D,$02,$09,$02,$64,$0F  ; $0F47
        DB $07,$09,$7A,$0C,$0B,$32,$08,$1E  ; $0F4F
        DB $00,$07,$09,$10,$0C,$0B,$32,$08  ; $0F57
        DB $1E,$00,$0B,$4F,$0F,$02,$06,$03  ; $0F5F
        DB $07,$06,$B1,$0C,$01,$26,$07,$03  ; $0F67
        DB $C1,$0C,$E1,$34,$10,$32,$20,$00  ; $0F6F
        DB $3C,$07,$06,$B1,$0C,$1E,$26,$07  ; $0F77
        DB $03,$BC,$0C,$FE,$34,$10,$31,$20  ; $0F7F
        DB $1D,$3C,$07,$0D,$9A,$0C,$08,$24  ; $0F87
        DB $10,$2E,$20,$16,$24,$07,$04,$AD  ; $0F8F
        DB $0C,$A3,$3E,$07,$07,$2B,$0D,$B1  ; $0F97
        DB $3E,$04,$48,$20,$37,$0D,$26,$20  ; $0F9F
        DB $17,$C0,$04,$59,$20,$32,$0D,$24  ; $0FA7
        DB $20,$E0,$C0,$0C,$01,$0D,$20,$0C  ; $0FAF
        DB $01,$20,$20,$00,$10,$2E,$20,$16  ; $0FB7
        DB $24,$09,$04,$45,$0F,$0E,$1B,$20  ; $0FBF
        DB $E3,$0F,$10,$32,$20,$00,$3C,$07  ; $0FC7
        DB $0A,$D2,$0C,$01,$26,$08,$1E,$00  ; $0FCF
        DB $07,$06,$C7,$0C,$01,$26,$08,$1E  ; $0FD7
        DB $00,$0B,$CE,$0F,$10,$31,$20,$1D  ; $0FDF
        DB $3C,$07,$0A,$D2,$0C,$1E,$26,$08  ; $0FE7
        DB $1E,$00,$07,$06,$C7,$0C,$1E,$26  ; $0FEF
        DB $08,$1E,$00,$0B,$E8,$0F,$00,$00  ; $0FF7
        DB $00  ; $0FFF
        END
