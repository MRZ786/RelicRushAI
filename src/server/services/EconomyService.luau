--!strict
-- EconomyService.luau
-- Authoritative currency transactions, pricing, and shop operations

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local EconomyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local RelicDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

local ProfileService = require(script.Parent.ProfileService)
local TransactionService = require(script.Parent.TransactionService)

local EconomyService = {}

function EconomyService.GetBalance(player: Player): (number, number)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return 0, 0
	end
	return profile.currencies.Cash, profile.currencies.RelicShards
end

function EconomyService.AddCash(player: Player, amount: number, reason: string?, idempotencyKey: string?): (boolean, string)
	if amount <= 0 then
		return false, "Invalid cash amount."
	end

	local reasonCode = reason or "AddCash"
	return TransactionService.Process(player, idempotencyKey, reasonCode, function()
		local profile = ProfileService.GetProfile(player)
		if not profile then
			return false, "Profile unavailable.", nil
		end

		profile.currencies.Cash += amount
		EconomyService.SyncProfileToClient(player)
		return true, "Cash added successfully.", profile.currencies.Cash
	end)
end

function EconomyService.SubtractCash(player: Player, amount: number, reason: string?, idempotencyKey: string?): (boolean, string)
	if amount <= 0 then
		return false, "Invalid cash amount."
	end

	local reasonCode = reason or "SubtractCash"
	return TransactionService.Process(player, idempotencyKey, reasonCode, function()
		local profile = ProfileService.GetProfile(player)
		if not profile then
			return false, "Profile unavailable.", nil
		end

		if profile.currencies.Cash < amount then
			return false, "Insufficient funds.", nil
		end

		profile.currencies.Cash -= amount
		EconomyService.SyncProfileToClient(player)
		return true, "Cash deducted successfully.", profile.currencies.Cash
	end)
end

function EconomyService.AddShards(player: Player, amount: number, reason: string?, idempotencyKey: string?): (boolean, string)
	if amount <= 0 then
		return false, "Invalid shard amount."
	end

	local reasonCode = reason or "AddShards"
	return TransactionService.Process(player, idempotencyKey, reasonCode, function()
		local profile = ProfileService.GetProfile(player)
		if not profile then
			return false, "Profile unavailable.", nil
		end

		profile.currencies.RelicShards += amount
		EconomyService.SyncProfileToClient(player)
		return true, "Relic Shards added successfully.", profile.currencies.RelicShards
	end)
end

function EconomyService.SubtractShards(player: Player, amount: number, reason: string?, idempotencyKey: string?): (boolean, string)
	if amount <= 0 then
		return false, "Invalid shard amount."
	end

	local reasonCode = reason or "SubtractShards"
	return TransactionService.Process(player, idempotencyKey, reasonCode, function()
		local profile = ProfileService.GetProfile(player)
		if not profile then
			return false, "Profile unavailable.", nil
		end

		if profile.currencies.RelicShards < amount then
			return false, "Insufficient Relic Shards.", nil
		end

		profile.currencies.RelicShards -= amount
		EconomyService.SyncProfileToClient(player)
		return true, "Relic Shards deducted successfully.", profile.currencies.RelicShards
	end)
end

function EconomyService.CalculateRelicSellValue(player: Player, definitionId: string, upgradeLevel: number?): number
	local relicDef = RelicDefinitions.Get(definitionId)
	if not relicDef then
		return 0
	end

	local baseValue = relicDef.baseValue
	local lvl = upgradeLevel or 1
	if lvl == 2 then
		baseValue = math.floor(baseValue * 1.35)
	elseif lvl >= 3 then
		baseValue = math.floor(baseValue * 1.75)
	end

	local profile = ProfileService.GetProfile(player)
	if profile and profile.equippedRelicId then
		for _, inst in ipairs(profile.inventory) do
			if inst.instanceId == profile.equippedRelicId then
				local equippedDef = RelicDefinitions.Get(inst.definitionId)
				if equippedDef and equippedDef.buff.buffType == "SaleBonus" then
					local eqLvl = inst.upgradeLevel or 1
					local mult = if eqLvl == 2 then 1.5 elseif eqLvl >= 3 then 2.0 else 1.0
					baseValue = math.floor(baseValue * (1 + (equippedDef.buff.magnitude * mult)))
				end
				break
			end
		end
	end

	return baseValue
end

