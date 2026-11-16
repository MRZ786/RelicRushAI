--!strict
-- CommonTypes.luau
-- Authoritative type definitions for Relic Rush: Dark-Fantasy Base-Raiding & Exploration RPG

export type RelicRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Cursed"

export type RelicBuffType = 
	| "SpeedBoost" 
	| "SaleBonus" 
	| "AlarmReduction" 
	| "HealthBoost" 
	| "TimeExtension" 
	| "DivineAura"
	| "RaidDefense"
	| "TreasureLuck"

export type RelicBuff = {
	buffType: RelicBuffType,
	magnitude: number, -- e.g. 0.15 for 15%
	description: string,
}

export type RelicDefinition = {
	definitionId: string,
	name: string,
	rarity: RelicRarity,
	description: string,
	lore: string,
	baseValue: number,
	incomeRateCash: number, -- Passive Cash per 10-second tick when slotted on base plinth
	incomeRateShards: number, -- Passive Shards per 10-second tick when slotted on base plinth
	buff: RelicBuff,
	accentColor: Color3,
}

export type RelicInstance = {
	instanceId: string,
	definitionId: string,
	ownerId: number,
	acquiredAt: number,
	upgradeLevel: number,
	isEquipped: boolean,
}

export type BasePlacedObject = {
	placementId: string,
	itemId: string,
	position: Vector3,
	rotationY: number,
}

export type BasePlotData = {
	plotId: string,
	plotIndex: number,
	tier: number,
	theme: string?,                          -- Base architectural visual style
	placedObjects: { BasePlacedObject },
	slottedRelicIds: { [number]: string? }, -- 10 Relic Slots (indices 1 to 10)
	uncollectedTributeCash: number,          -- Accumulated uncollected coffer cash
	uncollectedTributeShards: number,        -- Accumulated uncollected coffer shards
	lastIncomeTick: number,                  -- Timestamp of last passive income calculation
	defenseRating: number,                   -- Total defense strength calculated from tier and wards
}

export type PlayerCurrencies = {
	Cash: number,
	RelicShards: number,
}

export type QuestCategory = "Progression" | "Daily" | "Repeatable"

export type QuestDefinition = {
	questId: string,
	title: string,
	description: string,
	rewardCash: number,
	rewardShards: number,
	order: number,
	category: QuestCategory?,
	targetCount: number?,
}

export type MilestoneCategory = "DiscoveryCount" | "RarityTier" | "SignatureRelic"

export type MilestoneDefinition = {
	milestoneId: string,
	title: string,
	description: string,
	category: MilestoneCategory,
	targetCount: number?,
	targetRarity: RelicRarity?,
	targetRelicId: string?,
	rewardCash: number,
	rewardShards: number,
	rewardTitle: string?,
	order: number,
}

export type WorldZoneId = "ForgottenWilds" | "SunkenVault" | "AshenDomain" | "CelestialRift"
export type RegionId = "ForgottenMarket" | "EmpireDistrict" | "WhisperingWilds" | "ObsidianVaults" | "HollowRealm" | WorldZoneId

export type RebirthData = {
	rebirthCount: number,
	prestigeMultiplier: number, -- e.g. 1.0 = base, 1.25 = +25% permanent income
	totalRebirthSpentCash: number,
}

export type OfflineIncomeReceipt = {
	elapsedSeconds: number,
	offlineCashEarned: number,
	offlineShardsEarned: number,
	cappedAtHours: number,
}

export type PlayerProfile = {
	schemaVersion: number,
	playerId: number,
	currencies: PlayerCurrencies,
	inventory: { RelicInstance },
	equippedRelicId: string?,
	baseData: BasePlotData,
	discoveredRelics: { [string]: boolean },
	hasSelectedStarter: boolean,
	completedHeistsCount: number,
	completedQuests: { [string]: boolean },
	claimedQuests: { [string]: boolean },
	discoveredLore: { [string]: boolean },
	discoveredCaches: { [string]: boolean },
	unlockedRegions: { [string]: boolean },
	unlockedZones: { [string]: boolean },    -- Permanent zone access: ForgottenWilds, SunkenVault, AshenDomain, CelestialRift
	rebirthData: RebirthData,               -- Optional rebirth progression
	tutorialStep: number,
	completedTutorial: boolean,
	baseVaultStorage: { RelicInstance },
	showcaseRelicId: string?,
	relicSynergies: { string },
	collectionMilestonesClaimed: { [string]: boolean },
	lastSavedTimestamp: number,
}

export type RaidPhase = "Preparation" | "Infiltrating" | "CofferBreached" | "Escaped" | "Repelled"

export type RivalBaseInfo = {
	userId: number,
	username: string,
	displayName: string,
	plotIndex: number,
	baseTier: number,
	defenseRating: number,
	uncollectedTributeCash: number,
	isEligible: boolean,
	cooldownRemaining: number,
}

export type RaidSessionState = {
	raidId: string,
	infiltratorUserId: number,
	targetUserId: number,
	phase: RaidPhase,
	startTime: number,
	deadlineTime: number,
	siphonedCash: number,
	siphonedShards: number,
	detectedCount: number,
	alarmLevel: number?,
	smokeActiveUntil: number?,
	bypassWireActive: boolean?,
}

export type HeistPhase = "Briefing" | "Infiltration" | "ObjectiveSecured" | "AlarmLockdown" | "Extracted" | "Failed"

export type HeistSessionState = {
	sessionId: string,
	heistId: string,
	playerId: number,
	phase: HeistPhase,
	alarmLevel: number, -- 0 to 100
	startTime: number,
	objectiveSecured: boolean,
	chosenTool: string?,
	toolUsed: boolean?,
	smokeActiveUntil: number?,
	lasersDisabledUntil: number?,
	extractionDeadline: number?,
}

export type TransactionReceipt = {
	transactionId: string,
	idempotencyKey: string,
	playerId: number,
	success: boolean,
	reasonCode: string,
	timestamp: number,
}

return {}
