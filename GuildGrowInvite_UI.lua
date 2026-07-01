local GGI = GuildGrowInvite

-- Load LibSharedMedia-3.0 if available (LoadOnDemand: 1)
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

------------------------------------------------------------
-- Main UI
------------------------------------------------------------
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

------------------------------------------------------------
-- Build the frame
------------------------------------------------------------
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
    frame:SetBackdropColor(0.06, 0.06, 0.1, 0.95)

    frame.titleBg = frame:CreateTexture(nil, "ARTWORK")
    frame.titleBg:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\DialogFrame\\UI-DialogBox-Header")
    frame.titleBg:SetSize(400, 40)
    frame.titleBg:SetPoint("TOP", frame, "TOP", 0, -8)
    frame.titleBg:SetVertexColor(0.3, 0.3, 0.6, 0.8)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetFont(GetLSMFont(fontName), 16)
    frame.title:SetPoint("TOP", frame.titleBg, "TOP", 0, -10)
    frame.title:SetText("GuildGrowInvite")
    frame.title:SetTextColor(0.8, 0.8, 1, 1)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetFont(GetLSMFont(fontName), 11)
    subtitle:SetPoint("TOP", frame.title, "BOTTOM", 0, -2)
    subtitle:SetText("Auto-Recruitment Manager")
    subtitle:SetTextColor(0.5, 0.5, 0.7, 1)

    frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local db = GGI.db

    ------------------------------------------------------------
    -- Settings section
    ------------------------------------------------------------
    local settingsLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    settingsLabel:SetFont(GetLSMFont(fontName), 12)
    settingsLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -70)
    settingsLabel:SetText("SETTINGS")
    settingsLabel:SetTextColor(0.6, 0.6, 0.9, 1)

    local divider1 = frame:CreateTexture(nil, "ARTWORK")
    divider1:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\Tooltips\\UI-Tooltip-Border")
    divider1:SetSize(460, 2)
    divider1:SetPoint("TOPLEFT", settingsLabel, "BOTTOMLEFT", 0, -6)
    divider1:SetVertexColor(0.3, 0.3, 0.5, 0.6)

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
        label:SetTextColor(0.85, 0.85, 0.9, 1)
        return cb
    end

    local scanCheck = CreateStyledCheckbox("Chat-scan candidate list enabled", "scanEnabled", true, frame, "TOPLEFT", 24, -96)
    local chatAutoInviteCheck = CreateStyledCheckbox("Auto-invite from any tracked chat message", "chatAutoInviteEnabled", true, scanCheck, "TOPLEFT", 0, -24)
    local nearAutoInviteCheck = CreateStyledCheckbox("Auto-invite nearby players", "nearAutoInviteEnabled", true, chatAutoInviteCheck, "TOPLEFT", 0, -24)
    local lfgAutoInviteCheck = CreateStyledCheckbox("Auto-invite LFG whispers/chat (aggressive)", "lfgAutoInviteEnabled", true, nearAutoInviteCheck, "TOPLEFT", 0, -24)
    local snoopCheck = CreateStyledCheckbox("Snoop nearby players (aggressive scanning)", "snoopEnabled", true, lfgAutoInviteCheck, "TOPLEFT", 0, -24)

    -- Level filter section
    local levelFilterCheck = CreateStyledCheckbox("Enable level range filter", "levelFilterEnabled", false, snoopCheck, "TOPLEFT", 0, -28)

    local minLevelLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    minLevelLabel:SetFont(GetLSMFont(fontName), 11)
    minLevelLabel:SetPoint("TOPLEFT", levelFilterCheck, "BOTTOMLEFT", 20, -10)
    minLevelLabel:SetText("Min level:")
    minLevelLabel:SetTextColor(0.7, 0.7, 0.8, 1)

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
    minLevelBox:SetBackdropColor(0.08, 0.08, 0.12, 0.8)
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
    maxLevelLabel:SetTextColor(0.7, 0.7, 0.8, 1)

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
    maxLevelBox:SetBackdropColor(0.08, 0.08, 0.12, 0.8)
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

    ------------------------------------------------------------
    -- Quick Actions
    ------------------------------------------------------------
    local actionLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    actionLabel:SetFont(GetLSMFont(fontName), 12)
    actionLabel:SetPoint("TOPLEFT", maxLevelBox, "BOTTOMLEFT", -200, -16)
    actionLabel:SetText("QUICK ACTIONS")
    actionLabel:SetTextColor(0.6, 0.6, 0.9, 1)

    local divider2 = frame:CreateTexture(nil, "ARTWORK")
    divider2:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\Tooltips\\UI-Tooltip-Border")
    divider2:SetSize(460, 2)
    divider2:SetPoint("TOPLEFT", actionLabel, "BOTTOMLEFT", 0, -6)
    divider2:SetVertexColor(0.3, 0.3, 0.5, 0.6)

    local function CreateStyledButton(text, anchor, yOff)
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetSize(220, 28)
        btn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff)
        btn:SetText(text)
        return btn
    end

    local blacklistBtn = CreateStyledButton("Blacklist Manager", divider2, -6)
    blacklistBtn:SetScript("OnClick", function()
        GGI.ToggleBlacklistWindow()
    end)

    local messageBtn = CreateStyledButton("Message Manager", blacklistBtn, -6)
    messageBtn:SetScript("OnClick", function()
        GGI.ToggleMessagesWindow()
    end)

    -- Stats display
    local divider3 = frame:CreateTexture(nil, "ARTWORK")
    divider3:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\Tooltips\\UI-Tooltip-Border")
    divider3:SetSize(460, 2)
    divider3:SetPoint("TOPLEFT", messageBtn, "BOTTOMLEFT", 0, -10)
    divider3:SetVertexColor(0.3, 0.3, 0.5, 0.6)

    local statsLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    statsLabel:SetFont(GetLSMFont(fontName), 12)
    statsLabel:SetPoint("TOPLEFT", divider3, "BOTTOMLEFT", 0, -8)
    statsLabel:SetText("STATS")
    statsLabel:SetTextColor(0.6, 0.6, 0.9, 1)

    local statsText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    statsText:SetFont(GetLSMFont(fontName), 11)
    statsText:SetPoint("TOPLEFT", statsLabel, "BOTTOMLEFT", 0, -8)
    statsText:SetText("Total messages available: " .. #GGI.GetAllMessages())
    statsText:SetTextColor(0.6, 0.6, 0.7, 1)

    frame:Hide()
    return frame
end

------------------------------------------------------------
-- Message Manager Window
------------------------------------------------------------
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
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = GetLSMBG(bgName),
        edgeFile = GetLSMBorder(borderName),
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    frame:SetBackdropColor(0.06, 0.06, 0.1, 0.95)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    frame:Hide()
    messageWindow = frame

    -- Title bg bar
    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture(GetLSMStatusbar(statusbarName) or "Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetSize(380, 30)
    titleBg:SetPoint("TOP", frame, "TOP", 0, -6)
    titleBg:SetVertexColor(0.3, 0.3, 0.6, 0.8)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetFont(GetLSMFont(fontName), 14)
    title:SetPoint("TOP", titleBg, "TOP", 0, -7)
    title:SetText("Message Manager")
    title:SetTextColor(0.8, 0.8, 1, 1)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    -- Add new message
    local addLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addLabel:SetFont(GetLSMFont(fontName), 11)
    addLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -42)
    addLabel:SetText("Add new message:")
    addLabel:SetTextColor(0.7, 0.7, 0.8, 1)

    local addBox = CreateFrame("EditBox", nil, frame)
    addBox:SetAutoFocus(false)
    addBox:SetSize(365, 26)
    addBox:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -6)
    addBox:SetBackdrop({
        bgFile = GetLSMBG(bgName),
        edgeFile = GetLSMBorder(borderName),
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    addBox:SetBackdropColor(0.08, 0.08, 0.12, 0.8)
    addBox:SetTextInsets(6, 0, 0, 0)
    addBox:SetFont(GetLSMFont(fontName), 11)
    addBox:SetTextColor(1, 1, 1, 1)
    addBox:SetText("")

    local addBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    addBtn:SetSize(80, 26)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", function()
        local text = addBox:GetText()
        if text and text ~= "" then
            GGI.AddCustomMessage(text)
            addBox:SetText("")
            GGI.RefreshMessagesList()
        end
    end)

    -- Messages list label
    local listLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    listLabel:SetFont(GetLSMFont(fontName), 11)
    listLabel:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -15)
    listLabel:SetText("Messages:")
    listLabel:SetTextColor(0.7, 0.7, 0.8, 1)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(470, 180)
    scrollFrame:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -6)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(470, 180)
    scrollFrame:SetScrollChild(scrollContent)

    -- Randomize checkbox
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
    randomizeText:SetTextColor(0.85, 0.85, 0.9, 1)

    -- Selected message display
    local selectedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    selectedLabel:SetFont(GetLSMFont(fontName), 11)
    selectedLabel:SetPoint("TOPLEFT", randomizeCheck, "BOTTOMLEFT", 0, -15)
    selectedLabel:SetText("Currently selected:")
    selectedLabel:SetTextColor(0.7, 0.7, 0.8, 1)

    local selectedText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    selectedText:SetFont(GetLSMFont(fontName), 10)
    selectedText:SetPoint("TOPLEFT", selectedLabel, "BOTTOMLEFT", 0, -5)
    selectedText:SetSize(460, 40)
    selectedText:SetWordWrap(true)
    selectedText:SetText("Loading...")
    selectedText:SetTextColor(0.6, 0.6, 0.7, 1)

    -- Store references
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
        btn:SetSize(445, 22)
        btn:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 10, -yOffset)

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

------------------------------------------------------------
-- Public toggle
------------------------------------------------------------
function GGI.ToggleUI()
    local f = BuildFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end

------------------------------------------------------------
-- Map button initialization
------------------------------------------------------------
local mapButtonEvent = CreateFrame("Frame")
mapButtonEvent:RegisterEvent("ADDON_LOADED")
mapButtonEvent:SetScript("OnEvent", function(self, event)
    if event == "ADDON_LOADED" then
        self:RegisterEvent("WORLD_MAP_OPEN")
    elseif event == "WORLD_MAP_OPEN" then
        CreateMapButton()
    end
end)
