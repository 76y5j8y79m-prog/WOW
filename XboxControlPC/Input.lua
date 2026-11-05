local _, NS = ...
local CC = NS.CC

function CC:StartTurning(deviceID)
    self.turnDeviceID, self.turnTimer, self.turnValue = deviceID, 0, 0
    self.cameraIndex = nil
    for index = 0, 15 do
        local name = C_GamePad.StickIndexToConfigName(index)
        if name == "Camera" then self.cameraIndex = index + 1; break end
    end
    self.previousButtons = {}
end

function CC:StopTurning()
    self.turnDeviceID, self.turnValue = nil, nil
end

function CC:UpdateTurning(dt)
    if not self.active and not self.testing then return end
    self.turnTimer = (self.turnTimer or 0) + dt
    if self.turnTimer < 0.02 then return end
    local elapsed = self.turnTimer
    self.turnTimer = 0
    local ok, state = pcall(C_GamePad.GetDeviceMappedState, self.turnDeviceID or C_GamePad.GetActiveDeviceID())
    if not ok then state = nil end
    if self.active then
        local pitch = NS.FlightPitchFactor(self.db, IsMounted(), IsGamePadCursorControlEnabled(), IsGamePadFreelookEnabled())
        if tonumber(GetCVar("GamePadCameraPitchSpeed")) ~= pitch then
            local applied, err = pcall(SetCVar, "GamePadCameraPitchSpeed", pitch)
            if not applied and not self.pitchError then
                self.pitchError = tostring(err)
                self:Print("Analogove rizeni letu bylo blokovano: " .. self.pitchError)
            end
        end
        local x = 0
        local stick = state and state.sticks and self.cameraIndex and state.sticks[self.cameraIndex]
        if stick and not (issecretvalue and issecretvalue(stick.x)) then x = tonumber(stick.x) or 0 end
        local target = NS.TurnFactor(x, self.db.turnSpeed, self.db.turnGamma)
        if IsGamePadCursorControlEnabled() or not IsGamePadFreelookEnabled() then target = 0 end
        -- Gentle acceleration; immediate slowdown. The target and final output
        -- are both capped, including after a sudden jump to full stick deflection.
        local previous = self.turnValue or 0
        local value = target
        if target > previous then value = previous + (target - previous) * math.min(1, elapsed / 0.06) end
        value = math.max(0, math.min(NS.NormalizeTurnSpeed(self.db.turnSpeed), value))
        local actual = tonumber(GetCVar("GamePadCameraYawSpeed")) or -1
        if math.abs(value - actual) > 0.001 then
            local applied, err = pcall(SetCVar, "GamePadCameraYawSpeed", value)
            if not applied and not self.turnError then
                self.turnError = tostring(err)
                self:Print("Nastaveni krivky bylo blokovano: " .. self.turnError)
            end
        end
        self.turnValue = value
    end
    -- Diagnostics observe button state and never take ownership of gamepad input.
    if self.testing and state and state.buttons then
        self.previousButtons = self.previousButtons or {}
        for index, pressed in ipairs(state.buttons) do
            if pressed and not self.previousButtons[index] then
                self:Print("Gamepad: " .. tostring(C_GamePad.ButtonIndexToBinding(index - 1)))
            end
            self.previousButtons[index] = pressed
        end
    end
end

CC:SetScript("OnUpdate", function(self, dt) self:UpdateTurning(dt) end)
