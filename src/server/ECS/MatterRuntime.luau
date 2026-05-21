local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CollectSystems = require(script.Parent.CollectSystems)
local CreateComponents = require(script.Parent.Components)

local MatterRuntime = {}

local function runFallbackSystem(systemDefinition, context)
	if type(systemDefinition) == "table" then
		systemDefinition.system(nil, context)
	else
		systemDefinition(nil, context)
	end
end

function MatterRuntime.start(baseContext)
	local systems = CollectSystems.collect()
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	local matterModule = packages and packages:FindFirstChild("Matter")

	if matterModule then
		local Matter = require(matterModule)
		local world = Matter.World.new()
		local components = CreateComponents(Matter)
		local context = table.clone(baseContext)

		context.world = world
		context.components = components
		context.getDeltaTime = function()
			return Matter.useDeltaTime()
		end

		local loop = Matter.Loop.new(world, context)
		loop:setWorlds({
			server = world,
		})
		loop:scheduleSystems(systems)

		local connections = loop:begin({
			default = RunService.Heartbeat,
		})

		baseContext.matchService:bindWorld(world, components)

		return {
			mode = "Matter",
			world = world,
			loop = loop,
			stop = function()
				for _, connection in pairs(connections) do
					connection:Disconnect()
				end
			end,
		}
	end

	local context = table.clone(baseContext)
	context.deltaTime = 0
	context.getDeltaTime = function()
		return context.deltaTime
	end

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		context.deltaTime = deltaTime

		for _, systemDefinition in ipairs(systems) do
			runFallbackSystem(systemDefinition, context)
		end
	end)

	baseContext.matchService:announce("system_notice", {
		message = "Matter package missing; running fallback scheduler until Wally packages are installed.",
	})

	return {
		mode = "Fallback",
		stop = function()
			connection:Disconnect()
		end,
	}
end

return MatterRuntime
