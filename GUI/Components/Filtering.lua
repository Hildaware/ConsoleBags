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

function filtering:BuildContainer(parent, type, onSelect)
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

    f:SetScript('OnLeave', function(self)
        GameTooltip:Hide()
    end)

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

function filtering:Update(view, categories, pool, callback)
    -- Cleanup
    for i = 2, #categories + 1 do
        view.FilterFrame.Buttons[i] = nil
    end

    local filterOffset = 2
    for _, categoryData in ipairs(categories) do
        local frame = Pool.FetchInactive(pool, filterOffset, self.CreateButton)
        Pool.InsertActive(pool, frame, filterOffset)
        self:Build(view, frame, categoryData, filterOffset, callback)
        view.FilterFrame.Buttons[filterOffset] = frame
        filterOffset = filterOffset + 1
    end
end

function filtering:CreateButton()
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

function filtering:Build(view, frame, categoryData, index, callback)
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

    if GameTooltip.shoppingTooltips then
        for _, frame in pairs(GameTooltip.shoppingTooltips) do
            frame:Hide()
        end
    end

    callback()
end
