local _, NS = ...
local CC = NS.CC
local function label(parent,value,y,font)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormalSmall")
    t:SetPoint("TOP",0,y); t:SetText(value); t:SetShadowColor(0,0,0,1); t:SetShadowOffset(1,-1)
    return t
end

function CC:GetHUDAction(layer,slot)
    if self.actions and self.actions[layer] then return self.actions[layer][slot]:CalculateAction() end
    local bar=slot>=7 and 1 or self.db.layerBars[layer]
    if bar~=1 then return NS.BarOffsets[bar]+slot end
    local page=GetActionBarPage()
    if HasVehicleActionBar() then page=GetVehicleBarIndex()
    elseif HasOverrideActionBar() then page=GetOverrideBarIndex()
    elseif HasTempShapeshiftActionBar() then page=GetTempShapeshiftBarIndex()
    elseif GetBonusBarOffset()>0 then page=GetBonusBarOffset()+6 end
    return ((page or 1)-1)*12+slot
end

function CC:UpdateHUDSlot(cell,action)
    cell.icon:SetTexture(GetActionTexture(action))
    if C_ActionBar.GetActionCooldownDuration and cell.cooldown.SetCooldownFromDurationObject then
        local duration=C_ActionBar.GetActionCooldownDuration(action)
        if duration then cell.cooldown:SetCooldownFromDurationObject(duration) else cell.cooldown:Clear() end
    else cell.cooldown:Clear() end
end

function CC:RefreshHUD()
    local hud=self.hud; if not hud then return end
    local active=NS.GetLayer()
    local names=self.db.modifierSwap and {"Zaklad","LT","RT","LT + RT"} or {"Zaklad","RT","LT","LT + RT"}
    hud.title:SetText(names[active].." | BAR "..self.db.layerBars[active])
    for layer,group in ipairs(hud.groups) do
        group.title:SetText(names[layer].." | BAR "..self.db.layerBars[layer])
        group.title:SetTextColor(layer==active and 1 or 0.75,layer==active and 0.83 or 0.75,layer==active and 0.25 or 0.75)
        group:SetAlpha(layer==active and 1 or 0.65)
    end
    local keys=NS.GetKeys(self.db)
    for _,cell in ipairs(hud.displayCells or {}) do
        local layer=cell.layer==0 and active or cell.layer
        local slot=cell.slot
        local caption=slot==7 and "M1" or slot==8 and "M2" or NS.OptionLabel(NS.InputOptions,keys[slot]):gsub("Klavesa ","")
        cell.caption:SetText(caption)
        cell.cooldown:SetHideCountdownNumbers(not self.db.cooldownNumbers)
        cell:SetAlpha(keys[slot]=="NONE" and 0.35 or 1)
        self:UpdateHUDSlot(cell,self:GetHUDAction(layer,slot))
    end
    hud.lastLayer=active
end

function CC:ApplyHUDLayout()
    local hud=self.hud; if not hud then return end
    if not self.db.hudUnlocked then self:FinishHUDMove() end
    hud.moveHandle:SetShown(self.db.hudUnlocked)
    local clusters=self.db.hudLayout=="clusters"
    hud:SetSize(clusters and 690 or 450,clusters and 440 or 105)
    hud.row:SetShown(not clusters); hud.title:SetShown(not clusters)
    hud:SetBackdropColor(0.025,0.04,0.06,clusters and 0 or 0.92)
    hud:SetBackdropBorderColor(0.3,0.3,0.3,clusters and 0 or 1)
    hud.displayCells={}
    for _,cell in ipairs(hud.slots) do if not clusters then table.insert(hud.displayCells,cell) end end
    for layer,group in ipairs(hud.groups) do
        local settings=self.db.hudGroups[layer]
        local scale=settings.scale>0 and settings.scale or 1
        local visible=settings.visible and settings.scale>0
        group:SetScale(scale)
        local p=self.db.groupPositions[layer] or group.origin
        group:ClearAllPoints()
        group:SetPoint("CENTER",hud,"CENTER",p[1]/scale,p[2]/scale)
        group:SetShown(clusters and visible)
        group.moveHandle:SetShown(self.db.hudUnlocked)
        for slot,cell in ipairs(group.slots) do
            local shown=layer==1 or slot<=6
            cell:SetShown(shown)
            if clusters and visible and shown then table.insert(hud.displayCells,cell) end
        end
    end
    self:RefreshHUD()
end

function CC:FinishHUDMove()
    local frame=self.hudMoving
    if not frame then return end
    self.hudMoving=nil
    frame:StopMovingOrSizing()
    if frame.hudLayer then
        local x,y=frame:GetCenter()
        local hx,hy=self.hud:GetCenter()
        local fs,hs=frame:GetEffectiveScale(),self.hud:GetEffectiveScale()
        if x and y and hx and hy then
            local p={(x*fs-hx*hs)/hs,(y*fs-hy*hs)/hs}
            self.db.groupPositions[frame.hudLayer]=p
            frame:ClearAllPoints()
            frame:SetPoint("CENTER",self.hud,"CENTER",p[1]/frame:GetScale(),p[2]/frame:GetScale())
            if self.options and self.options.draft then
                self.options.draft.groupPositions=CopyTable(self.db.groupPositions)
            end
        end
    else
        local point,_,relative,x,y=frame:GetPoint()
        self.db.position={point,relative,x,y}
    end
