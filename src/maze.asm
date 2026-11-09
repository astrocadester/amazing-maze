; Amazing Maze (1976) original Intel 8080 native ROM reconstruction
; Source of truth: roms/original/maze.zip (maze.h $0000-$07FF; maze.g $0800-$0FFF)
; Version v20261108-0009 — native instruction recovery with conservatively classified data
; This is the native source work product. Continue hard RE by converting remaining
; data bytes to genuine native instructions when executable reachability proves them.
; All bytes, even unclassified data, follow their exact original ROM order.
; The native assembler/byte-exact build verification remains a separate gate.
        ORG $0000


RESET:
        NOP                      ; $0000: 00
        NOP                      ; $0001: 00
        LD SP,$2400              ; $0002: 31 00 24
        JP $0017                 ; $0005: C3 17 00

INTERRUPT_ENTRY:
        PUSH AF                  ; $0008: F5
        PUSH BC                  ; $0009: C5
        PUSH DE                  ; $000A: D5
        PUSH HL                  ; $000B: E5
        JP $030B                 ; $000C: C3 0B 03
        DB $00 ; $000F-$000F source data/unclassified
        PUSH AF                  ; $0010: F5
        PUSH BC                  ; $0011: C5
        PUSH DE                  ; $0012: D5
        PUSH HL                  ; $0013: E5
        JP $02E2                 ; $0014: C3 E2 02
; Read input port 1; carry controls transition into initial script setup.
RESET_START:
        IN A,($01)               ; $0017: DB 01
        RLA                      ; $0019: 17
        JP NC,$0377              ; $001A: D2 77 03
        LD B,$01                 ; $001D: 06 01
        LD DE,$0000              ; $001F: 11 00 00
NATIVE_0022:
        LD HL,$2000              ; $0022: 21 00 20
NATIVE_0025:
        OUT ($02),A              ; $0025: D3 02
        LD (HL),B                ; $0027: 70
        LD A,(HL)                ; $0028: 7E
        XOR B                    ; $0029: A8
        JP Z,$003C               ; $002A: CA 3C 00
        LD C,A                   ; $002D: 4F
        LD A,L                   ; $002E: 7D
        AND $01                  ; $002F: E6 01
        LD A,C                   ; $0031: 79
        JP NZ,$003A              ; $0032: C2 3A 00
        OR D                     ; $0035: B2
        LD D,A                   ; $0036: 57
        JP $003C                 ; $0037: C3 3C 00
NATIVE_003A:
        OR E                     ; $003A: B3
        LD E,A                   ; $003B: 5F
NATIVE_003C:
        INC HL                   ; $003C: 23
        LD A,H                   ; $003D: 7C
        CP $40                   ; $003E: FE 40
        JP NZ,$0025              ; $0040: C2 25 00
NATIVE_0043:
        OUT ($02),A              ; $0043: D3 02
        DEC HL                   ; $0045: 2B
        LD A,H                   ; $0046: 7C
        CP $1F                   ; $0047: FE 1F
        JP Z,$0079               ; $0049: CA 79 00
        LD A,(HL)                ; $004C: 7E
        XOR B                    ; $004D: A8
        JP Z,$0060               ; $004E: CA 60 00
        LD C,A                   ; $0051: 4F
        LD A,L                   ; $0052: 7D
        AND $01                  ; $0053: E6 01
        LD A,C                   ; $0055: 79
        JP NZ,$005E              ; $0056: C2 5E 00
        OR D                     ; $0059: B2
        LD D,A                   ; $005A: 57
        JP $0060                 ; $005B: C3 60 00
NATIVE_005E:
        OR E                     ; $005E: B3
        LD E,A                   ; $005F: 5F
NATIVE_0060:
        LD A,B                   ; $0060: 78
        CPL                      ; $0061: 2F
        LD (HL),A                ; $0062: 77
        XOR (HL)                 ; $0063: AE
        JP Z,$0043               ; $0064: CA 43 00
        LD C,A                   ; $0067: 4F
        LD A,L                   ; $0068: 7D
        AND $01                  ; $0069: E6 01
        LD A,C                   ; $006B: 79
        JP NZ,$0074              ; $006C: C2 74 00
        OR D                     ; $006F: B2
        LD D,A                   ; $0070: 57
        JP $0076                 ; $0071: C3 76 00
NATIVE_0074:
        OR E                     ; $0074: B3
        LD E,A                   ; $0075: 5F
NATIVE_0076:
        JP $0043                 ; $0076: C3 43 00
NATIVE_0079:
        OUT ($02),A              ; $0079: D3 02
        INC HL                   ; $007B: 23
        LD A,H                   ; $007C: 7C
        CP $40                   ; $007D: FE 40
        JP Z,$009C               ; $007F: CA 9C 00
        LD A,B                   ; $0082: 78
        CPL                      ; $0083: 2F
        XOR (HL)                 ; $0084: AE
        JP Z,$0097               ; $0085: CA 97 00
        LD C,A                   ; $0088: 4F
        LD A,L                   ; $0089: 7D
        AND $01                  ; $008A: E6 01
        LD A,C                   ; $008C: 79
        JP NZ,$0095              ; $008D: C2 95 00
        OR D                     ; $0090: B2
        LD D,A                   ; $0091: 57
        JP $0097                 ; $0092: C3 97 00
NATIVE_0095:
        OR E                     ; $0095: B3
        LD E,A                   ; $0096: 5F
NATIVE_0097:
        XOR A                    ; $0097: AF
        LD (HL),A                ; $0098: 77
        JP $0079                 ; $0099: C3 79 00
NATIVE_009C:
        LD A,B                   ; $009C: 78
        RLCA                     ; $009D: 07
        LD B,A                   ; $009E: 47
        JP NC,$0022              ; $009F: D2 22 00
        LD A,D                   ; $00A2: 7A
        OR E                     ; $00A3: B3
        JP Z,$00CC               ; $00A4: CA CC 00
        EX DE,HL                 ; $00A7: EB
        LD SP,HL                 ; $00A8: F9
        LD DE,$2000              ; $00A9: 11 00 20
        LD B,$00                 ; $00AC: 06 00
NATIVE_00AE:
        LD HL,$0000              ; $00AE: 21 00 00
        ADD HL,SP                ; $00B1: 39
        LD C,$10                 ; $00B2: 0E 10
NATIVE_00B4:
        XOR A                    ; $00B4: AF
        ADD HL,HL                ; $00B5: 29
        JP C,$00BA               ; $00B6: DA BA 00
        CPL                      ; $00B9: 2F
NATIVE_00BA:
        LD (DE),A                ; $00BA: 12
        INC DE                   ; $00BB: 13
        XOR A                    ; $00BC: AF
        LD (DE),A                ; $00BD: 12
        INC DE                   ; $00BE: 13
        DEC C                    ; $00BF: 0D
        JP NZ,$00B4              ; $00C0: C2 B4 00
        DEC B                    ; $00C3: 05
        JP NZ,$00AE              ; $00C4: C2 AE 00
NATIVE_00C7:
        OUT ($02),A              ; $00C7: D3 02
        JP $00C7                 ; $00C9: C3 C7 00
NATIVE_00CC:
        LD SP,$2400              ; $00CC: 31 00 24
        LD HL,$0000              ; $00CF: 21 00 00
        LD DE,$0000              ; $00D2: 11 00 00
        LD C,$04                 ; $00D5: 0E 04
NATIVE_00D7:
        XOR A                    ; $00D7: AF
NATIVE_00D8:
        OUT ($02),A              ; $00D8: D3 02
        ADD A,(HL)               ; $00DA: 86
        INC HL                   ; $00DB: 23
        LD B,A                   ; $00DC: 47
        LD A,C                   ; $00DD: 79
        CP H                     ; $00DE: BC
        LD A,B                   ; $00DF: 78
        JP NZ,$00D8              ; $00E0: C2 D8 00
        PUSH HL                  ; $00E3: E5
        LD HL,$0120              ; $00E4: 21 20 01
        ADD HL,DE                ; $00E7: 19
        CP (HL)                  ; $00E8: BE
        LD A,$40                 ; $00E9: 3E 40
        JP Z,$00F3               ; $00EB: CA F3 00
        LD HL,$0125              ; $00EE: 21 25 01
        ADD HL,DE                ; $00F1: 19
        LD A,(HL)                ; $00F2: 7E
NATIVE_00F3:
        LD HL,$2036              ; $00F3: 21 36 20
        ADD HL,DE                ; $00F6: 19
        LD (HL),A                ; $00F7: 77
        POP HL                   ; $00F8: E1
        INC DE                   ; $00F9: 13
        INC C                    ; $00FA: 0C
        INC C                    ; $00FB: 0C
        INC C                    ; $00FC: 0C
        INC C                    ; $00FD: 0C
        LD A,$14                 ; $00FE: 3E 14
        CP C                     ; $0100: B9
        JP NZ,$00D7              ; $0101: C2 D7 00
        LD HL,$2039              ; $0104: 21 39 20
        LD A,(HL)                ; $0107: 7E
        DEC HL                   ; $0108: 2B
        OR (HL)                  ; $0109: B6
        DEC HL                   ; $010A: 2B
        OR (HL)                  ; $010B: B6
        DEC HL                   ; $010C: 2B
        OR (HL)                  ; $010D: B6
        AND $BF                  ; $010E: E6 BF
        JP Z,$0000               ; $0110: CA 00 00
        LD DE,$3008              ; $0113: 11 08 30
        LD A,$04                 ; $0116: 3E 04
        CALL $0129               ; $0118: CD 29 01
NATIVE_011B:
        OUT ($02),A              ; $011B: D3 02
        JP $011B                 ; $011D: C3 1B 01
        DB $00,$A1,$C1,$EE,$58,$48,$48,$47,$47 ; $0120-$0128 source data/unclassified
; Original native text/glyph rendering entry at $0129.
; Entry HL -> encoded text, DE -> framebuffer destination, A = item count.
; Glyph bytes write at +$20 bitmap stride for ten rows; stream bytes
; below $30 advance position and other characters index the font below.
DRAW_TEXT_GLYPH_STREAM:
        PUSH AF                  ; $0129: F5
NATIVE_012A:
        LD A,(HL)                ; $012A: 7E
        INC HL                   ; $012B: 23
        SUB $30                  ; $012C: D6 30
        JP P,$0142               ; $012E: F2 42 01
        LD B,A                   ; $0131: 47
NATIVE_0132:
        INC DE                   ; $0132: 13
        LD A,E                   ; $0133: 7B
        AND $1F                  ; $0134: E6 1F
        JP NZ,$013B              ; $0136: C2 3B 01
        INC D                    ; $0139: 14
        INC D                    ; $013A: 14
NATIVE_013B:
        INC B                    ; $013B: 04
        JP NZ,$0132              ; $013C: C2 32 01
        JP $012A                 ; $013F: C3 2A 01
NATIVE_0142:
        PUSH HL                  ; $0142: E5
        PUSH DE                  ; $0143: D5
        INC A                    ; $0144: 3C
        CP $0B                   ; $0145: FE 0B
        JP M,$014C               ; $0147: FA 4C 01
        SUB $06                  ; $014A: D6 06
NATIVE_014C:
        LD HL,$0166              ; $014C: 21 66 01
        LD BC,$000A              ; $014F: 01 0A 00
NATIVE_0152:
        ADD HL,BC                ; $0152: 09
        DEC A                    ; $0153: 3D
        JP NZ,$0152              ; $0154: C2 52 01
        EX DE,HL                 ; $0157: EB
        LD BC,$0020              ; $0158: 01 20 00
        LD A,$0A                 ; $015B: 3E 0A
NATIVE_015D:
        PUSH AF                  ; $015D: F5
        LD A,(DE)                ; $015E: 1A
        INC DE                   ; $015F: 13
        LD (HL),A                ; $0160: 77
        ADD HL,BC                ; $0161: 09
        POP AF                   ; $0162: F1
        DEC A                    ; $0163: 3D
        JP NZ,$015D              ; $0164: C2 5D 01
        POP DE                   ; $0167: D1
        POP HL                   ; $0168: E1
        INC DE                   ; $0169: 13
        POP AF                   ; $016A: F1
        DEC A                    ; $016B: 3D
        JP NZ,$0129              ; $016C: C2 29 01
        RET                      ; $016F: C9
; Original 37 glyphs: ten numeric glyphs, space and 26 uppercase letters.
; Each glyph is ten vertical rows, eight pixels per byte.
; Native drawing routine $0129 writes each row with a $20-byte screen stride.
FONT_37_GLYPHS_10_ROWS:        ; $0170-$02E1
FONT_DIGIT_0:          ; $0170 ten original bitmap rows
        DB $3C,$7E,$66,$66,$66,$66,$66,$66,$7E,$3C
FONT_DIGIT_1:          ; $017A ten original bitmap rows
        DB $18,$1C,$18,$18,$18,$18,$18,$18,$3C,$3C
FONT_DIGIT_2:          ; $0184 ten original bitmap rows
        DB $3C,$7E,$66,$60,$7C,$3E,$06,$06,$7E,$7E
