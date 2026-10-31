local _, ns = ...
local ForgeAFK = ns.ForgeAFK

local COLORS = {
    bg = { 0.075, 0.078, 0.082, 0.98 },
    button = { 0.15, 0.14, 0.13, 1 },
    hover = { 0.24, 0.19, 0.12, 1 },
    edge = { 0.43, 0.34, 0.22, 1 },
    gold = { 0.88, 0.71, 0.43 },
    muted = { 0.69, 0.68, 0.65 },
}

local function Backdrop(frame, color)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(unpack(color))
    frame:SetBackdropBorderColor(unpack(COLORS.edge))
end

local function Text(parent, font, value, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(value)
    return label
end

function ForgeAFK:CreateUI()
    local panel = CreateFrame("Frame", "ForgeAFKPanel", UIParent, "BackdropTemplate")
    panel:SetSize(510, 604)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetPoint("CENTER", UIParent, "CENTER",
        type(self.db.x) == "number" and self.db.x or 0,
        type(self.db.y) == "number" and self.db.y or 0)
    Backdrop(panel, COLORS.bg)
    panel:SetBackdropBorderColor(0.86, 0.65, 0.35, 1)

    panel:SetScript("OnDragStart", function(frame)
        frame:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local x, y = frame:GetCenter()
        local ux, uy = UIParent:GetCenter()
        if x and y and ux and uy then
            ForgeAFK.db.x = math.floor(x - ux + 0.5)
            ForgeAFK.db.y = math.floor(y - uy + 0.5)
        end
    end)

    local heading = Text(panel, "GameFontNormalLarge", "FORGE AFK", 20, -18)
    heading:SetTextColor(unpack(COLORS.gold))
    local subtitle = Text(panel, "GameFontHighlightSmall",
        "DAD MODE  |  Azeroth can wait. Dad duty can't.", 21, -43)
    subtitle:SetTextColor(unpack(COLORS.muted))

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() panel:Hide() end)

    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.6, 0.43, 0.24, 0.75)
    divider:SetPoint("TOPLEFT", panel, "TOPLEFT", 19, -73)
    divider:SetSize(472, 1)

    local buttons = {}
    for i, id in ipairs(self.reasonOrder) do
        local reason = self.reasons[id]
        local column = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
        button:SetSize(230, 46)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", 19 + column * 241, -88 - row * 54)
        Backdrop(button, COLORS.button)

        local name = Text(button, "GameFontNormal", reason.name, 11, -7)
        name:SetTextColor(0.96, 0.82, 0.59)
        local hint = Text(button, "GameFontHighlightSmall", reason.hint, 11, -25)
        hint:SetTextColor(unpack(COLORS.muted))

        button:SetScript("OnEnter", function(btn)
            if not btn:IsEnabled() then return end
            btn:SetBackdropColor(unpack(COLORS.hover))
            btn:SetBackdropBorderColor(0.9, 0.68, 0.34, 1)
        end)
        button:SetScript("OnLeave", function(btn)
            btn:SetBackdropColor(unpack(COLORS.button))
            btn:SetBackdropBorderColor(unpack(COLORS.edge))
        end)
        button:SetScript("OnClick", function() ForgeAFK:Activate(id) end)
        buttons[id] = button
    end

    local timerTitle = Text(panel, "GameFontNormalSmall", "REAL-LIFE AGGRO TIMER", 20, -422)
    timerTitle:SetTextColor(unpack(COLORS.gold))
    local timer = Text(panel, "GameFontNormalLarge", "00:00", 405, -417)
    timer:SetTextColor(1, 1, 1)

    local status = Text(panel, "GameFontHighlightSmall", "Ready for real-life aggro.", 20, -449)
    status:SetTextColor(unpack(COLORS.muted))

    local silent = CreateFrame("Button", nil, panel, "BackdropTemplate")
    silent:SetPoint("TOPLEFT", panel, "TOPLEFT", 19, -470)
    silent:SetSize(472, 35)
    Backdrop(silent, COLORS.button)
    local silentLabel = silent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    silentLabel:SetPoint("CENTER")
    silentLabel:SetTextColor(0.96, 0.84, 0.61)
    silent:SetScript("OnClick", function() ForgeAFK:ToggleSilent() end)
    silent:SetScript("OnEnter", function(btn)
        btn:SetBackdropBorderColor(0.9, 0.68, 0.34, 1)
    end)
    silent:SetScript("OnLeave", function(btn)
        btn:SetBackdropBorderColor(unpack(COLORS.edge))
    end)

    local back = CreateFrame("Button", nil, panel, "BackdropTemplate")
    back:SetPoint("TOPLEFT", panel, "TOPLEFT", 19, -516)
    back:SetSize(472, 42)
    Backdrop(back, COLORS.hover)
    back:SetBackdropBorderColor(0.88, 0.67, 0.39, 1)
    local backLabel = back:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    backLabel:SetPoint("CENTER")
    backLabel:SetText("I'M BACK  -  RESUME ADVENTURE")
    backLabel:SetTextColor(1, 0.88, 0.67)
    back:SetScript("OnClick", function() ForgeAFK:Return() end)

    -- WoW's native AFK status provides the automatic whisper reply.
    local whisperInfo = Text(panel, "GameFontHighlightSmall",
        "WHISPERS: WoW replies automatically while AFK", 20, -563)
    whisperInfo:SetTextColor(0.79, 0.69, 0.49)

    local footer = Text(panel, "GameFontHighlightSmall",
        "NOVYX FORGE  |  /fafk  |  v" .. self.version .. "  |  R-click minimap: silent", 20, -582)
    footer:SetTextColor(0.55, 0.55, 0.52)

    panel:SetScript("OnUpdate", function(frame, elapsed)
        frame.refreshElapsed = (frame.refreshElapsed or 0) + elapsed
        if frame.refreshElapsed >= 0.5 then
            frame.refreshElapsed = 0
            ForgeAFK:UpdatePanel()
        end
    end)

    self.frame = panel
    self.timerText = timer
    self.statusText = status
    self.backButton = back
    self.silentLabel = silentLabel
    self.whisperInfo = whisperInfo
    self.reasonButtons = buttons
    panel:Hide()
end

function ForgeAFK:UpdatePanel()
    if not self.timerText or not self.db then return end
    local session = self.db.session
    local active = session and session.active
    self.timerText:SetText(self:FormatTime(self:Elapsed()))

    if active and self.reasons[session.reason] then
        self.statusText:SetText("ON DUTY: " .. self.reasons[session.reason].name)
    else
        self.statusText:SetText("Ready for real-life aggro.")
    end

    self.silentLabel:SetText(self.db.silent
        and "SILENT MODE: ON  -  No group announcements"
        or "SILENT MODE: OFF  -  Announce in party or raid")
    self.whisperInfo:SetText(active
        and "WHISPERS: WoW auto-replies with your selected AFK reason"
        or "WHISPERS: WoW auto-reply activates when you go AFK")

    for _, button in pairs(self.reasonButtons) do
        button:SetEnabled(not active)
        button:SetAlpha(active and 0.4 or 1)
    end
    self.backButton:SetEnabled(active and true or false)
    self.backButton:SetAlpha(active and 1 or 0.4)
end
