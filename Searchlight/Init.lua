-- SPDX-License-Identifier: GPL-3.0-only
local _, namespace = ...
local SL = namespace or {}
_G.Searchlight = SL
SL.version = "0.1.1"
SL.DB = {}
SL.MAX_RESULTS = 10
SL.MIN_QUERY_LENGTH = 2
SL.SEARCH_THROTTLE = 0.04
SL.SEARCH_BUDGET_MS = 4
function SL:Print(message)
    local text = "|cff68d8ffSearchlight|r: " .. tostring(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(text) end
end
