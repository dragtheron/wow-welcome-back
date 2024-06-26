---@diagnostic disable: inject-field
local addonName, addon = ...

local Notes = {
    filters = {},
    initialized = false,
    dataProvider = nil,
}

local Filter = EnumUtil.MakeEnum("CharacterName")
local Group = EnumUtil.MakeEnum("LastGroup", "PreviousGroup", "KnownCharacters")
local ActivityGroup = EnumUtil.MakeEnum("Raids", "Keystones", "Generic")

local function sortRootData(a, b)
    local aData = a:GetData()
    local bData = b:GetData()
    local aGroup = aData.group
    local bGroup = bData.group

    if aGroup ~= bGroup then
        return aGroup < bGroup
    end

    local aCategoryInfo = aData.categoryInfo
    local bCategoryInfo = bData.categoryInfo
    local aOrder = aCategoryInfo.uiOrder
    local bOrder = bCategoryInfo.uiOrder

    if aOrder ~= bOrder then
        return aOrder < bOrder
    end

    return strcmputf8i(aCategoryInfo.name, bCategoryInfo.name) < 0
end

local function sortEncounterData(a, b)
    local aData = a:GetData()
    local bData = b:GetData()

    local aOrder = aData.encounterInfo and aData.encounterInfo.order or aData.order
    local bOrder = bData.encounterInfo and bData.encounterInfo.order or bData.order

    if aOrder ~= bOrder then
        return aOrder < bOrder
    end
end

local characterDataProvider = CreateTreeDataProvider()
characterDataProvider:GetRootNode():SetSortComparator(sortRootData, false, false)

local activitiesDataProvider = CreateTreeDataProvider()
activitiesDataProvider:GetRootNode():SetSortComparator(sortRootData, false, false)

local function addTreeDataForCategory(categoryInfo, node)
    if next(categoryInfo.characters) == nil then
        return
    end


    local categoryNode = node:Insert({ categoryInfo = categoryInfo, group = categoryInfo.group })
    categoryNode:Insert({topPadding=true, order = -1});

    for index, characterInfo in ipairs(categoryInfo.characters) do
        if index < 25 then
            categoryNode:Insert({
                characterInfo = characterInfo,
                order = index,
                highlightKnown = categoryInfo.highlightKnown,
                highlightCurrentGroupMembers = categoryInfo.highlightCurrentGroupMembers,
            })
        end
    end

    categoryNode:Insert({topPadding=true, order = -1});

    return categoryNode
end

local function addTreeDataForActivityCategory(categoryInfo, node, collapses)
    if #categoryInfo.activities == 0 then
        return
    end

    local categoryNode = node:Insert({ categoryInfo = categoryInfo, group = categoryInfo.group })
    local affectChildren = false
    local skipSort = false
    -- categoryNode:SetSortComparator(sortCategoryData, affectChildren, skipSort)

    categoryNode:SetCollapsed(true)

    categoryNode:Insert({ topPadding=true, order = -1 });

    for _, activityInfo in ipairs(categoryInfo.activities) do
        local activityNode = categoryNode:Insert({ activityInfo = activityInfo, order = 0 })
        activityNode:SetSortComparator(sortEncounterData, affectChildren, skipSort)

        activityNode:SetCollapsed(true)

        local uniqueEncounters = {}

        local expectedEncounters = addon.HaveWeMet.GetEncounters(activityInfo.Activity)

        if expectedEncounters then
            for _, encounter in ipairs(expectedEncounters) do
                uniqueEncounters[encounter.Id] = {
                    Name = encounter.Name,
                    Id = encounter.Id,
                    order = encounter.Index,
                    times = {},
                    kills = 0,
                    wipes = 0,
                }
            end
        end

        for encounterIndex, encounterInfo in ipairs(activityInfo.Encounters) do

            if not expectedEncounters then
                if not uniqueEncounters[encounterInfo.Id] then
                    uniqueEncounters[encounterInfo.Id] = encounterInfo
                    uniqueEncounters[encounterInfo.Id].kills = 0
                    uniqueEncounters[encounterInfo.Id].wipes = 0
                    uniqueEncounters[encounterInfo.Id].order = encounterIndex
                    uniqueEncounters[encounterInfo.Id].times = {}
                end
            end

            if not uniqueEncounters[encounterInfo.Id] then
                return
            end

            if encounterInfo.Success == 1 then
                uniqueEncounters[encounterInfo.Id].kills = uniqueEncounters[encounterInfo.Id].kills + 1
            else
                uniqueEncounters[encounterInfo.Id].wipes = uniqueEncounters[encounterInfo.Id].wipes + 1
            end

            table.insert(uniqueEncounters[encounterInfo.Id].times, {encounterInfo.Time, encounterInfo.Success})
        end

        if activityInfo.Activity.KeystoneLevel and activityInfo.TrashCount then
            activityNode:Insert({ trashCount = activityInfo.TrashCount, order = -1 })
        end

        for _, encounterInfo in pairs(uniqueEncounters) do
            encounterInfo.instanceId = activityInfo.Activity.Id
            activityNode:Insert({ encounterInfo = encounterInfo, order = 0 })
        end
    end

    categoryNode:Insert({topPadding=true, order = -1});

    return categoryNode
end

addon.Notes = Notes

WelcomeBack_NotesCategoryMixin = {}

function WelcomeBack_NotesCategoryMixin:SetCollapseState(collapsed)
    local atlas = collapsed and "Professions-recipe-header-expand" or "Professions-recipe-header-collapse"
    self.CollapseIcon:SetAtlas(atlas, true)
    self.CollapseIconAlphaAdd:SetAtlas(atlas, true)
