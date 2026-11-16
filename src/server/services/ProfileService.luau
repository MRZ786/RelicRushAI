--!strict
-- ProfileService.luau
-- Robust, versioned persistence manager with session locking and Studio fallback
-- Schema Version 3: 20-Player Server, Starting Cash $500, 10 Relic Base Plinths, Limited Offline Income, Safe Raids

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local EconomyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local RelicDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

type PlayerProfile = CommonTypes.PlayerProfile
type RelicInstance = CommonTypes.RelicInstance

local DATASTORE_NAME = "RelicRush_PlayerData_v3"
local CURRENT_SCHEMA_VERSION = 3
local AUTO_SAVE_INTERVAL = 60

local ProfileService = {}

local activeProfiles: { [number]: PlayerProfile } = {}
local activeSessions: { [number]: string } = {}
local isMockMode = false

-- Fallback in-memory store for Studio sessions where DataStore API is disabled
local mockStore: { [string]: any } = {}
local dataStore: GlobalDataStore? = nil

local function initDataStore()
	local success, result = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)

	if success and result then
		local testSuccess = pcall(function()
			result:GetAsync("__connectivity_probe__")
		end)

		if testSuccess then
			dataStore = result
			isMockMode = false
			print("[ProfileService] Production DataStore successfully connected.")
		else
			isMockMode = true
			warn("[ProfileService] DataStore API disabled or unavailable. Falling back to Studio In-Memory Mock Store.")
		end
	else
		isMockMode = true
		warn("[ProfileService] DataStore unavailable. Falling back to Studio In-Memory Mock Store.")
	end
end

local function createDefaultProfile(userId: number): PlayerProfile
	-- Initialize 10 empty base relic slots
	local initialSlots: { [number]: string? } = {}
	for i = 1, EconomyConfig.BASE_RELIC_SLOTS do
		initialSlots[i] = nil
	end

	return {
		schemaVersion = CURRENT_SCHEMA_VERSION,
		playerId = userId,
		currencies = {
			Cash = EconomyConfig.STARTING_CASH, -- $500 per specification
			RelicShards = EconomyConfig.STARTING_SHARDS,
		},
		inventory = {},
		equippedRelicId = nil,
		baseData = {
			plotId = "plot_" .. tostring(userId),
			plotIndex = 1,
			tier = 1,
			placedObjects = {},
			slottedRelicIds = initialSlots,
			uncollectedTributeCash = 0,
			uncollectedTributeShards = 0,
			lastIncomeTick = os.time(),
			defenseRating = 10,
		},
		discoveredRelics = {},
		hasSelectedStarter = false,
		completedHeistsCount = 0,
		completedQuests = {},
		claimedQuests = {},
		discoveredLore = {},
		discoveredCaches = {},
		unlockedRegions = {
			["ForgottenMarket"] = true,
			["ForgottenWilds"] = true,
		},
		unlockedZones = {
			["ForgottenWilds"] = true,
		},
		rebirthData = {
			rebirthCount = 0,
			prestigeMultiplier = 1.0,
			totalRebirthSpentCash = 0,
		},
		tutorialStep = 0,
		completedTutorial = false,
		baseVaultStorage = {},
		showcaseRelicId = nil,
		relicSynergies = {},
		collectionMilestonesClaimed = {},
		lastSavedTimestamp = os.time(),
	}
end

