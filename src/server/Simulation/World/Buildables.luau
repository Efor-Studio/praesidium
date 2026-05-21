local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Buildables = require(Shared.Config.Buildables)
local Enemies = require(Shared.Config.Enemies)
local GameConfig = require(Shared.Config.GameConfig)

local PrototypeRules = require(script.Parent.Parent.PrototypeRules)
local WorldShared = require(script.Parent.Shared)

local BuildablesRuntime = {}

function BuildablesRuntime:_stepBuildables(deltaTime, matchState)
	for _, enemyState in pairs(self.activeEnemies) do
		enemyState.touchSlowMultiplier = 1
	end

	for buildId, buildState in pairs(self.activeBuildables) do
		local buildableDefinition = buildState.definition
		local laneEnemies = self:_getLaneEnemies(buildState.laneId)

		if buildState.health <= 0 then
			self:_destroyBuildable(buildId)
			continue
		end

		if buildState.buildableId == "Barricade" then
			for _, enemyState in ipairs(laneEnemies) do
				if math.abs(enemyState.distanceTraveled - buildState.pathDistance) <= 8 then
					enemyState.touchSlowMultiplier = math.min(enemyState.touchSlowMultiplier, 0.42)
					buildState.health -= deltaTime * (Enemies[enemyState.enemyId].speed + 4)
					self:_applyEnemyHit(enemyState, 6 * deltaTime, "trap", matchState)
				end
			end
		else
			buildState.cooldownRemaining = math.max(0, buildState.cooldownRemaining - deltaTime)

			if buildState.cooldownRemaining <= 0 then
				local didFire = false

				for _, enemyState in ipairs(laneEnemies) do
					local distance = (enemyState.position - buildState.position).Magnitude

					if distance <= buildState.range then
						local damage = buildState.damage

						if buildState.buildableId == "UtilityNode" then
							damage *= self.bonusState.trapDamageMultiplier
							enemyState.touchSlowMultiplier = math.min(enemyState.touchSlowMultiplier, 0.7)
							self:_applyEnemyHit(enemyState, damage, "utility", matchState)
						else
							local turretDamageMultiplier = self.bonusState.turretDamageMultiplier
							local laneEffect = self.laneEffects[buildState.laneId]

							if laneEffect.turretDamageUntil > self.clock then
								turretDamageMultiplier *= laneEffect.turretDamageMultiplier
							end

							self:_applyEnemyHit(enemyState, damage * turretDamageMultiplier, "turret", matchState)
						end

						didFire = true
						break
					end
				end

				if didFire then
					local rateMultiplier = 1

					if buildState.buildableId ~= "UtilityNode" then
						rateMultiplier *= self.bonusState.turretRateMultiplier

						local laneEffect = self.laneEffects[buildState.laneId]

						if laneEffect.turretRateUntil > self.clock then
							rateMultiplier *= laneEffect.turretRateMultiplier
						end
					end

					buildState.cooldownRemaining = buildState.baseCooldown / math.max(0.2, rateMultiplier)
				end
			end
		end

		self.scene:updateBuildable(buildState, buildableDefinition, buildState.tint)

		if buildState.health <= 0 then
			self:_destroyBuildable(buildId)
		end
	end
end

function BuildablesRuntime:_createBuildState(buildRecord, buildableId, laneId, slotId, ownerUserId, isStarter)
	local slot = self.slotById[slotId]
	local buildableDefinition = Buildables[buildableId]

	if not slot or not buildableDefinition then
		return nil
	end

	local stats = buildableDefinition.stats
	local buildState = {
		baseCooldown = buildableId == "Turret" and (1 / stats.attacksPerSecond) or (buildableId == "UtilityNode" and stats.cooldownSeconds or 0),
		buildableId = buildableId,
		cooldownRemaining = 0,
		damage = buildableId == "Turret" and stats.damage or (buildableId == "UtilityNode" and 26 or 0),
		definition = buildableDefinition,
		health = stats.health,
		id = buildRecord.id,
		isStarter = isStarter,
		laneId = laneId,
		maxHealth = stats.health,
		ownerUserId = ownerUserId,
		pathDistance = self.layout.lanes[laneId].spawnToGateLength * slot.pathAlpha,
		position = slot.position + Vector3.new(0, 4, 0),
		range = buildableId == "Turret" and stats.attackRange or (buildableId == "UtilityNode" and stats.triggerRadius or 10),
		size = WorldShared.getBuildSize(buildableId, isStarter),
		slotId = slotId,
		tint = PrototypeRules.getBuildableColor(buildableId, isStarter),
	}

	return buildState
end

function BuildablesRuntime:_destroyBuildable(buildId)
	local buildState = self.activeBuildables[buildId]

	if not buildState then
		return
	end

	self.scene:removeBuildable(buildId)

	if buildState.slotId then
		self.slotOccupancy[buildState.slotId] = nil
		self.scene:setSlotOccupied(buildState.slotId, false)
	end

	if buildState.isStarter then
		self.starterBuildIds[buildState.laneId] = nil
	end

	self.activeBuildables[buildId] = nil
end

function BuildablesRuntime:placeBuildable(buildRecord, buildableDefinition)
	local slot = self.slotById[buildRecord.slotId]

	if not slot then
		return false, "That build slot does not exist in the current blockout."
	end

	if self.slotOccupancy[buildRecord.slotId] ~= nil then
		return false, "That build slot is already occupied."
	end

	local buildState = self:_createBuildState(buildRecord, buildRecord.buildableId, buildRecord.laneId, buildRecord.slotId, buildRecord.ownerUserId, false)

	if not buildState then
		return false, "Build state could not be created."
	end

	self.activeBuildables[buildState.id] = buildState
	self.slotOccupancy[buildRecord.slotId] = buildState.id
	self.scene:spawnBuildable(buildState, buildableDefinition, buildState.tint)
	self.scene:setSlotOccupied(buildRecord.slotId, true, buildableDefinition.name)

	return true, "Buildable deployed."
end

function BuildablesRuntime:_ensureStarterBuildables()
	for _, laneId in ipairs(self.layout.laneOrder) do
		if self.starterBuildIds[laneId] == nil or self.activeBuildables[self.starterBuildIds[laneId]] == nil then
			local starterId = string.format("StarterTurret-%s", laneId)
			local slotId = self.layout.lanes[laneId].slots[1].id
			local buildRecord = {
				id = starterId,
				buildableId = GameConfig.Onboarding.starterDefenseBuildableId,
				laneId = laneId,
				slotId = slotId,
				ownerUserId = 0,
			}
			local buildState = self:_createBuildState(buildRecord, buildRecord.buildableId, laneId, slotId, 0, true)

			if buildState then
				buildState.damage = buildState.damage * 0.85
				self.activeBuildables[starterId] = buildState
				self.starterBuildIds[laneId] = starterId
				self.slotOccupancy[slotId] = starterId
				self.scene:spawnBuildable(buildState, Buildables[buildRecord.buildableId], buildState.tint)
				self.scene:setSlotOccupied(slotId, true, "Starter Turret")
			end
		end
	end
end

return BuildablesRuntime
