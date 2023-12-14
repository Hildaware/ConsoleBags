local _, CB = ...

local CBDataDefaults = {
    Characters = {},
    View = {
        Size = {
            X = 632,
            Y = 396,
        },
        Position = {
            X = 20,
            Y = 20
        },
        Columns = {
            Icon = 32,
            Name = 280,
            Category = 40,
            Ilvl = 50,
            ReqLvl = 50,
            Value = 110
        },
        SortField = {
            Field = CB.E.SortFields.Name,
            Sort = CB.E.SortOrder.Desc
        }
    },
    BankView = {
        Size = {
            X = 632,
            Y = 396,
        },
        Position = {
            X = 20,
            Y = 20
        },
        Columns = {
            Icon = 32,
            Name = 280,
            Category = 40,
            Ilvl = 50,
            ReqLvl = 50,
            Value = 110
        },
        SortField = {
            Field = CB.E.SortFields.Name,
            Sort = CB.E.SortOrder.Desc
        }
    }
}

CB.Session = {
    Items = {},
    InventoryCount = 0,
    InventoryResolved = 0,
    BankCount = 0,
    BankResolved = 0,
    InventoryFilter = nil,
    BankFilter = nil
}

local backpackShouldOpen = false
local backpackShouldClose = false
local buildingCache = false

local bankShouldOpen = false
local buildingBankCache = false

local playerIdentifier = ""

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("BANKFRAME_CLOSED")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
eventFrame:SetScript("OnEvent", function(self, event, param1, param2, param3)
    if event == "ADDON_LOADED" and param1 == "ConsoleBags" then -- Saved Variables
        if CBData == nil then
            CBData = CB.U.CopyTable(CBDataDefaults)
            return
        end
    end

    if event == "PLAYER_LOGIN" then
        CB.Init()
    end

    if event == "PLAYER_ENTERING_WORLD" then
        CB.U.CreateEnableBagButtons()
        CB.U.BagDestroyer()
        CB.U.DestroyDefaultBags()
        CB.GatherItems()
    end

    if event == "BAG_UPDATE_DELAYED" then
        CB.BuildItemCache()
        if CB.View:IsShown() then
            CB.G.UpdateInventory()
        end
    end

    if event == "EQUIPMENT_SETS_CHANGED" then
        CB.BuildItemCache()
        CB.G.UpdateInventory()
    end

    if event == "PLAYER_MONEY" then
        CB.G.UpdateCurrency()
    end

    if event == "BANKFRAME_OPENED" then
        if CB.View == nil then
            CB.G.InitializeInventoryGUI()
        end
        if CB.BankView == nil then
            CB.G.InitializeBankGUI()
        end


        bankShouldOpen = true
        CB.OpenBackpack()
    end

    if event == "BANKFRAME_CLOSED" then
        CB.G.HideBank()
        CB.CloseBackpack()
    end

    if event == "PLAYERBANKSLOTS_CHANGED" then
        CB.BuildBankCache()
        CB.G.UpdateBank()
    end
end)

eventFrame:SetScript("OnUpdate", function()
    if CB.View == nil then
        CB.G.InitializeInventoryGUI()
    end

    if backpackShouldOpen then
        if CB.Settings.HideBags == true then return end

        if not buildingCache then
            CB.BuildItemCache()
        end

        if CB.Session.InventoryResolved >= CB.Session.InventoryCount then
            backpackShouldOpen = false
            backpackShouldClose = false

            CB.G.UpdateInventory()

            PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
            CB.View:Show()
        end
    elseif backpackShouldClose then
        backpackShouldClose = false

        PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
        CB.View:Hide()

        local bank = CB.BankView and CB.BankView:IsShown()
        if bank then
            CB.BankView:Hide()
        end
    end

    if bankShouldOpen then
        if not buildingBankCache then
            CB.BuildBankCache()
        end

        if CB.Session.BankResolved >= CB.Session.BankCount then
            bankShouldOpen = false

            CB.G.UpdateBank()
            CB.BankView:Show()
        end
    end
end)

