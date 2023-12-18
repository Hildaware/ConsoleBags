local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Inventory: AceModule
local inventory = addon:NewModule('Inventory')

---@class GUIUtils: AceModule
local guiUtils = addon:GetModule('GUIUtils')

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

---@class Items: AceModule
local items = addon:GetModule('Items')

---@class BagContainer: AceModule
local bags = addon:GetModule('BagContainer')

---@class CategoryHeaders: AceModule
local categoryHeaders = addon:GetModule('CategoryHeaders')

---@class ItemFrame: AceModule
local itemFrame = addon:GetModule('ItemFrame')

---@class Events: AceModule
local events = addon:GetModule('Events')

-- Frame Pools
local ItemPool = pooling.Pool.New()
local CategoryPool = pooling.Pool.New()
local FilterPool = pooling.Pool.New()

function inventory:OnInitialize()
    local inventoryType = enums.InventoryType.Inventory

    self.inCombat = false

    local f = CreateFrame('Frame', 'ConsoleBagsInventory', UIParent)
    f:SetFrameStrata('HIGH')
    f:SetSize(600, database:GetInventoryViewHeight())
    f:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', database:GetInventoryViewPositionX(),
        database:GetInventoryViewPositionY())
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetResizeBounds(600, 396, 600, 2000)

    f.texture = f:CreateTexture(nil, 'BACKGROUND')
    f.texture:SetAllPoints(f)
    f.texture:SetColorTexture(0, 0, 0, 0.75)

    -- Stop ConsolePort from reading buttons
    f:SetScript('OnShow', function(self)
        if _G['ConsolePortInputHandler'] then
            _G['ConsolePortInputHandler']:SetCommand('PADRSHOULDER', self, true, 'LeftButton', 'UIControl', nil)
            _G['ConsolePortInputHandler']:SetCommand('PADLSHOULDER', self, true, 'LeftButton', 'UIControl', nil)

            if _G["Scrap"] then
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
        if inventory.inCombat then return end

        if _G["Scrap"] and key == "PAD3" then -- Square
            local item = GameTooltip:IsVisible() and select(2, GameTooltip:GetItem())
            if item then
                _G["Scrap"]:ToggleJunk(tonumber(item:match('item:(%d+)')))
            end
            return
        end

        if key ~= 'PADRSHOULDER' and key ~= 'PADLSHOULDER' then return end
        local filterCount = #self.FilterFrame.Buttons
        local index = self.FilterFrame.SelectedIndex

        if key == 'PADRSHOULDER' then -- Right
            if index == filterCount then
                self.FilterFrame.SelectedIndex = 1
            else
                self.FilterFrame.SelectedIndex = self.FilterFrame.SelectedIndex + 1
            end
            self.FilterFrame.Buttons[self.FilterFrame.SelectedIndex].OnSelect()
        elseif key == 'PADLSHOULDER' then -- Left
            if index == 1 then
                self.FilterFrame.SelectedIndex = filterCount
            else
                self.FilterFrame.SelectedIndex = self.FilterFrame.SelectedIndex - 1
            end
            self.FilterFrame.Buttons[self.FilterFrame.SelectedIndex].OnSelect()
        end
    end)

    -- Frame Header
    local header = CreateFrame('Frame', nil, f)
    header:SetSize(f:GetWidth(), session.Settings.Defaults.Sections.Header)
    header:SetPoint('TOPLEFT', f, 'TOPLEFT', 1, -1)
    header:EnableMouse(true)

    header.texture = header:CreateTexture(nil, 'BACKGROUND')
    header.texture:SetAllPoints(header)
    header.texture:SetColorTexture(0, 0, 0, 0.5)

    local close = CreateFrame('Button', nil, header)
    close:SetSize(32, 32)
    close:SetPoint('RIGHT', header, 'RIGHT', -6, 0)
    close:SetNormalTexture('Interface\\Addons\\ConsoleBags\\Media\\Close_Normal')
    close:SetHighlightTexture('Interface\\Addons\\ConsoleBags\\Media\\Close_Highlight')
    close:SetPushedTexture('Interface\\Addons\\ConsoleBags\\Media\\Close_Pushed')
    close:SetScript('OnClick', function()
        addon:CloseAllBags()
    end)

    -- Re-add this once we create the footer
    -- local defaultButton = CreateFrame('Button', nil, header)
    -- defaultButton:SetSize(32, 32)
    -- defaultButton:SetPoint('LEFT', header, 'LEFT', 6, 0)
    -- defaultButton:SetNormalTexture('Interface\\Addons\\ConsoleBags\\Media\\Back_Normal')
    -- defaultButton:SetHighlightTexture('Interface\\Addons\\ConsoleBags\\Media\\Back_Highlight')
    -- defaultButton:HookScript('OnEnter', function(self)
    --     GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
    --     GameTooltip:SetText('Show Default bags temporarily. ', 1, 1, 1, 1, true)
    --     GameTooltip:Show()
    -- end)
    -- defaultButton:HookScript('OnLeave', function(self)
    --     GameTooltip:Hide()
    -- end)
    -- defaultButton:SetScript('OnClick', function(self, button, down)
    --     CB.U.RestoreDefaultBags()
    --     CloseAllBags()
    --     OpenAllBags()
    -- end)

    local goldView = header:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    goldView:SetPoint('LEFT', header, 'LEFT', 12, 0)
    goldView:SetWidth(140)
    goldView:SetJustifyH('LEFT')
    goldView:SetText(GetCoinTextureString(GetMoney()))

    f.GoldView = goldView

    header:RegisterForDrag('LeftButton')
    header:SetScript('OnDragStart', function(self, button)
        self:GetParent():StartMoving()
    end)
    header:SetScript('OnDragStop', function(self)
        self:GetParent():StopMovingOrSizing()
        local x = self:GetParent():GetLeft()
        local y = self:GetParent():GetTop()
        database:SetInventoryPosition(x, y)
    end)

    f.Header = header

    -- Drag Bar
    local drag = CreateFrame('Button', nil, f)
    drag:SetSize(64, 12)
    drag:SetPoint('BOTTOM', f, 'BOTTOM', 0, -6)
    drag:SetScript('OnMouseDown', function(self)
        self:GetParent():StartSizing('BOTTOM')
    end)
    drag:SetScript('OnMouseUp', function(self)
        self:GetParent():StopMovingOrSizing('BOTTOM')
        database:SetInventoryViewHeight(self:GetParent():GetHeight())
    end)
    local dragTex = drag:CreateTexture(nil, 'BACKGROUND')
    dragTex:SetAllPoints(drag)
    dragTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Handlebar')

    -- Filters
    guiUtils:BuildFilteringContainer(f, inventoryType, function()
        session.InventoryFilter = nil
        self:Update()
    end)

    -- 'Header'
    guiUtils:BuildSortingContainer(f, inventoryType, function() self:Update() end)

    local scroller = CreateFrame('ScrollFrame', nil, f, 'UIPanelScrollFrameTemplate')
    local offset = session.Settings.Defaults.Sections.Header + session.Settings.Defaults.Sections.Filters
        + session.Settings.Defaults.Sections.ListViewHeader
    scroller:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, -offset)
    scroller:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -24, 2)
    scroller:SetWidth(f:GetWidth())

    local scrollChild = CreateFrame('Frame')
    scroller:SetScrollChild(scrollChild)
    scrollChild:SetSize(scroller:GetWidth(), 1)

    f.ListView = scrollChild
    f:Hide()

    table.insert(UISpecialFrames, f:GetName())

    guiUtils:CreateBorder(f)

    self.View = f

    bags:CreateBags(inventoryType, self.View)

    if _G['ConsolePort'] then
        _G['ConsolePort']:AddInterfaceCursorFrame(self.View)
    end
