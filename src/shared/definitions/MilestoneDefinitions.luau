--!strict
-- MilestoneDefinitions.luau
-- Authoritative collection milestones and prestige recognition catalog for Relic Rush
-- Rewards relic discovery counts, rarity tier milestones, and signature Hollow Crown discovery.

local CommonTypes = require(script.Parent.Parent.types.CommonTypes)

type MilestoneDefinition = CommonTypes.MilestoneDefinition

local MilestoneList: { MilestoneDefinition } = {
	-- 1. Discovery Count Milestones
	{
		milestoneId = "milestone_first_discovery",
		title = "First Step into Antiquity",
		description = "Discover your very first ancient relic from any realm or dynamic excavation node.",
		category = "DiscoveryCount",
		targetCount = 1,
		rewardCash = 100,
		rewardShards = 15,
		rewardTitle = "Antiquarian",
		order = 1,
	},
	{
		milestoneId = "milestone_collector_3",
		title = "Curio Collector",
		description = "Discover 3 unique relics across the fractured realms.",
		category = "DiscoveryCount",
		targetCount = 3,
		rewardCash = 250,
		rewardShards = 35,
		rewardTitle = "Seeker",
		order = 2,
	},
	{
		milestoneId = "milestone_curator_6",
		title = "Master Curator",
		description = "Discover 6 unique relics and catalog them in your codex.",
		category = "DiscoveryCount",
		targetCount = 6,
		rewardCash = 500,
		rewardShards = 75,
		rewardTitle = "Grand Curator",
		order = 3,
	},
	{
		milestoneId = "milestone_archivist_10",
		title = "Sanctuary Archivist",
		description = "Discover 10 unique relics, mastering ancient artifact resonance.",
		category = "DiscoveryCount",
		targetCount = 10,
		rewardCash = 1000,
		rewardShards = 150,
		rewardTitle = "Relic Master",
		order = 4,
	},

	-- 2. Rarity Tier Milestones
	{
		milestoneId = "milestone_rarity_uncommon",
		title = "Uncommon Fortune",
		description = "Discover your first Uncommon rarity relic.",
		category = "RarityTier",
		targetRarity = "Uncommon",
		rewardCash = 150,
		rewardShards = 20,
		rewardTitle = "Prowler",
		order = 5,
	},
	{
		milestoneId = "milestone_rarity_rare",
		title = "Hidden Antiquity",
		description = "Discover your first Rare rarity relic from deep ruins or fortresses.",
		category = "RarityTier",
		targetRarity = "Rare",
		rewardCash = 300,
		rewardShards = 50,
		rewardTitle = "Vaultbreaker",
		order = 6,
	},
	{
		milestoneId = "milestone_rarity_epic",
		title = "Epic Resonance",
		description = "Discover your first Epic rarity relic vibrating with ancient magic.",
		category = "RarityTier",
		targetRarity = "Epic",
		rewardCash = 600,
		rewardShards = 100,
		rewardTitle = "Arcanist",
		order = 7,
	},
	{
		milestoneId = "milestone_rarity_legendary",
		title = "Legend of the Fractured World",
		description = "Discover your first Legendary rarity relic.",
		category = "RarityTier",
		targetRarity = "Legendary",
		rewardCash = 1200,
		rewardShards = 200,
		rewardTitle = "Legendary Pioneer",
		order = 8,
	},
	{
		milestoneId = "milestone_rarity_cursed",
		title = "Embrace of the Abyss",
		description = "Discover a Cursed rarity relic shrouded in hazardous power.",
		category = "RarityTier",
		targetRarity = "Cursed",
		rewardCash = 800,
		rewardShards = 120,
		rewardTitle = "Abyssal Touched",
		order = 9,
	},

	-- 3. Signature Hollow Crown Discovery Milestone
	{
		milestoneId = "milestone_hollow_crown",
		title = "Sovereign of the Void",
		description = "Discover the signature Mythic relic of Relic Rush: The Hollow Crown atop the Celestial Rift Spire.",
		category = "SignatureRelic",
		targetRelicId = "relic_hollow_crown",
		rewardCash = 2500,
		rewardShards = 500,
		rewardTitle = "Void Sovereign",
		order = 10,
	},
}

local MilestoneMap: { [string]: MilestoneDefinition } = {}
for _, m in ipairs(MilestoneList) do
	MilestoneMap[m.milestoneId] = m
end

local MilestoneDefinitions = {
	All = MilestoneList,
	Map = MilestoneMap,

	Get = function(milestoneId: string): MilestoneDefinition?
		return MilestoneMap[milestoneId]
	end,
}

return MilestoneDefinitions
