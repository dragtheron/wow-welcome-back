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

frame:SetScript("OnEvent", function(self, event)
    if event == "VARIABLES_LOADED" then
        if Dragtheron_WelcomeBack.Settings then
            frame:SetShown(Dragtheron_WelcomeBack.Settings.ShowOverlay)
        end
    end
end)

frame:RegisterEvent("VARIABLES_LOADED")

local function onUpdate()
    local lastActivity = addon.HaveWeMet.lastActivity

    if lastActivity then
        local activityName = addon.HaveWeMet.GetActivityTitle(lastActivity)

        if lastActivity.ChallengeModeId then
            activityName = activityName .. format(" (CMID %s)", lastActivity.ChallengeModeId)
        end

        if lastActivity.SaveId then
            activityName = activityName .. format(" (Save ID %s)", lastActivity.SaveId)
        end

        frame.ActivityLine:SetText(format("Current Activity: |cffffffff%s|r", activityName))
        frame.ActivityLine:SetShown(true)

        local defaultDetailsString = addon.HaveWeMet.GetDetailsString({
            Activity = lastActivity,
            Encounters = {},
        }, true)

        frame.ActivityProgress:SetText(defaultDetailsString)

        local playerGUID = UnitGUID("player")
        local playerProgress = Dragtheron_WelcomeBack.KnownCharacters[playerGUID]

        if playerProgress and #playerProgress.Activities > 0 then
            local playerLastActivity = playerProgress.Activities[#playerProgress.Activities]

            if addon.HaveWeMet.IsEqualActivity(playerLastActivity.Activity, lastActivity) then
                local detailsString = addon.HaveWeMet.GetDetailsString(playerLastActivity, true)
                frame.ActivityProgress:SetText(detailsString)
            end

            frame.ActivityProgress:SetShown(true)
        else
            frame.ActivityProgress:SetShown(false)
        end

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
