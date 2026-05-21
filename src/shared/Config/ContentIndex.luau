local ContentIndex = {
	GameConfig = require(script.Parent.GameConfig),
	Maps = require(script.Parent.Maps),
	Buildables = require(script.Parent.Buildables),
	Enemies = require(script.Parent.Enemies),
	Skills = require(script.Parent.Skills),
	Ultimates = require(script.Parent.Ultimates),
	Classes = require(script.Parent.Classes),
	RewardCards = require(script.Parent.RewardCards),
	Modifiers = require(script.Parent.Modifiers),
	CampUpgrades = require(script.Parent.CampUpgrades),
	Waves = require(script.Parent.Waves),
}

return table.freeze(ContentIndex)
