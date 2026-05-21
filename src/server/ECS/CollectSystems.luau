local CollectSystems = {}

function CollectSystems.collect()
	return {
		require(script.Systems.Phase.WaveLifecycleSystem),
		require(script.Systems.Combat.SkillQueueSystem),
		require(script.Systems.AI.LanePressureSystem),
		require(script.Systems.Economy.RewardFlowSystem),
		require(script.Systems.Presentation.ReplicationSystem),
	}
end

return CollectSystems
