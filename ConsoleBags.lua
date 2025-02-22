local addonName = ...

---@class ConsoleBags: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
---@cast addon +AceHook-3.0

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Items: AceModule
local items = addon:GetModule('Items')

---@class View: AceModule
local view = addon:GetModule('View')

---@class ItemFrame: AceModule
local itemFrame = addon:GetModule('ItemFrame')

---@class ConsoleBagsStatus
---@field backpackShouldOpen boolean
---@field backpackShouldClose boolean
---@field visitingBank boolean
---@field visitingWarbank boolean
addon.status = {}

---@class Bags
---@field Inventory BagView
---@field Bank BagView
---@field FocusedNode Enums.InventoryType?
addon.bags = {}

function addon:OnInitialize()
    addon.status = {
        backpackShouldOpen = false,
        backpackShouldClose = false,
        visitingBank = false,
        visitingWarbank = false
    }

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
    addon.bags.FocusedNode = nil

    table.insert(UISpecialFrames, addon.bags.Inventory:GetName())
    table.insert(UISpecialFrames, addon.bags.Bank:GetName())

    self:SecureHook('ToggleAllBags')
    self:SecureHook('CloseSpecialWindows')
    self:SecureHook('OpenAllBags')
    self:SecureHook('CloseAllBags')

    -- Triggers when currency is Watch toggled
    self:SecureHook(TokenFrame, 'SetTokenWatched', addon.UpdateCurrencyTracking)

    ---@diagnostic disable-next-line: undefined-field
    events:RegisterEvent('BANKFRAME_OPENED', function()
        addon.status.visitingBank = true
        events:Send('ConsoleBagsBankToggle')
    end)

    ---@diagnostic disable-next-line: undefined-field
    events:RegisterEvent('BANKFRAME_CLOSED', function()
        addon.status.visitingBank = false
        events:Send('ConsoleBagsBankToggle')
    end)

    events:Register('ConsoleBagsBankToggle', addon.OnBankUpdate)
    events:Register('ConsoleBagsToggle', addon.OnUpdate)
end

function addon.OnBankUpdate()
    if not addon.status.visitingBank then
        addon.bags.Bank:Hide()

        addon.bags.Bank.widget.Header.Additions:SetAsBank()

        if addon.bags.Inventory:IsShown() then
            addon:ToggleAllBags()
        end

        return
    end

    if addon.bags.Bank:IsShown() then return end

    if session.Settings.HideBags == true then return end

    items.GetEquipmentSetData()

    if not session.BuildingBankCache then
        items.BuildBankCache()
    end

    if not addon.bags.Inventory:IsShown() then
        addon:ToggleAllBags()
    end

    if session.Bank.Resolved >= session.Bank.TotalCount then
        addon.bags.Bank:Update()
        addon.bags.Bank:Show()

        items.BuildWarbankCache()
    else
        C_Timer.After(0.1, addon.OnBankUpdate)
    end
end

function addon.OnUpdate()
    if addon.status.backpackShouldOpen then
        if session.Settings.HideBags == true then return end

        items.GetEquipmentSetData()

        if not session.BuildingCache then
            items.BuildItemCache()
        end

        if session.Inventory.Resolved >= session.Inventory.TotalCount then
            addon.status.backpackShouldOpen = false
            addon.status.backpackShouldClose = false

            addon.bags.Inventory:UpdateCurrency()
            addon.bags.Inventory:UpdateMoney()
            addon.bags.Inventory:Update()

            PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
            addon.bags.Inventory:Show()
        end
    elseif addon.status.backpackShouldClose then
        addon.status.backpackShouldClose = false

        PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
        addon.bags.Inventory:Hide()

        addon:CloseBank()
    end
end

function addon:ToggleAllBags()
    if addon.bags.Inventory:IsShown() then
        addon.status.backpackShouldClose = true
    else
        addon.status.backpackShouldOpen = true
    end

    events:Send('ConsoleBagsToggle')
end

function addon:OpenAllBags()
    if addon.bags.Inventory:IsShown() then return end
    addon.status.backpackShouldOpen = true

    events:Send('ConsoleBagsToggle')
end

function addon:CloseAllBags()
    if not addon.bags.Inventory:IsShown() then return end
    addon.status.backpackShouldClose = true

    events:Send('ConsoleBagsToggle')
end

function addon:CloseSpecialWindows()
    addon.status.backpackShouldClose = true
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

function addon:UpdateCurrencyTracking()
    addon.bags.Inventory:UpdateCurrency()
end

--#region Events

function events:PLAYER_MONEY()
    addon.bags.Inventory:UpdateMoney()
end

function events:ACCOUNT_MONEY()
    addon.bags.Bank:UpdateMoney()
end

function events:BAG_CONTAINER_UPDATE()
    items.BuildItemCache()
    if addon.bags.Inventory and addon.bags.Inventory:IsShown() then
        addon.bags.Inventory:Update()
    end
end

---@param bagId number
function events:BAG_UPDATE(_, bagId)
    local bagType = utils:GetBagType(bagId)
    if bagType == nil then
        return
    end

    local sessionData = items:UpdateBag(bagId, bagType)
    if sessionData.Resolved < sessionData.TotalCount then
        return
    end

    local bag = bagType == enums.InventoryType.Inventory and
        addon.bags.Inventory or addon.bags.Bank

    if bag and bag:IsShown() then
        items.BuildItemCache()
        bag:Update()
    end
end

function events:PLAYERBANKSLOTS_CHANGED()
    items.BuildBankCache()
    addon.bags.Bank:Update()
    items.BuildItemCache()
    addon.bags.Inventory:Update()
end

function events:PLAYERBANKBAGSLOTS_CHANGED()
    items.BuildBankCache()
    addon.bags.Bank:Update()
    items.BuildItemCache()
    addon.bags.Inventory:Update()
end

function events:EQUIPMENT_SETS_CHANGED()
    session.ShouldBuildEquipmentSetCache = true
    items.GetEquipmentSetData()
    if addon.bags.Inventory and addon.bags.Inventory:IsShown() then
        items.BuildItemCache()
        addon.bags.Inventory:Update()
    end
end

function events:PLAYER_REGEN_DISABLED()
    if _G['ConsolePortInputHandler'] then
        _G['ConsolePortInputHandler']:Release(addon.bags.Inventory)
    end
end

function events:PLAYERREAGENTBANKSLOTS_CHANGED()
    items.BuildBankCache()
    addon.bags.Bank:Update()
end

function events:CURRENCY_DISPLAY_UPDATE(_, currencyId, newValue)
    if not addon.bags.Inventory then return end
    addon.bags.Inventory:UpdateCurrency(currencyId, newValue)
end

--#endregion

if _G['Scrap'] then
    local original = _G['Scrap'].ToggleJunk
    ---@param self any
    ---@param id number
    _G['Scrap'].ToggleJunk = function(self, id)
        original(self, id)

        for _, iFrame in pairs(addon.bags.Inventory.items) do
            if iFrame.itemId == id then
                iFrame:Update()
            end
        end
    end
end
