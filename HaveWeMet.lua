local addonName, addon = ...

local DIFFICULTY_CHALLENGE_MODE = 8;
local locale = GetLocale()

local HaveWeMet = {
  ["loaded"] = false,
  ["lastActivity"] = nil,
  ["EncounterStart"] = 0,
}

DT_HWM = HaveWeMet
HaveWeMet.frame = CreateFrame("Frame")

local function printColored(text, color)
  print(color .. text .. "|r")
end

function HaveWeMet:CleanActivities()
  for characterIdx, character in pairs(Dragtheron_WelcomeBack.KnownCharacters) do
    if character.DanglingActivity == nil or #character.DanglingActivity.Encounters == 0 then
      character.DanglingActivity = nil
    end

    if #character.Activities == 0 then
      character[characterIdx] = nil
    end
  end
end

function HaveWeMet:RegisterActivity(type, id, keystoneLevel, difficultyId)
  self.lastActivity = {
    ["Type"] = type,
    ["Id"] = id,
    ["KeystoneLevel"] = keystoneLevel,
    ["DifficultyId"] = difficultyId,
  }

  return self.lastActivity
end

function HaveWeMet:CheckCharacters()
  local units = {}
  local numGroupMembers = GetNumGroupMembers()

  if IsInRaid() then
    for i = 1, 40 do
      table.insert(units, "raid" .. i)
    end
  else
    for i = 1, numGroupMembers do
      table.insert(units, "party" .. i)
    end
  end

  local characters = {}

  for _, unit in ipairs(units) do
    if UnitExists(unit) then
      local name, realm = UnitNameUnmodified(unit)
      local guid = UnitGUID(unit)

      if name ~= UNKNOWNOBJECT then
        if realm == nil then
          -- the same as player's realm
          realm = GetRealmName()
        end

        local character = {
          guid = guid,
          name = name,
          realm = realm,
        }

        table.insert(characters, character)
        self:CheckCharacter(character)
      end
    end
  end

  Dragtheron_WelcomeBack.LastGroup = {}

  for _, character in ipairs(characters) do
    self:AddToGroup(character)
  end
end

function HaveWeMet:IsKnownCharacter(character)
  return Dragtheron_WelcomeBack.KnownCharacters[character.guid]
end

function HaveWeMet:AddActivity(guid, activity, additionalInfo)
  if not Dragtheron_WelcomeBack.KnownCharacters[guid] then
    return HaveWeMet:CheckCharacters()
  end

  local lastActivityId = #Dragtheron_WelcomeBack.KnownCharacters[guid].Activities
  local lastActivity = Dragtheron_WelcomeBack.KnownCharacters[guid].Activities[lastActivityId]

  -- TODO: New Activity if older than a treshold
  -- e.g. if one only plays one instance-difficulty combination (mythic raid only),
  -- then all those events will be combined.

  if not lastActivity
    or lastActivity.Activity.Type ~= activity.Type
    or lastActivity.Activity.Id ~= activity.Id
    or lastActivity.Activity.KeystoneLevel ~= activity.KeystoneLevel
    or lastActivity.Activity.DifficultyId ~= activity.DifficultyId
  then
    Dragtheron_WelcomeBack.KnownCharacters[guid].DanglingActivity = {
      ["Time"] = GetServerTime(),
      ["Activity"] = activity,
      ["AdditionalInfo"] = additionalInfo,
      ["Encounters"] = {},
    }
  end
end

function HaveWeMet:AddEncounter(guid, encounter)
  if Dragtheron_WelcomeBack.KnownCharacters[guid].DanglingActivity then
    table.insert(
      Dragtheron_WelcomeBack.KnownCharacters[guid].Activities,
      Dragtheron_WelcomeBack.KnownCharacters[guid].DanglingActivity)
    Dragtheron_WelcomeBack.KnownCharacters[guid].DanglingActivity = nil
  end

  local lastActivityIdx = #Dragtheron_WelcomeBack.KnownCharacters[guid].Activities

  table.insert(
    Dragtheron_WelcomeBack.KnownCharacters[guid].Activities[lastActivityIdx].Encounters,
    encounter)
