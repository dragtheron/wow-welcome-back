local addonName, addon = ...

local overlayFrame = CreateFrame("Frame", "WelcomeBack_Overlay", UIParent)
overlayFrame:SetPoint("TOPLEFT", 40, -40)
overlayFrame:SetSize(600, 40)
overlayFrame:SetShown(false)

local activityLine = overlayFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
activityLine:SetPoint("TOPLEFT", 0, 0)
activityLine:SetHeight(12)
activityLine:SetText("Loading Activity Info...")
activityLine:SetJustifyH("LEFT")
activityLine:SetWidth(overlayFrame:GetWidth())

local activityProgress = overlayFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
activityProgress:SetPoint("TOPLEFT", activityLine, "BOTTOMLEFT", 0, -8)
activityProgress:SetWidth(overlayFrame:GetWidth())
activityProgress:SetHeight(16)
activityProgress:SetText("...")
activityProgress:SetJustifyH("LEFT")

local keystoneProgressFrame = CreateFrame("Frame", nil, overlayFrame)
keystoneProgressFrame:SetPoint("TOPLEFT", activityLine, "BOTTOMLEFT", 0, -8)
keystoneProgressFrame:SetSize(overlayFrame:GetWidth(), 16)
keystoneProgressFrame:SetShown(false)

local keystoneProgressDeathCountFrame = CreateFrame("Frame", nil, keystoneProgressFrame)
keystoneProgressDeathCountFrame:SetPoint("TOPLEFT", 0, 0)
keystoneProgressDeathCountFrame:SetHeight(16)
keystoneProgressDeathCountFrame:SetWidth(1)

local keystoneProgressDeathCountText = keystoneProgressDeathCountFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
keystoneProgressDeathCountText:SetPoint("TOPLEFT", 0, 0)
keystoneProgressDeathCountText:SetJustifyH("LEFT")
keystoneProgressDeathCountText:SetHeight(16)
keystoneProgressDeathCountText:SetText("D")

local keystoneProgressDeathCountAnimationGroup = keystoneProgressDeathCountFrame:CreateAnimationGroup(nil)
local keystoneProgressDeathCountAnimationAlpha = keystoneProgressDeathCountAnimationGroup:CreateAnimation("Alpha")
keystoneProgressDeathCountAnimationAlpha:SetFromAlpha(0)
keystoneProgressDeathCountAnimationAlpha:SetToAlpha(1)
keystoneProgressDeathCountAnimationAlpha:SetDuration(0.3)

local keystoneProgressMobCountFrame = CreateFrame("Frame", nil, keystoneProgressFrame)
keystoneProgressMobCountFrame:SetPoint("TOPLEFT", keystoneProgressDeathCountFrame, "TOPRIGHT", 8, 0)
keystoneProgressMobCountFrame:SetHeight(16)
keystoneProgressMobCountFrame:SetWidth(1)


-- <Translation childKey="Sheen" startDelay="1.06" duration="0.48" order="1" offsetX="68" offsetY="0" />
-- <Alpha childKey="Sheen" startDelay="1.09" duration="0.1" order="1" fromAlpha="0" toAlpha="1" />
-- <Alpha childKey="Sheen" startDelay="1.34" duration="0.05" order="1" fromAlpha="1" toAlpha="0" />

keystoneProgressMobCountFrame.Sheen = keystoneProgressMobCountFrame:CreateTexture(nil, "BACKGROUND", nil)
keystoneProgressMobCountFrame.Sheen:SetAtlas("OBJFX_LineBurst", true)
keystoneProgressMobCountFrame.Sheen:SetPoint("LEFT", 0, 0)
keystoneProgressMobCountFrame.Sheen:SetAlpha(0)
keystoneProgressMobCountFrame.Sheen:SetBlendMode("ADD")

keystoneProgressMobCountFrame.Glow = keystoneProgressMobCountFrame:CreateTexture(nil, "BACKGROUND", nil)
keystoneProgressMobCountFrame.Glow:SetAtlas("OBJFX_LineGlow", true)
keystoneProgressMobCountFrame.Glow:SetPoint("LEFT", -50, 0)
keystoneProgressMobCountFrame.Glow:SetAlpha(0)
keystoneProgressMobCountFrame.Glow:SetBlendMode("ADD")


