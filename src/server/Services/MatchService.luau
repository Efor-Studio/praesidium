local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Ids = require(Shared.Ids)
local Maps = require(Shared.Config.Maps)
local Modifiers = require(Shared.Config.Modifiers)
local RewardCards = require(Shared.Config.RewardCards)
local Waves = require(Shared.Config.Waves)
local RemoteNames = require(Shared.Networking.RemoteNames)
local BuildPlacementValidator = require(Shared.Validation.BuildPlacementValidator)
local LoadoutValidator = require(Shared.Validation.LoadoutValidator)

local REPLICATION_INTERVAL_SECONDS = 0.25

local MatchService = {}
MatchService.__index = MatchService

local function cloneArray(values)
	local clone = {}

	for index, value in ipairs(values) do
		clone[index] = value
	end

	return clone
end

local function arrayContains(values, expected)
	for _, value in ipairs(values) do
		if value == expected then
			return true
		end
	end

	return false
end

local function sortById(values)
	table.sort(values)
	return values
end

local function buildLaneState()
	local lanes = {}
	local mapDefinition = Maps[GameConfig.DefaultMapId]

	for _, laneId in ipairs(Ids.LaneIds) do
		local mapLane = mapDefinition.lanes[laneId]
		lanes[laneId] = {
			laneId = laneId,
			displayName = mapLane.displayName,
			gateHealth = GameConfig.Health.gate,
			leakPressure = 0,
			starterDefenseBuilt = true,
			starterBuildSlotId = mapLane.starterBuildSlotId,
		}
	end

	return lanes
end

local function countEstimatedWaveKills(waveDefinition)
	local total = 0

	for _, spawn in ipairs(waveDefinition.spawns) do
		total += spawn.count
	end

	return total
end

function MatchService.new(remotes, progressionService)
	local self = setmetatable({}, MatchService)

	self.remotes = remotes
	self.progressionService = progressionService
	self.skillQueue = {}
	self.placedBuildables = {
		North = {},
		East = {},
		West = {},
	}
	self.lastReplicatedAt = 0
	self.lastReplicatedRevision = -1
	self.world = nil
	self.components = nil
	self.entities = {}
	self.state = {
		runId = string.format("praesidium-%d", os.time()),
		modeId = GameConfig.StandardMode.id,
		mapId = GameConfig.DefaultMapId,
		phase = "Lobby",
		waveIndex = 0,
		nextWaveIndex = 1,
		secondsRemaining = 0,
		phaseStartedAt = os.clock(),
		startedAt = nil,
		endedAt = nil,
		coreHealth = GameConfig.Health.core,
		lanes = buildLaneState(),
		activeModifierIds = {},
		mapEvolutionId = nil,
		pendingReward = nil,
		players = {},
		scoreboard = {
			enemiesDefeated = 0,
			scrapCollected = 0,
			buildablesPlaced = 0,
			skillActivations = 0,
			revives = 0,
		},
		revision = 0,
	}

	self:_wireRemotes()
	return self
end

function MatchService:_wireRemotes()
	self.remotes[RemoteNames.SelectLoadout].OnServerInvoke = function(player, loadout)
		return self:selectLoadout(player, loadout)
	end

	self.remotes[RemoteNames.ActivateSkill].OnServerEvent:Connect(function(player, payload)
		self:queueSkillActivation(player, payload)
	end)

	self.remotes[RemoteNames.PlaceBuildable].OnServerInvoke = function(player, request)
		return self:placeBuildable(player, request)
	end

	self.remotes[RemoteNames.ChooseRewardCard].OnServerInvoke = function(player, rewardCardId)
		return self:chooseRewardCard(player, rewardCardId)
	end

	self.remotes[RemoteNames.ReadyForNextWave].OnServerEvent:Connect(function(player)
		self:readyForNextWave(player)
	end)
end

function MatchService:_markDirty()
	self.state.revision += 1
end

function MatchService:_setPhase(phase, secondsRemaining)
	self.state.phase = phase
	self.state.secondsRemaining = secondsRemaining or 0
	self.state.phaseStartedAt = os.clock()
	self:_markDirty()
end

function MatchService:_getWaveDefinition(waveIndex)
	return Waves[waveIndex]
end

function MatchService:_chooseLaneForNewPlayer()
	local counts = {
		North = 0,
		East = 0,
		West = 0,
	}

	for _, playerState in pairs(self.state.players) do
		counts[playerState.laneId] += 1
	end

	local chosenLaneId = Ids.LaneIds[1]

	for _, laneId in ipairs(Ids.LaneIds) do
		if counts[laneId] < counts[chosenLaneId] then
			chosenLaneId = laneId
		end
	end

	return chosenLaneId
