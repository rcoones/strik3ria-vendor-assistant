--[[
Name: Strik3ria's Vendor Assistant
Description: Sells grey items and repairs your items using guild funds if possible

I honestly have no clue what I am supposed to do with the license but this coder
below in the copywrite is the one who wrote the original functionality, I just added some stuff
to make it a little more customizable and to default to not using guild repairs.
But this is the real hero. - Strik3ria
Copyright 2017 Mateusz Kasprzak

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]
local addonName, localization = ...

VendorAssistant = LibStub("AceAddon-3.0"):NewAddon("VendorAssistant", "AceConsole-3.0", "AceEvent-3.0")

local options = {
    name = "Vendor Assistant",
    handler = VendorAssistant,
    type = "group",
    args = {
        guild = {
            name = "Toggle Guild Repairs",
            desc = "Toggle using guild funds for repairs",
            type = "toggle",
            get = "GetGuildFunds",
            set = "SetGuildFunds",
        },
    }
}

local defaults = {
    profile = {
        guildFunds = false,
    }
}

function VendorAssistant:GetGuildFunds(info)
    return self.db.profile.guildFunds
end

function VendorAssistant:SetGuildFunds(info, value)
    self.db.profile.guildFunds = value
end

local sortButton = CreateFrame("Button", "SortBagsActionButton", UIParent, "SecureActionButtonTemplate")
sortButton:SetScript("OnClick", C_Container.SortBags)

function VendorAssistant:OnInitialize()
    if GetBindingKey("CLICK SortBagsActionButton:LeftButton") == nil then
        SetBinding("ALT-S", "CLICK SortBagsActionButton:LeftButton")
    end

    self.db = LibStub("AceDB-3.0"):New("VendorAssistantDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("VendorAssistant_Options", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("VendorAssistant_Options", "VendorAssistant")
    
    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("VendorAssistant_Profiles", profiles)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("VendorAssistant_Profiles", "Profiles", "VendorAssistant")

    self:RegisterChatCommand("va", "SlashCommand")
end

function VendorAssistant:OnEnable()
    self:RegisterEvent("MERCHANT_SHOW")
end

function VendorAssistant:MERCHANT_SHOW()
    -- Auto Sell Grey Items
    local totalPrice = 0
    for myBags = 0,4 do
        for bagSlots = 1, C_Container.GetContainerNumSlots(myBags) do
            CurrentItemLink = C_Container.GetContainerItemLink(myBags, bagSlots)
            if CurrentItemLink then
                local _, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = C_Item.GetItemInfo(CurrentItemLink)
                local itemInfo = C_Container.GetContainerItemInfo(myBags, bagSlots)
                if itemRarity == 0 and itemSellPrice ~= 0 then
                    totalPrice = totalPrice + (itemSellPrice * itemInfo.stackCount)
                    C_Container.UseContainerItem(myBags, bagSlots)
                    PickupMerchantItem(0)
                end
            end
        end
    end
    if totalPrice ~= 0 then
        self:Print(localization.vendor[localization.locale]..C_CurrencyInfo.GetCoinTextureString(totalPrice))
    end

    -- Auto Repair
    if (CanMerchantRepair()) then
        local repairAllCost, canRepair = GetRepairAllCost();
        -- If merchant can repair and there is something to repair
        if (canRepair and repairAllCost > 0) then
            local costTextureString = C_CurrencyInfo.GetCoinTextureString(repairAllCost)
            -- Use Guild Bank
            local guildRepairedItems = false
            if (IsInGuild() and CanGuildBankRepair() and self.db.profile.guildFunds) then
                -- Checks if guild has enough money
                local amount = GetGuildBankWithdrawMoney()
                local guildBankMoney = GetGuildBankMoney()
                amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)

                if (amount >= repairAllCost) then
                    RepairAllItems(true);
                    guildRepairedItems = true
                    self:Print(localization.guild[localization.locale]..costTextureString)
                end
            end

            -- Use own funds
            if (repairAllCost <= GetMoney() and not guildRepairedItems) then
                RepairAllItems(false);
                self:Print(localization.personal[localization.locale]..costTextureString)
            end
        end
    end
end

function VendorAssistant:ShowCurrentStatus()
    local currentStatus = ""
    if self.db.profile.guildFunds then
        currentStatus = localization.useTrue[localization.locale]
    else
        currentStatus = localization.useFalse[localization.locale]
    end
    self:Print(localization.status[localization.locale]..currentStatus)
end

function VendorAssistant:Usage()
    self:Print(localization.usage[localization.locale])
end

function VendorAssistant:ToggleGuildRepairs()
    if self.db.profile.guildFunds then
        self.db.profile.guildFunds = false
        self:Print(localization.disabled[localization.locale])
    else
        self.db.profile.guildFunds = true
        self:Print(localization.enabled[localization.locale])
    end
end

function VendorAssistant:SlashCommand(msg)
    if string.len(msg) > 0 then
        if msg == "guild" then
            self:ToggleGuildRepairs()
        elseif msg == "status" then
            self:ShowCurrentStatus()
        else
            self:Usage()
        end
    else
        Settings.OpenToCategory("VendorAssistant")
    end
end