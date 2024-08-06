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


---@param bag integer
---@param slot integer
---@param inventoryType? Enums.InventoryType
---@return Item?
local function GetItemData(bag, slot, inventoryType)
    local containerItem = resolver.GetContainerItemInfo(bag, slot)
    if containerItem ~= nil then
        local itemInfo = resolver.GetItemInfo(containerItem.hyperlink)

        local item = types.Item.New(containerItem, itemInfo, inventoryType, bag, slot)
        return item
    end
    return nil
end

---@param item Item
---@param sessionData ViewData
local function AddItemToSession(item, sessionData)
    session.Items[utils.ReplaceBagSlot(item.bag)][item.slot] = item
    sessionData.Resolved = sessionData.Resolved + 1
end

---@param bag integer
---@param slot integer
---@param inventoryType Enums.InventoryType
---@param sessionData ViewData
local function CreateItem(bag, slot, inventoryType, sessionData)
    local i = Item:CreateFromBagAndSlot(bag, slot)
    if not i:IsItemEmpty() then
        if i:IsItemDataCached() then
            local item = GetItemData(bag, slot, inventoryType)
            if item then
                AddItemToSession(item, sessionData)
                return true
            end
        else
            i:ContinueOnItemLoad(function()
                local item = GetItemData(bag, slot)
                if item then
                    AddItemToSession(item, sessionData)
                    return true
                end
            end)
        end
    end
    return false
end

---@param bag integer
---@param sessionData ViewData
local function CreateBagData(bag, sessionData)
    local bagSize = C_Container.GetContainerNumSlots(bag)
    local freeSlots = C_Container.GetContainerNumFreeSlots(bag)

    local replacedBagSlot = utils.ReplaceBagSlot(bag)

    local sessionBag = sessionData.Bags[replacedBagSlot]
    sessionBag.TotalCount = bagSize - freeSlots

    if enums.PlayerInventoryBagIndex[bag] then
        if bag == Enum.BagIndex.ReagentBag then
            sessionBag.ReagentCount = bagSize - freeSlots
        else
            sessionBag.Count = bagSize - freeSlots
        end
    end

    session.Items[replacedBagSlot] = session.Items[replacedBagSlot] or {}

    return bagSize
end

---@param bag integer
---@param bagSize integer
---@param slots table
local function CleanupSessionItems(bag, bagSize, slots)
    for i = 1, bagSize do
        if slots[i] == false then
            session.Items[bag][i] = nil
        end
    end
end

function items.BuildItemCache()
    local invType = enums.InventoryType.Inventory
    session.BuildingCache = true
    session.Inventory.TotalCount = 0
    session.Inventory.Count = 0
    session.Inventory.ReagentCount = 0
    session.Inventory.Resolved = 0

    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        session.Inventory.Bags[bag].TotalCount = 0
        session.Inventory.Bags[bag].Count = 0

        local bagSize = CreateBagData(bag, session.Inventory)
        local requiresCleanup = {}
        for slot = 1, bagSize do
            local created = CreateItem(bag, slot, invType, session.Inventory)
            requiresCleanup[slot] = created
        end

        CleanupSessionItems(bag, bagSize, requiresCleanup)
    end

    -- Recalculate totals
    for index, bag in pairs(session.Inventory.Bags) do
        session.Inventory.TotalCount = session.Inventory.TotalCount + bag.TotalCount
        session.Inventory.Count = session.Inventory.Count + bag.Count
        session.Inventory.Resolved = session.Inventory.Resolved + bag.Count

        if index == Enum.BagIndex.ReagentBag then
            session.Inventory.ReagentCount = bag.TotalCount
        end
    end

    session.BuildingCache = false
end

function items.BuildBankCache()
    local invType = enums.InventoryType.Bank
    session.BuildingBankCache = true
    session.Bank.TotalCount = 0
    session.Bank.Count = 0
    session.Bank.ReagentCount = 0
    session.Bank.Resolved = 0

    -- Bank Container
    local replacedBagSlot = utils.ReplaceBagSlot(BANK_CONTAINER)
    session.Bank.Bags[replacedBagSlot].TotalCount = 0
    session.Bank.Bags[replacedBagSlot].Count = 0

    local bagSize = CreateBagData(BANK_CONTAINER, session.Bank)
    local requiresCleanup = {}
    for slot = 1, bagSize do
        local created = CreateItem(BANK_CONTAINER, slot, invType, session.Bank)
        requiresCleanup[slot] = created
    end

    CleanupSessionItems(replacedBagSlot, bagSize, requiresCleanup)

    -- Bank Bags
    for bag = ITEM_INVENTORY_BANK_BAG_OFFSET + 1, ITEM_INVENTORY_BANK_BAG_OFFSET + NUM_BANKBAGSLOTS do
        session.Bank.Bags[bag].TotalCount = 0
        session.Bank.Bags[bag].Count = 0

        local bankBagSize = CreateBagData(bag, session.Bank)
        requiresCleanup = {}
        for slot = 1, bankBagSize do
            local created = CreateItem(bag, slot, invType, session.Bank)
            requiresCleanup[slot] = created
        end

        CleanupSessionItems(bag, bankBagSize, requiresCleanup)
    end

    -- Bank Reagent Container
    local replacedReagentBagSlot = utils.ReplaceBagSlot(REAGENTBANK_CONTAINER)
    session.Bank.Bags[replacedReagentBagSlot].TotalCount = 0
    session.Bank.Bags[replacedReagentBagSlot].Count = 0

    local reagentContainerSize = CreateBagData(REAGENTBANK_CONTAINER, session.Bank)
    requiresCleanup = {}
    for slot = 1, reagentContainerSize do
        local created = CreateItem(REAGENTBANK_CONTAINER, slot, invType, session.Bank)
        requiresCleanup[slot] = created
    end

    CleanupSessionItems(replacedReagentBagSlot, reagentContainerSize, requiresCleanup)

    -- Recalculate totals
    for _, bag in pairs(session.Bank.Bags) do
        session.Bank.TotalCount = session.Bank.TotalCount + bag.TotalCount
        session.Bank.Count = session.Bank.Count + bag.Count
        session.Bank.Resolved = session.Bank.Resolved + bag.Count
    end

    session.BuildingBankCache = false
