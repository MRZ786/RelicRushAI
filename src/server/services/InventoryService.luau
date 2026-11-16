--!strict
-- InventoryService.luau
-- Authoritative inventory management, unique instance IDs, and relic buff application
-- Manages wearable Hollow Crown visuals, active stat adjustments, and collection tracking.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local RelicDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local MilestoneDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("MilestoneDefinitions"))
local EconomyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local ProfileService = require(script.Parent.ProfileService)
local EconomyService = require(script.Parent.EconomyService)
local TransactionService = require(script.Parent.TransactionService)
local RelicMeshBuilder = require(script.Parent.Parent.world.RelicMeshBuilder)

type RelicInstance = CommonTypes.RelicInstance
type RelicDefinition = CommonTypes.RelicDefinition

local InventoryService = {}

local BASE_WALKSPEED = 16
local BASE_MAX_HEALTH = 100

function InventoryService.ApplyActiveBuffs(player: Player, character: Model)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return
	end

	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not humanoid then
		return
	end

	-- Reset base stats
	humanoid.WalkSpeed = BASE_WALKSPEED
	humanoid.MaxHealth = BASE_MAX_HEALTH

	-- Clean any existing wearable visual
	local oldVisual = character:FindFirstChild("EquippedRelicVisual")
	if oldVisual then
		oldVisual:Destroy()
	end
	local oldCrown = character:FindFirstChild("WearableHollowCrown")
	if oldCrown then
		oldCrown:Destroy()
	end

	if not profile.equippedRelicId then
		return
	end

	-- Find equipped relic instance
	local equippedInstance: RelicInstance? = nil
	for _, inst in ipairs(profile.inventory) do
		if inst.instanceId == profile.equippedRelicId then
			equippedInstance = inst
			break
		end
	end

	if not equippedInstance then
		profile.equippedRelicId = nil
		return
	end

	local relicDef = RelicDefinitions.Get(equippedInstance.definitionId)
	if not relicDef then
		return
	end

	local lvl = equippedInstance.upgradeLevel or 1
	local refineMultiplier = if lvl == 2 then 1.3 elseif lvl >= 3 then 1.6 else 1.0

	if relicDef.buff.buffType == "SpeedBoost" then
		humanoid.WalkSpeed = BASE_WALKSPEED * (1 + (relicDef.buff.magnitude * refineMultiplier))
	elseif relicDef.buff.buffType == "HealthBoost" then
		humanoid.MaxHealth = BASE_MAX_HEALTH + math.floor(relicDef.buff.magnitude * refineMultiplier)
		humanoid.Health = humanoid.MaxHealth
	end

	-- Attach 3D visible equipped relic model with particle auras
	RelicMeshBuilder.AttachEquippedRelic(character, relicDef.definitionId)
end

function InventoryService.AddRelic(player: Player, definitionId: string): (boolean, string, RelicInstance?)
	local relicDef = RelicDefinitions.Get(definitionId)
	if not relicDef then
		return false, "Unknown relic definition: " .. definitionId, nil
	end

	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable.", nil
	end

	if #profile.inventory >= EconomyConfig.MAX_INVENTORY_CAPACITY then
		return false, "Inventory is full (Capacity: " .. tostring(EconomyConfig.MAX_INVENTORY_CAPACITY) .. ").", nil
	end

	local newInstance: RelicInstance = {
		instanceId = HttpService:GenerateGUID(false),
		definitionId = definitionId,
		ownerId = player.UserId,
		acquiredAt = os.time(),
		upgradeLevel = 1,
		isEquipped = false,
	}

	table.insert(profile.inventory, newInstance)
	profile.discoveredRelics[definitionId] = true

	print(string.format("[InventoryService] Granted %s (Instance: %s) to %s",
		relicDef.name, newInstance.instanceId, player.Name))

	return true, "Relic added to inventory.", newInstance
end

function InventoryService.RemoveRelic(player: Player, instanceId: string): (boolean, string, RelicInstance?)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable.", nil
	end

	local targetIndex = nil
	local targetInstance = nil
	for i, inst in ipairs(profile.inventory) do
		if inst.instanceId == instanceId then
			targetIndex = i
			targetInstance = inst
			break
		end
	end

	if not targetIndex or not targetInstance then
		return false, "Relic instance not found in inventory.", nil
	end

	if profile.equippedRelicId == instanceId then
		InventoryService.UnequipRelic(player)
	end

	table.remove(profile.inventory, targetIndex)
	return true, "Relic removed.", targetInstance
end

function InventoryService.EquipRelic(player: Player, instanceId: string): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	local found = false
	for _, inst in ipairs(profile.inventory) do
		if inst.instanceId == instanceId then
			inst.isEquipped = true
			found = true
		else
			inst.isEquipped = false
		end
	end

	if not found then
		return false, "Relic not found in player inventory."
	end

	profile.equippedRelicId = instanceId

	if player.Character then
		InventoryService.ApplyActiveBuffs(player, player.Character)
	end

	local updateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.ProfileUpdated)
	updateEvent:FireClient(player, profile)

	return true, "Relic equipped."
