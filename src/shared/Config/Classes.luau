local Classes = {
	Gunner = {
		id = "Gunner",
		name = "Gunner",
		role = "Sustained ranged DPS with turret synergy.",
		passive = {
			name = "Cover Discipline",
			description = "Your turret-focused buffs are strong, but non-damage aura overlaps only keep the highest value.",
		},
		skillPool = {
			"SuppressionBurst",
			"ArmorPiercer",
			"TurretOverclock",
			"CoverRelay",
		},
		startingSkills = {
			"SuppressionBurst",
			"ArmorPiercer",
			"TurretOverclock",
		},
		ultimateId = "LastStandBarrage",
	},
	Mage = {
		id = "Mage",
		name = "Mage",
		role = "AoE burst and crowd control.",
		passive = {
			name = "Arc Saturation",
			description = "Repeated hits on grouped enemies increase ability splash efficiency.",
		},
		skillPool = {
			"ArcBurst",
			"FrostNova",
			"MeteorDrop",
			"StaticWell",
		},
		startingSkills = {
			"ArcBurst",
			"FrostNova",
			"MeteorDrop",
		},
		ultimateId = "CataclysmRing",
	},
	Priest = {
		id = "Priest",
		name = "Priest",
		role = "Healing, shielding, and revive utility.",
		passive = {
			name = "Last Light",
			description = "Support spikes are strongest on endangered allies and damaged gates.",
		},
		skillPool = {
			"MendPulse",
			"SanctifiedShield",
			"RescueBeacon",
			"SmiteChain",
		},
		startingSkills = {
			"MendPulse",
			"SanctifiedShield",
			"RescueBeacon",
		},
		ultimateId = "GuardianAscension",
	},
	Thief = {
		id = "Thief",
		name = "Thief",
		role = "Mobility, trap synergy, and debuff/finisher utility.",
		passive = {
			name = "Scavenger's Instinct",
			description = "Marked kills and trap takedowns produce extra scrap and better lane tempo.",
		},
		skillPool = {
			"Shadowstep",
			"RazorWire",
			"ExposeWeakness",
			"ScrapSnare",
		},
		startingSkills = {
			"Shadowstep",
			"RazorWire",
			"ExposeWeakness",
		},
		ultimateId = "MidnightRaid",
	},
}

return table.freeze(Classes)
