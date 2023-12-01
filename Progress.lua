local addonName, addon = ...
local Module = {}
addon.Progress = Module

function Module.GetActivityProgress()
    local lastActivity = addon.HaveWeMet.lastActivity

    if not lastActivity then
        return
    end

    local activityName = addon.HaveWeMet.GetActivityTitle(lastActivity)

    if lastActivity.ChallengeModeId then
        activityName = activityName .. format(" (CMID %s)", lastActivity.ChallengeModeId)
    end

    if lastActivity.SaveId then
        activityName = activityName .. format(" (ID %s)", lastActivity.SaveId)
    end

    local activityString = format("Current Activity: |cffffffff%s|r", activityName)

    local playerGUID = UnitGUID("player")
    local playerInfo = Dragtheron_WelcomeBack.KnownCharacters[playerGUID]

    if playerInfo and playerInfo.currentActivityIndex then
        local playerLastActivity = playerInfo.Activities[playerInfo.currentActivityIndex]

        if playerLastActivity and addon.HaveWeMet.IsEqualActivity(playerLastActivity.Activity, lastActivity) then
            local detailsString = addon.HaveWeMet.GetDetailsString(playerLastActivity, true)
            return detailsString, activityString, playerLastActivity
        end
    end

    local currentActivity = {
        Activity = lastActivity,
        Encounters = {},
    }

    local defaultDetailsString = addon.HaveWeMet.GetDetailsString(currentActivity, true)
    return defaultDetailsString, activityString, currentActivity
end
