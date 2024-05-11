local addonName, addon = ...

local version = GetAddOnMetadata(addonName, "VERSION");

AddonCompartmentFrame:RegisterAddon({
    text = addonName,
    icon = "Interface\\ICONS\\achievement_guildperk_havegroup willtravel",
    registerForAnyClick = true,
    notCheckable = true,
    func = function(btn, arg1, arg2, checked, mouseButton)
        if mouseButton == "LeftButton" then
            addon.Notes:ShowFrame()
        end
    end,
    funcOnEnter = function()
        GameTooltip:SetOwner(AddonCompartmentFrame, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText(format("%s v%s", addonName, version))
        GameTooltip:AddLine("Click to open the character overview.", 0, 1, 0)
        GameTooltip:Show()
    end
})
