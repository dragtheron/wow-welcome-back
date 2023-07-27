local HaveWeMet = {
  ["loaded"] = false,
  ["lastActivity"] = nil,
  ["EncounterStart"] = 0,
}

local DIFFICULTY_CHALLENGE_MODE = 8;

DT_HWM = HaveWeMet

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

function HaveWeMet:RegisterActivity(type, id, title, keystoneLevel)
  self.lastActivity = {
    ["Type"] = type,
    ["Id"] = id,
    ["Title"] = title,
    ["KeystoneLevel"] = keystoneLevel,
  }

  return self.lastActivity
end

function HaveWeMet:CheckCharacters()
  local units = {}
  local numGroupMembers = GetNumGroupMembers()

  if IsInRaid() then
    for i = 1, numGroupMembers do
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
  local lastActivityId = #Dragtheron_WelcomeBack.KnownCharacters[guid].Activities
  local lastActivity = Dragtheron_WelcomeBack.KnownCharacters[guid].Activities[lastActivityId]

  if not lastActivity
    or lastActivity.Activity.Type ~= activity.Type
    or lastActivity.Activity.Id ~= activity.Id
    or lastActivity.Activity.KeystoneLevel ~= activity.KeystoneLevel
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
  return Dragtheron_WelcomeBack.LastGroup[character.guid]
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
        "Already played with character %s from realm %s.",
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
    if GetServerTime() - HaveWeMet.EncounterStart > 20 then
      local encounterId, encounterName, difficultyId, _, success = ...
      return HaveWeMet:OnEncounterEnd(encounterId, encounterName, difficultyId, success)
    end
  end

  if not self.loaded then
    return
  end

  C_Timer.After(3, function()
    HaveWeMet:CheckCharacters()
    HaveWeMet:OnInstanceUpdate()
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

local function getDateString(time)
  return date("%c", time)
end

function HaveWeMet.AddActivityLine(tooltip, activity)
  local wipes = 0
  local kills = 0

  for _, encounter in ipairs(activity.Encounters) do
    if encounter.Success == 1 then
      kills = kills + 1
    else
      wipes = wipes + 1
    end
  end

  if wipes > 0 or kills > 0 then
    local encounterInfoString
    if wipes > 0 and kills > 0 then
      encounterInfoString = format("|cff00ff00%d Kills|r, |cffff0000%d Wipes|r", kills, wipes)
    elseif wipes > 0 then
      encounterInfoString = format("|cffff0000%d Wipes|r", wipes)
    else
      encounterInfoString = format("|cff00ff00%d Kills|r", kills)
    end

    local leftText = format("%s (%s)", activity.Activity.Title, encounterInfoString)
    local rightText = IsLeftShiftKeyDown() and getDateString(activity.Time) or nil
    addColoredDoubleLine(tooltip, leftText, rightText, HIGHLIGHT_FONT_COLOR, HIGHLIGHT_FONT_COLOR)
  end
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

  if playerGUID == data.guid then
    return
  end

  if not data.guid:find("^Player%-%d+") then
    return
  end

  local knownCharacter = Dragtheron_WelcomeBack.KnownCharacters[data.guid]
  HaveWeMet.AddTooltipInfo(knownCharacter, tooltip)
end

function HaveWeMet:OnInstanceUpdate()
  local name, instanceType, difficultyId, difficultyName, _, _, _, instanceId = GetInstanceInfo()
  local title = name

  if difficultyName and difficultyName ~= "" then
    title = format("%s %s", difficultyName, name)
  end

  local keystoneLevel

  if difficultyId ==  DIFFICULTY_CHALLENGE_MODE then
     keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
     title = format("+%d %s", keystoneLevel, name)
  end

  local activity = self:RegisterActivity("Instance", instanceId, title, keystoneLevel)


  if activity == false then
    return
  end


  local additionalInfo = {
    ["Instance"] = {
      ["Name"] = name,
      ["Type"] = instanceType,
      ["DifficultyId"] = difficultyId,
      ["DifficultyName"] = difficultyName,
    }
  }

  for guid, _ in pairs(Dragtheron_WelcomeBack.LastGroup) do
    self:AddActivity(guid, activity, additionalInfo)
  end
end

function HaveWeMet:OnEncounterEnd(encounterId, encounterName, difficultyId, success)
  local encounter = {
    ["Id"] = tonumber(encounterId),
    ["Name"] = encounterName,
    ["DifficultyId"] = tonumber(difficultyId),
    ["Success"] = tonumber(success),
  }

  for guid, _ in pairs(Dragtheron_WelcomeBack.LastGroup) do
    self:AddEncounter(guid, encounter)
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

HaveWeMet.frame = CreateFrame("Frame")
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

HaveWeMet.frame:SetScript("OnEvent", HaveWeMet.OnEvent)

hooksecurefunc("Scenario_ChallengeMode_ShowBlock", HaveWeMet.OnInstanceUpdate)
hooksecurefunc("LFGListSearchEntry_OnEnter", HaveWeMet.LFGActivityTooltip)
hooksecurefunc("LFGListApplicantMember_OnEnter", HaveWeMet.LFGApplicantTooltip)

LFGListFrame.ApplicationViewer.UnempoweredCover:EnableMouse(false)
