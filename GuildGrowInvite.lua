-- GuildGrowInvite.lua (Core)
-- Ultra-aggressive whisper-keyword + proximity auto-invite for WoW 3.3.5

GuildGrowInvite = GuildGrowInvite or {}
local GGI = GuildGrowInvite

------------------------------------------------------------
-- Saved variable defaults
------------------------------------------------------------
local function InitDB()
    GuildGrowInviteDB = GuildGrowInviteDB or {}
    local db = GuildGrowInviteDB
    if db.whisperKeywords == nil then db.whisperKeywords = {"inv", "invite", "lfg", "lf", "guild"} end
    if db.whisperInviteEnabled == nil then db.whisperInviteEnabled = true end
    if db.whisperKeyword and type(db.whisperKeyword) == "string" then
        db.whisperKeywords = {db.whisperKeyword}
        db.whisperKeyword = nil
    end
    if db.autoReplyMessage == nil then db.autoReplyMessage = "Hello! I'm building ManaStorm Runs, a guild focused on making ManaStorm grouping simple. Whether you're leveling or farming gold, you'll always have people to run with. Interested?" end
    if db.autoReplyMessage == "Welcome to the guild!" then
        db.autoReplyMessage = "Hello! I'm building ManaStorm Runs, a guild focused on making ManaStorm grouping simple. Whether you're leveling or farming gold, you'll always have people to run with. Interested?"
    end
    if db.autoReplyEnabled == nil then db.autoReplyEnabled = true end
    if db.scanEnabled == nil then db.scanEnabled = true end
    if db.chatAutoInviteEnabled == nil then db.chatAutoInviteEnabled = true end
    if db.nearAutoInviteEnabled == nil then db.nearAutoInviteEnabled = true end
    if db.autoBlacklistDuration == nil then db.autoBlacklistDuration = 1800 end
    if db.selectedCategory == nil then db.selectedCategory = "All" end
    if db.maxCandidates == nil then db.maxCandidates = 50 end
    if db.minLevel == nil then db.minLevel = 1 end
    if db.maxLevel == nil then db.maxLevel = 70 end
    if db.levelFilterEnabled == nil then db.levelFilterEnabled = false end
    if db.lfgAutoInviteEnabled == nil then db.lfgAutoInviteEnabled = true end
    if db.snoopEnabled == nil then db.snoopEnabled = true end
    if db.snoopRadius == nil then db.snoopRadius = 100 end
    if db.inviteAggression == nil then db.inviteAggression = 10 end
    if db.autoAcceptDuel == nil then db.autoAcceptDuel = true end
    if db.autoAcceptTrade == nil then db.autoAcceptTrade = true end
    if db.autoAcceptParty == nil then db.autoAcceptParty = false end
    if db.filterGuildedPlayers == nil then db.filterGuildedPlayers = true end
    if db.debugLogging == nil then db.debugLogging = true end
    if db.inviteCooldown == nil then db.inviteCooldown = 30 end
    db.candidateList = db.candidateList or {}
    db.candidateSeen = db.candidateSeen or {}
    db.recentWhisperInvites = db.recentWhisperInvites or {}
    db.recentChatInvites = db.recentChatInvites or {}
    db.recentNearInvites = db.recentNearInvites or {}
    db.blacklist = db.blacklist or {}
    db.autoBlacklist = db.autoBlacklist or {}
    GGI.db = db
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

function GGI.StripRealm(name)
    if not name then return name end
    local base = name:match("^([^-]+)")
    return base or name
end

function GGI.FindUnitToken(name)
    if not name then return nil end
    for i = 1, 80 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and GGI.StripRealm(UnitName(unit)) == name then
            return unit
        end
    end
    for i = 1, GetNumPartyMembers() do
        local unit = "party" .. i
        if UnitExists(unit) and GGI.StripRealm(UnitName(unit)) == name then
            return unit
        end
    end
    for i = 1, GetNumRaidMembers() do
        local unit = "raid" .. i
        if UnitExists(unit) and GGI.StripRealm(UnitName(unit)) == name then
            return unit
        end
    end
    if UnitExists("target") and GGI.StripRealm(UnitName("target")) == name then
        return "target"
    end
    if UnitExists("mouseover") and GGI.StripRealm(UnitName("mouseover")) == name then
        return "mouseover"
    end
    if UnitExists("focus") and GGI.StripRealm(UnitName("focus")) == name then
        return "focus"
    end
    return nil
end

function GGI.IsInMyGuild(playerName)
    if not playerName or playerName == "" then return false end
    local stripped = GGI.StripRealm(playerName)
    local numMembers = GetNumGuildMembers()
    if numMembers and numMembers > 0 then
        for i = 1, numMembers do
            local name = GetGuildRosterInfo(i)
            if name then
                local base = GGI.StripRealm(name)
                if base == stripped then
                    GGI.MarkAsGuilded(stripped)
                    return true
                end
            end
        end
    end
    return false
end

function GGI.IsInAnyGuild(name)
    if not name or name == "" then return false end
    local stripped = GGI.StripRealm(name)
    if GGI.guildedCache and GGI.guildedCache[stripped] then return true end
    local checkUnit = GGI.FindUnitToken(stripped)
    if checkUnit then
        local guildName = GetGuildInfo(checkUnit)
        if guildName then
            GGI.MarkAsGuilded(stripped)
            return true
        end
    end
    return false
end

local function BuildKeywordVariants(keyword)
    local variants = {}
    local lower = keyword:lower()
    table.insert(variants, lower)
    if lower:sub(1, 1) == "/" then
        table.insert(variants, lower:sub(2))
    else
        table.insert(variants, "/" .. lower)
    end
    return variants
end

local function MessageMatchesKeyword(msg, keyword)
    if not msg or not keyword or keyword == "" then return false end
    local msgLower = msg:lower()
    for _, variant in ipairs(BuildKeywordVariants(keyword)) do
        if msgLower:find(variant, 1, true) then
            return true
        end
    end
    return false
end

