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

---@class SimpleButton: AceModule
local button = addon:GetModule('SimpleButton')

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

            i:UpdateState(enums.BankType.Bank)
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

            i:UpdateState(enums.BankType.Warbank)
        end)

    togglerContainer.bank = bank
    togglerContainer.warbank = warbank

    i.toggles = togglerContainer

    -- TODO: # purchased tabs should go in the bag info shit
    ---@class WarbankHeader
    local headerContainer = CreateFrame('Frame', nil, parent)
    headerContainer:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
    headerContainer:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', -200, 0)

    --#region Actions

    ---@type Size
    local baseButtonSize = { width = 30, height = 30 }

    local purchase = button:Create(headerContainer, 'Interface\\Garrison\\GarrisonBuildingUI',
        'Garr_Building-AddFollowerPlus', baseButtonSize)

    purchase:SetPoint('LEFT', headerContainer, 'LEFT', 8, 0)
    purchase:OnClick(function()
        StaticPopup_Show("CONFIRM_BUY_BANK_TAB", nil, nil, { bankType = Enum.BankType.Account })
    end)

    local purchaseCost = utils.FormatMoney(C_Bank.FetchNextPurchasableBankTabCost(2))
    purchase:SetTooltip(string.format('Purchase a Warbank Tab for %s', purchaseCost))

    if C_Bank.HasMaxBankTabs(2) then
        purchase.base:Hide()
    end

    local depositIconSize = { width = 20, height = 24 }
    local deposit = button:Create(headerContainer, 'Interface\\Minimap\\ObjectIconsAtlas',
        'poi-traveldirections-arrow2', baseButtonSize, depositIconSize)

    local setPoint = purchase.base:IsShown() and purchase.base or headerContainer
    local relativeTo = purchase.base:IsShown() and 'RIGHT' or 'LEFT'
    deposit:SetPoint('LEFT', setPoint, relativeTo, 8, 0)
    deposit:OnClick(function()
        C_Bank.AutoDepositItemsIntoBank(2)
    end)
    deposit:SetTooltip('Deposit All Warbound Items')

    ---@class CheckButton
    local reagentCheck = CreateFrame('CheckButton', nil, headerContainer, 'UICheckButtonTemplate')
    reagentCheck:SetPoint('TOPLEFT', deposit.base, 'TOPRIGHT', 2, 0)
    reagentCheck:SetSize(20, 20)
    reagentCheck:SetText('Include Reagents')
    reagentCheck:SetChecked(GetCVarBool('bankAutoDepositReagents'))
    reagentCheck:HookScript('OnEnter', function()
        GameTooltip:SetOwner(reagentCheck, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetText('Also include tradeable reagents', 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    reagentCheck:HookScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    reagentCheck:SetScript('OnClick', function()
        SetCVar('bankAutoDepositReagents', reagentCheck:GetChecked())
    end)

    --#endregion

    --#region Money

    local moneyDeposit = button:Create(headerContainer, 'Interface\\MainMenuBar\\MainMenuBar',
        'hud-MainMenuBar-arrowdown-up', baseButtonSize)

    moneyDeposit:SetPoint('LEFT', deposit.base, 'RIGHT', 120, 0)
    moneyDeposit:OnClick(function()
        StaticPopup_Show("BANK_MONEY_DEPOSIT", nil, nil, { bankType = 2 })
    end)
    moneyDeposit:SetTooltip(BANK_DEPOSIT_MONEY_BUTTON_LABEL)

    local moneyWithdraw = button:Create(headerContainer, 'Interface\\MainMenuBar\\MainMenuBar',
        'hud-MainMenuBar-arrowup-up', baseButtonSize)

    moneyWithdraw:SetPoint('LEFT', moneyDeposit.base, 'RIGHT', 2, 0)
    moneyWithdraw:OnClick(function()
        StaticPopup_Show("BANK_MONEY_WITHDRAW", nil, nil, { bankType = 2 })
    end)
    moneyWithdraw:SetTooltip(BANK_WITHDRAW_MONEY_BUTTON_LABEL)

    local goldView = headerContainer:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    goldView:SetPoint('LEFT', moneyWithdraw.base, 'RIGHT', 8, 0)
    goldView:SetWidth(140)
    goldView:SetJustifyH('LEFT')
    goldView:SetText(GetCoinTextureString(C_Bank.FetchDepositedMoney(2)))

    --#endregion

    headerContainer.purchase = purchase
    headerContainer.deposit = deposit
    headerContainer.reagentCheck = reagentCheck
    headerContainer.money = goldView

    headerContainer:Hide()
    i.warbankHeader = headerContainer

    return i
end

function header.proto:Update()
    if C_Bank.HasMaxBankTabs(2) then
        local purchase = self.warbankHeader.purchase
        purchase:Hide()

        local setPoint = purchase.base:IsShown() and purchase.base or self.warbankHeader
        local relativeTo = purchase.base:IsShown() and 'RIGHT' or 'LEFT'
        self.warbankHeader.deposit:SetPoint('LEFT', setPoint, relativeTo, 8, 0)
    else
        local purchaseCost = utils.FormatMoney(C_Bank.FetchNextPurchasableBankTabCost(2))
        self.warbankHeader.purchase:SetTooltip(string.format('Purchase a Warbank Tab for %s', purchaseCost))
    end

    self.warbankHeader.money:SetText(GetCoinTextureString(C_Bank.FetchDepositedMoney(2)))
end

---@param bankType Enums.BankType
function header.proto:UpdateState(bankType)
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

header:Enable()
