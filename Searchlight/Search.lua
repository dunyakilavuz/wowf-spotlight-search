-- SPDX-License-Identifier: GPL-3.0-only
local SL = Searchlight
local Search = {}
SL.Search = Search
local D = SL.DB
local floor, huge = math.floor, math.huge
local cache, fifo, nextSlot = {}, {}, 1
local CACHE_LIMIT = 512

function Search:Normalize(text)
    return (tostring(text or ""):lower():gsub("[^a-z0-9]", " "):gsub(" +", " "):match("^ *(.-) *$"))
end

-- Rows stay compact strings; only a bounded cache of decoded entity metadata is retained.
function Search:GetRecord(index)
    if cache[index] then return cache[index] end
    local row = D.rows[index]
    if not row then return nil end
    local kind,id,name,title,flags,faction,spawns,sources,zone = row:match(
        "^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$")
    if not kind then return nil end
    local record = {index=index, kind=kind, id=tonumber(id), name=name, title=title,
        flags=tonumber(flags) or 0, faction=faction, spawns=D.spawns[tonumber(spawns)] or "", sources=D.sources[tonumber(sources)] or "", zone=tonumber(zone)}
    local old = fifo[nextSlot]
    if old then cache[old] = nil end
    cache[index], fifo[nextSlot] = record, index
    nextSlot = nextSlot % CACHE_LIMIT + 1
    return record
end

local function hasFlag(value, flag)
    return floor(value / flag) % 2 == 1
end

function Search:IsAccessible(record, context, vendor)
    if not context.faction or record.kind ~= "n" then return true end
    if record.faction ~= "A" and record.faction ~= "H" then return true end
    local service = vendor
    for _,flag in ipairs({4,8,16,128,256,4096,8192,16384}) do
        if hasFlag(record.flags, flag) then service = true; break end
    end
    return not service or record.faction == context.faction
end

local function betterLocation(a,b)
    if not a then return false end
    if not b then return true end
    if a.tier ~= b.tier then return a.tier < b.tier end
    if a.metric ~= b.metric then return a.metric < b.metric end
    if a.map ~= b.map then return a.map < b.map end
    if a.x ~= b.x then return a.x < b.x end
    return a.y < b.y
end

function Search:NearestSpawn(record, context, nearestCache, cooperate)
    local cached = nearestCache[record.index]
    if cached ~= nil then return cached or nil end
    local best, work = nil, 0
    for area,sx,sy in record.spawns:gmatch("(%d+),(%d+),(%d+)") do
        local areaID = tonumber(area)
        local zone = D.zones[areaID]
        if zone and zone[1] > 0 and (not context.areas or context.areas[areaID]) then
            local x,y = tonumber(sx)/10000, tonumber(sy)/10000
            local tier,metric,world,distance = SL.Navigation:RankPoint(zone[1],x,y,context)
            if not best or tier < best.tier or (tier == best.tier and metric < best.metric) then
                best = {area=areaID, map=zone[1], x=x, y=y, tier=tier,
                    metric=metric, world=world, distance=distance, zone=zone[2]}
            end
        end
        work = work + 1
        if cooperate and work % 64 == 0 then cooperate() end
    end
    if best then best.entity=record end
    nearestCache[record.index] = best or false
    return best
end

function Search:Resolve(record, context, nearestCache, cooperate)
    if record.kind ~= "i" then
        return self:NearestSpawn(record,context,nearestCache,cooperate),record,nil
    end
    local best, source, sourceType, fallback, fallbackType
    local sourceNames = {v="Vendor", d="Mob drop", o="Object loot"}
    local work = 0
    for code,index in record.sources:gmatch("([vdo])(%d+)") do
        index=tonumber(index)
        local cached=nearestCache[index]
        -- Most broad-item sources have already been examined for another item. Reuse
        -- the actual decoded entity along with its nearest point, avoiding LRU churn.
        if cached~=false or not fallback then
            local entity=cached and cached.entity or self:GetRecord(index)
            if entity and self:IsAccessible(entity,context,code=="v") then
                if not fallback then fallback,fallbackType=entity,sourceNames[code] end
                local location=cached or self:NearestSpawn(entity,context,nearestCache,cooperate)
                if betterLocation(location,best) then
                    best,source,sourceType=location,entity,sourceNames[code]
                end
            end
        end
        work=work+1
        if cooperate and work % 64 == 0 then cooperate() end
    end
    return best, source or fallback, sourceType or fallbackType
end

local function better(a,b)
    if a.tier ~= b.tier then return a.tier < b.tier end
    if a.metric ~= b.metric then return a.metric < b.metric end
    if a.record.name ~= b.record.name then return a.record.name < b.record.name end
    return a.index < b.index