function CB.Init()
    -- CB.Data = {
    --     Characters = {
    --     }
    -- }


    CB.Settings = { -- This is technically Session data as well
        Defaults = {
            Columns = {
                Icon = 32,
                Name = 320, -- was 280 before removing cats
                Category = 40,
                Ilvl = 50,
                ReqLvl = 50,
                Value = 110
            },
            Sections = {
                Header = 40,
                Filters = 40,
                ListViewHeader = 40,
                ListItemHeight = 40
            }
        },
        HideBags = false
    }

    -- Build player data
    local playerId = UnitGUID("player")
    local playerName = UnitName("player")

    if playerId == nil or playerName == nil then return end
    playerIdentifier = playerId

    -- CB.Data.Characters[playerId] = {
    --     Name = playerName
    -- }

    hooksecurefunc('OpenBackpack', CB.OpenBackpack)
    hooksecurefunc('OpenAllBags', CB.OpenAllBags)
    hooksecurefunc('CloseBackpack', CB.CloseBackpack)
    hooksecurefunc('CloseAllBags', CB.CloseAllBags)
    hooksecurefunc('ToggleBackpack', CB.ToggleBackpack)
    hooksecurefunc('ToggleAllBags', CB.ToggleAllBags)
    hooksecurefunc('ToggleBag', CB.ToggleBag)
end

local function GetItemData(bag, slot, inventoryLocation)
    local containerItem = CB.R.GetContainerItemInfo(bag, slot)
    if containerItem ~= nil then
        local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
        local itemInfo = CB.R.GetItemInfo(containerItem.hyperlink)
        local ilvl = CB.R.GetEffectiveItemLevel(containerItem.hyperlink)
        local invType = CB.R.GetInventoryType(containerItem.hyperlink)
        local isNew = C_NewItems.IsNewItem(bag, slot)

        -- Create Item
        local item = CB.T.Item.new(containerItem, itemInfo, ilvl, bag, slot,
            isNew, invType, questInfo, inventoryLocation)
        return item
    end
    return nil
end

local function AddItemToSession(item)
    CB.Session.Items[CB.U.ReplaceBagSlot(item.bag)][item.slot] = item

    if item.location == CB.E.InventoryType.Inventory then
        CB.Session.InventoryResolved = CB.Session.InventoryResolved + 1
    elseif item.location == CB.E.InventoryType.Bank then
        CB.Session.BankResolved = CB.Session.BankResolved + 1
    end
end

local function CreateItem(bag, slot, inventoryLocation)
    local i = Item:CreateFromBagAndSlot(bag, slot)
    if not i:IsItemEmpty() then
        if i:IsItemDataCached() then
            local item = GetItemData(bag, slot, inventoryLocation)
            if item then
                AddItemToSession(item)
            end
        else
            i:ContinueOnItemLoad(function()
                local item = GetItemData(bag, slot)
                if item then
                    AddItemToSession(item)
                end
            end)
        end
    end
end

local function CreateBagData(bag, inventoryType)
    local bagSize = C_Container.GetContainerNumSlots(bag)
    local freeSlots = C_Container.GetContainerNumFreeSlots(bag)

    if inventoryType == CB.E.InventoryType.Inventory then
        CB.Session.InventoryCount = CB.Session.InventoryCount + (bagSize - freeSlots)
    elseif inventoryType == CB.E.InventoryType.Bank then
        CB.Session.BankCount = CB.Session.BankCount + (bagSize - freeSlots)
    end

    CB.Session.Items[CB.U.ReplaceBagSlot(bag)] =
        CB.Session.Items[CB.U.ReplaceBagSlot(bag)] or {}

    return bagSize
end

local function CleanupSessionItems(bag, bagSize)
    for i = bagSize + 1, #CB.Session.Items[bag] do
        CB.Session.Items[bag][i] = nil
    end
end

function CB.BuildItemCache()
    buildingCache = true
    CB.Session.InventoryCount = 0
    CB.Session.InventoryResolved = 0

    local invType = CB.E.InventoryType.Inventory
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local bagSize = CreateBagData(bag, invType)
        for slot = 1, bagSize do
            CreateItem(bag, slot, invType)
        end

        CleanupSessionItems(bag, bagSize)
    end

    buildingCache = false
end