end

function WelcomeBack_NotesCategoryMixin:Init(node)
    local elementData = node:GetData()
    local categoryInfo = elementData.categoryInfo
    self.Label:SetText(categoryInfo.name)
    self:SetCollapseState(node:IsCollapsed())
end

function WelcomeBack_NotesCategoryMixin:OnEnter(node)
    self.Label:SetFontObject(GameFontHighlight_NoShadow)
end

function WelcomeBack_NotesCategoryMixin:OnLeave(node)
    self.Label:SetFontObject(GameFontNormal_NoShadow)
end

WelcomeBack_NotesCharacterMixin = {}

function WelcomeBack_NotesCharacterMixin:GetLabelText(characterInfo)
    return Notes.GetColoredCharacterName(characterInfo)
end

function WelcomeBack_NotesCharacterMixin:Init(node)
    local elementData = node:GetData()
    local characterName = self:GetLabelText(elementData.characterInfo)
    self.Label:SetText(characterName)

    self.highlight = (elementData.characterInfo.Known and elementData.highlightKnown)
        or (elementData.characterInfo.InGroup and elementData.highlightCurrentGroupMembers)

    local hasNote = elementData.characterInfo.Note and elementData.characterInfo.Note ~= ""
    self.NoteIcon:SetShown(hasNote)
    self.Label:SetAlpha(self.highlight and 1.0 or 0.5)
end

function WelcomeBack_NotesCharacterMixin:SetSelected(selected)
    self.SelectedOverlay:SetShown(selected)
    self.HighlightOverlay:SetShown(not selected)
end

function WelcomeBack_NotesCharacterMixin:SetLabelFontColors(color)
    self.Label:SetVertexColor(color:GetRGB())
end

function WelcomeBack_NotesCharacterMixin:OnEnter()
    self.Label:SetAlpha(1.0)
    local elementData = self:GetElementData()
    local characterName = Notes.GetCharacterName(elementData.data.characterInfo)

    if self.Label:IsTruncated() then
        GameTooltip:SetOwner(self.Label, "ANCHOR_RIGHT")
        local wrap = false
        GameTooltip_AddHighlightLine(GameTooltip, characterName)
        GameTooltip:Show()
    end
end

function WelcomeBack_NotesCharacterMixin:OnLeave()
    self.Label:SetAlpha(self.highlight and 1.0 or 0.5)
    GameTooltip:Hide()
end

WelcomeBack_NotesActivityMixin = CreateFromMixins(WelcomeBack_NotesCategoryMixin)

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesActivityMixin:Init(node)
    local elementData = node:GetData()
    local activityInfo = elementData.activityInfo
    local activityTitle = addon.HaveWeMet.GetActivityTitle(activityInfo.Activity)
    local activitySummary = addon.HaveWeMet.GetDetailsString(activityInfo)
    self.Label:SetText(activityTitle)
    self.Progress:SetText(activitySummary)
    self:SetCollapseState(node:IsCollapsed())
end

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesActivityMixin:OnEnter(node)
    self.Label:SetFontObject(GameFontHighlight_NoShadow)
    local elementData = self:GetElementData()
    local activityInfo = elementData.data.activityInfo
    local activityDate = addon.HaveWeMet.GetDateString(activityInfo.Time)
    local activityTitle = addon.HaveWeMet.GetActivityTitle(activityInfo.Activity)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(activityTitle)
    GameTooltip:AddLine(activityDate, 1, 1, 1)

    local completedInfo = addon.HaveWeMet.GetCompletedInfo(activityInfo)

    if completedInfo then
        if completedInfo.OnTime then
            GameTooltip:AddLine(format("|cff00ff00%s +%d|r", "Timed", completedInfo.KeystoneUpgradeLevels))
        else
            GameTooltip:AddLine(format("|cffff0000%s|r", "Not Timed"))
        end
    end

    if activityInfo.Activity.SaveId then
        GameTooltip:AddLine(format("Save ID %s", activityInfo.Activity.SaveId))
    end

    GameTooltip:Show()
end

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesActivityMixin:OnLeave(node)
    self.Label:SetFontObject(GameFontNormal_NoShadow)
    GameTooltip:Hide()
end

WelcomeBack_NotesTrashCountMixin = CreateFromMixins(WelcomeBack_NotesCategoryMixin)

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesTrashCountMixin:Init(node)
    local elementData = self:GetElementData()
    local trashCount = elementData.data.trashCount
    local mobsKilled = trashCount.Progress
    local mobsTotal = trashCount.Total
    local checkIcon = "|A:UI-QuestTracker-Tracker-Check:16:16|a"
    local nubIcon = "|A:UI-QuestTracker-Objective-Nub:16:16|a"
    local trashSummary

    if mobsTotal and mobsKilled >= mobsTotal then
        trashSummary = checkIcon
    else
        trashSummary = nubIcon
    end

    self.Label:SetFontObject(mobsKilled >= mobsTotal and GameFontHighlight_NoShadow or GameFontDisable)
    self.Label:ClearAllPoints()
    self.Label:SetPoint("LEFT", 33, 0)
    self.Progress:ClearAllPoints()
    self.Progress:SetPoint("LEFT", 6, 0)

    if mobsTotal > 0 and mobsKilled >= mobsTotal then
        self.Label:SetText("Enemy Forces")
    else
        self.Label:SetText(format("%d %% Enemy Forces", mobsKilled / mobsTotal * 100))
    end

    self.Progress:SetText(trashSummary)
