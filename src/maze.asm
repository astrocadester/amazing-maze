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
        JP RESET_START

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
        JP INITIALIZE_FRAME_STATE
; Read input port 1; carry controls transition into initial script setup.

; Startup diagnostics, ROM checksums and program initialization.
RESET_START:
        IN A,($01)
        RLA
        JP NC,INIT_SCRIPT_ROOT
        LD B,$01
        LD DE,$0000

; Point HL to the beginning of the board RAM test area.
DIAG_RAM_BEGIN:
        LD HL,$2000

DIAG_RAM_WRITE_AND_COMPARE:
        OUT ($02),A
        LD (HL),B
        LD A,(HL)
        XOR B
        JP Z,DIAG_RAM_ADVANCE
        LD C,A
        LD A,L
        AND $01
        LD A,C
        JP NZ,DIAG_RECORD_ODD_ERROR
        OR D
        LD D,A
        JP DIAG_RAM_ADVANCE

; Merge odd-address RAM test mismatches into E.
DIAG_RECORD_ODD_ERROR:
        OR E
        LD E,A

; Advance to the next RAM byte until H reaches $40.
DIAG_RAM_ADVANCE:
        INC HL
        LD A,H
        CP $40
        JP NZ,DIAG_RAM_WRITE_AND_COMPARE

; Scan the test area backward and compare saved pattern bytes.
DIAG_RAM_REVERSE_SCAN:
        OUT ($02),A
        DEC HL
        LD A,H
        CP $1F
        JP Z,DIAG_RAM_FINAL_SCAN
        LD A,(HL)
        XOR B
        JP Z,DIAG_RAM_TEST_COMPLEMENT
        LD C,A
        LD A,L
        AND $01
        LD A,C
        JP NZ,DIAG_RECORD_REVERSE_ODD_ERROR
        OR D
        LD D,A
        JP DIAG_RAM_TEST_COMPLEMENT

; Accumulate reverse-scan mismatches from odd RAM addresses.
DIAG_RECORD_REVERSE_ODD_ERROR:
        OR E
        LD E,A

; Write and verify the complemented RAM pattern.
DIAG_RAM_TEST_COMPLEMENT:
        LD A,B
        CPL
        LD (HL),A
        XOR (HL)
        JP Z,DIAG_RAM_REVERSE_SCAN
        LD C,A
        LD A,L
        AND $01
        LD A,C
        JP NZ,DIAG_RECORD_COMPLEMENT_ODD_ERROR
        OR D
        LD D,A
        JP DIAG_RAM_REVERSE_NEXT

; Accumulate complemented-pattern errors in E.
DIAG_RECORD_COMPLEMENT_ODD_ERROR:
        OR E
        LD E,A

; Continue the descending RAM sweep.
DIAG_RAM_REVERSE_NEXT:
        JP DIAG_RAM_REVERSE_SCAN

DIAG_RAM_FINAL_SCAN:
        OUT ($02),A
        INC HL
        LD A,H
        CP $40
        JP Z,DIAG_EVALUATE_RAM_ERRORS
        LD A,B
        CPL
        XOR (HL)
        JP Z,DIAG_RAM_CLEAR_NEXT
        LD C,A
        LD A,L
        AND $01
        LD A,C
        JP NZ,DIAG_RECORD_FINAL_ODD_ERROR
        OR D
        LD D,A
        JP DIAG_RAM_CLEAR_NEXT

; Accumulate the final odd-address error bits.
DIAG_RECORD_FINAL_ODD_ERROR:
        OR E
        LD E,A

; Clear a tested RAM byte and continue the final scan.
DIAG_RAM_CLEAR_NEXT:
        XOR A
        LD (HL),A
        JP DIAG_RAM_FINAL_SCAN

; Rotate the RAM test pattern and examine accumulated error bits.
DIAG_EVALUATE_RAM_ERRORS:
        LD A,B
        RLCA
        LD B,A
        JP NC,DIAG_RAM_BEGIN
        LD A,D
        OR E
        JP Z,CHECK_ROM_PAGE_SUMS
        EX DE,HL
        LD SP,HL
        LD DE,$2000
        LD B,$00

; Initialize one diagnostic display row from saved error bits.
DIAG_ERROR_DISPLAY_ROW:
        LD HL,$0000
        ADD HL,SP
        LD C,$10

; Shift the failing-bit mask and choose its video pixel value.
DIAG_ERROR_DISPLAY_PIXEL:
        XOR A
        ADD HL,HL
        JP C,DIAG_ERROR_WRITE_PIXEL
        CPL

; Write the diagnostic pixel pair into video RAM.
DIAG_ERROR_WRITE_PIXEL:
        LD (DE),A
        INC DE
        XOR A
        LD (DE),A
        INC DE
        DEC C
        JP NZ,DIAG_ERROR_DISPLAY_PIXEL
        DEC B
        JP NZ,DIAG_ERROR_DISPLAY_ROW
; Repeatedly writes to hardware output port $02.

SERVICE_HALTED_OUTPUT_LOOP:
        OUT ($02),A
        JP SERVICE_HALTED_OUTPUT_LOOP
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
        JP NZ,ACCUMULATE_ROM_CHECKSUM
        PUSH HL
        LD HL,$0120
        ADD HL,DE
        CP (HL)
        LD A,$40
        JP Z,STORE_ROM_CHECK_RESULT
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
        JP NZ,BEGIN_ROM_CHECKSUM_PAGE
        LD HL,$2039
        LD A,(HL)
        DEC HL
        OR (HL)
        DEC HL
        OR (HL)
        DEC HL
        OR (HL)
        AND $BF
        JP Z,RESET
        LD DE,$3008
        LD A,$04
        CALL DRAW_TEXT_GLYPH_STREAM

; Hold the failing ROM diagnostic output on port $02.
DIAG_ROM_FAILURE_LOOP:
        OUT ($02),A
        JP DIAG_ROM_FAILURE_LOOP
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
        JP P,TEXT_DECODE_FONT_INDEX
        LD B,A
; Advances the framebuffer destination for text-position control codes.

ADVANCE_ENCODED_TEXT_POSITION:
        INC DE
        LD A,E
        AND $1F
        JP NZ,TEXT_POSITION_CONTROL_LOOP
        INC D
        INC D

; Repeat the encoded cursor-advance operation for its count.
TEXT_POSITION_CONTROL_LOOP:
        INC B
        JP NZ,ADVANCE_ENCODED_TEXT_POSITION
        JP TEXT_FETCH_NEXT_CODE

; Save text pointers and convert a character code into a glyph index.
TEXT_DECODE_FONT_INDEX:
        PUSH HL
        PUSH DE
        INC A
        CP $0B
        JP M,SELECT_FONT_GLYPH
        SUB $06