end

function HaveWeMet:RegisterCharacter(character)
  Dragtheron_WelcomeBack.KnownCharacters[character.guid] = {
    ["CharacterInfo"] = {
      ["Name"] = character.name,
      ["Realm"] = character.realm,
    },
    ["FirstContact"] = GetServerTime(),
    ["Activities"] = {},
    ["DanglingActivity"] = nil,
  }
end

function HaveWeMet:IsInGroup(character)
  local playerGUID = UnitGUID("player")
  return character.guid == playerGUID or Dragtheron_WelcomeBack.LastGroup[character.guid]
end

function HaveWeMet:AddToGroup(character)
  Dragtheron_WelcomeBack.LastGroup[character.guid] = true
end

function HaveWeMet:CheckCharacter(character)
  if self:IsInGroup(character) then
    return
  end

  local knownCharacter = self:IsKnownCharacter(character)

  if not knownCharacter then
    self:RegisterCharacter(character)
  end

  local color = {
    GREEN = "|cff00ff00",
    RED = "|cffff0000",
    GRAY = "|cff888888",
  }

  if knownCharacter then
    local dateString = date("%c", knownCharacter.FirstContact)
    printColored(
      format(
        "Already played with %s from %s.",
        character.name, character.realm
      ),
      color.GREEN
    )
  end
end

function HaveWeMet:OnEvent(event, ...)
  if event == "VARIABLES_LOADED" then
    if Dragtheron_WelcomeBack == nil then
      Dragtheron_WelcomeBack = {}
    end

    self.loaded = true

    if Dragtheron_WelcomeBack.Version == nil or Dragtheron_WelcomeBack.Version < 0.1 then
      -- wipe old database
      Dragtheron_WelcomeBack = {
        ["LastGroup"] = {},
        ["KnownCharacters"] = {},
        ["Version"] = 0.1,
      }
    end

    if TooltipDataProcessor then
      TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, HaveWeMet.OnUnitTooltip)
    end

    HaveWeMet:CleanActivities()

    return
  end

  if event == "ENCOUNTER_START" then
    HaveWeMet.EncounterStart = GetServerTime()
  end

  if event == "ENCOUNTER_END" then
    HaveWeMet.OnInstanceUpdate()
    if GetServerTime() - HaveWeMet.EncounterStart > 20 then
      local encounterId, encounterName, difficultyId, _, success = ...
      return HaveWeMet:OnEncounterEnd(encounterId, encounterName, difficultyId, success)
    end
  end

  if event == "CHALLENGE_MODE_COMPLETED" then
    print("Challange Mode completed.")
  end

  if event == "SCENARIO_COMPLETED" then
    print("Scenario completed.")
  end

  if not self.loaded then
    return
  end

  C_Timer.After(3, function()
    HaveWeMet:CheckCharacters()
    HaveWeMet.OnInstanceUpdate()
  end)
end

local function getRGB(color)
  local r, g, b = color:GetRGB()
  return {
    ["r"] = r,
    ["g"] = g,
    ["b"] = b,
  }
end

local function addColoredDoubleLine(tooltip, leftText, rightText, leftColor, rightColor)
  local leftRGB = getRGB(leftColor)
  local rightRGB = getRGB(rightColor)
  tooltip:AddDoubleLine(leftText, rightText, leftRGB.r, leftRGB.g, leftRGB.b, rightRGB.r, rightRGB.g, rightRGB.b)
end

local function addColoredLine(tooltip, text, color)
  local rgb = getRGB(color)
  tooltip:AddLine(text, rgb.r, rgb.g, rgb.b)
end

function HaveWeMet.GetDateString(time)
  return date("%c", time)
end

