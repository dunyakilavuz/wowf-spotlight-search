-- SPDX-License-Identifier: GPL-3.0-only
local SL = Searchlight
local Icons = {}
SL.Icons = Icons
local PREFIX = "Interface\\Icons\\"
Icons.FALLBACK = PREFIX.."INV_Misc_QuestionMark"
Icons.LOGO = "Interface\\AddOns\\Searchlight\\Media\\Icon"
-- Legacy icon paths only: no retail atlases or expansion-specific role artwork.
Icons.roles = {
    trainer=PREFIX.."INV_Misc_Book_09", vendor=PREFIX.."INV_Misc_Coin_01",
    flight=PREFIX.."INV_Feather_01", innkeeper=PREFIX.."INV_Misc_Rune_01",
    banker=PREFIX.."INV_Misc_Bag_10", auctioneer=PREFIX.."INV_Hammer_20",
    repair=PREFIX.."Trade_BlackSmithing", stable=PREFIX.."Ability_Mount_RidingHorse",
    npc=PREFIX.."INV_Misc_Head_Human_01", mining=PREFIX.."Trade_Mining",
    herb=PREFIX.."Trade_Herbalism", chest=PREFIX.."INV_Crate_03",
    mailbox=PREFIX.."INV_Letter_15", object=PREFIX.."INV_Misc_Gear_01",
}
Icons.sources = {
    ["Vendor"]=Icons.roles.vendor, ["Mob drop"]=PREFIX.."INV_Misc_Bone_Skull_01",
    ["Object loot"]=Icons.roles.chest, ["Auction House"]=Icons.roles.auctioneer,
}
local rolesByFlag = {{8,"flight"},{4096,"auctioneer"},{256,"banker"},{128,"innkeeper"},
    {8192,"stable"},{16,"trainer"},{16384,"repair"},{4,"vendor"}}
local herbs = {"peacebloom","silverleaf","earthroot","mageroyal","briarthorn","stranglekelp",
    "bruiseweed","wild steelbloom","grave moss","kingsblood","liferoot","fadeleaf","goldthorn",
    "khadgar s whisker","wintersbite","firebloom","purple lotus","arthas tears","sungrass",
    "blindweed","ghost mushroom","gromsblood","golden sansam","dreamfoil","mountain silversage",
    "plaguebloom","icecap","black lotus"}

function Icons:Role(record)
    if record.kind=="n" then
        for _,entry in ipairs(rolesByFlag) do
            if math.floor((record.flags or 0)/entry[1])%2==1 then return entry[2] end
        end
        return "npc"
    end
    if record.kind=="o" then
        -- The compact DB has no game-object type. Conservative English-name hints
        -- cover familiar nodes; unknown Forever objects keep the generic glyph.
        local name=" "..SL.Search:Normalize(record.name).." "
        if name:find(" mailbox ",1,true) or name:find(" mail box ",1,true) then return "mailbox" end
        if name:find(" vein ",1,true) or name:find(" deposit ",1,true) or name:find(" lode ",1,true) then return "mining" end
        if name:find(" herb ",1,true) then return "herb" end
        for _,herb in ipairs(herbs) do if name:find(" "..herb.." ",1,true) then return "herb" end end
        if name:find(" chest ",1,true) or name:find(" crate ",1,true) or name:find(" treasure ",1,true) then return "chest" end
        return "object"
    end
end

local function valid(texture)
    return (type(texture)=="number" and texture>0 and texture<math.huge) or
        (type(texture)=="string" and texture~="")
end
local function lookup(fn,itemID)
    if type(fn)~="function" then return nil end
    local ok,texture=pcall(fn,itemID)
    if ok and valid(texture) then return texture end
end
-- Bounded retry bookkeeping, not an all-catalog icon cache. Missing icons are never
-- cached as permanent results. Only visible result rows request item data.
local requests, fifo, nextSlot = {}, {}, 1
local MAX_REQUESTS, RETRY_SECONDS = 128, 30
function Icons:RequestItem(itemID)
    local now=GetTime and GetTime() or 0
    if requests[itemID] and now-requests[itemID]<RETRY_SECONDS then return end
    if not requests[itemID] then
        local old=fifo[nextSlot]
        if old then requests[old]=nil end
        fifo[nextSlot]=itemID; nextSlot=nextSlot%MAX_REQUESTS+1
    end
    requests[itemID]=now -- set BEFORE the API: synchronous callbacks cannot recurse
    if C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
        local ok=pcall(C_Item.RequestLoadItemDataByID,itemID)
        if ok then return end
    end
    local getter=GetItemInfo or (C_Item and C_Item.GetItemInfo)
    if type(getter)=="function" then pcall(getter,itemID) end
end

local function placeholder(texture)
    return texture==134400 or (type(texture)=="string" and texture:lower()==Icons.FALLBACK:lower())
end
function Icons:ItemTexture(itemID,request)
    if type(itemID)~="number" or itemID<=0 or itemID>=math.huge or itemID~=math.floor(itemID) then return self.FALLBACK end
    local texture=lookup(C_Item and C_Item.GetItemIconByID,itemID)
    if not texture or placeholder(texture) then texture=lookup(GetItemIcon,itemID) end
    if texture and not placeholder(texture) then return texture end
    if request~=false then self:RequestItem(itemID) end
    return self.FALLBACK
end

function Icons:ForResult(result)
    if result.record.kind=="i" then
        return self:ItemTexture(result.record.id),self.sources[result.sourceType]
    end
    return self.roles[self:Role(result.record)] or self.FALLBACK,nil
end

function Icons:Apply(texture,value)
    local ok,result=pcall(texture.SetTexture,texture,value or self.FALLBACK)
    if not ok or result==false then pcall(texture.SetTexture,texture,self.FALLBACK) end
end
