local addonName, NS = ...
local CC = CreateFrame("Frame", "ClawControl", UIParent)
NS.CC = CC

function CC:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff6bdcbdClaw Control:|r " .. tostring(message))
end

local function isConsolePortLoaded()
    return C_AddOns.IsAddOnLoaded("ConsolePort")
end

function CC:FindDevice()
    local id = C_GamePad.GetActiveDeviceID()
    local ids = C_GamePad.GetAllDeviceIDs()
    if self.db.deviceID then
        for _, candidate in ipairs(ids) do
            if candidate == self.db.deviceID then id = candidate; break end
        end
    end
    local ok, raw = pcall(C_GamePad.GetDeviceRawState, id)
    if not ok or not raw then
        id = ids[1]
        if id then ok, raw = pcall(C_GamePad.GetDeviceRawState, id) end
    end
    if not ok or not raw then return nil end
    return {vendorID = raw.vendorID, productID = raw.productID}, raw.name, id
end

function CC:GetDesiredCVars(deviceID)
    local db = self.db
    local desired = {
        GamePadEnable = "1",
        GamePadSingleActiveID = tostring(deviceID),
        GamePadEmulateShift = db.modifierSwap and "PADLTRIGGER" or "PADRTRIGGER",
        GamePadEmulateCtrl = db.modifierSwap and "PADRTRIGGER" or "PADLTRIGGER",
        GamePadEmulateAlt = "none",
        GamePadEmulateTapWindowMs = "0",
        GamePadStickAxisButtons = "1",
        GamePadAnalogMovement = "1",
        GamePadFaceMovementMaxAngle = "0",
        GamePadFaceMovementMaxAngleCombat = "0",
        GamePadTankTurnSpeed = "0",
        GamePadTurnWithCamera = "2",
        GamePadCameraYawSpeed = tostring(NS.NormalizeTurnSpeed(db.turnSpeed)),
        GamePadCameraPitchSpeed = "0",
        GamePadCursorLeftClick = NS.GetCursorKey(db),
        GamePadCursorRightClick = "none",
        GamePadCursorAutoEnable = "1",
        GamePadCursorAutoDisableSticks = "2",
        GamePadCursorAutoDisableJump = "1",
        SoftTargetInteract = NS.HasInteraction(db) and "1" or GetCVar("SoftTargetInteract"),
    }
    if GetCVar("GamePadEmulateEsc") ~= nil then desired.GamePadEmulateEsc = "none" end
    return desired
end

function CC:CreateSecureHandler()
    if self.handler then return end
    self.noop = CreateFrame("Button", "ClawControlNoop", UIParent, "SecureActionButtonTemplate")
    self.noop:RegisterForClicks("AnyDown", "AnyUp")
    self.handler = CreateFrame("Frame", "ClawControlBindings", UIParent, "SecureHandlerStateTemplate")
    self.handler:SetSize(1, 1)
    self.handler:SetPoint("CENTER")
    self.handler:Show()
    self.bindingOwner = CreateFrame("Frame", "ClawControlBaseBindings", UIParent)
    self.bindingOwner:SetSize(1, 1)
    self.bindingOwner:SetPoint("CENTER")
    self.bindingOwner:Show()
    NS.CreateActions(self)
    self.handler:SetAttribute("refresh", NS.SecureRefresh)
    self.handler:SetAttribute("_onstate-layer", [[self:RunAttribute("refresh")]])
    self.handler:SetAttribute("_onstate-mounted", [[self:RunAttribute("refresh")]])
    self.handler:SetAttribute("_onstate-page", NS.SecurePage)
end

function CC:StopBindings()
    if not self.handler then return end
    self.handler:SetAttribute("enabled", false)
    UnregisterStateDriver(self.handler, "layer")
    UnregisterStateDriver(self.handler, "mounted")
    UnregisterStateDriver(self.handler, "page")
    self.handler:Execute([[self:ClearBindings()]])
    ClearOverrideBindings(self.bindingOwner)
end

