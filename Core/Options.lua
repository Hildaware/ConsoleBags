local addonName = ...

---@class ConsoleBags: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
---@cast addon +AceConsole-3.0

local LSM = LibStub("LibSharedMedia-3.0")

---@class Options: AceModule
local options = addon:NewModule('Options')

---@class Database: AceModule
local database = addon:GetModule('Database')

local optionsFrame

---@class AceConfig.OptionsTable
local settings = {
    type = 'group',
    args = {
        baseOptions = {
            name = 'General Config',
            type = 'group',
            order = 1,
            args = {
                viewType = {
                    name = 'View Type',
                    desc = 'The view to use for the widget.',
                    type = 'select',
                    order = 1,
                    values = {
                        ['compact'] = 'Compact',
                        ['full'] = 'Full',
                    },
                    get = function() return database:GetViewType() end,
                    set = function(_, value) database:SetViewType(value) end
                },
                font = {
                    name = 'Font',
                    desc = 'The font to use for the view.',
                    type = 'select',
                    dialogControl = 'LSM30_Font',
                    values = LSM:HashTable(LSM.MediaType.FONT),
                    get = function()
                        return database:GetFont().name
                    end,
                    set = function(_, font)
                        database:SetFont(font, LSM:HashTable(LSM.MediaType.FONT)[font])
                    end
                },
                fontSize = {
                    name = 'Font Size',
                    desc = 'The font size to use for the view.',
                    type = 'range',
                    min = 10,
                    max = 100,
                    step = 1,
                    get = function() return database:GetFontSize() end,
                    set = function(_, value) database:SetFontSize(value) end
                },
                itemWidth = {
                    name = 'Item Width',
                    desc = 'The width of each item in the view.',
                    type = 'range',
                    min = 600,
                    max = 1200,
                    step = 1,
                    get = function() return database:GetInventoryViewWidth() end,
                    set = function(_, value) database:SetInventoryViewWidth(value) end
                },
                itemHeight = {
                    name = 'Item Height',
                    desc = 'The height of each item in the view.',
                    type = 'range',
                    min = 28,
                    max = 100,
                    step = 1,
                    get = function() return database:GetItemViewHeight() end,
                    set = function(_, value) database:SetItemViewHeight(value) end
                }
            }
        }
    }
}

function options:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, settings)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, 'Console Bags')

    addon:RegisterChatCommand('consolebags', 'SlashCommand')
    addon:RegisterChatCommand('cb', 'SlashCommand')
end

---@param key string
---@param aceOptions AceConfig.OptionsTable
function options:AddSettings(key, aceOptions)
    settings.args[key] = aceOptions

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, settings)
end

---@param msg string
function addon:SlashCommand(msg)
    LibStub("AceConfigDialog-3.0"):Open(addonName)
    -- if msg == '' then
    --     LibStub("AceConfigDialog-3.0"):Open(addonName)
    --     return
    -- end

    -- if msg == 'debug' then
    --     ---@class Debug: AceModule
    --     local debug = addon:GetModule('Debug')
    --     debug:Enable()
    --     debug:Show()
    --     return
    -- end
end

options:Enable()
