# Searchlight v0.1.2

## Install

Copy this `Searchlight` folder into your WoW Forever client's `Interface/AddOns/` folder,
so the client sees `Interface/AddOns/Searchlight/Searchlight.toc`. Restart WoW and enable
Searchlight at character select. No Questie installation is required; TomTom is optional.
The shipped data/TOC targets **Forever Interface 16001**, not unchanged Classic Era.

## Use

- Ctrl+Space opens/closes search (only installed if that key and the addon action are free).
- `/sl` or `/searchlight` toggles; `/sl linen cloth` opens with a query.
- Type 2+ English characters; Up/Down selects, Enter or click sets a waypoint, Esc closes.
- Examples: `fishing trainer`, `flight master`, `repair`, `innkeeper`, `mailbox`, `bank`,
  `mining trainer`, `mage trainer`, `linen cloth`, `copper vein`, `thunder bluff`.
- Rows have item icons, NPC-role glyphs and object hints; item-source badges distinguish
  vendors, mobs, objects and auctioneers. Uncached icons update without blocking search.
- Items show their source and ID. Vendors are preferred to incidental low-chance drops
  when reasonably near; very distant vendors do not always beat a nearby physical drop.
- Original `elixir of the mongoose` (#13452) / `swiftness potion` (#2459) with no usable
  physical-source coordinates suggest the nearest faction-safe Auction House instead.
  Neutral Booty Bay/Gadgetzan/Everlook auctioneers are valid for both factions.
- **AH?** is an unverified suggestion: listing availability, tradability and prices are
  unknown. Known quest items are excluded; other soulbound items cannot be identified.
- Same-name item IDs remain separate. Kyleen sells Greater Healing Potion #223914, not
  the original #1710; verify purchase/use restrictions in-game.
- `/searchlight status` prints build/map/API information for troubleshooting.
- Rebind Searchlight under the game's key-binding settings. Other commands are never
  overwritten. An otherwise entirely unbound action gets the free default again on login.

## Important limitations

The bundled 41,833 named NPC/item/object records are **partial community data**, not a
complete live game catalog. Item locations come from known vendors, mobs or containers.
Positions represent possible spawn points, not current availability. Some sources,
instances and new Forever content have no trustworthy physical coordinates; item results
may suggest an AH, otherwise no pin is invented. AH stock/tradability and vendor stock
are not verified. Crafting profession/skill information is absent from the pinned data
and is not inferred from names.
Quest/phase/season, reputation, race/class and stock restrictions are not modeled.
Known opposite-faction services are excluded; unknown restrictions may still matter.

Distances are straight-line, not routes/travel times. Other-continent points are labeled.
Explicit city/zone queries constrain locations. Without player position, the nearest
point is not guaranteed and distances are hidden. Native pin/super-tracking APIs vary;
TomTom is optional. The addon has no SavedVariables; WoW saves the key binding itself.

Offline tests passed, but the addon still needs **in-game testing** for appearance,
map-coordinate accuracy and actual waypoint behavior. Retained memory was approximately
16.8 MiB in standalone Lua 5.1, not measured inside WoW.

## Source and license

GPL version 3; see `LICENSE` and `THIRD_PARTY_NOTICES.md`. QuestieDB expressly permits
GPLv3 copying but retains a historical contributor-consent caveat; that is not a blanket
independent copyright clearance.

The full source distribution contains the top-level repository README, `tools/` builder,
`tests/`, `docs/`, SHA-256 lock and matching `vendor/QuestieDB` inputs. Those development
folders are not installed in WoW. Project repository:
https://github.com/dunyakilavuz/wowf-spotlight-search
