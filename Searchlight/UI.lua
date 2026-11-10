-- SPDX-License-Identifier: GPL-3.0-only
local SL = Searchlight
local UI = {results={}, selected=1}
SL.UI = UI
local function millis()
    if debugprofilestop then return debugprofilestop() end
    return (GetTime and GetTime() or 0)*1000
end
local function font(parent,template,x,y,width)
    local text=parent:CreateFontString(nil,"OVERLAY",template)
    text:SetPoint("TOPLEFT",x,y)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    return text
end
local function fill(parent,r,g,b,a)
    local tex=parent:CreateTexture(nil,"BACKGROUND")
    tex:SetAllPoints()
    tex:SetColorTexture(r,g,b,a)
    return tex
end

function UI:Select(index)
    if #self.results==0 then self.selected=1; return end
    self.selected=((index-1)%#self.results)+1
    for i,row in ipairs(self.rows) do row.selected:SetShown(i==self.selected) end
    if self.total and self.total>0 then
        local result=self.results[self.selected]
        local note=self.context.reason or "Source reliability + distance; straight-line, not a route"
        if result and result.sourceType=="Auction House" then
            note="AH suggestion only: listings/tradability unverified"
        elseif result and result.sourceType=="Vendor" then
            note="Vendor recorded; stock and purchase/use requirements unverified"
        end
        self.status:SetText(string.format("%d of %d matches | %s",#self.results,self.total,note))
    end
end

function UI:Accept(index)
    local result=self.results[index or self.selected]
    if not result then return end
    local ok,message=SL.Navigation:SetWaypoint(result)
    SL:Print(message)
    if ok then self.frame:Hide() else self.status:SetText(message) end
end

function UI:Render(results,total,context)
    local selected=self.results[self.selected]
    local keep=selected and selected.index
    self.results,self.total,self.context=results,total,context
    for i,row in ipairs(self.rows) do
        local result=results[i]
        row.result=result
        if result then
            row.name:SetText(result.record.name)
            row.detail:SetText(SL.Search:Describe(result))
            local tags={n="NPC",i="ITEM",o="OBJECT"}
            row.tag:SetText(result.sourceType=="Auction House" and "AH?" or (tags[result.record.kind] or ""))
            row:Show()
            if result.index==keep then self.selected=i end
        else
            row:Hide()
        end
    end
    self:Select(math.min(self.selected,math.max(1,#results)))
    self.frame:SetHeight(132+#results*54)
    if #SL.Search:Normalize(self.edit:GetText())<SL.MIN_QUERY_LENGTH then
        self.status:SetText("Type 2+ characters: fishing trainer, linen cloth, copper vein...")
    elseif total==0 then
        self.status:SetText("No matches. Try an English name, profession or service.")
    end
end

function UI:Queue(clear)
    self.job=nil
    self.pending=0
    self.refresh=0
    if clear then
        self.selected=1
        self:Render({},0,{})
        self.status:SetText("Searching...")
    end
end

function UI:StartSearch()
    self.pending=nil
    local query=self.edit:GetText()
    local context=SL.Navigation:GetPlayerContext()
    local deadline=millis()+SL.SEARCH_BUDGET_MS
    self.job=coroutine.create(function()
        local function cooperate()
            if millis()>=deadline then
                coroutine.yield()
                deadline=millis()+SL.SEARCH_BUDGET_MS
            end
        end
        local results,total=SL.Search:Run(query,context,SL.MAX_RESULTS,cooperate)
        return results,total,context
    end)
end

function UI:Update(elapsed)
    self.refresh=(self.refresh or 0)+elapsed
    if self.pending then
        self.pending=self.pending+elapsed
        if self.pending>=SL.SEARCH_THROTTLE then self:StartSearch() end
    end
    if self.job then
        local ok,results,total,context=coroutine.resume(self.job)
        if not ok then
            self.job=nil
            self.status:SetText("Search failed. See chat for details.")
            SL:Print("Search error: "..tostring(results))
        elseif coroutine.status(self.job)=="dead" then
            self.job=nil
            self.refresh=0
            self:Render(results,total,context)
        end
    elseif not self.pending and self.refresh>=1 and #SL.Search:Normalize(self.edit:GetText())>=SL.MIN_QUERY_LENGTH then
        self:Queue(false)
    end
end

function UI:Create()
    if self.frame then return end
    local frame=CreateFrame("Frame","SearchlightPalette",UIParent,BackdropTemplateMixin and "BackdropTemplate" or nil)
    self.frame=frame
    frame:SetSize(720,132)
    frame:SetPoint("TOP",UIParent,"TOP",0,-160)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    fill(frame,0.035,0.049,0.075,0.98)
    if frame.SetBackdrop then
        frame:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        frame:SetBackdropBorderColor(0.22,0.50,0.63,0.9)
    end
    local title=font(frame,"GameFontNormalSmall",20,-16,300)
    title:SetText("S E A R C H L I G H T")
    title:SetTextColor(0.40,0.85,1)
    local hint=font(frame,"GameFontDisableSmall",360,-16,315)
    hint:SetJustifyH("RIGHT")
    hint:SetText("Up / Down select   Enter navigate   Esc close")
    local close=CreateFrame("Button",nil,frame)
    close:SetSize(24,24);close:SetPoint("TOPRIGHT",-6,-7)
    local cross=close:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    cross:SetAllPoints();cross:SetText("x")
    close:SetScript("OnClick",function() frame:Hide() end)
    local bar=CreateFrame("Frame",nil,frame)
    bar:SetPoint("TOPLEFT",18,-40);bar:SetPoint("TOPRIGHT",-18,-40);bar:SetHeight(38)
    fill(bar,0.08,0.11,0.16,1)
    local edit=CreateFrame("EditBox",nil,bar)
    self.edit=edit
    edit:SetAllPoints();edit:SetTextInsets(12,12,0,0)
    edit:SetFontObject("GameFontHighlightLarge")
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(120)
    local placeholder=font(bar,"GameFontDisable",12,-10,620)
    placeholder:SetText("Find NPCs, items, objects, trainers, services...")
    edit:SetScript("OnTextChanged",function()
        placeholder:SetShown(edit:GetText()=="")
        self:Queue(true)
    end)
    edit:SetScript("OnEnterPressed",function() self:Accept() end)
    edit:SetScript("OnEscapePressed",function() frame:Hide() end)
    edit:SetScript("OnArrowPressed",function(_,key)
        if key=="UP" then self:Select(self.selected-1)
        elseif key=="DOWN" then self:Select(self.selected+1) end
    end)
    self.rows={}
    for i=1,SL.MAX_RESULTS do
        local index=i -- own upvalue in Lua 5.1
        local row=CreateFrame("Button",nil,frame)
        self.rows[i]=row
        row:SetHeight(52)
        row:SetPoint("TOPLEFT",18,-86-(i-1)*54)
        row:SetPoint("TOPRIGHT",-18,-86-(i-1)*54)
        row.selected=fill(row,0.12,0.29,0.39,0.75)
        row.selected:Hide()
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        row.name=font(row,"GameFontHighlight",12,-7,570)
        row.detail=font(row,"GameFontDisableSmall",12,-29,655)
        row.tag=font(row,"GameFontNormalSmall",590,-8,78)
        row.tag:SetJustifyH("RIGHT");row.tag:SetTextColor(0.40,0.85,1)
        row:SetScript("OnClick",function() self:Accept(index) end)
        row:SetScript("OnEnter",function()
            if row.result and GameTooltip then
                self:Select(index)
                GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
                GameTooltip:AddLine(row.result.record.name,0.4,0.85,1)
                GameTooltip:AddLine(SL.Search:Describe(row.result),1,1,1,true)
                GameTooltip:AddLine("Click / Enter: location waypoint",0.65,0.65,0.65)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        row:Hide()
    end
    local status=frame:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    self.status=status
    status:SetPoint("BOTTOMLEFT",20,14);status:SetPoint("BOTTOMRIGHT",-20,14)
    status:SetJustifyH("LEFT");status:SetWordWrap(false)
    frame:SetScript("OnUpdate",function(_,elapsed) self:Update(elapsed) end)
    frame:SetScript("OnShow",function() edit:SetFocus();self:Queue(false) end)
    frame:SetScript("OnHide",function()
        edit:ClearFocus();self.job=nil;self.pending=nil
        if GameTooltip then GameTooltip:Hide() end
    end)
    UISpecialFrames=UISpecialFrames or {}
    table.insert(UISpecialFrames,"SearchlightPalette")
    frame:Hide()
    edit:SetText("")
end

function UI:Open(query)
    self:Create()
    self.frame:Show()
    if query then self.edit:SetText(query) end
    self.edit:SetFocus()
    self.edit:HighlightText()
end

function SL:Toggle()
    if UI.frame and UI.frame:IsShown() then UI.frame:Hide() else UI:Open() end
end
