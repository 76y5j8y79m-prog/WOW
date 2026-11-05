local _, NS = ...

NS.InputOptions = {
    {"NONE", "Neprirazeno"},
    {"PAD1", "A"}, {"PAD2", "B"}, {"PAD3", "X"}, {"PAD4", "Y"},
    {"PADRSHOULDER", "RB"}, {"PADLSHOULDER", "LB"},
}
NS.CommandOptions = {
    {"NONE", "Bez funkce"}, {"OPENSETTINGS", "Nastaveni Xbox Control PC"}, {"RADIAL", "Kruhovy volic"}, {"TARGETNEARESTENEMY", "Dalsi nepritel (Tab)"},
    {"TARGETPREVIOUSENEMY", "Predchozi nepritel"}, {"TARGETNEARESTFRIEND", "Dalsi pratelsky cil"},
    {"INTERACTTARGET", "Interakce s NPC / predmetem"}, {"ESCAPE", "Escape / menu hry"},
    {"TOGGLEBACKPACK", "Hlavni batoh"}, {"OPENALLBAGS", "Vsechny tasky"},
    {"TOGGLEWORLDMAP", "Mapa sveta"}, {"TOGGLECHARACTER0", "Postava"},
    {"TOGGLEQUESTLOG", "Denik ukolu"}, {"JUMP", "Skok"},
    {"TOGGLEAUTORUN", "Automaticky beh"}, {"TOGGLERUN", "Chuze / beh"},
    {"TOGGLESHEATH", "Vytasit / schovat zbran"}, {"CURSOR", "Levy klik pod kurzorem"},
}
NS.ControlKeys = {"PADBACK", "PADFORWARD", "PADDUP", "PADDLEFT", "PADDRIGHT", "PADDDOWN", "PADLSTICK", "PADRSTICK"}
NS.ControlLabels = {"Predni leve View / Back", "Predni prave Menu / Start", "D-pad nahoru", "D-pad vlevo", "D-pad vpravo", "D-pad dolu", "Stisk leve packy", "Stisk prave packy"}
NS.BarOffsets = {0, 60, 48, 24, 36, 144, 156, 168}
NS.BarOptions = {}
for i = 1, 8 do NS.BarOptions[i] = {i, "Akcni bar " .. i} end
NS.GroupScaleOptions = {{0, "0.00 - skryty"}}
for i = 1, 20 do
    NS.GroupScaleOptions[#NS.GroupScaleOptions+1] = {i/20, string.format("%.2f (%d %%)", i/20, i*5)}
end

function NS.OptionLabel(options, value)
    for _, option in ipairs(options) do if option[1] == value then return option[2] end end
    return tostring(value)
end

function NS.InitProfile(db)
    db.actionKeys = db.actionKeys or {"PAD1", "PAD2", "PAD3", "PAD4", "PADRSHOULDER", "PADLSHOULDER"}
    db.layerBars = db.layerBars or {1, 2, 3, 4}
    db.controls = db.controls or {
        PADDUP = "TARGETNEARESTENEMY", PADDLEFT = db.accept == "cursor" and "CURSOR" or "INTERACTTARGET",
        PADDRIGHT = "ESCAPE", PADDDOWN = "TOGGLEBACKPACK", PADLSTICK = "OPENSETTINGS", PADRSTICK = "JUMP",
    }
    db.movementStick = db.movementStick or "right"
    db.controls.PADBACK = db.controls.PADBACK or "TOGGLEWORLDMAP"
    db.controls.PADFORWARD = db.controls.PADFORWARD or "RADIAL"
    db.hudLayout = db.hudLayout or "clusters"
    if not db.frontButtonsUpgrade050 then
        for slot, key in ipairs(db.actionKeys) do
            if key == "PADBACK" or key == "PADFORWARD" then db.actionKeys[slot] = "NONE" end
        end
        db.frontButtonsUpgrade050 = true
    end
    for _, key in ipairs({"modifierSwap", "invertTurn", "invertFlight"}) do
        if db[key] == nil then db[key] = false end
    end
    if db.cooldownNumbers == nil then db.cooldownNumbers = true end
    if db.showLauncher == nil then db.showLauncher = true end
    if db.flightPitchSpeed == nil then db.flightPitchSpeed = 0.75 end
    if db.lookOnFoot == nil then db.lookOnFoot = true end
    if db.hudUnlocked == nil then db.hudUnlocked = false end
    db.hudGroups = db.hudGroups or {}
    db.groupPositions = db.groupPositions or {}
    for layer = 1, 4 do
        db.hudGroups[layer] = db.hudGroups[layer] or {visible=true, scale=1}
        local value=db.hudGroups[layer].scale
        if type(value)=="number" and value>1 then db.hudGroups[layer].scale=1 end
    end
    if db.hideNativeBars == nil then
        db.hideNativeBars, db.hud, db.hudLayout = true, true, "clusters"
    end
    if not db.launcherUpgrade042 then
        if db.controls.PADLSTICK == "NONE" then db.controls.PADLSTICK = "OPENSETTINGS" end
        db.launcherUpgrade042 = true
    end
end

function NS.NewDefaultProfile()
    local db = CopyTable(NS.Defaults)
    db.enabled = nil
    NS.InitProfile(db)
    return db
end

function NS.ValidateProfile(db)
    local function allowed(options, value)
        for _, option in ipairs(options) do if option[1] == value then return true end end
        return false
    end
    local used = {}
    for slot = 1, 6 do
        local key = db.actionKeys and db.actionKeys[slot]
        if not allowed(NS.InputOptions, key) then return false, "Vyber platny vstup pro slot " .. slot .. "." end
        if key ~= "NONE" then
            if used[key] then return false, "Stejny vstup je ve slotech " .. used[key] .. " a " .. slot .. "." end
            used[key] = slot
        end
    end
    local cursors = 0
    for index, key in ipairs(NS.ControlKeys) do
        local command = db.controls and db.controls[key]
        if not allowed(NS.CommandOptions, command) then return false, "Vyber funkci: " .. NS.ControlLabels[index] .. "." end
        if command == "CURSOR" then cursors = cursors + 1 end
    end
    if cursors > 1 then return false, "Klik pod kurzorem muze mit jen jeden vstup." end
    for layer = 1, 4 do
        if not allowed(NS.BarOptions, db.layerBars and db.layerBars[layer]) then
            return false, "Vyber akcni bar pro vrstvu " .. layer .. "."
        end
    end
    local numericLabels = {turnSpeed="Maximum otaceni", turnGamma="Progrese", deadzone="Mrtva zona", scale="Velikost prehledu", flightPitchSpeed="Citlivost letu"}
    for key, limits in pairs({turnSpeed={0.05,1.5}, turnGamma={1,3}, deadzone={0.05,0.6}, scale={0.35,1.8}, flightPitchSpeed={0.1,1.5}}) do
        local value = db[key]
        if type(value) ~= "number" or value ~= value or value < limits[1] or value > limits[2] then
            return false, numericLabels[key] .. ": zadej cislo " .. limits[1] .. " az " .. limits[2] .. "."
        end
    end
    if db.movementStick ~= "left" and db.movementStick ~= "right" then return false, "Vyber pohybovou packu." end
    if db.flight ~= "steady" and db.flight ~= "skyriding" then return false, "Vyber rezim letu." end
    if db.hudLayout ~= "clusters" and db.hudLayout ~= "row" then return false, "Vyber rozlozeni schopnosti." end
    if db.hideNativeBars and not db.hud then return false, "Pri skrytych barech WoW zapni prehled schopnosti." end
    local visible = 0
    for layer = 1, 4 do
        local group = db.hudGroups and db.hudGroups[layer]
        if type(group) ~= "table" or type(group.visible) ~= "boolean" or type(group.scale) ~= "number"
            or group.scale ~= group.scale or group.scale < 0 or group.scale > 1 then
            return false, "Neplatne nastaveni krize " .. layer .. "."
        end
        if group.visible and group.scale > 0 then visible = visible + 1 end
    end
    if db.hideNativeBars and db.hudLayout == "clusters" and visible == 0 then
        return false, "Pri skrytych barech WoW ponech alespon jeden kriz viditelny."
    end
    return true
end

function NS.GetCursorKey(db)
    for _, key in ipairs(NS.ControlKeys) do if db.controls[key] == "CURSOR" then return key end end
    return "none"
end

function NS.HasInteraction(db)
    for _, key in ipairs(NS.ControlKeys) do if db.controls[key] == "INTERACTTARGET" then return true end end
    return false
end
