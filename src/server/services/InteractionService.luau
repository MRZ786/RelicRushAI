--!strict
-- InteractionService.luau
-- Authoritative onboarding, starter relic selection, and NPC interaction validation

local Players = game:GetService("Players")

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local RelicDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

local ProfileService = require(script.Parent.ProfileService)
local InventoryService = require(script.Parent.InventoryService)
local TransactionService = require(script.Parent.TransactionService)
local EconomyService = require(script.Parent.EconomyService)

local InteractionService = {}

function InteractionService.SelectStarterRelic(
	player: Player,
	relicDefId: string,
	idempotencyKey: string?
): (boolean, string, any)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Profile unavailable.", nil
	end

	if profile.hasSelectedStarter then
		return false, "Starter relic has already been selected.", nil
	end

	-- Check if chosen relic is in the allowed starter list
	local isStarter = false
	for _, id in ipairs(RelicDefinitions.StarterRelicIds) do
		if id == relicDefId then
			isStarter = true
			break
		end
	end

	if not isStarter then
		return false, "Selected relic is not an eligible starter relic.", nil
	end

	return TransactionService.Process(player, idempotencyKey, "SelectStarter:" .. relicDefId, function()
		local addOk, addMsg, instance = InventoryService.AddRelic(player, relicDefId)
		if not addOk or not instance then
			return false, addMsg, nil
		end

		InventoryService.EquipRelic(player, instance.instanceId)
		profile.hasSelectedStarter = true
		EconomyService.SyncProfileToClient(player)

		local questServiceModule = script.Parent:FindFirstChild("QuestService")
		if questServiceModule then
			local QuestService = require(questServiceModule :: ModuleScript) :: any
			QuestService.EvaluateQuests(player)
		end

		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		local relicDef = RelicDefinitions.Get(relicDefId)
		local rName = if relicDef then relicDef.name else relicDefId
		notif:FireClient(player, "Starter Relic Chosen", "You bonded with " .. rName .. "!", "Success")

		return true, "Starter relic acquired and equipped.", profile
	end)
end

function InteractionService.InteractNPC(player: Player, npcName: string): (boolean, string, any)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable.", nil
	end

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)

	if npcName == "NPC_AntiquarianValeria" or npcName == "Valeria" then
		local hasDiscovered = profile.discoveredLore["npc_valeria_appraisal"]
		profile.discoveredLore["npc_valeria_appraisal"] = true

		if not hasDiscovered then
			profile.currencies.RelicShards += 15
			EconomyService.SyncProfileToClient(player)
			notif:FireClient(player, "Antiquarian's Insight", "Valeria analyzed your artifacts and rewarded +15 Relic Shards!", "Success")
			return true, "Valeria deciphered an ancient curio for you (+15 Shards).", { shards = 15 }
		else
			notif:FireClient(player, "Antiquarian Valeria", "'The excavation in the Wilds unearthed ancient sandstone tablets... keep exploring, seeker.'", "Info")
			return true, "Valeria shared ancient archaeological wisdom.", nil
		end

	elseif npcName == "NPC_AlchemistIgnis" or npcName == "Ignis" then
		-- Alchemist brews volatile stealth smoke or elixir
		if profile.currencies.RelicShards >= 10 then
			profile.currencies.RelicShards -= 10
			EconomyService.SyncProfileToClient(player)
			notif:FireClient(player, "Alchemical Elixir Brewed", "Ignis infused a draught of shadow-essence for 10 Shards!", "Success")
			return true, "Ignis brewed an alchemical draught (-10 Shards).", { brewed = true }
		else
			notif:FireClient(player, "Alchemist Ignis", "'Bring me 10 Relic Shards, seeker, and I shall distill you essence of the deep void.'", "Info")
			return true, "Ignis requires 10 Relic Shards to distill an elixir.", nil
		end

	elseif npcName == "NPC_TorvaldBlacksmith" or npcName == "Torvald" then
		local firstTalk = not profile.discoveredLore["npc_torvald_forging"]
		profile.discoveredLore["npc_torvald_forging"] = true

		if firstTalk then
			profile.currencies.Cash += 25
			EconomyService.SyncProfileToClient(player)
			notif:FireClient(player, "Forgemaster's Favor", "Torvald granted you +25 Cash for tending the settlement hearth!", "Success")
			return true, "Torvald granted +25 Cash.", { cash = 25 }
		else
			local tierMsg = if profile.baseData.tier >= 2
				then "'That workshop of yours does honor to the iron hearth. Forge ahead!'"
				else "'Upgrade your workbench to Tier 2 in the Base District, seeker. Real craftsmanship requires an anvil.'"
			notif:FireClient(player, "Torvald the Blacksmith", tierMsg, "Info")
			return true, tierMsg, nil
		end

	elseif npcName == "NPC_TribuneAurelius" or npcName == "Aurelius" then
		local firstTalk = not profile.discoveredLore["npc_aurelius_garrison"]
		profile.discoveredLore["npc_aurelius_garrison"] = true

		if firstTalk then
			profile.currencies.Cash += 50
			profile.currencies.RelicShards += 25
			EconomyService.SyncProfileToClient(player)
			notif:FireClient(player, "Praetorian Commission", "Tribune Aurelius granted you an Imperial Reconnaissance Bounty (+50 Cash, +25 Shards)!", "Success")
			return true, "Tribune Aurelius commissioned your reconnaissance (+50 Cash, +25 Shards).", { cash = 50, shards = 25 }
		else
			local msg = "'The imperial treasury stands locked to the east. Investigate the sunken aqueduct steps if you seek the lost catacombs.'"
			notif:FireClient(player, "Tribune Aurelius", msg, "Info")
			return true, msg, nil
		end

	elseif npcName == "NPC_KeeperSylva" or npcName == "Sylva" then
		local firstTalk = not profile.discoveredLore["npc_sylva_groves"]
		profile.discoveredLore["npc_sylva_groves"] = true

		if firstTalk then
			profile.currencies.Cash += 30
			profile.currencies.RelicShards += 40
			EconomyService.SyncProfileToClient(player)
			notif:FireClient(player, "Verdant Blessing", "Keeper Sylva granted you the favor of the Ironwood (+30 Cash, +40 Shards)!", "Success")
			return true, "Keeper Sylva granted the favor of the Ironwood (+30 Cash, +40 Shards).", { cash = 30, shards = 40 }
		else
			local msg = "'To the north lies the Shrine of Shifting Sands. The Ancient Hourglass awaits one whose spirit defies the pull of time.'"
			notif:FireClient(player, "Keeper Sylva", msg, "Info")
			return true, msg, nil
		end

	elseif npcName == "NPC_VoidEcho" or npcName == "VoidEcho" then
		local firstTalk = not profile.discoveredLore["npc_voidecho_prophecy"]
		profile.discoveredLore["npc_voidecho_prophecy"] = true

		if firstTalk then
			profile.currencies.Cash += 100
			profile.currencies.RelicShards += 100
			EconomyService.SyncProfileToClient(player)
			notif:FireClient(player, "Astral Awakening", "The Void Echo recognized your arrival atop the Crown Spire (+100 Cash, +100 Shards)!", "Success")
			return true, "Void Echo bestowed celestial starlight (+100 Cash, +100 Shards).", { cash = 100, shards = 100 }
		else
			local msg = "'Eight obsidian spires guard the Altar of the Hollow Crown. Commune with the core when your soul is ready for divine reign.'"
			notif:FireClient(player, "Echo of the Void", msg, "Info")
			return true, msg, nil
		end
	end

	return false, "Unknown NPC: " .. tostring(npcName), nil
