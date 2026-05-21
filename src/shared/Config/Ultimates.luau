local Ultimates = {
	LastStandBarrage = {
		id = "LastStandBarrage",
		classId = "Gunner",
		name = "Last Stand Barrage",
		description = "A full-lane barrage that locks a lane down during spike waves or bosses.",
		cooldownSeconds = 70,
		targeting = "Lane",
	},
	CataclysmRing = {
		id = "CataclysmRing",
		classId = "Mage",
		name = "Cataclysm Ring",
		description = "Detonate a huge sigil that erases trash and heavily chunks elites.",
		cooldownSeconds = 75,
		targeting = "GroundTarget",
	},
	GuardianAscension = {
		id = "GuardianAscension",
		classId = "Priest",
		name = "Guardian Ascension",
		description = "Create a sanctuary that heals, shields, and grants revive insurance to nearby allies.",
		cooldownSeconds = 80,
		targeting = "GroundTarget",
	},
	MidnightRaid = {
		id = "MidnightRaid",
		classId = "Thief",
		name = "Midnight Raid",
		description = "Blink through priority targets, collapsing debuffed enemies and resetting trap cooldowns.",
		cooldownSeconds = 72,
		targeting = "MultiTarget",
	},
}

return table.freeze(Ultimates)
