local _, NS = ...
local CC = NS.CC
NS.RadialItems = {
    {"Postava", "TOGGLECHARACTER0", "Interface/Icons/INV_Chest_Cloth_21"},
    {"Profese", "TOGGLEPROFESSIONBOOK", "Interface/Icons/Trade_BlackSmithing"},
    {"Tasky", "OPENALLBAGS", "Interface/Icons/INV_Misc_Bag_08"},
    {"Kniha kouzel", "TOGGLESPELLBOOK", "Interface/Icons/INV_Misc_Book_09"},
    {"Game menu", "CLICK ClawControlRadialGameMenu:LeftButton", "Interface/Icons/INV_Misc_QuestionMark"},
    {"Chat", "OPENCHAT", "Interface/Icons/INV_Misc_Note_01"},
    {"Ukoly a mapa", "TOGGLEQUESTLOG", "Interface/Icons/INV_Misc_Map_01"},
    {"Talenty", "TOGGLETALENTS", "Interface/Icons/Ability_Marksmanship"},
}

function NS.RadialIndex(x, y)
    if x*x + y*y < 0.35*0.35 then return nil end
    local angle = math.atan2 and math.atan2(x,y) or math.atan(x,y)
    return math.floor((math.deg(angle) + 22.5) / 45) % 8 + 1
end

local function label(parent, value, size, y)
    local font = parent:CreateFontString(nil, "OVERLAY", size)
    font:SetPoint("CENTER", 0, y); font:SetWidth(150); font:SetText(value)
    font:SetShadowColor(0,0,0,1); font:SetShadowOffset(1,-1)
    return font
end