; Converts glyph index into ten-byte ROM font offset.

SELECT_FONT_GLYPH:
        LD HL,$0166
        LD BC,$000A
; Steps ten bytes per font index.

ADVANCE_FONT_TO_GLYPH:
        ADD HL,BC
        DEC A
        JP NZ,ADVANCE_FONT_TO_GLYPH
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
        JP NZ,WRITE_NEXT_GLYPH_ROW
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

; Clear working state and invoke timer and input services
INITIALIZE_FRAME_STATE:
        XOR A
        CALL CHECK_FRAME_MODE_OR_INTERRUPT_EXIT
        LD (HL),A
        CALL SAMPLE_GAME_TIMING_STATE
        CALL PERIODIC_TIMER_SERVICE
        LD HL,$2055
        CALL TEST_SIGNED_STATE_AND_COPY_POINTER
        CALL SERVICE_GAME_STATE_COUNTER
        CALL READ_STABLE_PORT0_INPUT
        CALL UPDATE_MAZE_STATE_IF_IDLE
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
        CALL CHECK_FRAME_MODE_OR_INTERRUPT_EXIT
        LD (HL),A
        CALL SAMPLE_GAME_TIMING_STATE
        CALL SAMPLE_PORT1_INPUT_EDGE
        CALL READ_START_INPUTS
        LD A,($2030)
        DEC A
        JP NZ,UPDATE_FRAME_POSITION_STATE
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
        CALL TEST_SIGNED_STATE_AND_COPY_POINTER
        JP RESTORE_INTERRUPT_REGISTERS

; Read game timer state and process the periodic counter path.
PERIODIC_TIMER_SERVICE:
        LD HL,$2035
        LD A,(HL)
        AND A
        RET NZ
        LD B,A
        LD HL,$200A
        DEC (HL)
        JP NZ,RECORD_TIMER_EVENT_BITS
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

; Check a timer value before decrementing the selected RAM byte.
TIMER_DECREMENT:
        LD A,(HL)
        AND A
        JP Z,FINISH_TIMER_BYTE_TEST
        DEC (HL)
        JP NZ,FINISH_TIMER_BYTE_TEST
        SCF
; Returns after advancing the periodic countdown and carry-driven event mask.

FINISH_TIMER_BYTE_TEST:
        LD A,B
        RLA
        LD B,A
        RET

; Initialize the first command-script root pointer at $0D64.
INIT_SCRIPT_ROOT:
        LD A,$10
        CALL ENTER_NATIVE_PROGRAM_STATE
        LD HL,$0D64
        LD ($2002),HL
        LD HL,$FFFF
        LD ($2004),HL
        LD ($2006),HL
        EI
        LD HL,$038B
        PUSH HL
        OUT ($02),A

; Load the saved script root, initialize cursors and clear script state.
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

; Read the next command through the script cursor at RAM $2000.
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

; Process command $00 through the event-control path.
ZERO_COMMAND:
        LD A,($201F)
        AND A
        CALL Z,ZERO_COMMAND_EVENT
        RET
        DB $00,$00

; Clear selected maze state and reset the event counter.
ZERO_COMMAND_EVENT:
        CALL CLEAR_MAZE_CELL_LOW_NIBBLES
        XOR A
        LD ($201C),A
        CALL MAZE_RECALCULATE_RANDOM_STATE
        CALL SELECT_MAZE_RANDOM_VALUE
; Runs maze-step and output-port service until event state E is zero.

RUN_ZERO_COMMAND_MAZE_EVENTS:
        CALL MAZE_INSPECT_NEIGHBOR_WALLS
        OUT ($02),A
        LD A,E
        AND A
        JP Z,TEST_MAZE_EVENT_COMPLETION
        CALL ADVANCE_MAZE_GENERATION_COUNT
        JP RUN_ZERO_COMMAND_MAZE_EVENTS
; Checks $201D and invokes $080D; increments $201F when the event is complete.

TEST_MAZE_EVENT_COMPLETION:
        LD A,($201D)
        AND A
        JP Z,ZERO_COMMAND_EVENT
        CALL MAZE_ADVANCE_COLUMN
        JP C,RUN_ZERO_COMMAND_MAZE_EVENTS
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
        JP NZ,CLEAR_MAZE_CELL_NIBBLE
        DEC B
        JP NZ,CLEAR_NEXT_MAZE_ROW_NIBBLES
        RET
        DB $C9

; Initialize maze and game RAM fields used by the command stream.
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
        JP NZ,CLEAR_NEXT_GAME_STATE_BYTE
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
        JP NZ,SHIFT_NEXT_MAZE_CELL_NIBBLE
        DEC B
        JP NZ,SHIFT_NEXT_MAZE_CELL_NIBBLE
        RET

; Exit when the activity byte at $201E is set
UPDATE_MAZE_STATE_IF_IDLE:
        LD A,($201E)
        AND A
        RET NZ
        LD B,$01
        LD HL,$2045
        LD DE,$2056
        LD A,(DE)
        SUB $10
        JP Z,COPY_STATE_BYTE_TO_NEIGHBORS
        INC B
        LD A,(HL)
        SUB $E6
        RET NZ

; Store a selected state byte in neighboring addresses
COPY_STATE_BYTE_TO_NEIGHBORS:
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
        JP Z,INCREMENT_PACKED_DECIMAL_STATE
        INC DE
        INC HL

; Increment a state byte using BCD decimal adjustment
INCREMENT_PACKED_DECIMAL_STATE:
        LD A,(HL)
        INC A
        DAA
        LD (HL),A
        LD (DE),A
        LD HL,$202E
        LD A,(HL)
        ADD A,$99
        DAA
        JP M,CMD_0A_GAME_CONTROL
        LD (HL),A
        JP CMD_0A_GAME_CONTROL
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

; Return to the interpreter continuation on the 8080 stack.
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
        CALL C,ADVANCE_END_OF_ROUND_COUNTER
        POP AF
        RRA
        PUSH AF
        CALL C,UPDATE_ROUND_COUNTER_AND_SCORE
        POP AF
        RRA
        CALL C,SKIP_NEXT_SCRIPT_BYTE
        RRA
        CALL C,RESTORE_SCRIPT_ROOT_FROM_SAVED_POINTER
        RET

; Decrement the round counter and select a follow-on display path
ADVANCE_END_OF_ROUND_COUNTER:
        LD HL,$2029
        DEC (HL)
        JP NZ,SETUP_NEXT_ROUND_DISPLAY
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

