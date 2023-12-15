local _, CB = ...

CB.G = {}
CB.G.U = {}

function CB.G.UpdateCurrency()
    if CB.View and CB.View.Header then
        CB.View.Header.Gold:SetText(GetCoinTextureString(GetMoney()))
    end
end

-- Filtering
function CB.G.BuildFilteringContainer(parent, type)
    local cFrame = CreateFrame("Frame", nil, parent)
    cFrame:SetSize(parent:GetWidth(), CB.Settings.Defaults.Sections.Filters)
    cFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -CB.Settings.Defaults.Sections.Header)

    local tex = cFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(cFrame)
    tex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Underline")
    tex:SetVertexColor(1, 1, 1, 0.5)

    cFrame.Buttons = {}
    cFrame.SelectedIndex = 1

    -- All
    local f = CreateFrame("Button", nil, cFrame)
    f:SetSize(28, 28)
    f:SetPoint("LEFT", cFrame, "LEFT", 30, 0)

    local aTex = f:CreateTexture(nil, "OVERLAY")
    aTex:SetPoint("CENTER", 0, "CENTER")
    aTex:SetSize(24, 24)
    aTex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Logo_Normal")

    f:SetScript("OnEnter", function(self)
        local itemCount = 0
        if type == CB.E.InventoryType.Inventory then
            itemCount = CB.Session.InventoryCount
        elseif type == CB.E.InventoryType.Bank then
            itemCount = CB.Session.BankCount
        end

        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("All (" .. itemCount .. ")", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    f:SetScript("OnClick", function(self)
        Filter_OnClick(f, type, nil, 1)
    end)
    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")
    f.OnSelect = function() Filter_OnClick(f, type, nil, 1) end

    cFrame.Buttons[1] = f

    -- IsSelected
    local selectedTex = cFrame:CreateTexture(nil, "ARTWORK")
    selectedTex:SetPoint("BOTTOMLEFT", cFrame, "BOTTOMLEFT", 30, 3)
    selectedTex:SetSize(28, CB.Settings.Defaults.Sections.Filters - 6)
    selectedTex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Filter_Highlight")
    selectedTex:SetVertexColor(1, 1, 1, 0.5)

    -- LEFT / RIGHT Buttons
    if _G["ConsolePort"] and type == CB.E.InventoryType.Inventory then
        local lTexture = cFrame:CreateTexture(nil, "ARTWORK")
        lTexture:SetPoint("LEFT", cFrame, "LEFT", 6, 0)
        lTexture:SetSize(24, 24)
        lTexture:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\lb")

        local rTexture = cFrame:CreateTexture(nil, "ARTWORK")
        rTexture:SetPoint("RIGHT", cFrame, "RIGHT", -6, 0)
        rTexture:SetSize(24, 24)
        rTexture:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\rb")
    end

    cFrame.selectedTexture = selectedTex
    parent.FilterFrame = cFrame
end

function CB.G.UpdateFilterButtons(categories, type, pool)
    local view
    if type == CB.E.InventoryType.Inventory then
        view = CB.View
    elseif type == CB.E.InventoryType.Bank then
        view = CB.BankView
    end

    -- Cleanup
    for i = 2, #categories + 1 do
        view.FilterFrame.Buttons[i] = nil
    end

    local filterOffset = 2
    for _, categoryData in ipairs(categories) do
        local frame = Pool.FetchInactive(pool, filterOffset, CB.G.CreateFilterButtonPlaceholder)
        Pool.InsertActive(pool, frame, filterOffset)
        BuildFilterButton(frame, type, categoryData, filterOffset)
        view.FilterFrame.Buttons[filterOffset] = frame
        filterOffset = filterOffset + 1
    end
end

function CB.G.CreateFilterButtonPlaceholder()
    local f = CreateFrame("Button")
    f:SetSize(28, CB.Settings.Defaults.Sections.Filters)

    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("CENTER", 0, "CENTER")
    tex:SetSize(24, 24)

    f.texture = tex
    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")

    local newTex = f:CreateTexture(nil, "OVERLAY")
    newTex:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -4)
    newTex:SetSize(12, 12)
    newTex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Exclamation")
    newTex:Hide()

    f.newTexture = newTex

    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return f
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
    f:SetPoint("LEFT", index * 30, 0)

    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")

    f.texture:SetTexture(CB.U.GetCategoyIcon(categoryData.key))

    if categoryData.hasNew == true then
        f.newTexture:Show()
    else
        f.newTexture:Hide()
    end

    f.OnSelect = function() Filter_OnClick(f, type, categoryData.key, index) end

    f:SetScript("OnClick", function(self)
        Filter_OnClick(self, type, categoryData.key, index)
    end)

    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText(categoryData.name .. " (" .. categoryData.count .. ")", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    f:Show()

    return f
end

function Filter_OnClick(self, type, categoryKey, index)
    self:GetParent().selectedTexture:SetPoint("LEFT", (index * 30), 0)

    if type == CB.E.InventoryType.Inventory then
        CB.Session.InventoryFilter = categoryKey
        CB.G.UpdateInventory()
    elseif type == CB.E.InventoryType.Bank then
        CB.Session.BankFilter = categoryKey
        CB.G.UpdateBank()
    end
end

-- TODO: Eventually get search working. Not priority
function CB.G.SearchFilter(inventoryType, searchText)
    if inventoryType == CB.E.InventoryType.Inventory then
        local found = {}
        for _, item in pairs(CB.Session.Items) do
            if item.name and item.name ~= "" and string.find(item.name, searchText) then
                tinsert(found, item)
            end
        end

        CB.Session.Items = found
    end
end

-- Sorting
function CB.G.BuildSortingContainer(parent, type)
    local hFrame = CreateFrame("Frame", nil, parent)
    hFrame:SetSize(parent:GetWidth(), CB.Settings.Defaults.Sections.ListViewHeader)
    local offset = CB.Settings.Defaults.Sections.Header + CB.Settings.Defaults.Sections.Filters
    hFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -offset)

    hFrame.fields = {}

    local tex = hFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetPoint("TOPLEFT", hFrame, "TOPLEFT", 0, -4)
    tex:SetPoint("BOTTOMRIGHT", hFrame, "BOTTOMRIGHT")
    tex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Doubleline")
    tex:SetVertexColor(1, 1, 1, 0.5)

    local icon = BuildSortButton(hFrame, hFrame, "•", CB.Settings.Defaults.Columns.Icon,
        CB.E.SortFields.Icon, true, type, "Rarity")

    local name = BuildSortButton(hFrame, icon, "name", CB.Settings.Defaults.Columns.Name,
        CB.E.SortFields.Name, false, type, "Item Name")

    -- local category = BuildSortButton(hFrame, name, "cat", CB.Settings.Defaults.Columns.Category,
    --     CB.E.SortFields.Category, false, type)

    local ilvl = BuildSortButton(hFrame, name, "ilvl", CB.Settings.Defaults.Columns.Ilvl,
        CB.E.SortFields.Ilvl, false, type, "Item Level")

    local reqlvl = BuildSortButton(hFrame, ilvl, "req", CB.Settings.Defaults.Columns.ReqLvl,
        CB.E.SortFields.ReqLvl, false, type, "Required Level")

    local value = BuildSortButton(hFrame, reqlvl, "value", CB.Settings.Defaults.Columns.Value,
        CB.E.SortFields.Value, false, type, "Gold Value")
end

function BuildSortButton(parent, anchor, name, width, sortField, initial, type, friendlyName)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(width, parent:GetHeight())
    frame:SetPoint("LEFT", anchor, initial and "LEFT" or "RIGHT", initial and 3 or 0, 0)

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("BOTTOM", frame, "BOTTOM", 0, 12)
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
        elseif type == CB.E.InventoryType.Bank then
            CB.G.UpdateBank()
        end
    end)

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("Sort By: " .. friendlyName, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
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
