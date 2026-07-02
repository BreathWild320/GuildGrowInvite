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

local blacklistFrame = nil
local ROW_HEIGHT = 22

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

local function CreateBlacklistFrame()
    if blacklistFrame then return blacklistFrame end

    blacklistFrame = CreateFrame("Frame", "GuildGrowInviteBlacklistFrame", UIParent)
    blacklistFrame:SetSize(580, 640)
    blacklistFrame:SetPoint("CENTER")
    blacklistFrame:SetFrameStrata("DIALOG")
    blacklistFrame:SetMovable(true)
    blacklistFrame:EnableMouse(true)
    blacklistFrame:RegisterForDrag("LeftButton")
    blacklistFrame:SetScript("OnDragStart", blacklistFrame.StartMoving)
    blacklistFrame:SetScript("OnDragStop", blacklistFrame.StopMovingOrSizing)

    blacklistFrame:SetBackdrop({
        bgFile = bgFile,
        edgeFile = borderFile,
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    blacklistFrame:SetBackdropColor(0.03, 0.05, 0.1, 0.97)
    blacklistFrame:SetBackdropBorderColor(0.3, 0.5, 0.95, 0.9)

    local titleBg = blacklistFrame:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture(statusbarFile)
    titleBg:SetSize(540, 38)
    titleBg:SetPoint("TOP", blacklistFrame, "TOP", 0, -6)
    titleBg:SetVertexColor(0.15, 0.35, 0.75, 0.95)

    local title = blacklistFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(fontFile, 16)
    title:SetPoint("TOP", titleBg, "TOP", 0, -10)
    title:SetText("Blacklist Manager")
    title:SetTextColor(1, 1, 1, 1)

    blacklistFrame.closeBtn = CreateFrame("Button", nil, blacklistFrame, "UIPanelCloseButton")
    blacklistFrame.closeBtn:SetPoint("TOPRIGHT", blacklistFrame, "TOPRIGHT", -5, -5)
    blacklistFrame.closeBtn:SetScript("OnClick", function() blacklistFrame:Hide() end)

    blacklistFrame.content = CreateFrame("ScrollFrame", "GuildGrowInviteBlacklistScrollFrame", blacklistFrame, "FauxScrollFrameTemplate")
    blacklistFrame.content:SetSize(520, 410)
    blacklistFrame.content:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 26, -62)

    blacklistFrame.scrollChild = CreateFrame("Frame")
    blacklistFrame.scrollChild:SetSize(520, 410)
    blacklistFrame.content:SetScrollChild(blacklistFrame.scrollChild)

    blacklistFrame.content:SetBackdrop({
        bgFile = bgFile,
        edgeFile = borderFile,
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    blacklistFrame.content:SetBackdropColor(0.02, 0.03, 0.08, 0.5)
    blacklistFrame.content:SetBackdropBorderColor(0.2, 0.35, 0.7, 0.6)

    local colH1 = blacklistFrame.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    colH1:SetFont(fontFile, 10)
    colH1:SetPoint("TOPLEFT", blacklistFrame.scrollChild, "TOPLEFT", 8, -8)
    colH1:SetText("Name")
    colH1:SetTextColor(0.5, 0.55, 0.85, 1)

    local colH2 = blacklistFrame.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    colH2:SetFont(fontFile, 10)
    colH2:SetPoint("LEFT", colH1, "RIGHT", 4, 0)
    colH2:SetText("Type / Expiry")
    colH2:SetTextColor(0.5, 0.55, 0.85, 1)

    blacklistFrame.emptyText = blacklistFrame.content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    blacklistFrame.emptyText:SetPoint("CENTER", blacklistFrame.content, "CENTER")
    blacklistFrame.emptyText:SetWidth(380)
    blacklistFrame.emptyText:SetWordWrap(true)
    blacklistFrame.emptyText:SetText("No blacklisted players.")
    blacklistFrame.emptyText:SetTextColor(0.6, 0.6, 0.75, 1)
    blacklistFrame.emptyText:Hide()

    local addLabel = blacklistFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    addLabel:SetFont(fontFile, 11)
    addLabel:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 26, -490)
    addLabel:SetText("Add to permanent blacklist:")
    addLabel:SetTextColor(0.75, 0.75, 0.85, 1)

    blacklistFrame.addBox = CreateFrame("EditBox", nil, blacklistFrame)
    blacklistFrame.addBox:SetAutoFocus(false)
    blacklistFrame.addBox:SetSize(280, 26)
    blacklistFrame.addBox:SetPoint("LEFT", addLabel, "RIGHT", 12, 0)
    blacklistFrame.addBox:SetBackdrop({
        bgFile = bgFile,
        edgeFile = borderFile,
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    blacklistFrame.addBox:SetBackdropColor(0.06, 0.06, 0.1, 0.85)
    blacklistFrame.addBox:SetBackdropBorderColor(0.2, 0.2, 0.35, 0.7)
    blacklistFrame.addBox:SetTextInsets(6, 0, 0, 0)
    blacklistFrame.addBox:SetFont(fontFile, 11)
    blacklistFrame.addBox:SetTextColor(1, 1, 1, 1)

    blacklistFrame.addBtn = CreateFrame("Button", nil, blacklistFrame, "UIPanelButtonTemplate")
    blacklistFrame.addBtn:SetSize(90, 26)
    blacklistFrame.addBtn:SetPoint("LEFT", blacklistFrame.addBox, "RIGHT", 8, 0)
    blacklistFrame.addBtn:SetText("Add")
    SetBtnFont(blacklistFrame.addBtn, fontFile, 10)
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

    for _, child in ipairs({blacklistFrame.scrollChild:GetChildren()}) do
        child:Hide()
    end

    GGI.CleanupAutoBlacklist()

    local all = {}

    for name in pairs(db.blacklist) do
        table.insert(all, { name = name, type = "Permanent", expiry = nil })
    end

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

    local totalHeight = #all * (ROW_HEIGHT + 2)
    blacklistFrame.scrollChild:SetHeight(totalHeight)

    local yOffset = -8
    for i, entry in ipairs(all) do
        local row = CreateFrame("Button", nil, blacklistFrame.scrollChild)
        row:SetSize(430, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", blacklistFrame.scrollChild, "TOPLEFT", 8, yOffset)

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
        nameText:SetWidth(150)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(entry.name)
        nameText:SetTextColor(0.9, 0.9, 1, 1)

        local infoText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        infoText:SetFont(fontFile, 10)
        infoText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
        infoText:SetWidth(180)
        infoText:SetJustifyH("LEFT")

        if entry.type == "Permanent" then
            infoText:SetText("[Permanent]")
            infoText:SetTextColor(1, 0.5, 0, 1)
        else
            local mins = math.floor(entry.expiry / 60)
            local secs = entry.expiry % 60
            infoText:SetText(("[Temp] %d:%02d remaining"):format(mins, secs))
            infoText:SetTextColor(0.5, 1, 0.5, 1)
        end

        local entryName = entry.name
        local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        removeBtn:SetSize(52, 18)
        removeBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        removeBtn:SetText("Remove")
        SetBtnFont(removeBtn, fontFile, 9)
        removeBtn:SetScript("OnClick", function()
            GGI.RemoveFromBlacklist(entryName)
            C_Timer.After(0.1, function()
                GGI.RefreshBlacklist()
            end)
            print("|cff00ccff[GuildGrowInvite]|r Removed " .. entryName .. " from blacklist.")
        end)

        yOffset = yOffset - (ROW_HEIGHT + 2)
    end

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