; Reload the frame countdown and update display state
SETUP_NEXT_ROUND_DISPLAY:
        LD A,$3C
        LD ($200E),A
        LD A,(HL)
        OR $30
        LD HL,$2036
        LD (HL),A
        LD A,$01
        LD DE,$3EAB
        JP DRAW_TEXT_GLYPH_STREAM

; Reload a countdown and select the score update path
UPDATE_ROUND_COUNTER_AND_SCORE:
        LD A,$3C
        LD ($200D),A
        LD A,($202C)
        AND A
        JP Z,INCREMENT_PACKED_SCORE
        LD HL,$202B
        LD A,(HL)
        ADD A,$99
        DAA
        LD (HL),A
        JP P,DISPLAY_SCORE_AND_INCREMENT
        LD (HL),$59
        DEC HL
        DEC (HL)
        JP P,DISPLAY_SCORE_AND_INCREMENT
        LD HL,$0D64
        LD ($2002),HL
        LD HL,$200B
        LD B,$05
        XOR A

; Clear five consecutive state bytes through HL.
CLEAR_FIVE_STATE_BYTES:
        LD (HL),A
        INC HL
        DEC B
        JP NZ,CLEAR_FIVE_STATE_BYTES
        LD ($2044),A
        LD ($2055),A
        RET

; Draw the packed score field and advance score state.
DISPLAY_SCORE_AND_INCREMENT:
        LD HL,$3EB8
        LD DE,$202A
        CALL DISPLAY_PACKED_SCORE_FIELD

; Increment the packed decimal score stored at $2019.
INCREMENT_PACKED_SCORE:
        LD HL,$2019
        LD A,(HL)
        INC A
        DAA
        LD (HL),A
        CP $60
        JP NZ,DISPLAY_SCORE_FROM_GAME_STATE
        LD (HL),$00
        DEC HL
        LD A,(HL)
        INC A
        DAA
        LD (HL),A

; Select a score display source and destination.
DISPLAY_SCORE_FROM_GAME_STATE:
        LD HL,$3EA8
        LD DE,$2018

; Format a packed value into the display work buffer.
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
        CALL NORMALIZE_DISPLAY_GLYPH_SPACE
        INC HL
        CALL NORMALIZE_DISPLAY_GLYPH_SPACE
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
        JP Z,RETURN_IF_END_FLAG_SET
        INC (HL)
        LD A,C
        AND $10
        JP Z,RETURN_IF_END_FLAG_SET
        INC (HL)

; Exit when the end-state flag at $202D is set
RETURN_IF_END_FLAG_SET:
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

; Draw the stored end-screen text at its display destination
DRAW_END_SCREEN_MESSAGE:
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
        JP NZ,STORE_START_SELECTION_STATE
        LD HL,$0F31
        LD A,B
        AND $02
        LD A,$02
        RET Z

; Save start state and script cursor and clear an output byte
STORE_START_SELECTION_STATE:
        LD ($2030),A
        LD ($2002),HL
        XOR A
        LD (DE),A
        RET
; Native frame-time hardware state update.

SAMPLE_GAME_TIMING_STATE:
        LD HL,$2044
        PUSH HL
        CALL TEST_CELL_STATE_BIT_20
        LD HL,$2055
        PUSH HL
        CALL TEST_CELL_STATE_BIT_20
        POP HL
        CALL TEST_CELL_STATE_BIT_10
        POP HL
        JP TEST_CELL_STATE_BIT_10
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

; Compare the $10 bit in the selected cell state
TEST_CELL_STATE_BIT_10:
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
        JP NZ,COPY_CELL_STATE_AND_ADVANCE
        LD B,$00

; Write the current cell state, load the next address and continue
COPY_CELL_STATE_AND_ADVANCE:
        LD (HL),B
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD A,E
        AND $07
        LD ($2015),A
        CALL INITIALIZE_THREE_STEP_SHIFT
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

; Copy one cell-record byte from HL to DE and advance both.
COPY_CELL_RECORD_LOOP:
        PUSH AF
        LD A,(HL)
        LD (DE),A
        INC DE
        LD A,(BC)
        INC BC
        CALL UPDATE_PACKED_MAZE_COORDINATE
        OR (HL)
        LD (HL),A
        INC HL
        LD A,(HL)
        LD (DE),A
        INC DE
        XOR A
        CALL UPDATE_PACKED_MAZE_COORDINATE
        OR (HL)
        LD (HL),A
        PUSH DE
        LD DE,$001F
        ADD HL,DE
        POP DE
        POP AF
        DEC A
        JP NZ,COPY_CELL_RECORD_LOOP
        RET

; Update the packed coordinate held at $2016
UPDATE_PACKED_MAZE_COORDINATE:
        PUSH HL
        LD HL,($2016)
        LD L,H
        LD H,A
        LD ($2016),HL
        LD A,($2015)
        AND A
        JP Z,FINISH_COORDINATE_SHIFT

; Double the row offset in HL until its count reaches zero.
SHIFT_COORDINATE_TO_ROW_OFFSET:
        ADD HL,HL
        DEC A
        JP NZ,SHIFT_COORDINATE_TO_ROW_OFFSET

; Return the shifted coordinate result in A
FINISH_COORDINATE_SHIFT:
        LD A,H
        POP HL
        RET

; Compare cell-state bits and test the $20 flag
TEST_CELL_STATE_BIT_20:
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

; Copy the next cell-state byte and advance source/destination.
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
        JP NZ,COPY_MAZE_CELL_RECORD_BYTE
        RET

; Set the three-step packed-coordinate shift count
INITIALIZE_THREE_STEP_SHIFT:
        LD B,$03

; Rotate the D/E coordinate pair one bit right
SHIFT_PACKED_COORDINATE_PAIR:
        XOR A
        LD A,D
        RRA
        LD D,A
        LD A,E
        RRA
        LD E,A
        DEC B
        JP NZ,SHIFT_PACKED_COORDINATE_PAIR
        LD A,D
        ADD A,$24
        LD D,A
        RET

; Load the frame count and update the random-related state.
MAZE_RECALCULATE_RANDOM_STATE:
        LD A,($200A)

MAZE_RANDOM_UPDATE_LOOP:
        PUSH AF
        CALL READ_GAME_RANDOM_STATE
        POP AF
        DEC A
        JP NZ,MAZE_RANDOM_UPDATE_LOOP
        RET

; Derive a bounded value and store it in game state
SELECT_MAZE_RANDOM_VALUE:
        LD E,$18
        CALL SAMPLE_RANDOM_RANGE
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

; Build direction flags from surrounding maze-cell boundaries.
MAZE_INSPECT_NEIGHBOR_WALLS:
        LD D,$00
        LD A,B
        CP $00
        JP Z,MAZE_CHECK_ROW_LIMIT
        DEC B
        CALL MAZE_CELL_ADDRESS
        INC B
        LD A,(HL)
        RRCA
        JP C,MAZE_CHECK_ROW_LIMIT
        LD A,D
        OR $01
        LD D,A

