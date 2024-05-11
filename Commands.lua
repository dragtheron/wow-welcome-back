local addonName, addon = ...

local function openNotes()
    addon.Notes:ShowFrame()
end

local function toggleFrame()
    addon.Overlay:ToggleFrame()
end

local function resetLastActivity()
    addon.HaveWeMet:ResetLastActivity()
end

SlashCmdList[strupper(addonName) .. "_NOTES"] = openNotes;
_G["SLASH_" .. strupper(addonName) .. "_NOTES1"] = "/wb"

SlashCmdList[strupper(addonName) .. "_OVERLAY"] = toggleFrame;
_G["SLASH_" .. strupper(addonName) .. "_OVERLAY1"] = "/wboverlay"

SlashCmdList[strupper(addonName) .. "_RESET"] = resetLastActivity;
_G["SLASH_" .. strupper(addonName) .. "_RESET1"] = "/wbclose"