FONT_DIGIT_3:          ; $018E ten original bitmap rows
        DB $3C,$7E,$66,$60,$38,$78,$60,$66,$7E,$3C
FONT_DIGIT_4:          ; $0198 ten original bitmap rows
        DB $66,$66,$66,$66,$7E,$7E,$60,$60,$60,$60
FONT_DIGIT_5:          ; $01A2 ten original bitmap rows
        DB $3E,$3E,$06,$06,$3E,$7E,$60,$66,$7E,$3C
FONT_DIGIT_6:          ; $01AC ten original bitmap rows
        DB $3C,$3E,$06,$06,$3E,$7E,$66,$66,$7E,$3C
FONT_DIGIT_7:          ; $01B6 ten original bitmap rows
        DB $7E,$7E,$60,$70,$30,$38,$18,$1C,$0C,$0C
FONT_DIGIT_8:          ; $01C0 ten original bitmap rows
        DB $3C,$7E,$66,$66,$3C,$7E,$66,$66,$7E,$3C
FONT_DIGIT_9:          ; $01CA ten original bitmap rows
        DB $3C,$7E,$66,$66,$7E,$7C,$60,$60,$7C,$3C
FONT_SPACE:          ; $01D4 ten original bitmap rows
        DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
FONT_LETTER_A:          ; $01DE ten original bitmap rows
        DB $18,$3C,$7E,$66,$66,$66,$7E,$7E,$66,$66
FONT_LETTER_B:          ; $01E8 ten original bitmap rows
        DB $3E,$7E,$66,$66,$3E,$7E,$66,$66,$7E,$3E
FONT_LETTER_C:          ; $01F2 ten original bitmap rows
        DB $3C,$7E,$66,$06,$06,$06,$06,$66,$7E,$3C
FONT_LETTER_D:          ; $01FC ten original bitmap rows
        DB $3E,$7E,$66,$66,$66,$66,$66,$66,$7E,$3E
FONT_LETTER_E:          ; $0206 ten original bitmap rows
        DB $7E,$7E,$06,$06,$3E,$3E,$06,$06,$7E,$7E
FONT_LETTER_F:          ; $0210 ten original bitmap rows
        DB $7E,$7E,$06,$06,$3E,$3E,$06,$06,$06,$06
FONT_LETTER_G:          ; $021A ten original bitmap rows
        DB $3C,$7E,$66,$06,$06,$76,$76,$66,$7E,$3C
FONT_LETTER_H:          ; $0224 ten original bitmap rows
        DB $66,$66,$66,$66,$7E,$7E,$66,$66,$66,$66
FONT_LETTER_I:          ; $022E ten original bitmap rows
        DB $3C,$3C,$18,$18,$18,$18,$18,$18,$3C,$3C
FONT_LETTER_J:          ; $0238 ten original bitmap rows
        DB $C0,$C0,$C0,$C0,$C0,$C0,$00,$00,$C0,$C0
FONT_LETTER_K:          ; $0242 ten original bitmap rows
        DB $66,$66,$76,$3E,$1E,$1E,$3E,$76,$66,$66
FONT_LETTER_L:          ; $024C ten original bitmap rows
        DB $06,$06,$06,$06,$06,$06,$06,$06,$7E,$7E
FONT_LETTER_M:          ; $0256 ten original bitmap rows
        DB $C3,$C3,$E7,$E7,$FF,$FF,$DB,$C3,$C3,$C3
FONT_LETTER_N:          ; $0260 ten original bitmap rows
        DB $66,$66,$6E,$6E,$7E,$7E,$76,$76,$66,$66
FONT_LETTER_O:          ; $026A ten original bitmap rows
        DB $3C,$7E,$66,$66,$66,$66,$66,$66,$7E,$3C
FONT_LETTER_P:          ; $0274 ten original bitmap rows
        DB $3E,$7E,$66,$66,$7E,$3E,$06,$06,$06,$06
FONT_LETTER_Q:          ; $027E ten original bitmap rows
        DB $00,$00,$08,$08,$08,$49,$6B,$3E,$1C,$08
FONT_LETTER_R:          ; $0288 ten original bitmap rows
        DB $3E,$7E,$66,$66,$7E,$3E,$76,$66,$66,$66
FONT_LETTER_S:          ; $0292 ten original bitmap rows
        DB $3C,$7E,$66,$06,$3E,$7C,$60,$66,$7E,$3C
FONT_LETTER_T:          ; $029C ten original bitmap rows
        DB $7E,$7E,$18,$18,$18,$18,$18,$18,$18,$18
FONT_LETTER_U:          ; $02A6 ten original bitmap rows
        DB $66,$66,$66,$66,$66,$66,$66,$66,$7E,$3C
FONT_LETTER_V:          ; $02B0 ten original bitmap rows
        DB $66,$66,$66,$66,$66,$7E,$3C,$3C,$18,$18
FONT_LETTER_W:          ; $02BA ten original bitmap rows
        DB $C3,$C3,$C3,$DB,$FF,$FF,$E7,$E7,$C3,$C3
FONT_LETTER_X:          ; $02C4 ten original bitmap rows
        DB $00,$18,$18,$00,$00,$00,$00,$18,$18,$00
FONT_LETTER_Y:          ; $02CE ten original bitmap rows
        DB $66,$66,$7E,$3C,$18,$18,$18,$18,$18,$18
FONT_LETTER_Z:          ; $02D8 ten original bitmap rows
        DB $7E,$7E,$60,$70,$38,$1C,$0E,$06,$7E,$7E
NATIVE_02E2:
        XOR A                    ; $02E2: AF
        CALL $0302               ; $02E3: CD 02 03
        LD (HL),A                ; $02E6: 77
        CALL $061E               ; $02E7: CD 1E 06
        CALL $0341               ; $02EA: CD 41 03
        LD HL,$2055              ; $02ED: 21 55 20
        CALL $0962               ; $02F0: CD 62 09
        CALL $04BE               ; $02F3: CD BE 04
        CALL $049B               ; $02F6: CD 9B 04
        CALL $0453               ; $02F9: CD 53 04
NATIVE_02FC:
        POP HL                   ; $02FC: E1
        POP DE                   ; $02FD: D1
        POP BC                   ; $02FE: C1
        POP AF                   ; $02FF: F1
        EI                       ; $0300: FB
        RET                      ; $0301: C9
NATIVE_0302:
        LD HL,$202F              ; $0302: 21 2F 20
        CP (HL)                  ; $0305: BE
        RET NZ                   ; $0306: C0
        POP HL                   ; $0307: E1
        JP $02FC                 ; $0308: C3 FC 02

FRAME_SERVICE:
        LD A,$10                 ; $030B: 3E 10
        CALL $0302               ; $030D: CD 02 03
        LD (HL),A                ; $0310: 77
        CALL $061E               ; $0311: CD 1E 06
        CALL $05A2               ; $0314: CD A2 05
        CALL $05F9               ; $0317: CD F9 05
        LD A,($2030)             ; $031A: 3A 30 20
        DEC A                    ; $031D: 3D
        JP NZ,$0338              ; $031E: C2 38 03
        LD A,($2020)             ; $0321: 3A 20 20
        AND A                    ; $0324: A7
        JP Z,$02FC               ; $0325: CA FC 02
        LD HL,$2033              ; $0328: 21 33 20
        INC (HL)                 ; $032B: 34
        LD A,($2013)             ; $032C: 3A 13 20
        CP (HL)                  ; $032F: BE
        JP NZ,$02FC              ; $0330: C2 FC 02
        LD (HL),$00              ; $0333: 36 00
        CALL $0A32               ; $0335: CD 32 0A
NATIVE_0338:
        LD HL,$2044              ; $0338: 21 44 20
        CALL $0962               ; $033B: CD 62 09
        JP $02FC                 ; $033E: C3 FC 02

PERIODIC_TIMER_SERVICE:
        LD HL,$2035              ; $0341: 21 35 20
        LD A,(HL)                ; $0344: 7E
        AND A                    ; $0345: A7
        RET NZ                   ; $0346: C0
        LD B,A                   ; $0347: 47
        LD HL,$200A              ; $0348: 21 0A 20
        DEC (HL)                 ; $034B: 35
        JP NZ,$0357              ; $034C: C2 57 03
        LD (HL),$3C              ; $034F: 36 3C
        LD HL,$200B              ; $0351: 21 0B 20
        CALL $0369               ; $0354: CD 69 03
NATIVE_0357:
        LD HL,$200C              ; $0357: 21 0C 20
        CALL $0369               ; $035A: CD 69 03
        INC HL                   ; $035D: 23
        CALL $0369               ; $035E: CD 69 03
        INC HL                   ; $0361: 23
        CALL $0369               ; $0362: CD 69 03
        LD ($2035),A             ; $0365: 32 35 20
        RET                      ; $0368: C9

TIMER_DECREMENT:
        LD A,(HL)                ; $0369: 7E
        AND A                    ; $036A: A7
        JP Z,$0373               ; $036B: CA 73 03
        DEC (HL)                 ; $036E: 35
        JP NZ,$0373              ; $036F: C2 73 03
        SCF                      ; $0372: 37
NATIVE_0373:
        LD A,B                   ; $0373: 78
        RLA                      ; $0374: 17
        LD B,A                   ; $0375: 47
        RET                      ; $0376: C9

INIT_SCRIPT_ROOT:
        LD A,$10                 ; $0377: 3E 10
        CALL $08EE               ; $0379: CD EE 08
        LD HL,$0D64              ; $037C: 21 64 0D
        LD ($2002),HL            ; $037F: 22 02 20
        LD HL,$FFFF              ; $0382: 21 FF FF
        LD ($2004),HL            ; $0385: 22 04 20
        LD ($2006),HL            ; $0388: 22 06 20
        EI                       ; $038B: FB
        LD HL,$038B              ; $038C: 21 8B 03
        PUSH HL                  ; $038F: E5
        OUT ($02),A              ; $0390: D3 02

SCRIPT_INITIALIZE:
        LD HL,($2002)            ; $0392: 2A 02 20
        LD A,H                   ; $0395: 7C
        OR L                     ; $0396: B5
        JP Z,$03AA               ; $0397: CA AA 03
        XOR A                    ; $039A: AF
        LD ($200B),A             ; $039B: 32 0B 20
        LD ($200C),A             ; $039E: 32 0C 20
        LD ($2000),HL            ; $03A1: 22 00 20
        LD HL,$0000              ; $03A4: 21 00 00
        LD ($2002),HL            ; $03A7: 22 02 20

SCRIPT_FETCH:
        LD HL,($2000)            ; $03AA: 2A 00 20
        LD A,(HL)                ; $03AD: 7E
        AND A                    ; $03AE: A7
        JP Z,$03CA               ; $03AF: CA CA 03
        INC HL                   ; $03B2: 23
        LD ($2000),HL            ; $03B3: 22 00 20
        EX DE,HL                 ; $03B6: EB
        LD HL,$0BEE              ; $03B7: 21 EE 0B
        DEC A                    ; $03BA: 3D
        CP $11                   ; $03BB: FE 11
        JP NC,$0377              ; $03BD: D2 77 03
        ADD A,A                  ; $03C0: 87
        LD C,A                   ; $03C1: 4F
        LD B,$00                 ; $03C2: 06 00
        ADD HL,BC                ; $03C4: 09
        LD A,(HL)                ; $03C5: 7E
        INC HL                   ; $03C6: 23
        LD H,(HL)                ; $03C7: 66
        LD L,A                   ; $03C8: 6F
        JP (HL)                  ; $03C9: E9

ZERO_COMMAND:
        LD A,($201F)             ; $03CA: 3A 1F 20
        AND A                    ; $03CD: A7
        CALL Z,$03D4             ; $03CE: CC D4 03
        RET                      ; $03D1: C9
        DB $00,$00 ; $03D2-$03D3 source data/unclassified

ZERO_COMMAND_EVENT:
        CALL $0403               ; $03D4: CD 03 04
        XOR A                    ; $03D7: AF
        LD ($201C),A             ; $03D8: 32 1C 20
        CALL $06E8               ; $03DB: CD E8 06
        CALL $06F5               ; $03DE: CD F5 06
NATIVE_03E1:
        CALL $070E               ; $03E1: CD 0E 07
        OUT ($02),A              ; $03E4: D3 02
        LD A,E                   ; $03E6: 7B
        AND A                    ; $03E7: A7
        JP Z,$03F1               ; $03E8: CA F1 03
        CALL $0780               ; $03EB: CD 80 07
        JP $03E1                 ; $03EE: C3 E1 03
NATIVE_03F1:
        LD A,($201D)             ; $03F1: 3A 1D 20
        AND A                    ; $03F4: A7
        JP Z,$03D4               ; $03F5: CA D4 03
        CALL $080D               ; $03F8: CD 0D 08
        JP C,$03E1               ; $03FB: DA E1 03
        INC A                    ; $03FE: 3C
        LD ($201F),A             ; $03FF: 32 1F 20
        RET                      ; $0402: C9
NATIVE_0403:
        LD DE,$2066              ; $0403: 11 66 20
        LD B,$1A                 ; $0406: 06 1A
