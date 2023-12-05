local _, Bagger = ...
Bagger.T = {}

local Item = {}
Item.new = function(containerItem, itemInfo, ilvl, bag, slot, isNew, invType)
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

    return self
end

Bagger.T.Item = Item
