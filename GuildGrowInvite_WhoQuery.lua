-- GuildGrowInvite_WhoQuery.lua
-- Reliable guild-membership lookup.
--
-- GGI.IsGuilded()/FindUnitToken() can only see a player's guild if they have
-- a live unit token (nameplate, party/raid member, target, mouseover). Most
-- people you see typing in a channel, /say, or /yell never get a token, so
-- that check silently reports "not guilded" for them even when they are.
--
-- The /who system is the only client API that returns guild info for an
-- arbitrary player by name, so this module wraps it as a small throttled
-- queue and exposes GGI.QueryGuildStatus(name, callback).

local GGI = GuildGrowInvite

local whoQueue = {}       -- ordered list of stripped names waiting to be queried
local whoQueued = {}       -- set for de-dupe, name -> true
local whoCallbacks = {}    -- name -> { callback, callback, ... }
local whoInFlight = nil    -- name currently awaiting a WHO_LIST_UPDATE
local lastWhoSent = 0
local WHO_THROTTLE = 5      -- server-side /who is rate limited to roughly one per 5s

local function FireCallbacks(name, isGuilded)
    local cbs = whoCallbacks[name]
    whoCallbacks[name] = nil
    if not cbs then return end
    for _, cb in ipairs(cbs) do
        cb(isGuilded)
    end
end

local whoFrame = CreateFrame("Frame")
whoFrame:RegisterEvent("WHO_LIST_UPDATE")
whoFrame:SetScript("OnEvent", function(self, event)
    if event ~= "WHO_LIST_UPDATE" or not whoInFlight then return end

    local queriedName = whoInFlight
    whoInFlight = nil

    local matched = false
    local numResults = GetNumWhoResults()
    for i = 1, numResults do
        local name, guild = GetWhoInfo(i)
        if name then
            local stripped = GGI.StripRealm(name)
            if stripped == queriedName then
                matched = true
                local isGuilded = guild ~= nil and guild ~= ""
                if isGuilded then
                    GGI.MarkAsGuilded(stripped)
                end
                FireCallbacks(stripped, isGuilded)
                break
            end
        end
    end

    if not matched then
        -- They weren't in the result set (offline, name typo, realm-hop, etc).
        -- Treat as "unknown/not guilded" rather than blocking forever.
        FireCallbacks(queriedName, false)
    end

    if GGI.RefreshCandidatesList then
        GGI.RefreshCandidatesList()
    end
end)

local function SendNextWhoQuery()
    if whoInFlight then return end
    if #whoQueue == 0 then return end
    if GetTime() - lastWhoSent < WHO_THROTTLE then return end

    local name = table.remove(whoQueue, 1)
    whoQueued[name] = nil
    whoInFlight = name
    lastWhoSent = GetTime()

    if SetWhoToUI then
        SetWhoToUI(1) -- stop the built-in Who window from popping open
    end
    SendWho(name)
end

local whoTicker = CreateFrame("Frame")
local elapsed = 0
whoTicker:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed >= 1 then
        elapsed = 0
        SendNextWhoQuery()
    end
end)

--- Determine whether `name` is in a guild (any guild, not just yours).
-- Resolves via cache / guild roster / a live unit token instantly when
-- possible; otherwise queues an async /who lookup and calls back once the
-- server responds (typically within a few seconds, throttled).
-- callback(isGuilded: boolean) is always called exactly once.
function GGI.QueryGuildStatus(name, callback)
    if not name or name == "" then
        if callback then callback(false) end
        return
    end

    local stripped = GGI.StripRealm(name)

    if GGI.guildedCache[stripped] then
        if callback then callback(true) end
        return
    end
    if GGI.IsInMyGuild(stripped) then
        if callback then callback(true) end
        return
    end
    local unit = GGI.FindUnitToken(stripped)
    if unit then
        local guildName = GetGuildInfo(unit)
        if guildName then
            GGI.MarkAsGuilded(stripped)
        end
        if callback then callback(guildName ~= nil) end
        return
    end

    if not callback then return end

    whoCallbacks[stripped] = whoCallbacks[stripped] or {}
    table.insert(whoCallbacks[stripped], callback)

    if not whoQueued[stripped] and whoInFlight ~= stripped then
        whoQueued[stripped] = true
        table.insert(whoQueue, stripped)
    end
end
