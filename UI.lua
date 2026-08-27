local _, GMH = ...

GMH.UI = {}

GMH.UI.rosterModeActive = false
GMH.UI.previousShowOffline = nil
GMH.UI.rosterCache = nil

local COLORS = {
    background = {0.025, 0.03, 0.04, 0.94},
    header = {0.06, 0.07, 0.09, 0.97},
    toolbar = {0.045, 0.05, 0.065, 0.97},
    row = {0.035, 0.04, 0.052, 0.90},
    rowAlt = {0.045, 0.05, 0.065, 0.90},
    hover = {0.10, 0.16, 0.24, 0.95},
    accent = {0.30, 0.65, 1.00, 1.00},
    text = {0.90, 0.92, 0.96, 1.00},
    muted = {0.55, 0.59, 0.66, 1.00},
    allowed = {0.35, 0.90, 0.55, 1.00},
    denied = {0.95, 0.38, 0.38, 1.00}
}

local FONT = "Fonts\\FRIZQT__.TTF"

local function SetSolidBackground(frame, color)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(frame)
    texture:SetTexture(1, 1, 1, 1)
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
    frame._background = texture
end

local function CreateText(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "ARTWORK")
    fs:SetFont(FONT, size, "")
    fs:SetTextColor(color[1], color[2], color[3], color[4])
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

local function CreateDivider(parent, y, width)
    local texture = parent:CreateTexture(nil, "ARTWORK")
    texture:SetTexture(1, 1, 1, 1)
    texture:SetVertexColor(1, 1, 1, 0.08)
    texture:SetHeight(1)
    texture:SetWidth(width)
    texture:SetPoint("TOP", parent, "TOP", 0, y)
    return texture
end

local function CreateButton(parent, width, height, text)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(button)
    background:SetTexture(1, 1, 1, 1)
    background:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.16)

    local label = CreateText(button, 11, COLORS.text, "CENTER")
    label:SetAllPoints(button)
    label:SetText(text)

    button:SetScript("OnEnter", function()
        if button:IsEnabled() then
            background:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.28)
        end
    end)

    button:SetScript("OnLeave", function()
        if button:IsEnabled() then
            background:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.16)
        end
    end)

    button._label = label
    button._background = background

    return button
end

local function EnableMoving(frame, dragButton)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag(dragButton or "LeftButton")

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local point, _, relativePoint, x, y = self:GetPoint()
        GMHelperDB.window.point = point
        GMHelperDB.window.relativePoint = relativePoint
        GMHelperDB.window.x = x
        GMHelperDB.window.y = y
    end)
end

local function GetMinimapButtonRadius()
    if Minimap and Minimap.GetWidth then
        return 80 * (Minimap:GetWidth() / 150)
    end
    return 80
end

local function NormalizeAngle(angle)
    while angle > math.pi do
        angle = angle - (2 * math.pi)
    end
    while angle < -math.pi do
        angle = angle + (2 * math.pi)
    end
    return angle
end

local function PositionButtonOnMinimap(button, angle)
    if not button or not Minimap then
        return
    end

    angle = NormalizeAngle(tonumber(angle) or math.rad(45))
    local scale = Minimap:GetWidth() / 150
    local radius = 80 * scale
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)

    GMHelperDB.button.angle = angle
    GMHelperDB.button.radius = radius
end

local function GetCursorUIPosition()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x / scale, y / scale
end

local function UpdateToggleButtonVisualState(button)
    if not button then
        return
    end

    local mode = GMHelperDB.button.mode or "free"
    if mode == "minimap" then
        button:SetSize(32, 32)
        if Minimap then
            button:SetFrameStrata("MEDIUM")
            button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
        end
        if button.icon then
            button.icon:SetSize(22, 22)
            button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
            pcall(function() button.icon:SetTexCoord(0.10, 0.90, 0.10, 0.90) end)
        end
        if button._minimapBorder then
            button._minimapBorder:SetSize(56, 56)
            button._minimapBorder:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
            button._minimapBorder:Show()
        end
    else
        button:SetSize(48, 48)
        button:SetFrameStrata("MEDIUM")
        button:SetFrameLevel(100)
        if button.icon then
            button.icon:SetSize(42, 42)
            button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
            pcall(function() button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end)
        end
        if button._minimapBorder then
            button._minimapBorder:Hide()
        end
    end
end

local function EnableMovingButton(button)
    button:SetMovable(true)
    button:EnableMouse(true)

    if GMHelperDB.button.mode == "minimap" then
        button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart", function(self)
            self:SetScript("OnUpdate", function()
                local mx, my = Minimap:GetCenter()
                local px, py = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                px, py = px / scale, py / scale

                GMHelperDB.button.angle = math.atan2(py - my, px - mx)
                PositionButtonOnMinimap(self, GMHelperDB.button.angle)
            end)
        end)

        button:SetScript("OnDragStop", function(self)
            self:SetScript("OnUpdate", nil)
        end)

        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(self, mouseButton)
            if mouseButton == "RightButton" then
                GMH.UI:ToggleSettings()
            elseif mouseButton == "LeftButton" then
                GMH.UI:Toggle()
            end
        end)
    else
        button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)

        button:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()

            local point, _, relativePoint, offsetX, offsetY = self:GetPoint()
            if point and relativePoint then
                GMHelperDB.button.freePoint = point
                GMHelperDB.button.freeRelativePoint = relativePoint
                GMHelperDB.button.freeX = offsetX
                GMHelperDB.button.freeY = offsetY
            end
        end)

        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(self, mouseButton)
            if mouseButton == "RightButton" then
                GMH.UI:ToggleSettings()
            elseif mouseButton == "LeftButton" then
                GMH.UI:Toggle()
            end
        end)
    end
end

local function ApplySavedPosition(frame, data, defaultPoint, defaultRelativePoint, defaultX, defaultY)
    frame:ClearAllPoints()
    frame:SetPoint(data.point or defaultPoint, UIParent, data.relativePoint or defaultRelativePoint, data.x or defaultX,
        data.y or defaultY)
end

local function Trim(value)
    value = tostring(value or "")
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function Lower(value)
    return string.lower(tostring(value or ""))
end

local function ParseLevel(value)
    value = Trim(value)

    if value == "" then
        return nil
    end

    local number = tonumber(value)

    if not number then
        return nil
    end

    return math.floor(number)
end

local function FormatLastOnline(member)
    if member.isOnline then
        return "Сейчас онлайн"
    end

    if not member.lastOnlineAvailable then
        return "Нет данных"
    end

    local years = tonumber(member.yearsOffline) or 0
    local months = tonumber(member.monthsOffline) or 0
    local days = tonumber(member.daysOffline) or 0
    local hours = tonumber(member.hoursOffline) or 0

    -- Один месяц и более: показываем только общее количество месяцев.
    local totalMonths = years * 12 + months

    if totalMonths >= 1 then
        return tostring(totalMonths) .. " мес."
    end

    -- Меньше месяца: показываем дни и часы.
    local parts = {}

    if days > 0 then
        parts[#parts + 1] = tostring(days) .. " д."
    end

    if hours > 0 then
        parts[#parts + 1] = tostring(hours) .. " ч."
    end

    if #parts == 0 then
        return "менее часа"
    end

    return table.concat(parts, " ")
end

local function GetLastOnlineInfo(index, isOnline)
    if isOnline then
        return true, 0, 0, 0, 0, 0
    end

    if type(GetGuildRosterLastOnline) ~= "function" then
        return false, nil, nil, nil, nil, nil
    end

    local ok, years, months, days, hours = pcall(GetGuildRosterLastOnline, index)

    if not ok then
        return false, nil, nil, nil, nil, nil
    end

    years = tonumber(years) or 0
    months = tonumber(months) or 0
    days = tonumber(days) or 0
    hours = tonumber(hours) or 0

    -- Для сортировки и фильтрации переводим время отсутствия в часы.
    local totalMonths = years * 12 + months
    local totalHours = (totalMonths * 30.5 + days) * 24 + hours

    return true, years, months, days, hours, totalHours
end

local function AddSubtleBorder(frame)
    local borderColor = {0.55, 0.59, 0.66, 0.16}

    local top = frame:CreateTexture(nil, "OVERLAY")
    top:SetTexture(1, 1, 1, 1)
    top:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    top:SetHeight(1)

    local bottom = frame:CreateTexture(nil, "OVERLAY")
    bottom:SetTexture(1, 1, 1, 1)
    bottom:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    bottom:SetHeight(1)

    local left = frame:CreateTexture(nil, "OVERLAY")
    left:SetTexture(1, 1, 1, 1)
    left:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3)
    left:SetWidth(1)

    local right = frame:CreateTexture(nil, "OVERLAY")
    right:SetTexture(1, 1, 1, 1)
    right:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    right:SetWidth(1)

    frame._noteBorder = {top, bottom, left, right}
end

local function CreateEditBox(parent, width, labelText)
    local boxFrame = CreateFrame("Frame", nil, parent)
    boxFrame:SetWidth(width)
    boxFrame:SetHeight(30)

    local label = CreateText(boxFrame, 9, COLORS.muted)
    label:SetPoint("TOPLEFT", boxFrame, "TOPLEFT", 0, 0)
    label:SetText(labelText)

    local background = boxFrame:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("BOTTOMLEFT", boxFrame, "BOTTOMLEFT", 0, 0)
    background:SetWidth(width)
    background:SetHeight(20)
    background:SetTexture(1, 1, 1, 1)
    background:SetVertexColor(1, 1, 1, 0.07)

    local editBox = CreateFrame("EditBox", nil, boxFrame)
    editBox:SetPoint("BOTTOMLEFT", boxFrame, "BOTTOMLEFT", 5, 0)
    editBox:SetWidth(width - 10)
    editBox:SetHeight(20)
    editBox:SetFont(FONT, 10, "")
    editBox:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], 1)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(64)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    boxFrame.editBox = editBox
    return boxFrame
end

