# Client and database research

Checked 2026-11-10 (Europe/Istanbul). Links are evidence, not a substitute for in-game
validation. Only public source files/documentation were read; no game-account login or
Wowhead scraping was used.

## Correct the initial client assumption

Forever is a distinct flavor with modern UI architecture, **not the unchanged Classic
Era client**. Use a Forever TOC/data build rather than quietly shipping an Era TOC.

- Primary: [Questie's Forever TOC](https://github.com/Questie/Questie/blob/master/Questie_Forever.toc)
  declares `## Interface: 16001` in the live v12.6.4 source read this turn.
- Primary: [Questie's Vanilla TOC](https://github.com/Questie/Questie/blob/master/Questie_Vanilla.toc)
  separately declares `11508, 11509`.
- Primary: [Questie Forever development notes](https://github.com/Questie/Questie/blob/master/docs/forever-development.md)
  record checks against Forever 1.60.1 / Interface 16001, including live Mulgore examples,
  and warn that `WOW_PROJECT_ID` is 1 like Retail despite Classic content.
- [Blizzard's launch article](https://news.blizzard.com/en-us/article/24315820/world-of-warcraft-forever-now-live)
  and [overview](https://news.blizzard.com/en-us/article/24315821/wow-foreverwhats-new-and-what-feels-familiar)
  corroborate the expanded level-60 Azeroth setting and new zones/dungeons.

Confidence in **16001 is high from current primary source**, but it was not verified by
launching the client. No multi-flavor TOC is shipped because a multi-version number alone
would not fix differing map coordinate bounds. `--flavor era` explicitly rebuilds the data
and TOC instead.

## API assumptions

- [GetWorldPosFromMapPos](https://warcraft.wiki.gg/wiki/API_C_Map.GetWorldPosFromMapPos)
  is documented for Forever 1.60.1 and vanilla Classic. It may return nothing; its first
  result is an InstanceID/world MapID, **not a UiMapID**. Searchlight preserves this
  distinction and only compares distances within the same world coordinate system.
- [SetUserWaypoint](https://warcraft.wiki.gg/wiki/API_C_Map.SetUserWaypoint) and
  [SetSuperTrackedUserWaypoint](https://warcraft.wiki.gg/wiki/API_C_SuperTrack.SetSuperTrackedUserWaypoint)
  are documented for Forever, but not all Classic clients. They are optional capability
  checks, attempted from explicit result clicks/Enter. Missing/failed APIs do not crash
  the addon; native pin placement can fall back to optional TomTom.
- Some community beta notes reported waypoint/super-tracking restrictions; current API
  documentation lists the calls for Forever. This discrepancy needs live testing.
  `pcall` handles errors only; it does not bypass protected, secret or restricted APIs.
- Player-map queries/UnitPosition can be unavailable in instances/loading. Those states
  never reuse a cached outdoor player position. Map projection failures are cached only
  briefly and invalidated on zone transitions.
- Frame, edit box, slash command, binding and basic vector APIs are the common modern
  Classic-style surface. No retail combat-decision API, Questie runtime, Ace library,
  map library or HTTP request is required in game.

## Community data exists, with provenance and licensing qualifications

The Questie project has moved data ownership into **Questie/QuestieDB**. Its
[provenance](https://github.com/Questie/QuestieDB/blob/master/PROVENANCE.md) documents the
Classic import; its current tree includes distinct `data/Forever`, `support/Forever`
and `src/corrections/Forever` sources. The pinned corresponding inputs are included in
`vendor/QuestieDB` and SHA-256 locked in `tools/sources.lock.json`.

The extractor composes the supported static entity subset in documented order. It uses
Forever's already-converted coordinates and native reviewed area/map routes, **not**
legacy synthetic dungeon-floor compatibility overrides. It does not attempt to import
Questie consumer Dynamic corrections, seasonal policy or quest-state availability.
Common-drop support is used conservatively for non-quest items lacking primary NPC
sources, so a query such as `linen cloth` can find mobs rather than just container loot.

See vendored:

- `docs/forever-data.md`: converted Era coordinates assume world positions did not move;
  new/moved entities require separate evidence. Mulgore, Eastern Plaguelands, Redridge and
  Stormwind have changed map bounds. Some dungeon entrances remain unreviewed.
- `docs/forever-delta-base.md`: provider order, generated source scope, withheld capped
  item lists, unresolved references, and the fact that this is not a complete gameplay DB.
- `docs/forever-spatial-validation.md`, `docs/forever-coordinate-audit.md`,
  `docs/forever-map-override-audit.md`: spatial/map caveats and live-validation gaps.
- `LICENSE.md`: **explicit GPLv3 copying permission from the Questie team, with an
  incomplete historical contributor-consent caveat**. This is not an independently
  cleared blanket license. That exact notice is retained; no stronger claim is made.

No additional Wowhead dataset was scraped or silently relicensed. An optional build-time
reviewed overlay is supported for independently verified GPLv3-compatible additions.

## v0.1.1 acquisition-source follow-up

Only the existing pinned, licensed vendor sources were used; no additional data was
scraped or downloaded. The source adapter already reads common item-drop percentages;
v0.1.1 emits usable 0..100 rates and honors manual reference selectors/zero overrides.
These cover only a subset of items, not all incidental loot or all Forever changes.
NPC `rank` and explicit auctioneer flags/faction/spawns are also retained as supplements.

Inspected the item schema and extracted fields across the pinned dataset: there is no
usable mapping from an output item to its creating spell, profession and required skill.
A recipe's teaching spell is not such a mapping. No other crafting dataset is currently
vendored, so crafted-by text and trainer alternatives were deliberately skipped rather
than guessing `Alchemy (skill N)`. Future additions need actual output/skill relationships,
GPLv3-compatible permission and the same input-lock/provenance review as other data.

No bonding/tradability, vendor stock quantities or spawn-frequency metadata is available.
Quest items can be excluded from AH suggestions by class, but remaining items are not
asserted to be tradeable/listed. Eric "The Swift" is rank-1 elite in an instance, with no
usable outdoor coordinates: do not falsely call him a rare or manufacture an entrance.
