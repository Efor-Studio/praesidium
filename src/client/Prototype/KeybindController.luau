local UserInputService = game:GetService("UserInputService")

local KeybindController = {}
KeybindController.__index = KeybindController

local LANE_KEY_ORDER = {
	[Enum.KeyCode.One] = "North",
	[Enum.KeyCode.Two] = "East",
	[Enum.KeyCode.Three] = "West",
}

local SKILL_KEYS = {
	[Enum.KeyCode.Q] = 1,
	[Enum.KeyCode.E] = 2,
	[Enum.KeyCode.R] = 3,
}

local BUILD_KEYS = {
	[Enum.KeyCode.Z] = "Turret",
	[Enum.KeyCode.X] = "Barricade",
	[Enum.KeyCode.C] = "UtilityNode",
}

function KeybindController.new(callbacks)
	local self = setmetatable({}, KeybindController)

	self.callbacks = callbacks
	self.connection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		local laneId = LANE_KEY_ORDER[input.KeyCode]

		if laneId then
			self.callbacks.onLaneSelected(laneId)
			return
		end

		local skillIndex = SKILL_KEYS[input.KeyCode]

		if skillIndex then
			self.callbacks.onSkill(skillIndex)
			return
		end

		local buildableId = BUILD_KEYS[input.KeyCode]

		if buildableId then
			self.callbacks.onBuild(buildableId)
			return
		end

		if input.KeyCode == Enum.KeyCode.F then
			self.callbacks.onUltimate()
		elseif input.KeyCode == Enum.KeyCode.G then
			self.callbacks.onReady()
		end
	end)

	return self
end

function KeybindController:destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
end

return KeybindController
