local _, CB = ...

-- Frame Pools
local ItemPool = CB.U.Pool.New()
local CategoryPool = CB.U.Pool.New()
local FilterPool = CB.U.Pool.New()

function CB.G.InitializeInventoryGUI()
    local inventoryType = CB.E.InventoryType.Inventory

    local f = CreateFrame("Frame", "ConsoleBagsInventory", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetSize(600, CBData.View.Size.Y or 396)
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", CBData.View.Position.X or 200, CBData.View.Position.Y or 200)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetResizeBounds(600, 396, 600, 2000)

    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetAllPoints(f)
    f.texture:SetColorTexture(0, 0, 0, 0.75)

    -- Stop ConsolePort from reading shoulder buttons
    f:SetScript("OnShow", function(self)
        if _G["ConsolePortInputHandler"] then
            _G["ConsolePortInputHandler"]:SetCommand("PADRSHOULDER", self, true, 'LeftButton', 'UIControl', nil)
            _G["ConsolePortInputHandler"]:SetCommand("PADLSHOULDER", self, true, 'LeftButton', 'UIControl', nil)
        end
    end)

    -- Re-allow ConsolePort Input handling
    f:SetScript("OnHide", function(self)
        if _G["ConsolePortInputHandler"] then
            _G["ConsolePortInputHandler"]:Release(self)
        end
    end)

    f:SetPropagateKeyboardInput(true)
    f:SetScript("OnGamePadButtonDown", function(self, key)
        if key ~= "PADRSHOULDER" and key ~= "PADLSHOULDER" then return end
        local filterCount = #self.FilterFrame.Buttons
        local index = self.FilterFrame.SelectedIndex

        if key == "PADRSHOULDER" then -- Right
            if index == filterCount then
                self.FilterFrame.SelectedIndex = 1
            else
                self.FilterFrame.SelectedIndex = self.FilterFrame.SelectedIndex + 1
            end
            self.FilterFrame.Buttons[self.FilterFrame.SelectedIndex].OnSelect()
        elseif key == "PADLSHOULDER" then -- Left
            if index == 1 then
                self.FilterFrame.SelectedIndex = filterCount
            else
                self.FilterFrame.SelectedIndex = self.FilterFrame.SelectedIndex - 1
            end
            self.FilterFrame.Buttons[self.FilterFrame.SelectedIndex].OnSelect()
        end
    end)

    -- TODO: Split header
    -- Frame Header
    local header = CreateFrame("Frame", nil, f)
    header:SetSize(f:GetWidth(), CB.Settings.Defaults.Sections.Header)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    header:EnableMouse(true)

    header.texture = header:CreateTexture(nil, "BACKGROUND")
    header.texture:SetAllPoints(header)
    header.texture:SetColorTexture(0, 0, 0, 0.5)

    local close = CreateFrame("Button", nil, header)
    close:SetSize(32, 32)
    close:SetPoint("RIGHT", header, "RIGHT", -6, 0)
    close:SetNormalTexture("Interface\\Addons\\ConsoleBags\\Media\\Close_Normal")
    close:SetHighlightTexture("Interface\\Addons\\ConsoleBags\\Media\\Close_Highlight")
    close:SetPushedTexture("Interface\\Addons\\ConsoleBags\\Media\\Close_Pushed")
    close:SetScript("OnClick", function()
        CB.CloseAllBags()
    end)

    -- local defaultButton = CreateFrame("Button", nil, header)
    -- defaultButton:SetSize(32, 32)
    -- defaultButton:SetPoint("LEFT", header, "LEFT", 6, 0)
    -- defaultButton:SetNormalTexture("Interface\\Addons\\ConsoleBags\\Media\\Back_Normal")
    -- defaultButton:SetHighlightTexture("Interface\\Addons\\ConsoleBags\\Media\\Back_Highlight")
    -- defaultButton:HookScript("OnEnter", function(self)
    --     GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    --     GameTooltip:SetText("Show Default bags temporarily. ", 1, 1, 1, 1, true)
    --     GameTooltip:Show()
    -- end)
    -- defaultButton:HookScript("OnLeave", function(self)
    --     GameTooltip:Hide()
    -- end)
    -- defaultButton:SetScript("OnClick", function(self, button, down)
    --     CB.U.RestoreDefaultBags()
    --     CloseAllBags()
    --     OpenAllBags()
    -- end)

    local goldView = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    goldView:SetPoint("LEFT", header, "LEFT", 12, 0)
    goldView:SetWidth(140)
    goldView:SetJustifyH("LEFT")
    goldView:SetText(GetCoinTextureString(GetMoney()))

    header.Gold = goldView

    -- TODO: Eventually add Search
    -- local search = CreateFrame("EditBox", nil, header, "BagSearchBoxTemplate")
    -- search:SetPoint("LEFT", goldView, "RIGHT", 6, 0)
    -- search:SetSize(200, 28)
    -- search:SetScript("OnTextChanged", function(self, changed)
    --     if changed then
    --         local text = self:GetText()
    --         CB.G.SearchFilter(inventoryType, text)
    --     end
    -- end)

    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function(self, button)
        self:GetParent():StartMoving()
    end)
    header:SetScript("OnDragStop", function(self)
        self:GetParent():StopMovingOrSizing()
        local x = CB.View:GetLeft()
        local y = CB.View:GetTop()
        CBData.View.Position = { X = x, Y = y }
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
        CBData.View.Size.Y = CB.View:GetHeight()
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

    CB.View = f

    CB.G.CreateBags(inventoryType, CB.View)

    if _G["ConsolePort"] then
        _G["ConsolePort"]:AddInterfaceCursorFrame(CB.View)
    end
end

function CB.G.UpdateInventory()
    if CB.View == nil then return end

    local inventoryType = CB.E.InventoryType.Inventory

    Pool.Cleanup(ItemPool)
    Pool.Cleanup(CategoryPool)
    Pool.Cleanup(FilterPool)

    -- Categorize
    local catTable = {}
    for _, slots in pairs(CB.Session.Items) do
        for _, item in pairs(slots) do
            if item.location == CB.E.InventoryType.Inventory then
                CB.U.AddItemToCategory(item, catTable)
            end
        end
    end

    CB.U.SortItems(catTable, CBData.View.SortField)

    -- Filter Categories
    local allCategories = {}
    local filteredCategories = {}
    local iter = 1
    for key, value in pairs(catTable) do
        value.key = key
        value.order = CB.E.Categories[key].order
        value.name = CB.E.Categories[key].name
        allCategories[iter] = value
        if (key == CB.Session.InventoryFilter) or CB.Session.InventoryFilter == nil then
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
            CB.G.BuildCategoryFrame(categoryData, offset, catFrame, CB.View.ListView, inventoryType)

            offset = offset + 1
            catIndex = catIndex + 1
            if CB.G.CollapsedCategories[categoryData.key] ~= true then
                for _, item in ipairs(categoryData.items) do
                    local frame = Pool.FetchInactive(ItemPool, itemIndex, CB.G.CreateItemFramePlaceholder)
                    Pool.InsertActive(ItemPool, frame, itemIndex)
                    CB.G.BuildItemFrame(item, offset, frame, CB.View.ListView)

                    offset = offset + 1
                    itemIndex = itemIndex + 1
                end
            end
        end
    end

    CB.G.UpdateFilterButtons(orderedAllCategories, inventoryType, FilterPool)
    CB.G.UpdateBags(CB.View.Bags.Container, inventoryType)
end
