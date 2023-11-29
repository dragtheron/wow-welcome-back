local addonName, addon = ...

local DIFFICULTY_CHALLENGE_MODE = 8;
local locale = GetLocale()

local HaveWeMet = CreateFromMixins(CallbackRegistryMixin)
HaveWeMet.loaded = false
HaveWeMet.lastActivity = nil
HaveWeMet.instanceInfoVersion = -1
HaveWeMet.EncounterStart = 0
HaveWeMet.cache = {}
DT_HWM = HaveWeMet
HaveWeMet.frame = CreateFrame("Frame")

CallbackRegistryMixin.OnLoad(HaveWeMet.frame)

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

function HaveWeMet:RegisterActivity(type, id, keystoneLevel, difficultyId, challengeModeId)
  self.lastActivity = {
    Type = type,
    Id = id,
    KeystoneLevel = keystoneLevel,
    DifficultyId = difficultyId,
    ChallengeModeId = challengeModeId,
  }

  if type == "raid" then
    for i, savedInstance in ipairs(self.savedInstances) do
      if self:MatchingRaidLockout(i, self.lastActivity) then
        self.lastActivity.SaveId = savedInstance.saveId
      end
    end
  end

  return self.lastActivity
end

function HaveWeMet:MatchingRaidLockout(savedInstanceIndex, activity)
  local savedInstance = self.savedInstances[savedInstanceIndex]

  return savedInstance
    and activity.Type == "raid"
    and savedInstance.instanceId == activity.Id
    and savedInstance.difficultyId == activity.DifficultyId
end

