local _, CB = ...

local LIST_ITEM_HEIGHT = 32
CB.G.CollapsedCategories = {} -- TODO: Generic

function CB.G.BuildCategoryFrame(data, offset, frame, parent)
    if frame == nil then return end

    frame:SetParent(parent)
    frame:SetPoint("TOP", 0, -((offset - 1) * LIST_ITEM_HEIGHT))

    if CB.G.CollapsedCategories[data.key] then
        frame:GetNormalTexture():SetVertexColor(1, 0, 0, 0.35)
    else
        frame:GetNormalTexture():SetVertexColor(1, 1, 0, 0.35)
    end

    frame.type:SetTexture(CB.U.GetCategoyIcon(data.key))
    frame.name:SetText(data.name .. " (" .. data.count .. ")")

    frame:SetScript("OnClick", function(self, button, down)
        if button == "LeftButton" then
            local isCollapsed = CB.G.CollapsedCategories[data.key] and
                CB.G.CollapsedCategories[data.key] == true
            if isCollapsed then
                CB.G.CollapsedCategories[data.key] = false
            else
                CB.G.CollapsedCategories[data.key] = true
            end
            CB.G.UpdateInventory()
        end
    end)

    frame:Show()
end

-- TODO: SetSize will eventually need to be set based on the View
function CB.G.CreateCategoryHeaderPlaceholder()
    local f = CreateFrame("Button")
    f:SetSize(CB.View.ListView:GetWidth(), LIST_ITEM_HEIGHT)

    f:RegisterForClicks("LeftButtonUp")

    f:SetNormalTexture("Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight")
    f:GetNormalTexture():SetVertexColor(1, 1, 0, 0.35)
    f:SetHighlightTexture("Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight")

    -- type
    local type = CreateFrame("Frame", nil, f)
    type:SetPoint("LEFT", f, "LEFT", 8, 0)
    type:SetHeight(LIST_ITEM_HEIGHT)
    type:SetWidth(32)

    local typeTex = type:CreateTexture(nil, "ARTWORK")
    typeTex:SetPoint("CENTER", type, "CENTER")
    typeTex:SetSize(24, 24)

    f.type = typeTex

    -- Name
    local name = CreateFrame("Frame", nil, f)
    name:SetPoint("LEFT", type, "RIGHT", 8, 0)
    name:SetHeight(LIST_ITEM_HEIGHT)
    name:SetWidth(300)
    local nameText = name:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameText:SetAllPoints(name)
    nameText:SetJustifyH("LEFT")

    f.name = nameText

    f.isHeader = true

    return f
end