function CC:CreateRadial()
    local ring = CreateFrame("Frame", "ClawControlRadial", UIParent, "SecureHandlerStateTemplate")
    self.radial = ring
    ring:SetSize(560,560); ring:SetPoint("CENTER"); ring:SetFrameStrata("TOOLTIP")
    ring:EnableGamePadStick(true)
    ring:EnableGamePadButton(false)
    ring:EnableKeyboard(false)
    ring:SetPropagateKeyboardInput(false)
    ring:SetScript("OnGamePadStick", function() end)
    local texture = ring:CreateTexture(nil,"BACKGROUND")
    texture:SetAllPoints(); texture:SetTexture("Interface/AddOns/ClawControl/Assets/Wheel.tga")
    ring.overlays, ring.labels = {}, {}
    for i, item in ipairs(NS.RadialItems) do
        local overlay = ring:CreateTexture(nil,"ARTWORK")
        overlay:SetAllPoints(); overlay:SetTexture("Interface/AddOns/ClawControl/Assets/Wheel" .. i .. ".tga")
        overlay:Hide(); ring.overlays[i] = overlay
        local sector = CreateFrame("Button", nil, ring)
        local angle = math.rad((i-1)*45)
        sector:SetSize(128,104); sector:SetPoint("CENTER", math.sin(angle)*187, math.cos(angle)*187)
        local icon = sector:CreateTexture(nil,"OVERLAY")
        icon:SetSize(48,48); icon:SetPoint("CENTER",0,-8); icon:SetTexture(item[3])
        ring.labels[i] = label(sector,item[1],"GameFontNormal",36)
        local index = i
        sector:SetScript("OnEnter",function() self:SelectRadial(index) end)
        sector:SetScript("OnClick",function() self:SelectRadial(index) end)
    end
    ring.title = label(ring,"Vyber polozku","GameFontNormalLarge",26)
    label(ring,"Prava packa: vyber\nA: potvrdit\nB / Menu: zavrit","GameFontHighlightSmall",-28)
    local toggle = CreateFrame("Button","ClawControlRadialToggle",UIParent)
    toggle:RegisterForClicks("AnyUp"); toggle:SetScript("OnClick",function()
        if ring.opened then self:CloseRadial() else self:OpenRadial() end
    end)
    toggle:Hide()
    local cancel = CreateFrame("Button","ClawControlRadialCancel",UIParent)
    cancel:RegisterForClicks("AnyDown", "AnyUp")
    cancel:SetScript("OnClick",function() self:CloseRadial() end)
    cancel:Hide()
    -- TOGGLEGAMEMENU runs Escape handlers and may only dismiss another panel.
    -- Show the Blizzard frame from a hardware-triggered secure click instead.
    -- Never call ToggleGameMenu/ShowUIPanel from an addon callback.
    local gameMenu=CreateFrame("Button","ClawControlRadialGameMenu",UIParent,"SecureActionButtonTemplate")
    gameMenu:RegisterForClicks("AnyDown", "AnyUp")
    gameMenu:SetAttribute("useOnKeyDown",true)
    gameMenu:SetAttribute("pressAndHoldAction",true)
    gameMenu:SetAttribute("type","attribute")
    local menuGate=CreateFrame("Frame",nil,UIParent,"SecureHandlerAttributeTemplate")
    gameMenu:SetAttribute("attribute-frame",menuGate)
    gameMenu:SetAttribute("attribute-name","open-menu")
    gameMenu:SetAttribute("attribute-value",true)
    menuGate:SetFrameRef("ring",ring)
    menuGate:SetAttribute("_onattributechanged", [[
        if name~="open-menu" or not value then return end
        self:SetAttribute("open-menu",nil)
        self:SetAttribute("menu-stage","request")
        local ring=self:GetFrameRef("ring")
        local menu=self:GetFrameRef("game-menu")
        if not menu then self:SetAttribute("menu-stage","missing-menu"); return end
        if not ring:GetAttribute("open") then self:SetAttribute("menu-stage","closed-ring"); return end
        self:SetAttribute("menu-stage","close-ring")
        ring:ClearBindings()
        ring:SetAttribute("open",false)
        local controller=ring:GetFrameRef("controller")
        controller:SetAttribute("radial-open",false)
        controller:RunAttribute("refresh")
        ring:Hide()
        self:SetAttribute("menu-stage","show-menu")
        menu:Show()
        self:SetAttribute("menu-stage",menu:IsShown() and "shown" or "not-shown")
    ]])
    ring.gameMenuButton=gameMenu
    ring.gameMenuGate=menuGate
    gameMenu:SetScript("PostClick",function(_,_,down)
        if not down then return end
        self.menuConfirmPresses=(self.menuConfirmPresses or 0)+1
        if GameMenuFrame and not GameMenuFrame:IsShown() then
            self:Print("Game menu: faze=" .. tostring(menuGate:GetAttribute("menu-stage") or "no-action") ..
                ", pozadavek=" .. tostring(menuGate:GetAttribute("open-menu")) .. ". Posli tento text a pripadnou Lua chybu.")
        end
    end)
    gameMenu:Hide()
    ring:SetAttribute("_onstate-combat", [[
        if tonumber(newstate) == 1 then
            self:ClearBindings()
            if self:GetAttribute("open") then
                self:SetAttribute("open",false)
                local controller = self:GetFrameRef("controller")
                if controller then
                    controller:SetAttribute("radial-open",false)
                    controller:RunAttribute("refresh")
                end
            end
            self:Hide()
        end
    ]])
    RegisterStateDriver(ring,"combat","[combat] 1; 0")
    ring:SetScript("OnHide",function()
        if ring.opened and not InCombatLockdown() then self:CloseRadial() else self:FinishRadial() end
    end)
    ring:SetScript("OnUpdate",function(_,dt) self:UpdateRadial(dt) end)
    ring:Hide()
end

function CC:FinishRadial()
    local ring = self.radial
    if not ring or not ring.opened then return end
    ring.opened = false
    if ring.savedInput then
        pcall(SetGamePadFreeLook,ring.savedInput.freelook)
        pcall(SetGamePadCursorControl,ring.savedInput.cursor)
        pcall(SetCVar,"GamePadCursorLeftClick",ring.savedInput.click)
        ring.savedInput = nil
    end
end

function CC:CloseRadial()
    local ring = self.radial
    if not ring or not ring.opened or InCombatLockdown() then return end
    ClearOverrideBindings(ring)
    ring:SetAttribute("open",false)
    self.handler:SetAttribute("radial-open",false)
    self.handler:Execute([[self:RunAttribute("refresh")]])
    self:FinishRadial()
    ring:Hide()
end

