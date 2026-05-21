local WorldShared = {}

function WorldShared.cloneTable(source)
	local copy = {}

	for key, value in pairs(source) do
		copy[key] = value
	end

	return copy
end

function WorldShared.contains(values, expected)
	for _, value in ipairs(values or {}) do
		if value == expected then
			return true
		end
	end

	return false
end

function WorldShared.createLaneEffectState()
	return {
		slowUntil = 0,
		slowMultiplier = 1,
		turretDamageUntil = 0,
		turretDamageMultiplier = 1,
		turretRateUntil = 0,
		turretRateMultiplier = 1,
		dotUntil = 0,
		dotDamagePerSecond = 0,
		gateRegenUntil = 0,
		gateRegenPerSecond = 0,
		scrapUntil = 0,
		scrapBonus = 0,
		shield = 0,
	}
end

function WorldShared.createBonusState()
	return {
		eliteArmorBonus = 0,
		enemyScrapBonus = 0,
		enemyScrapMultiplier = 1,
		enemySpeedMultiplier = 1,
		laneDotBonus = 0,
		laneSlowBonus = 0,
		passiveGateShield = 0,
		prepGateRegen = 0,
		slowedDamageMultiplier = 1,
		summonerBonusSpawns = 0,
		trapDamageMultiplier = 1,
		turretDamageMultiplier = 1,
		turretRateMultiplier = 1,
		volatileGateSplash = 0,
	}
end

function WorldShared.getEnemyThreatWeight(enemyDefinition)
	if WorldShared.contains(enemyDefinition.tags, "boss") then
		return 28
	end

	if WorldShared.contains(enemyDefinition.tags, "elite") then
		return 12
	end

	if WorldShared.contains(enemyDefinition.tags, "support") then
		return 8
	end

	if WorldShared.contains(enemyDefinition.tags, "fast") then
		return 7
	end

	return 5
end

function WorldShared.getBuildSize(buildableId, isStarter)
	if isStarter or buildableId == "Turret" then
		return Vector3.new(8, 10, 8)
	elseif buildableId == "Barricade" then
		return Vector3.new(12, 10, 6)
	end

	return Vector3.new(8, 8, 8)
end

return WorldShared
