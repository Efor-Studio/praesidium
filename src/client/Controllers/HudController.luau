local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Buildables = require(Shared.Config.Buildables)
local Classes = require(Shared.Config.Classes)
local Enemies = require(Shared.Config.Enemies)
local GameConfig = require(Shared.Config.GameConfig)
local Ids = require(Shared.Ids)
local Maps = require(Shared.Config.Maps)
local RewardCards = require(Shared.Config.RewardCards)
local Skills = require(Shared.Config.Skills)
local Ultimates = require(Shared.Config.Ultimates)
local Waves = require(Shared.Config.Waves)

local Theme = {
	Background = Color3.fromRGB(12, 16, 24),
	Panel = Color3.fromRGB(22, 28, 42),
	PanelAlt = Color3.fromRGB(30, 38, 57),
	PanelStrong = Color3.fromRGB(17, 23, 35),
	Outline = Color3.fromRGB(90, 104, 130),
	Text = Color3.fromRGB(241, 244, 250),
	Muted = Color3.fromRGB(154, 167, 194),
	Accent = Color3.fromRGB(104, 182, 255),
	Warm = Color3.fromRGB(247, 147, 59),
	Positive = Color3.fromRGB(97, 220, 155),
	Danger = Color3.fromRGB(237, 91, 91),
	Shadow = Color3.fromRGB(6, 9, 14),
	HeaderFont = Enum.Font.FredokaOne,
	BodyFont = Enum.Font.GothamMedium,
	BoldFont = Enum.Font.GothamBold,
}

local ClassColors = {
	Gunner = Color3.fromRGB(248, 134, 69),
	Mage = Color3.fromRGB(101, 190, 255),
	Priest = Color3.fromRGB(244, 214, 121),
	Thief = Color3.fromRGB(98, 217, 170),
}

local LaneColors = {
	North = Color3.fromRGB(107, 191, 255),
	East = Color3.fromRGB(255, 159, 104),
	West = Color3.fromRGB(127, 223, 171),
}

local HudController = {}
HudController.__index = HudController

local function create(className, properties)
	local instance = Instance.new(className)

	for key, value in pairs(properties or {}) do
		instance[key] = value
	end

	return instance
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent, top, right, bottom, left)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingRight = UDim.new(0, right or top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or top or 0)
	padding.PaddingLeft = UDim.new(0, left or right or top or 0)
	padding.Parent = parent
	return padding
end

local function addListLayout(parent, fillDirection, padding, horizontalAlignment, verticalAlignment)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = fillDirection or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, padding or 0)
	layout.HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = verticalAlignment or Enum.VerticalAlignment.Top
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

local function addGradient(parent, colorA, colorB, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colorA, colorB)
	gradient.Rotation = rotation or 0
	gradient.Parent = parent
	return gradient
end

local function clearGeneratedChildren(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function contains(values, expected)
	for _, value in ipairs(values or {}) do
		if value == expected then
			return true
		end
	end

	return false
end

local function formatSeconds(seconds)
	local rounded = math.max(0, math.ceil(seconds or 0))
	local minutes = math.floor(rounded / 60)
	local remainder = rounded % 60

	return string.format("%d:%02d", minutes, remainder)
end

local function formatTags(tags)
	if not tags or #tags == 0 then
		return "No tags"
	end

	return table.concat(tags, " • ")
end

local function getEnemyAccent(enemyDefinition)
	if contains(enemyDefinition.tags, "boss") then
		return Theme.Danger
	end

	if contains(enemyDefinition.tags, "elite") then
		return Theme.Warm
	end

	return Theme.Accent
end

local function getClassAccent(classId)
	return ClassColors[classId] or Theme.Accent
end

local function getLaneAccent(laneId)
	return LaneColors[laneId] or Theme.Accent
end

local function stylePanel(frame, accentColor, transparency)
	frame.BackgroundColor3 = Theme.Panel
	frame.BackgroundTransparency = transparency or 0.08
	frame.BorderSizePixel = 0
	addCorner(frame, 20)
	addStroke(frame, accentColor or Theme.Outline, 1, 0.45)
	addGradient(frame, Theme.PanelAlt, Theme.PanelStrong, 90)

	local shadow = create("Frame", {
		Name = "Shadow",
		Parent = frame,
		BackgroundColor3 = Theme.Shadow,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 6),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = frame.ZIndex - 1,
	})
	addCorner(shadow, 20)
end

