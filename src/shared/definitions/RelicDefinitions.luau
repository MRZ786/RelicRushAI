--!strict
-- RelicDefinitions.luau
-- Authoritative catalog of relics for Relic Rush
-- Features 7 rarities: Common, Uncommon, Rare, Epic, Legendary, Mythic, Cursed
-- Includes the signature relic: The Hollow Crown

local CommonTypes = require(script.Parent.Parent.types.CommonTypes)

type RelicDefinition = CommonTypes.RelicDefinition

local RelicDefinitions: { [string]: RelicDefinition } = {
	-- =========================================================================
	-- COMMON RARITY
	-- =========================================================================
	["relic_scavenger_compass"] = {
		definitionId = "relic_scavenger_compass",
		name = "Scavenger's Compass",
		rarity = "Common",
		description = "A tarnished brass compass whose needle quivers toward unseen riches in the wild.",
		lore = "Found buried beneath the overgrown roots of the Forgotten Wilds.",
		baseValue = 60,
		incomeRateCash = 2, -- $2 per 10s tick on base plinth
		incomeRateShards = 0,
		buff = {
			buffType = "SpeedBoost",
			magnitude = 0.15,
			description = "+15% Exploration WalkSpeed",
		},
		accentColor = Color3.fromRGB(158, 158, 158), -- Slate Gray
	},

	["relic_ancient_chisel"] = {
		definitionId = "relic_ancient_chisel",
		name = "Artisan's Chisel",
		rarity = "Common",
		description = "A hardened bronze chisel once used to engrave holy runes upon stone plinths.",
		lore = "Excavated from the rubble of forgotten mason workshops.",
		baseValue = 75,
		incomeRateCash = 3,
		incomeRateShards = 0,
		buff = {
			buffType = "SaleBonus",
			magnitude = 0.08,
			description = "+8% Bonus Sale Value",
		},
		accentColor = Color3.fromRGB(189, 189, 189),
	},

	-- =========================================================================
	-- UNCOMMON RARITY
	-- =========================================================================
	["relic_merchants_eye"] = {
		definitionId = "relic_merchants_eye",
		name = "Merchant's Eye",
		rarity = "Uncommon",
		description = "A carved amber talisman that glints with an appraiser's sharp intuition.",
		lore = "Once carried by the high appraisers of the Gilded Bazaar.",
		baseValue = 140,
		incomeRateCash = 5,
		incomeRateShards = 1,
		buff = {
			buffType = "SaleBonus",
			magnitude = 0.15,
			description = "+15% Bonus Cash from Relic Sales",
		},
		accentColor = Color3.fromRGB(76, 175, 80), -- Forest Emerald
	},

	["relic_gilded_goblet"] = {
		definitionId = "relic_gilded_goblet",
		name = "Gilded Chalice",
		rarity = "Uncommon",
		description = "A filigree golden goblet recovered from the sunken catacombs.",
		lore = "Used in royal libation rituals before the deluge drowned the valley.",
		baseValue = 160,
		incomeRateCash = 6,
		incomeRateShards = 1,
		buff = {
			buffType = "TreasureLuck",
			magnitude = 0.12,
			description = "+12% Chance for Bonus Relic Drops",
		},
		accentColor = Color3.fromRGB(129, 199, 132),
	},

	-- =========================================================================
	-- RARE RARITY
	-- =========================================================================
	["relic_shadow_talisman"] = {
		definitionId = "relic_shadow_talisman",
		name = "Shadow Talisman",
		rarity = "Rare",
		description = "A smooth obsidian stone that absorbs vibrations and obscures the wearer.",
		lore = "Favored by night-runners slipping past sentries into fortified vaults.",
		baseValue = 300,
		incomeRateCash = 10,
		incomeRateShards = 2,
		buff = {
			buffType = "AlarmReduction",
			magnitude = 0.25,
			description = "-25% Heist & Raid Alarm Detection Rate",
		},
		accentColor = Color3.fromRGB(33, 150, 243), -- Cerulean Sapphire
	},

	["relic_ancient_hourglass"] = {
		definitionId = "relic_ancient_hourglass",
		name = "Ancient Hourglass",
		rarity = "Rare",
		description = "Golden sand falls upward in defiance of earthly gravity.",
		lore = "Salvaged from the shifting dunes of the forgotten desert sanctuary.",
		baseValue = 320,
		incomeRateCash = 12,
		incomeRateShards = 2,
		buff = {
			buffType = "TimeExtension",
			magnitude = 15,
			description = "+15 Seconds Raid Infiltration Window",
		},
		accentColor = Color3.fromRGB(100, 181, 246),
	},

	-- =========================================================================
	-- EPIC RARITY
	-- =========================================================================
	["relic_obsidian_chalice"] = {
		definitionId = "relic_obsidian_chalice",
		name = "Obsidian Chalice",
		rarity = "Epic",
		description = "Dark as a moonless midnight, imbued with ancient sentinel protection.",
		lore = "Breached from the heavily fortified vaults of the Ashen Domain.",
		baseValue = 650,
		incomeRateCash = 20,
		incomeRateShards = 4,
		buff = {
			buffType = "HealthBoost",
			magnitude = 0.30,
			description = "+30 Maximum Health & Hazard Resistance",
		},
		accentColor = Color3.fromRGB(156, 39, 176), -- Royal Amethyst
	},

	["relic_praetorian_crest"] = {
		definitionId = "relic_praetorian_crest",
		name = "Praetorian Crest",
		rarity = "Epic",
		description = "A heavy gilded crest bearing the seal of imperial legion commanders.",
		lore = "Rallies spectral guards to fortify base defenses against raiders.",
		baseValue = 700,
		incomeRateCash = 22,
		incomeRateShards = 5,
		buff = {
			buffType = "RaidDefense",
			magnitude = 0.25,
			description = "+25% Base Defense & Alarm Sensitivity",
		},
		accentColor = Color3.fromRGB(186, 104, 200),
	},

	-- =========================================================================
	-- LEGENDARY RARITY
	-- =========================================================================
	["relic_sunstone_scepter"] = {
		definitionId = "relic_sunstone_scepter",
		name = "Sunstone Scepter",
		rarity = "Legendary",
		description = "Pulsates with the searing solar fire of a collapsed dawn.",
		lore = "Forged by ancient sorcerers to banish the creeping void darkness.",
		baseValue = 1500,
		incomeRateCash = 40,
		incomeRateShards = 10,
		buff = {
			buffType = "SpeedBoost",
			magnitude = 0.30,
			description = "+30% WalkSpeed & Radiant Illuminance",
		},
		accentColor = Color3.fromRGB(255, 152, 0), -- Radiant Amber
	},

	["relic_archons_aegis"] = {
		definitionId = "relic_archons_aegis",
		name = "Archon's Aegis",
		rarity = "Legendary",
		description = "A shield shaped from indestructible celestial meteor plate.",
		lore = "Warded an astral stronghold against centuries of siege.",
		baseValue = 1600,
		incomeRateCash = 45,
		incomeRateShards = 12,
		buff = {
			buffType = "RaidDefense",
			magnitude = 0.35,
			description = "+35% Base Defense & +40 Max Health",
		},
		accentColor = Color3.fromRGB(255, 183, 77),
	},

	-- =========================================================================
	-- MYTHIC RARITY (SIGNATURE RELIC)
	-- =========================================================================
	["relic_hollow_crown"] = {
		definitionId = "relic_hollow_crown",
		name = "The Hollow Crown",
		rarity = "Mythic",
		description = "The fabled crown of an astral empire lost to time. Whispers of absolute dominion echo in its presence.",
		lore = "Crowned the sovereign of the Celestial Rift. Grants immense prestige and wealth to any lord capable of bearing its weight.",
		baseValue = 3500,
		incomeRateCash = 100, -- Generates $100 per 10s tick on base plinth!
		incomeRateShards = 25, -- Generates 25 Shards per 10s tick!
		buff = {
			buffType = "DivineAura",
			magnitude = 0.50,
			description = "+50% Cash & Shard Rewards from all exploration & raids",
		},
		accentColor = Color3.fromRGB(233, 30, 99), -- Sovereign Crimson
	},

	-- =========================================================================
	-- CURSED RARITY
	-- =========================================================================
	["relic_cursed_soul_urn"] = {
		definitionId = "relic_cursed_soul_urn",
		name = "Cursed Soul Urn",
		rarity = "Cursed",
		description = "An obsidian urn bound in barbed iron chains. It emits a restless spectral wailing.",
		lore = "Yields immense wealth from trapped spirits, but marks your base on the map for all rival raiders to target.",
		baseValue = 2400,
		incomeRateCash = 80, -- High income
		incomeRateShards = 18,
		buff = {
			buffType = "TreasureLuck",
			magnitude = 0.40,
			description = "+40% Treasure Luck (Attracts enemy raiders & sentry aggro)",
		},
		accentColor = Color3.fromRGB(103, 58, 183), -- Eldritch Violet
	},
}

