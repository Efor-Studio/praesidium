local function SkillQueueSystem(_world, context)
	context.matchService:flushSkillQueue()
end

return {
	priority = -100,
	system = SkillQueueSystem,
}
