local _, CB = ...

function CB.G.InitializeBankGUI()
    local f = CreateFrame("Frame", "ConsoleBagsBanking", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetSize(632, CBData.View.Size.Y or 396)
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", CBData.BankView.Position.X or 500, CBData.BankView.Position.Y or 800)
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
        CBData.BankView.Size.Y = CB.View:GetHeight()
    end)
    local dragTex = drag:CreateTexture(nil, "BACKGROUND")
    dragTex:SetAllPoints(drag)
    dragTex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Handlebar")

    -- Filters
    CB.G.BuildFilteringContainer(f)

    -- 'Header'
    CB.G.BuildListViewHeader(f)

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

    CB.G.U.CreateBorder(f)

    CB.BankView = f

    ---@diagnostic disable-next-line: undefined-global
    if ConsolePort then
        ---@diagnostic disable-next-line: undefined-global
        ConsolePort:AddInterfaceCursorFrame(CB.BankView)
    end
end

function CB.G.ShowBank()
    if CB.BankView == nil then
        CB.G.InitializeBankGUI()
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