function EconomyService.SellRelic(player: Player, instanceId: string, idempotencyKey: string?): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Profile unavailable."
	end

	-- Check if player owns this relic
	local targetInst = nil
	for _, inst in ipairs(profile.inventory) do
		if inst.instanceId == instanceId then
			targetInst = inst
			break
		end
	end

	if not targetInst then
		return false, "Relic instance not found in your inventory."
	end

	local sellPrice = EconomyService.CalculateRelicSellValue(player, targetInst.definitionId, targetInst.upgradeLevel)
	local InventoryService = require(script.Parent.InventoryService)

	local success, message = TransactionService.Process(player, idempotencyKey, "SellRelic", function()
		local removeOk, removeMsg, removedItem = InventoryService.RemoveRelic(player, instanceId)
		if not removeOk or not removedItem then
			return false, removeMsg, nil
		end

		profile.currencies.Cash += sellPrice
		EconomyService.SyncProfileToClient(player)

		return true, string.format("Sold for %d Cash.", sellPrice), profile.currencies.Cash
	end)

	return success, message
end

function EconomyService.BuyShopItem(player: Player, itemId: string, idempotencyKey: string?): (boolean, string)
	local shopItem = EconomyConfig.GetItem(itemId)
	if not shopItem then
		return false, "Item does not exist in catalog."
	end

	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Profile unavailable."
	end

	if profile.currencies.Cash < shopItem.priceCash then
		return false, string.format("Insufficient Cash (Cost: %d, You have: %d).", shopItem.priceCash, profile.currencies.Cash)
	end

	local success, message = TransactionService.Process(player, idempotencyKey, "BuyShopItem:" .. itemId, function()
		profile.currencies.Cash -= shopItem.priceCash

		-- If it's a decoration item, add to available placed/inventory
		if shopItem.category == "Decoration" then
			-- Record as unlocked decoration in baseData
			table.insert(profile.baseData.placedObjects, {
				placementId = game:GetService("HttpService"):GenerateGUID(false),
				itemId = itemId,
				position = Vector3.new(0, 1, 0),
				rotationY = 0,
			})
		end

		EconomyService.SyncProfileToClient(player)
		local questServiceModule = script.Parent:FindFirstChild("QuestService")
		if questServiceModule then
			local QuestService = require(questServiceModule :: ModuleScript) :: any
			QuestService.RecordEvent(player, "item_purchased")
		end
		return true, string.format("Purchased %s for %d Cash.", shopItem.name, shopItem.priceCash), nil
	end)

	return success, message
end

function EconomyService.SyncProfileToClient(player: Player)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return
	end

	local updateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.ProfileUpdated)
	updateEvent:FireClient(player, profile)
end

function EconomyService.Init()
	-- Wire up remote functions
	local buyFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestBuyItem)
	buyFn.OnServerInvoke = function(player: Player, itemId: any, idempotencyKey: any)
		if type(itemId) ~= "string" then
			return { success = false, message = "Malformed itemId." }
		end
		local ok, msg = EconomyService.BuyShopItem(player, itemId, if type(idempotencyKey) == "string" then idempotencyKey else nil)
		return { success = ok, message = msg, profile = ProfileService.GetProfile(player) }
	end

	local sellFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestSellRelic)
	sellFn.OnServerInvoke = function(player: Player, instanceId: any, idempotencyKey: any)
		if type(instanceId) ~= "string" then
			return { success = false, message = "Malformed instanceId." }
		end
		local ok, msg = EconomyService.SellRelic(player, instanceId, if type(idempotencyKey) == "string" then idempotencyKey else nil)
		return { success = ok, message = msg, profile = ProfileService.GetProfile(player) }
	end

	local getProfileFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.GetPlayerProfile)
	getProfileFn.OnServerInvoke = function(player: Player)
		return ProfileService.GetProfile(player)
	end

	local tutFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.CompleteTutorialStep)
	tutFn.OnServerInvoke = function(player: Player, step: any)
		local profile = ProfileService.GetProfile(player)
		if not profile then
			return { success = false, message = "Profile unavailable." }
		end
		if type(step) == "number" and step > profile.tutorialStep then
			profile.tutorialStep = step
			if step >= 4 then
				profile.completedTutorial = true
			end
			EconomyService.SyncProfileToClient(player)
		end
		return { success = true, tutorialStep = profile.tutorialStep, completedTutorial = profile.completedTutorial }
	end
end

return EconomyService
