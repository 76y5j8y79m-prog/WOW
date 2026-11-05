local _, NS = ...

function NS.CreateActions(owner)
    if owner.actions then return end
    owner.actions = {}
    for layer = 1, 4 do
        owner.actions[layer] = {}
        for slot = 1, 8 do
            local b = CreateFrame("Button", "ClawControlAction" .. layer .. "_" .. slot,
                UIParent, "SecureActionButtonTemplate")
            b:SetSize(1, 1)
            b:SetPoint("CENTER")
            b:RegisterForClicks("AnyDown", "AnyUp")
            b:SetAttribute("type", "action")
            b:SetAttribute("useOnKeyDown", true)
            b:SetAttribute("pressAndHoldAction", true)
            b:SetAttribute("typerelease", "actionrelease")
            if layer == 1 then
                b:SetID(slot)
                b:SetAttribute("actionpage", 1)
            else
                b:SetID(0)
                b:SetAttribute("action", NS.Offsets[layer] + slot)
            end
            owner.handler:SetFrameRef("action" .. layer .. "_" .. slot, b)
            b:SetScript("PostClick", function(_, _, down)
                if down then
                    owner.actionPresses = (owner.actionPresses or 0) + 1
                    owner.lastAction = "BAR " .. layer .. ", slot " .. slot
                    if owner.testing then owner:Print("Akcni vstup: " .. owner.lastAction) end
                end
            end)
            b:Hide()
            owner.actions[layer][slot] = b
        end
    end
end

function NS.ConfigureActions(owner)
    for layer = 1, 4 do
        for slot, b in ipairs(owner.actions[layer]) do
            local bar = slot >= 7 and 1 or owner.db.layerBars[layer]
            if bar == 1 then
                b:SetID(slot)
                b:SetAttribute("actionpage", 1)
            else
                b:SetID(0)
                b:SetAttribute("action", NS.BarOffsets[bar] + slot)
            end
        end
    end
end

-- Set an actual action page in protected code, including vehicles/forms.
NS.SecurePage = [[
    local page
    if HasVehicleActionBar and HasVehicleActionBar() then page = GetVehicleBarIndex()
    elseif HasOverrideActionBar and HasOverrideActionBar() then page = GetOverrideBarIndex()
    elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then page = GetTempShapeshiftBarIndex()
    elseif GetBonusBarOffset and GetBonusBarOffset() > 0 then page = GetBonusBarOffset() + 6
    else page = GetActionBarPage() end
    for layer = 1, 4 do
        for slot = 1, 8 do
            local button = self:GetFrameRef("action" .. layer .. "_" .. slot)
            if button:GetID() > 0 then button:SetAttribute("actionpage", page or 1) end
        end
    end
]]

NS.PageCondition = "[vehicleui] 1; [overridebar] 2; [possessbar] 3; [shapeshift] 4; " ..
    "[bonusbar:1] 11; [bonusbar:2] 12; [bonusbar:3] 13; [bonusbar:4] 14; [bonusbar:5] 15; " ..
    "[bar:2] 22; [bar:3] 23; [bar:4] 24; [bar:5] 25; [bar:6] 26; 0"

-- Establish the entire base map directly outside combat, rather than relying
-- on state-driver evaluation to initialize every key. The secure handler only
-- adds dynamic routing while these stable native overrides remain present.
function NS.InstallBaseBindings(owner)
    local frame = owner.bindingOwner
    ClearOverrideBindings(frame)
    for layer, prefix in ipairs(NS.Prefixes) do
        for slot, key in ipairs(NS.GetKeys(owner.db)) do
            if key ~= "NONE" then
                SetOverrideBindingClick(frame, true, prefix .. key,
                    owner.actions[slot >= 7 and 1 or layer][slot]:GetName(), "LeftButton")
            end
        end
        for _, key in ipairs(NS.ControlKeys) do
            local command = owner.db.controls[key]
            if command == "ESCAPE" then
                -- Dispatch Blizzard's native binding. Calling ToggleGameMenu
                -- from an addon OnClick taints protected ESC handlers.
                SetOverrideBinding(frame, true, prefix .. key, "TOGGLEGAMEMENU")
            elseif command == "OPENSETTINGS" then
                SetOverrideBindingClick(frame, true, prefix .. key, "ClawControlLauncher", "LeftButton")
            elseif command == "RADIAL" then
                SetOverrideBindingClick(frame, true, prefix .. key, "ClawControlRadialToggle", "LeftButton")
            elseif command == "NONE" then
                SetOverrideBindingClick(frame, true, prefix .. key, "ClawControlNoop", "LeftButton")
            elseif command ~= "CURSOR" then
                SetOverrideBinding(frame, true, prefix .. key, command)
            end
        end
    end
end
