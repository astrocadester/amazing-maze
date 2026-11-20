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

; Digit 0 8x10 bitmap.
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

; Digit 1 8x10 bitmap.
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

; Digit 2 8x10 bitmap.
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

; Digit 3 8x10 bitmap.
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

; Digit 4 8x10 bitmap.
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

; Digit 5 8x10 bitmap.
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

; Digit 6 8x10 bitmap.
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

; Digit 7 8x10 bitmap.
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

; Digit 8 8x10 bitmap.
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

; Digit 9 8x10 bitmap.
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

; Space 8x10 bitmap.
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

; Letter a 8x10 bitmap.
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

; Letter b 8x10 bitmap.
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

; Letter c 8x10 bitmap.
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

; Letter d 8x10 bitmap.
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

; Letter e 8x10 bitmap.
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

; Letter f 8x10 bitmap.
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

; Letter g 8x10 bitmap.
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

; Letter h 8x10 bitmap.
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

; Letter i 8x10 bitmap.
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

; Letter j 8x10 bitmap.
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

; Letter k 8x10 bitmap.
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

; Letter l 8x10 bitmap.
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

; Letter m 8x10 bitmap.
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

; Letter n 8x10 bitmap.
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

; Letter o 8x10 bitmap.
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

; Letter p 8x10 bitmap.
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

; Letter q 8x10 bitmap.
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

; Letter r 8x10 bitmap.
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

; Letter s 8x10 bitmap.
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

; Letter t 8x10 bitmap.
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

; Letter u 8x10 bitmap.
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

; Letter v 8x10 bitmap.
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

; Letter w 8x10 bitmap.
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

; Letter x 8x10 bitmap.
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

; Letter y 8x10 bitmap.
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

; Letter z 8x10 bitmap.
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
; Original interpreted game command stream: $0D64-$0FFF.
; The native interpreter dispatches $01-$11 through the 17-entry table;
; $00 enters the game event/scheduler service. Inline operands follow
; each opcode, and DW preserves the original little-endian address fields.
INITIAL_GAME_SCRIPT:
        DB $0C,$00               ; $0D64 STORE_BYTE_TO_RAM
        DW $202C             ; store destination
        DB $0C,$00               ; $0D68 STORE_BYTE_TO_RAM
        DW $2031             ; store destination
        DB $0C,$00               ; $0D6C STORE_BYTE_TO_RAM
        DW $2032             ; store destination
        DB $0C,$00               ; $0D70 STORE_BYTE_TO_RAM
        DW $202D             ; store destination
        DB $11                   ; $0D74 UPDATE_END_STATE
        DB $09,$0A               ; $0D75 SET_COUNTER_AND_POINTER
        DW $0D94             ; saved pointer
        DB $07,$10               ; $0D79 DRAW_TEXT_RECORD (count $10)
        DW $0C10,$2408      ; data source, display destination

; Branch destination in the original command stream.
SCRIPT_0D7F:
        DB $07,$09               ; $0D7F DRAW_TEXT_RECORD (count $09)
        DW $0D22,$240B      ; data source, display destination
        DB $08,$1E               ; $0D85 SET_FRAME_COUNTER
        DB $00                   ; $0D87 ZERO_EVENT

        DB $07,$09               ; $0D88 DRAW_TEXT_RECORD (count $09)
        DW $0C10,$240B      ; data source, display destination
        DB $08,$1E               ; $0D8E SET_FRAME_COUNTER
        DB $00                   ; $0D90 ZERO_EVENT

        DB $0B                   ; $0D91 GOTO_SCRIPT
        DW SCRIPT_0D7F             ; next script entry

        DB $02                   ; $0D94 SET_MODE_0E
        DB $09,$0A               ; $0D95 SET_COUNTER_AND_POINTER
        DW $0DD5             ; saved pointer

