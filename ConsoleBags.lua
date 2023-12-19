local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
---@cast addon +AceHook-3.0

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Items: AceModule
local items = addon:GetModule('Items')

---@class View: AceModule
local view = addon:GetModule('View')


---@class ItemFrame: AceModule
local itemFrame = addon:GetModule('ItemFrame')

local backpackShouldOpen = false
local backpackShouldClose = false
local bankShouldOpen = false

local playerIdentifier = ''

function addon:OnInitialize()
    -- Build player data
    local playerId = UnitGUID('player')
    local playerName = UnitName('player')

    if playerId == nil or playerName == nil then return end
    playerIdentifier = playerId

    -- CB.Data.Characters[playerId] = {
    --     Name = playerName
    -- }
end

function addon:OnEnable()
    local eventFrame = CreateFrame('frame')
    eventFrame:SetScript('OnUpdate', self.OnUpdate)

    self:SecureHook('OpenBackpack')
    self:SecureHook('OpenAllBags')
    self:SecureHook('CloseBackpack')
    self:SecureHook('CloseAllBags')
    self:SecureHook('ToggleBackpack')
    self:SecureHook('ToggleAllBags')
    self:SecureHook('ToggleBag')
end

function addon.OnUpdate()
    if backpackShouldOpen then
        if session.Settings.HideBags == true then return end

        if not session.BuildingCache then
            items.BuildItemCache()
        end

        if session.InventoryResolved >= session.InventoryCount then
            backpackShouldOpen = false
            backpackShouldClose = false

            view:Update(enums.InventoryType.Inventory)

            PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
            view.inventory.frame:Show()
        end
    elseif backpackShouldClose then
        backpackShouldClose = false

        PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
        view.inventory.frame:Hide()

        local bankFrame = view.bank and view.bank.frame:IsShown()
        if bankFrame then
            view.bank.frame:Hide()
        end
    end

    if bankShouldOpen then
        if not session.BuildingBankCache then
            items.BuildBankCache()
        end

        if session.BankResolved >= session.BankCount then
            bankShouldOpen = false

            view:Update(enums.InventoryType.Bank)
            view.bank.frame:Show()
        end
    end
end

function addon:OpenAllBags()
    backpackShouldOpen = true
end

function addon:CloseAllBags()
    backpackShouldClose = true
end

function addon:CloseBackpack()
    backpackShouldClose = true
end

function addon:OpenBackpack()
    backpackShouldOpen = true
end

function addon:ToggleBag()
    if view.inventory.frame:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end
end

function addon:ToggleAllBags()
    if view.inventory.frame:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end
end

function addon:ToggleBackpack()
    if view.inventory.frame:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end
end

function addon:OpenBank()
    if view.bank == nil then
        view:Create(enums.InventoryType.Bank)
    end

    if not view.bank.frame:IsShown() then
        bankShouldOpen = true
    end
end

function addon:CloseBank()
    if view.bank.frame:IsShown() then
        view.bank.frame:Hide()
    end
end

if _G["Scrap"] then
    local original = _G["Scrap"].ToggleJunk
    _G["Scrap"].ToggleJunk = function(self, id)
        original(self, id)
        itemFrame:Refresh(id)
    end
end