function HaveWeMet.GetKeystoneDetailsString(activity)
  local expectedEncounters = addon.KeystoneEncounters[activity.Activity.Id]
  local outputString = ""

  local checkIcon = "|A:UI-QuestTracker-Tracker-Check:16:16|a"
  local failIcon = "|A:UI-QuestTracker-Objective-Fail:16:16|a"
  local nubIcon = "|A:UI-QuestTracker-Objective-Nub:16:16|a"

  for _, encounterId in ipairs(expectedEncounters) do
    local encounterCompleted = false
    local encounterTried = false

    for _, encounter in ipairs(activity.Encounters) do
      if tonumber(encounter.Id) == encounterId then
        encounterTried = true

        if encounter.Success then
          encounterCompleted = true
        end
      end
    end

    if encounterCompleted then
      outputString = outputString .. checkIcon
    elseif encounterTried then
      outputString = outputString .. failIcon
    else
      outputString = outputString .. nubIcon
    end
  end

  return outputString
end

function HaveWeMet.GetRaidDetailsString(activity)
  local expectedEncounters = addon.RaidEncounters[activity.Activity.Id]
  local outputString = ""

  local checkIcon = "|A:UI-QuestTracker-Tracker-Check:16:16|a"
  local failIcon = "|A:UI-QuestTracker-Objective-Fail:16:16|a"
  local nubIcon = "|A:UI-QuestTracker-Objective-Nub:16:16|a"

  for _, encounterId in ipairs(expectedEncounters) do
    local encounterCompleted = false
    local encounterTried = false

    for _, encounter in ipairs(activity.Encounters) do
      if tonumber(encounter.Id) == encounterId then
        encounterTried = true

        if encounter.Success == 1 then
          encounterCompleted = true
        end
      end
    end

    if encounterCompleted then
      outputString = outputString .. checkIcon
    elseif encounterTried then
      outputString = outputString .. failIcon
    else
      outputString = outputString .. nubIcon
    end
  end

  return outputString
end

function HaveWeMet.GetKillsWipesCountString(kills, wipes)
  local deathIcon = "|A:poi-graveyard-neutral:16:12|a"
  local defeatIcon = "|A:UI-QuestTracker-Tracker-Check:16:16|a"

  if wipes > 0 or kills > 0 then
    local encounterInfoString = ""

    if wipes > 0 then
      encounterInfoString = encounterInfoString .. format(" %s %d ", deathIcon, wipes)
    end

    if kills > 1 then
      encounterInfoString = encounterInfoString .. format(" %s %d ", defeatIcon, kills)
    elseif kills > 0 then
      encounterInfoString = encounterInfoString .. format(" %s ", defeatIcon)
    end

    return encounterInfoString
  end
end

function HaveWeMet.GetGenericDetailsString(activity)
  local deathIcon = "|A:poi-graveyard-neutral:16:12|a"
  local defeatIcon = "|A:UI-QuestTracker-Tracker-Check:16:16|a"
  local wipes = 0
  local kills = 0

  for _, encounter in ipairs(activity.Encounters) do
    if encounter.Success == 1 then
      kills = kills + 1
    else
      wipes = wipes + 1
    end
  end

  return HaveWeMet.GetKillsWipesCountString(kills, wipes)
end

function HaveWeMet.GetDetailsString(activity)
  if activity.Activity.KeystoneLevel then
    return HaveWeMet.GetKeystoneDetailsString(activity)
  elseif addon.RaidEncounters[activity.Activity.Id] then
    return HaveWeMet.GetRaidDetailsString(activity)
  else
    return HaveWeMet.GetGenericDetailsString(activity)
  end
end

function HaveWeMet.AddActivityLine(tooltip, activity)
  local activityDetails
  local activityTitle = HaveWeMet.GetActivityTitle(activity.Activity)

  if IsLeftShiftKeyDown() then
    activityDetails = HaveWeMet.GetDateString(activity.Time)
  else
    activityDetails = HaveWeMet.GetDetailsString(activity)
  end

  addColoredDoubleLine(tooltip, activityTitle, activityDetails, HIGHLIGHT_FONT_COLOR, HIGHLIGHT_FONT_COLOR)