function GMH.UI:CreateMainFrame()
    if self.mainFrame then
        return self.mainFrame
    end

    local frame = CreateFrame("Frame", "GMHelperMainFrame", UIParent)
    frame:SetWidth(760)
    frame:SetHeight(620)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    SetSolidBackground(frame, COLORS.background)
    EnableMoving(frame, "LeftButton")

    ApplySavedPosition(frame, GMHelperDB.window, "CENTER", "CENTER", 0, 0)

    self.mainFrame = frame

    frame:SetScript("OnHide", function()
        if GMH.UI then
            GMH.UI:HideRankMenu()
            GMH.UI:LeaveRosterMode()
        end
    end)

    ------------------------------------------------------------
    -- Заголовок
    ------------------------------------------------------------

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    header:SetHeight(46)
    SetSolidBackground(header, COLORS.header)

    local title = CreateText(header, 17, COLORS.text)
    title:SetPoint("LEFT", header, "LEFT", 18, 0)
    title:SetText(GMH.NAME)

    local version = CreateText(header, 10, COLORS.muted)
    version:SetPoint("LEFT", title, "RIGHT", 9, 0)
    version:SetText("v" .. GMH.VERSION)

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetWidth(32)
    close:SetHeight(32)
    close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    ------------------------------------------------------------
    -- Панель фильтров
    ------------------------------------------------------------

    local toolbar = CreateFrame("Frame", nil, frame)
    toolbar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -46)
    toolbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -46)
    toolbar:SetHeight(42)
    SetSolidBackground(toolbar, COLORS.toolbar)
    
    self.toolbar = toolbar

    -- Панель фильтров: одна строка.
    -- Поиск временно убран.

    local minLevel = CreateEditBox(toolbar, 58, "МИН. УР.")
    minLevel:SetPoint("TOPLEFT", toolbar, "TOPLEFT", 16, -5)
    minLevel.editBox:SetText(GMHelperDB.roster.minLevel or "")
    self.minLevelBox = minLevel.editBox

    local maxLevel = CreateEditBox(toolbar, 58, "МАКС. УР.")
    maxLevel:SetPoint("TOPLEFT", minLevel, "TOPRIGHT", 8, 0)
    maxLevel.editBox:SetText(GMHelperDB.roster.maxLevel or "")
    self.maxLevelBox = maxLevel.editBox

    local offlineValue = CreateEditBox(toolbar, 58, "ОТ")
    offlineValue:SetPoint("TOPLEFT", maxLevel, "TOPRIGHT", 10, 0)

    local savedOfflineValue = GMHelperDB.roster.minOfflineValue
    if savedOfflineValue == nil then
        savedOfflineValue = GMHelperDB.roster.minOfflineDays or ""
        GMHelperDB.roster.minOfflineValue = savedOfflineValue
    end

    offlineValue.editBox:SetText(savedOfflineValue or "")
    self.minOfflineValueBox = offlineValue.editBox

    if GMHelperDB.roster.minOfflineUnit ~= "months" and GMHelperDB.roster.minOfflineUnit ~= "days" then
        GMHelperDB.roster.minOfflineUnit = "months"
    end

    local unitButton = CreateFrame("Button", nil, toolbar)
    unitButton:SetWidth(82)
    unitButton:SetHeight(30)
    unitButton:SetPoint("TOPLEFT", offlineValue, "TOPRIGHT", 8, 0)

    local unitBg = unitButton:CreateTexture(nil, "BACKGROUND")
    unitBg:SetAllPoints(unitButton)
    unitBg:SetTexture(1, 1, 1, 1)
    unitBg:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.16)

    local unitLabel = CreateText(unitButton, 10, COLORS.text, "CENTER")
    unitLabel:SetAllPoints(unitButton)

    self.minOfflineUnitButton = unitButton
    self.minOfflineUnitBackground = unitBg
    self.minOfflineUnitLabel = unitLabel

    -- Create a small invisible EditBox to act as keyboard-focus proxy for the unit button.
    local unitProxy = CreateFrame("EditBox", nil, toolbar)
    unitProxy:SetWidth(1)
    unitProxy:SetHeight(1)
    unitProxy:SetAutoFocus(false)
    unitProxy:SetScript("OnEditFocusGained", function()
        unitButton:LockHighlight()
    end)
    unitProxy:SetScript("OnEditFocusLost", function()
        unitButton:UnlockHighlight()
    end)
    unitProxy:SetScript("OnEnterPressed", function(self)
        unitButton:Click()
        self:ClearFocus()
    end)
    unitProxy:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    self.minOfflineUnitProxy = unitProxy

    local unitMenu = CreateFrame("Frame", nil, toolbar)
    unitMenu:SetWidth(82)
    unitMenu:SetHeight(54)
    unitMenu:SetFrameStrata("TOOLTIP")
    unitMenu:Hide()
    SetSolidBackground(unitMenu, COLORS.header)

    local function CreateUnitOption(text, value, offsetY)
        local option = CreateFrame("Button", nil, unitMenu)
        option:SetWidth(82)
        option:SetHeight(27)
        option:SetPoint("TOPLEFT", unitMenu, "TOPLEFT", 0, offsetY)

        local bg = option:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(option)
        bg:SetTexture(1, 1, 1, 1)
        bg:SetVertexColor(1, 1, 1, 0.03)

        local label = CreateText(option, 10, COLORS.text, "CENTER")
        label:SetAllPoints(option)
        label:SetText(text)

        option:SetScript("OnEnter", function()
            bg:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.16)
        end)

        option:SetScript("OnLeave", function()
            bg:SetVertexColor(1, 1, 1, 0.03)
        end)

        option:SetScript("OnClick", function()
            GMHelperDB.roster.minOfflineUnit = value
            unitMenu:Hide()
            self:ClearRosterSelection()
            self:UpdateOfflineFilterUnit()
            self:RefreshRoster()
            -- return focus to the unit proxy so keyboard users keep context
            if self.minOfflineUnitProxy then
                self.minOfflineUnitProxy:SetFocus()
            end
        end)
    end

    -- Tab navigation between level/offline inputs and the unit button proxy.
    -- Order: minLevel -> maxLevel -> minOfflineValue -> unitProxy -> minLevel
    if self.minLevelBox and self.maxLevelBox and self.minOfflineValueBox and self.minOfflineUnitProxy then
        local minBox = self.minLevelBox
        local maxBox = self.maxLevelBox
        local offBox = self.minOfflineValueBox
        local proxy = self.minOfflineUnitProxy

        minBox:SetScript("OnTabPressed", function(self)
            if IsShiftKeyDown() then
                proxy:SetFocus()
            else
                maxBox:SetFocus()
            end
        end)

        maxBox:SetScript("OnTabPressed", function(self)
            if IsShiftKeyDown() then
                minBox:SetFocus()
            else
                offBox:SetFocus()
            end
        end)

        offBox:SetScript("OnTabPressed", function(self)
            if IsShiftKeyDown() then
                maxBox:SetFocus()
            else
                proxy:SetFocus()
            end
        end)

        proxy:SetScript("OnTabPressed", function(self)
            if IsShiftKeyDown() then
                offBox:SetFocus()
            else
                minBox:SetFocus()
            end
        end)
    end
    
    CreateUnitOption("Месяцы", "months", 0)
    CreateUnitOption("Дни", "days", -27)

    self.minOfflineUnitMenu = unitMenu

    unitButton:SetScript("OnClick", function()
        if unitMenu:IsShown() then
            unitMenu:Hide()
        else
            unitMenu:ClearAllPoints()
            unitMenu:SetPoint("TOPLEFT", unitButton, "BOTTOMLEFT", 0, -2)
            unitMenu:Show()
        end
    end)

    -- После максимального уровня: фильтр по давности.
    -- Затем режим отображения, сброс фильтров.
    local onlineButton = CreateFrame("Button", nil, toolbar)
    onlineButton:SetWidth(100)
    onlineButton:SetHeight(30)
    onlineButton:SetPoint("TOPLEFT", unitButton, "TOPRIGHT", 8, 0)

    local onlineBg = onlineButton:CreateTexture(nil, "BACKGROUND")
    onlineBg:SetAllPoints(onlineButton)
    onlineBg:SetTexture(1, 1, 1, 1)

    local onlineLabel = CreateText(onlineButton, 10, COLORS.text, "CENTER")
    onlineLabel:SetAllPoints(onlineButton)

    self.onlineButton = onlineButton
    self.onlineButtonBackground = onlineBg
    self.onlineButtonLabel = onlineLabel

    -- Tooltip and hover behavior: show explanatory tooltip when disabled by offline filter
    onlineButton:EnableMouse(true)
    onlineButton:SetMotionScriptsWhileDisabled(true)
    onlineButton:SetScript("OnEnter", function()
        if self.onlineButtonDisabledByFilter then
            GameTooltip:SetOwner(onlineButton, "ANCHOR_RIGHT")
            GameTooltip:SetText("Недоступно при установленном фильтре по времени отсутствия")
            GameTooltip:Show()
        else
            GameTooltip:SetOwner(onlineButton, "ANCHOR_RIGHT")
            GameTooltip:SetText(GMHelperDB.roster.onlineOnly and "Показаны только онлайн" or "Показать только онлайн")
            GameTooltip:Show()
        end
    end)
    onlineButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local resetButton = CreateButton(toolbar, 78, 30, "Сбросить")
    resetButton:SetPoint("TOPLEFT", onlineButton, "TOPRIGHT", 8, 0)
    resetButton:SetScript("OnClick", function()
        GMHelperDB.roster.search = ""
        GMHelperDB.roster.minLevel = ""
        GMHelperDB.roster.maxLevel = ""
        GMHelperDB.roster.minOfflineValue = ""
        GMHelperDB.roster.minOfflineDays = ""
        GMHelperDB.roster.minOfflineUnit = "months"
        GMHelperDB.roster.onlineOnly = false

        self.minLevelBox:SetText("")
        self.maxLevelBox:SetText("")
        self.minOfflineValueBox:SetText("")

        self:UpdateOfflineFilterUnit()
        self:UpdateOnlineButton()
        self:ClearRosterSelection()

        self:UpdateSelectionCount()
        self:RefreshRoster()
    end)

    self.resetButton = resetButton

    self.selectionLabel = nil

    ------------------------------------------------------------
    -- Действие над выбранными персонажами.
    -- Кнопка находится строго в той же строке фильтров.
    -- При создании всегда скрыта; показывается только после выбора.
    ------------------------------------------------------------

    -- Кнопка действий для массовых операций (показывается при наличии выбора).
    local actionButton = CreateButton(toolbar, 140, 30, "Действия")
    actionButton:SetPoint("LEFT", resetButton, "RIGHT", 8, 0)
    actionButton:Hide()
    actionButton:Enable(false)

    actionButton:SetScript("OnClick", function()
        self:ShowBulkActionMenu(actionButton)
    end)

    self.actionButton = actionButton

    -- (Stop button moved into confirmation modal.)

    ------------------------------------------------------------
    -- Строка состояния между фильтрами и таблицей
    ------------------------------------------------------------

    local statusBar = CreateFrame("Frame", nil, frame)
    statusBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -88)
    statusBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -88)
    statusBar:SetHeight(28)
    SetSolidBackground(statusBar, COLORS.toolbar)

    self.statusBar = statusBar

    local statusLabel = CreateText(statusBar, 10, COLORS.muted, "LEFT")
    statusLabel:SetPoint("LEFT", statusBar, "LEFT", 10, 0)
    statusLabel:SetPoint("RIGHT", statusBar, "RIGHT", -10, 0)
    statusLabel:SetJustifyH("LEFT")
    statusLabel:SetText("Всего: 0    Показано: 0    Выбрано: 0")

    self.selectionLabel = statusLabel

    local tableHeader = CreateFrame("Frame", nil, frame)
    tableHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -116)
    tableHeader:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -116)
    tableHeader:SetHeight(30)
    SetSolidBackground(tableHeader, COLORS.header)

    self.tableHeader = tableHeader

    ------------------------------------------------------------
    -- ScrollFrame
    ------------------------------------------------------------

    local scroll = CreateFrame("ScrollFrame", "GMHelperRosterScroll", frame)
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -146)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 16)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", "GMHelperRosterContent", scroll)
    content:SetWidth(726)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local range = self:GetVerticalScrollRange()
        local step = 40

        current = current - delta * step

        if current < 0 then
            current = 0
        end

        if current > range then
            current = range
        end

        self:SetVerticalScroll(current)

        if GMH.UI.RenderVisibleRows then
            GMH.UI:RenderVisibleRows()
        end

        if GMH.UI.UpdateScrollbar then
            GMH.UI:UpdateScrollbar()
        end
    end)

    scroll:SetScript("OnVerticalScroll", function(self)
        if GMH.UI.RenderVisibleRows then
            GMH.UI:RenderVisibleRows()
        end
        if GMH.UI.UpdateScrollbar then
            GMH.UI:UpdateScrollbar()
        end
    end)

    self.scroll = scroll
    self.content = content

    ------------------------------------------------------------
    -- Собственный тонкий scrollbar
    ------------------------------------------------------------

    local scrollbar = CreateFrame("Frame", nil, frame)
    scrollbar:SetWidth(8)
    scrollbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -146)
    scrollbar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 16)
    scrollbar:Hide()

    local track = scrollbar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(scrollbar)
    track:SetTexture(1, 1, 1, 1)
    track:SetVertexColor(1, 1, 1, 0.05)

    local thumb = CreateFrame("Button", nil, scrollbar)
    thumb:SetWidth(8)
    thumb:SetHeight(40)

    local thumbTexture = thumb:CreateTexture(nil, "ARTWORK")
    thumbTexture:SetAllPoints(thumb)
    thumbTexture:SetTexture(1, 1, 1, 1)
    thumbTexture:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.55)

    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then
            return
        end

        self.dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        self.dragStartScroll = GMH.UI.scroll:GetVerticalScroll()
        self.dragRange = GMH.UI.scroll:GetVerticalScrollRange()
        self.dragAvailable = GMH.UI.scrollbar:GetHeight() - self:GetHeight()
    end)

    thumb:SetScript("OnMouseUp", function(self)
        self.dragStartY = nil
    end)

    thumb:SetScript("OnUpdate", function(self)
        if not self.dragStartY or not self.dragAvailable or self.dragAvailable <= 0 then
            return
        end

        local currentY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local deltaY = self.dragStartY - currentY
        local fraction = deltaY / self.dragAvailable
        local newScroll = self.dragStartScroll + fraction * self.dragRange

        if newScroll < 0 then
            newScroll = 0
        end

        if newScroll > self.dragRange then
            newScroll = self.dragRange
        end

        GMH.UI.scroll:SetVerticalScroll(newScroll)
    end)

    scrollbar:SetScript("OnMouseWheel", function(self, delta)
        local current = GMH.UI.scroll:GetVerticalScroll()
        local range = GMH.UI.scroll:GetVerticalScrollRange()
        local step = math.max(GMH.UI.scroll:GetHeight() - 40, 40)

        current = current - delta * step

        if current < 0 then
            current = 0
        end

        if current > range then
            current = range
        end

        GMH.UI.scroll:SetVerticalScroll(current)
        if GMH.UI.RenderVisibleRows then
            GMH.UI:RenderVisibleRows()
        end
    end)

    scrollbar.thumb = thumb

    self.scrollbar = scrollbar
    self.scrollbarThumb = thumb

    ------------------------------------------------------------
    -- Колонки
    ------------------------------------------------------------

    self.columns = {}
    self:CreateColumns()

    ------------------------------------------------------------
    -- Фильтры
    ------------------------------------------------------------

    local function FilterChanged()
        GMHelperDB.roster.minLevel = self.minLevelBox:GetText() or ""
        GMHelperDB.roster.maxLevel = self.maxLevelBox:GetText() or ""
        GMHelperDB.roster.minOfflineValue = self.minOfflineValueBox:GetText() or ""
        self:ClearRosterSelection()
        self:UpdateOnlineButton()
        self:RefreshRoster()
    end

    self.minLevelBox:SetScript("OnTextChanged", function()
        FilterChanged()
    end)

    self.maxLevelBox:SetScript("OnTextChanged", function()
        FilterChanged()
    end)

    self.minOfflineValueBox:SetScript("OnTextChanged", function()
        FilterChanged()
    end)

    onlineButton:SetScript("OnClick", function()
        if self.onlineButtonDisabledByFilter then
            return
        end
        GMHelperDB.roster.onlineOnly = not GMHelperDB.roster.onlineOnly
        self:ClearRosterSelection()
        self:UpdateOnlineButton()
        self:RefreshRoster()
    end)

    self:UpdateOfflineFilterUnit()

    return frame
