local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Items: AceModule
local items = addon:NewModule('Items')

---@class Resolver: AceModule
local resolver = addon:GetModule('Resolver')

---@class Types: AceModule
local types = addon:GetModule('Types')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Database: AceModule
local database = addon:GetModule('Database')

local function GetItemData(bag, slot, inventoryLocation)
    local containerItem = resolver.GetContainerItemInfo(bag, slot)
    if containerItem ~= nil then
        local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
        local itemInfo = resolver.GetItemInfo(containerItem.hyperlink)
        local ilvl = resolver.GetEffectiveItemLevel(containerItem.hyperlink)
        local invType = resolver.GetInventoryType(containerItem.hyperlink)
        local isNew = C_NewItems.IsNewItem(bag, slot)

        local warboundStatus = false
        if resolver.IsEquippableItem(itemInfo.type) then
            warboundStatus = resolver.GetWarboundStatus(itemInfo.bindType, bag, slot)
        end

        -- Create Item
        local item = types.Item.new(containerItem, itemInfo, ilvl, bag, slot,
            isNew, invType, questInfo, inventoryLocation, warboundStatus)
        return item
    end
    return nil
end

local function AddItemToSession(item)
    session.Items[utils.ReplaceBagSlot(item.bag)][item.slot] = item

    if item.location == enums.InventoryType.Inventory then
        session.Inventory.Resolved = session.Inventory.Resolved + 1
    elseif item.location == enums.InventoryType.Bank then
        session.Bank.Resolved = session.Bank.Resolved + 1
    end
end

local function CreateItem(bag, slot, inventoryLocation)
    local i = Item:CreateFromBagAndSlot(bag, slot)
    if not i:IsItemEmpty() then
        if i:IsItemDataCached() then
            local item = GetItemData(bag, slot, inventoryLocation)
            if item then
                AddItemToSession(item)
                return true
            end
        else
            i:ContinueOnItemLoad(function()
                local item = GetItemData(bag, slot)
                if item then
                    AddItemToSession(item)
                    return true
                end
            end)
        end
    end
    return false
end

local function CreateBagData(bag, inventoryType)
    local bagSize = C_Container.GetContainerNumSlots(bag)
    local freeSlots = C_Container.GetContainerNumFreeSlots(bag)

    if inventoryType == enums.InventoryType.Inventory then
        session.Inventory.TotalCount = session.Inventory.TotalCount + (bagSize - freeSlots)

        if bag == NUM_TOTAL_EQUIPPED_BAG_SLOTS then -- Reagent Bag
            session.Inventory.ReagentCount = bagSize - freeSlots
        else
            session.Inventory.Count = session.Inventory.Count + (bagSize - freeSlots)
        end
    elseif inventoryType == enums.InventoryType.Bank then
        session.Bank.TotalCount = session.Bank.TotalCount + (bagSize - freeSlots)
    end

    session.Items[utils.ReplaceBagSlot(bag)] =
        session.Items[utils.ReplaceBagSlot(bag)] or {}

    return bagSize
end

local function CleanupSessionItems(bag, bagSize, slots)
    for i = 1, bagSize do
        if slots[i] == false then
            session.Items[bag][i] = nil
        end
    end
end

function items.BuildItemCache()
    session.BuildingCache = true
    session.Inventory.TotalCount = 0
    session.Inventory.Count = 0
    session.Inventory.ReagentCount = 0
    session.Inventory.Resolved = 0

    local invType = enums.InventoryType.Inventory
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local bagSize = CreateBagData(bag, invType)
        local requiresCleanup = {}
        for slot = 1, bagSize do
            local created = CreateItem(bag, slot, invType)
            requiresCleanup[slot] = created
        end

        CleanupSessionItems(bag, bagSize, requiresCleanup)
    end

    session.BuildingCache = false
end

function items.BuildBankCache()
    session.BuildingBankCache = true
    session.Bank.TotalCount = 0
    session.Bank.Count = 0
    session.Bank.ReagentCount = 0
    session.Bank.Resolved = 0

    local invType = enums.InventoryType.Bank

    -- Bank Container
    local bagSize = CreateBagData(BANK_CONTAINER, invType)
    local requiresCleanup = {}
    for slot = 1, bagSize do
        local created = CreateItem(BANK_CONTAINER, slot, invType)
        requiresCleanup[slot] = created
    end

    CleanupSessionItems(utils.ReplaceBagSlot(BANK_CONTAINER), bagSize, requiresCleanup)

    -- Bank Bags
    for bag = ITEM_INVENTORY_BANK_BAG_OFFSET, ITEM_INVENTORY_BANK_BAG_OFFSET + NUM_BANKBAGSLOTS do
        local bankBagSize = CreateBagData(bag, invType)
        requiresCleanup = {}
        for slot = 1, bankBagSize do
            local created = CreateItem(bag, slot, enums.InventoryType.Bank)
            requiresCleanup[slot] = created
        end

        CleanupSessionItems(bag, bankBagSize, requiresCleanup)
    end

    -- Bank Reagent Container
    local reagentContainerSize = CreateBagData(REAGENTBANK_CONTAINER, invType)
    requiresCleanup = {}
    for slot = 1, reagentContainerSize do
        local created = CreateItem(REAGENTBANK_CONTAINER, slot, enums.InventoryType.Bank)
        requiresCleanup[slot] = created
    end

    CleanupSessionItems(utils.ReplaceBagSlot(REAGENTBANK_CONTAINER), reagentContainerSize, requiresCleanup)

    session.BuildingBankCache = false
end

---@param categories CategorizedItemSet[]
---@param sortField SortField
function items:SortItems(categories, sortField)
    local type = sortField.Field
    local order = sortField.Sort

    for _, cat in pairs(categories) do
        if type == enums.SortFields.COUNT then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.stackCount > b.stackCount
                    else
                        return a.stackCount < b.stackCount
                    end
                end)
        end

        if type == enums.SortFields.Name then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.name < b.name
                    else
                        return a.name > b.name
                    end
                end)
        end

        if type == enums.SortFields.Icon then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.quality > b.quality
                    else
                        return a.quality < b.quality
                    end
                end)
        end

        if type == enums.SortFields.Category then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.type > b.type
                    else
                        return a.type < b.type
                    end
                end)
        end

        if type == enums.SortFields.Ilvl then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.ilvl > b.ilvl
                    else
                        return a.ilvl < b.ilvl
                    end
                end)
        end

        if type == enums.SortFields.ReqLvl then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.reqLvl > b.reqLvl
                    else
                        return a.reqLvl < b.reqLvl
                    end
                end)
        end

        if type == enums.SortFields.Value then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.value > b.value
                    else
                        return a.value < b.value
                    end
                end)
        end

        -- Always put new on top
        for index, item in ipairs(cat.items) do
            if item.isNew == true then
                table.insert(cat.items, 1, table.remove(cat.items, index))
            end
        end
    end
end

items:Enable()
