-- SPDX-License-Identifier: GPL-3.0-only
-- Offline, capability-limited adapter for Questie / QuestieDB source tables.
-- Only pinned Lua data/provider files are evaluated. No io/os/require in their environment.
local root, flavor = assert(arg[1]), arg[2] or "forever"
local modules, constants = {}, {Enum = {}}
local env = {pairs=pairs, ipairs=ipairs, tonumber=tonumber, tostring=tostring,
    type=type, assert=assert, error=error, math=math, string=string, table=table,
    select=select, unpack=unpack}
env.Questie = {IsClassic=true, IsForever=flavor=="forever"}
env.QuestieLoader = {}
function env.QuestieLoader:ImportModule(name)
    modules[name] = modules[name] or {}
    return modules[name]
end
env.QuestieLoader.CreateModule = env.QuestieLoader.ImportModule
local function load(path, ...)
    local f = assert(loadfile(root .. "/" .. path))
    setfenv(f, env)
    return f(...)
end
for _, name in ipairs({"zones", "phases", "waypoints"}) do
    load("src/corrections/enum/"..name..".lua", "QuestieDB", constants)
end
local db = env.QuestieLoader:ImportModule("QuestieDB")
local z = env.QuestieLoader:ImportModule("ZoneDB")
z.zoneIDs, z.private = constants.Enum.zoneIDs, {}
modules.Phasing = {phases=constants.Enum.phases}
db.waypointPresets = constants.Enum.waypointPresets
db.npcFlags = {NONE=0,GOSSIP=1,QUEST_GIVER=2,VENDOR=4,FLIGHT_MASTER=8,TRAINER=16,
    SPIRIT_HEALER=32,SPIRIT_GUIDE=64,INNKEEPER=128,BANKER=256,PETITIONER=512,
    TABARD_DESIGNER=1024,BATTLEMASTER=2048,AUCTIONEER=4096,STABLEMASTER=8192,
    REPAIR=16384,BARBER=33554432,TRANSMOGRIFIER=536870912}
db.itemClasses = {QUEST=12}
local schemas = {}
local function decode(text)
    local f = assert(loadstring(text)); setfenv(f,env); return f()
end
local names = {npc="Npc",object="Object",item="Item"}
for _, kind in ipairs({"npc","object","item"}) do
    local path = flavor=="forever" and ("data/Forever/forever"..names[kind].."DB.lua")
        or ("data/Classic/classic"..names[kind].."DB.lua")
    load(path)
    schemas[kind] = db[kind.."Keys"]
    db[kind.."Data"] = decode(db[kind.."Data"])
    -- Operation keys remain symbolic; base numeric keys retain their original meaning.
    setmetatable(db[kind.."Keys"], {__index=function(_,key)
        assert(key:match("_add$") or key:match("_remove$"), "Unknown schema key "..key)
        return key
    end})