end

function GMH.UI:CreateColumns()
    local canRemoveMembers = GMH.Permissions:Can("remove_member")
    local selectionWidth = canRemoveMembers and 36 or 0

    local columns = {{
        key = "selected",
        label = "",
        width = selectionWidth,
        align = "CENTER"
    }, {
        key = "name",
        label = "Персонаж",
        width = 140,
        align = "LEFT"
    }, {
        key = "level",
        label = "Ур.",
        width = 50,
        align = "CENTER"
    }, {
        key = "rankName",
        label = "Звание",
        width = 110,
        align = "LEFT"
    }, {
        key = "publicNote",
        label = "Общая заметка",
        width = 135,
        align = "LEFT"
    }, {
        key = "officerNote",
        label = "Офицерская заметка",
        width = 135,
        align = "LEFT"
    }, {
        key = "offlineHours",
        label = "Последний онлайн",
        width = 120,
        align = "LEFT"
    }}

    self.columnDefinitions = columns

    local x = 0

    for _, column in ipairs(columns) do
        local button = CreateFrame("Button", nil, self.tableHeader)
        button:SetPoint("TOPLEFT", self.tableHeader, "TOPLEFT", x, 0)
        button:SetWidth(column.width)
        button:SetHeight(30)

        column.button = button
        self.columns[column.key] = column

        if column.key == "selected" then
            -- Чекбокс заголовка создаём всегда. Его видимость и доступность
            -- обновляются в UpdateColumns(), поэтому смена персонажа/прав
            -- не зависит от того, с каким персонажем UI был создан.
            local selectAll = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
            selectAll:SetWidth(24)
            selectAll:SetHeight(24)
            selectAll:SetPoint("CENTER", button, "CENTER", 0, 0)
            selectAll:EnableMouse(true)
            selectAll:RegisterForClicks("LeftButtonUp")
            selectAll:SetHitRectInsets(0, 0, 0, 0)
            selectAll:SetShown(canRemoveMembers)
            selectAll:SetEnabled(canRemoveMembers)

            selectAll:SetScript("OnClick", function(self)
                if not GMH.Permissions:Can("remove_member") then
                    self:SetChecked(false)
                    return
                end

                local members = GMH.UI:GetRosterData()
                local visible = {}

                for _, member in ipairs(members) do
                    if GMH.UI:MatchesFilter(member) then
                        visible[#visible + 1] = member
                    end
                end

                local selectState = self:GetChecked() and true or false
                for _, member in ipairs(visible) do
                    member.selected = selectState
                end

                GMH.UI:RefreshRoster()
            end)

            column.selectAll = selectAll
            column.labelObject = nil

            button:SetScript("OnClick", function()
                if not GMH.Permissions:Can("remove_member") then
                    selectAll:SetChecked(false)
                    return
                end

                selectAll:SetChecked(not selectAll:GetChecked())
                selectAll:Click()
            end)
        else
            local label = CreateText(button, 12, COLORS.muted, column.align)
            label:SetPoint("LEFT", button, "LEFT", column.align == "LEFT" and 7 or 0, 0)
            label:SetPoint("RIGHT", button, "RIGHT", column.align == "LEFT" and -5 or 0, 0)
            label:SetText(column.label)

            button:SetScript("OnClick", function()
                self:SortBy(column.key)
            end)

            column.labelObject = label
        end

        x = x + column.width
    end
end

function GMH.UI:UpdateColumns()
    local canViewOfficerNote = GMH.Permissions:Can("view_officer_note")
    local canEditOfficerNote = GMH.Permissions:Can("edit_officer_note")
    local canRemoveMembers = GMH.Permissions:Can("remove_member")

    local officerColumn = self.columns.officerNote

    if officerColumn then
        officerColumn.button:SetShown(canViewOfficerNote)
        officerColumn.labelObject:SetText(canEditOfficerNote and "Офицерская заметка" or
                                              "Офицерская заметка")
    end

    -- Recompute selected column width and relayout header buttons
    local selectionWidth = canRemoveMembers and 36 or 0

    -- Update columnDefinitions width for selected column if present
    if self.columnDefinitions then
        for _, col in ipairs(self.columnDefinitions) do
            if col.key == "selected" then
                col.width = selectionWidth
            end
        end
    end

    -- Reposition header buttons according to new widths
    local x = 0
    for _, col in ipairs(self.columnDefinitions or {}) do
        if col.button then
            col.button:ClearAllPoints()
            col.button:SetPoint("TOPLEFT", self.tableHeader, "TOPLEFT", x, 0)
            col.button:SetWidth(col.width)
        end
        x = x + (col.width or 0)
    end

    -- Чекбокс "выбрать всех" должен появляться и после смены персонажа,
    -- даже если UI был создан персонажем без права remove_member.
    if self.columns and self.columns.selected and self.columns.selected.selectAll then
        local selectAll = self.columns.selected.selectAll
        selectAll:SetShown(canRemoveMembers)
        selectAll:SetEnabled(canRemoveMembers)
        if not canRemoveMembers then
            selectAll:SetChecked(false)
        end
    end

    -- Update existing rows to match new layout (checkbox visibility and cell positions)
    for _, row in ipairs(self.rowPool or {}) do
        if row then
            local x = selectionWidth
            row.checkbox:SetShown(canRemoveMembers)
            row.checkbox:SetEnabled(canRemoveMembers)
            -- checkbox anchor remains at 18 when shown
            row.checkbox:ClearAllPoints()
            row.checkbox:SetPoint("CENTER", row, "LEFT", 18, 0)

            if row.nameCell then
                row.nameCell:ClearAllPoints()
                row.nameCell:SetPoint("LEFT", row, "LEFT", x + 7, 0)
            end
            x = x + 140

            if row.levelCell then
                row.levelCell:ClearAllPoints()
                row.levelCell:SetPoint("LEFT", row, "LEFT", x, 0)
            end
            x = x + 50

            if row.rankCell then
                row.rankCell:ClearAllPoints()
                row.rankCell:SetPoint("LEFT", row, "LEFT", x, 0)
            end
            x = x + 110

            if row.publicButton then
                row.publicButton:ClearAllPoints()
                row.publicButton:SetPoint("LEFT", row, "LEFT", x, 0)
            end
            if row.publicCell then
                row.publicCell:ClearAllPoints()
                row.publicCell:SetPoint("LEFT", row, "LEFT", x + 7, 0)
            end
            x = x + 135

            if row.officerButton then
                row.officerButton:ClearAllPoints()
                row.officerButton:SetPoint("LEFT", row, "LEFT", x, 0)
            end
            if row.officerCell then
                row.officerCell:ClearAllPoints()
                row.officerCell:SetPoint("LEFT", row, "LEFT", x + 7, 0)
            end
            x = x + 135

            if row.lastOnlineCell then
                row.lastOnlineCell:ClearAllPoints()
                row.lastOnlineCell:SetPoint("LEFT", row, "LEFT", x + 7, 0)
            end
        end
    end
end

function GMH.UI:UpdateOfflineFilterUnit()
    local unit = GMHelperDB.roster.minOfflineUnit or "months"

    if unit == "months" then
        self.minOfflineUnitLabel:SetText("Месяцы")
    else
        self.minOfflineUnitLabel:SetText("Дни")
    end
end

function GMH.UI:UpdateOnlineButton()
    local active = GMHelperDB.roster.onlineOnly
    -- If an offline-age filter is set, the online-only mode is incompatible.
    local hasOfflineFilter = false
    local minOfflineValue = ParseLevel(GMHelperDB.roster.minOfflineValue)
    if minOfflineValue and minOfflineValue > 0 then
        hasOfflineFilter = true
    end

    self.onlineButtonDisabledByFilter = hasOfflineFilter

    if self.onlineButton then
        if hasOfflineFilter then
            -- visually disable the button and prevent clicks
            pcall(function() self.onlineButton:Disable() end)
            -- dim background
            self.onlineButtonBackground:SetVertexColor(COLORS.muted[1], COLORS.muted[2], COLORS.muted[3], 0.12)
            -- ensure internal flag is false
            GMHelperDB.roster.onlineOnly = false
            -- mark label red and ensure it's visible
            if self.onlineButtonLabel then
                self.onlineButtonLabel:SetTextColor(COLORS.denied[1], COLORS.denied[2], COLORS.denied[3], COLORS.denied[4])
                self.onlineButtonLabel:SetAlpha(1)
                -- ensure text remains correct
                local txt = GMHelperDB.roster.onlineOnly and "Показаны только онлайн" or "Все участники"
                self.onlineButtonLabel:SetText(txt)
            end
            return
        else
            pcall(function() self.onlineButton:Enable() end)
            if self.onlineButtonLabel then
                self.onlineButtonLabel:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], COLORS.text[4])
                self.onlineButtonLabel:SetAlpha(1)
                local txt = GMHelperDB.roster.onlineOnly and "Показаны только онлайн" or "Все участники"
                self.onlineButtonLabel:SetText(txt)
            end
        end
    end

    if active then
        self.onlineButtonBackground:SetVertexColor(COLORS.allowed[1], COLORS.allowed[2], COLORS.allowed[3], 0.20)
        self.onlineButtonLabel:SetText("Только онлайн")
    else
        self.onlineButtonBackground:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.16)
        self.onlineButtonLabel:SetText("Все участники")
    end
end

function GMH.UI:SortBy(columnKey)
    if GMHelperDB.roster.sortColumn == columnKey then
        GMHelperDB.roster.sortAscending = not GMHelperDB.roster.sortAscending
    else
        GMHelperDB.roster.sortColumn = columnKey
        GMHelperDB.roster.sortAscending = true
    end

    self:RefreshRoster()
end

function GMH.UI:GetRosterData()
    if self.rosterCache then
        return self.rosterCache
    end

    -- Первый запрос/обновление ростера должен проходить через
    -- RefreshRosterCache(), где корректно создаётся таблица
    -- сохранённых выделений. Ранее здесь использовалась
    -- несуществующая локальная previousSelection.
    self:RefreshRosterCache()

    return self.rosterCache or {}
end

-- Формирование нового кэша вынесено в RefreshRosterCache().
-- Старый код GetRosterData(), который напрямую читал API и
-- обращался к previousSelection, больше не используется.

