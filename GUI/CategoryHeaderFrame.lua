local _, CB = ...

local LIST_ITEM_HEIGHT = 32
CB.G.CollapsedCategories = {} -- TODO: Generic

local ActiveHeaderFrames = {}
local InactiveHeaderFrames = {}


function CB.G.CleanupCategoryHeaderFrames(inventoryType)
    for i = 1, #ActiveHeaderFrames do
        if ActiveHeaderFrames[i] and ActiveHeaderFrames[i].inventory == inventoryType then
            ActiveHeaderFrames[i]:Hide()
            ActiveHeaderFrames[i]:SetParent(nil)
            tinsert(InactiveHeaderFrames, ActiveHeaderFrames[i])
            ActiveHeaderFrames[i] = nil
        end
    end
end

function CB.G.BuildCategoryFrame(categoryName, count, categoryType, index, inventoryType)
    local frame = FetchInactiveHeaderFrame(inventoryType)
    frame.inventory = inventoryType

    InsertActiveHeaderFrame(frame)

    if frame == nil then return end

    local parent
    if inventoryType == CB.E.InventoryType.Inventory then
        parent = CB.View.ListView
    elseif inventoryType == CB.E.InventoryType.Bank then
        parent = CB.BankView.ListView
    end

    frame:SetParent(parent)
    frame:SetPoint("TOP", 0, -((index - 1) * LIST_ITEM_HEIGHT))

    if CB.G.CollapsedCategories[categoryType] then
        frame.texture:SetVertexColor(1, 0, 0, 0.35)
    else
        frame.texture:SetVertexColor(1, 1, 0, 0.35)
    end

    frame.type:SetTexture(CB.U.GetCategoyIcon(categoryType))
    frame.name:SetText(categoryName .. " (" .. count .. ")")

    frame:SetScript("OnClick", function(self, button, down)
        if button == "LeftButton" then
            local isCollapsed = CB.G.CollapsedCategories[categoryType] and
                CB.G.CollapsedCategories[categoryType] == true
            if isCollapsed then
                CB.G.CollapsedCategories[categoryType] = false
            else
                CB.G.CollapsedCategories[categoryType] = true
            end
            CB.G.UpdateInventory()
        end
    end)

    frame:Show()
end

-- TODO: SetSize will eventually need to be set based on the View
function CreateCategoryHeaderPlaceholder()
    local f = CreateFrame("Button")
    f:SetSize(CB.View.ListView:GetWidth(), LIST_ITEM_HEIGHT)

    f:RegisterForClicks("LeftButtonUp")

    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(f)
    tex:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight")
    tex:SetVertexColor(1, 1, 0, 0.35)

    f:SetHighlightTexture("Interface\\Addons\\ConsoleBags\\Media\\Item_Highlight")

    f.texture = tex

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

function RemoveActiveHeaderFrame(index)
    ActiveHeaderFrames[index] = nil
end

function InsertActiveHeaderFrame(frame)
    tinsert(ActiveHeaderFrames, frame)
end

function InsertInactiveHeaderFrame(frame)
    tinsert(InactiveHeaderFrames, frame)
end

function FetchInactiveHeaderFrame(type)
    local frame = nil
    if InactiveHeaderFrames[1] and InactiveHeaderFrames[1].inventory == type then
        frame = InactiveHeaderFrames[1]
        tremove(InactiveHeaderFrames, 1)
    else
        frame = CreateCategoryHeaderPlaceholder()
    end
    return frame
end
