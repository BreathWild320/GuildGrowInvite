local GGI = GuildGrowInvite

if not LibStub("LibSharedMedia-3.0", true) then
    LoadAddOn("LibSharedMedia-3.0")
end
local LSM = LibStub("LibSharedMedia-3.0", true)

local function FirstLSMMedia(mediaType)
    if not LSM or not LSM.GetMySets then return nil end
    local list = LSM:GetMySets(mediaType)
    if list and #list > 0 then
        return list[1]
    end
    return nil
end

local fontName = FirstLSMMedia("font") or "Friz Quadrata TT"
local bgName = FirstLSMMedia("background") or "Interface\\Tooltips\\UI-Tooltip-Background"
local borderName = FirstLSMMedia("border") or "Interface\\Tooltips\\UI-Tooltip-Border"
local statusbarName = FirstLSMMedia("statusbar")

local function GetLSMFont(name)
    if LSM and LSM.Fetch and LSM:Fetch("font", name) then
        return LSM:Fetch("font", name)
    end
    return name
end

local function GetLSMBG(name)
    if LSM and LSM.Fetch and LSM:Fetch("background", name) then
        return LSM:Fetch("background", name)
    end
    return name
end

local function GetLSMBorder(name)
    if LSM and LSM.Fetch and LSM:Fetch("border", name) then
        return LSM:Fetch("border", name)
    end
    return name
end

local function GetLSMStatusbar(name)
    if LSM and LSM.Fetch and LSM:Fetch("statusbar", name) then
        return LSM:Fetch("statusbar", name)
    end
    return name
end

local frame
local mapButton

local function CreateMapButton()
    if mapButton or not WorldMapFrame then return end

    mapButton = CreateFrame("Button", "GuildGrowInviteWorldMapButton", WorldMapFrame, "UIPanelButtonTemplate")
    mapButton:SetSize(32, 32)
    mapButton:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -80, -38)
    mapButton:SetText("")
    mapButton:SetFrameStrata("HIGH")

    local texture = mapButton:CreateTexture(nil, "ARTWORK")
    texture:SetTexture("Interface\\AddOns\\GuildGrowInvite\\GuildGrowInvite_button")
    texture:SetAllPoints(mapButton)
    mapButton.icon = texture

    mapButton:SetScript("OnClick", function()
        if GGI.ToggleUI then
            GGI.ToggleUI()
        end
    end)

    mapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("GuildGrowInvite")
        GameTooltip:AddLine("Click to open the guild recruitment window.")
        GameTooltip:Show()
    end)

    mapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateSectionHeader(parent, text, anchor, yOff, width)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    header:SetFont(GetLSMFont(fontName), 12)
    header:SetPoint("TOPLEFT", anchor or parent, "TOPLEFT", 24, yOff or -70)
    header:SetText(text)
    header:SetTextColor(0.55, 0.65, 1, 1)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\Tooltips\\UI-Tooltip-Border")
    divider:SetSize(width or 460, 2)
    divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    divider:SetVertexColor(0.35, 0.35, 0.65, 0.7)

    return header, divider
end

local function CreateSectionPanel(parent, anchor, yOff, width, height)
    local panel = parent:CreateTexture(nil, "ARTWORK")
    panel:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\Tooltips\\UI-Tooltip-Background")
    panel:SetSize(width or 472, height or 90)
    panel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff or -4)
    panel:SetVertexColor(0.08, 0.08, 0.16, 0.65)
    return panel
end