; Branch destination in the original command stream.
SCRIPT_0D99:
        DB $07,$03               ; $0D99 DRAW_TEXT_RECORD (count $03)
        DW $0C21,$2C0A      ; data source, display destination
        DB $08,$0F               ; $0D9F SET_FRAME_COUNTER
        DB $00                   ; $0DA1 ZERO_EVENT

        DB $07,$0B               ; $0DA2 DRAW_TEXT_RECORD (count $0B)
        DW $0C21,$2C0A      ; data source, display destination
        DB $08,$0F               ; $0DA8 SET_FRAME_COUNTER
        DB $00                   ; $0DAA ZERO_EVENT

        DB $07,$04               ; $0DAB DRAW_TEXT_RECORD (count $04)
        DW $0C2C,$320B      ; data source, display destination
        DB $08,$0F               ; $0DB1 SET_FRAME_COUNTER
        DB $00                   ; $0DB3 ZERO_EVENT

        DB $07,$04               ; $0DB4 DRAW_TEXT_RECORD (count $04)
        DW $0D22,$3210      ; data source, display destination
        DB $08,$3C               ; $0DBA SET_FRAME_COUNTER
        DB $00                   ; $0DBC ZERO_EVENT

        DB $07,$0B               ; $0DBD DRAW_TEXT_RECORD (count $0B)
        DW $0C10,$2C0A      ; data source, display destination
        DB $07,$09               ; $0DC3 DRAW_TEXT_RECORD (count $09)
        DW $0C10,$320B      ; data source, display destination
        DB $07,$0D               ; $0DC9 DRAW_TEXT_RECORD (count $0D)
        DW $0C6D,$3A09      ; data source, display destination
        DB $08,$0F               ; $0DCF SET_FRAME_COUNTER
        DB $00                   ; $0DD1 ZERO_EVENT

        DB $0B                   ; $0DD2 GOTO_SCRIPT
        DW SCRIPT_0D99             ; next script entry

        DB $02                   ; $0DD5 SET_MODE_0E
        DB $07,$0D               ; $0DD6 DRAW_TEXT_RECORD (count $0D)
        DW $0C6D,$3A09      ; data source, display destination
        DB $07,$19               ; $0DDC DRAW_TEXT_RECORD (count $19)
        DW $0C41,$2A0A      ; data source, display destination
        DB $09,$08               ; $0DE2 SET_COUNTER_AND_POINTER
        DW $0DFB             ; saved pointer

; Branch destination in the original command stream.
SCRIPT_0DE6:
        DB $07,$10               ; $0DE6 DRAW_TEXT_RECORD (count $10)
        DW $0C5D,$3608      ; data source, display destination
        DB $08,$1E               ; $0DEC SET_FRAME_COUNTER
        DB $00                   ; $0DEE ZERO_EVENT

        DB $07,$01               ; $0DEF DRAW_TEXT_RECORD (count $01)
        DW $0C10,$3608      ; data source, display destination
        DB $08,$1E               ; $0DF5 SET_FRAME_COUNTER
        DB $00                   ; $0DF7 ZERO_EVENT

        DB $0B                   ; $0DF8 GOTO_SCRIPT
        DW SCRIPT_0DE6             ; next script entry

        DB $02                   ; $0DFB SET_MODE_0E
        DB $07,$1F               ; $0DFC DRAW_TEXT_RECORD (count $1F)
        DW $0C3A,$2A0C      ; data source, display destination
        DB $09,$08               ; $0E02 SET_COUNTER_AND_POINTER
        DW $0E1B             ; saved pointer

