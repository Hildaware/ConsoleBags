local _, Bagger = ...

Bagger.G = {}

function Bagger.G.InitializeGUI()
    local f = CreateFrame("Frame", "BaggerFrame", UIParent)
    f:SetSize(632, BaggerData.View.Size.Y or 396)
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BaggerData.View.Position.X or 200, BaggerData.View.Position.Y or 200)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetResizeBounds(632, 396, 632, 2000)

    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetAllPoints(f)
    f.texture:SetColorTexture(0, 0, 0, 0.5)

    -- Frame Header
    -- TODO: Switch to "WoW mode"
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
    close:SetNormalTexture("Interface\\Addons\\Bagger\\Media\\Close_Normal")
    close:SetHighlightTexture("Interface\\Addons\\Bagger\\Media\\Close_Highlight")
    close:SetPushedTexture("Interface\\Addons\\Bagger\\Media\\Close_Pushed")
    close:SetScript("OnClick", function()
        Bagger.G.Toggle()
    end)

    local goldView = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    goldView:SetPoint("LEFT", header, "LEFT", 6, 0)
    goldView:SetWidth(140)
    goldView:SetText(GetCoinTextureString(GetMoney()))

    header.Gold = goldView

    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function(self, button)
        self:GetParent():StartMoving()
    end)
    header:SetScript("OnDragStop", function(self)
        self:GetParent():StopMovingOrSizing()
        local x = Bagger.View:GetLeft()
        local y = Bagger.View:GetTop()
        BaggerData.View.Position = { X = x, Y = y }
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
        BaggerData.View.Size.Y = Bagger.View:GetHeight()
    end)
    local dragTex = drag:CreateTexture(nil, "BACKGROUND")
    dragTex:SetAllPoints(drag)
    dragTex:SetTexture("Interface\\Addons\\Bagger\\Media\\Handlebar")
    -- dragTex:SetColorTexture(1, 1, 1, 0.75)

    -- Filters
    BuildFilteringContainer(f)

    -- 'Header'
    BuildListViewHeader(f)

    local scroller = CreateFrame("ScrollFrame", "BaggerScrollView", f, "UIPanelScrollFrameTemplate")
    scroller:SetPoint("TOPLEFT", f, "TOPLEFT", 36, -66)
    scroller:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 8)
    scroller:SetWidth(f:GetWidth())

    local scrollChild = CreateFrame("Frame", "BaggerListView")
    scroller:SetScrollChild(scrollChild)
    scrollChild:SetSize(scroller:GetWidth(), 1)

    f.ListView = scrollChild
    f:Hide()

    table.insert(UISpecialFrames, f:GetName())

    CreateBorder(f)

    Bagger.View = f

    Bagger.G.CreateBagContainer()

    ---@diagnostic disable-next-line: undefined-global
    if ConsolePort then
        ---@diagnostic disable-next-line: undefined-global
        ConsolePort:AddInterfaceCursorFrame(Bagger.View)
    end
end

