-- WoW API Calls, etc.
local _, Bagger = ...
Bagger.R = {}

Bagger.R.GetContainerItemInfo = function(bagId, slotId)
    return C_Container.GetContainerItemInfo(bagId, slotId)
end

Bagger.R.GetItemInfo = function(link)
    local name, _, rarity, _, reqLvl, type, subType, stackCount, equipLocation, texture, sellPrice, classId, subClassId, _, xpacId = GetItemInfo(link)
    return {
        rarity = rarity,
        type = classId,
        subType = subClassId,
        stackCount = stackCount,
        equipLocation = equipLocation,
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