local function RewardFlowSystem(_world, context)
	context.matchService:refreshRewardState()
end

return {
	priority = 50,
	system = RewardFlowSystem,
}
