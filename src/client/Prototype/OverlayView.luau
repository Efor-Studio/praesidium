local OverlayView = {}
OverlayView.__index = OverlayView

local function create(className, properties)
	local instance = Instance.new(className)

	for key, value in pairs(properties or {}) do
		instance[key] = value
	end

	return instance
end

local function createLabel(parent, positionY, sizeY, textSize, font)
	return create("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, positionY),
		Size = UDim2.new(1, 0, 0, sizeY),
		Font = font or Enum.Font.GothamMedium,
		Text = "",
		TextColor3 = Color3.fromRGB(244, 247, 252),
		TextSize = textSize,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
end

function OverlayView.new(playerGui)
	local self = setmetatable({}, OverlayView)

	local existingGui = playerGui:FindFirstChild("PraesidiumFlowOverlay")

	if existingGui then
		existingGui:Destroy()
	end

	self.screenGui = create("ScreenGui", {
		Name = "PraesidiumFlowOverlay",
		Parent = playerGui,
		DisplayOrder = 20,
		IgnoreGuiInset = false,
		ResetOnSpawn = false,
	})

	local frame = create("Frame", {
		Parent = self.screenGui,
		BackgroundColor3 = Color3.fromRGB(11, 16, 27),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(20, 20),
		Size = UDim2.fromOffset(430, 212),
	})

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(94, 124, 171)
	stroke.Transparency = 0.35
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.Parent = frame

	self.titleLabel = createLabel(frame, 0, 24, 18, Enum.Font.FredokaOne)
	self.phaseLabel = createLabel(frame, 28, 18, 14, Enum.Font.GothamBold)
	self.resourceLabel = createLabel(frame, 52, 34, 13)
	self.laneLabel = createLabel(frame, 88, 34, 13)
	self.statusLabel = createLabel(frame, 126, 34, 13)
	self.controlsLabel = createLabel(frame, 164, 40, 12)

	return self
end

function OverlayView:render(viewModel)
	self.titleLabel.Text = viewModel.title or "Praesidium MVP"
	self.phaseLabel.Text = viewModel.phase or ""
	self.resourceLabel.Text = viewModel.resources or ""
	self.laneLabel.Text = viewModel.lanes or ""
	self.statusLabel.Text = viewModel.status or ""
	self.controlsLabel.Text = viewModel.controls or ""
end

function OverlayView:destroy()
	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

return OverlayView
