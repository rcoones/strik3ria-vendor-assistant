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
VendorAssistant = LibStub("AceAddon-3.0"):NewAddon("VendorAssistant", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("VendorAssistant")

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
    local totalPrice = GetMoney()
    if C_MerchantFrame.GetNumJunkItems() > 0 then
        C_MerchantFrame.SellAllJunkItems()
        -- There is a bit of a delay after selling before PLAYER_MONEY updates. We wait a second to make sure it is updated first.
        C_Timer.After(1, function ()
            totalPrice = GetMoney() - totalPrice
            self:Print(L["Items were sold for "]..C_CurrencyInfo.GetCoinTextureString(totalPrice))
        end)
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
                    self:Print(L["Equipment has been repaired by your Guild for "]..costTextureString)
                end
            end

            -- Use own funds
            if (repairAllCost <= GetMoney() and not guildRepairedItems) then
                RepairAllItems(false);
                self:Print(L["Equipment has been repaired for "]..costTextureString)
            end
        end
    end
end

function VendorAssistant:ShowCurrentStatus()
    local currentStatus = ""
    if self.db.profile.guildFunds then
        currentStatus = L["true"]
    else
        currentStatus = L["false"]
    end
    self:Print(L["Guild repairs enabled: "]..currentStatus)
end

function VendorAssistant:Usage()
    self:Print(L["Usage:\n/va guild - Toggle guild repairs to enable/disable\n/va status - Show the current status of guild repairs"])
end

function VendorAssistant:ToggleGuildRepairs()
    if self.db.profile.guildFunds then
        self.db.profile.guildFunds = false
        self:Print(L["Guild repairs are now disabled."])
    else
        self.db.profile.guildFunds = true
        self:Print(L["Guild repairs are now enabled."])
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
        Settings.OpenToCategory(self.optionsFrame.name)
    end
end