local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local PrototypeLayout = require(script.Parent.Parent.Simulation.PrototypeLayout)
local PrototypeScene = require(script.Parent.Parent.Simulation.PrototypeScene)

local BuildablesRuntime = require(script.Parent.Parent.Simulation.World.Buildables)
local Economy = require(script.Parent.Parent.Simulation.World.Economy)
local EnemiesRuntime = require(script.Parent.Parent.Simulation.World.Enemies)
local Skills = require(script.Parent.Parent.Simulation.World.Skills)
local WorldShared = require(script.Parent.Parent.Simulation.World.Shared)

local WorldService = {}
WorldService.__index = WorldService

local function mixin(target, source)
	for name, value in pairs(source) do
		target[name] = value
	end
end

mixin(WorldService, BuildablesRuntime)
mixin(WorldService, Economy)
mixin(WorldService, EnemiesRuntime)
mixin(WorldService, Skills)

function WorldService.new()
	local self = setmetatable({}, WorldService)

	self.layout = PrototypeLayout
	self.scene = PrototypeScene.new(self.layout)
	self.clock = 0
	self.nextEnemyId = 0
	self.slotById = {}
	self.slotOccupancy = {}
	self.activeEnemies = {}
	self.activeBuildables = {}
	self.starterBuildIds = {}
	self.activeWave = nil
	self.delayedEffects = {}
	self.activeModifiers = {}
	self.bonusState = WorldShared.createBonusState()
	self.laneEffects = {}

	for _, laneId in ipairs(self.layout.laneOrder) do
		self.laneEffects[laneId] = WorldShared.createLaneEffectState()

		for _, slot in ipairs(self.layout.lanes[laneId].slots) do
			self.slotById[slot.id] = WorldShared.cloneTable(slot)
			self.slotById[slot.id].laneId = laneId
		end
	end

	return self
end

function WorldService:start()
	self.scene:ensureBuilt()
end

function WorldService:bindPlayer(player, laneId)
	self.scene:bindPlayer(player, laneId)
end

function WorldService:removePlayer(player)
	self.scene:removePlayer(player)
end

function WorldService:beginWave(waveDefinition)
	self:_ensureStarterBuildables()

	self.activeWave = {
		waveIndex = waveDefinition.index,
		spawnTracks = {},
	}

	self.scene:setPhaseText(string.format("Combat • Wave %d", waveDefinition.index))

	for _, spawnDefinition in ipairs(waveDefinition.spawns) do
		local totalCount = spawnDefinition.count

		if spawnDefinition.enemyId == "Necrocaller" and self.bonusState.summonerBonusSpawns > 0 then
			totalCount += self.bonusState.summonerBonusSpawns
		end

		table.insert(self.activeWave.spawnTracks, {
			burstSize = spawnDefinition.burstSize or 1,
			enemyId = spawnDefinition.enemyId,
			intervalSeconds = spawnDefinition.intervalSeconds,
			laneId = spawnDefinition.laneId or "North",
			remaining = totalCount,
			timer = 0,
		})
	end
end

function WorldService:beginPrep(nextWaveIndex, matchState)
	self.activeWave = nil
	self.delayedEffects = {}
	self.scene:setPhaseText(string.format("Prep • Wave %d", nextWaveIndex))

	for _, laneId in ipairs(self.layout.laneOrder) do
		local laneState = matchState.lanes[laneId]

		if self.bonusState.prepGateRegen > 0 then
			laneState.gateHealth = math.min(GameConfig.Health.gate, laneState.gateHealth + self.bonusState.prepGateRegen)
		end

		if self.bonusState.passiveGateShield > 0 then
			self.laneEffects[laneId].shield = math.max(self.laneEffects[laneId].shield, self.bonusState.passiveGateShield)
		end
	end
end

function WorldService:beginReward(isBossReward)
	self.scene:setPhaseText(isBossReward and "Boss Reward" or "Reward Draft")
end

function WorldService:beginLobby()
	self.scene:setPhaseText("Lobby")
end

function WorldService:step(deltaTime, matchState)
	local previousSignature = self:_captureStateSignature(matchState)

	self.clock += deltaTime
	self:_ensureStarterBuildables()
	self:_stepWaveSpawner(deltaTime)
	self:_stepDelayedEffects(matchState)
	self:_stepBuildables(deltaTime, matchState)
	self:_stepLaneEffects(deltaTime, matchState)
	self:_stepEnemies(deltaTime, matchState)
	self:_updateLaneTelemetry(matchState)

	for _, laneId in ipairs(self.layout.laneOrder) do
		self.scene:updateGate(laneId, matchState.lanes[laneId].gateHealth, GameConfig.Health.gate)
	end

	self.scene:updateCore(matchState.coreHealth, GameConfig.Health.core)

	return previousSignature ~= self:_captureStateSignature(matchState)
end

return WorldService