; Test the lower and upper row boundaries before inspecting cells.
MAZE_CHECK_ROW_LIMIT:
        LD A,$19
        CP B
        JP NZ,MAZE_TEST_NEXT_ROW_WALL
        LD A,($201D)
        OR A
        JP NZ,MAZE_CHECK_LEFT_COLUMN
        LD A,($201C)
        CP $46
        JP C,MAZE_CHECK_LEFT_COLUMN
        JP MAZE_FLAG_ROW_WALL

; Read the next row's wall bits and restore the row index.
MAZE_TEST_NEXT_ROW_WALL:
        INC B
        CALL MAZE_CELL_ADDRESS
        DEC B
        LD A,(HL)
        RRCA
        JP C,MAZE_CHECK_LEFT_COLUMN

; Mark the row-wall direction bit in D.
MAZE_FLAG_ROW_WALL:
        LD A,D
        OR $02
        LD D,A

; Test the left column boundary and adjacent maze cell.
MAZE_CHECK_LEFT_COLUMN:
        LD A,C
        CP $00
        JP Z,MAZE_CHECK_RIGHT_COLUMN
        DEC C
        CALL MAZE_CELL_ADDRESS
        INC C
        LD A,(HL)
        RRCA
        JP C,MAZE_CHECK_RIGHT_COLUMN
        LD A,D
        OR $04
        LD D,A

; Test the right column boundary and adjacent maze cell.
MAZE_CHECK_RIGHT_COLUMN:
        LD A,$17
        CP C
        JP Z,MAZE_COUNT_DIRECTION_FLAGS
        INC C
        CALL MAZE_CELL_ADDRESS
        DEC C
        LD A,(HL)
        RRCA
        JP C,MAZE_COUNT_DIRECTION_FLAGS
        LD A,D
        OR $08
        LD D,A

; Count available direction flags from the mask in D.
MAZE_COUNT_DIRECTION_FLAGS:
        LD E,$00
        LD A,D
        OR A

; Shift one direction bit into carry and increment the count if set.
COUNT_OPEN_DIRECTIONS_LOOP:
        RRA
        JP NC,COUNT_OPEN_DIRECTIONS_NEXT
        INC E

; Continue until the direction mask is exhausted.
COUNT_OPEN_DIRECTIONS_NEXT:
        OR A
        JP NZ,COUNT_OPEN_DIRECTIONS_LOOP
        RET

; Update the maze-generation counter at $201C
ADVANCE_MAZE_GENERATION_COUNT:
        LD A,($201D)
        AND A
        JP NZ,CHOOSE_MAZE_DIRECTION
        LD HL,$201C
        INC (HL)

; Select a direction value through the random-range routine
CHOOSE_MAZE_DIRECTION:
        LD A,$01
        LD ($2022),A
        CALL SAMPLE_RANDOM_RANGE
        LD E,A
        LD A,D
        INC E
        DEC E
        RRCA
        JP NC,TEST_DIRECTION_BIT_ZERO
        JP Z,MARK_MAZE_PREVIOUS_ROW
        DEC E

; Rotate and test a candidate direction bit
TEST_DIRECTION_BIT_ZERO:
        RRCA
        JP NC,TEST_DIRECTION_BIT_ONE
        JP Z,MARK_MAZE_NEXT_ROW
        DEC E

; Rotate and test the following candidate direction bit
TEST_DIRECTION_BIT_ONE:
        RRCA
        JP NC,MARK_MAZE_NEXT_COLUMN
        JP Z,MARK_MAZE_PREVIOUS_COLUMN
        JP MARK_MAZE_NEXT_COLUMN

; Address the previous row and select wall state $05
MARK_MAZE_PREVIOUS_ROW:
        DEC B
        CALL MAZE_CELL_ADDRESS
        LD D,$05
        JP WRITE_MAZE_DIRECTION_BITS

; Mark the current cell and advance the maze row
MARK_MAZE_NEXT_ROW:
        CALL MAZE_CELL_ADDRESS
        LD D,$04
        CALL WRITE_MAZE_DIRECTION_BITS
        LD A,$19
        CP B
        JP Z,SAVE_MAZE_COLUMN_AND_DIRECTION
        INC B
        CALL MAZE_CELL_ADDRESS
        LD D,$01
        JP WRITE_MAZE_DIRECTION_BITS

; Save the current column and direction state
SAVE_MAZE_COLUMN_AND_DIRECTION:
        LD A,($201D)
        AND A
        JP NZ,RESTORE_MAZE_COLUMN
        LD A,$08
        LD ($201D),A
        LD A,C
        LD ($2023),A

; Restore the saved maze column into C
RESTORE_MAZE_COLUMN:
        LD B,$19
        LD A,($2023)
        LD C,A
        RET

; Address the previous column and select wall state $03
MARK_MAZE_PREVIOUS_COLUMN:
        DEC C
        CALL MAZE_CELL_ADDRESS
        LD D,$03
        JP WRITE_MAZE_DIRECTION_BITS
        DB $00,$00

; Address the current and next columns and update wall state
MARK_MAZE_NEXT_COLUMN:
        CALL MAZE_CELL_ADDRESS
        LD D,$02
        CALL WRITE_MAZE_DIRECTION_BITS
        INC C
        CALL MAZE_CELL_ADDRESS
        LD D,$01
        JP WRITE_MAZE_DIRECTION_BITS

; Combine direction flags with the selected maze cell
WRITE_MAZE_DIRECTION_BITS:
        LD A,($201D)
        XOR $08
        OR (HL)
        OR D
        LD (HL),A
        RET

; Advance the column until the display-row limit.
MAZE_ADVANCE_COLUMN:
        INC C
        LD A,$18
        CP C
        JP Z,MAZE_ADVANCE_ROW

; Read current cell bits and test the next column's boundary.
MAZE_CHECK_COLUMN_BOUNDARY:
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        RRCA
        JP NC,MAZE_ADVANCE_COLUMN
        RET

; Reset column C and advance the row index B.
MAZE_ADVANCE_ROW:
        LD C,$00
        INC B
        LD A,$1A
        CP B
        JP NZ,MAZE_CHECK_COLUMN_BOUNDARY
        LD B,$00
        LD A,($2022)
        OR A
        RET Z
        LD A,$00
        LD ($2022),A
        JP MAZE_CHECK_COLUMN_BOUNDARY

; Read game display state and select native maze drawing paths.
CMD_03_GAME_DISPLAY_UPDATE:
        LD HL,$3E02
        LD D,$00

