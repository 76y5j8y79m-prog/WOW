local _, NS = ...
local CC = NS.CC

local function text(parent, value, x, y, width, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    if width then label:SetWidth(width); label:SetJustifyH("LEFT") end
    label:SetText(value)
    return label
end

local function button(parent, label, x, y, width, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 28)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(label)
    b:SetScript("OnClick", callback)
    return b
end

local function input(parent, label, x, y, width)
    text(parent, label, x, y, 250)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width or 110, 25)
    box:SetPoint("TOPLEFT", x + 270, y + 6)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return box
end

-- Appended to UI.lua; all edits are made in a draft until saved.
function CC:CreateUI()
    self:CreateHUD()
    local f = CreateFrame("Frame", "ClawControlOptions", UIParent, "BasicFrameTemplateWithInset")
    self.options = f
    f:SetSize(760, 655)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f.TitleText:SetText("Claw Control | Editor ovladani | 0.5.11 alpha")
    f:SetClampedToScreen(true)
    f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    table.insert(UISpecialFrames, "ClawControlOptions")
    f.refreshers, f.collectors, f.pages = {}, {}, {}
    local currentPage = 1
    local status = text(f, "Zmeny se projevi az po ulozeni. Ukladani je mozne mimo boj.", 24, -530, 710)

    local popup = CreateFrame("Frame", "ClawControlChoice", f, "BasicFrameTemplateWithInset")
    popup:SetSize(340, 420); popup:SetPoint("CENTER", f, "CENTER", 90, 0)
    popup:SetFrameStrata("TOOLTIP"); popup:SetClampedToScreen(true)
    popup.TitleText:SetText("Vyber hodnotu")
    local scroll = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -34); scroll:SetPoint("BOTTOMRIGHT", -32, 12)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(290, 1); scroll:SetScrollChild(content)
    popup.rows = {}; popup:Hide()
    table.insert(UISpecialFrames, "ClawControlChoice")

    local function refresh(reloadNumbers)
        for _, update in ipairs(f.refreshers) do update(reloadNumbers) end
    end
    local function choose(owner, options, value, setter)
        for _, row in ipairs(popup.rows) do row:Hide() end
        content:SetHeight(math.max(1, #options * 32)); scroll:SetVerticalScroll(0)
        for i, option in ipairs(options) do
            local row = popup.rows[i]
            if not row then row = button(content, "", 0, -(i - 1) * 32, 288, function() end); popup.rows[i] = row end
            row:SetText((value == option[1] and "> " or "") .. option[2])
            local selected = option[1]
            row:SetScript("OnClick", function() setter(selected); refresh(false); popup:Hide(); status:SetText("Zmeneno. Pouzij Ulozit a pouzit.") end)
            row:Show()
        end
        popup:Show()
    end
    local function selectField(parent, label, x, y, width, options, getter, setter)
        text(parent, label, x, y, width)
        local b = button(parent, "", x, y - 19, width, function()
            choose(parent, options, getter(), setter)
        end)
        table.insert(f.refreshers, function() b:SetText(NS.OptionLabel(options, getter()) .. "  v") end)
        return b
    end
    local function numeric(parent, label, y, key)
        local b = input(parent, label, 24, y, 120)
        table.insert(f.refreshers, function(reloadNumbers)
            if reloadNumbers ~= false then b:SetText(tostring(f.draft[key])) end
        end)
        table.insert(f.collectors, function() f.draft[key] = tonumber((b:GetText():gsub(",", "."))) or false end)
        return b
    end
    local function check(parent, label, y, key)
        local b = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        b:SetPoint("TOPLEFT", 20, y)
        text(parent, label, 55, y - 8, 640)
        b:SetScript("OnClick", function() f.draft[key] = b:GetChecked() and true or false end)
        table.insert(f.refreshers, function() b:SetChecked(f.draft[key]) end)
        return b
    end
    local tabs = {"Schopnosti", "D-pad a stisky", "Pohyb a otaceni", "Zobrazeni a let", "Krizove rozlozeni"}
    local function showPage(index)
        currentPage = index; popup:Hide()
        for i, page in ipairs(f.pages) do page:SetShown(i == index) end
    end
    for i, title in ipairs(tabs) do
        local index = i
        button(f, title, 20 + (i - 1) * 145, -43, 140, function() showPage(index) end)
        local page = CreateFrame("Frame", nil, f)
        page:SetPoint("TOPLEFT", 0, -90); page:SetSize(750, 430)
        f.pages[i] = page
    end

    local actions = f.pages[1]
    text(actions, "Ktery vstup spousti jednotlive sloty", 24, -2, 330, "GameFontNormal")
    for slot = 1, 8 do
        local index = slot
        selectField(actions, "Slot " .. slot .. (slot >= 7 and " pouze BAR 1" or " na vsech vrstvach"), 24, -28 - (slot - 1) * 47, 300,
            NS.InputOptions, function() return f.draft.actionKeys[index] end,
            function(value) f.draft.actionKeys[index] = value end)
    end
    text(actions, "Ktery herni bar pouziva vrstva", 389, -2, 320, "GameFontNormal")
    for layer = 1, 4 do
        local index = layer
        selectField(actions, "Vrstva " .. layer, 389, -28 - (layer - 1) * 70, 320, NS.BarOptions,
            function() return f.draft.layerBars[index] end, function(value) f.draft.layerBars[index] = value end)
    end
    text(actions, "Vrstva 1: bez spouste\nVrstva 2: RT (standardne)\nVrstva 3: LT (standardne)\nVrstva 4: obe spouste\n\nM1/M2 nastav na skutecne zadni vstupy.\nView/Menu jsou mapa a kruhovy volic.", 389, -320, 320)

    local controls = f.pages[2]
    for index, key in ipairs(NS.ControlKeys) do
        local control = key
        local x = index <= 4 and 24 or 389
        local row = (index - 1) % 4
        selectField(controls, NS.ControlLabels[index], x, -8 - row * 72, 320, NS.CommandOptions,
            function() return f.draft.controls[control] end, function(value) f.draft.controls[control] = value end)
    end
    check(controls, "Prohodit RT a LT pro vrstvy 2 a 3", -310, "modifierSwap")
    text(controls, "Prirazene funkce D-padu a stisku pacek jsou stejne ve vsech vrstvach.\nKlik pod kurzorem muze mit jen jeden ovladaci prvek.\nInterakce vyzaduje NPC nebo predmet v dosahu; cileni dostupny cil.", 24, -363, 685)

    local movement = f.pages[3]
    selectField(movement, "Packa pro pohyb a ukroky (druha otaci a ovlada let)", 24, -6, 685,
        {{"right", "Prava packa: pohyb | leva: otaceni a let"}, {"left", "Leva packa: pohyb | prava: otaceni a let"}},
        function() return f.draft.movementStick end, function(value) f.draft.movementStick = value end)
    numeric(movement, "Mrtva zona pacek (0.05-0.60)", -95, "deadzone")
    numeric(movement, "Maximum otaceni (0.05-1.5)", -142, "turnSpeed")
    numeric(movement, "Progrese / exponent (1-3)", -189, "turnGamma")
    numeric(movement, "Citlivost svisleho pohledu / letu (0.1-1.5)", -236, "flightPitchSpeed")
    check(movement, "Obratit smer otaceni", -280, "invertTurn")
    check(movement, "Obratit smer nahoru/dolu pri letu", -321, "invertFlight")
    text(movement, "Exponent 1 = linearni, 2 = jemny stred, 3 = jeste jemnejsi stred.\nVychozi maximum 1.5 / exponent 2: polovicni vychyleni = 0.375.\nSvisly pohled pri chuzi zapnes na zalozce Zobrazeni a let.\nDesetinna cisla mohou mit tecku i carku.", 24, -365, 680)

    local display = f.pages[4]
    check(display, "Zobrazit prehled schopnosti", -8, "hud")
    check(display, "Skryt puvodni akcni bary WoW (1-8)", -48, "hideNativeBars")
    check(display, "Zobrazit cisla cooldownu (kruh zustava)", -88, "cooldownNumbers")
    numeric(display, "Velikost prehledu (0.35-1.8)", -146, "scale")
    selectField(display, "Rozlozeni schopnosti", 427, -126, 280,
        {{"clusters", "Skupiny ovladace (4 vrstvy)"}, {"row", "Puvodni jeden radek"}},
        function() return f.draft.hudLayout end, function(value) f.draft.hudLayout=value end)
    selectField(display, "Zpusob letu", 24, -210, 685,
        {{"steady", "Bezne letani: stoupat / klesat"}, {"skyriding", "Skyriding: naklon nahoru / dolu"}},
        function() return f.draft.flight end, function(value) f.draft.flight = value end)
    check(display, "Pohled nahoru/dolu i pri chuzi", -263, "lookOnFoot")
    check(display, "Zobrazit ikonu pro otevreni nastaveni", -299, "showLauncher")
    button(display, "Vratit prehled na puvodni misto", 24, -341, 340, function()
        self.db.position = nil; self.hud:ClearAllPoints(); self.hud:SetPoint("BOTTOM", 0, 145)
        status:SetText("Pozice prehledu obnovena.")
    end)
    text(display, "Pro presouvani kouzel docasne vypni skryvani puvodnich baru.", 24, -389, 680)

    local arrangement=f.pages[5]
    text(arrangement,"Pro zobrazeni tlacitek Presun zapni Povolit presouvani krizu.\nPresun vse posouva cely prehled. Zmeny potvrd ulozenim.",24,-6,690)
    for layer=1,4 do
        local index=layer
        local y=-65-(layer-1)*72
        local visible=CreateFrame("CheckButton",nil,arrangement,"UICheckButtonTemplate")
        visible:SetPoint("TOPLEFT",20,y)
        text(arrangement,"Zobrazit kriz "..layer,55,y-8,240)
        visible:SetScript("OnClick",function() f.draft.hudGroups[index].visible=visible:GetChecked() and true or false end)
        table.insert(f.refreshers,function() visible:SetChecked(f.draft.hudGroups[index].visible) end)
        selectField(arrangement,"Velikost krize "..layer.." (0.0-1.0)",365,y,340,
            NS.GroupScaleOptions,
            function() return f.draft.hudGroups[index].scale end,
            function(value) f.draft.hudGroups[index].scale=value end)
    end
    check(arrangement,"Povolit presouvani krizu (zobrazit tlacitka Presun)",-329,"hudUnlocked")
    button(arrangement,"Obnovit vychozi pozice krizu",24,-370,340,function()
        f.draft.groupPositions={}
        status:SetText("Vychozi pozice pripraveny. Pouzij Ulozit a pouzit.")
    end)
    text(arrangement,"0.0 = skryty, 0.5 = polovicni, 1.0 = plny. Celkovy scale: Zobrazeni a let.",24,-407,690)

    local function save(activate)
        if InCombatLockdown() then status:SetText("Ukladani je mozne az po skonceni boje."); return end
        for _, collect in ipairs(f.collectors) do collect() end
        local valid, err = NS.ValidateProfile(f.draft)
        if not valid then status:SetText(err); return end
        if not self:ApplySettings(f.draft) then status:SetText("Nastaveni se nepodarilo pouzit; viz chat."); return end
        if activate and not self:Enable() then status:SetText("Profil se nepodarilo zapnout; viz chat."); return end
        status:SetText("Ulozeno. " .. (self.active and "Profil je zapnuty." or "Profil je vypnuty."))
        refresh()
    end
    button(f, "Ulozit a pouzit", 24, -568, 170, function() save(false) end)
    button(f, "Ulozit a zapnout", 204, -568, 170, function() save(true) end)
    button(f, "Vypnout profil", 384, -568, 170, function() self:Disable(); status:SetText("Profil vypnut; puvodni nastaveni obnoveno.") end)
    button(f, "Vychozi layout", 564, -568, 170, function()
        f.draft = NS.NewDefaultProfile(); refresh(); popup:Hide()
        status:SetText("Vychozi layout pripraven. Pro potvrzeni pouzij Ulozit a pouzit.")
    end)
    text(f, "/claw: editor | /claw status: stav | /claw test: vstupy | Zavreni zahodi neulozene zmeny.", 24, -614, 710, "GameFontHighlightSmall")
    f:SetScript("OnShow", function()
        f.draft = NS.NewDefaultProfile()
        for key in pairs(f.draft) do if self.db[key] ~= nil then f.draft[key] = CopyTable({self.db[key]})[1] end end
        refresh(); showPage(currentPage)
        status:SetText("Zmeny se projevi az po ulozeni. Ukladani je mozne mimo boj.")
    end)
    f:SetScript("OnHide", function() popup:Hide() end)
    f:Hide()
    self:CreateLauncher()
    self:CreateRadial()
end

function CC:CreateLauncher()
    local launcher = CreateFrame("Button", "ClawControlLauncher", UIParent, "BackdropTemplate")
    self.launcher = launcher
    launcher:SetSize(44, 44)
    launcher:SetFrameStrata("MEDIUM")
    launcher:SetClampedToScreen(true)
    launcher:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=12})
    launcher:SetBackdropColor(0.025, 0.04, 0.06, 0.95)
    launcher.icon = launcher:CreateTexture(nil, "ARTWORK")
    launcher.icon:SetPoint("TOPLEFT", 5, -5); launcher.icon:SetPoint("BOTTOMRIGHT", -5, 5)
    launcher.icon:SetTexture("Interface/Icons/INV_Misc_Gear_01")
    launcher:EnableMouse(true); launcher:SetMovable(true); launcher:RegisterForDrag("LeftButton")
    launcher:RegisterForClicks("AnyUp")
    launcher:SetScript("OnMouseDown", function(self) self.dragged = false end)
    launcher:SetScript("OnClick", function(self)
        if not self.dragged then CC:ShowOptions() end
    end)
    launcher:SetScript("OnDragStart", function(self)
        self.dragged = true; self:StartMoving()
    end)
    launcher:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        CC.db.launcherPosition = {point, relativePoint, x, y}
    end)
    launcher:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Claw Control")
        GameTooltip:AddLine("Kliknutim nebo dotykem otevres nastaveni.", 1, 1, 1)
        GameTooltip:AddLine("Ikonu muzes presunout tazenim.", 1, 1, 1)
        GameTooltip:Show()
    end)
    launcher:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local position = self.db.launcherPosition
    if position then launcher:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    else launcher:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -26, -185) end
    launcher:SetShown(self.db.showLauncher)
end

function CC:ShowOptions()
    if self.options:IsShown() then self.options:Hide() else self.options:Show() end
end









