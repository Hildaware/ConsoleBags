local _, Bagger = ...
Bagger.U = {}

Bagger.U.GetItemClass = function(classId)
    for i, v in pairs(Enum.ItemClass) do
        if classId == v then return i end
    end
    return nil
end

Bagger.U.GetCategoyIcon = function(classId)
    local className = Bagger.U.GetItemClass(classId)
    local path = "Interface\\Addons\\Bagger\\Media\\Categories\\"

    -- Custom Categories
    if className == nil then
        for key, value in pairs(Bagger.E.CustomCategory) do
            if value == classId then
                className = key
                break
            end
        end
    end

    if className == nil then return nil end
    return path .. className
end

Bagger.U.IsEquipmentUnbound = function(item)
    if item.bound == true then return false end
    if not item.type then return false end

    if item.type == Enum.ItemClass.Armor or item.type == Enum.ItemClass.Weapon then
        return true
    end
    return false
end

Bagger.U.IsJewelry = function(item)
    if item.equipLocation == nil then return false end
    if item.equipLocation == Enum.InventoryType.IndexNeckType or item.equipLocation == Enum.InventoryType.IndexFingerType then
        return true
    end
    return false
end

Bagger.U.IsTrinket = function(item)
    if item.equipLocation == nil then return false end
    if item.equipLocation == Enum.InventoryType.IndexTrinketType then
        return true
    end
    return false
end

Bagger.U.CopyTable = function(table)
    local orig_type = type(table)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(table) do
            copy[orig_key] = orig_value
        end
    else
        copy = table
    end
    return copy
end

Bagger.U.BuildCategoriesTable = function()
    local t = Bagger.U.CopyTable(Bagger.E.Categories)
    for key, value in pairs(t) do
        value.items = {}
        value.count = 0
        value.key = key
        value.hasNew = false
    end
    return t
end

-- Bag Killing
local killableFramesParent = CreateFrame("FRAME", nil, UIParent)
killableFramesParent:SetAllPoints()
killableFramesParent:Hide()
local function MakeFrameKillable(frame)
    frame:SetParent(killableFramesParent)
end
local killedFramesParent = CreateFrame("FRAME", nil, UIParent)
killedFramesParent:SetAllPoints()
killedFramesParent:Hide()
local function KillFramePermanently(frame)
    frame:SetParent(killedFramesParent)
end

-- TODO: After bank frame is complete, handle this
function Bagger.U.MakeBlizzBagsKillable()
    if _G["ElvUI_ContainerFrame"] then
        MakeFrameKillable(_G["ElvUI_ContainerFrame"])
        -- MakeFrameKillable(_G["ElvUI_BankContainerFrame"])
        -- Get rid of blizz bags permanently, since they are replaced by ElvUI
        if _G["ContainerFrameCombinedBags"] then
            KillFramePermanently(_G["ContainerFrameCombinedBags"])
        end
        for i = 1, NUM_CONTAINER_FRAMES do
            KillFramePermanently(_G["ContainerFrame" .. i])
        end
        -- KillFramePermanently(_G["BankFrame"])
    else
        if _G["ContainerFrameCombinedBags"] then
            MakeFrameKillable(_G["ContainerFrameCombinedBags"])
        end
        for i = 1, NUM_CONTAINER_FRAMES do
            MakeFrameKillable(_G["ContainerFrame" .. i])
        end
        -- MakeFrameKillable(_G["BankFrame"])
    end
    if _G["GwBagFrame"] then
        -- MakeFrameKillable(_G["GwBagFrame"])
        -- MakeFrameKillable(_G["GwBankFrame"])
    end
end

function Bagger.U.KillBlizzBags()
    killableFramesParent:Hide()
end
