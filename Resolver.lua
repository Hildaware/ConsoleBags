-- WoW API Calls, etc.
local _, CB = ...
CB.R = {}

CB.R.GetContainerItemInfo = function(bagId, slotId)
    return C_Container.GetContainerItemInfo(bagId, slotId)
end

CB.R.GetItemInfo = function(link)
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

CB.R.GetEffectiveItemLevel = function(link)
    local ilvl = GetDetailedItemLevelInfo(link)
    return ilvl
end

CB.R.GetInventoryType = function(link)
    return C_Item.GetItemInventoryTypeByID(link)
end