end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
-- Field operations follow upstream: removals, plain replacements, additions.
local function apply(kind, patch)
    local rows, keys = db[kind.."Data"], db[kind.."Keys"]
    for id,fields in pairs(patch) do
        local row = rows[id] or {}; rows[id]=row
        for op=1,3 do
            for key,value in pairs(fields) do
                local suffix=type(key)=="string" and key:match("_(%a+)$")
                if (op==1 and suffix=="remove") or (op==2 and not suffix) or (op==3 and suffix=="add") then
                    if not suffix then
                        row[key]=value
                    else
                        local base=assert(keys[key:gsub("_%a+$", "")]); local target=row[base] or {}; row[base]=target
                        if key:match("^spawns_") then
                            for area,coords in pairs(value) do
                                local list=target[area] or {}; target[area]=list
                                for _,coord in ipairs(coords) do
                                    if suffix=="add" then
                                        local found=false; for _,old in ipairs(list) do if equal(old,coord) then found=true end end
                                        if not found then list[#list+1]=coord end
                                    else
                                        for i=#list,1,-1 do if equal(list[i],coord) then table.remove(list,i) end end
                                    end
                                end
                            end
                        else
                            for _,v in ipairs(value) do
                                if suffix=="add" then
                                    local found=false; for _,old in ipairs(target) do if equal(old,v) then found=true end end
                                    if not found then target[#target+1]=v end
                                else
                                    for i=#target,1,-1 do if equal(target[i],v) then table.remove(target,i) end end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
local providerCounts = {}
local function provider(kind,path,name)
    load(path)
    local patch=assert(modules[name]):Load()
    local count=0; for _ in pairs(patch) do count=count+1 end
    providerCounts[path]=count
    apply(kind,patch)
end
for _,kind in ipairs({"npc","object","item"}) do
    local cap=kind=="npc" and "NPC" or names[kind]
    local prefix=flavor=="forever" and "src/corrections/Forever/legacy/" or "src/corrections/Era/"
    provider(kind,prefix.."classic"..cap.."Fixes.lua", "Questie"..cap.."Fixes")
end
if flavor=="forever" then
    for _,kind in ipairs({"npc","object","item"}) do
        provider(kind,"src/corrections/Forever/generated/foreverBase"..names[kind]..".lua", "ForeverBase"..names[kind])
        provider(kind,"src/corrections/Forever/traces/forever"..names[kind].."Traces.lua", "Forever"..names[kind].."Traces")
        local cap=kind=="npc" and "NPC" or names[kind]
        provider(kind,"src/corrections/Forever/forever"..cap.."Fixes.lua", "Forever"..names[kind].."Fixes")
    end
end
load(flavor=="forever" and "support/Forever/Zones/areaIdToUiMapId.lua" or "support/Zones/areaIdToUiMapId.lua")
local map=decode(z.private.areaIdToUiMapId)
-- Only these overrides are genuine continent/world routes; legacy dungeon aliases are NOT floor maps.
for area,ui in pairs(decode(z.private.areaIdToUiMapIdOverride)) do
    if area==10073 or area==10074 then map[area]=ui end
end
local dropPrefix = flavor=="forever" and "support/Forever/DropTables/" or "support/DropTables/"
load(dropPrefix.."classicItemDrops.lua")
modules.DropDB={correctionKeys={WOWHEAD=-1,PSERVER=-2}}
load(dropPrefix.."itemDropCorrections.lua")
local dropModule=modules.QuestieClassicItemDrops
local common=decode(dropModule.wowheadData)
local server=decode(dropModule.cmangosData)
for item,npcs in pairs(server) do
    common[item]=common[item] or {}
    for npc,rate in pairs(npcs) do common[item][npc]=rate end
end
for item,npcs in pairs(modules.QuestieItemDropCorrections.Era) do
    common[item]=common[item] or {}
    for npc,rate in pairs(npcs) do
        if rate>=0 then common[item][npc]=rate end
    end
end
local data={npc={},object={},item={},zones=z.zoneIDs,maps=map,providers=providerCounts,commonDrops=common}
for _,kind in ipairs({"npc","object","item"}) do
    for id,row in pairs(db[kind.."Data"]) do
        local record={}
        for key,index in pairs(schemas[kind]) do
            local value=row[index]
            if type(value)~="function" then record[key]=value end
        end
        data[kind][id]=record
    end
end
local function quote(s)
    return '"'..s:gsub('[%z\1-\31\\"]',function(c)
        return string.format('\\u%04x',string.byte(c))
    end)..'"'
end
local function json(v)
    local t=type(v)
    if t=="string" then return quote(v) end
    if t=="number" or t=="boolean" then return tostring(v) end
    if t=="nil" then return "null" end
    assert(t=="table", t)
    local parts={}; for k,x in pairs(v) do parts[#parts+1]=quote(tostring(k))..":"..json(x) end
    return "{"..table.concat(parts,",").."}"
end
io.write(json(data),"\n")