end

function InventoryService.UnequipRelic(player: Player): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	for _, inst in ipairs(profile.inventory) do
		inst.isEquipped = false
	end

	profile.equippedRelicId = nil

	if player.Character then
		InventoryService.ApplyActiveBuffs(player, player.Character)
	end

	local updateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.ProfileUpdated)
	updateEvent:FireClient(player, profile)

	return true, "Relic unequipped."
end

function InventoryService.UpdateSynergies(player: Player)
	local profile = ProfileService.GetProfile(player)
	if not profile then return end

	local ownedDefIds: { [string]: boolean } = {}
	for _, inst in ipairs(profile.inventory) do
		ownedDefIds[inst.definitionId] = true
	end

	local activeSynergies = RelicDefinitions.GetSynergiesForInventory(ownedDefIds)
	local synergyNames: { string } = {}
	for _, syn in ipairs(activeSynergies) do
		table.insert(synergyNames, syn.name)
	end
	profile.relicSynergies = synergyNames
end

function InventoryService.RefineRelic(player: Player, instanceId: string): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	local targetInstance: RelicInstance? = nil
	for _, inst in ipairs(profile.inventory) do
		if inst.instanceId == instanceId then
			targetInstance = inst
			break
		end
	end

	if not targetInstance then
		return false, "Relic not found in inventory."
	end

	local currentLvl = targetInstance.upgradeLevel or 1
	if currentLvl >= 3 then
		return false, "This relic has already reached maximum refinement (Level 3)."
	end

	local costShards = if currentLvl == 1 then 25 else 60
	if profile.currencies.RelicShards < costShards then
		return false, string.format("Insufficient Relic Shards (Requires %d Shards, you have %d).", costShards, profile.currencies.RelicShards)
	end

	profile.currencies.RelicShards -= costShards
	targetInstance.upgradeLevel = currentLvl + 1

	if player.Character and profile.equippedRelicId == instanceId then
		InventoryService.ApplyActiveBuffs(player, player.Character)
	end

	local questServiceModule = script.Parent:FindFirstChild("QuestService")
	if questServiceModule then
		local QuestService = require(questServiceModule :: ModuleScript) :: any
		QuestService.EvaluateQuests(player)
	end

	local updateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.ProfileUpdated)
	updateEvent:FireClient(player, profile)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(player, "Relic Refined!", string.format("Upgraded to Level %d! (-%d Shards)", targetInstance.upgradeLevel, costShards), "Success")

	return true, string.format("Relic refined to Level %d.", targetInstance.upgradeLevel)
end

function InventoryService.DepositToVault(player: Player, instanceId: string): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	local targetIdx = nil
	local targetInst = nil
	for i, inst in ipairs(profile.inventory) do
		if inst.instanceId == instanceId then
			targetIdx = i
			targetInst = inst
			break
		end
	end

	if not targetIdx or not targetInst then
		return false, "Relic not found in player inventory."
	end

	if profile.equippedRelicId == instanceId then
		InventoryService.UnequipRelic(player)
	end

	table.remove(profile.inventory, targetIdx)
	if not profile.baseVaultStorage then
		profile.baseVaultStorage = {}
	end
	table.insert(profile.baseVaultStorage, targetInst)

	InventoryService.UpdateSynergies(player)

	local updateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.ProfileUpdated)
	updateEvent:FireClient(player, profile)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(player, "Vault Deposit", "Relic deposited into base storage vault.", "Info")

	return true, "Relic deposited into base vault."
end

function InventoryService.WithdrawFromVault(player: Player, instanceId: string): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	if #profile.inventory >= EconomyConfig.MAX_INVENTORY_CAPACITY then
		return false, "Inventory is full. Deposit or sell items before withdrawing."
	end

	if not profile.baseVaultStorage then
		return false, "Base vault is empty."
	end

	local targetIdx = nil
	local targetInst = nil
	for i, inst in ipairs(profile.baseVaultStorage) do
		if inst.instanceId == instanceId then
			targetIdx = i
			targetInst = inst
			break
		end
	end

	if not targetIdx or not targetInst then
		return false, "Relic not found in base vault."
	end

	table.remove(profile.baseVaultStorage, targetIdx)
	table.insert(profile.inventory, targetInst)

	InventoryService.UpdateSynergies(player)

	local updateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.ProfileUpdated)
	updateEvent:FireClient(player, profile)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(player, "Vault Withdrawal", "Relic retrieved into inventory.", "Info")

	return true, "Relic withdrawn from base vault."
end

function InventoryService.SetShowcaseRelic(player: Player, instanceId: string?): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	profile.showcaseRelicId = instanceId

	local updateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.ProfileUpdated)
	updateEvent:FireClient(player, profile)

	return true, "Showcase relic updated."
