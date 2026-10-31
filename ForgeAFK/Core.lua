local addonName, ns = ...
local ForgeAFK = {}
ns.ForgeAFK = ForgeAFK

ForgeAFK.version = "0.1.0-alpha"
ForgeAFK.reasons = {
    kid = {
        name = "KID AGGRO",
        hint = "Real-life boss encounter",
        afk = "Kid aggro! Real-life boss fight. Back soon.",
        group = "[Forge AFK] Kid aggro! Real-life boss fight. BRB.",
    },
    partner = {
        name = "PARTNER AGGRO",
        hint = "This raid has priority",
        afk = "Partner aggro. This raid has priority. Back soon.",
        group = "[Forge AFK] Partner aggro. This raid has priority. BRB.",
    },
    pet = {
        name = "PET EMERGENCY",
        hint = "No hearthstone available",
        afk = "Pet emergency. No hearthstone available. Back soon.",
        group = "[Forge AFK] Pet emergency! No hearthstone available. BRB.",
    },
    snack = {
        name = "SNACK QUEST",
        hint = "Restocking supplies",
        afk = "Snack quest: restocking supplies. Back soon.",
        group = "[Forge AFK] Snack quest! Restocking supplies. BRB.",
    },
    doorbell = {
        name = "DOORBELL PULL",
        hint = "Unexpected visitor encounter",
        afk = "Doorbell boss pulled. Back soon.",
        group = "[Forge AFK] Someone pulled the doorbell boss. BRB.",
    },
}
ForgeAFK.reasonOrder = { "kid", "partner", "pet", "snack", "doorbell" }

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

    self.db.session = {
        active = true,
        reason = id,
        startedAt = time(),
    }

    -- Set WoW's actual AFK message, not just a local timer.
    self:SendChat(reason.afk, "AFK")
    local channel = self:GroupChannel()
    if channel then
        self:SendChat(reason.group, channel)
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
    self.db.session = { active = false }
    -- A blank AFK message clears the player's AFK status.
    self:SendChat("", "AFK")

    local channel = self:GroupChannel()
    if channel then
        self:SendChat("[Forge AFK] Dad mode complete. Back after " .. elapsed .. "!", channel)
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
    if self.UpdatePanel then
        self:UpdatePanel()
    end
end

function ForgeAFK:Initialize()
    if type(ForgeAFKDB) ~= "table" then
        ForgeAFKDB = {}
    end
    self.db = ForgeAFKDB
    if type(self.db.session) ~= "table"
        or (self.db.session.active and (
            not self.reasons[self.db.session.reason]
            or type(self.db.session.startedAt) ~= "number")) then
        self.db.session = { active = false }
    end

    self:CreateUI()
    SLASH_FORGEAFK1 = "/fafk"
    SLASH_FORGEAFK2 = "/forgeafk"
    SlashCmdList.FORGEAFK = function(input)
        local command = string.lower((input or ""):match("^%s*(.-)%s*$"))
        if command == "back" then
            ForgeAFK:Return()
        elseif ForgeAFK.reasons[command] then
            ForgeAFK:Activate(command)
        elseif command == "help" then
            ForgeAFK:Print("/fafk - panel  |  /fafk kid, partner, pet, snack, doorbell  |  /fafk back")
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
    self:Print("Dad Mode ready! /fafk opens the panel.")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, loadedName)
    if loadedName == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        ForgeAFK:Initialize()
    end
end)
