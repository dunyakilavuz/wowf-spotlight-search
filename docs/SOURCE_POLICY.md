# Item acquisition policy — v0.1.1

## Physical sources first, AH only when location data is missing

For each distinct item ID, resolve all accessible vendor, mob-drop and object/container
sources. Ignore known opposite-faction vendors and explicit zero-percent drops. Choose
the best coordinate-bearing physical source, respecting explicit zone scope. A physical
source on another continent still counts: AH is not a replacement for a known source.

Only when no usable physical coordinates remain, suggest the nearest explicitly
friendly auctioneer: player faction from `UnitFactionGroup`, or neutral `AH` friendliness.
Unknown player faction permits neutral auctioneers only. Booty Bay, Gadgetzan and
Everlook's mapped flag-4096 auctioneers participate in the normal nearest-spawn ranking.
The 29 explicit auctioneers are indexed at build time; named-but-unflagged NPCs are not
assumed to provide the service. No listing API, live inventory or price is queried.

The result's `sourceType` is `Auction House`, its description says `Buy on Auction House`,
and clicking uses the same resolver to pin the chosen auctioneer with fresh player
position/faction. The palette shows **AH?** and an always-visible uncertainty warning
when selected; the full tooltip and waypoint message repeat the limitation. Without
usable auctioneer coordinates it remains unavailable, never a fictional location.

Known class-12 quest items do not receive AH suggestions. Other soulbound/unsellable
items cannot be identified from the available schema: **tradability and listings remain
unverified**, not promised. Acquisition/crafting/reputation/season/phase requirements,
vendor stock and limited supply are not modeled.

## Source quality versus straight-line distance

Continent/world tier always comes first; sources on different continents do not get
fictional comparable distances. For comparable locations, let `d` be actual straight-line
yards. The current heuristic scores (lower is better) are:

- Vendor: `d`.
- Object loot: `2*d + 300`.
- Mob drop: `(w*d + 800) * r`.
- Known drop percent `p`: `w = min(20, max(2, 2*sqrt(100/p)))`.
- Unknown drop percent: `w = 6`; this is a **weight, not a claimed drop probability**.
- NPC rank 1 (elite): `r = 1.5`; rank 2/3/4 (rare elite/boss/rare): `r = 3`; otherwise 1.

Thus a reasonably close vendor beats a low-chance farm, while a practically adjacent
physical drop can beat an enormously distant vendor. Historical drop percentages are
shown only when upstream provides a valid percentage. Even 100% records are not a live
Forever availability guarantee. Instance-only presence markers still provide no pin.
Eric "The Swift" is correctly treated as elite, not relabeled rare; his instance-only
location causes the original Swiftness Potion entry to fall back to AH.

For missing world position, distance remains hidden. Same-map normalized coordinates
provide a labeled ranking proxy, never displayed as real yards; other-map ties use
source quality and deterministic order. The visible distance always comes from the
unmodified location, never from the acquisition score.

Search results first respect continent tier, then exact-name matches (documented exact
vendor variants first), then the effective source score. An AH suggestion carries a
20,000-point unverified-availability ranking penalty; this is **not travel distance**.
Ordinary NPC/object results retain proximity ordering within their match/tier. All
candidates are considered before the 10-result cap. AH nearest-spawn selection itself
uses actual distance, not the suggestion penalty.

## Same-name variants are not merged

Greater Healing Potion #1710 and #223914 are distinct IDs with distinct recorded vendor
links; only #223914 is explicitly sold by Quartermaster Kyleen in the pinned data.
Assigning Kyleen to #1710 would manufacture a relationship. #287977 has no usable physical
source and can suggest AH. The UI shows IDs; exact-name documented vendor variants are
promoted so an unverified AH clone does not hide a known vendor. Check purchase/use
requirements and actual item equivalence in game before traveling.

Original Swiftness Potion #2459 uses AH because Eric lacks usable coordinates. Another
same-name item #288898 has traced mob drops (including Infernal), so its result can keep
a nearby mob source instead. This is not a blanket "all potions go to AH" rule.

## Crafting deliberately not guessed

The pinned dataset has no usable output-item -> creating-spell -> profession/required-skill
mapping. No additional crafting dataset is vendored. A recipe teaching spell is not
proof of an output item's profession/required skill, so no `Crafted: Alchemy (skill N)`
or speculative trainer alternative is emitted. A future licensed, provenance-locked
crafting source can extend the generated schema without changing search prefix indexing.