NATIVE_0408:
        LD C,$18                 ; $0408: 0E 18
NATIVE_040A:
        LD A,(DE)                ; $040A: 1A
        AND $F0                  ; $040B: E6 F0
        LD (DE),A                ; $040D: 12
        INC DE                   ; $040E: 13
        DEC C                    ; $040F: 0D
        JP NZ,$040A              ; $0410: C2 0A 04
        DEC B                    ; $0413: 05
        JP NZ,$0408              ; $0414: C2 08 04
        RET                      ; $0417: C9
        DB $C9 ; $0418-$0418 source data/unclassified

CMD_06_INIT_GAME_FIELDS:
        CALL $043D               ; $0419: CD 3D 04
        XOR A                    ; $041C: AF
        LD HL,$2015              ; $041D: 21 15 20
        LD B,$0D                 ; $0420: 06 0D
NATIVE_0422:
        LD (HL),A                ; $0422: 77
        INC HL                   ; $0423: 23
        DEC B                    ; $0424: 05
        JP NZ,$0422              ; $0425: C2 22 04
        LD HL,$2023              ; $0428: 21 23 20
        LD A,(HL)                ; $042B: 7E
        INC HL                   ; $042C: 23
        LD (HL),A                ; $042D: 77
        INC HL                   ; $042E: 23
        LD A,(HL)                ; $042F: 7E
        INC HL                   ; $0430: 23
        LD (HL),A                ; $0431: 77
        LD HL,$2040              ; $0432: 21 40 20
        LD C,(HL)                ; $0435: 4E
        INC HL                   ; $0436: 23
        LD B,(HL)                ; $0437: 46
        INC HL                   ; $0438: 23
        LD (HL),C                ; $0439: 71
        INC HL                   ; $043A: 23
        LD (HL),B                ; $043B: 70
        RET                      ; $043C: C9
NATIVE_043D:
        LD DE,$2066              ; $043D: 11 66 20
        LD BC,$0370              ; $0440: 01 70 03
NATIVE_0443:
        LD A,(DE)                ; $0443: 1A
        ADD A,A                  ; $0444: 87
        ADD A,A                  ; $0445: 87
        ADD A,A                  ; $0446: 87
        ADD A,A                  ; $0447: 87
        LD (DE),A                ; $0448: 12
        INC DE                   ; $0449: 13
        DEC C                    ; $044A: 0D
        JP NZ,$0443              ; $044B: C2 43 04
        DEC B                    ; $044E: 05
        JP NZ,$0443              ; $044F: C2 43 04
        RET                      ; $0452: C9
NATIVE_0453:
        LD A,($201E)             ; $0453: 3A 1E 20
        AND A                    ; $0456: A7
        RET NZ                   ; $0457: C0
        LD B,$01                 ; $0458: 06 01
        LD HL,$2045              ; $045A: 21 45 20
        LD DE,$2056              ; $045D: 11 56 20
        LD A,(DE)                ; $0460: 1A
        SUB $10                  ; $0461: D6 10
        JP Z,$046B               ; $0463: CA 6B 04
        INC B                    ; $0466: 04
        LD A,(HL)                ; $0467: 7E
        SUB $E6                  ; $0468: D6 E6
        RET NZ                   ; $046A: C0
NATIVE_046B:
        LD (HL),A                ; $046B: 77
        DEC HL                   ; $046C: 2B
        LD (HL),A                ; $046D: 77
        EX DE,HL                 ; $046E: EB
        LD (HL),A                ; $046F: 77
        DEC HL                   ; $0470: 2B
        LD (HL),A                ; $0471: 77
        LD ($200D),A             ; $0472: 32 0D 20
        LD A,B                   ; $0475: 78
        LD ($200C),A             ; $0476: 32 0C 20
        LD ($201E),A             ; $0479: 32 1E 20
        LD HL,$2031              ; $047C: 21 31 20
        LD DE,$201A              ; $047F: 11 1A 20
        DEC A                    ; $0482: 3D
        JP Z,$0488               ; $0483: CA 88 04
        INC DE                   ; $0486: 13
        INC HL                   ; $0487: 23
NATIVE_0488:
        LD A,(HL)                ; $0488: 7E
        INC A                    ; $0489: 3C
        DAA                      ; $048A: 27
        LD (HL),A                ; $048B: 77
        LD (DE),A                ; $048C: 12
        LD HL,$202E              ; $048D: 21 2E 20
        LD A,(HL)                ; $0490: 7E
        ADD A,$99                ; $0491: C6 99
        DAA                      ; $0493: 27
        JP M,$08AC               ; $0494: FA AC 08
        LD (HL),A                ; $0497: 77
        JP $08AC                 ; $0498: C3 AC 08
NATIVE_049B:
        IN A,($00)               ; $049B: DB 00
        LD B,A                   ; $049D: 47
        IN A,($00)               ; $049E: DB 00
        CP B                     ; $04A0: B8
        RET NZ                   ; $04A1: C0
        LD DE,$2055              ; $04A2: 11 55 20
        CALL $04B5               ; $04A5: CD B5 04
        LD A,($2030)             ; $04A8: 3A 30 20
        DEC A                    ; $04AB: 3D
        RET Z                    ; $04AC: C8
        LD A,B                   ; $04AD: 78
        RRCA                     ; $04AE: 0F
        RRCA                     ; $04AF: 0F
        RRCA                     ; $04B0: 0F
        RRCA                     ; $04B1: 0F
        LD DE,$2044              ; $04B2: 11 44 20
NATIVE_04B5:
        AND $0F                  ; $04B5: E6 0F
        LD C,A                   ; $04B7: 4F
        LD A,(DE)                ; $04B8: 1A
        AND $F0                  ; $04B9: E6 F0
        OR C                     ; $04BB: B1
        LD (DE),A                ; $04BC: 12

CMD_01_RETURN_SCRIPT:
        RET                      ; $04BD: C9
NATIVE_04BE:
        LD HL,$2035              ; $04BE: 21 35 20
        LD A,(HL)                ; $04C1: 7E
        AND A                    ; $04C2: A7
        RET Z                    ; $04C3: C8
        LD (HL),$00              ; $04C4: 36 00
        RRA                      ; $04C6: 1F
        PUSH AF                  ; $04C7: F5
        CALL C,$04DB             ; $04C8: DC DB 04
        POP AF                   ; $04CB: F1
        RRA                      ; $04CC: 1F
        PUSH AF                  ; $04CD: F5
        CALL C,$0514             ; $04CE: DC 14 05
        POP AF                   ; $04D1: F1
        RRA                      ; $04D2: 1F
        CALL C,$0593             ; $04D3: DC 93 05
        RRA                      ; $04D6: 1F
        CALL C,$059B             ; $04D7: DC 9B 05
        RET                      ; $04DA: C9
NATIVE_04DB:
        LD HL,$2029              ; $04DB: 21 29 20
        DEC (HL)                 ; $04DE: 35
        JP NZ,$0500              ; $04DF: C2 00 05
        LD A,$01                 ; $04E2: 3E 01
        LD ($200D),A             ; $04E4: 32 0D 20
        LD ($2020),A             ; $04E7: 32 20 20
        LD HL,$0C10              ; $04EA: 21 10 0C
        LD DE,$3EA0              ; $04ED: 11 A0 3E
        LD A,$0A                 ; $04F0: 3E 0A
        CALL $0129               ; $04F2: CD 29 01
        LD HL,$0CAD              ; $04F5: 21 AD 0C
        LD DE,$3EA3              ; $04F8: 11 A3 3E
        LD A,$04                 ; $04FB: 3E 04
        JP $0129                 ; $04FD: C3 29 01
NATIVE_0500:
        LD A,$3C                 ; $0500: 3E 3C
        LD ($200E),A             ; $0502: 32 0E 20
        LD A,(HL)                ; $0505: 7E
        OR $30                   ; $0506: F6 30
        LD HL,$2036              ; $0508: 21 36 20
        LD (HL),A                ; $050B: 77
        LD A,$01                 ; $050C: 3E 01
        LD DE,$3EAB              ; $050E: 11 AB 3E
        JP $0129                 ; $0511: C3 29 01
NATIVE_0514:
        LD A,$3C                 ; $0514: 3E 3C
        LD ($200D),A             ; $0516: 32 0D 20
        LD A,($202C)             ; $0519: 3A 2C 20
        AND A                    ; $051C: A7
        JP Z,$0554               ; $051D: CA 54 05
        LD HL,$202B              ; $0520: 21 2B 20
        LD A,(HL)                ; $0523: 7E
        ADD A,$99                ; $0524: C6 99
        DAA                      ; $0526: 27
        LD (HL),A                ; $0527: 77
        JP P,$054B               ; $0528: F2 4B 05
        LD (HL),$59              ; $052B: 36 59
        DEC HL                   ; $052D: 2B
        DEC (HL)                 ; $052E: 35
        JP P,$054B               ; $052F: F2 4B 05
        LD HL,$0D64              ; $0532: 21 64 0D
        LD ($2002),HL            ; $0535: 22 02 20
        LD HL,$200B              ; $0538: 21 0B 20
        LD B,$05                 ; $053B: 06 05
        XOR A                    ; $053D: AF
NATIVE_053E:
        LD (HL),A                ; $053E: 77
        INC HL                   ; $053F: 23
        DEC B                    ; $0540: 05
        JP NZ,$053E              ; $0541: C2 3E 05
        LD ($2044),A             ; $0544: 32 44 20
        LD ($2055),A             ; $0547: 32 55 20
        RET                      ; $054A: C9
NATIVE_054B:
        LD HL,$3EB8              ; $054B: 21 B8 3E
        LD DE,$202A              ; $054E: 11 2A 20
        CALL $056D               ; $0551: CD 6D 05
NATIVE_0554:
        LD HL,$2019              ; $0554: 21 19 20
        LD A,(HL)                ; $0557: 7E
        INC A                    ; $0558: 3C
        DAA                      ; $0559: 27
        LD (HL),A                ; $055A: 77
        CP $60                   ; $055B: FE 60
        JP NZ,$0567              ; $055D: C2 67 05
        LD (HL),$00              ; $0560: 36 00
        DEC HL                   ; $0562: 2B
        LD A,(HL)                ; $0563: 7E
        INC A                    ; $0564: 3C
        DAA                      ; $0565: 27
        LD (HL),A                ; $0566: 77
NATIVE_0567:
        LD HL,$3EA8              ; $0567: 21 A8 3E
        LD DE,$2018              ; $056A: 11 18 20
NATIVE_056D:
        LD BC,$2036              ; $056D: 01 36 20
        CALL $0634               ; $0570: CD 34 06
        LD A,$58                 ; $0573: 3E 58
        LD (BC),A                ; $0575: 02
        INC BC                   ; $0576: 03
        CALL $0634               ; $0577: CD 34 06
        EX DE,HL                 ; $057A: EB
        LD HL,$2036              ; $057B: 21 36 20
        PUSH HL                  ; $057E: E5
        CALL $058C               ; $057F: CD 8C 05
        INC HL                   ; $0582: 23
        CALL $058C               ; $0583: CD 8C 05
        POP HL                   ; $0586: E1
        LD A,$05                 ; $0587: 3E 05
        JP $0129                 ; $0589: C3 29 01
NATIVE_058C:
        LD A,(HL)                ; $058C: 7E
        CP $30                   ; $058D: FE 30
        RET NZ                   ; $058F: C0
        LD (HL),$40              ; $0590: 36 40
        RET                      ; $0592: C9
NATIVE_0593:
        LD HL,($2000)            ; $0593: 2A 00 20
        INC HL                   ; $0596: 23
        LD ($2000),HL            ; $0597: 22 00 20
        RET                      ; $059A: C9
NATIVE_059B:
        LD HL,($2008)            ; $059B: 2A 08 20
        LD ($2002),HL            ; $059E: 22 02 20
        RET                      ; $05A1: C9
NATIVE_05A2:
        LD HL,$2028              ; $05A2: 21 28 20
        IN A,($01)               ; $05A5: DB 01
        LD C,A                   ; $05A7: 4F
        AND $08                  ; $05A8: E6 08
        LD B,A                   ; $05AA: 47
        XOR (HL)                 ; $05AB: AE
        RET Z                    ; $05AC: C8
        LD (HL),B                ; $05AD: 70
        LD A,B                   ; $05AE: 78
        AND A                    ; $05AF: A7
        RET Z                    ; $05B0: C8
        OUT ($01),A              ; $05B1: D3 01
        LD HL,$2014              ; $05B3: 21 14 20
        INC (HL)                 ; $05B6: 34
        LD A,C                   ; $05B7: 79
        RRA                      ; $05B8: 1F
        RRA                      ; $05B9: 1F
        RRA                      ; $05BA: 1F
        RRA                      ; $05BB: 1F
        AND $01                  ; $05BC: E6 01
        CP (HL)                  ; $05BE: BE
        RET P                    ; $05BF: F0
        LD (HL),$00              ; $05C0: 36 00
        LD HL,$2027              ; $05C2: 21 27 20
        INC (HL)                 ; $05C5: 34
        LD A,C                   ; $05C6: 79
        AND $20                  ; $05C7: E6 20
        JP Z,$05D4               ; $05C9: CA D4 05
        INC (HL)                 ; $05CC: 34
        LD A,C                   ; $05CD: 79
        AND $10                  ; $05CE: E6 10
        JP Z,$05D4               ; $05D0: CA D4 05
        INC (HL)                 ; $05D3: 34
