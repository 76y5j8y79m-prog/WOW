local _, NS = ...
local CC = NS.CC

NS.NativeBarNames = {
    "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
    "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
}

function CC:HideNativeBars()
    if InCombatLockdown() then self.nativeBarPending = true; return false end
    if not self.active or not self.db.hideNativeBars then return self:RestoreNativeBars() end
    if not self.nativeBarHider then
        self.nativeBarHider = CreateFrame("Frame", "ClawControlNativeBarHider", UIParent, "SecureHandlerBaseTemplate")
        self.nativeBarHider:Hide()
    end
    self.nativeBarParents = self.nativeBarParents or {}
    local allOK = true
    for _, name in ipairs(NS.NativeBarNames) do
        local bar = _G[name]
        if bar and bar:GetParent() ~= self.nativeBarHider then
            local previous = bar:GetParent()
            local ok, err = pcall(bar.SetParent, bar, self.nativeBarHider)
            if ok then
                self.nativeBarParents[bar] = {parent = previous}
            else
                allOK = false
                self:Print("Bar " .. name .. " se nepodarilo skryt: " .. tostring(err))
            end
        end
    end
    -- The bars retain their own shown state, events, anchors and action data.
    -- A hidden parent hides rendering and mouse input, including if Blizzard
    -- subsequently shows a child bar in combat. Our action proxies stay on UIParent.
    self.nativeBarPending = not allOK
    return allOK
end

function CC:RestoreNativeBars()
    if InCombatLockdown() then self.nativeBarPending = true; return false end
    local allOK = true
    for bar, saved in pairs(self.nativeBarParents or {}) do
        if bar:GetParent() == self.nativeBarHider then
            local ok, err = pcall(bar.SetParent, bar, saved.parent)
            if not ok then
                allOK = false
                self:Print("Puvodni bar se nepodarilo obnovit: " .. tostring(err))
            else self.nativeBarParents[bar] = nil end
        else
            -- Another UI owner has deliberately moved the frame; respect it.
            self.nativeBarParents[bar] = nil
        end
    end
    self.nativeBarPending = not allOK
    return allOK
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if not CC.db then return end
    if CC.active and CC.db.hideNativeBars then
        CC:HideNativeBars()
    elseif CC.nativeBarPending and event == "PLAYER_REGEN_ENABLED" then
        CC:RestoreNativeBars()
    end
end)
