local _, CB = ...

local ItemPool = CB.U.Pool.New()
local CategoryPool = CB.U.Pool.New()
local FilterPool = CB.U.Pool.New()

function CB.G.InitializeBankGUI()
    local inventoryType = CB.E.InventoryType.Bank

    local f = CreateFrame("Frame", "ConsoleBagsBanking", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetSize(600, CBData.BankView.Size.Y or 396)
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", CBData.BankView.Position.X or 500, CBData.BankView.Position.Y or 800)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetResizeBounds(600, 396, 600, 2000)

    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetAllPoints(f)
    f.texture:SetColorTexture(0, 0, 0, 0.75)

    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetAllPoints(f)
    f.texture:SetColorTexture(0, 0, 0, 0.65)

    -- Frame Header
    local header = CreateFrame("Frame", nil, f)
    header:SetSize(f:GetWidth(), CB.Settings.Defaults.Sections.Header)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    header:EnableMouse(true)

    header.texture = header:CreateTexture(nil, "BACKGROUND")
    header.texture:SetAllPoints(header)
    header.texture:SetColorTexture(0.5, 0.5, 0.5, 0.15)

    local name = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    name:SetPoint("LEFT", header, "LEFT", 12, 0)
    name:SetWidth(100)
    name:SetJustifyH("LEFT")
    name:SetText("Bank")

    local close = CreateFrame("Button", nil, header)
    close:SetSize(32, 32)
    close:SetPoint("RIGHT", header, "RIGHT", -6, 0)
    close:SetNormalTexture("Interface\\Addons\\ConsoleBags\\Media\\Close_Normal")
    close:SetHighlightTexture("Interface\\Addons\\ConsoleBags\\Media\\Close_Highlight")
    close:SetPushedTexture("Interface\\Addons\\ConsoleBags\\Media\\Close_Pushed")
    close:SetScript("OnClick", function()
        CB.G.HideBank()
    end)

    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function(self, button)
        self:GetParent():StartMoving()
    end)
    header:SetScript("OnDragStop", function(self)
        self:GetParent():StopMovingOrSizing()
        local x = CB.BankView:GetLeft()
        local y = CB.BankView:GetTop()
        CBData.BankView.Position = { X = x, Y = y }
    end)

    f.Header = header

    -- Drag Bar
    local drag = CreateFrame("Button", nil, f)
    drag:SetSize(64, 12)
    drag:SetPoint("BOTTOM", f, "BOTTOM", 0, -6)
    drag:SetScript("OnMouseDown", function(self)
        self:GetParent():StartSizing("BOTTOM")
    end)
    drag:SetScript("OnMouseUp", function(self)
        self:GetParent():StopMovingOrSizing("BOTTOM")
        CBData.BankView.Size.Y = CB.BankView:GetHeight()
    end)
    local dragTex = drag:CreateTexture(nil, "BACKGROUND")
    dragTex:SetAllPoints(drag)
    dragTex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Handlebar")

    -- Filters
    CB.G.BuildFilteringContainer(f, inventoryType)

    -- 'Header'
    CB.G.BuildSortingContainer(f, inventoryType)

    local scroller = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    local offset = CB.Settings.Defaults.Sections.Header + CB.Settings.Defaults.Sections.Filters
        + CB.Settings.Defaults.Sections.ListViewHeader
    scroller:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -offset)
    scroller:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 2)
    scroller:SetWidth(f:GetWidth())

    local scrollChild = CreateFrame("Frame")
    scroller:SetScrollChild(scrollChild)
    scrollChild:SetSize(scroller:GetWidth(), 1)

    f.ListView = scrollChild
    f:Hide()

    table.insert(UISpecialFrames, f:GetName())

    CB.G.U.CreateBorder(f)

    CB.BankView = f

    CB.G.CreateBags(inventoryType, CB.BankView)

    if _G["ConsolePort"] then
        _G["ConsolePort"]:AddInterfaceCursorFrame(CB.BankView)
    end
end

function CB.G.UpdateBank()
    if CB.BankView == nil then return end

    local inventoryType = CB.E.InventoryType.Bank

    Pool.Cleanup(ItemPool)
    Pool.Cleanup(CategoryPool)
    Pool.Cleanup(FilterPool)

    -- Categorize
    local catTable = {}
    for _, slots in pairs(CB.Session.Items) do
        for _, item in pairs(slots) do
            if item.location == CB.E.InventoryType.Bank then
                CB.U.AddItemToCategory(item, catTable)
            end
        end
    end

    CB.U.SortItems(catTable, CBData.BankView.SortField)

    -- Filter Categories
    local allCategories = {}
    local filteredCategories = {}
    local iter = 1
    for key, value in pairs(catTable) do
        value.key = key
        value.order = CB.E.Categories[key].order
        value.name = CB.E.Categories[key].name
        allCategories[iter] = value
        if (key == CB.Session.BankFilter) or CB.Session.BankFilter == nil then
            tinsert(filteredCategories, value)
        end
        iter = iter + 1
    end

    table.sort(allCategories, function(a, b) return a.order < b.order end)
    table.sort(filteredCategories, function(a, b) return a.order < b.order end)

    local orderedCategories = {}
    for i = 1, #filteredCategories do
        orderedCategories[i] = filteredCategories[i]
    end

    local orderedAllCategories = {}
    for i = 1, #allCategories do
        orderedAllCategories[i] = allCategories[i]
    end

    local offset = 1
    local catIndex = 1
    local itemIndex = 1
    for _, categoryData in ipairs(orderedCategories) do
        if #categoryData.items > 0 then
            local catFrame = Pool.FetchInactive(CategoryPool, catIndex, CB.G.CreateCategoryHeaderPlaceholder)
            Pool.InsertActive(CategoryPool, catFrame, catIndex)
            CB.G.BuildCategoryFrame(categoryData, offset, catFrame, CB.BankView.ListView, inventoryType)

            offset = offset + 1
            catIndex = catIndex + 1
            if CB.G.CollapsedCategories[categoryData.key] ~= true then
                for _, item in ipairs(categoryData.items) do
                    local frame = Pool.FetchInactive(ItemPool, itemIndex, CB.G.CreateItemFramePlaceholder)
                    Pool.InsertActive(ItemPool, frame, itemIndex)
                    CB.G.BuildItemFrame(item, offset, frame, CB.BankView.ListView)

                    offset = offset + 1
                    itemIndex = itemIndex + 1
                end
            end
        end
    end

    CB.G.UpdateFilterButtons(orderedAllCategories, inventoryType, FilterPool)
    CB.G.UpdateBags(CB.BankView.Bags.Container, inventoryType)
end

function CB.G.ShowBank()
    if CB.BankView == nil then
        -- CB.G.InitializeBankGUI()
        CB.G.InitializeView(CB.E.InventoryType.Bank, "Bank", CBData.BankView)
    end

    if not CB.BankView:IsShown() then
        PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
        CB.BankView:Show()
    end
end

function CB.G.HideBank()
    if CB.BankView and CB.BankView:IsShown() then
        CB.BankView:Hide()
    end
end
