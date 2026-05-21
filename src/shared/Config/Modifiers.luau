local Modifiers = {
	FogOfWar = {
		id = "FogOfWar",
		name = "Fog of War",
		description = "Enemy telegraphs shorten and fog pockets obscure late spawns.",
		tags = {
			"pressure",
			"vision",
		},
	},
	ArmoredHorde = {
		id = "ArmoredHorde",
		name = "Armored Horde",
		description = "More Shieldbearers and bonus armor on elite packs.",
		tags = {
			"armor",
			"elite",
		},
	},
	ScrapDrought = {
		id = "ScrapDrought",
		name = "Scrap Drought",
		description = "Base scrap drops are lower, but wave-clear bonuses stay high.",
		tags = {
			"economy",
		},
	},
	VolatileRemains = {
		id = "VolatileRemains",
		name = "Volatile Remains",
		description = "Trash enemies explode on death when killed too close to gates.",
		tags = {
			"positioning",
			"pressure",
		},
	},
	SwiftAssault = {
		id = "SwiftAssault",
		name = "Swift Assault",
		description = "Runner waves arrive faster and leak punishment is harsher.",
		tags = {
			"speed",
			"pressure",
		},
	},
	Gravetide = {
		id = "Gravetide",
		name = "Gravetide",
		description = "Necrocallers appear earlier and reinforce side lanes mid-wave.",
		tags = {
			"summoner",
			"pressure",
		},
	},
}

return table.freeze(Modifiers)
