local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CoreGUI: AceModule
local coreGui = addon:NewModule('CoreGUI')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Inventory: AceModule
local inventory = addon:GetModule('Inventory')

---@class Bank: AceModule
local bank = addon:GetModule('Bank')

coreGui.Inventory = {}
coreGui.Bank = {}

function coreGui:OnInitialize()
    self.Inventory = inventory.View
    self.Bank = bank.View
end

function coreGui:UpdateCurrency()
    if self.Inventory and self.Inventory.Header then
        self.Inventory.Header.Gold:SetText(GetCoinTextureString(GetMoney()))
    end
end

function events:PLAYER_MONEY()
    coreGui:UpdateCurrency()
end

coreGui:Enable()