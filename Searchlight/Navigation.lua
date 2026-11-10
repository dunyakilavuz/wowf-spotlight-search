-- SPDX-License-Identifier: GPL-3.0-only
local SL = Searchlight
local Nav = {}
SL.Navigation = Nav
local basisCache = {}
local huge = math.huge
local function now() return GetTime and GetTime() or 0 end
local function finite(x) return type(x)=="number" and x==x and x>-huge and x<huge end

local function worldPoint(map,x,y)
    if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local ok,world,wx,wy=pcall(function()
        local id,pos=C_Map.GetWorldPosFromMapPos(map,CreateVector2D(x,y))
        if not pos then return nil end
        local a,b=pos:GetXY()
        if finite(id) and finite(a) and finite(b) then return id,a,b end
    end)
    if ok then return world,wx,wy end
end

function Nav:Invalidate()
    basisCache={}
end

-- C_Map map coordinates are affine. Sample each map's three corners once, rather than
-- invoking the map API for every one of ~100k+ spawns on every keystroke.
function Nav:GetBasis(map)
    local entry=basisCache[map]
    if entry and (entry.valid or now()<entry.expires) then return entry.valid and entry or nil end
    local w0,x0,y0=worldPoint(map,0,0)
    local w1,x1,y1=worldPoint(map,1,0)
    local w2,x2,y2=worldPoint(map,0,1)
    if w0~=nil and w0==w1 and w0==w2 and finite(x0) and finite(x1) and finite(x2)
        and finite(y0) and finite(y1) and finite(y2) then
        entry={valid=true,world=w0,x=x0,y=y0,dx=x1-x0,dy=y1-y0,ex=x2-x0,ey=y2-y0}
        basisCache[map]=entry
        return entry
    end
    basisCache[map]={valid=false,expires=now()+5}
end

function Nav:WorldName(world)
    if world==0 then return "Eastern Kingdoms" end
    if world==1 then return "Kalimdor" end
end

function Nav:GetPlayerContext()
    local context={}
    if UnitFactionGroup then
        local faction=UnitFactionGroup("player")
        context.faction=faction=="Alliance" and "A" or faction=="Horde" and "H" or nil
    end
    local instance=IsInInstance and IsInInstance()
    if instance then context.reason="Inside an instance; outdoor distances unavailable"; return context end
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        local ok,map,x,y=pcall(function()
            local id=C_Map.GetBestMapForUnit("player")
            local pos=id and C_Map.GetPlayerMapPosition(id,"player")
            if not pos then return id end
            local a,b=pos:GetXY()
            if finite(a) and finite(b) and a>=0 and a<=1 and b>=0 and b<=1 then return id,a,b end
        end)
        if ok and map and x and y then
            context.map,context.x,context.y=map,x,y
            local world,wx,wy=worldPoint(map,x,y)
            if world~=nil and wx and wy then context.world,context.wx,context.wy=world,wx,wy end
        end
    end
    if not context.world and UnitPosition then
        local ok,x,y,world=pcall(function()
            local a,b,_,id=UnitPosition("player")
            if finite(a) and finite(b) and finite(id) then return a,b,id end
        end)
        if ok and x and y and world~=nil then context.world,context.wx,context.wy=world,x,y end
    end
    if not context.world and not context.map then context.reason="Player position unavailable; distances hidden" end
    return context
end

function Nav:RankPoint(map,x,y,context)
    local basis=self:GetBasis(map)
    if basis then
        if context.world~=nil and context.world==basis.world and context.wx and context.wy then
            local wx=basis.x+basis.dx*x+basis.ex*y
            local wy=basis.y+basis.dy*x+basis.ey*y
            local d2=(wx-context.wx)^2+(wy-context.wy)^2
            return 0,d2,basis.world,math.sqrt(d2)
        end
        if context.world~=nil and context.world~=basis.world then
            return 2,0,basis.world,nil
        end
    end
    if context.map==map and context.x and context.y then
        return 1,(x-context.x)^2+(y-context.y)^2,basis and basis.world,nil
    end
    return 3,0,basis and basis.world,nil
end

function Nav:SetWaypoint(result)
    -- Re-resolve on click: the player may have moved while the palette was open.
    local context=self:GetPlayerContext()
    context.areas=result.areas
    local location,source,sourceType=SL.Search:Resolve(result.record,context,{})
    if not location then
        return false,"No trustworthy coordinates are recorded for this result (instances may only have presence data)."
    end
    local title=result.record.name
    if result.record.kind=="i" then title=title.." [item #"..result.record.id.."]" end
    if source and result.record.kind=="i" then title=title.." - "..(sourceType or "Source")..": "..source.name end
    local native,tomtom=false,false
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local allowed=true
        if C_Map.CanSetUserWaypointOnMap then
            local ok,value=pcall(C_Map.CanSetUserWaypointOnMap,location.map)
            allowed=ok and value
        end
        if allowed then
            local ok,value=pcall(function()
                local point=UiMapPoint.CreateFromCoordinates(location.map,location.x,location.y)
                return C_Map.SetUserWaypoint(point)
            end)
            native=ok and value~=false
            if native and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                pcall(C_SuperTrack.SetSuperTrackedUserWaypoint,true)
            end
        end
    end
    if TomTom and type(TomTom.AddWaypoint)=="function" then
        local ok,uid=pcall(TomTom.AddWaypoint,TomTom,location.map,location.x,location.y,
            {title=title,persistent=false,minimap=true,world=true})
        tomtom=ok and uid~=nil and uid~=false
    end
    if native or tomtom then
        return true,string.format("%s: %s (%.1f, %.1f)%s",title,location.zone,location.x*100,
            location.y*100,(tomtom and " - TomTom arrow enabled" or "")..
            (context.reason and " - player position unavailable; nearest not guaranteed" or "")..
            (sourceType=="Auction House" and " - auction availability/tradability unverified" or ""))
    end
    return false,string.format("Cannot place a waypoint on this client/map. %s: %s (%.1f, %.1f). Try TomTom.",
        title,location.zone,location.x*100,location.y*100)
end
