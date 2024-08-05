local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Filtering: AceModule
local filtering = addon:NewModule('Filtering')

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class FilterItem: Button
---@field texture Texture
---@field backgroundTexture Texture
---@field newTexture Texture
---@field OnSelect function

---@class Filter
---@field widget FilterItem
---@field categoryKey number
---@field Build function
---@field Clear function
filtering.itemProto = {}

---@class FilterButtonContainer: Frame
---@field Children Filter[]

---@class SelectedFilterContainer: Frame
---@field texture Texture
---@field text FontString

---@class AnimatedTexture: Texture
---@field animation AnimationGroup

---@class FilterContainerFrame: Frame
---@field ButtonContainer FilterButtonContainer
---@field SelectedContainer SelectedFilterContainer
---@field LeftButton AnimatedTexture
---@field RightButton AnimatedTexture

---@class FilterContainer: Frame
---@field widget FilterContainerFrame
---@field currentCategories number[]
---@field currentCategoryKey integer
---@field Update function
filtering.proto = {}

---@param callback function
---@param categoryKey integer
local function OnFilterSelect(callback, categoryKey)
    if GameTooltip['shoppingTooltips'] then
        for _, frame in pairs(GameTooltip['shoppingTooltips']) do
            frame:Hide()
        end
    end

    local key = nil
    if categoryKey ~= 999 then
        key = categoryKey
    end
    callback(key)
end

--#region Item