end

function InventoryService.IsMilestoneCompleted(profile: CommonTypes.PlayerProfile, milestoneId: string): boolean
	local def = MilestoneDefinitions.Get(milestoneId)
	if not def then
		return false
	end

	if def.category == "DiscoveryCount" then
		local count = 0
		for _ in pairs(profile.discoveredRelics or {}) do
			count += 1
		end
		return count >= (def.targetCount or 1)
	elseif def.category == "RarityTier" then
		for relId in pairs(profile.discoveredRelics or {}) do
			local relDef = RelicDefinitions.Get(relId)
			if relDef and relDef.rarity == def.targetRarity then
				return true
			end
		end
		return false
	elseif def.category == "SignatureRelic" then
		local targetId = def.targetRelicId or "relic_hollow_crown"
		return profile.discoveredRelics ~= nil and profile.discoveredRelics[targetId] == true
	end

	return false
end

function InventoryService.ClaimMilestoneReward(player: Player, milestoneId: string): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	local def = MilestoneDefinitions.Get(milestoneId)
	if not def then
		return false, "Unknown milestone ID: " .. tostring(milestoneId)
	end

	if not profile.collectionMilestonesClaimed then
		profile.collectionMilestonesClaimed = {}
	end

	if profile.collectionMilestonesClaimed[milestoneId] then
		return false, "Milestone reward has already been claimed."
	end

	if not InventoryService.IsMilestoneCompleted(profile, milestoneId) then
		return false, "Milestone completion criteria have not been met."
	end

	-- Mark claimed atomically on server
	profile.collectionMilestonesClaimed[milestoneId] = true

	-- Award authoritative rewards
	if def.rewardCash > 0 then
		EconomyService.AddCash(player, def.rewardCash)
	end
	if def.rewardShards > 0 then
		EconomyService.AddShards(player, def.rewardShards)
	end

	-- Notify and sync
	local updateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.ProfileUpdated)
	updateEvent:FireClient(player, profile)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.ShowNotification)
	local titleMsg = if def.rewardTitle then " | Title: [" .. def.rewardTitle .. "]" else ""
	notif:FireClient(player, "Milestone Claimed!", string.format("Claimed '%s' (+$%d, +%d Shards%s)", def.title, def.rewardCash, def.rewardShards, titleMsg), "Success")

	return true, "Milestone reward claimed successfully."
end

function InventoryService.Init()
	-- Wire character spawning to re-apply active relic buffs
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.2)
			InventoryService.ApplyActiveBuffs(player, character)
		end)
	end)

	local equipFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestEquipRelic)
	equipFn.OnServerInvoke = function(player: Player, instanceId: any)
		if type(instanceId) ~= "string" then
			return { success = false, message = "Invalid relic instance ID." }
		end
		local ok, msg = InventoryService.EquipRelic(player, instanceId)
		return { success = ok, message = msg }
	end

	local unequipFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestUnequipRelic)
	unequipFn.OnServerInvoke = function(player: Player)
		local ok, msg = InventoryService.UnequipRelic(player)
		return { success = ok, message = msg }
	end

	local refineFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestRefineRelic)
	refineFn.OnServerInvoke = function(player: Player, instanceId: any)
		if type(instanceId) ~= "string" then
			return { success = false, message = "Invalid relic instance ID." }
		end
		local ok, msg = InventoryService.RefineRelic(player, instanceId)
		return { success = ok, message = msg }
	end

	local depositFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestDepositVault)
	depositFn.OnServerInvoke = function(player: Player, instanceId: any)
		if type(instanceId) ~= "string" then
			return { success = false, message = "Invalid relic instance ID." }
		end
		local ok, msg = InventoryService.DepositToVault(player, instanceId)
		return { success = ok, message = msg }
	end

	local withdrawFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestWithdrawVault)
	withdrawFn.OnServerInvoke = function(player: Player, instanceId: any)
		if type(instanceId) ~= "string" then
			return { success = false, message = "Invalid relic instance ID." }
		end
		local ok, msg = InventoryService.WithdrawFromVault(player, instanceId)
		return { success = ok, message = msg }
	end

	local showcaseFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestSetShowcaseRelic)
	showcaseFn.OnServerInvoke = function(player: Player, instanceId: any)
		local instId = if type(instanceId) == "string" then instanceId else nil
		local ok, msg = InventoryService.SetShowcaseRelic(player, instId)
		return { success = ok, message = msg }
	end

	local milestoneFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.ClaimCollectionMilestone)
	milestoneFn.OnServerInvoke = function(player: Player, milestoneId: any)
		if type(milestoneId) ~= "string" then
			return { success = false, message = "Invalid milestone ID." }
		end
		local ok, msg = InventoryService.ClaimMilestoneReward(player, milestoneId)
		return { success = ok, message = msg }
	end
end

return InventoryService
