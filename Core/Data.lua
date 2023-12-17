local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Database: AceModule
local database = addon:NewModule('Database')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class databaseOptions
local defaults = {
    global = {
        Characters = {},
        InventoryFrame = {
            Size = {
                X = 600,
                Y = 396,
            },
            Position = {
                X = 500,
                Y = 200
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
                Field = enums.SortFields.Name,
                Sort = enums.SortOrder.Desc
            }
        },
        BankFrame = {
            Size = {
                X = 600,
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
                Field = enums.SortFields.Name,
                Sort = enums.SortOrder.Desc
            }
        }
    }
}

function database:OnInitialize()
    database.internal = LibStub('AceDB-3.0'):New(addonName .. 'DB', defaults --[[@as AceDB.Schema]], true) --[[@as databaseOptions]]
end

function database:GetInventorySortField()
    return self.internal.global.InventoryFrame.SortField
end

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

database:Enable()