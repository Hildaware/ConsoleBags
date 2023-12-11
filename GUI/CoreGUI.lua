local _, CB = ...

CB.G = {}
CB.G.U = {}

local LIST_ITEM_HEIGHT = 32

function CB.G.UpdateCurrency()
    if CB.View and CB.View.Header then
        CB.View.Header.Gold:SetText(GetCoinTextureString(GetMoney()))
    end
end

-- Filtering
function CB.G.BuildFilteringContainer(parent, type)
    local cFrame = CreateFrame("Frame", nil, parent)
    cFrame:SetSize(32, parent:GetHeight() - 32)
    cFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -32)

    local tex = cFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(cFrame)
    tex:SetColorTexture(0, 0, 0, 0.25)

    cFrame.Buttons = {}
    cFrame.SelectedIndex = 1

    -- All
    local f = CreateFrame("Button", nil, cFrame)
    f:SetSize(28, 28)
    f:SetPoint("TOP", cFrame, "TOP", 0, -32)

    f:SetHighlightTexture("Interface\\Addons\\ConsoleBags\\Media\\Rounded_BG")
    f:SetPushedTexture("Interface\\Addons\\ConsoleBags\\Media\\Rounded_BG")
    f:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.25)
    f:GetPushedTexture():SetVertexColor(1, 1, 1, 0.25)

    local aTex = f:CreateTexture(nil, "OVERLAY")
    aTex:SetPoint("CENTER", 0, "CENTER")
    aTex:SetSize(24, 24)
    aTex:SetTexture(CB.U.GetCategoyIcon(1))

    f:SetScript("OnClick", function(self)
        Filter_OnClick(f, type, nil, 1)
    end)
    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")
    f.OnSelect = function() Filter_OnClick(f, type, nil, 1) end

    cFrame.Buttons[1] = f

    -- IsSelected
    local selectedTex = cFrame:CreateTexture(nil, "ARTWORK")
    selectedTex:SetPoint("TOP", cFrame, "TOP", 0, -32)
    selectedTex:SetSize(28, 28)
    selectedTex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Rounded_BG")
    selectedTex:SetVertexColor(1, 1, 0, 0.25)

    cFrame.selectedTexture = selectedTex
    parent.FilterFrame = cFrame
end

function CB.G.CreateFilterButtonPlaceholder()
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

function CB.G.UpdateFilterButtons(type, pool)
    local cats = nil
    if type == CB.E.InventoryType.Inventory then
        cats = CB.Session.Categories
    elseif type == CB.E.InventoryType.Bank then
        cats = CB.Session.Bank.Categories
    end

    if cats == nil then return end

    -- Filter Categories
    local foundCategories = {}
    for _, value in pairs(cats) do
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
        local frame = Pool.FetchInactive(pool, filterOffset, CB.G.CreateFilterButtonPlaceholder)
        Pool.InsertActive(pool, frame, filterOffset)
        BuildFilterButton(frame, type, categoryData, filterOffset)
        CB.View.FilterFrame.Buttons[filterOffset] = frame -- Add the button to the index
        filterOffset = filterOffset + 1
    end
end

