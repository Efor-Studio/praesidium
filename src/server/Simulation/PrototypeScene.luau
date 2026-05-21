local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local POSITIVE_COLOR = Color3.fromRGB(97, 220, 155)
local WARNING_COLOR = Color3.fromRGB(248, 195, 84)
local DANGER_COLOR = Color3.fromRGB(236, 91, 91)
local CORE_COLOR = Color3.fromRGB(133, 184, 255)
local PANEL_COLOR = Color3.fromRGB(15, 19, 31)

local function create(className, properties)
	local instance = Instance.new(className)

	for key, value in pairs(properties or {}) do
		instance[key] = value
	end

	return instance
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function attachBillboard(part, size, studsOffset, textSize)
	local billboard = create("BillboardGui", {
		Parent = part,
		AlwaysOnTop = true,
		ExtentsOffsetWorldSpace = studsOffset or Vector3.new(0, 4, 0),
		Size = size or UDim2.fromOffset(180, 68),
		StudsOffsetWorldSpace = studsOffset or Vector3.new(0, 4, 0),
	})

	local label = create("TextLabel", {
		Parent = billboard,
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextColor3 = Color3.fromRGB(244, 247, 252),
		TextScaled = false,
		TextSize = textSize or 14,
		TextStrokeTransparency = 0.85,
		TextWrapped = true,
	})
	createCorner(label, 10)

	return label
end

local function setPartLabel(label, text, textColor)
	label.Text = text
	label.TextColor3 = textColor
end

local function createStrip(parent, name, from, to, color, width, thickness, transparency)
	local length = (to - from).Magnitude
	local midpoint = from:Lerp(to, 0.5)

	return create("Part", {
		Name = name,
		Parent = parent,
		Anchored = true,
		CanCollide = false,
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = transparency or 0.3,
		Size = Vector3.new(width or 18, thickness or 1.2, length),
		CFrame = CFrame.lookAt(midpoint, to),
	})
end

local function createBlock(parent, name, size, cframe, color, material, transparency)
	return create("Part", {
		Name = name,
		Parent = parent,
		Anchored = true,
		CanCollide = true,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Transparency = transparency or 0,
		Size = size,
		CFrame = cframe,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	})
end

local function blendColor(from, to, alpha)
	return from:Lerp(to, math.clamp(alpha, 0, 1))
end

local function healthTint(alpha, accentColor)
	if alpha >= 0.6 then
		return blendColor(WARNING_COLOR, accentColor, (alpha - 0.6) / 0.4)
	end

	if alpha >= 0.3 then
		return blendColor(DANGER_COLOR, WARNING_COLOR, (alpha - 0.3) / 0.3)
	end

	return DANGER_COLOR
end

local PrototypeScene = {}
PrototypeScene.__index = PrototypeScene

function PrototypeScene.new(layout)
	local self = setmetatable({}, PrototypeScene)

	self.layout = layout
	self.root = nil
	self.dynamicFolder = nil
	self.phaseLabel = nil
	self.core = nil
	self.gates = {}
	self.laneStrips = {}
	self.buildSlots = {}
	self.enemyVisuals = {}
	self.buildableVisuals = {}
	self.playerConnections = {}

	return self
end

function PrototypeScene:ensureBuilt()
	local existingRoot = Workspace:FindFirstChild("PraesidiumBlockout")

	if existingRoot then
		existingRoot:Destroy()
	end

	self.root = create("Folder", {
		Name = "PraesidiumBlockout",
		Parent = Workspace,
	})

	local staticFolder = create("Folder", {
		Name = "Static",
		Parent = self.root,
	})

	self.dynamicFolder = create("Folder", {
		Name = "Dynamic",
		Parent = self.root,
	})

	local coreFolder = create("Folder", {
		Name = "Core",
		Parent = staticFolder,
	})

	local coreBase = createBlock(
		coreFolder,
		"CoreBase",
		Vector3.new(44, 6, 44),
		CFrame.new(self.layout.core.position - Vector3.new(0, 3, 0)),
		Color3.fromRGB(42, 52, 74),
		Enum.Material.Basalt
	)

	local coreCrystal = createBlock(
		coreFolder,
		"CoreCrystal",
		Vector3.new(20, 24, 20),
		CFrame.new(self.layout.core.position + Vector3.new(0, 12, 0)),
		CORE_COLOR,
		Enum.Material.Neon
	)

	self.phaseLabel = attachBillboard(coreCrystal, UDim2.fromOffset(220, 74), Vector3.new(0, 18, 0), 18)
	self.core = {
		base = coreBase,
		crystal = coreCrystal,
		label = attachBillboard(coreCrystal, UDim2.fromOffset(220, 84), Vector3.new(0, 10, 0), 16),
	}

	for _, laneId in ipairs(self.layout.laneOrder) do
		self:_buildLane(staticFolder, self.layout.lanes[laneId])
	end

	self:setPhaseText("Lobby")
	self:updateCore(0, 1)
end

