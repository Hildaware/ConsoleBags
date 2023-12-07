local _, Bagger = ...
Bagger.T = {}

local Item = {}
Item.new = function(containerItem, itemInfo, ilvl, bag, slot, isNew, invType, questInfo)
    local self = {}
    self.id = containerItem.itemId
    self.name = containerItem.itemName
    self.link = containerItem.hyperlink
    self.stackCount = containerItem.stackCount
    self.bound = containerItem.isBound
    self.quality = containerItem.quality
    self.type = itemInfo.type
    self.subType = itemInfo.subType
    self.equipLocation = invType
    self.texture = itemInfo.texture
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

    return self
end

function Item.GetCategory(self)
    if Bagger.U.IsEquipmentUnbound(self) then
        return Bagger.E.CustomCategory.BindOnEquip
    elseif self.quality == Enum.ItemQuality.Heirloom then
        return Enum.ItemQuality.Heirloom
    elseif Bagger.U.IsJewelry(self) then
        return Bagger.E.CustomCategory.Jewelry
    elseif Bagger.U.IsTrinket(self) then
        return Bagger.E.CustomCategory.Trinket
    elseif self.type == nil then
        return Enum.ItemClass.Miscellaneous
    else
        return self.type
    end
end

Bagger.T.Item = Item
