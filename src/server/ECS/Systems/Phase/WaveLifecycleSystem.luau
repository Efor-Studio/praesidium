local function WaveLifecycleSystem(_world, context)
	context.matchService:step(context.getDeltaTime())
end

return {
	priority = -200,
	system = WaveLifecycleSystem,
}
