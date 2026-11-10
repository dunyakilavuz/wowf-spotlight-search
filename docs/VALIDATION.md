# Offline validation — v0.1.0

Run on 2026-11-10 (Europe/Istanbul), Linux, standalone **Lua 5.1.5**.
This is an offline CPU/memory estimate with stubbed WoW APIs, not an in-game benchmark.

## Commands and outcomes

- `python3 tools/build_db.py`: PASS; all vendored input SHA-256 identities checked.
- Full second regeneration: PASS; generated Lua, TOC and coverage bytes identical.
- `python3 tools/check.py`: PASS; `luac -p` on **55 Lua files**, well-formed XML,
  **6 Python tests** and **196 Lua assertions** against the complete default database.
- Separate Era source-adapter export: PASS. This is only an adapter smoke test; it did
  not overwrite the checked-in Forever data or establish Era in-game compatibility.
- No test required Questie, TomTom, network access, an account login or SavedVariables.

The harness covers keyboard UI lifecycle, Up/Down, Enter, Esc and slash opening using
frame stubs. It tests native success/false-return/unsupported-map paths, TomTom fallback
and use alongside native pins, source re-resolution after moving, and explicit geographic
filter preservation. Every requested profession/class trainer alias is exercised.

## Representative timings

20-run warm mean on this box: fishing trainer **0.267 ms**, linen cloth **2.451 ms**,
copper vein **1.528 ms**, flight master **0.239 ms**, Thunder Bluff **6.806 ms**.
The broader `li` query was spread over **18 frames**, with a largest measured resume
slice of **4.940 ms** in this run (the cooperative target is ~4 ms, not a hard real-time
limit). Initial database/module load was **99.129 ms**.

Retained database/modules: **16.180 MiB**; after UI/cache activity: **16.682 MiB**.
WoW's allocator, frame system, patches and GC behavior can differ. These are estimates
for a SavedVariables-free addon, not readings from the actual game addon-memory meter.

## Disk footprint

| Generated file | Bytes |
|---|---:|
| `Data/Database.lua` | 5,856,772 |
| `Data/Index01.lua` | 245,086 |
| `Data/Index02.lua` | 246,446 |
| `Data/Index03.lua` | 251,715 |
| `Data/Index04.lua` | 261,682 |
| `Data/Index05.lua` | 166,437 |
| `Data/Postings.lua` | 2,180,900 |

Generated Lua total: **9,209,038 bytes**.
Installable folder including runtime code, README/license/notices: **9,279,433 bytes**
(about 8.85 MiB). Vendored corresponding source: **17,679,168 bytes**.
The vendor directory is for the repository/build, not copied into the WoW addon folder.

## Raw successful check output

```text
luac -p: PASS (55 Lua files)
Bindings.xml: well-formed
test_all_pinned_sources_match (test_builder.BuilderTests.test_all_pinned_sources_match) ... ok
test_ascii_word_normalization (test_builder.BuilderTests.test_ascii_word_normalization) ... ok
test_changed_source_fails_closed (test_builder.BuilderTests.test_changed_source_fails_closed) ... ok
test_coverage_consistency (test_builder.BuilderTests.test_coverage_consistency) ... ok
test_no_addon_saved_variables (test_builder.BuilderTests.test_no_addon_saved_variables) ... ok
test_profession_alias_not_only_literal_title (test_builder.BuilderTests.test_profession_alias_not_only_literal_title) ... ok

----------------------------------------------------------------------
Ran 6 tests in 0.022s

OK
QUERY fishing trainer           0.417 ms |    17 matches | Arnold Leland
QUERY linen cloth               2.756 ms |     2 matches | Linen Cloth
QUERY copper vein               1.708 ms |     7 matches | Copper Vein
QUERY flight master             0.345 ms |    36 matches | Dungar Longdrink
QUERY thunder bluff             8.990 ms |   250 matches | Anvil
QUERY fishing tra               0.787 ms |    18 matches | Arnold Leland
QUERY mage trainer              0.690 ms |    19 matches | Jennea Cannon
QUERY blacksmithing trainer     0.594 ms |    16 matches | Therum Deepforge
QUERY repair                    4.873 ms |   233 matches | Frederick Stover
QUERY innkeeper                 0.931 ms |    45 matches | Innkeeper Allison
QUERY mailbox                   2.329 ms |   151 matches | Mailbox
QUERY bank                      0.745 ms |    45 matches | Olivia Burnside
ASYNC query li: 18 frames, max resume slice 4.940 ms
BENCH fishing trainer         mean   0.267 ms (20 runs)
BENCH linen cloth             mean   2.451 ms (20 runs)
BENCH copper vein             mean   1.528 ms (20 runs)
BENCH flight master           mean   0.239 ms (20 runs)
BENCH thunder bluff           mean   6.806 ms (20 runs)
LOAD 99.129 ms | retained DB+modules 16.180 MiB | warm with palette/cache 16.682 MiB
PASS 196 assertions | 41833 entities | 4 native waypoint calls
```

## Still requires the user's game client

See [IN_GAME_TESTING.md](IN_GAME_TESTING.md). We cannot certify frame appearance,
secure/restricted API behavior, actual Forever map bounds, native super-tracking or
TomTom arrow behavior until the addon is loaded in game. Inherited/partial community
locations and faction/phase/quest restrictions remain data limitations, not validated
world-state facts.
