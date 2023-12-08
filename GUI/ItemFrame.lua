local _, CB = ...

local LIST_ITEM_HEIGHT = 32

-- Because we're treating these indexed Pools this way,
-- I think they need to be split up between Inventory, Bank, etc.
-- TODO: Generic Pools
local InactiveItemFrames = {}
local ActiveItemFrames = {}

function CB.G.CleanupItemFrames(inventoryType)
    for i = 1, #ActiveItemFrames do
        if ActiveItemFrames[i] and ActiveItemFrames[i].inventory == inventoryType then
            ActiveItemFrames[i]:SetParent(nil)
            ActiveItemFrames[i]:Hide()
            InsertInactiveItemFrame(ActiveItemFrames[i], i)
            RemoveActiveItemFrame(i)
        end
    end
end

function CB.G.BuildItemFrame(item, offset, index, inventoryType)
    local frame = FetchInactiveItemFrame(index, inventoryType)

    InsertActiveItemFrame(frame, index)

    if frame == nil then return end

    local parent
    if inventoryType == CB.E.InventoryType.Inventory then
        parent = CB.View.ListView
    elseif inventoryType == CB.E.InventoryType.Bank then
        parent = CB.BankView.ListView
    end

    frame:SetParent(parent)
    frame:SetPoint("TOP", 0, -((offset - 1) * LIST_ITEM_HEIGHT))

    local tooltipOwner = GameTooltip:GetOwner()

    frame.itemButton:SetID(item.slot)
    frame:SetID(item.bag)

    ClearItemButtonOverlay(frame.itemButton)
    frame.itemButton:SetHasItem(item.texture)
    frame.itemButton:UpdateExtended()
    frame.itemButton:UpdateJunkItem(item.quality, item.hasNoValue)
    frame.itemButton:UpdateItemContextMatching()
    frame.itemButton:UpdateCooldown(item.texture)
    frame.itemButton:SetReadable(item.isReadable)
    frame.itemButton:CheckUpdateTooltip(tooltipOwner)
    frame.itemButton:SetMatchesSearch(not item.isFiltered)


    local r, g, b, _ = GetItemQualityColor(item.quality or 0)
    frame.itemButton.HighlightTexture:SetVertexColor(r, g, b, 1)

    if item.isNew == true then
        frame.itemButton.NewTexture:Show()
    else
        frame.itemButton.NewTexture:Hide()
    end

    frame.icon:SetTexture(item.texture)

    local stackString = (item.stackCount and item.stackCount > 1) and "(" .. item.stackCount .. ")" or nil
    local nameString = item.name
    if stackString then
        nameString = nameString .. " " .. stackString
    end
    frame.name:SetText(nameString)

    -- Color
    frame.name:SetTextColor(r, g, b)

    frame.type:SetTexture(CB.U.GetCategoyIcon(item.type))

    if item.type == Enum.ItemClass.Armor or item.type == Enum.ItemClass.Weapon then
        frame.ilvl:SetText(item.ilvl)
    else
        frame.ilvl:SetText("")
    end

    if item.reqLvl and item.reqLvl > 1 then
        frame.reqlvl:SetText(item.reqLvl)
    else
        frame.reqlvl:SetText("")
    end

    if item.value and item.value > 1 then
        frame.value:SetText(GetCoinTextureString(item.value))
    else
        frame.value:SetText("")
    end

    frame.index = offset


    frame:Show()
    frame.itemButton:Show()
end