local keystoneProgressMobCountAnimationGroup = keystoneProgressMobCountFrame:CreateAnimationGroup(nil)
-- local keystoneProgressMobCountAnimationAlpha = keystoneProgressMobCountAnimationGroup:CreateAnimation("Alpha")
-- keystoneProgressMobCountAnimationAlpha:SetFromAlpha(0)
-- keystoneProgressMobCountAnimationAlpha:SetToAlpha(1)
-- keystoneProgressMobCountAnimationAlpha:SetDuration(0.3)

-- <Alpha childKey="LineSheen" startDelay="0.15" duration="0.5" order="1" fromAlpha="0" toAlpha="0.75"/>
-- 				<Alpha childKey="LineSheen" startDelay="0.75" duration="0.5" order="1" fromAlpha="0.75" toAlpha="0"/>
-- 				<Translation childKey="LineSheen" startDelay="0.15" duration="1.5" order="1" offsetX="250" offsetY="0"/>

local keystoneProgressMobCountAnimationSheenTranslation = keystoneProgressMobCountAnimationGroup:CreateAnimation("Translation")
keystoneProgressMobCountAnimationSheenTranslation:SetStartDelay(0.15)
keystoneProgressMobCountAnimationSheenTranslation:SetDuration(1.5)
keystoneProgressMobCountAnimationSheenTranslation:SetOrder(1)
keystoneProgressMobCountAnimationSheenTranslation:SetOffset(keystoneProgressMobCountFrame:GetWidth(), 0)
keystoneProgressMobCountAnimationSheenTranslation:SetChildKey("Sheen")

local keystoneProgressMobCountAnimationSheenAlpha1 = keystoneProgressMobCountAnimationGroup:CreateAnimation("Alpha")
keystoneProgressMobCountAnimationSheenAlpha1:SetChildKey("Sheen")
keystoneProgressMobCountAnimationSheenAlpha1:SetStartDelay(0.15)
keystoneProgressMobCountAnimationSheenAlpha1:SetDuration(0.5)
keystoneProgressMobCountAnimationSheenAlpha1:SetOrder(1)
keystoneProgressMobCountAnimationSheenAlpha1:SetFromAlpha(0)
keystoneProgressMobCountAnimationSheenAlpha1:SetToAlpha(0.75)

local keystoneProgressMobCountAnimationSheenAlpha2 = keystoneProgressMobCountAnimationGroup:CreateAnimation("Alpha")
keystoneProgressMobCountAnimationSheenAlpha2:SetChildKey("Sheen")
keystoneProgressMobCountAnimationSheenAlpha2:SetStartDelay(0.75)
keystoneProgressMobCountAnimationSheenAlpha2:SetDuration(0.05)
keystoneProgressMobCountAnimationSheenAlpha2:SetOrder(1)
keystoneProgressMobCountAnimationSheenAlpha2:SetFromAlpha(0.75)
keystoneProgressMobCountAnimationSheenAlpha2:SetToAlpha(0)


local keystoneProgressMobCountAnimationScaleTranslation = keystoneProgressMobCountAnimationGroup:CreateAnimation("Translation")
keystoneProgressMobCountAnimationScaleTranslation:SetDuration(0.75)
keystoneProgressMobCountAnimationScaleTranslation:SetOrder(1)
keystoneProgressMobCountAnimationScaleTranslation:SetOffset(50, 0)
keystoneProgressMobCountAnimationScaleTranslation:SetChildKey("Glow")

local keystoneProgressMobCountAnimationScaleAlpha1 = keystoneProgressMobCountAnimationGroup:CreateAnimation("Alpha")
keystoneProgressMobCountAnimationScaleAlpha1:SetChildKey("Glow")
keystoneProgressMobCountAnimationScaleAlpha1:SetDuration(0.15)
keystoneProgressMobCountAnimationScaleAlpha1:SetOrder(1)
keystoneProgressMobCountAnimationScaleAlpha1:SetFromAlpha(0)
keystoneProgressMobCountAnimationScaleAlpha1:SetToAlpha(1)

