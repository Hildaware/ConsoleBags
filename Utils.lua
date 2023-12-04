local _, Bagger = ...
Bagger.U = {}

Bagger.U.GetItemClass = function(classId)
    for i,v in pairs(Enum.ItemClass) do
        if classId == v then return i end
    end
    return nil
end

Bagger.U.GetCategoyIcon = function(classId)
    local className = Bagger.U.GetItemClass(classId)
    local path = "Interface\\Addons\\Bagger\\Media\\Categories\\"

    if className == nil then return nil end
    return path .. className
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

function Bagger.U.MakeBlizzBagsKillable()
    if _G["ElvUI_ContainerFrame"] then
        MakeFrameKillable(_G["ElvUI_ContainerFrame"])
        MakeFrameKillable(_G["ElvUI_BankContainerFrame"])
        -- Get rid of blizz bags permanently, since they are replaced by ElvUI
        if _G["ContainerFrameCombinedBags"] then
            KillFramePermanently(_G["ContainerFrameCombinedBags"])
        end
        for i = 1, NUM_CONTAINER_FRAMES do
            KillFramePermanently(_G["ContainerFrame"..i])
        end
        KillFramePermanently(_G["BankFrame"])
    else
        if _G["ContainerFrameCombinedBags"] then
            MakeFrameKillable(_G["ContainerFrameCombinedBags"])
        end
        for i = 1, NUM_CONTAINER_FRAMES do
            MakeFrameKillable(_G["ContainerFrame"..i])
        end
        MakeFrameKillable(_G["BankFrame"])
    end
    if _G["GwBagFrame"] then
        MakeFrameKillable(_G["GwBagFrame"])
        MakeFrameKillable(_G["GwBankFrame"])
    end
end

function Bagger.U.KillBlizzBags()
    killableFramesParent:Hide()
end