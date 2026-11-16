--!strict
-- WorldBuilder.luau
-- Authoritative coordinator for all 5 world regions inside Workspace.RelicRushWorld:
-- 1. Forgotten Market (Hub & Base District)
-- 2. Empire District (Imperial Roman/Gothic Citadel)
-- 3. Whispering Wilds (Ancient Overgrown Wilderness)
-- 4. Obsidian Outpost (Fortress & Multi-Route Heist)
-- 5. Hollow Realm (Supernatural Late-Game Void Dimension)
-- Coordinates lighting, models, security devices, regional gateways, and exploration prompts.

local Workspace = game:GetService("Workspace")
local LightingConfig = require(script.Parent.LightingConfig)
local MarketBuilder = require(script.Parent.MarketBuilder)
local EmpireDistrictBuilder = require(script.Parent.EmpireDistrictBuilder)
local WhisperingWildsBuilder = require(script.Parent.WhisperingWildsBuilder)
local OutpostHeistBuilder = require(script.Parent.OutpostHeistBuilder)
local HollowRealmBuilder = require(script.Parent.HollowRealmBuilder)

local WorldBuilder = {}

local WORLD_CONTAINER_NAME = "RelicRushWorld"

function WorldBuilder.Build(heistService: any, explorationService: any?, regionService: any?, interactionService: any?, dungeonCombatService: any?)
	-- 1. Apply Global Dark Fantasy Lighting & Post-Processing
	LightingConfig.Apply()

	-- 1B. Neutralize default Baseplate and disable any template SpawnLocations
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("SpawnLocation") and child.Name ~= "MarketSpawn" then
			child.Enabled = false
			pcall(function() child:Destroy() end)
		elseif child.Name == "Baseplate" and child:IsA("BasePart") then
			child.Transparency = 1
			child.CanCollide = false
		end
	end

	-- 1C. Optimize World Streaming Configuration for Mobile & Desktop Performance
	pcall(function()
		Workspace.StreamingEnabled = true
		Workspace.StreamOutBehavior = Enum.StreamOutBehavior.LowMemory
		Workspace.StreamingMinRadius = 128
		Workspace.StreamingTargetRadius = 384
	end)

	-- 2. Ensure isolated container exists; preserve pre-baked world geometry
	local existing = Workspace:FindFirstChild(WORLD_CONTAINER_NAME)
	if not existing then
		existing = Instance.new("Folder")
		existing.Name = WORLD_CONTAINER_NAME
		existing.Parent = Workspace
	end

	local worldFolder = existing :: Folder

	-- 3. Construct Region 1: Forgotten Market Hub & Base District
	print("[WorldBuilder] Constructing Region 1: Atmospheric Forgotten Market Hub & Base District...")
	local market = MarketBuilder.Build(worldFolder)

	-- 4. Construct Region 2 / Zone 3: Ashen Domain (Empire District)
	print("[WorldBuilder] Constructing Zone 3: Ashen Domain (Empire District)...")
	local empire = EmpireDistrictBuilder.Build(worldFolder)
	if not worldFolder:FindFirstChild("AshenDomain") then
		local ashenFolder = Instance.new("Folder")
		ashenFolder.Name = "AshenDomain"
		ashenFolder.Parent = worldFolder
	end

	-- 5. Construct Region 3 / Zone 1: Forgotten Wilds (Whispering Wilds)
	print("[WorldBuilder] Constructing Zone 1: Forgotten Wilds (Whispering Wilds)...")
	local wilds = WhisperingWildsBuilder.Build(worldFolder)
	if not worldFolder:FindFirstChild("ForgottenWilds") then
		local wildsFolder = Instance.new("Folder")
		wildsFolder.Name = "ForgottenWilds"
		wildsFolder.Parent = worldFolder
	end

	-- 6. Construct Region 4 / Zone 2: Sunken Vault (Obsidian Outpost Heist Fortress)
	print("[WorldBuilder] Constructing Zone 2: Sunken Vault (Obsidian Outpost)...")
	local heist = OutpostHeistBuilder.Build(worldFolder, heistService)
	if not worldFolder:FindFirstChild("SunkenVault") then
		local vaultFolder = Instance.new("Folder")
		vaultFolder.Name = "SunkenVault"
		vaultFolder.Parent = worldFolder
	end

	-- 7. Construct Region 5 / Zone 4: Celestial Rift (Hollow Realm Void Dimension)
	print("[WorldBuilder] Constructing Zone 4: Celestial Rift (Hollow Realm)...")
	local hollow = HollowRealmBuilder.Build(worldFolder)
	if not worldFolder:FindFirstChild("CelestialRift") then
		local celestialFolder = Instance.new("Folder")
		celestialFolder.Name = "CelestialRift"
		celestialFolder.Parent = worldFolder
	end

	-- 8. Connect ProximityPrompts for Heist Interactions
	local chaliceModel = heist:FindFirstChild("Relic_ObsidianChalice_Model")
	if chaliceModel then
		local prompt = chaliceModel:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			prompt.Triggered:Connect(function(player)
				heistService.InteractObjective(player)
			end)
		end
	end

	local exitAlpha = heist:FindFirstChild("ExitPad_Alpha")
	if exitAlpha then
		local prompt = exitAlpha:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				heistService.ExtractHeist(player, "exit_alpha")
			end)
		end
	end

	local exitBeta = heist:FindFirstChild("ExitPad_Beta")
	if exitBeta then
		local prompt = exitBeta:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				heistService.ExtractHeist(player, "exit_beta")
			end)
		end
	end

	local exitGamma = heist:FindFirstChild("ExitPad_Gamma")
	if exitGamma then
		local prompt = exitGamma:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				heistService.ExtractHeist(player, "exit_gamma")
			end)
		end
	end

	-- Connect Security Terminal
	local secDesk = heist:FindFirstChild("SecurityConsoleDesk")
	if secDesk then
		local prompt = secDesk:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				heistService.HackSecurityTerminal(player)
			end)
		end
	end

	-- 9. Connect Exploration Prompts Across All Regions
	if explorationService then
		-- Region 1 Lore & Urns
		local loreStele = market:FindFirstChild("AncientLoreStele")
		if loreStele then
			local prompt = loreStele:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.ReadLoreStele(player, "stele_chronicles")
				end)
			end
		end

		for i = 1, 3 do
			local urn = market:FindFirstChild("TreasureUrn_" .. tostring(i))
			if urn then
				local prompt = urn:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Triggered:Connect(function(player)
						explorationService.LootTreasureUrn(player, i)
					end)
				end
			end
		end

		-- Region 2 Empire Annals & Tribute Chest
		local annalsStele = empire:FindFirstChild("ImperialAnnalsStele")
		if annalsStele then
			local prompt = annalsStele:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.ReadLoreStele(player, "stele_empire_annals")
				end)
			end
		end

		local tributeChest = empire:FindFirstChild("ImperialTributeChest")
		if tributeChest then
			local prompt = tributeChest:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.LootRegionalCache(player, "cache_empire_tribute")
				end)
			end
		end

		local cryptPlinth = empire:FindFirstChild("CryptRelicPlinth")
		if cryptPlinth then
			local prompt = cryptPlinth:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.LootCryptPlinth(player)
				end)
			end
		end

		-- Region 3 Wilds Lore, Offering Urn & Hourglass Altar
		local wildsMonolith = wilds:FindFirstChild("WildsLoreMonolith")
		if wildsMonolith then
			local prompt = wildsMonolith:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.ReadLoreStele(player, "stele_wilds_chronicles")
				end)
			end
		end

		local offeringUrn = wilds:FindFirstChild("DruidicOfferingUrn")
		if offeringUrn then
			local prompt = offeringUrn:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.LootRegionalCache(player, "cache_wilds_offering")
				end)
			end
		end

		local sandsAltar = wilds:FindFirstChild("HourglassAltar")
		if sandsAltar then
			local prompt = sandsAltar:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.CommuneHourglassAltar(player)
				end)
			end
		end

		-- Region 5 Hollow Prophecy, Void Essence Cache & Altar of The Hollow Crown
		local prophecyStele = hollow:FindFirstChild("HollowProphecyStele")
		if prophecyStele then
			local prompt = prophecyStele:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.ReadLoreStele(player, "stele_hollow_prophecy")
				end)
			end
		end

		local voidCache = hollow:FindFirstChild("VoidEssenceCache")
		if voidCache then
			local prompt = voidCache:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.LootRegionalCache(player, "cache_hollow_void")
				end)
			end
		end

		local crownAltar = hollow:FindFirstChild("AltarCore")
		if crownAltar then
			local prompt = crownAltar:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					explorationService.CommuneHollowAltar(player)
				end)
			end
		end
	end

	-- 10. Connect Regional Gateway Travel Points
	if regionService then
		-- Travel from Market to Empire District
		local gateEmp = market:FindFirstChild("Gate_EmpireDistrict")
		if gateEmp then
			local prompt = gateEmp:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					regionService.TravelToRegion(player, "EmpireDistrict")
				end)
			end
		end

		-- Travel from Market to Whispering Wilds
		local gateWilds = market:FindFirstChild("Gate_WhisperingWilds")
		if gateWilds then
			local prompt = gateWilds:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					regionService.TravelToRegion(player, "WhisperingWilds")
				end)
			end
		end

		-- Travel from Market to Hollow Realm
		local gateHollow = market:FindFirstChild("Gate_HollowRealm")
		if gateHollow then
			local prompt = gateHollow:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					regionService.TravelToRegion(player, "HollowRealm")
				end)
			end
		end

		-- Travel from Market to Sunken Vault
		local gateVault = market:FindFirstChild("Gate_SunkenVault")
		if gateVault then
			local prompt = gateVault:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					regionService.TravelToRegion(player, "SunkenVault")
				end)
			end
		end

		-- Return Portals from Regions back to Market
		local returnEmp = empire:FindFirstChild("ReturnPad_Market")
		if returnEmp then
			local prompt = returnEmp:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					regionService.TravelToRegion(player, "ForgottenMarket")
				end)
			end
		end

		local returnWilds = wilds:FindFirstChild("WildsPortalVeil")
		if returnWilds then
			local prompt = returnWilds:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					regionService.TravelToRegion(player, "ForgottenMarket")
				end)
			end
		end

		local returnHollow = hollow:FindFirstChild("ReturnPortal_Market")
		if returnHollow then
			local prompt = returnHollow:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					regionService.TravelToRegion(player, "ForgottenMarket")
				end)
			end
		end

		local returnVault = heist:FindFirstChild("ReturnPad_Market")
		if returnVault then
			local prompt = returnVault:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					regionService.TravelToRegion(player, "ForgottenMarket")
				end)
			end
		end
	end

	-- 11. Connect Market Inhabitant Prompts
	if interactionService then
		local valeria = market:FindFirstChild("NPC_AntiquarianValeria")
		if valeria then
			local prompt = valeria:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function(player)
					interactionService.InteractNPC(player, "Valeria")
				end)
			end
		end

		local ignis = market:FindFirstChild("NPC_AlchemistIgnis")
		if ignis then
			local prompt = ignis:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function(player)
					interactionService.InteractNPC(player, "Ignis")
				end)
			end
		end

		local torvald = market:FindFirstChild("NPC_TorvaldBlacksmith")
		if torvald then
			local prompt = torvald:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function(player)
					interactionService.InteractNPC(player, "Torvald")
				end)
			end
		end
	end

	-- 12. Connect Dungeon Puzzles, Boss Combat & Treasure Vaults
	if dungeonCombatService then
		-- Dungeon 1: Sunken Crypt of the Druids (Whispering Wilds)
		local cryptRunes = {
			{ name = "CryptRune_Earth", element = "Earth" },
			{ name = "CryptRune_Water", element = "Water" },
			{ name = "CryptRune_Flora", element = "Flora" },
			{ name = "CryptRune_Sun", element = "Sun" },
		}
		for _, runeInfo in ipairs(cryptRunes) do
			local part = wilds:FindFirstChild(runeInfo.name)
			if part then
				local prompt = part:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Triggered:Connect(function(player)
						dungeonCombatService.InteractPuzzle(player, "Dungeon_Wilds_Crypt", runeInfo.element)
					end)
				end
			end
		end

		local druidBoss = wilds:FindFirstChild("Guardian_DruidGolem_Model")
		if druidBoss then
			local prompt = druidBoss:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function(player)
					dungeonCombatService.PlayerAttack(player, "Guardian_DruidGolem")
				end)
			end
		end

		local druidSarc = wilds:FindFirstChild("DruidSarcophagus")
		if druidSarc then
			local prompt = druidSarc:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					dungeonCombatService.ClaimDungeonTreasure(player, "Dungeon_Wilds_Crypt")
				end)
			end
		end

		-- Dungeon 2: Catacombs of the Praetors (Empire District)
		for plateNum = 1, 3 do
			local plate = empire:FindFirstChild("PressurePlate_" .. tostring(plateNum))
			if plate then
				local prompt = plate:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Triggered:Connect(function(player)
						dungeonCombatService.InteractPuzzle(player, "Dungeon_Ashen_Catacombs", tostring(plateNum))
					end)
				end
			end
		end

		local praetorBoss = empire:FindFirstChild("Guardian_PraetorCenturion_Model")
		if praetorBoss then
			local prompt = praetorBoss:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function(player)
					dungeonCombatService.PlayerAttack(player, "Guardian_PraetorCenturion")
				end)
			end
		end

		local praetorSarc = empire:FindFirstChild("PraetorSarcophagus")
		if praetorSarc then
			local prompt = praetorSarc:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					dungeonCombatService.ClaimDungeonTreasure(player, "Dungeon_Ashen_Catacombs")
				end)
			end
		end

		-- Dungeon 3: Astral Sanctum of the Void (Hollow Realm)
		for plateNum = 1, 4 do
			local plate = hollow:FindFirstChild("AstralLightPlate" .. tostring(plateNum))
			if plate then
				local prompt = plate:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Triggered:Connect(function(player)
						dungeonCombatService.InteractPuzzle(player, "Dungeon_Hollow_Sanctum", tostring(plateNum))
					end)
				end
			end
		end

		local voidBoss = hollow:FindFirstChild("Guardian_VoidSentinel_Model")
		if voidBoss then
			local prompt = voidBoss:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function(player)
					dungeonCombatService.PlayerAttack(player, "Guardian_VoidSentinel")
				end)
			end
		end

		local voidReliquary = hollow:FindFirstChild("SingularityReliquary")
		if voidReliquary then
			local prompt = voidReliquary:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					dungeonCombatService.ClaimDungeonTreasure(player, "Dungeon_Hollow_Sanctum")
				end)
			end
		end
	end

	print("[WorldBuilder] Full 5-Region World Construction Complete! All instances safely isolated inside Workspace.RelicRushWorld.")
end

return WorldBuilder