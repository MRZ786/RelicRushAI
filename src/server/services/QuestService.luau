--!strict
-- QuestService.luau
-- Authoritative quest progression engine, milestone tracking, and reward disbursement
-- Supports 12 Progression Quests, Daily Objectives, and Repeatables with server validation.

local Players = game:GetService("Players")

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local QuestDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("QuestDefinitions"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

local ProfileService = require(script.Parent.ProfileService)
local EconomyService = require(script.Parent.EconomyService)
local TransactionService = require(script.Parent.TransactionService)

local QuestService = {}

function QuestService.EvaluateQuests(player: Player)
	local profile = ProfileService.GetProfile(player)
	if not profile then return end

	local changed = false

	-- Quest 1: The Calling
	if profile.hasSelectedStarter and not profile.completedQuests["quest_the_calling"] then
		profile.completedQuests["quest_the_calling"] = true
		changed = true
	end

	-- Quest 2: Wilds Expedition (Discovered at least 2 relics or excavated from wilds)
	local relicCount = 0
	for _ in pairs(profile.discoveredRelics) do relicCount += 1 end
	if (relicCount >= 2 or #profile.inventory >= 2 or profile.discoveredCaches["cache_wilds_offering"]) and not profile.completedQuests["quest_wilds_discovery"] then
		profile.completedQuests["quest_wilds_discovery"] = true
		changed = true
	end

	-- Quest 3: Claim Your Sanctum (Placed at least 1 object on plot)
	if #profile.baseData.placedObjects >= 1 and not profile.completedQuests["quest_claim_sanctum"] then
		profile.completedQuests["quest_claim_sanctum"] = true
		changed = true
	end

	-- Quest 4: Plinth Attunement (Slotted at least 1 relic on a base plinth)
	local hasSlotted = false
	for _, instId in pairs(profile.baseData.slottedRelicIds) do
		if instId ~= nil then
			hasSlotted = true
			break
		end
	end
	if hasSlotted and not profile.completedQuests["quest_plinth_attunement"] then
		profile.completedQuests["quest_plinth_attunement"] = true
		changed = true
	end

	-- Quest 5: Vault Tithe (Collected passive income at least once)
	-- Verified via recordEvent or if cash exceeds starting + initial quest payouts
	if profile.currencies.Cash > 600 and not profile.completedQuests["quest_tribute_tithe"] then
		profile.completedQuests["quest_tribute_tithe"] = true
		changed = true
	end

	-- Quest 6: Fortify Sanctum (Base defense rating reaches 25+)
	if (profile.baseData.defenseRating or 10) >= 25 and not profile.completedQuests["quest_fortify_defenses"] then
		profile.completedQuests["quest_fortify_defenses"] = true
		changed = true
	end

	-- Quest 7: Sanctuary Upgrade (Base reaches Tier 2+)
	if profile.baseData.tier >= 2 and not profile.completedQuests["quest_sanctuary_upgrade"] then
		profile.completedQuests["quest_sanctuary_upgrade"] = true
		changed = true
	end

	-- Quest 8: Shadow Infiltration (Started an infiltration raid)
	if profile.completedHeistsCount >= 1 and not profile.completedQuests["quest_shadow_infiltration"] then
		profile.completedQuests["quest_shadow_infiltration"] = true
		changed = true
	end

	-- Quest 9: Coffer Breach & Escape (Breached and siphoned a rival coffer)
	if profile.completedHeistsCount >= 2 and not profile.completedQuests["quest_vault_breach"] then
		profile.completedQuests["quest_vault_breach"] = true
		changed = true
	end

	-- Quest 10: The Sunken Catacombs (Unlocked Sunken Vault)
	if profile.unlockedZones and profile.unlockedZones["SunkenVault"] and not profile.completedQuests["quest_sunken_catacombs"] then
		profile.completedQuests["quest_sunken_catacombs"] = true
		changed = true
	end

	-- Quest 11: Ashen Crucible (Unlocked Ashen Domain & discovered 4+ relics)
	if profile.unlockedZones and profile.unlockedZones["AshenDomain"] and relicCount >= 4 and not profile.completedQuests["quest_ashen_conquest"] then
		profile.completedQuests["quest_ashen_conquest"] = true
		changed = true
	end

	-- Quest 12: Crown of the Void (Discovered signature Hollow Crown or unlocked Celestial Rift)
	if ((profile.discoveredRelics and profile.discoveredRelics["relic_hollow_crown"]) or (profile.unlockedZones and profile.unlockedZones["CelestialRift"])) and not profile.completedQuests["quest_crown_of_void"] then
		profile.completedQuests["quest_crown_of_void"] = true
		changed = true
	end

	-- Daily: Daily Excavation
	if relicCount >= 2 and not profile.completedQuests["daily_wilds_harvest"] then
		profile.completedQuests["daily_wilds_harvest"] = true
		changed = true
	end

	-- Repeatable: Tithe
	if hasSlotted and not profile.completedQuests["repeatable_tribute_collect"] then
		profile.completedQuests["repeatable_tribute_collect"] = true
		changed = true
	end

	if changed then
		local evt = NetworkUtil.GetEvent(RemoteRegistry.Events.QuestProgressUpdated)
		evt:FireClient(player, profile.completedQuests, profile.claimedQuests)
	end
end

function QuestService.RecordEvent(player: Player, eventName: string)
	local profile = ProfileService.GetProfile(player)
	if not profile then return end

	if eventName == "income_collected" then
		profile.completedQuests["quest_tribute_tithe"] = true
		profile.completedQuests["repeatable_tribute_collect"] = true
		local evt = NetworkUtil.GetEvent(RemoteRegistry.Events.QuestProgressUpdated)
		evt:FireClient(player, profile.completedQuests, profile.claimedQuests)
	elseif eventName == "raid_started" then
		profile.completedQuests["quest_shadow_infiltration"] = true
		local evt = NetworkUtil.GetEvent(RemoteRegistry.Events.QuestProgressUpdated)
		evt:FireClient(player, profile.completedQuests, profile.claimedQuests)
	elseif eventName == "raid_extracted" then
		profile.completedQuests["quest_vault_breach"] = true
		profile.completedQuests["daily_rival_raid"] = true
		local evt = NetworkUtil.GetEvent(RemoteRegistry.Events.QuestProgressUpdated)
		evt:FireClient(player, profile.completedQuests, profile.claimedQuests)
	elseif eventName == "node_harvested" then
		profile.completedQuests["quest_wilds_discovery"] = true
		profile.completedQuests["daily_wilds_harvest"] = true
		local evt = NetworkUtil.GetEvent(RemoteRegistry.Events.QuestProgressUpdated)
		evt:FireClient(player, profile.completedQuests, profile.claimedQuests)
	end

	QuestService.EvaluateQuests(player)
end

function QuestService.ClaimReward(player: Player, questId: string, idempotencyKey: string?): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	local quest = QuestDefinitions.Get(questId)
	if not quest then
		return false, "Invalid quest ID: " .. tostring(questId)
	end

	QuestService.EvaluateQuests(player)

	if not profile.completedQuests[questId] then
		return false, "Quest objective has not been completed yet."
	end

	if profile.claimedQuests[questId] then
		return false, "Reward for this quest has already been claimed."
	end

	return TransactionService.Process(player, idempotencyKey, "ClaimQuest:" .. questId, function()
		profile.claimedQuests[questId] = true
		profile.currencies.Cash += quest.rewardCash
		profile.currencies.RelicShards += quest.rewardShards

		EconomyService.SyncProfileToClient(player)

		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notif:FireClient(player, "Quest Completed!", string.format("Claimed +$%d Cash and +%d Shards for '%s'!", quest.rewardCash, quest.rewardShards, quest.title), "Success")

		local evt = NetworkUtil.GetEvent(RemoteRegistry.Events.QuestProgressUpdated)
		evt:FireClient(player, profile.completedQuests, profile.claimedQuests)

		return true, "Quest reward claimed successfully."
	end)
end

function QuestService.Init()
	local claimFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.ClaimQuestReward)
	claimFn.OnServerInvoke = function(player: Player, questId: any, key: any)
		if type(questId) ~= "string" then
			return { success = false, message = "Invalid quest ID parameter." }
		end
		local ok, msg = QuestService.ClaimReward(
			player,
			questId,
			if type(key) == "string" then key else nil
		)
		return { success = ok, message = msg }
	end

	Players.PlayerAdded:Connect(function(player)
		task.delay(2, function()
			QuestService.EvaluateQuests(player)
		end)
	end)
end

return QuestService