function Bagger.G.UpdateView()
    if Bagger.View == nil then return end

    Bagger.GatherItems(Bagger.Settings.Filter)
    Bagger.SortItems(Bagger.Settings.SortField.Field, Bagger.Settings.SortField.Sort)

    -- Cleanup
    Bagger.G.CleanupItemFrames()
    Bagger.G.CleanupCategoryHeaderFrames()

    local categorizedItems = Bagger.U.BuildCategoriesTable()

    -- Build
    for _, item in ipairs(Bagger.Session.Filtered) do
        local iCategory = item.type

        if item.quality and item.quality == Enum.ItemQuality.Heirloom then -- BoA
            tinsert(categorizedItems[Bagger.E.CustomCategory.BindOnAccount].items, item)
            categorizedItems[Bagger.E.CustomCategory.BindOnAccount].count =
                categorizedItems[Bagger.E.CustomCategory.BindOnAccount].count + 1
        elseif Bagger.U.IsEquipmentUnbound(item) then -- BoE
            tinsert(categorizedItems[Bagger.E.CustomCategory.BindOnEquip].items, item)
            categorizedItems[Bagger.E.CustomCategory.BindOnEquip].count =
                categorizedItems[Bagger.E.CustomCategory.BindOnEquip].count + 1
        elseif Bagger.U.IsJewelry(item) then -- Jewelry
            tinsert(categorizedItems[Bagger.E.CustomCategory.Jewelry].items, item)
            categorizedItems[Bagger.E.CustomCategory.Jewelry].count =
                categorizedItems[Bagger.E.CustomCategory.Jewelry].count + 1
        elseif Bagger.U.IsTrinket(item) then -- Trinkets
            tinsert(categorizedItems[Bagger.E.CustomCategory.Trinket].items, item)
            categorizedItems[Bagger.E.CustomCategory.Trinket].count =
                categorizedItems[Bagger.E.CustomCategory.Trinket].count + 1
        elseif iCategory ~= nil then
            tinsert(categorizedItems[iCategory].items, item)
            categorizedItems[iCategory].count =
                categorizedItems[iCategory].count + 1
        else
            tinsert(categorizedItems[Enum.ItemClass.Miscellaneous].items, item)
            categorizedItems[Enum.ItemClass.Miscellaneous].count =
                categorizedItems[Enum.ItemClass.Miscellaneous].count + 1
        end
    end

    -- Categorize
    local orderedCategories = {}
    for key, value in pairs(categorizedItems) do
        orderedCategories[value.order] = value
        orderedCategories[value.order].key = key
    end

    local offset = 1
    local itemIndex = 1
    for _, categoryData in ipairs(orderedCategories) do
        if #categoryData.items > 0 then
            Bagger.G.BuildCategoryFrame(categoryData.name, categoryData.count, categoryData.key, offset)
            offset = offset + 1
            if Bagger.G.CollapsedCategories[categoryData.key] ~= true then
                for _, item in ipairs(categoryData.items) do
                    Bagger.G.BuildItemFrame(item, offset, itemIndex)
                    offset = offset + 1
                    itemIndex = itemIndex + 1
                end
            end
        end
    end
end

function Bagger.G.UpdateCurrency()
    if Bagger.View and Bagger.View.Header then
        Bagger.View.Header.Gold:SetText(GetCoinTextureString(GetMoney()))
    end
end

function BuildFilteringContainer(parent)
    local cFrame = CreateFrame("Frame", nil, parent)
    cFrame:SetSize(32, parent:GetHeight() - 32)
    cFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -32)

    local tex = cFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(cFrame)
    tex:SetColorTexture(0, 0, 0, 0.25)

    -- All
    local f = CreateFrame("Button", nil, cFrame)
    f:SetSize(28, 28)
    f:SetPoint("TOP", cFrame, "TOP", 0, -32)

    f:SetHighlightTexture("Interface\\Addons\\Bagger\\Media\\Rounded_BG")
    f:SetPushedTexture("Interface\\Addons\\Bagger\\Media\\Rounded_BG")
    f:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.25)
    f:GetPushedTexture():SetVertexColor(1, 1, 1, 0.25)

    local aTex = f:CreateTexture(nil, "OVERLAY")
    aTex:SetPoint("CENTER", 0, "CENTER")
    aTex:SetSize(24, 24)
    aTex:SetTexture(Bagger.U.GetCategoyIcon(1))

    f:SetScript("OnClick", function(self)
        Bagger.Settings.Filter = nil
        Bagger.G.UpdateView()
        self:GetParent().selectedTexture:SetPoint("TOP", self:GetParent(), "TOP", 0, -32)
    end)
    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")

    -- IsSelected
    local selectedTex = cFrame:CreateTexture(nil, "ARTWORK")
    selectedTex:SetPoint("TOP", cFrame, "TOP", 0, -32)
    selectedTex:SetSize(28, 28)
    selectedTex:SetTexture("Interface\\Addons\\Bagger\\Media\\Rounded_BG")
    selectedTex:SetVertexColor(1, 1, 0, 0.25)

    cFrame.selectedTexture = selectedTex
    parent.FilterFrame = cFrame
end

