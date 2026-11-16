--!strict
-- ZoneLootTables.luau
-- Authoritative exploration zone parameters, rarity-based weighted loot tables,
-- dynamic node spawn positions, and rotating celestial surge configurations.

local CommonTypes = require(script.Parent.Parent.types.CommonTypes)

export type RarityWeights = {
	Common: number,
	Uncommon: number,
	Rare: number,
	Epic: number,
	Legendary: number,
	Mythic: number,
	Cursed: number,
}

export type ZoneNodeDefinition = {
	nodeId: string,
	position: Vector3,
	description: string,
}

export type ZoneConfig = {
	zoneId: CommonTypes.WorldZoneId,
	displayName: string,
	tier: number,
	unlockCostCash: number,
	description: string,
	atmosphereColor: Color3,
	rarityWeights: RarityWeights,
	spawnNodes: { ZoneNodeDefinition },
	gatewayPosition: Vector3,
	returnPortalPosition: Vector3,
}

local ZoneConfigurations: { [CommonTypes.WorldZoneId]: ZoneConfig } = {
	-- =========================================================================
	-- ZONE 1: FORGOTTEN WILDS (Starter Zone)
	-- Overgrown mossy ruins, twisted ironwood canopy, ancient dolmen arches
	-- =========================================================================
	["ForgottenWilds"] = {
		zoneId = "ForgottenWilds",
		displayName = "Forgotten Wilds",
		tier = 1,
		unlockCostCash = 0, -- Free starter zone
		description = "A primordial, overgrown wilderness where forgotten stone altars rest beneath colossal ironwood canopies.",
		atmosphereColor = Color3.fromRGB(76, 175, 80),
		rarityWeights = {
			Common = 65,
			Uncommon = 28,
			Rare = 7,
			Epic = 0,
			Legendary = 0,
			Mythic = 0,
			Cursed = 0,
		},
		gatewayPosition = Vector3.new(-210, 3, -150),
		returnPortalPosition = Vector3.new(-210, 3, -135),
		spawnNodes = {
			{ nodeId = "wilds_node_1", position = Vector3.new(-230, 2, -180), description = "Overgrown Root Mound" },
			{ nodeId = "wilds_node_2", position = Vector3.new(-260, 4, -200), description = "Mossy Dolmen Archway" },
			{ nodeId = "wilds_node_3", position = Vector3.new(-290, 3, -240), description = "Ancient Ironwood Buttress" },
			{ nodeId = "wilds_node_4", position = Vector3.new(-245, 5, -260), description = "Sunken Amphitheater Edge" },
			{ nodeId = "wilds_node_5", position = Vector3.new(-310, 6, -190), description = "Dune Temple Shallows" },
		},
	},

	-- =========================================================================
	-- ZONE 2: SUNKEN VAULT (Mid-Tier Submerged Catacombs)
	-- Flooded aqueducts, subterranean crypts, rusted portcullises, security traps
	-- =========================================================================
	["SunkenVault"] = {
		zoneId = "SunkenVault",
		displayName = "Sunken Vault",
		tier = 2,
		unlockCostCash = 350,
		description = "A subterranean, half-flooded fortress complex lined with laser galleries, pressure traps, and sealed coffers.",
		atmosphereColor = Color3.fromRGB(33, 150, 243),
		rarityWeights = {
			Common = 32,
			Uncommon = 45,
			Rare = 20,
			Epic = 3,
			Legendary = 0,
			Mythic = 0,
			Cursed = 0,
		},
		gatewayPosition = Vector3.new(460, 4, 380),
		returnPortalPosition = Vector3.new(460, 4, 365),
		spawnNodes = {
			{ nodeId = "vault_node_1", position = Vector3.new(480, 2, 420), description = "Submerged Drainage Flume" },
			{ nodeId = "vault_node_2", position = Vector3.new(510, 5, 460), description = "Outer Moat Bastion" },
			{ nodeId = "vault_node_3", position = Vector3.new(475, 8, 510), description = "Laser Sentry Corridor" },
			{ nodeId = "vault_node_4", position = Vector3.new(530, 6, 540), description = "Mainframe Terminal Alcove" },
			{ nodeId = "vault_node_5", position = Vector3.new(440, 3, 520), description = "Deep Drainage Sump" },
		},
	},

	-- =========================================================================
	-- ZONE 3: ASHEN DOMAIN (High-Tier Volcanic Ruins)
	-- Scorched basalt plateaus, magma vents, imperial senate ruins, crypt sarcophagi
	-- =========================================================================
	["AshenDomain"] = {
		zoneId = "AshenDomain",
		displayName = "Ashen Domain",
		tier = 3,
		unlockCostCash = 800,
		description = "The charred, volcanic seat of a fallen empire. Imperial marble columns stand fractured amid glowing lava fissures.",
		atmosphereColor = Color3.fromRGB(255, 87, 34),
		rarityWeights = {
			Common = 0,
			Uncommon = 25,
			Rare = 45,
			Epic = 24,
			Legendary = 5,
			Mythic = 0,
			Cursed = 1,
		},
		gatewayPosition = Vector3.new(0, 3, -135),
		returnPortalPosition = Vector3.new(0, 3, -120),
		spawnNodes = {
			{ nodeId = "ashen_node_1", position = Vector3.new(-25, 3, -180), description = "Scorched Forum Colonnade" },
			{ nodeId = "ashen_node_2", position = Vector3.new(35, 4, -220), description = "Avenue of the Caesars" },
			{ nodeId = "ashen_node_3", position = Vector3.new(-70, -2, -225), description = "Sunken Crypt Sarcophagus" },
			{ nodeId = "ashen_node_4", position = Vector3.new(65, 5, -260), description = "Golden Eagle Monolith Plinth" },
			{ nodeId = "ashen_node_5", position = Vector3.new(0, 8, -315), description = "Senate Curia Portico" },
		},
	},

	-- =========================================================================
	-- ZONE 4: CELESTIAL RIFT (Endgame Astral Void)
	-- Floating obsidian archipelago, forcefield bridges, purple void crystals, Crown Spire
	-- =========================================================================
	["CelestialRift"] = {
		zoneId = "CelestialRift",
		displayName = "Celestial Rift",
		tier = 4,
		unlockCostCash = 1800,
		description = "A surreal, shattered dimension suspended over an astral void. Crowned by the apex altar of The Hollow Crown.",
		atmosphereColor = Color3.fromRGB(156, 39, 176),
		rarityWeights = {
			Common = 0,
			Uncommon = 0,
			Rare = 15,
			Epic = 40,
			Legendary = 35,
			Mythic = 5,   -- The Hollow Crown drop chance!
			Cursed = 5,
		},
		gatewayPosition = Vector3.new(220, 105, -150),
		returnPortalPosition = Vector3.new(220, 105, -135),
		spawnNodes = {
			{ nodeId = "celestial_node_1", position = Vector3.new(245, 105, -175), description = "Astral Bridgehead Islet" },
			{ nodeId = "celestial_node_2", position = Vector3.new(290, 108, -195), description = "Void Crystal Cluster" },
			{ nodeId = "celestial_node_3", position = Vector3.new(260, 112, -230), description = "Forcefield Light Nexus" },
			{ nodeId = "celestial_node_4", position = Vector3.new(310, 114, -250), description = "Ethereal Echo Dais" },
			{ nodeId = "celestial_node_5", position = Vector3.new(280, 118, -280), description = "Apex Crown Spire Altar" },
		},
	},
}

