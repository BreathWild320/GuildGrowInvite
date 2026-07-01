-- GuildGrowInvite_Settings.lua
-- Blacklist helpers for GuildGrowInvite.

GuildGrowInvite = GuildGrowInvite or {}
local GGI = GuildGrowInvite

function GGI.CleanupAutoBlacklist()
    local db = GGI.db
    if not db or not db.autoBlacklist then return end
    local now = GetTime()
    for name, expire in pairs(db.autoBlacklist) do
        if expire and expire <= now then
            db.autoBlacklist[name] = nil
        end
    end
end

function GGI.IsBlacklisted(name)
    if not name then return false end
    local db = GGI.db
    if not db then return false end
    GGI.CleanupAutoBlacklist()
    if db.blacklist[name] == true then
        return true
    end
    if db.autoBlacklist[name] and db.autoBlacklist[name] > GetTime() then
        return true
    end
    return false
end

function GGI.AddToBlacklist(name)
    if not name or name == "" then return end
    local db = GGI.db
    if not db then return end
    db.blacklist[name] = true
end

function GGI.RemoveFromBlacklist(name)
    if not name or name == "" then return end
    local db = GGI.db
    if not db then return end
    db.blacklist[name] = nil
end

function GGI.ListBlacklist()
    local db = GGI.db
    if not db then return {} end
    local list = {}
    for name in pairs(db.blacklist) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

------------------------------------------------------------
-- Guilded player cache
------------------------------------------------------------
GGI.guildedCache = {}

function GGI.MarkAsGuilded(name)
    if not name then return end
    local stripped = GGI.StripRealm(name)
    GGI.guildedCache[stripped] = true
end

function GGI.IsGuilded(name)
    if not name then return false end
    local stripped = GGI.StripRealm(name)
    if GGI.guildedCache[stripped] then return true end
    if GGI.IsInMyGuild(stripped) then
        GGI.guildedCache[stripped] = true
        return true
    end
    local unit = GGI.FindUnitToken(stripped)
    if unit then
        local guildName = GetGuildInfo(unit)
        if guildName then
            GGI.guildedCache[stripped] = true
            return true
        end
    end
    return false
end

function GGI.ClearGuildedCache()
    GGI.guildedCache = {}
end

------------------------------------------------------------
-- WHO-based guild check for remote players
------------------------------------------------------------
GGI.whoQueue = {}
GGI.whoPending = nil

function GGI.QueueWhoCheck(name)
    if not name or name == "" then return end
    local stripped = GGI.StripRealm(name)
    if GGI.guildedCache[stripped] then return end
    for _, entry in ipairs(GGI.whoQueue) do
        if entry == stripped then return end
    end
    table.insert(GGI.whoQueue, stripped)
end

function GGI.ProcessWhoQueue()
    if GGI.whoPending then return end
    if #GGI.whoQueue == 0 then return end
    GGI.whoPending = table.remove(GGI.whoQueue, 1)
    pcall(SetWhoToUI, 0)
    pcall(SendWho, "n-" .. GGI.whoPending)
end

function GGI.OnWhoUpdate()
    if not GGI.whoPending then return end
    local name = GGI.whoPending
    GGI.whoPending = nil
    local numResults = select(2, pcall(GetNumWhoResults))
    if not numResults or numResults == 0 then GGI.ProcessWhoQueue(); return end
    for i = 1, numResults do
        local success, whoName, guild = pcall(GetWhoInfo, i)
        if success and whoName and guild and guild ~= "" then
            local stripped = GGI.StripRealm(whoName)
            if stripped == name or stripped == GGI.StripRealm(name) then
                GGI.guildedCache[name] = true
                break
            end
        end
    end
    GGI.ProcessWhoQueue()
end
