local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared.Config.Enemies)
local GameConfig = require(Shared.Config.GameConfig)

local PrototypeRules = require(script.Parent.Parent.PrototypeRules)
local WorldShared = require(script.Parent.Shared)

local EnemiesRuntime = {}

function EnemiesRuntime:_getEnemyPosition(enemyState)
	local lane = self.layout.lanes[enemyState.laneId]

	if enemyState.distanceTraveled <= lane.spawnToGateLength then
		local alpha = lane.spawnToGateLength > 0 and enemyState.distanceTraveled / lane.spawnToGateLength or 0
		return lane.spawn:Lerp(lane.gate, alpha) + Vector3.new(0, enemyState.size.Y * 0.5, 0)
	end

	local inwardDistance = enemyState.distanceTraveled - lane.spawnToGateLength
	local alpha = lane.gateToCoreLength > 0 and math.clamp(inwardDistance / lane.gateToCoreLength, 0, 1) or 1
	return lane.gate:Lerp(lane.core, alpha) + Vector3.new(0, enemyState.size.Y * 0.5, 0)
end

function EnemiesRuntime:_spawnEnemy(enemyId, laneId)
	local lane = self.layout.lanes[laneId]
	local enemyDefinition = Enemies[enemyId]

	if not lane or not enemyDefinition then
		return
	end

	self.nextEnemyId += 1

	local size = PrototypeRules.getEnemySize(enemyDefinition)
	local enemyState = {
		id = string.format("Enemy-%d", self.nextEnemyId),
		enemyId = enemyId,
		laneId = laneId,
		health = enemyDefinition.health,
		maxHealth = enemyDefinition.health,
		armor = enemyDefinition.armor + (WorldShared.contains(enemyDefinition.tags, "elite") and self.bonusState.eliteArmorBonus or 0),
		armorShred = 0,
		armorShredUntil = 0,
		damageAmpMultiplier = 1,
		damageAmpUntil = 0,
		distanceTraveled = 0,
		dotDamagePerSecond = 0,
		dotUntil = 0,
		healthTint = PrototypeRules.getEnemyColor(enemyDefinition),
		position = lane.spawn + Vector3.new(0, size.Y * 0.5, 0),
		size = size,
		slowMultiplier = 1,
		slowUntil = 0,
		speed = enemyDefinition.speed,
		touchSlowMultiplier = 1,
	}

	enemyState.position = self:_getEnemyPosition(enemyState)
	self.activeEnemies[enemyState.id] = enemyState
	self.scene:spawnEnemy(enemyState, enemyDefinition, enemyState.healthTint)
end

function EnemiesRuntime:_getLaneEnemies(laneId)
	local laneEnemies = {}

	for _, enemyState in pairs(self.activeEnemies) do
		if enemyState.laneId == laneId then
			table.insert(laneEnemies, enemyState)
		end
	end

	table.sort(laneEnemies, function(left, right)
		return left.distanceTraveled > right.distanceTraveled
	end)

	return laneEnemies
end

function EnemiesRuntime:_getActiveArmorShred(enemyState)
	if enemyState.armorShredUntil > self.clock then
		return enemyState.armorShred
	end

	return 0
end

function EnemiesRuntime:_isLaneSlowed(laneId)
	local laneEffect = self.laneEffects[laneId]
	return laneEffect and laneEffect.slowUntil > self.clock
end

function EnemiesRuntime:_getLaneSlowMultiplier(laneId)
	local laneEffect = self.laneEffects[laneId]

	if laneEffect and laneEffect.slowUntil > self.clock then
		return math.max(0.2, laneEffect.slowMultiplier - self.bonusState.laneSlowBonus)
	end

	return 1
end

