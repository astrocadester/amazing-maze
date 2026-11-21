# AM-RE-004 — Actual original MAME execution log audit

Evidence date: 2026-11-21  
Input: user-supplied **error.log** from the original-game MAME debugger session; see the companion [624-byte RAM snapshot](AM-RE-004-MAME-GRID-SNAPSHOT.md).

## Log-format finding

The user-provided `error.log` is **257,030 characters** and contains **4,359 tagged AM004 events**. MAME's `logerror` statements were concatenated without separators, producing effectively a single very long event line. Any analyzer counting physical text lines would have **severely undercounted** the events. The repository's `tools/analyze-am-re-004-trace.mjs` has therefore been corrected to split by `AM004 <EVENT>` markers.

The source file begins with `Soft reset` followed by the events. There is no evidence of input-command changes or fabricated gameplay in this log.

## Original native breakpoint counts

| Event | Native PC | Actual hits |
| --- | --- | ---: |
| GEN_BEGIN | $03D4 | **21** |
| SEED_COLUMN | $06F5 | **21** |
| GEN_CELL | $070E | 100 |
| GEN_CHOOSE | $078B | 100 |
| GEN_WRITE | $0804 | 100 |
| GEN_FINISH_TEST | $03F1 | **3,964** |
| SHIFT_624 | $043D | **1** |
| SCORE_ENTRY | $0514 | **25** |
| SCORE_INC | $0554 | **25** |
| END_STATE | $05D9 | **2** |
| MOVE_BEGIN | $0A32 | **0** |
| MOVE_LEFT/UP/RIGHT/DOWN | $0ABE/$0ACE/$0ADD/$0AF0 | **0** |
| MOVE_COMMIT | $0AB1 | **0** |
| ROUND | $04DB | **0** |

**Interpretation:** at least one original maze was generated through the real command-zero event and direction-choice handlers, followed by a native pre-shift breakpoint and the previously supplied actual maze grid. A large number of generator completion/scan visits occurred. The GEN_CELL/GEN_CHOOSE/GEN_WRITE counts are **limited by the logging condition**, so 100 events are not the complete number of source-level iterations.

## Direct source execution samples

The first captured generator sequence begins with `GEN_BEGIN pc=03D4 seed=FFFFFFFF tick=FF status=00`, followed by `SEED_COLUMN pc=06F5 rng=B9D48953`. The first neighbor report reads `row=00 col=0C cell=09 gen=00 flags=00`; the candidate log at `$078B` reports `mask=0E candidates=03`. Subsequent `GEN_WRITE` entries show the original current/neighbor cells being modified. Repeated `GEN_BEGIN` events use different random-state values, such as `C51D5CE9` and `A4D6E3BE`.

The native generation state changes: early `GEN_FINISH_TEST` entries contain `flags=00`; later completion scans show `gen=4E flags=08`, indicating that the `$201D` special state was actually entered during this capture. The log includes one native `SHIFT_624 pc=043D` marker, at which `grid_start=07 grid_last=01 past_grid=00`. This agrees with the attached original 624-byte grid dump but **does not prove that the subsequent nibble-shift instruction loop completed**.

## Source execution: scoring

There are **25 actual SCORE_ENTRY / SCORE_INC breakpoint pairs**. In order, the original packed score field observed on entry is:

```text
0000 0001 0002 0003 0004 0005 0006 0007 0008 0009
0010 0011 0012 0013 0014 0015 0016 0017 0018 0019
0020 0021 0022 0023 0024
```

These are **hexadecimal representations of packed BCD values**, not a 0–36 decimal count. The series is consistent with the native `DAA` instruction at `$0554`, including the BCD transitions `$09 → $10` and `$19 → $20`. This is **direct runtime evidence that score-update code executed repeatedly**. The current breakpoint logs state **before** each increment; the next pair observes the subsequent changed value, not an immediate return-register trace.

The first score entry has `packed=0000 lives=04 wins=00`. Subsequent entries include `packed=0001 lives=03 wins=59` and continue through `packed=0024 lives=03 wins=36`. These are raw debugger field names, not proof that the RAM bytes were correctly labeled as lives or wins.

There are **2 END_STATE** hits (`end=00`, `end=01`) and **0 ROUND** hits. The source-level round transition at `$04DB` was **not observed** in this session.

## Unverified gameplay gates

**Movement and collision:** every `MOVE_*` breakpoint counter is zero. Do not interpret absence of events as a failed collision routine; the capture does not document the user's input actions or prove that a movement gate became active.

**Round changes:** no `$04DB` breakpoint was observed. The end-state handler was entered, but there is no traced full round transition.

**Full generator completion:** a real populated grid was captured at `$043D`, and 3,964 completion-test entries were observed. A post-shift grid dump and precise generator-to-display transition would strengthen proof of the entire lifecycle.

## AM-RE-004 disposition

- **G1 — PASS**: native generator entry and random seed-column code observed.
- **G2 — PASS for actual generator activity / direction updates**: recorded neighbor checks, choices, writes and completion scans; full edge-by-edge maze replay not established.
- **G3 — PASS for native pre-shift breakpoint and full 624-byte RAM capture**: subsequent shift completion not traced.
- **S1 — PASS for native score-entry and increment routine execution**, with 25 ordered packed-BCD score observations.
- **M1/M2 — OPEN**: no native movement or wall routine hits.
- **S2 — OPEN**: no round-update routine hit.

AM-RE-004 **remains open specifically for controlled movement/collision and round-transition evidence**. The generator and scoring routine execution gates now have genuine MAME evidence; new traces should focus on the remaining scenarios, not repeat completed research.
