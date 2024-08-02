---@meta

--[[
    Utilize this file specifically for telling the IDE that the following functions are legit.
    It literally does nothing but make the squigglies go bye bye.
]]


--#region Bank Header

---@class BankHeaderToggles: Frame
---@field bank Button
---@field warbank Button

---@class WarbankHeader: Frame
---@field purchase Button
---@field deposit Button
---@field reagentCheck CheckButton

---@class BankHeaderFrame: Frame
---@field toggles BankHeaderToggles
---@field warbankHeader WarbankHeader

--#endregion
