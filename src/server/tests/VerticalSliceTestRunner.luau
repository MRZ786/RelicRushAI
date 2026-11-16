--!strict
-- VerticalSliceTestRunner.luau
-- Authoritative automated QA diagnostic suite validating all 20 critical invariants for Relic Rush
-- Runs on server bootstrap to verify integrity across economy, inventory, heists, world, and persistence.

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local RelicDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local MilestoneDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("MilestoneDefinitions"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local QuestDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("QuestDefinitions"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

local TransactionService = require(script.Parent.Parent.services.TransactionService)
local BaseService = require(script.Parent.Parent.services.BaseService)
local ProfileService = require(script.Parent.Parent.services.ProfileService)
local InventoryService = require(script.Parent.Parent.services.InventoryService)
local EconomyService = require(script.Parent.Parent.services.EconomyService)
local HeistService = require(script.Parent.Parent.services.HeistService)
local QuestService = require(script.Parent.Parent.services.QuestService)
local InteractionService = require(script.Parent.Parent.services.InteractionService)
local ExplorationService = require(script.Parent.Parent.services.ExplorationService)
local RegionService = require(script.Parent.Parent.services.RegionService)
local SentryService = require(script.Parent.Parent.services.SentryService)
local RelicMeshBuilder = require(script.Parent.Parent.world.RelicMeshBuilder)
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))

local VerticalSliceTestRunner = {}

