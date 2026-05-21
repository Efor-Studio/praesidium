local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Classes = require(Shared.Config.Classes)
local Skills = require(Shared.Config.Skills)
local Ultimates = require(Shared.Config.Ultimates)

local LoadoutValidator = {}

local function contains(list, expected)
	for _, value in ipairs(list) do
		if value == expected then
			return true
		end
	end

	return false
end

local function hasDuplicateValues(list)
	local seen = {}

	for _, value in ipairs(list) do
		if seen[value] then
			return true
		end

		seen[value] = true
	end

	return false
end

function LoadoutValidator.buildDefaultLoadout(classId)
	local classDefinition = Classes[classId]

	if not classDefinition then
		return nil
	end

	return {
		classId = classDefinition.id,
		equippedSkillIds = table.clone(classDefinition.startingSkills),
		ultimateId = classDefinition.ultimateId,
	}
end

function LoadoutValidator.validate(loadout)
	if type(loadout) ~= "table" then
		return false, "Loadout must be a table."
	end

	local classDefinition = Classes[loadout.classId]

	if not classDefinition then
		return false, "Unknown class selection."
	end

	if type(loadout.equippedSkillIds) ~= "table" then
		return false, "Loadout must provide equipped skills."
	end

	if #loadout.equippedSkillIds ~= GameConfig.MaxEquippedSkills then
		return false, string.format("Expected exactly %d equipped skills.", GameConfig.MaxEquippedSkills)
	end

	if hasDuplicateValues(loadout.equippedSkillIds) then
		return false, "Duplicate skills are not allowed in a loadout."
	end

	for _, skillId in ipairs(loadout.equippedSkillIds) do
		local skillDefinition = Skills[skillId]

		if not skillDefinition then
			return false, string.format("Unknown skill: %s", tostring(skillId))
		end

		if skillDefinition.classId ~= classDefinition.id then
			return false, string.format("%s does not belong to %s.", skillId, classDefinition.id)
		end

		if not contains(classDefinition.skillPool, skillId) then
			return false, string.format("%s is not in the %s skill pool.", skillId, classDefinition.id)
		end
	end

	local ultimateDefinition = Ultimates[loadout.ultimateId]

	if not ultimateDefinition then
		return false, "Unknown ultimate selection."
	end

	if ultimateDefinition.classId ~= classDefinition.id then
		return false, "Ultimate does not belong to the selected class."
	end

	if loadout.ultimateId ~= classDefinition.ultimateId then
		return false, "Each class has a fixed v1 ultimate."
	end

	return true
end

return LoadoutValidator
