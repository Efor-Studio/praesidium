local function ReplicationSystem(_world, context)
	context.matchService:replicate()
end

return {
	priority = 100,
	system = ReplicationSystem,
}
