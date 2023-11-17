local addonName, addon = ...

local function openNotes()
    addon.Notes:ShowFrame()
end

local function toggleFrame()
    addon.Overlay:ToggleFrame()
end

SlashCmdList[strupper(addonName) .. "_NOTES"] = openNotes;
_G["SLASH_" .. strupper(addonName) .. "_NOTES1"] = "/wb"

SlashCmdList[strupper(addonName) .. "_OVERLAY"] = toggleFrame;
_G["SLASH_" .. strupper(addonName) .. "_OVERLAY1"] = "/wboverlay"