NATIVE_05D4:
        LD A,($202D)             ; $05D4: 3A 2D 20
        AND A                    ; $05D7: A7
        RET NZ                   ; $05D8: C0

CMD_11_UPDATE_END_STATE:
        LD HL,$2027              ; $05D9: 21 27 20
        XOR A                    ; $05DC: AF
        CP (HL)                  ; $05DD: BE
        RET Z                    ; $05DE: C8
        DEC (HL)                 ; $05DF: 35
        LD A,$03                 ; $05E0: 3E 03
        LD ($202E),A             ; $05E2: 32 2E 20
        LD ($202D),A             ; $05E5: 32 2D 20
        LD HL,$0E27              ; $05E8: 21 27 0E
        LD ($2002),HL            ; $05EB: 22 02 20
NATIVE_05EE:
        LD HL,$0CF1              ; $05EE: 21 F1 0C
        LD DE,$3EA3              ; $05F1: 11 A3 3E
        LD A,$04                 ; $05F4: 3E 04
        JP $0129                 ; $05F6: C3 29 01
NATIVE_05F9:
        LD DE,$2034              ; $05F9: 11 34 20
        LD A,(DE)                ; $05FC: 1A
        AND A                    ; $05FD: A7
        RET Z                    ; $05FE: C8
        IN A,($01)               ; $05FF: DB 01
        LD B,A                   ; $0601: 47
        LD HL,$0E5F              ; $0602: 21 5F 0E
        AND $01                  ; $0605: E6 01
        LD A,$01                 ; $0607: 3E 01
        JP NZ,$0615              ; $0609: C2 15 06
        LD HL,$0F31              ; $060C: 21 31 0F
        LD A,B                   ; $060F: 78
        AND $02                  ; $0610: E6 02
        LD A,$02                 ; $0612: 3E 02
        RET Z                    ; $0614: C8
NATIVE_0615:
        LD ($2030),A             ; $0615: 32 30 20
        LD ($2002),HL            ; $0618: 22 02 20
        XOR A                    ; $061B: AF
        LD (DE),A                ; $061C: 12
        RET                      ; $061D: C9
NATIVE_061E:
        LD HL,$2044              ; $061E: 21 44 20
        PUSH HL                  ; $0621: E5
        CALL $06AF               ; $0622: CD AF 06
        LD HL,$2055              ; $0625: 21 55 20
        PUSH HL                  ; $0628: E5
        CALL $06AF               ; $0629: CD AF 06
        POP HL                   ; $062C: E1
        CALL $0648               ; $062D: CD 48 06
        POP HL                   ; $0630: E1
        JP $0648                 ; $0631: C3 48 06
NATIVE_0634:
        LD A,(DE)                ; $0634: 1A
        RRA                      ; $0635: 1F
        RRA                      ; $0636: 1F
        RRA                      ; $0637: 1F
        RRA                      ; $0638: 1F
        AND $0F                  ; $0639: E6 0F
        ADD A,$30                ; $063B: C6 30
        LD (BC),A                ; $063D: 02
        INC BC                   ; $063E: 03
        LD A,(DE)                ; $063F: 1A
        INC DE                   ; $0640: 13
        AND $0F                  ; $0641: E6 0F
        ADD A,$30                ; $0643: C6 30
        LD (BC),A                ; $0645: 02
        INC BC                   ; $0646: 03
        RET                      ; $0647: C9
NATIVE_0648:
        LD A,($202F)             ; $0648: 3A 2F 20
        XOR (HL)                 ; $064B: AE
        AND $10                  ; $064C: E6 10
        RET NZ                   ; $064E: C0
        LD A,(HL)                ; $064F: 7E
        AND A                    ; $0650: A7
        RET P                    ; $0651: F0
        OR $20                   ; $0652: F6 20
        LD B,A                   ; $0654: 47
        AND $40                  ; $0655: E6 40
        JP NZ,$065C              ; $0657: C2 5C 06
        LD B,$00                 ; $065A: 06 00
NATIVE_065C:
        LD (HL),B                ; $065C: 70
        INC HL                   ; $065D: 23
        LD E,(HL)                ; $065E: 5E
        INC HL                   ; $065F: 23
        LD D,(HL)                ; $0660: 56
        INC HL                   ; $0661: 23
        LD A,E                   ; $0662: 7B
        AND $07                  ; $0663: E6 07
        LD ($2015),A             ; $0665: 32 15 20
        CALL $06D6               ; $0668: CD D6 06
        LD C,(HL)                ; $066B: 4E
        INC HL                   ; $066C: 23
        LD B,(HL)                ; $066D: 46
        INC HL                   ; $066E: 23
        LD (HL),E                ; $066F: 73
        INC HL                   ; $0670: 23
        LD (HL),D                ; $0671: 72
        INC HL                   ; $0672: 23
        EX DE,HL                 ; $0673: EB
        LD A,$05                 ; $0674: 3E 05
NATIVE_0676:
        PUSH AF                  ; $0676: F5
        LD A,(HL)                ; $0677: 7E
        LD (DE),A                ; $0678: 12
        INC DE                   ; $0679: 13
        LD A,(BC)                ; $067A: 0A
        INC BC                   ; $067B: 03
        CALL $0697               ; $067C: CD 97 06
        OR (HL)                  ; $067F: B6
        LD (HL),A                ; $0680: 77
        INC HL                   ; $0681: 23
        LD A,(HL)                ; $0682: 7E
        LD (DE),A                ; $0683: 12
        INC DE                   ; $0684: 13
        XOR A                    ; $0685: AF
        CALL $0697               ; $0686: CD 97 06
        OR (HL)                  ; $0689: B6
        LD (HL),A                ; $068A: 77
        PUSH DE                  ; $068B: D5
        LD DE,$001F              ; $068C: 11 1F 00
        ADD HL,DE                ; $068F: 19
        POP DE                   ; $0690: D1
        POP AF                   ; $0691: F1
        DEC A                    ; $0692: 3D
        JP NZ,$0676              ; $0693: C2 76 06
        RET                      ; $0696: C9
NATIVE_0697:
        PUSH HL                  ; $0697: E5
        LD HL,($2016)            ; $0698: 2A 16 20
        LD L,H                   ; $069B: 6C
        LD H,A                   ; $069C: 67
        LD ($2016),HL            ; $069D: 22 16 20
        LD A,($2015)             ; $06A0: 3A 15 20
        AND A                    ; $06A3: A7
        JP Z,$06AC               ; $06A4: CA AC 06
NATIVE_06A7:
        ADD HL,HL                ; $06A7: 29
        DEC A                    ; $06A8: 3D
        JP NZ,$06A7              ; $06A9: C2 A7 06
NATIVE_06AC:
        LD A,H                   ; $06AC: 7C
        POP HL                   ; $06AD: E1
        RET                      ; $06AE: C9
NATIVE_06AF:
        LD A,($202F)             ; $06AF: 3A 2F 20
        XOR (HL)                 ; $06B2: AE
        AND $10                  ; $06B3: E6 10
        RET NZ                   ; $06B5: C0
        LD A,(HL)                ; $06B6: 7E
        AND $20                  ; $06B7: E6 20
        RET Z                    ; $06B9: C8
        LD BC,$0005              ; $06BA: 01 05 00
        ADD HL,BC                ; $06BD: 09
        LD E,(HL)                ; $06BE: 5E
        INC HL                   ; $06BF: 23
        LD D,(HL)                ; $06C0: 56
        INC HL                   ; $06C1: 23
        EX DE,HL                 ; $06C2: EB
        LD C,$05                 ; $06C3: 0E 05
NATIVE_06C5:
        LD A,(DE)                ; $06C5: 1A
        INC DE                   ; $06C6: 13
        LD (HL),A                ; $06C7: 77
        INC HL                   ; $06C8: 23
        LD A,(DE)                ; $06C9: 1A
        INC DE                   ; $06CA: 13
        LD (HL),A                ; $06CB: 77
        LD A,C                   ; $06CC: 79
        LD C,$1F                 ; $06CD: 0E 1F
        ADD HL,BC                ; $06CF: 09
        LD C,A                   ; $06D0: 4F
        DEC C                    ; $06D1: 0D
        JP NZ,$06C5              ; $06D2: C2 C5 06
        RET                      ; $06D5: C9
NATIVE_06D6:
        LD B,$03                 ; $06D6: 06 03
NATIVE_06D8:
        XOR A                    ; $06D8: AF
        LD A,D                   ; $06D9: 7A
        RRA                      ; $06DA: 1F
        LD D,A                   ; $06DB: 57
        LD A,E                   ; $06DC: 7B
        RRA                      ; $06DD: 1F
        LD E,A                   ; $06DE: 5F
        DEC B                    ; $06DF: 05
        JP NZ,$06D8              ; $06E0: C2 D8 06
        LD A,D                   ; $06E3: 7A
        ADD A,$24                ; $06E4: C6 24
        LD D,A                   ; $06E6: 57
        RET                      ; $06E7: C9
NATIVE_06E8:
        LD A,($200A)             ; $06E8: 3A 0A 20
NATIVE_06EB:
        PUSH AF                  ; $06EB: F5
        CALL $0919               ; $06EC: CD 19 09
        POP AF                   ; $06EF: F1
        DEC A                    ; $06F0: 3D
        JP NZ,$06EB              ; $06F1: C2 EB 06
        RET                      ; $06F4: C9
NATIVE_06F5:
        LD E,$18                 ; $06F5: 1E 18
        CALL $0903               ; $06F7: CD 03 09
        LD ($2025),A             ; $06FA: 32 25 20
        LD ($2040),A             ; $06FD: 32 40 20
        LD C,A                   ; $0700: 4F
        XOR A                    ; $0701: AF
        LD ($2041),A             ; $0702: 32 41 20
        LD B,A                   ; $0705: 47
        CALL $0940               ; $0706: CD 40 09
        LD A,(HL)                ; $0709: 7E
        OR $09                   ; $070A: F6 09
        LD (HL),A                ; $070C: 77
        RET                      ; $070D: C9
NATIVE_070E:
        LD D,$00                 ; $070E: 16 00
        LD A,B                   ; $0710: 78
        CP $00                   ; $0711: FE 00
        JP Z,$0724               ; $0713: CA 24 07
        DEC B                    ; $0716: 05
        CALL $0940               ; $0717: CD 40 09
        INC B                    ; $071A: 04
        LD A,(HL)                ; $071B: 7E
        RRCA                     ; $071C: 0F
        JP C,$0724               ; $071D: DA 24 07
        LD A,D                   ; $0720: 7A
        OR $01                   ; $0721: F6 01
        LD D,A                   ; $0723: 57
NATIVE_0724:
        LD A,$19                 ; $0724: 3E 19
        CP B                     ; $0726: B8
        JP NZ,$073C              ; $0727: C2 3C 07
        LD A,($201D)             ; $072A: 3A 1D 20
        OR A                     ; $072D: B7
        JP NZ,$074A              ; $072E: C2 4A 07
        LD A,($201C)             ; $0731: 3A 1C 20
        CP $46                   ; $0734: FE 46
        JP C,$074A               ; $0736: DA 4A 07
        JP $0746                 ; $0739: C3 46 07
NATIVE_073C:
        INC B                    ; $073C: 04
        CALL $0940               ; $073D: CD 40 09
        DEC B                    ; $0740: 05
        LD A,(HL)                ; $0741: 7E
        RRCA                     ; $0742: 0F
        JP C,$074A               ; $0743: DA 4A 07
NATIVE_0746:
        LD A,D                   ; $0746: 7A
        OR $02                   ; $0747: F6 02
        LD D,A                   ; $0749: 57
NATIVE_074A:
        LD A,C                   ; $074A: 79
        CP $00                   ; $074B: FE 00
        JP Z,$075E               ; $074D: CA 5E 07
        DEC C                    ; $0750: 0D
        CALL $0940               ; $0751: CD 40 09
        INC C                    ; $0754: 0C
        LD A,(HL)                ; $0755: 7E
        RRCA                     ; $0756: 0F
        JP C,$075E               ; $0757: DA 5E 07
        LD A,D                   ; $075A: 7A
        OR $04                   ; $075B: F6 04
        LD D,A                   ; $075D: 57
NATIVE_075E:
        LD A,$17                 ; $075E: 3E 17
        CP C                     ; $0760: B9
        JP Z,$0772               ; $0761: CA 72 07
        INC C                    ; $0764: 0C
        CALL $0940               ; $0765: CD 40 09
        DEC C                    ; $0768: 0D
        LD A,(HL)                ; $0769: 7E
        RRCA                     ; $076A: 0F
        JP C,$0772               ; $076B: DA 72 07
        LD A,D                   ; $076E: 7A
        OR $08                   ; $076F: F6 08
        LD D,A                   ; $0771: 57