local keystoneProgressMobCountAnimationScaleAlpha2 = keystoneProgressMobCountAnimationGroup:CreateAnimation("Alpha")
keystoneProgressMobCountAnimationScaleAlpha2:SetChildKey("Glow")
keystoneProgressMobCountAnimationScaleAlpha2:SetStartDelay(0.25)
keystoneProgressMobCountAnimationScaleAlpha2:SetDuration(0.65)
keystoneProgressMobCountAnimationScaleAlpha2:SetOrder(1)
keystoneProgressMobCountAnimationScaleAlpha2:SetFromAlpha(1)
keystoneProgressMobCountAnimationScaleAlpha2:SetToAlpha(0)

local keystoneProgressMobCountAnimationScaleScale = keystoneProgressMobCountAnimationGroup:CreateAnimation("Scale")
keystoneProgressMobCountAnimationScaleScale:SetChildKey("Glow")
keystoneProgressMobCountAnimationScaleScale:SetDuration(0.15)
keystoneProgressMobCountAnimationScaleScale:SetOrder(1)
keystoneProgressMobCountAnimationScaleScale:SetScaleFrom(0.1, 1.5)
keystoneProgressMobCountAnimationScaleScale:SetScaleTo(2, 1.5)
keystoneProgressMobCountAnimationScaleScale:SetOrigin("CENTER", 0, 0)

local keystoneProgressMobCountText = keystoneProgressMobCountFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
keystoneProgressMobCountText:SetPoint("TOPLEFT", 0, 0)
keystoneProgressMobCountText:SetJustifyH("LEFT")
keystoneProgressMobCountText:SetHeight(16)
keystoneProgressMobCountText:SetText("M")

local keystoneProgressEncounterFrame = CreateFrame("Frame", nil, keystoneProgressFrame)
keystoneProgressEncounterFrame:SetPoint("TOPLEFT", keystoneProgressMobCountFrame, "TOPRIGHT", 8, 0)
keystoneProgressEncounterFrame:SetHeight(16)
keystoneProgressEncounterFrame:SetWidth(1)

local keystoneProgressEncounterText = keystoneProgressEncounterFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
keystoneProgressEncounterText:SetPoint("TOPLEFT", 0, 0)
keystoneProgressEncounterText:SetJustifyH("LEFT")
keystoneProgressEncounterText:SetHeight(16)
keystoneProgressEncounterText:SetText("E")

local keystoneProgressTimedInfoFrame = CreateFrame("Frame", nil, keystoneProgressFrame)
keystoneProgressTimedInfoFrame:SetPoint("TOPLEFT", keystoneProgressEncounterFrame, "TOPRIGHT", 8, 0)
keystoneProgressTimedInfoFrame:SetHeight(16)
keystoneProgressTimedInfoFrame:SetWidth(1)

local keystoneProgressTimedInfoText = keystoneProgressTimedInfoFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
keystoneProgressTimedInfoText:SetPoint("TOPLEFT", 0, 0)
keystoneProgressTimedInfoText:SetJustifyH("LEFT")
keystoneProgressTimedInfoText:SetHeight(16)
keystoneProgressTimedInfoText:SetText("T")

local currentActivity

overlayFrame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(overlayFrame, "ANCHOR_TOPRIGHT")

    if currentActivity then
        addon.HaveWeMet.GetDetailsTooltip(GameTooltip, currentActivity, true)
    end

    GameTooltip:Show()
end)

overlayFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

overlayFrame:SetScript("OnEvent", function(self, event)
    if event == "VARIABLES_LOADED" then
        if Dragtheron_WelcomeBack.Settings then
            overlayFrame:SetShown(Dragtheron_WelcomeBack.Settings.ShowOverlay)
        end
    end
end)

overlayFrame:RegisterEvent("VARIABLES_LOADED")