function CC:OpenRadial()
    if InCombatLockdown() then self:Print("Kruhovy volic otevri mimo boj."); return false end
    if not self.active then return false end
    local ring = self.radial
    ring.selected, ring.timer, ring.closeAt, ring.previousA = nil,0,nil,false
    ring.savedInput = {freelook=IsGamePadFreelookEnabled(),cursor=IsGamePadCursorControlEnabled(),click=GetCVar("GamePadCursorLeftClick")}
    SetGamePadFreeLook(false); SetGamePadCursorControl(false); SetCVar("GamePadCursorLeftClick","none")
    ring.axes = {}
    for index=0,31 do
        local name = C_GamePad.AxisIndexToConfigName(index)
        if name then ring.axes[name] = index+1 end
    end
    ring.fallbackStick = nil
    for index=0,15 do
        local name = C_GamePad.StickIndexToConfigName(index)
        if name == (self.db.movementStick == "right" and "Movement" or "Camera") then ring.fallbackStick=index+1 end
    end
    local a = C_GamePad.ButtonBindingToIndex("PAD1")
    ring.aIndex = a and a+1
    self.handler:SetAttribute("radial-open",true)
    self.handler:Execute([[self:ClearBindings()]])
    ClearOverrideBindings(ring)
    for _, prefix in ipairs(NS.Prefixes) do
        for _, key in ipairs(NS.GetKeys(self.db)) do
            if key ~= "NONE" then SetOverrideBindingClick(ring,true,prefix..key,"ClawControlNoop","LeftButton") end
        end
        for _, key in ipairs(NS.ControlKeys) do
            SetOverrideBindingClick(ring,true,prefix..key,"ClawControlNoop","LeftButton")
            if self.db.controls[key] == "RADIAL" then
                SetOverrideBindingClick(ring,true,prefix..key,"ClawControlRadialCancel","LeftButton")
            end
        end
        for _, key in ipairs({"PADLSTICKUP","PADLSTICKDOWN","PADLSTICKLEFT","PADLSTICKRIGHT",
            "PADRSTICKUP","PADRSTICKDOWN","PADRSTICKLEFT","PADRSTICKRIGHT"}) do
            SetOverrideBindingClick(ring,true,prefix..key,"ClawControlNoop","LeftButton")
        end
        SetOverrideBindingClick(ring,true,prefix.."PAD1","ClawControlNoop","LeftButton")
        SetOverrideBindingClick(ring,true,prefix.."PAD2","ClawControlRadialCancel","LeftButton")
    end
    for _,overlay in ipairs(ring.overlays) do overlay:Hide() end
    ring.title:SetText("Vyber polozku")
    ring.opened = true; ring:SetAttribute("open",true); ring:Show()
    return true
end

function CC:SelectRadial(index)
    local ring = self.radial
    if not ring.opened or InCombatLockdown() or ring.selected == index then return end
    if index==5 then
        if not GameMenuFrame then C_AddOns.LoadAddOn("Blizzard_GameMenu") end
        if not GameMenuFrame then self:Print("Game menu se nepodarilo nacist."); return end
        ring.gameMenuGate:SetFrameRef("game-menu",GameMenuFrame)
    end
    ring.selected=index; ring.title:SetText(NS.RadialItems[index][1])
    for i,overlay in ipairs(ring.overlays) do overlay:SetShown(i==index) end
    -- Execute panels using native bindings, never addon calls to protected UI.
    for _,prefix in ipairs(NS.Prefixes) do
        SetOverrideBinding(ring,true,prefix.."PAD1",NS.RadialItems[index][2])
    end
end

function CC:UpdateRadial(dt)
    local ring = self.radial
    if not ring.opened or InCombatLockdown() then return end
    if ring.closeAt and GetTime()>=ring.closeAt then self:CloseRadial(); return end
    ring.timer=ring.timer+dt; if ring.timer<0.02 then return end; ring.timer=0
    local state=C_GamePad.GetDeviceMappedState(self.turnDeviceID)
    if not state then return end
    local x,y=0,0
    if state.axes and ring.axes.RStickX and ring.axes.RStickY then
        x,y=state.axes[ring.axes.RStickX] or 0,state.axes[ring.axes.RStickY] or 0
    elseif state.sticks and ring.fallbackStick and state.sticks[ring.fallbackStick] then
        local stick=state.sticks[ring.fallbackStick]; x,y=stick.x,stick.y
    end
    local index=NS.RadialIndex(x,y)
    if index then self:SelectRadial(index) end
    local a=state.buttons and ring.aIndex and state.buttons[ring.aIndex]
    -- Game menu closes synchronously in its secure click handler. A timer here
    -- could remove the A override before the physical button is released.
    if a and not ring.previousA and ring.selected and ring.selected~=5 then ring.closeAt=GetTime()+0.05 end
    ring.previousA=a
end
