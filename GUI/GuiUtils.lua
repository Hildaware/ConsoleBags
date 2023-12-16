local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class GUIUtils: AceModule
local guiUtils = addon:NewModule('GUIUtils')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Database: AceModule
local database = addon:GetModule('Database')

-- Filtering
function guiUtils:BuildFilteringContainer(parent, type, onSelect)
    local cFrame = CreateFrame('Frame', nil, parent)
    cFrame:SetSize(parent:GetWidth(), session.Settings.Defaults.Sections.Filters)
    cFrame:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, -session.Settings.Defaults.Sections.Header)

    local tex = cFrame:CreateTexture(nil, 'BACKGROUND')
    tex:SetAllPoints(cFrame)
    tex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Underline')
    tex:SetVertexColor(1, 1, 1, 0.5)

    cFrame.Buttons = {}
    cFrame.SelectedIndex = 1

    -- All
    local f = CreateFrame('Button', nil, cFrame)
    f:SetSize(28, 28)
    f:SetPoint('LEFT', cFrame, 'LEFT', 30, 0)

    local aTex = f:CreateTexture(nil, 'OVERLAY')
    aTex:SetPoint('CENTER', 0, 'CENTER')
    aTex:SetSize(24, 24)
    aTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Logo_Normal')

    f:SetScript('OnEnter', function(self)
        local itemCount = 0
        if type == enums.InventoryType.Inventory then
            itemCount = session.InventoryCount
        elseif type == enums.InventoryType.Bank then
            itemCount = session.BankCount
        end

        GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetText('All (' .. itemCount .. ')', 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    f:SetScript('OnClick', function(self)
        Filter_OnClick(f, 1, onSelect)
    end)
    f:RegisterForClicks('AnyDown')
    f:RegisterForClicks('AnyUp')
    f.OnSelect = function() Filter_OnClick(f, 1, onSelect) end

    cFrame.Buttons[1] = f

    -- IsSelected
    local selectedTex = cFrame:CreateTexture(nil, 'ARTWORK')
    selectedTex:SetPoint('BOTTOMLEFT', cFrame, 'BOTTOMLEFT', 30, 3)
    selectedTex:SetSize(28, session.Settings.Defaults.Sections.Filters - 6)
    selectedTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Filter_Highlight')
    selectedTex:SetVertexColor(1, 1, 1, 0.5)

    -- LEFT / RIGHT Buttons
    if _G['ConsolePort'] and type == enums.InventoryType.Inventory then
        local lTexture = cFrame:CreateTexture(nil, 'ARTWORK')
        lTexture:SetPoint('LEFT', cFrame, 'LEFT', 6, 0)
        lTexture:SetSize(24, 24)
        lTexture:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\lb')

        local rTexture = cFrame:CreateTexture(nil, 'ARTWORK')
        rTexture:SetPoint('RIGHT', cFrame, 'RIGHT', -6, 0)
        rTexture:SetSize(24, 24)
        rTexture:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\rb')
    end

    cFrame.selectedTexture = selectedTex
    parent.FilterFrame = cFrame
end

function guiUtils:UpdateFilterButtons(view, categories, pool, callback)

    -- Cleanup
    for i = 2, #categories + 1 do
        view.FilterFrame.Buttons[i] = nil
    end

    local filterOffset = 2
    for _, categoryData in ipairs(categories) do
        local frame = Pool.FetchInactive(pool, filterOffset, guiUtils.CreateFilterButtonPlaceholder)
        Pool.InsertActive(pool, frame, filterOffset)
        self:BuildFilterButton(view, frame, categoryData, filterOffset, callback)
        view.FilterFrame.Buttons[filterOffset] = frame
        filterOffset = filterOffset + 1
    end
end

function guiUtils:CreateFilterButtonPlaceholder()
    local f = CreateFrame('Button')
    f:SetSize(28, session.Settings.Defaults.Sections.Filters)

    local tex = f:CreateTexture(nil, 'ARTWORK')
    tex:SetPoint('CENTER', 0, 'CENTER')
    tex:SetSize(24, 24)

    f.texture = tex
    f:RegisterForClicks('AnyDown')
    f:RegisterForClicks('AnyUp')

    local newTex = f:CreateTexture(nil, 'OVERLAY')
    newTex:SetPoint('TOPRIGHT', f, 'TOPRIGHT', 0, -4)
    newTex:SetSize(12, 12)
    newTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Exclamation')
    newTex:Hide()

    f.newTexture = newTex

    f:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    return f
end

function guiUtils:BuildFilterButton(view, frame, categoryData, index, callback)
    if frame == nil then return end

    frame:SetParent(view.FilterFrame)
    frame:SetPoint('LEFT', index * 30, 0)

    frame:RegisterForClicks('AnyDown')
    frame:RegisterForClicks('AnyUp')

    frame.texture:SetTexture(utils.GetCategoyIcon(categoryData.key))

    if categoryData.hasNew == true then
        frame.newTexture:Show()
    else
        frame.newTexture:Hide()
    end

    local onSelect = function()
        callback(categoryData.key)
    end
    frame.OnSelect = function() Filter_OnClick(frame, index, onSelect) end

    frame:SetScript('OnClick', function(self)
        Filter_OnClick(self, index, onSelect)
    end)

    frame:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetText(categoryData.name .. ' (' .. categoryData.count .. ')', 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    frame:Show()

    return frame
end

function Filter_OnClick(self, index, callback)
    self:GetParent().selectedTexture:SetPoint('LEFT', (index * 30), 0)
    callback()
end

-- Sorting
function guiUtils:BuildSortingContainer(parent, type, onSelect)
    local hFrame = CreateFrame('Frame', nil, parent)
    hFrame:SetSize(parent:GetWidth(), session.Settings.Defaults.Sections.ListViewHeader)
    local offset = session.Settings.Defaults.Sections.Header + session.Settings.Defaults.Sections.Filters
    hFrame:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, -offset)

    hFrame.fields = {}

    local tex = hFrame:CreateTexture(nil, 'BACKGROUND')
    tex:SetPoint('TOPLEFT', hFrame, 'TOPLEFT', 0, -4)
    tex:SetPoint('BOTTOMRIGHT', hFrame, 'BOTTOMRIGHT')
    tex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Doubleline')
    tex:SetVertexColor(1, 1, 1, 0.5)

    local icon = self:BuildSortButton(hFrame, hFrame, '•', session.Settings.Defaults.Columns.Icon,
        enums.SortFields.Icon, true, type, 'Rarity', onSelect)

    local name = self:BuildSortButton(hFrame, icon, 'name', session.Settings.Defaults.Columns.Name,
        enums.SortFields.Name, false, type, 'Item Name', onSelect)

    -- local category = BuildSortButton(hFrame, name, 'cat', session.Settings.Defaults.Columns.Category,
    --     enums.SortFields.Category, false, type)

    local ilvl = self:BuildSortButton(hFrame, name, 'ilvl', session.Settings.Defaults.Columns.Ilvl,
        enums.SortFields.Ilvl, false, type, 'Item Level', onSelect)

    local reqlvl = self:BuildSortButton(hFrame, ilvl, 'req', session.Settings.Defaults.Columns.ReqLvl,
        enums.SortFields.ReqLvl, false, type, 'Required Level', onSelect)

    local value = self:BuildSortButton(hFrame, reqlvl, 'value', session.Settings.Defaults.Columns.Value,
        enums.SortFields.Value, false, type, 'Gold Value', onSelect)
end

function guiUtils:BuildSortButton(parent, anchor, name, width, sortField, initial, type, friendlyName, onSelect)
    local frame = CreateFrame('Button', nil, parent)
    frame:SetSize(width, parent:GetHeight())
    frame:SetPoint('LEFT', anchor, initial and 'LEFT' or 'RIGHT', initial and 3 or 0, 0)

    local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    text:SetPoint('BOTTOM', frame, 'BOTTOM', 0, 12)
    text:SetJustifyH('CENTER')
    text:SetText(name)
    text:SetTextColor(1, 1, 1)

    local arrow = frame:CreateTexture('ARTWORK')
    arrow:SetPoint('LEFT', text, 'RIGHT', 2, 0)
    arrow:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Arrow_Up')
    arrow:SetSize(8, 14)

    local sortData
    if type == enums.InventoryType.Inventory then
        sortData = database:GetInventorySortField()
    elseif type == enums.InventoryType.Bank then
        sortData = database:GetBankSortField()
    end

    if sortData.Sort == enums.SortOrder.Desc then
        arrow:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Arrow_Up')
    else
        arrow:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Arrow_Down')
    end

    if sortData.Field ~= sortField then
        arrow:Hide()
    end

    frame:SetScript('OnClick', function()
        local sortOrder = sortData.Sort
        if sortData.Field == sortField then
            if sortOrder == enums.SortOrder.Asc then
                sortOrder = enums.SortOrder.Desc
            else
                sortOrder = enums.SortOrder.Asc
            end
        end

        sortData.Field = sortField
        sortData.Sort = sortOrder

        if sortData.Sort ~= enums.SortOrder.Desc then
            arrow:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Arrow_Up')
        else
            arrow:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Arrow_Down')
        end

        arrow:Show()
        text:SetTextColor(1, 1, 0)

        -- Remove other arrows
        for _, k in pairs(enums.SortFields) do
            if k ~= sortField then
                parent.fields[k].arrow:Hide()
                parent.fields[k].text:SetTextColor(1, 1, 1)
            end
        end

        onSelect()
    end)

    frame:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetText('Sort By: ' .. friendlyName, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    frame:SetScript('OnLeave', function(self)
        GameTooltip:Hide()
    end)

    parent.fields[sortField] = frame
    frame.arrow = arrow
    frame.text = text

    return frame
end

-- Utils
function guiUtils:CreateBorder(self)
    if not self.borders then
        self.borders = {}
        for i = 1, 4 do
            self.borders[i] = self:CreateLine(nil, 'BACKGROUND', nil, 0)
            local l = self.borders[i]
            l:SetThickness(1)
            l:SetColorTexture(0, 0, 0, 1)
            if i == 1 then
                l:SetStartPoint('TOPLEFT')
                l:SetEndPoint('TOPRIGHT')
            elseif i == 2 then
                l:SetStartPoint('TOPRIGHT')
                l:SetEndPoint('BOTTOMRIGHT')
            elseif i == 3 then
                l:SetStartPoint('BOTTOMRIGHT')
                l:SetEndPoint('BOTTOMLEFT')
            else
                l:SetStartPoint('BOTTOMLEFT')
                l:SetEndPoint('TOPLEFT')
            end
        end
    end
end