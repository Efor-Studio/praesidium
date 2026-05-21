export type ClassId = "Gunner" | "Mage" | "Priest" | "Thief"
export type SkillId = string
export type UltimateId = string
export type BuildableId = "Turret" | "Barricade" | "UtilityNode"
export type EnemyArchetypeId = string
export type RewardCardId = string
export type ModifierId = string
export type LaneId = "North" | "East" | "West"
export type RunPhase = "Lobby" | "ColdOpen" | "Combat" | "Prep" | "Reward" | "BossReward" | "Victory" | "Defeat"

export type Loadout = {
	classId: ClassId,
	equippedSkillIds: { SkillId },
	ultimateId: UltimateId,
}

export type WaveSpawnDefinition = {
	enemyId: EnemyArchetypeId,
	laneId: LaneId?,
	count: number,
	intervalSeconds: number,
	burstSize: number?,
	eliteChance: number?,
}

export type WaveDefinition = {
	index: number,
	stage: string,
	combatSeconds: number,
	prepSeconds: number,
	rewardCardCount: number,
	modifierChoiceCount: number,
	isBossWave: boolean,
	mapEvolutionId: string?,
	spawns: { WaveSpawnDefinition },
	notes: { string }?,
}

export type CampUpgradeDefinition = {
	id: string,
	name: string,
	description: string,
	maxRank: number,
	category: string,
}

return table.freeze({})
