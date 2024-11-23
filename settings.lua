local settings, panel = ...
local addonName, localization = ...

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

local settingsPanel = CreateFrame("Frame", "Strik3ria_MainMenu")
settingsPanel.name = "Strik3ria's Vendor Assistant"
local category, layout = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
Settings.RegisterCategory(category)

local title = settingsPanel:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
title:SetPoint("TOP")
title:SetText(settingsPanel.name)

local guildRepairCheckButton = CreateFrame("CheckButton", "guildRepairCheckButton_GlobalName", settingsPanel, "ChatConfigCheckButtonTemplate")
guildRepairCheckButton:SetPoint("TOPLEFT", 100, -65)
guildRepairCheckButton_GlobalNameText:SetText(localization.settings.text[localization.locale])
guildRepairCheckButton.tooltip = localization.settings.tooltip[localization.locale]

local function ToggleGuildRepairs()
    if useGuildFunds then
        useGuildFunds = false
        guildRepairCheckButton:SetChecked(useGuildFunds)
        DEFAULT_CHAT_FRAME:AddMessage(localization.disabled[localization.locale], 255, 255, 255)
    else
        useGuildFunds = true
        guildRepairCheckButton:SetChecked(useGuildFunds)
        DEFAULT_CHAT_FRAME:AddMessage(localization.enabled[localization.locale], 255, 255, 255)
    end
end

SLASH_SVA1 = "/sva"
SlashCmdList["SVA"] = function(msg)
    if string.len(msg) > 0 then
        -- '/asgre guild' will enable or disable guild repairs depending on current
        -- state
        if msg == "guild" then
            ToggleGuildRepairs()
        -- '/asgre status' will show the current status of guild repairs
        elseif msg == "status" then
            ShowCurrentStatus()
        else
            -- No command was given, give them a hint
            Usage()
        end
    else
        Usage()
    end
end

SLASH_RL1 = "/rl"
SlashCmdList["RL"] = function(msg)
    C_UI.Reload()
end

local sortButton = CreateFrame("Button", "SortBagsActionButton", UIParent, "SecureActionButtonTemplate")
sortButton:SetScript("OnClick", function ()
    C_Container.SortBags()
end)

guildRepairCheckButton:SetScript("OnClick", ToggleGuildRepairs)
panel.checkbutton = guildRepairCheckButton
