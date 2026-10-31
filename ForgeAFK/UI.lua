local _, ns = ...
local ForgeAFK = ns.ForgeAFK

local COLORS = {
    dark = { 0.075, 0.083, 0.094, 0.98 },
    panel = { 0.12, 0.13, 0.15, 1 },
    hover = { 0.21, 0.18, 0.13, 1 },
    gold = { 0.82, 0.66, 0.38, 1 },
    muted = { 0.67, 0.69, 0.72 },
}

local function ApplyBackdrop(widget, background)
    widget:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    widget:SetBackdropColor(unpack(background))
    widget:SetBackdropBorderColor(0.40, 0.34, 0.24, 0.95)
end

local function Font(parent, template, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", template)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    return label
end

function ForgeAFK:CreateUI()
    local panel = CreateFrame("Frame", "ForgeAFKPanel", UIParent, "BackdropTemplate")
    local extraHeight = math.max(0, #self.reasonOrder - 5) * 47
    panel:SetSize(350, 452 + extraHeight)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")

    local posX = type(self.db.x) == "number" and self.db.x or 0
    local posY = type(self.db.y) == "number" and self.db.y or 0
    panel:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    ApplyBackdrop(panel, COLORS.dark)
    panel:SetBackdropBorderColor(0.82, 0.66, 0.38, 1)

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

    local heading = Font(panel, "GameFontNormalLarge", "FORGE AFK", 20, -17)
    heading:SetTextColor(0.92, 0.75, 0.45)
    local mode = Font(panel, "GameFontHighlightSmall", "DAD MODE  |  Azeroth can wait. Dad duty can't.", 21, -42)
    mode:SetTextColor(unpack(COLORS.muted))

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() panel:Hide() end)

    local bar = panel:CreateTexture(nil, "ARTWORK")
    bar:SetColorTexture(0.55, 0.43, 0.24, 0.7)
    bar:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -67)
    bar:SetSize(314, 1)

    local reasonButtons = {}
    for i, id in ipairs(self.reasonOrder) do
        local reason = self.reasons[id]
        local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
        button:SetSize(314, 42)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -82 - (i - 1) * 47)
        ApplyBackdrop(button, COLORS.panel)

        local name = Font(button, "GameFontNormal", reason.name, 12, -5)
        name:SetTextColor(0.96, 0.84, 0.61)
        local hint = Font(button, "GameFontHighlightSmall", reason.hint, 12, -23)
        hint:SetTextColor(unpack(COLORS.muted))

        button:SetScript("OnEnter", function(b)
            b:SetBackdropColor(unpack(COLORS.hover))
            b:SetBackdropBorderColor(0.88, 0.68, 0.36, 1)
        end)
        button:SetScript("OnLeave", function(b)
            b:SetBackdropColor(unpack(COLORS.panel))
            b:SetBackdropBorderColor(0.40, 0.34, 0.24, 0.95)
        end)
        button:SetScript("OnClick", function()
            ForgeAFK:Activate(id)
        end)
        reasonButtons[id] = button
    end

    local timerLabel = Font(panel, "GameFontNormalSmall", "REAL-LIFE AGGRO TIMER", 20, -327 - extraHeight)
    timerLabel:SetTextColor(0.82, 0.66, 0.38)
    local timer = Font(panel, "GameFontNormalLarge", "00:00", 221, -323 - extraHeight)
    timer:SetTextColor(1, 1, 1)

    local status = Font(panel, "GameFontHighlightSmall", "Ready for real-life aggro.", 20, -352 - extraHeight)
    status:SetTextColor(unpack(COLORS.muted))

    local back = CreateFrame("Button", nil, panel, "BackdropTemplate")
    back:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -376 - extraHeight)
    back:SetSize(314, 38)
    ApplyBackdrop(back, COLORS.hover)
    back:SetBackdropBorderColor(0.82, 0.66, 0.38, 1)
    local backText = back:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    backText:SetPoint("CENTER")
    backText:SetText("I'M BACK  -  RESUME ADVENTURE")
    backText:SetTextColor(1, 0.88, 0.66)
    back:SetScript("OnClick", function()
        ForgeAFK:Return()
    end)

    local footer = Font(panel, "GameFontHighlightSmall", "Novyx Forge  |  /fafk  |  v" .. self.version, 20, -426 - extraHeight)
    footer:SetTextColor(0.51, 0.52, 0.55)

    panel:SetScript("OnUpdate", function(frame, elapsed)
        frame.elapsedSinceRefresh = (frame.elapsedSinceRefresh or 0) + elapsed
        if frame.elapsedSinceRefresh >= 0.5 then
            frame.elapsedSinceRefresh = 0
            ForgeAFK:UpdatePanel()
        end
    end)

    self.frame = panel
    self.timerText = timer
    self.statusText = status
    self.backButton = back
    self.reasonButtons = reasonButtons
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

    self.backButton:SetEnabled(active and true or false)
    self.backButton:SetAlpha(active and 1 or 0.42)
end