end

function HaveWeMet.AddTooltipInfo(character, tooltip)
  tooltip:AddLine(" ")

  if character and #character.Activities > 0 then
    tooltip:AddLine("Already played with this character:")
    local shownActivities = 0
    local moreActivites = 0

    for i = #character.Activities, 1, -1 do
      local activity = character.Activities[i]

      if shownActivities < 5 then
        HaveWeMet.AddActivityLine(tooltip, activity)
        shownActivities = shownActivities + 1
      else
        moreActivites = moreActivites + 1
      end
    end

    if moreActivites > 0 then
      addColoredLine(tooltip, format("(and %d more activites)", moreActivites), HIGHLIGHT_FONT_COLOR)
    end
  else
    addColoredLine(tooltip, "Never played with this player.", GRAY_FONT_COLOR)
  end
end

function HaveWeMet.OnUnitTooltip(tooltip, data)
  local playerGUID = UnitGUID("player")
  local knownCharacter = Dragtheron_WelcomeBack.KnownCharacters[data.guid]

  if playerGUID == data.guid then
    -- knownCharacter = Dragtheron_WelcomeBack.KnownCharacters["Player-3691-0A12FB19"]
  end

  if not data.guid:find("^Player%-%d+") then
    return
  end
  HaveWeMet.AddTooltipInfo(knownCharacter, tooltip)
end


function HaveWeMet.OnInstanceUpdate()
  local name, instanceType, difficultyId, difficultyName, _, _, _, instanceId = GetInstanceInfo()

  HaveWeMet.RegisterName(instanceType, instanceId, name)
  HaveWeMet.RegisterName("difficulty", difficultyId, difficultyName)

  local keystoneLevel

  if difficultyId ==  DIFFICULTY_CHALLENGE_MODE then
     keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
  end

  local activity = HaveWeMet:RegisterActivity(instanceType, instanceId, keystoneLevel, difficultyId)

  if activity == false then
    return
  end

  local additionalInfo = {
    ["Instance"] = {
      ["Type"] = instanceType,
      ["DifficultyId"] = difficultyId,
    }
  }

  for guid, _ in pairs(Dragtheron_WelcomeBack.LastGroup) do
    HaveWeMet:AddActivity(guid, activity, additionalInfo)
  end
end

function HaveWeMet:OnEncounterEnd(encounterId, encounterName, difficultyId, success)
  HaveWeMet.RegisterName("encounter", encounterId, encounterName)

  local encounter = {
    ["Id"] = tonumber(encounterId),
    ["DifficultyId"] = tonumber(difficultyId),
    ["Success"] = tonumber(success),
  }

  Dragtheron_WelcomeBack.PreviousGroup = {}

  for guid, _ in pairs(Dragtheron_WelcomeBack.LastGroup) do
    self:AddEncounter(guid, encounter)
    Dragtheron_WelcomeBack.PreviousGroup[guid] = true
  end
end

function HaveWeMet:LFGActivityTooltip()
  if not C_LFGList.HasSearchResultInfo(self.resultID) then
    return
  end

  local info = C_LFGList.GetSearchResultInfo(self.resultID)

  if info ~= nil and info.leaderName ~= nil then
    local name = info.leaderName:match("[^-]+")
    local realm = info.leaderName:match("-([^-]+)") or GetRealmName()

    for _, character in pairs(Dragtheron_WelcomeBack.KnownCharacters) do
      if (
        character.CharacterInfo.Realm == realm
        and character.CharacterInfo.Name == name
      ) then
        HaveWeMet.AddTooltipInfo(character, GameTooltip)
        GameTooltip:Show()
        return
      end
    end

    HaveWeMet.AddTooltipInfo(false, GameTooltip)
    GameTooltip:Show()
  end