; Select graphics for the current maze border row
DRAW_MAZE_BORDER_ROW:
        LD A,($2026)
        LD BC,$0D44
        CP D
        JP NZ,ADVANCE_MAZE_BORDER_ROW
        CALL DRAW_MAZE_BORDER_TILE
        LD BC,$01D4

; Draw the row graphic and advance the maze row index
ADVANCE_MAZE_BORDER_ROW:
        CALL DRAW_MAZE_TILE
        INC D
        LD A,$18
        CP D
        JP NZ,DRAW_MAZE_BORDER_ROW
        LD HL,$3E23
        LD DE,$2066
        LD B,$1A

; Write a display byte and step through the bitmap column
DRAW_MAZE_CELL_COLUMN:
        LD C,$18
        PUSH HL
        PUSH BC
        LD (HL),$FF
        LD BC,$FFE0
        ADD HL,BC
        POP BC

; Choose a tile according to the $40 cell-state bit
CHOOSE_MAZE_CELL_TILE:
        PUSH BC
        LD A,(DE)
        LD BC,$0D44
        AND $40
        JP Z,DRAW_MAZE_CELL_SIDE
        LD BC,$01D4

; Draw a tile and test the next cell's $20 flag
DRAW_MAZE_CELL_SIDE:
        PUSH HL
        CALL DRAW_MAZE_TILE
        POP HL
        LD A,(DE)
        INC DE
        LD BC,$0D4C
        AND $20
        JP Z,ADVANCE_MAZE_DRAW_CURSOR
        LD BC,$01D4

; Advance the cell loop and row display pointer
ADVANCE_MAZE_DRAW_CURSOR:
        CALL DRAW_MAZE_TILE
        POP BC
        DEC C
        JP NZ,CHOOSE_MAZE_CELL_TILE
        POP HL
        INC HL
        DEC B
        JP NZ,DRAW_MAZE_CELL_COLUMN
        LD A,($2024)
        INC H

; Step through display rows before selecting a tile
ADVANCE_MAZE_FRAMEBUFFER_ROW:
        DEC H
        DEC A
        JP P,ADVANCE_MAZE_FRAMEBUFFER_ROW
        LD BC,$0D5C
        JP DRAW_MAZE_TILE

; Draw one border tile while preserving the display pointer
DRAW_MAZE_BORDER_TILE:
        PUSH HL
        LD BC,$0D54
        CALL DRAW_MAZE_TILE
        POP HL
        RET

; Initialize and traverse maze cell data for display updates.
CMD_0A_GAME_CONTROL:
        LD HL,$3E03
        LD DE,$2066
        LD B,$1A

; Initialize the per-row maze display loop
SETUP_MAZE_ROW_DRAW_LOOP:
        LD C,$18
        PUSH HL

; Read the next maze-cell state and select its display tile.
DRAW_MAZE_ROW_LOOP:
        PUSH BC
        LD A,(DE)
        INC DE
        LD BC,$0D3C
        AND $80
        JP NZ,DRAW_MAZE_ROW_ADVANCE
        LD BC,$01D4

; Complete a maze row and advance to the next cell record.
DRAW_MAZE_ROW_ADVANCE:
        CALL DRAW_MAZE_TILE
        POP BC
        DEC C
        JP NZ,DRAW_MAZE_ROW_LOOP
        POP HL
        INC HL
        DEC B
        JP NZ,SETUP_MAZE_ROW_DRAW_LOOP
        LD A,($201F)
        AND A
        JP Z,DRAW_END_SCREEN_MESSAGE
        RET

; Preserve DE while rendering an eight-row bitmap tile.
DRAW_MAZE_TILE:
        PUSH DE
        LD E,$08

; OR the next tile bitmap byte into the frame buffer.
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
        JP NZ,DRAW_GRAPHIC_ROW_LOOP
        POP DE
        RET

; Reset native register state and transfer to the address in HL
ENTER_NATIVE_PROGRAM_STATE:
        DI
        POP HL
        LD BC,$0000
        LD DE,$0000
        LD SP,$4000

; Advance DE until it reaches the value in A
WAIT_FOR_NATIVE_STATE_COUNTER:
        PUSH BC
        INC DE
        CP D
        JP NZ,WAIT_FOR_NATIVE_STATE_COUNTER
        LD SP,$2400
        JP (HL)

; Sample the random state and accumulate a bounded value
SAMPLE_RANDOM_RANGE:
        PUSH BC
        CALL READ_GAME_RANDOM_STATE
        LD C,A
        LD B,$00

; Accumulate sampled state until a bounded random result is formed.
RANDOM_RANGE_ACCUMULATE:
        DEC E
        JP Z,RANDOM_RANGE_RETURN
        ADD A,C
        JP NC,RANDOM_RANGE_ACCUMULATE
        INC B
        JP RANDOM_RANGE_ACCUMULATE

; Return the bounded value and restore BC.
RANDOM_RANGE_RETURN:
        LD A,B
        POP BC
        RET

; Load the byte at $2004 and mix its bits for the next sample.
READ_GAME_RANDOM_STATE:
        PUSH HL
        PUSH BC
        LD HL,$2004
        LD B,$08
        LD A,(HL)

; Rotate and XOR the saved random-state byte
MIX_RANDOM_STATE_BITS:
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
        JP NZ,MIX_RANDOM_STATE_BITS
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
        JP Z,MAZE_CELL_ADDRESS_RETURN
        ADD HL,HL
        RLA
        JP NC,MAZE_ROW_OFFSET_MULTIPLY
        ADD HL,DE
        JP MAZE_ROW_OFFSET_MULTIPLY
; Adds column C and maze RAM base $2066; restores BC and DE.

MAZE_CELL_ADDRESS_RETURN:
        POP BC
        LD E,C
        ADD HL,DE
        LD DE,$2066
        ADD HL,DE
        POP DE
        RET

; Check the state sign and fetch the following pointer
TEST_SIGNED_STATE_AND_COPY_POINTER:
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
        CALL C,TRY_MAZE_STEP_UP
        POP AF
        RRCA
        PUSH AF
        CALL C,TRY_MAZE_STEP_DOWN
        POP AF
        RRCA
        PUSH AF
        CALL C,TRY_MAZE_STEP_RIGHT
        POP AF
        RRCA
        CALL C,TRY_MAZE_STEP_LEFT
        POP HL
        LD A,E
        CP $0F
        RET Z
        LD A,D
        LD BC,$00EF
        CP $60
        JP NC,COMBINE_MAZE_CELL_FLAGS
        LD B,$10

; Combine mask flags and store the resulting cell record
COMBINE_MAZE_CELL_FLAGS:
        LD A,(HL)
        AND C
        OR B
        LD (HL),A
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        RET

