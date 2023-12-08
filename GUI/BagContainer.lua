local _, CB = ...

function CB.G.UpdateBagContainer()
    local max = 0
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local maxSlots = C_Container.GetContainerNumSlots(bag)
        max = max + maxSlots
    end

    if CB.View ~= nil then
        CB.View.ItemCountText:SetText(#CB.Session.Items .. "/" .. max)
    end

    UpdateBags()
end

function CB.G.CreateBagContainer()
    local f = CreateFrame("Frame", nil, CB.View.Header)
    f:SetSize(140, 32)
    f:SetPoint("RIGHT", CB.View.Header, "RIGHT", -40, 0)

    -- Bag Button
    local bagButton = CreateFrame("Button", nil, f)
    bagButton:SetPoint("RIGHT", 0, "RIGHT")
    bagButton:SetSize(24, 24)

    local btnTex = bagButton:CreateTexture(nil, "ARTWORK")
    btnTex:SetAllPoints(bagButton)
    btnTex:SetTexture(133633)

    bagButton:SetScript("OnClick", function(self)
        if CB.View.BagContainer.Bags:IsShown() then
            CB.View.BagContainer.Bags:Hide()
            self:GetParent().ItemCountContainer:Show()
        else
            CB.View.BagContainer.Bags:Show()
            self:GetParent().ItemCountContainer:Hide()
        end
    end)

    CreateBagContainer(f, bagButton)

    local itemCountContainer = CreateFrame("Frame", nil, f)
    itemCountContainer:SetPoint("RIGHT", bagButton, "LEFT", -4, 0)
    itemCountContainer:SetSize(120, 24)

    local itemCountText = itemCountContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    itemCountText:SetAllPoints(itemCountContainer)
    itemCountText:SetText("")
    itemCountText:SetJustifyH("RIGHT")

    f.ItemCountContainer = itemCountContainer

    CB.View.BagContainer = f
    CB.View.ItemCountText = itemCountText
end

function CreateBagContainer(parent, anchor)
    local bagsContainer = CreateFrame("Frame", nil, parent)
    bagsContainer:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
    bagsContainer:SetSize(120, 24)

    bagsContainer.Containers = {}

    for bag = 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local bagID = C_Container.ContainerIDToInventoryID(bag)
        local iconID = GetInventoryItemTexture("player", bagID)
        local link = GetInventoryItemLink("player", bag)

        local bagData = {
            bagIndex = bag,
            id = bagID,
            icon = iconID,
            link = link
        }
        local f = CreateBagSlot(bagsContainer, bagData)
        bagsContainer.Containers[bag] = f
    end

    parent.Bags = bagsContainer
    bagsContainer:Hide()
end

function UpdateBags()
    if CB.View == nil then return end

    for bag = 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local bagID = C_Container.ContainerIDToInventoryID(bag)
        local iconID = GetInventoryItemTexture("player", bagID)
        local link = GetInventoryItemLink("player", bag)

        local bagData = {
            bagIndex = bag,
            id = bagID,
            icon = iconID,
            link = link
        }
        local frame = CB.View.BagContainer.Bags.Containers[bag]
        if frame ~= nil then
            frame.bagID = bagData.id
            frame:SetID(bagData.id)

            if bagData.icon ~= nil then
                frame.texture:SetTexture(bagData.icon)
            else
                frame.texture:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
            end

            frame:SetScript("OnClick", function(self, button, down)
                if button == "LeftButton" then
                    PickupInventoryItem(self.bagID)
                end
            end)

            frame:SetScript("OnDragStart", function(self)
                PickupInventoryItem(self.bagID)
            end)

            frame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_NONE")
                ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip)
                GameTooltip:SetInventoryItem("player", self.bagID)
                GameTooltip:Show()
            end)

            frame:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end
    end
end

function CreateBagSlot(parent, bagData)
    local f = CreateFrame("Button", nil, parent)
    f:SetPoint("RIGHT", parent, "LEFT", (bagData.bagIndex * 24), 0)
    f:SetSize(20, 20)

    f.bagID = bagData.id

    f:SetID(bagData.id)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    f:RegisterForDrag("LeftButton")

    local btnTex = f:CreateTexture(nil, "ARTWORK")
    btnTex:SetAllPoints(f)

    if bagData.icon ~= nil then
        btnTex:SetTexture(bagData.icon)
    else
        btnTex:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
    end

    f.texture = btnTex

    f:SetScript("OnClick", function(self, button, down)
        if button == "LeftButton" then
            PickupInventoryItem(self.bagID)
        end
    end)

    f:SetScript("OnDragStart", function(self)
        PickupInventoryItem(self.bagID)
    end)

    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip)
        GameTooltip:SetInventoryItem("player", self.bagID)
        GameTooltip:Show()
    end)

    f:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return f
end
