# Third-party notices and data provenance

Searchlight code and its compiled database are distributed under GPL version 3
(SPDX: GPL-3.0-only). See `LICENSE`. Source and build tools are included in this repository.
No Questie names, logos, icons, or third-party runtime libraries are bundled as branding.
World of Warcraft names and other game material remain the property of their owners.
Searchlight is an independent addon, not a Blizzard product or endorsement.

## Questie / QuestieDB

- Original Classic database: https://github.com/Questie/Questie
- Current extracted database owner: https://github.com/Questie/QuestieDB
- Pinned revision: `ae4404b01a45163d3ef05909395b29aafc437bc2`
- Original sources, unmodified notices and corresponding GPL text: `vendor/QuestieDB/`
- Exact file identities: `tools/sources.lock.json`
- Extraction/format changes by Searchlight contributors, 2026-11-10: static provider
  composition, field selection, filtering invalid/presence-only coordinates, deduplicated
  string pools, item-container source expansion and precompiled English prefix indexes.

English base names and titles, spawns, NPC flags, vendor/drop/container relationships,
zone identities and map relationships derive from Questie Classic and the independently
maintained Forever data in QuestieDB. The original project credits over 100 contributors.
Its notices list consent from Muehe, Logon, TheCrux/BreakBB, Drejjmit, Cheeq, TechnoHunter
(spelled TechoHunter in the QuestieDB notice), and Yttrium. See upstream notices for the
full, authoritative current wording and any additional contributors.

**Important licensing caveat:** QuestieDB's LICENSE.md is not an unqualified blanket GPL
claim. The Questie team explicitly permits forking/copying under GPLv3 terms, but says
historical contributor consent is incomplete and that uncertain contributions may be
all rights reserved. That notice is retained verbatim. Searchlight follows the team's
express GPLv3 copying permission; we cannot warrant that every historical contribution
has been independently cleared. Review this caveat before wide/public redistribution.

The existing upstream common-drop support and generated Forever providers include
relationships originally derived by that project from community sources, including
Wowhead and CMaNGOS. Searchlight performed no direct Wowhead scraping. Their inherited
provenance does not establish fresh in-game validation, completeness, or source accuracy.
The supplemental common NPC drops are used only where a non-quest item's primary NPC
source list is empty; quest-only correction removals are not blindly reintroduced.

Static composition order: raw flavor data -> inherited Static corrections -> Forever
generated delta-base -> generated client traces -> authored Forever Static corrections.
Faction/quest-dependent Dynamic corrections and consumer/seasonal policies are not run.
See the vendored provenance and audit documents, and README limitations.