end

-- Every token is a prebuilt word-start prefix. No full-catalog name scan, no result truncation
-- before distance ranking. A cooperation callback makes broad queries incremental in the UI.
function Search:Run(query, context, limit, cooperate)
    query = self:Normalize(query)
    if #query < SL.MIN_QUERY_LENGTH then return {},0 end
    context = context or SL.Navigation:GetPlayerContext()
    -- A city/zone query must rank only locations IN that zone, not an item's unrelated
    -- closer vendor elsewhere. These tiny query windows use prebuilt geographic lookups.
    local scoped = D.zonePrefixes and D.zonePrefixes[query]
    local longest,scopePhrase=0,nil
    if not scoped and D.zoneQueries then
        local words={}; for word in query:gmatch("%S+") do words[#words+1]=word end
        for first=1,#words do
            local phrase=""
            for last=first,math.min(#words,first+5) do
                phrase=phrase=="" and words[last] or phrase.." "..words[last]
                if #phrase>longest and D.zoneQueries[phrase] then scoped=D.zoneQueries[phrase];longest=#phrase;scopePhrase=phrase end
            end
        end
    end
    if scoped then
        local copy={}; for k,v in pairs(context) do copy[k]=v end
        copy.areas={}; for area in scoped:gmatch("%d+") do copy.areas[tonumber(area)]=true end
        context=copy
        if scopePhrase and scopePhrase~=query then
            local first,last=query:find(scopePhrase,1,true)
            query=self:Normalize(query:sub(1,first-1).." "..query:sub(last+1))
        end
    end
    limit = math.min(limit or SL.MAX_RESULTS,SL.MAX_RESULTS)
    local lists, seen = {}, {}
    for token in query:gmatch("%S+") do
        if not seen[token] then
            seen[token] = true
            local posting = D.prefix[token]
            if not posting then return {},0 end
            lists[#lists+1] = posting
        end
    end
    if #lists == 0 then return {},0 end
    table.sort(lists,function(a,b) return #a < #b end)
    local sets, work = {}, 0
    for i=2,#lists do
        local set = {}
        local accumulated=0
        for delta in lists[i]:gmatch("%d+") do
            accumulated=accumulated+tonumber(delta)
            set[accumulated] = true
            work=work+1
            if cooperate and work % 128 == 0 then cooperate() end
        end
        sets[#sets+1]=set
    end
    local results, nearestCache, total = {}, {}, 0
    local accumulated=0
    for delta in lists[1]:gmatch("%d+") do
        accumulated=accumulated+tonumber(delta)
        local index, matches = accumulated, true
        for i=1,#sets do if not sets[i][index] then matches=false; break end end
        if matches then
            local record = self:GetRecord(index)
            if record and self:IsAccessible(record,context,false) then
                local location,source,sourceType=self:Resolve(record,context,nearestCache,cooperate)
                if location or not context.areas then
                    total=total+1
                    local result={index=index,record=record,location=location,source=source,sourceType=sourceType,
                        tier=location and location.tier or 4,metric=location and location.metric or huge,areas=context.areas}
                    local pos=#results+1
                    while pos>1 and better(result,results[pos-1]) do pos=pos-1 end
                    if pos<=limit then
                        table.insert(results,pos,result)
                        if #results>limit then results[#results]=nil end
                    end
                end
            end
        end
        work=work+1
        if cooperate and work % 64 == 0 then cooperate() end
    end
    self.lastStats={candidates=total,returned=#results}
    return results,total
end

function Search:Describe(result)
    local record,location = result.record,result.location
    local kindNames={n="NPC",i="Item",o="Object"}
    local description=kindNames[record.kind] or "Location"
    if record.title ~= "" then description=description.." - "..record.title end
    if record.kind == "i" then
        if result.source then
            description=description.." - "..(result.sourceType or "Source")..": "..result.source.name
        else
            description=description.." - no known vendor, mob or object source"
        end
    end
    if not location then return description.." | Coordinates unavailable" end
    local place=location.zone..string.format(" (%.1f, %.1f)",location.x*100,location.y*100)
    if location.distance then
        place=place..string.format(" - %d yd straight line",math.floor(location.distance+0.5))
    elseif location.tier == 2 then
        local continent=SL.Navigation:WorldName(location.world)
        place=place.." - Other continent"..(continent and (": "..continent) or "")
    elseif location.tier == 1 then
        place=place.." - same map; distance unavailable"
    else
        place=place.." - distance unavailable"
    end
    return description.." | "..place
end
