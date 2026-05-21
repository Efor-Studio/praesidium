local Players = game:GetService("Players")

local MatterRuntime = require(script.Parent.Parent.ECS.MatterRuntime)
local MatchService = require(script.Parent.Parent.Services.MatchService)
local ProgressionService = require(script.Parent.Parent.Services.ProgressionService)
local RemoteRegistry = require(script.Parent.Parent.Services.RemoteRegistry)

local ServerBootstrap = {}

function ServerBootstrap.start()
	local remoteBundle = RemoteRegistry.create()
	local progressionService = ProgressionService.new()
	local matchService = MatchService.new(remoteBundle.remotes, progressionService)

	local runtime = MatterRuntime.start({
		matchService = matchService,
		progressionService = progressionService,
		remotes = remoteBundle.remotes,
	})

	local function handlePlayerAdded(player)
		progressionService:addPlayer(player)
		matchService:addPlayer(player)
	end

	local function handlePlayerRemoving(player)
		matchService:removePlayer(player)
		progressionService:removePlayer(player)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		handlePlayerAdded(player)
	end

	Players.PlayerAdded:Connect(handlePlayerAdded)
	Players.PlayerRemoving:Connect(handlePlayerRemoving)

	return {
		matchService = matchService,
		progressionService = progressionService,
		remoteBundle = remoteBundle,
		runtime = runtime,
	}
end

return ServerBootstrap