function CC:StartBindings()
    self:CreateSecureHandler()
    NS.ConfigureActions(self)
    if self.radial then self.radial:SetFrameRef("controller", self.handler) end
    local handler = self.handler
    for slot, key in ipairs(NS.GetKeys(self.db)) do handler:SetAttribute("key" .. slot, key) end
    for layer, command in ipairs(NS.Bars) do handler:SetAttribute("bar" .. layer, command) end
    for index, prefix in ipairs(NS.Prefixes) do handler:SetAttribute("prefix" .. index, prefix) end
    for index, key in ipairs(NS.ControlKeys) do
        handler:SetAttribute("control-key" .. index, key)
        handler:SetAttribute("control-" .. key, self.db.controls[key])
    end
    for index, key in ipairs(NS.AxisButtonKeys) do handler:SetAttribute("axis-key" .. index, key) end
    local pitch = self.db.flight == "skyriding"
    local up, down = pitch and "PITCHUP" or "JUMP", pitch and "PITCHDOWN" or "SITORSTAND"
    if self.db.invertFlight then up, down = down, up end
    if pitch then
        -- Native analog pitch owns this axis in Skyriding. Never also fire
        -- cardinal pitch bindings, which can compete with the camera control.
        up, down = "CLICK ClawControlNoop:LeftButton", "CLICK ClawControlNoop:LeftButton"
    end
    handler:SetAttribute("flight-up", up)
    handler:SetAttribute("flight-down", down)
    local turn = self.db.movementStick == "left" and "R" or "L"
    handler:SetAttribute("flight-key-up", "PAD" .. turn .. "STICKUP")
    handler:SetAttribute("flight-key-down", "PAD" .. turn .. "STICKDOWN")
    handler:SetAttribute("enabled", true)
    NS.InstallBaseBindings(self)
    RegisterStateDriver(handler, "layer", NS.LayerCondition)
    RegisterStateDriver(handler, "mounted", "[mounted] 1; 0")
    RegisterStateDriver(handler, "page", NS.PageCondition)
    handler:Execute([[self:RunAttribute("refresh")]])
end

