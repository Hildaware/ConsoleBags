local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Resolver: AceModule
local resolver = addon:NewModule('Resolver')

resolver.GetContainerItemInfo = function(bagId, slotId)
    return C_Container.GetContainerItemInfo(bagId, slotId)
end

resolver.GetItemInfo = function(link)
    local _, _, rarity, _, reqLvl, _, _, stackCount, _, texture, sellPrice, classId, subClassId, bindType, xpacId =
        C_Item.GetItemInfo(link)
    return {
        rarity = rarity,
        type = classId,
        subType = subClassId,
        stackCount = stackCount,
        texture = texture,
        sellPrice = sellPrice,
        xpacId = xpacId,
        reqLvl = reqLvl,
        bindType = bindType
    }
end

resolver.GetEffectiveItemLevel = function(link)
    local ilvl = GetDetailedItemLevelInfo(link)
    return ilvl
end

resolver.GetInventoryType = function(link)
    return C_Item.GetItemInventoryTypeByID(link)
end

---@return boolean
resolver.GetWarboundStatus = function(bindType, bag, slot)
    local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if bindType == 2 then -- Bind on equip
        return C_Item.IsBoundToAccountUntilEquip(itemLoc)
    else
        return C_Bank.IsItemAllowedInBankType(Enum.BankType.Account, itemLoc)
    end
end

resolver.IsEquippableItem = function(classId)
    return classId == Enum.ItemClass.Weapon or classId == Enum.ItemClass.Armor
end

resolver:Enable()
