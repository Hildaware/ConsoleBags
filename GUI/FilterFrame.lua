local _, Bagger = ...

local LIST_ITEM_HEIGHT = 32
local InactiveFilterFrames = {}
local ActiveFilterFrames = {}

function Bagger.G.CleanupFilterFrames()
    if type == nil then
        for i = 1, #ActiveFilterFrames do
            ActiveFilterFrames[i]:Hide()
            ActiveFilterFrames[i]:SetParent(nil)
            tinsert(InactiveFilterFrames, ActiveFilterFrames[i])
            ActiveFilterFrames[i] = nil
        end
    end
end

function Bagger.G.BuildFilterButton(categoryType, index)
    local f = FetchInactiveFilterFrame()
    InsertActiveFilterFrame(f)

    f:SetParent(Bagger.View.FilterFrame)
    f:SetPoint("TOP", 0, -(index * (LIST_ITEM_HEIGHT + 4)))

    f.texture:SetTexture(Bagger.U.GetCategoyIcon(categoryType))

    f:SetScript("OnClick", function()
        Bagger.G.UpdateView(categoryType)
    end)
    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")
end

function CreateFilterButtonPlaceholder()
    local f = CreateFrame("Button")
    f:SetSize(32, 32)

    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("CENTER", 0, "CENTER")
    tex:SetSize(24, 24)

    f.texture = tex
    f:RegisterForClicks("AnyDown")
    f:RegisterForClicks("AnyUp")

    return f
end

function RemoveActiveFilterFrame(index)
    ActiveFilterFrames[index] = nil
end

function InsertActiveFilterFrame(frame)
    tinsert(ActiveFilterFrames, frame)
end

function InsertInactiveFilterFrame(frame)
    tinsert(InactiveFilterFrames, frame)
end

function FetchInactiveFilterFrame()
    local frame = nil
    if InactiveFilterFrames[1] then
        frame = InactiveFilterFrames[1]
        tremove(InactiveFilterFrames, 1)
    else
        frame = CreateFilterButtonPlaceholder()
    end
    return frame
end
