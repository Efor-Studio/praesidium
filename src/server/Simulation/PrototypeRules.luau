local PrototypeRules = {}

PrototypeRules.EnemyColors = {
	boss = Color3.fromRGB(241, 92, 92),
	elite = Color3.fromRGB(244, 179, 77),
	support = Color3.fromRGB(151, 130, 255),
	fast = Color3.fromRGB(112, 225, 170),
	default = Color3.fromRGB(209, 218, 232),
}

PrototypeRules.BuildableColors = {
	Turret = Color3.fromRGB(111, 184, 255),
	Barricade = Color3.fromRGB(255, 171, 96),
	UtilityNode = Color3.fromRGB(136, 229, 181),
	StarterTurret = Color3.fromRGB(183, 216, 255),
}

PrototypeRules.SkillProfiles = {
	SuppressionBurst = {
		displayText = "Suppress",
		pulseColor = Color3.fromRGB(103, 182, 255),
		damage = { mode = "multi", amount = 22, count = 5 },
		laneSlow = { multiplier = 0.58, duration = 4 },
	},
	ArmorPiercer = {
		displayText = "Pierce",
		pulseColor = Color3.fromRGB(255, 177, 112),
		damage = { mode = "front", amount = 120, count = 1 },
		armorShred = { amount = 10, duration = 6 },
	},
	TurretOverclock = {
		displayText = "Overclock",
		pulseColor = Color3.fromRGB(255, 121, 91),
		turretBuff = { damageMultiplier = 1.45, rateMultiplier = 1.7, duration = 6 },
	},
	CoverRelay = {
		displayText = "Relay",
		pulseColor = Color3.fromRGB(255, 209, 96),
		healBuildables = 80,
		gateHeal = 60,
		turretBuff = { damageMultiplier = 1.15, rateMultiplier = 1.15, duration = 8 },
	},
	ArcBurst = {
		displayText = "Arc",
		pulseColor = Color3.fromRGB(112, 206, 255),
		damage = { mode = "multi", amount = 36, count = 4 },
	},
	FrostNova = {
		displayText = "Freeze",
		pulseColor = Color3.fromRGB(154, 229, 255),
		laneSlow = { multiplier = 0.42, duration = 4 },
		damage = { mode = "multi", amount = 18, count = 6 },
	},
	MeteorDrop = {
		displayText = "Meteor",
		pulseColor = Color3.fromRGB(255, 119, 88),
		delayedDamage = { mode = "all", amount = 95, delay = 1.4 },
	},
	StaticWell = {
		displayText = "Well",
		pulseColor = Color3.fromRGB(171, 144, 255),
		laneSlow = { multiplier = 0.5, duration = 6 },
		laneDot = { damagePerSecond = 7, duration = 6 },
	},
	MendPulse = {
		displayText = "Mend",
		pulseColor = Color3.fromRGB(130, 241, 191),
		gateHeal = 135,
		healBuildables = 70,
	},
	SanctifiedShield = {
		displayText = "Shield",
		pulseColor = Color3.fromRGB(242, 224, 118),
		gateShield = 180,
		healBuildables = 40,
	},
	RescueBeacon = {
		displayText = "Beacon",
		pulseColor = Color3.fromRGB(248, 242, 167),
		gateRegen = { amount = 18, duration = 8 },
	},
	SmiteChain = {
		displayText = "Smite",
		pulseColor = Color3.fromRGB(255, 238, 140),
		damage = { mode = "multi", amount = 60, count = 3 },
	},
	Shadowstep = {
		displayText = "Step",
		pulseColor = Color3.fromRGB(116, 243, 198),
		damage = { mode = "front", amount = 54, count = 1 },
		instantScrap = 5,
	},
	RazorWire = {
		displayText = "Wire",
		pulseColor = Color3.fromRGB(255, 114, 160),
		laneSlow = { multiplier = 0.65, duration = 6 },
		laneDot = { damagePerSecond = 10, duration = 6 },
	},
	ExposeWeakness = {
		displayText = "Expose",
		pulseColor = Color3.fromRGB(255, 141, 141),
		damage = { mode = "front", amount = 34, count = 1 },
		damageAmp = { multiplier = 1.35, duration = 6 },
	},
	ScrapSnare = {
		displayText = "Snare",
		pulseColor = Color3.fromRGB(112, 232, 183),
		laneSlow = { multiplier = 0.58, duration = 7 },
		scrapBonus = { amount = 1, duration = 7 },
	},
	LastStandBarrage = {
		displayText = "Barrage",
		pulseColor = Color3.fromRGB(255, 126, 75),
		damage = { mode = "all", amount = 130, count = 99 },
		turretBuff = { damageMultiplier = 1.3, rateMultiplier = 1.6, duration = 8 },
	},
	CataclysmRing = {
		displayText = "Cataclysm",
		pulseColor = Color3.fromRGB(120, 191, 255),
		damage = { mode = "all", amount = 180, count = 99 },
		laneSlow = { multiplier = 0.6, duration = 4 },
	},
	GuardianAscension = {
		displayText = "Ascension",
		pulseColor = Color3.fromRGB(255, 231, 123),
		gateHeal = 260,
		coreHeal = 220,
		gateShield = 240,
		healBuildables = 140,
		gateRegen = { amount = 28, duration = 10 },
	},
	MidnightRaid = {
		displayText = "Raid",
		pulseColor = Color3.fromRGB(115, 238, 194),
		damage = { mode = "multi", amount = 155, count = 4 },
		laneSlow = { multiplier = 0.72, duration = 5 },
	},
}

