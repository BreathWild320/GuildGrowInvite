------------------------------------------------------------
-- GuildGrowInvite Candidates List UI
------------------------------------------------------------

local GGI = GuildGrowInvite

local LSM = LibStub("LibSharedMedia-3.0", true)
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
local function GetLSMFont(name)
    if LSM and LSM.Fetch and LSM:Fetch("font", name) then
        return LSM:Fetch("font", name)
    end
    return name
end

local bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
local borderFile = "Interface\\Tooltips\\UI-Tooltip-Border"
local statusbarFile = GetLSMStatusbar("Glamour") or "Interface\\Tooltips\\UI-Tooltip-Border"
local fontFile = GetLSMFont("Friz Quadrata TT") or "Fonts\\FRIZQT__.TTF"

local candidatesFrame = nil
local ROW_HEIGHT = 22

-- Cache guild status for candidates to avoid repeated lookups
local guildStatusCache = {}

local function GetGuildStatus(name)
    if not name then return "unknown" end
    if guildStatusCache[name] then return guildStatusCache[name] end
    if GGI.IsInMyGuild(name) then
        guildStatusCache[name] = "mine"
        return "mine"
    end
    if GGI.IsInAnyGuild(name) then
        guildStatusCache[name] = "other"
        return "other"
    end
    guildStatusCache[name] = "none"
    return "none"
end

local function ClearGuildCache()
    guildStatusCache = {}
end

