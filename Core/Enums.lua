local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Enums: AceModule
local enums = addon:NewModule('Enums')

---@enum Enums.PlayerInventoryBagIndex
enums.PlayerInventoryBagIndex = {
    [Enum.BagIndex.Backpack] = Enum.BagIndex.Backpack,
    [Enum.BagIndex.Bag_1] = Enum.BagIndex.Bag_1,
    [Enum.BagIndex.Bag_2] = Enum.BagIndex.Bag_2,
    [Enum.BagIndex.Bag_3] = Enum.BagIndex.Bag_3,
    [Enum.BagIndex.Bag_4] = Enum.BagIndex.Bag_4,
    [Enum.BagIndex.ReagentBag] = Enum.BagIndex.ReagentBag
}

---@enum Enums.WarbankBagIndex
enums.WarbankBagIndex = {
    [Enum.BagIndex.AccountBankTab_1] = Enum.BagIndex.AccountBankTab_1,
    [Enum.BagIndex.AccountBankTab_2] = Enum.BagIndex.AccountBankTab_2,
    [Enum.BagIndex.AccountBankTab_3] = Enum.BagIndex.AccountBankTab_3,
    [Enum.BagIndex.AccountBankTab_4] = Enum.BagIndex.AccountBankTab_4,
    [Enum.BagIndex.AccountBankTab_5] = Enum.BagIndex.AccountBankTab_5
}

---@enum Enums.InventoryType
enums.InventoryType = {
    Inventory = 1,
    Bank = 2,
    GuildBank = 3,
    Shared = 4
}

---@enum Enums.BankType
enums.BankType = {
    Bank = 1,
    ReagentBank = 2,
    Warbank = 3
}

enums.SortOrder = {
    Asc = 1,
    Desc = 2,
}

enums.SortFields = {
    Icon = 2,
    Name = 3,
    -- Category = 4,
    Ilvl = 5,
    ReqLvl = 6,
    Value = 7
}

enums.FilterFields = {
    All = 1,
    Weapons = 2,
    Armor = 3
}

enums.CustomCategory = {
    BindOnAccount = 99,
    BindOnEquip = 98,
    Jewelry = 97,
    Trinket = 96,
    Warbound = 95
}

---@class HildaCategory
---@field order number
---@field name string

---@type table<number, HildaCategory>
enums.Categories = {
    [enums.CustomCategory.BindOnAccount] = { order = 1, name = 'Bind On Account' },
    [enums.CustomCategory.Warbound] = { order = 2, name = 'Warbound' },
    [enums.CustomCategory.BindOnEquip] = { order = 3, name = 'Bind On Equip' },
    [Enum.ItemClass.Weapon] = { order = 4, name = 'Weapons' },
    [Enum.ItemClass.Armor] = { order = 5, name = 'Armor' },
    [enums.CustomCategory.Jewelry] = { order = 6, name = 'Jewelry' },
    [enums.CustomCategory.Trinket] = { order = 7, name = 'Trinkets' },
    [Enum.ItemClass.ItemEnhancement] = { order = 8, name = 'Item Enhancements' },
    [Enum.ItemClass.Gem] = { order = 9, name = 'Gems' },
    [Enum.ItemClass.Glyph] = { order = 10, name = 'Glyphs' },
    [Enum.ItemClass.Consumable] = { order = 11, name = 'Consumables' },
    [Enum.ItemClass.Reagent] = { order = 12, name = 'Reagents' },
    [Enum.ItemClass.Tradegoods] = { order = 13, name = 'Trade Goods' },
    [Enum.ItemClass.Recipe] = { order = 14, name = 'Recipes' },
    [Enum.ItemClass.Miscellaneous] = { order = 15, name = 'Misc' },
    [Enum.ItemClass.Battlepet] = { order = 16, name = 'Battle Pets' },
    [Enum.ItemClass.Profession] = { order = 17, name = 'Professions' },
    [Enum.ItemClass.Container] = { order = 18, name = 'Containers' },
    [Enum.ItemClass.Projectile] = { order = 19, name = 'Projectiles' },
    [Enum.ItemClass.Quiver] = { order = 20, name = 'Quivers' },
    [Enum.ItemClass.Questitem] = { order = 21, name = 'Quest Items' },
    [Enum.ItemClass.Key] = { order = 22, name = 'Keys' },
    [Enum.ItemClass.WoWToken] = { order = 23, name = 'Tokens' }
}

enums:Enable()
