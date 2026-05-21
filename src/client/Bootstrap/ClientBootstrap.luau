local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteManifest = require(Shared.Networking.RemoteManifest)
local MatchController = require(script.Parent.Parent.Controllers.MatchController)

local ClientBootstrap = {}

local function collectRemotes()
	local container = ReplicatedStorage:WaitForChild("Remotes")
	local remotes = {}

	for _, definition in ipairs(RemoteManifest.Commands) do
		remotes[definition.name] = container:WaitForChild(definition.name)
	end

	for _, definition in ipairs(RemoteManifest.Events) do
		remotes[definition.name] = container:WaitForChild(definition.name)
	end

	return remotes
end

function ClientBootstrap.start()
	local remotes = collectRemotes()
	local matchController = MatchController.new(remotes)

	matchController:bootstrap()

	return {
		matchController = matchController,
	}
end

return ClientBootstrap
