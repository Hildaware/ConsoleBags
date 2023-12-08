local _, CB = ...
CB.U = {}

CB.U.GetItemClass = function(classId)
    for i, v in pairs(Enum.ItemClass) do
        if classId == v then return i end
    end
    return nil
end

CB.U.GetCategoyIcon = function(classId)
    local className = CB.U.GetItemClass(classId)
    local path = "Interface\\Addons\\ConsoleBags\\Media\\Categories\\"

    -- Custom Categories
    if className == nil then
        for key, value in pairs(CB.E.CustomCategory) do
            if value == classId then
                className = key
                break
            end
        end
    end

    if className == nil then return nil end
    return path .. className
end

CB.U.IsEquipmentUnbound = function(item)
    if item.bound == true then return false end
    if not item.type then return false end

    if item.type == Enum.ItemClass.Armor or item.type == Enum.ItemClass.Weapon then
        return true
    end
    return false
end

CB.U.IsJewelry = function(item)
    if item.equipLocation == nil then return false end
    if item.equipLocation == Enum.InventoryType.IndexNeckType or item.equipLocation == Enum.InventoryType.IndexFingerType then
        return true
    end
    return false
end

CB.U.IsTrinket = function(item)
    if item.equipLocation == nil then return false end
    if item.equipLocation == Enum.InventoryType.IndexTrinketType then
        return true
    end
    return false
end

CB.U.CopyTable = function(table)
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

CB.U.BuildCategoriesTable = function()
    local t = CB.U.CopyTable(CB.E.Categories)
    for key, value in pairs(t) do
        value.items = {}
        value.count = 0
        value.key = key
        value.hasNew = false
    end
    return t
end

CB.U.BuildBankCategoriesTable = function()
    local t = CB.U.CopyTable(CB.E.Categories)
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

local function CreateEnableBagButton(parent)
    if parent.ClickableTitleFrame then
        parent.ClickableTitleFrame:Hide()
    end
    if parent.TitleContainer then
        parent.TitleContainer:Hide()
    end

    local button = CreateFrame("Button", nil, parent)
    button:SetFrameLevel(parent:GetFrameLevel() + 420)
    button.text = button:CreateTexture()
    button.text:SetPoint("CENTER", 4, -1)
    button.text:SetSize(20, 20)
    -- button.text:SetTexCoord(0, 0.75, 0, 1)
    button.text:SetTexture("Interface\\Addons\\ConsoleBags\\Media\\Logo_Normal")
    button:SetSize(24, 24)
    button:HookScript("OnMouseDown", function(self)
        self.text:SetPoint("CENTER", 3, -2)
        self.text:SetAlpha(0.75)
    end)
    button:HookScript("OnMouseUp", function(self)
        self.text:SetPoint("CENTER", 4, -1)
        self.text:SetAlpha(1)
    end)
    button:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("Back to ConsoleBags", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    button:HookScript("OnClick", function(self)
        CB.U.DestroyDefaultBags()
        CloseAllBags()
        OpenAllBags()
    end)
    return button
end

function CB.U.CreateEnableBagButtons()
    local f = _G["ContainerFrame1"]
    f.CB = CreateEnableBagButton(f)
    if _G["ContainerFrameCombinedBags"] then
        f = _G["ContainerFrameCombinedBags"]
        f.CB = CreateEnableBagButton(f)
        f.CB:SetPoint("TOPRIGHT", -22, -1)
        f.CB:SetHeight(20)
    end

    if _G["ElvUI_ContainerFrame"] then
        f = _G["ElvUI_ContainerFrame"]
        f.CB = CreateEnableBagButton(f)
        f.CB:SetPoint("TOPLEFT", 2, -2)
        f.CB:SetSize(22, 22)
    end
end

-- TODO: After Guild Bank frame is complete, handle this
function CB.U.BagDestroyer()
    if _G["ElvUI_ContainerFrame"] then
        MakeFrameKillable(_G["ElvUI_ContainerFrame"])
        MakeFrameKillable(_G["ElvUI_BankContainerFrame"])
        -- Get rid of blizz bags permanently, since they are replaced by ElvUI
        if _G["ContainerFrameCombinedBags"] then
            KillFramePermanently(_G["ContainerFrameCombinedBags"])
        end
        for i = 1, NUM_CONTAINER_FRAMES do
            KillFramePermanently(_G["ContainerFrame" .. i])
        end
        KillFramePermanently(_G["BankFrame"])
    else
        if _G["ContainerFrameCombinedBags"] then
            MakeFrameKillable(_G["ContainerFrameCombinedBags"])
        end
        for i = 1, NUM_CONTAINER_FRAMES do
            MakeFrameKillable(_G["ContainerFrame" .. i])
        end
        MakeFrameKillable(_G["BankFrame"])
    end
    if _G["GwBagFrame"] then
        -- MakeFrameKillable(_G["GwBagFrame"])
        -- MakeFrameKillable(_G["GwBankFrame"])
    end
end

function CB.U.DestroyDefaultBags()
    CB.Settings.HideBags = false
    killableFramesParent:Hide()
end

function CB.U.RestoreDefaultBags()
    killableFramesParent:Show()
    CB.Settings.HideBags = true
end