function EnemiesRuntime:_applyEnemyHit(enemyState, rawDamage, sourceType, matchState)
	local enemyDefinition = Enemies[enemyState.enemyId]

	if not enemyDefinition then
		return false
	end

	local damageMultiplier = 1

	if enemyState.damageAmpUntil > self.clock then
		damageMultiplier *= enemyState.damageAmpMultiplier
	end

	if sourceType ~= "utility" and sourceType ~= "trap" and self:_isLaneSlowed(enemyState.laneId) then
		damageMultiplier *= self.bonusState.slowedDamageMultiplier
	end

	if sourceType == "trap" or sourceType == "utility" then
		damageMultiplier *= self.bonusState.trapDamageMultiplier
	end

	local resolvedDamage = PrototypeRules.resolveDamage(
		rawDamage * damageMultiplier,
		enemyState.armor,
		self:_getActiveArmorShred(enemyState)
	)

	enemyState.health -= resolvedDamage

	if enemyState.health > 0 then
		return false
	end

	self:_handleEnemyDefeat(enemyState, matchState)
	return true
end

function EnemiesRuntime:_handleEnemyDefeat(enemyState, matchState)
	local enemyDefinition = Enemies[enemyState.enemyId]
	local laneEffect = self.laneEffects[enemyState.laneId]

	if not enemyDefinition then
		return
	end

	self.scene:removeEnemy(enemyState.id)
	self.activeEnemies[enemyState.id] = nil

	local bonusScrap = self.bonusState.enemyScrapBonus

	if laneEffect.scrapUntil > self.clock then
		bonusScrap += laneEffect.scrapBonus
	end

	local reward = math.max(1, math.floor(enemyDefinition.scrapReward * self.bonusState.enemyScrapMultiplier + bonusScrap))
	self:_awardScrap(matchState, enemyState.laneId, reward)
	matchState.scoreboard.enemiesDefeated += 1

	if self.bonusState.volatileGateSplash > 0 then
		local lane = self.layout.lanes[enemyState.laneId]
		local nearGateThreshold = lane.spawnToGateLength * 0.82

		if enemyState.distanceTraveled >= nearGateThreshold and not WorldShared.contains(enemyDefinition.tags, "boss") then
			self:_applyGateDamage(enemyState.laneId, self.bonusState.volatileGateSplash, matchState)
		end
	end

	if self.bonusState.summonerBonusSpawns > 0 and WorldShared.contains(enemyDefinition.tags, "summoner") then
		for _ = 1, self.bonusState.summonerBonusSpawns do
			self:_spawnEnemy("Shambler", enemyState.laneId)
		end
	end
end

function EnemiesRuntime:_applyGateDamage(laneId, amount, matchState)
	local laneState = matchState.lanes[laneId]
	local laneEffect = self.laneEffects[laneId]
	local remainingDamage = amount

	if laneEffect.shield > 0 then
		local absorbed = math.min(laneEffect.shield, remainingDamage)
		laneEffect.shield -= absorbed
		remainingDamage -= absorbed
	end

	if remainingDamage <= 0 then
		self.scene:showLanePulse(laneId, "Gate Shield", Color3.fromRGB(242, 220, 114))
		return
	end

	laneState.gateHealth = math.max(0, laneState.gateHealth - remainingDamage)
	self.scene:showLanePulse(laneId, string.format("Gate -%d", math.floor(remainingDamage + 0.5)), Color3.fromRGB(241, 97, 97))
end

function EnemiesRuntime:_applyCoreDamage(amount, matchState)
	matchState.coreHealth = math.max(0, matchState.coreHealth - amount)
	self.scene:showCorePulse(string.format("Core -%d", math.floor(amount + 0.5)), Color3.fromRGB(241, 97, 97))
end

function EnemiesRuntime:_updateLaneTelemetry(matchState)
	for _, laneId in ipairs(self.layout.laneOrder) do
		local threat = 0
		local gateState = matchState.lanes[laneId]

		for _, enemyState in pairs(self.activeEnemies) do
			if enemyState.laneId == laneId then
				threat += WorldShared.getEnemyThreatWeight(Enemies[enemyState.enemyId])
			end
		end

		local gateDamageFactor = 1 - (gateState.gateHealth / GameConfig.Health.gate)
		local pressure = math.clamp(math.floor(threat * 1.75 + gateDamageFactor * 42), 0, 100)

		gateState.leakPressure = pressure
		self.scene:setLaneThreat(laneId, pressure)
	end
end