PrototypeRules.RewardProfiles = {
	SalvageMagnet = {
		displayText = "Scrap +1",
		enemyScrapBonus = 1,
	},
	ReinforcedPlates = {
		displayText = "Gate Repair",
		gateHeal = 180,
	},
	KillboxTuning = {
		displayText = "Turrets Up",
		turretDamageMultiplier = 1.12,
		slowedDamageMultiplier = 1.12,
	},
	LaneMedkits = {
		displayText = "Prep Regen",
		prepGateRegen = 8,
	},
	GunnerHotSwap = {
		displayText = "Turret Haste",
		turretRateMultiplier = 1.12,
	},
	GunnerTracerGrid = {
		displayText = "Tracer Grid",
		slowedDamageMultiplier = 1.15,
	},
	MageFlashFreeze = {
		displayText = "Freeze+",
		laneSlowBonus = 0.08,
	},
	MageArcStorm = {
		displayText = "AoE+",
		laneDotBonus = 4,
	},
	PriestGraceReserve = {
		displayText = "Shielded Gates",
		passiveGateShield = 90,
	},
	PriestQuickLift = {
		displayText = "Regen Up",
		prepGateRegen = 12,
	},
	ThiefDeadfall = {
		displayText = "Trap Damage",
		trapDamageMultiplier = 1.2,
	},
	ThiefCleanEscape = {
		displayText = "Scrap Burst",
		enemyScrapBonus = 1,
	},
	BossSalvageCache = {
		displayText = "Boss Cache",
		immediateScrap = 80,
		enemyScrapBonus = 1,
	},
	BossBulwarkCore = {
		displayText = "Bulwark",
		gateHeal = 260,
		coreHeal = 260,
		passiveGateShield = 120,
	},
}

PrototypeRules.ModifierProfiles = {
	FogOfWar = {
		displayText = "Fog",
		enemyTintBlend = Color3.fromRGB(176, 176, 196),
	},
	ArmoredHorde = {
		displayText = "Armor +8",
		eliteArmorBonus = 8,
	},
	ScrapDrought = {
		displayText = "Scrap x0.8",
		enemyScrapMultiplier = 0.8,
	},
	VolatileRemains = {
		displayText = "Volatile",
		volatileGateSplash = 14,
	},
	SwiftAssault = {
		displayText = "Speed x1.2",
		enemySpeedMultiplier = 1.2,
	},
	Gravetide = {
		displayText = "Extra Adds",
		summonerBonusSpawns = 1,
	},
}

function PrototypeRules.getEnemyColor(enemyDefinition)
	local tags = enemyDefinition.tags or {}

	for _, tag in ipairs(tags) do
		if PrototypeRules.EnemyColors[tag] then
			return PrototypeRules.EnemyColors[tag]
		end
	end

	return PrototypeRules.EnemyColors.default
end

function PrototypeRules.getEnemySize(enemyDefinition)
	local tags = enemyDefinition.tags or {}

	for _, tag in ipairs(tags) do
		if tag == "boss" then
			return Vector3.new(20, 20, 20)
		elseif tag == "elite" then
			return Vector3.new(11, 11, 11)
		end
	end

	if enemyDefinition.speed >= 14 then
		return Vector3.new(7, 7, 7)
	end

	return Vector3.new(8, 8, 8)
end

function PrototypeRules.getBuildableColor(buildableId, isStarter)
	if isStarter then
		return PrototypeRules.BuildableColors.StarterTurret
	end

	return PrototypeRules.BuildableColors[buildableId] or Color3.fromRGB(214, 220, 236)
end

function PrototypeRules.getEnemyLeakDamage(enemyDefinition)
	local tags = enemyDefinition.tags or {}

	for _, tag in ipairs(tags) do
		if tag == "boss" then
			return 180
		elseif tag == "elite" then
			return 54
		end
	end

	if enemyDefinition.speed >= 14 then
		return 28
	end

	return 36
end

function PrototypeRules.resolveDamage(rawDamage, armor, armorShred)
	local effectiveArmor = math.max(0, (armor or 0) - (armorShred or 0))
	return math.max(4, rawDamage - effectiveArmor * 0.65)
end

return table.freeze(PrototypeRules)
