-- WoW API Calls, etc.
local _, Bagger = ...
Bagger.R = {}

Bagger.R.GetContainerItemInfo = function(bagId, slotId)
    return C_Container.GetContainerItemInfo(bagId, slotId)
end

Bagger.R.GetItemInfo = function(link)
    local _, _, rarity, _, reqLvl, _, _, stackCount, _, texture, sellPrice, classId, subClassId, _, xpacId =
        GetItemInfo(link)
    return {
        rarity = rarity,
        type = classId,
        subType = subClassId,
        stackCount = stackCount,
        texture = texture,
        sellPrice = sellPrice,
        xpacId = xpacId,
        reqLvl = reqLvl
    }
end

Bagger.R.GetEffectiveItemLevel = function(link)
    local ilvl = GetDetailedItemLevelInfo(link)
    return ilvl
end

Bagger.R.GetInventoryType = function(link)
    return C_Item.GetItemInventoryTypeByID(link)
end
