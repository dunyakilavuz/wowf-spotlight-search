-- SPDX-License-Identifier: GPL-3.0-only
-- Run from repository root: lua5.1 tests/test_searchlight.lua
local t0=os.clock()
local state={map=1453,x=0.5,y=0.5,faction="Alliance",worldCalls=0,native=0,tracked=0,tomtom=0}
local checks=0
local function check(value,message)
    checks=checks+1
    assert(value,message or ("check "..checks))
end
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
local kalimdor={}
for _,map in ipairs({1411,1412,1413,1414,1438,1439,1440,1441,1442,1443,1444,1445,1446,1447,1448,
    1449,1450,1451,1452,1454,1456,1457,2482,2521,2652}) do kalimdor[map]=true end
local function projection(map,x,y)
    local world=kalimdor[map] and 1 or 0
    -- Artificial affine maps only: these are NOT claimed to reproduce Azeroth geometry.
    local origin=(map-1400)*1000
    return world,origin+x*1000,origin+y*1000
end
C_Map={}
function C_Map.GetWorldPosFromMapPos(map,pos)
    state.worldCalls=state.worldCalls+1
    if state.noWorld then return nil end
    local x,y=pos:GetXY()
    local w,a,b=projection(map,x,y)
    return w,CreateVector2D(a,b)
end
function C_Map.GetBestMapForUnit() return not state.noMap and state.map or nil end
function C_Map.GetPlayerMapPosition()
    if state.noMap then return nil end
    return CreateVector2D(state.x,state.y)
end
function C_Map.CanSetUserWaypointOnMap() return not state.denyNative end
function C_Map.SetUserWaypoint(point)
    state.native=state.native+1;state.lastPoint=point
end
UiMapPoint={CreateFromCoordinates=function(map,x,y) return {uiMapID=map,x=x,y=y} end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function(value) state.tracked=state.tracked+1;check(value==true) end}
function IsInInstance() return state.instance or false end
function UnitPosition()
    if state.noUnit then return nil end
    local w,x,y=projection(state.map,state.x,state.y)
    return x,y,0,w
end
function UnitFactionGroup() return state.faction end
function GetTime() return os.clock() end
function debugprofilestop() return os.clock()*1000 end
DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) state.message=msg end}
SlashCmdList={}
function GetBuildInfo() return "1.60.1","70291","test",16001 end

local Frame={}
Frame.__index=Frame
local function newFrame(kind,name,parent)
    local f=setmetatable({kind=kind,name=name,parent=parent,shown=true,scripts={}},Frame)
    if name then _G[name]=f end
    return f
end
function CreateFrame(kind,name,parent) return newFrame(kind,name,parent) end
function Frame:CreateFontString() return newFrame("FontString",nil,self) end
function Frame:CreateTexture() return newFrame("Texture",nil,self) end
function Frame:SetScript(event,fn) self.scripts[event]=fn end
function Frame:RegisterEvent() end
function Frame:Show()
    local changed=not self.shown;self.shown=true
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Frame:Hide()
    local changed=self.shown;self.shown=false
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Frame:IsShown() return self.shown end
function Frame:SetShown(value) if value then self:Show() else self:Hide() end end
function Frame:SetText(value)
    self.text=value
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,true) end
end
function Frame:GetText() return self.text or "" end
function Frame:SetHeight(v) self.height=v end
function Frame:SetSize(w,h) self.width,self.height=w,h end
function Frame:SetFocus() self.focus=true end
function Frame:ClearFocus() self.focus=false end
for _,name in ipairs({"SetPoint","SetAllPoints","SetWidth","SetJustifyH","SetWordWrap","SetColorTexture",
    "SetTextColor","SetBackdrop","SetBackdropBorderColor","SetClampedToScreen","SetFrameStrata",
    "EnableMouse","SetTextInsets","SetFontObject","SetAutoFocus","SetMaxLetters","SetHighlightTexture",
    "HighlightText"}) do Frame[name]=function() end end
UIParent=newFrame("Frame","UIParent")
BackdropTemplateMixin={}
local dbStart=collectgarbage("count")
local toc=assert(io.open("Searchlight/Searchlight.toc")):read("*a")
for file in toc:gmatch("[^\r\n]+") do
    if file:match("%.lua$") then dofile("Searchlight/"..file) end