function PrototypeScene:_buildLane(parent, lane)
	local laneFolder = create("Folder", {
		Name = lane.id,
		Parent = parent,
	})

	local outwardStrip = createStrip(laneFolder, "OuterStrip", lane.spawn, lane.gate, lane.accent, 18, 1.2, 0.45)
	local inwardStrip = createStrip(laneFolder, "InnerStrip", lane.gate, lane.core, lane.accent, 16, 1.2, 0.62)

	local gatePart = createBlock(
		laneFolder,
		"Gate",
		Vector3.new(28, 18, 8),
		CFrame.lookAt(lane.gate, lane.core) + Vector3.new(0, 9, 0),
		lane.accent,
		Enum.Material.ForceField,
		0.15
	)

	local spawnMarker = createBlock(
		laneFolder,
		"SpawnMarker",
		Vector3.new(20, 2, 20),
		CFrame.new(lane.spawn - Vector3.new(0, 1, 0)),
		lane.accent,
		Enum.Material.Neon,
		0.35
	)

	local playerPad = createBlock(
		laneFolder,
		"PlayerPad",
		Vector3.new(14, 1, 14),
		lane.playerStand - Vector3.new(0, 4.5, 0),
		blendColor(lane.accent, Color3.fromRGB(255, 255, 255), 0.35),
		Enum.Material.Neon,
		0.15
	)

	local gateLabel = attachBillboard(gatePart, UDim2.fromOffset(196, 72), Vector3.new(0, 12, 0), 16)
	setPartLabel(gateLabel, string.format("%s\nGate 0 / 0", lane.displayName), Color3.fromRGB(247, 250, 255))

	self.gates[lane.id] = {
		part = gatePart,
		label = gateLabel,
		accent = lane.accent,
	}

	self.laneStrips[lane.id] = {
		outward = outwardStrip,
		inward = inwardStrip,
		accent = lane.accent,
	}

	for _, slot in ipairs(lane.slots) do
		local slotPart = createBlock(
			laneFolder,
			slot.id,
			Vector3.new(10, 3, 10),
			CFrame.new(slot.position),
			blendColor(lane.accent, Color3.fromRGB(255, 255, 255), 0.3),
			Enum.Material.Metal,
			0.18
		)

		local slotLabel = attachBillboard(slotPart, UDim2.fromOffset(158, 58), Vector3.new(0, 5, 0), 13)
		setPartLabel(slotLabel, string.format("%s\nOpen", slot.id), Color3.fromRGB(244, 247, 252))

		self.buildSlots[slot.id] = {
			part = slotPart,
			label = slotLabel,
			laneId = lane.id,
			accent = lane.accent,
		}
	end

	local laneBillboard = attachBillboard(spawnMarker, UDim2.fromOffset(170, 52), Vector3.new(0, 5, 0), 14)
	setPartLabel(laneBillboard, string.format("%s\nSpawn Route", lane.displayName), Color3.fromRGB(244, 247, 252))

	playerPad:SetAttribute("LaneId", lane.id)
end

function PrototypeScene:setPhaseText(text)
	if self.phaseLabel then
		setPartLabel(self.phaseLabel, string.format("Praesidium\n%s", text), Color3.fromRGB(244, 247, 252))
	end
end

function PrototypeScene:updateCore(currentHealth, maxHealth)
	if not self.core then
		return
	end

	local alpha = maxHealth > 0 and currentHealth / maxHealth or 0
	local tint = healthTint(alpha, CORE_COLOR)

	self.core.crystal.Color = tint
	setPartLabel(
		self.core.label,
		string.format("Praesidium Core\n%d / %d", math.floor(currentHealth + 0.5), maxHealth),
		Color3.fromRGB(244, 247, 252)
	)
end

function PrototypeScene:updateGate(laneId, currentHealth, maxHealth)
	local gateVisual = self.gates[laneId]
	local lane = self.layout.lanes[laneId]

	if not gateVisual or not lane then
		return
	end

	local alpha = maxHealth > 0 and currentHealth / maxHealth or 0
	gateVisual.part.Color = healthTint(alpha, gateVisual.accent)
	setPartLabel(
		gateVisual.label,
		string.format("%s\nGate %d / %d", lane.displayName, math.floor(currentHealth + 0.5), maxHealth),
		Color3.fromRGB(244, 247, 252)
	)
end

function PrototypeScene:setLaneThreat(laneId, pressure)
	local strips = self.laneStrips[laneId]

	if not strips then
		return
	end

	local alpha = math.clamp((pressure or 0) / 100, 0, 1)
	local threatColor = blendColor(strips.accent, DANGER_COLOR, alpha)
	strips.outward.Color = threatColor
	strips.inward.Color = blendColor(threatColor, Color3.fromRGB(255, 255, 255), 0.15)
	strips.outward.Transparency = 0.52 - alpha * 0.18
	strips.inward.Transparency = 0.7 - alpha * 0.18
end

