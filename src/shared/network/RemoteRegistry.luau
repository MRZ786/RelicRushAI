--!strict
-- RemoteRegistry.luau
-- Declarative names and definitions of all client-server communication remotes
-- Supports 20-Player Exploration, Base Building, 10 Relic Plinths, and Low-Risk Raiding

local RemoteRegistry = {
	Functions = {
		-- Starter & Relics
		SelectStarterRelic = "SelectStarterRelic",
		RequestEquipRelic = "RequestEquipRelic",
		RequestUnequipRelic = "RequestUnequipRelic",
		RequestRefineRelic = "RequestRefineRelic",
		RequestSetShowcaseRelic = "RequestSetShowcaseRelic",

		-- Economy & Trades
		RequestBuyItem = "RequestBuyItem",
		RequestSellRelic = "RequestSellRelic",

		-- Base Management & 10 Relic Plinths
		RequestPlaceBaseObject = "RequestPlaceBaseObject",
		RequestMoveBaseObject = "RequestMoveBaseObject",
		RequestRemoveBaseObject = "RequestRemoveBaseObject",
		RequestBaseUpgrade = "RequestBaseUpgrade",
		RequestSetBaseTheme = "RequestSetBaseTheme",
		RequestSlotBaseRelic = "RequestSlotBaseRelic",       -- Slot relic onto 1 of 10 plinths
		RequestUnslotBaseRelic = "RequestUnslotBaseRelic",   -- Return slotted relic to backpack
		RequestCollectBaseIncome = "RequestCollectBaseIncome", -- Collect accumulated vault coffer tribute
		RequestDepositVault = "RequestDepositVault",
		RequestWithdrawVault = "RequestWithdrawVault",

		-- Low-Risk Base Raiding
		GetRivalBaseList = "GetRivalBaseList",               -- Query targetable rival bases with defenses
		RequestRaidBase = "RequestRaidBase",                 -- Infiltrate another player's base
		RequestSiphonCoffer = "RequestSiphonCoffer",         -- Siphon portion of uncollected coffer tribute
		UseRaidGadget = "UseRaidGadget",                     -- Activate Smoke Capsule or Bypass Wire in raid
		ExtractRaid = "ExtractRaid",                         -- Escape safely with siphoned haul

		-- Exploration, Quests & Zones
		RequestUnlockZone = "RequestUnlockZone",             -- Permanently unlock Forgotten Wilds, Sunken Vault, etc.
		RequestTravelRegion = "RequestTravelRegion",
		HarvestRelicNode = "HarvestRelicNode",               -- Excavate dynamic relic spawn node
		ClaimQuestReward = "ClaimQuestReward",
		ClaimCollectionMilestone = "ClaimCollectionMilestone", -- Claim relic collection milestone tier
		CompleteTutorialStep = "CompleteTutorialStep",
		SkipTutorial = "SkipTutorial",                       -- Skip onboarding to full exploration mode
		InteractLoreStele = "InteractLoreStele",
		LootTreasureUrn = "LootTreasureUrn",
		LootRegionalCache = "LootRegionalCache",
		InteractNPC = "InteractNPC",

		-- Prestige & Profiles
		RequestRebirth = "RequestRebirth",                   -- Optional rebirth prestige
		GetPlayerProfile = "GetPlayerProfile",

		-- Fortress Heists
		StartHeist = "StartHeist",
		UseHeistTool = "UseHeistTool",
		InteractHeistObjective = "InteractHeistObjective",
		ExtractHeist = "ExtractHeist",
		AbortHeist = "AbortHeist",
		HackSecurityTerminal = "HackSecurityTerminal",

		-- Dungeons & Action Combat
		RequestCombatAttack = "RequestCombatAttack",
		DungeonInteractPuzzle = "DungeonInteractPuzzle",
		DungeonClaimTreasure = "DungeonClaimTreasure",
	},

	Events = {
		ProfileUpdated = "ProfileUpdated",
		BaseIncomeTick = "BaseIncomeTick",                   -- Periodic notification of generated tribute
		BaseRaidAlert = "BaseRaidAlert",                     -- Defender alert when base is being raided
		RaidStateChanged = "RaidStateChanged",               -- Infiltrator real-time raid status & countdown
		TreasureSurgeActive = "TreasureSurgeActive",         -- Server-wide rotating surge alert
		HeistStateChanged = "HeistStateChanged",
		AlarmTriggered = "AlarmTriggered",
		Notification = "Notification",
		QuestProgressUpdated = "QuestProgressUpdated",
		CombatDamageDealt = "CombatDamageDealt",
		PvPZoneStateChanged = "PvPZoneStateChanged",
	},
}

return RemoteRegistry
