local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Session: AceModule
local session = addon:NewModule('Session')

function session:OnInitialize()
    self.Items = {}
    self.FramesByItemId = {}

    self.Inventory = {
        TotalCount = 0,
        Count = 0,
        ReagentCount = 0,
        Resolved = 0
    }

    self.Bank = {
        TotalCount = 0,
        Count = 0,
        ReagentCount = 0,
        Resolved = 0
    }

    self.InventoryFilter = nil
    self.BankFilter = nil

    self.BuildingCache = false
    self.BuildingBankCache = false

    self.InventoryCollapsedCategories = {}
    self.BankCollapsedCategories = {}

    self.Settings = {
        Defaults = {
            Columns = {
                Icon = 32,
                Name = 320, -- was 280 before removing cats
                Category = 40,
                Ilvl = 50,
                ReqLvl = 50,
                Value = 110
            },
            Sections = {
                Header = 40,
                Filters = 40,
                ListViewHeader = 40,
                ListItemHeight = 40,
                Footer = 32
            }
        },
        HideBags = false
    }
end

session:Enable()