end

function CC:CreateHUDMoveHandle(frame,layer)
    frame:SetMovable(true); frame:SetClampedToScreen(true)
    local handle=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
    frame.moveHandle=handle; frame.hudLayer=layer
    handle:EnableMouse(true); handle:SetFrameLevel(frame:GetFrameLevel()+20)
    handle:SetSize(layer and 76 or 86,22)
    if layer then handle:SetPoint("TOP",0,25); handle:SetText("Presun "..layer)
    else handle:SetPoint("TOPRIGHT",-5,-5); handle:SetText("Presun vse") end
    handle:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" then return end
        if InCombatLockdown() then self:Print("Prehled presouvej mimo boj."); return end
        self:FinishHUDMove()
        self.hudMoving=frame; frame:StartMoving()
    end)
    handle:SetScript("OnMouseUp",function(_,button)
        if button=="LeftButton" then self:FinishHUDMove() end
    end)
    frame:SetScript("OnHide",function() if self.hudMoving==frame then self:FinishHUDMove() end end)
end

function CC:CreateHUD()
    local hud=CreateFrame("Frame","ClawControlHUD",UIParent,"BackdropTemplate")
    self.hud=hud
    hud:SetPoint("BOTTOM",0,145); hud:SetScale(self.db.scale)
    hud:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=12})
    hud:EnableMouse(false)
    self:CreateHUDMoveHandle(hud)
    if self.db.position then
        local p=self.db.position; hud:ClearAllPoints(); hud:SetPoint(p[1],UIParent,p[2],p[3],p[4])
    end
    hud.title=label(hud,"",-10,"GameFontNormal")
    local function cell(parent,layer,slot,x,y,size)
        local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
        f:SetSize(size,size); f:SetPoint("CENTER",x,y); f.layer,f.slot=layer,slot
        f:SetBackdrop({edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=9})
        f.icon=f:CreateTexture(nil,"BACKGROUND"); f.icon:SetPoint("TOPLEFT",3,-3); f.icon:SetPoint("BOTTOMRIGHT",-3,3)
        f.icon:SetTexCoord(0.07,0.93,0.07,0.93)
        f.cooldown=CreateFrame("Cooldown",nil,f,"CooldownFrameTemplate")
        f.cooldown:SetPoint("TOPLEFT",3,-3); f.cooldown:SetPoint("BOTTOMRIGHT",-3,3)
        f.cooldown:EnableMouse(false); f.cooldown:SetDrawSwipe(true); f.cooldown:SetSwipeColor(0,0,0,0.65)
        f.cooldown:SetDrawEdge(false); f.cooldown:SetDrawBling(false); f.cooldown:SetMinimumCountdownDuration(0)
        f.cooldown:GetCountdownFontString():SetFontObject(GameFontNormalLarge)
        f.caption=label(f,"",-size,"GameFontNormalSmall")
        if layer~=0 then
            f.caption:ClearAllPoints()
            f.caption:SetPoint("TOPLEFT",3,-2)
        end
        return f
    end
    hud.row=CreateFrame("Frame",nil,hud); hud.row:SetAllPoints()
    hud.slots={}
    for slot=1,8 do hud.slots[slot]=cell(hud.row,0,slot,-188+(slot-1)*53,-3,45) end
    hud.groups={}
    local origins={{0,110},{230,-10},{-230,-10},{0,-130}}
    -- Compact user sketch: no empty center; shoulders/rear keys fan out diagonally.
    local positions={{0,-19},{38,0},{-38,0},{0,19},{60,38},{-60,38},{-60,-38},{60,-38}}
    for layer=1,4 do
        local group=CreateFrame("Frame",nil,hud)
        group.origin=origins[layer]
        group:SetSize(160,148); group:SetPoint("CENTER",origins[layer][1],origins[layer][2])
        group:EnableMouse(false)
        self:CreateHUDMoveHandle(group,layer)
        group.title=label(group,"",0,"GameFontNormal"); group.slots={}
        for slot,p in ipairs(positions) do group.slots[slot]=cell(group,layer,slot,p[1],p[2],36) end
        hud.groups[layer]=group
    end
    self:ApplyHUDLayout()
    local elapsed=0
    hud:SetScript("OnUpdate",function(_,dt)
        if self.hudMoving and not IsMouseButtonDown("LeftButton") then self:FinishHUDMove() end
        elapsed=elapsed+dt; if elapsed<0.1 then return end; elapsed=0
        if hud.lastLayer~=NS.GetLayer() then self:RefreshHUD() end
    end)
    for _,event in ipairs({"ACTIONBAR_UPDATE_COOLDOWN","ACTIONBAR_SLOT_CHANGED","SPELL_UPDATE_CHARGES","PLAYER_ENTERING_WORLD",
        "ACTIONBAR_PAGE_CHANGED","UPDATE_BONUS_ACTIONBAR","UPDATE_SHAPESHIFT_FORM","UPDATE_OVERRIDE_ACTIONBAR",
        "UPDATE_VEHICLE_ACTIONBAR","PLAYER_REGEN_ENABLED","MODIFIER_STATE_CHANGED"}) do hud:RegisterEvent(event) end
    hud:SetScript("OnEvent",function() self:RefreshHUD() end)
    hud:SetScript("OnShow",function() self:RefreshHUD() end)
    hud:Hide()
end
