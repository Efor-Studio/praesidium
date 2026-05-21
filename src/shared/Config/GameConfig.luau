local Ids = require(script.Parent.Parent.Ids)

local GameConfig = {
	GameId = "ZombieSiegePraesidium",
	DefaultMapId = "PraesidiumOutskirts",
	MaxPlayers = 3,
	MaxEquippedSkills = 3,
	FixedUltimateSlots = 1,
	DuplicateClassesAllowed = true,
	AuraStackingRule = "highest_only",
	StandardMode = {
		id = "Standard",
		displayName = "Standard",
		waveCount = 15,
		targetRunMinutes = {
			min = 15,
			max = 18,
		},
		coldOpenSeconds = 5,
		prepWindowSeconds = {
			min = 10,
			max = 15,
		},
		midWaveSeconds = {
			min = 60,
			max = 75,
		},
		lateWaveSeconds = {
			min = 75,
			max = 90,
		},
		bossWaves = {
			5,
			10,
			15,
		},
		mapEvolutionWave = 10,
	},
	Onboarding = {
		objectiveText = "Defend your Gate",
		firstActionTargetSeconds = 5,
		firstRewardTargetSeconds = 45,
		firstBuildPromptTargetSeconds = 60,
		firstRewardCardCount = 2,
		starterDefenseBuildableId = "Turret",
		highlightedBuildSlotId = "North-Intro-01",
	},
	Health = {
		gate = 1500,
		core = 4500,
	},
	Economy = {
		starterScrap = 75,
		firstPickupScrap = 15,
		waveClearScrap = 25,
		bossWaveClearScrap = 60,
	},
	Buildables = {
		menu = Ids.BuildableIds,
		perLaneCaps = {
			Turret = 4,
			Barricade = 6,
			UtilityNode = 4,
		},
	},
	DefaultLoadout = {
		classId = "Gunner",
		equippedSkillIds = {
			"SuppressionBurst",
			"ArmorPiercer",
			"TurretOverclock",
		},
		ultimateId = "LastStandBarrage",
	},
}

return table.freeze(GameConfig)
