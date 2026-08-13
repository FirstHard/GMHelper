local _, GMH = ...

GMH.Permissions = {}

local FLAG_DEFINITIONS = {{
    index = 1,
    key = "guildchat_listen",
    label = "Чтение гильдейского чата"
}, {
    index = 2,
    key = "guildchat_speak",
    label = "Сообщения в гильдейский чат"
}, {
    index = 3,
    key = "officerchat_listen",
    label = "Чтение офицерского чата"
}, {
    index = 4,
    key = "officerchat_speak",
    label = "Сообщения в офицерский чат"
}, {
    index = 5,
    key = "promote",
    label = "Повышение звания"
}, {
    index = 6,
    key = "demote",
    label = "Понижение звания"
}, {
    index = 7,
    key = "invite_member",
    label = "Приглашение в гильдию"
}, {
    index = 8,
    key = "remove_member",
    label = "Исключение из гильдии"
}, {
    index = 9,
    key = "set_motd",
    label = "Изменение сообщения дня"
}, {
    index = 10,
    key = "edit_public_note",
    label = "Изменение общей заметки"
}, {
    index = 11,
    key = "view_officer_note",
    label = "Просмотр офицерской заметки"
}, {
    index = 12,
    key = "edit_officer_note",
    label = "Изменение офицерской заметки"
}, {
    index = 13,
    key = "modify_guild_info",
    label = "Изменение информации о гильдии"
}, {
    index = 15,
    key = "withdraw_repair",
    label = "Ремонт за счёт гильдии"
}, {
    index = 16,
    key = "withdraw_gold",
    label = "Снятие золота из банка"
}, {
    index = 17,
    key = "create_guild_event",
    label = "Создание событий гильдии"
}, {
    index = 18,
    key = "authenticator",
    label = "Аутентификатор"
}, {
    index = 19,
    key = "modify_bank_tabs",
    label = "Изменение вкладок банка"
}, {
    index = 20,
    key = "remove_guild_event",
    label = "Удаление событий гильдии"
}}

GMH.Permissions.FlagDefinitions = FLAG_DEFINITIONS

function GMH.Permissions:GetCurrent()
    local guildName, rankName, rankIndex = GetGuildInfo("player")

    local result = {
        available = false,
        guildName = guildName,
        rankName = rankName,
        rankIndex = rankIndex,
        flags = {}
    }

    if not guildName or rankIndex == nil then
        return result
    end

    if not GuildControlGetRankFlags then
        return result
    end

    if GuildControlSetRank then
        pcall(GuildControlSetRank, rankIndex + 1)
    end

    local ok, values = pcall(function()
        return {GuildControlGetRankFlags()}
    end)

    if not ok then
        return result
    end

    result.available = true

    for _, definition in ipairs(FLAG_DEFINITIONS) do
        result.flags[definition.key] = values[definition.index] == 1 or values[definition.index] == true
    end

    return result
end

function GMH.Permissions:Can(permissionKey)
    local current = self:GetCurrent()
    return current.available and current.flags[permissionKey] == true
end

function GMH.Permissions:CanAny(...)
    local current = self:GetCurrent()

    if not current.available then
        return false
    end

    local keys = {...}

    for _, key in ipairs(keys) do
        if current.flags[key] then
            return true
        end
    end

    return false
end
