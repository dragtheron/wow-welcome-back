local addonName, addon = ...

local frame = CreateFrame("Frame", "WelcomeBack_Overlay", UIParent)
frame:SetPoint("TOPLEFT", 40, -40)
frame:SetSize(300, 40)

frame.ActivityLine = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
frame.ActivityLine:SetPoint("TOPLEFT", 0, 0)
frame.ActivityLine:SetHeight(16)
frame.ActivityLine:SetText("Loading...")

frame.ActivityLine:SetWidth()
frame.ActivityProgress = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
frame.ActivityProgress:SetPoint("TOPLEFT", frame.ActivityLine, "BOTTOMLEFT", 0, -8)
frame.ActivityProgress:SetHeight(16)
frame.ActivityLine:SetText("Loading...")

local function onUpdate()
    local lastActivity = addon.HaveWeMet.lastActivity
    local activityName = addon.HaveWeMet.GetActivityTitle(lastActivity)

    if lastActivity then
        frame.ActivityLine:SetText(format("Current Activity: |cffffffff%s|r", activityName))
        frame.ActivityLine:SetShown(true)

        local defaultDetailsString = addon.HaveWeMet.GetDetailsString({
            Activity = lastActivity,
            Encounters = {},
        })

        frame.ActivityProgress:SetText(defaultDetailsString)

        local playerGUID = UnitGUID("player")
        local playerProgress = Dragtheron_WelcomeBack.KnownCharacters[playerGUID]

        if playerProgress and #playerProgress.Activities > 0 then
            local playerLastActivity = playerProgress.Activities[#playerProgress.Activities]

            if addon.HaveWeMet.IsEqualActivity(playerLastActivity.Activity, lastActivity) then
                local detailsString = addon.HaveWeMet.GetDetailsString(playerLastActivity)
                frame.ActivityProgress:SetText(detailsString)
            end
        end

        frame:SetShown(true)
    else
        frame:SetShown(false)
    end
end

EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.Update", onUpdate)
EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.ActivityUpdate", onUpdate)