---@param view FilterContainer
---@param inventoryType Enums.InventoryType
---@param categoryData CategorizedItemSet
---@param position number
---@param isMain boolean
---@param callback function
---@return FilterItem
function filtering.itemProto:Build(view, inventoryType, categoryData, position, isMain, callback)
    self.widget:SetParent(view.widget.ButtonContainer)
    self.widget:SetPoint('CENTER', view.widget.ButtonContainer, 'CENTER', position, 0)

    if isMain then
        self.widget:SetScale(1.0)
        self.widget.backgroundTexture:Hide()
    else
        self.widget:SetScale(0.75)
        self.widget.backgroundTexture:Show()
    end

    self.widget:RegisterForClicks('AnyDown')
    self.widget:RegisterForClicks('AnyUp')

    if categoryData.key == 999 then -- ALL
        self.widget.texture:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Logo_Normal')
    else
        self.widget.texture:SetTexture(utils.GetCategoyIcon(categoryData.key))
    end

    if categoryData.hasNew == true then
        self.widget.newTexture:Show()
    else
        self.widget.newTexture:Hide()
    end
    self.widget.OnSelect = function() OnFilterSelect(callback, categoryData.key) end

    self.widget:SetScript('OnClick', function()
        view:OnClickCategory(categoryData.key, callback)
        -- OnFilterSelect(callback, categoryData.key)
    end)

    self.widget:SetScript('OnEnter', function(_)
        GameTooltip:SetOwner(self.widget, 'ANCHOR_TOPRIGHT')

        local count = categoryData.count
        if categoryData.key == 999 then
            if inventoryType == enums.InventoryType.Inventory then
                count = session.Inventory.Count
            elseif inventoryType == enums.InventoryType.Bank then
                count = session.Bank.Count
            end
        end

        GameTooltip:SetText(categoryData.name .. ' (' .. count .. ')', 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    self.categoryKey = categoryData.key

    self.widget:Show()

    return self.widget
end

function filtering.itemProto:Clear()
    self.widget:Hide()
    self.widget:SetParent(nil)
    self.widget:ClearAllPoints()

    if filtering._pool:IsActive(self) then
        filtering._pool:Release(self)
    end
end

--#endregion

--#region Container

---@return integer
function filtering.proto:GetCategoryIndex()
    for index, categoryKey in pairs(self.currentCategories) do
        if categoryKey == self.currentCategoryKey then
            return index
        end
    end
    return -1
end

function filtering.proto:SelectCurrentCategory()
    for _, category in pairs(self.widget.ButtonContainer.Children) do
        if category.categoryKey == self.currentCategoryKey then
            category.widget.OnSelect()
            break
        end
    end
end

function filtering.proto:ScrollLeft()
    local catIndex = self:GetCategoryIndex()

    if catIndex == -1 then
        self.currentCategoryKey = self.currentCategories[#self.currentCategories]
    else
        if catIndex == 1 then
            self.currentCategoryKey = self.currentCategories[#self.currentCategories]
        else
            self.currentCategoryKey = self.currentCategories[catIndex - 1]
        end
    end

    self.widget.LeftButton.animation:Play()
    self:SelectCurrentCategory()
end

---@param category integer
---@param callback function
function filtering.proto:OnClickCategory(category, callback)
    self.currentCategoryKey = category
    self:SelectCurrentCategory()

    if GameTooltip['shoppingTooltips'] then
        for _, frame in pairs(GameTooltip['shoppingTooltips']) do
            frame:Hide()
        end
    end

    local key = nil
    if category ~= 999 then
        key = category
    end
    callback(key)
end

function filtering.proto:ScrollRight()
    local catIndex = self:GetCategoryIndex()

    if catIndex == -1 then
        self.currentCategoryKey = self.currentCategories[1]
    else
        if catIndex == #self.currentCategories then
            self.currentCategoryKey = self.currentCategories[1]
        else
            self.currentCategoryKey = self.currentCategories[catIndex + 1]
        end
    end

    self.widget.RightButton.animation:Play()
    self:SelectCurrentCategory()
end

---@param inventoryType Enums.InventoryType
---@param categories CategorizedItemSet[]
---@param callback function
function filtering.proto:Update(inventoryType, categories, callback)
    self.currentCategoryKey = self.currentCategoryKey or 999

    -- Update the categories
    self.currentCategories = {}
    tinsert(self.currentCategories, 999)
    for _, category in pairs(categories) do
        tinsert(self.currentCategories, category.key)
    end

    -- Clear the kids
    for index, item in pairs(self.widget.ButtonContainer.Children) do
        item:Clear()
        self.widget.ButtonContainer.Children[index] = nil
    end
    self.widget.ButtonContainer.Children = {}

    -- Insert 'All' before any others
    table.insert(categories, 1, { key = 999, name = 'All', count = 0, order = 0 })

    local maxItemsShown = math.min(#categories, 17) -- TODO: Variable based on width?
    local maxPerSide = math.ceil(#categories / 2) - 1
    local maxPerSideShown = math.floor(maxItemsShown / 2)
    local keyFrameIndex = math.ceil(maxItemsShown / 2)
    local currentIndex = keyFrameIndex - 1

    ---@type CategorizedItemSet
    local newKeyCategory = {
        key = 999,
        name = 'All',
        count = 0,
        hasNew = false,
        order = 0,
        items = {}
    }
    local newCategoryIndex = 0
    for index, categoryData in pairs(categories) do
        if categoryData.key == self.currentCategoryKey then
            newCategoryIndex = index
            newKeyCategory = categoryData
            break
        end
    end

    local newKeyFrame = filtering:Create()
    newKeyFrame:Build(self, inventoryType, newKeyCategory, 0, true, callback)

    local count = newKeyCategory.count
    if newKeyCategory.key == 999 then
        if inventoryType == enums.InventoryType.Inventory then
            count = session.Inventory.Count
        elseif inventoryType == enums.InventoryType.Bank then
            count = session.Bank.Count
        end
    end
    local catText = string.upper(newKeyCategory.name .. ' (' .. count .. ')')
    self.widget.SelectedContainer.text:SetText(catText)

    self.widget.ButtonContainer.Children[keyFrameIndex] = newKeyFrame

    -- build the left side
    local leftIndex = newCategoryIndex
    for i = 1, maxPerSide, 1 do
        leftIndex = leftIndex - 1
        if leftIndex < 1 then
            leftIndex = #categories
        end

        local leftFrame = filtering:Create()
        leftFrame:Build(self, inventoryType, categories[leftIndex], (-32 * i) - 10, false, callback)
        self.widget.ButtonContainer.Children[currentIndex] = leftFrame

        if i > maxPerSideShown then
            leftFrame.widget:Hide()
        end

        currentIndex = currentIndex - 1
    end

    -- build the right side
    currentIndex = keyFrameIndex + 1
    local rightIndex = newCategoryIndex
    for i = 1, maxPerSide, 1 do
        rightIndex = rightIndex + 1
        if rightIndex > #categories then
            rightIndex = 1
        end

        local rightFrame = filtering:Create()
        rightFrame:Build(self, inventoryType, categories[rightIndex], (32 * i) + 10, false, callback)
        self.widget.ButtonContainer.Children[currentIndex] = rightFrame

        if i > maxPerSideShown then
            rightFrame.widget:Hide()
        end

        currentIndex = currentIndex + 1
    end
end

--#endregion

function filtering:OnInitialize()
    self._pool = CreateObjectPool(self._DoCreate, self._DoReset)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end

    ---@type Filter[]
    local frames = {}
    for i = 1, 40 do
        frames[i] = self:Create()
    end
    for _, frame in pairs(frames) do
        frame:Clear()
    end
end

---@param view Frame
---@param type Enums.InventoryType
---@return FilterContainer
function filtering:BuildContainer(view, type)
    ---@type FilterContainer
    local i = setmetatable({}, { __index = filtering.proto })

    local filterContainer = CreateFrame('Frame', nil, view)
    filterContainer:SetSize(view:GetWidth(), session.Settings.Defaults.Sections.Filters)
    filterContainer:SetPoint('TOPLEFT', view, 'TOPLEFT', 0, -session.Settings.Defaults.Sections.Header)

    local buttonContainer = CreateFrame('Frame', nil, filterContainer)
    buttonContainer:SetPoint('TOPLEFT', filterContainer, 'TOPLEFT', 34, 0)
    buttonContainer:SetPoint('BOTTOMRIGHT', filterContainer, 'BOTTOMRIGHT', -34, 0)

    local selected = buttonContainer:CreateTexture(nil, 'ARTWORK')
    selected:SetPoint('TOP')
    selected:SetPoint('BOTTOM')
    selected:SetWidth(32)
    selected:SetColorTexture(1, 1, 0, 0.25)

    -- mask
    local mask = buttonContainer:CreateMaskTexture()
    mask:SetAllPoints(selected)
    mask:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\box', 'CLAMPTOBLACKADDITIVE',
        'CLAMPTOBLACKADDITIVE')
    selected:AddMaskTexture(mask)

    buttonContainer.Children = {}

    -- LEFT / RIGHT Buttons
    if _G['ConsolePort'] and type == enums.InventoryType.Inventory then
        local lTexture = filterContainer:CreateTexture(nil, 'ARTWORK')
        lTexture:SetPoint('LEFT', filterContainer, 'LEFT', 6, 0)
        lTexture:SetSize(24, 24)
        lTexture:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\lb')

        local anim = lTexture:CreateAnimationGroup()
        local scaleOut = anim:CreateAnimation('Scale')
        scaleOut:SetScaleFrom(1, 1)
        scaleOut:SetScaleTo(1.5, 1.5)
        scaleOut:SetDuration(0.2)
        scaleOut:SetSmoothing('OUT')

        lTexture.animation = anim
        filterContainer.LeftButton = lTexture

        local rTexture = filterContainer:CreateTexture(nil, 'ARTWORK')
        rTexture:SetPoint('RIGHT', filterContainer, 'RIGHT', -6, 0)
        rTexture:SetSize(24, 24)
        rTexture:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\rb')

        local animRight = rTexture:CreateAnimationGroup()
        local scaleOutRight = animRight:CreateAnimation('Scale')
        scaleOutRight:SetScaleFrom(1, 1)
        scaleOutRight:SetScaleTo(1.5, 1.5)
        scaleOutRight:SetDuration(0.2)
        scaleOutRight:SetSmoothing('OUT')

        rTexture.animation = animRight
        filterContainer.RightButton = rTexture
    end

    local selectedContainer = CreateFrame('Frame', nil, filterContainer)
    selectedContainer:SetPoint('TOP', buttonContainer, 'BOTTOM', 0, 0)
    selectedContainer:SetSize(view:GetWidth(), session.Settings.Defaults.Sections.Filters)

    local selectedTex = selectedContainer:CreateTexture(nil, 'ARTWORK')
    selectedTex:SetAllPoints(selectedContainer)
    selectedTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Underline')
    selectedTex:SetVertexColor(1, 1, 1, 0.5)

    local selectedText = selectedContainer:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    selectedText:SetPoint('CENTER', selectedContainer, 'CENTER', 0, 0)
    selectedText:SetJustifyH('CENTER')
    selectedText:SetJustifyV('MIDDLE')
    selectedText:SetTextColor(1, 1, 0, 1)
    selectedText:SetText(string.upper('All'))

    selectedContainer.text = selectedText

    filterContainer.ButtonContainer = buttonContainer
    filterContainer.SelectedContainer = selectedContainer

    i.widget = filterContainer --[[@as FilterContainerFrame]]

    return i
end

---@return Filter
function filtering:Create()
    return self._pool:Acquire()
end

---@return Filter
function filtering:_DoCreate()
    local i = setmetatable({}, { __index = filtering.itemProto })

    ---@type Button
    local f = CreateFrame('Button')
    f:SetSize(28, session.Settings.Defaults.Sections.Filters)

    local tex = f:CreateTexture(nil, 'ARTWORK')
    tex:SetPoint('CENTER', 0, 'CENTER')
    tex:SetSize(24, 24)

    f.texture = tex
    f:RegisterForClicks('AnyDown')
    f:RegisterForClicks('AnyUp')

    local background = f:CreateTexture(nil, 'BACKGROUND')
    background:SetAllPoints(f)
    background:SetColorTexture(1, 1, 1, 0.1)

    local mask = f:CreateMaskTexture()
    mask:SetAllPoints(background)
    mask:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\box', 'CLAMPTOBLACKADDITIVE',
        'CLAMPTOBLACKADDITIVE')
    background:AddMaskTexture(mask)

    f.backgroundTexture = background

    local newTex = f:CreateTexture(nil, 'OVERLAY')
    newTex:SetPoint('TOPRIGHT', f, 'TOPRIGHT', 0, -4)
    newTex:SetSize(12, 12)
    newTex:SetTexture('Interface\\Addons\\ConsoleBags\\Media\\Exclamation')
    newTex:Hide()

    f.newTexture = newTex

    f:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    i.widget = f --[[@as FilterItem]]

    return i
end

function filtering:_DoReset(item)
end

filtering:Enable()
