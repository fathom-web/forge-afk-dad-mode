local _, ns = ...
local ForgeAFK = ns.ForgeAFK

local function MoveToAngle(button, angle)
    if not Minimap then return end
    button:ClearAllPoints()
    local radians = math.rad(angle)
    button:SetPoint("CENTER", Minimap, "CENTER",
        80 * math.cos(radians), 80 * math.sin(radians))
end

local function CursorAngle()
    if not Minimap then return nil end
    local x, y = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if not x or not y or not cursorX or not cursorY or not scale or scale == 0 then
        return nil
    end

    local dx, dy = cursorX / scale - x, cursorY / scale - y
    if type(math.atan2) == "function" then
        return math.deg(math.atan2(dy, dx)) % 360
    end
    -- Older Lua builds may only provide single-argument atan().
    local angle = math.deg(math.atan(dy / (dx == 0 and 0.00001 or dx)))
    if dx < 0 then angle = angle + 180 end
    return angle % 360
end

function ForgeAFK:UpdateMinimap()
    if not self.minimapButton or not self.db then return end
    if self.db.minimapHidden then
        self.minimapButton:Hide()
    else
        self.minimapButton:Show()
        MoveToAngle(self.minimapButton, self.db.minimapAngle or 225)
    end
end

function ForgeAFK:CreateMinimapButton()
    if not Minimap then
        self:Print("Minimap unavailable. /fafk still opens Dad Mode.")
        return
    end

    local button = CreateFrame("Button", "ForgeAFKMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
    icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", button, "TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(_, click)
        if click == "RightButton" then
            ForgeAFK:ToggleSilent()
        else
            ForgeAFK:Toggle()
        end
    end)

    button:SetScript("OnEnter", function(btn)
        if not GameTooltip then return end
        GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
        GameTooltip:AddLine("FORGE AFK - DAD MODE", 1, 0.78, 0.45)
        GameTooltip:AddLine("Left-click: Open/close Dad Mode", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Toggle Silent Mode", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move around the minimap", 0.72, 0.72, 0.72)
        GameTooltip:AddLine(ForgeAFK.db.silent and "Silent Mode: ON" or "Silent Mode: OFF",
            0.87, 0.77, 0.53)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    button:SetScript("OnDragStart", function(btn)
        btn:SetScript("OnUpdate", function(target)
            local angle = CursorAngle()
            if angle then
                ForgeAFK.db.minimapAngle = angle
                MoveToAngle(target, angle)
            end
        end)
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:SetScript("OnDragStop", function(btn)
        btn:SetScript("OnUpdate", nil)
    end)

    self.minimapButton = button
    self:UpdateMinimap()
end