function BuildListViewHeader(parent)
    local hFrame = CreateFrame("Frame", nil, parent)
    hFrame:SetSize(parent:GetWidth() - 32, 32)
    hFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 32, -32)

    hFrame.fields = {}

    local tex = hFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(hFrame)
    tex:SetColorTexture(0, 0, 0, 0.25)

    local icon = BuildSortButton(hFrame, hFrame, "•", Bagger.Settings.Defaults.Columns.Icon,
        Bagger.E.SortFields.Icon, true)

    local name = BuildSortButton(hFrame, icon, "NAME", Bagger.Settings.Defaults.Columns.Name,
        Bagger.E.SortFields.Name, false)

    local category = BuildSortButton(hFrame, name, "CAT", Bagger.Settings.Defaults.Columns.Category,
        Bagger.E.SortFields.Category, false)

    local ilvl = BuildSortButton(hFrame, category, "ILVL", Bagger.Settings.Defaults.Columns.Ilvl,
        Bagger.E.SortFields.Ilvl, false)

    local reqlvl = BuildSortButton(hFrame, ilvl, "REQ", Bagger.Settings.Defaults.Columns.ReqLvl,
        Bagger.E.SortFields.ReqLvl, false)

    local value = BuildSortButton(hFrame, reqlvl, "VALUE", Bagger.Settings.Defaults.Columns.Value,
        Bagger.E.SortFields.Value, false)
end

function BuildSortButton(parent, anchor, name, width, sortField, initial)
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
    arrow:SetTexture("Interface\\Addons\\Bagger\\Media\\Arrow_Up")
    arrow:SetSize(8, 14)

    if Bagger.Settings.SortField.Sort == Bagger.E.SortOrder.Desc then
        arrow:SetTexture("Interface\\Addons\\Bagger\\Media\\Arrow_Up")
    else
        arrow:SetTexture("Interface\\Addons\\Bagger\\Media\\Arrow_Down")
    end

    if Bagger.Settings.SortField.Field ~= sortField then
        arrow:Hide()
    end

    frame:SetScript("OnClick", function()
        local sortOrder = Bagger.Settings.SortField.Sort
        if Bagger.Settings.SortField.Field == sortField then
            if sortOrder == Bagger.E.SortOrder.Asc then
                sortOrder = Bagger.E.SortOrder.Desc
            else
                sortOrder = Bagger.E.SortOrder.Asc
            end
        end

        Bagger.Settings.SortField.Field = sortField
        Bagger.Settings.SortField.Sort = sortOrder

        if Bagger.Settings.SortField.Sort ~= Bagger.E.SortOrder.Desc then
            arrow:SetTexture("Interface\\Addons\\Bagger\\Media\\Arrow_Up")
        else
            arrow:SetTexture("Interface\\Addons\\Bagger\\Media\\Arrow_Down")
        end

        arrow:Show()
        text:SetTextColor(1, 1, 0)

        -- Remove other arrows
        for _, k in pairs(Bagger.E.SortFields) do
            if k ~= sortField then
                parent.fields[k].arrow:Hide()
                parent.fields[k].text:SetTextColor(1, 1, 1)
            end
        end

        Bagger.G.UpdateView()
    end)

    parent.fields[sortField] = frame
    frame.arrow = arrow
    frame.text = text

    return frame
end

-- TODO: Eventually get this working for adjustable columns
function BuildHeaderAdjuster(parent, anchor)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetSize(2, parent:GetHeight())
    frame:SetPoint("LEFT", anchor, "RIGHT")
    frame:SetScript("OnMouseDown", function(self)
        self.x, self.y = GetCursorPosition()
        self.x = self.x / self:GetEffectiveScale()
        self.y = self.y / self:GetEffectiveScale()

        self:SetScript("OnUpdate", function(self)
            local x, y = GetCursorPosition()
            x = x / self:GetEffectiveScale()
            y = y / self:GetEffectiveScale()
            print(x)
            -- TODO: Adjust columns
        end)
    end)
    frame:SetScript("onMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    local tex = frame:CreateTexture()
    tex:SetAllPoints(frame)
    tex:SetTexture(1, 1, 1, 0.75)

    return frame
end

-- Utils
function CreateBorder(self)
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
