local addonName, addon = ...

local Module = {}

Module.KeystoneEncounters = {}
Module.KeystoneShorthands = {}

function Module:AddKeystone(challengeModeId, shorthand, encounterIds)
    self.KeystoneEncounters[challengeModeId] = encounterIds
    self.KeystoneShorthands[challengeModeId] = shorthand
end

function Module:GetEncounterIds(challengeModeId)
    return self.KeystoneEncounters[challengeModeId]
end

addon.Keystones = Module
