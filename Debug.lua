local _, GMH = ...

GMH.Debug = {}
GMH.Debug.VERSION = 2

local function Serialize(value)
    local valueType = type(value)

    if valueType == "nil" then
        return {
            type = "nil"
        }
    elseif valueType == "boolean" or valueType == "number" or valueType == "string" then
        return {
            type = valueType,
            value = value
        }
    end

    return {
        type = valueType,
        value = tostring(value)
    }
end

function GMH.Debug:Run()
    GMHelperDebugDB = {
        version = self.VERSION,
        last = {
            timestamp = date("%Y-%m-%d %H:%M:%S"),
            player = UnitName("player"),
            guild = GMH:GetPlayerGuildInfo(),
            api = {}
        }
    }

    local functions = {"GetGuildInfo", "GetNumGuildMembers", "GetGuildRosterInfo", "GuildRoster",
                       "GuildControlGetNumRanks", "GuildControlGetRankName", "GuildControlSetRank",
                       "GuildControlGetRankFlags", "GuildPromote", "GuildDemote", "GuildInvite", "GuildUninvite",
                       "GuildSetLeader"}

    for _, name in ipairs(functions) do
        GMHelperDebugDB.last.api[name] = type(_G[name]) == "function"
    end

    if GuildControlGetRankFlags then
        GMHelperDebugDB.last.currentRankFlags = {}

        if GuildControlSetRank then
            local _, _, rankIndex = GetGuildInfo("player")
            if rankIndex ~= nil then
                pcall(GuildControlSetRank, rankIndex + 1)
            end
        end

        local ok, values = pcall(function()
            return {GuildControlGetRankFlags()}
        end)

        if ok then
            for i = 1, 20 do
                GMHelperDebugDB.last.currentRankFlags[i] = Serialize(values[i])
            end
        end
    end

    if GetNumGuildMembers and GetGuildRosterInfo then
        local total = select(1, GetNumGuildMembers()) or 0
        GMHelperDebugDB.last.roster = {}

        for index = 1, total do
            local ok, name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline,
                status, class = pcall(GetGuildRosterInfo, index)

            if ok then
                GMHelperDebugDB.last.roster[index] = {
                    name = name,
                    rankName = rankName,
                    rankIndex = rankIndex,
                    level = level,
                    classDisplayName = classDisplayName,
                    class = class,
                    zone = zone,
                    publicNote = publicNote,
                    officerNote = officerNote,
                    isOnline = isOnline,
                    status = status
                }
            end
        end
    end

    if GuildControlGetNumRanks and GuildControlGetRankName then
        local count = GuildControlGetNumRanks() or 0
        GMHelperDebugDB.last.ranks = {}

        for index = 1, count do
            GMHelperDebugDB.last.ranks[index] = {
                index = index,
                name = GuildControlGetRankName(index)
            }
        end
    end

    GMH:Print("Диагностика сохранена в GMHelper.lua.")
end
