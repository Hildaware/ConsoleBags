local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Resolver: AceModule
local resolver = addon:NewModule('Resolver')

resolver.GetContainerItemInfo = function(bagId, slotId)
    return C_Container.GetContainerItemInfo(bagId, slotId)
end

resolver.GetItemInfo = function(link)
    local _, _, rarity, _, reqLvl, _, _, stackCount, _, texture, sellPrice, classId, subClassId, _, xpacId =
        C_Item.GetItemInfo(link)
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

resolver.GetEffectiveItemLevel = function(link)
    local ilvl = GetDetailedItemLevelInfo(link)
    return ilvl
end

resolver.GetInventoryType = function(link)
    return C_Item.GetItemInventoryTypeByID(link)
end

resolver:Enable()
