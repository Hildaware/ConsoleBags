local _, CB = ...

function CB.G.CreateBags(type, parent)
    local f = CreateFrame("Frame", nil, parent.Header)
    f:SetSize(32, 32)
    f:SetPoint("RIGHT", parent.Header, "RIGHT", -40, 0)

    -- Bag Button
    local bagButton = CreateFrame("Button", nil, f)
    bagButton:SetPoint("RIGHT", 0, "RIGHT")
    bagButton:SetSize(30, 30)

    local btnTex = bagButton:CreateTexture(nil, "ARTWORK")
    btnTex:SetAllPoints(bagButton)
    btnTex:SetTexture(133633) -- Generic Bag

    CreateBagContainerG(bagButton, type)

    bagButton:SetScript("OnClick", function(self)
        if self.Container:IsShown() then
            self.Container:Hide()
            self:GetParent().ItemCountContainer:Show()
        else
            self.Container:Show()
            self:GetParent().ItemCountContainer:Hide()
        end
    end)

    local itemCountContainer = CreateFrame("Frame", nil, f)
    itemCountContainer:SetPoint("RIGHT", bagButton, "LEFT", -4, 0)
    itemCountContainer:SetSize(120, 24)

    local itemCountText = itemCountContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    itemCountText:SetAllPoints(itemCountContainer)
    itemCountText:SetText("")
    itemCountText:SetJustifyH("RIGHT")

    f.ItemCountContainer = itemCountContainer

    parent.Bags = bagButton
    parent.ItemCountText = itemCountText
end

function CB.G.UpdateBags(container, type)
    if container == nil then return end

    local bagStart = 1
    local bagEnd = NUM_TOTAL_EQUIPPED_BAG_SLOTS
    if type == CB.E.InventoryType.Bank then
        local _, full = GetNumBankSlots()
        if full then
            container.purchase:Hide()
        end

        bagStart = ITEM_INVENTORY_BANK_BAG_OFFSET + 1
        bagEnd = NUM_BANKBAGSLOTS + NUM_BAG_SLOTS + 1
    end

    local max = type == CB.E.InventoryType.Bank and 28 or 0
    for bag = bagStart, bagEnd do
        local bagID = C_Container.ContainerIDToInventoryID(bag)
        local iconID = GetInventoryItemTexture("player", bagID)
        local link = GetInventoryItemLink("player", bag)
        local maxSlots = C_Container.GetContainerNumSlots(bag)
        max = max + maxSlots

        local bagIndex = bag
        if type == CB.E.InventoryType.Bank then
            bagIndex = bagIndex - ITEM_INVENTORY_BANK_BAG_OFFSET
        end

        local bagData = {
            bagIndex = bagIndex,
            id = bagID,
            icon = iconID,
            link = link
        }

        if type == CB.E.InventoryType.Bank then
            local numSlots, _ = GetNumBankSlots()
            bagData.isPurchased = bagIndex <= numSlots
        end

        container.Bags[bagIndex] = UpdateBagSlotG(container.Bags[bagIndex], bagData)
    end

    local itemCount = 0
    if type == CB.E.InventoryType.Inventory then
        itemCount = #CB.Session.Items
        CB.View.ItemCountText:SetText(itemCount .. "/" .. max)
    elseif type == CB.E.InventoryType.Bank then
        itemCount = #CB.Session.Bank.Items
        CB.BankView.ItemCountText:SetText(itemCount .. "/" .. max)
    end
end

function CreateBagContainerG(parent, type)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("RIGHT", parent, "LEFT", -4, 0)
    container:SetSize(1, parent:GetHeight())

    container.Bags = {}

    local bagStart = 1
    local bagEnd = NUM_TOTAL_EQUIPPED_BAG_SLOTS
    if type == CB.E.InventoryType.Bank then
        bagStart = ITEM_INVENTORY_BANK_BAG_OFFSET + 1
        bagEnd = NUM_BANKBAGSLOTS + NUM_BAG_SLOTS + 1
    end

    for bag = bagStart, bagEnd do
        local bagID = C_Container.ContainerIDToInventoryID(bag)
        local iconID = GetInventoryItemTexture("player", bagID)
        local link = GetInventoryItemLink("player", bag)

        local bagIndex = bag
        if type == CB.E.InventoryType.Bank then
            bagIndex = bagIndex - ITEM_INVENTORY_BANK_BAG_OFFSET
        end

        local bagData = {
            bagIndex = bagIndex,
            id = bagID,
            icon = iconID,
            link = link
        }

        if type == CB.E.InventoryType.Bank then
            local numSlots, _ = GetNumBankSlots()
            bagData.isPurchased = bagIndex <= numSlots
        end

        local f = CreateBagSlotG(container, bagData)
        container.Bags[bagIndex] = f
    end

    if type == CB.E.InventoryType.Bank then
        local purchaseBagButton = CreateFrame('Button', nil, container)
        purchaseBagButton:SetSize(28, 28)
        purchaseBagButton:SetPoint('LEFT', container.Bags[#container.Bags], 'RIGHT', 12, 0)
        purchaseBagButton:SetNormalTexture(133784)

        purchaseBagButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip)

            local num, _ = GetNumBankSlots()
            local cost = GetBankSlotCost(num)
            GameTooltip:SetText("Purchase Bag Slot: " .. GetCoinTextureString(cost))
            GameTooltip:Show()
        end)

        purchaseBagButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        purchaseBagButton:SetScript('OnClick', function()
            local _, fullBank = GetNumBankSlots()
            if not fullBank then
                PurchaseSlot()
            end
        end)

        container:SetWidth(container:GetWidth() + 40)

        container.purchase = purchaseBagButton
    end

    parent.Container = container
    container:Hide()
end

function CreateBagSlotG(parent, bagData)
    local f = CreateFrame("Button", nil, parent)
    f:SetPoint("RIGHT", parent, "LEFT", (bagData.bagIndex * 30), 0)
    f:SetSize(28, 28)

    f.bagID = bagData.id

    f:SetID(bagData.id)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    f:RegisterForDrag("LeftButton")

    local btnTex = f:CreateTexture(nil, "ARTWORK")
    btnTex:SetAllPoints(f)

    if bagData.icon ~= nil then
        btnTex:SetTexture(bagData.icon)
        btnTex:SetVertexColor(1, 1, 1, 1)
    else
        btnTex:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")

        if bagData.isPurchased ~= nil then
            if not bagData.isPurchased then
                btnTex:SetVertexColor(1, 0, 0, 1)
            else
                btnTex:SetVertexColor(1, 1, 1, 1)
            end
        end
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

    parent:SetWidth(parent:GetWidth() + 30)

    return f
end

function UpdateBagSlotG(self, bagData)
    if self == nil then return end

    self.bagID = bagData.id
    self:SetID(bagData.id)

    if bagData.icon ~= nil then
        self.texture:SetTexture(bagData.icon)
        self.texture:SetVertexColor(1, 1, 1, 1)
    else
        self.texture:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")

        if bagData.isPurchased ~= nil then
            if not bagData.isPurchased then
                self.texture:SetVertexColor(1, 0, 0, 1)
            else
                self.texture:SetVertexColor(1, 1, 1, 1)
            end
        end
    end

    return self
end
