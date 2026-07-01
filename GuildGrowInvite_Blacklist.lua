------------------------------------------------------------
-- GuildGrowInvite Blacklist Manager UI
------------------------------------------------------------

local GGI = GuildGrowInvite
local blacklistFrame = nil
local ROW_HEIGHT = 22

local function CreateBlacklistFrame()
    if blacklistFrame then return blacklistFrame end

    blacklistFrame = CreateFrame("Frame", "GuildGrowInviteBlacklistFrame", UIParent)
    blacklistFrame:SetSize(500, 550)
    blacklistFrame:SetPoint("CENTER")
    blacklistFrame:SetFrameStrata("DIALOG")
    blacklistFrame:SetMovable(true)
    blacklistFrame:EnableMouse(true)
    blacklistFrame:RegisterForDrag("LeftButton")
    blacklistFrame:SetScript("OnDragStart", blacklistFrame.StartMoving)
    blacklistFrame:SetScript("OnDragStop", blacklistFrame.StopMovingOrSizing)

    blacklistFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Title bar
    blacklistFrame.titleBg = blacklistFrame:CreateTexture(nil, "ARTWORK")
    blacklistFrame.titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    blacklistFrame.titleBg:SetSize(300, 64)
    blacklistFrame.titleBg:SetPoint("TOP", blacklistFrame, "TOP", 0, 12)

    blacklistFrame.title = blacklistFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    blacklistFrame.title:SetPoint("TOP", blacklistFrame.titleBg, "TOP", 0, -14)
    blacklistFrame.title:SetText("Blacklist Manager")

    blacklistFrame.closeBtn = CreateFrame("Button", nil, blacklistFrame, "UIPanelCloseButton")
    blacklistFrame.closeBtn:SetPoint("TOPRIGHT", blacklistFrame, "TOPRIGHT", -5, -5)
    blacklistFrame.closeBtn:SetScript("OnClick", function() blacklistFrame:Hide() end)

    -- List content area with scrollbar
    blacklistFrame.content = CreateFrame("ScrollFrame", "GuildGrowInviteBlacklistScrollFrame", blacklistFrame, "FauxScrollFrameTemplate")
    blacklistFrame.content:SetSize(430, 350)
    blacklistFrame.content:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 20, -55)

    blacklistFrame.scrollChild = CreateFrame("Frame")
    blacklistFrame.scrollChild:SetSize(430, 350)
    blacklistFrame.content:SetScrollChild(blacklistFrame.scrollChild)

    blacklistFrame.content:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    blacklistFrame.content:SetBackdropColor(0, 0, 0, 0.3)

    -- Empty message
    blacklistFrame.emptyText = blacklistFrame.content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    blacklistFrame.emptyText:SetPoint("CENTER", blacklistFrame.content, "CENTER")
    blacklistFrame.emptyText:SetWidth(380)
    blacklistFrame.emptyText:SetWordWrap(true)
    blacklistFrame.emptyText:SetText("No blacklisted players.")
    blacklistFrame.emptyText:Hide()

    -- Add to blacklist section
    local addLabel = blacklistFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    addLabel:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 20, -450)
    addLabel:SetText("Add to permanent blacklist:")

    blacklistFrame.addBox = CreateFrame("EditBox", nil, blacklistFrame)
    blacklistFrame.addBox:SetAutoFocus(false)
    blacklistFrame.addBox:SetSize(220, 22)
    blacklistFrame.addBox:SetPoint("LEFT", addLabel, "RIGHT", 10, 0)
    blacklistFrame.addBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    blacklistFrame.addBox:SetBackdropColor(0, 0, 0, 0.5)
    blacklistFrame.addBox:SetTextInsets(6, 0, 0, 0)
    blacklistFrame.addBox:SetFontObject("GameFontHighlightSmall")

    blacklistFrame.addBtn = CreateFrame("Button", nil, blacklistFrame, "UIPanelButtonTemplate")
    blacklistFrame.addBtn:SetSize(80, 22)
    blacklistFrame.addBtn:SetPoint("LEFT", blacklistFrame.addBox, "RIGHT", 8, 0)
    blacklistFrame.addBtn:SetText("Add")
    blacklistFrame.addBtn:SetScript("OnClick", function()
        local name = blacklistFrame.addBox:GetText():trim()
        if name ~= "" then
            GGI.AddToBlacklist(name)
            blacklistFrame.addBox:SetText("")
            GGI.RefreshBlacklist()
            print("|cff00ccff[GuildGrowInvite]|r Added " .. name .. " to blacklist.")
        end
    end)

    return blacklistFrame
end

function GGI.RefreshBlacklist()
    if not blacklistFrame or not blacklistFrame:IsShown() then return end

    local db = GGI.db
    if not db then return end

    -- Clear previous rows from scroll child
    for _, child in ipairs({blacklistFrame.scrollChild:GetChildren()}) do
        child:Hide()
    end

    GGI.CleanupAutoBlacklist()

    local all = {}

    -- Permanent blacklist
    for name in pairs(db.blacklist) do
        table.insert(all, { name = name, type = "Permanent", expiry = nil })
    end

    -- Temporary auto-blacklist
    local now = GetTime()
    for name, expiry in pairs(db.autoBlacklist) do
        if expiry > now then
            local remaining = math.floor(expiry - now)
            table.insert(all, { name = name, type = "Temp", expiry = remaining })
        end
    end

    table.sort(all, function(a, b) return a.name < b.name end)

    if #all == 0 then
        blacklistFrame.emptyText:Show()
        blacklistFrame.content:Hide()
        return
    else
        blacklistFrame.emptyText:Hide()
        blacklistFrame.content:Show()
    end

    -- Calculate total height needed
    local totalHeight = #all * (ROW_HEIGHT + 2)
    blacklistFrame.scrollChild:SetHeight(totalHeight)

    local yOffset = -8
    for i, entry in ipairs(all) do
        local row = CreateFrame("Button", nil, blacklistFrame.scrollChild)
        row:SetSize(410, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", blacklistFrame.scrollChild, "TOPLEFT", 8, yOffset)

        -- Name
        local nameText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT", row, "LEFT", 6, 0)
        nameText:SetWidth(150)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(entry.name)

        -- Type and expiry
        local infoText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        infoText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
        infoText:SetWidth(150)
        infoText:SetJustifyH("LEFT")

        if entry.type == "Permanent" then
            infoText:SetText("[Permanent]")
            infoText:SetTextColor(1, 0.5, 0)
        else
            infoText:SetText(("[Temp] Expires in %ds"):format(entry.expiry))
            infoText:SetTextColor(0.5, 1, 0.5)
        end

        -- Remove button
        local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        removeBtn:SetSize(40, 18)
        removeBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        removeBtn:SetText("Remove")

        local entryName = entry.name
        removeBtn:SetScript("OnClick", function()
            GGI.RemoveFromBlacklist(entryName)
            C_Timer.After(0.1, function()
                GGI.RefreshBlacklist()
            end)
            print("|cff00ccff[GuildGrowInvite]|r Removed " .. entryName .. " from blacklist.")
        end)

        yOffset = yOffset - (ROW_HEIGHT + 2)
    end

    -- Update scrollbar
    FauxScrollFrame_Update(blacklistFrame.content, #all, 16, ROW_HEIGHT + 2)
end

function GGI.ToggleBlacklistWindow()
    local frame = CreateBlacklistFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        GGI.RefreshBlacklist()
    end
end
