local _, NS = ...

NS.Defaults = {
    enabled = false,
    m1 = "F9",
    m2 = "F10",
    deadzone = 0.20,
    turnSpeed = 1.5,
    turnGamma = 2,
    flight = "skyriding",
    flightPitchSpeed = 0.75,
    accept = "interact",
    hud = true,
    scale = 1,
}

-- GamePadCameraYawSpeed is a small speed factor, not degrees per second.
-- A hard cap also applies to old saved preferences (including 1 and 3).
function NS.NormalizeTurnSpeed(value)
    local speed = tonumber(value)
    if not speed or speed ~= speed or speed < 0.05 or speed > 1.5 then
        return NS.Defaults.turnSpeed
    end
    return speed
end

function NS.UpgradeTurnSpeed023(db)
    if db.turnSpeedUpgrade023 then return end
    local previous = tonumber(db.turnSpeed)
    if previous == 0.25 or previous == 0.375 then db.turnSpeed = 0.5 end
    db.turnSpeedUpgrade023 = true
end

function NS.UpgradeRearKeys024(db)
    -- Keyboard rear inputs are independent of the front View/Menu buttons.
    db.rearKeysUpgrade024 = true
end

function NS.UpgradeControls030(db)
    if db.controlsUpgrade030 then return end
    db.turnSpeed, db.turnGamma = 1.5, 2
    if db.accept == "cursor" then db.accept = "interact" end
    db.controlsUpgrade030 = true
end

function NS.UpgradeFlight043(db)
    if db.nativeFlightUpgrade043 then return end
    db.flight = "skyriding"
    db.nativeFlightUpgrade043 = true
end

function NS.FlightPitchFactor(db, mounted, cursor, freelook)
    if cursor or not freelook then return 0 end
    if mounted then
        if db.flight ~= "skyriding" then return 0 end
    elseif not db.lookOnFoot then return 0 end
    return db.flightPitchSpeed or 0.75
end

-- Mapped Camera.x already contains the native stick deadzone. Native yaw
-- multiplies x by this factor, producing a progressive response ~abs(x)^gamma.
function NS.TurnFactor(x, maximum, gamma)
    local magnitude = math.min(1, math.abs(x or 0))
    local cap = NS.NormalizeTurnSpeed(maximum)
    local exponent = math.max(1, math.min(3, tonumber(gamma) or 2.2))
    return cap * magnitude ^ (exponent - 1)
end

NS.Keys = {"PAD1", "PAD2", "PAD3", "PAD4", "PADRSHOULDER", "PADLSHOULDER"}
NS.Labels = {"A", "B", "X", "Y", "RB", "LB", "M1", "M2"}
-- Blizzard's visible action bars 1, 2 (bottom left), 3 (bottom right), 4 (right).
-- These are NOT the hidden pages 1..4 of the main action bar.
NS.Bars = {"ACTIONBUTTON", "MULTIACTIONBAR1BUTTON", "MULTIACTIONBAR2BUTTON", "MULTIACTIONBAR3BUTTON"}
NS.Offsets = {0, 60, 48, 24}
NS.Prefixes = {"", "SHIFT-", "CTRL-", "CTRL-SHIFT-"}
NS.AxisButtonKeys = {"PADLSTICKUP", "PADLSTICKDOWN", "PADLSTICKLEFT", "PADLSTICKRIGHT",
    "PADRSTICKUP", "PADRSTICKDOWN", "PADRSTICKLEFT", "PADRSTICKRIGHT"}
NS.LayerCondition = "[mod:ctrl,mod:shift] 4; [mod:ctrl] 3; [mod:shift] 2; 1"

function NS.GetLayer()
    return 1 + (IsShiftKeyDown() and 1 or 0) + (IsControlKeyDown() and 2 or 0)
end

function NS.GetKeys(db)
    if db.actionKeys then return CopyTable(db.actionKeys) end
    local keys = {}
    for i, key in ipairs(NS.Keys) do keys[i] = key end
    keys[7], keys[8] = db.m1, db.m2
    return keys
end

function NS.ValidateRearKeys(m1, m2)
    -- View/Menu are free in this layout and can stand in for the rear buttons.
    local function valid(key)
        if type(key) ~= "string" then return false end
        local n = tonumber(key:match("^F(%d+)$"))
        return key == "PADBACK" or key == "PADFORWARD"
            or (n and n >= 1 and n <= 12) or key:match("^PADPADDLE[1-4]$")
    end
    return m1 ~= m2 and valid(m1) and valid(m2)
end

