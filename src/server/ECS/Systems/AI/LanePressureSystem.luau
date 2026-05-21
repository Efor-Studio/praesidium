local function LanePressureSystem(_world, context)
	context.matchService:refreshLanePressure()
end

return {
	priority = 0,
	system = LanePressureSystem,
}