function GMH.UI:RefreshRosterCache()
    if not GetNumGuildMembers or not GetGuildRosterInfo then
        self.rosterCache = {}
        return
    end

    -- Safe full-roster policy:
    -- only force Blizzard's roster to show offline members when GMHelper is the
    -- active guild UI. If the Blizzard guild window is already open, do not
    -- override its user-selected setting or fight with its display state.
    local guildWindowVisible = GuildFrame and GuildFrame:IsShown() and true or false
    local shouldForceFullRoster = not guildWindowVisible and self.rosterModeActive

    if SetGuildRosterShowOffline and shouldForceFullRoster then
        pcall(SetGuildRosterShowOffline, true)
        -- Request a fresh roster from the server to ensure data is up-to-date.
        GMH:RequestGuildRoster()
    end

    local previousSelection = {}

    for _, oldMember in ipairs(self.rosterCache or {}) do
        if oldMember.name then
            previousSelection[oldMember.name] = oldMember.selected and true or false
        end
    end

    local total = GetNumGuildMembers() or 0
    local result = {}

    for index = 1, total do
        local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class =
            GetGuildRosterInfo(index)

        if name then
            isOnline = isOnline and true or false

            local lastAvailable, yearsOffline, monthsOffline, daysOffline, hoursOffline, offlineHours =
                GetLastOnlineInfo(index, isOnline)

            local member = {
                rosterIndex = index,
                name = name,
                rankName = rankName or "",
                rankIndex = rankIndex or 0,
                level = level or 0,
                classDisplayName = classDisplayName or "",
                class = class or "",
                zone = zone or "",
                publicNote = publicNote or "",
                officerNote = officerNote or "",
                isOnline = isOnline,
                status = status or "",
                selected = previousSelection[name] and true or false,
                lastOnlineAvailable = lastAvailable,
                yearsOffline = yearsOffline or 0,
                monthsOffline = monthsOffline or 0,
                daysOffline = daysOffline or 0,
                hoursOffline = hoursOffline or 0,
                offlineHours = offlineHours or 0
            }

            member.lastOnlineText = FormatLastOnline(member)

            result[#result + 1] = member
        end
    end

    self.rosterCache = result
    self.guildRankNames = nil
end

function GMH.UI:EnterRosterMode()
    if self.rosterModeActive then
        return
    end

    self.rosterModeActive = true

    if GetGuildRosterShowOffline then
        self.previousShowOffline = GetGuildRosterShowOffline() and true or false
    else
        self.previousShowOffline = nil
    end

    -- Only force the full roster when GMHelper owns the guild UI. If Blizzard's
    -- guild window is already visible, the user's checkbox takes priority.
    if SetGuildRosterShowOffline and not (GuildFrame and GuildFrame:IsShown()) then
        SetGuildRosterShowOffline(true)
    end

    self.rosterCache = nil

    GMH:RequestGuildRoster()
end

function GMH.UI:LeaveRosterMode()
    if not self.rosterModeActive then
        return
    end

    self.rosterModeActive = false

    if SetGuildRosterShowOffline and self.previousShowOffline ~= nil then
        SetGuildRosterShowOffline(self.previousShowOffline)

        -- Возвращаем и состояние стандартного ростера.
        GMH:RequestGuildRoster()
    end

    self.previousShowOffline = nil
    self.rosterCache = nil
end

function GMH.UI:MatchesFilter(member)
    local minLevel = ParseLevel(GMHelperDB.roster.minLevel)
    local maxLevel = ParseLevel(GMHelperDB.roster.maxLevel)
    local minOfflineValue = ParseLevel(GMHelperDB.roster.minOfflineValue)
    local minOfflineUnit = GMHelperDB.roster.minOfflineUnit or "months"

    if GMHelperDB.roster.onlineOnly and not member.isOnline then
        return false
    end

    if minLevel and member.level < minLevel then
        return false
    end

    if maxLevel and member.level > maxLevel then
        return false
    end

    if minOfflineValue then
        if member.isOnline then
            return false
        end

        if not member.lastOnlineAvailable then
            return false
        end

        local minimumHours

        if minOfflineUnit == "months" then
            minimumHours = minOfflineValue * 30.5 * 24
        else
            minimumHours = minOfflineValue * 24
        end

        if member.offlineHours < minimumHours then
            return false
        end
    end

    return true
end

function GMH.UI:SortRoster(members)
    local column = GMHelperDB.roster.sortColumn or "name"
    local ascending = GMHelperDB.roster.sortAscending ~= false

    table.sort(members, function(a, b)
        -- "Последний онлайн" сортируется естественно по времени отсутствия:
        -- онлайн = -1 час (условный минимальный ключ),
        -- остальные = фактическое количество часов отсутствия.
        -- Поэтому при возрастании онлайн идут первыми,
        -- а при убывании — последними.
        if column == "offlineHours" then
            local function LastOnlineKey(member)
                if member.isOnline then
                    return -1
                end

                local hours = tonumber(member.offlineHours)

                if hours ~= nil then
                    return hours
                end

                -- Нет данных: отправляем в конец сортировки по времени.
                return math.huge
            end

            local keyA = LastOnlineKey(a)
            local keyB = LastOnlineKey(b)

            if keyA ~= keyB then
                if ascending then
                    return keyA < keyB
                end
                return keyA > keyB
            end

            local nameA = Lower(a.name)
            local nameB = Lower(b.name)

            if nameA ~= nameB then
                return nameA < nameB
            end

            return a.rosterIndex < b.rosterIndex
        end

        local va
        local vb

        -- В ростере WoW rankIndex определяет реальный порядок званий.
        if column == "rankName" then
            va = tonumber(a.rankIndex) or 0
            vb = tonumber(b.rankIndex) or 0
        else
            va = a[column]
            vb = b[column]

            if column == "name" or column == "publicNote" or column == "officerNote" then
                va = Lower(tostring(va or ""))
                vb = Lower(tostring(vb or ""))
            else
                va = tonumber(va) or 0
                vb = tonumber(vb) or 0
            end
        end

        if va == vb then
            return a.rosterIndex < b.rosterIndex
        end

        if ascending then
            return va < vb
        end

        return va > vb
    end)
end

function GMH.UI:UpdateRankContext()
    local current = GMH.Permissions:GetCurrent()

    self.rankContext = {
        available = current and current.available or false,
        rankIndex = current and current.rankIndex or nil,
        rankName = current and current.rankName or nil,
        canPromote = current and current.flags and current.flags.promote or false,
        canDemote = current and current.flags and current.flags.demote or false
    }
end

function GMH.UI:GetGuildRankNames()
    if self.guildRankNames then
        return self.guildRankNames
    end

    local names = {}
    local count = 0

    if type(GuildControlGetNumRanks) == "function" then
        local ok, value = pcall(GuildControlGetNumRanks)
        if ok then
            count = tonumber(value) or 0
        end
    end

    for index = 1, count do
        local name

        if type(GuildControlGetRankName) == "function" then
            local ok, value = pcall(GuildControlGetRankName, index)
            if ok then
                name = value
            end
        end

        names[index - 1] = name or tostring(index)
    end

    self.guildRankNames = names
    self.guildRankCount = count

    return names
end

function GMH.UI:GetRankNameByIndex(rankIndex)
    local names = self:GetGuildRankNames()
    return names[tonumber(rankIndex)] or tostring(rankIndex)
end

function GMH.UI:GetRankOptionsForMember(member)
    local context = self.rankContext

    if not context or not context.available then
        return {}
    end

    if not member or member.rankIndex == nil then
        return {}
    end

    local actorRank = tonumber(context.rankIndex)
    local memberRank = tonumber(member.rankIndex)

    if not actorRank or not memberRank then
        return {}
    end

    local options = {}
    local names = self:GetGuildRankNames()

    -- Нельзя менять персонажа своего звания или выше.
    if memberRank <= actorRank then
        return options
    end

    for rankIndex = actorRank + 1, (self.guildRankCount or 0) - 1 do
        if rankIndex ~= memberRank then
            local isPromotion = rankIndex < memberRank
            local isDemotion = rankIndex > memberRank

            if (isPromotion and context.canPromote) or (isDemotion and context.canDemote) then
                options[#options + 1] = {
                    rankIndex = rankIndex,
                    rankName = names[rankIndex],
                    direction = isPromotion and "promote" or "demote"
                }
            end
        end
    end

    return options
end

function GMH.UI:CanSetMemberRank(member, targetRankIndex)
    if not member or member.rankIndex == nil then
        return false
    end

    local context = self.rankContext

    if not context or not context.available then
        return false
    end

    local actorRank = tonumber(context.rankIndex)
    local memberRank = tonumber(member.rankIndex)
    local targetRank = tonumber(targetRankIndex)

    if not actorRank or not memberRank or not targetRank then
        return false
    end

    if memberRank == targetRank then
        return false
    end

    -- Нельзя назначить звание равное или выше собственного.
    if targetRank <= actorRank then
        return false
    end

    if targetRank < memberRank then
        return context.canPromote and memberRank >= actorRank + 2
    end

    return context.canDemote and memberRank > actorRank
end

function GMH.UI:GetRankChangeTargets(clickedMember, targetRankIndex)
    local selected = self:GetSelectedMembers()
    local targets = {}

    -- Если есть выделенные персонажи, применяем новое звание ко всей выборке.
    if #selected > 0 then
        for _, member in ipairs(selected) do
            if self:CanSetMemberRank(member, targetRankIndex) then
                targets[#targets + 1] = member
            end
        end
    elseif clickedMember and self:CanSetMemberRank(clickedMember, targetRankIndex) then
        targets[#targets + 1] = clickedMember
    end

    return targets, #selected
end

function GMH.UI:CreateRankMenu()
    if self.rankMenu then
        return self.rankMenu
    end

    local menu = CreateFrame("Frame", "GMHelperRankMenu", UIParent)
    menu:SetWidth(150)
    menu:SetHeight(1)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetToplevel(true)
    menu:EnableMouse(true)
    menu:Hide()

    SetSolidBackground(menu, COLORS.header)

    self.rankMenu = menu

    -- Прозрачный полноэкранный перехватчик клика для закрытия меню
    -- при клике в любом месте вне самого списка.
    local dismiss = CreateFrame("Button", nil, UIParent)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("DIALOG")
    dismiss:SetFrameLevel(1)
    dismiss:EnableMouse(true)
    dismiss:Hide()
    dismiss:SetScript("OnClick", function()
        self:HideRankMenu()
    end)

    self.rankMenuDismiss = dismiss

    return menu
end

function GMH.UI:HideRankMenu()
    if self.rankMenu then
        self.rankMenu:Hide()
    end

    if self.rankMenuDismiss then
        self.rankMenuDismiss:Hide()
    end

    self.rankMenuOwnerButton = nil
    self.rankMenuOwnerMember = nil
end

function GMH.UI:ShowRankMenu(button, member)
    -- Повторный клик по той же ячейке закрывает меню.
    if self.rankMenu and self.rankMenu:IsShown() and self.rankMenuOwnerButton == button then
        self:HideRankMenu()
        return
    end

    self:HideRankMenu()

    local options = self:GetRankOptionsForMember(member)

    if #options == 0 then
        return
    end

    local menu = self:CreateRankMenu()

    for _, child in ipairs({menu:GetChildren()}) do
        child:Hide()
    end

    local rowHeight = 26
    menu:SetHeight(#options * rowHeight)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    menu:Show()

    if self.rankMenuDismiss then
        self.rankMenuDismiss:Show()
    end

    self.rankMenuOwnerButton = button
    self.rankMenuOwnerMember = member

    for index, option in ipairs(options) do
        local item = CreateFrame("Button", nil, menu)
        item:SetWidth(150)
        item:SetHeight(rowHeight)
        item:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -(index - 1) * rowHeight)

        local background = item:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(item)
        background:SetTexture(1, 1, 1, 1)
        background:SetVertexColor(1, 1, 1, 0.03)

        local label = CreateText(item, 10, COLORS.text, "LEFT")
        label:SetPoint("LEFT", item, "LEFT", 9, 0)
        label:SetWidth(132)
        label:SetHeight(rowHeight)
        label:SetJustifyV("MIDDLE")
        label:SetText(option.rankName)

        item:SetScript("OnEnter", function()
            background:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.18)
        end)

        item:SetScript("OnLeave", function()
            background:SetVertexColor(1, 1, 1, 0.03)
        end)

        item:SetScript("OnClick", function()
            self:HideRankMenu()
            self:ShowRankChangeConfirmation(member, option.rankIndex)
        end)
    end
end

function GMH.UI:BuildRankChangeConfirmationText(count, targetRankName, skipped)
    local text =
        "Вы действительно хотите изменить звание у выбранных персонажей, количеством: " ..
            tostring(count) .. "?\n\nНовое звание: " .. tostring(targetRankName) .. ""

    if skipped and skipped > 0 then
        text = text .. "\n\nПерсонажей, которые не могут быть изменены: " ..
                   tostring(skipped)
    end

    return text
end

function GMH.UI:CreateRankConfirmationFrame()
    if self.rankConfirmFrame then
        return self.rankConfirmFrame
    end

    local frame = CreateFrame("Frame", "GMHelperRankConfirmFrame", self.mainFrame)
    frame:SetWidth(520)
    frame:SetHeight(280)
    -- Keep the modal beneath the dropdown so the list remains on top.
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(self.mainFrame:GetFrameLevel() + 20)
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function() end)
    frame:SetScript("OnMouseUp", function() end)
    frame:Hide()

    frame:SetScript("OnHide", function()
        if self.rankConfirmDropdown and self.rankConfirmDropdown.menu then
            self.rankConfirmDropdown.menu:Hide()
        end
        if self.rankConfirmYesButton then
            self.rankConfirmYesButton:Enable(true)
        end
    end)

    SetSolidBackground(frame, {0.02, 0.025, 0.035, 0.98})

    local title = CreateText(frame, 15, COLORS.text, "CENTER")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -16)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -16)
    title:SetHeight(24)
    title:SetText("Подтверждение изменения звания")

    local message = CreateText(frame, 12, COLORS.text, "CENTER")
    message:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -50)
    message:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -50)
    message:SetHeight(120)
    message:SetJustifyV("MIDDLE")
    message:SetWordWrap(true)

    local yesButton = CreateButton(frame, 110, 32, "Да")
    yesButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -8, 20)

    local cancelButton = CreateButton(frame, 110, 32, "Отменить")
    cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 8, 20)

    cancelButton:SetScript("OnClick", function()
        if self.rankChangeQueueRunning then
            -- Прерываем очередь и закрываем окно.
            self:StopRankChangeQueue()
            frame:Hide()
            self.rankChangePending = nil
        else
            frame:Hide()
            self.rankChangePending = nil
        end
    end)

    yesButton:SetScript("OnClick", function()
        -- Не закрываем окно; кнопка "Отменить" будет прерывать процесс.
        yesButton:Enable(false)
        cancelButton:Enable(false)
        self:StartRankChangeQueue()
    end)

    -- Expose yes and stop buttons to allow enabling/disabling from callers.
    self.rankConfirmYesButton = yesButton

    self.rankConfirmFrame = frame
    self.rankConfirmMessage = message

    -- Stop button removed: cancelling the modal now interrupts the queue.

    return frame
end

