local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local PrototypeRules = require(script.Parent.Parent.PrototypeRules)

local Skills = {}

function Skills:_stepDelayedEffects(matchState)
	for index = #self.delayedEffects, 1, -1 do
		local delayedEffect = self.delayedEffects[index]

		if delayedEffect.triggerAt <= self.clock then
			self:_applyDamageProfile(delayedEffect.laneId, delayedEffect.profile, matchState, delayedEffect.sourceType)
			self.scene:showLanePulse(delayedEffect.laneId, delayedEffect.text, delayedEffect.color)
			table.remove(self.delayedEffects, index)
		end
	end
end

function Skills:_stepLaneEffects(deltaTime, matchState)
	for _, laneId in ipairs(self.layout.laneOrder) do
		local laneEffect = self.laneEffects[laneId]
		local laneState = matchState.lanes[laneId]

		if laneEffect.dotUntil > self.clock then
			local laneEnemies = self:_getLaneEnemies(laneId)

			for _, enemyState in ipairs(laneEnemies) do
				self:_applyEnemyHit(enemyState, laneEffect.dotDamagePerSecond * deltaTime, "trap", matchState)
			end
		end

		if laneEffect.gateRegenUntil > self.clock and laneState.gateHealth > 0 then
			laneState.gateHealth = math.min(GameConfig.Health.gate, laneState.gateHealth + laneEffect.gateRegenPerSecond * deltaTime)
		end
	end
end

function Skills:_applyDamageProfile(laneId, damageProfile, matchState, sourceType)
	if not damageProfile then
		return
	end

	local laneEnemies = self:_getLaneEnemies(laneId)
	local targets = {}

	if damageProfile.mode == "front" then
		if laneEnemies[1] then
			table.insert(targets, laneEnemies[1])
		end
	elseif damageProfile.mode == "multi" then
		for index = 1, math.min(#laneEnemies, damageProfile.count or 1) do
			table.insert(targets, laneEnemies[index])
		end
	else
		for _, enemyState in ipairs(laneEnemies) do
			table.insert(targets, enemyState)
		end
	end

	for _, enemyState in ipairs(targets) do
		self:_applyEnemyHit(enemyState, damageProfile.amount, sourceType or "skill", matchState)
	end
end

function Skills:_healBuildables(laneId, amount)
	for _, buildState in pairs(self.activeBuildables) do
		if buildState.laneId == laneId then
			buildState.health = math.min(buildState.maxHealth, buildState.health + amount)
		end
	end
end

function Skills:applySkill(playerState, skillId, laneId, matchState)
	local profile = PrototypeRules.SkillProfiles[skillId]
	local lane = self.layout.lanes[laneId]

	if not profile or not lane then
		return false
	end

	local laneEffect = self.laneEffects[laneId]
	self.scene:showLanePulse(laneId, profile.displayText, profile.pulseColor)

	if profile.damage then
		self:_applyDamageProfile(laneId, profile.damage, matchState, "skill")
	end

	if profile.delayedDamage then
		table.insert(self.delayedEffects, {
			laneId = laneId,
			triggerAt = self.clock + profile.delayedDamage.delay,
			profile = profile.delayedDamage,
			color = profile.pulseColor,
			sourceType = "skill",
			text = string.format("%s Impact", profile.displayText),
		})
	end

	if profile.laneSlow then
		laneEffect.slowUntil = math.max(laneEffect.slowUntil, self.clock + profile.laneSlow.duration)
		laneEffect.slowMultiplier = math.min(laneEffect.slowMultiplier, profile.laneSlow.multiplier)
	end

	if profile.turretBuff then
		laneEffect.turretDamageUntil = math.max(laneEffect.turretDamageUntil, self.clock + profile.turretBuff.duration)
		laneEffect.turretRateUntil = math.max(laneEffect.turretRateUntil, self.clock + profile.turretBuff.duration)
		laneEffect.turretDamageMultiplier = math.max(laneEffect.turretDamageMultiplier, profile.turretBuff.damageMultiplier)
		laneEffect.turretRateMultiplier = math.max(laneEffect.turretRateMultiplier, profile.turretBuff.rateMultiplier)
	end

	if profile.laneDot then
		laneEffect.dotUntil = math.max(laneEffect.dotUntil, self.clock + profile.laneDot.duration)
		laneEffect.dotDamagePerSecond = math.max(laneEffect.dotDamagePerSecond, profile.laneDot.damagePerSecond + self.bonusState.laneDotBonus)
	end

	if profile.gateRegen then
		laneEffect.gateRegenUntil = math.max(laneEffect.gateRegenUntil, self.clock + profile.gateRegen.duration)
		laneEffect.gateRegenPerSecond = math.max(laneEffect.gateRegenPerSecond, profile.gateRegen.amount)
	end

	if profile.scrapBonus then
		laneEffect.scrapUntil = math.max(laneEffect.scrapUntil, self.clock + profile.scrapBonus.duration)
		laneEffect.scrapBonus = math.max(laneEffect.scrapBonus, profile.scrapBonus.amount)
	end

	if profile.damageAmp then
		local laneEnemies = self:_getLaneEnemies(laneId)
		local target = laneEnemies[1]

		if target then
			target.damageAmpUntil = self.clock + profile.damageAmp.duration
			target.damageAmpMultiplier = profile.damageAmp.multiplier
		end
	end

	if profile.armorShred then
		local laneEnemies = self:_getLaneEnemies(laneId)
		local target = laneEnemies[1]

		if target then
			target.armorShredUntil = self.clock + profile.armorShred.duration
			target.armorShred = math.max(target.armorShred, profile.armorShred.amount)
		end
	end

	if profile.gateHeal then
		matchState.lanes[laneId].gateHealth = math.min(GameConfig.Health.gate, matchState.lanes[laneId].gateHealth + profile.gateHeal)
	end

	if profile.coreHeal then
		matchState.coreHealth = math.min(GameConfig.Health.core, matchState.coreHealth + profile.coreHeal)
	end

	if profile.gateShield then
		laneEffect.shield += profile.gateShield
	end

	if profile.healBuildables then
		self:_healBuildables(laneId, profile.healBuildables)
	end

	if profile.instantScrap then
		playerState.scrap += profile.instantScrap
		matchState.scoreboard.scrapCollected += profile.instantScrap
	end

	return true
end

return Skills
