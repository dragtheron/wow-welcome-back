local addonName, addon = ...
local Module = {}
addon.Progress = Module

local function getPlayerLastActivityInfo()
    local playerGUID = UnitGUID("player")
    local playerInfo = Dragtheron_WelcomeBack.KnownCharacters[playerGUID]

    if not playerInfo or not playerInfo.currentActivityIndex then
        return
    end

    local lastPlayerActivityInfo = playerInfo.Activities[playerInfo.currentActivityIndex]

    if not lastPlayerActivityInfo or not lastPlayerActivityInfo.Activity then
        return
    end

    return lastPlayerActivityInfo
end

local function getProgressInfo(lastActivity)
    local activityName = addon.HaveWeMet.GetActivityTitle(lastActivity)
    local titleString = format("Current Activity: |cffffffff%s|r", activityName)
    local playerLastActivityInfo = getPlayerLastActivityInfo()

    local activityInfo = playerLastActivityInfo
        and playerLastActivityInfo
        or {
            Activity = lastActivity,
            Encounters = {},
        }

    return titleString, activityInfo
end

function Module.IsKeystoneActivity(activity)
    return activity.KeystoneLevel
end

function Module.GetActivityProgress(activity)
    local titleString, activityInfo = getProgressInfo(activity)
    local detailsString = addon.HaveWeMet.GetDetailsString(activityInfo, true)
    return detailsString, titleString, activityInfo
end

function Module.GetKeystoneProgress(activity)
    local titleString, activityInfo = getProgressInfo(activity)
    local details = addon.HaveWeMet.GetDetails(activityInfo, true)
    return details, titleString, activityInfo
end
