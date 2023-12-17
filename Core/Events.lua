local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Events: AceModule
local events = addon:NewModule('Events', 'AceEvent-3.0')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

function events:OnInitialize()
    events:RegisterEvent('PLAYER_ENTERING_WORLD')
    events:RegisterEvent('BAG_UPDATE_DELAYED')
    events:RegisterEvent('EQUIPMENT_SETS_CHANGED')
    events:RegisterEvent('PLAYER_MONEY')
    events:RegisterEvent('BANKFRAME_OPENED')
    events:RegisterEvent('BANKFRAME_CLOSED')
    events:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
    events:RegisterEvent('PLAYER_REGEN_DISABLED')
    events:RegisterEvent('PLAYER_REGEN_ENABLED')
end

function events:PLAYER_ENTERING_WORLD()
    utils.CreateEnableBagButtons()
    utils.BagDestroyer()
    utils.DestroyDefaultBags()
end

events:Enable()