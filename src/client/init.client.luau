--!strict
-- init.client.luau
-- Authoritative client entry point for Relic Rush Full Game Build
-- Coordinates HUD, dialogues, shops, base management, heist state, quests, and settings.

print("==================================================")
print("  STARTING RELIC RUSH CLIENT (Release Candidate)  ")
print("==================================================")

local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))

local HUDController = require(script.controllers.HUDController)
local DialogueController = require(script.controllers.DialogueController)
local ShopController = require(script.controllers.ShopController)
local BaseController = require(script.controllers.BaseController)
local HeistController = require(script.controllers.HeistController)
local RaidController = require(script.controllers.RaidController)
local CollectionController = require(script.controllers.CollectionController)
local QuestController = require(script.controllers.QuestController)
local SettingsController = require(script.controllers.SettingsController)
local OnboardingController = require(script.controllers.OnboardingController)
local RebirthController = require(script.controllers.RebirthController)
local NavigationController = require(script.controllers.NavigationController)
local CameraController = require(script.controllers.CameraController)

type PlayerProfile = CommonTypes.PlayerProfile

local currentProfile: PlayerProfile? = nil

-- 1. Initialize Controllers
HUDController.Init()
CameraController.Init()
NavigationController.Init()
HeistController.Init()
RaidController.Init()
OnboardingController.Init()

HUDController.SetCollectionCallback(function(profile: PlayerProfile)
	CollectionController.OpenShowcase(profile)
end)

HUDController.SetQuestsCallback(function(profile: PlayerProfile)
	QuestController.Toggle(profile)
end)

HUDController.SetRebirthCallback(function(profile: PlayerProfile)
	RebirthController.Toggle(profile)
end)

HUDController.SetSettingsCallback(function()
	SettingsController.Toggle()
end)

HUDController.SetMobileGadgetCallback(function()
	HeistController.DeployGadget()
end)

-- 2. Connect Remote Listeners
local profileUpdateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.ProfileUpdated)
profileUpdateEvent.OnClientEvent:Connect(function(profile: PlayerProfile)
	currentProfile = profile
	HUDController.UpdateProfile(profile)
	OnboardingController.UpdateProfile(profile)
end)

local questUpdateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.QuestProgressUpdated)
questUpdateEvent.OnClientEvent:Connect(function(completedMap: any, claimedMap: any)
	if currentProfile then
		currentProfile.completedQuests = completedMap
		currentProfile.claimedQuests = claimedMap
		HUDController.UpdateProfile(currentProfile)
		OnboardingController.UpdateProfile(currentProfile)
	end
end)

local notifEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
notifEvent.OnClientEvent:Connect(function(title: string, message: string, alertType: string)
	HUDController.ShowToast(title, message, alertType)
end)

local surgeEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.TreasureSurgeActive)
surgeEvent.OnClientEvent:Connect(function(zoneId: string, displayName: string, description: string, expiresAt: number)
	HUDController.ShowToast("⚡ " .. displayName, string.format("Manifested in %s! %s", zoneId, description), "Warning")
end)

local incomeEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.BaseIncomeTick)
incomeEvent.OnClientEvent:Connect(function(uncollectedCash: number, uncollectedShards: number, cashRate: number, shardsRate: number)
	if currentProfile then
		currentProfile.baseData.uncollectedTributeCash = uncollectedCash
		currentProfile.baseData.uncollectedTributeShards = uncollectedShards
		HUDController.UpdateProfile(currentProfile)
	end
end)