end

function items.BuildWarbankCache()
    local invType = enums.InventoryType.Shared

    session.BuildingWarbankCache = true
    session.Warbank.TotalCount = 0
    session.Warbank.Count = 0
    session.Warbank.Resolved = 0

    for bag = Enum.BagIndex.AccountBankTab_1, Enum.BagIndex.AccountBankTab_5 do
        session.Warbank.Bags[bag].TotalCount = 0
        session.Warbank.Bags[bag].Count = 0

        local bagSize = CreateBagData(bag, session.Warbank)
        local requiresCleanup = {}
        for slot = 1, bagSize do
            local created = CreateItem(bag, slot, invType, session.Warbank)
            requiresCleanup[slot] = created
        end

        CleanupSessionItems(bag, bagSize, requiresCleanup)
    end

    -- Recalculate totals
    for _, bag in pairs(session.Warbank.Bags) do
        session.Warbank.TotalCount = session.Warbank.TotalCount + bag.TotalCount
        session.Warbank.Count = session.Warbank.Count + bag.Count
        session.Warbank.Resolved = session.Warbank.Resolved + bag.Count
    end

    session.BuildingWarbankCache = false
end

---@param bagId integer
---@param inventoryType Enums.InventoryType
---@return ViewData
function items:UpdateBag(bagId, inventoryType)
    if inventoryType == enums.InventoryType.Inventory then
        session.BuildingCache = true
    elseif inventoryType == enums.InventoryType.Bank then
        session.BuildingBankCache = true
    elseif inventoryType == enums.InventoryType.Shared then
        session.BuildingWarbankCache = true
    end

    local sessionData = session:GetSessionViewDataByType(inventoryType)

    sessionData.TotalCount = 0
    sessionData.Count = 0
    sessionData.ReagentCount = 0
    sessionData.Resolved = 0

    local replacedBagSlot = utils.ReplaceBagSlot(bagId)

    sessionData.Bags[replacedBagSlot].TotalCount = 0
    sessionData.Bags[replacedBagSlot].Count = 0

    local bagSize = CreateBagData(bagId, sessionData)
    local requiresCleanup = {}
    for slot = 1, bagSize do
        local created = CreateItem(bagId, slot, inventoryType, sessionData)
        requiresCleanup[slot] = created
    end

    CleanupSessionItems(replacedBagSlot, bagSize, requiresCleanup)

    -- Recalculate totals
    for index, bag in pairs(sessionData.Bags) do
        sessionData.TotalCount = sessionData.TotalCount + bag.TotalCount
        sessionData.Count = sessionData.Count + bag.Count
        sessionData.Resolved = sessionData.Resolved + bag.TotalCount

        if index == Enum.BagIndex.ReagentBag then
            sessionData.ReagentCount = bag.TotalCount
        end
    end

    if inventoryType == enums.InventoryType.Inventory then
        session.BuildingCache = false
    elseif inventoryType == enums.InventoryType.Bank then
        session.BuildingBankCache = false
    elseif inventoryType == enums.InventoryType.Shared then
        session.BuildingWarbankCache = false
    end

    return sessionData
end

---@param categories CategorizedItemSet[]
---@param sortField SortField
function items:SortItems(categories, sortField)
    local type = sortField.Field
    local order = sortField.Sort

    for _, cat in pairs(categories) do
        if type == enums.SortField.COUNT then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.stackCount > b.stackCount
                    else
                        return a.stackCount < b.stackCount
                    end
                end)
        end

        if type == enums.SortField.Name then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.name < b.name
                    else
                        return a.name > b.name
                    end
                end)
        end

        if type == enums.SortField.Icon then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.quality > b.quality
                    else
                        return a.quality < b.quality
                    end
                end)
        end

        if type == enums.SortField.Category then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.type > b.type
                    else
                        return a.type < b.type
                    end
                end)
        end

        if type == enums.SortField.Ilvl then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.ilvl > b.ilvl
                    else
                        return a.ilvl < b.ilvl
                    end
                end)
        end

        if type == enums.SortField.ReqLvl then
            table.sort(cat.items,
                function(a, b)
                    if order == enums.SortOrder.Desc then
                        return a.reqLvl > b.reqLvl
                    else
                        return a.reqLvl < b.reqLvl
                    end
                end)
        end

        if type == enums.SortField.Value then
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
