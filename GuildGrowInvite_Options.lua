local function CreateOptionsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "GuildGrowInvite"
    panel:SetScript("OnShow", function(self)
        if self.initialized then return end
        self.initialized = true

        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("GuildGrowInvite Settings")

        local y = -50
        local function CreateCheckbox(text, key, defaultVal)
            local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 16, y)
            local label = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            label:SetPoint("LEFT", cb, "RIGHT", 8, 0)
            label:SetText(text)
            cb:SetChecked(GGI.db[key] or defaultVal)
            cb:SetScript("OnClick", function()
                GGI.db[key] = cb:GetChecked()
            end)
            y = y - 30
            return cb
        end

        CreateCheckbox("Whisper Auto-Invite", "whisperInviteEnabled", true)
        CreateCheckbox("Chat Auto-Invite", "chatAutoInviteEnabled", true)
        CreateCheckbox("Nearby Auto-Invite", "nearAutoInviteEnabled", true)
        CreateCheckbox("Build Candidate List", "scanEnabled", true)
        CreateCheckbox("Skip Players Already in a Guild", "filterGuildedPlayers", true)
        CreateCheckbox("Log Invites/Skips to Chat ([GuildInvite])", "debugLogging", true)

        y = y - 10
        CreateCheckbox("Auto-Accept Duel Requests", "autoAcceptDuel", true)
        CreateCheckbox("Auto-Accept Trade Requests", "autoAcceptTrade", true)
        CreateCheckbox("Auto-Accept Party Invites", "autoAcceptParty", false)

        y = y - 20
        local aggLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        aggLabel:SetPoint("TOPLEFT", 16, y)
        aggLabel:SetText("Invite Aggression Level (higher = faster/more):")

        y = y - 30
        local aggSlider = CreateFrame("Slider", nil, panel, "UISliderTemplate")
        aggSlider:SetPoint("TOPLEFT", 16, y)
        aggSlider:SetWidth(200)
        aggSlider:SetMinMaxValues(1, 10)
        aggSlider:SetValue(GGI.db.inviteAggression or 10)
        aggSlider:SetValueStep(1)
        aggSlider:SetObeyStepOnDrag(true)

        local aggValue = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        aggValue:SetPoint("LEFT", aggSlider, "RIGHT", 10, 0)
        aggValue:SetText(tostring(math.floor(aggSlider:GetValue())))

        local aggHint = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        aggHint:SetPoint("TOPLEFT", 16, y - 20)
        aggHint:SetWidth(400)
        aggHint:SetWordWrap(true)
        aggHint:SetText("Controls scan rate, nameplate range, and invites per tick.")
        aggHint:SetTextColor(0.6, 0.6, 0.6)

        aggSlider:SetScript("OnValueChanged", function()
            local val = math.floor(aggSlider:GetValue())
            GGI.db.inviteAggression = val
            aggValue:SetText(tostring(val))
        end)

        y = y - 60
        local cdLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cdLabel:SetPoint("TOPLEFT", 16, y)
        cdLabel:SetText("Player Invite Cooldown (seconds):")

        y = y - 30
        local cdSlider = CreateFrame("Slider", nil, panel, "UISliderTemplate")
        cdSlider:SetPoint("TOPLEFT", 16, y)
        cdSlider:SetWidth(200)
        cdSlider:SetMinMaxValues(15, 300)
        cdSlider:SetValue(GGI.db.inviteCooldown or 30)
        cdSlider:SetValueStep(5)

        local cdValue = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        cdValue:SetPoint("LEFT", cdSlider, "RIGHT", 10, 0)
        cdValue:SetText(tostring(math.floor(cdSlider:GetValue())))

        cdSlider:SetScript("OnValueChanged", function()
            local val = math.floor(cdSlider:GetValue())
            GGI.db.inviteCooldown = val
            cdValue:SetText(tostring(val))
        end)

        y = y - 60
        local blLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        blLabel:SetPoint("TOPLEFT", 16, y)
        blLabel:SetText("Auto-Blacklist Duration (seconds):")

        y = y - 30
        local blSlider = CreateFrame("Slider", nil, panel, "UISliderTemplate")
        blSlider:SetPoint("TOPLEFT", 16, y)
        blSlider:SetWidth(200)
        blSlider:SetMinMaxValues(600, 14400)
        blSlider:SetValue(GGI.db.autoBlacklistDuration or 1800)
        blSlider:SetValueStep(60)

        local blValue = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        blValue:SetPoint("LEFT", blSlider, "RIGHT", 10, 0)
        blValue:SetText(tostring(math.floor(blSlider:GetValue())))

        blSlider:SetScript("OnValueChanged", function()
            local val = math.floor(blSlider:GetValue())
            GGI.db.autoBlacklistDuration = val
            blValue:SetText(tostring(val))
        end)

        y = y - 60
        local cmdLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        cmdLabel:SetPoint("TOPLEFT", 16, y)
        cmdLabel:SetText("Commands: /gugiui (toggle UI), /gugihelp (show help)")
        cmdLabel:SetWidth(400)
        cmdLabel:SetWordWrap(true)

        y = y - 30
        local statLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        statLabel:SetPoint("TOPLEFT", 16, y)
        statLabel:SetWidth(400)
        statLabel:SetWordWrap(true)
        statLabel:SetText("Set aggression to 10 for maximum invite throughput.")
    end)

    return panel
end

local panel = CreateOptionsPanel()
InterfaceOptions_AddCategory(panel)