-- Rotating Treasure Surge Types
export type RotatingSurge = {
	surgeType: "CelestialSurge" | "CursedTide" | "BountyFrenzy",
	displayName: string,
	bonusDescription: string,
	durationSeconds: number,
	bonusShardMultiplier: number,
	bonusLuckRating: number,
}

local SurgeTypes: { RotatingSurge } = {
	{
		surgeType = "CelestialSurge",
		displayName = "Celestial Surge",
		bonusDescription = "Cosmic auras envelop this zone! +100% Relic Shards and elevated drop rarities!",
		durationSeconds = 240, -- 4 minutes
		bonusShardMultiplier = 2.0,
		bonusLuckRating = 0.25,
	},
	{
		surgeType = "CursedTide",
		displayName = "Cursed Tide",
		bonusDescription = "Eldritch shadows swell! Vastly increased chance for high-tier relics and ancient salvage!",
		durationSeconds = 240,
		bonusShardMultiplier = 1.75,
		bonusLuckRating = 0.35,
	},
	{
		surgeType = "BountyFrenzy",
		displayName = "Bounty Frenzy",
		bonusDescription = "Ancient treasure veins rupture! +150% Cash yields from all discovered relics!",
		durationSeconds = 240,
		bonusShardMultiplier = 1.5,
		bonusLuckRating = 0.20,
	},
}

local ZoneLootTables = {
	Zones = ZoneConfigurations,
	SurgeTypes = SurgeTypes,

	Get = function(zoneId: CommonTypes.WorldZoneId): ZoneConfig?
		return ZoneConfigurations[zoneId]
	end,

	GetAllZones = function(): { [CommonTypes.WorldZoneId]: ZoneConfig }
		return ZoneConfigurations
	end,
}

return ZoneLootTables
