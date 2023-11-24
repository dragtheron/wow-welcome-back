local addonName, addon = ...

local Notes = {
    filters = {},
    initialized = false,
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
    local aOrder = aData.encounterInfo.order
    local bOrder = bData.encounterInfo.order

    if aOrder ~= bOrder then
        return aOrder < bOrder
    end
end

local function sortCategoryData(a, b)
    local aData = a:GetData()
    local bData = b:GetData()

    local aCategoryInfo = aData.categoryInfo
    local bCategoryInfo = bData.categoryInfo

    if aCategoryInfo or bCategoryInfo then
        if aCategoryInfo and not bCategoryInfo then
            return true
        elseif not aCategoryInfo and bCategoryInfo then
            return false
        elseif aCategoryInfo and bCategoryInfo then
            local aOrder = aCategoryInfo.uiOrder
            local bOrder = bCategoryInfo.uiOrder

            if aOrder ~= bOrder then
                return aOrder < bOrder
            end

            return strcmputf8i(aCategoryInfo.name, bCategoryInfo.name) < 0
        end
    end

    local aOrder = aData.order
    local bOrder = bData.order

    if aOrder ~= bOrder then
        return aOrder < bOrder
    end

    local aCharacterInfo = aData.characterInfo
    local bCharacterInfo = bData.characterInfo
    local aName = aCharacterInfo.Name
    local bName = bCharacterInfo.Name

    if aName ~= bName then
        return strcmputf8i(aName, bName) < 0
    end

    local aRealm = aCharacterInfo.Realm
    local bRealm = bCharacterInfo.Realm

    if aRealm ~= bRealm then
        return strcmputf8i(aRealm, bRealm) < 0
    end

    return strcmputf8i(aCharacterInfo.Id, bCharacterInfo.Id) < 0
end

local function addTreeDataForCategory(categoryInfo, node)
    if next(categoryInfo.characters) == nil then
        return
    end


    local categoryNode = node:Insert({ categoryInfo = categoryInfo, group = categoryInfo.group })
    local affectChildren = false
    local skipSort = false
    -- categoryNode:SetSortComparator(sortCategoryData, affectChildren, skipSort)

    if categoryInfo.collapsed then
        categoryNode:SetCollapsed(true)
    end

    categoryNode:Insert({topPadding=true, order = -1});

    for _, characterInfo in ipairs(categoryInfo.characters) do
        categoryNode:Insert({
            characterInfo = characterInfo,
            order = 0,
            highlightKnown = categoryInfo.highlightKnown,
            highlightCurrentGroupMembers = categoryInfo.highlightCurrentGroupMembers,
        })

        if characterInfo.collapsed then
            categoryNode:SetCollapsed(true)
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

    if categoryInfo.collapsed then
        categoryNode:SetCollapsed(true)
    end

    categoryNode:Insert({topPadding=true, order = -1});

    for _, activityInfo in ipairs(categoryInfo.activities) do
        local activityNode = categoryNode:Insert({ activityInfo = activityInfo, order = 0 })
        activityNode:SetSortComparator(sortEncounterData, affectChildren, skipSort)

        if collapses and collapses[activityInfo.index] then
            activityNode:SetCollapses(true)
        else
            if activityInfo.collapsed then
                activityNode:SetCollapsed(true)
            end
        end

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

            if encounterInfo.Success == 1 then
                uniqueEncounters[encounterInfo.Id].kills = uniqueEncounters[encounterInfo.Id].kills + 1
            else
                uniqueEncounters[encounterInfo.Id].wipes = uniqueEncounters[encounterInfo.Id].wipes + 1
            end

            table.insert(uniqueEncounters[encounterInfo.Id].times, encounterInfo.Time)
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

function WelcomeBack_NotesActivityMixin:Init(node)
    local elementData = node:GetData()
    local activityInfo = elementData.activityInfo
    local activityTitle = addon.HaveWeMet.GetActivityTitle(activityInfo.Activity)
    local activitySummary = addon.HaveWeMet.GetDetailsString(activityInfo)
    self.Label:SetText(activityTitle)
    self.Progress:SetText(activitySummary)
    self:SetCollapseState(node:IsCollapsed())
end

function WelcomeBack_NotesActivityMixin:OnEnter(node)
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

    GameTooltip:Show()
end

function WelcomeBack_NotesActivityMixin:OnLeave(node)
    self.Label:SetFontObject(GameFontNormal_NoShadow)
    GameTooltip:Hide()
end

WelcomeBack_NotesEncounterMixin = CreateFromMixins(WelcomeBack_NotesCategoryMixin)

function WelcomeBack_NotesEncounterMixin:Init(node)
    local elementData = node:GetData()
    local encounterInfo = elementData.encounterInfo
    local encounterTitle = encounterInfo.Name
    local encounterCounters = addon.HaveWeMet.GetKillsWipesCountString(encounterInfo.kills, encounterInfo.wipes)
    self.Label:SetFontObject(encounterInfo.kills > 0 and GameFontHighlight_NoShadow or GameFontDisable)
    self.Label:SetText(encounterTitle)
    self.Progress:SetText(encounterCounters)
end

function WelcomeBack_NotesEncounterMixin:OnEnter(node)
    local elementData = self:GetElementData()
    local encounterInfo = elementData.data.encounterInfo
    local encounterName = addon.HaveWeMet.GetEncounterTitleFromJournal(encounterInfo.instanceId, encounterInfo.Id)
    self.Label:SetFontObject(GameFontHighlight_NoShadow)
    self.HighlightOverlay:SetShown(false)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(encounterName)

    if encounterInfo.times then
        for _, disengageTime in ipairs(encounterInfo.times) do
            local encounterTime = addon.HaveWeMet.GetDateString(disengageTime)
            GameTooltip:AddLine(encounterTime, 1, 1, 1)
        end
    end

    GameTooltip:Show()
end

function WelcomeBack_NotesEncounterMixin:OnLeave()
    local elementData = self:GetElementData()
    local encounterInfo = elementData.data.encounterInfo
    self.Label:SetFontObject(encounterInfo.kills > 0 and GameFontHighlight_NoShadow or GameFontDisable)
end

WelcomeBack_NotesActivityCategoryMixin = CreateFromMixins(WelcomeBack_NotesCategoryMixin)

function WelcomeBack_NotesActivityCategoryMixin:Init(node)
    local elementData = node:GetData()
    local categoryInfo = elementData.categoryInfo
    self.Label:SetText(categoryInfo.name)
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
mainFrame:SetTitle("Welcome Back: Notes")
mainFrame:SetPortraitToUnit("player")
mainFrame:SetPortraitToAsset("Interface\\ICONS\\achievement_guildperk_havegroup willtravel")

mainFrame:SetScript("OnHide", function()
    addon.Overlay.frame:Show()
end)

mainFrame:SetScript("OnShow", function()
    addon.Overlay.frame:Hide()
end)

local header = CreateFrame("Frame", "$parentHeader", mainFrame)
header:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 64, -34)
header:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -28, -68)
header.Label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header.Label:SetPoint("LEFT", 0, 0)
header.Label:SetJustifyH("LEFT")
header.Label:SetText("Loading...")
header.Progress = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight_NoShadow")
header.Progress:SetHeight(header:GetHeight())
header.Progress:SetWidth(200)
header.Progress:SetPoint("RIGHT", 0, 0)
header.Progress:SetJustifyH("RIGHT")
header.Progress:SetText("...")

