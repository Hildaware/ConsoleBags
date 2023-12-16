local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Resolver: AceModule
local resolver = addon:NewModule('Resolver')

resolver.GetContainerItemInfo = function(bagId, slotId)
    return C_Container.GetContainerItemInfo(bagId, slotId)
end

resolver.GetItemInfo = function(link)
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

resolver.GetEffectiveItemLevel = function(link)
    local ilvl = GetDetailedItemLevelInfo(link)
    return ilvl
end

resolver.GetInventoryType = function(link)
    return C_Item.GetItemInventoryTypeByID(link)
end

resolver.ResolveItem = function(bag, slot)
    local itemDataProto = {}

    local i = Item:CreateFromBagAndSlot(bag, slot)
    local data = setmetatable({}, { __index = itemDataProto })
    data.bag = bag
    data.slot = slot

    if not i:IsItemEmpty() and not i:IsItemDataCached() then
        print(i:GetItemLink())
    end
end

resolver:Enable()