end

function MatchService:_allPlayersReady()
	local hasPlayers = false

	for _, playerState in pairs(self.state.players) do
		hasPlayers = true

		if not playerState.readyForNextWave then
			return false
		end
	end

	return hasPlayers
end

function MatchService:_allRewardSelectionsMade()
	local pendingReward = self.state.pendingReward

	if not pendingReward then
		return false
	end

	for userId in pairs(self.state.players) do
		if pendingReward.optionsByUserId[tostring(userId)] and pendingReward.selectedByUserId[tostring(userId)] == nil then
			return false
		end
	end

	return true
end

function MatchService:_getPlayerState(player)
	return self.state.players[player.UserId]
end

function MatchService:_resetReadyFlags()
	for _, playerState in pairs(self.state.players) do
		playerState.readyForNextWave = false
	end
end

function MatchService:_estimateModifierForWave(waveIndex)
	local modifierIds = {}

	for modifierId in pairs(Modifiers) do
		if not arrayContains(self.state.activeModifierIds, modifierId) then
			table.insert(modifierIds, modifierId)
		end
	end

	sortById(modifierIds)

	if #modifierIds == 0 then
		return nil
	end

	local pickIndex = ((waveIndex - 1) % #modifierIds) + 1
	return modifierIds[pickIndex]
end

function MatchService:_rollRewardOptionsForPlayer(playerState, rewardCount, bossReward)
	local classId = playerState.loadout.classId
	local primaryPool = {}
	local fallbackPool = {}

	for rewardCardId, rewardDefinition in pairs(RewardCards) do
		if bossReward and rewardDefinition.bossOnly then
			table.insert(primaryPool, rewardCardId)
		elseif not bossReward and not rewardDefinition.bossOnly then
			if rewardDefinition.classId == nil or rewardDefinition.classId == classId then
				table.insert(primaryPool, rewardCardId)
			else
				table.insert(fallbackPool, rewardCardId)
			end
		elseif bossReward and not rewardDefinition.bossOnly then
			table.insert(fallbackPool, rewardCardId)
		end
	end

	sortById(primaryPool)
	sortById(fallbackPool)

	local combinedPool = {}

	for _, rewardCardId in ipairs(primaryPool) do
		table.insert(combinedPool, rewardCardId)
	end

	for _, rewardCardId in ipairs(fallbackPool) do
		table.insert(combinedPool, rewardCardId)
	end

	local options = {}

	if #combinedPool == 0 then
		return options
	end

	local startIndex = ((playerState.userId + self.state.waveIndex) % #combinedPool) + 1

	for offset = 0, #combinedPool - 1 do
		if #options >= rewardCount then
			break
		end

		local candidateIndex = ((startIndex + offset - 1) % #combinedPool) + 1
		local rewardCardId = combinedPool[candidateIndex]

		if not arrayContains(options, rewardCardId) then
			table.insert(options, rewardCardId)
		end
	end

	return options
end

function MatchService:_beginColdOpen()
	if self.state.phase ~= "Lobby" then
		return
	end

	self.state.startedAt = os.clock()
	self.state.nextWaveIndex = 1
	self:_setPhase("ColdOpen", GameConfig.StandardMode.coldOpenSeconds)
	self:announce("objective", {
		text = GameConfig.Onboarding.objectiveText,
		mapId = self.state.mapId,
	})
end

function MatchService:_beginWave(waveIndex)
	local waveDefinition = self:_getWaveDefinition(waveIndex)

	if not waveDefinition then
		self:_completeRun(true, "All waves cleared.")
		return
	end

	self.state.waveIndex = waveIndex
	self.state.nextWaveIndex = waveIndex + 1
	self.state.pendingReward = nil
	self:_resetReadyFlags()
	self:_setPhase("Combat", waveDefinition.combatSeconds)
	self:announce("wave_started", {
		waveIndex = waveDefinition.index,
		stage = waveDefinition.stage,
		isBossWave = waveDefinition.isBossWave,
	})
end

function MatchService:_beginPrepPhase(nextWaveIndex, secondsRemaining)
	self.state.nextWaveIndex = nextWaveIndex
	self:_resetReadyFlags()
	self:_setPhase("Prep", secondsRemaining)
	self:announce("prep_started", {
		nextWaveIndex = nextWaveIndex,
		secondsRemaining = secondsRemaining,
	})
end

function MatchService:_beginRewardPhase(waveDefinition)
	local pendingReward = {
		waveIndex = waveDefinition.index,
		bossReward = waveDefinition.isBossWave,
		modifierId = waveDefinition.modifierChoiceCount > 0 and self:_estimateModifierForWave(waveDefinition.index) or nil,
		optionsByUserId = {},
		selectedByUserId = {},
	}

	for userId, playerState in pairs(self.state.players) do
		playerState.selectedRewardCardId = nil
		pendingReward.optionsByUserId[tostring(userId)] = self:_rollRewardOptionsForPlayer(
			playerState,
			waveDefinition.rewardCardCount,
			waveDefinition.isBossWave
		)
	end

	self.state.pendingReward = pendingReward
	self:_setPhase(waveDefinition.isBossWave and "BossReward" or "Reward", 0)
	self:announce("reward_available", {
		waveIndex = waveDefinition.index,
		bossReward = waveDefinition.isBossWave,
		modifierId = pendingReward.modifierId,
	})
end

function MatchService:_applyWaveClearRewards(waveDefinition)
	local scrapReward = waveDefinition.isBossWave and GameConfig.Economy.bossWaveClearScrap or GameConfig.Economy.waveClearScrap

	for userId, playerState in pairs(self.state.players) do
		playerState.scrap += scrapReward
		self.state.scoreboard.scrapCollected += scrapReward
		self.progressionService:awardClassMastery(userId, playerState.loadout.classId, waveDefinition.isBossWave and 35 or 15)
	end

	self.state.scoreboard.enemiesDefeated += countEstimatedWaveKills(waveDefinition)
	self:_markDirty()
end

function MatchService:_completeWave(waveIndex)
	local waveDefinition = self:_getWaveDefinition(waveIndex)

	if not waveDefinition then
		return
	end

	self:_applyWaveClearRewards(waveDefinition)

	if waveIndex >= #Waves then
		self:_completeRun(true, "The final boss has fallen.")
		return
	end

	if waveDefinition.rewardCardCount > 0 or waveDefinition.isBossWave then
		self:_beginRewardPhase(waveDefinition)
	else
		self:_beginPrepPhase(waveIndex + 1, waveDefinition.prepSeconds)
	end
end

function MatchService:_completeRun(victory, reason)
	if self.state.phase == "Victory" or self.state.phase == "Defeat" then
		return
	end

	self.state.endedAt = os.clock()
	self.state.pendingReward = nil
	self:_setPhase(victory and "Victory" or "Defeat", 0)

	for userId, playerState in pairs(self.state.players) do
		self.progressionService:awardClassMastery(userId, playerState.loadout.classId, victory and 75 or 30)
		self.progressionService:incrementContract(userId, "HoldTheLine", victory and 1 or 0)
	end

	self:announce("run_ended", {
		result = victory and "Victory" or "Defeat",
		reason = reason,
	})
end

function MatchService:addPlayer(player)
	local startingLoadout = LoadoutValidator.buildDefaultLoadout(GameConfig.DefaultLoadout.classId)
	local startingScrap = GameConfig.Economy.starterScrap + self.progressionService:getCampUpgradeLevel(player.UserId, "QuartermasterHooks") * 10

	self.state.players[player.UserId] = {
		userId = player.UserId,
		name = player.Name,
		laneId = self:_chooseLaneForNewPlayer(),
		loadout = startingLoadout,
		scrap = startingScrap,
		readyForNextWave = false,
		selectedRewardCardId = nil,
		rewardCards = {},
		contribution = {
			buildablesPlaced = 0,
			scrapSpent = 0,
			skillActivations = 0,
		},
	}

	self:_markDirty()
	self:replicateToPlayer(player)

	if self.state.phase == "Lobby" then
		self:_beginColdOpen()
	end
end

function MatchService:removePlayer(player)
	self.state.players[player.UserId] = nil
	self:_markDirty()
	self:refreshRewardState()
end

function MatchService:selectLoadout(player, loadout)
	local playerState = self:_getPlayerState(player)

	if not playerState then
		return false, "Player session was not found."
	end

	local isValid, errorMessage = LoadoutValidator.validate(loadout)

	if not isValid then
		return false, errorMessage
	end

	playerState.loadout = {
		classId = loadout.classId,
		equippedSkillIds = cloneArray(loadout.equippedSkillIds),
		ultimateId = loadout.ultimateId,
	}

	self:_markDirty()
	return true, "Loadout selected."
end

function MatchService:queueSkillActivation(player, payload)
	local playerState = self:_getPlayerState(player)

	if not playerState or self.state.phase ~= "Combat" then
		return
	end

	if type(payload) ~= "table" or type(payload.skillId) ~= "string" then
		return
	end

	table.insert(self.skillQueue, {
		userId = player.UserId,
		skillId = payload.skillId,
		laneId = payload.laneId,
		queuedAt = os.clock(),
	})
end

function MatchService:_countBuildablesInLane(laneId, buildableId)
	local count = 0

	for _, buildRecord in ipairs(self.placedBuildables[laneId]) do
		if buildRecord.buildableId == buildableId then
			count += 1
		end
	end

	return count
end

function MatchService:placeBuildable(player, request)
	local playerState = self:_getPlayerState(player)

	if not playerState then
		return false, "Player session was not found."
	end

	local isValid, buildableDefinitionOrMessage = BuildPlacementValidator.validate(request)

	if not isValid then
		return false, buildableDefinitionOrMessage
	end

	local buildableDefinition = buildableDefinitionOrMessage

	if playerState.scrap < buildableDefinition.scrapCost then
		return false, "Not enough Scrap."
	end

	local perLaneCap = GameConfig.Buildables.perLaneCaps[request.buildableId] or buildableDefinition.buildLimitPerLane
	local existingCount = self:_countBuildablesInLane(request.laneId, request.buildableId)

	if existingCount >= perLaneCap then
		return false, "This buildable is already capped in that lane."
	end

	local buildRecord = {
		id = string.format("%s-%d-%d", request.buildableId, player.UserId, #self.placedBuildables[request.laneId] + 1),
		buildableId = request.buildableId,
		laneId = request.laneId,
		slotId = request.slotId,
		rotationY = request.rotationY or 0,
		ownerUserId = player.UserId,
		placedAt = os.clock(),
	}

	playerState.scrap -= buildableDefinition.scrapCost
	playerState.contribution.buildablesPlaced += 1
	playerState.contribution.scrapSpent += buildableDefinition.scrapCost
	self.state.scoreboard.buildablesPlaced += 1
	self.state.scoreboard.scrapCollected += buildableDefinition.scrapCost

	table.insert(self.placedBuildables[request.laneId], buildRecord)
	self.progressionService:incrementContract(player.UserId, "MasterBuilder", 1)
	self:_markDirty()

	return true, "Buildable placed.", buildRecord.id
end

function MatchService:chooseRewardCard(player, rewardCardId)
	local playerState = self:_getPlayerState(player)
	local pendingReward = self.state.pendingReward

	if not playerState then
		return false, "Player session was not found."
	end

	if not pendingReward then
		return false, "There is no active reward choice."
	end

	local userIdKey = tostring(player.UserId)
	local options = pendingReward.optionsByUserId[userIdKey]

	if options == nil or not arrayContains(options, rewardCardId) then
		return false, "That reward card is not currently offered."
	end

	pendingReward.selectedByUserId[userIdKey] = rewardCardId
	playerState.selectedRewardCardId = rewardCardId
	table.insert(playerState.rewardCards, rewardCardId)
	self:_markDirty()
	self:refreshRewardState()

	return true, "Reward card selected."
end

function MatchService:readyForNextWave(player)
	local playerState = self:_getPlayerState(player)

	if not playerState then
		return
	end

	if self.state.phase ~= "Prep" then
		return
	end

	playerState.readyForNextWave = true

	if self:_allPlayersReady() then
		self.state.secondsRemaining = 0
	end

	self:_markDirty()
end

function MatchService:step(deltaTime)
	if self.state.phase == "Lobby" then
		if next(self.state.players) ~= nil then
			self:_beginColdOpen()
		end

		return
	end

	if self.state.phase == "Victory" or self.state.phase == "Defeat" then
		return
	end

	if self.state.phase == "Reward" or self.state.phase == "BossReward" then
		self:refreshRewardState()
		return
	end

	local previousSeconds = self.state.secondsRemaining
	self.state.secondsRemaining = math.max(0, self.state.secondsRemaining - deltaTime)

	if math.ceil(previousSeconds) ~= math.ceil(self.state.secondsRemaining) then
		self:_markDirty()
	end

	if self.state.secondsRemaining > 0 then
		return
	end

	if self.state.phase == "ColdOpen" then
		self:_beginWave(1)
	elseif self.state.phase == "Combat" then
		self:_completeWave(self.state.waveIndex)
	elseif self.state.phase == "Prep" then
		self:_beginWave(self.state.nextWaveIndex)
	end
end

function MatchService:flushSkillQueue()
	if #self.skillQueue == 0 then
		return
	end

	for _, skillRequest in ipairs(self.skillQueue) do
		local playerState = self.state.players[skillRequest.userId]

		if playerState and (
			arrayContains(playerState.loadout.equippedSkillIds, skillRequest.skillId)
			or playerState.loadout.ultimateId == skillRequest.skillId
		) then
			playerState.contribution.skillActivations += 1
			self.state.scoreboard.skillActivations += 1

			if skillRequest.skillId == "ScrapSnare" then
				playerState.scrap += 3
				self.state.scoreboard.scrapCollected += 3
			end
		end
	end

	table.clear(self.skillQueue)
	self:_markDirty()
end

function MatchService:refreshLanePressure()
	local waveDefinition = self:_getWaveDefinition(self.state.waveIndex)
	local pressureByLane = {
		North = 0,
		East = 0,
		West = 0,
	}

	if self.state.phase == "Combat" and waveDefinition then
		for _, spawn in ipairs(waveDefinition.spawns) do
			local laneId = spawn.laneId or "North"
			local basePressure = spawn.count

			if string.find(spawn.enemyId, "Boss") or spawn.enemyId == "GateGnawer" or spawn.enemyId == "RotwallTitan" or spawn.enemyId == "WardenOfAsh" then
				basePressure *= 5
			end

			pressureByLane[laneId] += basePressure
		end
	end

	for _, laneId in ipairs(Ids.LaneIds) do
		local laneState = self.state.lanes[laneId]
		local gateDamageFactor = 1 - (laneState.gateHealth / GameConfig.Health.gate)
		local modifierFactor = #self.state.activeModifierIds * 3
		local nextPressure = math.clamp(math.floor(pressureByLane[laneId] / 3 + gateDamageFactor * 20 + modifierFactor), 0, 100)

		if laneState.leakPressure ~= nextPressure then
			laneState.leakPressure = nextPressure
			self:_markDirty()
		end
	end
end

function MatchService:refreshRewardState()
	local pendingReward = self.state.pendingReward

	if self.state.phase ~= "Reward" and self.state.phase ~= "BossReward" then
		return
	end

	if not pendingReward then
		local waveDefinition = self:_getWaveDefinition(self.state.waveIndex)
		self:_beginPrepPhase(self.state.waveIndex + 1, waveDefinition and waveDefinition.prepSeconds or 10)
		return
	end

	if not self:_allRewardSelectionsMade() then
		return
	end

	if pendingReward.modifierId and not arrayContains(self.state.activeModifierIds, pendingReward.modifierId) then
		table.insert(self.state.activeModifierIds, pendingReward.modifierId)
		self:announce("modifier_applied", {
			modifierId = pendingReward.modifierId,
		})
	end

	local completedWave = self:_getWaveDefinition(self.state.waveIndex)

	if completedWave and completedWave.mapEvolutionId then
		self.state.mapEvolutionId = completedWave.mapEvolutionId
		self:announce("map_evolved", {
			mapEvolutionId = completedWave.mapEvolutionId,
		})
	end

	self.state.pendingReward = nil
	self:_markDirty()

	if self.state.waveIndex >= #Waves then
		self:_completeRun(true, "All waves cleared.")
		return
	end

	self:_beginPrepPhase(self.state.waveIndex + 1, completedWave and completedWave.prepSeconds or 10)
end

function MatchService:bindWorld(world, components)
	self.world = world
	self.components = components

	if not world or not components or self.entities.match ~= nil then
		return
	end

	self.entities.match = world:spawn(components.MatchState({
		runId = self.state.runId,
		mapId = self.state.mapId,
		modeId = self.state.modeId,
	}))

	self.entities.lanes = {}

	for _, laneId in ipairs(Ids.LaneIds) do
		self.entities.lanes[laneId] = world:spawn(components.LaneState({
			laneId = laneId,
		}))
	end
end

function MatchService:announce(kind, payload)
	self.remotes[RemoteNames.MatchAnnouncement]:FireAllClients(kind, payload or {})
end

function MatchService:_serializePlacedBuildables()
	local serialized = {}

	for _, laneId in ipairs(Ids.LaneIds) do
		serialized[laneId] = {}

		for index, buildRecord in ipairs(self.placedBuildables[laneId]) do
			serialized[laneId][index] = {
				id = buildRecord.id,
				buildableId = buildRecord.buildableId,
				slotId = buildRecord.slotId,
				ownerUserId = buildRecord.ownerUserId,
			}
		end
	end

	return serialized
end

function MatchService:getPublicSnapshot()
	local playerSnapshots = {}

	for userId, playerState in pairs(self.state.players) do
		table.insert(playerSnapshots, {
			userId = userId,
			name = playerState.name,
			laneId = playerState.laneId,
			scrap = playerState.scrap,
			readyForNextWave = playerState.readyForNextWave,
			selectedRewardCardId = playerState.selectedRewardCardId,
			loadout = {
				classId = playerState.loadout.classId,
				equippedSkillIds = cloneArray(playerState.loadout.equippedSkillIds),
				ultimateId = playerState.loadout.ultimateId,
			},
			rewardCards = cloneArray(playerState.rewardCards),
			contribution = {
				buildablesPlaced = playerState.contribution.buildablesPlaced,
				scrapSpent = playerState.contribution.scrapSpent,
				skillActivations = playerState.contribution.skillActivations,
			},
			masteryRank = self.progressionService:getMasteryRank(userId, playerState.loadout.classId),
			masteryBadges = self.progressionService:getMasteryBadges(userId),
		})
	end

	table.sort(playerSnapshots, function(left, right)
		return left.userId < right.userId
	end)

	local pendingRewardSnapshot = nil

	if self.state.pendingReward then
		pendingRewardSnapshot = {
			waveIndex = self.state.pendingReward.waveIndex,
			bossReward = self.state.pendingReward.bossReward,
			modifierId = self.state.pendingReward.modifierId,
			optionsByUserId = {},
			selectedByUserId = {},
		}

		for userId, options in pairs(self.state.pendingReward.optionsByUserId) do
			pendingRewardSnapshot.optionsByUserId[userId] = cloneArray(options)
		end

		for userId, rewardCardId in pairs(self.state.pendingReward.selectedByUserId) do
			pendingRewardSnapshot.selectedByUserId[userId] = rewardCardId
		end
	end

	local laneSnapshot = {}

	for _, laneId in ipairs(Ids.LaneIds) do
		local laneState = self.state.lanes[laneId]
		laneSnapshot[laneId] = {
			laneId = laneState.laneId,
			displayName = laneState.displayName,
			gateHealth = laneState.gateHealth,
			leakPressure = laneState.leakPressure,
			starterDefenseBuilt = laneState.starterDefenseBuilt,
			starterBuildSlotId = laneState.starterBuildSlotId,
		}
	end

	return {
		runId = self.state.runId,
		modeId = self.state.modeId,
		mapId = self.state.mapId,
		phase = self.state.phase,
		waveIndex = self.state.waveIndex,
		nextWaveIndex = self.state.nextWaveIndex,
		secondsRemaining = self.state.secondsRemaining,
		coreHealth = self.state.coreHealth,
		activeModifierIds = cloneArray(self.state.activeModifierIds),
		mapEvolutionId = self.state.mapEvolutionId,
		lanes = laneSnapshot,
		players = playerSnapshots,
		pendingReward = pendingRewardSnapshot,
		placedBuildables = self:_serializePlacedBuildables(),
		scoreboard = {
			enemiesDefeated = self.state.scoreboard.enemiesDefeated,
			scrapCollected = self.state.scoreboard.scrapCollected,
			buildablesPlaced = self.state.scoreboard.buildablesPlaced,
			skillActivations = self.state.scoreboard.skillActivations,
			revives = self.state.scoreboard.revives,
		},
		revision = self.state.revision,
	}
end

function MatchService:replicate()
	local now = os.clock()
	local revisionChanged = self.state.revision ~= self.lastReplicatedRevision
	local intervalElapsed = now - self.lastReplicatedAt >= REPLICATION_INTERVAL_SECONDS

	if not revisionChanged and not intervalElapsed then
		return
	end

	self.remotes[RemoteNames.MatchSnapshot]:FireAllClients(self:getPublicSnapshot())
	self.lastReplicatedAt = now
	self.lastReplicatedRevision = self.state.revision
end

function MatchService:replicateToPlayer(player)
	self.remotes[RemoteNames.MatchSnapshot]:FireClient(player, self:getPublicSnapshot())
end

return MatchService
