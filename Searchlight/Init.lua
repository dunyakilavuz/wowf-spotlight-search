-- SPDX-License-Identifier: GPL-3.0-only
local _, namespace = ...
local SL = namespace or {}
_G.Searchlight = SL
-- The packager substitutes the tag (e.g. v0.2.0); unpackaged checkouts report "dev".
local version = "@project-version@"
SL.version = version:find("@", 1, true) and "dev" or version
SL.DB = {}
SL.MAX_RESULTS = 10
SL.MIN_QUERY_LENGTH = 2
SL.SEARCH_THROTTLE = 0.04
SL.SEARCH_BUDGET_MS = 4
function SL:Print(message)
    local text = "|cff68d8ffSearchlight|r: " .. tostring(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(text) end
end
