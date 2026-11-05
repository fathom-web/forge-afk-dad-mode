-- Forge AFK - Dad Mode: headless smoke test using mocked WoW APIs.
-- Run from repository root with Lua 5.1: lua5.1 tests/smoke.lua
unpack = unpack or table.unpack

local now, messages = 100000, {}
local inParty, inRaid, inInstance = false, false, false

function time() return now end
function IsInGroup(category)
    if category == LE_PARTY_CATEGORY_INSTANCE then return inInstance end
    return inParty or inRaid or inInstance
end
function IsInRaid() return inRaid end
function GetCursorPosition() return 620, 540 end

C_ChatInfo = { SendChatMessage = function(message, channel)
    messages[#messages + 1] = { body = message, channel = channel }
end }
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
LE_PARTY_CATEGORY_INSTANCE = 2
local nativeAFKMessages = {}
SLASH_CHAT_AFK1 = "/afk"
SlashCmdList = { CHAT_AFK = function(message)
    nativeAFKMessages[#nativeAFKMessages + 1] = message
end }
hash_SlashCmdList = { ["/AFK"] = SlashCmdList.CHAT_AFK }

local Widget = {}
Widget.__index = function(_, key)
    return rawget(Widget, key) or function() end
end
function Widget:SetScript(event, handler)
    local scripts = rawget(self, "scripts")
    if not scripts then
        scripts = {}
        rawset(self, "scripts", scripts)
    end
    scripts[event] = handler
end
function Widget:CreateTexture()
    return setmetatable({}, Widget)
end
function Widget:CreateFontString()
    return setmetatable({}, Widget)
end
function Widget:SetText(value)
    self.text = value
end
function Widget:SetEnabled(enabled)
    self.enabled = enabled
end
function Widget:IsEnabled()
    return self.enabled ~= false
end
function Widget:Show()
    self.visible = true
end
function Widget:Hide()
    self.visible = false
end
function Widget:IsShown()
    return self.visible == true
end
function Widget:GetCenter()
    return 500, 500
end
function Widget:GetEffectiveScale()
    return 1
end
function CreateFrame(_, name, parent)
    local obj = setmetatable({ name = name, parent = parent }, Widget)
    return obj
end

UIParent = setmetatable({}, Widget)
Minimap = setmetatable({}, Widget)
GameTooltip = setmetatable({}, Widget)

local ns = {}
assert(loadfile("ForgeAFK/Core.lua"))("ForgeAFK", ns)
assert(loadfile("ForgeAFK/UI.lua"))("ForgeAFK", ns)
assert(loadfile("ForgeAFK/Minimap.lua"))("ForgeAFK", ns)

local afk = assert(ns.ForgeAFK)
assert(afk.version == "1.0.1-beta.1")
assert(#afk.reasonOrder == 12, "Exactly twelve reasons expected")

-- First-load lifecycle is triggered explicitly just like WoW's addon event.
-- Initialize using the same method called by the ADDON_LOADED listener.
afk:Initialize()
assert(afk.frame:IsShown(), "First launch must show UI")
assert(afk.minimapButton and afk.minimapButton:IsShown(), "Minimap button should be visible")
assert(afk.reasonButtons and afk.reasonButtons.tech, "Missing Tech Support button")
assert(afk.whisperInfo and afk.whisperInfo.text, "Missing whisper auto-reply indicator")
assert(not afk.db.silent)


-- Native /afk opens our panel without toggling AFK; /afk custom text retains
-- Blizzard's original behavior and the cached handler is invalidated.
afk.frame:Hide()
assert(type(hash_SlashCmdList["/AFK"]) == "function",
    "Bare /afk must have a cached command handler")
assert(hash_SlashCmdList["/AFK"] ~= nil and
    hash_SlashCmdList["/AFK"] == SlashCmdList.CHAT_AFK,
    "Runtime chat parser must use our handler, not Blizzard's cached handler")
hash_SlashCmdList["/AFK"]("")
assert(afk.frame:IsShown(), "Bare /afk must open Dad Mode")
assert(#nativeAFKMessages == 0, "Bare /afk must not set native AFK")
hash_SlashCmdList["/AFK"]("Custom away text")
assert(#nativeAFKMessages == 1 and nativeAFKMessages[1] == "Custom away text",
    "/afk with a message must preserve native behavior")

-- All 12 reasons must provide unique return texts and emit exactly one
-- AFK + one party announcement on start and return when non-silent.
local uniqueComebacks = {}
inParty = true
for _, id in ipairs(afk.reasonOrder) do
    local reason = assert(afk.reasons[id], "Missing reason: " .. id)
    assert(reason.name and reason.hint and reason.afk and reason.group and reason.back)
    assert(reason.afk:sub(1, 11) == "[Forge AFK]", "Native AFK auto-reply must use our branding")
    assert(#reason.afk <= 255, "AFK reply exceeds chat limit")
    assert(not uniqueComebacks[reason.back], "Duplicate comeback: " .. id)
    uniqueComebacks[reason.back] = true
    assert(afk.reasonButtons[id], "Missing UI button: " .. id)

    messages = {}
    afk:Activate(id)
    assert(afk.db.session.active)
    assert(afk.whisperInfo.text:find("auto-replies", 1, true), "Whisper status should activate")
    assert(#messages == 2, "Departure must be one AFK and one group message: " .. id)
    assert(messages[1].channel == "AFK" and messages[2].channel == "PARTY")
    assert(messages[1].body == reason.afk, "AFK auto-reply message mismatch")
    assert(messages[2].channel ~= "WHISPER", "Do not send a duplicate direct whisper")
    now = now + 42
    afk:UpdatePanel()
    assert(afk.timerText.text == "00:42", "Timer display was not updated")
    afk:Return()
    assert(#messages == 4, "Comeback must be one AFK clear and one party message: " .. id)
    assert(messages[3].channel == "AFK" and messages[4].channel == "PARTY")
    assert(messages[4].body:find(reason.back, 1, true), "Wrong comeback for: " .. id)
    assert(messages[4].body:find("00:42", 1, true), "Missing comeback duration")
    assert(not afk.db.session.active, "Still active after return")
end

-- Prevent double broadcasts.
local n = #messages
afk:Return()
assert(#messages == n, "Second return should not broadcast")

-- Silent Mode: normal AFK status is still set/cleared, no group messages.
messages = {}
afk:SetSilent(true)
afk:Activate("toilet")
now = now + 3
afk:Return()
assert(#messages == 2)
assert(messages[1].channel == "AFK" and messages[2].channel == "AFK")
assert(messages[1].body == afk.reasons.toilet.afk,
    "Silent Mode must preserve WoW's native AFK auto-reply")
afk:SetSilent(false)

-- If silent is enabled mid-session, suppress the comeback.
messages = {}
afk:Activate("phone")
afk:SetSilent(true)
afk:Return()
assert(#messages == 3 and messages[3].channel == "AFK")
afk:SetSilent(false)

-- Solo gameplay: no group spam.
inParty = false
messages = {}
afk:Activate("coffee")
afk:Return()
assert(#messages == 2 and messages[1].channel == "AFK")

-- Raid / instance routing.
inRaid = true
messages = {}
afk:Activate("sleep")
assert(messages[2].channel == "RAID")
afk:Return()
inRaid = false
inInstance = true
messages = {}
afk:Activate("delivery")
assert(messages[2].channel == "INSTANCE_CHAT")
afk:Return()
inInstance = false

-- Simulate an addon reload while an away session is active.
afk:Activate("tech")
now = now + 97
local saved = ForgeAFKDB
afk:Initialize()
assert(ForgeAFKDB == saved and afk:Elapsed() == 97, "Reload lost session")
afk:Return()

-- Slash commands and minimap UI.
assert(type(SlashCmdList.FORGEAFK) == "function")
local wasHidden = afk.db.minimapHidden
SlashCmdList.FORGEAFK("minimap")
assert(afk.db.minimapHidden ~= wasHidden)
SlashCmdList.FORGEAFK("minimap")
assert(afk.db.minimapHidden == wasHidden)
local wasSilent = afk.db.silent
afk.minimapButton.scripts.OnClick(afk.minimapButton, "RightButton")
assert(afk.db.silent ~= wasSilent, "Minimap right click must toggle silent")
afk.minimapButton.scripts.OnClick(afk.minimapButton, "RightButton")
assert(afk.db.silent == wasSilent)
afk.minimapButton.scripts.OnDragStart(afk.minimapButton)
afk.minimapButton.scripts.OnUpdate(afk.minimapButton)
afk.minimapButton.scripts.OnDragStop(afk.minimapButton)
assert(type(afk.db.minimapAngle) == "number", "Minimap drag must save angle")

print("Forge AFK Dad Mode: 12 native whisper replies, UI, chat, minimap and silent-mode smoke tests passed.")
