local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CampUpgrades = require(Shared.Config.CampUpgrades)
local Classes = require(Shared.Config.Classes)

local ProgressionService = {}
ProgressionService.__index = ProgressionService

local function buildClassMasteryState()
	local mastery = {}

	for classId in pairs(Classes) do
		mastery[classId] = {
			xp = 0,
			rank = 1,
		}
	end

	return mastery
end

local function buildCampUpgradeState()
	local upgrades = {}

	for upgradeId in pairs(CampUpgrades) do
		upgrades[upgradeId] = 0
	end

	return upgrades
end

local function buildDailyContracts()
	return {
		{
			id = "HoldTheLine",
			description = "Finish one Standard run.",
			progress = 0,
			goal = 1,
		},
		{
			id = "MasterBuilder",
			description = "Place 6 defenses in one run.",
			progress = 0,
			goal = 6,
		},
	}
end

function ProgressionService.new()
	local self = setmetatable({}, ProgressionService)
	self.profiles = {}
	return self
end

function ProgressionService:addPlayer(player)
	local profile = self.profiles[player.UserId]

	if profile then
		return profile
	end

	profile = {
		userId = player.UserId,
		name = player.Name,
		classMastery = buildClassMasteryState(),
		campUpgrades = buildCampUpgradeState(),
		dailyContracts = buildDailyContracts(),
		weeklyMutatorUnlocked = false,
		masteryBadges = {},
	}

	self.profiles[player.UserId] = profile
	return profile
end

function ProgressionService:removePlayer(player)
	return self.profiles[player.UserId]
end

function ProgressionService:getProfile(playerOrUserId)
	local userId = typeof(playerOrUserId) == "Instance" and playerOrUserId.UserId or playerOrUserId
	return self.profiles[userId]
end

function ProgressionService:getCampUpgradeLevel(userId, upgradeId)
	local profile = self:getProfile(userId)

	if not profile then
		return 0
	end

	return profile.campUpgrades[upgradeId] or 0
end

function ProgressionService:awardClassMastery(userId, classId, xp)
	local profile = self:getProfile(userId)

	if not profile then
		return
	end

	local masteryEntry = profile.classMastery[classId]

	if not masteryEntry then
		return
	end

	masteryEntry.xp += xp
	masteryEntry.rank = math.floor(masteryEntry.xp / 100) + 1

	if masteryEntry.rank >= 5 then
		profile.masteryBadges[classId] = string.format("%s-Rank-%d", classId, masteryEntry.rank)
	end
end

function ProgressionService:getMasteryRank(userId, classId)
	local profile = self:getProfile(userId)

	if not profile then
		return 1
	end

	local masteryEntry = profile.classMastery[classId]
	return masteryEntry and masteryEntry.rank or 1
end

function ProgressionService:getMasteryBadges(userId)
	local profile = self:getProfile(userId)

	if not profile then
		return {}
	end

	local badges = {}

	for _, badgeId in pairs(profile.masteryBadges) do
		table.insert(badges, badgeId)
	end

	table.sort(badges)
	return badges
end

function ProgressionService:incrementContract(userId, contractId, amount)
	local profile = self:getProfile(userId)

	if not profile then
		return
	end

	for _, contract in ipairs(profile.dailyContracts) do
		if contract.id == contractId then
			contract.progress = math.min(contract.goal, contract.progress + amount)
			break
		end
	end
end

return ProgressionService
