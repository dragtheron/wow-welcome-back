local addonName, addon = ...

local frame = CreateFrame("Frame", "WelcomeBack_Overlay", UIParent)
frame:SetPoint("TOPLEFT", 40, -40)
frame:SetSize(600, 40)
frame:SetShown(false)

frame.ActivityLine = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
frame.ActivityLine:SetPoint("TOPLEFT", 0, 0)
frame.ActivityLine:SetHeight(12)
frame.ActivityLine:SetText("Loading Activity Info...")
frame.ActivityLine:SetJustifyH("LEFT")

frame.ActivityLine:SetWidth(frame:GetWidth())
frame.ActivityProgress = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
frame.ActivityProgress:SetPoint("TOPLEFT", frame.ActivityLine, "BOTTOMLEFT", 0, -8)
frame.ActivityProgress:SetWidth(frame:GetWidth())
frame.ActivityProgress:SetHeight(16)
frame.ActivityProgress:SetText("...")
frame.ActivityProgress:SetJustifyH("LEFT")

local currentActivity

frame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT")

    if currentActivity then
        addon.HaveWeMet.GetDetailsTooltip(GameTooltip, currentActivity, true)
    end

    GameTooltip:Show()
end)

frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

frame:SetScript("OnEvent", function(self, event)
    if event == "VARIABLES_LOADED" then
        if Dragtheron_WelcomeBack.Settings then
            frame:SetShown(Dragtheron_WelcomeBack.Settings.ShowOverlay)
        end
    end
end)

frame:RegisterEvent("VARIABLES_LOADED")

local function onUpdate()
    local detailsString, titleString, activity = addon.Progress.GetActivityProgress()
    currentActivity = activity

    if detailsString and titleString then
        frame.ActivityLine:SetText(titleString)
        frame.ActivityProgress:SetText(detailsString)
        frame.ActivityProgress:SetShown(true)
        frame.ActivityLine:SetShown(true)
    else
        frame.ActivityLine:SetShown(false)
        frame.ActivityProgress:SetShown(false)
    end
end

addon.Overlay = {
    frame = frame
}

function addon.Overlay.ToggleFrame()
    local shouldShow = not frame:IsShown()
    frame:SetShown(shouldShow)

    if not Dragtheron_WelcomeBack.Settings then
        Dragtheron_WelcomeBack.Settings = {}
    end

    Dragtheron_WelcomeBack.Settings.ShowOverlay = shouldShow;
end

EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.Update", onUpdate)
EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.ActivityUpdate", onUpdate)