end

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesTrashCountMixin:OnEnter(node)
    self.Label:SetFontObject(GameFontHighlight_NoShadow)
    local elementData = self:GetElementData()
    local trashCount = elementData.data.trashCount
    local mobsKilled = trashCount.Progress
    local mobsTotal = trashCount.Total
    local mobsPercent = mobsKilled / mobsTotal * 100
    self.Label:SetFontObject(GameFontHighlight_NoShadow)
    self.HighlightOverlay:SetShown(false)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Mobs Killed")
    GameTooltip:AddDoubleLine(format("%d/%d", mobsKilled, mobsTotal), format("%.2f %%", mobsPercent), 1, 1, 1)
    GameTooltip:Show()
end

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesTrashCountMixin:OnLeave(node)
    local elementData = self:GetElementData()
    local trashCount = elementData.data.trashCount
    local mobsKilled = trashCount.Progress
    local mobsTotal = trashCount.Total
    self.Label:SetFontObject(mobsKilled >= mobsTotal and GameFontHighlight_NoShadow or GameFontDisable)
    GameTooltip:Hide()
end

WelcomeBack_NotesEncounterMixin = CreateFromMixins(WelcomeBack_NotesCategoryMixin)

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesEncounterMixin:Init(node)
    local elementData = node:GetData()
    local encounterInfo = elementData.encounterInfo
    local encounterTitle = encounterInfo.Name
    local encounterCounters = addon.HaveWeMet.GetEncounterStatusIcon(encounterInfo.kills, encounterInfo.wipes)
    self.Label:SetFontObject(encounterInfo.kills > 0 and GameFontHighlight_NoShadow or GameFontDisable)
    self.Label:SetText(encounterTitle)
    self.Label:ClearAllPoints()
    self.Label:SetPoint("LEFT", 33, 0)
    self.Progress:SetText(encounterCounters)
    self.Progress:ClearAllPoints()
    self.Progress:SetPoint("LEFT", 6, 0)
end

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesEncounterMixin:OnEnter(node)
    local elementData = self:GetElementData()
    local encounterInfo = elementData.data.encounterInfo
    local encounterName = addon.HaveWeMet.GetEncounterTitleFromJournal(encounterInfo.instanceId, encounterInfo.Id)
    self.Label:SetFontObject(GameFontHighlight_NoShadow)
    self.HighlightOverlay:SetShown(false)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(encounterName)

    if encounterInfo.times then
        for _, disengageTimeInfo in ipairs(encounterInfo.times) do
            local disengageTime = disengageTimeInfo[1]
            local success = disengageTimeInfo[2] == 1
            local encounterTime = addon.HaveWeMet.GetDateString(disengageTime)
            local colorRight = success and { 0, 1, 0 } or { 1, 0, 0 }
            local rightText = success and "Kill" or "Wipe"

            GameTooltip:AddDoubleLine(
                encounterTime, rightText, 1, 1, 1, colorRight[1], colorRight[2], colorRight[3])
        end
    end

    GameTooltip:Show()
end

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesEncounterMixin:OnLeave()
    local elementData = self:GetElementData()
    local encounterInfo = elementData.data.encounterInfo
    self.Label:SetFontObject(encounterInfo.kills > 0 and GameFontHighlight_NoShadow or GameFontDisable)
end

WelcomeBack_NotesActivityCategoryMixin = CreateFromMixins(WelcomeBack_NotesCategoryMixin)

---@diagnostic disable-next-line: duplicate-set-field
function WelcomeBack_NotesActivityCategoryMixin:Init(node)
    local elementData = node:GetData()
    local categoryInfo = elementData.categoryInfo
    self.Label:SetText(categoryInfo.name)
    self.Progress:SetText(#categoryInfo.activities)
    self:SetCollapseState(node:IsCollapsed())
end

local mainFrame = CreateFrame("Frame", "WelcomeBack_Notes", UIParent, "PortraitFrameTemplate")
mainFrame:SetAttribute("UIPanelLayout-defined", true)
mainFrame:SetAttribute("UIPanelLayout-enabled", true)
mainFrame:SetAttribute("UIPanelLayout-area", "left")
mainFrame:SetAttribute("UIPanelLayout-pushable", 5)
mainFrame:SetAttribute("UIPanelLayout-whileDead", true)
mainFrame:SetSize(942, 658)
mainFrame:SetToplevel(true)
mainFrame:SetShown(false)
mainFrame:SetPoint("TOPLEFT", 0, 0)
---@diagnostic disable-next-line: undefined-field
mainFrame:SetTitle("Welcome Back: Notes")
---@diagnostic disable-next-line: undefined-field
mainFrame:SetPortraitToUnit("player")
---@diagnostic disable-next-line: undefined-field
mainFrame:SetPortraitToAsset("Interface\\ICONS\\achievement_guildperk_havegroup willtravel")

local header = CreateFrame("Frame", "$parentHeader", mainFrame)
header:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 64, -34)
header:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -28, -68)
header.Label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header.Label:SetPoint("LEFT", 0, 0)
header.Label:SetJustifyH("LEFT")
header.Label:SetText("")
header.Progress = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight_NoShadow")
header.Progress:SetHeight(header:GetHeight())
header.Progress:SetWidth(200)
header.Progress:SetPoint("RIGHT", 0, 0)
header.Progress:SetJustifyH("RIGHT")
header.Progress:SetText("")

header:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")

    if self.currentActivity then
        addon.HaveWeMet.GetDetailsTooltip(GameTooltip, self.currentActivity, true)
    end

    GameTooltip:Show()
end)

header:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

mainFrame.Header = header

local characterList = CreateFrame("Frame", "$parentCharacters", mainFrame)
characterList:SetWidth(274)
characterList:SetPoint("TOPLEFT", 5, -72)
characterList:SetPoint("BOTTOMLEFT", 0, 5)
---@diagnostic disable-next-line: undefined-field
CallbackRegistryMixin.OnLoad(characterList)
---@diagnostic disable-next-line: param-type-mismatch
CallbackRegistryMixin.GenerateCallbackEvents(characterList, { "OnCharacterSelected" })

characterList.Background = characterList:CreateTexture(nil, "BACKGROUND")
characterList.Background:SetAtlas("Professions-background-summarylist")
characterList.Background:SetAllPoints()

characterList.NoResultsText = characterList:CreateFontString(nil, "ARTWORK", "GameFontNormal")
characterList.NoResultsText:SetText("No Characters found.")
characterList.NoResultsText:SetSize(200, 0)
characterList.NoResultsText:SetPoint("TOP", 0, -60)

characterList.BackgroundNineSlice = CreateFrame("Frame", nil, characterList, "NineSlicePanelTemplate")
characterList.BackgroundNineSlice.layoutType = "InsetFrameTemplate"
characterList.BackgroundNineSlice:SetPoint("TOPLEFT", characterList.Background)
characterList.BackgroundNineSlice:SetPoint("BOTTOMRIGHT", characterList.Background)
---@diagnostic disable-next-line: undefined-field
characterList.BackgroundNineSlice:OnLoad()

characterList.SearchBox = CreateFrame("EditBox", nil, characterList, "SearchBoxTemplate")
characterList.SearchBox:SetHeight(20)
characterList.SearchBox:SetPoint("RIGHT", -8, 0)
characterList.SearchBox:SetPoint("TOPLEFT", 13, -8)

characterList.SearchBox:SetScript("OnTextChanged", function(editBox)
    SearchBoxTemplate_OnTextChanged(editBox)
    Notes:SetSearchText(editBox:GetText())
end)

characterList.ScrollBox = CreateFrame("Frame", nil, characterList, "WowScrollBoxList")
characterList.ScrollBox:SetPoint("TOPLEFT", characterList.SearchBox, "BOTTOMLEFT", -5, -7)
characterList.ScrollBox:SetPoint("BOTTOMRIGHT", -20, 5)
---@diagnostic disable-next-line: undefined-field
characterList.ScrollBox:OnLoad()

characterList.ScrollBar = CreateFrame("EventFrame", nil, characterList, "MinimalScrollBar")
characterList.ScrollBar:SetPoint("TOPLEFT", characterList.ScrollBox, "TOPRIGHT", 0, 0)
characterList.ScrollBar:SetPoint("BOTTOMLEFT", characterList.ScrollBox, "BOTTOMRIGHT", 0, 0)
---@diagnostic disable-next-line: undefined-field
characterList.ScrollBar:OnLoad()

local indent = 10
local padTop, padBottom, padLeft, padRight = 5, 5, 0, 5
local spacing = 1
local characterListView = CreateScrollBoxListTreeListView(indent, padTop, padBottom, padLeft, padRight, spacing)

characterListView:SetElementFactory(function(factory, node)
    -- memo: frames created by these factories will be reused!

    local elementData = node:GetData()

    if elementData.categoryInfo then
        local function Initializer(button, _node)
            button:Init(_node)

            button:SetScript("OnClick", function(_button)
                _node:ToggleCollapsed()
                _button:SetCollapseState(_node:IsCollapsed())
            end)
        end

        factory("WelcomeBack_NotesCategoryTemplate", Initializer)
    elseif elementData.characterInfo then
        local function Initializer(button, _node)
            button:Init(_node)

            local selected = characterList.selectionBehavior:IsElementDataSelected(node)
            button:SetSelected(selected)

            button:SetScript("OnClick", function(_button, buttonName, down)
                if buttonName == "LeftButton" then
                    characterList.selectionBehavior:Select(button)
                end
            end)
        end
        factory("WelcomeBack_NotesCharacterTemplate", Initializer)
    else
        factory("Frame")
    end
end)

characterListView:SetElementExtentCalculator(function(_, node)
    local elementData = node:GetData()
    local baseElementHeight = 20
    local categoryPadding = 5

    if elementData.characterInfo then
        return baseElementHeight
    end

    if elementData.categoryInfo then
        return baseElementHeight + categoryPadding
    end

    if elementData.topPadding then
        return 1
    end

    if elementData.bottomPadding then
        return 10
    end
end)

function characterList.OnSelectionChanged(_, elementData, selected)
    ---@diagnostic disable-next-line: undefined-field
    local button = characterList.ScrollBox:FindFrame(elementData)

    if button then
        button:SetSelected(selected)
    end

    if selected then
        local data = elementData:GetData()
        assert(data.characterInfo)

        local newCharacterId = data.characterInfo.Id
        local changed = Notes.previousCharacterId ~= newCharacterId

        if changed then
            EventRegistry:TriggerEvent(addonName .. ".Notes.OnCharacterSelected", data.characterInfo, characterList)

            if newCharacterId then
                Notes.previousCharacterId = newCharacterId
            end
        end
    end
end