function GMH.UI:ShowRankChangeConfirmation(clickedMember, targetRankIndex)
    if not self.rankContext or not self.rankContext.available then
        GMH:Print("Не удалось определить права текущего персонажа.")
        return
    end

    local targets, selectedCount = self:GetRankChangeTargets(clickedMember, targetRankIndex)

    if #targets == 0 then
        GMH:Print(
            "Нет выбранных персонажей, которым можно назначить это звание.")
        return
    end

    local targetRankName = self:GetRankNameByIndex(targetRankIndex)
    local skipped = selectedCount > #targets and selectedCount - #targets or 0

    self.rankChangePending = {
        members = targets,
        targetRankIndex = targetRankIndex,
        targetRankName = targetRankName
    }

    local frame = self:CreateRankConfirmationFrame()

    -- Заполняем сообщение и разрешаем подтверждение сразу (ранг уже выбран).
    -- При одиночном изменении звание уже выбрано в колонке ростера,
    -- поэтому список в модальном окне должен показывать именно его,
    -- а не значение, оставшееся от предыдущего массового действия.
    if self.rankConfirmDropdown and self.rankConfirmDropdown.label then
        self.rankConfirmDropdown.label:SetText(targetRankName)
    end
    self.rankConfirmMessage:SetText(self:BuildRankChangeConfirmationText(#targets, targetRankName, skipped))
    if self.rankConfirmYesButton then
        self.rankConfirmYesButton:Enable(true)
    end

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", self.mainFrame, "CENTER", 0, 0)
    frame:Show()
end

function GMH.UI:ShowBulkActionMenu(button)
    if not button then
        return
    end

    if self.bulkActionMenu and self.bulkActionMenu:IsShown() and self.bulkActionMenuOwner == button then
        self.bulkActionMenu:Hide()
        return
    end

    if not self.bulkActionMenu then
        local menu = CreateFrame("Frame", "GMHelperBulkActionMenu", UIParent)
        menu:SetWidth(220)
        menu:SetHeight(1)
        menu:SetFrameStrata("TOOLTIP")
        menu:SetToplevel(true)
        menu:EnableMouse(true)
        menu:Hide()
        SetSolidBackground(menu, COLORS.header)

        self.bulkActionMenu = menu
    end

    local menu = self.bulkActionMenu

    for _, child in ipairs({menu:GetChildren()}) do
        child:Hide()
    end

    local options = {
        { label = "Исключить выбранных" , action = function() self:ShowRemoveConfirmation() end },
        { label = "Изменить звания" , action = function() self:ShowBulkRankSelection() end }
    }

    local rowHeight = 26
    menu:SetHeight(#options * rowHeight)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    menu:Show()

    self.bulkActionMenuOwner = button

    for index, option in ipairs(options) do
        local item = CreateFrame("Button", nil, menu)
        item:SetWidth(220)
        item:SetHeight(rowHeight)
        item:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -(index - 1) * rowHeight)

        local background = item:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(item)
        background:SetTexture(1, 1, 1, 1)
        background:SetVertexColor(1, 1, 1, 0.03)

        local label = CreateText(item, 12, COLORS.text, "LEFT")
        label:SetPoint("LEFT", item, "LEFT", 8, 0)
        label:SetWidth(200)
        label:SetHeight(rowHeight)
        label:SetJustifyV("MIDDLE")
        label:SetWordWrap(false)
        label:SetText(option.label)

        item:SetScript("OnEnter", function()
            background:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.18)
        end)

        item:SetScript("OnLeave", function()
            background:SetVertexColor(1, 1, 1, 0.03)
        end)

        item:SetScript("OnClick", function()
            menu:Hide()
            option.action()
        end)
    end
end

function GMH.UI:ShowBulkRankSelection()
    if not self.rankContext or not self.rankContext.available then
        GMH:Print("Не удалось определить права текущего персонажа.")
        return
    end

    local selected = self:GetSelectedMembers()
    if #selected == 0 then
        GMH:Print("Не выбрано ни одного персонажа.")
        return
    end

    local actorRank = tonumber(self.rankContext.rankIndex)
    if not actorRank then
        GMH:Print("Не удалось определить ваше звание.")
        return
    end

    local options = {}
    local names = self:GetGuildRankNames()

    for rankIndex = actorRank + 1, (self.guildRankCount or 0) - 1 do
        -- проверить, есть ли хотя бы один выбранный, для которого допустимо это звание
        local any = false
        for _, member in ipairs(selected) do
            if self:CanSetMemberRank(member, rankIndex) then
                any = true
                break
            end
        end

        if any then
            options[#options + 1] = { rankIndex = rankIndex, rankName = names[rankIndex] }
        end
    end

    if #options == 0 then
        GMH:Print("Нет допустимых званий для выбранных персонажей.")
        return
    end

    -- Используем фрейм подтверждения для выбора ранга внутри него.
    local frame = self:CreateRankConfirmationFrame()

    -- Очищаем предыдущие объекты выпадающего списка, если есть
    if self.rankConfirmDropdown and self.rankConfirmDropdown.menu then
        self.rankConfirmDropdown.menu:Hide()
    end

    -- Встроенный dropdown выбора звания. Он должен быть поверх модалки.
    local dropdown = self.rankConfirmDropdown
    if not dropdown then
        dropdown = CreateFrame("Button", nil, frame)
        dropdown:SetWidth(320)
        dropdown:SetHeight(30)
        -- Anchor dropdown below the message so it shifts when message grows.
        dropdown:SetPoint("TOP", self.rankConfirmMessage, "BOTTOM", 0, -12)
        dropdown:SetFrameStrata("TOOLTIP")
        dropdown:SetFrameLevel(frame:GetFrameLevel() + 100)
        dropdown:EnableMouse(true)

        local bg = dropdown:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(dropdown)
        bg:SetTexture(1, 1, 1, 1)
        bg:SetVertexColor(1, 1, 1, 0.05)

        local label = CreateText(dropdown, 12, COLORS.text, "LEFT")
        label:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
        label:SetWidth(260)
        label:SetHeight(30)
        label:SetJustifyV("MIDDLE")
        label:SetText("Выберите звание...")

        local arrow = CreateText(dropdown, 12, COLORS.muted, "CENTER")
        arrow:SetPoint("RIGHT", dropdown, "RIGHT", -8, 0)
        arrow:SetWidth(16)
        arrow:SetHeight(30)
        arrow:SetText("v")

        dropdown.label = label
        dropdown.arrow = arrow

        dropdown.menu = CreateFrame("Frame", nil, UIParent)
        dropdown.menu:SetWidth(300)
        dropdown.menu:SetFrameStrata("TOOLTIP")
        dropdown.menu:SetToplevel(true)
        dropdown.menu:Hide()
        dropdown.menu:SetFrameLevel(frame:GetFrameLevel() + 250)
        dropdown.menu:SetClampedToScreen(true)

        local menuBg = dropdown.menu:CreateTexture(nil, "BACKGROUND")
        menuBg:SetAllPoints(dropdown.menu)
        menuBg:SetTexture(1, 1, 1, 1)
        menuBg:SetVertexColor(0.02, 0.025, 0.035, 0.98)
        dropdown.menu._background = menuBg

        self.rankConfirmDropdown = dropdown
    end

    -- Build menu items
    for _, child in ipairs({dropdown.menu:GetChildren()}) do
        child:Hide()
    end

    local rowH = 26
    for i, option in ipairs(options) do
        local item = CreateFrame("Button", nil, dropdown.menu)
        item:SetWidth(300)
        item:SetHeight(rowH)
        item:SetPoint("TOPLEFT", dropdown.menu, "TOPLEFT", 0, -(i - 1) * rowH)

        local bg = item:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(item)
        bg:SetTexture(1, 1, 1, 1)
        -- Use opaque/dark background so modal content does not show through
        bg:SetVertexColor(0.06, 0.07, 0.09, 1)
        item._background = bg

        local lbl = CreateText(item, 12, COLORS.text, "LEFT")
        lbl:SetPoint("LEFT", item, "LEFT", 8, 0)
        lbl:SetWidth(284)
        lbl:SetHeight(rowH)
        lbl:SetJustifyV("MIDDLE")
        lbl:SetText(option.rankName)

        item:SetScript("OnEnter", function()
            bg:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.18)
        end)
        item:SetScript("OnLeave", function()
            bg:SetVertexColor(0.06, 0.07, 0.09, 1)
        end)

        item:SetScript("OnClick", function()
            -- set selection
            dropdown.label:SetText(option.rankName)

            local selectedMembers = selected
            local targets = {}
            for _, m in ipairs(selectedMembers) do
                if self:CanSetMemberRank(m, option.rankIndex) then
                    targets[#targets + 1] = m
                end
            end

            local skipped = #selectedMembers - #targets

            self.rankChangePending = {
                members = targets,
                targetRankIndex = option.rankIndex,
                targetRankName = option.rankName
            }

            self.rankConfirmMessage:SetText(self:BuildRankChangeConfirmationText(#targets, option.rankName, skipped))
            if self.rankConfirmYesButton then
                self.rankConfirmYesButton:Enable(true)
            end

            dropdown.menu:Hide()
        end)
    end

    dropdown.menu:SetHeight(#options * rowH)
    dropdown.menu:ClearAllPoints()
    dropdown.menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    dropdown.menu:SetFrameLevel(frame:GetFrameLevel() + 250)

    dropdown:SetScript("OnClick", function()
        if dropdown.menu:IsShown() then
            dropdown.menu:Hide()
        else
            dropdown.menu:Show()
            dropdown.menu:SetFrameLevel(frame:GetFrameLevel() + 250)
        end
    end)

    -- По умолчанию запрещаем подтверждение пока не выбран ранг.
    if self.rankConfirmYesButton then
        self.rankConfirmYesButton:Enable(false)
    end

    -- Показываем окно подтверждения в центре и dropdown
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", self.mainFrame, "CENTER", 0, 0)
    self.rankConfirmMessage:SetText("Выберите звание для выбранных персонажей и подтвердите действие.")
    frame:Show()
end

function GMH.UI:StopRankChangeQueue()
    if not self.rankChangeQueueRunning then
        return
    end

    self.rankChangeQueueRunning = false
    self.rankChangeQueue = nil
    self.rankChangeQueueIndex = nil

    if self._rankChangeFrame then
        self._rankChangeFrame:SetScript("OnUpdate", nil)
    end

    GMH:Print("Очередь изменения званий была прервана.")
    -- Закрываем модальное окно при отмене
    if self.rankConfirmFrame then
        self.rankConfirmFrame:Hide()
    end
    self:Refresh()
end

function GMH.UI:StartRankChangeQueue()
    local pending = self.rankChangePending

    if not pending or not pending.members or #pending.members == 0 then
        self.rankChangePending = nil
        return
    end

    if not self.rankContext or not self.rankContext.available then
        self.rankChangePending = nil
        GMH:Print("Не удалось определить права текущего персонажа.")
        return
    end

    self.rankChangeQueue = {}

    for _, member in ipairs(pending.members) do
        local currentRank = tonumber(member.rankIndex)
        local targetRank = tonumber(pending.targetRankIndex)

        if currentRank and targetRank and currentRank ~= targetRank then
            self.rankChangeQueue[#self.rankChangeQueue + 1] = {
                name = member.name,
                currentRank = currentRank,
                targetRank = targetRank
            }
            member.selected = false
        end
    end

    self.rankChangeQueueIndex = 1
    self.rankChangeQueueRunning = true
    self.rankChangePending = nil

    -- Показать кнопку прерывания в модальном окне, если есть
    -- no inline stop button; cancellation will interrupt the queue

    self:UpdateSelectionCount()
    self:ProcessRankChangeQueue()
end

function GMH.UI:ProcessRankChangeQueue()
    if not self.rankChangeQueueRunning then
        return
    end

    local queue = self.rankChangeQueue or {}
    local index = self.rankChangeQueueIndex or 1
    local operation = queue[index]

    if not operation then
        self.rankChangeQueueRunning = false
        self.rankChangeQueue = nil
        self.rankChangeQueueIndex = nil

        -- no inline stop button to hide

        GMH:Print("Очередь изменения званий завершена.")
        -- Закрываем модальное окно по завершении
        if self.rankConfirmFrame then
            self.rankConfirmFrame:Hide()
        end
        self:Refresh()
        return
    end

    if not operation.currentRank or not operation.targetRank then
        self.rankChangeQueueIndex = index + 1
        self:ScheduleNextRankChangeStep()
        return
    end

    if operation.currentRank == operation.targetRank then
        self.rankChangeQueueIndex = index + 1
        self:ScheduleNextRankChangeStep()
        return
    end

    local success = false

    if operation.currentRank > operation.targetRank then
        if type(GuildPromote) == "function" then
            GuildPromote(operation.name)
            operation.currentRank = operation.currentRank - 1
            success = true
        end
    else
        if type(GuildDemote) == "function" then
            GuildDemote(operation.name)
            operation.currentRank = operation.currentRank + 1
            success = true
        end
    end

    if not success then
        GMH:Print("Функция изменения звания недоступна для " ..
                      tostring(operation.name) .. ".")
        self.rankChangeQueueIndex = index + 1
        self:ScheduleNextRankChangeStep()
        return
    end

    if operation.currentRank == operation.targetRank then
        self.rankChangeQueueIndex = index + 1
    end

    self:ScheduleNextRankChangeStep()
end

function GMH.UI:ScheduleNextRankChangeStep()
    self._rankChangeFrame = self._rankChangeFrame or CreateFrame("Frame")
    self._rankChangeElapsed = 0

    self._rankChangeFrame:SetScript("OnUpdate", function(frame, delta)
        if not self.rankChangeQueueRunning then
            frame:SetScript("OnUpdate", nil)
            return
        end

        self._rankChangeElapsed = self._rankChangeElapsed + delta

        if self._rankChangeElapsed >= 1.0 then
            frame:SetScript("OnUpdate", nil)
            self._rankChangeElapsed = 0
            self:ProcessRankChangeQueue()
        end
    end)
end

function GMH.UI:CreateNoteEditor()
    if self.noteEditorFrame then
        return self.noteEditorFrame
    end

    local frame = CreateFrame("Frame", "GMHelperNoteEditor", UIParent)
    frame:SetWidth(500)
    frame:SetHeight(180)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(self.mainFrame:GetFrameLevel() + 25)
    frame:Hide()
    SetSolidBackground(frame, {0.02, 0.025, 0.035, 0.98})
    frame:EnableMouse(true)

    local title = CreateText(frame, 14, COLORS.text, "CENTER")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -14)
    title:SetHeight(24)

    local editBox = CreateFrame("EditBox", nil, frame)
    editBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -52)
    editBox:SetWidth(464)
    editBox:SetHeight(36)
    editBox:SetFont(FONT, 12, "")
    editBox:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], 1)
    editBox:SetAutoFocus(false)
    editBox:SetMultiLine(false)
    editBox:SetMaxLetters(255)

    local editBg = frame:CreateTexture(nil, "BACKGROUND")
    editBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -50)
    editBg:SetWidth(464)
    editBg:SetHeight(36)
    editBg:SetTexture(1, 1, 1, 1)
    editBg:SetVertexColor(1, 1, 1, 0.07)

    -- EditBox должен находиться поверх фона.
    editBox:SetFrameLevel(frame:GetFrameLevel() + 2)

    local saveButton = CreateButton(frame, 110, 30, "Сохранить")
    saveButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -8, 16)

    local cancelButton = CreateButton(frame, 110, 30, "Отменить")
    cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 8, 16)

    local function CloseEditor()
        frame:Hide()
        editBox:ClearFocus()
        self.noteEditorData = nil
    end

    cancelButton:SetScript("OnClick", CloseEditor)

    saveButton:SetScript("OnClick", function()
        self:SaveNoteEditor()
    end)

    editBox:SetScript("OnEnterPressed", function()
        self:SaveNoteEditor()
    end)

    editBox:SetScript("OnEscapePressed", function()
        CloseEditor()
    end)

    -- Клик снаружи редактора закрывает его.
    local dismiss = CreateFrame("Button", nil, UIParent)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("DIALOG")
    dismiss:SetFrameLevel(1)
    dismiss:EnableMouse(true)
    dismiss:Hide()
    dismiss:SetScript("OnClick", CloseEditor)

    frame:SetScript("OnHide", function()
        dismiss:Hide()
        editBox:ClearFocus()
    end)

    self.noteEditorFrame = frame
    self.noteEditorTitle = title
    self.noteEditorEditBox = editBox
    self.noteEditorDismiss = dismiss

    return frame
