--!strict
-- QuestDefinitions.luau
-- Authoritative quest progression catalog for Relic Rush
-- 12 progression quests (Exploration, Discovery, Base Building, Defence, Collection, Raiding)
-- plus Daily and Repeatable quest objectives.

local CommonTypes = require(script.Parent.Parent.types.CommonTypes)

type QuestDefinition = CommonTypes.QuestDefinition

local QuestList: { QuestDefinition } = {
	-- 12 Progression Quests
	{
		questId = "quest_the_calling",
		title = "The Calling",
		description = "Seek out Elder Corvus on the sanctuary dais and bond with your first starter relic.",
		rewardCash = 100,
		rewardShards = 25,
		order = 1,
		category = "Progression",
	},
	{
		questId = "quest_wilds_discovery",
		title = "Wilds Expedition",
		description = "Venture into the Forgotten Wilds and excavate an ancient relic from a dynamic node.",
		rewardCash = 120,
		rewardShards = 25,
		order = 2,
		category = "Progression",
	},
	{
		questId = "quest_claim_sanctum",
		title = "Sanctum Foundation",
		description = "Visit your assigned plot in the Base District and place your first base customisation.",
		rewardCash = 100,
		rewardShards = 20,
		order = 3,
		category = "Progression",
	},
	{
		questId = "quest_plinth_attunement",
		title = "Plinth Attunement",
		description = "Slot a relic onto 1 of your 10 sanctum plinths to begin generating passive income.",
		rewardCash = 120,
		rewardShards = 30,
		order = 4,
		category = "Progression",
	},
	{
		questId = "quest_tribute_tithe",
		title = "Vault Tithe",
		description = "Collect accumulated passive tribute from your central Sanctum Vault Coffer.",
		rewardCash = 150,
		rewardShards = 35,
		order = 5,
		category = "Progression",
	},
	{
		questId = "quest_fortify_defenses",
		title = "Fortify Sanctum",
		description = "Place an Abyssal Runic Ward or Arcane Sentry Totem to increase base defense rating to 25+.",
		rewardCash = 180,
		rewardShards = 40,
		order = 6,
		category = "Progression",
	},
	{
		questId = "quest_sanctuary_upgrade",
		title = "Workshop Elevation",
		description = "Upgrade your workshop bench to Tier 2 (Stone Workshop with artisan forge & anvil).",
		rewardCash = 200,
		rewardShards = 50,
		order = 7,
		category = "Progression",
	},
	{
		questId = "quest_shadow_infiltration",
		title = "Shadow Infiltration",
		description = "Select an active online rival and infiltrate their personal sanctum plot.",
		rewardCash = 220,
		rewardShards = 45,
		order = 8,
		category = "Progression",
	},
	{
		questId = "quest_vault_breach",
		title = "Coffer Breach & Escape",
		description = "Crack a rival vault coffer, evade sentry defenses, and reach the extraction boundary safely.",
		rewardCash = 300,
		rewardShards = 60,
		order = 9,
		category = "Progression",
	},
	{
		questId = "quest_sunken_catacombs",
		title = "The Sunken Catacombs",
		description = "Unlock permanent access to the Sunken Vault and navigate its submerged traps.",
		rewardCash = 350,
		rewardShards = 75,
		order = 10,
		category = "Progression",
	},
	{
		questId = "quest_ashen_conquest",
		title = "Ashen Crucible",
		description = "Unlock the Ashen Domain and discover 3 unique relics in the volcanic ruins.",
		rewardCash = 450,
		rewardShards = 100,
		order = 11,
		category = "Progression",
	},
	{
		questId = "quest_crown_of_void",
		title = "Crown of the Void",
		description = "Reach the Celestial Rift apex and commune with the altar of the signature Hollow Crown.",
		rewardCash = 600,
		rewardShards = 200,
		order = 12,
		category = "Progression",
	},

	-- Daily & Repeatable Quests
	{
		questId = "daily_wilds_harvest",
		title = "Daily Excavation",
		description = "Excavate 2 dynamic relic nodes across any exploration zone today.",
		rewardCash = 150,
		rewardShards = 25,
		order = 101,
		category = "Daily",
		targetCount = 2,
	},
	{
		questId = "daily_rival_raid",
		title = "Daily Infiltration",
		description = "Successfully infiltrate and siphon tribute from an online rival base.",
		rewardCash = 200,
		rewardShards = 35,
		order = 102,
		category = "Daily",
		targetCount = 1,
	},
	{
		questId = "repeatable_tribute_collect",
		title = "Repeatable Tithe",
		description = "Collect passive tribute from your Sanctum Vault Coffer.",
		rewardCash = 80,
		rewardShards = 15,
		order = 201,
		category = "Repeatable",
	},
}

local QuestMap: { [string]: QuestDefinition } = {}
for _, q in ipairs(QuestList) do
	QuestMap[q.questId] = q
end

local QuestDefinitions = {
	All = QuestList,
	Map = QuestMap,

	Get = function(questId: string): QuestDefinition?
		return QuestMap[questId]
	end,
}

return QuestDefinitions
