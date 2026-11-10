# Icon and artwork manifest — v0.1.2

All role/source paths below have the prefix **`Interface\Icons\`**. Extensions are
omitted for WoW's built-in texture lookup. No Blizzard textures are redistributed in
this repository. The standalone logo is original generated artwork, included under
the project license; it is not a Blizzard logo.

## NPC service glyphs

| Role | Texture basename | Visual intent |
|---|---|---|
| Trainer | `INV_Misc_Book_09` | Book / instruction |
| Vendor | `INV_Misc_Coin_01` | Coin / purchase |
| Flight master | `INV_Feather_01` | Feather / travel |
| Innkeeper | `INV_Misc_Rune_01` | Hearthstone |
| Banker | `INV_Misc_Bag_10` | Bag / storage |
| Auctioneer | `INV_Hammer_20` | Hammer / auction gavel |
| Repair | `Trade_BlackSmithing` | Anvil / smithing |
| Stable master | `Ability_Mount_RidingHorse` | Horse |
| Generic NPC | `INV_Misc_Head_Human_01` | Humanoid head glyph, not a live NPC portrait |

Canonical Questie NPC flags select these roles; overlapping services prioritize flight,
auction, bank, inn, stable, trainer, repair, then general vendor. Unknown flags use generic
NPC rather than guessing a service. The game API is not queried for live NPC portraits.

## Object glyphs

| Type hint | Texture basename |
|---|---|
| Mining node | `Trade_Mining` |
| Herb | `Trade_Herbalism` |
| Chest / crate / treasure | `INV_Crate_03` |
| Mailbox | `INV_Letter_15` |
| Generic object | `INV_Misc_Gear_01` |

**Classification uncertainty:** the compact database does not retain game-object type.
Conservative English whole-word hints identify vein/deposit/lode, mailbox, chest/crate/
treasure and familiar vanilla herbs. Unknown/new Forever names stay generic. These are
visual hints, not proof that an object is gatherable, lootable or currently available.
They do not change search ranking, source relationships, coordinates or waypoint logic.

## Item and source icons

Primary image: actual texture/fileID from guarded `C_Item.GetItemIconByID(itemID)` or
legacy `GetItemIcon(itemID)`. Missing/invalid/placeholder images show
`INV_Misc_QuestionMark` immediately; that placeholder is never permanently cached as a
resolved icon. Runtime fileIDs come from the client, not a guessed static item-icon DB.

A 14px badge overlaps the corner of the 36px primary icon:

| Source type | Texture basename |
|---|---|
| Vendor | `INV_Misc_Coin_01` |
| Mob drop | `INV_Misc_Bone_Skull_01` |
| Object loot | `INV_Crate_03` |
| Auction House | `INV_Hammer_20` |

No source badge is displayed for NPC/object rows or unknown item sources. Text remains
authoritative: in particular, **AH?** and the unverified-listing warning are retained.

Only rendered item rows request uncached data, through optional
`C_Item.RequestLoadItemDataByID`, or legacy `GetItemInfo`/`C_Item.GetItemInfo` warmup.
Both `GET_ITEM_INFO_RECEIVED` and guarded `ITEM_DATA_LOAD_RESULT` update matching visible
rows, never recycled rows or hidden palettes. Event callbacks do not re-request data or
restart search. Retry bookkeeping is bounded to 128 IDs, with a 30-second cooldown; no
all-catalog cache or SavedVariables are added. API/SetTexture errors are caught; detectable
missing textures fall back. Some client SetTexture implementations do not signal a
missing path, so actual visual validation still matters.

## Logo

- `docs/logo.png`: canonical 512x512 RGBA PNG, suitable for a repository preview.
- `Searchlight/Media/Icon.tga`: 128x128, type-2 uncompressed true-color TGA, BGRA pixels,
  32 bits/pixel, 8 alpha bits, descriptor bit 5 clear (bottom-left origin), 65,554 bytes.
- TOC: `## IconTexture: Interface\AddOns\Searchlight\Media\Icon`.
- The same asset is shown at 24px in the palette header.
- `python3 tools/build_media.py` regenerates TGA from the canonical PNG; only this optional
  artwork tool needs Pillow. Standard validation has no third-party Python dependency.
- `--source /path/to/new-image` explicitly replaces the canonical PNG and TGA. The first
  logo was generated for Searchlight, then downsampled and given antialiased alpha corners.

## Availability confidence and evidence

These are deliberately legacy/vanilla-style texture names, not Retail atlases or TBC
flight-form assets. **No selected name is known to require an expansion**, but actual
Forever texture rendering is **not verified in the game client**. Generic-object and NPC
visual interpretations are broad glyphs rather than exact models. The role names/paths
are high-confidence legacy references; the remaining uncertainty is the actual Forever
asset bundle and heuristic object classification, not a silently assumed live test.

Read on 2026-11-10 (Europe/Istanbul):

- [Blizzard generated item API documentation, Classic branch mirror](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)
  declares GetItemIconByID, RequestLoadItemDataByID and both completion events. All are
  capability-guarded anyway. The unrelated 1.12 ClassicAPI compatibility project is not
  treated as evidence for Blizzard Forever behavior.
- [Vanilla Sunscale Feather reference](https://wow.66wan.net/60/en/?item=5165) corroborates
  `INV_Feather_01` (not the guessed/nonstandard `INV_Misc_Feather_01`).
- Public legacy-icon inventories/search references corroborated book, hammer, bag,
  letter, crate, head and gear basenames. Direct retrieval of one community original-icon
  listing failed (TLS/HTTP error), so it is not presented as exhaustive client verification.

Use the in-game checklist to check every row type, missing-item load, source badge,
addon-list logo and header logo before publication. A green offline harness cannot
certify Blizzard texture files or pixel-perfect frame layout.
