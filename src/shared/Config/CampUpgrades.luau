local CampUpgrades = {
	QuartermasterHooks = {
		id = "QuartermasterHooks",
		name = "Quartermaster Hooks",
		description = "Begin runs with extra scrap for faster first-lane stabilization.",
		category = "economy",
		maxRank = 3,
	},
	ContractDesk = {
		id = "ContractDesk",
		name = "Contract Desk",
		description = "Unlock daily contract slots and post-run bonus objectives.",
		category = "retention",
		maxRank = 2,
	},
	TriageDrills = {
		id = "TriageDrills",
		name = "Triage Drills",
		description = "Gain a limited emergency revive buffer and better first-session forgiveness.",
		category = "utility",
		maxRank = 2,
	},
	AugmentArchive = {
		id = "AugmentArchive",
		name = "Augment Archive",
		description = "Unlock a reroll bank for reward cards instead of raw stat creep.",
		category = "utility",
		maxRank = 3,
	},
	MasteryShowcase = {
		id = "MasteryShowcase",
		name = "Mastery Showcase",
		description = "Display class mastery badges and contribution callouts on the profile banner.",
		category = "social",
		maxRank = 1,
	},
	WeeklyMutatorBoard = {
		id = "WeeklyMutatorBoard",
		name = "Weekly Mutator Board",
		description = "Unlock the weekly mutator scaffold without adding permanent combat power.",
		category = "retention",
		maxRank = 1,
	},
}

return table.freeze(CampUpgrades)
