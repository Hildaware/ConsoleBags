local _, CB = ...

CB.G = {}
CB.G.U = {}

function CB.G.UpdateCurrency()
    if CB.View and CB.View.Header then
        CB.View.Header.Gold:SetText(GetCoinTextureString(GetMoney()))
    end
end

-- TODO: Make more generic (bank)
function CB.G.BuildFilteringContainer(parent)
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
        CB.G.UpdateInventory()
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

-- TODO: Make more generic (bank)
function CB.G.BuildListViewHeader(parent)
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

-- TODO: Make more generic (bank)
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

    if CBData.View.SortField.Sort == CB.E.SortOrder.Desc then
        arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Up")
    else
        arrow:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Arrow_Down")
    end

    if CBData.View.SortField.Field ~= sortField then
        arrow:Hide()
    end

    frame:SetScript("OnClick", function()
        local sortOrder = CBData.View.SortField.Sort
        if CBData.View.SortField.Field == sortField then
            if sortOrder == CB.E.SortOrder.Asc then
                sortOrder = CB.E.SortOrder.Desc
            else
                sortOrder = CB.E.SortOrder.Asc
            end
        end

        CBData.View.SortField.Field = sortField
        CBData.View.SortField.Sort = sortOrder

        if CBData.View.SortField.Sort ~= CB.E.SortOrder.Desc then
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

        CB.G.UpdateInventory()
        CB.G.UpdateFilterButtons()
        CB.G.UpdateBagContainer()
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
