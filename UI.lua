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

local function EnableMovingButton(button)
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("RightButton")

    button:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local point, _, relativePoint, x, y = self:GetPoint()
        GMHelperDB.button.point = point
        GMHelperDB.button.relativePoint = relativePoint
        GMHelperDB.button.x = x
        GMHelperDB.button.y = y
    end)
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
            self:UpdateOfflineFilterUnit()
            self:RefreshRoster()
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
        self:RefreshRoster()
    end)

    self.resetButton = resetButton

    self.selectionLabel = nil

    ------------------------------------------------------------
    -- Действие над выбранными персонажами.
    -- Кнопка находится строго в той же строке фильтров.
    -- При создании всегда скрыта; показывается только после выбора.
    ------------------------------------------------------------

    local removeButton = CreateButton(toolbar, 190, 30, "Исключить выбранных")
    removeButton:SetPoint("LEFT", resetButton, "RIGHT", 8, 0)
    removeButton:Hide()
    removeButton:Enable(false)

    removeButton:SetScript("OnClick", function()
        self:ShowRemoveConfirmation()
    end)

    self.removeButton = removeButton

    local tableHeader = CreateFrame("Frame", nil, frame)
    tableHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -88)
    tableHeader:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -88)
    tableHeader:SetHeight(30)
    SetSolidBackground(tableHeader, COLORS.header)

    self.tableHeader = tableHeader

    ------------------------------------------------------------
    -- ScrollFrame
    ------------------------------------------------------------

    local scroll = CreateFrame("ScrollFrame", "GMHelperRosterScroll", frame)
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -118)
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

        if GMH.UI.UpdateScrollbar then
            GMH.UI:UpdateScrollbar()
        end
    end)

    scroll:SetScript("OnVerticalScroll", function(self)
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
    scrollbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -118)
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
        GMHelperDB.roster.onlineOnly = not GMHelperDB.roster.onlineOnly
        self:UpdateOnlineButton()
        self:RefreshRoster()
    end)

    self:UpdateOfflineFilterUnit()

    return frame
end

