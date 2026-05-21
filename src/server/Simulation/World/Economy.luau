local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local PrototypeRules = require(script.Parent.Parent.PrototypeRules)

local Economy = {}

function Economy:_getLanePlayers(matchState, laneId)
	local lanePlayers = {}

	for _, playerState in pairs(matchState.players) do
		if playerState.laneId == laneId then
			table.insert(lanePlayers, playerState)
		end
	end

	return lanePlayers
end

function Economy:_awardScrap(matchState, laneId, amount)
	local allPlayers = {}

	for _, playerState in pairs(matchState.players) do
		table.insert(allPlayers, playerState)
	end

	if #allPlayers == 0 or amount <= 0 then
		return
	end

	local recipients = self:_getLanePlayers(matchState, laneId)

	if #recipients == 0 then
		recipients = allPlayers
	end

	local perPlayer = math.max(1, math.floor(amount / #recipients))

	for _, playerState in ipairs(recipients) do
		playerState.scrap += perPlayer
	end

	matchState.scoreboard.scrapCollected += perPlayer * #recipients
end

function Economy:_showModifierPulse(modifierId)
	local profile = PrototypeRules.ModifierProfiles[modifierId]

	if profile then
		self.scene:showCorePulse(string.format("Modifier: %s", profile.displayText), Color3.fromRGB(255, 205, 115))
	end
end

function Economy:applyModifier(modifierId)
	if self.activeModifiers[modifierId] then
		return
	end

	local profile = PrototypeRules.ModifierProfiles[modifierId]

	if not profile then
		return
	end

	self.activeModifiers[modifierId] = true

	if profile.enemySpeedMultiplier then
		self.bonusState.enemySpeedMultiplier *= profile.enemySpeedMultiplier
	end

	if profile.eliteArmorBonus then
		self.bonusState.eliteArmorBonus += profile.eliteArmorBonus
	end

	if profile.enemyScrapMultiplier then
		self.bonusState.enemyScrapMultiplier *= profile.enemyScrapMultiplier
	end

	if profile.volatileGateSplash then
		self.bonusState.volatileGateSplash += profile.volatileGateSplash
	end

	if profile.summonerBonusSpawns then
		self.bonusState.summonerBonusSpawns += profile.summonerBonusSpawns
	end

	self:_showModifierPulse(modifierId)
end

function Economy:applyRewardCard(playerState, rewardCardId, matchState)
	local profile = PrototypeRules.RewardProfiles[rewardCardId]

	if not profile then
		return
	end

	if profile.enemyScrapBonus then
		self.bonusState.enemyScrapBonus += profile.enemyScrapBonus
	end

	if profile.turretDamageMultiplier then
		self.bonusState.turretDamageMultiplier *= profile.turretDamageMultiplier
	end

	if profile.turretRateMultiplier then
		self.bonusState.turretRateMultiplier *= profile.turretRateMultiplier
	end

	if profile.slowedDamageMultiplier then
		self.bonusState.slowedDamageMultiplier *= profile.slowedDamageMultiplier
	end

	if profile.laneSlowBonus then
		self.bonusState.laneSlowBonus += profile.laneSlowBonus
	end

	if profile.laneDotBonus then
		self.bonusState.laneDotBonus += profile.laneDotBonus
	end

	if profile.prepGateRegen then
		self.bonusState.prepGateRegen += profile.prepGateRegen
	end

	if profile.passiveGateShield then
		self.bonusState.passiveGateShield += profile.passiveGateShield
	end

	if profile.trapDamageMultiplier then
		self.bonusState.trapDamageMultiplier *= profile.trapDamageMultiplier
	end

	if profile.immediateScrap then
		self:_awardScrap(matchState, playerState.laneId, profile.immediateScrap)
	end

	if profile.gateHeal then
		for _, laneId in ipairs(self.layout.laneOrder) do
			matchState.lanes[laneId].gateHealth = math.min(GameConfig.Health.gate, matchState.lanes[laneId].gateHealth + profile.gateHeal)
		end
	end

	if profile.coreHeal then
		matchState.coreHealth = math.min(GameConfig.Health.core, matchState.coreHealth + profile.coreHeal)
	end

	if profile.passiveGateShield then
		for _, laneId in ipairs(self.layout.laneOrder) do
			self.laneEffects[laneId].shield += profile.passiveGateShield
		end
	end

	self.scene:showCorePulse(string.format("Reward: %s", profile.displayText), Color3.fromRGB(255, 215, 120))
end

function Economy:setRunResult(victory)
	self.scene:setPhaseText(victory and "Victory" or "Defeat")
end

return Economy
