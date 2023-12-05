local _, Bagger = ...

local LIST_ITEM_HEIGHT = 32
Bagger.G.CollapsedCategories = {}

local ActiveHeaderFrames = {}
local InactiveHeaderFrames = {}


function Bagger.G.CleanupCategoryHeaderFrames()
    for i = 1, #ActiveHeaderFrames do
        if ActiveHeaderFrames[i] and ActiveHeaderFrames[i].isHeader then
            ActiveHeaderFrames[i]:Hide()
            ActiveHeaderFrames[i]:SetParent(nil)
            tinsert(InactiveHeaderFrames, ActiveHeaderFrames[i])
            ActiveHeaderFrames[i] = nil
        end
    end
end

function Bagger.G.BuildCategoryFrame(categoryName, count, categoryType, index)
    local frame = FetchInactiveHeaderFrame()
    InsertActiveHeaderFrame(frame)

    if frame == nil then return end

    frame:SetParent(Bagger.View.ListView)
    frame:SetPoint("TOP", 0, -((index - 1) * LIST_ITEM_HEIGHT))

    frame.type:SetTexture(Bagger.U.GetCategoyIcon(categoryType))
    frame.name:SetText(categoryName .. " (" .. count .. ")")

    frame:SetScript("OnClick", function(self, button, down)
        if button == "LeftButton" then
            local isCollapsed = Bagger.G.CollapsedCategories[categoryType] and
                Bagger.G.CollapsedCategories[categoryType] == true
            if isCollapsed then
                Bagger.G.CollapsedCategories[categoryType] = false
            else
                Bagger.G.CollapsedCategories[categoryType] = true
            end
            Bagger.G.UpdateView()
        end
    end)

    frame:Show()
end

function CreateCategoryHeaderPlaceholder()
    local f = CreateFrame("Button")
    f:SetSize(Bagger.View.ListView:GetWidth(), LIST_ITEM_HEIGHT)

    f:RegisterForClicks("LeftButtonUp")

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

function FetchInactiveHeaderFrame()
    local frame = nil
    if InactiveHeaderFrames[1] then
        frame = InactiveHeaderFrames[1]
        tremove(InactiveHeaderFrames, 1)
    else
        frame = CreateCategoryHeaderPlaceholder()
    end
    return frame
end