function NS.MakeDeviceConfig(original, id, db)
    local config = original and CopyTable(original) or {}
    config.configID = CopyTable(id)
    config.name = config.name or "Claw Control"
    config.rawAxisMappings = config.rawAxisMappings or {}
    config.rawButtonMappings = config.rawButtonMappings or {}
    config.axisConfigs = config.axisConfigs or {}
    config.stickConfigs = config.stickConfigs or {}

    local function patch(list, field, key, values)
        local entry
        for _, item in ipairs(list) do
            if item[field] == key then entry = item; break end
        end
        if not entry then entry = {[field] = key}; table.insert(list, entry) end
        for k, v in pairs(values) do entry[k] = v end
    end

    -- Native analog movement stays analog, rather than Lua polling movement calls.
    local move = db.movementStick == "left" and "L" or "R"
    local turn = move == "L" and "R" or "L"
    patch(config.stickConfigs, "stick", "Movement", {
        axisX = move .. "StickX", axisY = move .. "StickY", deadzone = db.deadzone,
    })
    -- Camera yaw is coupled to facing. Native pitch handles on-foot looking
    -- and Skyriding; steady flight uses directional buttons while mounted.
    patch(config.stickConfigs, "stick", "Camera", {
        axisX = turn .. "StickX", axisY = turn .. "StickY", deadzone = db.deadzone,
    })
    patch(config.stickConfigs, "stick", "Look", {deadzone = 1})
    -- Config names omit the PAD prefix. Use engine conversion to avoid guessing.
    local function buttonName(binding)
        local index = C_GamePad.ButtonBindingToIndex(binding)
        assert(index ~= nil, "Klient nezna vstup " .. binding)
        return assert(C_GamePad.ButtonIndexToConfigName(index), "Chybi nazev osoveho tlacitka")
    end
    patch(config.axisConfigs, "axis", turn .. "StickX", {scale = db.invertTurn and -1 or 1})
    patch(config.axisConfigs, "axis", turn .. "StickY", {
        scale = db.flight == "skyriding" and db.invertFlight and -1 or 1,
        buttonThreshold = math.max(0.35, db.deadzone),
        buttonPos = buttonName("PAD" .. turn .. "STICKUP"),
        buttonNeg = buttonName("PAD" .. turn .. "STICKDOWN"),
    })
    return config
end

-- Executed only by Blizzard's restricted secure handler. Layer changes and
-- mounted changes therefore work during combat without insecure SetBinding calls.
NS.SecureRefresh = [[
    self:ClearBindings()
    if not self:GetAttribute("enabled") then return end
    if self:GetAttribute("radial-open") then return end
    local layer = tonumber(self:GetAttribute("state-layer")) or 1
    local mounted = tonumber(self:GetAttribute("state-mounted")) == 1
    for prefixLayer = 1, 4 do
        local prefix = self:GetAttribute("prefix" .. prefixLayer)
        for slot = 1, 8 do
            local key = self:GetAttribute("key" .. slot)
            -- PAD inputs use immediate native modified bindings. For a keyboard
            -- rear key, also route an unmodified event through the secure layer:
            -- some drivers emit keyboard events without gamepad modifiers.
            local effectiveLayer = prefixLayer
            if prefix == "" and key:sub(1, 3) ~= "PAD" then effectiveLayer = layer end
            if slot >= 7 then effectiveLayer = 1 end
            if key ~= "NONE" then
                self:SetBindingClick(true, prefix .. key, "ClawControlAction" .. effectiveLayer .. "_" .. slot, "LeftButton")
            end
        end
        for controlIndex = 1, 8 do
            local key = self:GetAttribute("control-key" .. controlIndex)
            local command = self:GetAttribute("control-" .. key)
            if command == "ESCAPE" then
                self:SetBinding(true, prefix .. key, "TOGGLEGAMEMENU")
            elseif command == "OPENSETTINGS" then
                self:SetBindingClick(true, prefix .. key, "ClawControlLauncher", "LeftButton")
            elseif command == "RADIAL" then
                self:SetBindingClick(true, prefix .. key, "ClawControlRadialToggle", "LeftButton")
            elseif command == "NONE" then
                self:SetBindingClick(true, prefix .. key, "ClawControlNoop", "LeftButton")
            elseif command ~= "CURSOR" then
                self:SetBinding(true, prefix .. key, command)
            end
        end
        local up = mounted and self:GetAttribute("flight-up") or "CLICK ClawControlNoop:LeftButton"
        local down = mounted and self:GetAttribute("flight-down") or "CLICK ClawControlNoop:LeftButton"
        local upkey, downkey = self:GetAttribute("flight-key-up"), self:GetAttribute("flight-key-down")
        self:SetBinding(true, prefix .. upkey, up)
        self:SetBinding(true, prefix .. downkey, down)
        -- Reserve the unused stick click and prevent an old movement-axis binding
        -- from also firing on top of the native analog mapping.
        for axisIndex = 1, 8 do
            local key = self:GetAttribute("axis-key" .. axisIndex)
            if key ~= upkey and key ~= downkey then
                self:SetBinding(true, prefix .. key, "CLICK ClawControlNoop:LeftButton")
            end
        end
    end
]]
