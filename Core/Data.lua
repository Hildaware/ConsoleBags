local addonName = ...

---@class ConsoleBags: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Database: AceModule
local database = addon:NewModule('Database')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class databaseOptions
local defaults = {
    global = {
        Characters = {},
        ViewType = enums.ViewType.Compact,
        BackgroundOpacity = 0.75,
        Font = {
            Name = 'Accidental Presidency',
            Path = 'Interface\\AddOns\\ConsoleBags\\Fonts\\AccidentalPresidency.ttf',
            Size = 12
        },
        InventoryFrame = {
            Size = {
                X = 600,
                Y = 436,
            },
            Position = {
                X = 500,
                Y = 500
            },
            Columns = {
                Icon = 32,
                Name = 320,
                Category = 40,
                Ilvl = 50,
                ReqLvl = 50,
                Value = 110
            },
            ItemHeight = 28,
            SortField = { ---@type SortField
                Field = enums.SortField.Name,
                Sort = enums.SortOrder.Desc
            }
        },
        BankFrame = {
            Size = {
                X = 600,
                Y = 436,
            },
            Position = {
                X = 20,
                Y = 500
            },
            Columns = {
                Icon = 32,
                Name = 280,
                Category = 40,
                Ilvl = 50,
                ReqLvl = 50,
                Value = 110
            },
            SortField = { ---@type SortField
                Field = enums.SortField.Name,
                Sort = enums.SortOrder.Desc
            }
        }
    }
}

function database:OnInitialize()
    database.internal = LibStub('AceDB-3.0'):New(addonName .. 'DB', defaults --[[@as AceDB.Schema]], true) --[[@as databaseOptions]]
end

---@return SortField
function database:GetInventorySortField()
    return self.internal.global.InventoryFrame.SortField
end

---@return SortField
function database:GetBankSortField()
    return database.internal.global.BankFrame.SortField
end

function database:GetInventoryViewPositionY()
    return database.internal.global.InventoryFrame.Position.Y or 200
end

function database:GetInventoryViewPositionX()
    return database.internal.global.InventoryFrame.Position.X or 500
end

function database:GetInventoryViewHeight()
    return database.internal.global.InventoryFrame.Size.Y or 396
end

function database:SetInventoryPosition(x, y)
    database.internal.global.InventoryFrame.Position = { X = x, Y = y }
end

function database:SetInventoryViewHeight(height)
    database.internal.global.InventoryFrame.Size.Y = height
    addon.bags.Inventory:UpdateGUI(enums.InventoryType.Inventory)
end

function database:SetInventoryViewWidth(width)
    database.internal.global.InventoryFrame.Size.X = width
    addon.bags.Inventory:UpdateGUI(enums.InventoryType.Inventory)
end

function database:GetInventoryViewWidth()
    return database.internal.global.InventoryFrame.Size.X or 600
end

function database:GetItemViewHeight()
    return database.internal.global.InventoryFrame.ItemHeight or 28
end

function database:SetItemViewHeight(height)
    database.internal.global.InventoryFrame.ItemHeight = height
    addon.bags.Inventory:UpdateGUI(enums.InventoryType.Inventory)
end

---@return { name: string, path: string, size: number }
function database:GetFont()
    local font = database.internal.global.Font
    return { name = font.Name, path = font.Path, size = font.Size }
end

---@param name string
---@param path string
function database:SetFont(name, path)
    local font = database.internal.global.Font
    font.Name = name
    font.Path = path

    addon.bags.Inventory:UpdateGUI(enums.InventoryType.Inventory)
    addon.bags.Bank:UpdateGUI(enums.InventoryType.Bank)
end

function database:GetBankViewPositionY()
    return database.internal.global.BankFrame.Position.Y or 200
end

function database:GetBankViewPositionX()
    return database.internal.global.BankFrame.Position.X or 500
end

function database:GetBankViewHeight()
    return database.internal.global.BankFrame.Size.Y or 396
end

function database:SetBankPosition(x, y)
    database.internal.global.BankFrame.Position = { X = x, Y = y }
end

function database:SetBankViewHeight(height)
    database.internal.global.BankFrame.Size.Y = height
end

---@param inventoryType Enums.InventoryType
function database:GetViewHeight(inventoryType)
    if inventoryType == enums.InventoryType.Inventory then
        return database:GetInventoryViewHeight()
    elseif inventoryType == enums.InventoryType.Bank then
        return database:GetBankViewHeight()
    end
end

---@param inventoryType Enums.InventoryType
---@param height integer
function database:SetViewHeight(inventoryType, height)
    if inventoryType == enums.InventoryType.Inventory then
        database:SetInventoryViewHeight(height)
    elseif inventoryType == enums.InventoryType.Bank then
        database:SetBankViewHeight(height)
    end
end

---@param inventoryType Enums.InventoryType
---@return {x: integer, y: integer}
function database:GetViewPosition(inventoryType)
    local position = { x = 0, y = 0 }
    if inventoryType == enums.InventoryType.Inventory then
        position.x, position.y = database:GetInventoryViewPositionX(), database:GetInventoryViewPositionY()
    elseif inventoryType == enums.InventoryType.Bank then
        position.x, position.y = database:GetBankViewPositionX(), database:GetBankViewPositionY()
    end

    return position
end

---@param inventoryType Enums.InventoryType
---@param x integer
---@param y integer
function database:SetViewPosition(inventoryType, x, y)
    if inventoryType == enums.InventoryType.Inventory then
        database:SetInventoryPosition(x, y)
    elseif inventoryType == enums.InventoryType.Bank then
        database:SetBankPosition(x, y)
    end
end

---@param inventoryType Enums.InventoryType
---@return SortField
function database:GetSortField(inventoryType)
    if inventoryType == enums.InventoryType.Bank then
        return database:GetBankSortField()
    else
        return database:GetInventorySortField()
    end
end

---@return Enums.ViewType
function database:GetViewType()
    return database.internal.global.ViewType
end

---@param type Enums.ViewType
function database:SetViewType(type)
    database.internal.global.ViewType = type
    addon.bags.Inventory:UpdateGUI(enums.InventoryType.Inventory)
end

---@param opacity number
function database:SetBackgroundOpacity(opacity)
    database.internal.global.BackgroundOpacity = opacity
    addon.bags.Inventory:UpdateGUI(enums.InventoryType.Inventory)
end

---@return number
function database:GetBackgroundOpacity()
    return database.internal.global.BackgroundOpacity
end

database:Enable()