function GGI.CheckLevelRange(name)
    local db = GGI.db
    if not db or not db.levelFilterEnabled then return true end
    local level = UnitLevel(name)
    if not level or level == 0 then return true end
    return level >= (db.minLevel or 1) and level <= (db.maxLevel or 70)
end

------------------------------------------------------------
-- Anti-spam / cooldown system
------------------------------------------------------------

local inviteCooldowns = {}
local nameplateAttempted = {}
local nameplateResetCounter = 0
local activePlates = {}

local function IsOnCooldown(name)
    local expiry = inviteCooldowns[name]
    return expiry and GetTime() < expiry
end

local function SetCooldown(name, seconds)
    inviteCooldowns[name] = GetTime() + (seconds or 30)
end

local function CleanExpiredCooldowns()
    local now = GetTime()
    for name, expiry in pairs(inviteCooldowns) do
        if expiry and expiry <= now then
            inviteCooldowns[name] = nil
        end
    end
    nameplateResetCounter = nameplateResetCounter + 1
    if nameplateResetCounter >= 60 then
        nameplateAttempted = {}
        nameplateResetCounter = 0
    end
end

------------------------------------------------------------
-- Invite queue
------------------------------------------------------------

local inviteQueue = {}

local function QueueInvite(name, source, unit)
    if not name or name == "" then return end
    for _, entry in ipairs(inviteQueue) do
        if entry.name == name then return end
    end
    tinsert(inviteQueue, {name = name, source = source, unit = unit})
end

local function ProcessInviteQueue(maxPerTick)
    local count = 0
    while #inviteQueue > 0 and count < (maxPerTick or 1) do
        local entry = tremove(inviteQueue, 1)
        if entry and entry.name then
            GGI.InviteName(entry.name, entry.source, entry.unit)
            count = count + 1
        end
    end
end

------------------------------------------------------------
-- Debug logging
------------------------------------------------------------

function GGI.DebugLog(fmt, ...)
    local db = GGI.db
    if db and db.debugLogging == false then return end
    print(("|cff00ccff[GuildInvite]:|r " .. fmt):format(...))
end

------------------------------------------------------------
-- Guild invite action
------------------------------------------------------------

-- Invites `name` to the guild.
-- `skipGuildCheck` should be true only when the caller has already confirmed
-- (via GGI.QueryGuildStatus) that this player isn't guilded - used for
-- whisper-triggered invites, where no unit token exists to check directly.
function GGI.InviteName(name, source, unit, skipGuildCheck)
    if not name or name == "" then return false, "no name" end

    if GGI.IsBlacklisted(name) then
        return false, "blacklisted"
    end

    if IsOnCooldown(name) then
        return false, "cooldown"
    end

    if not GGI.CheckLevelRange(name) then
        return false, "level out of range"
    end

    if GGI.IsInMyGuild(name) then
        return false, "already in guild"
    end

    -- checkUnit is declared here (not inside the block below) so it's still
    -- in scope further down when deciding whether to send the whisper.
    local checkUnit = unit or GGI.FindUnitToken(name)

    if not skipGuildCheck and GGI.db and GGI.db.filterGuildedPlayers then
        if GGI.IsGuilded(name) then
            SetCooldown(name, GGI.db.inviteCooldown or 30)
            GGI.DebugLog("Skipped '%s', they're already in a guild.", name)
            return false, "in a guild (cached)"
        end
        if checkUnit then
            local guildName = GetGuildInfo(checkUnit)
            if guildName then
                GGI.MarkAsGuilded(name)
                SetCooldown(name, GGI.db.inviteCooldown or 30)
                GGI.DebugLog("Skipped '%s', they're already in a guild.", name)
                return false, "in another guild"
            end
        else
            SetCooldown(name, GGI.db.inviteCooldown or 30)
            return false, "cannot verify guild status"
        end
    end

    if not CanGuildInvite() then
        print("|cffff0000[GuildGrowInvite]|r You don't have permission to invite to this guild.")
        return false, "no permission"
    end

    SetCooldown(name, GGI.db and GGI.db.inviteCooldown or 30)

    GuildInvite(name)
    GGI.AutoBlacklistName(name)

    GGI.DebugLog("Invited '%s' to the guild.%s", name, source and (" (" .. source .. ")") or "")

    local shouldWhisper = true
    if checkUnit and GetGuildInfo(checkUnit) then
        shouldWhisper = false
    end
    if shouldWhisper and GGI.IsInMyGuild(name) then
        shouldWhisper = false
    end
    if shouldWhisper then
        local message = GGI.GetSelectedMessage()
        SendChatMessage(message, "WHISPER", nil, name)
    end

    return true
end

function GGI.AutoBlacklistName(name)
    if not name or name == "" then return end
    local db = GGI.db
    if not db then return end
    db.autoBlacklist[name] = GetTime() + (db.autoBlacklistDuration or 1800)
end

------------------------------------------------------------
-- Message Generator (natural, varied, human-sounding)
------------------------------------------------------------

local parts = {}

parts.greet = {
    "Hey there!", "Heya!", "How's it going?", "Hi!", "Hello!",
    "Hey!", "Howdy!", "Greetings!", "Hey, hope you're having a good session!",
    "Hi, hope your day's going well!", "Heya, what's up?", "Yo!",
    "Hey, quick question for you -", "Hey, hope the grind's treating you well!",
    "Hi, sorry to interrupt -", "Hello there!",
}

parts.intro = {
    "I'm from ManaStorm Runs",
    "I'm part of ManaStorm Runs over here",
    "I recruit for ManaStorm Runs",
    "I'm one of the folks behind ManaStorm Runs",
    "I help run ManaStorm Runs",
    "I'm with ManaStorm Runs",
}

parts.guildDesc = {
    "we're a guild focused on getting people together for ManaStorm runs, whether you're leveling or farming",
    "we're building a community around ManaStorm grouping so people always have someone to run with",
    "our main thing is helping people find groups for ManaStorm content without all the hassle",
    "we put together groups for ManaStorm runs constantly - leveling, gold, you name it",
    "the whole point of the guild is making it easy to find parties for ManaStorm",
    "we're all about helping each other run ManaStorm, no matter what level or gear you're at",
    "we help players group up for ManaStorm runs, both for leveling and for gold farming",
    "we try to make it simple for people to find groups and actually play together instead of just sitting in town",
}