characterList.selectionBehavior = ScrollUtil.AddSelectionBehavior(characterList.ScrollBox)

characterList.selectionBehavior:RegisterCallback(
    SelectionBehaviorMixin.Event.OnSelectionChanged, characterList.OnSelectionChanged)

mainFrame.characterList = characterList

local characterDetails = CreateFrame("Frame", "$parentCharacterDetails", mainFrame)
characterDetails:SetHeight(200)
characterDetails:SetPoint("TOPLEFT", characterList, "TOPRIGHT", 2, 0)
characterDetails:SetPoint("RIGHT", -5, 0)

characterDetails.Background = characterDetails:CreateTexture(nil, "BACKGROUND")
characterDetails.Background:SetAtlas("Professions-Recipe-Background", false)
characterDetails.Background:SetAllPoints()
characterDetails.NineSlice = CreateFrame("Frame", nil, characterDetails, "NineSlicePanelTemplate")
characterDetails.NineSlice.layoutType = "InsetFrameTemplate"
characterDetails.NineSlice:SetAllPoints()
---@diagnostic disable-next-line: undefined-field
characterDetails.NineSlice:OnLoad()

local noteFrame = CreateFrame("Frame", nil, characterDetails)
noteFrame:SetSize(300, 144)
noteFrame:SetPoint("RIGHT", -8, 0)
noteFrame:SetShown(false)
noteFrame.Border = noteFrame:CreateTexture(nil, "ARTWORK")
noteFrame.Border:SetAtlas("CraftingOrders-NoteFrameNarrow", true)
noteFrame.Border:SetPoint("CENTER", 0, -17)
noteFrame.TitleBox = CreateFrame("Frame", nil, noteFrame)
noteFrame.TitleBox:SetPoint("TOPLEFT", 16, 0)
noteFrame.TitleBox:SetPoint("BOTTOMRIGHT", noteFrame, "TOPRIGHT", -24, -23)
noteFrame.Title = noteFrame.TitleBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
noteFrame.Title:SetSize(200, 1)
noteFrame.Title:SetPoint("LEFT", 10, 0)
noteFrame.Title:SetJustifyH("LEFT")
noteFrame.Title:SetText("Good to Know")
noteFrame.EditBox = CreateFrame("Frame", nil, noteFrame, "ScrollingEditBoxTemplate")
noteFrame.EditBox:SetFrameStrata("HIGH")
noteFrame.EditBox.fontName = "GameFontHighlight"
---@diagnostic disable-next-line: undefined-field
noteFrame.EditBox:SetDefaultText("Write something interesting about this character to be remembered next time playing together.")
noteFrame.EditBox.maxLetters = 1000
noteFrame.EditBox:SetPoint("TOPLEFT", noteFrame.TitleBox, "BOTTOMLEFT", 10, -3)
noteFrame.EditBox:SetPoint("BOTTOMRIGHT", -32, 5)

noteFrame.EditBox.ScrollBox.EditBox:HookScript("OnKeyDown", function(self, key)
    if key == "ENTER" and not IsShiftKeyDown() then
        self:ClearFocus()
        Notes.OnCharacterNoteChanged()
    end
end)

characterDetails.Note = noteFrame

local summaryFrame = CreateFrame("Frame", nil, characterDetails)
summaryFrame:SetPoint("TOPLEFT", 16, -16)
summaryFrame:SetPoint("RIGHT", noteFrame, "LEFT", -8)
summaryFrame:SetPoint("BOTTOM", 0, -16)
summaryFrame.CharacterName = summaryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
summaryFrame.CharacterName:SetHeight(20)
summaryFrame.CharacterName:SetPoint("TOPLEFT", 16, -16)
summaryFrame.CharacterRealm = summaryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
summaryFrame.CharacterRealm:SetHeight(16)
summaryFrame.CharacterRealm:SetPoint("TOPLEFT", summaryFrame.CharacterName, "BOTTOMLEFT", 0, -4)
summaryFrame.CharacterGuild = summaryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
summaryFrame.CharacterGuild:SetHeight(16)
summaryFrame.CharacterGuild:SetPoint("TOPLEFT", summaryFrame.CharacterRealm, "BOTTOMLEFT", 0, -1)
summaryFrame.CharacterGuild:SetTextColor(0, 1, 0)
summaryFrame.ActivitiesCounter = summaryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
summaryFrame.ActivitiesCounter:SetHeight(20)
summaryFrame.ActivitiesCounter:SetPoint("TOPLEFT", summaryFrame.CharacterGuild, "BOTTOMLEFT", 0, -8)
summaryFrame.ActivitiesCounter:SetHeight(20)

characterDetails.Summary = summaryFrame