; Test a potential maze step and the current row bound
TRY_MAZE_STEP_UP:
        CALL CHECK_MAZE_ROW_STEP_LIMIT
        JP NZ,MAZE_REJECT_LEFT_STEP
        CALL DECODE_MAZE_ROW_FROM_COORDINATE
        DEC B
        JP P,TEST_MAZE_UP_CELL
        LD A,($2026)
        CP C
        RET NZ
        JP MAZE_REJECT_LEFT_STEP

; Read the selected neighbor cell's $40 wall flag
TEST_MAZE_UP_CELL:
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $40
        RET Z

; Decrement the tested maze coordinate E and return.
MAZE_REJECT_LEFT_STEP:
        DEC E
        RET

; Test the neighboring cell state before advancing down
TRY_MAZE_STEP_DOWN:
        CALL CHECK_MAZE_ROW_STEP_LIMIT
        JP NZ,MAZE_REJECT_RIGHT_STEP
        CALL DECODE_MAZE_ROW_FROM_COORDINATE
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $40
        RET Z

; Increment the tested maze coordinate E and return.
MAZE_REJECT_RIGHT_STEP:
        INC E
        RET

; Test horizontal coordinate and neighboring wall state
TRY_MAZE_STEP_LEFT:
        CALL CHECK_MAZE_COLUMN_STEP_LIMIT
        JP NZ,MAZE_REJECT_UP_STEP
        CALL DECODE_MAZE_ROW_FROM_COORDINATE
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $20
        RET Z

; Decrement the tested maze coordinate D and return.
MAZE_REJECT_UP_STEP:
        DEC D
        RET

; Check the coordinate and neighboring wall flag
TRY_MAZE_STEP_RIGHT:
        CALL CHECK_MAZE_COLUMN_STEP_LIMIT
        JP NZ,MAZE_REJECT_DOWN_STEP
        CALL DECODE_MAZE_ROW_FROM_COORDINATE
        DEC C
        RET M
        CALL MAZE_CELL_ADDRESS
        LD A,(HL)
        AND $20
        RET Z

; Increment the tested maze coordinate D and return.
MAZE_REJECT_DOWN_STEP:
        INC D
        RET

; Compare the row coordinate and call the shared state check
CHECK_MAZE_ROW_STEP_LIMIT:
        LD A,D
        AND $07
        CP $03
        POP BC
        RET NZ
        PUSH BC
        CALL SET_MAZE_STEP_STATE
        LD A,E
        AND $07
        CP $07
        RET

; Compare the column coordinate and call the shared state check
CHECK_MAZE_COLUMN_STEP_LIMIT:
        LD A,E
        AND $07
        CP $07
        POP BC
        RET NZ
        PUSH BC
        CALL SET_MAZE_STEP_STATE
        LD A,D
        AND $07
        CP $03
        RET

; Set the step-state flag at $2020 and update its timer
SET_MAZE_STEP_STATE:
        LD BC,$2020
        LD A,(BC)
        AND A
        RET NZ
        INC A
        LD (BC),A
        LD ($2029),A
        RET

; Shift the coordinate and store the derived row index
DECODE_MAZE_ROW_FROM_COORDINATE:
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
        JP C,TRY_PATH_LEFT_UP_RIGHT
        RRA
        JP C,TRY_PATH_LEFT_RIGHT_DOWN
        RRA
        JP C,TRY_PATH_DOWN_LEFT_UP
        RRA
        JP C,TRY_PATH_DOWN_RIGHT_UP
        RET
; Tests neighboring maze cells by varying column C and row B; common movement path.

TRY_PATH_LEFT_UP_RIGHT:
        CALL CHECK_MAZE_LEFT_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        INC C
        CALL CHECK_MAZE_UP_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        INC B
        CALL CHECK_MAZE_RIGHT_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        DEC C
        RET
; Tests another sequence of adjacent maze-cell boundaries.

TRY_PATH_DOWN_LEFT_UP:
        CALL CHECK_MAZE_DOWN_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        DEC B
        CALL CHECK_MAZE_LEFT_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        INC C
        CALL CHECK_MAZE_UP_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        INC B
        RET
; Tests adjacent maze-cell boundaries, restoring column/row counters.

TRY_PATH_LEFT_RIGHT_DOWN:
        CALL CHECK_MAZE_LEFT_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        INC C
        CALL CHECK_MAZE_RIGHT_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        DEC C
        CALL CHECK_MAZE_DOWN_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        DEC B
        RET
; Tests adjacent maze-cell boundaries, restoring column/row counters.

TRY_PATH_DOWN_RIGHT_UP:
        CALL CHECK_MAZE_DOWN_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        DEC B
        CALL CHECK_MAZE_RIGHT_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
        DEC C
        CALL CHECK_MAZE_UP_BOUNDARY
        JP C,STORE_MAZE_POSITION_AND_WALL_STATE
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
        JP Z,CHECK_MAZE_DOWN_PLAYER_LIMIT
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
        JP Z,SET_MAZE_DOWN_BOUNDARY_EVENT
        XOR A
        RET

; Load mode $0E and transfer to native program-state initialization.
CMD_02_SET_MODE_0E:
        LD A,$0E
        JP ENTER_NATIVE_PROGRAM_STATE

; Read inline source/destination information and write display data.
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
        JP NC,COPY_INLINE_GRAPHICS_BYTE
        LD C,$10

; Copy one original graphics byte and move the destination pointer.
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

; Sample input port $01 bit $40 and save the game input result.
CMD_05_READ_PLAYER_INPUT:
        LD HL,$0006
        IN A,($01)
        AND $40
        JP Z,STORE_PLAYER_INPUT_AND_COMPLEMENT
        LD L,$04

; Save the selected player input and its complement
STORE_PLAYER_INPUT_AND_COMPLEMENT:
        LD ($202A),HL
        CPL
        LD ($202C),A
        RET

; Store a one-byte immediate in RAM $200C and advance the cursor.
CMD_08_SET_COUNTER_200C:
        EX DE,HL
        LD A,(HL)
        INC HL
        LD ($2000),HL
        LD ($200C),A
        RET

; Store a count at $200B and a word at $2008.
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

; Update the value at $2013 when its threshold condition is met.
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
        JP NZ,BRANCH_IF_NONZERO_SET_SCRIPT
        EX DE,HL

; Store the selected or sequential script cursor at $2000.
BRANCH_IF_NONZERO_SET_SCRIPT:
        LD ($2000),HL
        RET
; BRANCH_IF_NONZERO: choose script target for nonzero, fall-through otherwise.
; Both paths update RAM $2000.