NATIVE_0772:
        LD E,$00                 ; $0772: 1E 00
        LD A,D                   ; $0774: 7A
        OR A                     ; $0775: B7
NATIVE_0776:
        RRA                      ; $0776: 1F
        JP NC,$077B              ; $0777: D2 7B 07
        INC E                    ; $077A: 1C
NATIVE_077B:
        OR A                     ; $077B: B7
        JP NZ,$0776              ; $077C: C2 76 07
        RET                      ; $077F: C9
NATIVE_0780:
        LD A,($201D)             ; $0780: 3A 1D 20
        AND A                    ; $0783: A7
        JP NZ,$078B              ; $0784: C2 8B 07
        LD HL,$201C              ; $0787: 21 1C 20
        INC (HL)                 ; $078A: 34
NATIVE_078B:
        LD A,$01                 ; $078B: 3E 01
        LD ($2022),A             ; $078D: 32 22 20
        CALL $0903               ; $0790: CD 03 09
        LD E,A                   ; $0793: 5F
        LD A,D                   ; $0794: 7A
        INC E                    ; $0795: 1C
        DEC E                    ; $0796: 1D
        RRCA                     ; $0797: 0F
        JP NC,$079F              ; $0798: D2 9F 07
        JP Z,$07B1               ; $079B: CA B1 07
        DEC E                    ; $079E: 1D
NATIVE_079F:
        RRCA                     ; $079F: 0F
        JP NC,$07A7              ; $07A0: D2 A7 07
        JP Z,$07BA               ; $07A3: CA BA 07
        DEC E                    ; $07A6: 1D
NATIVE_07A7:
        RRCA                     ; $07A7: 0F
        JP NC,$07F3              ; $07A8: D2 F3 07
        JP Z,$07E8               ; $07AB: CA E8 07
        JP $07F3                 ; $07AE: C3 F3 07
NATIVE_07B1:
        DEC B                    ; $07B1: 05
        CALL $0940               ; $07B2: CD 40 09
        LD D,$05                 ; $07B5: 16 05
        JP $0804                 ; $07B7: C3 04 08
NATIVE_07BA:
        CALL $0940               ; $07BA: CD 40 09
        LD D,$04                 ; $07BD: 16 04
        CALL $0804               ; $07BF: CD 04 08
        LD A,$19                 ; $07C2: 3E 19
        CP B                     ; $07C4: B8
        JP Z,$07D1               ; $07C5: CA D1 07
        INC B                    ; $07C8: 04
        CALL $0940               ; $07C9: CD 40 09
        LD D,$01                 ; $07CC: 16 01
        JP $0804                 ; $07CE: C3 04 08
NATIVE_07D1:
        LD A,($201D)             ; $07D1: 3A 1D 20
        AND A                    ; $07D4: A7
        JP NZ,$07E1              ; $07D5: C2 E1 07
        LD A,$08                 ; $07D8: 3E 08
        LD ($201D),A             ; $07DA: 32 1D 20
        LD A,C                   ; $07DD: 79
        LD ($2023),A             ; $07DE: 32 23 20
NATIVE_07E1:
        LD B,$19                 ; $07E1: 06 19
        LD A,($2023)             ; $07E3: 3A 23 20
        LD C,A                   ; $07E6: 4F
        RET                      ; $07E7: C9
NATIVE_07E8:
        DEC C                    ; $07E8: 0D
        CALL $0940               ; $07E9: CD 40 09
        LD D,$03                 ; $07EC: 16 03
        JP $0804                 ; $07EE: C3 04 08
        DB $00,$00 ; $07F1-$07F2 source data/unclassified
NATIVE_07F3:
        CALL $0940               ; $07F3: CD 40 09
        LD D,$02                 ; $07F6: 16 02
        CALL $0804               ; $07F8: CD 04 08
        INC C                    ; $07FB: 0C
        CALL $0940               ; $07FC: CD 40 09
        LD D,$01                 ; $07FF: 16 01
        JP $0804                 ; $0801: C3 04 08
NATIVE_0804:
        LD A,($201D)             ; $0804: 3A 1D 20
        XOR $08                  ; $0807: EE 08
        OR (HL)                  ; $0809: B6
        OR D                     ; $080A: B2
        LD (HL),A                ; $080B: 77
        RET                      ; $080C: C9
NATIVE_080D:
        INC C                    ; $080D: 0C
        LD A,$18                 ; $080E: 3E 18
        CP C                     ; $0810: B9
        JP Z,$081D               ; $0811: CA 1D 08
NATIVE_0814:
        CALL $0940               ; $0814: CD 40 09
        LD A,(HL)                ; $0817: 7E
        RRCA                     ; $0818: 0F
        JP NC,$080D              ; $0819: D2 0D 08
        RET                      ; $081C: C9
NATIVE_081D:
        LD C,$00                 ; $081D: 0E 00
        INC B                    ; $081F: 04
        LD A,$1A                 ; $0820: 3E 1A
        CP B                     ; $0822: B8
        JP NZ,$0814              ; $0823: C2 14 08
        LD B,$00                 ; $0826: 06 00
        LD A,($2022)             ; $0828: 3A 22 20
        OR A                     ; $082B: B7
        RET Z                    ; $082C: C8
        LD A,$00                 ; $082D: 3E 00
        LD ($2022),A             ; $082F: 32 22 20
        JP $0814                 ; $0832: C3 14 08

CMD_03_GAME_DISPLAY_UPDATE:
        LD HL,$3E02              ; $0835: 21 02 3E
        LD D,$00                 ; $0838: 16 00
NATIVE_083A:
        LD A,($2026)             ; $083A: 3A 26 20
        LD BC,$0D44              ; $083D: 01 44 0D
        CP D                     ; $0840: BA
        JP NZ,$084A              ; $0841: C2 4A 08
        CALL $08A3               ; $0844: CD A3 08
        LD BC,$01D4              ; $0847: 01 D4 01
NATIVE_084A:
        CALL $08DB               ; $084A: CD DB 08
        INC D                    ; $084D: 14
        LD A,$18                 ; $084E: 3E 18
        CP D                     ; $0850: BA
        JP NZ,$083A              ; $0851: C2 3A 08
        LD HL,$3E23              ; $0854: 21 23 3E
        LD DE,$2066              ; $0857: 11 66 20
        LD B,$1A                 ; $085A: 06 1A
NATIVE_085C:
        LD C,$18                 ; $085C: 0E 18
        PUSH HL                  ; $085E: E5
        PUSH BC                  ; $085F: C5
        LD (HL),$FF              ; $0860: 36 FF
        LD BC,$FFE0              ; $0862: 01 E0 FF
        ADD HL,BC                ; $0865: 09
        POP BC                   ; $0866: C1
NATIVE_0867:
        PUSH BC                  ; $0867: C5
        LD A,(DE)                ; $0868: 1A
        LD BC,$0D44              ; $0869: 01 44 0D
        AND $40                  ; $086C: E6 40
        JP Z,$0874               ; $086E: CA 74 08
        LD BC,$01D4              ; $0871: 01 D4 01
NATIVE_0874:
        PUSH HL                  ; $0874: E5
        CALL $08DB               ; $0875: CD DB 08
        POP HL                   ; $0878: E1
        LD A,(DE)                ; $0879: 1A
        INC DE                   ; $087A: 13
        LD BC,$0D4C              ; $087B: 01 4C 0D
        AND $20                  ; $087E: E6 20
        JP Z,$0886               ; $0880: CA 86 08
        LD BC,$01D4              ; $0883: 01 D4 01
NATIVE_0886:
        CALL $08DB               ; $0886: CD DB 08
        POP BC                   ; $0889: C1
        DEC C                    ; $088A: 0D
        JP NZ,$0867              ; $088B: C2 67 08
        POP HL                   ; $088E: E1
        INC HL                   ; $088F: 23
        DEC B                    ; $0890: 05
        JP NZ,$085C              ; $0891: C2 5C 08
        LD A,($2024)             ; $0894: 3A 24 20
        INC H                    ; $0897: 24
NATIVE_0898:
        DEC H                    ; $0898: 25
        DEC A                    ; $0899: 3D
        JP P,$0898               ; $089A: F2 98 08
        LD BC,$0D5C              ; $089D: 01 5C 0D
        JP $08DB                 ; $08A0: C3 DB 08
NATIVE_08A3:
        PUSH HL                  ; $08A3: E5
        LD BC,$0D54              ; $08A4: 01 54 0D
        CALL $08DB               ; $08A7: CD DB 08
        POP HL                   ; $08AA: E1
        RET                      ; $08AB: C9

CMD_0A_GAME_CONTROL:
        LD HL,$3E03              ; $08AC: 21 03 3E
        LD DE,$2066              ; $08AF: 11 66 20
        LD B,$1A                 ; $08B2: 06 1A
NATIVE_08B4:
        LD C,$18                 ; $08B4: 0E 18
        PUSH HL                  ; $08B6: E5
NATIVE_08B7:
        PUSH BC                  ; $08B7: C5
        LD A,(DE)                ; $08B8: 1A
        INC DE                   ; $08B9: 13
        LD BC,$0D3C              ; $08BA: 01 3C 0D
        AND $80                  ; $08BD: E6 80
        JP NZ,$08C5              ; $08BF: C2 C5 08
        LD BC,$01D4              ; $08C2: 01 D4 01
NATIVE_08C5:
        CALL $08DB               ; $08C5: CD DB 08
        POP BC                   ; $08C8: C1
        DEC C                    ; $08C9: 0D
        JP NZ,$08B7              ; $08CA: C2 B7 08
        POP HL                   ; $08CD: E1
        INC HL                   ; $08CE: 23
        DEC B                    ; $08CF: 05
        JP NZ,$08B4              ; $08D0: C2 B4 08
        LD A,($201F)             ; $08D3: 3A 1F 20
        AND A                    ; $08D6: A7
        JP Z,$05EE               ; $08D7: CA EE 05
        RET                      ; $08DA: C9
NATIVE_08DB:
        PUSH DE                  ; $08DB: D5
        LD E,$08                 ; $08DC: 1E 08
NATIVE_08DE:
        LD A,(BC)                ; $08DE: 0A
        INC BC                   ; $08DF: 03
        OR (HL)                  ; $08E0: B6
        LD (HL),A                ; $08E1: 77
        PUSH DE                  ; $08E2: D5
        LD DE,$FFE0              ; $08E3: 11 E0 FF
        ADD HL,DE                ; $08E6: 19
        POP DE                   ; $08E7: D1
        DEC E                    ; $08E8: 1D
        JP NZ,$08DE              ; $08E9: C2 DE 08
        POP DE                   ; $08EC: D1
        RET                      ; $08ED: C9
NATIVE_08EE:
        DI                       ; $08EE: F3
        POP HL                   ; $08EF: E1
        LD BC,$0000              ; $08F0: 01 00 00
        LD DE,$0000              ; $08F3: 11 00 00
        LD SP,$4000              ; $08F6: 31 00 40
NATIVE_08F9:
        PUSH BC                  ; $08F9: C5
        INC DE                   ; $08FA: 13
        CP D                     ; $08FB: BA
        JP NZ,$08F9              ; $08FC: C2 F9 08
        LD SP,$2400              ; $08FF: 31 00 24
        JP (HL)                  ; $0902: E9
NATIVE_0903:
        PUSH BC                  ; $0903: C5
        CALL $0919               ; $0904: CD 19 09
        LD C,A                   ; $0907: 4F
        LD B,$00                 ; $0908: 06 00
NATIVE_090A:
        DEC E                    ; $090A: 1D
        JP Z,$0916               ; $090B: CA 16 09
        ADD A,C                  ; $090E: 81
        JP NC,$090A              ; $090F: D2 0A 09
        INC B                    ; $0912: 04
        JP $090A                 ; $0913: C3 0A 09
NATIVE_0916:
        LD A,B                   ; $0916: 78
        POP BC                   ; $0917: C1
        RET                      ; $0918: C9
NATIVE_0919:
        PUSH HL                  ; $0919: E5
        PUSH BC                  ; $091A: C5
        LD HL,$2004              ; $091B: 21 04 20
        LD B,$08                 ; $091E: 06 08
        LD A,(HL)                ; $0920: 7E
NATIVE_0921:
        RLCA                     ; $0921: 07
        RLCA                     ; $0922: 07
        RLCA                     ; $0923: 07
        XOR (HL)                 ; $0924: AE
        RLA                      ; $0925: 17
        RLA                      ; $0926: 17
        LD HL,$2004              ; $0927: 21 04 20
        LD A,(HL)                ; $092A: 7E
        RLA                      ; $092B: 17
        LD (HL),A                ; $092C: 77
        INC HL                   ; $092D: 23
        LD A,(HL)                ; $092E: 7E
        RLA                      ; $092F: 17
        LD (HL),A                ; $0930: 77
        INC HL                   ; $0931: 23
        LD A,(HL)                ; $0932: 7E
        RLA                      ; $0933: 17
        LD (HL),A                ; $0934: 77
        INC HL                   ; $0935: 23
        LD A,(HL)                ; $0936: 7E
        RLA                      ; $0937: 17
        LD (HL),A                ; $0938: 77
        DEC B                    ; $0939: 05
        JP NZ,$0921              ; $093A: C2 21 09
        POP BC                   ; $093D: C1
        POP HL                   ; $093E: E1
        RET                      ; $093F: C9
