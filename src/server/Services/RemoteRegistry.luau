local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteManifest = require(Shared.Networking.RemoteManifest)

local RemoteRegistry = {}

local function ensureRemote(container, definition)
	local remote = container:FindFirstChild(definition.name)

	if remote and remote.ClassName ~= definition.className then
		remote:Destroy()
		remote = nil
	end

	if not remote then
		remote = Instance.new(definition.className)
		remote.Name = definition.name
		remote.Parent = container
	end

	return remote
end

function RemoteRegistry.create()
	local container = ReplicatedStorage:FindFirstChild("Remotes")

	if not container then
		container = Instance.new("Folder")
		container.Name = "Remotes"
		container.Parent = ReplicatedStorage
	end

	local remotes = {}

	for _, definition in ipairs(RemoteManifest.Commands) do
		remotes[definition.name] = ensureRemote(container, definition)
	end

	for _, definition in ipairs(RemoteManifest.Events) do
		remotes[definition.name] = ensureRemote(container, definition)
	end

	return {
		container = container,
		remotes = remotes,
	}
end

return RemoteRegistry
