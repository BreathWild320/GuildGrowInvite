------------------------------------------------------------
-- GuildGrowInvite Candidates List UI
------------------------------------------------------------

local GGI = GuildGrowInvite
local candidatesFrame = nil
local ROW_HEIGHT = 22

local function CreateCandidatesFrame()
    if candidatesFrame then return candidatesFrame end

    candidatesFrame = CreateFrame("Frame", "GuildGrowInviteCandidatesFrame", UIParent)
    candidatesFrame:SetSize(550, 600)
    candidatesFrame:SetPoint("CENTER")
    candidatesFrame:SetFrameStrata("DIALOG")
    candidatesFrame:SetMovable(true)
    candidatesFrame:EnableMouse(true)
    candidatesFrame:RegisterForDrag("LeftButton")
    candidatesFrame:SetScript("OnDragStart", candidatesFrame.StartMoving)
    candidatesFrame:SetScript("OnDragStop", candidatesFrame.StopMovingOrSizing)

    candidatesFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Title bar
    candidatesFrame.titleBg = candidatesFrame:CreateTexture(nil, "ARTWORK")
    candidatesFrame.titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    candidatesFrame.titleBg:SetSize(300, 64)
    candidatesFrame.titleBg:SetPoint("TOP", candidatesFrame, "TOP", 0, 12)

    candidatesFrame.title = candidatesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    candidatesFrame.title:SetPoint("TOP", candidatesFrame.titleBg, "TOP", 0, -14)
    candidatesFrame.title:SetText("Recruitment Candidates")

    candidatesFrame.closeBtn = CreateFrame("Button", nil, candidatesFrame, "UIPanelCloseButton")
    candidatesFrame.closeBtn:SetPoint("TOPRIGHT", candidatesFrame, "TOPRIGHT", -5, -5)
    candidatesFrame.closeBtn:SetScript("OnClick", function() candidatesFrame:Hide() end)

    -- Category buttons
    local categoryLabel = candidatesFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    categoryLabel:SetPoint("TOPLEFT", candidatesFrame, "TOPLEFT", 20, -45)
    categoryLabel:SetText("Filter:")

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
        local row = math.floor((i - 1) / 4)
        local col = (i - 1) % 4
        btn:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", col * 105, -4 - row * 20)
        _G[btn:GetName() .. "Text"]:SetFont("Fonts\\FRIZQT__.TTF", 9)
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
    candidatesFrame.listFrame:SetSize(480, 400)
    candidatesFrame.listFrame:SetPoint("TOPLEFT", candidatesFrame, "TOPLEFT", 20, -75)

    candidatesFrame.scrollChild = CreateFrame("Frame")
    candidatesFrame.scrollChild:SetSize(480, 400)
    candidatesFrame.listFrame:SetScrollChild(candidatesFrame.scrollChild)

    candidatesFrame.listFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    candidatesFrame.listFrame:SetBackdropColor(0, 0, 0, 0.3)

    -- Empty message
    candidatesFrame.emptyText = candidatesFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    candidatesFrame.emptyText:SetPoint("CENTER", candidatesFrame.listFrame, "CENTER")
    candidatesFrame.emptyText:SetWidth(420)
    candidatesFrame.emptyText:SetWordWrap(true)
    candidatesFrame.emptyText:SetText("No candidates. Enable chat-scan to find players.")
    candidatesFrame.emptyText:Hide()

    -- Buttons at bottom
    local inviteBtn = CreateFrame("Button", nil, candidatesFrame, "UIPanelButtonTemplate")
    inviteBtn:SetSize(100, 22)
    inviteBtn:SetPoint("BOTTOMLEFT", candidatesFrame, "BOTTOMLEFT", 16, 14)
    inviteBtn:SetText("Blacklist Manager")
    inviteBtn:SetScript("OnClick", function()
        GGI.ToggleBlacklistWindow()
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

    -- Clear previous rows from scroll child
    for _, child in ipairs({candidatesFrame.scrollChild:GetChildren()}) do
        child:Hide()
    end

    local category = db.selectedCategory or "All"
    local filtered = {}

    -- Filter candidates
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
            table.insert(filtered, entry)
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

    -- Calculate total height needed
    local totalHeight = #filtered * (ROW_HEIGHT + 2)
    candidatesFrame.scrollChild:SetHeight(totalHeight)

    local yOffset = -8
    for i, entry in ipairs(filtered) do
        local row = CreateFrame("Button", nil, candidatesFrame.scrollChild)
        row:SetSize(460, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", candidatesFrame.scrollChild, "TOPLEFT", 8, yOffset)

        -- Name (clickable to whisper)
        local nameText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT", row, "LEFT", 6, 0)
        nameText:SetWidth(120)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(entry.name)

        -- Channel and message info
        local infoText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        infoText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
        infoText:SetWidth(220)
        infoText:SetJustifyH("LEFT")
        infoText:SetText(("[%s] %s"):format(entry.channel, entry.msg or ""))

        -- Invite button
        local inviteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        inviteBtn:SetSize(50, 18)
        inviteBtn:SetPoint("RIGHT", row, "RIGHT", -48, 0)
        inviteBtn:SetText("Invite")

        local entryName = entry.name
        inviteBtn:SetScript("OnClick", function()
            GGI.InviteName(entryName, "UI candidate list")
            GGI.RefreshCandidatesList()
        end)

        -- Blacklist button
        local blacklistBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        blacklistBtn:SetSize(40, 18)
        blacklistBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        blacklistBtn:SetText("Block")

        blacklistBtn:SetScript("OnClick", function()
            GGI.AddToBlacklist(entryName)
            GGI.RefreshCandidatesList()
            print("|cff00ccff[GuildGrowInvite]|r Blocked " .. entryName)
        end)

        yOffset = yOffset - (ROW_HEIGHT + 2)
    end

    -- Update scrollbar
    FauxScrollFrame_Update(candidatesFrame.listFrame, #filtered, 18, ROW_HEIGHT + 2)
end

function GGI.ToggleCandidatesWindow()
    local frame = CreateCandidatesFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        GGI.RefreshCandidatesList()
    end
end