-- Starter relic choices for new explorers
local StarterRelicIds: { string } = {
	"relic_scavenger_compass",
	"relic_ancient_chisel",
	"relic_merchants_eye",
	"relic_shadow_talisman",
}

export type RelicSynergy = {
	synergyId: string,
	name: string,
	requiredRelicIds: { string },
	bonusDescription: string,
}

local RelicSynergies: { RelicSynergy } = {
	{
		synergyId = "synergy_smuggler",
		name = "Smuggler's Fortune",
		requiredRelicIds = { "relic_scavenger_compass", "relic_merchants_eye" },
		bonusDescription = "+10% Speed & +25% Sell Value",
	},
	{
		synergyId = "synergy_phantom",
		name = "Phantom Infiltrator",
		requiredRelicIds = { "relic_shadow_talisman", "relic_obsidian_chalice" },
		bonusDescription = "-50% Sentry Detection & +30 Max Health",
	},
	{
		synergyId = "synergy_temporal",
		name = "Temporal Singularity",
		requiredRelicIds = { "relic_ancient_hourglass", "relic_hollow_crown" },
		bonusDescription = "+30s Raid Infiltration Time & 2x Shard Rates",
	},
}

local RelicCatalog = {
	All = RelicDefinitions,
	StarterRelicIds = StarterRelicIds,
	Synergies = RelicSynergies,

	Get = function(id: string): RelicDefinition?
		return RelicDefinitions[id]
	end,

	GetAll = function(): { [string]: RelicDefinition }
		return RelicDefinitions
	end,

	GetByRarity = function(rarity: string): { RelicDefinition }
		local list: { RelicDefinition } = {}
		for _, def in pairs(RelicDefinitions) do
			if def.rarity == rarity then
				table.insert(list, def)
			end
		end
		return list
	end,

	IsValidStarter = function(id: string): boolean
		for _, starterId in ipairs(StarterRelicIds) do
			if starterId == id then
				return true
			end
		end
		return false
	end,

	GetSynergiesForInventory = function(ownedDefIds: { [string]: boolean }): { RelicSynergy }
		local active: { RelicSynergy } = {}
		for _, syn in ipairs(RelicSynergies) do
			local allPresent = true
			for _, reqId in ipairs(syn.requiredRelicIds) do
				if not ownedDefIds[reqId] then
					allPresent = false
					break
				end
			end
			if allPresent then
				table.insert(active, syn)
			end
		end
		return active
	end,
}

return RelicCatalog