function HaveWeMet:IsCurrentLockout(activity)
  for _, savedInstance in ipairs(self.savedInstances) do
    if savedInstance.saveId == activity.SaveId then
      return true
    end
  end
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

  table.insert(units, "player")

  local characters = {}

  for _, unit in ipairs(units) do
    if UnitExists(unit) then
      local name, realm = UnitNameUnmodified(unit)
      local guid = UnitGUID(unit)
      local guild = GetGuildInfo(unit)
      local classFilename = UnitClassBase(unit)

      if name ~= UNKNOWNOBJECT then
        if realm == nil then
          -- the same as player's realm
          realm = GetRealmName()
        end

        local character = {
          guid = guid,
          name = name,
          realm = realm,
          guild = guild,
          classFilename = classFilename,
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

function HaveWeMet.IsEqualActivity(a, b)
  if not a or not b then
    return false
  end

  return a.Type == b.Type
    and a.Id == b.Id
    and a.KeystoneLevel == b.KeystoneLevel
    and a.DifficultyId == b.DifficultyId
end

function HaveWeMet:AddActivity(guid, activity)
  local characterInfo = Dragtheron_WelcomeBack.KnownCharacters[guid]

  if not characterInfo then
    return
  end

  if activity.Type == "raid" then
    for i = #characterInfo.Activities, 1, -1 do
      local knownActivity = characterInfo.Activities[i]

      if HaveWeMet.IsEqualActivity(knownActivity, activity) then

        if not knownActivity.SaveId then
          knownActivity.SaveId = activity.SaveId
        end

        characterInfo.currentActivityIndex = i
        return
      end
    end
  end

  local lastActivityIndex = #characterInfo.Activities
  local lastActivity = characterInfo.Activities[lastActivityIndex]

  if not lastActivity or not HaveWeMet.IsEqualActivity(lastActivity.Activity, activity) then
    Dragtheron_WelcomeBack.KnownCharacters[guid].DanglingActivity = {
      ["Time"] = GetServerTime(),
      ["Activity"] = activity,
      ["Encounters"] = {},
    }

    characterInfo.currentActivityIndex = nil
    return
  end

  characterInfo.currentActivityIndex = lastActivityIndex
end

function HaveWeMet:AddEncounter(guid, encounter)
  local characterInfo = Dragtheron_WelcomeBack.KnownCharacters[guid]

  if not characterInfo.currentActivityIndex and characterInfo.DanglingActivity then
    table.insert(
      characterInfo.Activities,
      characterInfo.DanglingActivity)

    characterInfo.DanglingActivity = nil
    characterInfo.currentActivityIndex = #characterInfo.Activities
  end

  table.insert(
    characterInfo.Activities[characterInfo.currentActivityIndex].Encounters,
    encounter)
end

function HaveWeMet:RegisterKeystone()
  if not Dragtheron_WelcomeBack.CompletedKeystones then
    Dragtheron_WelcomeBack.CompletedKeystones = {}
  end

  local mapID, level, time, onTime, keystoneUpgradeLevels, practiceRun, oldDungeonScore, newDungeonScore, isAffixRecord, isMapRecord, primaryAffix, isEligibleForScore, upgradeMembers = C_ChallengeMode.GetCompletionInfo()

  local keystoneInfo = {
    MapId = mapID,
    Level = level,
    Time = time,
    OnTime = onTime,
    KeystoneUpgradeLevels = keystoneUpgradeLevels,
  }

  table.insert(Dragtheron_WelcomeBack.CompletedKeystones, keystoneInfo)

  return #Dragtheron_WelcomeBack.CompletedKeystones
end

function HaveWeMet:AddKeystoneToCharacter(guid, keystoneIndex)
  if Dragtheron_WelcomeBack.KnownCharacters[guid].DanglingActivity then
    Dragtheron_WelcomeBack.KnownCharacters[guid].DanglingActivity.CompletedInfo = keystoneIndex
    return
  end

  local lastActivityIdx = #Dragtheron_WelcomeBack.KnownCharacters[guid].Activities
  local lastActivity = Dragtheron_WelcomeBack.KnownCharacters[guid].Activities[lastActivityIdx]
  local keystoneInfo = Dragtheron_WelcomeBack.CompletedKeystones[keystoneIndex]

  if keystoneInfo.MapId == lastActivity.Activity.ChallengeModeId then
    lastActivity.CompletedInfo = keystoneIndex
  end
end

function HaveWeMet:RegisterCharacter(character)
  local knownCharacter = self:IsKnownCharacter(character)

  local characterInfo = {
    Name = character.name,
    Realm = character.realm,
    ClassFilename = character.classFilename,
    Guild = character.guild,
  }

  if knownCharacter then
    knownCharacter.CharacterInfo = characterInfo
    return knownCharacter
  else
    Dragtheron_WelcomeBack.KnownCharacters[character.guid] = {
      ["CharacterInfo"] = characterInfo,
      ["FirstContact"] = GetServerTime(),
      ["Activities"] = {},
      ["DanglingActivity"] = nil,
    }
  end
end

function HaveWeMet:IsInGroup(character)
  return Dragtheron_WelcomeBack.LastGroup[character.guid]
end

function HaveWeMet:AddToGroup(character)
  Dragtheron_WelcomeBack.LastGroup[character.guid] = true
end

function HaveWeMet:CheckCharacter(character)
  local knownCharacter = self:RegisterCharacter(character)

  if self:IsInGroup(character) then
    return
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

function HaveWeMet:AnnounceUpdate()
  EventRegistry:TriggerEvent(addonName .. ".HaveWeMet.Update")
end

function HaveWeMet:OnEvent(event, ...)
  if event == "PLAYER_ENTERING_WORLD" then
    HaveWeMet:RequestLockoutInfo()
  end

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
    return
  end

  if event == "ENCOUNTER_END" then
    HaveWeMet.OnInstanceUpdate()
    local time = GetServerTime()

    if time - HaveWeMet.EncounterStart > 20 then
      local encounterId, _, difficultyId, _, success = ...
      HaveWeMet:OnEncounterEnd(encounterId, difficultyId, success, time)
      HaveWeMet:AnnounceUpdate()
    end

    return
  end

  if event == "CHALLENGE_MODE_COMPLETED" then
    HaveWeMet:OnKeystoneEnd()
    return
  end

  if event == "UPDATE_INSTANCE_INFO" then
    HaveWeMet:OnInstanceInfoUpdate()
    return
  end

  if not self.loaded then
    return
  end

  if self.checkCharactersTimer then
    self.checkCharactersTimer:Cancel()
  end

  self.checkCharactersTimer = C_Timer.NewTimer(3, function()
    HaveWeMet:CheckCharacters()
    HaveWeMet.OnInstanceUpdate()
    HaveWeMet:AnnounceUpdate()
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

function HaveWeMet.GetRaidDetailsString(activity, showLootable)
  local expectedEncounters = HaveWeMet.GetEncounters(activity.Activity)
  local outputString = ""

  local checkIcon = "|A:UI-QuestTracker-Tracker-Check:16:16|a"
  local failIcon = "|A:UI-QuestTracker-Objective-Fail:16:16|a"
  local nubIcon = "|A:UI-QuestTracker-Objective-Nub:16:16|a"
  local lockedIcon = "|A:Forge-Lock:16:16|a"
  local deathIcon = "|A:poi-graveyard-neutral:16:12|a"

  local deaths = 0
  local allComplete = true
  local savedInstanceIndex = nil

  if activity.Activity.Type == "raid" and showLootable then
    for i = 1, #HaveWeMet.savedInstances do
      if addon.HaveWeMet:MatchingRaidLockout(i, activity.Activity) then
        savedInstanceIndex = i
      end
    end
  end

  for encounterIndex, expectedEncounterData in ipairs(expectedEncounters) do
    local encounterCompleted = false
    local encounterTried = false

    for _, encounter in ipairs(activity.Encounters) do
      if tonumber(encounter.Id) == expectedEncounterData.Id then
        encounterTried = true

        if encounter.Success == 1 then
          encounterCompleted = true
        else
          deaths = deaths + 1
        end
      end
    end

    local encounterLocked = false

    if savedInstanceIndex then
      for i = 1, addon.HaveWeMet.savedInstances[savedInstanceIndex].numEncounters do
        local bossName, _, locked = GetSavedInstanceEncounterInfo(savedInstanceIndex, i)

        if bossName == expectedEncounterData.Name then
          encounterLocked = locked
        end
      end
    end

    if encounterCompleted then
       outputString = outputString .. checkIcon
    elseif encounterLocked and showLootable then
      outputString = outputString .. lockedIcon
    else
      allComplete = false

      if encounterTried then
        outputString = outputString .. failIcon
      else
        outputString = outputString .. nubIcon
      end
    end
  end

  if deaths > 0 then
    return format("%s %d   %s", deathIcon, deaths, outputString)
  else
    return outputString
  end
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

function HaveWeMet.GetDetailsString(activity, showLootable)
  local expectedEncounters = HaveWeMet.GetEncounters(activity.Activity)

  if #expectedEncounters > 0 then
    return HaveWeMet.GetRaidDetailsString(activity, showLootable)
  end

  return HaveWeMet.GetGenericDetailsString(activity)
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

    if character.Note and character.Note ~= "" then
      tooltip:AddLine(" ")
      addColoredLine(tooltip, format("\"%s\"", character.Note), NORMAL_FONT_COLOR)
    end
  else
    addColoredLine(tooltip, "Never played with this player.", GRAY_FONT_COLOR)
  end
end

function HaveWeMet.OnUnitTooltip(tooltip, data)
  local playerGUID = UnitGUID("player")
  local knownCharacter = Dragtheron_WelcomeBack.KnownCharacters[data.guid]

  if not data.guid:find("^Player%-%d+") then
    return
  end
  HaveWeMet.AddTooltipInfo(knownCharacter, tooltip)
end


function HaveWeMet.OnInstanceUpdate()
  local _, instanceType, difficultyId, _, _, _, _, instanceId = GetInstanceInfo()
  local keystoneLevel, challengeModeId

  if difficultyId ==  DIFFICULTY_CHALLENGE_MODE then
    keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
    challengeModeId = C_ChallengeMode.GetActiveChallengeMapID()
  end

  if instanceType == "none" then
    HaveWeMet.lastActivity = nil
    return
  end

  local activity = HaveWeMet:RegisterActivity(instanceType, instanceId, keystoneLevel, difficultyId, challengeModeId)

  if activity == false then
    return
  end

  local playerGUID = UnitGUID("player")

  for guid, _ in pairs(Dragtheron_WelcomeBack.LastGroup) do
    if guid ~= playerGUID then
      HaveWeMet:AddActivity(guid, activity)
    end
  end

  HaveWeMet:AddActivity(playerGUID, activity)
end

function HaveWeMet:RequestLockoutInfo()
  if not self.lockoutInfoRequested or self.lockoutInfoRequested > self.instanceInfoVersion then
    self.lockoutInfoRequested = GetServerTime()
    RequestRaidInfo()
  end
end

function HaveWeMet:OnInstanceInfoUpdate()
  self.instanceInfoVersion = GetServerTime()
  local savedInstances = {}

  for i = 1, GetNumSavedInstances() do
    local _, saveId, reset, difficultyId = GetSavedInstanceInfo(i)
    local instanceId = select(14, GetSavedInstanceInfo(i))
    local numEncounters = select(11, GetSavedInstanceInfo(i))

    if reset > 0 then
      local lockoutInfo = {
        instanceId = instanceId,
        difficultyId = difficultyId,
        saveId = saveId,
        numEncounters = numEncounters
      }

      table.insert(savedInstances, lockoutInfo)
    end
  end

  self.savedInstances = savedInstances
  self.OnInstanceUpdate()
end

function HaveWeMet:OnEncounterEnd(encounterId, difficultyId, success, time)
  local encounter = {
    Id = tonumber(encounterId),
    DifficultyId = tonumber(difficultyId),
    Success = tonumber(success),
    Time = time,
  }

  local this = self

  if self.lastActivity and self.lastActivity.Type == "raid" then
    -- delay saving encounter data after first pull to the include save id
    if success and not self.lastActivity.SaveId then
      self:RequestLockoutInfo()
      C_Timer.After(5, function()
        HaveWeMet.OnEncounterEnd(self, encounterId, difficultyId, success, time)
      end)
      print("Delaying saving encounter data.")
      return
    end
  end

  Dragtheron_WelcomeBack.PreviousGroup = {}

  for guid, _ in pairs(Dragtheron_WelcomeBack.LastGroup) do
    self:AddEncounter(guid, encounter)
    Dragtheron_WelcomeBack.PreviousGroup[guid] = true
  end
end

function HaveWeMet:OnKeystoneEnd()
  local keystoneIndex = self:RegisterKeystone()

  for guid, _ in pairs(Dragtheron_WelcomeBack.LastGroup) do
    self:AddKeystoneToCharacter(guid, keystoneIndex)
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

function HaveWeMet.GetActivityTitle(activity)
  if not activity then
    return "Unknown"
  end

  if activity.Title then
    return activity.Title
  end

  local instanceName

  if activity.ChallengeModeId then
    instanceName = C_ChallengeMode.GetMapUIInfo(activity.ChallengeModeId) or "Invalid Data"
  else
    instanceName = HaveWeMet.GetInstanceName(activity.Id)
  end

  if activity.KeystoneLevel then
    return format("+%d %s", activity.KeystoneLevel, instanceName)
  end

  local difficultyName = HaveWeMet.GetDifficultyName(activity.DifficultyId)

  if difficultyName then
    return format("%s %s", difficultyName, instanceName)
  else
    return instanceName
  end
end

function HaveWeMet.GetSelectedInstanceId()
  local mapId = select(10, EJ_GetInstanceInfo())

  if not mapId then
    return nil
  end

  return C_EncounterJournal.GetInstanceForGameMap(mapId) or nil
end

function HaveWeMet.GetEncounters(activity)
  local instanceId = activity.Id
  local challengeModeId = activity.ChallengeModeId
  local instanceEncounters = HaveWeMet.GetEncounterDataFromJournal(instanceId)

  if challengeModeId then
    local keystoneEncounterIds = addon.Keystones:GetEncounterIds(challengeModeId)

    if keystoneEncounterIds then
      return HaveWeMet.FilterEncounters(instanceEncounters, keystoneEncounterIds)
    end
  end

  return instanceEncounters
end

function HaveWeMet.GetCompletedInfo(activityInfo)
  local index = activityInfo.CompletedInfo

  if not index then
    return
  end

  return Dragtheron_WelcomeBack.CompletedKeystones[index]
end

function HaveWeMet.FilterEncounters(encounterData, filterIds)
  local encounters = {}

  for _, encounterId in ipairs(filterIds) do
    for _, encounterInfo in ipairs(encounterData) do
      if encounterInfo.Id == encounterId then
        table.insert(encounters, encounterInfo)
      end
    end
  end

  return encounters
end

function HaveWeMet.GetEncounterDataFromJournal(instanceId)
  if HaveWeMet.cache["instances:" .. instanceId] then
    return HaveWeMet.cache["instances:" .. instanceId]
  end

  local journalInstanceId = C_EncounterJournal.GetInstanceForGameMap(instanceId)

  if not journalInstanceId then
    return {}
  end

  local currentInstanceId = HaveWeMet.GetSelectedInstanceId()
  EJ_SelectInstance(journalInstanceId)

  HaveWeMet.cache["instances:" .. instanceId] = {}

  for index = 1, 20 do
    local name, _, _, _, _, _, dungeonEncounterId = EJ_GetEncounterInfoByIndex(index)

    if not name then
      return HaveWeMet.cache["instances:" .. instanceId]
    end

    local encounterInfo = {
      Id = dungeonEncounterId,
      Name = name,
      Index = index,
    }

    table.insert(HaveWeMet.cache["instances:" .. instanceId], encounterInfo)
  end

  if currentInstanceId then
    EJ_SelectInstance(currentInstanceId)
  end

  return HaveWeMet.cache["instances:" .. instanceId]
end

function HaveWeMet.GetEncounterTitleFromJournal(instanceId, encounterId)
  local journalInstanceId = C_EncounterJournal.GetInstanceForGameMap(instanceId)

  if not journalInstanceId then
    return "Unknown"
  end

  local currentInstanceId = HaveWeMet.GetSelectedInstanceId()
  EJ_SelectInstance(journalInstanceId)

  for index = 1, 20 do
    local name, _, _, _, _, _, dungeonEncounterId = EJ_GetEncounterInfoByIndex(index)

    if not name then
      if currentInstanceId then
        EJ_SelectInstance(currentInstanceId)
      end

      return "Unknown"
    end

    if dungeonEncounterId == encounterId then
      if currentInstanceId then
        EJ_SelectInstance(currentInstanceId)
      end

      return name
    end
  end
end

function HaveWeMet.GetInstanceName(instanceId)
  local journalInstanceId = C_EncounterJournal.GetInstanceForGameMap(instanceId)

  if not journalInstanceId then
    return "Unknown"
  end

  local currentInstanceId = HaveWeMet.GetSelectedInstanceId()
  EJ_SelectInstance(journalInstanceId)
  local name = EJ_GetInstanceInfo()

  if currentInstanceId then
    EJ_SelectInstance(currentInstanceId)
  end

  return name
end

function HaveWeMet.GetDifficultyName(difficultyId)
  return GetDifficultyInfo(difficultyId)
end

HaveWeMet.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
HaveWeMet.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
HaveWeMet.frame:RegisterEvent("VARIABLES_LOADED")
HaveWeMet.frame:RegisterEvent("ENCOUNTER_START")
HaveWeMet.frame:RegisterEvent("ENCOUNTER_END")
HaveWeMet.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
HaveWeMet.frame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
HaveWeMet.frame:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
HaveWeMet.frame:RegisterEvent("PLAYER_GUILD_UPDATE")
HaveWeMet.frame:RegisterEvent("PARTY_MEMBER_ENABLE")
HaveWeMet.frame:RegisterEvent("PARTY_MEMBER_DISABLE")
HaveWeMet.frame:RegisterEvent("GUILD_PARTY_STATE_UPDATED")
HaveWeMet.frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")

HaveWeMet.frame:SetScript("OnEvent", HaveWeMet.OnEvent)

hooksecurefunc("Scenario_ChallengeMode_ShowBlock", HaveWeMet.OnInstanceUpdate)
hooksecurefunc("LFGListSearchEntry_OnEnter", HaveWeMet.LFGActivityTooltip)
hooksecurefunc("LFGListApplicantMember_OnEnter", HaveWeMet.LFGApplicantTooltip)

LFGListFrame.ApplicationViewer.UnempoweredCover:EnableMouse(false)

addon.HaveWeMet = HaveWeMet