function PrototypeScene:setSlotOccupied(slotId, isOccupied, occupantName)
	local slotVisual = self.buildSlots[slotId]

	if not slotVisual then
		return
	end

	slotVisual.part.Color = isOccupied and blendColor(slotVisual.accent, WARNING_COLOR, 0.45) or blendColor(slotVisual.accent, Color3.fromRGB(255, 255, 255), 0.3)
	slotVisual.part.Transparency = isOccupied and 0.04 or 0.18
	setPartLabel(
		slotVisual.label,
		string.format("%s\n%s", slotId, isOccupied and (occupantName or "Occupied") or "Open"),
		Color3.fromRGB(244, 247, 252)
	)
end

function PrototypeScene:bindPlayer(player, laneId)
	local lane = self.layout.lanes[laneId]

	if not lane then
		return
	end

	self:removePlayer(player)

	local function teleportCharacter(character)
		task.spawn(function()
			local rootPart = character:WaitForChild("HumanoidRootPart", 5)

			if rootPart then
				rootPart.CFrame = lane.playerStand
			end
		end)
	end

	self.playerConnections[player] = player.CharacterAdded:Connect(teleportCharacter)

	if player.Character then
		teleportCharacter(player.Character)
	end
end

function PrototypeScene:removePlayer(player)
	local connection = self.playerConnections[player]

	if connection then
		connection:Disconnect()
		self.playerConnections[player] = nil
	end
end

function PrototypeScene:spawnEnemy(enemyState, enemyDefinition, tint)
	local size = enemyState.size
	local part = createBlock(
		self.dynamicFolder,
		enemyState.id,
		size,
		CFrame.new(enemyState.position),
		tint,
		Enum.Material.Neon
	)

	local label = attachBillboard(part, UDim2.fromOffset(172, 62), Vector3.new(0, size.Y * 0.65, 0), 13)
	self.enemyVisuals[enemyState.id] = {
		part = part,
		label = label,
	}

	self:updateEnemy(enemyState, enemyDefinition, tint)
end

function PrototypeScene:updateEnemy(enemyState, enemyDefinition, tint)
	local visual = self.enemyVisuals[enemyState.id]

	if not visual then
		return
	end

	visual.part.CFrame = CFrame.new(enemyState.position)
	visual.part.Color = tint
	setPartLabel(
		visual.label,
		string.format("%s\n%d / %d", enemyDefinition.name, math.max(0, math.floor(enemyState.health + 0.5)), math.floor(enemyState.maxHealth + 0.5)),
		Color3.fromRGB(244, 247, 252)
	)
end

function PrototypeScene:removeEnemy(enemyId)
	local visual = self.enemyVisuals[enemyId]

	if visual then
		visual.part:Destroy()
		self.enemyVisuals[enemyId] = nil
	end
end

function PrototypeScene:spawnBuildable(buildState, buildableDefinition, tint)
	local part = createBlock(
		self.dynamicFolder,
		buildState.id,
		buildState.size,
		CFrame.new(buildState.position),
		tint,
		Enum.Material.Metal
	)
	local label = attachBillboard(part, UDim2.fromOffset(170, 62), Vector3.new(0, buildState.size.Y * 0.75, 0), 13)

	self.buildableVisuals[buildState.id] = {
		part = part,
		label = label,
	}

	self:updateBuildable(buildState, buildableDefinition, tint)
end

function PrototypeScene:updateBuildable(buildState, buildableDefinition, tint)
	local visual = self.buildableVisuals[buildState.id]

	if not visual then
		return
	end

	visual.part.CFrame = CFrame.new(buildState.position)
	visual.part.Color = tint
	setPartLabel(
		visual.label,
		string.format("%s\n%d / %d", buildableDefinition.name, math.max(0, math.floor(buildState.health + 0.5)), math.floor(buildState.maxHealth + 0.5)),
		Color3.fromRGB(244, 247, 252)
	)
end

function PrototypeScene:removeBuildable(buildId)
	local visual = self.buildableVisuals[buildId]

	if visual then
		visual.part:Destroy()
		self.buildableVisuals[buildId] = nil
	end
end

function PrototypeScene:showLanePulse(laneId, text, color)
	local lane = self.layout.lanes[laneId]

	if not lane then
		return
	end

	local pulsePart = createBlock(
		self.dynamicFolder,
		string.format("%sPulse", laneId),
		Vector3.new(1, 1, 1),
		CFrame.new(lane.gate + Vector3.new(0, 18, 0)),
		color,
		Enum.Material.Neon,
		1
	)

	local label = attachBillboard(pulsePart, UDim2.fromOffset(168, 50), Vector3.new(0, 0, 0), 15)
	setPartLabel(label, text, color)
	Debris:AddItem(pulsePart, 1.2)
end

function PrototypeScene:showCorePulse(text, color)
	local pulsePart = createBlock(
		self.dynamicFolder,
		"CorePulse",
		Vector3.new(1, 1, 1),
		CFrame.new(self.layout.core.position + Vector3.new(0, 28, 0)),
		color,
		Enum.Material.Neon,
		1
	)

	local label = attachBillboard(pulsePart, UDim2.fromOffset(196, 54), Vector3.new(0, 0, 0), 16)
	setPartLabel(label, text, color)
	Debris:AddItem(pulsePart, 1.2)
end

return PrototypeScene
