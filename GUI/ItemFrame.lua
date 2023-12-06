local _, Bagger = ...

local LIST_ITEM_HEIGHT = 32

local InactiveItemFrames = {}
local ActiveItemFrames = {}

function Bagger.G.CleanupItemFrames()
    for i = 1, #ActiveItemFrames do
        if ActiveItemFrames[i] and ActiveItemFrames[i].isItem then
            ActiveItemFrames[i]:SetParent(nil)
            ActiveItemFrames[i]:Hide()
            InsertInactiveItemFrame(ActiveItemFrames[i], i)
            RemoveActiveItemFrame(i)
        end
    end
end

function Bagger.G.BuildItemFrame(item, offset, index)
    local frame = FetchInactiveItemFrame(index)
    InsertActiveItemFrame(frame, index)

    if frame == nil then return end

    frame:SetParent(Bagger.View.ListView)
    frame:SetPoint("TOP", 0, -((offset - 1) * LIST_ITEM_HEIGHT))

    local r, g, b, _ = GetItemQualityColor(item.quality or 0)
    frame:SetHighlightTexture("Interface\\Addons\\Bagger\\Media\\Item_Highlight")
    frame:SetPushedTexture("Interface\\Addons\\Bagger\\Media\\Item_Highlight")
    frame:GetHighlightTexture():SetVertexColor(r, g, b, 1)

    if item.isNew == true then
        frame:SetNormalTexture("Interface\\Addons\\Bagger\\Media\\Item_Highlight")
        frame:GetNormalTexture():SetVertexColor(1, 1, 0, 1)
    else
        frame:SetNormalTexture("")
        frame:GetNormalTexture():SetVertexColor(0, 0, 0, 0)
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

    frame.type:SetTexture(Bagger.U.GetCategoyIcon(item.type))

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

    frame:SetScript("OnEnter", function(self)
        -- This is pretty jank, but it fixes a specific issue with ConsolePort
        self.GetBagID = function() return item.bag end
        self.GetID = function() return item.slot end
        self.GetSlotAndBagID = ContainerFrameItemButtonMixin.GetSlotAndBagID

        if item.isNew == true then
            C_NewItems.RemoveNewItem(item.bag, item.slot)
        end

        frame:SetNormalTexture("")
        frame:GetNormalTexture():SetVertexColor(0, 0, 0, 0)

        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetBagItem(item.bag, item.slot)
        GameTooltip:Show()
    end)

    frame:SetScript("OnClick", function(self, button, down)
        if button == "LeftButton" then
            C_Container.PickupContainerItem(item.bag, item.slot)
        else
            C_Container.UseContainerItem(item.bag, item.slot)
        end
    end)
    frame:SetScript("OnDragStart", function(self)
        C_Container.PickupContainerItem(item.bag, item.slot)
    end)

    frame.index = offset

    frame:Show()
end

function CreateItemFramePlaceholder()
    local f = CreateFrame("Button")
    f:SetSize(Bagger.View.ListView:GetWidth(), LIST_ITEM_HEIGHT)

    f:RegisterForClicks("LeftButtonUp")
    f:RegisterForClicks("RightButtonUp")
    f:RegisterForDrag("LeftButton")

    f:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Icon
    local icon = CreateFrame("Frame", nil, f)
    icon:SetPoint("LEFT", f, "LEFT")
    icon:SetSize(Bagger.Settings.Defaults.Columns.Icon, LIST_ITEM_HEIGHT)
    local iconTexture = icon:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(24, 24)
    iconTexture:SetPoint("CENTER", icon, "CENTER")

    f.icon = iconTexture

    -- Name
    local name = CreateFrame("Frame", nil, f)
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetHeight(LIST_ITEM_HEIGHT)
    name:SetWidth(Bagger.Settings.Defaults.Columns.Name)
    local nameText = name:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameText:SetAllPoints(name)
    nameText:SetJustifyH("LEFT")

    f.name = nameText

    -- type
    local type = CreateFrame("Frame", nil, f)
    type:SetPoint("LEFT", name, "RIGHT")
    type:SetHeight(LIST_ITEM_HEIGHT)
    type:SetWidth(Bagger.Settings.Defaults.Columns.Category)

    local typeTex = type:CreateTexture(nil, "ARTWORK")
    typeTex:SetPoint("CENTER", type, "CENTER")
    typeTex:SetSize(24, 24)

    f.type = typeTex

    -- ilvl
    local ilvl = CreateFrame("Frame", nil, f)
    ilvl:SetPoint("LEFT", type, "RIGHT")
    ilvl:SetHeight(LIST_ITEM_HEIGHT)
    ilvl:SetWidth(Bagger.Settings.Defaults.Columns.Ilvl)
    local ilvlText = ilvl:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ilvlText:SetAllPoints(ilvl)
    ilvlText:SetJustifyH("CENTER")

    f.ilvl = ilvlText

    -- reqlvl
    local reqlvl = CreateFrame("Frame", nil, f)
    reqlvl:SetPoint("LEFT", ilvl, "RIGHT")
    reqlvl:SetHeight(LIST_ITEM_HEIGHT)
    reqlvl:SetWidth(Bagger.Settings.Defaults.Columns.ReqLvl)
    local reqlvlText = reqlvl:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    reqlvlText:SetAllPoints(reqlvl)
    reqlvlText:SetJustifyH("CENTER")

    f.reqlvl = reqlvlText

    -- value
    local value = CreateFrame("Frame", nil, f)
    value:SetPoint("LEFT", reqlvl, "RIGHT")
    value:SetHeight(LIST_ITEM_HEIGHT)
    value:SetWidth(Bagger.Settings.Defaults.Columns.Value)
    local valueText = value:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valueText:SetAllPoints(value)
    valueText:SetJustifyH("RIGHT")

    f.value = valueText

    f.isItem = true

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

function FetchInactiveItemFrame(index)
    local frame = nil
    if InactiveItemFrames[index] then
        frame = InactiveItemFrames[index]
        InactiveItemFrames[index] = nil
    else
        frame = CreateItemFramePlaceholder()
    end
    return frame
end