local function BuildFrame()
    if frame then return frame end

    frame = CreateFrame("Frame", "GuildGrowInviteFrame", UIParent)
    frame:SetSize(520, 720)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
        bgFile = GetLSMBG(bgName),
        edgeFile = GetLSMBorder(borderName),
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    frame:SetBackdropColor(0.04, 0.04, 0.08, 0.96)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.65, 0.85)

    local titleBar = frame:CreateTexture(nil, "ARTWORK")
    titleBar:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBar:SetSize(490, 52)
    titleBar:SetPoint("TOP", frame, "TOP", 0, -6)
    titleBar:SetVertexColor(0.28, 0.28, 0.58, 0.9)

    local titleGlow = frame:CreateTexture(nil, "OVERLAY")
    titleGlow:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\DialogFrame\\UI-DialogBox-Header")
    titleGlow:SetSize(490, 8)
    titleGlow:SetPoint("TOP", titleBar, "BOTTOM", 0, 0)
    titleGlow:SetVertexColor(0.4, 0.4, 0.8, 0.5)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetFont(GetLSMFont(fontName), 18)
    frame.title:SetPoint("TOP", titleBar, "TOP", 0, -12)
    frame.title:SetText("GuildGrowInvite")
    frame.title:SetTextColor(0.85, 0.85, 1, 1)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetFont(GetLSMFont(fontName), 11)
    subtitle:SetPoint("TOP", frame.title, "BOTTOM", 0, -2)
    subtitle:SetText("Auto-Recruitment Manager")
    subtitle:SetTextColor(0.5, 0.55, 0.75, 1)

    frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local db = GGI.db

    CreateSectionHeader(frame, "RECRUITMENT SETTINGS", frame, -70)

    local function CreateStyledCheckbox(text, key, defaultVal, anchor, anchorPoint, xOff, yOff)
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetPoint(anchorPoint or "TOPLEFT", anchor or frame, "TOPLEFT", xOff or 24, yOff or -90)
        cb:SetChecked(GGI.db[key] or defaultVal)
        cb:SetScript("OnClick", function(self)
            GGI.db[key] = self:GetChecked() and true or false
        end)
        local label = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", cb, "RIGHT", 8, 1)
        label:SetFont(GetLSMFont(fontName), 12)
        label:SetText(text)
        label:SetTextColor(0.85, 0.85, 0.92, 1)
        return cb
    end

    local scanCheck = CreateStyledCheckbox("Chat-scan candidate list enabled", "scanEnabled", true, frame, "TOPLEFT", 24, -96)
    local chatAutoInviteCheck = CreateStyledCheckbox("Auto-invite from any tracked chat message", "chatAutoInviteEnabled", true, scanCheck, "TOPLEFT", 0, -24)
    local nearAutoInviteCheck = CreateStyledCheckbox("Auto-invite nearby players", "nearAutoInviteEnabled", true, chatAutoInviteCheck, "TOPLEFT", 0, -24)
    local lfgAutoInviteCheck = CreateStyledCheckbox("Auto-invite LFG whispers/chat (aggressive)", "lfgAutoInviteEnabled", true, nearAutoInviteCheck, "TOPLEFT", 0, -24)
    local snoopCheck = CreateStyledCheckbox("Snoop nearby players (aggressive scanning)", "snoopEnabled", true, lfgAutoInviteCheck, "TOPLEFT", 0, -24)

    local levelFilterCheck = CreateStyledCheckbox("Enable level range filter", "levelFilterEnabled", false, snoopCheck, "TOPLEFT", 0, -28)

    local filterPanel = CreateSectionPanel(frame, levelFilterCheck, -4, 350, 30)

    local minLevelLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    minLevelLabel:SetFont(GetLSMFont(fontName), 11)
    minLevelLabel:SetPoint("TOPLEFT", levelFilterCheck, "BOTTOMLEFT", 20, -10)
    minLevelLabel:SetText("Min level:")
    minLevelLabel:SetTextColor(0.65, 0.65, 0.8, 1)

    local minLevelBox = CreateFrame("EditBox", nil, frame)
    minLevelBox:SetAutoFocus(false)
    minLevelBox:SetSize(50, 22)
    minLevelBox:SetPoint("LEFT", minLevelLabel, "RIGHT", 10, 0)
    minLevelBox:SetBackdrop({
        bgFile = GetLSMBG(bgName),
        edgeFile = GetLSMBorder(borderName),
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    minLevelBox:SetBackdropColor(0.06, 0.06, 0.1, 0.85)
    minLevelBox:SetBackdropBorderColor(0.2, 0.2, 0.35, 0.7)
    minLevelBox:SetTextInsets(6, 0, 0, 0)
    minLevelBox:SetFont(GetLSMFont(fontName), 11)
    minLevelBox:SetTextColor(1, 1, 1, 1)
    minLevelBox:SetText(tostring(db.minLevel or 1))
    minLevelBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText():trim()
        local value = tonumber(text)
        if value and value >= 1 and value <= 70 then
            db.minLevel = value
            print("|cff00ccff[GuildGrowInvite]|r Min level set to " .. value)
        else
            print("|cffff0000[GuildGrowInvite]|r Invalid level. Enter 1-70.")
        end
        self:ClearFocus()
    end)

    local maxLevelLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    maxLevelLabel:SetFont(GetLSMFont(fontName), 11)
    maxLevelLabel:SetPoint("LEFT", minLevelBox, "RIGHT", 20, 0)
    maxLevelLabel:SetText("Max level:")
    maxLevelLabel:SetTextColor(0.65, 0.65, 0.8, 1)

    local maxLevelBox = CreateFrame("EditBox", nil, frame)
    maxLevelBox:SetAutoFocus(false)
    maxLevelBox:SetSize(50, 22)
    maxLevelBox:SetPoint("LEFT", maxLevelLabel, "RIGHT", 10, 0)
    maxLevelBox:SetBackdrop({
        bgFile = GetLSMBG(bgName),
        edgeFile = GetLSMBorder(borderName),
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    maxLevelBox:SetBackdropColor(0.06, 0.06, 0.1, 0.85)
    maxLevelBox:SetBackdropBorderColor(0.2, 0.2, 0.35, 0.7)
    maxLevelBox:SetTextInsets(6, 0, 0, 0)
    maxLevelBox:SetFont(GetLSMFont(fontName), 11)
    maxLevelBox:SetTextColor(1, 1, 1, 1)
    maxLevelBox:SetText(tostring(db.maxLevel or 70))
    maxLevelBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText():trim()
        local value = tonumber(text)
        if value and value >= 1 and value <= 70 then
            db.maxLevel = value
            print("|cff00ccff[GuildGrowInvite]|r Max level set to " .. value)
        else
            print("|cffff0000[GuildGrowInvite]|r Invalid level. Enter 1-70.")
        end
        self:ClearFocus()
    end)

    local guildFilterCheck = CreateStyledCheckbox("Skip players already in a guild", "filterGuildedPlayers", true, maxLevelBox, "TOPLEFT", -200, -16)

    guildFilterCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Skip Guilded Players", 1, 1, 1)
        GameTooltip:AddLine("When enabled, the addon will skip players", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("who are already a member of any guild.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Uses a cache to remember guilded players", 0.6, 0.6, 0.8)
        GameTooltip:AddLine("even after they leave your range.", 0.6, 0.6, 0.8)
        GameTooltip:Show()
    end)
    guildFilterCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local checkboxTooltips = {
        [scanCheck] = {"Chat-Scan Candidate List", "Build a candidate list from public chat messages.", "When enabled, every player who speaks in a", "tracked channel gets added to the candidate list", "for you to manually review and invite."},
        [chatAutoInviteCheck] = {"Auto-Invite from Chat", "Automatically invite players who speak in public channels.", "Works for every message in tracked channels.", "Use with caution as this is very aggressive."},
        [nearAutoInviteCheck] = {"Auto-Invite Nearby Players", "Automatically invite nearby players.", "Scans nameplates, party, raid, target,", "and mouseover units for potential recruits."},
        [lfgAutoInviteCheck] = {"LFG Auto-Invite", "Invite players who use LFG-related keywords.", "Works in both whispers and public chat.", "Includes terms like 'lfg', 'looking for', 'guild', etc."},
        [snoopCheck] = {"Snoop Nearby Players", "Aggressively scan nearby players.", "Enables high-frequency nameplate scanning", "to find potential recruits faster."},
        [levelFilterCheck] = {"Level Range Filter", "Only invite players within a specific level range.", "Useful if you want to target leveling players", "or max-level players specifically."},
    }

    for cb, info in pairs(checkboxTooltips) do
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(info[1], 1, 1, 1)
            for i = 2, #info do
                GameTooltip:AddLine(info[i], 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    local _, qaDivider = CreateSectionHeader(frame, "QUICK ACTIONS", guildFilterCheck, -96)

    local function CreateStyledButton(text, anchor, yOff)
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetSize(210, 28)
        btn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 18, yOff)
        btn:SetText(text)
        return btn
    end

    local blacklistBtn = CreateStyledButton("Blacklist Manager", qaDivider, -8)
    blacklistBtn:SetScript("OnClick", function()
        GGI.ToggleBlacklistWindow()
    end)

    local messageBtn = CreateStyledButton("Message Manager", blacklistBtn, -4)
    messageBtn:SetScript("OnClick", function()
        GGI.ToggleMessagesWindow()
    end)

    frame:Hide()
    return frame
end

local messageWindow = nil
local messageButtons = {}

function GGI.ToggleMessagesWindow()
    if not messageWindow then
        GGI.CreateMessagesWindow()
    end

    if messageWindow:IsShown() then
        messageWindow:Hide()
    else
        GGI.RefreshMessagesList()
        if GGI.GetSelectedMessage then
            messageWindow.selectedText:SetText(GGI.GetSelectedMessage())
        end
        messageWindow:Show()
    end
end

function GGI.CreateMessagesWindow()
    if messageWindow then return end

    local frame = CreateFrame("Frame", "GuildGrowInviteMessagesFrame", UIParent)
    frame:SetSize(520, 420)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = GetLSMBG(bgName),
        edgeFile = GetLSMBorder(borderName),
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    frame:SetBackdropColor(0.04, 0.04, 0.08, 0.96)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.65, 0.85)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    frame:Hide()
    messageWindow = frame

    local titleBar = frame:CreateTexture(nil, "ARTWORK")
    titleBar:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBar:SetSize(490, 36)
    titleBar:SetPoint("TOP", frame, "TOP", 0, -6)
    titleBar:SetVertexColor(0.28, 0.28, 0.58, 0.9)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetFont(GetLSMFont(fontName), 15)
    title:SetPoint("TOP", titleBar, "TOP", 0, -9)
    title:SetText("Message Manager")
    title:SetTextColor(0.85, 0.85, 1, 1)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    local addLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addLabel:SetFont(GetLSMFont(fontName), 11)
    addLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -48)
    addLabel:SetText("Add new message:")
    addLabel:SetTextColor(0.65, 0.65, 0.8, 1)

    local addBox = CreateFrame("EditBox", nil, frame)
    addBox:SetAutoFocus(false)
    addBox:SetSize(385, 26)
    addBox:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -6)
    addBox:SetBackdrop({
        bgFile = GetLSMBG(bgName),
        edgeFile = GetLSMBorder(borderName),
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    addBox:SetBackdropColor(0.06, 0.06, 0.1, 0.85)
    addBox:SetBackdropBorderColor(0.2, 0.2, 0.35, 0.7)
    addBox:SetTextInsets(6, 0, 0, 0)
    addBox:SetFont(GetLSMFont(fontName), 11)
    addBox:SetTextColor(1, 1, 1, 1)
    addBox:SetText("")

    local addBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    addBtn:SetSize(80, 26)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)
    addBtn:SetText("Add")
    local addBtnText = addBtn.GetFontString and addBtn:GetFontString()
    if not addBtnText and addBtn.GetRegions then
        for _, r in ipairs({addBtn:GetRegions()}) do
            if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                addBtnText = r
                break
            end
        end
    end
    if addBtnText then addBtnText:SetFont(GetLSMFont(fontName), 11) end
    addBtn:SetScript("OnClick", function()
        local text = addBox:GetText()
        if text and text ~= "" then
            GGI.AddCustomMessage(text)
            addBox:SetText("")
            GGI.RefreshMessagesList()
        end
    end)

    local listLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    listLabel:SetFont(GetLSMFont(fontName), 11)
    listLabel:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -15)
    listLabel:SetText("Messages:")
    listLabel:SetTextColor(0.65, 0.65, 0.8, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(490, 180)
    scrollFrame:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -6)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(490, 180)
    scrollContent:SetBackdrop({
        bgFile = GetLSMBG(bgName),
        tile = true, tileSize = 16,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    scrollContent:SetBackdropColor(0.02, 0.02, 0.05, 0.4)
    scrollFrame:SetScrollChild(scrollContent)

    local randomizeCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    randomizeCheck:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -15)
    randomizeCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Randomize messages", 1, 1, 1)
        GameTooltip:AddLine("Send a different message each time", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    randomizeCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    randomizeCheck:SetScript("OnClick", function(self)
        GGI.db.randomizeMessages = self:GetChecked()
    end)

    local randomizeText = randomizeCheck:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    randomizeText:SetFont(GetLSMFont(fontName), 11)
    randomizeText:SetPoint("LEFT", randomizeCheck, "RIGHT", 5, 0)
    randomizeText:SetText("Randomize messages")
    randomizeText:SetTextColor(0.85, 0.85, 0.92, 1)

    local selectedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    selectedLabel:SetFont(GetLSMFont(fontName), 11)
    selectedLabel:SetPoint("TOPLEFT", randomizeCheck, "BOTTOMLEFT", 0, -15)
    selectedLabel:SetText("Currently selected:")
    selectedLabel:SetTextColor(0.65, 0.65, 0.8, 1)

    local selectedText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    selectedText:SetFont(GetLSMFont(fontName), 10)
    selectedText:SetPoint("TOPLEFT", selectedLabel, "BOTTOMLEFT", 0, -5)
    selectedText:SetSize(470, 40)
    selectedText:SetWordWrap(true)
    selectedText:SetText("Loading...")
    selectedText:SetTextColor(0.6, 0.6, 0.75, 1)

    frame.scrollContent = scrollContent
    frame.selectedText = selectedText
    frame.randomizeCheck = randomizeCheck

    if GGI.db and GGI.db.randomizeMessages then
        randomizeCheck:SetChecked(GGI.db.randomizeMessages)
    end
end

function GGI.RefreshMessagesList()
    if not messageWindow then return end

    local allMessages = GGI.GetAllMessages()
    local db = GGI.db
    local selectedIndex = db.selectedMessageIndex or 1
    local scrollContent = messageWindow.scrollContent

    for _, btn in ipairs(messageButtons) do
        btn:Hide()
    end
    messageButtons = {}

    local yOffset = 0
    for i, msg in ipairs(allMessages) do
        local displayMsg = msg
        if string.len(msg) > 55 then
            displayMsg = string.sub(msg, 1, 55) .. "..."
        end

        local isDefault = i <= #GGI.DefaultMessages
        local prefix = isDefault and "[D] " or "[C] "

        local btn = CreateFrame("Button", nil, scrollContent)
        btn:SetSize(465, 22)
        btn:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 10, -yOffset)

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.12, 0.12, 0.22, 0.5)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0, 0, 0, 0)
        end)
        btn:SetBackdrop({
            bgFile = GetLSMBG(bgName),
            tile = true, tileSize = 16,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(0, 0, 0, 0)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetFont(GetLSMFont(fontName), 10)
        text:SetPoint("LEFT", btn, "LEFT", 5, 0)
        text:SetText(prefix .. displayMsg)

        if i == selectedIndex then
            text:SetTextColor(0.3, 1, 0.3, 1)
        else
            text:SetTextColor(0.8, 0.8, 0.9, 1)
        end

        btn:SetScript("OnClick", function()
            GGI.SetSelectedMessage(i)
            GGI.RefreshMessagesList()
            messageWindow.selectedText:SetText(allMessages[i])
        end)

        if not isDefault then
            local customIndex = i - #GGI.DefaultMessages
            local removeBtn = CreateFrame("Button", nil, btn)
            removeBtn:SetSize(16, 16)
            removeBtn:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
            removeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
            removeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
            removeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
            removeBtn:SetScript("OnClick", function()
                GGI.RemoveCustomMessage(customIndex)
                GGI.RefreshMessagesList()
                messageWindow.selectedText:SetText(GGI.GetSelectedMessage())
            end)
        end

        table.insert(messageButtons, btn)
        yOffset = yOffset + 24
    end

    scrollContent:SetHeight(yOffset)
end

function GGI.ToggleUI()
    local f = BuildFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end

local mapButtonEvent = CreateFrame("Frame")
mapButtonEvent:RegisterEvent("ADDON_LOADED")
mapButtonEvent:SetScript("OnEvent", function(self, event)
    if event == "ADDON_LOADED" then
        self:RegisterEvent("WORLD_MAP_OPEN")
    elseif event == "WORLD_MAP_OPEN" then
        CreateMapButton()
    end
end)