; Branch destination in the original command stream.
SCRIPT_0E06:
        DB $07,$0D               ; $0E06 DRAW_TEXT_RECORD (count $0D)
        DW $0C6D,$3A09      ; data source, display destination
        DB $08,$14               ; $0E0C SET_FRAME_COUNTER
        DB $00                   ; $0E0E ZERO_EVENT

        DB $07,$01               ; $0E0F DRAW_TEXT_RECORD (count $01)
        DW $0C10,$3A15      ; data source, display destination
        DB $08,$14               ; $0E15 SET_FRAME_COUNTER
        DB $00                   ; $0E17 ZERO_EVENT

        DB $0B                   ; $0E18 GOTO_SCRIPT
        DW SCRIPT_0E06             ; next script entry

        DB $02                   ; $0E1B SET_MODE_0E
        DB $06                   ; $0E1C INIT_GAME_FIELDS
        DB $03                   ; $0E1D DRAW_MAZE_PLAYFIELD
        DB $08,$F0               ; $0E1E SET_FRAME_COUNTER
        DB $00                   ; $0E20 ZERO_EVENT

        DB $0A                   ; $0E21 DRAW_MAZE_CELLS
        DB $09,$04               ; $0E22 SET_COUNTER_AND_POINTER
        DW $0D94             ; saved pointer
        DB $00                   ; $0E26 ZERO_EVENT

        DB $02                   ; $0E27 SET_MODE_0E
        DB $07,$19               ; $0E28 DRAW_TEXT_RECORD (count $19)
        DW $0D0C,$2808      ; data source, display destination
        DB $07,$0D               ; $0E2E DRAW_TEXT_RECORD (count $0D)
        DW $0C41,$3409      ; data source, display destination
        DB $07,$0A               ; $0E34 DRAW_TEXT_RECORD (count $0A)
        DW $0C52,$380B      ; data source, display destination
        DB $0C,$01               ; $0E3A STORE_BYTE_TO_RAM
        DW $2034             ; store destination

; Branch destination in the original command stream.
SCRIPT_0E3E:
        DB $07,$01               ; $0E3E DRAW_TEXT_RECORD (count $01)
        DW $0C10,$3417      ; data source, display destination
        DB $07,$01               ; $0E44 DRAW_TEXT_RECORD (count $01)
        DW $0C79,$3809      ; data source, display destination
        DB $08,$1E               ; $0E4A SET_FRAME_COUNTER
        DB $00                   ; $0E4C ZERO_EVENT

        DB $07,$01               ; $0E4D DRAW_TEXT_RECORD (count $01)
        DW $0C79,$3417      ; data source, display destination
        DB $07,$01               ; $0E53 DRAW_TEXT_RECORD (count $01)
        DW $0C10,$3809      ; data source, display destination
        DB $08,$1E               ; $0E59 SET_FRAME_COUNTER
        DB $00                   ; $0E5B ZERO_EVENT

        DB $0B                   ; $0E5C GOTO_SCRIPT
        DW SCRIPT_0E3E             ; next script entry

        DB $02                   ; $0E5F SET_MODE_0E
        DB $0C,$04               ; $0E60 STORE_BYTE_TO_RAM
        DW $2013             ; store destination
        DB $07,$0D               ; $0E64 DRAW_TEXT_RECORD (count $0D)
        DW $0C41,$2C09      ; data source, display destination
        DB $07,$07               ; $0E6A DRAW_TEXT_RECORD (count $07)
        DW $0C5D,$300C      ; data source, display destination
        DB $07,$02               ; $0E70 DRAW_TEXT_RECORD (count $02)
        DW $0C4F,$320F      ; data source, display destination
        DB $07,$16               ; $0E76 DRAW_TEXT_RECORD (count $16)
        DW $0C83,$3408      ; data source, display destination
        DB $08,$F0               ; $0E7C SET_FRAME_COUNTER
        DB $00                   ; $0E7E ZERO_EVENT

        DB $0B                   ; $0E7F GOTO_SCRIPT
        DW SCRIPT_0EA6             ; next script entry

        DB $0F                   ; $0E82 BRANCH_IF_NONZERO
        DW $202E,SCRIPT_0E8C      ; state test, branch destination
        DB $0F                   ; $0E87 BRANCH_IF_NONZERO
        DW $2032,INITIAL_GAME_SCRIPT      ; state test, branch destination

; Branch destination in the original command stream.
SCRIPT_0E8C:
        DB $02                   ; $0E8C SET_MODE_0E
        DB $09,$02               ; $0E8D SET_COUNTER_AND_POINTER
        DW $0EA6             ; saved pointer

