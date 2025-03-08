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

local sortButton = CreateFrame("Button", "SortBagsActionButton", UIParent, "SecureActionButtonTemplate")
sortButton:SetScript("OnClick", function ()
    C_Container.SortBags()
end)

function VendorAssistant:OnInitialize()
    if useGuildFunds == nil then
        useGuildFunds = false
    end

    if GetBindingKey("CLICK SortBagsActionButton:LeftButton") == nil then
        SetBinding("ALT-S", "CLICK SortBagsActionButton:LeftButton")
    end

    self:RegisterChatCommand("va", "SlashCommand")
end

function VendorAssistant:OnEnable()
    self:RegisterEvent("MERCHANT_SHOW")
end

function VendorAssistant:MERCHANT_SHOW()
    -- Auto Sell Grey Items
    totalPrice = 0
    for myBags = 0,4 do
        for bagSlots = 1, C_Container.GetContainerNumSlots(myBags) do
            CurrentItemLink = C_Container.GetContainerItemLink(myBags, bagSlots)
            if CurrentItemLink then
                _, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(CurrentItemLink)
                itemInfo = C_Container.GetContainerItemInfo(myBags, bagSlots)
                if itemRarity == 0 and itemSellPrice ~= 0 then
                    totalPrice = totalPrice + (itemSellPrice * itemInfo.stackCount)
                    C_Container.UseContainerItem(myBags, bagSlots)
                    PickupMerchantItem()
                end
            end
        end
    end
    if totalPrice ~= 0 then
        DEFAULT_CHAT_FRAME:AddMessage(localization.vendor[localization.locale]..GetCoinTextureString(totalPrice), 255, 255, 255)
    end

    -- Auto Repair
    if (CanMerchantRepair()) then
        repairAllCost, canRepair = GetRepairAllCost();
        -- If merchant can repair and there is something to repair
        if (canRepair and repairAllCost > 0) then
            costTextureString = GetCoinTextureString(repairAllCost)
            -- Use Guild Bank
            guildRepairedItems = false
            if (IsInGuild() and CanGuildBankRepair() and useGuildFunds) then
                -- Checks if guild has enough money
                local amount = GetGuildBankWithdrawMoney()
                local guildBankMoney = GetGuildBankMoney()
                amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)

                if (amount >= repairAllCost) then
                    RepairAllItems(true);
                    guildRepairedItems = true
                    DEFAULT_CHAT_FRAME:AddMessage(localization.guild[localization.locale]..costTextureString, 255, 255, 255)
                end
            end

            -- Use own funds
            if (repairAllCost <= GetMoney() and not guildRepairedItems) then
                RepairAllItems(false);
                DEFAULT_CHAT_FRAME:AddMessage(localization.personal[localization.locale]..costTextureString, 255, 255, 255)
            end
        end
    end
end

local function ShowCurrentStatus()
    if useGuildFunds then
        currentStatus = localization.useTrue[localization.locale]
    else
        currentStatus = localization.useFalse[localization.locale]
    end
    DEFAULT_CHAT_FRAME:AddMessage(localization.status[localization.locale]..currentStatus, 255, 255, 255)
end

local function Usage()
    DEFAULT_CHAT_FRAME:AddMessage(localization.usage[localization.locale], 255, 255, 255)
end

local function ToggleGuildRepairs()
    if useGuildFunds then
        useGuildFunds = false
        DEFAULT_CHAT_FRAME:AddMessage(localization.disabled[localization.locale], 255, 255, 255)
    else
        useGuildFunds = true
        DEFAULT_CHAT_FRAME:AddMessage(localization.enabled[localization.locale], 255, 255, 255)
    end
end

function VendorAssistant:SlashCommand(msg)
    if string.len(msg) > 0 then
        if msg == "guild" then
            ToggleGuildRepairs()
        elseif msg == "status" then
            ShowCurrentStatus()
        else
            Usage()
        end
    else
        Usage()
    end
end