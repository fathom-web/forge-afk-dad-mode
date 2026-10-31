local addonName, ns = ...
local ForgeAFK = {}
ns.ForgeAFK = ForgeAFK

ForgeAFK.version = "1.0.0-beta.1"
ForgeAFK.reasons = {
    kid = {
        name = "KID AGGRO",
        hint = "Real-life boss encounter",
        afk = "Kid aggro! Real-life boss fight. Back soon.",
        group = "[Forge AFK] Kid aggro! Real-life boss fight. BRB.",
        back = "Dad survived Kid Aggro. Bedtime boss defeated.",
    },
    partner = {
        name = "PARTNER AGGRO",
        hint = "This raid has priority",
        afk = "Partner aggro. This raid has priority. Back soon.",
        group = "[Forge AFK] Partner aggro. This raid has priority. BRB.",
        back = "Partner raid cleared. Relationship reputation +10.",
    },
    pet = {
        name = "PET EMERGENCY",
        hint = "No hearthstone available",
        afk = "Pet emergency. No hearthstone available. Back soon.",
        group = "[Forge AFK] Pet emergency! No hearthstone available. BRB.",
        back = "Pet escort quest complete. Paw patrol survived.",
    },
    toilet = {
        name = "TOILET RAID",
        hint = "Nature calls. No ready check.",
        afk = "Toilet raid! Nature called. Back soon.",
        group = "[Forge AFK] Toilet raid! Nature called a ready check. BRB.",
        back = "Dad survived the Toilet Raid. No loot dropped.",
    },
    phone = {
        name = "PHONE AGGRO",
        hint = "Incoming real-life call",
        afk = "Phone aggro! Incoming real-life call. Back soon.",
        group = "[Forge AFK] Phone aggro! Can't silence this boss. BRB.",
        back = "Phone boss defeated. Battery -5. Sanity -20.",
    },
    snack = {
        name = "SNACK QUEST",
        hint = "Restocking supplies",
        afk = "Snack quest: restocking supplies. Back soon.",
        group = "[Forge AFK] Snack quest! Restocking supplies. BRB.",
        back = "Snack quest complete. Inventory replenished.",
    },
    sleep = {
        name = "SLEEP DEBUFF",
        hint = "Dad fell asleep. Again.",
        afk = "Sleep debuff. Brief recharge needed.",
        group = "[Forge AFK] Dad fell asleep at the keyboard. Again. BRB.",
        back = "Sleep debuff dispelled. Dad is operational.",
    },
    work = {
        name = "WORK AGGRO",
        hint = "Employer has entered combat",
        afk = "Work aggro! Real-life boss needs attention.",
        group = "[Forge AFK] Real-life employer has entered combat. BRB.",
        back = "Work aggro evaded. Back to the real endgame.",
    },
    coffee = {
        name = "COFFEE REFILL",
        hint = "Brewing a mana potion",
        afk = "Coffee refill. Brewing a fresh mana potion.",
        group = "[Forge AFK] Mana depleted. Brewing a fresh potion. BRB.",
        back = "Coffee potion consumed. Mana restored +100.",
    },
    delivery = {
        name = "DELIVERY BOSS",
        hint = "Legendary loot at the door",
        afk = "Delivery boss! Package at the door.",
        group = "[Forge AFK] Legendary loot delivery at the front door. BRB.",
        back = "Delivery boss down. Package looted.",
    },
    doorbell = {
        name = "DOORBELL PULL",
        hint = "Unexpected visitor encounter",
        afk = "Doorbell boss pulled. Back soon.",
        group = "[Forge AFK] Someone pulled the doorbell boss. BRB.",
        back = "Doorbell boss handled. Unexpected NPC despawned.",
    },
}
ForgeAFK.reasonOrder = { "kid", "partner", "pet", "toilet", "phone", "snack", "doorbell", "sleep", "work", "coffee", "delivery" }

function ForgeAFK:Print(message)
    local line = "|cffd5af67Forge AFK|r  " .. tostring(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(line)
    end
end

function ForgeAFK:Elapsed()
    local session = self.db and self.db.session
    if not session or not session.active or type(session.startedAt) ~= "number" then
        return 0
    end
    return math.max(0, time() - session.startedAt)
end

function ForgeAFK:FormatTime(seconds)
    local value = math.max(0, math.floor(seconds or 0))
    local hours = math.floor(value / 3600)
    local minutes = math.floor((value % 3600) / 60)
    local remaining = value % 60
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, remaining)
    end
    return string.format("%02d:%02d", minutes, remaining)
end

function ForgeAFK:GroupChannel()
    if type(IsInGroup) == "function" and LE_PARTY_CATEGORY_INSTANCE
        and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end
    if type(IsInRaid) == "function" and IsInRaid() then
        return "RAID"
    end
    if type(IsInGroup) == "function" and IsInGroup() then
        return "PARTY"
    end
    return nil
end