function BuildFilterButton(f, type, categoryData, index)
    if f == nil then return end

    local parent = nil
    if type == CB.E.InventoryType.Inventory then
        parent = CB.View
    elseif type == CB.E.InventoryType.Bank then
        parent = CB.BankView
    end

    if parent == nil then return end


    f:SetParent(parent.FilterFrame)
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

    f.OnSelect = function() Filter_OnClick(f, type, categoryData.key, index) end

    f:SetScript("OnClick", function(self)
        Filter_OnClick(f, type, categoryData.key, index)
    end)

    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText(categoryData.name .. " (" .. categoryData.count .. ")", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    f:Show()

    return f
end

-- temp
function Filter_OnClick(self, type, categoryKey, index)
    self:GetParent().selectedTexture:SetPoint("TOP", 0, -(index * (LIST_ITEM_HEIGHT + 4)))

    if type == CB.E.InventoryType.Inventory then
        CB.Session.Filter = categoryKey
        CB.GatherItems()
        CB.G.UpdateInventory()
        CB.G.UpdateBagContainer()
    elseif type == CB.E.InventoryType.Bank then
        CB.Session.Bank.Filter = categoryKey
        CB.GatherBankItems()
        CB.G.UpdateBank()
    end
end

-- Sorting
function CB.G.BuildSortingContainer(parent, type)
    local hFrame = CreateFrame("Frame", nil, parent)
    hFrame:SetSize(parent:GetWidth() - 32, 32)
    hFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 32, -32)

    hFrame.fields = {}

    local tex = hFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(hFrame)
    tex:SetColorTexture(0, 0, 0, 0.25)

    local icon = BuildSortButton(hFrame, hFrame, "•", CB.Settings.Defaults.Columns.Icon,
        CB.E.SortFields.Icon, true, type)

    local name = BuildSortButton(hFrame, icon, "NAME", CB.Settings.Defaults.Columns.Name,
        CB.E.SortFields.Name, false, type)

    local category = BuildSortButton(hFrame, name, "CAT", CB.Settings.Defaults.Columns.Category,
        CB.E.SortFields.Category, false, type)

    local ilvl = BuildSortButton(hFrame, category, "ILVL", CB.Settings.Defaults.Columns.Ilvl,
        CB.E.SortFields.Ilvl, false, type)

    local reqlvl = BuildSortButton(hFrame, ilvl, "REQ", CB.Settings.Defaults.Columns.ReqLvl,
        CB.E.SortFields.ReqLvl, false, type)

    local value = BuildSortButton(hFrame, reqlvl, "VALUE", CB.Settings.Defaults.Columns.Value,
        CB.E.SortFields.Value, false, type)
end

function BuildSortButton(parent, anchor, name, width, sortField, initial, type)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(width, parent:GetHeight())
    frame:SetPoint("LEFT", anchor, initial and "LEFT" or "RIGHT", initial and 10 or 0, 0)

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("CENTER", frame, "CENTER")
    text:SetJustifyH("CENTER")
    text:SetText(name)
    text:SetTextColor(1, 1, 1)

    local arrow = frame:CreateTexture("ARTWORK")
    arrow:SetPoint("LEFT", text, "RIGHT", 2, 0)
    arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Up")
    arrow:SetSize(8, 14)

    local sortData
    if type == CB.E.InventoryType.Inventory then
        sortData = CBData.View.SortField
    elseif type == CB.E.InventoryType.Bank then
        sortData = CBData.BankView.SortField
    end

    if sortData.Sort == CB.E.SortOrder.Desc then
        arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Up")
    else
        arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Down")
    end

    if sortData.Field ~= sortField then
        arrow:Hide()
    end

    frame:SetScript("OnClick", function()
        local sortOrder = sortData.Sort
        if sortData.Field == sortField then
            if sortOrder == CB.E.SortOrder.Asc then
                sortOrder = CB.E.SortOrder.Desc
            else
                sortOrder = CB.E.SortOrder.Asc
            end
        end

        sortData.Field = sortField
        sortData.Sort = sortOrder

        if sortData.Sort ~= CB.E.SortOrder.Desc then
            arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Up")
        else
            arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Down")
        end

        arrow:Show()
        text:SetTextColor(1, 1, 0)

        -- Remove other arrows
        for _, k in pairs(CB.E.SortFields) do
            if k ~= sortField then
                parent.fields[k].arrow:Hide()
                parent.fields[k].text:SetTextColor(1, 1, 1)
            end
        end

        if type == CB.E.InventoryType.Inventory then
            CB.G.UpdateInventory()
            CB.G.UpdateBagContainer()
        elseif type == CB.E.InventoryType.Bank then
            CB.G.UpdateBank()
        end
    end)

    parent.fields[sortField] = frame
    frame.arrow = arrow
    frame.text = text

    return frame
end

-- Utils
function CB.G.U.CreateBorder(self)
    if not self.borders then
        self.borders = {}
        for i = 1, 4 do
            self.borders[i] = self:CreateLine(nil, "BACKGROUND", nil, 0)
            local l = self.borders[i]
            l:SetThickness(1)
            l:SetColorTexture(0, 0, 0, 1)
            if i == 1 then
                l:SetStartPoint("TOPLEFT")
                l:SetEndPoint("TOPRIGHT")
            elseif i == 2 then
                l:SetStartPoint("TOPRIGHT")
                l:SetEndPoint("BOTTOMRIGHT")
            elseif i == 3 then
                l:SetStartPoint("BOTTOMRIGHT")
                l:SetEndPoint("BOTTOMLEFT")
            else
                l:SetStartPoint("BOTTOMLEFT")
                l:SetEndPoint("TOPLEFT")
            end
        end
    end
end
