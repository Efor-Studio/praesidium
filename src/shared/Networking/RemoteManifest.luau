local RemoteNames = require(script.Parent.RemoteNames)

local RemoteManifest = {
	Commands = {
		{ name = RemoteNames.SelectLoadout, className = "RemoteFunction" },
		{ name = RemoteNames.ActivateSkill, className = "RemoteEvent" },
		{ name = RemoteNames.PlaceBuildable, className = "RemoteFunction" },
		{ name = RemoteNames.ChooseRewardCard, className = "RemoteFunction" },
		{ name = RemoteNames.ReadyForNextWave, className = "RemoteEvent" },
	},
	Events = {
		{ name = RemoteNames.MatchSnapshot, className = "RemoteEvent" },
		{ name = RemoteNames.MatchAnnouncement, className = "RemoteEvent" },
	},
}

return table.freeze(RemoteManifest)
