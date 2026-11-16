--!strict
-- ExplorationService.luau
-- Authoritative exploration mechanics: Dynamic relic spawn nodes, rarity-based loot rolls,
-- rotating celestial treasure surges, lore steles, and regional caches across all 4 world zones.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local EconomyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local RelicDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local ZoneLootTables = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("ZoneLootTables"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

local ProfileService = require(script.Parent.ProfileService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local RelicMeshBuilder = require(script.Parent.Parent.world.RelicMeshBuilder)

type WorldZoneId = CommonTypes.WorldZoneId
type RelicRarity = CommonTypes.RelicRarity
type RelicInstance = CommonTypes.RelicInstance

local ExplorationService = {}

-- Dynamic Node Tracking
local activeNodeCooldowns: { [string]: number } = {} -- [nodeId] = respawnTimestamp
local nodeInstances: { [string]: Model } = {}
local nodeZoneMap: { [string]: { zoneId: WorldZoneId, position: Vector3, name: string } } = {}

-- Rotating Treasure Surge Tracking
local currentActiveSurge: {
	zoneId: WorldZoneId,
	surgeType: string,
	displayName: string,
	bonusDescription: string,
	expiresAt: number,
	bonusShardMult: number,
	bonusLuck: number,
}? = nil

-- Existing Lore Steles & Caches
local LORE_STELES: { [string]: { pos: Vector3, name: string, loreText: string, rewardCash: number, rewardShards: number } } = {
	["stele_chronicles"] = {
		pos = Vector3.new(-82, 23, -53),
		name = "The First Vault",
		loreText = "Four seals bound the deep citadel... until shadows fell upon the market.",
		rewardCash = 50,
		rewardShards = 25,
	},
	["stele_empire_annals"] = {
		pos = Vector3.new(0, 5, -206),
		name = "The Imperial Annals",
		loreText = "From blood and gold rose the triumphal eagle. No emperor shall kneel before the void.",
		rewardCash = 75,
		rewardShards = 35,
	},
	["stele_wilds_chronicles"] = {
		pos = Vector3.new(-280, 5, -130),
		name = "The Verdant Oath",
		loreText = "Roots drinking from ancient celestial veins remember what time sought to erase.",
		rewardCash = 80,
		rewardShards = 40,
	},
	["stele_hollow_prophecy"] = {
		pos = Vector3.new(280, 116, -256),
		name = "The Hollow Prophecy",
		loreText = "When the eight spires ignite, the Hollow Crown claims its sovereign vessel.",
		rewardCash = 120,
		rewardShards = 60,
	},
}

local REGIONAL_CACHES: { [string]: { pos: Vector3, name: string, minCash: number, maxCash: number, shards: number, cooldown: number } } = {
	["cache_empire_tribute"] = {
		pos = Vector3.new(61, 2, -220),
		name = "Imperial Tribute Chest",
		minCash = 40,
		maxCash = 70,
		shards = 15,
		cooldown = 120,
	},
	["cache_wilds_offering"] = {
		pos = Vector3.new(-272, 4, -224),
		name = "Druidic Offering Urn",
		minCash = 45,
		maxCash = 75,
		shards = 20,
		cooldown = 120,
	},
	["cache_hollow_void"] = {
		pos = Vector3.new(280, 107, -200),
		name = "Void Essence Cache",
		minCash = 60,
		maxCash = 100,
		shards = 35,
		cooldown = 180,
	},
}

local cacheCooldowns: { [string]: number } = {}
local urnCooldowns: { [string]: number } = {}
local altarCooldowns: { [string]: number } = {}

-- =============================================================================
-- DYNAMIC RELIC SPAWN NODES GENERATION
-- =============================================================================

function ExplorationService.SpawnAllZoneNodes()
	local world = Workspace:FindFirstChild("RelicRushWorld")
	if not world then return end

	for zoneId, zoneCfg in pairs(ZoneLootTables.Zones) do
		-- Find or create zone container folder
		local zoneFolder = world:FindFirstChild(zoneId)
		if not zoneFolder then
			-- Fallback to legacy names if needed
			if zoneId == "ForgottenWilds" then zoneFolder = world:FindFirstChild("WhisperingWilds") end
			if zoneId == "SunkenVault" then zoneFolder = world:FindFirstChild("ObsidianOutpost") end
			if zoneId == "AshenDomain" then zoneFolder = world:FindFirstChild("EmpireDistrict") end
			if zoneId == "CelestialRift" then zoneFolder = world:FindFirstChild("HollowRealm") end
		end

		if not zoneFolder then
			zoneFolder = Instance.new("Folder")
			zoneFolder.Name = zoneId
			zoneFolder.Parent = world
		end

		local nodesFolder = zoneFolder:FindFirstChild("RelicSpawnNodes")
		if not nodesFolder then
			nodesFolder = Instance.new("Folder")
			nodesFolder.Name = "RelicSpawnNodes"
			nodesFolder.Parent = zoneFolder
		end

		for _, nodeDef in ipairs(zoneCfg.spawnNodes) do
			nodeZoneMap[nodeDef.nodeId] = {
				zoneId = zoneId,
				position = nodeDef.position,
				name = nodeDef.description,
			}

			local existingNode = nodesFolder:FindFirstChild(nodeDef.nodeId)
			if existingNode then existingNode:Destroy() end

			local nodeModel = Instance.new("Model")
			nodeModel.Name = nodeDef.nodeId

			-- Pedestal base
			local base = Instance.new("Part")
			base.Name = "NodeBase"
			base.Size = Vector3.new(3.5, 0.8, 3.5)
			base.CFrame = CFrame.new(nodeDef.position)
			base.Color = Color3.fromRGB(35, 30, 42)
			base.Material = Enum.Material.Basalt
			base.Anchored = true
			base.CanCollide = true
			base.Parent = nodeModel
			nodeModel.PrimaryPart = base

			-- Floating ancient runic curiosity
			local orb = Instance.new("Part")
			orb.Name = "CuriosityOrb"
			orb.Size = Vector3.new(1.8, 1.8, 1.8)
			orb.CFrame = CFrame.new(nodeDef.position + Vector3.new(0, 2.2, 0))
			orb.Color = zoneCfg.atmosphereColor
			orb.Material = Enum.Material.Neon
			orb.Shape = Enum.PartType.Ball
			orb.Anchored = true
			orb.CanCollide = false
			orb.Parent = nodeModel

			local light = Instance.new("PointLight")
			light.Name = "NodeGlow"
			light.Color = zoneCfg.atmosphereColor
			light.Brightness = 2.0
			light.Range = 14
			light.Parent = orb

			local pe = Instance.new("ParticleEmitter")
			pe.Name = "NodeSparks"
			pe.Color = ColorSequence.new(zoneCfg.atmosphereColor)
			pe.Size = NumberSequence.new(0.25, 0.05)
			pe.Lifetime = NumberRange.new(0.8, 1.5)
			pe.Rate = 8
			pe.Speed = NumberRange.new(0.5, 1.2)
			pe.Parent = orb

			-- Interaction ProximityPrompt
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "ExcavatePrompt"
			prompt.ActionText = "Excavate Ancient Relic"
			prompt.ObjectText = string.format("%s (%s)", nodeDef.description, zoneCfg.displayName)
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Parent = base

			nodeModel.Parent = nodesFolder
			nodeInstances[nodeDef.nodeId] = nodeModel
		end
	end
	print("[ExplorationService] Spawned all dynamic relic discovery nodes across 4 exploration zones.")
end

-- =============================================================================
-- RARITY-BASED LOOT ROLL & COLLECTION
-- =============================================================================

local function rollRarityForZone(zoneId: WorldZoneId, playerLuckBuff: number, isSurging: boolean): RelicRarity
	local zoneCfg = ZoneLootTables.Get(zoneId)
	if not zoneCfg then return "Common" end

	local weights = zoneCfg.rarityWeights
	local rollWeights = {
		Common = weights.Common,
		Uncommon = weights.Uncommon,
		Rare = weights.Rare,
		Epic = weights.Epic,
		Legendary = weights.Legendary,
		Mythic = weights.Mythic,
		Cursed = weights.Cursed,
	}

	-- Luck boosts elevate rare, epic, and legendary probabilities
	local luckFactor = 1.0 + playerLuckBuff + (if isSurging then 0.25 else 0)
	rollWeights.Rare = math.floor(rollWeights.Rare * luckFactor)
	rollWeights.Epic = math.floor(rollWeights.Epic * luckFactor)
	rollWeights.Legendary = math.floor(rollWeights.Legendary * luckFactor)
	rollWeights.Mythic = math.floor(rollWeights.Mythic * luckFactor)

	local totalWeight = 0
	for _, w in pairs(rollWeights) do totalWeight += w end
	if totalWeight <= 0 then return "Common" end

	local roll = math.random(1, totalWeight)
	local cumulative = 0

	-- Roll order from highest to lowest rarity
	local rarityOrder: { RelicRarity } = { "Mythic", "Cursed", "Legendary", "Epic", "Rare", "Uncommon", "Common" }
	for _, rName in ipairs(rarityOrder) do
		cumulative += rollWeights[rName]
		if roll <= cumulative and rollWeights[rName] > 0 then
			return rName
		end
	end

	return "Common"
end

function ExplorationService.HarvestRelicNode(player: Player, nodeId: string): (boolean, string, any)
	local nodeInfo = nodeZoneMap[nodeId]
	if not nodeInfo then
		return false, "Invalid relic spawn node ID: " .. tostring(nodeId), nil
	end

	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable.", nil
	end

	-- Distance validation (<= 18 studs)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		local dist = (hrp.Position - nodeInfo.position).Magnitude
		if dist > 20 then
			return false, string.format("Too far from relic node (Distance: %.1f studs).", dist), nil
		end
	else
		return false, "Character unavailable.", nil
	end

	-- Zone unlock validation
	if not profile.unlockedZones[nodeInfo.zoneId] then
		return false, string.format("You have not unlocked the %s yet!", nodeInfo.zoneId), nil
	end

	-- Node cooldown check
	local now = os.time()
	local lastLooted = activeNodeCooldowns[nodeId] or 0
	if now < lastLooted then
		local remaining = lastLooted - now
		return false, string.format("This relic node is depleted. Respawns in %d seconds.", remaining), nil
	end

	-- Check player luck buff from equipped relic
	local luckBuff = 0
	if profile.equippedRelicId then
		for _, inst in ipairs(profile.inventory) do
			if inst.instanceId == profile.equippedRelicId then
				local relicDef = RelicDefinitions.Get(inst.definitionId)
				if relicDef and relicDef.buff.buffType == "TreasureLuck" then
					luckBuff = relicDef.buff.magnitude
				end
				break
			end
		end
	end

	local isSurging = currentActiveSurge ~= nil and currentActiveSurge.zoneId == nodeInfo.zoneId
	local chosenRarity = rollRarityForZone(nodeInfo.zoneId, luckBuff, isSurging)

	-- Select a random relic matching the rolled rarity
	local candidateList = RelicDefinitions.GetByRarity(chosenRarity)
	if #candidateList == 0 then
		candidateList = RelicDefinitions.GetByRarity("Common")
	end
	local awardedDef = candidateList[math.random(1, #candidateList)]

	-- Check inventory capacity
	local isBackpackFull = #profile.inventory >= EconomyConfig.MAX_INVENTORY_CAPACITY
	local shardYield = awardedDef.incomeRateShards * 5 + math.random(5, 15)
	if isSurging then shardYield = math.floor(shardYield * (currentActiveSurge and currentActiveSurge.bonusShardMult or 1.5)) end

	if isBackpackFull then
		-- Salvage conversion fallback so player never loses their find!
		local salvageCash = awardedDef.baseValue + (awardedDef.incomeRateCash * 10)
		profile.currencies.Cash += salvageCash
		profile.currencies.RelicShards += shardYield
		EconomyService.SyncProfileToClient(player)

		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notif:FireClient(
			player,
			"Backpack Full — Salvaged!",
			string.format("Backpack full! Salvaged %s [%s] into +$%d Cash and +%d Shards!", awardedDef.name, chosenRarity, salvageCash, shardYield),
			"Warning"
		)
	else
		-- Add relic to inventory
		InventoryService.AddRelic(player, awardedDef.definitionId)
		profile.discoveredRelics[awardedDef.definitionId] = true
		profile.currencies.RelicShards += shardYield
		EconomyService.SyncProfileToClient(player)

		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notif:FireClient(
			player,
			"Relic Discovered!",
			string.format("Uncovered %s [%s]! (+%d Shards). Added to your collection.", awardedDef.name, chosenRarity, shardYield),
			"Success"
		)
	end

	-- Deplete node and set cooldown (75 seconds)
	local cooldownDuration = 75
	activeNodeCooldowns[nodeId] = now + cooldownDuration

	local nodeModel = nodeInstances[nodeId]
	if nodeModel then
		local orb = nodeModel:FindFirstChild("CuriosityOrb") :: BasePart?
		local base = nodeModel:FindFirstChild("NodeBase") :: BasePart?
		local prompt = base and base:FindFirstChild("ExcavatePrompt") :: ProximityPrompt?

		if prompt then prompt.Enabled = false end
		if orb then
			orb.Transparency = 0.8
			local light = orb:FindFirstChild("NodeGlow") :: PointLight?
			if light then light.Brightness = 0.2 end
		end

		task.delay(cooldownDuration, function()
			if prompt then prompt.Enabled = true end
			if orb then
				orb.Transparency = 0
				local light = orb:FindFirstChild("NodeGlow") :: PointLight?
				if light then light.Brightness = 2.0 end
			end
		end)
	end

	return true, string.format("Discovered %s [%s]!", awardedDef.name, chosenRarity), {
		relicId = awardedDef.definitionId,
		rarity = chosenRarity,
		shardsEarned = shardYield,
	}
end

-- =============================================================================
-- ROTATING TREASURE SURGES
-- =============================================================================

local function startTreasureSurgeCycle()
	task.spawn(function()
		local zoneKeys: { WorldZoneId } = { "ForgottenWilds", "SunkenVault", "AshenDomain", "CelestialRift" }
		local surgeIndex = 1

		while true do
			task.wait(360) -- Every 6 minutes, manifest a surge

			local pickedZone = zoneKeys[math.random(1, #zoneKeys)]
			local surgeType = ZoneLootTables.SurgeTypes[surgeIndex]
			surgeIndex = (surgeIndex % #ZoneLootTables.SurgeTypes) + 1

			local now = os.time()
			currentActiveSurge = {
				zoneId = pickedZone,
				surgeType = surgeType.surgeType,
				displayName = surgeType.displayName,
				bonusDescription = surgeType.bonusDescription,
				expiresAt = now + surgeType.durationSeconds,
				bonusShardMult = surgeType.bonusShardMultiplier,
				bonusLuck = surgeType.bonusLuckRating,
			}

			print(string.format("[ExplorationService] Active Surge: %s manifested in %s for %d seconds!",
				surgeType.displayName, pickedZone, surgeType.durationSeconds))

			-- Broadcast surge event to all 20 players
			local surgeEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.TreasureSurgeActive)
			surgeEvent:FireAllClients(pickedZone, surgeType.displayName, surgeType.bonusDescription, currentActiveSurge.expiresAt)

			local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
			notif:FireAllClients(
				string.format("⚡ %s!", string.upper(surgeType.displayName)),
				string.format("%s in %s! %s", surgeType.displayName, pickedZone, surgeType.bonusDescription),
				"Warning"
			)

			task.wait(surgeType.durationSeconds)
			currentActiveSurge = nil
		end
	end)
end

-- =============================================================================
-- LORE STELE & REGIONAL CACHE HARVESTING
-- =============================================================================

function ExplorationService.ReadLoreStele(player: Player, steleId: string?): (boolean, string)
	local id = steleId or "stele_chronicles"
	local steleData = LORE_STELES[id]
	if not steleData then return false, "Invalid lore stele ID." end

	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Player profile unavailable." end

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		local dist = (hrp.Position - steleData.pos).Magnitude
		if dist > 35 then
			return false, string.format("Too far from %s (Distance: %.1f studs).", steleData.name, dist)
		end
	end

	local firstTime = not profile.discoveredLore[id]
	profile.discoveredLore[id] = true

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	if firstTime then
		profile.currencies.Cash += steleData.rewardCash
		profile.currencies.RelicShards += steleData.rewardShards
		EconomyService.SyncProfileToClient(player)
		notif:FireClient(player, "Chronicles Deciphered!", string.format("Discovered %s (+%d Cash, +%d Shards)!", steleData.name, steleData.rewardCash, steleData.rewardShards), "Success")
	else
		notif:FireClient(player, steleData.name, "'" .. steleData.loreText .. "'", "Info")
	end

	return true, "Lore deciphered."
end

function ExplorationService.LootRegionalCache(player: Player, cacheId: string): (boolean, string)
	local cacheData = REGIONAL_CACHES[cacheId]
	if not cacheData then return false, "Invalid cache ID." end

	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Player profile unavailable." end

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		local dist = (hrp.Position - cacheData.pos).Magnitude
		if dist > 35 then
			return false, string.format("Too far from %s (Distance: %.1f studs).", cacheData.name, dist)
		end
	end

	local cdKey = tostring(player.UserId) .. "_" .. cacheId
	local lastLooted = cacheCooldowns[cdKey] or 0
	if os.time() - lastLooted < cacheData.cooldown then
		local remaining = cacheData.cooldown - (os.time() - lastLooted)
		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notif:FireClient(player, "Cache Depleted", string.format("%s was recently looted. Refills in %ds.", cacheData.name, remaining), "Info")
		return false, "Cache on cooldown."
	end

	cacheCooldowns[cdKey] = os.time()
	local rewardCash = math.random(cacheData.minCash, cacheData.maxCash)
	profile.currencies.Cash += rewardCash
	profile.currencies.RelicShards += cacheData.shards
	profile.discoveredCaches[cacheId] = true
	EconomyService.SyncProfileToClient(player)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(player, "Treasure Secured!", string.format("Looted %s: +%d Cash, +%d Relic Shards!", cacheData.name, rewardCash, cacheData.shards), "Success")

	return true, string.format("Looted %s (+%d Cash, +%d Shards).", cacheData.name, rewardCash, cacheData.shards)
end

function ExplorationService.LootTreasureUrn(player: Player, urnIndex: number): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Player profile unavailable." end

	local cdKey = tostring(player.UserId) .. "_" .. tostring(urnIndex)
	local lastLooted = urnCooldowns[cdKey] or 0
	if os.time() - lastLooted < 60 then
		local remaining = 60 - (os.time() - lastLooted)
		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notif:FireClient(player, "Urn Empty", string.format("This urn was recently looted. Refills in %ds.", remaining), "Info")
		return false, "Urn on cooldown."
	end

	urnCooldowns[cdKey] = os.time()
	local rewardCash = math.random(15, 30)
	profile.currencies.Cash += rewardCash
	EconomyService.SyncProfileToClient(player)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(player, "Salvage Found!", string.format("Searched ancient urn and salvaged %d Cash!", rewardCash), "Success")

	return true, string.format("Salvaged %d Cash.", rewardCash)
end

function ExplorationService.CommuneHourglassAltar(player: Player): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Player profile unavailable." end

	local cdKey = tostring(player.UserId) .. "_hourglass_altar"
	local lastLooted = altarCooldowns[cdKey] or 0
	if os.time() - lastLooted < 60 then
		return false, "Altar on cooldown."
	end

	altarCooldowns[cdKey] = os.time()
	local hasHourglass = false
	for _, inst in ipairs(profile.inventory) do
		if inst.definitionId == "relic_ancient_hourglass" then
			hasHourglass = true
			break
		end
	end

	if not hasHourglass and not profile.discoveredRelics["relic_ancient_hourglass"] then
		InventoryService.AddRelic(player, "relic_ancient_hourglass")
		profile.currencies.Cash += 150
		profile.currencies.RelicShards += 50
	else
		profile.currencies.Cash += 60
		profile.currencies.RelicShards += 25
	end
	EconomyService.SyncProfileToClient(player)
	return true, "Hourglass Altar communion completed."
end

function ExplorationService.CommuneHollowAltar(player: Player): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Player profile unavailable." end

	local cdKey = tostring(player.UserId) .. "_hollow_altar"
	local lastLooted = altarCooldowns[cdKey] or 0
	if os.time() - lastLooted < 90 then
		return false, "Altar on cooldown."
	end

	altarCooldowns[cdKey] = os.time()
	local hasCrown = false
	for _, inst in ipairs(profile.inventory) do
		if inst.definitionId == "relic_hollow_crown" then
			hasCrown = true
			break
		end
	end

	if not hasCrown and not profile.discoveredRelics["relic_hollow_crown"] then
		InventoryService.AddRelic(player, "relic_hollow_crown")
		profile.currencies.Cash += 500
		profile.currencies.RelicShards += 150
	else
		profile.currencies.Cash += 150
		profile.currencies.RelicShards += 50
	end
	EconomyService.SyncProfileToClient(player)
	return true, "Hollow Crown Altar communion completed."
end

function ExplorationService.LootCryptPlinth(player: Player): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Player profile unavailable." end

	local cdKey = tostring(player.UserId) .. "_crypt_plinth"
	local lastLooted = altarCooldowns[cdKey] or 0
	if os.time() - lastLooted < 90 then
		return false, "Plinth on cooldown."
	end

	altarCooldowns[cdKey] = os.time()
	profile.currencies.Cash += 75
	profile.currencies.RelicShards += 25
	EconomyService.SyncProfileToClient(player)
	return true, "Looted Imperial Crypt Plinth."
end

-- =============================================================================
-- SERVICE INITIALIZATION
-- =============================================================================

function ExplorationService.Init()
	local loreFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.InteractLoreStele)
	loreFn.OnServerInvoke = function(player: Player, steleId: any)
		local sId = if type(steleId) == "string" then steleId else "stele_chronicles"
		local ok, msg = ExplorationService.ReadLoreStele(player, sId)
		return { success = ok, message = msg }
	end

	local urnFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.LootTreasureUrn)
	urnFn.OnServerInvoke = function(player: Player, urnIdx: any)
		if type(urnIdx) ~= "number" then
			return { success = false, message = "Invalid urn index parameter." }
		end
		local ok, msg = ExplorationService.LootTreasureUrn(player, urnIdx)
		return { success = ok, message = msg }
	end

	local cacheFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.LootRegionalCache)
	cacheFn.OnServerInvoke = function(player: Player, cacheId: any)
		if type(cacheId) ~= "string" then
			return { success = false, message = "Invalid cache ID parameter." }
		end
		local ok, msg = ExplorationService.LootRegionalCache(player, cacheId)
		return { success = ok, message = msg }
	end

	local harvestFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.HarvestRelicNode)
	harvestFn.OnServerInvoke = function(player: Player, nodeId: any)
		if type(nodeId) ~= "string" then
			return { success = false, message = "Invalid node ID parameter." }
		end
		local ok, msg, data = ExplorationService.HarvestRelicNode(player, nodeId)
		return { success = ok, message = msg, data = data }
	end

	-- Spawn all dynamic relic discovery nodes and start surge cycle
	task.delay(2.0, function()
		ExplorationService.SpawnAllZoneNodes()
		startTreasureSurgeCycle()
	end)
end

return ExplorationService