NATIVE_0940:
        PUSH DE                  ; $0940: D5
        LD E,$18                 ; $0941: 1E 18
        LD D,$00                 ; $0943: 16 00
        LD HL,$0000              ; $0945: 21 00 00
        LD A,B                   ; $0948: 78
        PUSH BC                  ; $0949: C5
        LD B,$09                 ; $094A: 06 09
NATIVE_094C:
        DEC B                    ; $094C: 05
        JP Z,$0959               ; $094D: CA 59 09
        ADD HL,HL                ; $0950: 29
        RLA                      ; $0951: 17
        JP NC,$094C              ; $0952: D2 4C 09
        ADD HL,DE                ; $0955: 19
        JP $094C                 ; $0956: C3 4C 09
NATIVE_0959:
        POP BC                   ; $0959: C1
        LD E,C                   ; $095A: 59
        ADD HL,DE                ; $095B: 19
        LD DE,$2066              ; $095C: 11 66 20
        ADD HL,DE                ; $095F: 19
        POP DE                   ; $0960: D1
        RET                      ; $0961: C9
NATIVE_0962:
        LD A,(HL)                ; $0962: 7E
        AND A                    ; $0963: A7
        RET P                    ; $0964: F0
        PUSH HL                  ; $0965: E5
        INC HL                   ; $0966: 23
        LD E,(HL)                ; $0967: 5E
        INC HL                   ; $0968: 23
        LD D,(HL)                ; $0969: 56
        RRCA                     ; $096A: 0F
        PUSH AF                  ; $096B: F5
        CALL C,$0999             ; $096C: DC 99 09
        POP AF                   ; $096F: F1
        RRCA                     ; $0970: 0F
        PUSH AF                  ; $0971: F5
        CALL C,$09B7             ; $0972: DC B7 09
        POP AF                   ; $0975: F1
        RRCA                     ; $0976: 0F
        PUSH AF                  ; $0977: F5
        CALL C,$09DB             ; $0978: DC DB 09
        POP AF                   ; $097B: F1
        RRCA                     ; $097C: 0F
        CALL C,$09C9             ; $097D: DC C9 09
        POP HL                   ; $0980: E1
        LD A,E                   ; $0981: 7B
        CP $0F                   ; $0982: FE 0F
        RET Z                    ; $0984: C8
        LD A,D                   ; $0985: 7A
        LD BC,$00EF              ; $0986: 01 EF 00
        CP $60                   ; $0989: FE 60
        JP NC,$0990              ; $098B: D2 90 09
        LD B,$10                 ; $098E: 06 10
NATIVE_0990:
        LD A,(HL)                ; $0990: 7E
        AND C                    ; $0991: A1
        OR B                     ; $0992: B0
        LD (HL),A                ; $0993: 77
        INC HL                   ; $0994: 23
        LD (HL),E                ; $0995: 73
        INC HL                   ; $0996: 23
        LD (HL),D                ; $0997: 72
        RET                      ; $0998: C9
NATIVE_0999:
        CALL $09EF               ; $0999: CD EF 09
        JP NZ,$09B5              ; $099C: C2 B5 09
        CALL $0A1D               ; $099F: CD 1D 0A
        DEC B                    ; $09A2: 05
        JP P,$09AE               ; $09A3: F2 AE 09
        LD A,($2026)             ; $09A6: 3A 26 20
        CP C                     ; $09A9: B9
        RET NZ                   ; $09AA: C0
        JP $09B5                 ; $09AB: C3 B5 09
NATIVE_09AE:
        CALL $0940               ; $09AE: CD 40 09
        LD A,(HL)                ; $09B1: 7E
        AND $40                  ; $09B2: E6 40
        RET Z                    ; $09B4: C8
NATIVE_09B5:
        DEC E                    ; $09B5: 1D
        RET                      ; $09B6: C9
NATIVE_09B7:
        CALL $09EF               ; $09B7: CD EF 09
        JP NZ,$09C7              ; $09BA: C2 C7 09
        CALL $0A1D               ; $09BD: CD 1D 0A
        CALL $0940               ; $09C0: CD 40 09
        LD A,(HL)                ; $09C3: 7E
        AND $40                  ; $09C4: E6 40
        RET Z                    ; $09C6: C8
NATIVE_09C7:
        INC E                    ; $09C7: 1C
        RET                      ; $09C8: C9
NATIVE_09C9:
        CALL $0A00               ; $09C9: CD 00 0A
        JP NZ,$09D9              ; $09CC: C2 D9 09
        CALL $0A1D               ; $09CF: CD 1D 0A
        CALL $0940               ; $09D2: CD 40 09
        LD A,(HL)                ; $09D5: 7E
        AND $20                  ; $09D6: E6 20
        RET Z                    ; $09D8: C8
NATIVE_09D9:
        DEC D                    ; $09D9: 15
        RET                      ; $09DA: C9
NATIVE_09DB:
        CALL $0A00               ; $09DB: CD 00 0A
        JP NZ,$09ED              ; $09DE: C2 ED 09
        CALL $0A1D               ; $09E1: CD 1D 0A
        DEC C                    ; $09E4: 0D
        RET M                    ; $09E5: F8
        CALL $0940               ; $09E6: CD 40 09
        LD A,(HL)                ; $09E9: 7E
        AND $20                  ; $09EA: E6 20
        RET Z                    ; $09EC: C8
NATIVE_09ED:
        INC D                    ; $09ED: 14
        RET                      ; $09EE: C9
NATIVE_09EF:
        LD A,D                   ; $09EF: 7A
        AND $07                  ; $09F0: E6 07
        CP $03                   ; $09F2: FE 03
        POP BC                   ; $09F4: C1
        RET NZ                   ; $09F5: C0
        PUSH BC                  ; $09F6: C5
        CALL $0A11               ; $09F7: CD 11 0A
        LD A,E                   ; $09FA: 7B
        AND $07                  ; $09FB: E6 07
        CP $07                   ; $09FD: FE 07
        RET                      ; $09FF: C9
NATIVE_0A00:
        LD A,E                   ; $0A00: 7B
        AND $07                  ; $0A01: E6 07
        CP $07                   ; $0A03: FE 07
        POP BC                   ; $0A05: C1
        RET NZ                   ; $0A06: C0
        PUSH BC                  ; $0A07: C5
        CALL $0A11               ; $0A08: CD 11 0A
        LD A,D                   ; $0A0B: 7A
        AND $07                  ; $0A0C: E6 07
        CP $03                   ; $0A0E: FE 03
        RET                      ; $0A10: C9
NATIVE_0A11:
        LD BC,$2020              ; $0A11: 01 20 20
        LD A,(BC)                ; $0A14: 0A
        AND A                    ; $0A15: A7
        RET NZ                   ; $0A16: C0
        INC A                    ; $0A17: 3C
        LD (BC),A                ; $0A18: 02
        LD ($2029),A             ; $0A19: 32 29 20
        RET                      ; $0A1C: C9
NATIVE_0A1D:
        LD A,E                   ; $0A1D: 7B
        RRA                      ; $0A1E: 1F
        RRA                      ; $0A1F: 1F
        RRA                      ; $0A20: 1F
        AND $1F                  ; $0A21: E6 1F
        SUB $02                  ; $0A23: D6 02
        LD B,A                   ; $0A25: 47
        LD A,D                   ; $0A26: 7A
        RRA                      ; $0A27: 1F
        RRA                      ; $0A28: 1F
        RRA                      ; $0A29: 1F
        AND $1F                  ; $0A2A: E6 1F
        LD C,A                   ; $0A2C: 4F
        LD A,$19                 ; $0A2D: 3E 19
        SUB C                    ; $0A2F: 91
        LD C,A                   ; $0A30: 4F
        RET                      ; $0A31: C9
NATIVE_0A32:
        LD HL,$2046              ; $0A32: 21 46 20
        LD A,(HL)                ; $0A35: 7E
        AND $07                  ; $0A36: E6 07
        CP $03                   ; $0A38: FE 03
        RET NZ                   ; $0A3A: C0
        DEC HL                   ; $0A3B: 2B
        LD A,(HL)                ; $0A3C: 7E
        AND $07                  ; $0A3D: E6 07
        CP $07                   ; $0A3F: FE 07
        RET NZ                   ; $0A41: C0
        DEC HL                   ; $0A42: 2B
        LD A,(HL)                ; $0A43: 7E
        DEC HL                   ; $0A44: 2B
        LD B,(HL)                ; $0A45: 46
        DEC HL                   ; $0A46: 2B
        LD C,(HL)                ; $0A47: 4E
        RRA                      ; $0A48: 1F
        JP C,$0A59               ; $0A49: DA 59 0A
        RRA                      ; $0A4C: 1F
        JP C,$0A85               ; $0A4D: DA 85 0A
        RRA                      ; $0A50: 1F
        JP C,$0A6F               ; $0A51: DA 6F 0A
        RRA                      ; $0A54: 1F
        JP C,$0A9B               ; $0A55: DA 9B 0A
        RET                      ; $0A58: C9
NATIVE_0A59:
        CALL $0ABE               ; $0A59: CD BE 0A
        JP C,$0AB1               ; $0A5C: DA B1 0A
        INC C                    ; $0A5F: 0C
        CALL $0ACE               ; $0A60: CD CE 0A
        JP C,$0AB1               ; $0A63: DA B1 0A
        INC B                    ; $0A66: 04
        CALL $0ADD               ; $0A67: CD DD 0A
        JP C,$0AB1               ; $0A6A: DA B1 0A
        DEC C                    ; $0A6D: 0D
        RET                      ; $0A6E: C9
NATIVE_0A6F:
        CALL $0AF0               ; $0A6F: CD F0 0A
        JP C,$0AB1               ; $0A72: DA B1 0A
        DEC B                    ; $0A75: 05
        CALL $0ABE               ; $0A76: CD BE 0A
        JP C,$0AB1               ; $0A79: DA B1 0A
        INC C                    ; $0A7C: 0C
        CALL $0ACE               ; $0A7D: CD CE 0A
        JP C,$0AB1               ; $0A80: DA B1 0A
        INC B                    ; $0A83: 04
        RET                      ; $0A84: C9
NATIVE_0A85:
        CALL $0ABE               ; $0A85: CD BE 0A
        JP C,$0AB1               ; $0A88: DA B1 0A
        INC C                    ; $0A8B: 0C
        CALL $0ADD               ; $0A8C: CD DD 0A
        JP C,$0AB1               ; $0A8F: DA B1 0A
        DEC C                    ; $0A92: 0D
        CALL $0AF0               ; $0A93: CD F0 0A
        JP C,$0AB1               ; $0A96: DA B1 0A
        DEC B                    ; $0A99: 05
        RET                      ; $0A9A: C9
NATIVE_0A9B:
        CALL $0AF0               ; $0A9B: CD F0 0A
        JP C,$0AB1               ; $0A9E: DA B1 0A
        DEC B                    ; $0AA1: 05
        CALL $0ADD               ; $0AA2: CD DD 0A
        JP C,$0AB1               ; $0AA5: DA B1 0A
        DEC C                    ; $0AA8: 0D
        CALL $0ACE               ; $0AA9: CD CE 0A
        JP C,$0AB1               ; $0AAC: DA B1 0A
        INC B                    ; $0AAF: 04
        RET                      ; $0AB0: C9
NATIVE_0AB1:
        LD HL,$2042              ; $0AB1: 21 42 20
        LD (HL),C                ; $0AB4: 71
        INC HL                   ; $0AB5: 23
        LD (HL),B                ; $0AB6: 70
        INC HL                   ; $0AB7: 23
        LD A,(HL)                ; $0AB8: 7E
        AND $F0                  ; $0AB9: E6 F0
        OR D                     ; $0ABB: B2
        LD (HL),A                ; $0ABC: 77
        RET                      ; $0ABD: C9
NATIVE_0ABE:
        XOR A                    ; $0ABE: AF
        DEC C                    ; $0ABF: 0D
        RET M                    ; $0AC0: F8
        CALL $0940               ; $0AC1: CD 40 09
        LD A,(HL)                ; $0AC4: 7E
        AND $20                  ; $0AC5: E6 20
        RET Z                    ; $0AC7: C8
        LD A,(HL)                ; $0AC8: 7E
        RLA                      ; $0AC9: 17
        RET NC                   ; $0ACA: D0
        LD D,$C4                 ; $0ACB: 16 C4
        RET                      ; $0ACD: C9
NATIVE_0ACE:
        DEC B                    ; $0ACE: 05
        RET M                    ; $0ACF: F8
        CALL $0940               ; $0AD0: CD 40 09
        LD A,(HL)                ; $0AD3: 7E
        AND $40                  ; $0AD4: E6 40
        RET Z                    ; $0AD6: C8
        LD A,(HL)                ; $0AD7: 7E
        RLA                      ; $0AD8: 17
        RET NC                   ; $0AD9: D0
        LD D,$C1                 ; $0ADA: 16 C1
        RET                      ; $0ADC: C9
