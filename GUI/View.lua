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
---@field items ListItem[]
---@field filterContainer FilterContainer
---@field categoryPool Pool
---@field frame Frame
---@field type Enums.InventoryType
view.proto = {}

---@param inventoryType Enums.InventoryType
---@return BagView
function view:Create(inventoryType)
    local i = setmetatable({}, { __index = self.proto })
    i.items = {}
    i.categoryPool = pooling.Pool.New()
    i.type = inventoryType

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
            if InCombatLockdown() then return end

            if _G['Scrap'] and key == 'PAD3' then -- Square
                local item = GameTooltip:IsVisible() and select(2, GameTooltip:GetItem())
                if item then
                    _G['Scrap']:ToggleJunk(tonumber(item:match('item:(%d+)')))
                end
                return
            end

            if key ~= 'PADRSHOULDER' and key ~= 'PADLSHOULDER' then return end

            if key == 'PADRSHOULDER' then     -- Right
                i.filterContainer:ScrollRight()
            elseif key == 'PADLSHOULDER' then -- Left
                i.filterContainer:ScrollLeft()
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
            addon:ToggleAllBags()
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
    local filterContainer = filtering:BuildContainer(f, inventoryType)

    sorting:Build(f, inventoryType, function() i:Update() end)

    local scroller = CreateFrame('ScrollFrame', nil, f, 'UIPanelScrollFrameTemplate')
    local offset = session.Settings.Defaults.Sections.Header + (session.Settings.Defaults.Sections.Filters * 2)
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
            f:Hide()
            OpenAllBags()
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

    i.frame = f
    i.filterContainer = filterContainer

    return i
end

function view.proto:Update()
    -- Empty up the current items
    for _, row in pairs(self.items) do
        row:Empty()
    end

    -- TODO: Pools should be removed for basic pooling
    Pool.Cleanup(self.categoryPool)

    local sessionFilter = nil
    local sessionCats = {}
    if self.type == enums.InventoryType.Inventory then
        sessionFilter = session.InventoryFilter
        sessionCats = session.InventoryCollapsedCategories
    elseif self.type == enums.InventoryType.Bank then
        sessionFilter = session.BankFilter
        sessionCats = session.BankCollapsedCategories
    end

    ---@type CategorizedItemSet[]
    local catTable = {}
    for _, slots in pairs(session.Items) do
        for _, item in pairs(slots) do
            if item.location == self.type then
                utils.AddItemToCategory(item, catTable)
            end
        end
    end

    items:SortItems(catTable, database:GetSortField(self.type))

    ---@type CategorizedItemSet[]
    local allCategories = {}

    ---@type CategorizedItemSet[]
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

    ---@type CategorizedItemSet[]
    local orderedCategories = {}
    for i = 1, #filteredCategories do
        orderedCategories[i] = filteredCategories[i]
    end

    ---@type CategorizedItemSet[]
    local orderedAllCategories = {}
    for i = 1, #allCategories do
        orderedAllCategories[i] = allCategories[i]
    end

    local offset = 1
    local catIndex = 1
    local itemIndex = 1
    for _, categoryData in ipairs(orderedCategories) do
        if #categoryData.items > 0 then
            local catFrame = Pool.FetchInactive(self.categoryPool, catIndex,
                categoryHeaders.CreateCategoryHeaderPlaceholder)
            Pool.InsertActive(self.categoryPool, catFrame, catIndex)
            categoryHeaders:BuildCategoryFrame(categoryData, offset, catFrame, self.frame.ListView,
                sessionCats, function() self:Update() end)

            offset = offset + 1
            catIndex = catIndex + 1
            if sessionCats[categoryData.key] ~= true then
                for _, item in ipairs(categoryData.items) do
                    -- Fetch a frame that we already have, OR get a new one
                    if self.items[itemIndex] then
                        self.items[itemIndex]:Build(item, offset, self.frame.ListView)
                    else
                        local frame = itemFrame:Create()
                        frame:Build(item, offset, self.frame.ListView)
                        tinsert(self.items, frame)
                    end

                    offset = offset + 1
                    itemIndex = itemIndex + 1
                end
            end
        end
    end

    -- Cleanup Unused
    for index, row in pairs(self.items) do
        if row.item == nil then
            row:Clear()
            self.items[index] = nil
        end
    end

    local function onFilterSelectCallback(key)
        if self.type == enums.InventoryType.Inventory then
            session.InventoryFilter = key
        elseif self.type == enums.InventoryType.Bank then
            session.BankFilter = key
        end

        self:Update()
    end

    self.filterContainer:Update(self.type, orderedAllCategories, onFilterSelectCallback)
    bags:Update(self.frame, self.type)
end

---@return boolean
function view.proto:IsShown()
    return self.frame:IsShown()
end

function view.proto:Show()
    self.frame:Show()
end

function view.proto:Hide()
    self.frame:Hide()
end

function view.proto:UpdateCurrency()
    local money = GetMoney()
    if money == nil then return end
    local str = GetCoinTextureString(money)
    if str == nil or str == '' then return end
    self.frame.gold:SetText(str)
end

view:Enable()
