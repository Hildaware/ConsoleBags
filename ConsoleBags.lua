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

local backpackShouldOpen = false
local backpackShouldClose = false

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
        CB.BuildItemCache()
    end

    if event == "BAG_UPDATE_DELAYED" then
        CB.BuildItemCache()
        CB.G.UpdateInventory()
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

        CB.BuildBankCache()
        CB.G.UpdateBank()
        CB.G.ShowBank()

        CB.OpenBackpack()
    end

    if event == "BANKFRAME_CLOSED" then
        CB.G.HideBank()
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

        backpackShouldOpen = false
        backpackShouldClose = false

        CB.BuildItemCache()
        CB.G.UpdateInventory()

        PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
        CB.View:Show()
    elseif backpackShouldClose then
        backpackShouldClose = false

        PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
        CB.View:Hide()

        local bank = CB.BankView and CB.BankView:IsShown()
        if bank then
            CB.BankView:Hide()
        end
    end
end)

function CB.Init()
    -- CB.Data = {
    --     Characters = {
    --     }
    -- }

    CB.Session = {
        Items = {}, -- All Items
        Categories = CB.U.BuildCategoriesTable(),
        Filter = nil,
        Bank = {
            Items = {},
            Categories = CB.U.BuildBankCategoriesTable(),
            Filter = nil
        }
    }

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

local function GetItemData(bag, slot)
    local containerItem = CB.R.GetContainerItemInfo(bag, slot)
    if containerItem ~= nil then
        local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
        local itemInfo = CB.R.GetItemInfo(containerItem.hyperlink)
        local ilvl = CB.R.GetEffectiveItemLevel(containerItem.hyperlink)
        local invType = CB.R.GetInventoryType(containerItem.hyperlink)
        local isNew = C_NewItems.IsNewItem(bag, slot)

        -- Create Item
        local item = CB.T.Item.new(containerItem, itemInfo, ilvl, bag, slot, isNew, invType, questInfo)
        return item
    end
    return nil
end

local function CategorizeItem(item, SessionInventory)
    tinsert(SessionInventory.Items, item)

    -- Category Data
    if item.category ~= nil then
        SessionInventory.Categories[item.category].count =
            SessionInventory.Categories[item.category].count + 1
        tinsert(SessionInventory.Categories[item.category].items, item)
        if item.isNew then
            SessionInventory.Categories[item.category].hasNew = true
        end
    else
        SessionInventory.Categories[Enum.ItemClass.Miscellaneous].count =
            SessionInventory.Categories[Enum.ItemClass.Miscellaneous] + 1
        tinsert(SessionInventory.Categories[Enum.ItemClass.Miscellaneous].items, item)
        if item.isNew then
            SessionInventory.Categories[Enum.ItemClass.Miscellaneous].hasNew = true
        end
    end
end

local function CreateItem(bag, slot, SessionInventory)
    local i = Item:CreateFromBagAndSlot(bag, slot)
    if not i:IsItemEmpty() then
        if i:IsItemDataCached() then
            local item = GetItemData(bag, slot)
            if item then
                CategorizeItem(item, SessionInventory)
            end
        else
            i:ContinueOnItemLoad(function()
                local item = GetItemData(bag, slot)
                if item then
                    CategorizeItem(item, SessionInventory)
                end
            end)
        end
    end
end

function CB.BuildItemCache()
    CB.Session.Items = {}
    CB.Session.Categories = CB.U.BuildCategoriesTable()

    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            CreateItem(bag, slot, CB.Session)
        end
    end
end

function CB.BuildBankCache()
    CB.Session.Bank.Items = {}
    CB.Session.Bank.Categories = CB.U.BuildBankCategoriesTable()

    -- Bank Container
    for slot = 1, C_Container.GetContainerNumSlots(BANK_CONTAINER) do
        CreateItem(BANK_CONTAINER, slot, CB.Session.Bank)
    end

    -- Bank Bags
    for bag = ITEM_INVENTORY_BANK_BAG_OFFSET, ITEM_INVENTORY_BANK_BAG_OFFSET + NUM_BANKBAGSLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            CreateItem(bag, slot, CB.Session.Bank)
        end
    end

    -- Reagent Bank
    for slot = 1, C_Container.GetContainerNumSlots(REAGENTBANK_CONTAINER) do
        CreateItem(REAGENTBANK_CONTAINER, slot, CB.Session.Bank)
    end
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
