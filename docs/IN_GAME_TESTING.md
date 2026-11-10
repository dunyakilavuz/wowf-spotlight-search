# In-game acceptance checklist (not yet run)

1. Install only the repository's `Searchlight/` folder under the selected WoW Forever
   client's `Interface/AddOns/`. Restart the client; enable Searchlight at character select.
2. Run `/searchlight status`; capture the client version, build, Interface, map/world IDs,
   native-waypoint support and database revision. The shipped TOC targets Interface 16001.
3. Try `/sl`, `/searchlight`, and Ctrl+Space. If Ctrl+Space already belongs to another
   command it is intentionally left alone; set Searchlight under the game's key bindings.
4. Stand near a known fishing trainer. Type `fi`, `fishing tra`, then `fishing trainer`.
   Confirm responsiveness, nearest faction-compatible trainer and the source location.
   Test another profession, your class trainer, `flight master`, `repair`, `innkeeper`,
   `mailbox` and `bank`.
5. Try `linen cloth` and `copper vein`. An item should show the physical vendor, mob or
   object source name; copper should show a gatherable object, not a bag item placeholder.
6. Use Up/Down and Enter, then mouse-click another result. Confirm the native map pin and
   super-tracking. Repeat with TomTom loaded for its arrow, then without TomTom. No pin
   should be manufactured when neither a physical source nor an eligible auctioneer has coordinates.
7. Search `thunder bluff` while in the Eastern Kingdoms: locations should be scoped to
   Thunder Bluff and labeled Other continent, not ranked by incomparable map percentages.
   Try `fishing trainer thunder bluff` and repeat on Kalimdor.
8. Move while the palette is open; it refreshes about once a second. Clicking re-resolves
   the nearest source immediately. Test Esc releasing keyboard focus and reopening.
9. Try a dungeon, a loading screen and a world area with unavailable player position.
   Search must remain usable and hide distances instead of inventing a nearby outdoor pin.
10. Check a new Forever zone, especially transformed-map coordinates in Mulgore,
    Eastern Plaguelands, Redridge and Stormwind. A pin on the wrong terrain is a data/map
    issue worth reporting with the client build and `/searchlight status` output.
11. Test on each faction. Vendors, trainers and other services flagged for the opposite
    faction should be excluded; hostile mobs remain valid drop sources. Reputation,
    race/class restrictions, phase/quest availability and stock are not modeled in v1.
12. On Horde in Orgrimmar and Alliance in Stormwind, search `elixir of the mongoose`.
    Item #13452 should say Buy on Auction House and use the nearest faction-compatible
    auctioneer; **AH?** and the status line must warn that listings/tradability are unverified.
    Click/Enter should place the auctioneer pin. Repeat near neutral Gadgetzan, Everlook
    and Booty Bay auctioneers on both factions. No live auction listings are checked.
13. Inspect original Swiftness Potion #2459: Eric has no usable coordinates, so this entry
    should use the AH. Other same-name IDs may have different physical sources; do not
    assume they are equivalent. A stale result must re-resolve after moving/changing faction.
14. From Orgrimmar, inspect `greater healing potion`: a documented vendor should beat the
    Winterfall Shaman farm when reasonably nearby. Check both #1710 and Kyleen's #223914
    and confirm actual purchase/use restrictions. A nearby mob may still beat a vendor
    on another continent or vastly farther away. Vendor stock is not guaranteed.
15. Confirm the gold/blue logo in the addon list and palette header. Check item icons,
    trainer/vendor/flight/inn/bank/AH/repair/stable/generic NPC glyphs and mining/herb/
    chest/mailbox/generic object glyphs against docs/ICONS.md. Some object types are
    inferred from English names; unknown new objects should remain generic.
16. Search an uncached item: question mark first, actual icon when data arrives, without
    freezing input. Type a different query before it arrives: an old response must not
    overwrite the new row. Confirm source badges on items and no leftover badge on NPCs.
    AH? text and uncertainty warnings must remain readable with the new icon layout.
17. Optional: enable Lua errors with `/console scriptErrors 1`, reproduce any error and
    share the full error/stack plus the exact query and location. `/reload` after updates.

Offline stub tests cannot prove frame appearance, actual Forever map transforms,
secure/restricted API behavior, or waypoint-arrow behavior in the real client.
