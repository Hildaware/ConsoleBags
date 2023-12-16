local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CategoryHeaders: AceModule
local categoryHeaders = addon:NewModule('CategoryHeaders')

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

function categoryHeaders:BuildCategoryFrame(data, offset, frame, parent, collapsedCategories, callback)
    if frame == nil then return end

    frame:SetParent(parent)
    frame:SetPoint('TOP', 0, -((offset - 1) * session.Settings.Defaults.Sections.ListItemHeight))

    if collapsedCategories[data.key] then
        frame:GetNormalTexture():SetVertexColor(1, 0, 0, 1)
    else
        frame:GetNormalTexture():SetVertexColor(1, 1, 1, 0.35)
    end

    frame.type:SetTexture(utils.GetCategoyIcon(data.key))
    frame.name:SetText(data.name .. ' (' .. data.count .. ')')

    frame:SetScript('OnClick', function(self, button, down)
        if button == 'LeftButton' then

            local isCollapsed = collapsedCategories[data.key] and
                collapsedCategories[data.key] == true

            if isCollapsed then
                collapsedCategories[data.key] = false
            else
                collapsedCategories[data.key] = true
            end

            callback()
        end
    end)

    frame:Show()
end

-- TODO: SetSize will eventually need to be set based on the View
function categoryHeaders:CreateCategoryHeaderPlaceholder()
    local f = CreateFrame('Button')
    f:SetSize(600-24, session.Settings.Defaults.Sections.ListItemHeight)

    f:RegisterForClicks('LeftButtonUp')

    f:SetNormalTexture('Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight_Solid')
    f:GetNormalTexture():SetVertexColor(1, 1, 0, 0.5)
    f:SetHighlightTexture('Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight_Solid')
    f:GetHighlightTexture():SetVertexColor(1, 1, 0, 0.25)

    -- type
    local type = CreateFrame('Frame', nil, f)
    type:SetPoint('LEFT', f, 'LEFT', 8, 0)
    type:SetHeight(session.Settings.Defaults.Sections.ListItemHeight)
    type:SetWidth(32)

    local typeTex = type:CreateTexture(nil, 'ARTWORK')
    typeTex:SetPoint('CENTER', type, 'CENTER')
    typeTex:SetSize(24, 24)

    f.type = typeTex

    -- Name
    local name = CreateFrame('Frame', nil, f)
    name:SetPoint('LEFT', type, 'RIGHT', 8, 0)
    name:SetHeight(session.Settings.Defaults.Sections.ListItemHeight)
    name:SetWidth(300)
    local nameText = name:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    nameText:SetAllPoints(name)
    nameText:SetJustifyH('LEFT')

    f.name = nameText

    f.isHeader = true

    return f
end

categoryHeaders:Enable()