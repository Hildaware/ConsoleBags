local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class ItemFrame: AceModule
local itemFrame = addon:NewModule('ItemFrame')

---@class Session: AceModule
local session = addon:GetModule('Session')

local Masque = LibStub('Masque', true)

function itemFrame:BuildItemFrame(item, offset, frame, parent)
    if frame == nil then return end

    frame.item = item
    session.FramesByItemId[item.id] = session.FramesByItemId[item.id] or {}
    tinsert(session.FramesByItemId[item.id], frame)

    frame:SetParent(parent)
    frame:SetPoint('TOP', 0, -((offset - 1) * session.Settings.Defaults.Sections.ListItemHeight))

    local tooltipOwner = GameTooltip:GetOwner()

    frame.itemButton:SetID(item.slot)
    frame:SetID(item.bag)

    frame.itemButton:SetHasItem(item.texture)

    local r, g, b, _ = GetItemQualityColor(item.quality or 0)
    frame.itemButton.HighlightTexture:SetVertexColor(r, g, b, 1)

    frame.itemButton:HookScript('OnEnter', function(s)
        s.HighlightTexture:Show()
    end)
    frame.itemButton:HookScript('OnLeave', function(s)
        s.HighlightTexture:Hide()
        s.NewTexture:Hide()
        frame.item.isNew = false
    end)

    local questInfo = item.questInfo
    local isQuestItem = questInfo.isQuestItem;
    local questID = questInfo.questID;
    local isActive = questInfo.isActive

    -- Utilize the Icon as an ItemButton
    frame.icon:SetID(item.slot)
    frame.icon.frame:SetID(item.bag)

    ClearItemButtonOverlay(frame.icon)
    frame.icon:SetHasItem(item.texture)
    frame.icon:SetItemButtonTexture(item.texture)
    SetItemButtonQuality(frame.icon, item.quality, item.link, false, item.bound)
    SetItemButtonCount(frame.icon, item.stackCount)
    SetItemButtonDesaturated(frame.icon, item.isLocked)
    frame.icon:UpdateExtended()
    frame.icon:UpdateQuestItem(isQuestItem, questID, isActive)
    frame.icon:UpdateNewItem(item.quality)
    frame.icon:UpdateJunkItem(item.quality, item.hasNoValue)
    frame.icon:UpdateItemContextMatching()
    frame.icon:UpdateCooldown(item.texture)
    frame.icon:SetReadable(item.isReadable)
    frame.icon:CheckUpdateTooltip(tooltipOwner)
    frame.icon:SetMatchesSearch(not item.isFiltered)
    frame.icon:Show()
    frame.icon:EnableMouse(false)

    -- Pawn Support
    if _G['PawnIsContainerItemAnUpgrade'] then
        if _G['PawnIsContainerItemAnUpgrade'](item.bag, item.slot) then
            frame.icon.upgrade:Show()
        else
            frame.icon.upgrade:Hide()
        end
    end

    -- Can I Mog It? Support
    if _G['CanIMogIt'] then
        local iconText = _G['CanIMogIt']:GetIconText(item.link, item.bag, item.slot)
        if iconText and iconText ~= '' then
            frame.icon.canI.text:SetText(iconText)
            frame.icon.canI:Show()
        else
            frame.icon.canI.text:SetText('')
            frame.icon.canI:Hide()
        end
    end

    -- Masque Support
    if Masque then
        ---@diagnostic disable-next-line: undefined-field
        local cBags = Masque:Group('ConsoleBags')
        cBags:AddButton(frame.icon)
    end

    local stackString = (item.stackCount and item.stackCount > 1) and '(' .. item.stackCount .. ')' or nil
    local nameString = item.name
    if stackString then
        nameString = nameString .. ' ' .. stackString
    end
    frame.name:SetText(nameString)

    -- Color
    frame.name:SetTextColor(r, g, b)

    -- frame.type:SetTexture(CB.U.GetCategoyIcon(item.type))

    if item.type == Enum.ItemClass.Armor or item.type == Enum.ItemClass.Weapon
        or item.category == Enum.ItemClass.Battlepet then
        frame.ilvl:SetText(item.ilvl)
    else
        frame.ilvl:SetText('')
    end

    if item.reqLvl and item.reqLvl > 1 then
        frame.reqlvl:SetText(item.reqLvl)
    else
        frame.reqlvl:SetText('')
    end

    if item.value and item.value > 1 then
        frame.value:SetText(GetCoinTextureString(item.value))
    else
        frame.value:SetText('')
    end

    frame.index = offset

    self:Update(frame)
    frame:Show()
    frame.itemButton:Show()
