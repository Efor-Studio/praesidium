local Buildables = {
	Turret = {
		id = "Turret",
		name = "Sentry Turret",
		description = "Reliable lane DPS that scales well with Gunner augments and shared pressure relief.",
		scrapCost = 45,
		buildLimitPerLane = 4,
		placementTags = {
			"Hardpoint",
			"Lane",
		},
		stats = {
			health = 320,
			damage = 18,
			attackRange = 42,
			attacksPerSecond = 1.4,
		},
	},
	Barricade = {
		id = "Barricade",
		name = "Barricade",
		description = "Short-delay blocker that buys time when a lane spikes or a gate is close to folding.",
		scrapCost = 30,
		buildLimitPerLane = 6,
		placementTags = {
			"Lane",
			"Choke",
		},
		stats = {
			health = 700,
			durationSeconds = 40,
		},
	},
	UtilityNode = {
		id = "UtilityNode",
		name = "Trap Node",
		description = "Flexible utility build for slows, shocks, and trap synergies that shine with Thief control.",
		scrapCost = 35,
		buildLimitPerLane = 4,
		placementTags = {
			"Lane",
			"Trap",
		},
		stats = {
			health = 220,
			triggerRadius = 14,
			cooldownSeconds = 5,
		},
	},
}

return table.freeze(Buildables)
