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
