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
        CB.GatherItems()
        CB.U.CreateEnableBagButtons()
        CB.U.BagDestroyer()
        CB.U.DestroyDefaultBags()
    end

    if event == "BAG_UPDATE_DELAYED" then
        CB.GatherItems()
        CB.G.UpdateInventory()
        CB.G.UpdateFilterButtons()
        CB.G.UpdateBagContainer()
    end

    if event == "EQUIPMENT_SETS_CHANGED" then
        CB.GatherItems()
        CB.G.UpdateInventory()
        CB.G.UpdateFilterButtons()
        CB.G.UpdateBagContainer()
    end

    if event == "PLAYER_MONEY" then
        CB.G.UpdateCurrency()
    end

    if event == "BANKFRAME_OPENED" then
        CB.GatherItems()
        CB.G.UpdateInventory()
        CB.G.UpdateFilterButtons()
        CB.G.UpdateBagContainer()

        CB.G.ShowBank()
        CB.G.ShowInventory()
    end

    if event == "BANKFRAME_CLOSED" then
        CB.G.HideBank()
    end
end)

function CB.Init()
    -- CB.Data = {
    --     Characters = {
    --     }
    -- }

    CB.Session = {
        Items = {}, -- All Items
        Categories = CB.U.BuildCategoriesTable()
    }

    CB.Settings = {
        Defaults = {
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
        SortField = { -- TODO: SavedVariables
            Field = CB.E.SortFields.Name,
            Sort = CB.E.SortOrder.Desc
        },
        Filter = nil,
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

    hooksecurefunc('OpenAllBags', CB.G.Toggle)
    hooksecurefunc('CloseAllBags', CB.G.Hide)
    hooksecurefunc('ToggleBag', CB.G.Toggle)
    hooksecurefunc('ToggleAllBags', CB.G.Toggle)
    hooksecurefunc('ToggleBackpack', CB.G.Toggle)
end

-- TODO: Move this. It's specific to Inventory
function CB.GatherItems()
    CB.Session.Items = {}
    CB.Session.Categories = CB.U.BuildCategoriesTable()

    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local containerItem = CB.R.GetContainerItemInfo(bag, slot)
            if containerItem ~= nil then
                local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
                local itemInfo = CB.R.GetItemInfo(containerItem.hyperlink)
                local ilvl = CB.R.GetEffectiveItemLevel(containerItem.hyperlink)
                local invType = CB.R.GetInventoryType(containerItem.hyperlink)
                local isNew = C_NewItems.IsNewItem(bag, slot)

                -- Create Item
                local item = CB.T.Item.new(containerItem, itemInfo, ilvl, bag, slot, isNew, invType, questInfo)
                table.insert(CB.Session.Items, item)

                -- Category Data
                if item.category ~= nil then
                    CB.Session.Categories[item.category].count =
                        CB.Session.Categories[item.category].count + 1
                    tinsert(CB.Session.Categories[item.category].items, item)
                    if isNew then
                        CB.Session.Categories[item.category].hasNew = true
                    end
                else
                    CB.Session.Categories[Enum.ItemClass.Miscellaneous].count =
                        CB.Session.Categories[Enum.ItemClass.Miscellaneous] + 1
                    tinsert(CB.Session.Categories[Enum.ItemClass.Miscellaneous].items, item)
                    if isNew then
                        CB.Session.Categories[Enum.ItemClass.Miscellaneous].hasNew = true
                    end
                end
            end
        end
    end
end

-- TODO: Make this more generic so we can use it in the bank
function CB.SortItems()
    local sortField = CB.Settings.SortField
    local type = sortField.Field
    local order = sortField.Sort

    for _, cat in pairs(CB.Session.Categories) do
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

function CB.G.ShowInventory()
    if CB.View == nil then return end
    if CB.Settings.HideBags == true then return end

    if not CB.View:IsShown() then
        CB.GatherItems()
        CB.G.UpdateInventory()
        CB.G.UpdateFilterButtons()
        CB.G.UpdateBagContainer()

        PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
        CB.View:Show()
    end
end

function CB.G.Hide()
    if CB.View == nil then return end

    local inventory = CB.View:IsShown()
    local bank = CB.BankView and CB.BankView:IsShown()
    if inventory or bank then
        if inventory then
            CB.View:Hide()
            PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
        end

        if bank then
            CB.BankView:Hide()
        end
    end
end

function CB.G.Toggle()
    if CB.View == nil then
        CB.G.InitializeInventoryGUI()
    end

    if CB.View:IsShown() then
        CB.G.Hide()
    else
        CB.G.ShowInventory()
    end
end
