local Players = game:GetService("Players")

local MatterRuntime = require(script.Parent.Parent.ECS.MatterRuntime)
local MatchService = require(script.Parent.Parent.Services.MatchService)
local ProgressionService = require(script.Parent.Parent.Services.ProgressionService)
local RemoteRegistry = require(script.Parent.Parent.Services.RemoteRegistry)
local WorldService = require(script.Parent.Parent.Services.WorldService)

local ServerBootstrap = {}

function ServerBootstrap.start()
	local remoteBundle = RemoteRegistry.create()
	local progressionService = ProgressionService.new()
	local worldService = WorldService.new()
	local matchService = MatchService.new(remoteBundle.remotes, progressionService, worldService)

	worldService:start()
	worldService:beginLobby()

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
		worldService = worldService,
	}
end

return ServerBootstrap