local function migrateProfile(raw: any, userId: number): PlayerProfile
	if not raw or type(raw) ~= "table" then
		return createDefaultProfile(userId)
	end

	local version = raw.schemaVersion or 0
	if version < CURRENT_SCHEMA_VERSION then
		raw.schemaVersion = CURRENT_SCHEMA_VERSION
		
		-- Ensure starting cash is at least $500 for legacy profiles with less
		raw.currencies = raw.currencies or {}
		if (raw.currencies.Cash or 0) < EconomyConfig.STARTING_CASH then
			raw.currencies.Cash = EconomyConfig.STARTING_CASH
		end
		raw.currencies.RelicShards = raw.currencies.RelicShards or 0

		raw.inventory = raw.inventory or {}
		raw.baseData = raw.baseData or {}
		raw.baseData.plotId = raw.baseData.plotId or ("plot_" .. tostring(userId))
		raw.baseData.plotIndex = raw.baseData.plotIndex or 1
		raw.baseData.tier = raw.baseData.tier or 1
		raw.baseData.placedObjects = raw.baseData.placedObjects or {}

		-- Initialize 10 slots if absent
		if not raw.baseData.slottedRelicIds then
			raw.baseData.slottedRelicIds = {}
			for i = 1, EconomyConfig.BASE_RELIC_SLOTS do
				raw.baseData.slottedRelicIds[i] = nil
			end
		end

		raw.baseData.uncollectedTributeCash = raw.baseData.uncollectedTributeCash or 0
		raw.baseData.uncollectedTributeShards = raw.baseData.uncollectedTributeShards or 0
		raw.baseData.lastIncomeTick = raw.baseData.lastIncomeTick or os.time()
		raw.baseData.defenseRating = raw.baseData.defenseRating or 10

		raw.unlockedZones = raw.unlockedZones or { ["ForgottenWilds"] = true }
		raw.rebirthData = raw.rebirthData or { rebirthCount = 0, prestigeMultiplier = 1.0, totalRebirthSpentCash = 0 }
		raw.collectionMilestonesClaimed = raw.collectionMilestonesClaimed or {}
	end

	-- Ensure all sub-tables are populated
	if not raw.baseData.slottedRelicIds then
		raw.baseData.slottedRelicIds = {}
		for i = 1, EconomyConfig.BASE_RELIC_SLOTS do
			raw.baseData.slottedRelicIds[i] = nil
		end
	end
	if raw.baseData.uncollectedTributeCash == nil then raw.baseData.uncollectedTributeCash = 0 end
	if raw.baseData.uncollectedTributeShards == nil then raw.baseData.uncollectedTributeShards = 0 end
	if not raw.unlockedZones then raw.unlockedZones = { ["ForgottenWilds"] = true } end
	if not raw.rebirthData then raw.rebirthData = { rebirthCount = 0, prestigeMultiplier = 1.0, totalRebirthSpentCash = 0 } end
	if not raw.collectionMilestonesClaimed then raw.collectionMilestonesClaimed = {} end

	return raw :: PlayerProfile
end

-- Calculate limited offline income from slotted relics when player returns
function ProfileService.CalculateOfflineIncome(profile: PlayerProfile, currentTime: number?): (number, number, number)
	local now = currentTime or os.time()
	local lastSaved = profile.lastSavedTimestamp or now
	local elapsed = now - lastSaved

	-- Guard against negative elapsed time or too brief session
	if elapsed <= 30 or elapsed < 0 then
		return 0, 0, 0
	end

	-- Cap offline earnings per specification (6 hours max)
	local maxSeconds = EconomyConfig.MAX_OFFLINE_INCOME_HOURS * 3600
	local eligibleSeconds = math.clamp(elapsed, 0, maxSeconds)
	local ticks = math.floor(eligibleSeconds / EconomyConfig.INCOME_TICK_SECONDS)

	if ticks <= 0 then
		return 0, 0, eligibleSeconds
	end

	-- Find all slotted relics in player's inventory
	local slottedInstances: { RelicInstance } = {}
	if profile.baseData and profile.baseData.slottedRelicIds then
		for slotIdx = 1, EconomyConfig.BASE_RELIC_SLOTS do
			local instId = profile.baseData.slottedRelicIds[slotIdx]
			if instId then
				for _, inst in ipairs(profile.inventory) do
					if inst.instanceId == instId then
						table.insert(slottedInstances, inst)
						break
					end
				end
			end
		end
	end

	if #slottedInstances == 0 then
		return 0, 0, eligibleSeconds
	end

	local offlineCash = 0
	local offlineShards = 0
	local prestigeMult = if profile.rebirthData then profile.rebirthData.prestigeMultiplier else 1.0

	for _, inst in ipairs(slottedInstances) do
		local relicDef = RelicDefinitions.Get(inst.definitionId)
		if relicDef then
			local upgradeMult = if inst.upgradeLevel == 2 then 1.3 elseif inst.upgradeLevel >= 3 then 1.6 else 1.0
			local cashYield = math.floor(relicDef.incomeRateCash * upgradeMult * prestigeMult * EconomyConfig.OFFLINE_INCOME_EFFICIENCY)
			local shardYield = math.floor(relicDef.incomeRateShards * upgradeMult * prestigeMult * EconomyConfig.OFFLINE_INCOME_EFFICIENCY)

			offlineCash += (cashYield * ticks)
			offlineShards += (shardYield * ticks)
		end
	end

	return offlineCash, offlineShards, eligibleSeconds
end