function CB.BuildBankCache()
    buildingBankCache = true
    CB.Session.BankCount = 0
    CB.Session.BankResolved = 0

    local invType = CB.E.InventoryType.Bank

    -- Bank Container
    local bagSize = CreateBagData(BANK_CONTAINER, invType)
    for slot = 1, bagSize do
        CreateItem(BANK_CONTAINER, slot, invType)
    end

    CleanupSessionItems(CB.U.ReplaceBagSlot(BANK_CONTAINER), bagSize)

    -- Bank Bags
    for bag = ITEM_INVENTORY_BANK_BAG_OFFSET, ITEM_INVENTORY_BANK_BAG_OFFSET + NUM_BANKBAGSLOTS do
        local bankBagSize = CreateBagData(bag, invType)
        for slot = 1, bankBagSize do
            CreateItem(bag, slot, CB.E.InventoryType.Bank)
        end

        CleanupSessionItems(bag, bankBagSize)
    end

    -- Bank Reagent Container
    local reagentContainerSize = CreateBagData(REAGENTBANK_CONTAINER, invType)
    for slot = 1, reagentContainerSize do
        CreateItem(REAGENTBANK_CONTAINER, slot, CB.E.InventoryType.Bank)
    end

    CleanupSessionItems(CB.U.ReplaceBagSlot(REAGENTBANK_CONTAINER), reagentContainerSize)

    buildingBankCache = false
end

function CB.SortItems(inventoryType, categories)
    local sortField
    if inventoryType == CB.E.InventoryType.Inventory then
        sortField = CBData.View.SortField
    elseif inventoryType == CB.E.InventoryType.Bank then
        sortField = CBData.BankView.SortField
    end
    local type = sortField.Field
    local order = sortField.Sort

    for _, cat in pairs(categories) do
        if type == CB.E.SortFields.COUNT then
            table.sort(cat.items,
                function(a, b)
                    if order == CB.E.SortOrder.Desc then
                        return a.stackCount > b.stackCount
                    else
                        return a.stackCount < b.stackCount
                    end
                end)
        end

        if type == CB.E.SortFields.Name then
            table.sort(cat.items,
                function(a, b)
                    if order == CB.E.SortOrder.Desc then
                        return a.name < b.name
                    else
                        return a.name > b.name
                    end
                end)
        end

        if type == CB.E.SortFields.Icon then
            table.sort(cat.items,
                function(a, b)
                    if order == CB.E.SortOrder.Desc then
                        return a.quality > b.quality
                    else
                        return a.quality < b.quality
                    end
                end)
        end

        if type == CB.E.SortFields.Category then
            table.sort(cat.items,
                function(a, b)
                    if order == CB.E.SortOrder.Desc then
                        return a.type > b.type
                    else
                        return a.type < b.type
                    end
                end)
        end

        if type == CB.E.SortFields.Ilvl then
            table.sort(cat.items,
                function(a, b)
                    if order == CB.E.SortOrder.Desc then
                        return a.ilvl > b.ilvl
                    else
                        return a.ilvl < b.ilvl
                    end
                end)
        end

        if type == CB.E.SortFields.ReqLvl then
            table.sort(cat.items,
                function(a, b)
                    if order == CB.E.SortOrder.Desc then
                        return a.reqLvl > b.reqLvl
                    else
                        return a.reqLvl < b.reqLvl
                    end
                end)
        end

        if type == CB.E.SortFields.Value then
            table.sort(cat.items,
                function(a, b)
                    if order == CB.E.SortOrder.Desc then
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

-- Slashy
-- SLASH_CB1 = '/CB'
-- SLASH_CB2 = '/bg'
-- function SlashCmdList.CB(msg, editbox)
--     CB.G.Toggle()
-- end

function CB.OpenAllBags()
    backpackShouldOpen = true
end

function CB.CloseAllBags()
    backpackShouldClose = true
end

function CB.CloseBackpack()
    backpackShouldClose = true
end

function CB.OpenBackpack()
    backpackShouldOpen = true
end

function CB.ToggleBag()
    if CB.View:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end
end

function CB.CloseBag()
    backpackShouldClose = true
end

function CB.ToggleAllBags()
    if CB.View:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end
end

function CB.ToggleBackpack()
    if CB.View:IsShown() then
        backpackShouldClose = true
    else
        backpackShouldOpen = true
    end
end
