local ADDON_NAME, GMH = ...

GMH.NAME = "GMHelper - Помощник Гильдмастера"
GMH.VERSION = "1.1.4"
GMH.DB_VERSION = 4

GMHelperDB = GMHelperDB or {}
GMHelperDebugDB = GMHelperDebugDB or {}

UISpecialFrames = UISpecialFrames or {}

local function RegisterSpecialFrame(frameName)
    for _, name in ipairs(UISpecialFrames) do
        if name == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

RegisterSpecialFrame("GMHelperMainFrame")
RegisterSpecialFrame("GMHelperSettingsFrame")

local function InitDB()
    GMHelperDB.version = GMH.DB_VERSION

    GMHelperDB.window = GMHelperDB.window or {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0
    }

    GMHelperDB.button = GMHelperDB.button or {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 220,
        y = -120,
        mode = "free"
    }

    GMHelperDB.button.mode = GMHelperDB.button.mode or "free"

    GMHelperDB.roster = GMHelperDB.roster or {
        sortColumn = "name",
        sortAscending = true,
        minLevel = "",
        maxLevel = "",
        search = "",
        onlineOnly = false,
        minOfflineDays = ""
    }
end

function GMH:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff70b8ff[GMHelper]|r " .. tostring(message))
end

function GMH:IsGuildMember()
    local guildName = GetGuildInfo("player")
    return guildName ~= nil
end

function GMH:GetPlayerGuildInfo()
    local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")

    return {
        guildName = guildName,
        rankName = guildRankName,
        rankIndex = guildRankIndex
    }
end

function GMH:RequestGuildRoster()
    if GuildRoster then
        GuildRoster()
    end
end

function GMH:Initialize()
    InitDB()

    if GameMenuFrame then
        GameMenuFrame:HookScript("OnShow", function()
            if GMH.UI and GMH.UI.mainFrame then
                GMH.UI.mainFrame:Hide()
            end
        end)
    end

    if self.UI and self.UI.Initialize then
        self.UI:Initialize()
    end

    -- UI уже создан: теперь запрашиваем ростер.
    self:RequestGuildRoster()

    self.initialized = true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        GMH:Initialize()

    elseif event == "PLAYER_LOGIN" then
        -- После входа ростер может быть ещё не загружен.
        -- Сначала запрашиваем его, затем обновляем UI.
        GMH:RequestGuildRoster()

        if GMH.UI then
            if GMH.UI.UpdateColumns then
                GMH.UI:UpdateColumns()
            end
            if GMH.UI.Refresh then
                GMH.UI:Refresh()
            end
        end

        -- Дополнительное обновление через небольшую задержку,
        -- если первый ответ GuildRoster ещё не успел прийти.
        if GMH.UI and GMH.UI.ScheduleRosterRefresh then
            GMH.UI:ScheduleRosterRefresh()
        end

    elseif event == "GUILD_ROSTER_UPDATE" then
        if GMH.UI and GMH.UI.OnGuildRosterUpdate then
            GMH.UI:OnGuildRosterUpdate()
        end
    end
end)

SLASH_GMHELPER1 = "/gmhelper"
SLASH_GMHELPER2 = "/gmh"
SLASH_GMHELPER3 = "/gm"
SLASH_GMHELPER4 = "/guildmanager"

SlashCmdList.GMHELPER = function(message)
    message = string.lower(message or "")

    if message == "debug" then
        if GMH.Debug and GMH.Debug.Run then
            GMH.Debug:Run()
        else
            GMH:Print("Модуль диагностики не загружен.")
        end
        return
    end

    if GMH.UI and GMH.UI.Toggle then
        GMH.UI:Toggle()
    end
end