local function createHeaderLabel(parent, text, size)
	return create("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = size or UDim2.new(1, 0, 0, 24),
		Font = Theme.HeaderFont,
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
end

local function createBodyLabel(parent, text, size, textColor, textSize)
	return create("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = size or UDim2.new(1, 0, 0, 20),
		Font = Theme.BodyFont,
		Text = text,
		TextColor3 = textColor or Theme.Muted,
		TextSize = textSize or 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
end

local function createTokenBadge(parent, text, accentColor)
	local badge = create("TextLabel", {
		Parent = parent,
		BackgroundColor3 = accentColor,
		BackgroundTransparency = 0.24,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 88, 0, 24),
		Font = Theme.BoldFont,
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 12,
	})
	addCorner(badge, 12)
	addStroke(badge, accentColor, 1, 0.15)
	return badge
end

local function createActionButton(parent, title, subtitle, accentColor, width)
	local button = create("TextButton", {
		Parent = parent,
		AutoButtonColor = false,
		BackgroundColor3 = accentColor,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		Size = UDim2.new(0, width or 176, 1, 0),
		Text = "",
	})
	addCorner(button, 16)
	addStroke(button, accentColor, 1, 0.08)
	addGradient(button, accentColor, Theme.PanelStrong, 45)
	addPadding(button, 10, 12, 10, 12)

	createHeaderLabel(button, title, UDim2.new(1, 0, 0, 20)).TextSize = 16
	createBodyLabel(button, subtitle, UDim2.new(1, 0, 1, -24), Theme.Text, 12).Position = UDim2.new(0, 0, 0, 24)

	return button
end

local function createCompactButton(parent, text, accentColor, width, height)
	local button = create("TextButton", {
		Parent = parent,
		AutoButtonColor = false,
		BackgroundColor3 = accentColor,
		BackgroundTransparency = 0.64,
		BorderSizePixel = 0,
		Font = Theme.BoldFont,
		Size = UDim2.new(0, width or 112, 0, height or 30),
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 13,
	})
	addCorner(button, 14)
	addStroke(button, accentColor, 1, 0.1)
	addGradient(button, accentColor, Theme.PanelStrong, 45)
	return button
end

function HudController.new(matchController)
	local self = setmetatable({}, HudController)

	self.matchController = matchController
	self.localPlayer = Players.LocalPlayer
	self.playerGui = self.localPlayer:WaitForChild("PlayerGui")
	self.selectedLaneId = nil
	self.selectedConceptTab = "Operators"
	self.statusTitle = "Visual Prototype Live"
	self.statusBody = "Waiting for the first match snapshot."
	self.statusColor = Theme.Accent
	self.latestSnapshot = nil

	self:_build()

	self.snapshotDisconnect = self.matchController:onSnapshot(function(snapshot)
		self.latestSnapshot = snapshot
		self:render(snapshot)
	end)

	self.announcementDisconnect = self.matchController:onAnnouncement(function(kind, payload)
		self:_applyAnnouncement(kind, payload)
	end)

	local latestSnapshot = self.matchController:getLatestSnapshot()

	if latestSnapshot then
		self.latestSnapshot = latestSnapshot
		self:render(latestSnapshot)
	end

	return self
end

function HudController:_build()
	local existingGui = self.playerGui:FindFirstChild("PraesidiumHud")

	if existingGui then
		existingGui:Destroy()
	end

	local screenGui = create("ScreenGui", {
		Name = "PraesidiumHud",
		Parent = self.playerGui,
		DisplayOrder = 10,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
	})

	local root = create("Frame", {
		Name = "Root",
		Parent = screenGui,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	})
	addGradient(root, Color3.fromRGB(11, 16, 26), Color3.fromRGB(20, 24, 38), 90)

	local glowA = create("Frame", {
		Name = "GlowA",
		Parent = root,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.15, 0.12),
		Size = UDim2.fromOffset(320, 320),
	})
	addCorner(glowA, 160)

	local glowB = create("Frame", {
		Name = "GlowB",
		Parent = root,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Warm,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.88, 0.78),
		Size = UDim2.fromOffset(360, 360),
	})
	addCorner(glowB, 180)

	local content = create("Frame", {
		Name = "Content",
		Parent = root,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})
	addPadding(content, 20, 20, 20, 20)
	addListLayout(content, Enum.FillDirection.Vertical, 16)

	self.topBar = create("Frame", {
		Name = "TopBar",
		Parent = content,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 96),
	})
	stylePanel(self.topBar, Theme.Accent)
	addPadding(self.topBar, 16, 18, 16, 18)

	local topLayoutHost = create("Frame", {
		Name = "TopLayoutHost",
		Parent = self.topBar,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})
	addListLayout(topLayoutHost, Enum.FillDirection.Horizontal, 16, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

	local brandBlock = create("Frame", {
		Name = "BrandBlock",
		Parent = topLayoutHost,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.28, 0, 1, 0),
	})
	self.titleLabel = createHeaderLabel(brandBlock, "PRAESIDIUM", UDim2.new(1, 0, 0, 32))
	self.titleLabel.TextSize = 28
	self.titleLabel.TextColor3 = Theme.Text
	self.subtitleLabel = createBodyLabel(
		brandBlock,
		"Three lanes, one core, placeholder art with live gameplay data.",
		UDim2.new(1, 0, 0, 42),
		Theme.Muted,
		14
	)
	self.subtitleLabel.Position = UDim2.new(0, 0, 0, 34)

	local statusBlock = create("Frame", {
		Name = "StatusBlock",
		Parent = topLayoutHost,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.4, 0, 1, 0),
	})
	self.statusAccent = create("Frame", {
		Name = "StatusAccent",
		Parent = statusBlock,
		BackgroundColor3 = self.statusColor,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(0, 6, 1, -16),
	})
	addCorner(self.statusAccent, 3)
	self.statusTitleLabel = createHeaderLabel(statusBlock, self.statusTitle, UDim2.new(1, -18, 0, 22))
	self.statusTitleLabel.Position = UDim2.new(0, 18, 0, 8)
	self.statusTitleLabel.TextSize = 18
	self.statusBodyLabel = createBodyLabel(statusBlock, self.statusBody, UDim2.new(1, -18, 0, 50), Theme.Text, 13)
	self.statusBodyLabel.Position = UDim2.new(0, 18, 0, 34)

	local metricsBlock = create("Frame", {
		Name = "MetricsBlock",
		Parent = topLayoutHost,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.32, 0, 1, 0),
	})
	local metricsLayout = addListLayout(metricsBlock, Enum.FillDirection.Vertical, 4)
	metricsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

	self.phaseLabel = createHeaderLabel(metricsBlock, "LOBBY", UDim2.new(1, 0, 0, 22))
	self.phaseLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.phaseLabel.TextSize = 18
	self.waveLabel = createBodyLabel(metricsBlock, "Wave 0 / 15", UDim2.new(1, 0, 0, 18), Theme.Text, 14)
	self.waveLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.timerLabel = createBodyLabel(metricsBlock, "00:00", UDim2.new(1, 0, 0, 18), Theme.Muted, 14)
	self.timerLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.metaLabel = createBodyLabel(metricsBlock, "Praesidium Outskirts • Standard", UDim2.new(1, 0, 0, 18), Theme.Muted, 13)
	self.metaLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.coreHealthLabel = createBodyLabel(metricsBlock, "Core 4500", UDim2.new(1, 0, 0, 18), Theme.Positive, 13)
	self.coreHealthLabel.TextXAlignment = Enum.TextXAlignment.Right

	self.middleRow = create("Frame", {
		Name = "MiddleRow",
		Parent = content,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 1, -356),
	})
	addListLayout(self.middleRow, Enum.FillDirection.Horizontal, 16)

	self.mainColumn = create("Frame", {
		Name = "MainColumn",
		Parent = self.middleRow,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.64, 0, 1, 0),
	})
	addListLayout(self.mainColumn, Enum.FillDirection.Vertical, 16)

	self.lanePanel = create("Frame", {
		Name = "LanePanel",
		Parent = self.mainColumn,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 190),
	})
	stylePanel(self.lanePanel, Theme.Accent)
	addPadding(self.lanePanel, 14, 14, 14, 14)
	createHeaderLabel(self.lanePanel, "Lane Pressure", UDim2.new(1, 0, 0, 22))
	self.laneSubLabel = createBodyLabel(
		self.lanePanel,
		"Read the match state here before we have proper world-space combat visuals.",
		UDim2.new(1, 0, 0, 18),
		Theme.Muted,
		13
	)
	self.laneSubLabel.Position = UDim2.new(0, 0, 0, 24)
	self.laneCardRow = create("Frame", {
		Name = "LaneCardRow",
		Parent = self.lanePanel,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 60),
		Size = UDim2.new(1, 0, 1, -60),
	})
	addListLayout(self.laneCardRow, Enum.FillDirection.Horizontal, 12)

	self.squadPanel = create("Frame", {
		Name = "SquadPanel",
		Parent = self.mainColumn,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -206),
	})
	stylePanel(self.squadPanel, Theme.Positive)
	addPadding(self.squadPanel, 14, 14, 14, 14)
	createHeaderLabel(self.squadPanel, "Squad Feed", UDim2.new(1, 0, 0, 22))
	self.squadSubLabel = createBodyLabel(
		self.squadPanel,
		"Player state, scrap flow, reward count, and lane assignments.",
		UDim2.new(1, 0, 0, 18),
		Theme.Muted,
		13
	)
	self.squadSubLabel.Position = UDim2.new(0, 0, 0, 24)
	self.squadList = create("ScrollingFrame", {
		Name = "SquadList",
		Parent = self.squadPanel,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 58),
		ScrollBarImageColor3 = Theme.Outline,
		ScrollBarThickness = 6,
		Size = UDim2.new(1, 0, 1, -58),
	})
	addListLayout(self.squadList, Enum.FillDirection.Vertical, 10)
	addPadding(self.squadList, 0, 4, 8, 0)

	self.sideColumn = create("Frame", {
		Name = "SideColumn",
		Parent = self.middleRow,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.36, 0, 1, 0),
	})
	self.conceptPanel = create("Frame", {
		Name = "ConceptPanel",
		Parent = self.sideColumn,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})
	stylePanel(self.conceptPanel, Theme.Warm)
	addPadding(self.conceptPanel, 14, 14, 14, 14)
	createHeaderLabel(self.conceptPanel, "Concept Board", UDim2.new(1, 0, 0, 22))
	self.conceptSubLabel = createBodyLabel(
		self.conceptPanel,
		"Template cards to guide UI art direction before final operators and monsters exist.",
		UDim2.new(1, 0, 0, 34),
		Theme.Muted,
		13
	)
	self.conceptSubLabel.Position = UDim2.new(0, 0, 0, 24)
	self.tabRow = create("Frame", {
		Name = "TabRow",
		Parent = self.conceptPanel,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 66),
		Size = UDim2.new(1, 0, 0, 36),
	})
	addListLayout(self.tabRow, Enum.FillDirection.Horizontal, 10)
	self.conceptTabButtons = {}

	local operatorTab = createCompactButton(self.tabRow, "OPERATORS", Theme.Accent, 120, 32)
	operatorTab.MouseButton1Click:Connect(function()
		self:setConceptTab("Operators")
	end)
	self.conceptTabButtons.Operators = operatorTab

	local threatTab = createCompactButton(self.tabRow, "THREATS", Theme.Danger, 120, 32)
	threatTab.MouseButton1Click:Connect(function()
		self:setConceptTab("Threats")
	end)
	self.conceptTabButtons.Threats = threatTab

	self.conceptList = create("ScrollingFrame", {
		Name = "ConceptList",
		Parent = self.conceptPanel,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 112),
		ScrollBarImageColor3 = Theme.Outline,
		ScrollBarThickness = 6,
		Size = UDim2.new(1, 0, 1, -112),
	})
	addListLayout(self.conceptList, Enum.FillDirection.Vertical, 10)
	addPadding(self.conceptList, 0, 4, 8, 0)

	self.actionPanel = create("Frame", {
		Name = "ActionPanel",
		Parent = content,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 228),
	})
	stylePanel(self.actionPanel, Theme.Positive)
	addPadding(self.actionPanel, 14, 14, 14, 14)
	createHeaderLabel(self.actionPanel, "Command Rail", UDim2.new(1, 0, 0, 22))
	self.actionHintLabel = createBodyLabel(
		self.actionPanel,
		"Choose a lane, trigger placeholder skills, and test starter build placements.",
		UDim2.new(1, -148, 0, 32),
		Theme.Muted,
		13
	)
	self.actionHintLabel.Position = UDim2.new(0, 0, 0, 24)

	self.readyButton = createActionButton(self.actionPanel, "Ready", "Start next wave", Theme.Positive, 128)
	self.readyButton.AnchorPoint = Vector2.new(1, 0)
	self.readyButton.Position = UDim2.new(1, 0, 0, 0)
	self.readyButton.Size = UDim2.new(0, 128, 0, 52)
	self.readyButton.MouseButton1Click:Connect(function()
		self.matchController:readyForNextWave()
		self:setStatus("Prep Confirmed", "You marked yourself ready for the next wave.", Theme.Positive)
	end)

	self.laneSelectorRow = create("ScrollingFrame", {
		Name = "LaneSelectorRow",
		Parent = self.actionPanel,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 68),
		ScrollBarThickness = 0,
		Size = UDim2.new(1, 0, 0, 28),
	})
	addListLayout(self.laneSelectorRow, Enum.FillDirection.Horizontal, 8)

	self.skillRow = create("ScrollingFrame", {
		Name = "SkillRow",
		Parent = self.actionPanel,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 106),
		ScrollBarImageColor3 = Theme.Outline,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, 0, 0, 54),
	})
	addListLayout(self.skillRow, Enum.FillDirection.Horizontal, 10)

	self.buildRow = create("ScrollingFrame", {
		Name = "BuildRow",
		Parent = self.actionPanel,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 164),
		ScrollBarImageColor3 = Theme.Outline,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, 0, 0, 54),
	})
	addListLayout(self.buildRow, Enum.FillDirection.Horizontal, 10)

	self.rewardOverlay = create("Frame", {
		Name = "RewardOverlay",
		Parent = screenGui,
		BackgroundColor3 = Theme.Shadow,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 20,
	})

	local rewardPanel = create("Frame", {
		Name = "RewardPanel",
		Parent = self.rewardOverlay,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.48, 0, 0.58, 0),
		ZIndex = 21,
	})
	stylePanel(rewardPanel, Theme.Warm, 0.02)
	addPadding(rewardPanel, 18, 18, 18, 18)
	self.rewardTitleLabel = createHeaderLabel(rewardPanel, "Reward Draft", UDim2.new(1, 0, 0, 24))
	self.rewardTitleLabel.ZIndex = 22
	self.rewardTitleLabel.TextSize = 22
	self.rewardSubtitleLabel = createBodyLabel(
		rewardPanel,
		"Choose one placeholder reward to keep the prototype flow moving.",
		UDim2.new(1, 0, 0, 32),
		Theme.Text,
		14
	)
	self.rewardSubtitleLabel.Position = UDim2.new(0, 0, 0, 28)
	self.rewardSubtitleLabel.ZIndex = 22
	self.rewardChoiceList = create("ScrollingFrame", {
		Name = "RewardChoiceList",
		Parent = rewardPanel,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 76),
		ScrollBarImageColor3 = Theme.Outline,
		ScrollBarThickness = 6,
		Size = UDim2.new(1, 0, 1, -76),
		ZIndex = 22,
	})
	addListLayout(self.rewardChoiceList, Enum.FillDirection.Vertical, 10)
	addPadding(self.rewardChoiceList, 0, 4, 8, 0)

	self:setConceptTab("Operators")
	self:_refreshStatusLabels()
