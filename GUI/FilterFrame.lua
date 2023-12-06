local _, Bagger = ...

local LIST_ITEM_HEIGHT = 32
local InactiveFilterFrames = {}
local ActiveFilterFrames = {}

function Bagger.G.UpdateFilterButtons()
    CleanupFilterFrames()
    local cats = Bagger.U.CopyTable(Bagger.E.Categories)

    for _, item in ipairs(Bagger.Session.Items) do
        local iCategory = item.type

        if item.quality and item.quality == Enum.ItemQuality.Heirloom then -- BoA
            cats[Bagger.E.CustomCategory.BindOnAccount].show = true
        elseif Bagger.U.IsEquipmentUnbound(item) then                      -- BoE
            cats[Bagger.E.CustomCategory.BindOnEquip].show = true
        elseif Bagger.U.IsJewelry(item) then                               -- Jewelry
            cats[Bagger.E.CustomCategory.Jewelry].show = true
        elseif Bagger.U.IsTrinket(item) then                               -- Trinkets
            cats[Bagger.E.CustomCategory.Trinket].show = true
        elseif iCategory ~= nil then
            cats[iCategory].show = true
        else
            cats[Enum.ItemClass.Miscellaneous].show = true
        end
    end

    local foundCategories = {}
    for key, value in pairs(cats) do
        if value.show == true then
            local data = value
            data.key = key
            tinsert(foundCategories, data)
        end
    end

    table.sort(foundCategories, function(a, b) return a.order < b.order end)


    local orderedCategories = {}
    for i = 1, #foundCategories do
        orderedCategories[i] = foundCategories[i]
    end

    local filterOffset = 2
    for _, categoryData in ipairs(orderedCategories) do
        BuildFilterButton(categoryData.key, filterOffset)
        filterOffset = filterOffset + 1
    end
end

function CleanupFilterFrames()
    for i = 1, #ActiveFilterFrames do
        ActiveFilterFrames[i]:Hide()
        ActiveFilterFrames[i].texture:SetTexture(nil)
        ActiveFilterFrames[i]:SetParent(nil)
        InsertInactiveFilterFrame(ActiveFilterFrames[i])
        ActiveFilterFrames[i] = nil
    end
end

function CreateFilterButtonPlaceholder()
    local f = CreateFrame("Button")
    f:SetSize(28, 28)

    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetPoint("CENTER", 0, "CENTER")
    tex:SetSize(24, 24)

    f.texture = tex
    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")

    return f
end

function BuildFilterButton(categoryType, index)
    local f = FetchInactiveFilterFrame()
    InsertActiveFilterFrame(f)

    f:SetParent(Bagger.View.FilterFrame)
    f:SetPoint("TOP", 0, -(index * (LIST_ITEM_HEIGHT + 4)))

    f:SetHighlightTexture("Interface\\Addons\\Bagger\\Media\\Rounded_BG")
    f:SetPushedTexture("Interface\\Addons\\Bagger\\Media\\Rounded_BG")
    f:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.25)
    f:GetPushedTexture():SetVertexColor(1, 1, 1, 0.25)

    f.texture:SetTexture(Bagger.U.GetCategoyIcon(categoryType))

    f:Show()

    f:SetScript("OnClick", function(self)
        Bagger.Settings.Filter = categoryType
        Bagger.G.UpdateView()
        self:GetParent().selectedTexture:SetPoint("TOP", 0, -(index * (LIST_ITEM_HEIGHT + 4)))
    end)
    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")
end

function RemoveActiveFilterFrame(index)
    ActiveFilterFrames[index] = nil
end

function InsertActiveFilterFrame(frame)
    tinsert(ActiveFilterFrames, frame)
end

function InsertInactiveFilterFrame(frame)
    tinsert(InactiveFilterFrames, frame)
end

function FetchInactiveFilterFrame()
    local frame = nil
    if InactiveFilterFrames[1] then
        frame = InactiveFilterFrames[1]
        tremove(InactiveFilterFrames, 1)
    else
        frame = CreateFilterButtonPlaceholder()
    end
    return frame
end