end

function InteractionService.CompleteTutorialStep(player: Player, stepNumber: number): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	if profile.completedTutorial then
		return true, "Tutorial already completed."
	end

	if stepNumber > profile.tutorialStep then
		profile.tutorialStep = stepNumber
	end

	if profile.tutorialStep >= 9 then
		profile.completedTutorial = true
		profile.currencies.Cash += 200
		profile.currencies.RelicShards += 25
		EconomyService.SyncProfileToClient(player)

		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notif:FireClient(player, "🎓 Tutorial Completed!", "You completed the onboarding journey! Rewarded +$200 Cash & +25 Shards. The open world awaits!", "Success")

		return true, "Tutorial completed! Onboarding bonus awarded."
	end

	EconomyService.SyncProfileToClient(player)
	return true, string.format("Tutorial advanced to step %d of 9.", profile.tutorialStep)
end

function InteractionService.SkipTutorial(player: Player): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	profile.completedTutorial = true
	profile.tutorialStep = 9
	EconomyService.SyncProfileToClient(player)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(player, "Tutorial Skipped", "Onboarding skipped. You have full access to explore, build, and raid!", "Info")

	return true, "Tutorial skipped."
end

function InteractionService.Init()
	local selectFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.SelectStarterRelic)
	selectFn.OnServerInvoke = function(player: Player, defId: any, key: any)
		if type(defId) ~= "string" then
			return { success = false, message = "Malformed relic ID." }
		end

		local ok, msg, profile = InteractionService.SelectStarterRelic(
			player,
			defId,
			if type(key) == "string" then key else nil
		)
		return { success = ok, message = msg, profile = profile }
	end

	local npcFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.InteractNPC)
	npcFn.OnServerInvoke = function(player: Player, npcName: any)
		if type(npcName) ~= "string" then
			return { success = false, message = "Invalid NPC identifier." }
		end
		local ok, msg, data = InteractionService.InteractNPC(player, npcName)
		return { success = ok, message = msg, data = data }
	end

	local tutFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.CompleteTutorialStep)
	tutFn.OnServerInvoke = function(player: Player, step: any)
		if type(step) ~= "number" then
			return { success = false, message = "Malformed step number." }
		end
		local ok, msg = InteractionService.CompleteTutorialStep(player, step)
		return { success = ok, message = msg }
	end

	local skipFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.SkipTutorial)
	skipFn.OnServerInvoke = function(player: Player)
		local ok, msg = InteractionService.SkipTutorial(player)
		return { success = ok, message = msg }
	end
end

return InteractionService
