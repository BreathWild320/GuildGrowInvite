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

local function GetGuildStatus(name)
    if not name then return "unknown" end
    if GGI.IsInMyGuild(name) then return "mine" end
    if GGI.IsGuilded(name) then return "other" end
    return "none"
end

local function SetBtnFont(btn, font, size)
    local text = btn.GetFontString and btn:GetFontString()
    if not text and btn.GetRegions then
        for _, r in ipairs({btn:GetRegions()}) do
            if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                text = r
                break
            end
        end
    end
    if text then
        text:SetFont(font, size)
    end
end

local function CreateCandidatesFrame()
    if candidatesFrame then return candidatesFrame end

    candidatesFrame = CreateFrame("Frame", "GuildGrowInviteCandidatesFrame", UIParent)
    candidatesFrame:SetSize(680, 740)
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
    candidatesFrame:SetBackdropColor(0.03, 0.05, 0.1, 0.97)
    candidatesFrame:SetBackdropBorderColor(0.3, 0.5, 0.95, 0.9)

    local titleBg = candidatesFrame:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture(statusbarFile)
    titleBg:SetSize(640, 38)
    titleBg:SetPoint("TOP", candidatesFrame, "TOP", 0, -6)
    titleBg:SetVertexColor(0.15, 0.35, 0.75, 0.95)

    local title = candidatesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(fontFile, 16)
    title:SetPoint("TOP", titleBg, "TOP", 0, -10)
    title:SetText("Recruitment Candidates")
    title:SetTextColor(1, 1, 1, 1)

    candidatesFrame.closeBtn = CreateFrame("Button", nil, candidatesFrame, "UIPanelCloseButton")
    candidatesFrame.closeBtn:SetPoint("TOPRIGHT", candidatesFrame, "TOPRIGHT", -5, -5)
    candidatesFrame.closeBtn:SetScript("OnClick", function() candidatesFrame:Hide() end)

    local categoryLabel = candidatesFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    categoryLabel:SetFont(fontFile, 11)
    categoryLabel:SetPoint("TOPLEFT", candidatesFrame, "TOPLEFT", 20, -54)
    categoryLabel:SetText("Filter:")
    categoryLabel:SetTextColor(0.55, 0.55, 0.8, 1)

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
        local bText = (btn.GetFontString and btn:GetFontString()) or _G[btn:GetName() .. "Text"]
        if bText then
            bText:SetFont(fontFile, 9)
            bText:SetText(category)
        end
        btn.category = category
        btn:SetChecked(GGI.db.selectedCategory == category)
        btn:SetScript("OnClick", function(self)
            SetCategory(self.category)
        end)
        categoryButtons[#categoryButtons + 1] = btn
    end

    candidatesFrame.listFrame = CreateFrame("ScrollFrame", "GuildGrowInviteCandidatesScrollFrame", candidatesFrame, "FauxScrollFrameTemplate")
    candidatesFrame.listFrame:SetSize(590, 400)
    candidatesFrame.listFrame:SetPoint("TOPLEFT", candidatesFrame, "TOPLEFT", 20, -100)

    candidatesFrame.scrollChild = CreateFrame("Frame")
    candidatesFrame.scrollChild:SetSize(590, 400)
    candidatesFrame.listFrame:SetScrollChild(candidatesFrame.scrollChild)

    candidatesFrame.listFrame:SetBackdrop({
        bgFile = bgFile,
        edgeFile = borderFile,
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    candidatesFrame.listFrame:SetBackdropColor(0, 0, 0, 0.35)
    candidatesFrame.listFrame:SetBackdropBorderColor(0.2, 0.2, 0.4, 0.6)

    local colHeaders = {"Name", "Channel", "Message", "Guild"}
    local colX = {8, 122, 188, 400}
    local colW = {110, 60, 210, 70}
    for i = 1, 4 do
        local h = candidatesFrame.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        h:SetFont(fontFile, 10)
        h:SetPoint("TOPLEFT", candidatesFrame.scrollChild, "TOPLEFT", colX[i], -12)
        h:SetWidth(colW[i])
        h:SetJustifyH("LEFT")
        h:SetText(colHeaders[i])
        h:SetTextColor(0.5, 0.55, 0.85, 1)
    end

    candidatesFrame.emptyText = candidatesFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    candidatesFrame.emptyText:SetPoint("CENTER", candidatesFrame.listFrame, "CENTER")
    candidatesFrame.emptyText:SetWidth(420)
    candidatesFrame.emptyText:SetWordWrap(true)
    candidatesFrame.emptyText:SetText("No candidates. Enable chat-scan to find players.")
    candidatesFrame.emptyText:Hide()

    local bottomBtn1 = CreateFrame("Button", nil, candidatesFrame, "UIPanelButtonTemplate")
    bottomBtn1:SetSize(120, 22)
    bottomBtn1:SetPoint("BOTTOMLEFT", candidatesFrame, "BOTTOMLEFT", 25, 14)
    bottomBtn1:SetText("Blacklist Manager")
    SetBtnFont(bottomBtn1, fontFile, 10)
    bottomBtn1:SetScript("OnClick", function()
        GGI.ToggleBlacklistWindow()
    end)

    local bottomBtn2 = CreateFrame("Button", nil, candidatesFrame, "UIPanelButtonTemplate")
    bottomBtn2:SetSize(80, 22)
    bottomBtn2:SetPoint("LEFT", bottomBtn1, "RIGHT", 10, 0)
    bottomBtn2:SetText("Refresh")
    SetBtnFont(bottomBtn2, fontFile, 10)
    bottomBtn2:SetScript("OnClick", function()
        GGI.ClearGuildedCache()
        GGI.RefreshCandidatesList()
    end)

    local bottomBtn3 = CreateFrame("Button", nil, candidatesFrame, "UIPanelButtonTemplate")
    bottomBtn3:SetSize(100, 22)
    bottomBtn3:SetPoint("BOTTOMRIGHT", candidatesFrame, "BOTTOMRIGHT", -25, 14)
    bottomBtn3:SetText("Close")
    SetBtnFont(bottomBtn3, fontFile, 10)
    bottomBtn3:SetScript("OnClick", function()
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
            if not (db.filterGuildedPlayers and GGI.IsGuilded(entry.name)) then
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
        row:SetSize(570, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", candidatesFrame.scrollChild, "TOPLEFT", 8, yOffset)

        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.28, 0.5)
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(i % 2 == 0 and 0.06 or 0, i % 2 == 0 and 0.06 or 0, i % 2 == 0 and 0.1 or 0, i % 2 == 0 and 0.4 or 0)
        end)
        row:SetBackdrop({
            bgFile = bgFile,
            tile = true, tileSize = 16,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        local rowColor = i % 2 == 0 and 0.06 or 0
        row:SetBackdropColor(rowColor, rowColor, i % 2 == 0 and 0.1 or 0, i % 2 == 0 and 0.4 or 0)

        local nameText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        nameText:SetFont(fontFile, 11)
        nameText:SetPoint("LEFT", row, "LEFT", 6, 0)
        nameText:SetWidth(110)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(entry.name)
        nameText:SetTextColor(0.9, 0.9, 1, 1)

        local channelText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        channelText:SetFont(fontFile, 10)
        channelText:SetPoint("LEFT", nameText, "RIGHT", 4, 0)
        channelText:SetWidth(60)
        channelText:SetJustifyH("LEFT")
        channelText:SetText("[" .. (entry.channel or "?") .. "]")
        channelText:SetTextColor(0.45, 0.65, 1, 1)

        local infoText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        infoText:SetFont(fontFile, 10)
        infoText:SetPoint("LEFT", channelText, "RIGHT", 6, 0)
        infoText:SetWidth(200)
        infoText:SetJustifyH("LEFT")
        infoText:SetText(entry.msg or "")
        infoText:SetTextColor(0.6, 0.6, 0.7, 1)

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

        local entryName = entry.name

        local inviteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        inviteBtn:SetSize(52, 18)
        inviteBtn:SetPoint("RIGHT", row, "RIGHT", -56, 0)
        inviteBtn:SetText("Invite")
        SetBtnFont(inviteBtn, fontFile, 9)
        inviteBtn:SetScript("OnClick", function()
            GGI.InviteName(entryName, "UI candidate list")
            GGI.ClearGuildedCache()
            GGI.RefreshCandidatesList()
        end)

        local blockBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        blockBtn:SetSize(42, 18)
        blockBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        blockBtn:SetText("Block")
        SetBtnFont(blockBtn, fontFile, 9)
        blockBtn:SetScript("OnClick", function()
            GGI.AddToBlacklist(entryName)
            GGI.ClearGuildedCache()
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
        GGI.ClearGuildedCache()
        frame:Show()
        GGI.RefreshCandidatesList()
    end
end
