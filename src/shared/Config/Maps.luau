local Maps = {
	PraesidiumOutskirts = {
		id = "PraesidiumOutskirts",
		name = "Praesidium Outskirts",
		description = "A tri-lane defense line wrapped around the Praesidium Core with fast rotations between gates.",
		laneIds = {
			"North",
			"East",
			"West",
		},
		core = {
			displayName = "Praesidium Core",
			maxHealth = 4500,
		},
		lanes = {
			North = {
				id = "North",
				displayName = "North Gate",
				starterBuildSlotId = "North-Intro-01",
				leakRoute = "CenterNorth",
			},
			East = {
				id = "East",
				displayName = "East Gate",
				starterBuildSlotId = "East-Intro-01",
				leakRoute = "CenterEast",
			},
			West = {
				id = "West",
				displayName = "West Gate",
				starterBuildSlotId = "West-Intro-01",
				leakRoute = "CenterWest",
			},
		},
		mapEvolution = {
			id = "RotwallCollapse",
			triggerWave = 10,
			description = "The outer wall collapses and leak paths shorten, forcing faster cross-lane rotations.",
		},
	},
}

return table.freeze(Maps)
