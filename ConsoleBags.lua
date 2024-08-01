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

    table.insert(UISpecialFrames, addon.bags.Inventory:GetName())
    table.insert(UISpecialFrames, addon.bags.Bank:GetName())

    self:SecureHook('ToggleAllBags')
    self:SecureHook('CloseSpecialWindows')

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
    if addon.status.backpackShouldOpen then
        if session.Settings.HideBags == true then return end

        if not session.BuildingCache then
            items.BuildItemCache()
        end

        if session.Inventory.Resolved >= session.Inventory.TotalCount then
            addon.status.backpackShouldOpen = false
            addon.status.backpackShouldClose = false

            addon.bags.Inventory:UpdateCurrency()
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

---@param bagId number
function events:BAG_UPDATE(_, bagId)
    items.BuildItemCache(bagId)
    if addon.bags.Inventory and addon.bags.Inventory:IsShown() then
        addon.bags.Inventory:Update()
    end
end

function events:PLAYERBANKSLOTS_CHANGED()
    items.BuildBankCache()
    addon.bags.Bank:Update()
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

function events:PLAYERREAGENTBANKSLOTS_CHANGED()
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
