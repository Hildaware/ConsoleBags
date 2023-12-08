local _, CB = ...

local LIST_ITEM_HEIGHT = 32
local InactiveFilterFrames = {}
local ActiveFilterFrames = {}

function CB.G.UpdateFilterButtons()
    if CB.Session.Categories == nil then return end

    CleanupFilterFrames()

    -- Filter Categories
    local foundCategories = {}
    for _, value in pairs(CB.Session.Categories) do
        if value.count > 0 then
            tinsert(foundCategories, value)
        end
    end

    -- Sort By Order
    table.sort(foundCategories, function(a, b) return a.order < b.order end)


    local orderedCategories = {}
    for i = 1, #foundCategories do
        orderedCategories[i] = foundCategories[i]
    end

    local filterOffset = 2
    for _, categoryData in ipairs(orderedCategories) do
        BuildFilterButton(categoryData, filterOffset)
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

    local newTex = f:CreateTexture(nil, "OVERLAY")
    newTex:SetPoint("TOPRIGHT", f, "TOPRIGHT")
    newTex:SetSize(10, 10)
    newTex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Exclamation")
    newTex:Hide()

    f.newTexture = newTex

    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return f
end

function BuildFilterButton(categoryData, index)
    if CB.View == nil then return end

    local f = FetchInactiveFilterFrame()
    InsertActiveFilterFrame(f)

    f:SetParent(CB.View.FilterFrame)
    f:SetPoint("TOP", 0, -(index * (LIST_ITEM_HEIGHT + 4)))

    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")

    f:SetHighlightTexture("Interface\\Addons\\ConsoleBags\\Media\\Rounded_BG")
    f:SetPushedTexture("Interface\\Addons\\ConsoleBags\\Media\\Rounded_BG")
    f:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.25)
    f:GetPushedTexture():SetVertexColor(1, 1, 1, 0.25)

    f.texture:SetTexture(CB.U.GetCategoyIcon(categoryData.key))

    if categoryData.hasNew == true then
        f.newTexture:Show()
    else
        f.newTexture:Hide()
    end

    f:SetScript("OnClick", function(self)
        self:GetParent().selectedTexture:SetPoint("TOP", 0, -(index * (LIST_ITEM_HEIGHT + 4)))

        CB.Settings.Filter = categoryData.key
        CB.GatherItems()
        CB.G.UpdateView()
        CB.G.UpdateFilterButtons()
        CB.G.UpdateBagContainer()
    end)

    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText(categoryData.name .. " (" .. categoryData.count .. ")", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    f:Show()
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