parts.benefit = {
    "so you never have to spam trade chat hoping someone replies",
    "makes the game way more fun when help is literally a guild chat away",
    "it's a game changer not having to beg for groups all the time",
    "takes all the frustration out of trying to find a party",
    "honestly makes the whole experience so much better when you've got people to run with",
    "you'd be surprised how much more you enjoy the game when grouping is effortless",
}

parts.community = {
    "the community here is really friendly and laid back",
    "everyone in the guild is super chill and helpful",
    "we've got a really positive vibe going, people actually enjoy playing together",
    "it's a mix of new and veteran players and everyone gets along great",
    "people are always running something and looking for more to join in",
    "the guild's got a great atmosphere, no drama just people having fun",
    "folks are really welcoming here, felt like home pretty much right away",
}

parts.invite = {
    "Would you be interested in joining us?",
    "Want to come check us out?",
    "Let me know if you'd like an invite!",
    "What do you think? No pressure at all, just thought I'd ask!",
    "You should come hang out with us sometime, see if you like it!",
    "We'd love to have you if you're looking for a guild.",
    "Feel free to join and see if it's your kind of place!",
    "Give us a try and see what you think - you can always leave if it's not your vibe.",
    "If you're looking for a group to run with, we'd be happy to have you aboard.",
    "Want an invite? We'd love to have you join the crew!",
    "No worries if not, but the offer's there if you ever change your mind!",
}

parts.personal = {
    "I've been running with this group for a while and honestly it's been great.",
    "I joined a few weeks back and finding groups has been so much easier since.",
    "I used to struggle finding parties until I joined - now I never run alone.",
    "I was hesitant at first but honestly joining was one of the best things I did in-game.",
    "I found this guild recently and the difference in being able to find groups is night and day.",
    "I've been in a lot of guilds over the years but this one actually follows through on grouping up.",
}

parts.opener = {
    "How's your leveling going?",
    "What class are you playing these days?",
    "Are you looking for a guild by any chance?",
    "How's your session going?",
    "What kind of content do you mostly do?",
    "Do you run ManaStorm at all?",
    "Finding it hard to get groups together?",
    "Are you enjoying the game so far?",
    "What level are you at right now?",
    "Just wondering if you're looking for people to run with?",
}

parts.closer = {
    "Anyway, just thought I'd reach out and say hi!",
    "Hope you have a great day either way!",
    "Good luck with whatever you're working on!",
    "Happy gaming, and hope to see you around!",
    "Take care, and let me know if you ever want in!",
    "Cheers, and good luck out there!",
    "Anyway, thought I'd throw it out there!",
    "Have a good one, and the door's always open!",
}

local r = math.random