function EnemiesRuntime:_stepWaveSpawner(deltaTime)
	if not self.activeWave then
		return
	end

	for _, spawnTrack in ipairs(self.activeWave.spawnTracks) do
		if spawnTrack.remaining <= 0 then
			continue
		end

		if spawnTrack.intervalSeconds <= 0 then
			for _ = 1, spawnTrack.remaining do
				self:_spawnEnemy(spawnTrack.enemyId, spawnTrack.laneId)
			end

			spawnTrack.remaining = 0
			continue
		end

		spawnTrack.timer -= deltaTime

		while spawnTrack.remaining > 0 and spawnTrack.timer <= 0 do
			local batchCount = math.min(spawnTrack.burstSize, spawnTrack.remaining)

			for _ = 1, batchCount do
				self:_spawnEnemy(spawnTrack.enemyId, spawnTrack.laneId)
			end

			spawnTrack.remaining -= batchCount
			spawnTrack.timer += spawnTrack.intervalSeconds
		end
	end
end

function EnemiesRuntime:_captureStateSignature(matchState)
	local signature = {
		tostring(math.floor(matchState.coreHealth / 5 + 0.5)),
		tostring(matchState.scoreboard.enemiesDefeated),
		tostring(matchState.scoreboard.scrapCollected),
		tostring(matchState.scoreboard.buildablesPlaced),
		tostring(matchState.scoreboard.skillActivations),
	}

	for _, laneId in ipairs(self.layout.laneOrder) do
		local laneState = matchState.lanes[laneId]
		table.insert(signature, tostring(math.floor(laneState.gateHealth / 5 + 0.5)))
		table.insert(signature, tostring(laneState.leakPressure))
	end

	local userIds = {}

	for userId in pairs(matchState.players) do
		table.insert(userIds, userId)
	end

	table.sort(userIds)

	for _, userId in ipairs(userIds) do
		local playerState = matchState.players[userId]
		table.insert(signature, tostring(userId))
		table.insert(signature, tostring(math.floor(playerState.scrap + 0.5)))
	end

	return table.concat(signature, ":")
end

function EnemiesRuntime:_stepEnemies(deltaTime, matchState)
	for enemyId, enemyState in pairs(self.activeEnemies) do
		if enemyState.dotUntil > self.clock then
			self:_applyEnemyHit(enemyState, enemyState.dotDamagePerSecond * deltaTime, "trap", matchState)
		end

		if self.activeEnemies[enemyId] == nil then
			continue
		end

		local lane = self.layout.lanes[enemyState.laneId]
		local laneState = matchState.lanes[enemyState.laneId]
		local laneSlow = self:_getLaneSlowMultiplier(enemyState.laneId)
		local enemySlow = enemyState.slowUntil > self.clock and enemyState.slowMultiplier or 1
		local speed = enemyState.speed * self.bonusState.enemySpeedMultiplier * laneSlow * enemySlow * enemyState.touchSlowMultiplier

		enemyState.distanceTraveled += speed * deltaTime
		enemyState.position = self:_getEnemyPosition(enemyState)
		self.scene:updateEnemy(enemyState, Enemies[enemyState.enemyId], enemyState.healthTint)

		if laneState.gateHealth > 0 and enemyState.distanceTraveled >= lane.spawnToGateLength then
			local leakDamage = PrototypeRules.getEnemyLeakDamage(Enemies[enemyState.enemyId])
			self:_applyGateDamage(enemyState.laneId, leakDamage, matchState)
			self.scene:removeEnemy(enemyId)
			self.activeEnemies[enemyId] = nil
		elseif laneState.gateHealth <= 0 and enemyState.distanceTraveled >= lane.spawnToGateLength + lane.gateToCoreLength then
			local leakDamage = math.ceil(PrototypeRules.getEnemyLeakDamage(Enemies[enemyState.enemyId]) * 0.8)
			self:_applyCoreDamage(leakDamage, matchState)
			self.scene:removeEnemy(enemyId)
			self.activeEnemies[enemyId] = nil
		end
	end
end

function EnemiesRuntime:isWaveResolved()
	if not self.activeWave then
		return false
	end

	for _, spawnTrack in ipairs(self.activeWave.spawnTracks) do
		if spawnTrack.remaining > 0 then
			return false
		end
	end

	return next(self.activeEnemies) == nil
end

return EnemiesRuntime
