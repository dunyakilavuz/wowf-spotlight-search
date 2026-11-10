# Offline validation — v0.1.1

Run on 2026-11-10 (Europe/Istanbul), Linux, standalone **Lua 5.1.5**.
These are offline CPU/memory estimates with stubbed WoW APIs, **not in-game benchmarks**.
The harness deliberately uses artificial affine map geometry: cross-zone rankings and
yard values printed below are test-fixture values, not Azeroth distance measurements.
Coordinates and source/item IDs are from the real pinned database.

## Commands and outcomes

- `python3 tools/build_db.py`: PASS; pinned input SHA-256 identities verified.
- Two consecutive regenerations: PASS; generated Lua, TOC, coverage and stdout reports
  byte-for-byte identical. Coverage remains 41,833 entities / 138,149 physical points.
- `python3 tools/check.py`: PASS; **55 Lua files** passed `luac -p`, XML parsed,
  **7 Python tests** and **263 Lua assertions** passed against the complete default DB.
- `git diff --check`: PASS.
- Separate Era source-adapter export: PASS; checked-in Forever files were not overwritten.
- **29** mapped explicit auctioneers; **15,943** usable historical rate links across
  **1,249** items. No new source download, scraping, runtime dependency or SavedVariable.
- Existing native/TomTom, key binding, trainer aliases, instances/missing-position,
  UI keyboard/slash, geographic scope and moved-player tests continue to pass.

New regressions cover original Mongoose/Swiftness AH fallback, both factions, all three
neutral AH towns, missing faction, no available/scoped auctioneers, fresh AH re-resolution
after changing faction, quest-item exclusion, actual vs unknown/zero drop percentages,
rare/elite penalties, reasonable vendor-vs-drop travel tradeoffs and visible AH warnings.

## Important result interpretation

At the Horde test position (standing at Auctioneer Thathung), Mongoose #13452 and
original Swiftness #2459 route to **Auctioneer Thathung — Orgrimmar (55.9, 62.7)**.
At the Alliance test position (standing at Jaxon), Mongoose #13452 and original Swiftness
#2459 resolve to **Auctioneer Jaxon — Stormwind City (61.2, 70.7)**. AH availability and
tradability are explicitly unverified; waypoints go to the auctioneer, not a listing.

