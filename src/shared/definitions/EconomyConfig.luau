--!strict
-- EconomyConfig.luau
-- Authoritative balancing, prices, and constants for Relic Rush
-- Dark-Fantasy Base-Raiding, 20-Player Server Architecture

export type ShopItem = {
	itemId: string,
	name: string,
	category: "Decoration" | "Defense" | "Upgrade" | "Tool" | "Consumable",
	priceCash: number,
	description: string,
	defenseValue: number?,
}

local ShopCatalog: { [string]: ShopItem } = {
	-- Base Decor & Plinths
	["decor_stone_plinth"] = {
		itemId = "decor_stone_plinth",
		name = "Carved Stone Plinth",
		category = "Decoration",
		priceCash = 30,
		description = "An ornamental marble pedestal for showcasing prized relics in your base.",
	},
	["decor_market_banner"] = {
		itemId = "decor_market_banner",
		name = "Market Guild Banner",
		category = "Decoration",
		priceCash = 25,
		description = "A woven silk banner bearing the insignia of the Forgotten Market.",
	},
	["decor_oak_chest"] = {
		itemId = "decor_oak_chest",
		name = "Iron-Banded Oak Chest",
		category = "Decoration",
		priceCash = 40,
		description = "A sturdy chest for organizing extra salvage and curiosities.",
	},
	["decor_brazier"] = {
		itemId = "decor_brazier",
		name = "Bronze Fire Brazier",
		category = "Decoration",
		priceCash = 35,
		description = "An ornate bronze brazier that casts a warm, atmospheric flame.",
	},
	["decor_gargoyle"] = {
		itemId = "decor_gargoyle",
		name = "Obsidian Gargoyle Sconce",
		category = "Decoration",
		priceCash = 45,
		description = "A menacing carved gargoyle statuette salvaged from ancient ruins.",
	},
	["decor_gold_pedestal"] = {
		itemId = "decor_gold_pedestal",
		name = "Gilded Relic Showcase Pedestal",
		category = "Decoration",
		priceCash = 60,
		description = "A towering gold-leaf pedestal crafted for central trophy exhibitions.",
	},
	["decor_trophy_dais"] = {
		itemId = "decor_trophy_dais",
		name = "Grand Antiquity Dais",
		category = "Decoration",
		priceCash = 80,
		description = "An elevated multi-tiered stone dais commanding authority in your sanctum.",
	},

	-- Base Floors & Customisation
	["floor_obsidian_tiles"] = {
		itemId = "floor_obsidian_tiles",
		name = "Obsidian Paver Tiles",
		category = "Decoration",
		priceCash = 40,
		description = "Polished dark volcanic tiles for opulent base flooring.",
	},
	["floor_marble_mosaic"] = {
		itemId = "floor_marble_mosaic",
		name = "Gilded Marble Mosaic",
		category = "Decoration",
		priceCash = 50,
		description = "Classical marble floor inlay with gold geometric accents.",
	},
	["floor_runic_cobble"] = {
		itemId = "floor_runic_cobble",
		name = "Runic Cobblestone",
		category = "Decoration",
		priceCash = 35,
		description = "Ancient cobblestones etched with faint blue luminescent runes.",
	},

	-- Base Walls, Parapets & Gates
	["wall_granite_parapet"] = {
		itemId = "wall_granite_parapet",
		name = "Granite Bastion Parapet",
		category = "Decoration",
		priceCash = 50,
		description = "A fortified stone parapet providing structural boundary and cover.",
		defenseValue = 5,
	},
	["wall_runic_battlement"] = {
		itemId = "wall_runic_battlement",
		name = "Runic Reinforced Wall",
		category = "Decoration",
		priceCash = 75,
		description = "A massive basalt wall reinforced with protective warding runes.",
		defenseValue = 10,
	},
	["wall_iron_gate"] = {
		itemId = "wall_iron_gate",
		name = "Forged Iron Gateway",
		category = "Decoration",
		priceCash = 60,
		description = "A grand wrought-iron archway demarcating sanctum chambers.",
		defenseValue = 5,
	},

	-- Base Lighting
	["light_soulfire_lantern"] = {
		itemId = "light_soulfire_lantern",
		name = "Soulfire Hanging Lantern",
		category = "Decoration",
		priceCash = 30,
		description = "A suspended iron lantern burning with eternal cyan soulflame.",
	},
	["light_crystal_sconce"] = {
		itemId = "light_crystal_sconce",
		name = "Celestial Crystal Sconce",
		category = "Decoration",
		priceCash = 45,
		description = "A wall sconce holding an astral crystal that emits radiant violet light.",
	},

	-- Base Defenses for Raiding Security
	["defense_runic_ward"] = {
		itemId = "defense_runic_ward",
		name = "Abyssal Runic Ward",
		category = "Defense",
		priceCash = 120,
		description = "Emits a protective field that reduces enemy raid siphon yield by 15%.",
		defenseValue = 15,
	},
	["defense_sentry_totem"] = {
		itemId = "defense_sentry_totem",
		name = "Arcane Sentry Totem",
		category = "Defense",
		priceCash = 200,
		description = "Alarms intruder presence and shortens raid escape timer by 10 seconds.",
		defenseValue = 25,
	},
	["defense_decoy_coffer"] = {
		itemId = "defense_decoy_coffer",
		name = "Gilded Decoy Coffer",
		category = "Defense",
		priceCash = 150,
		description = "Distracts raiders, giving a 30% chance to trigger an immediate alarm.",
		defenseValue = 20,
	},

	-- Tools & Infiltration
	["tool_smoke_capsule"] = {
		itemId = "tool_smoke_capsule",
		name = "Alchemical Smoke Capsule",
		category = "Tool",
		priceCash = 35,
		description = "Deploys a brief obscuring cloud to suppress laser alarms and sentry vision.",
	},
	["tool_lockpick_wire"] = {
		itemId = "tool_lockpick_wire",
		name = "Bypass Wire Set",
		category = "Tool",
		priceCash = 35,
		description = "Enables faster interaction when cracking vault locks or raiding coffers.",
	},
	["consumable_health_elixir"] = {
		itemId = "consumable_health_elixir",
		name = "Vitality Elixir",
		category = "Consumable",
		priceCash = 20,
		description = "Restores 50 health points when consumed.",
	},
}