-- TODO: SetSize will eventually need to be set based on the View
function CreateItemFramePlaceholder(type)
    local f = CreateFrame("Frame", nil, UIParent) -- Taint Killer
    f.inventory = type
    f:SetSize(CB.View.ListView:GetWidth(), LIST_ITEM_HEIGHT)

    local itemButton = CreateFrame("ItemButton", nil, f, "ContainerFrameItemButtonTemplate")
    itemButton:SetAllPoints(f)
    itemButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    itemButton:RegisterForClicks("RightButtonUp")

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

    local highlight = itemButton:CreateTexture()
    highlight:SetDrawLayer("BACKGROUND")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight")
    highlight:Hide()
    itemButton.HighlightTexture = highlight
    itemButton:HookScript("OnEnter", function(s)
        s.HighlightTexture:Show()
    end)
    itemButton:HookScript("OnLeave", function(s)
        s.HighlightTexture:Hide()
        s.NewTexture:Hide()
    end)

    local new = itemButton:CreateTexture()
    new:SetDrawLayer("BACKGROUND")
    new:SetBlendMode("ADD")
    new:SetAllPoints()
    new:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight")
    new:SetVertexColor(1, 1, 0, 1)
    new:Hide()
    itemButton.NewTexture = new

    f.itemButton = itemButton

    -- Icon
    local icon = CreateFrame("Frame", nil, f)
    icon:SetPoint("LEFT", f, "LEFT")
    icon:SetSize(CB.Settings.Defaults.Columns.Icon, LIST_ITEM_HEIGHT)
    local iconTexture = icon:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(24, 24)
    iconTexture:SetPoint("CENTER", icon, "CENTER")

    f.icon = iconTexture

    -- Name
    local name = CreateFrame("Frame", nil, f)
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetHeight(LIST_ITEM_HEIGHT)
    name:SetWidth(CB.Settings.Defaults.Columns.Name)
    local nameText = name:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameText:SetAllPoints(name)
    nameText:SetJustifyH("LEFT")

    f.name = nameText

    -- type
    local type = CreateFrame("Frame", nil, f)
    type:SetPoint("LEFT", name, "RIGHT")
    type:SetHeight(LIST_ITEM_HEIGHT)
    type:SetWidth(CB.Settings.Defaults.Columns.Category)

    local typeTex = type:CreateTexture(nil, "ARTWORK")
    typeTex:SetPoint("CENTER", type, "CENTER")
    typeTex:SetSize(24, 24)

    f.type = typeTex

    -- ilvl
    local ilvl = CreateFrame("Frame", nil, f)
    ilvl:SetPoint("LEFT", type, "RIGHT")
    ilvl:SetHeight(LIST_ITEM_HEIGHT)
    ilvl:SetWidth(CB.Settings.Defaults.Columns.Ilvl)
    local ilvlText = ilvl:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ilvlText:SetAllPoints(ilvl)
    ilvlText:SetJustifyH("CENTER")

    f.ilvl = ilvlText

    -- reqlvl
    local reqlvl = CreateFrame("Frame", nil, f)
    reqlvl:SetPoint("LEFT", ilvl, "RIGHT")
    reqlvl:SetHeight(LIST_ITEM_HEIGHT)
    reqlvl:SetWidth(CB.Settings.Defaults.Columns.ReqLvl)
    local reqlvlText = reqlvl:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    reqlvlText:SetAllPoints(reqlvl)
    reqlvlText:SetJustifyH("CENTER")

    f.reqlvl = reqlvlText

    -- value
    local value = CreateFrame("Frame", nil, f)
    value:SetPoint("LEFT", reqlvl, "RIGHT")
    value:SetHeight(LIST_ITEM_HEIGHT)
    value:SetWidth(CB.Settings.Defaults.Columns.Value)
    local valueText = value:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valueText:SetAllPoints(value)
    valueText:SetJustifyH("RIGHT")

    f.value = valueText

    f.isItem = true

    f:Hide()

    return f
end

function RemoveActiveItemFrame(index)
    ActiveItemFrames[index] = nil
end

function InsertActiveItemFrame(frame, index)
    -- tinsert(ActiveItemFrames, frame)
    ActiveItemFrames[index] = frame
end

function InsertInactiveItemFrame(frame, index)
    -- tinsert(InactiveItemFrames, frame)
    InactiveItemFrames[index] = frame
end

function FetchInactiveItemFrame(index, type)
    local frame = nil
    if InactiveItemFrames[index] and InactiveItemFrames[index].inventory == type then
        print("Fetching unused for " .. type)
        frame = InactiveItemFrames[index]
        InactiveItemFrames[index] = nil
    else
        frame = CreateItemFramePlaceholder(type)
    end
    return frame
end