mainFrame.Header = header

local characterList = CreateFrame("Frame", "$parentCharacters", mainFrame)
characterList:SetWidth(274)
characterList:SetPoint("TOPLEFT", 5, -72)
characterList:SetPoint("BOTTOMLEFT", 0, 5)
CallbackRegistryMixin.OnLoad(characterList)
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
characterList.ScrollBox:OnLoad()

characterList.ScrollBar = CreateFrame("EventFrame", nil, characterList, "MinimalScrollBar")
characterList.ScrollBar:SetPoint("TOPLEFT", characterList.ScrollBox, "TOPRIGHT", 0, 0)
characterList.ScrollBar:SetPoint("BOTTOMLEFT", characterList.ScrollBox, "BOTTOMRIGHT", 0, 0)
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
noteFrame.EditBox:SetDefaultText("Write something interesting about this character to be remembered next time playing together.")
noteFrame.EditBox.maxLetters = 1000
noteFrame.EditBox:SetPoint("TOPLEFT", noteFrame.TitleBox, "BOTTOMLEFT", 10, -3)
noteFrame.EditBox:SetPoint("BOTTOMRIGHT", -32, 5)

noteFrame.EditBox:RegisterCallback("OnTextChanged", function() Notes.OnCharacterNoteChanged() end)

characterDetails.Note = noteFrame