function CC:RestoreBackup()
    local backup = self.db.backup
    if not backup then return true end
    local errors = {}
    local function attempt(fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok then table.insert(errors, tostring(err)) end
    end
    if backup.config then
        attempt(C_GamePad.SetConfig, backup.config)
    elseif backup.id then
        attempt(C_GamePad.DeleteConfig, backup.id)
    end
    attempt(C_GamePad.ApplyConfigs)
    for cvar, value in pairs(backup.cvars) do attempt(SetCVar, cvar, value) end
    if backup.freelook ~= nil then attempt(SetGamePadFreeLook, backup.freelook) end
    if backup.cursor ~= nil then attempt(SetGamePadCursorControl, backup.cursor) end
    if #errors > 0 then
        self:Print("Obnova neni uplna; zaloha zustava ulozena. " .. table.concat(errors, "; "))
        return false
    end
    self.db.backup = nil
    return true
end

function CC:Disable()
    if InCombatLockdown() then self:Print("Vypnuti proved mimo boj."); return false end
    if self.radial and self.radial.opened then self:CloseRadial() end
    self:StopBindings()
    self:StopTurning()
    self.active, self.db.enabled = false, false
    local barsRestored = self:RestoreNativeBars()
    local settingsRestored = self:RestoreBackup()
    local restored = barsRestored and settingsRestored
    if self.hud then self.hud:Hide() end
    if restored then self:Print("Profil vypnut, puvodni nastaveni obnoveno.") end
    return restored
end

function CC:Enable()
    if InCombatLockdown() then self:Print("Zapnuti proved mimo boj."); return false end
    if self.active then return true end
    -- Script registration / old diagnostic mode must never consume gameplay input.
    self:EnableGamePadButton(false)
    self:EnableKeyboard(false)
    self.testing = false
    if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
        self:Print("Tato verze je urcena pouze pro WoW Retail."); return false
    end
    if isConsolePortLoaded() then
        self:Print("Nejprve vypni ConsolePort a jeho moduly v seznamu addonu a pouzij /reload.")
        return false
    end
    local valid, validationError = NS.ValidateProfile(self.db)
    if not valid then
        self:Print(validationError); return false
    end
    -- A persisted snapshot belongs to the previous activation, including across reload.
    -- Restore before taking a new snapshot, so our own settings never become the backup.
    if self.db.backup and not self:RestoreBackup() then return false end
    local oldEnable = GetCVar("GamePadEnable")
    SetCVar("GamePadEnable", "1")
    local id, name, deviceID = self:FindDevice()
    if not id then
        SetCVar("GamePadEnable", oldEnable)
        self:Print("Ovladac nenalezen. Zapni v MSI Center M rezim Gamepad a zkus znovu.")
        return false
    end
    local desired = self:GetDesiredCVars(deviceID)
    local snapshot = {
        id = CopyTable(id), config = C_GamePad.GetConfig(id), cvars = {},
        freelook = IsGamePadFreelookEnabled(), cursor = IsGamePadCursorControlEnabled(),
    }
    for cvar in pairs(desired) do
        local value = GetCVar(cvar)
        if value == nil then
            SetCVar("GamePadEnable", oldEnable)
            self:Print("Klient nepodporuje nastaveni " .. cvar .. ". Profil nebyl zapnut.")
            return false
        end
        snapshot.cvars[cvar] = value
    end
    snapshot.cvars.GamePadEnable = oldEnable
    snapshot.config = snapshot.config and CopyTable(snapshot.config)
    self.db.backup = snapshot
    local ok, err = pcall(function()
        local config = NS.MakeDeviceConfig(snapshot.config, id, self.db)
        C_GamePad.SetConfig(config)
        C_GamePad.ApplyConfigs()
        -- Reapply axis buttons, even when the CVar is already 1 (client startup quirk).
        SetCVar("GamePadStickAxisButtons", "0")
        for cvar, value in pairs(desired) do SetCVar(cvar, value) end
        SetGamePadCursorControl(false)
        SetGamePadFreeLook(true)
        self:StartBindings()
        self:StartTurning(deviceID)
    end)
    if not ok then
        self:StopBindings()
        self:RestoreBackup()
        self.db.enabled, self.active = false, false
        self:Print("Profil se nepodarilo zapnout: " .. tostring(err))
        return false
    end
    self.db.enabled, self.active, self.deviceName = true, true, name
    self:HideNativeBars()
    self.bindingReady = true
    for slot, key in ipairs(NS.GetKeys(self.db)) do
        if key ~= "NONE" then
            self.bindingReady = GetBindingAction(key, true):find("ClawControlAction1_" .. slot, 1, true) ~= nil
            break
        end
    end
    if not self.bindingReady then
        self:Print("Pozor: jina vstupni vrstva prekryva tlacitka. Posli vypis /claw status.")
    end
    if self.hud and self.db.hud then self.hud:Show() end
    self:Print("Zapnuto pro " .. name .. ". Upravy rozlozeni: /claw")
    return true
end

function CC:ApplySettings(values)
    if InCombatLockdown() then self:Print("Nastaveni uprav mimo boj."); return false end
    local candidate = CopyTable(self.db)
    for key, value in pairs(values) do candidate[key] = value end
    local valid, validationError = NS.ValidateProfile(candidate)
    if not valid then self:Print(validationError); return false end
    local active = self.active
    if active and not self:Disable() then return false end
    for key, value in pairs(values) do self.db[key] = type(value) == "table" and CopyTable(value) or value end
    self.db.m1, self.db.m2 = self.db.actionKeys[7], self.db.actionKeys[8]
    if self.hud then self.hud:SetScale(self.db.scale) end
    if self.hud then self:ApplyHUDLayout() end
    if self.launcher then self.launcher:SetShown(self.db.showLauncher) end
    if active then return self:Enable() end
    self:Print("Nastaveni ulozeno.")
    return true
end

function CC:Status()
    self:Print((self.active and "ZAPNUTO" or "VYPNUTO") .. " | WoW " .. tostring(select(4, GetBuildInfo())))
    self:Print("Slot 7=" .. self.db.m1 .. ", slot 8=" .. self.db.m2 .. " | let=" .. self.db.flight)
    self:Print("Otaceni: maximum=" .. tostring(self.db.turnSpeed) .. ", krivka=" .. tostring(self.db.turnGamma) ..
        ", prave ted=" .. tostring(GetCVar("GamePadCameraYawSpeed")))
    self:Print("A=" .. tostring(GetBindingAction("PAD1", true)) .. " | D-pad nahoru=" .. tostring(GetBindingAction("PADDUP", true)))
    self:Print("D-pad vlevo=" .. tostring(GetBindingAction("PADDLEFT", true)) ..
        " | vpravo=" .. tostring(GetBindingAction("PADDRIGHT", true)) ..
        " | dolu=" .. tostring(GetBindingAction("PADDDOWN", true)))
    self:Print("Akcni stisky=" .. tostring(self.actionPresses or 0) .. ", posledni=" .. tostring(self.lastAction or "zadny"))
    self:Print("Svisly let=" .. tostring(GetCVar("GamePadCameraPitchSpeed")) .. " | rezim=" .. self.db.flight)
    self:Print("Game menu: potvrzeni=" .. tostring(self.menuConfirmPresses or 0) ..
        ", viditelne=" .. tostring(GameMenuFrame and GameMenuFrame:IsShown() or false))
    for _, id in ipairs(C_GamePad.GetAllDeviceIDs()) do
        local raw = C_GamePad.GetDeviceRawState(id)
        if raw then self:Print(("Ovladac %d: %s (VID %04X / PID %04X)"):format(id, raw.name, raw.vendorID, raw.productID)) end
    end
end

SLASH_CLAWCONTROL1 = "/claw"
SlashCmdList.CLAWCONTROL = function(input)
    local cmd, arg = input:match("^(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "on" or cmd == "zapnout" then CC:Enable()
    elseif cmd == "off" or cmd == "vypnout" or cmd == "restore" then CC:Disable()
    elseif cmd == "status" then CC:Status()
    elseif cmd == "speed" then
        local speed = tonumber((arg:gsub(",", ".")))
        if not speed or speed < 0.05 or speed > 1.5 then
            CC:Print("Pouzij /claw speed 1.5; povoleny rozsah je 0.05-1.5.")
        else
            CC:ApplySettings({m1 = CC.db.m1, m2 = CC.db.m2, turnSpeed = speed})
        end
    elseif cmd == "cursor" then
        if CC.active then
            local cursor = not IsGamePadCursorControlEnabled()
            SetGamePadFreeLook(not cursor)
            SetGamePadCursorControl(cursor)
            CC:Print(cursor and "Kurzor zapnut. Accept klika pod kurzorem." or "Ovladani postavy zapnuto.")
        end
    elseif cmd == "device" and tonumber(arg) then
        if InCombatLockdown() or CC.active then
            CC:Print("Nejprve mimo boj profil vypni. Pak /claw device CISLO a /claw on.")
        else CC.db.deviceID = tonumber(arg); CC:Status() end
    elseif cmd == "test" then
        CC.testing = not CC.testing
        CC:EnableGamePadButton(false)
        CC:EnableKeyboard(CC.testing)
        CC:SetPropagateKeyboardInput(true)
        CC:Print(CC.testing and "Test vstupu zapnut: stiskni M1/M2 (mimo boj). /claw test jej vypne." or "Test vypnut.")
    else CC:ShowOptions() end
end

CC:SetScript("OnKeyDown", function(self, key)
    if self.testing then self:Print("Klavesa: " .. tostring(key)) end
end)
CC:EnableGamePadButton(false)
CC:EnableKeyboard(false)

CC:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        ClawControlDB = ClawControlDB or {}
        self.db = ClawControlDB
        for key, value in pairs(NS.Defaults) do
            if self.db[key] == nil then self.db[key] = value end
        end
        self.db.turnSpeed = NS.NormalizeTurnSpeed(self.db.turnSpeed)
        NS.UpgradeTurnSpeed023(self.db)
        NS.UpgradeRearKeys024(self.db)
        NS.UpgradeControls030(self.db)
        NS.UpgradeFlight043(self.db)
        NS.InitProfile(self.db)
        self:CreateUI()
    elseif event == "PLAYER_LOGIN" then
        if self.db.enabled then self:Enable()
        elseif self.db.backup then self:RestoreBackup() end
        self:Print("Verze 0.5.11 alpha. View: mapa | Menu: kruhovy volic | Nastaveni: ikona / L3")
    elseif event == "ADDON_LOADED" and name == "ConsolePort" and self.active then
        if not InCombatLockdown() then self:Disable()
        else self:Print("Konflikt s ConsolePortem; vypni jeden z addonu mimo boj.") end
    end
end)
CC:RegisterEvent("ADDON_LOADED")
CC:RegisterEvent("PLAYER_LOGIN")








