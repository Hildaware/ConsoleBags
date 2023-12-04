local _, Bagger = ...

Bagger.G = {}

local LIST_ITEM_HEIGHT = 32

function Bagger.G.InitializeGUI()
    local f = CreateFrame("Frame", "Bagger", UIParent)
    f:SetSize(600, 396)
    f:SetPoint("CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetResizeBounds(600, 396, 600, 2000)

    f.texture = f:CreateTexture(nil,"BACKGROUND")
    f.texture:SetAllPoints(f)
    f.texture:SetColorTexture(0, 0, 0, 0.5)

    -- Frame Header
    -- TODO: Close Button, Bag View, Switch to "WoW mode", Gold View
    local header = CreateFrame("Frame", nil, f)
    header:SetSize(f:GetWidth()-2, 32)
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

    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function(self, button)
        self:GetParent():StartMoving()
        print("OnDragStart", button)
    end)
    header:SetScript("OnDragStop", function(self)
        self:GetParent():StopMovingOrSizing()
        print("OnDragStop")
    end)

    -- Drag Bar
    local drag = CreateFrame("Button", nil, f)
    drag:SetSize(40, 6)
    drag:SetPoint("BOTTOM", f, "BOTTOM", 0, -2)
    drag:SetScript("OnMouseDown", function(self)
        self:GetParent():StartSizing("BOTTOMRIGHT")
    end)
    drag:SetScript("OnMouseUp", function(self)
        self:GetParent():StopMovingOrSizing("BOTTOMRIGHT")
    end)
    local dragTex = drag:CreateTexture(nil, "BACKGROUND")
    dragTex:SetAllPoints(drag)
    dragTex:SetColorTexture(0.5, 0.5, 0.5, 1)

    Bagger.G.CreateBorder(f)

    -- Filters
    Bagger.G.BuildFilterFrame(f)

    -- 'Header'
    Bagger.G.BuildHeaderFrame(f)

    local scroller = CreateFrame("ScrollFrame", "BaggerScrollView", f, "UIPanelScrollFrameTemplate")
    scroller:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -98)
    scroller:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 8)
    scroller:SetWidth(f:GetWidth())

    local scrollChild = CreateFrame("Frame", "BaggerListView")
    scroller:SetScrollChild(scrollChild)
    scrollChild:SetSize(scroller:GetWidth(), 1)

    f.listView = scrollChild
    f:Hide()

    table.insert(UISpecialFrames, f:GetName())

    Bagger.View = f

        -- listView should have (200?) frames we can recycle
        for i = 1, 200 do
            local phFrame = Bagger.G.CreateItemFramePlaceholder(f.listView)
            phFrame:SetPoint("TOP", 0, -((i-1)*LIST_ITEM_HEIGHT))
            phFrame:Hide()
        end

---@diagnostic disable-next-line: undefined-global
    if ConsolePort then
---@diagnostic disable-next-line: undefined-global
        ConsolePort:AddInterfaceCursorFrame(Bagger.View)
    end
end

function Bagger.G.UpdateView(type)
    if Bagger.View == nil then return end

    Bagger.GatherItems(type)

    Bagger.SortItems(Bagger.Settings.SortField.Field, Bagger.Settings.SortField.Sort)

    -- Hide what we're not going to use
    for i = #Bagger.Session.Filtered, 200 do
        local frame = select(i, Bagger.View.listView:GetChildren())
        if frame ~= nil then
            frame:Hide()
        end
    end

    for index,item in ipairs(Bagger.Session.Filtered) do
        Bagger.G.BuildItemFrame(item, index)
    end
end