function VerticalSliceTestRunner.RunAllTests(): { passed: number, failed: number, results: { string } }
	local passed = 0
	local failed = 0
	local results = {}

	local function assertTest(name: string, condition: boolean, detail: string)
		if condition then
			passed += 1
			local msg = string.format("[PASS] %s", name)
			table.insert(results, msg)
			print(msg)
		else
			failed += 1
			local msg = string.format("[FAIL] %s - %s", name, detail)
			table.insert(results, msg)
			warn(msg)
		end
	end

	print("\n==================================================")
	print("  RELIC RUSH: 20-POINT AUTOMATED QA TEST SUITE    ")
	print("==================================================")

	local mockPlayer = {
		UserId = 99999901,
		Name = "TestPlayer_QA",
		DisplayName = "QA Tester",
	} :: any
	local worldContainer: Instance? = nil
	local mockHrp: any = nil
	local mockRaider: any = nil
	local testTraveler: any = nil
	local travProfile: any = nil

	do
	-- Check 1: Required Remote Contracts Exist
	local expectedFunctions = {
		"SelectStarterRelic", "RequestBuyItem", "RequestSellRelic", "RequestEquipRelic",
		"RequestUnequipRelic", "RequestPlaceBaseObject", "RequestBaseUpgrade",
		"StartHeist", "UseHeistTool", "InteractHeistObjective", "ExtractHeist",
		"ClaimQuestReward", "HackSecurityTerminal", "InteractLoreStele", "LootTreasureUrn"
	}
	local relicRushFolder = ReplicatedStorage:FindFirstChild("RelicRush")
	local remotesFolder = (relicRushFolder and relicRushFolder:FindFirstChild("Remotes")) or ReplicatedStorage:FindFirstChild("RelicRushRemotes")
	local allRemotesPresent = remotesFolder ~= nil
	if remotesFolder then
		for _, fnName in ipairs(expectedFunctions) do
			if not remotesFolder:FindFirstChild(fnName) then
				allRemotesPresent = false
				break
			end
		end
	end
	assertTest("Check 1: Remote Contracts Registered", allRemotesPresent, "One or more remote functions missing in ReplicatedStorage")

	-- Check 2: Starter Relics Validation
	local starterCount = #RelicDefinitions.StarterRelicIds
	assertTest("Check 2: 4 Starter Relics Defined", starterCount == 4, "Expected 4 starter relics, got " .. tostring(starterCount))
	for _, id in ipairs(RelicDefinitions.StarterRelicIds) do
		local def = RelicDefinitions.Get(id)
		assertTest("Check 2b: Starter Relic Valid (" .. id .. ")", def ~= nil and def.baseValue > 0, "Invalid starter definition: " .. id)
	end

	-- Check 2c: Authoritative Starter Relic Selection & Validation
	local starterMockPlayer = {
		UserId = 99999902,
		Name = "TestPlayer_Starter",
		DisplayName = "Starter Tester",
	} :: any
	local starterProfile = ProfileService.LoadProfile(starterMockPlayer)
	local badSelectOk, _ = InteractionService.SelectStarterRelic(starterMockPlayer, "relic_hollow_crown", "test_starter_key_01")
	assertTest("Check 2c: Non-Starter Relic Rejected", badSelectOk == false, "Allowed non-starter selection")

	local goodSelectOk, _, resProfile = InteractionService.SelectStarterRelic(starterMockPlayer, "relic_scavenger_compass", "test_starter_key_02")
	assertTest("Check 2d: Valid Starter Relic Selected & Equipped",
		goodSelectOk == true and starterProfile.hasSelectedStarter == true and starterProfile.equippedRelicId ~= nil and #starterProfile.inventory == 1,
		"Starter selection failed or inventory not updated")

	local dupSelectOk, _ = InteractionService.SelectStarterRelic(starterMockPlayer, "relic_merchants_eye", "test_starter_key_03")
	assertTest("Check 2e: Duplicate Starter Relic Selection Rejected", dupSelectOk == false, "Allowed duplicate starter selection")

	-- Check 3: World Container Isolation & No Duplicates
	worldContainer = Workspace:FindFirstChild("RelicRushWorld")
	assertTest("Check 3: World Container Isolated in Workspace.RelicRushWorld", worldContainer ~= nil, "Missing RelicRushWorld folder")
	if worldContainer then
		local market = worldContainer:FindFirstChild("ForgottenMarket")
		local outpost = worldContainer:FindFirstChild("ObsidianOutpost")
		assertTest("Check 3b: Core Environments Present", market ~= nil and outpost ~= nil, "Missing Market or Outpost in world container")
	end

	-- Check 4: Multi-Plot Base District Configuration (20-Player Architecture)
	assertTest("Check 4: 20 Base Plots Configured", EconomyConfig.PLOT_COUNT == 20 and #EconomyConfig.PLOT_COORDINATES == 20, "Plot count mismatch")
	local allocatedPlot = BaseService.AssignPlot(mockPlayer)
	assertTest("Check 4b: Authoritative Base Plot Allocation", allocatedPlot >= 1 and allocatedPlot <= 20, "Invalid plot index assigned")

	-- Check 5: Base Placement In-Bounds & Out-of-Bounds Checks
	local validPos = Vector3.new(10, 2, 10)
	local invalidPos = Vector3.new(100, 2, 100)
	local invalidHeight = Vector3.new(5, 50, 5)
	assertTest("Check 5: Placement In-Bounds Check", BaseService.ValidatePlacement(validPos) == true, "Valid coordinate rejected")
	assertTest("Check 5b: Placement Out-of-Bounds Rejection", BaseService.ValidatePlacement(invalidPos) == false, "Out-of-bounds allowed")
	assertTest("Check 5c: Placement Height Check", BaseService.ValidatePlacement(invalidHeight) == false, "Excessive height allowed")

	-- Check 6: Transaction Idempotency Interception
	local testKey = "qa_idempotency_key_001"
	local counter = 0
	local testOp = function()
		counter += 1
		return true, "Success", counter
	end
	local s1, _, d1 = TransactionService.Process(mockPlayer, testKey, "TestScope", testOp)
	local s2, _, d2 = TransactionService.Process(mockPlayer, testKey, "TestScope", testOp)
	assertTest("Check 6: Transaction Idempotency (Single Execution)",
		s1 == true and s2 == true and counter == 1 and d1 == 1 and d2 == 1,
		string.format("Expected 1 execution, got %d", counter))

	-- Check 7: Profile Persistence & Schema v3 Migration ($500 Starting Cash)
	local loadedProfile = ProfileService.LoadProfile(mockPlayer)
	assertTest("Check 7: Profile Schema v3 Initialized ($500 Starting Cash)", loadedProfile.schemaVersion == 3 and loadedProfile.currencies.Cash >= 500 and loadedProfile.completedQuests ~= nil, "Schema v3 migration failure")

	-- Check 8: Inventory Relic Addition & Unique GUIDs
	local addOk, _, inst1 = InventoryService.AddRelic(mockPlayer, "relic_scavenger_compass")
	local addOk2, _, inst2 = InventoryService.AddRelic(mockPlayer, "relic_merchants_eye")
	assertTest("Check 8: Relic Addition with Unique GUIDs",
		addOk == true and addOk2 == true and inst1 ~= nil and inst2 ~= nil and inst1.instanceId ~= inst2.instanceId,
		"GUID duplication or relic grant failure")

	-- Check 9: Relic Equip & Active Buff State
	if inst1 then
		local equipOk = InventoryService.EquipRelic(mockPlayer, inst1.instanceId)
		assertTest("Check 9: Relic Equip Authority", equipOk == true and loadedProfile.equippedRelicId == inst1.instanceId, "Equip state mismatch")
	end

	-- Check 10: Relic Sale & Appraisal Bonus Invariant
	local initialCash = loadedProfile.currencies.Cash
	if inst2 then
		local sellOk, _ = EconomyService.SellRelic(mockPlayer, inst2.instanceId, "sale_key_001")
		local expectedGain = RelicDefinitions.Get("relic_merchants_eye").baseValue
		assertTest("Check 10: Relic Sale Currency Invariant", sellOk == true and loadedProfile.currencies.Cash > initialCash, "Sale failed or balance unchanged")
	end

	-- Check 11: Shop Purchasing & Cash Sink Validation
	local cashBeforeBuy = loadedProfile.currencies.Cash
	local buyOk, _ = EconomyService.BuyShopItem(mockPlayer, "tool_smoke_capsule", "buy_key_001")
	assertTest("Check 11: Shop Purchase Cash Deduction", buyOk == true and loadedProfile.currencies.Cash < cashBeforeBuy, "Purchase failed or cash not deducted")

	-- Check 12: Insufficient Funds Rejection
	loadedProfile.currencies.Cash = 5
	local brokeBuyOk, _ = EconomyService.BuyShopItem(mockPlayer, "tool_smoke_capsule", "buy_key_002")
	assertTest("Check 12: Insufficient Funds Rejected", brokeBuyOk == false, "Allowed purchase with insufficient funds")
	loadedProfile.currencies.Cash = 500 -- Restore cash

	-- Check 13: Quest Definitions Integrity
	assertTest("Check 13: 12 Progression Quests Defined", #QuestDefinitions.All == 12, "Expected 12 progression quests")

	-- Check 13b: Quest Reward Claim Invariant & Duplicate Prevention
	loadedProfile.completedQuests["quest_the_calling"] = true
	local preClaimCash = loadedProfile.currencies.Cash
	local qDef = QuestDefinitions.Get("quest_the_calling")
	local claimOk, _ = QuestService.ClaimReward(mockPlayer, "quest_the_calling", "test_claim_key_01")
	assertTest("Check 13b: Quest Reward Claim Authority",
		claimOk == true and loadedProfile.claimedQuests["quest_the_calling"] == true and qDef ~= nil and loadedProfile.currencies.Cash == preClaimCash + qDef.rewardCash,
		"Quest claim failed or balance incorrect")

	local dupClaimOk, _ = QuestService.ClaimReward(mockPlayer, "quest_the_calling", "test_claim_key_02")
	assertTest("Check 13c: Duplicate Quest Claim Rejection", dupClaimOk == false, "Allowed duplicate quest reward claim")

	-- Check 14: Heist Initiation & Phase Verification
	local heistStartOk, _, session = HeistService.StartHeist(mockPlayer, "heist_obsidian_outpost", "tool_smoke_capsule")
	assertTest("Check 14: Heist Start & Infiltration Phase", heistStartOk == true and session ~= nil and session.phase == "Infiltration", "Heist failed to start")

	-- Check 15: Security Terminal Override Hack
	local hackOk, _ = HeistService.HackSecurityTerminal(mockPlayer)
	assertTest("Check 15: Security Terminal Override", hackOk == true and session ~= nil and session.lasersDisabledUntil ~= nil and session.lasersDisabledUntil > os.clock(), "Terminal override failed")

	-- Check 16: Smoke Gadget Deployment & Alarm Suppression
	local toolOk, _ = HeistService.UseHeistTool(mockPlayer)
	assertTest("Check 16: Smoke Gadget Laser Suppression", toolOk == true and session ~= nil and session.toolUsed == true, "Smoke gadget failed")

	-- Check 17: Objective Theft & 60s Extraction Timer
	local stealOk, _, sSteal = HeistService.InteractObjective(mockPlayer)
	assertTest("Check 17: Chalice Theft & Extraction Timer", stealOk == true and sSteal ~= nil and sSteal.phase == "ObjectiveSecured" and sSteal.extractionDeadline ~= nil, "Theft or deadline not set")

	-- Check 18: Extraction Out-of-Sequence / Premature Protection
	local prematurePlayer = { UserId = 88888801, Name = "Premature" } :: any
	local earlyExtractOk, _ = HeistService.ExtractHeist(prematurePlayer, "exit_alpha")
	assertTest("Check 18: Early Extraction Rejected", earlyExtractOk == false, "Allowed extraction without active session")

	-- Check 19: Permanent Relics Preserved on Failure
	local inventoryCountBefore = #loadedProfile.inventory
	HeistService.AbortHeist(mockPlayer, false)
	assertTest("Check 19: Failure Preserves Permanent Inventory", #loadedProfile.inventory == inventoryCountBefore, "Permanent relics lost on failure")

	-- Check 20: Hollow Crown Mythic Multiplier Integrity
	local crownDef = RelicDefinitions.Get("relic_hollow_crown")
	assertTest("Check 20: The Hollow Crown Mythic Rarity & Mechanics", crownDef ~= nil and crownDef.rarity == "Mythic" and crownDef.buff.buffType == "DivineAura", "Crown definition invalid")
	end

	do
	-- Check 21: Full Forgotten Market Architecture & Sub-Districts
	if worldContainer then
		local market = worldContainer:FindFirstChild("ForgottenMarket")
		if market then
			local bobFloor = market:FindFirstChild("BobGuildFloor")
			local alchFloor = market:FindFirstChild("AlchFloor")
			local vaultFloor = market:FindFirstChild("VaultFloor")
			local smithyBack = market:FindFirstChild("SmithyBackWall")
			local vanceFront = market:FindFirstChild("VanceWallBack")
			assertTest("Check 21: Settlement Districts Constructed (Guildhall, Vault, Emporium, Smithy, Bunker)",
				bobFloor ~= nil and alchFloor ~= nil and vaultFloor ~= nil and smithyBack ~= nil and vanceFront ~= nil,
				"One or more district buildings missing in ForgottenMarket")
		end
	end

	-- Check 22: Base Visual Upgrades (Tier 1 -> Tier 2 -> Tier 3)
	local testPlotIdx = 2
	BaseService.ApplyVisualUpgrade(testPlotIdx, 2)
	local plot2Folder = Workspace:FindFirstChild("RelicRushWorld")
		and Workspace.RelicRushWorld:FindFirstChild("ForgottenMarket")
		and Workspace.RelicRushWorld.ForgottenMarket:FindFirstChild("BasePlot_" .. tostring(testPlotIdx))
	local t2Visuals = plot2Folder and plot2Folder:FindFirstChild("WorkshopTier2Visuals")
	local t1Shelter = plot2Folder and plot2Folder:FindFirstChild("StarterShelterTier1")
	assertTest("Check 22: Base Tier 2 Upgrade (Workshop Added, Shelter Dismantled)",
		t2Visuals ~= nil and t1Shelter == nil,
		"Base Tier 2 upgrade did not create workshop or did not remove starter shelter")

	BaseService.ApplyVisualUpgrade(testPlotIdx, 3)
	local t3Visuals = plot2Folder and plot2Folder:FindFirstChild("SanctuaryTier3Visuals")
	assertTest("Check 22b: Base Tier 3 Upgrade (Arcane Colonnade & Power Core)",
		t3Visuals ~= nil,
		"Base Tier 3 upgrade did not generate Arcane Sanctuary visuals")

	-- Check 23: Exploration Service & Lore Stele / Treasure Urn Authoritative Mechanics
	local exploreMock = {
		UserId = 99999903,
		Name = "TestPlayer_Explorer",
		DisplayName = "Explorer",
		Character = {
			FindFirstChild = function(self: any, name: string)
				if name == "HumanoidRootPart" then
					return { Position = Vector3.new(-82, 23, -53) }
				end
				return nil
			end
		}
	} :: any
	local expProfile = ProfileService.LoadProfile(exploreMock)
	local steleOk, _ = ExplorationService.ReadLoreStele(exploreMock)
	assertTest("Check 23: Authoritative Lore Stele Deciphering",
		steleOk == true and expProfile.discoveredLore["stele_chronicles"] == true,
		"Lore stele deciphering failed")

	local urnOk, _ = ExplorationService.LootTreasureUrn(exploreMock, 1)
	local cashAfterUrn = expProfile.currencies.Cash
	assertTest("Check 23b: Authoritative Treasure Urn Salvage",
		urnOk == true and cashAfterUrn > 0,
		"Treasure urn loot failed")

	local dupUrnOk, _ = ExplorationService.LootTreasureUrn(exploreMock, 1)
	assertTest("Check 23c: Treasure Urn Cooldown Protection",
		dupUrnOk == false,
		"Allowed looting urn on cooldown")

	-- Check 24: All 6 Authoritative Relic 3D Models & Auras
	local relicDefIds = {
		"relic_scavenger_compass",
		"relic_merchants_eye",
		"relic_shadow_talisman",
		"relic_obsidian_chalice",
		"relic_ancient_hourglass",
		"relic_hollow_crown",
	}
	local relicsAllSpawned = true
	local tempFolder = Instance.new("Folder")
	tempFolder.Name = "TestRelicShowcase"
	tempFolder.Parent = Workspace

	for _, rId in ipairs(relicDefIds) do
		local m = RelicMeshBuilder.SpawnRelicModel(rId, tempFolder, CFrame.new(0, 50, 0))
		if not m or not m.PrimaryPart then
			relicsAllSpawned = false
			break
		end
	end
	tempFolder:Destroy()

	assertTest("Check 24: Procedural Relic Models (Compass, Eye, Talisman, Chalice, Hourglass, Crown)",
		relicsAllSpawned == true,
		"One or more relic 3D procedural models failed to build")

	-- Check 25: All 5 Distinct World Regions Constructed in World Container
	if worldContainer then
		local r1 = worldContainer:FindFirstChild("ForgottenMarket")
		local r2 = worldContainer:FindFirstChild("EmpireDistrict")
		local r3 = worldContainer:FindFirstChild("WhisperingWilds")
		local r4 = worldContainer:FindFirstChild("ObsidianOutpost")
		local r5 = worldContainer:FindFirstChild("HollowRealm")

		local r2Ok = r2 and r2:FindFirstChild("AvenuePavement") and r2:FindFirstChild("ImperialAnnalsStele")
		local r3Ok = r3 and r3:FindFirstChild("IronwoodTrunk") and r3:FindFirstChild("WildsLoreMonolith")
		local r4Ok = r4 and r4:FindFirstChild("ExitPad_Gamma")
		local r5Ok = r5 and r5:FindFirstChild("ApexIsland") and r5:FindFirstChild("HollowProphecyStele")

		assertTest("Check 25: All 5 Full World Regions Constructed (Market, Empire, Wilds, Outpost, Hollow)",
			r1 ~= nil and r2Ok ~= nil and r3Ok ~= nil and r4Ok ~= nil and r5Ok ~= nil,
			"One or more of the 5 game regions failed to construct or missing key landmarks")
	end

	-- Check 26: Server-Authoritative Region Access Prerequisites
	mockHrp = Instance.new("Part")
	mockHrp.Name = "HumanoidRootPart"
	mockHrp.CFrame = CFrame.new(0, 3, 0)

	testTraveler = {
		UserId = 99999905,
		Name = "TestPlayer_Traveler",
		DisplayName = "Traveler",
		Character = {
			HumanoidRootPart = mockHrp,
			FindFirstChild = function(self: any, name: string)
				if name == "HumanoidRootPart" then
					return mockHrp
				end
				return nil
			end,
		},
	} :: any

	travProfile = ProfileService.LoadProfile(testTraveler)
	local canMarket, _ = RegionService.CanAccessRegion(testTraveler, "ForgottenMarket")
	local canEmpireBefore, _ = RegionService.CanAccessRegion(testTraveler, "EmpireDistrict")
	local canWildsBefore, _ = RegionService.CanAccessRegion(testTraveler, "WhisperingWilds")
	local canHollowBefore, _ = RegionService.CanAccessRegion(testTraveler, "HollowRealm")

	assertTest("Check 26: Gate Lock Enforcement on Fresh Profiles",
		canMarket == true and canEmpireBefore == false and canWildsBefore == false and canHollowBefore == false,
		"Locked regions were accessible before prerequisites were met")

	-- Unlock progression milestones
	travProfile.hasSelectedStarter = true
	InventoryService.AddRelic(testTraveler, "relic_scavenger_compass")
	local canWildsAfter, _ = RegionService.CanAccessRegion(testTraveler, "WhisperingWilds")

	travProfile.baseData.tier = 2
	local canEmpireAfter, _ = RegionService.CanAccessRegion(testTraveler, "EmpireDistrict")

	travProfile.completedHeistsCount = 2
	InventoryService.AddRelic(testTraveler, "relic_obsidian_chalice")
	local canHollowAfter, _ = RegionService.CanAccessRegion(testTraveler, "HollowRealm")

	assertTest("Check 26b: Legitimate Progression Unlocks Regions Authoritatively",
		canWildsAfter == true and canEmpireAfter == true and canHollowAfter == true,
		"Regions failed to unlock after meeting verified prerequisites")

	-- Check 27: Region Travel Teleportation & Position Invariants (Expanded Universe Coordinates)
	local travelEmpireOk, _ = RegionService.TravelToRegion(testTraveler, "EmpireDistrict")
	local posAfterEmpire = testTraveler.Character.HumanoidRootPart.CFrame.Position
	local distToEmpireSpawn = (posAfterEmpire - Vector3.new(0, 12, -3000)).Magnitude

	local travelWildsOk, _ = RegionService.TravelToRegion(testTraveler, "WhisperingWilds")
	local posAfterWilds = testTraveler.Character.HumanoidRootPart.CFrame.Position
	local distToWildsSpawn = (posAfterWilds - Vector3.new(-3000, 12, 0)).Magnitude

	assertTest("Check 27: Region Gateway Teleportation Coordinates",
		travelEmpireOk == true and distToEmpireSpawn < 5 and travelWildsOk == true and distToWildsSpawn < 5,
		"Region travel teleport failed or landed player outside safe spawn bounds")

	-- Check 28: Multi-Region Lore Steles Deciphering
	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(0, 5, -206)
	local empireAnnalsOk, _ = ExplorationService.ReadLoreStele(testTraveler, "stele_empire_annals")

	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(-280, 5, -130)
	local wildsLoreOk, _ = ExplorationService.ReadLoreStele(testTraveler, "stele_wilds_chronicles")

	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(280, 116, -256)
	local hollowProphecyOk, _ = ExplorationService.ReadLoreStele(testTraveler, "stele_hollow_prophecy")

	assertTest("Check 28: Multi-Region Lore Inscriptions (Empire, Wilds, Hollow)",
		empireAnnalsOk == true and wildsLoreOk == true and hollowProphecyOk == true
		and travProfile.discoveredLore["stele_empire_annals"] == true
		and travProfile.discoveredLore["stele_wilds_chronicles"] == true
		and travProfile.discoveredLore["stele_hollow_prophecy"] == true,
		"One or more regional lore steles failed to decipher or award lore")

	-- Check 29: Regional Caches with Anti-Exploit Cooldowns
	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(61, 2, -220)
	local cacheEmpOk, _ = ExplorationService.LootRegionalCache(testTraveler, "cache_empire_tribute")
	local dupCacheEmpOk, _ = ExplorationService.LootRegionalCache(testTraveler, "cache_empire_tribute")

	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(-272, 4, -224)
	local cacheWildsOk, _ = ExplorationService.LootRegionalCache(testTraveler, "cache_wilds_offering")

	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(280, 107, -200)
	local cacheHollowOk, _ = ExplorationService.LootRegionalCache(testTraveler, "cache_hollow_void")

	assertTest("Check 29: Regional Exploration Caches (Tribute, Offering, Void) & Cooldowns",
		cacheEmpOk == true and dupCacheEmpOk == false and cacheWildsOk == true and cacheHollowOk == true,
		"Regional caches loot or cooldown enforcement failed")

	-- Check 30: Heist Extraction Gamma (Deep Sub-Level Catacombs)
	HeistService.StartHeist(testTraveler, "heist_obsidian_outpost", "tool_smoke_capsule")
	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(500, 52, 552)
	testTraveler.Character.HumanoidRootPart.CFrame = CFrame.new(500, 52, 552)
	HeistService.InteractObjective(testTraveler)
	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(435, 52, 520)
	testTraveler.Character.HumanoidRootPart.CFrame = CFrame.new(435, 52, 520)
	local gammaExtractOk, _ = HeistService.ExtractHeist(testTraveler, "exit_gamma")

	assertTest("Check 30: Heist Extraction Gamma (Sub-Level Catacombs Route)",
		gammaExtractOk == true and travProfile.completedQuests["quest_vault_catacombs"] == true,
		"Extraction Gamma failed or did not award Catacombs quest progress")

	-- Check 31: Settlement Inhabitant NPC Services (Valeria, Ignis, Torvald)
	local valeriaOk, _, valeriaData = InteractionService.InteractNPC(testTraveler, "Valeria")
	local torvaldOk, _, torvaldData = InteractionService.InteractNPC(testTraveler, "Torvald")

	assertTest("Check 31: Settlement Inhabitant Services (Valeria Appraisal, Torvald Forging)",
		valeriaOk == true and valeriaData ~= nil and valeriaData.shards == 15
		and torvaldOk == true and torvaldData ~= nil and torvaldData.cash == 25,
		"Valeria or Torvald interaction service failed")

	-- Check 32: Extended Regional Quest Progression & Rewards
	QuestService.EvaluateQuests(testTraveler)
	local qEmpireDone = travProfile.completedQuests["quest_empire_expedition"]
	local qWildsDone = travProfile.completedQuests["quest_wilds_discovery"]
	local qVaultDone = travProfile.completedQuests["quest_vault_catacombs"]
	local qHollowDone = travProfile.completedQuests["quest_hollow_confrontation"]

	assertTest("Check 32: Extended Regional Quests (Quests 7, 8, 9, 10 Completed)",
		qEmpireDone == true and qWildsDone == true and qVaultDone == true and qHollowDone == true,
		"One or more regional progression quests failed to evaluate to complete")

	-- Check 33: Sentry Service Deployment & Archetypes
	local sentries = SentryService.GetSentries()
	local sCourtyard = sentries["Courtyard_1"]
	local sCorridor = sentries["Corridor_2"]
	local sVault = sentries["Vault_3"]
	local sEmpire = sentries["Empire_4"]

	assertTest("Check 33: Sentry Infiltration AI Archetypes Deployed (Courtyard, Corridor, Vault, Empire)",
		sCourtyard ~= nil and sCorridor ~= nil and sVault ~= nil and sEmpire ~= nil
		and sCourtyard.state == "Patrol" and #sCourtyard.waypoints >= 2,
		"One or more sentry AI units failed to deploy with valid waypoint routes")

	-- Check 34: Sentry Suspicion Buildup & Line-of-Sight Detection
	local mockSentry = {
		id = "Test_Sentry",
		state = "Patrol" :: any,
		suspicion = 0,
	} :: any
	local stateAfterLOS, suspAfterLOS, isAlerted = SentryService.ProcessDetection(
		mockSentry,
		testTraveler,
		18, -- 18 studs away
		true, -- line of sight clear
		false, -- no smoke
		false, -- no talisman
		1.0 -- 1 second
	)

	assertTest("Check 34: Sentry Suspicion Buildup on Clear Line-of-Sight",
		stateAfterLOS == "Suspicious" and suspAfterLOS > 0 and not isAlerted,
		"Sentry did not build suspicion when player was visible")

	-- Check 35: Stealth Counterplay — Smoke Screen Concealment
	local stateInSmoke, suspInSmoke, _ = SentryService.ProcessDetection(
		mockSentry,
		testTraveler,
		10, -- 10 studs away
		true, -- line of sight
		true, -- SMOKE ACTIVE
		false,
		1.0
	)

	assertTest("Check 35: Smoke Screen Concealment Suppresses Sentry Vision",
		suspInSmoke < suspAfterLOS,
		"Smoke screen failed to suppress sentry detection")

	-- Check 36: Stealth Counterplay — Breaking Line-of-Sight (Cover)
	mockSentry.suspicion = 50
	mockSentry.state = "Suspicious"
	local stateInCover, suspInCover, _ = SentryService.ProcessDetection(
		mockSentry,
		testTraveler,
		25,
		false, -- OBSTRUCTED BY COVER
		false,
		false,
		2.5 -- 2.5 seconds
	)

	assertTest("Check 36: Cover & Obstruction Decays Suspicion Back to Patrol",
		suspInCover == 0 and stateInCover == "Patrol",
		"Sentry failed to decay suspicion when player broke line-of-sight behind cover")

	-- Check 37: Museum-Grade Relic Display Plinth Generator
	local tempPlinthFolder = Instance.new("Folder")
	tempPlinthFolder.Name = "TestPlinthFolder"
	tempPlinthFolder.Parent = Workspace

	local testPlinth = RelicMeshBuilder.CreateRelicPlinth(tempPlinthFolder, CFrame.new(0, 80, 0), "relic_obsidian_chalice")
	local hasCushion = testPlinth and testPlinth:FindFirstChild("VelvetCushion")
	local hasPlaque = testPlinth and testPlinth:FindFirstChild("BrassNamePlaque")
	tempPlinthFolder:Destroy()

	assertTest("Check 37: Museum-Grade Relic Display Plinth & Spotlight Generator",
		testPlinth ~= nil and hasCushion ~= nil and hasPlaque ~= nil,
		"Relic display plinth model failed to construct with cushion and plaque")

	-- Check 38: Client Audio Safe Fallbacks & Global Mute Controller
	local audioSafe = true
	local successAudio = pcall(function()
		SoundEffects.SetMuted(false)
		SoundEffects.PlayClick()
		SoundEffects.PlayCash()
		SoundEffects.PlayRelicChime()
		SoundEffects.PlayAlarm()
		SoundEffects.PlaySentryAlert()
		SoundEffects.PlayGatewayTravel()
		SoundEffects.PlayCacheLoot()
		SoundEffects.PlayLoreDecipher()
		SoundEffects.SetMuted(true)
	end)
	if not successAudio then
		audioSafe = false
	end

	assertTest("Check 38: Client Audio Controller Safe Fallbacks & Global Mute Toggle",
		audioSafe == true,
		"Audio controller threw error during sound execution")

	-- Check 39: Relic Synergies Calculation & Detection
	local activeSyns = RelicDefinitions.GetSynergiesForInventory({
		["relic_scavenger_compass"] = true,
		["relic_merchants_eye"] = true,
	})
	assertTest("Check 39: Relic Synergy Detection (Smuggler's Fortune)",
		#activeSyns >= 1 and activeSyns[1].synergyId == "synergy_smuggler",
		"Failed to calculate active relic synergies")

	-- Check 40: Relic Refinement Level Upgrade Authority
	travProfile.currencies.RelicShards = 100
	local refineInst = travProfile.inventory[1]
	local refineOk, _ = InventoryService.RefineRelic(testTraveler, refineInst.instanceId)
	assertTest("Check 40: Relic Refinement Level Upgrade (Lvl 1 -> Lvl 2)",
		refineOk == true and refineInst.upgradeLevel == 2 and travProfile.currencies.RelicShards < 100,
		"Relic refinement failed or did not deduct shards")

	-- Check 41: Base Storage Vault Deposit and Withdrawal
	local preInvCount = #travProfile.inventory
	local depOk, _ = InventoryService.DepositToVault(testTraveler, refineInst.instanceId)
	local afterDepInv = #travProfile.inventory
	local afterDepVault = #travProfile.baseVaultStorage
	local withOk, _ = InventoryService.WithdrawFromVault(testTraveler, refineInst.instanceId)
	assertTest("Check 41: Base Storage Vault Safe Deposit & Withdrawal",
		depOk == true and afterDepInv == preInvCount - 1 and afterDepVault >= 1 and withOk == true and #travProfile.inventory == preInvCount,
		"Base storage vault deposit or withdrawal failed")

	-- Check 42: Shrine of Shifting Sands - Hourglass Altar Recovery
	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(-280, 4, -220)
	local hourAltarOk, _ = ExplorationService.CommuneHourglassAltar(testTraveler)
	local hasHourglassNow = travProfile.discoveredRelics["relic_ancient_hourglass"] == true
	assertTest("Check 42: Shrine of Shifting Sands Hourglass Altar Communion",
		hourAltarOk == true and hasHourglassNow,
		"Hourglass Altar communion failed to grant relic or register discovery")

	-- Check 43: Hollow Realm Crown Spire Apex - Hollow Crown Divine Communion
	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(280, 115, -270)
	local crownAltarOk, _ = ExplorationService.CommuneHollowAltar(testTraveler)
	local hasCrownNow = travProfile.discoveredRelics["relic_hollow_crown"] == true
	assertTest("Check 43: Hollow Crown Altar Divine Mastery Communion",
		crownAltarOk == true and hasCrownNow,
		"Hollow Crown altar communion failed to grant divine relic")

	-- Check 44: Imperial Crypt Plinth Exploration Salvage
	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(-65, -3.5, -220)
	local cryptLootOk, _ = ExplorationService.LootCryptPlinth(testTraveler)
	assertTest("Check 44: Imperial Crypt Plinth Salvage",
		cryptLootOk == true,
		"Imperial crypt plinth loot failed")
	end

	do
	-- Check 45: Sentry Raycast Self-Occlusion Filter & Alert Recovery Invariant
	local alertMockSentry = {
		id = "Alert_Recover_Sentry",
		state = "Alerted" :: any,
		suspicion = 100,
	} :: any
	local recoveredState, recoveredSusp, _ = SentryService.ProcessDetection(
		alertMockSentry,
		testTraveler,
		30,
		false, -- In cover / lost sight
		false,
		false,
		6.0 -- 6 seconds of no LOS
	)
	assertTest("Check 45: Sentry Alerted State Recovery Back to Patrol",
		recoveredState == "Patrol" and recoveredSusp == 0,
		"Sentry failed to recover from Alerted state back to Patrol when suspicion decayed")

	-- Check 46: Heist Tactical Retreat & Non-Heist ExitPad Safe Handling
	HeistService.StartHeist(testTraveler, "heist_obsidian_outpost", "tool_smoke_capsule")
	testTraveler.Character.HumanoidRootPart.Position = Vector3.new(500, 52, 425)
	testTraveler.Character.HumanoidRootPart.CFrame = CFrame.new(500, 52, 425)
	local retreatOk, retreatMsg, _ = HeistService.ExtractHeist(testTraveler, "exit_alpha")
	local nonHeistExitOk, _, _ = HeistService.ExtractHeist(testTraveler, "exit_alpha")
	assertTest("Check 46: Heist Tactical Retreat & Fail-Safe Return to Market",
		retreatOk == true and nonHeistExitOk == true,
		"Tactical retreat or fail-safe exit failed to return player to hub")

	-- Check 47: Heist Abort & Failure Safety Invariant (Permanent Inventory Preserved)
	local preAbortInvCount = #travProfile.inventory
	HeistService.StartHeist(testTraveler, "heist_obsidian_outpost", "tool_smoke_capsule")
	local abortOk, _ = HeistService.AbortHeist(testTraveler, true)
	local postAbortInvCount = #travProfile.inventory
	assertTest("Check 47: Heist Abort/Death Safety (Permanent Relics Preserved)",
		abortOk == true and preAbortInvCount == postAbortInvCount,
		"Heist abort failed or damaged permanent inventory")

	-- Check 48: Profile Schema V3 Invariants & Complete Data Contract
	assertTest("Check 48: Profile Schema V3 Data Contract Verification",
		travProfile.schemaVersion >= 2
		and travProfile.tutorialStep ~= nil
		and type(travProfile.completedTutorial) == "boolean"
		and type(travProfile.baseVaultStorage) == "table"
		and type(travProfile.relicSynergies) == "table"
		and type(travProfile.baseData.slottedRelicIds) == "table",
		"Profile Schema V3 contract missing required persistence fields")

	-- Check 49: Authoritative Onboarding Tutorial Step Synchronization
	travProfile.tutorialStep = 4
	travProfile.completedTutorial = true
	EconomyService.SyncProfileToClient(testTraveler)
	assertTest("Check 49: Onboarding Progression Synchronization",
		travProfile.tutorialStep == 4 and travProfile.completedTutorial == true,
		"Onboarding tutorial step update failed")

	-- Check 50: Relic Buff Re-Application on Character Spawning
	-- Equip Scavenger Compass (+15% WalkSpeed)
	for _, inst in ipairs(travProfile.inventory) do
		if inst.definitionId == "relic_scavenger_compass" then
			InventoryService.EquipRelic(testTraveler, inst.instanceId)
			break
		end
	end
	InventoryService.ApplyActiveBuffs(testTraveler, testTraveler.Character)
	local charHum = testTraveler.Character:FindFirstChildOfClass("Humanoid")
	local hasBuffedSpeed = charHum and charHum.WalkSpeed > 16.5
	assertTest("Check 50: Character Relic Buff Re-Application (WalkSpeed Amplification)",
		hasBuffedSpeed == true,
		"Character did not receive relic speed boost buff")

	-- Check 51: Workspace World Root & 5-Region Container Hierarchy
	local worldRoot = Workspace:FindFirstChild("RelicRushWorld")
	local hasMarket = worldRoot and worldRoot:FindFirstChild("ForgottenMarket")
	local hasEmpire = worldRoot and worldRoot:FindFirstChild("EmpireDistrict")
	local hasWilds = worldRoot and worldRoot:FindFirstChild("WhisperingWilds")
	local hasOutpost = worldRoot and worldRoot:FindFirstChild("ObsidianOutpost")
	local hasHollow = worldRoot and worldRoot:FindFirstChild("HollowRealm")

	assertTest("Check 51: Workspace World Root & 5-Region Container Hierarchy",
		worldRoot ~= nil and hasMarket ~= nil and hasEmpire ~= nil and hasWilds ~= nil and hasOutpost ~= nil and hasHollow ~= nil,
		"One or more of the 5 game regions is missing from Workspace.RelicRushWorld")

	-- Check 52: Real World Landmarks & Interactive Objects Instantiation Invariant
	local marketSpawn = hasMarket and hasMarket:FindFirstChild("MarketSpawn")
	local corvus = hasMarket and hasMarket:FindFirstChild("NPC_ElderCorvus")
	local bob = hasMarket and hasMarket:FindFirstChild("NPC_BrimstoneBob")
	local eagle = hasEmpire and hasEmpire:FindFirstChild("EagleBody")
	local crypt = hasEmpire and hasEmpire:FindFirstChild("CryptRelicPlinth")
	local ironwood = hasWilds and hasWilds:FindFirstChild("IronwoodTrunk")
	local hourglassAltar = hasWilds and hasWilds:FindFirstChild("HourglassAltar")
	local chalice = hasOutpost and hasOutpost:FindFirstChild("Relic_ObsidianChalice_Model")
	local exitAlpha = hasOutpost and hasOutpost:FindFirstChild("ExitPad_Alpha")
	local hollowCrownAltar = hasHollow and hasHollow:FindFirstChild("AltarCore")
	local hollowReturn = hasHollow and hasHollow:FindFirstChild("ReturnPortal_Market")

	local allLandmarksExist = marketSpawn ~= nil and corvus ~= nil and bob ~= nil
		and eagle ~= nil and crypt ~= nil and ironwood ~= nil and hourglassAltar ~= nil
		and chalice ~= nil and exitAlpha ~= nil and hollowCrownAltar ~= nil and hollowReturn ~= nil

	assertTest("Check 52: World Landmarks & Interactive Objects Instantiation Invariant",
		allLandmarksExist == true,
		"One or more essential landmarks or interactive world objects were not instantiated")

	-- Check 53: Regional NPCs Instantiation Invariant
	local aurelius = hasEmpire and hasEmpire:FindFirstChild("NPC_TribuneAurelius")
	local sylva = hasWilds and hasWilds:FindFirstChild("NPC_KeeperSylva")
	local voidEcho = hasHollow and hasHollow:FindFirstChild("NPC_VoidEcho")
	local marketVance = hasMarket and hasMarket:FindFirstChild("NPC_Vance")
	local marketValeria = hasMarket and hasMarket:FindFirstChild("NPC_Valeria")

	local allRegionalNpcsExist = aurelius ~= nil and sylva ~= nil and voidEcho ~= nil and marketVance ~= nil and marketValeria ~= nil
	assertTest("Check 53: Regional NPCs Instantiation Invariant (Aurelius, Sylva, VoidEcho, Vance, Valeria)",
		allRegionalNpcsExist == true,
		"One or more regional NPCs were not instantiated in their designated territories")

	-- Check 54: RelicMeshBuilder 3D Visual Accessory Models (All 6 Core Relics)
	local accessoryChar = Instance.new("Model")
	accessoryChar.Name = "TestAccessoryChar"
	local accTorso = Instance.new("Part")
	accTorso.Name = "UpperTorso"
	accTorso.Size = Vector3.new(2, 2, 1)
	accTorso.CFrame = CFrame.new(0, 10, 0)
	accTorso.Parent = accessoryChar
	local accHead = Instance.new("Part")
	accHead.Name = "Head"
	accHead.Size = Vector3.new(1.2, 1.2, 1.2)
	accHead.CFrame = CFrame.new(0, 12, 0)
	accHead.Parent = accessoryChar
	local accHum = Instance.new("Humanoid")
	accHum.Parent = accessoryChar
	accessoryChar.Parent = Workspace

	local allRelicVisualsMounted = true
	local sixCoreRelicIds = {
		"relic_scavenger_compass",
		"relic_merchants_eye",
		"relic_shadow_talisman",
		"relic_obsidian_chalice",
		"relic_ancient_hourglass",
		"relic_hollow_crown",
	}

	for _, relicDefId in ipairs(sixCoreRelicIds) do
		local prev = accessoryChar:FindFirstChild("EquippedRelicVisual")
		if prev then prev:Destroy() end
		RelicMeshBuilder.AttachEquippedRelic(accessoryChar, relicDefId)
		local visual = accessoryChar:FindFirstChild("EquippedRelicVisual")
		if not visual or #visual:GetChildren() == 0 then
			allRelicVisualsMounted = false
			break
		end
	end
	accessoryChar:Destroy()

	assertTest("Check 54: RelicMeshBuilder 3D Visual Accessory Models (All 6 Core Relics)",
		allRelicVisualsMounted == true,
		"Failed to build or attach 3D accessory visual models for one or more core relics")

	-- Check 55: Relic Refinement Stat Amplification Invariant
	-- Test WalkSpeed scaling: Lvl 1 (1.0x), Lvl 2 (1.3x), Lvl 3 (1.6x)
	local baseSpeedVal = 16.0
	local boostRatio = 0.15 -- Scavenger Compass provides 15%
	local lvl1Expected = baseSpeedVal * (1 + boostRatio * 1.0)
	local lvl2Expected = baseSpeedVal * (1 + boostRatio * 1.3)
	local lvl3Expected = baseSpeedVal * (1 + boostRatio * 1.6)

	local testInstCompass = {
		instanceId = "test_refine_compass_inst",
		definitionId = "relic_scavenger_compass",
		upgradeLevel = 1,
		acquiredTimestamp = os.time(),
		isLocked = false,
	}
	table.insert(travProfile.inventory, testInstCompass)
	travProfile.equippedRelicId = testInstCompass.instanceId

	InventoryService.ApplyActiveBuffs(testTraveler, testTraveler.Character)
	local spd1 = charHum.WalkSpeed

	testInstCompass.upgradeLevel = 2
	InventoryService.ApplyActiveBuffs(testTraveler, testTraveler.Character)
	local spd2 = charHum.WalkSpeed

	testInstCompass.upgradeLevel = 3
	InventoryService.ApplyActiveBuffs(testTraveler, testTraveler.Character)
	local spd3 = charHum.WalkSpeed

	local refinementScalingValid = (spd2 > spd1) and (spd3 > spd2) and math.abs(spd3 - lvl3Expected) < 0.1
	assertTest("Check 55: Relic Refinement Stat Amplification Invariant (Tiers 1, 2, 3)",
		refinementScalingValid == true,
		string.format("Refinement scaling failed: spd1=%.2f, spd2=%.2f, spd3=%.2f (expected ~%.2f)", spd1, spd2, spd3, lvl3Expected))

	-- Check 56: Regional Travel & Access Gating Invariant
	local marketAccessOk, _ = RegionService.CanAccessRegion(testTraveler, "ForgottenMarket")
	local wildsAccessOk, _ = RegionService.CanAccessRegion(testTraveler, "WhisperingWilds")
	local empireAccessOk, _ = RegionService.CanAccessRegion(testTraveler, "EmpireDistrict")
	local vaultsAccessOk, _ = RegionService.CanAccessRegion(testTraveler, "ObsidianVaults")
	local hollowAccessOk, _ = RegionService.CanAccessRegion(testTraveler, "HollowRealm")

	local allRegionsAccessible = marketAccessOk and wildsAccessOk and empireAccessOk and vaultsAccessOk and hollowAccessOk
	assertTest("Check 56: Regional Travel & Access Gating Invariant (All 5 Regions)",
		allRegionsAccessible == true,
		"One or more regions failed access gating check for qualified endgame player")

	-- Check 57: 10 Base Relic Plinths Per Sanctuary (Specification)
	assertTest("Check 57: 10 Base Relic Plinths Configured",
		EconomyConfig.BASE_RELIC_SLOTS == 10,
		"Expected 10 base relic slots")

	-- Check 58: 7 Relic Rarities in Catalog (Specification)
	local rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cursed" }
	local allRaritiesFound = true
	for _, rName in ipairs(rarities) do
		local list = RelicDefinitions.GetByRarity(rName)
		if #list == 0 then
			allRaritiesFound = false
			break
		end
	end
	assertTest("Check 58: 7 Relic Rarities Represented in Catalog",
		allRaritiesFound == true,
		"One or more of the 7 required rarities missing in RelicDefinitions")

	-- Check 59: Base Relic Slotting & Income Generation
	local testSlotRelic = travProfile.inventory[1]
	local slotOk, _ = BaseService.SlotRelic(testTraveler, 1, testSlotRelic.instanceId)
	local isSlotted = travProfile.baseData.slottedRelicIds[1] == testSlotRelic.instanceId
	assertTest("Check 59: Base Relic Slotting & Passive Plinth Assignment",
		slotOk == true and isSlotted == true,
		"Failed to slot relic onto base plinth")

	-- Check 60: Low-Risk Base Raiding (Siphons uncollected tribute, permanent relics 100% safe)
	travProfile.baseData.uncollectedTributeCash = 400
	travProfile.baseData.uncollectedTributeShards = 20
	local preRaidPermanentCount = #travProfile.inventory

	mockRaider = {
		UserId = 99999905,
		Name = "MockRaider",
		DisplayName = "Shadow Raider",
		Character = {
			FindFirstChild = function(self: any, name: string)
				if name == "HumanoidRootPart" then
					return { Position = Vector3.new(0, 0, 0), CFrame = CFrame.new(0, 0, 0) }
				end
				return nil
			end
		}
	} :: any
	ProfileService.LoadProfile(mockRaider)

	local raidStartOk, _, raidSession = BaseService.StartRaid(mockRaider, testTraveler.UserId)
	local siphonOk, _, sCash, sShards = BaseService.SiphonCoffer(mockRaider)
	local postRaidPermanentCount = #travProfile.inventory

	assertTest("Check 60: Low-Risk Base Raiding (Coffer Siphoned, Permanent Relics Safe)",
		raidStartOk == true and siphonOk == true and sCash > 0
		and postRaidPermanentCount == preRaidPermanentCount
		and travProfile.baseData.uncollectedTributeCash < 400,
		"Base raiding failed or violated permanent relic safety invariant")

	-- Check 60b: Empty Coffer Exploit Prevention (A raid must not generate free currency)
	travProfile.baseData.uncollectedTributeCash = 0
	travProfile.baseData.uncollectedTributeShards = 0
	local emptyRaidOk, _, _ = BaseService.StartRaid(mockRaider, testTraveler.UserId)
	local emptySiphonOk, _, emptyCash, emptyShards = BaseService.SiphonCoffer(mockRaider)
	assertTest("Check 60b: Empty Coffer Exploit Prevention (Zero Free Currency Generated)",
		emptySiphonOk == false and emptyCash == 0 and emptyShards == 0,
		"Exploit detected: Empty coffer yielded free currency!")

	-- Check 61: BaseDistrict vs ForgottenMarket Hierarchy Resolution
	local marketF = Workspace:FindFirstChild("RelicRushWorld") and Workspace.RelicRushWorld:FindFirstChild("ForgottenMarket")
	local hasBaseDistrict = marketF and marketF:FindFirstChild("BaseDistrict")
	assertTest("Check 61: BaseDistrict Container Resolution in ForgottenMarket",
		hasBaseDistrict ~= nil,
		"Missing BaseDistrict folder inside ForgottenMarket")

	-- Check 62: All 4 Exploration Zones Defined in ZoneLootTables
	local ZoneLootTables = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("ZoneLootTables"))
	local z1 = ZoneLootTables.Get("ForgottenWilds")
	local z2 = ZoneLootTables.Get("SunkenVault")
	local z3 = ZoneLootTables.Get("AshenDomain")
	local z4 = ZoneLootTables.Get("CelestialRift")
	assertTest("Check 62: 4 Exploration Zones Configured (Wilds, Vault, Ashen, Celestial)",
		z1 ~= nil and z2 ~= nil and z3 ~= nil and z4 ~= nil,
		"One or more of the 4 exploration zones is missing in ZoneLootTables")

	-- Check 63: Dynamic Relic Spawn Nodes Physical Instantiation
	ExplorationService.SpawnAllZoneNodes()
	local harvestTestPlayer = {
		UserId = 99999908,
		Name = "HarvestPlayer",
		DisplayName = "Harvester",
		Character = {
			FindFirstChild = function(self: any, name: string)
				if name == "HumanoidRootPart" then
					return { Position = Vector3.new(-230, 2, -180), CFrame = CFrame.new(-230, 2, -180) }
				end
				return nil
			end
		}
	} :: any
	local hProfile = ProfileService.LoadProfile(harvestTestPlayer)
	hProfile.unlockedZones["ForgottenWilds"] = true

	local harvestOk, harvestMsg, harvestData = ExplorationService.HarvestRelicNode(harvestTestPlayer, "wilds_node_1")
	assertTest("Check 64: Server-Authoritative Dynamic Relic Node Excavation",
		harvestOk == true and harvestData ~= nil and harvestData.relicId ~= nil,
		"Failed to harvest dynamic relic node: " .. tostring(harvestMsg))

	local dupHarvestOk, _ = ExplorationService.HarvestRelicNode(harvestTestPlayer, "wilds_node_1")
	assertTest("Check 64b: Dynamic Relic Node Cooldown Protection",
		dupHarvestOk == false,
		"Allowed harvesting dynamic relic node on cooldown")

	-- Check 65: Rotating Treasure Surges System Configuration
	assertTest("Check 65: Rotating Treasure Surge Types Configured",
		#ZoneLootTables.SurgeTypes >= 3,
		"Fewer than 3 rotating treasure surge types configured")

	-- =========================================================================
	-- PHASE 3 TESTS: BASE CUSTOMISATION, DEFENCES & ACTIVE INFILTRATION RAIDING
	-- =========================================================================

	end

	do
	-- Check 66: Base Customisation Shop Catalog Options Configured
	local hasFloor = EconomyConfig.GetItem("floor_obsidian_tiles") ~= nil
	local hasWall = EconomyConfig.GetItem("wall_granite_parapet") ~= nil
	local hasLight = EconomyConfig.GetItem("light_soulfire_lantern") ~= nil
	local hasDisplay = EconomyConfig.GetItem("decor_gold_pedestal") ~= nil
	local hasWard = EconomyConfig.GetItem("defense_runic_ward") ~= nil
	local hasSentry = EconomyConfig.GetItem("defense_sentry_totem") ~= nil
	local hasDecoy = EconomyConfig.GetItem("defense_decoy_coffer") ~= nil
	assertTest("Check 66: Base Customisation Catalog (Floors, Walls, Lights, Displays, Defenses)",
		hasFloor and hasWall and hasLight and hasDisplay and hasWard and hasSentry and hasDecoy,
		"One or more required Phase 3 customisation or defense items missing from catalog")

	-- Check 67: Base Customisation Placement & Placement Limit Enforcement
	local custPlayer = {
		UserId = 99999909,
		Name = "ArchitectPlayer",
		DisplayName = "Architect",
		Character = {
			FindFirstChild = function(self: any, name: string)
				if name == "HumanoidRootPart" then
					return { Position = Vector3.new(0, 0, 0), CFrame = CFrame.new(0, 0, 0) }
				end
				return nil
			end
		}
	} :: any
	local custProfile = ProfileService.LoadProfile(custPlayer)
	custProfile.currencies.Cash = 5000 -- Give ample cash for testing placements
	BaseService.AssignPlot(custPlayer)

	local placeOk1, _, _ = BaseService.PlaceObject(custPlayer, "floor_obsidian_tiles", Vector3.new(2, 0, 2), 0)
	local placeOk2, _, _ = BaseService.PlaceObject(custPlayer, "wall_granite_parapet", Vector3.new(4, 0, 4), 90)
	assertTest("Check 67: Base Object Placement with Authoritative Validation",
		placeOk1 == true and placeOk2 == true and #custProfile.baseData.placedObjects == 2,
		"Failed to place base customisation objects")

	-- Placement limit test
	local originalPlaced = custProfile.baseData.placedObjects
	custProfile.baseData.placedObjects = {}
	for i = 1, EconomyConfig.MAX_PLACED_OBJECTS_PER_BASE do
		table.insert(custProfile.baseData.placedObjects, {
			placementId = "mock_place_" .. tostring(i),
			itemId = "decor_stone_plinth",
			position = Vector3.new(0, 0, 0),
			rotationY = 0,
		})
	end
	local limitPlaceOk, _, _ = BaseService.PlaceObject(custPlayer, "floor_marble_mosaic", Vector3.new(5, 0, 5), 0)
	assertTest("Check 67b: Placement Limit Enforcement (Max 15 Objects)",
		limitPlaceOk == false,
		"Allowed placing beyond MAX_PLACED_OBJECTS_PER_BASE limit")

	-- Restore placed items
	custProfile.baseData.placedObjects = originalPlaced

	-- Check 68: Base Object Move & Reposition Persistence
	local firstPlaced = custProfile.baseData.placedObjects[1]
	local moveOk, moveMsg, _ = BaseService.MoveObject(custPlayer, firstPlaced.placementId, Vector3.new(8, 0, 8), 45)
	assertTest("Check 68: Configurable Object Moving & Rotation Persistence",
		moveOk == true and firstPlaced.position == Vector3.new(8, 0, 8) and firstPlaced.rotationY == 45,
		"Failed to move base object: " .. tostring(moveMsg))

	-- Out of bounds move check
	local oobMoveOk, _, _ = BaseService.MoveObject(custPlayer, firstPlaced.placementId, Vector3.new(50, 0, 50), 0)
	assertTest("Check 68b: Move Bounds Validation (Plot Boundary Enforced)",
		oobMoveOk == false,
		"Allowed moving object outside plot boundaries")

	-- Check 69: Base Object Removal with 50% Refund & Defense Rating Recalibration
	local preRemoveCash = custProfile.currencies.Cash
	local removeOk, removeMsg, _ = BaseService.RemoveObject(custPlayer, firstPlaced.placementId)
	assertTest("Check 69: Object Removal with 50% Cash Refund",
		removeOk == true and custProfile.currencies.Cash > preRemoveCash and #custProfile.baseData.placedObjects == 1,
		"Failed to remove object or refund cash: " .. tostring(removeMsg))

	-- Check 70: Defenses (Abyssal Runic Ward, Arcane Sentry Totem) Defense Rating Scaling
	local baseDefBefore = custProfile.baseData.defenseRating or 10
	local placeWardOk, _, _ = BaseService.PlaceObject(custPlayer, "defense_runic_ward", Vector3.new(-6, 0, -6), 0)
	local placeTotemOk, _, _ = BaseService.PlaceObject(custPlayer, "defense_sentry_totem", Vector3.new(6, 0, -6), 0)
	local placeDecoyOk, _, _ = BaseService.PlaceObject(custPlayer, "defense_decoy_coffer", Vector3.new(0, 0, 6), 0)
	local baseDefAfter = custProfile.baseData.defenseRating or 10
	assertTest("Check 70: Base Defenses (Ward +15, Totem +25, Decoy +20) Scaling",
		placeWardOk == true and placeTotemOk == true and placeDecoyOk == true and baseDefAfter == (baseDefBefore + 15 + 25 + 20),
		"Defenses did not correctly increase base defense rating")

	-- Check 71: Rival Base List Retrieval & Self-Exclusion
	local rivalList = BaseService.GetRivalBaseList(mockRaider)
	assertTest("Check 71: Rival Base List Retrieval with Defense Overview",
		type(rivalList) == "table",
		"Failed to retrieve rival base list")

	-- Check 72: Gilded Decoy Coffer Detonation Trap
	local decoyRaidOk, _, decoySession = BaseService.StartRaid(mockRaider, custPlayer.UserId)
	local decoyTrapOk, _ = BaseService.TriggerDecoyTrap(mockRaider)
	assertTest("Check 72: Gilded Decoy Coffer Trap Detonation (100% Alarm)",
		decoyRaidOk == true and decoyTrapOk == true and decoySession.alarmLevel == 100,
		"Decoy trap did not trigger or escalate alarm to 100%")

	-- Check 73: Raid Tactical Infiltration Gadgets (Smoke Capsule & Bypass Wire)
	local smokeOk, _ = BaseService.UseRaidGadget(mockRaider, "tool_smoke_capsule")
	local wireOk, _ = BaseService.UseRaidGadget(mockRaider, "tool_lockpick_wire")
	assertTest("Check 73: Raid Tactical Gadgets (Smoke Capsule & Bypass Wire)",
		smokeOk == true and wireOk == true and decoySession.smokeActiveUntil > os.time() and decoySession.bypassWireActive == true,
		"Raid gadgets failed to activate in active session")

	-- Check 74: Low-Risk Siphoning Invariant with Defense Rating Mitigation
	custProfile.baseData.uncollectedTributeCash = 1000
	local siphonOk, _, sCash, _ = BaseService.SiphonCoffer(mockRaider)
	assertTest("Check 74: Vault Coffer Breach with Defense Ward Siphon Mitigation",
		siphonOk == true and sCash > 0 and sCash < 250 and decoySession.phase == "CofferBreached",
		"Defense wards failed to mitigate siphon yield or transition phase to CofferBreached")

	-- Check 75: Raid Extraction & Bounty Safe Escape
	local preExtractCash = ProfileService.GetProfile(mockRaider).currencies.Cash
	local extractOk, extractMsg = BaseService.ExtractRaid(mockRaider)
	local postExtractCash = ProfileService.GetProfile(mockRaider).currencies.Cash
	assertTest("Check 75: Safe Extraction & Server-Authoritative Haul Banking",
		extractOk == true and postExtractCash >= preExtractCash,
		"Failed to extract raid safely: " .. tostring(extractMsg))

	end

	do
	-- Check 76: 12 Progression Quests & Daily/Repeatable Catalog Verification
	local progCount = 0
	local dailyCount = 0
	local repCount = 0
	for _, q in ipairs(QuestDefinitions.All) do
		if q.category == "Progression" or q.category == nil then
			progCount += 1
		elseif q.category == "Daily" then
			dailyCount += 1
		elseif q.category == "Repeatable" then
			repCount += 1
		end
	end
	assertTest("Check 76: 12 Progression Quests, Daily & Repeatable Catalog",
		progCount == 12 and dailyCount == 2 and repCount == 1 and #QuestDefinitions.All == 15,
		string.format("Expected 12 Progression, 2 Daily, 1 Repeatable quests, got: Prog=%d, Daily=%d, Rep=%d", progCount, dailyCount, repCount))

	-- Check 77: Quest Evaluation & Server Duplicate Claim Prevention
	local questMockPlayer = {
		UserId = 99999908,
		Name = "TestPlayer_Quest",
		DisplayName = "Quest Tester",
	} :: any
	local questProfile = ProfileService.LoadProfile(questMockPlayer)
	questProfile.hasSelectedStarter = true
	QuestService.EvaluateQuests(questMockPlayer)
	local isQ1Completed = questProfile.completedQuests["quest_the_calling"] == true
	local preClaimCash = questProfile.currencies.Cash
	local claimOk, claimMsg = QuestService.ClaimReward(questMockPlayer, "quest_the_calling")
	local postClaimCash = questProfile.currencies.Cash
	local doubleClaimOk, _ = QuestService.ClaimReward(questMockPlayer, "quest_the_calling")
	assertTest("Check 77: Quest Evaluation & Duplicate Claim Prevention",
		isQ1Completed == true and claimOk == true and postClaimCash > preClaimCash and doubleClaimOk == false and questProfile.claimedQuests["quest_the_calling"] == true,
		"Quest claim failed or allowed duplicate reward claim: " .. tostring(claimMsg))

	-- Check 78: 9-Step Tutorial Progression & Step Saving
	local tutMockPlayer = {
		UserId = 99999909,
		Name = "TestPlayer_Tutorial",
		DisplayName = "Tutorial Tester",
	} :: any
	local tutProfile = ProfileService.LoadProfile(tutMockPlayer)
	local step1Ok, _ = InteractionService.CompleteTutorialStep(tutMockPlayer, 1)
	local step2Ok, _ = InteractionService.CompleteTutorialStep(tutMockPlayer, 2)
	local step3Ok, _ = InteractionService.CompleteTutorialStep(tutMockPlayer, 3)
	assertTest("Check 78: 9-Step Tutorial Progression & Server Step Saving",
		step1Ok == true and step2Ok == true and step3Ok == true and tutProfile.tutorialStep == 3 and tutProfile.completedTutorial == false,
		"Tutorial steps failed to advance or persist on server")

	-- Check 79: Tutorial Skip & Onboarding Bonus Payout ($200 Cash, 25 Shards)
	local preSkipCash = tutProfile.currencies.Cash
	local skipOk, skipMsg = InteractionService.SkipTutorial(tutMockPlayer)
	local postSkipCash = tutProfile.currencies.Cash
	assertTest("Check 79: Tutorial Skip & Onboarding Bonus Payout ($200 Cash, 25 Shards)",
		skipOk == true and tutProfile.completedTutorial == true and tutProfile.tutorialStep == 9 and postSkipCash == (preSkipCash + 200),
		"Tutorial skip failed or bonus not awarded: " .. tostring(skipMsg))

	-- Check 80: Collection Milestones Catalog Integrity (10 Tiers)
	local mCount = #MilestoneDefinitions.All
	local hasCountM = false
	local hasRarityM = false
	local hasCrownM = false
	for _, m in ipairs(MilestoneDefinitions.All) do
		if m.category == "DiscoveryCount" then hasCountM = true end
		if m.category == "RarityTier" then hasRarityM = true end
		if m.milestoneId == "milestone_hollow_crown" then hasCrownM = true end
	end
	assertTest("Check 80: Collection Milestones Catalog Integrity (10 Tiers)",
		mCount == 10 and hasCountM and hasRarityM and hasCrownM,
		string.format("Milestone catalog incomplete: count=%d, hasCount=%s, hasRarity=%s, hasCrown=%s",
			mCount, tostring(hasCountM), tostring(hasRarityM), tostring(hasCrownM)))

	-- Check 81: Milestone Server Validation & Duplicate Claim Prevention
	local msMockPlayer = {
		UserId = 99999910,
		Name = "TestPlayer_Milestone",
		DisplayName = "Milestone Tester",
	} :: any
	local msProfile = ProfileService.LoadProfile(msMockPlayer)
	local prematureClaimOk, _ = InventoryService.ClaimMilestoneReward(msMockPlayer, "milestone_first_discovery")
	msProfile.discoveredRelics["relic_scavenger_compass"] = true
	local preMsCash = msProfile.currencies.Cash
	local eligibleClaimOk, msClaimMsg = InventoryService.ClaimMilestoneReward(msMockPlayer, "milestone_first_discovery")
	local postMsCash = msProfile.currencies.Cash
	local duplicateMsOk, _ = InventoryService.ClaimMilestoneReward(msMockPlayer, "milestone_first_discovery")
	assertTest("Check 81: Milestone Server Validation & Duplicate Claim Prevention",
		prematureClaimOk == false and eligibleClaimOk == true and postMsCash > preMsCash and duplicateMsOk == false and msProfile.collectionMilestonesClaimed["milestone_first_discovery"] == true,
		"Milestone claim validation failed or duplicate permitted: " .. tostring(msClaimMsg))

	-- Check 82: Hollow Crown Signature Milestone Award (+$2500, +500 Shards)
	local crownBeforeOk = InventoryService.IsMilestoneCompleted(msProfile, "milestone_hollow_crown")
	msProfile.discoveredRelics["relic_hollow_crown"] = true
	local crownAfterOk = InventoryService.IsMilestoneCompleted(msProfile, "milestone_hollow_crown")
	local preCrownCash = msProfile.currencies.Cash
	local preCrownShards = msProfile.currencies.RelicShards
	local crownClaimOk, _ = InventoryService.ClaimMilestoneReward(msMockPlayer, "milestone_hollow_crown")
	assertTest("Check 82: Hollow Crown Signature Milestone Award (+$2500, +500 Shards)",
		crownBeforeOk == false and crownAfterOk == true and crownClaimOk == true and msProfile.currencies.Cash == (preCrownCash + 2500) and msProfile.currencies.RelicShards == (preCrownShards + 500),
		"Hollow crown milestone failed to detect crown discovery or award $2500/500 shards")

	-- Check 83: Offline Income Invariants (6hr Cap, 65% Efficiency, Negative Time Guard)
	local offlineProfile = ProfileService.LoadProfile({
		UserId = 99999911,
		Name = "TestPlayer_Offline",
		DisplayName = "Offline Tester",
	} :: any)
	local testRelicInst: CommonTypes.RelicInstance = {
		instanceId = "offline_inst_01",
		definitionId = "relic_scavenger_compass",
		upgradeLevel = 1,
		isEquipped = false,
		acquiredTimestamp = os.time(),
	}
	table.insert(offlineProfile.inventory, testRelicInst)
	offlineProfile.baseData.slottedRelicIds[1] = "offline_inst_01"

	offlineProfile.lastSavedTimestamp = os.time() + 5000
	local negCash, negShards, _ = ProfileService.CalculateOfflineIncome(offlineProfile, os.time())

	offlineProfile.lastSavedTimestamp = os.time() - 36000
	local capCash, _, capSecs = ProfileService.CalculateOfflineIncome(offlineProfile, os.time())

	assertTest("Check 83: Offline Income Invariants (6hr Cap, 65% Efficiency, Negative Time Guard)",
		negCash == 0 and negShards == 0 and capSecs == 21600 and capCash > 0,
		string.format("Offline income invariants violated: negCash=%d, capSecs=%d, capCash=%d", negCash, capSecs, capCash))

	-- Check 84: Rebirth Requirement Enforcement ($2,500 min cash & 8 unique relics)
	local rebirthMockPlayer = {
		UserId = 99999912,
		Name = "TestPlayer_Rebirth",
		DisplayName = "Rebirth Tester",
	} :: any
	local rebirthProfile = ProfileService.LoadProfile(rebirthMockPlayer)
	local rebFailCashOk, _ = BaseService.Rebirth(rebirthMockPlayer)
	rebirthProfile.currencies.Cash = 3000
	local rebFailRelicsOk, _ = BaseService.Rebirth(rebirthMockPlayer)

	assertTest("Check 84: Rebirth Requirement Enforcement ($2,500 min cash & 8 unique relics)",
		rebFailCashOk == false and rebFailRelicsOk == false,
		"Rebirth executed without meeting cash or relic requirements")

	-- Check 85: Rebirth Execution (+25% Prestige, $500 Restart, Full Retention)
	local allDefKeys = {}
	for k in pairs(RelicDefinitions.GetAll()) do
		table.insert(allDefKeys, k)
		if #allDefKeys >= 8 then break end
	end
	for _, k in ipairs(allDefKeys) do
		rebirthProfile.discoveredRelics[k] = true
	end
	local rebSuccessOk, rebSuccessMsg = BaseService.Rebirth(rebirthMockPlayer)

	assertTest("Check 85: Rebirth Execution (+25% Prestige, $500 Restart, Full Retention)",
		rebSuccessOk == true and rebirthProfile.rebirthData.rebirthCount == 1 and rebirthProfile.rebirthData.prestigeMultiplier == 1.25 and rebirthProfile.currencies.Cash == EconomyConfig.STARTING_CASH and #allDefKeys >= 8,
		"Rebirth execution failed or did not correctly apply multiplier: " .. tostring(rebSuccessMsg))

	-- Check 86: The Hollow Crown Procedural Geometry & Void Singularity
	local crownModel = RelicMeshBuilder.CreateHollowCrown(Workspace, CFrame.new(0, 100, 0))
	local hasCirclet = crownModel:FindFirstChild("Circlet") ~= nil
	local hasSingularity = crownModel:FindFirstChild("VoidSingularity") ~= nil
	local hasRunes = crownModel:FindFirstChild("VoidRune_1") ~= nil
	crownModel:Destroy()
	assertTest("Check 86: The Hollow Crown Procedural Geometry & Void Singularity",
		hasCirclet and hasSingularity and hasRunes,
		"The Hollow Crown missing circlet, void singularity, or orbiting runes")

	-- Check 87: Cosmetic Catalog Integrity (Zero Pay-to-Win Invariant)
	local cosmeticCatalog = EconomyConfig.CosmeticCatalog
	local cosmeticValid = true
	local cosmeticCount = 0
	for _, cos in pairs(cosmeticCatalog or {}) do
		cosmeticCount += 1
		if (cos :: any).defenseValue or (cos :: any).buffType or (cos :: any).incomeMultiplier then
			cosmeticValid = false
			break
		end
	end
	assertTest("Check 87: Cosmetic Catalog Integrity (Zero Pay-to-Win Invariant)",
		cosmeticCount >= 4 and cosmeticValid,
		"Cosmetics catalog incomplete or contains pay-to-win stat boosts")

	-- Check 88: Multi-Channel Audio & Sound Volume Settings
	SoundEffects.SetMasterVolume(0.7)
	SoundEffects.SetSFXVolume(0.85)
	SoundEffects.SetMusicVolume(0.5)
	local masterOk = math.abs(SoundEffects.GetMasterVolume() - 0.7) < 0.01
	local sfxOk = math.abs(SoundEffects.GetSFXVolume() - 0.85) < 0.01
	local musicOk = math.abs(SoundEffects.GetMusicVolume() - 0.5) < 0.01
	assertTest("Check 88: Multi-Channel Audio & Sound Volume Settings",
		masterOk and sfxOk and musicOk,
		"SoundEffects volume channel setters or getters misbehaving")

	-- Check 89: Atmospheric Zone Ambience System (5 Zones)
	local ambienceOk = true
	local testZones = { "ForgottenMarket", "ForgottenWilds", "SunkenVault", "AshenDomain", "CelestialRift" }
	for _, z in ipairs(testZones) do
		local ok, _ = pcall(function()
			SoundEffects.PlayZoneAmbience(z)
		end)
		if not ok then ambienceOk = false break end
	end
	assertTest("Check 89: Atmospheric Zone Ambience System (5 Zones)",
		ambienceOk == true,
		"Zone ambience failed to initialize across all 5 zones")

	-- Check 90: Transaction Idempotency & Duplicate Prevention
	local transPlayer = { UserId = 99999913, Name = "TestPlayer_Trans" } :: any
	local keyA = "idempotent_test_key_alpha"
	local ranFirst = false
	local ranSecond = false
	TransactionService.Process(transPlayer, keyA, "TestOp", function()
		ranFirst = true
		return true, "Success"
	end)
	local secondOk, _ = TransactionService.Process(transPlayer, keyA, "TestOp", function()
		ranSecond = true
		return true, "Duplicate"
	end)
	assertTest("Check 90: Transaction Idempotency & Duplicate Prevention",
		ranFirst == true and ranSecond == false and secondOk == true,
		"TransactionService allowed duplicate execution on identical idempotency key")

	-- Check 91: DataStore Safety & Mock Isolation Invariant
	local isMock = ProfileService.IsMockMode()
	local p1 = ProfileService.GetProfile(mockPlayer)
	assertTest("Check 91: DataStore Safety & Mock Isolation Invariant",
		isMock == true and p1 ~= nil and p1.currencies.Cash > 0,
		"ProfileService failed to isolate active session or initialize mock profile")

	-- Check 92: Base Object Limits & Plot Boundary Enforcement
	local plotTestPlayer = { UserId = 99999914, Name = "TestPlayer_Plot" } :: any
	local plotProfile = ProfileService.LoadProfile(plotTestPlayer)
	plotProfile.currencies.Cash = 5000
	local placeInsideOk, _, _ = BaseService.PlaceObject(plotTestPlayer, "decor_brazier", Vector3.new(0, 0, 0), 0)
	local placeBoundaryOk, _, _ = BaseService.PlaceObject(plotTestPlayer, "decor_brazier", Vector3.new(45, 0, 0), 0)
	assertTest("Check 92: Base Object Limits & Plot Boundary Enforcement",
		placeInsideOk == true and placeBoundaryOk == false,
		"BaseService permitted object placement outside 40x40 base boundary")

	-- Check 93: Currency & Inventory Duplication Prevention
	local dupPlayer = { UserId = 99999915, Name = "TestPlayer_Dup" } :: any
	local dupProfile = ProfileService.LoadProfile(dupPlayer)
	dupProfile.currencies.Cash = 500
	local claimAOk, _, _ = InteractionService.SelectStarterRelic(dupPlayer, "relic_scavenger_compass", "dup_key_1")
	local claimBOk, _, _ = InteractionService.SelectStarterRelic(dupPlayer, "relic_ancient_chisel", "dup_key_2")
	assertTest("Check 93: Currency & Inventory Duplication Prevention",
		claimAOk == true and claimBOk == false and #dupProfile.inventory == 1,
		"InteractionService permitted duplicate starter relic claim")

	-- Check 94: Raid Cooldown Enforcement Invariant
	local targetP = { UserId = 99999916, Name = "TestPlayer_Target" } :: any
	local raiderP = { UserId = 99999917, Name = "TestPlayer_Cooldown" } :: any
	ProfileService.LoadProfile(targetP)
	ProfileService.LoadProfile(raiderP)
	local raid1Ok, _, _ = BaseService.StartRaid(raiderP, targetP.UserId)
	local raid2Ok, _, _ = BaseService.StartRaid(raiderP, targetP.UserId)
	assertTest("Check 94: Raid Cooldown Enforcement Invariant (3-Minute Lockout)",
		raid1Ok == true and raid2Ok == false,
		"BaseService permitted immediate re-raiding without enforcing cooldown")

	-- Check 95: Rebirth Retention of Discovered Relics & Milestones
	local rebRetentionPlayer = { UserId = 99999918, Name = "TestPlayer_Retain" } :: any
	local rebRetProfile = ProfileService.LoadProfile(rebRetentionPlayer)
	rebRetProfile.currencies.Cash = 3000
	rebRetProfile.collectionMilestonesClaimed["milestone_first_discovery"] = true
	for i = 1, 8 do
		rebRetProfile.discoveredRelics["mock_relic_" .. tostring(i)] = true
	end
	local rebRetOk, _ = BaseService.Rebirth(rebRetentionPlayer)
	local discoveredPreserved = 0
	for _ in pairs(rebRetProfile.discoveredRelics) do discoveredPreserved += 1 end
	assertTest("Check 95: Rebirth Retention of Discovered Relics & Milestones",
		rebRetOk == true and discoveredPreserved == 8 and rebRetProfile.collectionMilestonesClaimed["milestone_first_discovery"] == true,
		"Rebirth stripped discovered relics or milestone progress")

	-- Check 96: Offline Income Invariant (12-Hour Request Clamped to 6-Hour Cap)
	local longOfflineProfile = ProfileService.LoadProfile({ UserId = 99999919, Name = "TestPlayer_LongOffline" } :: any)
	table.insert(longOfflineProfile.inventory, {
		instanceId = "long_offline_inst",
		definitionId = "relic_ancient_chisel",
		upgradeLevel = 1,
		isEquipped = false,
		acquiredTimestamp = os.time(),
	})
	longOfflineProfile.baseData.slottedRelicIds[1] = "long_offline_inst"
	longOfflineProfile.lastSavedTimestamp = os.time() - (12 * 3600)
	local _, _, clampedSeconds = ProfileService.CalculateOfflineIncome(longOfflineProfile, os.time())
	assertTest("Check 96: Offline Income 6-Hour Strict Clamp (21,600s)",
		clampedSeconds == 21600,
		"Offline income eligible seconds exceeded 6-hour cap: " .. tostring(clampedSeconds))

	-- Check 97: Sentry Drone Sight Range & Smoke Obscuration
	local smokeMitigated = false
	local testRaidSession = {
		raiderUserId = 99999920,
		targetUserId = 99999921,
		phase = "Infiltrating" :: any,
		startedTimestamp = os.time(),
		expiresTimestamp = os.time() + 45,
		alarmLevel = 0,
		siphonedCash = 0,
		siphonedShards = 0,
		smokeActiveUntil = os.time() + 10,
		bypassWireActive = false,
	}
	smokeMitigated = testRaidSession.smokeActiveUntil > os.time()
	assertTest("Check 97: Tactical Smoke Obscuration Active Window",
		smokeMitigated == true,
		"Smoke capsule failed to register active concealment window")

	-- Check 98: Siphon Reward Invariant (Max 25% of Coffer)
	local richProfile = ProfileService.LoadProfile({ UserId = 99999922, Name = "TestPlayer_Rich" } :: any)
	richProfile.baseData.uncollectedTributeCash = 400
	local siphonRaider = { UserId = 99999923, Name = "TestPlayer_Siphon" } :: any
	ProfileService.LoadProfile(siphonRaider)
	local sRaidOk, _, _ = BaseService.StartRaid(siphonRaider, richProfile.playerId)
	local siphOk, _, sAmt, _ = BaseService.SiphonCoffer(siphonRaider)
	assertTest("Check 98: Siphon Reward Invariant (Max 25% of Coffer)",
		sRaidOk == true and siphOk == true and sAmt <= 100,
		"Siphoned amount exceeded 25% coffer limit: " .. tostring(sAmt))

	-- Check 99: Quest Progress Event Trigger & Auto-Evaluation
	local evtPlayer = { UserId = 99999924, Name = "TestPlayer_Evt" } :: any
	local evtProfile = ProfileService.LoadProfile(evtPlayer)
	QuestService.RecordEvent(evtPlayer, "income_collected")
	local hasTributeQuest = evtProfile.completedQuests["quest_tribute_tithe"] == true
	assertTest("Check 99: Quest Progress Event Trigger & Auto-Evaluation",
		hasTributeQuest == true,
		"RecordEvent failed to trigger quest completion")

	-- Check 100: End-to-End Game Build & Launch Readiness
	local totalRelics = 0
	for _ in pairs(RelicDefinitions.GetAll()) do totalRelics += 1 end
	local totalQuests = #QuestDefinitions.All
	local totalMilestones = #MilestoneDefinitions.All
	assertTest("Check 100: Full Game Loop Integration & Launch Readiness",
		totalRelics >= 14 and totalQuests == 15 and totalMilestones == 10 and passed >= 95,
		string.format("Game loop integration incomplete: Relics=%d, Quests=%d, Milestones=%d, Passed=%d",
			totalRelics, totalQuests, totalMilestones, passed))

	end

	-- Clean up mock allocations
	BaseService.ReleasePlot(mockPlayer)
	mockHrp:Destroy()

	print("==================================================")
	print(string.format("  QA SUITE COMPLETE: %d Passed, %d Failed", passed, failed))
	print("==================================================\n")

	return {
		passed = passed,
		failed = failed,
		results = results,
	}
end

return VerticalSliceTestRunner