local function CreateCandidatesFrame()
    if candidatesFrame then return candidatesFrame end

    candidatesFrame = CreateFrame("Frame", "GuildGrowInviteCandidatesFrame", UIParent)
    candidatesFrame:SetSize(620, 650)
    candidatesFrame:SetPoint("CENTER")
    candidatesFrame:SetFrameStrata("DIALOG")
    candidatesFrame:SetMovable(true)
    candidatesFrame:EnableMouse(true)
    candidatesFrame:RegisterForDrag("LeftButton")
    candidatesFrame:SetScript("OnDragStart", candidatesFrame.StartMoving)
    candidatesFrame:SetScript("OnDragStop", candidatesFrame.StopMovingOrSizing)

    candidatesFrame:SetBackdrop({
        bgFile = bgFile,
        edgeFile = borderFile,
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    candidatesFrame:SetBackdropColor(0.06, 0.06, 0.1, 0.95)
    candidatesFrame:SetBackdropBorderColor(0.3, 0.3, 0.5, 0.8)

    -- Title bar
    candidatesFrame.titleBg = candidatesFrame:CreateTexture(nil, "ARTWORK")
    candidatesFrame.titleBg:SetTexture(statusbarFile)
    candidatesFrame.titleBg:SetSize(560, 36)
    candidatesFrame.titleBg:SetPoint("TOP", candidatesFrame, "TOP", 0, -6)
    candidatesFrame.titleBg:SetVertexColor(0.3, 0.3, 0.6, 0.8)

    candidatesFrame.title = candidatesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    candidatesFrame.title:SetFont(fontFile, 14)
    candidatesFrame.title:SetPoint("TOP", candidatesFrame.titleBg, "TOP", 0, -9)
    candidatesFrame.title:SetText("Recruitment Candidates")
    candidatesFrame.title:SetTextColor(0.8, 0.8, 1, 1)

    candidatesFrame.closeBtn = CreateFrame("Button", nil, candidatesFrame, "UIPanelCloseButton")
    candidatesFrame.closeBtn:SetPoint("TOPRIGHT", candidatesFrame, "TOPRIGHT", -5, -5)
    candidatesFrame.closeBtn:SetScript("OnClick", function() candidatesFrame:Hide() end)

    -- Category buttons
    local categoryLabel = candidatesFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    categoryLabel:SetFont(fontFile, 11)
    categoryLabel:SetPoint("TOPLEFT", candidatesFrame, "TOPLEFT", 20, -50)
    categoryLabel:SetText("Filter:")
    categoryLabel:SetTextColor(0.6, 0.6, 0.9, 1)

    local categoryButtons = {}
    local categories = {"All", "Channel", "Say", "Yell", "Party", "Raid", "Instance", "Battleground", "Guild", "Officer"}
    local function SetCategory(category)
        GGI.db.selectedCategory = category
        for _, btn in ipairs(categoryButtons) do
            btn:SetChecked(btn.category == category)
        end
        GGI.RefreshCandidatesList()
    end

    for i, category in ipairs(categories) do
        local btn = CreateFrame("CheckButton", "GuildGrowInviteCandidateCategoryButton" .. i, candidatesFrame, "UICheckButtonTemplate")
        local row = math.floor((i - 1) / 5)
        local col = (i - 1) % 5
        btn:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", col * 105, -4 - row * 20)
        _G[btn:GetName() .. "Text"]:SetFont(fontFile, 9)
        _G[btn:GetName() .. "Text"]:SetText(category)
        btn.category = category
        btn:SetChecked(GGI.db.selectedCategory == category)
        btn:SetScript("OnClick", function(self)
            SetCategory(self.category)
        end)
        categoryButtons[#categoryButtons + 1] = btn
    end

    -- Candidates list frame with scrollbar
    candidatesFrame.listFrame = CreateFrame("ScrollFrame", "GuildGrowInviteCandidatesScrollFrame", candidatesFrame, "FauxScrollFrameTemplate")
    candidatesFrame.listFrame:SetSize(570, 400)
    candidatesFrame.listFrame:SetPoint("TOPLEFT", candidatesFrame, "TOPLEFT", 20, -95)

    candidatesFrame.scrollChild = CreateFrame("Frame")
    candidatesFrame.scrollChild:SetSize(570, 400)
    candidatesFrame.listFrame:SetScrollChild(candidatesFrame.scrollChild)

    candidatesFrame.listFrame:SetBackdrop({
        bgFile = bgFile,
        edgeFile = borderFile,
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    candidatesFrame.listFrame:SetBackdropColor(0, 0, 0, 0.3)
    candidatesFrame.listFrame:SetBackdropBorderColor(0.2, 0.2, 0.35, 0.6)

    -- Column headers
    local headerY = -12
    local function CreateColHeader(text, xOff, width)
        local h = candidatesFrame.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        h:SetFont(fontFile, 10)
        h:SetPoint("TOPLEFT", candidatesFrame.scrollChild, "TOPLEFT", xOff, headerY)
        h:SetWidth(width)
        h:SetJustifyH("LEFT")
        h:SetText(text)
        h:SetTextColor(0.5, 0.5, 0.8, 1)
        return h
    end

    CreateColHeader("Name", 8, 110)
    CreateColHeader("Channel", 118, 60)
    CreateColHeader("Message", 180, 210)
    CreateColHeader("Guild", 390, 80)

    -- Empty message
    candidatesFrame.emptyText = candidatesFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    candidatesFrame.emptyText:SetPoint("CENTER", candidatesFrame.listFrame, "CENTER")
    candidatesFrame.emptyText:SetWidth(420)
    candidatesFrame.emptyText:SetWordWrap(true)
    candidatesFrame.emptyText:SetText("No candidates. Enable chat-scan to find players.")
    candidatesFrame.emptyText:Hide()

    -- Bottom buttons
    local inviteBtn = CreateFrame("Button", nil, candidatesFrame, "UIPanelButtonTemplate")
    inviteBtn:SetSize(100, 22)
    inviteBtn:SetPoint("BOTTOMLEFT", candidatesFrame, "BOTTOMLEFT", 16, 14)
    inviteBtn:SetText("Blacklist Manager")
    inviteBtn:SetScript("OnClick", function()
        GGI.ToggleBlacklistWindow()
    end)

    local refreshBtn = CreateFrame("Button", nil, candidatesFrame, "UIPanelButtonTemplate")
    refreshBtn:SetSize(80, 22)
    refreshBtn:SetPoint("LEFT", inviteBtn, "RIGHT", 8, 0)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        ClearGuildCache()
        GGI.RefreshCandidatesList()
    end)

    local closeBtn = CreateFrame("Button", nil, candidatesFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 22)
    closeBtn:SetPoint("BOTTOMRIGHT", candidatesFrame, "BOTTOMRIGHT", -16, 14)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        candidatesFrame:Hide()
    end)

    return candidatesFrame
end

function GGI.RefreshCandidatesList()
    if not candidatesFrame or not candidatesFrame:IsShown() then return end

    local db = GGI.db
    if not db then return end

    for _, child in ipairs({candidatesFrame.scrollChild:GetChildren()}) do
        child:Hide()
    end

    local category = db.selectedCategory or "All"
    local filtered = {}

    local function CategoryMatches(entry, cat)
        if cat == "All" then return true end
        if cat == "Channel" then return entry.channel == "Channel" end
        if cat == "Say" then return entry.channel == "Say" end
        if cat == "Yell" then return entry.channel == "Yell" end
        if cat == "Party" then return entry.channel == "Party" or entry.channel == "Party Leader" end
        if cat == "Raid" then return entry.channel == "Raid" or entry.channel == "Raid Leader" end
        if cat == "Instance" then return entry.channel == "Instance" or entry.channel == "Instance Leader" end
        if cat == "Battleground" then return entry.channel == "Battleground" or entry.channel == "Battleground Leader" end
        if cat == "Guild" then return entry.channel == "Guild" end
        if cat == "Officer" then return entry.channel == "Officer" end
        return false
    end

    for _, entry in ipairs(db.candidateList) do
        if CategoryMatches(entry, category) and not GGI.IsBlacklisted(entry.name) then
            -- If filter is enabled, skip guilded players
            if not (db.filterGuildedPlayers and GetGuildStatus(entry.name) == "other") then
                table.insert(filtered, entry)
            end
        end
    end

    if #filtered == 0 then
        candidatesFrame.emptyText:Show()
        candidatesFrame.listFrame:Hide()
        return
    else
        candidatesFrame.emptyText:Hide()
        candidatesFrame.listFrame:Show()
    end

    local totalHeight = #filtered * (ROW_HEIGHT + 2)
    candidatesFrame.scrollChild:SetHeight(totalHeight)

    local yOffset = -28
    for i, entry in ipairs(filtered) do
        local row = CreateFrame("Button", nil, candidatesFrame.scrollChild)
        row:SetSize(550, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", candidatesFrame.scrollChild, "TOPLEFT", 8, yOffset)

        -- Row highlight on hover
        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.25, 0.5)
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0, 0, 0, 0)
        end)
        row:SetBackdrop({
            bgFile = bgFile,
            tile = true, tileSize = 16,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        row:SetBackdropColor(0, 0, 0, 0)

        -- Alternate row background
        if i % 2 == 0 then
            row:SetBackdropColor(0.08, 0.08, 0.12, 0.4)
        end

        -- Name (clickable to whisper)
        local nameText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        nameText:SetFont(fontFile, 11)
        nameText:SetPoint("LEFT", row, "LEFT", 6, 0)
        nameText:SetWidth(110)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(entry.name)
        nameText:SetTextColor(0.9, 0.9, 1, 1)

        -- Channel
        local channelText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        channelText:SetFont(fontFile, 10)
        channelText:SetPoint("LEFT", nameText, "RIGHT", 4, 0)
        channelText:SetWidth(60)
        channelText:SetJustifyH("LEFT")
        channelText:SetText("[" .. (entry.channel or "?") .. "]")
        channelText:SetTextColor(0.5, 0.7, 1, 1)

        -- Message
        local infoText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        infoText:SetFont(fontFile, 10)
        infoText:SetPoint("LEFT", channelText, "RIGHT", 6, 0)
        infoText:SetWidth(200)
        infoText:SetJustifyH("LEFT")
        infoText:SetText(entry.msg or "")
        infoText:SetTextColor(0.6, 0.6, 0.7, 1)

        -- Guild status
        local status = GetGuildStatus(entry.name)
        local guildText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        guildText:SetFont(fontFile, 10)
        guildText:SetPoint("LEFT", infoText, "RIGHT", 6, 0)
        guildText:SetWidth(70)
        guildText:SetJustifyH("LEFT")

        if status == "mine" then
            guildText:SetText("In Guild")
            guildText:SetTextColor(0.3, 1, 0.3, 1)
        elseif status == "other" then
            guildText:SetText("Guilded")
            guildText:SetTextColor(1, 0.6, 0.2, 1)
        elseif status == "none" then
            guildText:SetText("No Guild")
            guildText:SetTextColor(0.5, 0.5, 0.5, 1)
        else
            guildText:SetText("?")
            guildText:SetTextColor(0.4, 0.4, 0.4, 1)
        end

        -- Invite button
        local inviteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        inviteBtn:SetSize(50, 18)
        inviteBtn:SetPoint("RIGHT", row, "RIGHT", -52, 0)
        inviteBtn:SetText("Invite")

        local entryName = entry.name
        inviteBtn:SetScript("OnClick", function()
            GGI.InviteName(entryName, "UI candidate list")
            ClearGuildCache()
            GGI.RefreshCandidatesList()
        end)

        -- Blacklist button
        local blacklistBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        blacklistBtn:SetSize(40, 18)
        blacklistBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        blacklistBtn:SetText("Block")

        blacklistBtn:SetScript("OnClick", function()
            GGI.AddToBlacklist(entryName)
            ClearGuildCache()
            GGI.RefreshCandidatesList()
            print("|cff00ccff[GuildGrowInvite]|r Blocked " .. entryName)
        end)

        yOffset = yOffset - (ROW_HEIGHT + 2)
    end

    FauxScrollFrame_Update(candidatesFrame.listFrame, #filtered, 17, ROW_HEIGHT + 2)
end

function GGI.ToggleCandidatesWindow()
    local frame = CreateCandidatesFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        ClearGuildCache()
        frame:Show()
        GGI.RefreshCandidatesList()
    end
end
