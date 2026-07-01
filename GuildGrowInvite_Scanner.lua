-- GuildGrowInvite_Scanner.lua
-- Watches public chat for any player message in tracked channels.
-- Builds a manual-confirm candidate list and auto-invites with cooldown.

local GGI = GuildGrowInvite

-- Scan every tracked chat message for auto-invite and candidate list building.
-- This is intentionally broad so the addon can recruit from as many chat sources
-- as possible.
local function Truncate(str, maxLen)
    if #str <= maxLen then return str end
    return str:sub(1, maxLen - 3) .. "..."
end

local function RemoveCandidate(name)
    local db = GGI.db
    if not db then return end
    for i, entry in ipairs(db.candidateList) do
        if entry.name == name then
            table.remove(db.candidateList, i)
            break
        end
    end
    db.candidateSeen[name] = nil
    if GGI.RefreshCandidatesList then
        GGI.RefreshCandidatesList()
    end
    if GGI.RefreshUI then
        GGI.RefreshUI()
    end
end

local function AddCandidate(name, channelLabel, msg)
    local db = GGI.db
    if not db then return end

    -- Fast-path skip using whatever we already know (cache/roster/unit token).
    -- This won't catch everyone (see QueryGuildStatus below), but avoids
    -- adding an entry we'd have to remove a moment later in the common case.
    if db.filterGuildedPlayers and GGI.IsGuilded(name) then return end

    -- Don't re-add the same person repeatedly
    if db.candidateSeen[name] then return end

    local entry = {
        name = name,
        channel = channelLabel or "?",
        msg = Truncate(msg, 60),
        time = time(),
    }

    table.insert(db.candidateList, entry)
    db.candidateSeen[name] = entry.time

    -- Cap the list, dropping the oldest entry
    while #db.candidateList > (db.maxCandidates or 15) do
        local removed = table.remove(db.candidateList, 1)
        if removed then
            db.candidateSeen[removed.name] = nil
        end
    end

    if GGI.RefreshCandidatesList then
        GGI.RefreshCandidatesList()
    end
    if GGI.RefreshUI then
        GGI.RefreshUI()
    end

    -- Reliable check: most chat senders have no unit token, so the fast-path
    -- check above frequently misses guilded players. Confirm via /who and
    -- drop them from the list if it turns out they're guilded after all.
    if db.filterGuildedPlayers then
        GGI.QueryGuildStatus(name, function(isGuilded)
            if isGuilded and GGI.db and GGI.db.candidateSeen[name] then
                RemoveCandidate(name)
            end
        end)
    end
end

------------------------------------------------------------
-- Event handling
------------------------------------------------------------
local eventLabels = {
    CHAT_MSG_CHANNEL = "Channel",
    CHAT_MSG_SAY = "Say",
    CHAT_MSG_YELL = "Yell",
    CHAT_MSG_PARTY = "Party",
    CHAT_MSG_PARTY_LEADER = "Party Leader",
    CHAT_MSG_RAID = "Raid",
    CHAT_MSG_RAID_LEADER = "Raid Leader",
    CHAT_MSG_INSTANCE_CHAT = "Instance",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "Instance Leader",
    CHAT_MSG_BATTLEGROUND = "Battleground",
    CHAT_MSG_BATTLEGROUND_LEADER = "Battleground Leader",
    CHAT_MSG_GUILD = "Guild",
    CHAT_MSG_OFFICER = "Officer",
    CHAT_MSG_EMOTE = "Emote",
    CHAT_MSG_TEXT_EMOTE = "Text Emote",
}

local scanFrame = CreateFrame("Frame")
scanFrame:RegisterEvent("CHAT_MSG_CHANNEL")
scanFrame:RegisterEvent("CHAT_MSG_SAY")
scanFrame:RegisterEvent("CHAT_MSG_YELL")
scanFrame:RegisterEvent("CHAT_MSG_PARTY")
scanFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
scanFrame:RegisterEvent("CHAT_MSG_RAID")
scanFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
scanFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
scanFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
scanFrame:RegisterEvent("CHAT_MSG_BATTLEGROUND")
scanFrame:RegisterEvent("CHAT_MSG_BATTLEGROUND_LEADER")
scanFrame:RegisterEvent("CHAT_MSG_GUILD")
scanFrame:RegisterEvent("CHAT_MSG_OFFICER")
scanFrame:RegisterEvent("CHAT_MSG_EMOTE")
scanFrame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")

scanFrame:SetScript("OnEvent", function(self, event, ...)
    local db = GGI.db
    if not db then return end

    local msg, sender, _, channelName = ...
    if not msg or not sender then return end

    local playerName = GGI.StripRealm(UnitName("player"))
    local senderName = GGI.StripRealm(sender)
    if senderName == playerName then return end

    local label = eventLabels[event] or channelName or event

    if db.scanEnabled then
        AddCandidate(senderName, label, msg)
    end

    -- Skip if sender is already in our guild
    if GGI.IsInMyGuild(senderName) then return end

    -- Reliable, async guild check (unit-token checks miss most chat senders,
    -- since they usually aren't on-screen). Everything that should skip
    -- guilded players now waits for this instead of trusting the old
    -- synchronous GGI.IsGuilded(), which returned false for anyone without
    -- a visible unit token.
    GGI.QueryGuildStatus(senderName, function(isGuilded)
        if db.filterGuildedPlayers and isGuilded then return end

        -- Invite from ALL chat messages (extremely aggressive)
        if db.chatAutoInviteEnabled then
            GGI.OnChatMatch(senderName, label)
        end

        -- LFG keyword detection (additional layer on top of universal invite)
        if db.lfgAutoInviteEnabled then
            local lfgKeywords = {"lfg", "lf", "looking for", "guild", "recruit", "invite", "any guild", "need guild", "lf guild", "lfm", "looking for more", "need members", "recruiting", "join guild", "guild invite", "wts", "wtb", "wtt", "lf raid", "lf dungeon", "lf group", "need group", "need raid", "looking for raid", "looking for dungeon", "looking for group", "lf healer", "lf tank", "lf dps", "need healer", "need tank", "need dps", "anyone", "any class", "all classes", "social", "casual", "hardcore", "raiding", "pvp", "pve", "leveling", "new guild", "active guild", "friendly", "help", "guild chat", "community"}
            local msgLower = msg:lower()
            for _, keyword in ipairs(lfgKeywords) do
                if msgLower:find(keyword, 1, true) then
                    GGI.InviteName(senderName, "LFG detection: " .. label)
                    break
                end
            end
        end
    end)
end)
