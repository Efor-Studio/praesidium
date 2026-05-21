local function createComponents(Matter)
	return {
		MatchState = Matter.component("MatchState"),
		LaneState = Matter.component("LaneState"),
		PlayerState = Matter.component("PlayerState"),
		BuildableState = Matter.component("BuildableState"),
	}
end

return createComponents
