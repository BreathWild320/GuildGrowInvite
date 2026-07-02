local GGI = GuildGrowInvite

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "GuildGrowInvite"
    panel:SetScript("OnShow", function(self)
        if self.initialized then return end
        self.initialized = true

        -- Title
        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("GuildGrowInvite Settings")
        title:SetTextColor(0.85, 0.85, 1, 1)

        local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        subtitle:SetText("Auto-Recruitment Manager for WoW 3.3.5")
        subtitle:SetTextColor(0.6, 0.6, 0.8, 1)

        local y = -60
        local function CreateCheckbox(text, key, defaultVal, tooltipText)
            local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 16, y)
            local label = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            label:SetPoint("LEFT", cb, "RIGHT", 8, 1)
            label:SetText(text)
            label:SetTextColor(0.85, 0.85, 0.92, 1)
            cb:SetChecked(GGI.db[key] or defaultVal)
            cb:SetScript("OnClick", function()
                GGI.db[key] = cb:GetChecked()
            end)
            if tooltipText then
                cb:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(text, 1, 1, 1)
                    GameTooltip:AddLine(tooltipText, 0.8, 0.8, 0.8)
                    GameTooltip:Show()
                end)
                cb:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end
            y = y - 28
            return cb
        end

        -- Recruitment Features Section
        local recruitmentHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        recruitmentHeader:SetPoint("TOPLEFT", 16, y)
        recruitmentHeader:SetText("RECRUITMENT FEATURES")
        recruitmentHeader:SetTextColor(0.35, 0.7, 1, 1)
        y = y - 24

        local scanCheck = CreateCheckbox("Build candidate list from chat", "scanEnabled", true, "Scan public messages to find recruits")
        local chatCheck = CreateCheckbox("Auto-invite from tracked chat", "chatAutoInviteEnabled", true, "Automatically invite players who speak in channels")
        local nearCheck = CreateCheckbox("Auto-invite nearby players", "nearAutoInviteEnabled", true, "Invite players near your character")
        local guildCheck = CreateCheckbox("Skip guilded players", "filterGuildedPlayers", true, "Ignore players already in guilds")
        local logCheck = CreateCheckbox("Log invites to chat", "debugLogging", true, "Show [GuildGrowInvite] messages in chat")

        y = y - 16
        -- Request Handling Section
        local requestHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        requestHeader:SetPoint("TOPLEFT", 16, y)
        requestHeader:SetText("REQUEST HANDLING")
        requestHeader:SetTextColor(0.35, 0.7, 1, 1)
        y = y - 24

        local duelCheck = CreateCheckbox("Auto-accept duel requests", "autoAcceptDuel", true, "Accept duels automatically")
        local tradeCheck = CreateCheckbox("Auto-accept trade requests", "autoAcceptTrade", true, "Accept trades automatically")
        local partyCheck = CreateCheckbox("Auto-accept party invites", "autoAcceptParty", false, "Accept party invites automatically")

        y = y - 16
        -- Aggression Level Section
        local aggHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        aggHeader:SetPoint("TOPLEFT", 16, y)
        aggHeader:SetText("INVITE AGGRESSION LEVEL")
        aggHeader:SetTextColor(0.35, 0.7, 1, 1)
        y = y - 24

        local aggLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        aggLabel:SetPoint("TOPLEFT", 16, y)
        aggLabel:SetText("Speed/Frequency (1-10):")
        aggLabel:SetTextColor(0.75, 0.75, 0.85, 1)
        y = y - 28

        local aggSlider = CreateFrame("Slider", nil, panel, "UISliderTemplate")
        aggSlider:SetPoint("TOPLEFT", 16, y)
        aggSlider:SetWidth(250)
        aggSlider:SetMinMaxValues(1, 10)
        aggSlider:SetValue(GGI.db.inviteAggression or 10)
        aggSlider:SetValueStep(1)
        aggSlider:SetObeyStepOnDrag(true)

        local aggValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        aggValue:SetPoint("LEFT", aggSlider, "RIGHT", 15, 0)
        aggValue:SetText(tostring(math.floor(aggSlider:GetValue())))
        aggValue:SetTextColor(0.3, 1, 0.3, 1)

        local aggHint = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        aggHint:SetPoint("TOPLEFT", 16, y - 26)
        aggHint:SetWidth(400)
        aggHint:SetWordWrap(true)
        aggHint:SetText("Higher values = faster scanning and more invites per cycle. (10 = maximum throughput)")
        aggHint:SetTextColor(0.6, 0.6, 0.75, 1)

        aggSlider:SetScript("OnValueChanged", function()
            local val = math.floor(aggSlider:GetValue())
            GGI.db.inviteAggression = val
            aggValue:SetText(tostring(val))
        end)

        y = y - 60
        -- Cooldown Section
        local cooldownHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cooldownHeader:SetPoint("TOPLEFT", 16, y)
        cooldownHeader:SetText("COOLDOWN SETTINGS")
        cooldownHeader:SetTextColor(0.35, 0.7, 1, 1)
        y = y - 24

        local cdLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cdLabel:SetPoint("TOPLEFT", 16, y)
        cdLabel:SetText("Per-player invite cooldown (seconds):")
        cdLabel:SetTextColor(0.75, 0.75, 0.85, 1)
        y = y - 28

        local cdSlider = CreateFrame("Slider", nil, panel, "UISliderTemplate")
        cdSlider:SetPoint("TOPLEFT", 16, y)
        cdSlider:SetWidth(250)
        cdSlider:SetMinMaxValues(15, 300)
        cdSlider:SetValue(GGI.db.inviteCooldown or 30)
        cdSlider:SetValueStep(5)

        local cdValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        cdValue:SetPoint("LEFT", cdSlider, "RIGHT", 15, 0)
        cdValue:SetText(tostring(math.floor(cdSlider:GetValue())) .. "s")
        cdValue:SetTextColor(0.3, 1, 0.3, 1)

        local cdHint = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cdHint:SetPoint("TOPLEFT", 16, y - 26)
        cdHint:SetWidth(400)
        cdHint:SetWordWrap(true)
        cdHint:SetText("Time to wait before inviting the same player again")
        cdHint:SetTextColor(0.6, 0.6, 0.75, 1)

        cdSlider:SetScript("OnValueChanged", function()
            local val = math.floor(cdSlider:GetValue())
            GGI.db.inviteCooldown = val
            cdValue:SetText(tostring(val) .. "s")
        end)

        y = y - 60
        -- Auto-Blacklist Section
        local blacklistHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        blacklistHeader:SetPoint("TOPLEFT", 16, y)
        blacklistHeader:SetText("AUTO-BLACKLIST")
        blacklistHeader:SetTextColor(0.35, 0.7, 1, 1)
        y = y - 24

        local blLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        blLabel:SetPoint("TOPLEFT", 16, y)
        blLabel:SetText("Blacklist duration (seconds):")
        blLabel:SetTextColor(0.75, 0.75, 0.85, 1)
        y = y - 28

        local blSlider = CreateFrame("Slider", nil, panel, "UISliderTemplate")
        blSlider:SetPoint("TOPLEFT", 16, y)
        blSlider:SetWidth(250)
        blSlider:SetMinMaxValues(600, 14400)
        blSlider:SetValue(GGI.db.autoBlacklistDuration or 1800)
        blSlider:SetValueStep(60)

        local blValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        blValue:SetPoint("LEFT", blSlider, "RIGHT", 15, 0)
        blValue:SetText(tostring(math.floor(blSlider:GetValue() / 60)) .. "m")
        blValue:SetTextColor(0.3, 1, 0.3, 1)

        local blHint = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        blHint:SetPoint("TOPLEFT", 16, y - 26)
        blHint:SetWidth(400)
        blHint:SetWordWrap(true)
        blHint:SetText("How long to remember blacklisted players")
        blHint:SetTextColor(0.6, 0.6, 0.75, 1)

        blSlider:SetScript("OnValueChanged", function()
            local val = math.floor(blSlider:GetValue())
            GGI.db.autoBlacklistDuration = val
            blValue:SetText(tostring(math.floor(val / 60)) .. "m")
        end)

        y = y - 60
        -- Commands Section
        local cmdHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cmdHeader:SetPoint("TOPLEFT", 16, y)
        cmdHeader:SetText("COMMANDS & INFO")
        cmdHeader:SetTextColor(0.35, 0.7, 1, 1)
        y = y - 24

        local cmdLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cmdLabel:SetPoint("TOPLEFT", 16, y)
        cmdLabel:SetText("/gugiui - Toggle the main window | /gugihelp - Show help")
        cmdLabel:SetWidth(500)
        cmdLabel:SetWordWrap(true)
        cmdLabel:SetTextColor(0.7, 0.7, 0.8, 1)
        y = y - 30

        local statLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        statLabel:SetPoint("TOPLEFT", 16, y)
        statLabel:SetWidth(500)
        statLabel:SetWordWrap(true)
        statLabel:SetText("Version 1.0 • Set aggression to 10 for maximum performance")
        statLabel:SetTextColor(0.5, 0.55, 0.65, 1)
    end)

    return panel
end

local panel = CreateOptionsPanel()
InterfaceOptions_AddCategory(panel)