CMD_0F_BRANCH_IF_NONZERO:
        CALL READ_CONDITION_RECORD
        JP Z,BRANCH_IF_ZERO_SET_SCRIPT
        EX DE,HL

; Store the selected or sequential script cursor at $2000.
BRANCH_IF_ZERO_SET_SCRIPT:
        LD ($2000),HL
        RET

; Read inline pointers and invoke native record processing.
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
        CALL NORMALIZE_DISPLAY_GLYPH_SPACE
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
INITIAL_GAME_SCRIPT:             ; $0D64, original interpreted game program
; The script is a stream of one-byte commands and inline operands.
; $00 invokes the separate event path; $01-$11 dispatch via the 17
; native-handler vectors at $0BEE. Word operands use little-endian DW.
;
; Verified packet boundaries and operand widths through $0E1C:
        DB $0C,$00               ; $0D64 [$202C] = $00
        DW $202C                ; store target
        DB $0C,$00               ; $0D68 [$2031] = $00
        DW $2031                ; store target
        DB $0C,$00               ; $0D6C [$2032] = $00
        DW $2032                ; store target
        DB $0C,$00               ; $0D70 [$202D] = $00
        DW $202D                ; store target
        DB $11                   ; $0D74 UPDATE_END_STATE
        DB $09,$0A               ; $0D75 SET_COUNTER_AND_POINTER
        DW $0D94                ; saved pointer
        DB $07,$10               ; $0D79 DRAW_INLINE_RECORD, count $10
        DW $0C10,$2408     ; text/data and display addresses
        DB $07,$09               ; $0D7F DRAW_INLINE_RECORD, count $09
        DW $0D22,$240B     ; text/data and display addresses
        DB $08,$1E               ; $0D85 SET_COUNTER_200C = $1E
        DB $00                   ; $0D87 ZERO_COMMAND_EVENT
        DB $07,$09               ; $0D88 DRAW_INLINE_RECORD, count $09
        DW $0C10,$240B     ; text/data and display addresses
        DB $08,$1E               ; $0D8E SET_COUNTER_200C = $1E
        DB $00                   ; $0D90 ZERO_COMMAND_EVENT
        DB $0B                   ; $0D91 GOTO_SCRIPT
        DW $0D7F                ; script target
        DB $02                   ; $0D94 SET_MODE_0E
        DB $09,$0A               ; $0D95 SET_COUNTER_AND_POINTER
        DW $0DD5                ; saved pointer
        DB $07,$03               ; $0D99 DRAW_INLINE_RECORD, count $03
        DW $0C21,$2C0A     ; text/data and display addresses
        DB $08,$0F               ; $0D9F SET_COUNTER_200C = $0F
        DB $00                   ; $0DA1 ZERO_COMMAND_EVENT
        DB $07,$0B               ; $0DA2 DRAW_INLINE_RECORD, count $0B
        DW $0C21,$2C0A     ; text/data and display addresses
        DB $08,$0F               ; $0DA8 SET_COUNTER_200C = $0F
        DB $00                   ; $0DAA ZERO_COMMAND_EVENT
        DB $07,$04               ; $0DAB DRAW_INLINE_RECORD, count $04
        DW $0C2C,$320B     ; text/data and display addresses
        DB $08,$0F               ; $0DB1 SET_COUNTER_200C = $0F
        DB $00                   ; $0DB3 ZERO_COMMAND_EVENT
        DB $07,$04               ; $0DB4 DRAW_INLINE_RECORD, count $04
        DW $0D22,$3210     ; text/data and display addresses
        DB $08,$3C               ; $0DBA SET_COUNTER_200C = $3C
        DB $00                   ; $0DBC ZERO_COMMAND_EVENT
        DB $07,$0B               ; $0DBD DRAW_INLINE_RECORD, count $0B
        DW $0C10,$2C0A     ; text/data and display addresses
        DB $07,$09               ; $0DC3 DRAW_INLINE_RECORD, count $09
        DW $0C10,$320B     ; text/data and display addresses
        DB $07,$0D               ; $0DC9 DRAW_INLINE_RECORD, count $0D
        DW $0C6D,$3A09     ; text/data and display addresses
        DB $08,$0F               ; $0DCF SET_COUNTER_200C = $0F
        DB $00                   ; $0DD1 ZERO_COMMAND_EVENT
        DB $0B                   ; $0DD2 GOTO_SCRIPT
        DW $0D99                ; script target
        DB $02                   ; $0DD5 SET_MODE_0E
        DB $07,$0D               ; $0DD6 DRAW_INLINE_RECORD, count $0D
        DW $0C6D,$3A09     ; text/data and display addresses
        DB $07,$19               ; $0DDC DRAW_INLINE_RECORD, count $19
        DW $0C41,$2A0A     ; text/data and display addresses
        DB $09,$08               ; $0DE2 SET_COUNTER_AND_POINTER
        DW $0DFB                ; saved pointer
        DB $07,$10               ; $0DE6 DRAW_INLINE_RECORD, count $10
        DW $0C5D,$3608     ; text/data and display addresses
        DB $08,$1E               ; $0DEC SET_COUNTER_200C = $1E
        DB $00                   ; $0DEE ZERO_COMMAND_EVENT
        DB $07,$01               ; $0DEF DRAW_INLINE_RECORD, count $01
        DW $0C10,$3608     ; text/data and display addresses
        DB $08,$1E               ; $0DF5 SET_COUNTER_200C = $1E
        DB $00                   ; $0DF7 ZERO_COMMAND_EVENT
        DB $0B                   ; $0DF8 GOTO_SCRIPT
        DW $0DE6                ; script target
        DB $02                   ; $0DFB SET_MODE_0E
        DB $07,$1F               ; $0DFC DRAW_INLINE_RECORD, count $1F
        DW $0C3A,$2A0C     ; text/data and display addresses
        DB $09,$08               ; $0E02 SET_COUNTER_AND_POINTER
        DW $0E1B                ; saved pointer
        DB $07,$0D               ; $0E06 DRAW_INLINE_RECORD, count $0D
        DW $0C6D,$3A09     ; text/data and display addresses
        DB $08,$14               ; $0E0C SET_COUNTER_200C = $14
        DB $00                   ; $0E0E ZERO_COMMAND_EVENT
        DB $07,$01               ; $0E0F DRAW_INLINE_RECORD, count $01
        DW $0C10,$3A15     ; text/data and display addresses
        DB $08,$14               ; $0E15 SET_COUNTER_200C = $14
        DB $00                   ; $0E17 ZERO_COMMAND_EVENT
        DB $0B                   ; $0E18 GOTO_SCRIPT
        DW $0E06                ; script target
        DB $02                   ; $0E1B SET_MODE_0E
        DB $06                   ; $0E1C INIT_GAME_FIELDS