end

function GMH.UI:ShowNoteEditor(member, noteType)
    if not member then
        return
    end

    local canEdit = false
    local title = ""
    local currentText = ""

    if noteType == "public" then
        canEdit = GMH.Permissions:Can("edit_public_note")
        title = "Изменение общей заметки"
        currentText = member.publicNote or ""
    elseif noteType == "officer" then
        canEdit = GMH.Permissions:Can("edit_officer_note")
        title = "Изменение офицерской заметки"
        currentText = member.officerNote or ""
    else
        return
    end

    if not canEdit then
        return
    end

    if type(GuildRosterSetPublicNote) ~= "function" and noteType == "public" then
        GMH:Print(
            "Функция изменения общей заметки недоступна в текущем клиенте.")
        return
    end

    if type(GuildRosterSetOfficerNote) ~= "function" and noteType == "officer" then
        GMH:Print(
            "Функция изменения офицерской заметки недоступна в текущем клиенте.")
        return
    end

    self:HideRankMenu()

    local frame = self:CreateNoteEditor()

    self.noteEditorData = {
        member = member,
        noteType = noteType
    }

    self.noteEditorTitle:SetText(title)
    self.noteEditorEditBox:SetText(currentText)
    self.noteEditorEditBox:SetCursorPosition(0)

    frame:ClearAllPoints()
    local savedScroll = self.scroll and self.scroll:GetVerticalScroll() or 0

    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:Show()
    self.noteEditorDismiss:Show()

    self.noteEditorEditBox:SetFocus()

    -- Фокус EditBox не должен заставлять ScrollFrame прокручивать ростер.
    if self.scroll then
        self.scroll:SetVerticalScroll(savedScroll)
        if self.UpdateScrollbar then
            self:UpdateScrollbar()
        end
    end
end

function GMH.UI:SaveNoteEditor()
    local data = self.noteEditorData
    local editBox = self.noteEditorEditBox

    if not data or not data.member or not editBox then
        return
    end

    local member = data.member
    local note = editBox:GetText() or ""
    local ok
    local err

    if data.noteType == "public" then
        ok, err = pcall(GuildRosterSetPublicNote, member.rosterIndex, note)
    elseif data.noteType == "officer" then
        ok, err = pcall(GuildRosterSetOfficerNote, member.rosterIndex, note)
    else
        return
    end

    if not ok then
        GMH:Print("Не удалось изменить заметку: " .. tostring(err))
        return
    end

    -- Сразу меняем кэш, чтобы UI не ждал GUILD_ROSTER_UPDATE.
    if data.noteType == "public" then
        member.publicNote = note
    else
        member.officerNote = note
    end

    if self.noteEditorFrame then
        self.noteEditorFrame:Hide()
    end

    self.noteEditorData = nil
    self:RefreshRoster()
end

function GMH.UI:CreateRow(member, rowIndex)
    local row = CreateFrame("Frame", nil, self.content)
    row:SetWidth(726)
    row:SetHeight(32)
    row:EnableMouse(true)
    row:SetFrameLevel(self.content:GetFrameLevel() + 2)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(row)
    background:SetTexture(1, 1, 1, 1)

    local function ApplyRowColor()
        local index = row._visibleIndex or rowIndex or 1
        if (index % 2) == 0 then
            background:SetVertexColor(COLORS.rowAlt[1], COLORS.rowAlt[2], COLORS.rowAlt[3], COLORS.rowAlt[4])
        else
            background:SetVertexColor(COLORS.row[1], COLORS.row[2], COLORS.row[3], COLORS.row[4])
        end
    end

    ApplyRowColor()

    row:SetScript("OnEnter", function()
        background:SetVertexColor(COLORS.hover[1], COLORS.hover[2], COLORS.hover[3], COLORS.hover[4])
    end)

    row:SetScript("OnLeave", function()
        ApplyRowColor()
    end)

    local canRemoveMembers = GMH.Permissions:Can("remove_member")

    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    checkbox:SetWidth(24)
    checkbox:SetHeight(24)
    checkbox:SetPoint("CENTER", row, "LEFT", 18, 0)
    checkbox:SetShown(canRemoveMembers)
    checkbox:SetEnabled(canRemoveMembers)
    checkbox:SetScript("OnClick", function(self)
        -- Не замыкаем первоначальное значение права: оно может измениться
        -- после входа другим персонажем без пересоздания UI.
        local isCurrentRow = row:IsShown()
            and row.member
            and row._absoluteIndex
            and GMH.UI.visibleRoster
            and GMH.UI.visibleRoster[row._absoluteIndex] == row.member

        if isCurrentRow and GMH.Permissions:Can("remove_member") then
            row.member.selected = self:GetChecked() and true or false
            self:GetParent()._ui:UpdateSelectionCount()
        else
            self:SetChecked(false)
        end
    end)

    local x = canRemoveMembers and 36 or 0

    local function AddCell(width, justify, color, offset)
        local cell = CreateText(row, 12, color or COLORS.text, justify or "LEFT")
        cell:SetDrawLayer("OVERLAY")
        cell:SetPoint("LEFT", row, "LEFT", offset or x, 0)
        cell:SetWidth(width)
        cell:SetHeight(32)
        cell:SetJustifyV("MIDDLE")
        cell:SetWordWrap(false)
        return cell
    end

    local nameCell = AddCell(140, "LEFT", COLORS.text, x + 7)
    x = x + 140

    local levelCell = AddCell(50, "CENTER", COLORS.text, x)
    x = x + 50

    local rankButton = CreateFrame("Button", nil, row)
    rankButton:SetWidth(110)
    rankButton:SetHeight(32)
    rankButton:SetPoint("LEFT", row, "LEFT", x, 0)
    rankButton:SetFrameLevel(row:GetFrameLevel() + 1)
    rankButton:EnableMouse(true)

    local rankBg = rankButton:CreateTexture(nil, "BACKGROUND")
    rankBg:SetAllPoints(rankButton)
    rankBg:SetTexture(1, 1, 1, 1)
    rankBg:SetVertexColor(1, 1, 1, 0.001)

    local rankLabel = CreateText(rankButton, 12, COLORS.text, "LEFT")
    rankLabel:SetPoint("LEFT", rankButton, "LEFT", 7, 0)
    rankLabel:SetWidth(92)
    rankLabel:SetHeight(32)
    rankLabel:SetJustifyV("MIDDLE")
    rankLabel:SetWordWrap(false)

    local arrow = CreateText(rankButton, 12, COLORS.muted, "CENTER")
    arrow:SetPoint("RIGHT", rankButton, "RIGHT", -5, 0)
    arrow:SetWidth(12)
    arrow:SetHeight(32)
    arrow:SetJustifyV("MIDDLE")
    arrow:SetText("v")

    rankButton:SetScript("OnEnter", function()
        if rankButton:IsShown() then
            rankBg:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.10)
        end
    end)

    rankButton:SetScript("OnLeave", function()
        rankBg:SetVertexColor(1, 1, 1, 0.001)
    end)

    rankButton:SetScript("OnClick", function()
        if row.member then
            self:ShowRankMenu(rankButton, row.member)
        end
    end)

    x = x + 110

    local publicButton = CreateFrame("Button", nil, row)
    publicButton:SetPoint("LEFT", row, "LEFT", x, 0)
    publicButton:SetWidth(135)
    publicButton:SetHeight(32)
    publicButton:SetFrameLevel(row:GetFrameLevel() + 1)
    publicButton:EnableMouse(true)

    local publicCell = AddCell(135, "LEFT", COLORS.muted, x + 7)
    publicButton:SetScript("OnEnter", function()
        publicCell:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], 1)
    end)
    publicButton:SetScript("OnLeave", function()
        publicCell:SetTextColor(COLORS.muted[1], COLORS.muted[2], COLORS.muted[3], 1)
    end)
    publicButton:SetScript("OnClick", function()
        if row.member then
            self:ShowNoteEditor(row.member, "public")
        end
    end)
    x = x + 135

    local officerButton = CreateFrame("Button", nil, row)
    officerButton:SetPoint("LEFT", row, "LEFT", x, 0)
    officerButton:SetWidth(135)
    officerButton:SetHeight(32)
    officerButton:SetFrameLevel(row:GetFrameLevel() + 1)
    officerButton:EnableMouse(true)

    local officerCell = AddCell(135, "LEFT", COLORS.muted, x + 7)
    officerButton:SetScript("OnEnter", function()
        officerCell:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], 1)
    end)
    officerButton:SetScript("OnLeave", function()
        officerCell:SetTextColor(COLORS.muted[1], COLORS.muted[2], COLORS.muted[3], 1)
    end)
    officerButton:SetScript("OnClick", function()
        if row.member then
            self:ShowNoteEditor(row.member, "officer")
        end
    end)
    x = x + 135

    local lastOnlineCell = AddCell(120, "LEFT", COLORS.muted, x + 7)

    row.checkbox = checkbox
    row.member = member
    row.background = background
    row.nameCell = nameCell
    row.levelCell = levelCell
    row.rankCell = rankButton
    row.rankLabel = rankLabel
    row.rankArrow = arrow
    row.rankBg = rankBg
    row.publicButton = publicButton
    row.publicCell = publicCell
    row.officerButton = officerButton
    row.officerCell = officerCell
    row.lastOnlineCell = lastOnlineCell
    row._ui = self

    return row
end

