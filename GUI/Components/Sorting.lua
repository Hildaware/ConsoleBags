local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Sorting: AceModule
local sorting = addon:NewModule('Sorting')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Database: AceModule
local database = addon:GetModule('Database')

function sorting:Build(parent, type, onSelect)
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

    local icon = self:Create(hFrame, hFrame, '•', session.Settings.Defaults.Columns.Icon,
        enums.SortFields.Icon, true, type, 'Rarity', onSelect)

    local name = self:Create(hFrame, icon, 'name', session.Settings.Defaults.Columns.Name,
        enums.SortFields.Name, false, type, 'Item Name', onSelect)

    -- local category = CreateButton(hFrame, name, 'cat', session.Settings.Defaults.Columns.Category,
    --     enums.SortFields.Category, false, type)

    local ilvl = self:Create(hFrame, name, 'ilvl', session.Settings.Defaults.Columns.Ilvl,
        enums.SortFields.Ilvl, false, type, 'Item Level', onSelect)

    local reqlvl = self:Create(hFrame, ilvl, 'req', session.Settings.Defaults.Columns.ReqLvl,
        enums.SortFields.ReqLvl, false, type, 'Required Level', onSelect)

    local value = self:Create(hFrame, reqlvl, 'value', session.Settings.Defaults.Columns.Value,
        enums.SortFields.Value, false, type, 'Gold Value', onSelect)
end

function sorting:Create(parent, anchor, name, width, sortField, initial, type, friendlyName, onSelect)
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

sorting:Enable()
