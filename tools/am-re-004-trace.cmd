// AM-RE-004 original 8080 gameplay trace for MAME 0.289.
// Run: mame maze -rompath roms -window -skip_gameinfo -debug -log -debugscript tools/am-re-004-trace.cmd
// Debugger addresses are hexadecimal. Traces go to MAME's error.log.
// No CPU registers or memory values are changed by this script.

temp0=0
temp1=0
temp2=0

// Generator: initial state, native random-state update, start column.
bp 03d4,1,{logerror "AM004 GEN_BEGIN pc=%04X seed=%02X%02X%02X%02X tick=%02X status=%02X",pc,b@2004,b@2005,b@2006,b@2007,b@200a,b@201f ; g}
bp 06f5,1,{logerror "AM004 SEED_COLUMN pc=%04X rng=%02X%02X%02X%02X e=%02X",pc,b@2004,b@2005,b@2006,b@2007,e ; g}

// Candidate walk: bound the large generator loop log to first 64 entries.
bp 070e,++temp0<=64,{logerror "AM004 GEN_CELL pc=%04X row=%02X col=%02X cell=%02X gen=%02X flags=%02X",pc,b,c,b@(2066+b*18+c),b@201c,b@201d ; g}
bp 078b,++temp1<=64,{logerror "AM004 GEN_CHOOSE pc=%04X row=%02X col=%02X mask=%02X candidates=%02X rng=%02X%02X%02X%02X",pc,b,c,d,e,b@2004,b@2005,b@2006,b@2007 ; g}
bp 0804,++temp2<=64,{logerror "AM004 GEN_WRITE pc=%04X row=%02X col=%02X mask=%02X value=%02X",pc,b,c,d,b@(hl) ; g}

// Generator completion and conversion for gameplay.
bp 03f1,1,{logerror "AM004 GEN_FINISH_TEST pc=%04X gen=%02X flags=%02X col=%02X row=%02X",pc,b@201c,b@201d,c,b ; g}
bp 043d,1,{logerror "AM004 SHIFT_880 pc=%04X first=%02X endgrid=%02X extra0=%02X extraend=%02X",pc,b@2066,b@22d5,b@22d6,b@23d5 ; g}

// Player movement gating and wall/collision checks.
bp 0a32,1,{logerror "AM004 MOVE_BEGIN pc=%04X col=%02X row=%02X dir=%02X sub=%02X%02X",pc,b@2042,b@2043,b@2044,b@2045,b@2046 ; g}
bp 0abe,1,{logerror "AM004 MOVE_LEFT pc=%04X row=%02X col=%02X",pc,b,c ; g}
bp 0ace,1,{logerror "AM004 MOVE_UP pc=%04X row=%02X col=%02X",pc,b,c ; g}
bp 0add,1,{logerror "AM004 MOVE_RIGHT pc=%04X row=%02X col=%02X",pc,b,c ; g}
bp 0af0,1,{logerror "AM004 MOVE_DOWN pc=%04X row=%02X col=%02X",pc,b,c ; g}
bp 0ab1,1,{logerror "AM004 MOVE_COMMIT pc=%04X next_col=%02X next_row=%02X state=%02X carry=%02X",pc,c,b,d,f ; g}

// Score, rounds and reset branching, without changing game state.
bp 0514,1,{logerror "AM004 SCORE_ENTRY pc=%04X packed=%02X%02X lives=%02X wins=%02X",pc,b@2018,b@2019,b@202a,b@202b ; g}
bp 0554,1,{logerror "AM004 SCORE_INC pc=%04X packed=%02X%02X",pc,b@2018,b@2019 ; g}
bp 04db,1,{logerror "AM004 ROUND pc=%04X count=%02X timer=%02X",pc,b@2029,b@200d ; g}
bp 05d9,1,{logerror "AM004 END_STATE pc=%04X end=%02X mode=%02X root=%02X%02X",pc,b@2027,b@202d,b@2003,b@2002 ; g}
g