function GMH.UI:UpdateRow(row, member, visibleIndex, absoluteIndex)
    row.member = member
    row._visibleIndex = visibleIndex
    row._absoluteIndex = absoluteIndex
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -((absoluteIndex - 1) * 32))
    row:Show()

    local currentCanRemove = GMH.Permissions:Can("remove_member")
    row.checkbox:SetShown(currentCanRemove)
    row.checkbox:SetEnabled(currentCanRemove)
    row.checkbox:SetChecked(currentCanRemove and member.selected and true or false)

    local defaultColor = member.isOnline and COLORS.text or COLORS.muted
    -- Color name by class if available
    local classColor = nil
    if member.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[member.class] then
        classColor = RAID_CLASS_COLORS[member.class]
    end

    row.nameCell:SetText(tostring(member.name or ""))
    if classColor then
        row.nameCell:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
    else
        row.nameCell:SetTextColor(defaultColor[1], defaultColor[2], defaultColor[3], 1)
    end

    row.levelCell:SetText(tostring(member.level or ""))
    row.levelCell:SetTextColor(defaultColor[1], defaultColor[2], defaultColor[3], 1)

    row.rankLabel:SetText(tostring(member.rankName or ""))
    local rankOptions = self:GetRankOptionsForMember(member)
    local canChangeRank = #rankOptions > 0
    row.rankCell:Show()
    row.rankCell:EnableMouse(canChangeRank)
    row.rankArrow:SetShown(canChangeRank)

    if canChangeRank then
        row.rankBg:SetVertexColor(1, 1, 1, 0.001)
    else
        row.rankBg:SetVertexColor(1, 1, 1, 0)
    end

    local canEditPublic = GMH.Permissions:Can("edit_public_note")
    row.publicButton:SetShown(canEditPublic)
    row.publicCell:SetText(tostring(member.publicNote or ""))

    if canEditPublic and Trim(member.publicNote or "") == "" then
        if not row.publicButton._noteBorder then
            AddSubtleBorder(row.publicButton)
        end
        for _, border in ipairs(row.publicButton._noteBorder) do
            border:SetAlpha(0.16)
        end
    elseif row.publicButton._noteBorder then
        for _, border in ipairs(row.publicButton._noteBorder) do
            border:SetAlpha(0)
        end
    end

    local officerVisible = self.columns.officerNote.button:IsShown()
    local canEditOfficer = GMH.Permissions:Can("edit_officer_note")
    row.officerButton:SetShown(officerVisible and canEditOfficer)
    row.officerCell:SetText(tostring(member.officerNote or ""))

    if officerVisible and canEditOfficer and Trim(member.officerNote or "") == "" then
        if not row.officerButton._noteBorder then
            AddSubtleBorder(row.officerButton)
        end
        for _, border in ipairs(row.officerButton._noteBorder) do
            border:SetAlpha(0.16)
        end
    elseif row.officerButton._noteBorder then
        for _, border in ipairs(row.officerButton._noteBorder) do
            border:SetAlpha(0)
        end
    end

    row.lastOnlineCell:SetText(tostring(member.lastOnlineText or ""))
    local lastColor = member.isOnline and COLORS.allowed or COLORS.muted
    row.lastOnlineCell:SetTextColor(lastColor[1], lastColor[2], lastColor[3], 1)

    local index = visibleIndex or 1
    if (index % 2) == 0 then
        row.background:SetVertexColor(COLORS.rowAlt[1], COLORS.rowAlt[2], COLORS.rowAlt[3], COLORS.rowAlt[4])
    else
        row.background:SetVertexColor(COLORS.row[1], COLORS.row[2], COLORS.row[3], COLORS.row[4])
    end
end

function GMH.UI:EnsureRowPool()
    self.rowPool = self.rowPool or {}
    local needed = math.ceil(self.scroll:GetHeight() / 32) + 4
    if needed < 20 then
        needed = 20
    end

    while #self.rowPool < needed do
        self.rowPool[#self.rowPool + 1] = self:CreateRow(nil, #self.rowPool + 1)
    end
end

function GMH.UI:RefreshRoster()
    if not self.mainFrame then
        return
    end

    local oldScroll = self.scroll:GetVerticalScroll()

    local allMembers = self:GetRosterData()
    local visibleMembers = {}

    for _, member in ipairs(allMembers) do
        if self:MatchesFilter(member) then
            visibleMembers[#visibleMembers + 1] = member
        else
            -- A member hidden by the current filters must never remain
            -- selected for a later bulk operation.
            member.selected = false
        end
    end

    self:SortRoster(visibleMembers)
    self.visibleRoster = visibleMembers

    self:EnsureRowPool()
    self.rows = self.rowPool

    local contentHeight = math.max(#visibleMembers * 32 + 6, 1)
    self.content:SetHeight(contentHeight)

    local newRange = self.scroll:GetVerticalScrollRange()
    if oldScroll > newRange then
        oldScroll = newRange
    end
    self.scroll:SetVerticalScroll(oldScroll)

    self:RenderVisibleRows()
    self:UpdateScrollbar()
    self:UpdateSelectionCount()
end

function GMH.UI:RenderVisibleRows()
    if not self.visibleRoster then
        return
    end

    local total = #self.visibleRoster
    local scroll = self.scroll:GetVerticalScroll()
    local firstIndex = math.floor(scroll / 32) + 1
    if firstIndex < 1 then
        firstIndex = 1
    end

    for poolIndex, row in ipairs(self.rowPool or {}) do
        local absoluteIndex = firstIndex + poolIndex - 1
        if absoluteIndex <= total then
            local member = self.visibleRoster[absoluteIndex]
            self:UpdateRow(row, member, poolIndex, absoluteIndex)
        else
            row:Hide()
        end
    end
end

function GMH.UI:UpdateScrollbar()
    local range = self.scroll:GetVerticalScrollRange()

    if range <= 0 then
        self.scrollbar:Hide()
        return
    end

    self.scrollbar:Show()

    local viewportHeight = self.scroll:GetHeight()
    local contentHeight = self.content:GetHeight()
    local trackHeight = self.scrollbar:GetHeight()

    if viewportHeight <= 0 or contentHeight <= 0 or trackHeight <= 0 then
        self.scrollbar:Hide()
        return
    end

    local thumbHeight = trackHeight * (viewportHeight / contentHeight)

    if thumbHeight < 32 then
        thumbHeight = 32
    end

    if thumbHeight > trackHeight then
        thumbHeight = trackHeight
    end

    local available = trackHeight - thumbHeight
    local fraction = 0

    if range > 0 and available > 0 then
        fraction = self.scroll:GetVerticalScroll() / range
    end

    if fraction < 0 then
        fraction = 0
    elseif fraction > 1 then
        fraction = 1
    end

    local position = available * fraction

    self.scrollbarThumb:ClearAllPoints()
    self.scrollbarThumb:SetWidth(8)
    self.scrollbarThumb:SetHeight(thumbHeight)
    self.scrollbarThumb:SetPoint("TOP", self.scrollbar, "TOP", 0, -position)

    self.scrollbarThumb.dragAvailable = available
end

function GMH.UI:ClearRosterSelection()
    for _, member in ipairs(self:GetRosterData() or {}) do
        member.selected = false
    end
end

function GMH.UI:GetSelectedMembers()
    local selected = {}

    -- Для действий учитываем только отмеченных персонажей,
    -- которые входят в текущую выборку по фильтру.
    -- Это не позволяет скрытым после фильтрации персонажам
    -- продолжать участвовать в массовых операциях.
    for _, member in ipairs(self.rosterCache or {}) do
        if member.selected and self:MatchesFilter(member) then
            selected[#selected + 1] = member
        end
    end

    return selected
end

function GMH.UI:BuildRemovalConfirmationText(count)
    local parts = {}

    local minLevel = ParseLevel(GMHelperDB.roster.minLevel)
    local maxLevel = ParseLevel(GMHelperDB.roster.maxLevel)

    if minLevel and maxLevel then
        parts[#parts + 1] = "уровнем: от " .. tostring(minLevel) .. " до " .. tostring(maxLevel)
    elseif maxLevel then
        parts[#parts + 1] = "уровнем: до " .. tostring(maxLevel)
    elseif minLevel then
        parts[#parts + 1] = "уровнем: от " .. tostring(minLevel)
    end

    local offlineValue = tonumber(GMHelperDB.roster.minOfflineValue)
    local offlineUnit = GMHelperDB.roster.minOfflineUnit or "months"

    if offlineValue and offlineValue > 0 then
        if offlineUnit == "months" then
            parts[#parts + 1] = "отсутствовавших более: " .. tostring(offlineValue) .. " мес."
        else
            parts[#parts + 1] = "отсутствовавших более: " .. tostring(offlineValue) .. " дн."
        end
    end

    if GMHelperDB.roster.onlineOnly then
        parts[#parts + 1] = "сейчас находящихся в игре"
    end

    local criteria = ""

    if #parts > 0 then
        criteria = ", " .. table.concat(parts, ", ")
    end

    return
        "Вы действительно хотите удалить персонажей, количеством: " ..
            tostring(count) .. criteria .. "?"
end

function GMH.UI:CreateRemoveConfirmationFrame()
    if self.removeConfirmFrame then
        return self.removeConfirmFrame
    end

    local frame = CreateFrame("Frame", "GMHelperRemoveConfirmFrame", self.mainFrame)
    frame:SetWidth(520)
    frame:SetHeight(220)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(self.mainFrame:GetFrameLevel() + 20)
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function() end)
    frame:SetScript("OnMouseUp", function() end)
    frame:Hide()

    SetSolidBackground(frame, {0.02, 0.025, 0.035, 0.98})

    local title = CreateText(frame, 15, COLORS.text, "CENTER")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -16)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -16)
    title:SetHeight(24)
    title:SetText("Подтверждение исключения")

    local message = CreateText(frame, 12, COLORS.text, "CENTER")
    message:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -52)
    message:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -52)
    message:SetHeight(80)
    message:SetJustifyV("MIDDLE")
    message:SetWordWrap(true)

    local yesButton = CreateButton(frame, 110, 32, "Да")
    yesButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -8, 20)

    local cancelButton = CreateButton(frame, 110, 32, "Отменить")
    cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 8, 20)

    cancelButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    yesButton:SetScript("OnClick", function()
        frame:Hide()
        self:StartRemovalQueue()
    end)

    self.removeConfirmFrame = frame
    self.removeConfirmMessage = message

    return frame
end

function GMH.UI:ShowRemoveConfirmation()
    -- no early UI guard; check permissions instead

    if not GMH.Permissions:Can("remove_member") then
        GMH:Print("У вас нет права исключать персонажей из гильдии.")
        return
    end

    local selected = self:GetSelectedMembers()

    if #selected == 0 then
        GMH:Print("Не выбрано ни одного персонажа.")
        return
    end

    local frame = self:CreateRemoveConfirmationFrame()
    self.removeQueue = nil

    self.removeConfirmMessage:SetText(self:BuildRemovalConfirmationText(#selected))

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", self.mainFrame, "CENTER", 0, 0)
    frame:Show()
end

function GMH.UI:StartRemovalQueue()
    if not GMH.Permissions:Can("remove_member") then
        GMH:Print("У вас нет права исключать персонажей из гильдии.")
        return
    end

    local selected = self:GetSelectedMembers()

    if #selected == 0 then
        GMH:Print("Не выбрано ни одного персонажа.")
        return
    end

    self.removeQueue = {}

    for _, member in ipairs(selected) do
        self.removeQueue[#self.removeQueue + 1] = member.name
        member.selected = false
    end

    self.removeQueueIndex = 1
    self.removeQueueRunning = true

    self:UpdateSelectionCount()
    self:ProcessRemovalQueue()
end

function GMH.UI:ProcessRemovalQueue()
    if not self.removeQueueRunning then
        return
    end

    local queue = self.removeQueue or {}
    local index = self.removeQueueIndex or 1
    local name = queue[index]

    if not name then
        self.removeQueueRunning = false
        self.removeQueue = nil
        self.removeQueueIndex = nil
        GMH:Print("Очередь исключения завершена.")
        self:Refresh()
        return
    end

    if type(GuildUninvite) ~= "function" then
        self.removeQueueRunning = false
        GMH:Print(
            "Функция исключения из гильдии недоступна в текущем клиенте.")
        return
    end

    GuildUninvite(name)

    self.removeQueueIndex = index + 1

    self._removeQueueFrame = self._removeQueueFrame or CreateFrame("Frame")
    self._removeQueueElapsed = 0

    self._removeQueueFrame:SetScript("OnUpdate", function(frame, delta)
        if not self.removeQueueRunning then
            frame:SetScript("OnUpdate", nil)
            return
        end

        self._removeQueueElapsed = self._removeQueueElapsed + delta

        if self._removeQueueElapsed >= 1.0 then
            frame:SetScript("OnUpdate", nil)
            self._removeQueueElapsed = 0
            self:ProcessRemovalQueue()
        end
    end)
end

function GMH.UI:UpdateSelectionCount()
    local visible = 0
    local visibleSelected = 0

    local members = self:GetRosterData() or {}

    for _, member in ipairs(members) do
        if self:MatchesFilter(member) then
            visible = visible + 1

            if member.selected then
                visibleSelected = visibleSelected + 1
            end
        end
    end

    -- В интерфейсе показываем именно выборку текущего фильтра.
    -- Скрытые фильтром отметки не считаются выбранными для действий.
    local selected = visibleSelected

    if self.selectionLabel then
        self.selectionLabel:SetText(
            "Всего: " .. tostring(#members)
            .. "    Показано: " .. tostring(visible)
            .. "    Выбрано: " .. tostring(selected)
        )
    end

    ------------------------------------------------------------
    -- Состояние чекбокса в заголовке.
    -- Он отмечен только когда выбраны все строки текущей
    -- выборки. При смешанном состоянии остаётся снятым.
    ------------------------------------------------------------
    local selectAll = self.columns and self.columns.selected and self.columns.selected.selectAll

    local canRemove = GMH.Permissions:Can("remove_member")

    local hasSelection = selected > 0

    if selectAll then
        selectAll:SetChecked(canRemove and visible > 0 and visibleSelected == visible)
    end

    if self.actionButton then
        -- По умолчанию кнопка скрыта.
        self.actionButton:Hide()
        self.actionButton:Enable(false)

        if hasSelection then
            self.actionButton._label:SetText("Действия (" .. tostring(selected) .. ")")
            self.actionButton._background:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.16)
            self.actionButton:Show()
            self.actionButton:Enable(true)
        end
    end
end

function GMH.UI:Refresh()
    self:CreateMainFrame()
    self:CreateToggleButton()
    self:UpdateRankContext()
    self:UpdateColumns()
    self:UpdateOnlineButton()
    self:RefreshRoster()
end

function GMH.UI:ScheduleRosterRefresh()
    if self._rosterRefreshScheduled then
        return
    end

    self._rosterRefreshScheduled = true
    local elapsed = 0

    self._rosterRefreshFrame = self._rosterRefreshFrame or CreateFrame("Frame")
    self._rosterRefreshFrame:SetScript("OnUpdate", function(frame, delta)
        elapsed = elapsed + delta

        if elapsed < 1.0 then
            return
        end

        frame:SetScript("OnUpdate", nil)
        self._rosterRefreshScheduled = false

        if self.mainFrame then
            GMH:RequestGuildRoster()
        end
    end)
end

function GMH.UI:OnGuildRosterUpdate()
    if not self.mainFrame or not self.rosterModeActive then
        return
    end

    -- Respect the Blizzard guild window state whenever it is visible. GMHelper
    -- may read a full roster on its own, but it must not override the player's
    -- choice in "Показывать отсутствующих" while the native guild UI is active.
    local guildWindowVisible = GuildFrame and GuildFrame:IsShown() and true or false

    if GetGuildRosterShowOffline and SetGuildRosterShowOffline and not guildWindowVisible then
        local ok, showing = pcall(GetGuildRosterShowOffline)
        if ok and not showing then
            pcall(SetGuildRosterShowOffline, true)
            GMH:RequestGuildRoster()
            return
        end
    end

    -- Permissions and roster may have changed; update column visibility/layout first
    self:UpdateColumns()
    self:RefreshRosterCache()
    self:RefreshRoster()
end

function GMH.UI:CreateSettingsFrame()
    if self.settingsFrame then
        return self.settingsFrame
    end

    local frame = CreateFrame("Frame", "GMHelperSettingsFrame", UIParent)
    frame:SetWidth(310)
    frame:SetHeight(290)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:Hide()
    SetSolidBackground(frame, COLORS.background)

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    header:SetHeight(42)
    SetSolidBackground(header, COLORS.header)

    local title = CreateText(header, 14, COLORS.text)
    title:SetPoint("LEFT", header, "LEFT", 14, 0)
    title:SetText("Настройки GMHelper")

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetWidth(28)
    close:SetHeight(28)
    close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    local info = CreateText(frame, 10, COLORS.muted, "LEFT")
    info:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -55)
    info:SetWidth(282)
    info:SetHeight(32)
    info:SetText("ПКМ по кнопке: открыть настройки.\nЛКМ с перемещением: изменить положение кнопки.")

    local modeLabel = CreateText(frame, 11, COLORS.text)
    modeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -96)
    modeLabel:SetText("Расположение кнопки")

    local freeButton = CreateButton(frame, 125, 32, "Свободное")
    freeButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -120)

    local minimapButton = CreateButton(frame, 125, 32, "У мини-карты")
    minimapButton:SetPoint("LEFT", freeButton, "RIGHT", 8, 0)

    local function UpdateModeButtons()
        local mode = GMHelperDB.button.mode or "free"

        if mode == "minimap" then
            minimapButton._background:SetVertexColor(COLORS.allowed[1], COLORS.allowed[2], COLORS.allowed[3], 0.25)
            freeButton._background:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.16)
        else
            freeButton._background:SetVertexColor(COLORS.allowed[1], COLORS.allowed[2], COLORS.allowed[3], 0.25)
            minimapButton._background:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.16)
        end

        if self.toggleButton then
            UpdateToggleButtonVisualState(self.toggleButton)
        end
    end

    local function ApplyButtonMode(mode)
        GMHelperDB.button.mode = mode
        local button = self.toggleButton
        if not button then
            return
        end
        local prevMode = GMHelperDB.button.mode or "free"

        -- If switching away from free mode, save the free position so it can be restored later
        if prevMode == "free" and mode == "minimap" and button then
            local p, _, rp, ox, oy = button:GetPoint()
            if p and rp then
                GMHelperDB.button.freePoint = p
                GMHelperDB.button.freeRelativePoint = rp
                GMHelperDB.button.freeX = ox
                GMHelperDB.button.freeY = oy
            end
        end

        button:SetParent(mode == "minimap" and Minimap or UIParent)
        button:ClearAllPoints()

        if mode == "minimap" then
            PositionButtonOnMinimap(button, GMHelperDB.button.angle or math.rad(45))
        else
            local data = {
                point = GMHelperDB.button.freePoint or GMHelperDB.button.point,
                relativePoint = GMHelperDB.button.freeRelativePoint or GMHelperDB.button.relativePoint,
                x = GMHelperDB.button.freeX or GMHelperDB.button.x,
                y = GMHelperDB.button.freeY or GMHelperDB.button.y,
            }
            ApplySavedPosition(button, data, "CENTER", "CENTER", 220, -120)
        end

        UpdateToggleButtonVisualState(button)
        -- Reconfigure drag/click handlers to match new mode
        EnableMovingButton(button)
        UpdateModeButtons()
    end

    freeButton:SetScript("OnClick", function()
        ApplyButtonMode("free")
    end)

    minimapButton:SetScript("OnClick", function()
        ApplyButtonMode("minimap")
    end)

    local resetButton = CreateButton(frame, 126, 32, "Сбросить кнопку")
    resetButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -156)
    resetButton:SetScript("OnClick", function()
        GMHelperDB.button.point = "CENTER"
        GMHelperDB.button.relativePoint = "CENTER"
        GMHelperDB.button.x = 220
        GMHelperDB.button.y = -120
        -- also reset free-mode saved values
        -- free-mode default: center of screen
        GMHelperDB.button.freePoint = "CENTER"
        GMHelperDB.button.freeRelativePoint = "CENTER"
        GMHelperDB.button.freeX = 0
        GMHelperDB.button.freeY = 0
        GMHelperDB.button.mode = "free"
        GMHelperDB.button.angle = math.rad(45)
        GMHelperDB.button.radius = nil

        if self.toggleButton then
            -- Use ApplyButtonMode to ensure parent, frame level and visual state are updated
            ApplyButtonMode("free")
        end

        UpdateModeButtons()
        GMH:Print("Позиция кнопки сброшена.")
    end)

    local resetWindowButton = CreateButton(frame, 126, 32, "Сбросить окно")
    resetWindowButton:SetPoint("LEFT", resetButton, "RIGHT", 8, 0)
    resetWindowButton:SetScript("OnClick", function()
        if self.mainFrame then
            -- Set stored values first, then apply them so ApplySavedPosition uses updated data.
            GMHelperDB.window.point = "CENTER"
            GMHelperDB.window.relativePoint = "CENTER"
            GMHelperDB.window.x = 0
            GMHelperDB.window.y = 0
            ApplySavedPosition(self.mainFrame, GMHelperDB.window, "CENTER", "CENTER", 0, 0)
            GMH:Print("Позиция окна GMHelper сброшена.")
        end
    end)

    -- Option: close Blizzard Guild window when opening GMHelper
    local closeGuildCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    closeGuildCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -224)
    closeGuildCheckbox:SetWidth(20)
    closeGuildCheckbox:SetHeight(20)
    local closeGuildLabel = CreateText(frame, 10, COLORS.text)
    closeGuildLabel:SetPoint("LEFT", closeGuildCheckbox, "RIGHT", 6, 0)
    closeGuildLabel:SetText("Закрывать окно гильдии при открытии GMHelper")
    closeGuildCheckbox:SetChecked(GMHelperDB.settings and GMHelperDB.settings.closeGuildOnOpen)
    closeGuildCheckbox:SetScript("OnClick", function(self)
        GMHelperDB.settings.closeGuildOnOpen = self:GetChecked() and true or false
    end)

    -- Option: close GMHelper when Blizzard Guild window opens
    local closeAddonCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    closeAddonCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -250)
    closeAddonCheckbox:SetWidth(20)
    closeAddonCheckbox:SetHeight(20)
    local closeAddonLabel = CreateText(frame, 10, COLORS.text)
    closeAddonLabel:SetPoint("LEFT", closeAddonCheckbox, "RIGHT", 6, 0)
    closeAddonLabel:SetText("Закрывать GMHelper при открытии окна гильдии")
    closeAddonCheckbox:SetChecked(GMHelperDB.settings and GMHelperDB.settings.closeAddonOnGuildOpen)
    closeAddonCheckbox:SetScript("OnClick", function(self)
        GMHelperDB.settings.closeAddonOnGuildOpen = self:GetChecked() and true or false
    end)

    local note = CreateText(frame, 9, COLORS.muted, "LEFT")
    note:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -194)
    note:SetWidth(282)
    note:SetHeight(24)
    note:SetText("Сброс кнопки возвращает её в свободный режим.\nСброс окна центрирует окно GMHelper.")

    self.settingsFrame = frame
    self.settingsUpdateModeButtons = UpdateModeButtons
    return frame
