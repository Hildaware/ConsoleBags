local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Filtering: AceModule
local filtering = addon:NewModule('Filtering')

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

local function OnFilterSelect(view, category, callback)
    view.selectedFilter = category

    if GameTooltip['shoppingTooltips'] then
        for _, frame in pairs(GameTooltip['shoppingTooltips']) do
            frame:Hide()
        end
    end

    callback()
end

function filtering:BuildContainer(view, type, onSelect)
    local cFrame = CreateFrame('Frame', nil, view)
    cFrame:SetSize(view:GetWidth(), session.Settings.Defaults.Sections.Filters)
    cFrame:SetPoint('TOPLEFT', view, 'TOPLEFT', 0, -session.Settings.Defaults.Sections.Header)

    local tex = cFrame:CreateTexture(nil, 'BACKGROUND')
    tex:SetAllPoints(cFrame)
    tex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Underline')
    tex:SetVertexColor(1, 1, 1, 0.5)

    cFrame.Buttons = {}

    -- All
    local f = CreateFrame('Button', nil, cFrame)
    f:SetSize(28, 28)
    f:SetPoint('LEFT', cFrame, 'LEFT', 34, 0)

    local aTex = f:CreateTexture(nil, 'OVERLAY')
    aTex:SetPoint('CENTER', 0, 'CENTER')
    aTex:SetSize(24, 24)
    aTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Logo_Normal')

    local selectedTex = f:CreateTexture(nil, 'ARTWORK')
    selectedTex:SetPoint('CENTER', f, 'CENTER')
    selectedTex:SetSize(28, session.Settings.Defaults.Sections.Filters - 6)
    selectedTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Filter_Highlight')
    selectedTex:SetVertexColor(1, 1, 1, 0.5)

    f.isSelected = selectedTex

    f:SetScript('OnEnter', function(self)
        local itemCount = 0
        if type == enums.InventoryType.Inventory then
            itemCount = session.Inventory.TotalCount
        elseif type == enums.InventoryType.Bank then
            itemCount = session.Bank.TotalCount
        end

        GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetText('All (' .. itemCount .. ')', 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    f:RegisterForClicks('AnyDown')
    f:RegisterForClicks('AnyUp')
    f:SetScript('OnClick', function() OnFilterSelect(view, nil, onSelect) end)
    f.OnSelect = function() OnFilterSelect(view, nil, onSelect) end

    f:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    cFrame.Buttons[1] = f

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

    view.FilterFrame = cFrame
end

function filtering:Update(view, categories, pool, callback)
    -- Cleanup all buttons except 'ALL'
    for i = 2, #categories + 1 do
        view.FilterFrame.Buttons[i] = nil
    end

    local filterOffset = 2
    for _, categoryData in ipairs(categories) do
        local frame = Pool.FetchInactive(pool, filterOffset, self.Create)
        Pool.InsertActive(pool, frame, filterOffset)
        self:Build(view, frame, categoryData, filterOffset, callback)
        view.FilterFrame.Buttons[filterOffset] = frame
        filterOffset = filterOffset + 1
    end

    if view.selectedFilter == nil then
        view.FilterFrame.Buttons[1].isSelected:Show()
    else
        view.FilterFrame.Buttons[1].isSelected:Hide()
    end
end

function filtering:Create()
    local f = CreateFrame('Button')
    f:SetSize(28, session.Settings.Defaults.Sections.Filters)

    local tex = f:CreateTexture(nil, 'ARTWORK')
    tex:SetPoint('CENTER', 0, 'CENTER')
    tex:SetSize(24, 24)

    f.texture = tex
    f:RegisterForClicks('AnyDown')
    f:RegisterForClicks('AnyUp')

    local selectedTex = f:CreateTexture(nil, 'ARTWORK')
    selectedTex:SetPoint('CENTER', f, 'CENTER')
    selectedTex:SetSize(28, session.Settings.Defaults.Sections.Filters - 6)
    selectedTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Filter_Highlight')
    selectedTex:SetVertexColor(1, 1, 1, 0.5)

    f.isSelected = selectedTex

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

function filtering:Build(view, frame, categoryData, index, callback)
    if frame == nil then return end

    frame:SetParent(view.FilterFrame)
    frame:SetPoint('LEFT', index * 32, 0)

    frame:RegisterForClicks('AnyDown')
    frame:RegisterForClicks('AnyUp')

    frame.texture:SetTexture(utils.GetCategoyIcon(categoryData.key))

    if categoryData.hasNew == true then
        frame.newTexture:Show()
    else
        frame.newTexture:Hide()
    end

    if view.selectedFilter == categoryData.key then
        frame.isSelected:Show()
    else
        frame.isSelected:Hide()
    end

    local onSelect = function()
        callback(categoryData.key)
    end
    frame.OnSelect = function() OnFilterSelect(view, categoryData.key, onSelect) end

    frame:SetScript('OnClick', function()
        OnFilterSelect(view, categoryData.key, onSelect)
    end)

    frame:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetText(categoryData.name .. ' (' .. categoryData.count .. ')', 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    frame:Show()

    return frame
end
