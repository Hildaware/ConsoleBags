local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
---@cast addon +AceHook-3.0

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Items: AceModule
local items = addon:GetModule('Items')

---@class View: AceModule
local view = addon:GetModule('View')


---@class ItemFrame: AceModule
local itemFrame = addon:GetModule('ItemFrame')

local backpackShouldOpen = false
local backpackShouldClose = false
local visitingBank = false

---@class ConsoleBags
---@field Inventory BagView
---@field Bank BagView
addon.bags = {}

function addon:OnInitialize()
    local frame = CreateFrame('Frame')
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("UPDATE_BINDINGS")
    frame:SetScript("OnEvent", function()
        ClearOverrideBindings(frame)
        local bindings = {
            "TOGGLEBACKPACK",
            "TOGGLEREAGENTBAG",
            "TOGGLEBAG1",
            "TOGGLEBAG2",
            "TOGGLEBAG3",
            "TOGGLEBAG4",
            "OPENALLBAGS"
        }
        for _, binding in pairs(bindings) do
            local key, otherkey = GetBindingKey(binding)
            if key ~= nil then
                SetOverrideBinding(frame, true, key, function() addon:ToggleAllBags() end)
            end
            if otherkey ~= nil then
                SetOverrideBinding(frame, true, otherkey, function() addon:ToggleAllBags() end)
            end
        end
    end)
end

function addon:OnEnable()
    addon.bags.Inventory = view:Create(enums.InventoryType.Inventory)
    addon.bags.Bank = view:Create(enums.InventoryType.Bank)

    self:SecureHook('ToggleAllBags')
    self:SecureHook('CloseSpecialWindows')

    ---@diagnostic disable-next-line: undefined-field
    events:RegisterEvent('BANKFRAME_OPENED', function()
        visitingBank = true
        events:Send('ConsoleBagsBankToggle')
    end)

    ---@diagnostic disable-next-line: undefined-field
    events:RegisterEvent('BANKFRAME_CLOSED', function()
        visitingBank = false
        events:Send('ConsoleBagsBankToggle')
    end)

    events:Register('ConsoleBagsBankToggle', addon.OnBankUpdate)
    events:Register('ConsoleBagsToggle', addon.OnUpdate)
end

function addon.OnBankUpdate()
    if not visitingBank then
        addon.bags.Bank:Hide()

        if addon.bags.Inventory:IsShown() then
            addon:ToggleAllBags()
        end

        return
    end

    if addon.bags.Bank:IsShown() then return end

    if session.Settings.HideBags == true then return end

    if not addon.bags.Inventory:IsShown() then
        addon:ToggleAllBags()
    end

    if not session.BuildingBankCache then
        items.BuildBankCache()
    end

    if session.Bank.Resolved >= session.Bank.TotalCount then
        addon.bags.Bank:Update()
        addon.bags.Bank:Show()
    end
end

function addon.OnUpdate()
    if backpackShouldOpen then
        if session.Settings.HideBags == true then return end

        if not session.BuildingCache then
            items.BuildItemCache()
        end

        if session.Inventory.Resolved >= session.Inventory.TotalCount then
            backpackShouldOpen = false
            backpackShouldClose = false

            addon.bags.Inventory:UpdateCurrency()
            addon.bags.Inventory:Update()

            PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
            addon.bags.Inventory:Show()
        end
    elseif backpackShouldClose then
        backpackShouldClose = false

        PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
        addon.bags.Inventory:Hide()

        addon:CloseBank()
    end
end

function addon:ToggleAllBags()
    if addon.bags.Inventory:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end

    events:Send('ConsoleBagsToggle')
end

function addon:CloseSpecialWindows()
    backpackShouldClose = true
    addon.bags.Bank:Hide()
    if C_Bank then
        C_Bank.CloseBankFrame()
    else
        CloseBankFrame()
    end
end

function addon:CloseBank()
    addon:CloseSpecialWindows()
end

--#region Events

function events:PLAYER_MONEY()
    addon.bags.Inventory:UpdateCurrency()
end

function events:BAG_CONTAINER_UPDATE()
    items.BuildItemCache()
    if addon.bags.Inventory and addon.bags.Inventory:IsShown() then
        addon.bags.Inventory:Update()
    end
end

function events:EQUIPMENT_SETS_CHANGED()
    items.BuildItemCache()
    if addon.bags.Inventory and addon.bags.Inventory:IsShown() then
        addon.bags.Inventory:Update()
    end
end

function events:PLAYER_REGEN_DISABLED()
    if _G['ConsolePortInputHandler'] then
        _G['ConsolePortInputHandler']:Release(addon.bags.Inventory)
    end
end

function events:PLAYERBANKBAGSLOTS_CHANGED()
    items.BuildBankCache()
    addon.bags.Bank:Update()
end

--#endregion

if _G['Scrap'] then
    local original = _G['Scrap'].ToggleJunk
    _G['Scrap'].ToggleJunk = function(self, id)
        original(self, id)
        -- Fetch the itemFrame we require (how da fuq)
        itemFrame:Refresh(id)
    end
end