end
collectgarbage("collect")
local dbMemory=collectgarbage("count")-dbStart
local loadTime=(os.clock()-t0)*1000
local SL=Searchlight
check(SL.DB.meta.flavor=="forever","default DB must target Forever")
check(#SL.DB.rows==41833,"review changed coverage count and update this witness deliberately")
check(SL.DB._postings==nil,"temporary posting pool must be released")
check(SL.Search:Normalize("  FiSHING--Trainer! ")=="fishing trainer")
check(#SL.Search:Run("f")==0,"single letters should not search")
check(#SL.Search:Run("definitelynotanentity")==0,"absent token")

local function find(kind,id)
    for index in ipairs(SL.DB.rows) do
        local record=SL.Search:GetRecord(index)
        if record.kind==kind and record.id==id then return record end
    end
    error("missing entity "..kind..id)
end
local arnold=find("n",5493)
check(arnold.name=="Arnold Leland" and arnold.title:find("Fishing"),"English title/name")
local area,x,y=arnold.spawns:match("(%d+),(%d+),(%d+)")
state.map=SL.DB.zones[tonumber(area)][1];state.x=tonumber(x)/10000;state.y=tonumber(y)/10000
local dungar=find("n",352)
check(dungar.spawns:find("1519,7129,7223",1,true),"authored Forever correction must win; no second Era coordinate transform")
for area,map in pairs({[616]=2482,[16591]=2548,[16593]=2521,[16651]=2652}) do
    check(SL.DB.zones[area] and SL.DB.zones[area][1]==map,"Forever AreaID -> UiMapID mapping")
end
check(#SL.Search:Run("ishing trainer")==0,"word-start prefix, not substring scan")
local qTimes={}
for _,query in ipairs({"fishing trainer","linen cloth","copper vein","flight master","thunder bluff",
    "fishing tra","mage trainer","blacksmithing trainer","repair","innkeeper","mailbox","bank"}) do
    local start=os.clock()
    local results,total=SL.Search:Run(query)
    local ms=(os.clock()-start)*1000
    qTimes[query]=ms
    check(#results>0 and #results<=10,query.." must return capped results")
    for i=2,#results do
        local a,b=results[i-1],results[i]
        check(a.tier<b.tier or (a.tier==b.tier and a.metric<=b.metric),"distance order: "..query)
    end
    if query=="fishing trainer" then check(results[1].record.id==5493,"standing next to Arnold must rank him first") end
    if query=="linen cloth" then
        local linen
        for _,r in ipairs(results) do if r.record.id==2589 and r.record.kind=="i" then linen=r end end
        check(linen and linen.source and linen.location and linen.sourceType=="Mob drop","cloth must resolve a physical mob source")
    end
    if query=="copper vein" then check(results[1].record.kind=="o" and results[1].location,"copper object/spawn") end
    if query=="thunder bluff" then
        check(results[1].location and results[1].location.map==1456,"zone aliases should locate Thunder Bluff")
        check(SL.Search:Describe(results[1]):find("Other continent"),"cross-continent label")
    end
    local name=results[1].record.name
    print(string.format("QUERY %-23s %7.3f ms | %5d matches | %s",query,ms,total,name))
end

-- All requested profession/class role aliases; select the appropriate faction for shaman.
for _,profession in ipairs({"alchemy","blacksmithing","cooking","enchanting","engineering","first aid",
    "fishing","herbalism","leatherworking","mining","skinning","tailoring","riding"}) do
    check(#SL.Search:Run(profession.." trainer")>0,profession.." trainer alias")
end
for _,class in ipairs({"warrior","paladin","hunter","rogue","priest","shaman","mage","warlock","druid"}) do
    state.faction=class=="shaman" and "Horde" or "Alliance"
    check(#SL.Search:Run(class.." trainer")>0,class.." trainer alias")
end
state.faction="Horde"
local scoped=SL.Search:Run("fishing trainer thunder bluff")
check(#scoped>0 and scoped[1].record.kind=="n" and scoped[1].location.map==1456,"composite city/role query")
local partial=SL.Search:Run("thunder bl")
check(#partial>0 and partial[1].location.map==1456,"partial city prefix query")
state.faction="Alliance"

-- Exact affine projection, continent priority, multiple spawns and source type selection.
local D=SL.DB
local rowCount,spawnCount,sourceCount=#D.rows,#D.spawns,#D.sources
D.zones[90001]={1453,"Test Eastern"};D.zones[90002]={1456,"Test Kalimdor"}
local function fixture(kind,id,name,title,flags,faction,points,sources)
    D.spawns[#D.spawns+1]=points
    D.sources[#D.sources+1]=sources or ""
    D.rows[#D.rows+1]=table.concat({kind,id,name,title or "",flags or 0,faction or "",#D.spawns,#D.sources,90001},"\t")
    return SL.Search:GetRecord(#D.rows)
end
local vendor=fixture("n",90001,"Fixture Vendor","Trade Supplies",4,"A","90001,1000,1000")
local mob=fixture("n",90002,"Fixture Mob","",0,"","90001,9000,9000;90002,5000,5000")
local object=fixture("o",90003,"Fixture Box","",0,"","90001,5000,5000")
local item=fixture("i",90004,"Fixture Item","",0,"","","v"..vendor.index..";d"..mob.index..";o"..object.index)
state.map,state.x,state.y=1453,0.11,0.11
local loc,source,sourceType=SL.Search:Resolve(item,SL.Navigation:GetPlayerContext(),{})
check(source.id==90001 and sourceType=="Vendor" and loc.tier==0,"nearest vendor source")
check(math.abs(loc.distance-math.sqrt(200))<0.001,"world-space distance must be in yards, not normalized percent")
state.x,state.y=0.89,0.89
loc,source,sourceType=SL.Search:Resolve(item,SL.Navigation:GetPlayerContext(),{})
check(source.id==90002 and sourceType=="Mob drop","nearest mob source after moving")
state.x,state.y=0.5,0.5
loc,source,sourceType=SL.Search:Resolve(item,SL.Navigation:GetPlayerContext(),{})
check(source.id==90003 and sourceType=="Object loot" and loc.distance==0,"nearest containing object")
local stale={record=item,location=loc}
state.x,state.y=0.1,0.1
check(SL.Navigation:SetWaypoint(stale),"native waypoint")
check(state.lastPoint.x==0.1 and state.lastPoint.y==0.1,"click must re-resolve nearest source, not use stale result")
check(state.tracked>0,"native waypoint super-tracking")
check(SL.Navigation:SetWaypoint({record=item,areas={[90002]=true}}),"scoped waypoint")
check(state.lastPoint.uiMapID==1456,"click must preserve an explicit geographic filter")

state.denyNative=true
TomTom={AddWaypoint=function(_,map,tx,ty,options)
    state.tomtom=state.tomtom+1;check(options.persistent==false);return {map,tx,ty}
end}
check(SL.Navigation:SetWaypoint(stale) and state.tomtom>0,"TomTom fallback")
state.denyNative=false
local before=state.tomtom
check(SL.Navigation:SetWaypoint(stale) and state.tomtom==before+1,"native and TomTom used when both are present")
TomTom=nil;state.denyNative=true
check(not SL.Navigation:SetWaypoint(stale),"unsupported waypoint APIs fail gracefully")
local originalSet=C_Map.SetUserWaypoint
C_Map.SetUserWaypoint=function() return false end
state.denyNative=false
local trackedBefore=state.tracked
check(not SL.Navigation:SetWaypoint(stale),"native false return is not success")
check(state.tracked==trackedBefore,"failed native pin must not be super-tracked")
C_Map.SetUserWaypoint=originalSet

state.denyNative=false
check(not SL.Search:IsAccessible(vendor,{faction="H"},true),"faction-incompatible service")
check(SL.Search:IsAccessible(mob,{faction="H"},false),"hostile drop source remains searchable")
local beforeCalls=state.worldCalls
for _=1,100 do SL.Navigation:RankPoint(1453,0.5,0.5,SL.Navigation:GetPlayerContext()) end
check(state.worldCalls-beforeCalls<=100,"map transforms cached; only player point calls allowed")
state.instance=true
local context=SL.Navigation:GetPlayerContext()
check(context.world==nil and context.reason,"instances must not use stale outdoor position")
local noPos=SL.Search:Run("linen cloth",context)
check(#noPos>0 and not noPos[1].location.distance,"instance query should not crash or claim a distance")
state.instance=false;state.noWorld=true;state.noUnit=true
SL.Navigation:Invalidate()
context=SL.Navigation:GetPlayerContext()
local tier,_,_,distance=SL.Navigation:RankPoint(state.map,state.x,state.y,context)
check(tier==1 and distance==nil,"same-map fallback without world projection")
state.noMap=true
context=SL.Navigation:GetPlayerContext()
check(context.reason and not context.map and not context.world,"missing player position")
check(#SL.Search:Run("copper vein",context)>0,"search without position")
state.noMap=false;state.noWorld=false;state.noUnit=false
SL.Navigation:Invalidate()
-- Restore added fixture rows/pools. Bounded record cache entries are harmless and private.
for i=#D.rows,rowCount+1,-1 do D.rows[i]=nil end
for i=#D.spawns,spawnCount+1,-1 do D.spawns[i]=nil end
for i=#D.sources,sourceCount+1,-1 do D.sources[i]=nil end
D.zones[90001],D.zones[90002]=nil,nil

local unknown
for index in ipairs(SL.DB.rows) do
    local record=SL.Search:GetRecord(index)
    if record.kind=="i" and record.sources=="" then unknown=record;break end
end
local beforeUnknown=state.native
check(unknown and not SL.Navigation:SetWaypoint({record=unknown}),"unknown item source must not manufacture coordinates")
check(state.native==beforeUnknown,"unknown source does not place a pin")

-- Non-destructive key binding, deferred during combat; no addon SavedVariables used.
local bindings,saved={},0
function GetBindingKey(action)
    for key,value in pairs(bindings) do if value==action then return key end end
end
function GetBindingAction(key) return bindings[key] or "" end
function SetBinding(key,action) bindings[key]=action;return true end
function SaveBindings(set) saved=saved+1;check(set==2) end
function GetCurrentBindingSet() return 2 end
function InCombatLockdown() return state.combat end
SL:InstallDefaultBinding()
check(bindings["CTRL-SPACE"]=="SEARCHLIGHT_TOGGLE" and saved==1,"first-use Ctrl+Space binding")
SL:InstallDefaultBinding();check(saved==1,"do not resave installed binding")
bindings={["CTRL-SPACE"]="OTHER_ACTION"}
SL:InstallDefaultBinding();check(bindings["CTRL-SPACE"]=="OTHER_ACTION" and saved==1,"never overwrite existing action")
bindings={["ALT-S"]="SEARCHLIGHT_TOGGLE"}
SL:InstallDefaultBinding();check(not bindings["CTRL-SPACE"],"respect user rebind")
bindings={};state.combat=true;SL:InstallDefaultBinding()
check(SL.bindingPending and not bindings["CTRL-SPACE"],"combat deferral")
state.combat=false;SL.events.scripts.OnEvent(SL.events,"PLAYER_REGEN_ENABLED")
check(bindings["CTRL-SPACE"]=="SEARCHLIGHT_TOGGLE","binding after combat")

-- UI lifecycle, keyboard/mouse acceptance, slash opening, Esc, and incremental broad search.
SlashCmdList.SEARCHLIGHT("fishing trainer")
check(SL.UI.frame:IsShown() and SL.UI.edit:GetText()=="fishing trainer","slash query opens palette")
local frames=0
while (SL.UI.pending or SL.UI.job) and frames<1000 do SL.UI:Update(0.05);frames=frames+1 end
check(#SL.UI.results>0,"as-you-type results render")
SL.UI.edit.scripts.OnArrowPressed(SL.UI.edit,"DOWN")
check(SL.UI.selected==2,"arrow key selection")
SL.UI.edit.scripts.OnEscapePressed()
check(not SL.UI.frame:IsShown() and not SL.UI.edit.focus,"Esc closes and releases focus")
SL:Toggle();check(SL.UI.frame:IsShown(),"binding toggle opens")
SL.UI.edit:SetText("copper vein")
frames=0
while (SL.UI.pending or SL.UI.job) and frames<1000 do SL.UI:Update(0.05);frames=frames+1 end
local beforeNative=state.native
SL.UI.edit.scripts.OnEnterPressed()
check(state.native==beforeNative+1 and not SL.UI.frame:IsShown(),"Enter sets waypoint and closes")
SL.UI:Open("li")
local maxSlice,totalFrames=0,0
while (SL.UI.pending or SL.UI.job) and totalFrames<10000 do
    local start=os.clock();SL.UI:Update(0.05)
    maxSlice=math.max(maxSlice,(os.clock()-start)*1000);totalFrames=totalFrames+1
end
check(totalFrames<10000 and #SL.UI.results>0,"incremental broad query completes")
print(string.format("ASYNC query li: %d frames, max resume slice %.3f ms",totalFrames,maxSlice))
SL.UI.frame:Hide()

local warmTimes={}
for _,query in ipairs({"fishing trainer","linen cloth","copper vein","flight master","thunder bluff"}) do
    collectgarbage("collect")
    local start=os.clock()
    for _=1,20 do SL.Search:Run(query) end
    warmTimes[#warmTimes+1]=(os.clock()-start)*1000/20
    print(string.format("BENCH %-23s mean %7.3f ms (20 runs)",query,warmTimes[#warmTimes]))
end
collectgarbage("collect")
local warmMemory=collectgarbage("count")-dbStart
print(string.format("LOAD %.3f ms | retained DB+modules %.3f MiB | warm with palette/cache %.3f MiB",loadTime,dbMemory/1024,warmMemory/1024))
print(string.format("PASS %d assertions | %d entities | %d native waypoint calls",checks,#SL.DB.rows,state.native))
