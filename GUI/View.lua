local addonName = ... ---@type string
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class View: AceModule
local view = addon:NewModule('View')

---@class Pooling: AceModule
local pooling = addon:GetModule('Pooling')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Items: AceModule
local items = addon:GetModule('Items')

---@class Filtering: AceModule
local filtering = addon:GetModule('Filtering')

---@class Sorting: AceModule
local sorting = addon:GetModule('Sorting')

---@class BagContainer: AceModule
local bags = addon:GetModule('BagContainer')

---@class CategoryHeaders: AceModule
local categoryHeaders = addon:GetModule('CategoryHeaders')

---@class ItemFrame: AceModule
local itemFrame = addon:GetModule('ItemFrame')

---@class (exact) BagView
---@field itemPool Pool
---@field categoryPool Pool
---@field filterPool Pool
---@field frame Frame
---@field selectedFilter integer
---@field filterIndex integer
local viewPrototype = {}

function view:OnInitialize()
    ---@type BagView[]
    self.views = {}
    self.inCombat = false

    ---@type BagView
    self.inventory = nil
    ---@type BagView
    self.bank = nil

    self:Create(enums.InventoryType.Inventory)
end

---@param inventoryType Enums.InventoryType
function view:Create(inventoryType)
    ---@type BagView
    local newView = {
        itemPool = pooling.Pool.New(),
        categoryPool = pooling.Pool.New(),
        filterPool = pooling.Pool.New(),
        frame = {},
        selectedFilter = 0,
        filterIndex = 1
    }
    newView.selectedFilter = nil

    local viewName = (inventoryType == enums.InventoryType.Inventory and 'Inventory') or 'Bank'

    local f = CreateFrame('Frame', addonName .. viewName, UIParent)
    f:SetFrameStrata('HIGH')
    f:SetSize(600, database:GetViewHeight(inventoryType))

    local position = database:GetViewPosition(inventoryType)
    f:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', position.x, position.y)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetResizeBounds(600, 436, 600, 2000)

    f.texture = f:CreateTexture(nil, 'BACKGROUND')
    f.texture:SetAllPoints(f)
    f.texture:SetColorTexture(0, 0, 0, 0.75)

    -- Input Handling for Inventory (todo: Bank?)
    if inventoryType == enums.InventoryType.Inventory then
        -- Stop ConsolePort from reading buttons
        f:SetScript('OnShow', function(self)
            if _G['ConsolePortInputHandler'] then
                _G['ConsolePortInputHandler']:SetCommand('PADRSHOULDER', self, true, 'LeftButton', 'UIControl', nil)
                _G['ConsolePortInputHandler']:SetCommand('PADLSHOULDER', self, true, 'LeftButton', 'UIControl', nil)

                if _G['Scrap'] then
                    _G['ConsolePortInputHandler']:SetCommand('PAD3', self, true, 'LeftButton', 'UIControl', nil)
                end
            end
        end)

        -- Re-allow ConsolePort Input handling
        f:SetScript('OnHide', function(self)
            if _G['ConsolePortInputHandler'] then
                _G['ConsolePortInputHandler']:Release(self)
            end
        end)

        f:SetPropagateKeyboardInput(true)
        f:SetScript('OnGamePadButtonDown', function(self, key)
            if view.inCombat then return end

            if _G['Scrap'] and key == 'PAD3' then -- Square
                local item = GameTooltip:IsVisible() and select(2, GameTooltip:GetItem())
                if item then
                    _G['Scrap']:ToggleJunk(tonumber(item:match('item:(%d+)')))
                end
                return
            end

            if key ~= 'PADRSHOULDER' and key ~= 'PADLSHOULDER' then return end
            local filterCount = #self.FilterFrame.Buttons

            if key == 'PADRSHOULDER' then -- Right
                if newView.filterIndex == filterCount then
                    newView.filterIndex = 1
                else
                    newView.filterIndex = newView.filterIndex + 1
                end
                self.FilterFrame.Buttons[newView.filterIndex].OnSelect()
            elseif key == 'PADLSHOULDER' then -- Left
                if newView.filterIndex == 1 then
                    newView.filterIndex = filterCount
                else
                    newView.filterIndex = newView.filterIndex - 1
                end
                self.FilterFrame.Buttons[newView.filterIndex].OnSelect()
            end
        end)
    end

    -- Frame Header
    local header = CreateFrame('Frame', nil, f)
    header:SetSize(f:GetWidth(), session.Settings.Defaults.Sections.Header)
    header:SetPoint('TOPLEFT', f, 'TOPLEFT', 1, -1)
    header:EnableMouse(true)

    header.texture = header:CreateTexture(nil, 'BACKGROUND')
    header.texture:SetAllPoints(header)
    header.texture:SetColorTexture(0, 0, 0, 0.5)

    local text = header:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    text:SetPoint('LEFT', header, 'LEFT', 12, 0)
    text:SetWidth(140)
    text:SetJustifyH('LEFT')
    text:SetText(viewName)

    local close = CreateFrame('Button', nil, header)
    close:SetSize(32, 32)
    close:SetPoint('RIGHT', header, 'RIGHT', -6, 0)
    close:SetNormalTexture('Interface\\Addons\\ConsoleBags\\Media\\Close_Normal')
    close:SetHighlightTexture('Interface\\Addons\\ConsoleBags\\Media\\Close_Highlight')
    close:SetPushedTexture('Interface\\Addons\\ConsoleBags\\Media\\Close_Pushed')
    close:SetScript('OnClick', function()
        if inventoryType == enums.InventoryType.Inventory then
            ---@diagnostic disable-next-line: undefined-field
            addon:CloseAllBags()
        elseif inventoryType == enums.InventoryType.Bank then
            ---@diagnostic disable-next-line: undefined-field
            addon:CloseBank()
        end
    end)

    header:RegisterForDrag('LeftButton')
    header:SetScript('OnDragStart', function(self, button)
        self:GetParent():StartMoving()
    end)
    header:SetScript('OnDragStop', function(self)
        self:GetParent():StopMovingOrSizing()
        local x = self:GetParent():GetLeft()
        local y = self:GetParent():GetTop()
        database:SetViewPosition(inventoryType, x, y)
    end)

    f.Header = header

    -- Filters
    filtering:BuildContainer(f, inventoryType, function()
        if inventoryType == enums.InventoryType.Inventory then
            session.InventoryFilter = nil
        elseif inventoryType == enums.InventoryType.Bank then
            session.BankFilter = nil
        end

        self:Update(inventoryType)
    end)

    sorting:Build(f, inventoryType, function() self:Update(inventoryType) end)

    local scroller = CreateFrame('ScrollFrame', nil, f, 'UIPanelScrollFrameTemplate')
    local offset = session.Settings.Defaults.Sections.Header + session.Settings.Defaults.Sections.Filters
        + session.Settings.Defaults.Sections.ListViewHeader
    scroller:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, -offset)
    scroller:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -24, session.Settings.Defaults.Sections.Footer + 2)
    scroller:SetWidth(f:GetWidth())

    -- Disable targetting the scrollbar for CP users
    if _G['ConsolePort'] then
        local scrollerName = addonName .. viewName .. 'ScrollBar'
        if _G[scrollerName] then
            _G[scrollerName]:EnableMouse(false)
        end
    end

    local scrollChild = CreateFrame('Frame')
    scroller:SetScrollChild(scrollChild)
    scrollChild:SetSize(scroller:GetWidth(), 1)

    local footer = CreateFrame('Frame', nil, f)
    footer:SetSize(f:GetWidth(), session.Settings.Defaults.Sections.Footer)
    footer:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 1, 1)

    footer.texture = footer:CreateTexture(nil, 'BACKGROUND')
    footer.texture:SetAllPoints(footer)
    footer.texture:SetColorTexture(0, 0, 0, 0.5)

    if inventoryType == enums.InventoryType.Inventory then
        local goldView = footer:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
        goldView:SetPoint('LEFT', footer, 'LEFT', 12, 0)
        goldView:SetWidth(140)
        goldView:SetJustifyH('LEFT')
        goldView:SetText(GetCoinTextureString(GetMoney()))

        f.gold = goldView

        local defaultButton = CreateFrame('Button', nil, footer)
        defaultButton:SetSize(28, 28)
        defaultButton:SetPoint('RIGHT', footer, 'RIGHT', -6, 0)
        defaultButton:SetNormalTexture('Interface\\Addons\\ConsoleBags\\Media\\Back_Normal')
        defaultButton:SetHighlightTexture('Interface\\Addons\\ConsoleBags\\Media\\Back_Highlight')
        defaultButton:HookScript('OnEnter', function(self)
            GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
            GameTooltip:SetText('Show Default bags temporarily. ', 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        defaultButton:HookScript('OnLeave', function(self)
            GameTooltip:Hide()
        end)
        defaultButton:SetScript('OnClick', function(self, button, down)
            utils.RestoreDefaultBags()
            view.inventory.frame:Hide()
            addon:OpenAllBags()
        end)
    end

    -- Drag Bar
    local drag = CreateFrame('Button', nil, f)
    drag:SetSize(64, 12)
    drag:SetPoint('BOTTOM', f, 'BOTTOM', 0, -6)

    drag:SetScript('OnMouseDown', function(self)
        self:GetParent():StartSizing('BOTTOM')
    end)

    drag:SetScript('OnMouseUp', function(self)
        self:GetParent():StopMovingOrSizing('BOTTOM')
        database:SetViewHeight(inventoryType, self:GetParent():GetHeight())
    end)

    local dragTex = drag:CreateTexture(nil, 'BACKGROUND')
    dragTex:SetAllPoints(drag)
    dragTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Handlebar')


    f.ListView = scrollChild
    f:Hide()

    table.insert(UISpecialFrames, f:GetName())

    utils:CreateBorder(f)

    bags:Build(inventoryType, f)

    if _G['ConsolePort'] then
        _G['ConsolePort']:AddInterfaceCursorFrame(f)
    end

    newView.frame = f
    self.views[inventoryType] = newView

    if inventoryType == enums.InventoryType.Inventory then
        self.inventory = self.views[inventoryType]
    elseif inventoryType == enums.InventoryType.Bank then
        self.bank = self.views[inventoryType]
    end
end

---@param inventoryType Enums.InventoryType
function view:Update(inventoryType)
    if self.views[inventoryType] == nil then return end

    local currentView = self.views[inventoryType]

    Pool.Cleanup(currentView.itemPool)
    Pool.Cleanup(currentView.categoryPool)
    Pool.Cleanup(currentView.filterPool)

    local sessionFilter = nil
    local sessionCats = {}
    if inventoryType == enums.InventoryType.Inventory then
        sessionFilter = session.InventoryFilter
        sessionCats = session.InventoryCollapsedCategories
    elseif inventoryType == enums.InventoryType.Bank then
        sessionFilter = session.BankFilter
        sessionCats = session.BankCollapsedCategories
    end

    -- Categorize
    local catTable = {}
    for _, slots in pairs(session.Items) do
        for _, item in pairs(slots) do
            if item.location == inventoryType then
                utils.AddItemToCategory(item, catTable)
            end
        end
    end

    items:SortItems(catTable, database:GetSortField(inventoryType))

    -- Filter Categories
    local allCategories = {}
    local filteredCategories = {}
    local iter = 1

    for key, value in pairs(catTable) do
        value.key = key
        value.order = enums.Categories[key].order
        value.name = enums.Categories[key].name
        allCategories[iter] = value
        if (key == sessionFilter) or sessionFilter == nil then
            tinsert(filteredCategories, value)
        end
        iter = iter + 1
    end

    table.sort(allCategories, function(a, b) return a.order < b.order end)
    table.sort(filteredCategories, function(a, b) return a.order < b.order end)

    local orderedCategories = {}
    for i = 1, #filteredCategories do
        orderedCategories[i] = filteredCategories[i]
    end

    local orderedAllCategories = {}
    for i = 1, #allCategories do
        orderedAllCategories[i] = allCategories[i]
    end

    local offset = 1
    local catIndex = 1
    local itemIndex = 1
    for _, categoryData in ipairs(orderedCategories) do
        if #categoryData.items > 0 then
            local catFrame = Pool.FetchInactive(currentView.categoryPool, catIndex,
                categoryHeaders.CreateCategoryHeaderPlaceholder)
            Pool.InsertActive(currentView.categoryPool, catFrame, catIndex)
            categoryHeaders:BuildCategoryFrame(categoryData, offset, catFrame, currentView.frame.ListView,
                sessionCats, function() self:Update(inventoryType) end)

            offset = offset + 1
            catIndex = catIndex + 1
            if sessionCats[categoryData.key] ~= true then
                for _, item in ipairs(categoryData.items) do
                    local frame = Pool.FetchInactive(currentView.itemPool, itemIndex,
                        itemFrame.CreateItemFramePlaceholder)
                    Pool.InsertActive(currentView.itemPool, frame, itemIndex)
                    itemFrame:BuildItemFrame(item, offset, frame, currentView.frame.ListView)

                    offset = offset + 1
                    itemIndex = itemIndex + 1
                end
            end
        end
    end

    local function onFilterSelectCallback(key)
        if inventoryType == enums.InventoryType.Inventory then
            session.InventoryFilter = key
        elseif inventoryType == enums.InventoryType.Bank then
            session.BankFilter = key
        end

        self:Update(inventoryType)
    end

    filtering:Update(currentView.frame, orderedAllCategories, currentView.filterPool, onFilterSelectCallback)
    bags:Update(currentView.frame, inventoryType)
end

function view:UpdateCurrency()
    if view.inventory then
        local money = GetMoney()
        if money == nil then return end
        local str = GetCoinTextureString(money)
        if str == nil or str == '' then return end
        view.inventory.frame.gold:SetText(str)
    end
end

--#region Events

function events:PLAYER_MONEY()
    view:UpdateCurrency()
end

function events:BAG_UPDATE_DELAYED()
    items.BuildItemCache()
    if view.inventory and view.inventory.frame:IsShown() then
        view:Update(enums.InventoryType.Inventory)
    end
end

function events:EQUIPMENT_SETS_CHANGED()
    items.BuildItemCache()
    if view.inventory and view.inventory.frame:IsShown() then
        view:Update(enums.InventoryType.Inventory)
    end
end

function events:PLAYER_REGEN_DISABLED()
    view.inCombat = true
    if _G['ConsolePortInputHandler'] then
        -- TODO: All frames?
        _G['ConsolePortInputHandler']:Release(view.inventory.frame)
    end
end

function events:PLAYER_REGEN_ENABLED()
    view.inCombat = false
end

function events:PLAYERBANKSLOTS_CHANGED()
    items.BuildBankCache()
    view:Update(enums.InventoryType.Bank)
end

function events:BANKFRAME_CLOSED()
    view.bank.frame:Hide()
    addon:CloseBank()
end

function events:BANKFRAME_OPENED()
    addon:OpenBank()
    addon:OpenBackpack()
end

--#endregion

view:Enable()