end

function GMH.UI:ToggleSettings()
    local frame = self:CreateSettingsFrame()
    self:CreateToggleButton()

    if frame:IsShown() then
        frame:Hide()
        return
    end

    -- Окно настроек всегда открываем по центру экрана,
    -- независимо от положения кнопки GMHelper. Это особенно важно,
    -- когда кнопка находится у края экрана.
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if self.settingsUpdateModeButtons then
        self.settingsUpdateModeButtons()
    end
    frame:Show()
end

function GMH.UI:CreateToggleButton()
    if self.toggleButton then
        if GMHelperDB.button.mode == "minimap" then
            self.toggleButton:SetParent(Minimap)
        else
            self.toggleButton:SetParent(UIParent)
        end
        UpdateToggleButtonVisualState(self.toggleButton)
        return self.toggleButton
    end

    local parent = (GMHelperDB.button.mode == "minimap" and Minimap) or UIParent
    local button = CreateFrame("Button", "GMHelperToggleButton", parent)
    button:SetFrameStrata("MEDIUM")
    if GMHelperDB.button.mode == "minimap" and Minimap then
        button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    else
        button:SetFrameLevel(100)
    end
    button:SetClampedToScreen(true)
    button:SetSize(32, 32)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetSize(22, 22)
    icon:SetTexture("Interface\\AddOns\\GMHelper\\Textures\\GMHelperIcon")
    pcall(function() icon:SetTexCoord(0.10, 0.90, 0.10, 0.90) end)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(56, 56)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.overlay = border
    button._minimapBorder = border

    UpdateToggleButtonVisualState(button)

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            GMH.UI:Toggle()
        end
    end)

    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText("GMHelper", 1, 1, 1)
        GameTooltip:AddLine("ЛКМ — открыть / закрыть", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("ПКМ — настройки", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("ЛКМ + перетаскивание — переместить", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    EnableMovingButton(button)

    if GMHelperDB.button.mode == "minimap" then
        PositionButtonOnMinimap(button, GMHelperDB.button.angle or math.rad(45))
    else
        local data = {
            point = GMHelperDB.button.freePoint or GMHelperDB.button.point,
            relativePoint = GMHelperDB.button.freeRelativePoint or GMHelperDB.button.relativePoint,
            x = GMHelperDB.button.freeX or GMHelperDB.button.x,
            y = GMHelperDB.button.freeY or GMHelperDB.button.y,
        }
        ApplySavedPosition(button, data, "CENTER", "CENTER", 220, -120)
    end

    self.toggleButton = button
    return button
end

function GMH.UI:Toggle()
    self:CreateMainFrame()
    self:CreateToggleButton()

    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        -- Optionally close Blizzard Guild window when opening GMHelper
        if GMHelperDB.settings and GMHelperDB.settings.closeGuildOnOpen and GuildFrame and GuildFrame:IsShown() then
            pcall(HideUIPanel, GuildFrame)
        end

        -- Во время работы GMHelper всегда получает полный ростер,
        -- независимо от состояния стандартной галочки WoW.
        self:EnterRosterMode()
        self:Refresh()
        self:ScheduleRosterRefresh()
        self.mainFrame:Show()
    end
end

function GMH.UI:Initialize()
    self:CreateMainFrame()
    self:CreateToggleButton()
end