local summaryFrame = CreateFrame("Frame", nil, characterDetails)
summaryFrame:SetPoint("TOPLEFT", 16, -16)
summaryFrame:SetPoint("RIGHT", noteFrame, "LEFT", -8)
summaryFrame:SetPoint("BOTTOM", 0, -16)
summaryFrame.CharacterName = summaryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
summaryFrame.CharacterName:SetHeight(20)
summaryFrame.CharacterName:SetPoint("TOPLEFT", 16, -16)
summaryFrame.CharacterRealm = summaryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
summaryFrame.CharacterRealm:SetHeight(20)
summaryFrame.CharacterRealm:SetPoint("TOPLEFT", summaryFrame.CharacterName, "BOTTOMLEFT", 0, -8)
summaryFrame.ActivitiesCounter = summaryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
summaryFrame.ActivitiesCounter:SetHeight(20)
summaryFrame.ActivitiesCounter:SetPoint("TOPLEFT", summaryFrame.CharacterRealm, "BOTTOMLEFT", 0, -8)
summaryFrame.ActivitiesCounter:SetHeight(20)

characterDetails.Summary = summaryFrame

function characterDetails:Refresh()
    local characterInfo = Notes.selectedCharacterInfo
    self.Summary.CharacterName:SetText(Notes.GetColoredName(characterInfo))
    self.Summary.CharacterRealm:SetText(characterInfo.Realm)

    local characterData = Dragtheron_WelcomeBack.KnownCharacters[characterInfo.Id]
    local activities = characterData.Activities

    if #activities > 0 then
        self.Summary.ActivitiesCounter:SetText(format("Activities played with this character: %d", #activities))
    else
        self.Summary.ActivitiesCounter:SetText("|cff888888Character is not known yet.|r")
    end

    self.Note.EditBox:SetDefaultTextEnabled(true)
    self.Note.EditBox:SetText(characterData.Note or "")
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
activitiesFrame.NineSlice:OnLoad()

activitiesFrame.ScrollBox = CreateFrame("Frame", nil, activitiesFrame, "WowScrollBoxList")
activitiesFrame.ScrollBox:SetPoint("TOPLEFT", 8, -7)
activitiesFrame.ScrollBox:SetPoint("BOTTOMRIGHT", -20, 5)
activitiesFrame.ScrollBox:OnLoad()

activitiesFrame.ScrollBar = CreateFrame("EventFrame", nil, activitiesFrame, "MinimalScrollBar")
activitiesFrame.ScrollBar:SetPoint("TOPLEFT", activitiesFrame.ScrollBox, "TOPRIGHT", 0, -7)
activitiesFrame.ScrollBar:SetPoint("BOTTOMLEFT", activitiesFrame.ScrollBox, "BOTTOMRIGHT", 0, 0)
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
    self.collapses = {}
    local dataProvider = scrollbox:GetDataProvider()
    local childrenNodes = dataProvider:GetChildrenNodes()

    for _, child in ipairs(childrenNodes) do
        if child.data and child:IsCollapsed() then
            self.collapses[child.data.activityInfo.index] = true
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

    local dataProvider = Notes:GenerateActivitiesDataProvider(self:GetCollapses())
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.view)
    self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
    self.NoResultsText:SetShown(#activities == 0)
end

activitiesFrame.view = activitiesListView
mainFrame.Activities = activitiesFrame
Notes.frame = mainFrame

function Notes:Init()
    local dataProvider = self:GenerateCharacterDataProvider()
    ScrollUtil.InitScrollBoxListWithScrollBar(characterList.ScrollBox, characterList.ScrollBar, characterListView)
    characterList.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
    characterList.NoResultsText:SetShown(dataProvider:IsEmpty())

    if self.selectedCharacterInfo then
        self.frame.CharacterDetails:Refresh()
        self.frame.Activities:Refresh()
    end
end

function Notes:Refresh()
    if self.selectedCharacterInfo then
        self.frame.Activities:StoreCollapses(activitiesFrame.ScrollBox)
    end

    self:Init()
end

function Notes:ShowFrame()
    self:Refresh()
    ShowUIPanel(self.frame)
end

function Notes:HideFrame()
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
        if not self.initialized then
            self.initialized = true
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

function Notes:GenerateCharacterDataProvider()
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

    local dataProvider = CreateTreeDataProvider()
    local node = dataProvider:GetRootNode()
    local affectChildren = false
    local skipSort = false
    node:SetSortComparator(sortRootData, affectChildren, skipSort)

    for _, categoryInfo in pairs(categories) do
        addTreeDataForCategory(categoryInfo, node)
    end

    return dataProvider
end

function Notes:GenerateActivitiesDataProvider(collapses)
    local characterData = Dragtheron_WelcomeBack.KnownCharacters[self.selectedCharacterInfo.Id]
    local dataProvider = CreateTreeDataProvider()

    if not characterData.Activities or #characterData.Activities == 0 then
        return dataProvider
    end

    local raidActivities = {}
    local keystoneActivities = {}
    local genericActivities = {}

    local raidActivityInfo = {
        name = "Raids",
        uiOrder = 0,
        group = ActivityGroup.Raids,
    }

    local keystoneActivityInfo = {
        name = "Mythic Keystone Dungeons",
        uiOrder = 1,
        group = ActivityGroup.Keystones,
    }

    local genericActivityInfo = {
        name = "Other Activities",
        uiOrder = 2,
        group = ActivityGroup.Generic,
    }
    for i = #characterData.Activities, 1, -1 do
        local activity = characterData.Activities[i]
        local activityInfo = activity

        activity.index = i

        if activity.Activity.Type == "raid" then
            if #raidActivities > 0 then
                activityInfo.collapsed = true
            end

            table.insert(raidActivities, activityInfo)
        elseif activity.Activity.KeystoneLevel then
            if #keystoneActivities > 0 then
                activityInfo.collapsed = true
            end

            table.insert(keystoneActivities, activityInfo)
        else
            if #genericActivities > 0 then
                activityInfo.collapsed = true
            end

            table.insert(genericActivities, activity)
        end
    end

    raidActivityInfo.activities = raidActivities
    keystoneActivityInfo.activities = keystoneActivities
    genericActivityInfo.activities = genericActivities

    local categories = { raidActivityInfo, keystoneActivityInfo, genericActivityInfo }

    local node = dataProvider:GetRootNode()
    local affectChildren = false
    local skipSort = false
    node:SetSortComparator(sortRootData, affectChildren, skipSort)

    for _, categoryInfo in pairs(categories) do
        addTreeDataForActivityCategory(categoryInfo, node, collapses)
    end

    return dataProvider
end

function Notes:SetCharacterNameFilter(text)
    self.filters[Filter.CharacterName] = text
    self:Refresh()
end

function Notes.OnUpdate()
    if Notes.updateTimer then
        Notes.updateTimer:Cancel()
    end

    Notes.updateTimer = C_Timer.NewTimer(3, function()
        Notes:Refresh()
        Notes.OnActivityUpdate()
    end)
end

function Notes.OnActivityUpdate()
    if Notes.activityUpdateTimer then
        Notes.activityUpdateTimer:Cancel()
    end

    Notes.activityUpdateTimer = C_Timer.NewTimer(3, function()
        local lastActivity = addon.HaveWeMet.lastActivity
        local activityName = addon.HaveWeMet.GetActivityTitle(lastActivity)

        if lastActivity then
            Notes.frame.Header.Label:SetText(format("Current Activity: |cffffffff%s|r", activityName))
            Notes.frame.Header.Label:SetShown(true)

            local defaultDetailsString = addon.HaveWeMet.GetDetailsString({
                Activity = lastActivity,
                Encounters = {},
            })

            Notes.frame.Header.Progress:SetText(defaultDetailsString)

            local playerGUID = UnitGUID("player")
            local playerProgress = Dragtheron_WelcomeBack.KnownCharacters[playerGUID]

            if playerProgress and #playerProgress.Activities > 0 then
                local playerLastActivity = playerProgress.Activities[#playerProgress.Activities]

                if addon.HaveWeMet.IsEqualActivity(playerLastActivity.Activity, lastActivity) then
                    local detailsString = addon.HaveWeMet.GetDetailsString(playerLastActivity)
                    Notes.frame.Header.Progress:SetText(detailsString)
                end
            end
        else
            Notes.frame.Header.Label:SetShown(false)
            Notes.frame.Header.Progress:SetShown(false)
        end
    end)
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

    local text = Notes.frame.CharacterDetails.Note.EditBox:GetInputText()
    Dragtheron_WelcomeBack.KnownCharacters[Notes.selectedCharacterInfo.Id].Note = text
end

Notes.frame:RegisterEvent("VARIABLES_LOADED")
Notes.frame:SetScript("OnEvent", Notes.OnEvent)

EventRegistry:RegisterCallback(addonName .. ".Notes.OnCharacterSelected", Notes.OnCharacterSelected, Notes)
EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.Update", Notes.OnUpdate, Notes)
EventRegistry:RegisterCallback(addonName .. ".HaveWeMet.ActivityUpdate", Notes.OnActivityUpdate, Notes)
