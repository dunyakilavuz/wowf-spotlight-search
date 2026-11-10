# Searchlight v0.1.0

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
- `/searchlight status` prints build/map/API information for troubleshooting.
- Rebind Searchlight under the game's key-binding settings. Other commands are never
  overwritten. An otherwise entirely unbound action gets the free default again on login.

## Important limitations

The bundled 41,833 named NPC/item/object records are **partial community data**, not a
complete live game catalog. Item locations come from known vendors, mobs or containers.
Positions represent possible spawn points, not current availability. Some sources,
instances and new Forever content have no trustworthy coordinates and cannot be pinned.
Quest/phase/season, reputation, race/class and stock restrictions are not modeled.
Known opposite-faction services are excluded; unknown restrictions may still matter.

Distances are straight-line, not routes/travel times. Other-continent points are labeled.
Explicit city/zone queries constrain locations. Without player position, the nearest
point is not guaranteed and distances are hidden. Native pin/super-tracking APIs vary;
TomTom is optional. The addon has no SavedVariables; WoW saves the key binding itself.

Offline tests passed, but the addon still needs **in-game testing** for appearance,
map-coordinate accuracy and actual waypoint behavior. Retained memory was approximately
16.2 MiB in standalone Lua 5.1, not measured inside WoW.

## Source and license

GPL version 3; see `LICENSE` and `THIRD_PARTY_NOTICES.md`. QuestieDB expressly permits
GPLv3 copying but retains a historical contributor-consent caveat; that is not a blanket
independent copyright clearance.

The full source distribution contains the top-level repository README, `tools/` builder,
`tests/`, `docs/`, SHA-256 lock and matching `vendor/QuestieDB` inputs. Those development
folders are not installed in WoW. Project repository:
https://github.com/dunyakilavuz/wowf-spotlight-search