end

function HudController:_refreshStatusLabels()
	self.statusAccent.BackgroundColor3 = self.statusColor
	self.statusTitleLabel.Text = self.statusTitle
	self.statusBodyLabel.Text = self.statusBody
end

function HudController:setStatus(title, body, color)
	self.statusTitle = title
	self.statusBody = body
	self.statusColor = color or Theme.Accent
	self:_refreshStatusLabels()
end

function HudController:setConceptTab(tabName)
	self.selectedConceptTab = tabName

	for currentTabName, button in pairs(self.conceptTabButtons) do
		local isSelected = currentTabName == tabName
		button.BackgroundTransparency = isSelected and 0.2 or 0.72
	end

	self:renderConceptCards()
end

function HudController:_applyAnnouncement(kind, payload)
	if kind == "objective" then
		self:setStatus("Mission Brief", tostring(payload.text), Theme.Accent)
	elseif kind == "wave_started" then
		self:setStatus(
			"Wave Started",
			string.format("Wave %d is live: %s", payload.waveIndex or 0, tostring(payload.stage or "Unknown stage")),
			Theme.Danger
		)
	elseif kind == "prep_started" then
		self:setStatus(
			"Prep Window",
			string.format("Use the command rail now. Wave %d starts in %ss.", payload.nextWaveIndex or 0, math.ceil(payload.secondsRemaining or 0)),
			Theme.Positive
		)
	elseif kind == "reward_available" then
		self:setStatus("Reward Draft", "Choose one of the available reward cards to continue.", Theme.Warm)
	elseif kind == "modifier_applied" then
		self:setStatus("Mutator Online", string.format("Modifier applied: %s", tostring(payload.modifierId)), Theme.Warm)
	elseif kind == "map_evolved" then
		self:setStatus("Map Shift", string.format("Evolution triggered: %s", tostring(payload.mapEvolutionId)), Theme.Danger)
	elseif kind == "run_ended" then
		self:setStatus("Run Ended", string.format("%s: %s", tostring(payload.result), tostring(payload.reason)), Theme.Danger)
	elseif kind == "system_notice" then
		self:setStatus("Fallback Runtime", tostring(payload.message), Theme.Warm)
	end
