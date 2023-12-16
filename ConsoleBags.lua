local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Items: AceModule
local items = addon:GetModule('Items')

---@class Inventory: AceModule
local inventory = addon:GetModule('Inventory')

---@class Bank: AceModule
local bank = addon:GetModule('Bank')

---@class CoreGUI: AceModule
local coreGui = addon:GetModule('CoreGUI')

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

            inventory:Update()

            PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
            coreGui.Inventory:Show()
        end
    elseif backpackShouldClose then
        backpackShouldClose = false

        PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
        coreGui.Inventory:Hide()

        local bankFrame = coreGui.Bank and coreGui.Bank:IsShown()
        if bankFrame then
            coreGui.Bank:Hide()
        end
    end

    if bankShouldOpen then
        if not session.BuildingBankCache then
            items.BuildBankCache()
        end

        if session.BankResolved >= session.BankCount then
            bankShouldOpen = false

            bank:Update()
            coreGui.Bank:Show()
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
    if coreGui.Inventory:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end
end

function addon:ToggleAllBags()
    if coreGui.Inventory:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end
end

function addon:ToggleBackpack()
    if coreGui.Inventory:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end
end

function addon:OpenBank()
    if not coreGui.Bank:IsShown() then
        bankShouldOpen = true
    end
end

function addon:CloseBank()
    if coreGui.Bank:IsShown() then
        coreGui.Bank:Hide()
    end
end