end

function itemFrame:Update(frame)
    -- Scrap Support
    if _G['Scrap'] then
        if _G['Scrap']:IsJunk(frame.item.id) then
            frame.icon.scrap:Show()
        else
            frame.icon.scrap:Hide()
        end
    end

    if frame.item.isNew == true then
        frame.itemButton.NewTexture:Show()
    else
        frame.itemButton.NewTexture:Hide()
    end
end

-- TODO: SetSize will eventually need to be set based on the View
function itemFrame:CreateItemFramePlaceholder()
    local f = CreateFrame('Frame', nil, UIParent) -- Taint Killer
    f:SetSize(600-24, session.Settings.Defaults.Sections.ListItemHeight)

    local itemButton = CreateFrame('ItemButton', nil, f, 'ContainerFrameItemButtonTemplate')
    itemButton:SetAllPoints(f)
    itemButton:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

    itemButton.NormalTexture:Hide()
    itemButton.NormalTexture:SetParent(nil)
    itemButton.NormalTexture = nil
    itemButton.PushedTexture:Hide()
    itemButton.PushedTexture:SetParent(nil)
    itemButton.PushedTexture = nil
    itemButton.NewItemTexture:Hide()
    itemButton.BattlepayItemTexture:Hide()
    itemButton:GetHighlightTexture():Hide()
    itemButton:GetHighlightTexture():SetParent(nil)
    itemButton.HighlightTexture = nil

    local undermark = itemButton:CreateTexture()
    undermark:SetDrawLayer('BACKGROUND')
    undermark:SetBlendMode('ADD')
    undermark:SetPoint('TOPLEFT', itemButton, 'BOTTOMLEFT', 0, 1)
    undermark:SetPoint('BOTTOMRIGHT', itemButton, 'BOTTOMRIGHT')
    undermark:SetColorTexture(1, 1, 1, 0.2)

    local highlight = itemButton:CreateTexture()
    highlight:SetDrawLayer('BACKGROUND')
    highlight:SetBlendMode('ADD')
    highlight:SetAllPoints()
    highlight:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight')
    highlight:Hide()
    itemButton.HighlightTexture = highlight

    local new = itemButton:CreateTexture()
    new:SetDrawLayer('BACKGROUND')
    new:SetBlendMode('ADD')
    new:SetAllPoints()
    new:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight')
    new:SetVertexColor(1, 1, 0, 1)
    new:Hide()
    itemButton.NewTexture = new

    f.itemButton = itemButton

    -- Icon
    local iconSpace = CreateFrame('Frame', nil, f)
    iconSpace:SetPoint('LEFT', f, 'LEFT', 4, 0)
    iconSpace:SetSize(session.Settings.Defaults.Columns.Icon, session.Settings.Defaults.Sections.ListItemHeight)
    local icon = CreateFrame('Frame', nil, iconSpace)
    icon:SetPoint('CENTER', iconSpace, 'CENTER')
    icon:SetSize(32, 32)
    local iconTexture = CreateFrame('ItemButton', nil, icon, 'ContainerFrameItemButtonTemplate')
    iconTexture:SetAllPoints(icon)

    iconTexture.frame = icon

    local upgradeIcon = iconTexture:CreateTexture(nil, 'ARTWORK')
    upgradeIcon:SetPoint('TOPLEFT', iconTexture, 'TOPLEFT', 2, -2)
    upgradeIcon:SetSize(12, 12)
    upgradeIcon:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Upgrade')
    upgradeIcon:Hide()

    iconTexture.upgrade = upgradeIcon

    local canIFrame = CreateFrame('Frame', nil, iconTexture)
    canIFrame:SetPoint('TOPRIGHT', iconTexture, 'TOPRIGHT', -2, -2)
    canIFrame:SetSize(14, 14)
    canIFrame.tex = canIFrame:CreateTexture(nil, 'BACKGROUND')
    canIFrame.tex:SetAllPoints(canIFrame)
    canIFrame.tex:SetColorTexture(0, 0, 0, 1)

    local canIMogIt = canIFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalTiny')
    canIMogIt:SetAllPoints(canIFrame)
    canIMogIt:SetJustifyH('RIGHT')

    canIFrame:Hide()

    canIFrame.text = canIMogIt
    iconTexture.canI = canIFrame
    
    local scrapFrame = CreateFrame('Frame', nil, iconTexture)
    scrapFrame:SetPoint('BOTTOMRIGHT', iconTexture, 'BOTTOMRIGHT', -2, -1)
    scrapFrame:SetSize(14, 14)
    scrapFrame.tex = scrapFrame:CreateTexture(nil, 'BACKGROUND')
    scrapFrame.tex:SetAllPoints(scrapFrame)
    scrapFrame.tex:SetColorTexture(0, 0, 0, 1)
    scrapFrame.tex:SetTexture('Interface\\Buttons\\UI-GroupLoot-Coin-Up')

    scrapFrame:Hide()
    iconTexture.scrap = scrapFrame

    f.icon = iconTexture

    -- Name
    local name = CreateFrame('Frame', nil, f)
    name:SetPoint('LEFT', iconSpace, 'RIGHT', 8, 0)
    name:SetHeight(session.Settings.Defaults.Sections.ListItemHeight)
    name:SetWidth(session.Settings.Defaults.Columns.Name)
    local nameText = name:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    nameText:SetAllPoints(name)
    nameText:SetJustifyH('LEFT')

    f.name = nameText

    -- type
    -- local type = CreateFrame('Frame', nil, f)
    -- type:SetPoint('LEFT', name, 'RIGHT')
    -- type:SetHeight(CB.Settings.Defaults.Sections.ListItemHeight)
    -- type:SetWidth(CB.Settings.Defaults.Columns.Category)

    -- local typeTex = type:CreateTexture(nil, 'ARTWORK')
    -- typeTex:SetPoint('CENTER', type, 'CENTER')
    -- typeTex:SetSize(24, 24)

    -- f.type = typeTex

    -- ilvl
    local ilvl = CreateFrame('Frame', nil, f)
    ilvl:SetPoint('LEFT', name, 'RIGHT')
    ilvl:SetHeight(session.Settings.Defaults.Sections.ListItemHeight)
    ilvl:SetWidth(session.Settings.Defaults.Columns.Ilvl)
    local ilvlText = ilvl:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    ilvlText:SetAllPoints(ilvl)
    ilvlText:SetJustifyH('CENTER')

    f.ilvl = ilvlText

    -- reqlvl
    local reqlvl = CreateFrame('Frame', nil, f)
    reqlvl:SetPoint('LEFT', ilvl, 'RIGHT')
    reqlvl:SetHeight(session.Settings.Defaults.Sections.ListItemHeight)
    reqlvl:SetWidth(session.Settings.Defaults.Columns.ReqLvl)
    local reqlvlText = reqlvl:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    reqlvlText:SetAllPoints(reqlvl)
    reqlvlText:SetJustifyH('CENTER')

    f.reqlvl = reqlvlText

    -- value
    local value = CreateFrame('Frame', nil, f)
    value:SetPoint('LEFT', reqlvl, 'RIGHT')
    value:SetHeight(session.Settings.Defaults.Sections.ListItemHeight)
    value:SetWidth(session.Settings.Defaults.Columns.Value)
    local valueText = value:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    valueText:SetAllPoints(value)
    valueText:SetJustifyH('RIGHT')

    f.value = valueText

    f.isItem = true

    f:Hide()

    return f
end

function itemFrame:Refresh(itemId)
    if not session.FramesByItemId[itemId] then
        return
    end
    for _, frame in pairs(session.FramesByItemId[itemId]) do
        itemFrame:Update(frame)
    end
end

itemFrame:Enable()