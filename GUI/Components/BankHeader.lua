local addonName = ... ---@type string

---@class ConsoleBags: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class BankHeader: AceModule
local header = addon:NewModule('BankHeader')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Items: AceModule
local items = addon:GetModule('Items')

---@class BankHeaderFrame
header.proto = {}

---@param parent Frame
---@param type Enums.BankType
---@param width number
---@param onClick function
local function CreateBankButton(parent, type, width, onClick)
    local button = CreateFrame('Button', nil, parent)
    button:SetPoint(type == enums.BankType.Bank and 'LEFT' or 'RIGHT')
    button:SetSize(width, session.Settings.Defaults.Sections.Header - 8)
    button:SetNormalTexture('Interface\\Addons\\ConsoleBags\\Media\\rectangle')
    button:GetNormalTexture():SetVertexColor(0, 0, 0, 0.75)
    button:SetScript('OnClick', onClick)

    button.text = button:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    button.text:SetPoint('CENTER')
    button.text:SetText(type == enums.BankType.Bank and 'Bank' or 'Warbank')
    button.text:SetJustifyH('CENTER')

    local textColor = type == enums.BankType.Bank and { 1, 1, 0 } or { 1, 1, 1 }
    button.text:SetTextColor(unpack(textColor))

    utils:CreateBorder(button)

    return button
end


---@param view BagView
---@param parent Frame
---@return BankHeaderFrame
function header:CreateAdditions(view, parent)
    local i = setmetatable({}, { __index = header.proto })

    ---@class BankHeaderToggles
    local togglerContainer = CreateFrame('Frame', nil, parent)
    togglerContainer:SetPoint('BOTTOMLEFT', parent, 'TOPLEFT', 8, -3)
    togglerContainer:SetSize(146, session.Settings.Defaults.Sections.Header)

    local bank = CreateBankButton(togglerContainer, enums.BankType.Bank, 60,
        function(btn)
            btn.text:SetTextColor(1, 1, 0)
            btn:GetParent().warbank.text:SetTextColor(1, 1, 1)

            view.selectedBankType = enums.BankType.Bank
            addon.status.visitingWarbank = false

            if not session.BuildingBankCache then
                items.BuildBankCache()
            end

            addon.bags.Inventory:Update()

            BankFrame.selectedTab = 1
            BankFrame.activeTabIndex = 1
            AccountBankPanel.selectedTabID = nil

            if session.Bank.Resolved >= session.Bank.TotalCount then
                addon.bags.Bank:Update()
            end

            i:Update(enums.BankType.Bank)
        end)

    local warbank = CreateBankButton(togglerContainer, enums.BankType.Warbank, 80,
        function(btn)
            btn.text:SetTextColor(1, 1, 0)
            btn:GetParent().bank.text:SetTextColor(1, 1, 1)

            view.selectedBankType = enums.BankType.Warbank
            addon.status.visitingWarbank = true

            if not session.BuildingWarbankCache then
                items.BuildWarbankCache()
            end

            addon.bags.Inventory:Update()

            BankFrame.selectedTab = 1
            BankFrame.activeTabIndex = 3
            local tabData = C_Bank.FetchPurchasedBankTabData(Enum.BankType.Account)
            for _, data in pairs(tabData) do
                if data.ID ~= nil then
                    AccountBankPanel.selectedTabID = data.ID
                    break
                end
            end

            if session.Warbank.Resolved >= session.Warbank.TotalCount then
                addon.bags.Bank:Update()
            end

            i:Update(enums.BankType.Warbank)
        end)

    togglerContainer.bank = bank
    togglerContainer.warbank = warbank

    i.toggles = togglerContainer

    -- TODO: # purchased tabs should go in the bag info shit
    ---@class WarbankHeader
    local headerContainer = CreateFrame('Frame', nil, parent)
    headerContainer:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
    headerContainer:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', -200, 0)

    -- if view.selectedBankType == enums.BankType.Warbank then
    -- TODO: Only show if we have tabs to purchase
    -- purchase tab button
    local purchase = CreateFrame('Button', nil, headerContainer)
    purchase:SetPoint('LEFT')
    purchase:SetSize(30, 30)
    purchase:SetNormalTexture('Interface\\Garrison\\GarrisonBuildingUI')
    purchase:SetNormalAtlas('Garr_Building-AddFollowerPlus')
    purchase:HookScript('OnEnter', function()
        GameTooltip:SetOwner(purchase, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetText('Purchase a Warbank Tab for TODO amounts of monies?', 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    purchase:HookScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    purchase:SetScript('OnClick', function()
        StaticPopup_Show("CONFIRM_BUY_BANK_TAB", nil, nil, { bankType = Enum.BankType.Account })
    end)

    local deposit = CreateFrame('Button', nil, headerContainer)
    deposit:SetPoint('LEFT', purchase, 'RIGHT', 8, 0)
    deposit:SetSize(26, 30)
    deposit:SetNormalTexture('Interface\\Minimap\\ObjectIconsAtlas')
    deposit:SetNormalAtlas('poi-traveldirections-arrow2')
    deposit:HookScript('OnEnter', function()
        GameTooltip:SetOwner(deposit, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetText('Deposit All Warbound Items', 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    deposit:HookScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    deposit:SetScript('OnClick', function()
        C_Bank.AutoDepositItemsIntoBank(2)
    end)

    ---@class CheckButton
    local reagentCheck = CreateFrame('CheckButton', nil, headerContainer, 'UICheckButtonTemplate')
    reagentCheck:SetPoint('LEFT', deposit, 'RIGHT', 8, 0)
    reagentCheck:SetSize(26, 26)
    reagentCheck:SetText('Include Reagents')
    reagentCheck:SetChecked(GetCVarBool('bankAutoDepositReagents'))
    reagentCheck:HookScript('OnEnter', function()
        GameTooltip:SetOwner(deposit, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetText('Also include tradeable reagents', 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    reagentCheck:HookScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    reagentCheck:SetScript('OnClick', function()
        SetCVar('bankAutoDepositReagents', reagentCheck:GetChecked())
    end)

    -- end
    headerContainer.purchase = purchase
    headerContainer.deposit = deposit
    headerContainer.reagentCheck = reagentCheck

    headerContainer:Hide()
    i.warbankHeader = headerContainer

    return i
end

---@param bankType Enums.BankType
function header.proto:Update(bankType)
    if bankType == enums.BankType.Bank then
        self.warbankHeader:Hide()
        return
    end
    self.warbankHeader:Show()
end

function header.proto:SetAsBank()
    self.warbankHeader:Hide()

    self.toggles.bank.text:SetTextColor(1, 1, 0)
    self.toggles.warbank.text:SetTextColor(1, 1, 1)

    addon.bags.Bank.selectedBankType = enums.BankType.Bank
    addon.status.visitingWarbank = false
    addon.bags.Inventory:Update()
end

-- if i.selectedBankType == enums.BankType.Warbank then
-- # purchased tabs
-- Money Deposit / Withdraw
-- Show money
-- end

header:Enable()
