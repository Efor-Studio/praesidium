local function lerpVector3(from, to, alpha)
	return from:Lerp(to, alpha)
end

local UP_VECTOR = Vector3.new(0, 1, 0)
local CORE_POSITION = Vector3.new(0, 8, 0)
local CORE_RADIUS = 18

local SLOT_PROFILES = {
	{ suffix = "Intro-01", pathAlpha = 0.76, sideOffset = -18 },
	{ suffix = "Mid-02", pathAlpha = 0.60, sideOffset = 18 },
	{ suffix = "Mid-03", pathAlpha = 0.44, sideOffset = -18 },
	{ suffix = "Outer-04", pathAlpha = 0.28, sideOffset = 18 },
}

local LANE_SEEDS = {
	North = {
		id = "North",
		displayName = "North Gate",
		accent = Color3.fromRGB(92, 182, 255),
		spawn = Vector3.new(0, 6, -232),
		gate = Vector3.new(0, 6, -104),
	},
	East = {
		id = "East",
		displayName = "East Gate",
		accent = Color3.fromRGB(255, 156, 96),
		spawn = Vector3.new(204, 6, 138),
		gate = Vector3.new(96, 6, 70),
	},
	West = {
		id = "West",
		displayName = "West Gate",
		accent = Color3.fromRGB(122, 224, 168),
		spawn = Vector3.new(-204, 6, 138),
		gate = Vector3.new(-96, 6, 70),
	},
}

local function buildLane(seed)
	local outwardDirection = (seed.gate - seed.spawn).Unit
	local rightVector = outwardDirection:Cross(UP_VECTOR)

	if rightVector.Magnitude <= 0.001 then
		rightVector = Vector3.new(1, 0, 0)
	else
		rightVector = rightVector.Unit
	end

	local inwardDirection = (CORE_POSITION - seed.gate).Unit
	local playerStandPosition = seed.gate + inwardDirection * 24 + Vector3.new(0, 4, 0)
	local playerLookTarget = CORE_POSITION + Vector3.new(0, 4, 0)
	local slots = {}

	for index, profile in ipairs(SLOT_PROFILES) do
		local pathPosition = lerpVector3(seed.spawn, seed.gate, profile.pathAlpha)
		local slotPosition = pathPosition + rightVector * profile.sideOffset + Vector3.new(0, 2.5, 0)

		slots[index] = {
			id = string.format("%s-%s", seed.id, profile.suffix),
			pathAlpha = profile.pathAlpha,
			position = slotPosition,
		}
	end

	return {
		id = seed.id,
		displayName = seed.displayName,
		accent = seed.accent,
		spawn = seed.spawn,
		gate = seed.gate,
		core = CORE_POSITION,
		outwardDirection = outwardDirection,
		inwardDirection = inwardDirection,
		rightVector = rightVector,
		spawnToGateLength = (seed.gate - seed.spawn).Magnitude,
		gateToCoreLength = (CORE_POSITION - seed.gate).Magnitude,
		playerStand = CFrame.lookAt(playerStandPosition, playerLookTarget),
		slots = slots,
	}
end

local Layout = {
	core = {
		position = CORE_POSITION,
		radius = CORE_RADIUS,
	},
	laneOrder = {
		"North",
		"East",
		"West",
	},
	lanes = {},
}

for _, laneId in ipairs(Layout.laneOrder) do
	Layout.lanes[laneId] = buildLane(LANE_SEEDS[laneId])
end

return table.freeze(Layout)