-- 3. Connect World Interaction Triggers (ProximityPrompts opening Client GUIs)
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, triggeringPlayer: Player)
	if triggeringPlayer ~= player or not currentProfile then
		return
	end

	-- Client UI Panels
	if prompt.Name == "Prompt_Guide" then
		DialogueController.OpenGuideDialogue(currentProfile)
	elseif prompt.Name == "Prompt_Merchant" then
		ShopController.OpenShop(currentProfile)
	elseif prompt.Name == "Prompt_Heist" then
		HeistController.OpenBriefing()
	elseif prompt.Name == "Prompt_BaseWorkbench" then
		BaseController.OpenBaseManager(currentProfile)
	elseif prompt.Name == "Prompt_Plinth" then
		CollectionController.OpenShowcase(currentProfile)
	elseif prompt.Name == "Prompt_StorageChest" then
		CollectionController.OpenShowcase(currentProfile)
	elseif prompt.Name == "Prompt_Valeria" then
		DialogueController.OpenValeriaDialogue(currentProfile)
	elseif prompt.Name == "Prompt_Ignis" then
		DialogueController.OpenIgnisDialogue(currentProfile)
	elseif prompt.Name == "Prompt_Torvald" then
		DialogueController.OpenTorvaldDialogue(currentProfile)
	elseif prompt.Name == "Prompt_Aurelius" then
		DialogueController.OpenAureliusDialogue(currentProfile)
	elseif prompt.Name == "Prompt_Sylva" then
		DialogueController.OpenSylvaDialogue(currentProfile)
	elseif prompt.Name == "Prompt_VoidEcho" then
		DialogueController.OpenVoidEchoDialogue(currentProfile)
	elseif prompt.Name == "ExcavatePrompt" then
		local nodeModel = prompt.Parent and prompt.Parent.Parent
		if nodeModel then
			local harvestFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.HarvestRelicNode)
			harvestFn:InvokeServer(nodeModel.Name)
		end
	elseif prompt.Name == "CofferPrompt" then
		local raidSession = RaidController.GetCurrentSession()
		if raidSession and (raidSession.phase == "Infiltrating" or raidSession.phase == "CofferBreached") then
			local siphonFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestSiphonCoffer)
			siphonFn:InvokeServer()
		else
			local collectFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestCollectBaseIncome)
			collectFn:InvokeServer()
		end
	elseif prompt.Name == "DecoyCofferPrompt" then
		local siphonFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestSiphonCoffer)
		siphonFn:InvokeServer()
	elseif prompt.Name == "PlinthPrompt" then
		CollectionController.OpenShowcase(currentProfile)
	end
	-- Note: Server operations (Gates, Steles, Altars, Caches, Heist Objective, Extractions)
	-- are handled directly by server-side ProximityPrompt listeners in WorldBuilder.luau
end)

-- 4. Keybind Listeners ([B] Collection, [J] Quests, [M] Settings, [Q] Smoke Capsule)
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	-- Multiplatform Controls (Keyboard & Gamepad)
	if input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.ButtonX then
		CollectionController.OpenShowcase(currentProfile)
	elseif input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.ButtonY then
		QuestController.Toggle(currentProfile)
	elseif input.KeyCode == Enum.KeyCode.P or input.KeyCode == Enum.KeyCode.ButtonL1 then
		RebirthController.Toggle(currentProfile)
	elseif input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.ButtonSelect then
		SettingsController.Toggle()
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonR1 then
		HeistController.DeployGadget()
	end
end)

-- 5. Lightweight Region Tracking Loop (Updates Top-Left Region Badge & Zone Ambience)
task.spawn(function()
	local lastDetectedRegion = ""
	while task.wait(1.0) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local pos = hrp.Position
				local rName = "Forgotten Market"
				local rSub = "Sanctum Base District"

				if pos.Y > 75 and pos.X > 150 then
					rName = "Celestial Rift"
					rSub = "Astral Void & Crown Spire"
				elseif pos.X > 300 and pos.Z > 300 then
					rName = "Sunken Vault"
					rSub = "Submerged Catacombs & Fortress"
				elseif pos.X < -120 then
					rName = "Forgotten Wilds"
					rSub = "Overgrown Forest Ruins"
				elseif pos.Z < -100 then
					rName = "Ashen Domain"
					rSub = "Scorched Imperial Ruins"
				end

				if rName ~= lastDetectedRegion then
					lastDetectedRegion = rName
					HUDController.SetCurrentRegion(rName, rSub)
					local zoneKey = rName:gsub("%s+", "")
					SoundEffects.PlayZoneAmbience(zoneKey)
				end
			end
		end
	end
end)

-- 6. Fetch Initial Profile on Client Boot
task.spawn(function()
	local getProfileFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.GetPlayerProfile)
	local initial = getProfileFn:InvokeServer()
	if initial then
		currentProfile = initial
		HUDController.UpdateProfile(initial)
		OnboardingController.UpdateProfile(initial)
		print(string.format("[ClientInit] Initialized profile for %s (Cash: %d, HasStarter: %s)",
			player.Name, initial.currencies.Cash, tostring(initial.hasSelectedStarter)))

		if not initial.hasSelectedStarter then
			task.delay(1.5, function()
				if currentProfile and not currentProfile.hasSelectedStarter then
					DialogueController.OpenGuideDialogue(currentProfile)
				end
			end)
		end
	end
end)

print("[ClientInit] Relic Rush client initialized successfully.")