local function showGenericProgess()
    activityProgress:SetShown(true)
    keystoneProgressFrame:SetShown(false)
    overlayFrame:Show()
end

local function showKeystoneProgress()
    activityProgress:SetShown(false)
    keystoneProgressFrame:SetShown(true)
    overlayFrame:Show()
end

local function onUpdate()
    local lastActivity = addon.HaveWeMet.lastActivity

    if not lastActivity then
        overlayFrame:Hide()
        return
    end

    if addon.Progress.IsKeystoneActivity(lastActivity) then
        local keystoneDetails, title = addon.Progress.GetKeystoneProgress(lastActivity)
        activityLine:SetText(title)

        if keystoneDetails.DeathCount then
            keystoneProgressDeathCountText:SetText(keystoneDetails.DeathCount)
            keystoneProgressMobCountFrame:ClearAllPoints()
            keystoneProgressMobCountFrame:SetPoint("TOPLEFT", keystoneProgressDeathCountFrame, "TOPRIGHT", 8, 0)
        else
            keystoneProgressMobCountFrame:ClearAllPoints()
            keystoneProgressMobCountFrame:SetPoint("TOPLEFT", 0, 0)
        end

        if keystoneDetails.TimedInfo then
            keystoneProgressMobCountFrame:Hide()
            keystoneProgressEncounterFrame:Hide()
            keystoneProgressMobCountFrame:ClearAllPoints()

            if keystoneDetails.DeathCount then
                keystoneProgressTimedInfoFrame:SetPoint("TOPLEFT", keystoneProgressDeathCountFrame, "TOPRIGHT", 8, 0)
            else
                keystoneProgressTimedInfoFrame:SetPoint("TOPLEFT", 0, 0)
            end
        else
            keystoneProgressEncounterFrame:SetPoint("TOPLEFT", keystoneProgressMobCountFrame, "TOPRIGHT", 8, 0)
            keystoneProgressMobCountFrame:Show()
            keystoneProgressEncounterFrame:Show()
        end

        keystoneProgressDeathCountFrame:SetWidth(keystoneProgressDeathCountText:GetStringWidth())
        keystoneProgressMobCountFrame:SetWidth(keystoneProgressMobCountText:GetStringWidth())
        keystoneProgressEncounterFrame:SetWidth(keystoneProgressEncounterText:GetStringWidth())
        keystoneProgressTimedInfoFrame:SetWidth(keystoneProgressTimedInfoText:GetStringWidth())
        keystoneProgressMobCountAnimationSheenTranslation:SetOffset(keystoneProgressMobCountFrame:GetWidth(), 0)

        local previousDeathCount = keystoneProgressDeathCountText:GetText()
        local previousMobCount = keystoneProgressMobCountText:GetText()

        keystoneProgressDeathCountText:SetText(keystoneDetails.DeathCount)
        keystoneProgressMobCountText:SetText(keystoneDetails.MobCount)
        keystoneProgressEncounterText:SetText(keystoneDetails.EncounterInfo)
        keystoneProgressTimedInfoText:SetText(keystoneDetails.TimedInfo)
        showKeystoneProgress()

        if previousDeathCount ~= keystoneDetails.DeathCount then
            keystoneProgressDeathCountAnimationGroup:Play()
        end

        if previousMobCount ~= keystoneDetails.MobCount then
            keystoneProgressMobCountAnimationGroup:Play()
        end
    else
        local detailsString, title = addon.Progress.GetActivityProgress(lastActivity)
        activityLine:SetText(title)
        activityProgress:SetText(detailsString)
        showGenericProgess()
    end
end

addon.Overlay = {
    frame = overlayFrame
}

function addon.Overlay.ToggleFrame()
    local shouldShow = not overlayFrame:IsShown()
    overlayFrame:SetShown(shouldShow)

    if not Dragtheron_WelcomeBack.Settings then
        Dragtheron_WelcomeBack.Settings = {}
    end

    Dragtheron_WelcomeBack.Settings.ShowOverlay = shouldShow;
end

EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.Update", onUpdate)
EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.ActivityUpdate", onUpdate)