NATIVE_0ADD:
        CALL $0940               ; $0ADD: CD 40 09
        INC C                    ; $0AE0: 0C
        LD A,(HL)                ; $0AE1: 7E
        AND $20                  ; $0AE2: E6 20
        RET Z                    ; $0AE4: C8
        LD A,$18                 ; $0AE5: 3E 18
        CP C                     ; $0AE7: B9
        RET Z                    ; $0AE8: C8
        INC HL                   ; $0AE9: 23
        LD A,(HL)                ; $0AEA: 7E
        RLA                      ; $0AEB: 17
        RET NC                   ; $0AEC: D0
        LD D,$C8                 ; $0AED: 16 C8
        RET                      ; $0AEF: C9
NATIVE_0AF0:
        CALL $0940               ; $0AF0: CD 40 09
        INC B                    ; $0AF3: 04
        LD A,(HL)                ; $0AF4: 7E
        AND $40                  ; $0AF5: E6 40
        RET Z                    ; $0AF7: C8
        LD A,$1A                 ; $0AF8: 3E 1A
        CP B                     ; $0AFA: B8
        JP Z,$0B09               ; $0AFB: CA 09 0B
        LD DE,$0018              ; $0AFE: 11 18 00
        ADD HL,DE                ; $0B01: 19
        LD A,(HL)                ; $0B02: 7E
        RLA                      ; $0B03: 17
        RET NC                   ; $0B04: D0
NATIVE_0B05:
        LD D,$C2                 ; $0B05: 16 C2
        SCF                      ; $0B07: 37
        RET                      ; $0B08: C9
NATIVE_0B09:
        LD A,($2024)             ; $0B09: 3A 24 20
        CP C                     ; $0B0C: B9
        JP Z,$0B05               ; $0B0D: CA 05 0B
        XOR A                    ; $0B10: AF
        RET                      ; $0B11: C9

CMD_02_SET_MODE_0E:
        LD A,$0E                 ; $0B12: 3E 0E
        JP $08EE                 ; $0B14: C3 EE 08

CMD_04_WRITE_DISPLAY_DATA:
        DI                       ; $0B17: F3
        EX DE,HL                 ; $0B18: EB
        LD E,(HL)                ; $0B19: 5E
        INC HL                   ; $0B1A: 23
        LD D,(HL)                ; $0B1B: 56
        INC HL                   ; $0B1C: 23
        LD C,(HL)                ; $0B1D: 4E
        INC HL                   ; $0B1E: 23
        LD B,(HL)                ; $0B1F: 46
        INC HL                   ; $0B20: 23
        EX DE,HL                 ; $0B21: EB
        LD (HL),B                ; $0B22: 70
        DEC HL                   ; $0B23: 2B
        LD (HL),C                ; $0B24: 71
        DEC HL                   ; $0B25: 2B
        EX DE,HL                 ; $0B26: EB
        LD C,(HL)                ; $0B27: 4E
        INC HL                   ; $0B28: 23
        LD B,(HL)                ; $0B29: 46
        INC HL                   ; $0B2A: 23
        LD A,(BC)                ; $0B2B: 0A
        CPL                      ; $0B2C: 2F
        ADD A,$1A                ; $0B2D: C6 1A
        RLCA                     ; $0B2F: 07
        RLCA                     ; $0B30: 07
        RLCA                     ; $0B31: 07
        ADD A,$03                ; $0B32: C6 03
        LD (DE),A                ; $0B34: 12
        DEC DE                   ; $0B35: 1B
        LD C,$00                 ; $0B36: 0E 00
        CP $60                   ; $0B38: FE 60
        JP NC,$0B3F              ; $0B3A: D2 3F 0B
        LD C,$10                 ; $0B3D: 0E 10
NATIVE_0B3F:
        LD A,(HL)                ; $0B3F: 7E
        INC HL                   ; $0B40: 23
        LD (DE),A                ; $0B41: 12
        DEC DE                   ; $0B42: 1B
        LD A,(HL)                ; $0B43: 7E
        INC HL                   ; $0B44: 23
        LD ($2000),HL            ; $0B45: 22 00 20
        OR C                     ; $0B48: B1
        LD (DE),A                ; $0B49: 12
        RET                      ; $0B4A: C9

CMD_05_READ_PLAYER_INPUT:
        LD HL,$0006              ; $0B4B: 21 06 00
        IN A,($01)               ; $0B4E: DB 01
        AND $40                  ; $0B50: E6 40
        JP Z,$0B57               ; $0B52: CA 57 0B
        LD L,$04                 ; $0B55: 2E 04
NATIVE_0B57:
        LD ($202A),HL            ; $0B57: 22 2A 20
        CPL                      ; $0B5A: 2F
        LD ($202C),A             ; $0B5B: 32 2C 20
        RET                      ; $0B5E: C9

CMD_08_SET_COUNTER_200C:
        EX DE,HL                 ; $0B5F: EB
        LD A,(HL)                ; $0B60: 7E
        INC HL                   ; $0B61: 23
        LD ($2000),HL            ; $0B62: 22 00 20
        LD ($200C),A             ; $0B65: 32 0C 20
        RET                      ; $0B68: C9

CMD_09_SET_COUNTER_AND_POINTER:
        EX DE,HL                 ; $0B69: EB
        LD A,(HL)                ; $0B6A: 7E
        LD ($200B),A             ; $0B6B: 32 0B 20
        INC HL                   ; $0B6E: 23
        LD E,(HL)                ; $0B6F: 5E
        INC HL                   ; $0B70: 23
        LD D,(HL)                ; $0B71: 56
        INC HL                   ; $0B72: 23
        LD ($2000),HL            ; $0B73: 22 00 20
        EX DE,HL                 ; $0B76: EB
        LD ($2008),HL            ; $0B77: 22 08 20
        RET                      ; $0B7A: C9

; Script record: target16. Replaces RAM $2000 with target address.
CMD_0B_GOTO_SCRIPT:
        EX DE,HL                 ; $0B7B: EB
        LD E,(HL)                ; $0B7C: 5E
        INC HL                   ; $0B7D: 23
        LD D,(HL)                ; $0B7E: 56
        EX DE,HL                 ; $0B7F: EB
        LD ($2000),HL            ; $0B80: 22 00 20
        RET                      ; $0B83: C9

; Script record: byte8, target16. RAM[target16] = byte8.
; Advances interpreter cursor $2000 by three bytes.
CMD_0C_STORE_IMMEDIATE_BYTE:
        EX DE,HL                 ; $0B84: EB
        LD A,(HL)                ; $0B85: 7E
        INC HL                   ; $0B86: 23
        LD E,(HL)                ; $0B87: 5E
        INC HL                   ; $0B88: 23
        LD D,(HL)                ; $0B89: 56
        INC HL                   ; $0B8A: 23
        LD ($2000),HL            ; $0B8B: 22 00 20
        LD (DE),A                ; $0B8E: 12
        RET                      ; $0B8F: C9

; Script record: byte8, pointer16, pointer16 (5 bytes).
; A = first byte, HL = first pointer, DE = second pointer on transfer
; to native drawing helper $0129. RAM $2000 advanced by five bytes.
CMD_07_DRAW_INLINE_RECORD:
        EX DE,HL                 ; $0B90: EB
        LD A,(HL)                ; $0B91: 7E
        INC HL                   ; $0B92: 23
        LD E,(HL)                ; $0B93: 5E
        INC HL                   ; $0B94: 23
        LD D,(HL)                ; $0B95: 56
        INC HL                   ; $0B96: 23
        PUSH DE                  ; $0B97: D5
        LD E,(HL)                ; $0B98: 5E
        INC HL                   ; $0B99: 23
        LD D,(HL)                ; $0B9A: 56
        INC HL                   ; $0B9B: 23
        LD ($2000),HL            ; $0B9C: 22 00 20
        POP HL                   ; $0B9F: E1
        JP $0129                 ; $0BA0: C3 29 01

CMD_0D_DECREMENT_GAME_STATE:
        LD DE,$2013              ; $0BA3: 11 13 20
        LD A,(DE)                ; $0BA6: 1A
        DEC A                    ; $0BA7: 3D
        CP $01                   ; $0BA8: FE 01
        RET Z                    ; $0BAA: C8
        LD (DE),A                ; $0BAB: 12
        RET                      ; $0BAC: C9
; Read conditional script record, tested RAM byte, and target.
; Entry: DE = pointer to 4 inline bytes (test16, branch16).
; Exit: BC = test address; DE = branch address; HL = byte after record;
;       A = RAM[test]; Z flag indicates tested byte zero.
READ_CONDITION_RECORD:
        EX DE,HL                 ; $0BAD: EB
        LD C,(HL)                ; $0BAE: 4E
        INC HL                   ; $0BAF: 23
        LD B,(HL)                ; $0BB0: 46
        INC HL                   ; $0BB1: 23
        LD E,(HL)                ; $0BB2: 5E
        INC HL                   ; $0BB3: 23
        LD D,(HL)                ; $0BB4: 56
        INC HL                   ; $0BB5: 23
        LD A,(BC)                ; $0BB6: 0A
        AND A                    ; $0BB7: A7
        RET                      ; $0BB8: C9

; BRANCH_IF_ZERO: choose script target for zero, fall-through cursor otherwise.
; Both paths update RAM $2000; XCHG selects target from DE on taken path.
CMD_0E_BRANCH_IF_ZERO:
        CALL $0BAD               ; $0BB9: CD AD 0B
        JP NZ,$0BC0              ; $0BBC: C2 C0 0B
        EX DE,HL                 ; $0BBF: EB
NATIVE_0BC0:
        LD ($2000),HL            ; $0BC0: 22 00 20
        RET                      ; $0BC3: C9

; BRANCH_IF_NONZERO: choose script target for nonzero, fall-through otherwise.
; Both paths update RAM $2000.
CMD_0F_BRANCH_IF_NONZERO:
        CALL $0BAD               ; $0BC4: CD AD 0B
        JP Z,$0BCB               ; $0BC7: CA CB 0B
        EX DE,HL                 ; $0BCA: EB
NATIVE_0BCB:
        LD ($2000),HL            ; $0BCB: 22 00 20
        RET                      ; $0BCE: C9

CMD_10_PROCESS_INLINE_RECORD:
        EX DE,HL                 ; $0BCF: EB
        LD E,(HL)                ; $0BD0: 5E
        INC HL                   ; $0BD1: 23
        LD D,(HL)                ; $0BD2: 56
        INC HL                   ; $0BD3: 23
        LD BC,$2036              ; $0BD4: 01 36 20
        CALL $0634               ; $0BD7: CD 34 06
        LD E,(HL)                ; $0BDA: 5E
        INC HL                   ; $0BDB: 23
        LD D,(HL)                ; $0BDC: 56
        INC HL                   ; $0BDD: 23
        LD ($2000),HL            ; $0BDE: 22 00 20
        LD HL,$2036              ; $0BE1: 21 36 20
        CALL $058C               ; $0BE4: CD 8C 05
        LD A,$02                 ; $0BE7: 3E 02
        JP $0129                 ; $0BE9: C3 29 01
        DB $00,$00 ; $0BEC-$0BED source data/unclassified