-- 20 Player Plot Layout in Base District
-- Spaced along East Grand Sanctum Boulevard with 60x60 stud plots, 350-stud column spacing and 400-stud row spacing
local PLOT_COORDINATES: { Vector3 } = {}
local colX = { 600, 950, 1300, 1650, 2000 }
local rowZ = { 600, 200, -200, -600 }

for _, z in ipairs(rowZ) do
	for _, x in ipairs(colX) do
		table.insert(PLOT_COORDINATES, Vector3.new(x, 12, z))
	end
end

local EconomyConfig = {
	-- Core Player Parameters
	MAX_PLAYERS_PER_SERVER = 20,
	STARTING_CASH = 500,           -- Specification: Starting cash: $500
	STARTING_SHARDS = 0,
	BASE_RELIC_SLOTS = 10,         -- Specification: Each player's base starts with 10 relic slots
	MAX_INVENTORY_CAPACITY = 25,

	-- Passive Income Loop
	INCOME_TICK_SECONDS = 10,      -- Generates income every 10 seconds
	MAX_OFFLINE_INCOME_HOURS = 6,  -- Specification: Limited offline income (capped at 6 hours)
	OFFLINE_INCOME_EFFICIENCY = 0.65, -- 65% efficiency for offline earnings to encourage active play

	-- Base Raiding: Low-Risk Security Parameters
	-- Stealing must be low-risk and must NOT cause players to lose hours of progress or permanent relics
	RAID_SIPHON_PERCENTAGE = 0.25, -- Raiders siphon max 25% of uncollected coffer tribute
	RAID_MIN_BOUNTY_CASH = 50,     -- System-funded minimum reward so raider gets paid even if coffer is empty
	RAID_MIN_BOUNTY_SHARDS = 5,    -- System-funded shard bounty
	RAID_TIME_LIMIT_SECONDS = 45,  -- 45-second infiltration window
	RAID_COOLDOWN_SECONDS = 180,   -- 3-minute cooldown between raiding the same target

	-- Base Upgrades & Placement Limits
	BASE_UPGRADE_TIER_2_COST = 250,
	BASE_UPGRADE_TIER_3_COST = 600,
	BASE_PLOT_HALF_SIZE = 30,      -- 60x60 studs usable base plot (generous spacing & zero label overlap)
	MAX_PLACED_OBJECTS_PER_BASE = 15, -- Authoritative cap on placed customisation objects per plot
	PLOT_COUNT = 20,
	PLOT_COORDINATES = PLOT_COORDINATES,

	-- Architectural Base Themes (Cosmetic only, no pay-to-win advantage)
	BaseThemes = {
		["GothicFortress"] = {
			id = "GothicFortress",
			name = "Gothic Fortress",
			floorMaterial = Enum.Material.Slate,
			floorColor = Color3.fromRGB(45, 45, 52),
			trimColor = Color3.fromRGB(30, 30, 36),
			pillarColor = Color3.fromRGB(60, 58, 64),
			accentColor = Color3.fromRGB(180, 140, 60),
			description = "Towering dark slate talus, iron crenellations, and gargoyle corbels.",
		},
		["ImperialSanctum"] = {
			id = "ImperialSanctum",
			name = "Imperial Sanctum",
			floorMaterial = Enum.Material.Marble,
			floorColor = Color3.fromRGB(220, 215, 205),
			trimColor = Color3.fromRGB(180, 150, 65),
			pillarColor = Color3.fromRGB(240, 238, 232),
			accentColor = Color3.fromRGB(255, 215, 0),
			description = "Fluted marble pillars, gilded pediment, and imperial laurel friezes.",
		},
		["ForestSanctuary"] = {
			id = "ForestSanctuary",
			name = "Ancient Forest Sanctuary",
			floorMaterial = Enum.Material.WoodPlanks,
			floorColor = Color3.fromRGB(85, 60, 38),
			trimColor = Color3.fromRGB(50, 75, 45),
			pillarColor = Color3.fromRGB(45, 32, 22),
			accentColor = Color3.fromRGB(76, 215, 80),
			description = "Ironwood timbers, mossy overgrown stone, and verdant spore vines.",
		},
		["ObsidianCitadel"] = {
			id = "ObsidianCitadel",
			name = "Obsidian Citadel",
			floorMaterial = Enum.Material.Basalt,
			floorColor = Color3.fromRGB(24, 22, 28),
			trimColor = Color3.fromRGB(180, 50, 30),
			pillarColor = Color3.fromRGB(35, 30, 42),
			accentColor = Color3.fromRGB(255, 90, 30),
			description = "Blackened basalt plates, volcanic runic inlays, and smoldering braziers.",
		},
		["CelestialPalace"] = {
			id = "CelestialPalace",
			name = "Celestial Palace",
			floorMaterial = Enum.Material.Marble,
			floorColor = Color3.fromRGB(30, 24, 40),
			trimColor = Color3.fromRGB(156, 39, 176),
			pillarColor = Color3.fromRGB(48, 38, 62),
			accentColor = Color3.fromRGB(186, 104, 200),
			description = "Astral obsidian, levitating amethyst pylons, and starlight halos.",
		},
		["LuxuryEstate"] = {
			id = "LuxuryEstate",
			name = "Luxury Merchant Estate",
			floorMaterial = Enum.Material.WoodPlanks,
			floorColor = Color3.fromRGB(110, 72, 42),
			trimColor = Color3.fromRGB(220, 180, 50),
			pillarColor = Color3.fromRGB(75, 52, 34),
			accentColor = Color3.fromRGB(255, 225, 100),
			description = "Polished mahogany, gilded coin trims, and scalloped velvet awnings.",
		},
	},

	-- Zone Unlock Requirements (Permanent progression combined with rotating treasure)
	ZONE_UNLOCK_COSTS = {
		["ForgottenWilds"] = 0,       -- Starter Zone (Free)
		["SunkenVault"] = 350,        -- Tier 2 Zone
		["AshenDomain"] = 800,        -- Tier 3 Zone
		["CelestialRift"] = 1800,     -- Tier 4 Endgame Zone
	},

	-- Optional Rebirth System
	REBIRTH_MIN_CASH = 2500,
	REBIRTH_RELIC_REQUIREMENT = 8, -- Must have at least 8 unique relics discovered
	REBIRTH_PRESTIGE_BONUS = 0.25, -- +25% permanent income per rebirth

	ShopCatalog = ShopCatalog,

	-- Purely Cosmetic Vanity Catalog (NO Pay-to-Win stat boosts)
	CosmeticCatalog = {
		["cosmetic_trim_gilded_obsidian"] = {
			itemId = "cosmetic_trim_gilded_obsidian",
			name = "Gilded Obsidian Plinth Trim",
			category = "PedestalTrim",
			priceShards = 120,
			priceCash = 600,
			description = "Adorns your 10 sanctum plinths with gold-inlaid obsidian filigree borders. Pure cosmetic prestige.",
			cosmeticTag = "GildedObsidian",
		},
		["cosmetic_aura_abyssal_void"] = {
			itemId = "cosmetic_aura_abyssal_void",
			name = "Voidwalker Ethereal Mist Aura",
			category = "Aura",
			priceShards = 250,
			priceCash = 1200,
			description = "A swirling cosmic violet mist aura that surrounds your character. Purely visual prestige effect.",
			cosmeticTag = "VoidAura",
		},
		["cosmetic_floor_astral_mosaic"] = {
			itemId = "cosmetic_floor_astral_mosaic",
			name = "Celestial Constellation Tiles",
			category = "Skin",
			priceShards = 180,
			priceCash = 850,
			description = "Transforms your base sanctum floor into reflective starry constellation stone. Zero stat boost, 100% style.",
			cosmeticTag = "AstralMosaic",
		},
		["cosmetic_title_archaeologist"] = {
			itemId = "cosmetic_title_archaeologist",
			name = "Title: Grand Antiquarian",
			category = "Title",
			priceShards = 100,
			priceCash = 500,
			description = "Unlocks the exclusive golden title badge [Grand Antiquarian] above your name.",
			cosmeticTag = "TitleGrandAntiquarian",
		},
	},

	GetItem = function(itemId: string): ShopItem?
		return ShopCatalog[itemId]
	end,
}

return EconomyConfig
