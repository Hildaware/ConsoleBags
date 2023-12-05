local _, Bagger = ...

function Bagger.G.CreateBagContainer()
    local f = CreateFrame("Frame", nil, Bagger.View.Header)
    f:SetSize(140, 32)
    f:SetPoint("RIGHT", Bagger.View.Header, "RIGHT", -40, 0)

    -- Bag Button
    local bagButton = CreateFrame("Button", nil, f)
    bagButton:SetPoint("RIGHT", 0, "RIGHT")
    bagButton:SetSize(24, 24)

    local btnTex = bagButton:CreateTexture(nil, "ARTWORK")
    btnTex:SetAllPoints(bagButton)
    btnTex:SetTexture(133633)

    bagButton:SetScript("OnClick", function(self)
        if self:GetParent().BagsContainer:IsShown() then
            self:GetParent().BagsContainer:Hide()
            self:GetParent().ItemCountContainer:Show()
        else
            self:GetParent().BagsContainer:Show()
            self:GetParent().ItemCountContainer:Hide()
        end
    end)

    local bagsContainer = CreateFrame("Frame", nil, f)
    bagsContainer:SetPoint("RIGHT", bagButton, "LEFT", -4, 0)
    bagsContainer:SetSize(120, 24)

    for bag = 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local bagID = C_Container.ContainerIDToInventoryID(bag)
        local iconID = GetInventoryItemTexture("player", bagID)
        CreateBagSlot(bagsContainer, bag, iconID)
    end

    bagsContainer:Hide()

    f.BagsContainer = bagsContainer

    local itemCountContainer = CreateFrame("Frame", nil, f)
    itemCountContainer:SetPoint("RIGHT", bagButton, "LEFT", -4, 0)
    itemCountContainer:SetSize(120, 24)

    local itemCountText = itemCountContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    itemCountText:SetAllPoints(itemCountContainer)
    itemCountText:SetText("")
    itemCountText:SetJustifyH("RIGHT")

    f.ItemCountContainer = itemCountContainer

    Bagger.View.ItemCountText = itemCountText
end

function CreateBagSlot(parent, index, icon)
    local f = CreateFrame("Button", nil, parent)
    f:SetPoint("RIGHT", parent, "LEFT", (index * 24), 0)
    f:SetSize(20, 20)

    local btnTex = f:CreateTexture(nil, "ARTWORK")
    btnTex:SetAllPoints(f)

    if icon then
        btnTex:SetTexture(icon)
    else
        btnTex:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
    end
end
