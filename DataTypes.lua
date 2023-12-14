local _, CB = ...
CB.T = {}

local Item = {}
Item.new = function(containerItem, itemInfo, ilvl, bag, slot, isNew, invType, questInfo, inventoryLocation)
    local self = {}
    self.id = containerItem.itemID
    self.name = containerItem.itemName
    self.link = containerItem.hyperlink
    self.stackCount = containerItem.stackCount
    self.bound = containerItem.isBound
    self.quality = containerItem.quality
    self.type = itemInfo.type
    self.subType = itemInfo.subType
    self.equipLocation = invType
    self.texture = itemInfo.texture or containerItem.iconFileID
    self.value = itemInfo.sellPrice or 0
    self.ilvl = ilvl or 0
    self.bag = bag
    self.slot = slot
    self.isNew = isNew
    self.reqLvl = itemInfo.reqLvl or 0
    self.isLocked = containerItem.isLocked
    self.questInfo = questInfo
    self.isReadable = containerItem.isReadable
    self.isFiltered = containerItem.isFiltered
    self.hasNoValue = containerItem.hasNoValue
    self.category = Item.GetCategory(self)
    self.location = inventoryLocation

    return self
end

function Item.GetCategory(self)
    if CB.U.IsEquipmentUnbound(self) then
        return CB.E.CustomCategory.BindOnEquip
    elseif self.quality == Enum.ItemQuality.Heirloom then
        return CB.E.CustomCategory.BindOnAccount
    elseif CB.U.IsJewelry(self) then
        return CB.E.CustomCategory.Jewelry
    elseif CB.U.IsTrinket(self) then
        return CB.E.CustomCategory.Trinket
    elseif self.id == 82800 then
        return Enum.ItemClass.Battlepet
    elseif self.type == nil then
        return Enum.ItemClass.Miscellaneous
    else
        return self.type
    end
end

CB.T.Item = Item