; Original game program continued at $0E1D.
; This point begins command $03, whose native inline-operand contract
; is tracked in docs/8080-WORD-SEMANTICS.md. The remaining bytes are
; retained in their exact original order pending packet-boundary audit.
        DB $3,$8,$F0,$000,$000A,$00009,$000004,$0000094  ; $0E1D
        DB $D,$0,$02,$007,$0019,$0000C,$00000D,$0000008  ; $0E25
        DB $28,$7,$0D,$041,$000C,$00009,$000034,$0000007  ; $0E2D
        DB $A,$52,$0C,$00B,$0038,$0000C,$000001,$0000034  ; $0E35
        DB $20,$7,$01,$010,$000C,$00017,$000034,$0000007  ; $0E3D
        DB $1,$79,$0C,$009,$0038,$00008,$00001E,$0000000  ; $0E45
        DB $7,$1,$79,$00C,$0017,$00034,$000007,$0000001  ; $0E4D
        DB $10,$C,$09,$038,$0008,$0001E,$000000,$000000B  ; $0E55
        DB $3E,$E,$02,$00C,$0004,$00013,$000020,$0000007  ; $0E5D
        DB $D,$41,$0C,$009,$002C,$00007,$000007,$000005D  ; $0E65
        DB $C,$C,$30,$007,$0002,$0004F,$00000C,$000000F  ; $0E6D
        DB $32,$7,$16,$083,$000C,$00008,$000034,$0000008  ; $0E75
        DB $F0,$0,$0B,$0A6,$000E,$0000F,$00002E,$0000020  ; $0E7D
        DB $8C,$E,$0F,$032,$0020,$00064,$00000D,$0000002  ; $0E85
        DB $9,$2,$A6,$00E,$0007,$00009,$00007A,$000000C  ; $0E8D
        DB $B,$32,$08,$01E,$0000,$00007,$000009,$0000010  ; $0E95
        DB $C,$B,$32,$008,$000F,$00000,$00000B,$0000091  ; $0E9D
        DB $E,$2,$06,$003,$0007,$0000A,$0000A7,$000000C  ; $0EA5
        DB $A0,$3E,$0F,$02E,$0020,$000C1,$00000E,$0000007  ; $0EAD
        DB $C,$E5,$0C,$008,$0024,$0000C,$000001,$000002E  ; $0EB5
        DB $20,$B,$CC,$00E,$0007,$0000D,$00009A,$000000C  ; $0EBD
        DB $8,$24,$10,$02E,$0020,$00016,$000024,$0000007  ; $0EC5
        DB $9,$31,$0C,$0B1,$003E,$00010,$000031,$0000020  ; $0ECD
        DB $BB,$3E,$04,$048,$0020,$00032,$00000D,$0000026  ; $0ED5
        DB $20,$17,$C2,$004,$0059,$00020,$000037,$000000D  ; $0EDD
        DB $24,$20,$E0,$0C0,$000C,$00006,$00000E,$0000020  ; $0EE5
        DB $C,$6,$29,$020,$0000,$00009,$000004,$0000082  ; $0EED
        DB $E,$7,$10,$010,$000C,$00008,$000024,$0000010  ; $0EF5
        DB $31,$20,$BB,$03E,$000E,$0001A,$000020,$000001C  ; $0EFD
        DB $F,$D,$07,$00B,$00F5,$0000C,$000008,$0000024  ; $0F05
        DB $8,$1E,$00,$007,$000B,$00010,$00000C,$0000008  ; $0F0D
        DB $24,$8,$1E,$000,$000B,$00007,$00000F,$0000007  ; $0F15
        DB $C,$0,$0D,$008,$0024,$00008,$00001E,$0000000  ; $0F1D
        DB $7,$C,$10,$00C,$0008,$00024,$000008,$000001E  ; $0F25
        DB $0,$B,$1C,$00F,$0002,$00005,$000007,$000000A  ; $0F2D
        DB $52,$C,$0B,$02C,$0007,$00007,$00005D,$000000C  ; $0F35
        DB $C,$30,$08,$0B4,$0000,$0000B,$000064,$000000F  ; $0F3D
        DB $E,$2E,$20,$064,$000D,$00002,$000009,$0000002  ; $0F45
        DB $64,$F,$07,$009,$007A,$0000C,$00000B,$0000032  ; $0F4D
        DB $8,$1E,$00,$007,$0009,$00010,$00000C,$000000B  ; $0F55
        DB $32,$8,$1E,$000,$000B,$0004F,$00000F,$0000002  ; $0F5D
        DB $6,$3,$07,$006,$00B1,$0000C,$000001,$0000026  ; $0F65
        DB $7,$3,$C1,$00C,$00E1,$00034,$000010,$0000032  ; $0F6D
        DB $20,$0,$3C,$007,$0006,$000B1,$00000C,$000001E  ; $0F75
        DB $26,$7,$03,$0BC,$000C,$000FE,$000034,$0000010  ; $0F7D
        DB $31,$20,$1D,$03C,$0007,$0000D,$00009A,$000000C  ; $0F85
        DB $8,$24,$10,$02E,$0020,$00016,$000024,$0000007  ; $0F8D
        DB $4,$AD,$0C,$0A3,$003E,$00007,$000007,$000002B  ; $0F95
        DB $D,$B1,$3E,$004,$0048,$00020,$000037,$000000D  ; $0F9D
        DB $26,$20,$17,$0C0,$0004,$00059,$000020,$0000032  ; $0FA5
        DB $D,$24,$20,$0E0,$00C0,$0000C,$000001,$000000D  ; $0FAD
        DB $20,$C,$01,$020,$0020,$00000,$000010,$000002E  ; $0FB5
        DB $20,$16,$24,$009,$0004,$00045,$00000F,$000000E  ; $0FBD
        DB $1B,$20,$E3,$00F,$0010,$00032,$000020,$0000000  ; $0FC5
        DB $3C,$7,$0A,$0D2,$000C,$00001,$000026,$0000008  ; $0FCD
        DB $1E,$0,$07,$006,$00C7,$0000C,$000001,$0000026  ; $0FD5
        DB $8,$1E,$00,$00B,$00CE,$0000F,$000010,$0000031  ; $0FDD
        DB $20,$1D,$3C,$007,$000A,$000D2,$00000C,$000001E  ; $0FE5
        DB $26,$8,$1E,$000,$0007,$00006,$0000C7,$000000C  ; $0FED
        DB $1E,$26,$08,$01E,$0000,$0000B,$0000E8,$000000F  ; $0FF5
        DB $0,$0,$00  ; $0FFD
        END