-- Items
function Bagger.G.CreateItemFramePlaceholder(parent)

    local f = CreateFrame("Button", nil, parent)
    f:SetSize(Bagger.View.listView:GetWidth(), LIST_ITEM_HEIGHT)

    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    f:RegisterForDrag("LeftButton")

    f:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Icon
    local icon = CreateFrame("Frame", nil, f)
    icon:SetPoint("LEFT", f, "LEFT")
    icon:SetSize(Bagger.Settings.Defaults.Columns.ICON, parent:GetHeight())
    local iconTexture = icon:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(24, 24)
    iconTexture:SetPoint("CENTER", icon, "CENTER")
    
    f.icon = iconTexture

    -- Name
    local name = CreateFrame("Frame", nil, f)
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetHeight(parent:GetHeight())
    name:SetWidth(Bagger.Settings.Defaults.Columns.NAME)
    local nameText = name:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameText:SetAllPoints(name)
    nameText:SetJustifyH("LEFT")
    
    f.name = nameText

    -- type
    local type = CreateFrame("Frame", nil, f)
    type:SetPoint("LEFT", name, "RIGHT")
    type:SetHeight(parent:GetHeight())
    type:SetWidth(Bagger.Settings.Defaults.Columns.CATEGORY)

    local typeTex = type:CreateTexture(nil, "ARTWORK")
    typeTex:SetPoint("CENTER", type, "CENTER")
    typeTex:SetSize(24, 24)

    f.type = typeTex

    -- TODO:DECIDE >>> subType (Could be useful for trinkets / rings / neck?) 
    -- local subType = CreateFrame("Frame", nil, parent)
    -- subType:SetPoint("LEFT", type, "RIGHT")
    -- subType:SetHeight(parent:GetHeight())
    -- subType:SetWidth(80)
    -- local subTypeText = subType:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- subTypeText:SetAllPoints(subType)
    -- subTypeText:SetJustifyH("CENTER")
    -- subTypeText:SetText(item.subType)

    -- ilvl
    local ilvl = CreateFrame("Frame", nil, f)
    ilvl:SetPoint("LEFT", type, "RIGHT")
    ilvl:SetHeight(parent:GetHeight())
    ilvl:SetWidth(Bagger.Settings.Defaults.Columns.ILVL)
    local ilvlText = ilvl:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ilvlText:SetAllPoints(ilvl)
    ilvlText:SetJustifyH("CENTER")

    f.ilvl = ilvlText

    -- reqlvl
    local reqlvl = CreateFrame("Frame", nil, f)
    reqlvl:SetPoint("LEFT", ilvl, "RIGHT")
    reqlvl:SetHeight(parent:GetHeight())
    reqlvl:SetWidth(Bagger.Settings.Defaults.Columns.REQLVL)
    local reqlvlText = reqlvl:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    reqlvlText:SetAllPoints(reqlvl)
    reqlvlText:SetJustifyH("CENTER")

    f.reqlvl = reqlvlText

    -- value
    local value = CreateFrame("Frame", nil, f)
    value:SetPoint("LEFT", reqlvl, "RIGHT")
    value:SetHeight(parent:GetHeight())
    value:SetWidth(Bagger.Settings.Defaults.Columns.VALUE)
    local valueText = value:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valueText:SetAllPoints(value)
    valueText:SetJustifyH("RIGHT")

    f.value = valueText

    return f
end

function Bagger.G.BuildItemFrame(item, index)
    local frame = select(index, Bagger.View.listView:GetChildren())
    if frame == nil then return end

    local r, g, b, _ = GetItemQualityColor(item.quality or 0)
    frame:SetHighlightTexture("Interface\\Addons\\Bagger\\Media\\Item_Highlight")
    frame:SetPushedTexture("Interface\\Addons\\Bagger\\Media\\Item_Highlight")
    frame:GetHighlightTexture():SetVertexColor(r, g, b, 1)

    if item.isNew == true then
        frame:SetNormalTexture("Interface\\Addons\\Bagger\\Media\\Item_Highlight")
        frame:GetNormalTexture():SetVertexColor(1, 1, 0, 1)
    else
        frame:SetNormalTexture("")
        frame:GetNormalTexture():SetVertexColor(0, 0, 0, 0)
    end

    -- frame.stack:SetText(tostring(item.stackCount))
    frame.icon:SetTexture(item.texture)

    local stackString = (item.stackCount and item.stackCount > 1) and "(" .. item.stackCount .. ")" or nil
    local nameString = item.name
    if stackString then
        nameString = nameString .. " " .. stackString
    end
    frame.name:SetText(nameString)
    -- Color
    frame.name:SetTextColor(r, g, b)

    frame.type:SetTexture(Bagger.U.GetCategoyIcon(item.type))

    if item.type == Enum.ItemClass.Armor or item.type == Enum.ItemClass.Weapon then
        frame.ilvl:SetText(item.ilvl)
    else
        frame.ilvl:SetText("")
    end

    if item.reqLvl and item.reqLvl > 1 then
        frame.reqlvl:SetText(item.reqLvl)
    else
        frame.reqlvl:SetText("")
    end

    if item.value and item.value > 1 then
        frame.value:SetText(GetCoinTextureString(item.value))
    else
        frame.value:SetText("")
    end

    frame:SetScript("OnEnter", function(self)
        -- This is pretty jank, but it fixes a specific issue with ConsolePort
        self.GetBagID = function() return item.bag end
        self.GetID = function() return item.slot end
        self.GetSlotAndBagID = ContainerFrameItemButtonMixin.GetSlotAndBagID

        if item.isNew == true then
            C_NewItems.RemoveNewItem(item.bag, item.slot)
        end

        frame:SetNormalTexture("")
        frame:GetNormalTexture():SetVertexColor(0, 0, 0, 0)

        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetBagItem(item.bag, item.slot)
        GameTooltip:Show()
    end)

    frame:SetScript("OnClick", function(self, button, down)
        if button == "LeftButton" then
            C_Container.PickupContainerItem(item.bag, item.slot)
        else
            C_Container.UseContainerItem(item.bag, item.slot)
        end
    end)
    frame:SetScript("OnDragStart", function(self)
        C_Container.PickupContainerItem(item.bag, item.slot)
    end)

    frame:Show()
end

