# Data refreshes and overlays

The default generator consumes the pinned, vendored QuestieDB inputs. It never contacts
Wowhead and does not require Questie at runtime. Refresh inputs deliberately, retaining
upstream notices, checking coordinate provenance and reviewing the changed counts.
`tools/sources.lock.json` is a SHA-256 allowlist, not a floating `master` download.

To recover any missing vendored files from their pinned public source:

```sh
python3 tools/build_db.py --fetch --lua lua5.1
```

To update: review a new QuestieDB revision, replace the corresponding source files **as a
set** (raw data, inherited corrections, generated base, traces, authored corrections and
map support), then explicitly update the revision and per-file SHA-256 entries in the
lock. Rebuild, inspect the coverage diff and run the tests. The generator deliberately
fails on changed input bytes until this review/lock update happens. The adapter fails
on unknown schema keys rather than silently dropping fields. See vendored provenance
and `docs/forever-delta-base.md` for upstream provider ordering and limitations.

## Optional reviewed overlay

Copy `tools/overlay.example.json`, replace the provenance description, add data, then:

```sh
python3 tools/build_db.py --overlay /path/to/reviewed-overlay.json --lua lua5.1
python3 tools/check.py --lua lua5.1 --luac luac5.1
```

The overlay is **build-time JSON**, never downloaded or executed in-game. It shallowly
updates fields of an existing record, or adds a record. Supply complete replacement
`spawns`, `npcDrops`, `objectDrops` or `vendors` fields where changing those fields.
The top-level keys are:

- `npc`: NPC ID -> `name`, `subName`, `npcFlags`, `friendlyToFaction` (`A`, `H`, `AH` or
  absent), `spawns`, `zoneID`. Flags are the **canonical Era/Forever database flags**,
  not Mainline raw NPC flag values. Flight master=8, trainer=16, innkeeper=128,
  banker=256, repair=16384, vendor=4.
- `object`: object ID -> `name`, `spawns`, `zoneID`.
- `item`: item ID -> `name`, `npcDrops`, `objectDrops`, `vendors`, `itemDrops`.
  ID arrays can be JSON arrays; `itemDrops` refers to container item IDs. Physical
  sources are recursively resolved with cycle detection.
- `maps`: AreaID -> **UiMapID**, not world MapID.
- `zones`: English `UPPER_SNAKE_CASE` label -> AreaID.
- `license` and `source`: required provenance declarations. The builder does not verify
  a declaration legally; the maintainer must verify GPLv3 compatibility and permission.

`spawns` maps an **AreaID** to arrays of `[x, y]` map percentages (0..100), e.g. the
abstract shape `{"AREA_ID": [[X_PERCENT, Y_PERCENT]]}`. All keys/coordinates must be real,
reviewed identities in an actual overlay; do not invent new-zone IDs or coordinates.
Coordinates in a Forever overlay must already use **Forever map bounds**. Era coordinates
must not be copied unchanged onto changed map frames, nor converted twice. Conversion
and no-conversion assumptions are documented in the vendored coordinate audit.

The generator skips `[-1,-1]` instance-presence sentinels, malformed pairs and off-map
points rather than manufacturing a waypoint or a dungeon entrance. It preserves those
omission counts in `Searchlight/Data/coverage.json`. Moving spawns retain sampled source
points but are not tracked live. Phase annotations are not evaluated by Searchlight v1.

`--flavor era` is a developer rebuild option, selecting the Classic raw/Static inputs
and Interface 11509. It overwrites the generated database/TOC. Do not ship both flavors
as the same artifact without rebuilding/testing each: Forever coordinates differ.
The checked-in v0.1.0 data is Forever, and the main harness validates that flavor.
