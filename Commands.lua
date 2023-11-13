local addonName, addon = ...

local function openNotes()
    addon.Notes:ShowFrame()
end

SlashCmdList[strupper(addonName) .. "_NOTES"] = openNotes;
_G["SLASH_" .. strupper(addonName) .. "_NOTES1"] = "/wb"
