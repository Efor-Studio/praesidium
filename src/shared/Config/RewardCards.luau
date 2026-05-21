local RewardCards = {
	SalvageMagnet = {
		id = "SalvageMagnet",
		name = "Salvage Magnet",
		description = "Increase scrap pickup radius and add a small wave-clear scrap bonus.",
		tags = {
			"economy",
			"general",
		},
	},
	ReinforcedPlates = {
		id = "ReinforcedPlates",
		name = "Reinforced Plates",
		description = "Barricades and gates gain extra durability.",
		tags = {
			"defense",
			"general",
		},
	},
	KillboxTuning = {
		id = "KillboxTuning",
		name = "Killbox Tuning",
		description = "Turrets and traps deal more damage to slowed enemies.",
		tags = {
			"buildable",
			"general",
		},
	},
	LaneMedkits = {
		id = "LaneMedkits",
		name = "Lane Medkits",
		description = "Small heals trigger when players reinforce their own gate lane.",
		tags = {
			"support",
			"general",
		},
	},
	GunnerHotSwap = {
		id = "GunnerHotSwap",
		name = "Hot Swap Feed",
		description = "Gunner active skills refund a portion of turret cooldown windows.",
		classId = "Gunner",
		tags = {
			"class",
			"gunner",
		},
	},
	GunnerTracerGrid = {
		id = "GunnerTracerGrid",
		name = "Tracer Grid",
		description = "Suppression effects increase allied turret accuracy and crit chance.",
		classId = "Gunner",
		tags = {
			"class",
			"gunner",
		},
	},
	MageFlashFreeze = {
		id = "MageFlashFreeze",
		name = "Flash Freeze",
		description = "Mage crowd control lasts longer on enemies near gates.",
		classId = "Mage",
		tags = {
			"class",
			"mage",
		},
	},
	MageArcStorm = {
		id = "MageArcStorm",
		name = "Arc Storm",
		description = "Repeated arc hits build a detonation threshold on trash packs.",
		classId = "Mage",
		tags = {
			"class",
			"mage",
		},
	},
	PriestGraceReserve = {
		id = "PriestGraceReserve",
		name = "Grace Reserve",
		description = "Overhealing converts into a short shield on gates and allies.",
		classId = "Priest",
		tags = {
			"class",
			"priest",
		},
	},
	PriestQuickLift = {
		id = "PriestQuickLift",
		name = "Quick Lift",
		description = "Revive utility activates faster and leaves behind a heal pulse.",
		classId = "Priest",
		tags = {
			"class",
			"priest",
		},
	},
	ThiefDeadfall = {
		id = "ThiefDeadfall",
		name = "Deadfall Loop",
		description = "Trap kills extend snare zones and increase bleed damage.",
		classId = "Thief",
		tags = {
			"class",
			"thief",
		},
	},
	ThiefCleanEscape = {
		id = "ThiefCleanEscape",
		name = "Clean Escape",
		description = "Cross-lane movement leaves a brief haste trail for allies.",
		classId = "Thief",
		tags = {
			"class",
			"thief",
		},
	},
	BossSalvageCache = {
		id = "BossSalvageCache",
		name = "Boss Salvage Cache",
		description = "Boss kills grant a large immediate scrap injection and an extra reroll bank.",
		bossOnly = true,
		tags = {
			"boss",
			"economy",
		},
	},
	BossBulwarkCore = {
		id = "BossBulwarkCore",
		name = "Bulwark Core",
		description = "Restore gate health and reduce leak damage to the core for the next phase.",
		bossOnly = true,
		tags = {
			"boss",
			"defense",
		},
	},
}

return table.freeze(RewardCards)
