local _, CB = ...

-- Frame Pools
local ItemPool = CB.U.Pool.New()
local CategoryPool = CB.U.Pool.New()
local FilterPool = CB.U.Pool.New()

function CB.G.InitializeInventoryGUI()
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
        _G["ConsolePortInputHandler"]:Release(self)
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

    local defaultButton = CreateFrame("Button", nil, header)
    defaultButton:SetSize(32, 32)
    defaultButton:SetPoint("LEFT", header, "LEFT", 6, 0)
    defaultButton:SetNormalTexture("Interface\\Addons\\ConsoleBags\\Media\\Back_Normal")
    defaultButton:SetHighlightTexture("Interface\\Addons\\ConsoleBags\\Media\\Back_Highlight")
    defaultButton:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("Show Default bags temporarily. ", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    defaultButton:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    defaultButton:SetScript("OnClick", function(self, button, down)
        CB.U.RestoreDefaultBags()
        CloseAllBags()
        OpenAllBags()
    end)

    local goldView = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    goldView:SetPoint("LEFT", defaultButton, "RIGHT", 6, 0)
    goldView:SetWidth(140)
    goldView:SetText(GetCoinTextureString(GetMoney()))

    header.Gold = goldView

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
    CB.G.BuildFilteringContainer(f, CB.E.InventoryType.Inventory)

    -- 'Header'
    CB.G.BuildSortingContainer(f, CB.E.InventoryType.Inventory)

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

    CB.G.CreateBagContainer()

    ---@diagnostic disable-next-line: undefined-global
    if ConsolePort then
        ---@diagnostic disable-next-line: undefined-global
        ConsolePort:AddInterfaceCursorFrame(CB.View)
    end
end

function CB.G.UpdateInventory()
    if CB.View == nil then return end

    local inventoryType = CB.E.InventoryType.Inventory
    CB.SortItems(inventoryType, CB.Session.Categories)

    Pool.Cleanup(ItemPool)
    Pool.Cleanup(CategoryPool)
    Pool.Cleanup(FilterPool)

    -- Filter Categories
    local foundCategories = {}
    for _, value in pairs(CB.Session.Categories) do
        if (value.key == CB.Session.Filter) or CB.Session.Filter == nil then
            tinsert(foundCategories, value)
        end
    end

    table.sort(foundCategories, function(a, b) return a.order < b.order end)

    local orderedCategories = {}
    for i = 1, #foundCategories do
        orderedCategories[i] = foundCategories[i]
    end

    local offset = 1
    local catIndex = 1
    local itemIndex = 1
    for _, categoryData in ipairs(orderedCategories) do
        if #categoryData.items > 0 then
            local catFrame = Pool.FetchInactive(CategoryPool, catIndex, CB.G.CreateCategoryHeaderPlaceholder)
            Pool.InsertActive(CategoryPool, catFrame, catIndex)
            CB.G.BuildCategoryFrame(categoryData, offset, catFrame, CB.View.ListView)

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

    CB.G.UpdateFilterButtons(inventoryType, FilterPool)
end