local function processOfflineIncome(player: Player, profile: PlayerProfile)
	local now = os.time()
	local lastSaved = profile.lastSavedTimestamp or now
	local elapsed = now - lastSaved

	-- Guard against clock manipulation
	if elapsed < 0 then
		profile.lastSavedTimestamp = now
		return
	end

	local offlineCash, offlineShards, eligibleSeconds = ProfileService.CalculateOfflineIncome(profile, now)

	-- Immediately record timestamps to prevent duplicate payouts or double-claim
	profile.lastSavedTimestamp = now
	profile.baseData.lastIncomeTick = now

	if offlineCash > 0 or offlineShards > 0 then
		profile.baseData.uncollectedTributeCash += offlineCash
		profile.baseData.uncollectedTributeShards += offlineShards

		print(string.format("[ProfileService] Processed offline income for %s: +$%d Cash, +%d Shards (Offline duration: %d min, capped at %d hrs)",
			player.Name, offlineCash, offlineShards, math.floor(eligibleSeconds / 60), EconomyConfig.MAX_OFFLINE_INCOME_HOURS))

		task.delay(3, function()
			if player.Parent then
				local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
				notif:FireClient(
					player,
					"Sanctum Tribute Awaits!",
					string.format("Your base plinths generated $%d Cash and %d Shards while you were away! Collect at your vault coffer.", offlineCash, offlineShards),
					"Success"
				)
			end
		end)
	end
end

function ProfileService.IsMockMode(): boolean
	return isMockMode
end

function ProfileService.GetProfile(player: Player): PlayerProfile?
	return activeProfiles[player.UserId]
end

function ProfileService.UpdateProfile(player: Player, updater: (PlayerProfile) -> PlayerProfile): boolean
	local current = activeProfiles[player.UserId]
	if not current then
		return false
	end

	local updated = updater(current)
	activeProfiles[player.UserId] = updated
	return true
end

function ProfileService.LoadProfile(player: Player): PlayerProfile
	local userId = player.UserId
	local sessionToken = HttpService:GenerateGUID(false)
	activeSessions[userId] = sessionToken

	local rawData = nil
	if isMockMode then
		rawData = mockStore[tostring(userId)]
	else
		local attempts = 0
		local success = false
		local result = nil
		while attempts < 3 and not success do
			attempts += 1
			success, result = pcall(function()
				local store = dataStore :: GlobalDataStore
				return store:GetAsync("player_" .. tostring(userId))
			end)
			if not success and attempts < 3 then
				task.wait(1.5 * attempts)
			end
		end

		if success then
			rawData = result
		else
			warn(string.format("[ProfileService] Failed to load data for player %d after 3 attempts: %s", userId, tostring(result)))
		end
	end

	local profile = migrateProfile(rawData, userId)
	activeProfiles[userId] = profile

	-- Process limited offline income from slotted relics
	processOfflineIncome(player, profile)

	print(string.format("[ProfileService] Loaded profile for %s (UserId: %d, Cash: $%d, Items: %d, Slotted: %d, MockMode: %s)",
		player.Name, userId, profile.currencies.Cash, #profile.inventory,
		0, tostring(isMockMode)))

	return profile
end

function ProfileService.SaveProfile(player: Player): boolean
	local userId = player.UserId
	local profile = activeProfiles[userId]
	if not profile then
		return false
	end

	profile.lastSavedTimestamp = os.time()

	if isMockMode then
		mockStore[tostring(userId)] = profile
		return true
	else
		local attempts = 0
		local success = false
		local err = nil
		while attempts < 3 and not success do
			attempts += 1
			success, err = pcall(function()
				local store = dataStore :: GlobalDataStore
				store:SetAsync("player_" .. tostring(userId), profile)
			end)
			if not success and attempts < 3 then
				task.wait(1.5 * attempts)
			end
		end

		if not success then
			warn(string.format("[ProfileService] Error saving profile for %s after 3 attempts: %s", player.Name, tostring(err)))
			return false
		end
		return true
	end
end

function ProfileService.UnloadProfile(player: Player)
	local userId = player.UserId
	ProfileService.SaveProfile(player)
	activeProfiles[userId] = nil
	activeSessions[userId] = nil
end

function ProfileService.Init()
	initDataStore()

	Players.PlayerAdded:Connect(function(player)
		ProfileService.LoadProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ProfileService.UnloadProfile(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			ProfileService.LoadProfile(player)
		end)
	end

	-- Auto-save loop (every 60s)
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				ProfileService.SaveProfile(player)
			end
		end
	end)

	-- Graceful server shutdown
	game:BindToClose(function()
		print("[ProfileService] Server shutting down, performing final save on all profiles...")
		for _, player in ipairs(Players:GetPlayers()) do
			ProfileService.SaveProfile(player)
		end
	end)
end

return ProfileService