; Branch destination in the original command stream.
SCRIPT_0E91:
        DB $07,$09               ; $0E91 DRAW_TEXT_RECORD (count $09)
        DW $0C7A,$320B      ; data source, display destination
        DB $08,$1E               ; $0E97 SET_FRAME_COUNTER
        DB $00                   ; $0E99 ZERO_EVENT

        DB $07,$09               ; $0E9A DRAW_TEXT_RECORD (count $09)
        DW $0C10,$320B      ; data source, display destination
        DB $08,$0F               ; $0EA0 SET_FRAME_COUNTER
        DB $00                   ; $0EA2 ZERO_EVENT

        DB $0B                   ; $0EA3 GOTO_SCRIPT
        DW SCRIPT_0E91             ; next script entry


; Branch destination in the original command stream.
SCRIPT_0EA6:
        DB $02                   ; $0EA6 SET_MODE_0E
        DB $06                   ; $0EA7 INIT_GAME_FIELDS
        DB $03                   ; $0EA8 DRAW_MAZE_PLAYFIELD
        DB $07,$0A               ; $0EA9 DRAW_TEXT_RECORD (count $0A)
        DW $0CA7,$3EA0      ; data source, display destination
        DB $0F                   ; $0EAF BRANCH_IF_NONZERO
        DW $202E,SCRIPT_0EC1      ; state test, branch destination
        DB $07,$0C               ; $0EB4 DRAW_TEXT_RECORD (count $0C)
        DW $0CE5,$2408      ; data source, display destination
        DB $0C,$01               ; $0EBA STORE_BYTE_TO_RAM
        DW $202E             ; store destination
        DB $0B                   ; $0EBE GOTO_SCRIPT
        DW SCRIPT_0ECC             ; next script entry


; Branch destination in the original command stream.
SCRIPT_0EC1:
        DB $07,$0D               ; $0EC1 DRAW_TEXT_RECORD (count $0D)
        DW $0C9A,$2408      ; data source, display destination
        DB $10                   ; $0EC7 PROCESS_DISPLAY_RECORD
        DW $202E,$2416      ; native inline record

; Branch destination in the original command stream.
SCRIPT_0ECC:
        DB $07,$09               ; $0ECC DRAW_TEXT_RECORD (count $09)
        DW $0C31,$3EB1      ; data source, display destination
        DB $10                   ; $0ED2 PROCESS_DISPLAY_RECORD
        DW $2031,$3EBB      ; native inline record
        DB $04                   ; $0ED7 WRITE_DISPLAY_RECORD
        DW $2048,$0D32      ; display destination, data word
        DW $2026             ; source pointer
        DB $17,$C2               ; inline display bytes
        DB $04                   ; $0EE0 WRITE_DISPLAY_RECORD
        DW $2059,$0D37      ; display destination, data word
        DW $2024             ; source pointer
        DB $E0,$C0               ; inline display bytes
        DB $0C,$06               ; $0EE9 STORE_BYTE_TO_RAM
        DW $200E             ; store destination
        DB $0C,$06               ; $0EED STORE_BYTE_TO_RAM
        DW $2029             ; store destination
        DB $00                   ; $0EF1 ZERO_EVENT

        DB $09,$04               ; $0EF2 SET_COUNTER_AND_POINTER
        DW $0E82             ; saved pointer
        DB $07,$10               ; $0EF6 DRAW_TEXT_RECORD (count $10)
        DW $0C10,$2408      ; data source, display destination
        DB $10                   ; $0EFC PROCESS_DISPLAY_RECORD
        DW $2031,$3EBB      ; native inline record
        DB $0E                   ; $0F01 BRANCH_IF_ZERO
        DW $201A,SCRIPT_0F1C      ; state test, branch destination
        DB $0D                   ; $0F06 DECREMENT_GAME_STATE