local styles = {
    -- Greeting, intro, guild, benefit, invite
    function()
        return parts.greet[r(#parts.greet)] .. " " ..
               parts.intro[r(#parts.intro)] .. ", " ..
               parts.guildDesc[r(#parts.guildDesc)] .. ". " ..
               parts.benefit[r(#parts.benefit)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Greeting, intro, community, invite
    function()
        return parts.greet[r(#parts.greet)] .. " " ..
               parts.intro[r(#parts.intro)] .. ". " ..
               parts.community[r(#parts.community)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Opener question, intro, guild, invite
    function()
        return parts.opener[r(#parts.opener)] .. " " ..
               parts.intro[r(#parts.intro)] .. " and " ..
               parts.guildDesc[r(#parts.guildDesc)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Greeting, intro, personal, benefit, invite
    function()
        return parts.greet[r(#parts.greet)] .. " " ..
               parts.intro[r(#parts.intro)] .. ". " ..
               parts.personal[r(#parts.personal)] .. " " ..
               parts.benefit[r(#parts.benefit)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Greeting, intro, guild, community, invite
    function()
        return parts.greet[r(#parts.greet)] .. " " ..
               parts.intro[r(#parts.intro)] .. ", " ..
               parts.guildDesc[r(#parts.guildDesc)] .. ". " ..
               parts.community[r(#parts.community)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Intro, personal, benefit, invite
    function()
        return parts.intro[r(#parts.intro)] .. ". " ..
               parts.personal[r(#parts.personal)] .. " " ..
               parts.benefit[r(#parts.benefit)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Greeting, opener, intro, guild, closer
    function()
        return parts.greet[r(#parts.greet)] .. " " ..
               parts.opener[r(#parts.opener)] .. " " ..
               parts.intro[r(#parts.intro)] .. ", " ..
               parts.guildDesc[r(#parts.guildDesc)] .. ". " ..
               parts.closer[r(#parts.closer)]
    end,
    -- Greeting, intro, community, invite
    function()
        return parts.greet[r(#parts.greet)] .. " " ..
               parts.intro[r(#parts.intro)] .. ". We've got a really solid group going - " ..
               parts.community[r(#parts.community)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Intro, guild, personal, closer + invite
    function()
        return parts.intro[r(#parts.intro)] .. " and " ..
               parts.guildDesc[r(#parts.guildDesc)] .. ". " ..
               parts.personal[r(#parts.personal)] .. " " ..
               parts.closer[r(#parts.closer)] .. " " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Opener, intro, benefit, invite
    function()
        return parts.opener[r(#parts.opener)] .. " " ..
               parts.intro[r(#parts.intro)] .. ", " ..
               parts.guildDesc[r(#parts.guildDesc)] .. ". " ..
               parts.benefit[r(#parts.benefit)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Greeting, intro (short), invite (direct)
    function()
        return parts.greet[r(#parts.greet)] .. " " ..
               parts.intro[r(#parts.intro)] .. ". " ..
               parts.community[r(#parts.community)] .. " " ..
               parts.closer[r(#parts.closer)]
    end,
    -- Greeting, guild, personal, invite
    function()
        return parts.greet[r(#parts.greet)] .. " " ..
               parts.guildDesc[r(#parts.guildDesc)] .. ". " ..
               parts.personal[r(#parts.personal)] .. " " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Intro, community, benefit, closer
    function()
        return parts.intro[r(#parts.intro)] .. ", " ..
               parts.guildDesc[r(#parts.guildDesc)] .. ". " ..
               parts.community[r(#parts.community)] .. ". " ..
               parts.benefit[r(#parts.benefit)] .. ". " ..
               parts.closer[r(#parts.closer)]
    end,
    -- Greeting + opener + intro + community + invite (warm)
    function()
        return parts.greet[r(#parts.greet)] .. " " ..
               parts.opener[r(#parts.opener)] .. " " ..
               parts.intro[r(#parts.intro)] .. ". " ..
               parts.community[r(#parts.community)] .. " and " ..
               parts.guildDesc[r(#parts.guildDesc)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
    -- Intro + personal + community + invite (personalized feel)
    function()
        return parts.intro[r(#parts.intro)] .. ". " ..
               parts.personal[r(#parts.personal)] .. " " ..
               parts.community[r(#parts.community)] .. ". " ..
               parts.invite[r(#parts.invite)]
    end,
}

function GGI.GenerateMessages(count)
    local seen = {}
    local messages = {}
    local attempts = 0
    while #messages < count and attempts < count * 10 do
        attempts = attempts + 1
        local msg = styles[r(#styles)]()
        if not seen[msg] then
            seen[msg] = true
            table.insert(messages, msg)
        end
    end
    return messages
end

GGI.DefaultMessages = {
    "Hey there! I'm from ManaStorm Runs, we're a guild that focuses on helping people find groups for ManaStorm runs - whether you're leveling, farming gold, or just want people to play with. We've got a really chill community and people are always running something. Would you be interested in joining?",
    "How's it going? I help recruit for ManaStorm Runs, which is basically a guild built around making it easy to find groups for ManaStorm content. I used to spend forever looking for parties before I joined, but now there's always someone around to run with. If you're tired of spamming trade chat, you might like it here!",
    "Hi! Just wanted to reach out because I'm with ManaStorm Runs - we're a community focused on ManaStorm grouping for both leveling and gold farming. The vibe is super chill and people are always happy to help out. Let me know if you'd like to check us out sometime!",
    "Hey, hope you're having a good session! I'm with ManaStorm Runs and we're basically a bunch of people who got tired of not being able to find groups for ManaStorm. Now we run together all the time and it's made the game so much more enjoyable. Would you want in?",
    "Hey there! I recruit for ManaStorm Runs, a guild that's all about getting people together for ManaStorm content. It doesn't matter if you're brand new or max level, there's always someone around to run with. The community is super welcoming and we'd love to have you if you're interested!",
    "What class are you playing? I'm asking because I'm with ManaStorm Runs, a guild built around helping each other with ManaStorm runs. We've got players of all levels and specs and people are always grouping up for something. If you're looking for a guild that actually plays together, we might be a good fit!",
    "Hi! Sorry if this is random, but I'm part of ManaStorm Runs and we're looking for more people who enjoy ManaStorm runs. The guild is really active and everyone's super friendly - feels more like playing with a group of friends than a typical guild. Want to give it a try?",
    "Hey, quick question - do you run ManaStorm much? I'm with ManaStorm Runs and we've built a really solid community around grouping up for ManaStorm content. I used to have a hard time finding parties but now I never run solo. Let me know if you'd like an invite!",
    "How's the grind going? I'm part of ManaStorm Runs, a guild focused on making ManaStorm grouping easy and fun. Whether you're leveling up or farming gold, you'll always find people to group with here. The community is really active and welcoming. Want to check us out?",
    "Hey! I'm with ManaStorm Runs, a guild that helps people find groups for ManaStorm content. I joined a few weeks ago and honestly it's been awesome - there's always someone online running something. If you're looking for a guild that actually groups up, you should come see what we're about!",
    "Greetings! I'm one of the recruiters for ManaStorm Runs. We're a friendly guild focused on helping people find groups for ManaStorm runs - leveling, gold farming, you name it. The best part is you never have to wait long to find a party. Interested in joining?",
    "Hey, hope your day's going well! I'm from ManaStorm Runs, a guild that's all about teamwork and helping each other through ManaStorm content. People here are really supportive and always down to group up. If that sounds like your kind of thing, we'd love to have you!",
    "Hi there! I recruit for ManaStorm Runs, and the whole idea is simple - we help each other find groups for ManaStorm so nobody has to sit around waiting. The community is super active and chill. Want an invite?",
    "Hey, what level are you? I'm with ManaStorm Runs, a guild that focuses on helping players group up for ManaStorm runs at any level. We've got a really friendly community and people are always looking for more to join their runs. Would you be interested?",
    "How's it going? I wanted to tell you about ManaStorm Runs - it's a guild I'm part of that's built around grouping up for ManaStorm content. I've met a lot of cool people here and the difference in being able to find groups is amazing. No pressure, but if you're looking for a guild we'd love to chat!",
    "Hey! I'm with ManaStorm Runs and we're basically a bunch of players who love running ManaStorm together. The guild is really social and active, people are always helping each other out. If you're tired of pugging or just want a community to be part of, come check us out!",
    "Hello! I'm part of ManaStorm Runs, a guild dedicated to making ManaStorm grouping easy for everyone. We've got a great mix of players from all levels and everyone's super welcoming. I promise it's way better than most guilds out there. Want to see for yourself?",
    "Hey, quick message - I recruit for ManaStorm Runs, a friendly community of players who group up for ManaStorm runs regularly. If you're tired of struggling to find parties or just want a more social experience, this might be what you're looking for. Let me know if you want in!",
    "How's your session going? I'm from ManaStorm Runs and we focus on helping each other find groups for ManaStorm runs. It's honestly made the game so much more fun for me not having to wait around for groups. If you're interested in joining an active guild, hit me up!",
    "Hi! I'm with ManaStorm Runs and I wanted to reach out because we're always looking for more players who enjoy running ManaStorm. The guild is really active and the community is super positive. If you're looking for a place to call home in-game, we'd be happy to have you!",
    "Hey there! Are you looking for a guild by any chance? I'm with ManaStorm Runs and we help people find groups for ManaStorm content at any level. The vibe is really chill and people are always running something. Would you be interested in checking us out?",
    "Hey! I recruit for ManaStorm Runs, a community built around one simple thing - helping each other run ManaStorm. Whether you're leveling, farming, or just want company while you play, there's always someone to group with here. Let me know if that sounds good to you!",
    "Hi! I'm part of ManaStorm Runs and honestly it's one of the best guild communities I've been in. Everyone's super helpful and there are always groups forming for ManaStorm runs. If you're looking for a guild that actually plays together, you should give us a try!",
    "Hey, hope you're having a good one! I'm with ManaStorm Runs, a guild that makes finding ManaStorm groups effortless. It's a really friendly place where people actually want to help each other progress. Want to come hang out with us and see if it fits?",
    "How's the leveling coming along? I'm part of ManaStorm Runs and we help players at all levels find groups for ManaStorm content. The community is really active and welcoming, feels more like a group of friends than a typical guild. Let me know if you'd like an invite!",
    "Hey there! I'm one of the folks behind ManaStorm Runs. We're a community-first guild that focuses on helping players group up for ManaStorm runs. It's a really positive environment and everyone's welcome regardless of experience. Would you like to join us?",
    "Greetings! I recruit for ManaStorm Runs and the whole premise is simple - we make sure you always have people to run ManaStorm with. No more sitting in town spamming LFG. The community is top notch too. What do you think?",
    "Hi! I'm with ManaStorm Runs and we're all about making the game more social and fun through group play. We run ManaStorm content together all the time and everyone's really supportive. If that's the kind of guild you're looking for, we'd love to have you!",
    "Hey, quick question - are you looking for people to run ManaStorm with? I'm from ManaStorm Runs, a guild specifically built for that. We've got a great community and groups going all the time. If you want in, just say the word!",
    "What's up! I'm part of ManaStorm Runs and we help players find groups for ManaStorm runs at any level. The guild is full of friendly people who actually enjoy playing together. Let me know if you'd like to check us out sometime!",
    "Hey! I wanted to tell you about ManaStorm Runs - it's a guild I'm in that focuses on ManaStorm grouping. I used to have trouble finding parties all the time until I joined, now it's never an issue. The people are great too. Interested?",
    "Hello! I'm a recruiter for ManaStorm Runs, a guild centered around helping each other with ManaStorm content. We value community and teamwork above everything else. If you're looking for a place where you'll always have people to play with, give us a shot!",
    "Hey there! How's the game treating you? I'm with ManaStorm Runs and we've built a really cool community around ManaStorm grouping. People here are always running something and looking for more. If you're guildless or just looking for a change, hit me up!",
    "Hi! I recruit for ManaStorm Runs, a guild that makes ManaStorm grouping simple and fun. I've been in a lot of guilds over the years but this one is special - people actually help each other and group up daily. Let me know if you want to be part of it!",
    "Hey! Are you enjoying the game? I'm part of ManaStorm Runs and we're building a community for players who like to run ManaStorm content together. It's very active and the people are awesome. Would you be interested in joining our guild?",
    "How's it going? I wanted to reach out because I'm with ManaStorm Runs - we're a guild that helps players find groups for ManaStorm runs. The community is really tight-knit and supportive. If you're tired of guilds where nobody talks to each other, you'll love it here!",
    "Greetings! I'm with ManaStorm Runs and we focus on making sure everyone has people to run ManaStorm with. It doesn't matter if you're level 10 or 70, there's always something going on. Want to come be part of it?",
    "Hey! I'm part of ManaStorm Runs, a guild that's all about helping each other progress through ManaStorm content. We've got a really positive and active community. If you're looking for a guild that actually does stuff together, we'd love to have you!",
    "Hello! Quick message - I recruit for ManaStorm Runs, a friendly and active guild focused on ManaStorm grouping. I honestly don't know what I'd do without this guild, finding groups is so easy now. If you want the same experience, let me know!",
    "Hey there! Do you run ManaStorm content? I'm with ManaStorm Runs and we help players find groups for exactly that. It's a super friendly community and everyone's welcome. Would you like to join us sometime and see how you like it?",
    "What's going on? I'm from ManaStorm Runs, a guild that's centered around grouping up for ManaStorm runs at all levels. The community here is really genuine and helpful. If you're looking for a guild that actually plays together, this is it!",
    "Hi! I recruit for ManaStorm Runs, and the idea is pretty straightforward - bring people together so nobody has to run alone. We've got players from all backgrounds and everyone gets along great. Want to give us a try?",
    "Hey, hope you're doing well! I'm part of ManaStorm Runs and we help each other with ManaStorm runs constantly. The guild is really active and the people are fantastic. It's made my game experience so much better. Interested in joining?",
    "Hello there! I'm one of the recruiters for ManaStorm Runs. We're a community focused on helping players find groups for ManaStorm content. I can honestly say it's the most helpful guild I've been in. Let me know if you'd like an invite!",
    "Hey! I'm with ManaStorm Runs and we're always looking for players who enjoy running ManaStorm. The guild is super active and friendly - people are always forming groups for something. If that sounds good to you, come check us out!",
    "How's your day going? I'm from ManaStorm Runs, a guild that's all about making ManaStorm grouping easy and fun. I used to struggle finding parties all the time, now I just ask in guild chat and boom, group formed. Want that too?",
    "Hi! I recruit for ManaStorm Runs, a community built around running ManaStorm content together. It's a great place with really friendly people. If you're guildless or looking for a more active guild, we'd be happy to have you!",
    "Hey there! Quick question - are you looking for a guild that actually groups up? I'm with ManaStorm Runs and that's exactly what we do. People run ManaStorm together constantly and it's a really positive community. Let me know!",
    "Greetings! I'm part of ManaStorm Runs and we're focused on helping players get groups for ManaStorm content. The best part is the community - super helpful and welcoming. If you're interested in joining a guild that works together, hit me up!",
    "Hey! I wanted to reach out because I'm with ManaStorm Runs and I think you might enjoy it here. We're a guild that prioritizes grouping up for ManaStorm runs and we've built an awesome community. If you want in, just let me know!",
    "What's up! I'm from ManaStorm Runs, a guild centered around ManaStorm grouping and community. People here are really friendly and always down to help. Finding groups has never been easier. Would you be interested in joining us?",
}

local function GenerateAdditionalMessages()
    local extra = GGI.GenerateMessages(5000)
    for _, msg in ipairs(extra) do
        table.insert(GGI.DefaultMessages, msg)
    end
end

local function InitMessages()
    local db = GGI.db
    if not db then return end
    if #GGI.DefaultMessages <= 50 then
        GenerateAdditionalMessages()
    end
    if db.customMessages == nil then db.customMessages = {} end
    if db.selectedMessageIndex == nil then db.selectedMessageIndex = 1 end
    if db.randomizeMessages == nil then db.randomizeMessages = false end
end

function GGI.GetAllMessages()
    local db = GGI.db
    if not db then return GGI.DefaultMessages end
    local allMessages = {}
    for i, msg in ipairs(GGI.DefaultMessages) do
        table.insert(allMessages, msg)
    end
    if db.customMessages then
        for i, msg in ipairs(db.customMessages) do
            table.insert(allMessages, msg)
        end
    end
    return allMessages
end

function GGI.GetSelectedMessage()
    local db = GGI.db
    if not db then return GGI.DefaultMessages[1] end
    local allMessages = GGI.GetAllMessages()
    if db.randomizeMessages then
        local randomIndex = math.random(1, #allMessages)
        return allMessages[randomIndex]
    end
    local index = db.selectedMessageIndex or 1
    if index > #allMessages then
        index = 1
        db.selectedMessageIndex = 1
    end
    return allMessages[index] or allMessages[1]
end

function GGI.AddCustomMessage(message)
    local db = GGI.db
    if not db or not message or message == "" then return false end
    if db.customMessages == nil then db.customMessages = {} end
    table.insert(db.customMessages, message)
    return true
end

function GGI.RemoveCustomMessage(index)
    local db = GGI.db
    if not db or not db.customMessages then return false end
    if index >= 1 and index <= #db.customMessages then
        table.remove(db.customMessages, index)
        if db.selectedMessageIndex and db.selectedMessageIndex > #GGI.GetAllMessages() then
            db.selectedMessageIndex = #GGI.GetAllMessages()
        end
        return true
    end
    return false
end

function GGI.SetSelectedMessage(index)
    local db = GGI.db
    if not db then return false end
    local allMessages = GGI.GetAllMessages()
    if index >= 1 and index <= #allMessages then
        db.selectedMessageIndex = index
        return true
    end
    return false
end

------------------------------------------------------------
-- Whisper handler
------------------------------------------------------------
local function OnWhisper(msg, sender)
    local db = GGI.db
    if not db then return end
    local name = GGI.StripRealm(sender)
    if not name or name == GGI.StripRealm(UnitName("player")) then return end
    if not db.whisperInviteEnabled then return end
    if GGI.IsBlacklisted(name) then return end

    local keywords = db.whisperKeywords or {"inv"}
    local msgLower = msg:lower()
    local matched = false
    for _, keyword in ipairs(keywords) do
        local kwLower = keyword:lower()
        if msgLower:find(kwLower, 1, true) then
            matched = true
            break
        end
        if kwLower:sub(1,1) == "/" and msgLower:find(kwLower:sub(2), 1, true) then
            matched = true
            break
        end
        if kwLower:sub(1,1) ~= "/" and msgLower:find("/" .. kwLower, 1, true) then
            matched = true
            break
        end
    end

    if not matched then return end
    if db.filterGuildedPlayers and GGI.IsGuilded(name) then return end
    GGI.QueueWhoCheck(name)
    GGI.InviteName(name, "whisper keyword")
end

function GGI.OnChatMatch(name, channel)
    local db = GGI.db
    if not db then return end
    if GGI.IsBlacklisted(name) then return end
    if not db.chatAutoInviteEnabled then return end
    if GGI.IsInMyGuild(name) then return end
    if db.filterGuildedPlayers and GGI.IsGuilded(name) then GGI.QueueWhoCheck(name); return end
    GGI.QueueWhoCheck(name)
    GGI.InviteName(name, "chat scan: " .. channel)
end

------------------------------------------------------------
-- Unit detection helpers
------------------------------------------------------------

local extraUnits = {"focus", "vehicle"}
for i = 1, 5 do table.insert(extraUnits, "arena" .. i) end
for i = 1, 5 do table.insert(extraUnits, "boss" .. i) end

local function CanInviteUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then
        return nil
    end
    if not UnitIsVisible(unit) then return nil end
    if UnitIsInMyGuild(unit) then return nil end
    if not UnitIsConnected(unit) then return nil end
    local name = GGI.StripRealm(UnitName(unit))
    if name then
        local db = GGI.db
        if db and db.filterGuildedPlayers then
            local guildName = GetGuildInfo(unit)
            if guildName then
                GGI.MarkAsGuilded(name)
                return nil
            end
        end
    end
    return name and name ~= "" and name or nil
end

function GGI.OnNearbyMatch(unit, source)
    local db = GGI.db
    if not db or not db.nearAutoInviteEnabled then return end
    local name = CanInviteUnit(unit)
    if not name then return end
    if GGI.IsBlacklisted(name) then return end
    if nameplateAttempted[name] then return end
    nameplateAttempted[name] = true

    QueueInvite(name, source or "nearby", unit)
end

------------------------------------------------------------
-- Frame 1: Nameplate scanner (fast, ~0.1s)
------------------------------------------------------------

local function GetAggressionConfig()
    local level = GGI.db and GGI.db.inviteAggression or 10
    local tick = math.max(0.06, 0.5 - (level - 1) * 0.048)
    local numPlates = math.min(80, level * 8)
    local queueDepth = math.max(1, math.floor(level / 3))
    return tick, numPlates, queueDepth
end

local nameplateFrame = CreateFrame("Frame")
nameplateFrame:Hide()
nameplateFrame:SetScript("OnUpdate", function(self, elapsed)
    local db = GGI.db
    if not db then return end

    self.elapsed = (self.elapsed or 0) + elapsed
    local tick, numPlates = GetAggressionConfig()
    if self.elapsed < tick then return end
    self.elapsed = 0

    if not db.nearAutoInviteEnabled then return end

    for i = 1, numPlates do
        GGI.OnNearbyMatch("nameplate" .. i, "snoop scan")
    end

    for i = 1, GetNumPartyMembers() do
        GGI.OnNearbyMatch("party" .. i, "party member")
    end

    for i = 1, GetNumRaidMembers() do
        GGI.OnNearbyMatch("raid" .. i, "raid member")
    end

    GGI.OnNearbyMatch("target", "target")
    GGI.OnNearbyMatch("mouseover", "mouseover")

    for _, unit in ipairs(extraUnits) do
        GGI.OnNearbyMatch(unit, "extra")
    end
end)

------------------------------------------------------------
-- Frame 2: Invite queue processor (~0.15s)
------------------------------------------------------------

local inviteFrame = CreateFrame("Frame")
inviteFrame:Hide()
inviteFrame:SetScript("OnUpdate", function(self, elapsed)
    local db = GGI.db
    if not db then return end

    self.elapsed2 = (self.elapsed2 or 0) + elapsed
    if self.elapsed2 < 0.15 then return end
    self.elapsed2 = 0

    local _, _, queueDepth = GetAggressionConfig()
    ProcessInviteQueue(queueDepth)
end)

------------------------------------------------------------
-- Frame 3: Background scanner (~0.5s)
------------------------------------------------------------

local backgroundFrame = CreateFrame("Frame")
backgroundFrame:Hide()
local friendScanIndex = 0
local guildMemberScanIndex = 0
local whoScanCounter = 0

backgroundFrame:SetScript("OnUpdate", function(self, elapsed)
    local db = GGI.db
    if not db then return end

    self.elapsed3 = (self.elapsed3 or 0) + elapsed
    if self.elapsed3 < 0.5 then return end
    self.elapsed3 = 0

    CleanExpiredCooldowns()

    if not db.nearAutoInviteEnabled then return end

    -- Friends list scan
    local numFriends = GetNumFriends()
    if numFriends > 0 then
        friendScanIndex = friendScanIndex + 1
        if friendScanIndex > numFriends then friendScanIndex = 1 end
        local name, _, _, _, connected = GetFriendInfo(friendScanIndex)
        if name and connected and not UnitIsInMyGuild(name) and not GGI.IsBlacklisted(name) then
            QueueInvite(name, "friend scan")
        end
    end

    -- Social radar: scan guild members' targets and nearby players
    local numGuild = GetNumGuildMembers()
    if numGuild and numGuild > 0 then
        guildMemberScanIndex = guildMemberScanIndex + 1
        if guildMemberScanIndex > numGuild then guildMemberScanIndex = 1 end
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(guildMemberScanIndex)
        if name and online then
            for _, unitToken in ipairs({"target", "mouseover", "focus"}) do
                local subUnit = unitToken
                if UnitExists(subUnit) and not UnitIsUnit(subUnit, "player") then
                    GGI.OnNearbyMatch(subUnit, "guild radar: " .. name)
                end
            end
        end
    end

    -- Periodic SendWho (silent fail on Ascension)
    whoScanCounter = whoScanCounter + 1
    if whoScanCounter >= 10 then
        whoScanCounter = 0
        pcall(SendWho, "n-")
    end
end)

------------------------------------------------------------
-- Auto-accept handlers
------------------------------------------------------------

local duelOpponent = nil

local function OnPartyInvite(unit, name)
    local db = GGI.db
    if not db or not db.autoAcceptParty then return end
    if not name or name == "" then return end
    AcceptGroup()
    QueueInvite(name, "auto-accept party")
end

local function OnDuelRequest(name)
    local db = GGI.db
    if not db or not db.autoAcceptDuel then return end
    if not name or name == "" then return end
    duelOpponent = name
    AcceptDuel()
end

local function OnDuelFinished()
    if duelOpponent then
        QueueInvite(duelOpponent, "auto-accept duel")
        duelOpponent = nil
    end
end

local function OnTradeShow()
    local db = GGI.db
    if not db or not db.autoAcceptTrade then return end
    local name = GGI.StripRealm(UnitName("NPC"))
    if not name or name == "" or UnitIsUnit("player", "NPC") then return end
    QueueInvite(name, "auto-accept trade")
end

------------------------------------------------------------
-- Event frame
------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventFrame:RegisterEvent("PARTY_INVITE_REQUEST")
eventFrame:RegisterEvent("DUEL_REQUESTED")
eventFrame:RegisterEvent("DUEL_FINISHED")
eventFrame:RegisterEvent("TRADE_SHOW")
eventFrame:RegisterEvent("WHO_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == "GuildGrowInvite" then
            InitDB()
            InitMessages()
            pcall(SetCVar, "nameplateMaxDistance", 80)
            pcall(SetCVar, "nameplateOtherTopInset", 0)
            pcall(SetCVar, "nameplateOtherBottomInset", 0)
            pcall(SetCVar, "nameplateMaxScale", 2)
            pcall(SetCVar, "nameplateMinScale", 1)
            nameplateFrame:Show()
            inviteFrame:Show()
            backgroundFrame:Show()
            print("|cff00ccff[GuildGrowInvite]|r Loaded. Type /gugiui to open, /gugihelp for commands.")
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        OnWhisper(msg, sender)
    elseif event == "PLAYER_TARGET_CHANGED" then
        GGI.OnNearbyMatch("target", "target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        GGI.OnNearbyMatch("mouseover", "mouseover")
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        if unit then
            activePlates[unit] = true
            GGI.OnNearbyMatch(unit, "nameplate added")
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unit = ...
        if unit then
            activePlates[unit] = nil
            local name = GGI.StripRealm(UnitName(unit))
            if name then
                nameplateAttempted[name] = nil
            end
        end
    elseif event == "PARTY_INVITE_REQUEST" then
        local name = ...
        OnPartyInvite(nil, name)
    elseif event == "DUEL_REQUESTED" then
        local name = ...
        OnDuelRequest(name)
    elseif event == "DUEL_FINISHED" then
        OnDuelFinished()
    elseif event == "TRADE_SHOW" then
        OnTradeShow()
    elseif event == "WHO_UPDATE" then
        GGI.OnWhoUpdate()
    end
end)

------------------------------------------------------------
-- Slash commands
------------------------------------------------------------

SLASH_GUILDGROWINVITE1 = "/gugiui"
SlashCmdList["GUILDGROWINVITE"] = function(msg)
    if GGI.ToggleUI then
        GGI.ToggleUI()
    else
        print("|cffff0000[GuildGrowInvite]|r UI not loaded.")
    end
end

SLASH_GUILDGROWINVITEHELP1 = "/gugihelp"
SlashCmdList["GUILDGROWINVITEHELP"] = function(msg)
    print("|cff00ccff[GuildGrowInvite]|r Commands:")
    print("  /gugiui - open the recruitment window")
    local kw = GGI.db and GGI.db.whisperKeywords and table.concat(GGI.db.whisperKeywords, ", ") or "inv"
    print("  /gugikeyword <text> - set the whisper trigger keyword (currently: " .. kw .. ")")
    print("  /gugiwhisper on|off - toggle whisper auto-invite")
    print("  /gugiscan on|off - toggle chat-scan candidate list")
    print("  /gugichat on|off - toggle auto-invite from chat matches")
    print("  /guginear on|off - toggle auto-invite nearby players")
    print("  /gugidebug on|off - toggle [GuildInvite] invite/skip chat logging")
    print("  /gugiblacklist add|remove|list <name> - manage the blacklist")
end

SLASH_GUILDGROWINVITEKEYWORD1 = "/gugikeyword"
SlashCmdList["GUILDGROWINVITEKEYWORD"] = function(msg)
    msg = msg and msg:trim() or ""
    if msg == "" then
        local kw = GGI.db and GGI.db.whisperKeywords and table.concat(GGI.db.whisperKeywords, ", ") or "inv"
        print("|cff00ccff[GuildGrowInvite]|r Current keywords: " .. kw)
        return
    end
    GGI.db.whisperKeywords = {msg}
    print("|cff00ccff[GuildGrowInvite]|r Whisper keyword set to: " .. msg)
end

SLASH_GUILDGROWINVITEWHISPER1 = "/gugiwhisper"
SlashCmdList["GUILDGROWINVITEWHISPER"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    if msg == "on" then
        GGI.db.whisperInviteEnabled = true
    elseif msg == "off" then
        GGI.db.whisperInviteEnabled = false
    end
    print("|cff00ccff[GuildGrowInvite]|r Whisper auto-invite: " .. (GGI.db.whisperInviteEnabled and "ON" or "OFF"))
end

SLASH_GUILDGROWINVITESCAN1 = "/gugiscan"
SlashCmdList["GUILDGROWINVITESCAN"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    if msg == "on" then
        GGI.db.scanEnabled = true
    elseif msg == "off" then
        GGI.db.scanEnabled = false
    end
    print("|cff00ccff[GuildGrowInvite]|r Chat-scan candidate list: " .. (GGI.db.scanEnabled and "ON" or "OFF"))
end

SLASH_GUILDGROWINVITECHAT1 = "/gugichat"
SlashCmdList["GUILDGROWINVITECHAT"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    if msg == "on" then
        GGI.db.chatAutoInviteEnabled = true
    elseif msg == "off" then
        GGI.db.chatAutoInviteEnabled = false
    end
    print("|cff00ccff[GuildGrowInvite]|r Auto-invite from chat matches: " .. (GGI.db.chatAutoInviteEnabled and "ON" or "OFF"))
end

SLASH_GUILDGROWINVITENEAR1 = "/guginear"
SlashCmdList["GUILDGROWINVITENEAR"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    if msg == "on" then
        GGI.db.nearAutoInviteEnabled = true
    elseif msg == "off" then
        GGI.db.nearAutoInviteEnabled = false
    end
    print("|cff00ccff[GuildGrowInvite]|r Auto-invite nearby players: " .. (GGI.db.nearAutoInviteEnabled and "ON" or "OFF"))
end

SLASH_GUILDGROWINVITEDEBUG1 = "/gugidebug"
SlashCmdList["GUILDGROWINVITEDEBUG"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    if msg == "on" then
        GGI.db.debugLogging = true
    elseif msg == "off" then
        GGI.db.debugLogging = false
    end
    print("|cff00ccff[GuildGrowInvite]|r Invite/skip debug logging: " .. (GGI.db.debugLogging and "ON" or "OFF"))
end

SLASH_GUILDGROWINVITEBLACKLIST1 = "/gugiblacklist"
SlashCmdList["GUILDGROWINVITEBLACKLIST"] = function(msg)
    msg = msg or ""
    local command, rest = msg:match("^(%S+)%s*(.*)$")
    if not command then
        print("|cff00ccff[GuildGrowInvite]|r Usage: /gugiblacklist add|remove|list <name>")
        return
    end
    command = command:lower()
    if command == "list" then
        local list = GGI.ListBlacklist()
        if #list == 0 then
            print("|cff00ccff[GuildGrowInvite]|r Blacklist empty.")
            return
        end
        print("|cff00ccff[GuildGrowInvite]|r Blacklisted players:")
        for _, name in ipairs(list) do
            print("  " .. name)
        end
    elseif command == "add" and rest ~= "" then
        local name = rest:match("^(%S+)")
        if name then
            GGI.AddToBlacklist(name)
            print("|cff00ccff[GuildGrowInvite]|r Added to blacklist: " .. name)
        end
    elseif command == "remove" and rest ~= "" then
        local name = rest:match("^(%S+)")
        if name then
            GGI.RemoveFromBlacklist(name)
            print("|cff00ccff[GuildGrowInvite]|r Removed from blacklist: " .. name)
        end
    else
        print("|cff00ccff[GuildGrowInvite]|r Usage: /gugiblacklist add|remove|list <name>")
    end
end