function characterDetails:Refresh()
    local characterInfo = Notes.selectedCharacterInfo

    self.Summary.CharacterName:SetText(Notes.GetColoredName(characterInfo))
    self.Summary.CharacterRealm:SetText(characterInfo.Realm)
    self.Summary.CharacterGuild:SetText(characterInfo.Guild)
    local characterData = Dragtheron_WelcomeBack.KnownCharacters[characterInfo.Id]
    local activities = characterData.Activities

    if #activities > 0 then
        self.Summary.ActivitiesCounter:SetText(format("Activities played with this character: %d", #activities))
    else
        self.Summary.ActivitiesCounter:SetText("|cff888888Character is not known yet.|r")
    end


    if characterInfo ~= self.characterInfo then
    ---@diagnostic disable-next-line: undefined-field
        self.Note.EditBox:SetDefaultTextEnabled(true)
    ---@diagnostic disable-next-line: undefined-field
        self.Note.EditBox:SetText(characterData.Note or "")
    end

    self.characterInfo = characterInfo
    self.Note:SetShown(#activities > 0)
end

mainFrame.CharacterDetails = characterDetails

local activitiesFrame = CreateFrame("Frame", "$parentCharacterActivities", mainFrame)
activitiesFrame:SetPoint("TOPLEFT", characterDetails, "BOTTOMLEFT", 0, -2)
activitiesFrame:SetPoint("BOTTOMRIGHT", -5, 5)

activitiesFrame.Background = activitiesFrame:CreateTexture(nil, "BACKGROUND")
activitiesFrame.Background:SetAtlas("Professions-Recipe-Background", false)
activitiesFrame.Background:SetAllPoints()
activitiesFrame.NineSlice = CreateFrame("Frame", nil, activitiesFrame, "NineSlicePanelTemplate")
activitiesFrame.NineSlice.layoutType = "InsetFrameTemplate"
activitiesFrame.NineSlice:SetAllPoints()
---@diagnostic disable-next-line: undefined-field
activitiesFrame.NineSlice:OnLoad()

activitiesFrame.ScrollBox = CreateFrame("Frame", nil, activitiesFrame, "WowScrollBoxList")
activitiesFrame.ScrollBox:SetPoint("TOPLEFT", 8, -7)
activitiesFrame.ScrollBox:SetPoint("BOTTOMRIGHT", -20, 5)
---@diagnostic disable-next-line: undefined-field
activitiesFrame.ScrollBox:OnLoad()

activitiesFrame.ScrollBar = CreateFrame("EventFrame", nil, activitiesFrame, "MinimalScrollBar")
activitiesFrame.ScrollBar:SetPoint("TOPLEFT", activitiesFrame.ScrollBox, "TOPRIGHT", 0, -7)
activitiesFrame.ScrollBar:SetPoint("BOTTOMLEFT", activitiesFrame.ScrollBox, "BOTTOMRIGHT", 0, 0)
---@diagnostic disable-next-line: undefined-field
activitiesFrame.ScrollBar:OnLoad()

activitiesFrame.NoResultsText = activitiesFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
activitiesFrame.NoResultsText:SetText("No activites found.")
activitiesFrame.NoResultsText:SetSize(200, 0)
activitiesFrame.NoResultsText:SetPoint("TOP", 0, -60)

local activitiesListView = CreateScrollBoxListTreeListView(10, 5, 5, 0, 5, 1)

activitiesListView:SetElementFactory(function(factory, node)
    local elementData = node:GetData()

    if elementData.categoryInfo then
        local function Initializer(button, _node)
            button:Init(_node)

            button:SetScript("OnClick", function(_button)
                _node:ToggleCollapsed()
                _button:SetCollapseState(_node:IsCollapsed())
            end)
        end

        factory("WelcomeBack_NotesActivityCategoryTemplate", Initializer)
    elseif elementData.activityInfo then
        local function Initializer(button, _node)
            button:Init(_node)

            button:SetScript("OnClick", function(_button)
                _node:ToggleCollapsed()
                _button:SetCollapseState(_node:IsCollapsed())
            end)

            button:SetScript("OnEnter", function()
                WelcomeBack_NotesActivityMixin.OnEnter(button)
            end)

            button:SetScript("OnLeave", function()
                WelcomeBack_NotesActivityMixin.OnLeave(button)
            end)
        end

        factory("WelcomeBack_NotesActivityTemplate", Initializer)
    elseif elementData.encounterInfo then
        local function Initializer(button, _node)
            button:Init(_node)
        end
        factory("WelcomeBack_NotesEncounterTemplate", Initializer)
    elseif elementData.trashCount then
        local function Initializer(button, _node)
            button:Init(_node)
        end
        factory("WelcomeBack_NotesTrashCountTemplate", Initializer)
    else
        factory("Frame")
    end
end)

activitiesListView:SetElementExtentCalculator(function(_, node)
    local elementData = node:GetData()
    local baseElementHeight = 20
    local categoryPadding = 5

    if elementData.encounterInfo then
        return baseElementHeight
    end

    if elementData.trashCount then
        return baseElementHeight
    end

    if elementData.activityInfo then
        return baseElementHeight + categoryPadding
    end

    if elementData.categoryInfo then
        return baseElementHeight + categoryPadding
    end

    if elementData.topPadding then
        return 1
    end

    if elementData.bottomPadding then
        return 10
    end
end)

function activitiesFrame:StoreCollapses(scrollbox)
    self.collapses = {
        categories = {},
        activities = {},
    }

    local dataProvider = scrollbox:GetDataProvider()
    local categoryNodes = dataProvider:GetChildrenNodes()

    for _, categoryNode in ipairs(categoryNodes) do
        if categoryNode.data and categoryNode:IsCollapsed() and categoryNode.data.categoryInfo then
            self.collapses.categories[categoryNode.data.categoryInfo.index] = true
        end

        for _, activityNode in ipairs(categoryNode.nodes) do
            if activityNode.data and activityNode:IsCollapsed() and activityNode.data.activityInfo then
                self.collapses.activities[activityNode.data.activityInfo.index] = true
            end
        end
    end
end

function activitiesFrame:GetCollapses()
    return self.collapses
end

function activitiesFrame:Refresh()
    local characterInfo = Notes.selectedCharacterInfo
    local characterData = Dragtheron_WelcomeBack.KnownCharacters[characterInfo.Id]
    local activities = characterData.Activities
    Notes:RefreshActivityData(self:GetCollapses())
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.view)
    self.ScrollBox:SetDataProvider(activitiesDataProvider, ScrollBoxConstants.RetainScrollPosition)
    self.NoResultsText:SetShown(#activities == 0)
end

activitiesFrame.view = activitiesListView
mainFrame.Activities = activitiesFrame
Notes.frame = mainFrame

function Notes:Init()
    ScrollUtil.InitScrollBoxListWithScrollBar(characterList.ScrollBox, characterList.ScrollBar, characterListView)
    characterList.ScrollBox:SetDataProvider(characterDataProvider, ScrollBoxConstants.RetainScrollPosition)

    ScrollUtil.InitScrollBoxListWithScrollBar(self.frame.Activities.ScrollBox, self.frame.Activities.ScrollBar, self.frame.Activities.view)
    self.frame.Activities.ScrollBox:SetDataProvider(activitiesDataProvider, ScrollBoxConstants.RetainScrollPosition)

    self:Refresh()
end

function Notes:Refresh()
    if not self.shown then
        return
    end

    self:RefreshCharacterData()
    characterList.NoResultsText:SetShown(characterDataProvider:IsEmpty())

    if self.selectedCharacterInfo then
        local characterInfo = Notes.selectedCharacterInfo
        local characterData = Dragtheron_WelcomeBack.KnownCharacters[characterInfo.Id]
        local activities = characterData.Activities
        self.frame.Activities.NoResultsText:SetShown(#activities == 0)
        -- activitiesFrame:StoreCollapses(activitiesFrame.ScrollBox)
        Notes:RefreshActivityData(self.frame.Activities:GetCollapses())
    end
end

function Notes:ShowFrame()
    self:Refresh()
    self.shown = true
    ShowUIPanel(self.frame)
end

function Notes:HideFrame()
    self.shown = false
    HideUIPanel(self.frame)
end

function WelcomeBack_ToggleNotesFrame()
    if Notes.frame:IsShown() then
        Notes:HideFrame()
    else
        Notes:ShowFrame()
    end
end

function Notes.OnEvent(self, event, ...)
    if event == "VARIABLES_LOADED" then
        if not Notes.initialized then
            Notes.initialized = true
            Notes:Init()
        end
    end
end

function Notes:MatchesFilter(characterInfo)
    for filterType, filter in pairs(Notes.filters) do
        if filterType == Filter.CharacterName then
            local forceRealm = true

            local characterName = string.lower(self.GetCharacterName(characterInfo, forceRealm))
            if not string.match(characterName, ".*" .. string.lower(filter) .. ".*") then
                return false
            end
        end
    end

    return true
end

function Notes:RefreshCharacterData()
    characterDataProvider:Flush()
    local characterInfo = {}
    local lastGroupCharacterInfo = {}
    local previousGroupCharacterInfo = {}

    local lastGroupCategoryInfo = {
        name = "Current Activity",
        uiOrder = 0,
        group = Group.LastGroup,
        highlightKnown = true,
    }

    local previousGroupCategoryInfo = {
        name = "Last Activity",
        uiOrder = 1,
        group = Group.PreviousGroup,
        highlightCurrentGroupMembers = true,
    }

    local knownCharactersCategoryInfo = {
        name = "Known Characters",
        uiOrder = 2,
        group = Group.KnownCharacters,
        highlightCurrentGroupMembers = true,
    }

    for characterId, characterData in pairs(Dragtheron_WelcomeBack.KnownCharacters) do
        local character = {
            Name = characterData.CharacterInfo.Name,
            Realm = characterData.CharacterInfo.Realm,
            ClassFilename = characterData.CharacterInfo.ClassFilename,
            Guild = characterData.CharacterInfo.Guild,
            Note = characterData.Note,
            Id = characterId,
        }

        if Dragtheron_WelcomeBack.LastGroup[characterId] then
            character.InGroup = true
        end

        local isKnownCharacter = #Dragtheron_WelcomeBack.KnownCharacters[character.Id].Activities > 0

        if isKnownCharacter then
            character.Known = true
        end

        if self:MatchesFilter(character) then
            if #characterData.Activities > 0 then
                table.insert(characterInfo, character)
            end

            if Dragtheron_WelcomeBack.LastGroup[characterId] then
                table.insert(lastGroupCharacterInfo, character)
            end

            if Dragtheron_WelcomeBack.PreviousGroup and Dragtheron_WelcomeBack.PreviousGroup[characterId] then
                table.insert(previousGroupCharacterInfo, character)
            end
        end
    end

    lastGroupCategoryInfo.characters = lastGroupCharacterInfo
    knownCharactersCategoryInfo.characters = characterInfo
    previousGroupCategoryInfo.characters = previousGroupCharacterInfo

    local categories = {
        lastGroupCategoryInfo,
        previousGroupCategoryInfo,
        knownCharactersCategoryInfo,
    }

    local counter = 1

    local rootNode = characterDataProvider:GetRootNode()

    for _, categoryInfo in pairs(categories) do
        addTreeDataForCategory(categoryInfo, rootNode)
        counter = counter + 1
    end
end

function Notes:RefreshActivityData(collapses)
    activitiesDataProvider:Flush()
    local characterData = Dragtheron_WelcomeBack.KnownCharacters[self.selectedCharacterInfo.Id]

    if not characterData.Activities or #characterData.Activities == 0 then
        return
    end

    local currentRaidActivities = {}
    local oldRaidActivities = {}
    local keystoneActivities = {}
    local genericActivities = {}

    local currentRaidActivityInfo = {
        name = "Current Raids",
        uiOrder = 0,
        group = ActivityGroup.Raids,
        index = 1,
    }

    local oldRaidActivityInfo = {
        name = "Expired Raids",
        uiOrder = 1,
        group = ActivityGroup.Raids,
        index = 2,
    }

    local keystoneActivityInfo = {
        name = "Mythic Keystone Dungeons",
        uiOrder = 2,
        group = ActivityGroup.Keystones,
        index = 3,
    }

    local genericActivityInfo = {
        name = "Other Activities",
        uiOrder = 3,
        group = ActivityGroup.Generic,
        index = 4,
    }
    for i = #characterData.Activities, 1, -1 do
        local activity = characterData.Activities[i]
        local activityInfo = activity

        activity.index = i

        if activity.Activity.Type == "raid" then
            if addon.HaveWeMet:IsCurrentLockout(activity.Activity) then
                table.insert(currentRaidActivities, activityInfo)
            else
                activityInfo.collapsed = true
                table.insert(oldRaidActivities, activityInfo)
            end
        elseif activity.Activity.KeystoneLevel then
            table.insert(keystoneActivities, activityInfo)
        else
            table.insert(genericActivities, activity)
        end
    end

    currentRaidActivityInfo.activities = currentRaidActivities
    oldRaidActivityInfo.activities = oldRaidActivities
    keystoneActivityInfo.activities = keystoneActivities
    genericActivityInfo.activities = genericActivities

    local categories = { currentRaidActivityInfo, oldRaidActivityInfo, keystoneActivityInfo, genericActivityInfo }

    for _, categoryInfo in pairs(categories) do
        addTreeDataForActivityCategory(categoryInfo, activitiesDataProvider:GetRootNode(), collapses)
    end
end

function Notes:SetCharacterNameFilter(text)
    self.filters[Filter.CharacterName] = text
    self:Refresh()
end

function Notes.OnUpdate()
    if not Notes.frame:IsShown() then
        return
    end

    if Notes.updateTimer then
        Notes.updateTimer:Cancel()
    end

    Notes.updateTimer = C_Timer.NewTimer(3, function()
        Notes:Refresh()
        Notes.OnActivityUpdate()
    end)
end

function Notes.OnActivityUpdate()
    if not Notes.frame:IsShown() then
        return
    end

    local lastActivity = addon.HaveWeMet.lastActivity

    if Notes.updating then
        return
    end

    Notes.updating = true

    if not lastActivity then
        Notes.updating = false
        return
    end

    local detailsString, titleString, activity = addon.Progress.GetActivityProgress(lastActivity)
    Notes.frame.Header.currentActivity = activity

    if detailsString and titleString then
        Notes.frame.Header.Label:SetText(titleString)
        Notes.frame.Header.Progress:SetText(detailsString)
        Notes.frame.Header.Progress:SetShown(true)
        Notes.frame.Header.Label:SetShown(true)
    else
        Notes.frame.Header.Label:SetShown(false)
        Notes.frame.Header.Progress:SetShown(false)
    end

    Notes.updating = false
end

function Notes:SetSearchText(text)
    self.frame.characterList.SearchBox:SetText(text)
    self:SetCharacterNameFilter(text)
end

function Notes.GetColoredName(characterInfo)
    local classColor = characterInfo.ClassFilename
        and RAID_CLASS_COLORS[characterInfo.ClassFilename]
        or NORMAL_FONT_COLOR

    return classColor:WrapTextInColorCode(characterInfo.Name)
end

function Notes.GetColoredCharacterName(characterInfo, forceRealm)
    local characterName = Notes.GetColoredName(characterInfo)
    return Notes.AppendRealm(characterName, characterInfo.Realm, forceRealm)
end

function Notes.GetCharacterName(characterInfo, forceRealm)
    local characterName = characterInfo.Name
    return Notes.AppendRealm(characterName, characterInfo.Realm, forceRealm)
end

function Notes.AppendRealm(text, realm, force)

    if force or realm ~= GetNormalizedRealmName() then
        return format("%s-%s", text, realm)
    end

    return text
end

function Notes:OnCharacterSelected(characterInfo)
    self.selectedCharacterInfo = characterInfo
    self.frame.CharacterDetails:Refresh()
    self.frame.Activities:Refresh()
end

function Notes.OnCharacterNoteChanged()
    if not Notes.selectedCharacterInfo then
        return
    end

    local editBox = Notes.frame.CharacterDetails.Note.EditBox
    local text = editBox:GetInputText()

    if string.sub(text, -2, -1) == '\n' then
        text = string.sub(text, 1, -1)
    end

    C_Timer.NewTimer(0.1, function()
        editBox:ClearFocus()
        editBox:SetText(text)
    end)

    Dragtheron_WelcomeBack.KnownCharacters[Notes.selectedCharacterInfo.Id].Note = text
    print(format("Saved note: %s", text))
end

Notes.frame:RegisterEvent("VARIABLES_LOADED")
Notes.frame:SetScript("OnEvent", Notes.OnEvent)

EventRegistry:RegisterCallback(addonName .. ".Notes.OnCharacterSelected", Notes.OnCharacterSelected, Notes)
EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.Update", Notes.OnUpdate, Notes)
EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.ActivityUpdate", Notes.OnActivityUpdate, Notes)