; Branch destination in the original command stream.
SCRIPT_0F07:
        DB $07,$0B               ; $0F07 DRAW_TEXT_RECORD (count $0B)
        DW $0CF5,$2408      ; data source, display destination
        DB $08,$1E               ; $0F0D SET_FRAME_COUNTER
        DB $00                   ; $0F0F ZERO_EVENT

        DB $07,$0B               ; $0F10 DRAW_TEXT_RECORD (count $0B)
        DW $0C10,$2408      ; data source, display destination
        DB $08,$1E               ; $0F16 SET_FRAME_COUNTER
        DB $00                   ; $0F18 ZERO_EVENT

        DB $0B                   ; $0F19 GOTO_SCRIPT
        DW SCRIPT_0F07             ; next script entry


; Branch destination in the original command stream.
SCRIPT_0F1C:
        DB $07,$0C               ; $0F1C DRAW_TEXT_RECORD (count $0C)
        DW $0D00,$2408      ; data source, display destination
        DB $08,$1E               ; $0F22 SET_FRAME_COUNTER
        DB $00                   ; $0F24 ZERO_EVENT

        DB $07,$0C               ; $0F25 DRAW_TEXT_RECORD (count $0C)
        DW $0C10,$2408      ; data source, display destination
        DB $08,$1E               ; $0F2B SET_FRAME_COUNTER
        DB $00                   ; $0F2D ZERO_EVENT

        DB $0B                   ; $0F2E GOTO_SCRIPT
        DW SCRIPT_0F1C             ; next script entry

        DB $02                   ; $0F31 SET_MODE_0E
        DB $05                   ; $0F32 READ_PLAYER_INPUT
        DB $07,$0A               ; $0F33 DRAW_TEXT_RECORD (count $0A)
        DW $0C52,$2C0B      ; data source, display destination
        DB $07,$07               ; $0F39 DRAW_TEXT_RECORD (count $07)
        DW $0C5D,$300C      ; data source, display destination
        DB $08,$B4               ; $0F3F SET_FRAME_COUNTER
        DB $00                   ; $0F41 ZERO_EVENT

        DB $0B                   ; $0F42 GOTO_SCRIPT
        DW SCRIPT_0F64             ; next script entry

        DB $0E                   ; $0F45 BRANCH_IF_ZERO
        DW $202E,INITIAL_GAME_SCRIPT      ; state test, branch destination
        DB $02                   ; $0F4A SET_MODE_0E
        DB $09,$02               ; $0F4B SET_COUNTER_AND_POINTER
        DW $0F64             ; saved pointer

; Branch destination in the original command stream.
SCRIPT_0F4F:
        DB $07,$09               ; $0F4F DRAW_TEXT_RECORD (count $09)
        DW $0C7A,$320B      ; data source, display destination
        DB $08,$1E               ; $0F55 SET_FRAME_COUNTER
        DB $00                   ; $0F57 ZERO_EVENT

        DB $07,$09               ; $0F58 DRAW_TEXT_RECORD (count $09)
        DW $0C10,$320B      ; data source, display destination
        DB $08,$1E               ; $0F5E SET_FRAME_COUNTER
        DB $00                   ; $0F60 ZERO_EVENT

        DB $0B                   ; $0F61 GOTO_SCRIPT
        DW SCRIPT_0F4F             ; next script entry