end

function inventory:Update()
    if self.View == nil then return end

    local inventoryType = enums.InventoryType.Inventory

    Pool.Cleanup(ItemPool)
    Pool.Cleanup(CategoryPool)
    Pool.Cleanup(FilterPool)

    -- Categorize
    local catTable = {}
    for _, slots in pairs(session.Items) do
        for _, item in pairs(slots) do
            if item.location == enums.InventoryType.Inventory then
                utils.AddItemToCategory(item, catTable)
            end
        end
    end

    items:SortItems(catTable, database:GetInventorySortField())

    -- Filter Categories
    local allCategories = {}
    local filteredCategories = {}
    local iter = 1
    for key, value in pairs(catTable) do
        value.key = key
        value.order = enums.Categories[key].order
        value.name = enums.Categories[key].name
        allCategories[iter] = value
        if (key == session.InventoryFilter) or session.InventoryFilter == nil then
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
            local catFrame = Pool.FetchInactive(CategoryPool, catIndex, categoryHeaders.CreateCategoryHeaderPlaceholder)
            Pool.InsertActive(CategoryPool, catFrame, catIndex)
            categoryHeaders:BuildCategoryFrame(categoryData, offset, catFrame, self.View.ListView,
                session.InventoryCollapsedCategories, function() self:Update() end)

            offset = offset + 1
            catIndex = catIndex + 1
            if session.InventoryCollapsedCategories[categoryData.key] ~= true then
                for _, item in ipairs(categoryData.items) do
                    local frame = Pool.FetchInactive(ItemPool, itemIndex, itemFrame.CreateItemFramePlaceholder)
                    Pool.InsertActive(ItemPool, frame, itemIndex)
                    itemFrame:BuildItemFrame(item, offset, frame, self.View.ListView)

                    offset = offset + 1
                    itemIndex = itemIndex + 1
                end
            end
        end
    end

    local function onFilterSelectCallback(key)
        session.InventoryFilter = key
        self:Update()
    end

    guiUtils:UpdateFilterButtons(self.View, orderedAllCategories, FilterPool, onFilterSelectCallback)
    bags:UpdateBags(self.View, inventoryType)
end

function inventory:UpdateCurrency()
    if self.View then
        self.View.GoldView:SetText(GetCoinTextureString(GetMoney()))
    end
end

function events:PLAYER_MONEY()
    inventory:UpdateCurrency()
end

function events:BAG_UPDATE_DELAYED()
    items.BuildItemCache()
    if inventory.View and inventory.View:IsShown() then
        inventory:Update()
    end
end

function events:EQUIPMENT_SETS_CHANGED()
    items.BuildItemCache()
    if inventory.View and inventory.View:IsShown() then
        inventory:Update()
    end
end

function events:PLAYER_REGEN_DISABLED()
    inventory.inCombat = true
    if _G['ConsolePortInputHandler'] then
        _G['ConsolePortInputHandler']:Release(inventory.View)
    end
end

function events:PLAYER_REGEN_ENABLED()
    inventory.inCombat = false
end

inventory:Enable()
