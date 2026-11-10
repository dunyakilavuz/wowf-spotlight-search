-- SPDX-License-Identifier: GPL-3.0-only
local SL = Searchlight
BINDING_HEADER_SEARCHLIGHT = "Searchlight"
BINDING_NAME_SEARCHLIGHT_TOGGLE = "Open / close Searchlight"

function SL:InstallDefaultBinding()
    if InCombatLockdown and InCombatLockdown() then self.bindingPending=true;return end
    self.bindingPending=nil
    if not (GetBindingAction and GetBindingKey and SetBinding and SaveBindings) then return end
    -- Do not override another action or a user-rebound Searchlight command.
    if GetBindingKey("SEARCHLIGHT_TOGGLE") then return end
    local existing=GetBindingAction("CTRL-SPACE",true)
    if existing and existing~="" then return end
    if SetBinding("CTRL-SPACE","SEARCHLIGHT_TOGGLE") then
        SaveBindings(GetCurrentBindingSet and GetCurrentBindingSet() or 1)
    end
end

function SL:Diagnostics()
    local version,build,_,interface
    if GetBuildInfo then version,build,_,interface=GetBuildInfo() end
    local ctx=self.Navigation:GetPlayerContext()
    self:Print(string.format("v%s | DB %s (%d entities) | client %s build %s interface %s | map %s, world %s",
        self.version,self.DB.meta.flavor,self.DB.meta.rows,tostring(version),tostring(build),tostring(interface),
        tostring(ctx.map),tostring(ctx.world)))
    self:Print("DB source revision: "..self.DB.meta.sourceRevision.."; native waypoints "..
        tostring(C_Map and C_Map.SetUserWaypoint~=nil)..", TomTom "..tostring(TomTom~=nil))
end

SLASH_SEARCHLIGHT1 = "/sl"
SLASH_SEARCHLIGHT2 = "/searchlight"
SlashCmdList.SEARCHLIGHT = function(text)
    text=tostring(text or ""):match("^%s*(.-)%s*$")
    if text=="status" then SL:Diagnostics()
    elseif text~="" then SL.UI:Open(text)
    else SL:Toggle() end
end

local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_LOGIN" then
        SL:InstallDefaultBinding()
    elseif event=="PLAYER_REGEN_ENABLED" and SL.bindingPending then
        SL:InstallDefaultBinding()
    end
    if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then
        SL.Navigation:Invalidate()
        if SL.UI.frame and SL.UI.frame:IsShown() then SL.UI:Queue(false) end
    end
end)
SL.events=events