; Branch destination in the original command stream.
SCRIPT_0F64:
        DB $02                   ; $0F64 SET_MODE_0E
        DB $06                   ; $0F65 INIT_GAME_FIELDS
        DB $03                   ; $0F66 DRAW_MAZE_PLAYFIELD
        DB $07,$06               ; $0F67 DRAW_TEXT_RECORD (count $06)
        DW $0CB1,$2601      ; data source, display destination
        DB $07,$03               ; $0F6D DRAW_TEXT_RECORD (count $03)
        DW $0CC1,$34E1      ; data source, display destination
        DB $10                   ; $0F73 PROCESS_DISPLAY_RECORD
        DW $2032,$3C00      ; native inline record
        DB $07,$06               ; $0F78 DRAW_TEXT_RECORD (count $06)
        DW $0CB1,$261E      ; data source, display destination
        DB $07,$03               ; $0F7E DRAW_TEXT_RECORD (count $03)
        DW $0CBC,$34FE      ; data source, display destination
        DB $10                   ; $0F84 PROCESS_DISPLAY_RECORD
        DW $2031,$3C1D      ; native inline record
        DB $07,$0D               ; $0F89 DRAW_TEXT_RECORD (count $0D)
        DW $0C9A,$2408      ; data source, display destination
        DB $10                   ; $0F8F PROCESS_DISPLAY_RECORD
        DW $202E,$2416      ; native inline record
        DB $07,$04               ; $0F94 DRAW_TEXT_RECORD (count $04)
        DW $0CAD,$3EA3      ; data source, display destination
        DB $07,$07               ; $0F9A DRAW_TEXT_RECORD (count $07)
        DW $0D2B,$3EB1      ; data source, display destination
        DB $04                   ; $0FA0 WRITE_DISPLAY_RECORD
        DW $2048,$0D37      ; display destination, data word
        DW $2026             ; source pointer
        DB $17,$C0               ; inline display bytes
        DB $04                   ; $0FA9 WRITE_DISPLAY_RECORD
        DW $2059,$0D32      ; display destination, data word
        DW $2024             ; source pointer
        DB $E0,$C0               ; inline display bytes
        DB $0C,$01               ; $0FB2 STORE_BYTE_TO_RAM
        DW $200D             ; store destination
        DB $0C,$01               ; $0FB6 STORE_BYTE_TO_RAM
        DW $2020             ; store destination
        DB $00                   ; $0FBA ZERO_EVENT

        DB $10                   ; $0FBB PROCESS_DISPLAY_RECORD
        DW $202E,$2416      ; native inline record
        DB $09,$04               ; $0FC0 SET_COUNTER_AND_POINTER
        DW $0F45             ; saved pointer
        DB $0E                   ; $0FC4 BRANCH_IF_ZERO
        DW $201B,SCRIPT_0FE3      ; state test, branch destination
        DB $10                   ; $0FC9 PROCESS_DISPLAY_RECORD
        DW $2032,$3C00      ; native inline record

; Branch destination in the original command stream.
SCRIPT_0FCE:
        DB $07,$0A               ; $0FCE DRAW_TEXT_RECORD (count $0A)
        DW $0CD2,$2601      ; data source, display destination
        DB $08,$1E               ; $0FD4 SET_FRAME_COUNTER
        DB $00                   ; $0FD6 ZERO_EVENT

        DB $07,$06               ; $0FD7 DRAW_TEXT_RECORD (count $06)
        DW $0CC7,$2601      ; data source, display destination
        DB $08,$1E               ; $0FDD SET_FRAME_COUNTER
        DB $00                   ; $0FDF ZERO_EVENT

        DB $0B                   ; $0FE0 GOTO_SCRIPT
        DW SCRIPT_0FCE             ; next script entry


; Branch destination in the original command stream.
SCRIPT_0FE3:
        DB $10                   ; $0FE3 PROCESS_DISPLAY_RECORD
        DW $2031,$3C1D      ; native inline record

; Branch destination in the original command stream.
SCRIPT_0FE8:
        DB $07,$0A               ; $0FE8 DRAW_TEXT_RECORD (count $0A)
        DW $0CD2,$261E      ; data source, display destination
        DB $08,$1E               ; $0FEE SET_FRAME_COUNTER
        DB $00                   ; $0FF0 ZERO_EVENT

        DB $07,$06               ; $0FF1 DRAW_TEXT_RECORD (count $06)
        DW $0CC7,$261E      ; data source, display destination
        DB $08,$1E               ; $0FF7 SET_FRAME_COUNTER
        DB $00                   ; $0FF9 ZERO_EVENT

        DB $0B                   ; $0FFA GOTO_SCRIPT
        DW SCRIPT_0FE8             ; next script entry

        DB $00                   ; $0FFD ZERO_EVENT

        DB $00                   ; $0FFE ZERO_EVENT

        DB $00                   ; $0FFF ZERO_EVENT

        END