The Orgrimmar query `greater healing potion` now prefers a **vendor**, not Winterfall
Shaman. The synthetic maps rank Vendor-Tron 1000 (#1710) first; **Quartermaster Kyleen
is correctly attached to the separate potion #223914**, not falsely merged into #1710.
The real client supplies its real world-coordinate transforms and may rank Kyleen first.

Stormwind's artificial geometry puts Lord Gregor Lescovar extremely near the player,
so #1710 can still choose that mob rather than a vastly distant vendor. This is intentional
weighted distance, not unlimited vendor priority. The other Swiftness #288898 has actual
traced mob links (including Infernal) and can outrank the original #2459 AH entry in
Stormwind. **Same display name does not prove equivalent items.** See SOURCE_POLICY.md.

No `Crafted: Alchemy (skill N)` was added: the pinned input has no usable crafting-output,
profession and required-skill relationship. No values were inferred from names/recipes.

## Timing and memory

20-run warm means: fishing trainer **0.256 ms**, linen cloth
**2.501 ms**, copper vein **1.426 ms**, flight master
**0.262 ms**, Thunder Bluff **7.195 ms**, Mongoose
**1.475 ms**, Greater Healing Potion **23.825 ms**.
Broad live queries cooperate across frames; the `li` run used 18 frames, with maximum
resume slice 5.140 ms against the ~4 ms cooperative target (not a hard real-time limit).
Initial module/database load: **107.240 ms**.

Retained modules/database **16.759 MiB**; warm palette/cache **17.270 MiB**.
WoW's allocator/frames/GC can differ. This is SavedVariables-free but eagerly loaded.

## Disk footprint

| Generated file | Bytes |
|---|---:|
| `Data/Database.lua` | 6,121,030 |
| `Data/Index01.lua` | 245,086 |
| `Data/Index02.lua` | 246,446 |
| `Data/Index03.lua` | 251,715 |
| `Data/Index04.lua` | 261,682 |
| `Data/Index05.lua` | 166,437 |
| `Data/Postings.lua` | 2,180,900 |

Generated Lua: **9,473,296 bytes**. Complete installable `Searchlight/` folder:
**9,549,937 bytes** (9.11 MiB). Vendored corresponding source:
**17,679,168 bytes**; do not copy that directory into the game addon folder.

## Raw successful check output

```text
luac -p: PASS (55 Lua files)
Bindings.xml: well-formed
test_acquisition_metadata_coverage (test_builder.BuilderTests.test_acquisition_metadata_coverage) ... ok
test_all_pinned_sources_match (test_builder.BuilderTests.test_all_pinned_sources_match) ... ok
test_ascii_word_normalization (test_builder.BuilderTests.test_ascii_word_normalization) ... ok
test_changed_source_fails_closed (test_builder.BuilderTests.test_changed_source_fails_closed) ... ok
test_coverage_consistency (test_builder.BuilderTests.test_coverage_consistency) ... ok
test_no_addon_saved_variables (test_builder.BuilderTests.test_no_addon_saved_variables) ... ok
test_profession_alias_not_only_literal_title (test_builder.BuilderTests.test_profession_alias_not_only_literal_title) ... ok

----------------------------------------------------------------------
Ran 7 tests in 0.028s

OK
QUERY fishing trainer           0.422 ms |    17 matches | Arnold Leland
QUERY linen cloth               2.838 ms |     2 matches | Linen Cloth
QUERY copper vein               1.491 ms |     7 matches | Copper Vein
QUERY flight master             0.390 ms |    36 matches | Dungar Longdrink
QUERY thunder bluff             9.001 ms |   250 matches | Anvil
QUERY elixir of the mongoose    1.541 ms |     2 matches | Elixir of the Mongoose
QUERY swiftness potion          1.355 ms |     4 matches | Swiftness Potion
QUERY greater healing potion   22.463 ms |     6 matches | Greater Healing Potion
QUERY fishing tra               0.686 ms |    18 matches | Arnold Leland
QUERY mage trainer              0.633 ms |    19 matches | Jennea Cannon
QUERY blacksmithing trainer     0.558 ms |    16 matches | Therum Deepforge
QUERY repair                    5.048 ms |   233 matches | Frederick Stover
QUERY innkeeper                 0.948 ms |    45 matches | Innkeeper Allison
QUERY mailbox                   2.170 ms |   151 matches | Mailbox
QUERY bank                      1.126 ms |    45 matches | Bank
EXAMPLE Horde / Orgrimmar | elixir of the mongoose -> Elixir of the Mongoose | Item - Buy on Auction House: Auctioneer Thathung [item #13452] | Orgrimmar (55.9, 62.7) - 0 yd straight line | Availability/tradability unverified
EXAMPLE Horde / Orgrimmar | swiftness potion -> Swiftness Potion | Item - Buy on Auction House: Auctioneer Thathung [item #2459] | Orgrimmar (55.9, 62.7) - 0 yd straight line | Availability/tradability unverified
EXAMPLE Horde / Orgrimmar | greater healing potion -> Greater Healing Potion | Item - Vendor: Vendor-Tron 1000 [item #1710] | Desolace (60.3, 38.1) - 15700 yd straight line
EXAMPLE Horde | Kyleen variant #223914 -> Vendor: Quartermaster Kyleen
EXAMPLE Alliance / Stormwind City | elixir of the mongoose -> Elixir of the Mongoose | Item - Buy on Auction House: Auctioneer Jaxon [item #13452] | Stormwind City (61.2, 70.7) - 0 yd straight line | Availability/tradability unverified
EXAMPLE Alliance / Stormwind City | swiftness potion -> Swiftness Potion | Item - Mob drop: Infernal [Elite] [item #288898] | Stormwind City (71.4, 86.8) - 191 yd straight line
EXAMPLE Alliance / Stormwind City | greater healing potion -> Greater Healing Potion | Item - Mob drop: Lord Gregor Lescovar [item #1710] | Stormwind City (72.4, 35.1) - 373 yd straight line
EXAMPLE Alliance | Kyleen variant #223914 -> Vendor: Quartermaster Kyleen
ASYNC query li: 18 frames, max resume slice 5.140 ms
BENCH fishing trainer         mean   0.256 ms (20 runs)
BENCH linen cloth             mean   2.501 ms (20 runs)
BENCH copper vein             mean   1.426 ms (20 runs)
BENCH flight master           mean   0.262 ms (20 runs)
BENCH thunder bluff           mean   7.195 ms (20 runs)
BENCH elixir of the mongoose  mean   1.475 ms (20 runs)
BENCH greater healing potion  mean  23.825 ms (20 runs)
LOAD 107.240 ms | retained DB+modules 16.759 MiB | warm with palette/cache 17.270 MiB
PASS 263 assertions | 41833 entities | 7 native waypoint calls
```

## Still requires the game client

Follow IN_GAME_TESTING.md for actual map bounds, NPC friendliness, item purchase/use
restrictions, frame appearance, protected API behavior, native super-tracking and TomTom.
Partial community traces, spawn/phase availability, auction tradability/stock and vendor
stock are not live-validated. Offline success is not an in-game compatibility claim.