function GMH.UI:CreateColumns()
    local columns = {{
        key = "selected",
        label = "",
        width = 36,
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
            --------------------------------------------------------
            -- Чекбокс в заголовке: выбрать/снять все строки,
            -- попавшие в текущую выборку по фильтру.
            --------------------------------------------------------
            local selectAll = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")

            selectAll:SetWidth(24)
            selectAll:SetHeight(24)
            selectAll:SetPoint("CENTER", button, "CENTER", 0, 0)
            selectAll:EnableMouse(true)
            selectAll:RegisterForClicks("LeftButtonUp")
            selectAll:SetHitRectInsets(0, 0, 0, 0)

            selectAll:SetScript("OnClick", function(self)
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
                selectAll:SetChecked(not selectAll:GetChecked())
                selectAll:Click()
            end)
        else
            local label = CreateText(button, 10, COLORS.muted, column.align)
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

    local officerColumn = self.columns.officerNote

    if officerColumn then
        officerColumn.button:SetShown(canViewOfficerNote)
        officerColumn.labelObject:SetText(canEditOfficerNote and "Офицерская заметка" or
                                              "Офицерская заметка")
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

    if SetGuildRosterShowOffline then
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
        local va
        local vb

        -- Звание сортируем по числовому rankIndex, а не по названию.
        -- В ростере WoW rankIndex определяет реальный порядок званий.
        if column == "rankName" then
            va = tonumber(a.rankIndex) or 0
            vb = tonumber(b.rankIndex) or 0
        else
            va = a[column]
            vb = b[column]

            if column == "name" or column == "publicNote" or column == "officerNote" then
                va = Lower(va)
                vb = Lower(vb)
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

    -- Если кликнули по выбранному персонажу и выбрано несколько,
    -- применяем новое звание ко всей выборке.
    if clickedMember and clickedMember.selected and #selected > 1 then
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
    frame:SetHeight(220)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(self.mainFrame:GetFrameLevel() + 20)
    frame:Hide()

    SetSolidBackground(frame, {0.02, 0.025, 0.035, 0.98})

    local title = CreateText(frame, 15, COLORS.text, "CENTER")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -16)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -16)
    title:SetHeight(24)
    title:SetText("Подтверждение изменения звания")

    local message = CreateText(frame, 12, COLORS.text, "CENTER")
    message:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -50)
    message:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -50)
    message:SetHeight(92)
    message:SetJustifyV("MIDDLE")
    message:SetWordWrap(true)

    local yesButton = CreateButton(frame, 110, 32, "Да")
    yesButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -8, 20)

    local cancelButton = CreateButton(frame, 110, 32, "Отменить")
    cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 8, 20)

    cancelButton:SetScript("OnClick", function()
        frame:Hide()
        self.rankChangePending = nil
    end)

    yesButton:SetScript("OnClick", function()
        frame:Hide()
        self:StartRankChangeQueue()
    end)

    self.rankConfirmFrame = frame
    self.rankConfirmMessage = message

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

    self.rankConfirmMessage:SetText(self:BuildRankChangeConfirmationText(#targets, targetRankName, skipped))

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", self.mainFrame, "CENTER", 0, 0)
    frame:Show()
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

        GMH:Print("Очередь изменения званий завершена.")
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
    -- Обычный Frame вместо Button: это исключает влияние
    -- стандартного состояния Button на отображение FontString.
    local row = CreateFrame("Frame", nil, self.content)
    row:SetWidth(726)
    row:SetHeight(32)
    row:EnableMouse(true)
    row:SetFrameLevel(self.content:GetFrameLevel() + 2)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(row)
    background:SetTexture(1, 1, 1, 1)

    local function ApplyRowColor()
        if (rowIndex % 2) == 0 then
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

    ------------------------------------------------------------
    -- Чекбокс
    ------------------------------------------------------------

    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")

    checkbox:SetWidth(24)
    checkbox:SetHeight(24)
    checkbox:SetPoint("CENTER", row, "LEFT", 18, 0)

    checkbox:SetChecked(member.selected and true or false)

    checkbox:SetScript("OnClick", function(self)
        member.selected = self:GetChecked() and true or false
        GMH.UI:UpdateSelectionCount()
    end)

    ------------------------------------------------------------
    -- Ячейки
    ------------------------------------------------------------

    local x = 36

    local function AddCell(text, width, justify, color, offset)
        local cell = CreateText(row, 10, color or COLORS.text, justify or "LEFT")

        cell:SetDrawLayer("OVERLAY")
        cell:SetPoint("LEFT", row, "LEFT", offset or x, 0)

        cell:SetWidth(width)
        cell:SetHeight(32)
        cell:SetJustifyV("MIDDLE")
        cell:SetWordWrap(false)
        cell:SetText(tostring(text or ""))

        return cell
    end

    local nameColor = member.isOnline and COLORS.text or COLORS.muted

    local nameCell = AddCell(member.name, 140, "LEFT", nameColor, x + 7)

    x = x + 140

    local levelColor = member.isOnline and COLORS.text or COLORS.muted

    local levelCell = AddCell(tostring(member.level or ""), 50, "CENTER", levelColor, x)

    x = x + 50

    local rankCell
    local rankOptions = self:GetRankOptionsForMember(member)

    if #rankOptions > 0 then
        local rankButton = CreateFrame("Button", nil, row)
        rankButton:SetWidth(110)
        rankButton:SetHeight(32)
        rankButton:SetPoint("LEFT", row, "LEFT", x, 0)
        rankButton:EnableMouse(true)

        local rankBg = rankButton:CreateTexture(nil, "BACKGROUND")
        rankBg:SetAllPoints(rankButton)
        rankBg:SetTexture(1, 1, 1, 1)
        rankBg:SetVertexColor(1, 1, 1, 0.001)

        local rankLabel = CreateText(rankButton, 10, COLORS.text, "LEFT")
        rankLabel:SetPoint("LEFT", rankButton, "LEFT", 7, 0)
        rankLabel:SetWidth(92)
        rankLabel:SetHeight(32)
        rankLabel:SetJustifyV("MIDDLE")
        rankLabel:SetWordWrap(false)
        rankLabel:SetText(member.rankName)

        -- В FRIZQT__.TTF символ "▼" на клиенте отображается как "?".
        -- Используем совместимый ASCII-символ в виде небольшой стрелки.
        local arrow = CreateText(rankButton, 10, COLORS.muted, "CENTER")
        arrow:SetPoint("RIGHT", rankButton, "RIGHT", -5, 0)
        arrow:SetWidth(12)
        arrow:SetHeight(32)
        arrow:SetJustifyV("MIDDLE")
        arrow:SetText("v")

        rankButton:SetScript("OnEnter", function()
            rankBg:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.10)
        end)

        rankButton:SetScript("OnLeave", function()
            rankBg:SetVertexColor(1, 1, 1, 0.001)
        end)

        rankButton:SetScript("OnClick", function()
            self:ShowRankMenu(rankButton, member)
        end)

        rankCell = rankButton
    else
        rankCell = AddCell(member.rankName, 110, "LEFT", COLORS.text, x + 7)
    end

    x = x + 110

    local publicCell

    if GMH.Permissions:Can("edit_public_note") then
        local noteButton = CreateFrame("Button", nil, row)
        noteButton:SetPoint("LEFT", row, "LEFT", x, 0)
        noteButton:SetWidth(135)
        noteButton:SetHeight(32)
        noteButton:SetFrameLevel(row:GetFrameLevel() + 1)
        noteButton:EnableMouse(true)

        publicCell = AddCell(member.publicNote, 135, "LEFT", COLORS.muted, x + 7)

        local publicEmpty = Trim(member.publicNote or "") == ""
        if publicEmpty then
            AddSubtleBorder(noteButton)
        end

        noteButton:SetScript("OnEnter", function()
            publicCell:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], 1)
            if publicEmpty and noteButton._noteBorder then
                for _, border in ipairs(noteButton._noteBorder) do
                    border:SetAlpha(0.28)
                end
            end
        end)

        noteButton:SetScript("OnLeave", function()
            publicCell:SetTextColor(COLORS.muted[1], COLORS.muted[2], COLORS.muted[3], 1)
            if noteButton._noteBorder then
                for _, border in ipairs(noteButton._noteBorder) do
                    border:SetAlpha(publicEmpty and 0.16 or 0)
                end
            end
        end)

        noteButton:SetScript("OnClick", function()
            self:ShowNoteEditor(member, "public")
        end)
    else
        publicCell = AddCell(member.publicNote, 135, "LEFT", COLORS.muted, x + 7)
    end

    x = x + 135

    local officerCell

    if self.columns.officerNote.button:IsShown() then
        if GMH.Permissions:Can("edit_officer_note") then
            local noteButton = CreateFrame("Button", nil, row)
            noteButton:SetPoint("LEFT", row, "LEFT", x, 0)
            noteButton:SetWidth(135)
            noteButton:SetHeight(32)
            noteButton:SetFrameLevel(row:GetFrameLevel() + 1)
            noteButton:EnableMouse(true)

            officerCell = AddCell(member.officerNote, 135, "LEFT", COLORS.muted, x + 7)

            local officerEmpty = Trim(member.officerNote or "") == ""
            if officerEmpty then
                AddSubtleBorder(noteButton)
            end

            noteButton:SetScript("OnEnter", function()
                officerCell:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], 1)
                if officerEmpty and noteButton._noteBorder then
                    for _, border in ipairs(noteButton._noteBorder) do
                        border:SetAlpha(0.28)
                    end
                end
            end)

            noteButton:SetScript("OnLeave", function()
                officerCell:SetTextColor(COLORS.muted[1], COLORS.muted[2], COLORS.muted[3], 1)
                if noteButton._noteBorder then
                    for _, border in ipairs(noteButton._noteBorder) do
                        border:SetAlpha(officerEmpty and 0.16 or 0)
                    end
                end
            end)

            noteButton:SetScript("OnClick", function()
                self:ShowNoteEditor(member, "officer")
            end)
        else
            officerCell = AddCell(member.officerNote, 135, "LEFT", COLORS.muted, x + 7)
        end
    end

    if self.columns.officerNote.button:IsShown() then
        x = x + 135
    end

    local lastOnlineColor = member.isOnline and COLORS.allowed or COLORS.muted

    local lastOnlineCell = AddCell(member.lastOnlineText, 120, "LEFT", lastOnlineColor, x + 7)

    row.checkbox = checkbox
    row.member = member
    row.background = background
    row.nameCell = nameCell
    row.levelCell = levelCell
    row.rankCell = rankCell
    row.publicCell = publicCell
    row.officerCell = officerCell
    row.lastOnlineCell = lastOnlineCell

    self.rows[#self.rows + 1] = row

    return row
end

function GMH.UI:RefreshRoster()
    if not self.mainFrame then
        return
    end

    if self.rosterModeActive then
        self:RefreshRosterCache()
    end

    for _, row in ipairs(self.rows or {}) do
        row:Hide()
    end

    self.rows = {}

    local allMembers = self:GetRosterData()
    local visibleMembers = {}

    for _, member in ipairs(allMembers) do
        if self:MatchesFilter(member) then
            visibleMembers[#visibleMembers + 1] = member
        end
    end

    self:SortRoster(visibleMembers)

    local rowY = 0

    for index, member in ipairs(visibleMembers) do
        local row = self:CreateRow(member, index)
        row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, rowY)
        rowY = rowY - 32
    end

    self.content:SetHeight(math.max(math.abs(rowY) + 6, 1))
    self.scroll:SetVerticalScroll(0)

    self:UpdateScrollbar()
    self:UpdateSelectionCount()
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

function GMH.UI:GetSelectedMembers()
    local selected = {}

    for _, member in ipairs(self.rosterCache or {}) do
        if member.selected then
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
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(self.mainFrame:GetFrameLevel() + 20)
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
    if not self.removeButton then
        return
    end

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
    local selected = 0
    local visible = 0
    local visibleSelected = 0

    local members = self:GetRosterData() or {}

    for _, member in ipairs(members) do
        if member.selected then
            selected = selected + 1
        end

        if self:MatchesFilter(member) then
            visible = visible + 1
            if member.selected then
                visibleSelected = visibleSelected + 1
            end
        end
    end

    if self.selectionLabel then
        self.selectionLabel:SetText("Выбрано: " .. tostring(selected))
    end

    ------------------------------------------------------------
    -- Состояние чекбокса в заголовке.
    -- Он отмечен только когда выбраны все строки текущей
    -- выборки. При смешанном состоянии остаётся снятым.
    ------------------------------------------------------------
    local selectAll = self.columns and self.columns.selected and self.columns.selected.selectAll

    if selectAll then
        selectAll:SetChecked(visible > 0 and visibleSelected == visible)
    end

    if self.removeButton then
        local canRemove = GMH.Permissions:Can("remove_member")
        local hasSelection = selected > 0

        -- По умолчанию кнопка всегда скрыта.
        self.removeButton:Hide()
        self.removeButton:Enable(false)

        if canRemove and hasSelection then
            self.removeButton._label:SetText("Исключить выбранных (" .. tostring(selected) .. ")")
            self.removeButton._background:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.16)
            self.removeButton:Show()
            self.removeButton:Enable(true)
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

    local startedAt = GetTime()
    local elapsed = 0

    self._rosterRefreshFrame = self._rosterRefreshFrame or CreateFrame("Frame")

    self._rosterRefreshFrame:SetScript("OnUpdate", function(frame, delta)
        elapsed = elapsed + delta

        if elapsed < 0.5 then
            return
        end

        if elapsed >= 2.0 then
            frame:SetScript("OnUpdate", nil)
            self._rosterRefreshScheduled = false

            if self.mainFrame then
                GMH:RequestGuildRoster()
                self:Refresh()
            end
        else
            if self.mainFrame then
                self:RefreshRoster()
            end
        end
    end)
end

function GMH.UI:OnGuildRosterUpdate()
    if self.mainFrame then
        self:Refresh()
    end
end

function GMH.UI:CreateToggleButton()
    if self.toggleButton then
        return self.toggleButton
    end

    local button = CreateFrame("Button", "GMHelperToggleButton", UIParent)
    button:SetWidth(46)
    button:SetHeight(46)
    button:SetFrameStrata("DIALOG")
    button:SetClampedToScreen(true)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetWidth(36)
    icon:SetHeight(36)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_07")
    button.icon = icon

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            GMH.UI:Toggle()
        end
    end)

    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText("GMHelper", 1, 1, 1)
        GameTooltip:AddLine("ЛКМ — открыть / закрыть", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("ПКМ + перетаскивание — переместить", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    EnableMovingButton(button)

    ApplySavedPosition(button, GMHelperDB.button, "CENTER", "CENTER", 220, -120)

    self.toggleButton = button
    return button
end

function GMH.UI:Toggle()
    self:CreateMainFrame()
    self:CreateToggleButton()

    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
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