-- Filtering
function Bagger.G.BuildFilterFrame(parent)

    local cFrame = CreateFrame("Frame", nil, parent)
    cFrame:SetSize(parent:GetWidth(), 32)
    cFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -32)

    local all = CreateFrame("Button", nil, cFrame, "UIPanelButtonTemplate")
    all:SetSize(32, 32)
    all:SetPoint("LEFT", cFrame, "LEFT", 10, 0)
    all:SetText("ALL")
    all:SetScript("OnClick", function()
         Bagger.G.UpdateView()
    end)
    all:RegisterForClicks("AnyDown", "AnyUp")

    local weapons = CreateFrame("Button", nil, cFrame, "UIPanelButtonTemplate")
    weapons:SetSize(32, 32)
    weapons:SetPoint("LEFT", all, "RIGHT", 10, 0)
    weapons:SetText("WEAP")
    weapons:SetScript("OnClick", function()
        Bagger.G.UpdateView(Enum.ItemClass.Weapon)
    end)
    weapons:RegisterForClicks("AnyDown", "AnyUp")

    local armor = CreateFrame("Button", nil, cFrame, "UIPanelButtonTemplate")
    armor:SetSize(32, 32)
    armor:SetPoint("LEFT", weapons, "RIGHT", 10, 0)
    armor:SetText("ARM")
    armor:SetScript("OnClick", function()
        Bagger.G.UpdateView(Enum.ItemClass.Armor)
    end)
    armor:RegisterForClicks("AnyDown", "AnyUp")
end

-- Sorting
function Bagger.G.BuildHeaderFrame(parent)
    local hFrame = CreateFrame("Frame", nil, parent)
    hFrame:SetSize(parent:GetWidth(), 32)
    hFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -64)

    hFrame.fields = {}

    local tex = hFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(hFrame)
    tex:SetColorTexture(0, 0, 0, 0.25)

    -- local stackCount = Bagger.G.BuildSortButton(hFrame, hFrame, "#", Bagger.Settings.Defaults.Columns.COUNT,
    -- Bagger.E.SORT_FIELDS.COUNT, true)

    -- rarity
    local icon = Bagger.G.BuildSortButton(hFrame, hFrame, "•", Bagger.Settings.Defaults.Columns.ICON,
    Bagger.E.SORT_FIELDS.ICON, true)

    local name = Bagger.G.BuildSortButton(hFrame, icon, "NAME", Bagger.Settings.Defaults.Columns.NAME,
    Bagger.E.SORT_FIELDS.NAME, false)

    local category = Bagger.G.BuildSortButton(hFrame, name, "CAT", Bagger.Settings.Defaults.Columns.CATEGORY,
    Bagger.E.SORT_FIELDS.CATEGORY, false)

    local ilvl = Bagger.G.BuildSortButton(hFrame, category, "ILVL", Bagger.Settings.Defaults.Columns.ILVL,
    Bagger.E.SORT_FIELDS.ILVL, false)

    local reqlvl = Bagger.G.BuildSortButton(hFrame, ilvl, "REQ", Bagger.Settings.Defaults.Columns.REQLVL,
    Bagger.E.SORT_FIELDS.REQLVL, false)

    local value = Bagger.G.BuildSortButton(hFrame, reqlvl, "VALUE", Bagger.Settings.Defaults.Columns.VALUE,
    Bagger.E.SORT_FIELDS.VALUE, false)

end

function Bagger.G.BuildSortButton(parent, anchor, name, width, sortField, initial)
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

    if Bagger.Settings.SortField.Sort == Bagger.E.SORT_ORDER.DESC then
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
            if sortOrder == Bagger.E.SORT_ORDER.ASC then
                sortOrder = Bagger.E.SORT_ORDER.DESC
            else
                sortOrder = Bagger.E.SORT_ORDER.ASC
            end
        end

        Bagger.SortItems(sortField, sortOrder)

        if Bagger.Settings.SortField.Sort ~= Bagger.E.SORT_ORDER.DESC then
            arrow:SetTexture("Interface\\Addons\\Bagger\\Media\\Arrow_Up")
        else
            arrow:SetTexture("Interface\\Addons\\Bagger\\Media\\Arrow_Down")
        end

        arrow:Show()
        text:SetTextColor(1, 1, 0)

        -- Remove other arrows
        for _, k in pairs(Bagger.E.SORT_FIELDS) do
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

-- TODO: Get this working
function Bagger.G.BuildHeaderAdjuster(parent, anchor)
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
Bagger.G.CreateBorder =  function(self)
    if not self.borders then
        self.borders = {}
        for i=1, 4 do
            self.borders[i] = self:CreateLine(nil, "BACKGROUND", nil, 0)
            local l = self.borders[i]
            l:SetThickness(1)
            l:SetColorTexture(0, 0, 0, 1)
            if i==1 then
                l:SetStartPoint("TOPLEFT")
                l:SetEndPoint("TOPRIGHT")
            elseif i==2 then
                l:SetStartPoint("TOPRIGHT")
                l:SetEndPoint("BOTTOMRIGHT")
            elseif i==3 then
                l:SetStartPoint("BOTTOMRIGHT")
                l:SetEndPoint("BOTTOMLEFT")
            else
                l:SetStartPoint("BOTTOMLEFT")
                l:SetEndPoint("TOPLEFT")
            end
        end
    end
end