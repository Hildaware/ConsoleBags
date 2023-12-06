local _, Bagger = ...

local BaggerDataDefaults = {
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
            Field = Bagger.E.SortFields.Name,
            Sort = Bagger.E.SortOrder.Desc
        }
    },
}

local playerIdentifier = ""

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, param1, param2, param3)
    if event == "ADDON_LOADED" and param1 == "Bagger" then -- Saved Variables
        if BaggerData == nil then
            BaggerData = Bagger.U.CopyTable(BaggerDataDefaults)
            return
        end
    end

    if event == "PLAYER_LOGIN" then
        Bagger.Init()
    end

    if event == "PLAYER_ENTERING_WORLD" then
        Bagger.U.MakeBlizzBagsKillable()
        Bagger.U.KillBlizzBags()
    end

    if event == "BAG_UPDATE_DELAYED" then
        Bagger.G.UpdateView()
        Bagger.G.UpdateBagContainer()
    end

    if event == "EQUIPMENT_SETS_CHANGED" then
        Bagger.G.UpdateView()
        Bagger.G.UpdateBagContainer()
    end
end)

function Bagger.Init()
    -- Bagger.Data = {
    --     Characters = {
    --     }
    -- }

    Bagger.Session = {
        Items = {},
        Filtered = {},
        InitialView = true
    }

    Bagger.Settings = {
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
                Field = Bagger.E.SortFields.Name,
                Sort = Bagger.E.SortOrder.Desc
            }
        },
        SortField = { -- TODO: SavedVariables
            Field = Bagger.E.SortFields.Name,
            Sort = Bagger.E.SortOrder.Desc
        }
    }

    -- Build player data
    local playerId = UnitGUID("player")
    local playerName = UnitName("player")

    if playerId == nil or playerName == nil then return end
    playerIdentifier = playerId

    -- Bagger.Data.Characters[playerId] = {
    --     Name = playerName
    -- }
end

function Bagger.GatherItems(type)
    local numFreeSlots = 0

    local items = {}
    local filteredItems = {}
    -- gather items in bag
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local containerItem = Bagger.R.GetContainerItemInfo(bag, slot)
            if containerItem == nil then
                numFreeSlots = numFreeSlots + 1
            else
                local itemInfo = Bagger.R.GetItemInfo(containerItem.hyperlink)
                local ilvl = Bagger.R.GetEffectiveItemLevel(containerItem.hyperlink)
                local invType = Bagger.R.GetInventoryType(containerItem.hyperlink)
                local isNew = C_NewItems.IsNewItem(bag, slot)

                if containerItem.hyperlink == nil then
                    Bagger.GatherItems(type)
                    return
                end

                -- Create Item
                local item = Bagger.T.Item.new(containerItem, itemInfo, ilvl, bag, slot, isNew, invType)
                if (type and item.type == type) or not type then
                    table.insert(filteredItems, item)
                end
                table.insert(items, item)
            end
        end
    end

    -- Bagger.Data.Characters[playerIdentifier].Items = items
    Bagger.Session.Items = items
    Bagger.Session.Filtered = filteredItems

    return items
end

function Bagger.SortItems(type, order)
    if type == Bagger.E.SortFields.COUNT then
        table.sort(Bagger.Session.Filtered,
            function(a, b)
                if order == Bagger.E.SortOrder.Desc then
                    return a.stackCount > b.stackCount
                else
                    return a.stackCount < b.stackCount
                end
            end)
    end

    if type == Bagger.E.SortFields.Name then
        table.sort(Bagger.Session.Filtered,
            function(a, b)
                if order == Bagger.E.SortOrder.Desc then
                    return a.name < b.name
                else
                    return a.name > b.name
                end
            end)
    end

    if type == Bagger.E.SortFields.Icon then
        table.sort(Bagger.Session.Filtered,
            function(a, b)
                if order == Bagger.E.SortOrder.Desc then
                    return a.quality > b.quality
                else
                    return a.quality < b.quality
                end
            end)
    end

    if type == Bagger.E.SortFields.Category then
        table.sort(Bagger.Session.Filtered,
            function(a, b)
                if order == Bagger.E.SortOrder.Desc then
                    return a.type > b.type
                else
                    return a.type < b.type
                end
            end)
    end

    if type == Bagger.E.SortFields.Ilvl then
        table.sort(Bagger.Session.Filtered,
            function(a, b)
                if order == Bagger.E.SortOrder.Desc then
                    return a.ilvl > b.ilvl
                else
                    return a.ilvl < b.ilvl
                end
            end)
    end

    if type == Bagger.E.SortFields.ReqLvl then
        table.sort(Bagger.Session.Filtered,
            function(a, b)
                if order == Bagger.E.SortOrder.Desc then
                    return a.reqLvl > b.reqLvl
                else
                    return a.reqLvl < b.reqLvl
                end
            end)
    end

    if type == Bagger.E.SortFields.Value then
        table.sort(Bagger.Session.Filtered,
            function(a, b)
                if order == Bagger.E.SortOrder.Desc then
                    return a.value > b.value
                else
                    return a.value < b.value
                end
            end)
    end

    -- Always put new on top
    for index, item in ipairs(Bagger.Session.Filtered) do
        if item.isNew == true then
            table.insert(Bagger.Session.Filtered, 1, table.remove(Bagger.Session.Filtered, index))
        end
    end

    Bagger.Settings.SortField.Field = type
    Bagger.Settings.SortField.Sort = order
end

function Bagger.FilterItems(type, items)
    local filtered = {}
    for _, item in ipairs(items) do
        if type == Bagger.E.FilterFields.Weapons then
            if item.type == Enum.ItemClass.Weapon then
                table.insert(filtered, item)
            end
        end
    end

    return filtered
end

-- Slashy
SLASH_BAGGER1 = '/bagger'
SLASH_BAGGER2 = '/bg'
function SlashCmdList.BAGGER(msg, editbox)
    Bagger.G.Toggle()
end

-- Frame Operations
local lastToggledTime = 0
local TOGGLE_TIMEOUT = 0.01

function Bagger.G.Show()
    if Bagger.View == nil then return end

    if (lastToggledTime < GetTime() - TOGGLE_TIMEOUT) and not Bagger.View:IsShown() then
        Bagger.G.UpdateView()
        Bagger.G.UpdateBagContainer()

        PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
        Bagger.View:Show()
        lastToggledTime = GetTime()
    end
end

function Bagger.G.Hide()
    if Bagger.View == nil then return end

    if (lastToggledTime < GetTime() - TOGGLE_TIMEOUT) and Bagger.View:IsShown() then
        PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
        Bagger.View:Hide()
        lastToggledTime = GetTime()
    end
end

function Bagger.G.Toggle()
    if Bagger.View == nil then
        Bagger.G.InitializeGUI()
    end

    if Bagger.View:IsShown() then
        Bagger.G.Hide()
    else
        Bagger.G.Show()
    end
end

hooksecurefunc('OpenBackpack', Bagger.G.Toggle)
hooksecurefunc('CloseBackpack', Bagger.G.Hide)
hooksecurefunc('ToggleBackpack', Bagger.G.Toggle)
hooksecurefunc('OpenBag', Bagger.G.Toggle)
hooksecurefunc('ToggleBag', Bagger.G.Toggle)
