local function toSet(values)
	local set = {}

	for _, value in ipairs(values) do
		set[value] = true
	end

	return table.freeze(set)
end

local ClassIds = table.freeze({
	"Gunner",
	"Mage",
	"Priest",
	"Thief",
})

local LaneIds = table.freeze({
	"North",
	"East",
	"West",
})

local BuildableIds = table.freeze({
	"Turret",
	"Barricade",
	"UtilityNode",
})

local RunPhases = table.freeze({
	"Lobby",
	"ColdOpen",
	"Combat",
	"Prep",
	"Reward",
	"BossReward",
	"Victory",
	"Defeat",
})

local Ids = {
	ClassIds = ClassIds,
	ClassIdSet = toSet(ClassIds),
	LaneIds = LaneIds,
	LaneIdSet = toSet(LaneIds),
	BuildableIds = BuildableIds,
	BuildableIdSet = toSet(BuildableIds),
	RunPhases = RunPhases,
	RunPhaseSet = toSet(RunPhases),
	MapIds = table.freeze({
		"PraesidiumOutskirts",
	}),
}

return table.freeze(Ids)
