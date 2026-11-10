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
   should be manufactured when source coordinates are unknown.
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
12. Optional: enable Lua errors with `/console scriptErrors 1`, reproduce any error and
    share the full error/stack plus the exact query and location. `/reload` after updates.

Offline stub tests cannot prove frame appearance, actual Forever map transforms,
secure/restricted API behavior, or waypoint-arrow behavior in the real client.
