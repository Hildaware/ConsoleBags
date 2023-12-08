local _, CB = ...

CB.G = {}

function CB.G.InitializeGUI()
    local f = CreateFrame("Frame", "CBFrame", UIParent)
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
    BuildFilteringContainer(f)

    -- 'Header'
    BuildListViewHeader(f)

    local scroller = CreateFrame("ScrollFrame", "CBScrollView", f, "UIPanelScrollFrameTemplate")
    scroller:SetPoint("TOPLEFT", f, "TOPLEFT", 36, -66)
    scroller:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 8)
    scroller:SetWidth(f:GetWidth())

    local scrollChild = CreateFrame("Frame", "CBListView")
    scroller:SetScrollChild(scrollChild)
    scrollChild:SetSize(scroller:GetWidth(), 1)

    f.ListView = scrollChild
    f:Hide()

    table.insert(UISpecialFrames, f:GetName())

    CreateBorder(f)

    CB.View = f

    CB.G.CreateBagContainer()

    ---@diagnostic disable-next-line: undefined-global
    if ConsolePort then
        ---@diagnostic disable-next-line: undefined-global
        ConsolePort:AddInterfaceCursorFrame(CB.View)
    end
end

function CB.G.UpdateView()
    if CB.View == nil then return end

    CB.SortItems()

    -- Cleanup
    CB.G.CleanupItemFrames()
    CB.G.CleanupCategoryHeaderFrames()

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
            CB.G.BuildCategoryFrame(categoryData.name, categoryData.count, categoryData.key, offset)
            offset = offset + 1
            if CB.G.CollapsedCategories[categoryData.key] ~= true then
                for _, item in ipairs(categoryData.items) do
                    CB.G.BuildItemFrame(item, offset, itemIndex)
                    offset = offset + 1
                    itemIndex = itemIndex + 1
                end
            end
        end
    end
end

function CB.G.UpdateCurrency()
    if CB.View and CB.View.Header then
        CB.View.Header.Gold:SetText(GetCoinTextureString(GetMoney()))
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

    f:SetHighlightTexture("Interface\\Addons\\ConsoleBags\\Media\\Rounded_BG")
    f:SetPushedTexture("Interface\\Addons\\ConsoleBags\\Media\\Rounded_BG")
    f:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.25)
    f:GetPushedTexture():SetVertexColor(1, 1, 1, 0.25)

    local aTex = f:CreateTexture(nil, "OVERLAY")
    aTex:SetPoint("CENTER", 0, "CENTER")
    aTex:SetSize(24, 24)
    aTex:SetTexture(CB.U.GetCategoyIcon(1))

    f:SetScript("OnClick", function(self)
        CB.Settings.Filter = nil
        CB.GatherItems()
        CB.G.UpdateView()
        CB.G.UpdateFilterButtons()
        CB.G.UpdateBagContainer()
        self:GetParent().selectedTexture:SetPoint("TOP", self:GetParent(), "TOP", 0, -32)
    end)
    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")

    -- IsSelected
    local selectedTex = cFrame:CreateTexture(nil, "ARTWORK")
    selectedTex:SetPoint("TOP", cFrame, "TOP", 0, -32)
    selectedTex:SetSize(28, 28)
    selectedTex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Rounded_BG")
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

    local icon = BuildSortButton(hFrame, hFrame, "•", CB.Settings.Defaults.Columns.Icon,
        CB.E.SortFields.Icon, true)

    local name = BuildSortButton(hFrame, icon, "NAME", CB.Settings.Defaults.Columns.Name,
        CB.E.SortFields.Name, false)

    local category = BuildSortButton(hFrame, name, "CAT", CB.Settings.Defaults.Columns.Category,
        CB.E.SortFields.Category, false)

    local ilvl = BuildSortButton(hFrame, category, "ILVL", CB.Settings.Defaults.Columns.Ilvl,
        CB.E.SortFields.Ilvl, false)

    local reqlvl = BuildSortButton(hFrame, ilvl, "REQ", CB.Settings.Defaults.Columns.ReqLvl,
        CB.E.SortFields.ReqLvl, false)

    local value = BuildSortButton(hFrame, reqlvl, "VALUE", CB.Settings.Defaults.Columns.Value,
        CB.E.SortFields.Value, false)
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
    arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Up")
    arrow:SetSize(8, 14)

    if CB.Settings.SortField.Sort == CB.E.SortOrder.Desc then
        arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Up")
    else
        arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Down")
    end

    if CB.Settings.SortField.Field ~= sortField then
        arrow:Hide()
    end

    frame:SetScript("OnClick", function()
        local sortOrder = CB.Settings.SortField.Sort
        if CB.Settings.SortField.Field == sortField then
            if sortOrder == CB.E.SortOrder.Asc then
                sortOrder = CB.E.SortOrder.Desc
            else
                sortOrder = CB.E.SortOrder.Asc
            end
        end

        CB.Settings.SortField.Field = sortField
        CB.Settings.SortField.Sort = sortOrder

        if CB.Settings.SortField.Sort ~= CB.E.SortOrder.Desc then
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

        CB.G.UpdateView()
        CB.G.UpdateFilterButtons()
        CB.G.UpdateBagContainer()
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