function ForgeAFK:SendChat(message, chatType)
    if not C_ChatInfo or type(C_ChatInfo.SendChatMessage) ~= "function" then
        self:Print("Chat API unavailable. Local timer still works.")
        return false
    end
    -- Only invoked by the player's own button click or slash command.
    local success = pcall(C_ChatInfo.SendChatMessage, message, chatType)
    if not success then
        self:Print("Chat action blocked by the client. Timer is still running.")
    end
    return success
end

function ForgeAFK:SetSilent(enabled)
    self.db.silent = not not enabled
    self:RefreshUI()
    self:Print(self.db.silent and "Silent Mode ON: no group announcements."
        or "Silent Mode OFF: group announcements enabled.")
end

function ForgeAFK:ToggleSilent()
    self:SetSilent(not self.db.silent)
end

function ForgeAFK:SetMinimapHidden(hidden)
    self.db.minimapHidden = not not hidden
    self:RefreshUI()
    self:Print(self.db.minimapHidden and "Minimap icon hidden. Use /fafk minimap to restore."
        or "Minimap icon visible.")
end

function ForgeAFK:Activate(id)
    local reason = self.reasons[id]
    if not reason then
        self:Print("Unknown reason. Try /fafk to open the panel.")
        return
    end
    if self.db.session.active then
        self:Print("You're already AFK. Click I'M BACK first.")
        return
    end

    local session = {
        active = true,
        reason = id,
        startedAt = time(),
        announced = false,
    }
    self.db.session = session

    -- A user action sets the WoW AFK message; no anti-AFK automation.
    self:SendChat(reason.afk, "AFK")
    local channel = self:GroupChannel()
    if channel and not self.db.silent then
        session.announced = self:SendChat(reason.group, channel)
    end

    self:RefreshUI()
    self:Print(reason.name .. " activated. Dad duty comes first.")
end

function ForgeAFK:Return()
    if not self.db.session.active then
        self:Print("You're already back in Azeroth.")
        return
    end

    local elapsed = self:FormatTime(self:Elapsed())
    local session = self.db.session
    local reason = self.reasons[session.reason]
    -- Silence is sticky: even an active session won't announce when toggled on.
    local announce = session.announced and not self.db.silent
    self.db.session = { active = false, announced = false }
    self:SendChat("", "AFK")

    local channel = announce and self:GroupChannel()
    if channel and reason then
        self:SendChat("[Forge AFK] " .. reason.back .. " Back after " .. elapsed .. "!", channel)
    end
    self:RefreshUI()
    self:Print("Welcome back! You survived " .. elapsed .. " of real-life aggro.")
end

function ForgeAFK:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
        self:RefreshUI()
    end
end

function ForgeAFK:RefreshUI()
    if self.UpdatePanel then self:UpdatePanel() end
    if self.UpdateMinimap then self:UpdateMinimap() end
end

function ForgeAFK:Initialize()
    if type(ForgeAFKDB) ~= "table" then
        ForgeAFKDB = {}
    end
    self.db = ForgeAFKDB
    if type(self.db.silent) ~= "boolean" then self.db.silent = false end
    if type(self.db.minimapHidden) ~= "boolean" then self.db.minimapHidden = false end
    if type(self.db.minimapAngle) ~= "number" then self.db.minimapAngle = 225 end
    if type(self.db.session) ~= "table"
        or (self.db.session.active and (
            not self.reasons[self.db.session.reason]
            or type(self.db.session.startedAt) ~= "number"
            or self.db.session.startedAt > time())) then
        self.db.session = { active = false }
    end

    self:CreateUI()
    self:CreateMinimapButton()
    SLASH_FORGEAFK1 = "/fafk"
    SLASH_FORGEAFK2 = "/forgeafk"
    SlashCmdList.FORGEAFK = function(input)
        local command = string.lower((input or ""):match("^%s*(.-)%s*$"))
        if command == "back" then
            ForgeAFK:Return()
        elseif ForgeAFK.reasons[command] then
            ForgeAFK:Activate(command)
        elseif command == "silent" then
            ForgeAFK:ToggleSilent()
        elseif command == "minimap" then
            ForgeAFK:SetMinimapHidden(not ForgeAFK.db.minimapHidden)
        elseif command == "help" then
            ForgeAFK:Print("/fafk - panel | /fafk silent | /fafk minimap | /fafk back")
            ForgeAFK:Print("Reasons: " .. table.concat(ForgeAFK.reasonOrder, ", "))
        elseif command == "about" then
            ForgeAFK:Print("Made by Novyx Forge  -  https://wow.novyxforge.com")
        else
            ForgeAFK:Toggle()
        end
    end

    if not self.db.seenWelcome then
        self.db.seenWelcome = true
        self.frame:Show()
    end
    self:RefreshUI()
    self:Print("Dad Mode ready! /fafk opens the panel. Right-click minimap icon for Silent Mode.")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, loadedName)
    if loadedName == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        ForgeAFK:Initialize()
    end
end)
