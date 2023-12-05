local _, Bagger = ...
Bagger.E = {}

Bagger.E.SortOrder = {
    Asc = 1,
    Desc = 2,
}

Bagger.E.SortFields = {
    -- COUNT = 1,
    Icon = 2,
    Name = 3,
    Category = 4,
    Ilvl = 5,
    ReqLvl = 6,
    Value = 7
}

Bagger.E.FilterFields = {
    All = 1,
    Weapons = 2,
    Armor = 3
}

Bagger.E.CustomCategory = {
    BindOnAccount = 99,
    BindOnEquip = 98,
    Jewelry = 97,
    Trinket = 96
}

-- DO NOT USE THIS DIRECTLY. Make a Copy.
Bagger.E.Categories = {
    [Bagger.E.CustomCategory.BindOnAccount] = { order = 1, name = "Bind On Account" },
    [Bagger.E.CustomCategory.BindOnEquip] = { order = 2, name = "Bind On Equip" },
    [Enum.ItemClass.Weapon] = { order = 3, name = "Weapons" },
    [Enum.ItemClass.Armor] = { order = 4, name = "Armor" },
    [Bagger.E.CustomCategory.Jewelry] = { order = 5, name = "Jewelry" },
    [Bagger.E.CustomCategory.Trinket] = { order = 6, name = "Trinkets" },
    [Enum.ItemClass.ItemEnhancement] = { order = 7, name = "Item Enhancements" },
    [Enum.ItemClass.Gem] = { order = 8, name = "Gems" },
    [Enum.ItemClass.Glyph] = { order = 9, name = "Glyphs" },
    [Enum.ItemClass.Consumable] = { order = 10, name = "Consumables" },
    [Enum.ItemClass.Reagent] = { order = 11, name = "Reagents" },
    [Enum.ItemClass.Tradegoods] = { order = 12, name = "Trade Goods" },
    [Enum.ItemClass.Recipe] = { order = 13, name = "Recipes" },
    [Enum.ItemClass.Miscellaneous] = { order = 14, name = "Misc" },
    [Enum.ItemClass.Battlepet] = { order = 15, name = "Battle Pets" },
    [Enum.ItemClass.Profession] = { order = 16, name = "Professions" },
    [Enum.ItemClass.Container] = { order = 17, name = "Containers" },
    [Enum.ItemClass.Projectile] = { order = 18, name = "Projectiles" },
    [Enum.ItemClass.Quiver] = { order = 19, name = "Quivers" },
    [Enum.ItemClass.Questitem] = { order = 20, name = "Quest Items" },
    [Enum.ItemClass.Key] = { order = 21, name = "Keys" },
    [Enum.ItemClass.WoWToken] = { order = 22, name = "Tokens" },

}