NATIVE_COMMAND_VECTORS:
; Original 17 little-endian native dispatch vectors, tokens $01-$11
        DW CMD_01_RETURN_SCRIPT      ; token $01 -> CMD_01_RETURN_SCRIPT
        DW CMD_02_SET_MODE_0E      ; token $02 -> CMD_02_SET_MODE_0E
        DW CMD_03_GAME_DISPLAY_UPDATE      ; token $03 -> CMD_03_GAME_DISPLAY_UPDATE
        DW CMD_04_WRITE_DISPLAY_DATA      ; token $04 -> CMD_04_WRITE_DISPLAY_DATA
        DW CMD_05_READ_PLAYER_INPUT      ; token $05 -> CMD_05_READ_PLAYER_INPUT
        DW CMD_06_INIT_GAME_FIELDS      ; token $06 -> CMD_06_INIT_GAME_FIELDS
        DW CMD_07_DRAW_INLINE_RECORD      ; token $07 -> CMD_07_DRAW_INLINE_RECORD
        DW CMD_08_SET_COUNTER_200C      ; token $08 -> CMD_08_SET_COUNTER_200C
        DW CMD_09_SET_COUNTER_AND_POINTER      ; token $09 -> CMD_09_SET_COUNTER_AND_POINTER
        DW CMD_0A_GAME_CONTROL      ; token $0A -> CMD_0A_GAME_CONTROL
        DW CMD_0B_GOTO_SCRIPT      ; token $0B -> CMD_0B_GOTO_SCRIPT
        DW CMD_0C_STORE_IMMEDIATE_BYTE      ; token $0C -> CMD_0C_STORE_IMMEDIATE_BYTE
        DW CMD_0D_DECREMENT_GAME_STATE      ; token $0D -> CMD_0D_DECREMENT_GAME_STATE
        DW CMD_0E_BRANCH_IF_ZERO      ; token $0E -> CMD_0E_BRANCH_IF_ZERO
        DW CMD_0F_BRANCH_IF_NONZERO      ; token $0F -> CMD_0F_BRANCH_IF_NONZERO
        DW CMD_10_PROCESS_INLINE_RECORD      ; token $10 -> CMD_10_PROCESS_INLINE_RECORD
        DW CMD_11_UPDATE_END_STATE      ; token $11 -> CMD_11_UPDATE_END_STATE
        DB $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40 ; $0C10-$0C1F source data/unclassified
        DB $40,$54,$48,$45,$40,$41,$4D,$41,$5A,$49,$4E,$47,$4D,$41,$5A,$45 ; $0C20-$0C2F source data/unclassified
        DB $40,$4D,$41,$5A,$45,$53,$40,$57,$4F,$4E,$53,$45,$4C,$45,$43,$54 ; $0C30-$0C3F source data/unclassified
        DB $19,$53,$49,$4E,$47,$4C,$45,$40,$50,$4C,$41,$59,$45,$52,$18,$4F ; $0C40-$0C4F source data/unclassified
        DB $52,$16,$54,$57,$4F,$40,$50,$4C,$41,$59,$45,$52,$18,$33,$40,$4D ; $0C50-$0C5F source data/unclassified
        DB $41,$5A,$45,$53,$40,$50,$45,$52,$40,$47,$41,$4D,$45,$49,$4E,$53 ; $0C60-$0C6F source data/unclassified
        DB $45,$52,$54,$40,$43,$4F,$49,$4E,$40,$51,$47,$45,$54,$40,$52,$45 ; $0C70-$0C7F source data/unclassified
        DB $41,$44,$59,$50,$4C,$41,$59,$40,$41,$53,$40,$4C,$4F,$4E,$47,$40 ; $0C80-$0C8F source data/unclassified
        DB $41,$53,$1B,$59,$4F,$55,$40,$57,$49,$4E,$4D,$41,$5A,$45,$53,$40 ; $0C90-$0C9F source data/unclassified
        DB $54,$4F,$40,$50,$4C,$41,$59,$53,$54,$55,$44,$59,$40,$54,$49,$4D ; $0CA0-$0CAF source data/unclassified
        DB $45,$50,$11,$4C,$11,$41,$11,$59,$11,$45,$11,$52,$4F,$11,$4E,$11 ; $0CB0-$0CBF source data/unclassified
        DB $45,$54,$11,$57,$11,$4F,$11,$57,$11,$49,$11,$4E,$11,$4E,$11,$45 ; $0CC0-$0CCF source data/unclassified
        DB $11,$52,$40,$11,$40,$11,$40,$11,$40,$11,$40,$11,$40,$11,$40,$11 ; $0CD0-$0CDF source data/unclassified
        DB $40,$11,$40,$11,$40,$4B,$45,$45,$50,$40,$50,$4C,$41,$59,$49,$4E ; $0CE0-$0CEF source data/unclassified
        DB $47,$57,$41,$49,$54,$50,$4C,$41,$59,$45,$52,$40,$57,$49,$4E,$53 ; $0CF0-$0CFF source data/unclassified
        DB $50,$4C,$41,$59,$45,$52,$40,$4C,$4F,$53,$45,$53,$50,$52,$45,$53 ; $0D00-$0D0F source data/unclassified
        DB $53,$40,$42,$55,$54,$54,$4F,$4E,$40,$54,$4F,$1C,$53,$54,$41,$52 ; $0D10-$0D1F source data/unclassified
        DB $54,$40,$47,$41,$4D,$45,$40,$4F,$56,$45,$52,$4F,$56,$45,$52,$41 ; $0D20-$0D2F source data/unclassified
        DB $4C,$4C,$10,$38,$6C,$38,$10,$7C,$44,$54,$44,$7C,$00,$00,$10,$28 ; $0D30-$0D3F source data/unclassified
        DB $10,$00,$00,$00,$80,$80,$80,$80,$80,$80,$80,$80,$00,$00,$00,$00 ; $0D40-$0D4F source data/unclassified
        DB $00,$00,$00,$FF,$18,$30,$60,$FE,$60,$30,$18,$00,$00,$18,$0C,$06 ; $0D50-$0D5F source data/unclassified
        DB $7F,$06,$0C,$18 ; $0D60-$0D63 source data/unclassified

INITIAL_GAME_SCRIPT:      ; Original native command packets, beginning $0D64
        DB $0C,$00              ; $0D64: STORE_IMMEDIATE_BYTE, value 0
        DW $202C                 ; $0D66: address of cleared game byte
        DB $0C,$00              ; $0D68: STORE_IMMEDIATE_BYTE, value 0
        DW $2031                 ; $0D6A
        DB $0C,$00              ; $0D6C: STORE_IMMEDIATE_BYTE, value 0
        DW $2032                 ; $0D6E
        DB $0C,$00              ; $0D70: STORE_IMMEDIATE_BYTE, value 0
        DW $202D                 ; $0D72
        DB $11                  ; $0D74: UPDATE_END_STATE
        DB $09,$0A              ; $0D75: SET_COUNTER_AND_POINTER, counter = $0A
        DW $0D94                 ; $0D77: saved command/data pointer
        DB $07,$10              ; $0D79: DRAW_INLINE_RECORD, parameter byte $10
        DW $0C10,$2408          ; $0D7B: data pointer and destination pointer
        DB $07,$09,$22,$0D,$0B ; $0D7F-$0D83: subsequent command/data bytes
        DB $24,$08,$1E,$00,$07,$09,$10,$0C,$0B,$24,$08,$1E,$00,$0B,$7F,$0D ; $0D84-$0D93 source data/unclassified
        DB $02,$09,$0A,$D5,$0D,$07,$03,$21,$0C,$0A,$2C,$08,$0F,$00,$07,$0B ; $0D94-$0DA3 source data/unclassified
        DB $21,$0C,$0A,$2C,$08,$0F,$00,$07,$04,$2C,$0C,$0B,$32,$08,$0F,$00 ; $0DA4-$0DB3 source data/unclassified
        DB $07,$04,$22,$0D,$10,$32,$08,$3C,$00,$07,$0B,$10,$0C,$0A,$2C,$07 ; $0DB4-$0DC3 source data/unclassified
        DB $09,$10,$0C,$0B,$32,$07,$0D,$6D,$0C,$09,$3A,$08,$0F,$00,$0B,$99 ; $0DC4-$0DD3 source data/unclassified
        DB $0D,$02,$07,$0D,$6D,$0C,$09,$3A,$07,$19,$41,$0C,$0A,$2A,$09,$08 ; $0DD4-$0DE3 source data/unclassified
        DB $FB,$0D,$07,$10,$5D,$0C,$08,$36,$08,$1E,$00,$07,$01,$10,$0C,$08 ; $0DE4-$0DF3 source data/unclassified
        DB $36,$08,$1E,$00,$0B,$E6,$0D,$02,$07,$1F,$3A,$0C,$0C,$2A,$09,$08 ; $0DF4-$0E03 source data/unclassified
        DB $1B,$0E,$07,$0D,$6D,$0C,$09,$3A,$08,$14,$00,$07,$01,$10,$0C,$15 ; $0E04-$0E13 source data/unclassified
        DB $3A,$08,$14,$00,$0B,$06,$0E,$02,$06,$03,$08,$F0,$00,$0A,$09,$04 ; $0E14-$0E23 source data/unclassified
        DB $94,$0D,$00,$02,$07,$19,$0C,$0D,$08,$28,$07,$0D,$41,$0C,$09,$34 ; $0E24-$0E33 source data/unclassified
        DB $07,$0A,$52,$0C,$0B,$38,$0C,$01,$34,$20,$07,$01,$10,$0C,$17,$34 ; $0E34-$0E43 source data/unclassified
        DB $07,$01,$79,$0C,$09,$38,$08,$1E,$00,$07,$01,$79,$0C,$17,$34,$07 ; $0E44-$0E53 source data/unclassified
        DB $01,$10,$0C,$09,$38,$08,$1E,$00,$0B,$3E,$0E,$02,$0C,$04,$13,$20 ; $0E54-$0E63 source data/unclassified
        DB $07,$0D,$41,$0C,$09,$2C,$07,$07,$5D,$0C,$0C,$30,$07,$02,$4F,$0C ; $0E64-$0E73 source data/unclassified
        DB $0F,$32,$07,$16,$83,$0C,$08,$34,$08,$F0,$00,$0B,$A6,$0E,$0F,$2E ; $0E74-$0E83 source data/unclassified
        DB $20,$8C,$0E,$0F,$32,$20,$64,$0D,$02,$09,$02,$A6,$0E,$07,$09,$7A ; $0E84-$0E93 source data/unclassified
        DB $0C,$0B,$32,$08,$1E,$00,$07,$09,$10,$0C,$0B,$32,$08,$0F,$00,$0B ; $0E94-$0EA3 source data/unclassified
        DB $91,$0E,$02,$06,$03,$07,$0A,$A7,$0C,$A0,$3E,$0F,$2E,$20,$C1,$0E ; $0EA4-$0EB3 source data/unclassified
        DB $07,$0C,$E5,$0C,$08,$24,$0C,$01,$2E,$20,$0B,$CC,$0E,$07,$0D,$9A ; $0EB4-$0EC3 source data/unclassified
        DB $0C,$08,$24,$10,$2E,$20,$16,$24,$07,$09,$31,$0C,$B1,$3E,$10,$31 ; $0EC4-$0ED3 source data/unclassified
        DB $20,$BB,$3E,$04,$48,$20,$32,$0D,$26,$20,$17,$C2,$04,$59,$20,$37 ; $0ED4-$0EE3 source data/unclassified
        DB $0D,$24,$20,$E0,$C0,$0C,$06,$0E,$20,$0C,$06,$29,$20,$00,$09,$04 ; $0EE4-$0EF3 source data/unclassified
        DB $82,$0E,$07,$10,$10,$0C,$08,$24,$10,$31,$20,$BB,$3E,$0E,$1A,$20 ; $0EF4-$0F03 source data/unclassified
        DB $1C,$0F,$0D,$07,$0B,$F5,$0C,$08,$24,$08,$1E,$00,$07,$0B,$10,$0C ; $0F04-$0F13 source data/unclassified
        DB $08,$24,$08,$1E,$00,$0B,$07,$0F,$07,$0C,$00,$0D,$08,$24,$08,$1E ; $0F14-$0F23 source data/unclassified
        DB $00,$07,$0C,$10,$0C,$08,$24,$08,$1E,$00,$0B,$1C,$0F,$02,$05,$07 ; $0F24-$0F33 source data/unclassified
        DB $0A,$52,$0C,$0B,$2C,$07,$07,$5D,$0C,$0C,$30,$08,$B4,$00,$0B,$64 ; $0F34-$0F43 source data/unclassified
        DB $0F,$0E,$2E,$20,$64,$0D,$02,$09,$02,$64,$0F,$07,$09,$7A,$0C,$0B ; $0F44-$0F53 source data/unclassified
        DB $32,$08,$1E,$00,$07,$09,$10,$0C,$0B,$32,$08,$1E,$00,$0B,$4F,$0F ; $0F54-$0F63 source data/unclassified
        DB $02,$06,$03,$07,$06,$B1,$0C,$01,$26,$07,$03,$C1,$0C,$E1,$34,$10 ; $0F64-$0F73 source data/unclassified
        DB $32,$20,$00,$3C,$07,$06,$B1,$0C,$1E,$26,$07,$03,$BC,$0C,$FE,$34 ; $0F74-$0F83 source data/unclassified
        DB $10,$31,$20,$1D,$3C,$07,$0D,$9A,$0C,$08,$24,$10,$2E,$20,$16,$24 ; $0F84-$0F93 source data/unclassified
        DB $07,$04,$AD,$0C,$A3,$3E,$07,$07,$2B,$0D,$B1,$3E,$04,$48,$20,$37 ; $0F94-$0FA3 source data/unclassified
        DB $0D,$26,$20,$17,$C0,$04,$59,$20,$32,$0D,$24,$20,$E0,$C0,$0C,$01 ; $0FA4-$0FB3 source data/unclassified
        DB $0D,$20,$0C,$01,$20,$20,$00,$10,$2E,$20,$16,$24,$09,$04,$45,$0F ; $0FB4-$0FC3 source data/unclassified
        DB $0E,$1B,$20,$E3,$0F,$10,$32,$20,$00,$3C,$07,$0A,$D2,$0C,$01,$26 ; $0FC4-$0FD3 source data/unclassified
        DB $08,$1E,$00,$07,$06,$C7,$0C,$01,$26,$08,$1E,$00,$0B,$CE,$0F,$10 ; $0FD4-$0FE3 source data/unclassified
        DB $31,$20,$1D,$3C,$07,$0A,$D2,$0C,$1E,$26,$08,$1E,$00,$07,$06,$C7 ; $0FE4-$0FF3 source data/unclassified
        DB $0C,$1E,$26,$08,$1E,$00,$0B,$E8,$0F,$00,$00,$00 ; $0FF4-$0FFF source data/unclassified

        END