end

function HudController:_getStarterSlotId(snapshot, laneId)
	local laneSnapshot = snapshot and snapshot.lanes and snapshot.lanes[laneId]

	if laneSnapshot and laneSnapshot.starterBuildSlotId then
		return laneSnapshot.starterBuildSlotId
	end

	local mapDefinition = Maps[GameConfig.DefaultMapId]
	return mapDefinition.lanes[laneId].starterBuildSlotId
end

function HudController:render(snapshot)
	local localPlayerSnapshot = self.matchController:getLocalPlayerSnapshot(snapshot)

	if localPlayerSnapshot and (self.selectedLaneId == nil or snapshot.lanes[self.selectedLaneId] == nil) then
		self.selectedLaneId = localPlayerSnapshot.laneId
	end

	self:renderTopBar(snapshot)
	self:renderLaneCards(snapshot)
	self:renderSquad(snapshot)
	self:renderActions(snapshot)
	self:renderRewardOverlay(snapshot)
end

function HudController:renderTopBar(snapshot)
	local mapDefinition = Maps[snapshot.mapId] or Maps[GameConfig.DefaultMapId]
	self.phaseLabel.Text = string.upper(snapshot.phase)
	self.waveLabel.Text = string.format("Wave %d / %d", snapshot.waveIndex, #Waves)
	self.timerLabel.Text = string.format("Clock %s", formatSeconds(snapshot.secondsRemaining))
	self.metaLabel.Text = string.format("%s • %s", mapDefinition.name, snapshot.modeId)
	self.coreHealthLabel.Text = string.format("Core %d • Modifiers %d", snapshot.coreHealth, #snapshot.activeModifierIds)
end

function HudController:renderLaneCards(snapshot)
	clearGeneratedChildren(self.laneCardRow)

	for _, laneId in ipairs(Ids.LaneIds) do
		local laneState = snapshot.lanes[laneId]
		local accentColor = getLaneAccent(laneId)
		local isSelected = self.selectedLaneId == laneId
		local laneCard = create("Frame", {
			Name = string.format("%sLaneCard", laneId),
			Parent = self.laneCardRow,
			BackgroundTransparency = 1,
			Size = UDim2.new(1 / #Ids.LaneIds, -8, 1, 0),
		})
		stylePanel(laneCard, accentColor, isSelected and 0.02 or 0.12)
		addPadding(laneCard, 12, 12, 12, 12)

		createHeaderLabel(laneCard, laneState.displayName, UDim2.new(1, 0, 0, 20)).TextSize = 17
		createBodyLabel(
			laneCard,
			string.format("Gate %d • Pressure %d%%", laneState.gateHealth, laneState.leakPressure),
			UDim2.new(1, 0, 0, 18),
			Theme.Text,
			13
		).Position = UDim2.new(0, 0, 0, 26)

		local buildCount = #(snapshot.placedBuildables[laneId] or {})
		createBodyLabel(
			laneCard,
			string.format("Starter Slot %s • Builds %d", laneState.starterBuildSlotId, buildCount),
			UDim2.new(1, 0, 0, 18),
			Theme.Muted,
			12
		).Position = UDim2.new(0, 0, 0, 48)

		local pressureTrack = create("Frame", {
			Name = "PressureTrack",
			Parent = laneCard,
			BackgroundColor3 = Theme.PanelStrong,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 78),
			Size = UDim2.new(1, 0, 0, 10),
		})
		addCorner(pressureTrack, 5)

		local pressureFill = create("Frame", {
			Name = "PressureFill",
			Parent = pressureTrack,
			BackgroundColor3 = accentColor,
			BorderSizePixel = 0,
			Size = UDim2.new(math.clamp(laneState.leakPressure / 100, 0, 1), 0, 1, 0),
		})
		addCorner(pressureFill, 5)

		local selectorButton = createActionButton(
			laneCard,
			isSelected and "Selected Lane" or "Focus Lane",
			string.format("Route actions to %s", laneId),
			accentColor,
			160
		)
		selectorButton.Position = UDim2.new(0, 0, 1, -54)
		selectorButton.Size = UDim2.new(1, 0, 0, 54)
		selectorButton.MouseButton1Click:Connect(function()
			self.selectedLaneId = laneId
			self:setStatus("Lane Focus Updated", string.format("Actions now route through %s.", laneState.displayName), accentColor)
			if self.latestSnapshot then
				self:render(self.latestSnapshot)
			end
		end)
	end
end

function HudController:renderSquad(snapshot)
	clearGeneratedChildren(self.squadList)

	for _, playerSnapshot in ipairs(snapshot.players) do
		local accentColor = getClassAccent(playerSnapshot.loadout.classId)
		local playerCard = create("Frame", {
			Name = string.format("PlayerCard%d", playerSnapshot.userId),
			Parent = self.squadList,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 108),
		})
		stylePanel(playerCard, accentColor, 0.08)
		addPadding(playerCard, 12, 12, 12, 12)

		createHeaderLabel(
			playerCard,
			string.format("%s • %s", playerSnapshot.name, playerSnapshot.loadout.classId),
			UDim2.new(1, 0, 0, 20)
		).TextSize = 17

		createBodyLabel(
			playerCard,
			string.format("Lane %s • Scrap %d • Reward Cards %d", playerSnapshot.laneId, playerSnapshot.scrap, #playerSnapshot.rewardCards),
			UDim2.new(1, 0, 0, 18),
			Theme.Text,
			13
		).Position = UDim2.new(0, 0, 0, 26)

		createBodyLabel(
			playerCard,
			string.format(
				"Builds %d • Spent %d • Skills %d • Mastery %d",
				playerSnapshot.contribution.buildablesPlaced,
				playerSnapshot.contribution.scrapSpent,
				playerSnapshot.contribution.skillActivations,
				playerSnapshot.masteryRank
			),
			UDim2.new(1, 0, 0, 18),
			Theme.Muted,
			12
		).Position = UDim2.new(0, 0, 0, 48)

		local readyText = playerSnapshot.readyForNextWave and "Ready for next wave" or "Waiting in current phase"
		createBodyLabel(playerCard, readyText, UDim2.new(1, 0, 0, 18), accentColor, 12).Position = UDim2.new(0, 0, 0, 68)

		if #playerSnapshot.masteryBadges > 0 then
			createTokenBadge(playerCard, playerSnapshot.masteryBadges[1], accentColor).Position = UDim2.new(0, 0, 1, -24)
		end
	end
end

function HudController:renderActions(snapshot)
	local localPlayerSnapshot = self.matchController:getLocalPlayerSnapshot(snapshot)

	if localPlayerSnapshot and self.selectedLaneId == nil then
		self.selectedLaneId = localPlayerSnapshot.laneId
	end

	if localPlayerSnapshot and self.selectedLaneId ~= localPlayerSnapshot.laneId and not snapshot.lanes[self.selectedLaneId] then
		self.selectedLaneId = localPlayerSnapshot.laneId
	end

	clearGeneratedChildren(self.laneSelectorRow)
	clearGeneratedChildren(self.skillRow)
	clearGeneratedChildren(self.buildRow)

	for _, laneId in ipairs(Ids.LaneIds) do
		local accentColor = getLaneAccent(laneId)
		local button = createCompactButton(
			self.laneSelectorRow,
			self.selectedLaneId == laneId and string.format("%s • ACTIVE", string.upper(laneId)) or string.upper(laneId),
			accentColor,
			118
		)
		button.Size = UDim2.new(0, 118, 1, 0)
		button.BackgroundTransparency = self.selectedLaneId == laneId and 0.18 or 0.72
		button.MouseButton1Click:Connect(function()
			self.selectedLaneId = laneId
			self:setStatus("Lane Routing", string.format("Action focus moved to %s.", laneId), accentColor)
			if self.latestSnapshot then
				self:render(self.latestSnapshot)
			end
		end)
	end

	if not localPlayerSnapshot then
		self.actionHintLabel.Text = "Waiting for the local player to be registered by the server."
		self.readyButton.Visible = false
		return
	end

	self.selectedLaneId = self.selectedLaneId or localPlayerSnapshot.laneId

	local classDefinition = Classes[localPlayerSnapshot.loadout.classId]
	local starterSlotId = self:_getStarterSlotId(snapshot, self.selectedLaneId)
	self.actionHintLabel.Text = string.format(
		"%s template active. Route actions through %s and place builds on starter slot %s.",
		classDefinition.name,
		self.selectedLaneId,
		starterSlotId
	)

	for _, skillId in ipairs(localPlayerSnapshot.loadout.equippedSkillIds) do
		local skillDefinition = Skills[skillId]
		local button = createActionButton(
			self.skillRow,
			skillDefinition.name,
			string.format("%ss • %s", skillDefinition.cooldownSeconds, skillDefinition.targeting),
			getClassAccent(localPlayerSnapshot.loadout.classId),
			186
		)
		button.MouseButton1Click:Connect(function()
			self.matchController:activateSkill(skillId, self.selectedLaneId)
			self:setStatus(
				"Skill Triggered",
				string.format("%s routed through %s.", skillDefinition.name, self.selectedLaneId),
				getClassAccent(localPlayerSnapshot.loadout.classId)
			)
		end)
	end

	local ultimateDefinition = Ultimates[localPlayerSnapshot.loadout.ultimateId]
	local ultimateButton = createActionButton(
		self.skillRow,
		ultimateDefinition.name,
		string.format("Ultimate • %ss", ultimateDefinition.cooldownSeconds),
		Theme.Warm,
		210
	)
	ultimateButton.MouseButton1Click:Connect(function()
		self.matchController:activateSkill(ultimateDefinition.id, self.selectedLaneId)
		self:setStatus("Ultimate Triggered", string.format("%s aimed at %s.", ultimateDefinition.name, self.selectedLaneId), Theme.Warm)
	end)

	for _, buildableId in ipairs(Ids.BuildableIds) do
		local buildableDefinition = Buildables[buildableId]
		local laneBuilds = snapshot.placedBuildables[self.selectedLaneId] or {}
		local placedCount = 0

		for _, buildRecord in ipairs(laneBuilds) do
			if buildRecord.buildableId == buildableId then
				placedCount += 1
			end
		end

		local button = createActionButton(
			self.buildRow,
			buildableDefinition.name,
			string.format("%d scrap • %d in lane", buildableDefinition.scrapCost, placedCount),
			Theme.Positive,
			190
		)
		button.MouseButton1Click:Connect(function()
			task.spawn(function()
				local ok, message = self.matchController:placeBuildable({
					buildableId = buildableId,
					laneId = self.selectedLaneId,
					slotId = starterSlotId,
					rotationY = 0,
				})

				if ok then
					self:setStatus(
						"Build Placed",
						string.format("%s committed to %s.", buildableDefinition.name, self.selectedLaneId),
						Theme.Positive
					)
				else
					self:setStatus("Build Rejected", tostring(message), Theme.Danger)
				end
			end)
		end)
	end

	self.readyButton.Visible = snapshot.phase == "Prep" and not localPlayerSnapshot.readyForNextWave
end

function HudController:renderRewardOverlay(snapshot)
	local pendingReward = snapshot.pendingReward
	local userOptions = pendingReward and pendingReward.optionsByUserId[tostring(self.localPlayer.UserId)] or nil
	local visible = (snapshot.phase == "Reward" or snapshot.phase == "BossReward") and pendingReward ~= nil and userOptions ~= nil

	self.rewardOverlay.Visible = visible

	if not visible then
		return
	end

	self.rewardTitleLabel.Text = pendingReward.bossReward and "Boss Reward Draft" or "Reward Draft"
	self.rewardSubtitleLabel.Text = string.format(
		"Wave %d rewards • Modifier candidate: %s",
		pendingReward.waveIndex,
		tostring(pendingReward.modifierId or "None")
	)

	clearGeneratedChildren(self.rewardChoiceList)

	for _, rewardCardId in ipairs(userOptions) do
		local rewardDefinition = RewardCards[rewardCardId]
		local accentColor = rewardDefinition.bossOnly and Theme.Danger or (rewardDefinition.classId and getClassAccent(rewardDefinition.classId) or Theme.Warm)
		local choiceButton = create("TextButton", {
			Name = rewardCardId,
			Parent = self.rewardChoiceList,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 0, 112),
			Text = "",
			ZIndex = 22,
		})
		stylePanel(choiceButton, accentColor, 0.04)
		addPadding(choiceButton, 12, 12, 12, 12)

		local titleLabel = createHeaderLabel(choiceButton, rewardDefinition.name, UDim2.new(1, -96, 0, 20))
		titleLabel.ZIndex = 23
		titleLabel.TextSize = 17

		local classLabel = createTokenBadge(choiceButton, rewardDefinition.classId or (rewardDefinition.bossOnly and "Boss" or "General"), accentColor)
		classLabel.Position = UDim2.new(1, -92, 0, 0)
		classLabel.ZIndex = 23

		local descriptionLabel = createBodyLabel(choiceButton, rewardDefinition.description, UDim2.new(1, 0, 0, 44), Theme.Text, 13)
		descriptionLabel.Position = UDim2.new(0, 0, 0, 28)
		descriptionLabel.ZIndex = 23

		local tagLabel = createBodyLabel(
			choiceButton,
			formatTags(rewardDefinition.tags),
			UDim2.new(1, 0, 0, 16),
			Theme.Muted,
			12
		)
		tagLabel.Position = UDim2.new(0, 0, 1, -18)
		tagLabel.ZIndex = 23

		choiceButton.MouseButton1Click:Connect(function()
			task.spawn(function()
				local ok, message = self.matchController:chooseRewardCard(rewardCardId)

				if ok then
					self:setStatus("Reward Locked", string.format("%s added to your run.", rewardDefinition.name), accentColor)
				else
					self:setStatus("Reward Failed", tostring(message), Theme.Danger)
				end
			end)
		end)
	end
end

function HudController:renderConceptCards()
	clearGeneratedChildren(self.conceptList)

	if self.selectedConceptTab == "Operators" then
		for _, classId in ipairs(Ids.ClassIds) do
			local classDefinition = Classes[classId]
			local accentColor = getClassAccent(classId)
			local card = create("Frame", {
				Name = string.format("%sConceptCard", classId),
				Parent = self.conceptList,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -4, 0, 164),
			})
			stylePanel(card, accentColor, 0.06)
			addPadding(card, 12, 12, 12, 12)

			local portraitToken = create("Frame", {
				Name = "PortraitToken",
				Parent = card,
				BackgroundColor3 = accentColor,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(48, 48),
			})
			addCorner(portraitToken, 24)
			create("TextLabel", {
				Parent = portraitToken,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Font = Theme.HeaderFont,
				Text = string.sub(classId, 1, 1),
				TextColor3 = Theme.Text,
				TextSize = 24,
			})

			local headerLabel = createHeaderLabel(card, classDefinition.name, UDim2.new(1, -64, 0, 20))
			headerLabel.Position = UDim2.new(0, 60, 0, 0)
			headerLabel.TextSize = 17
			local roleLabel = createBodyLabel(card, classDefinition.role, UDim2.new(1, -64, 0, 36), Theme.Text, 13)
			roleLabel.Position = UDim2.new(0, 60, 0, 24)

			local passiveLabel = createBodyLabel(
				card,
				string.format("Passive: %s", classDefinition.passive.name),
				UDim2.new(1, 0, 0, 16),
				accentColor,
				12
			)
			passiveLabel.Position = UDim2.new(0, 0, 0, 62)

			local passiveBody = createBodyLabel(card, classDefinition.passive.description, UDim2.new(1, 0, 0, 38), Theme.Muted, 12)
			passiveBody.Position = UDim2.new(0, 0, 0, 80)

			local skillNames = {}

			for _, skillId in ipairs(classDefinition.startingSkills) do
				table.insert(skillNames, Skills[skillId].name)
			end

			local skillLabel = createBodyLabel(
				card,
				string.format("Starter Kit: %s", table.concat(skillNames, " • ")),
				UDim2.new(1, 0, 0, 16),
				Theme.Text,
				12
			)
			skillLabel.Position = UDim2.new(0, 0, 1, -18)
		end
	else
		local sortedEnemyIds = {}

		for enemyId in pairs(Enemies) do
			table.insert(sortedEnemyIds, enemyId)
		end

		table.sort(sortedEnemyIds)

		for _, enemyId in ipairs(sortedEnemyIds) do
			local enemyDefinition = Enemies[enemyId]
			local accentColor = getEnemyAccent(enemyDefinition)
			local card = create("Frame", {
				Name = string.format("%sEnemyCard", enemyId),
				Parent = self.conceptList,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -4, 0, 142),
			})
			stylePanel(card, accentColor, 0.06)
			addPadding(card, 12, 12, 12, 12)

			local titleLabel = createHeaderLabel(card, enemyDefinition.name, UDim2.new(1, -72, 0, 20))
			titleLabel.TextSize = 17
			local typeBadge = createTokenBadge(card, contains(enemyDefinition.tags, "boss") and "Boss" or "Mob", accentColor)
			typeBadge.Position = UDim2.new(1, -92, 0, 0)

			local roleLabel = createBodyLabel(card, enemyDefinition.role, UDim2.new(1, 0, 0, 34), Theme.Text, 13)
			roleLabel.Position = UDim2.new(0, 0, 0, 24)

			local statsLabel = createBodyLabel(
				card,
				string.format("HP %d • Armor %d • Speed %d • Scrap %d", enemyDefinition.health, enemyDefinition.armor, enemyDefinition.speed, enemyDefinition.scrapReward),
				UDim2.new(1, 0, 0, 16),
				accentColor,
				12
			)
			statsLabel.Position = UDim2.new(0, 0, 0, 64)

			local tagsLabel = createBodyLabel(card, formatTags(enemyDefinition.tags), UDim2.new(1, 0, 0, 34), Theme.Muted, 12)
			tagsLabel.Position = UDim2.new(0, 0, 0, 86)
		end
	end
end

return HudController
