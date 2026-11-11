# Searchlight changelog

All notable changes are listed here. The release workflow uploads this file as the
CurseForge/Wago changelog (`manual-changelog` in `.pkgmeta`), so update it before tagging.

## v0.1.2 — 2026-11-12

- Async-safe result icons (NPC, item, object, auction-house and fallback textures).
- Original Searchlight logo: in-game `Media/Icon.tga` (TOC `IconTexture`) and docs/logo.png.
- Automated packaging and publishing to CurseForge (and optionally Wago) via
  BigWigsMods/packager on `v*` tags; the TOC version now comes from the tag.

## v0.1.1

- Faction-safe nearest auction-house fallback for purchasable items (e.g. alchemy potions)
  with no known vendor.
- Reliability-weighted item source ranking: vendors before drops/objects, exact names first.
- Additional potion and fallback tests.

## v0.1.0

- Initial release: Ctrl+Space Spotlight-style palette for WoW: Forever (Interface 16001).
- Static NPC/item/object database derived from QuestieDB (GPL-3.0), with a prefix index.
- Distance-ranked results, role queries (vendor, trainer, flight master...), and waypoints
  through the native map pin API or TomTom.