end

function HaveWeMet:LFGApplicantTooltip()
	local memberIdx = self.memberIdx;
	local applicantID = self:GetParent().applicantID;

	local activeEntryInfo = C_LFGList.GetActiveEntryInfo();
	if ( not activeEntryInfo ) then
		return;
	end

	local activityInfo = C_LFGList.GetActivityInfoTable(activeEntryInfo.activityID);
	if(not activityInfo) then
		return;
	end

  local nameAndRealm = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx);

  if nameAndRealm ~= nil then
    local name = nameAndRealm:match("[^-]+")
    local realm = nameAndRealm:match("-([^-]+)") or GetRealmName()

    for _, character in pairs(Dragtheron_WelcomeBack.KnownCharacters) do
      if (
        character.CharacterInfo.Realm == realm
        and character.CharacterInfo.Name == name
      ) then
        HaveWeMet.AddTooltipInfo(character, GameTooltip)
        GameTooltip:Show()
        return
      end
    end

    HaveWeMet.AddTooltipInfo(false, GameTooltip)
    GameTooltip:Show()
  end
end

function HaveWeMet.GetName(type, id)
  return HaveWeMet.RegisterName(type, id)
end

function HaveWeMet.RegisterName(type, id, nameValue)
  local nameIdentifier = format("%s:%s:%s", type, id, locale)
  local names = Dragtheron_WelcomeBack["Names"] or {}
  local name = names[nameIdentifier]

  if name then
    return name
  end

  Dragtheron_WelcomeBack["Names"] = Dragtheron_WelcomeBack["Names"] or {}

  if nameValue then
    Dragtheron_WelcomeBack["Names"][nameIdentifier] = nameValue
  else
    return "Unknown"
  end
end

function HaveWeMet.GetActivityTitle(activity)
  if activity.Title then
    return activity.Title
  end

  local instanceName = HaveWeMet.GetName(activity.Type, activity.Id)

  if activity.KeystoneLevel then
    return format("+%d %s", activity.KeystoneLevel, instanceName)
  end

  local difficultyName = HaveWeMet.GetName("difficulty", activity.DifficultyId)
  return format("%s %s", difficultyName, instanceName)
end

function HaveWeMet.GetEncounterTitle(encounter)
  if encounter.Name then
    return encounter.Name
  end

  return HaveWeMet.GetName("encounter", encounter.Id)
end

HaveWeMet.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
HaveWeMet.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
HaveWeMet.frame:RegisterEvent("VARIABLES_LOADED")
HaveWeMet.frame:RegisterEvent("ENCOUNTER_START")
HaveWeMet.frame:RegisterEvent("ENCOUNTER_END")
HaveWeMet.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
HaveWeMet.frame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
HaveWeMet.frame:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
HaveWeMet.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
HaveWeMet.frame:RegisterEvent("PLAYER_GUILD_UPDATE")
HaveWeMet.frame:RegisterEvent("PARTY_MEMBER_ENABLE")
HaveWeMet.frame:RegisterEvent("PARTY_MEMBER_DISABLE")
HaveWeMet.frame:RegisterEvent("GUILD_PARTY_STATE_UPDATED")

HaveWeMet.frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
HaveWeMet.frame:RegisterEvent("SCENARIO_COMPLETED")

HaveWeMet.frame:SetScript("OnEvent", HaveWeMet.OnEvent)

hooksecurefunc("Scenario_ChallengeMode_ShowBlock", HaveWeMet.OnInstanceUpdate)
hooksecurefunc("LFGListSearchEntry_OnEnter", HaveWeMet.LFGActivityTooltip)
hooksecurefunc("LFGListApplicantMember_OnEnter", HaveWeMet.LFGApplicantTooltip)

LFGListFrame.ApplicationViewer.UnempoweredCover:EnableMouse(false)

addon.HaveWeMet = HaveWeMet
