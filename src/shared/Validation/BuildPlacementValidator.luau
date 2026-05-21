local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Buildables = require(Shared.Config.Buildables)
local Ids = require(Shared.Ids)

local BuildPlacementValidator = {}

function BuildPlacementValidator.validate(request)
	if type(request) ~= "table" then
		return false, "Build request must be a table."
	end

	if not Ids.BuildableIdSet[request.buildableId] then
		return false, "Unknown buildable."
	end

	if not Ids.LaneIdSet[request.laneId] then
		return false, "Unknown lane."
	end

	if type(request.slotId) ~= "string" or request.slotId == "" then
		return false, "A slotId is required for build placement."
	end

	if request.rotationY ~= nil and type(request.rotationY) ~= "number" then
		return false, "rotationY must be numeric when provided."
	end

	return true, Buildables[request.buildableId]
end

return BuildPlacementValidator
