-- GuildGrowInvite_Minimap.lua
-- Minimap button for quick access to the addon UI

local GGI = GuildGrowInvite

local minimapButton = nil
local minimapIcon = "Interface\\AddOns\\GuildGrowInvite\\minimap_icon.blp" -- User needs to convert webp to blp
local fallbackIcon = "Interface\\Icons\\Achievement_GuildPerk_WorkingOvertime" -- Fallback icon

local function OnMinimapClick(self, button)
    if button == "LeftButton" then
        if GGI.ToggleUI then
            GGI.ToggleUI()
        end
    end
end

local function OnMinimapEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("GuildGrowInvite")
    GameTooltip:AddLine("Left-click: Open Settings")
    GameTooltip:Show()
end

local function OnMinimapLeave(self)
    GameTooltip:Hide()
end

local function UpdateMinimapPosition()
    if not minimapButton or not GGI.db then return end

    local angle = GGI.db.minimapPosition or 45
    local radius = GGI.db.minimapRadius or 80

    local x, y = 0, 0
    x = radius * math.cos(math.rad(angle))
    y = radius * math.sin(math.rad(angle))

    minimapButton:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - x, (y - 52))
end

local function OnMinimapDragStart(self)
    self:LockHighlight()
    self.isDragging = true
end

local function OnMinimapDragStop(self)
    self:UnlockHighlight()
    self.isDragging = false
    
    -- Calculate new angle based on mouse position
    local mx, my = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    mx, my = mx / scale, my / scale
    
    local cx, cy = Minimap:GetCenter()
    local dx, dy = mx - cx, my - cy
    
    local angle = math.atan2(dy, dx)
    if angle < 0 then
        angle = angle + (2 * math.pi)
    end
    
    -- Convert to degrees
    angle = math.deg(angle)
    
    if GGI.db then
        GGI.db.minimapPosition = angle
    end
    
    UpdateMinimapPosition()
end

local function OnMinimapUpdate(self)
    if self.isDragging then
        local mx, my = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        mx, my = mx / scale, my / scale
        
        local cx, cy = Minimap:GetCenter()
        local dx, dy = mx - cx, my - cy
        
        local angle = math.atan2(dy, dx)
        if angle < 0 then
            angle = angle + (2 * math.pi)
        end
        
        -- Convert to degrees
        angle = math.deg(angle)
        
        local radius = GGI.db.minimapRadius or 80
        local x = radius * math.cos(math.rad(angle))
        local y = radius * math.sin(math.rad(angle))
        
        self:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - x, (y - 52))
    end
end

function GGI.CreateMinimapButton()
    if minimapButton then return minimapButton end

    minimapButton = CreateFrame("Button", "GuildGrowInviteMinimapButton", Minimap)
    minimapButton:SetSize(20, 20)
    minimapButton:SetFrameStrata("LOW")

    -- Icon texture with fallback
    local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(minimapIcon)
    -- Check if texture loaded, if not use fallback
    if not icon:GetTexture() then
        icon:SetTexture(fallbackIcon)
    end
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
    minimapButton.icon = icon

    -- Border/overlay for visibility
    local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetSize(32, 32)
    overlay:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", -6, 6)
    overlay:Hide()
    
    -- Show overlay on hover
    minimapButton:SetScript("OnEnter", function(self)
        overlay:Show()
        OnMinimapEnter(self)
    end)
    
    minimapButton:SetScript("OnLeave", function(self)
        overlay:Hide()
        OnMinimapLeave(self)
    end)
    
    minimapButton:SetScript("OnClick", OnMinimapClick)
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Dragging functionality
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetScript("OnDragStart", OnMinimapDragStart)
    minimapButton:SetScript("OnDragStop", OnMinimapDragStop)
    minimapButton:SetScript("OnUpdate", OnMinimapUpdate)
    
    -- Initialize position
    if GGI.db and GGI.db.minimapPosition then
        UpdateMinimapPosition()
    else
        minimapButton:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - (80 * math.cos(math.rad(45))), (80 * math.sin(math.rad(45)) - 52))
    end

    minimapButton:Show()

    return minimapButton
end

-- Initialize minimap button on addon load
local minimapEventFrame = CreateFrame("Frame")
minimapEventFrame:RegisterEvent("ADDON_LOADED")
minimapEventFrame:RegisterEvent("PLAYER_LOGIN")
minimapEventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "GuildGrowInvite" then
        -- Wait for PLAYER_LOGIN to ensure Minimap is ready
        return
    elseif event == "PLAYER_LOGIN" then
        -- Delay slightly to ensure Minimap is fully loaded
        C_Timer.After(1, function()
            if Minimap then
                GGI.CreateMinimapButton()
            else
                print("|cffff0000[GuildGrowInvite]|r Minimap not found, minimap button disabled.")
            end
        end)
    end
end)
