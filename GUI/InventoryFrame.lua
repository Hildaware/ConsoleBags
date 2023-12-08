local _, CB = ...

function CB.G.InitializeInventoryGUI()
    local f = CreateFrame("Frame", "ConsoleBagsInventory", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetSize(632, CBData.View.Size.Y or 396)
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", CBData.View.Position.X or 200, CBData.View.Position.Y or 200)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetResizeBounds(632, 396, 632, 2000)

    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetAllPoints(f)
    f.texture:SetColorTexture(0, 0, 0, 0.5)

    -- Frame Header
    local header = CreateFrame("Frame", nil, f)
    header:SetSize(f:GetWidth() - 2, 32)
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
        CB.G.Toggle()
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
    -- dragTex:SetColorTexture(1, 1, 1, 0.75)

    -- Filters
    CB.G.BuildFilteringContainer(f)

    -- 'Header'
    CB.G.BuildListViewHeader(f)

    local scroller = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroller:SetPoint("TOPLEFT", f, "TOPLEFT", 36, -66)
    scroller:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 8)
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

    -- Cleanup
    -- Hey, lets clean up only the Inventory Frames
    CB.G.CleanupItemFrames(inventoryType)
    CB.G.CleanupCategoryHeaderFrames(inventoryType)

    -- Filter Categories
    local foundCategories = {}
    for _, value in pairs(CB.Session.Categories) do
        if (value.key == CB.Settings.Filter) or CB.Settings.Filter == nil then
            tinsert(foundCategories, value)
        end
    end

    table.sort(foundCategories, function(a, b) return a.order < b.order end)

    local orderedCategories = {}
    for i = 1, #foundCategories do
        orderedCategories[i] = foundCategories[i]
    end

    local offset = 1
    local itemIndex = 1
    for _, categoryData in ipairs(orderedCategories) do
        if #categoryData.items > 0 then
            CB.G.BuildCategoryFrame(categoryData.name, categoryData.count, categoryData.key, offset, inventoryType)
            offset = offset + 1
            if CB.G.CollapsedCategories[categoryData.key] ~= true then
                for _, item in ipairs(categoryData.items) do
                    CB.G.BuildItemFrame(item, offset, itemIndex, inventoryType)
                    offset = offset + 1
                    itemIndex = itemIndex + 1
                end
            end
        end
    end
end
