--!strict
-- HeistService.luau
-- Authoritative heist mission state machine, alarm escalation, terminal override, gadget tools, and timed extraction
-- Validates theft, escape routes, stealth bonuses, and Hollow Crown divine multipliers.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local HeistDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("HeistDefinitions"))
local RelicDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

local ProfileService = require(script.Parent.ProfileService)
local InventoryService = require(script.Parent.InventoryService)
local EconomyService = require(script.Parent.EconomyService)

type HeistSessionState = CommonTypes.HeistSessionState

local HeistService = {}

local activeSessions: { [number]: HeistSessionState } = {}

-- World positions
local HUB_SPAWN_POSITION = Vector3.new(0, 5, 52)
local HEIST_SPAWN_POSITION = Vector3.new(500, 52, 445)
local VAULT_PEDESTAL_POSITION = Vector3.new(500, 52, 552)
local EXTRACTION_POSITIONS = {
	["exit_alpha"] = Vector3.new(500, 52, 425), -- Main gate exit
	["exit_beta"] = Vector3.new(565, 52, 520),  -- Shadow drain exit
	["exit_gamma"] = Vector3.new(435, 52, 520), -- Catacombs escape grate
}

local function setChaliceModelVisible(visible: boolean)
	local world = Workspace:FindFirstChild("RelicRushWorld")
	if not world then return end
	local heist = world:FindFirstChild("ObsidianOutpost")
	if not heist then return end
	local chalice = heist:FindFirstChild("Relic_ObsidianChalice_Model")
	if chalice then
		for _, desc in chalice:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Transparency = if visible then 0 else 0.95
			elseif desc:IsA("Highlight") then
				desc.Enabled = visible
			elseif desc:IsA("ProximityPrompt") then
				desc.Enabled = visible
			end
		end
		if chalice:IsA("BasePart") then
			chalice.Transparency = if visible then 0 else 0.95
		end
	end
end

function HeistService.GetActiveSession(player: Player): HeistSessionState?
	return activeSessions[player.UserId]
end

function HeistService.StartHeist(player: Player, heistId: string, chosenTool: string?): (boolean, string, HeistSessionState?)
	if activeSessions[player.UserId] then
		return false, "Player already has an active heist session.", nil
	end

	local heistDef = HeistDefinitions.Get(heistId)
	if not heistDef then
		return false, "Unknown heist ID: " .. tostring(heistId), nil
	end

	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable.", nil
	end

	local session: HeistSessionState = {
		sessionId = HttpService:GenerateGUID(false),
		heistId = heistId,
		playerId = player.UserId,
		phase = "Infiltration",
		alarmLevel = 0,
		startTime = os.time(),
		objectiveSecured = false,
		chosenTool = chosenTool,
		toolUsed = false,
		smokeActiveUntil = 0,
		lasersDisabledUntil = 0,
		extractionDeadline = nil,
	}

	activeSessions[player.UserId] = session

	setChaliceModelVisible(true)

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		hrp.CFrame = CFrame.new(HEIST_SPAWN_POSITION + Vector3.new(0, 3, 0))
	end

	local stateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.HeistStateChanged)
	stateEvent:FireClient(player, session)

	local notifEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notifEvent:FireClient(player, "Heist Begun", "Infiltrate the vault and secure the Obsidian Chalice!", "Info")

	local questServiceModule = script.Parent:FindFirstChild("QuestService")
	if questServiceModule then
		local QuestService = require(questServiceModule :: ModuleScript) :: any
		QuestService.RecordEvent(player, "heist_started")
	end

	return true, "Heist started.", session
end

function HeistService.HackSecurityTerminal(player: Player): (boolean, string)
	local session = activeSessions[player.UserId]
	if not session or session.phase == "Extracted" or session.phase == "Failed" then
		return false, "No active heist session."
	end

	session.lasersDisabledUntil = os.clock() + 20

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(player, "Security Override Active", "Lasers bypassed for 20 seconds!", "Success")

	return true, "Laser defenses disabled for 20s."
end

function HeistService.UseHeistTool(player: Player): (boolean, string)
	local session = activeSessions[player.UserId]
	if not session or session.phase == "Extracted" or session.phase == "Failed" then
		return false, "No active heist session."
	end

	if not session.chosenTool or session.chosenTool == "" then
		return false, "No gadget equipped for this mission."
	end

	if session.toolUsed then
		return false, "Gadget has already been deployed for this mission."
	end

	session.toolUsed = true
	session.smokeActiveUntil = os.clock() + 10

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		local smoke = Instance.new("Smoke")
		smoke.Name = "AlchemicalSmoke"
		smoke.Color = Color3.fromRGB(180, 210, 230)
		smoke.Size = 6
		smoke.RiseVelocity = 3
		smoke.Parent = hrp
		task.delay(10, function()
			if smoke and smoke.Parent then
				smoke:Destroy()
			end
		end)
	end

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(player, "Smoke Capsule Deployed", "Lasers suppressed for 10 seconds!", "Success")

	local stateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.HeistStateChanged)
	stateEvent:FireClient(player, session)

	return true, "Smoke tool activated."
end

function HeistService.TriggerAlarm(player: Player, amount: number, reason: string)
	local session = activeSessions[player.UserId]
	if not session or session.phase == "Extracted" or session.phase == "Failed" then
		return
	end

	-- Check if terminal laser hack is active
	if session.lasersDisabledUntil and os.clock() < session.lasersDisabledUntil then
		return
	end

	-- Check if smoke capsule is active
	if session.smokeActiveUntil and os.clock() < session.smokeActiveUntil then
		local notifEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notifEvent:FireClient(player, "Alarm Suppressed", "Smoke obscured security sensors!", "Info")
		return
	end

	-- Check if player has Shadow Talisman equipped for alarm reduction
	local profile = ProfileService.GetProfile(player)
	if profile and profile.equippedRelicId then
		for _, inst in ipairs(profile.inventory) do
			if inst.instanceId == profile.equippedRelicId then
				local relicDef = RelicDefinitions.Get(inst.definitionId)
				if relicDef and relicDef.buff.buffType == "AlarmReduction" then
					local lvl = inst.upgradeLevel or 1
					local mult = if lvl == 2 then 1.4 elseif lvl >= 3 then 1.75 else 1.0
					amount = amount * (1 - (relicDef.buff.magnitude * mult))
				end
				break
			end
		end
	end

	session.alarmLevel = math.clamp(session.alarmLevel + amount, 0, 100)

	local alarmEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.AlarmTriggered)
	alarmEvent:FireClient(player, session.alarmLevel, reason)

	local stateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.HeistStateChanged)
	stateEvent:FireClient(player, session)

	if session.alarmLevel >= 100 and session.phase ~= "AlarmLockdown" then
		session.phase = "AlarmLockdown"
		local notifEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notifEvent:FireClient(player, "LOCKDOWN TRIGGERED", "Security alarms have reached maximum! Escape immediately!", "Warning")
	end
end

function HeistService.InteractObjective(player: Player): (boolean, string, HeistSessionState?)
	local session = activeSessions[player.UserId]
	if not session or session.phase == "Extracted" or session.phase == "Failed" then
		return false, "No active heist session.", nil
	end

	if session.objectiveSecured then
		return false, "Objective is already secured.", session
	end

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		local dist = (hrp.Position - VAULT_PEDESTAL_POSITION).Magnitude
		if dist > 22 then
			return false, string.format("Too far from the vault pedestal (Distance: %.1f studs).", dist), nil
		end
	else
		return false, "Character unavailable.", nil
	end

	local extraWindow = 60
	local profile = ProfileService.GetProfile(player)
	if profile and profile.equippedRelicId then
		for _, inst in ipairs(profile.inventory) do
			if inst.instanceId == profile.equippedRelicId then
				local relicDef = RelicDefinitions.Get(inst.definitionId)
				if relicDef and relicDef.buff.buffType == "TimeExtension" then
					local lvl = inst.upgradeLevel or 1
					local addSecs = if lvl == 2 then 22 elseif lvl >= 3 then 30 else 15
					extraWindow += addSecs
				end
				break
			end
		end
	end
	if profile and profile.relicSynergies then
		for _, syn in ipairs(profile.relicSynergies) do
			if syn == "Temporal Singularity" then
				extraWindow += 20
				break
			end
		end
	end

	session.objectiveSecured = true
	session.phase = "ObjectiveSecured"
	session.extractionDeadline = os.time() + extraWindow

	setChaliceModelVisible(false)
	HeistService.TriggerAlarm(player, 25, "Vault Pedestal Tampered")

	-- Authoritative extraction timer countdown loop
	task.spawn(function()
		local deadline = session.extractionDeadline :: number
		while session.phase == "ObjectiveSecured" and os.time() < deadline do
			task.wait(1)
		end

		-- If still in vault after deadline, fail the heist
		if session.phase == "ObjectiveSecured" and os.time() >= deadline then
			session.phase = "Failed"
			session.alarmLevel = 100

			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = player.Character.HumanoidRootPart :: BasePart
				hrp.CFrame = CFrame.new(HUB_SPAWN_POSITION + Vector3.new(0, 3, 0))
			end

			setChaliceModelVisible(true)
			activeSessions[player.UserId] = nil

			local stateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.HeistStateChanged)
			stateEvent:FireClient(player, session)

			local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
			notif:FireClient(player, "Heist Failed", "Extraction window expired! Security forces closed the gates.", "Warning")
		end
	end)

	local stateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.HeistStateChanged)
	stateEvent:FireClient(player, session)

	local notifEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notifEvent:FireClient(player, "Objective Secured", "Obsidian Chalice secured! Escape to an Extraction Point before the 60s timer expires!", "Success")

	return true, "Objective secured.", session
end

function HeistService.ExtractHeist(player: Player, extractionPointId: string): (boolean, string, any)
	local session = activeSessions[player.UserId]
	if not session or session.phase == "Extracted" or session.phase == "Failed" then
		-- Safe return for non-heist explorers or after-heist visitors
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart :: BasePart
			hrp.CFrame = CFrame.new(HUB_SPAWN_POSITION + Vector3.new(0, 3, 0))
		end
		return true, "Returned safely to Forgotten Market.", nil
	end

	if not session.objectiveSecured then
		-- Tactical retreat before securing the vault chalice
		HeistService.AbortHeist(player, false)
		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notif:FireClient(player, "Tactical Retreat", "Infiltration retreated. Returned safely to Forgotten Market.", "Info")
		return true, "Retreated safely to Forgotten Market.", nil
	end

	local targetPos = EXTRACTION_POSITIONS[extractionPointId]
	if not targetPos then
		return false, "Invalid extraction point ID: " .. tostring(extractionPointId), nil
	end

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		local dist = (hrp.Position - targetPos).Magnitude
		if dist > 24 then
			return false, string.format("You must reach the extraction zone (Distance: %.1f studs).", dist), nil
		end
	else
		return false, "Character unavailable.", nil
	end

	local heistDef = HeistDefinitions.Get(session.heistId)
	if not heistDef then
		return false, "Missing heist definition.", nil
	end

	session.phase = "Extracted"

	-- Calculate rewards & stealth bonus
	local cashReward = heistDef.completionCashReward
	local shardsReward = heistDef.completionShardsReward

	if extractionPointId == "exit_beta" then
		cashReward += 30 -- Flume aqueduct bonus
	elseif extractionPointId == "exit_gamma" then
		shardsReward += 10 -- Deep catacombs salvage bonus
	end

	local stealthRating = "Loud"
	if session.alarmLevel == 0 then
		stealthRating = "Ghost"
		cashReward += 50
	elseif session.alarmLevel <= 50 then
		stealthRating = "Infiltrator"
		cashReward += 25
	end

	-- Check for The Hollow Crown Divine Aura multiplier (+50% at Lvl 1, +65% at Lvl 2, +80% at Lvl 3)
	local profile = ProfileService.GetProfile(player)
	if profile and profile.equippedRelicId then
		for _, inst in ipairs(profile.inventory) do
			if inst.instanceId == profile.equippedRelicId and inst.definitionId == "relic_hollow_crown" then
				local lvl = inst.upgradeLevel or 1
				local divineMult = if lvl == 2 then 1.65 elseif lvl >= 3 then 1.80 else 1.50
				cashReward = math.floor(cashReward * divineMult)
				shardsReward = math.floor(shardsReward * divineMult)
				break
			end
		end
	end

	if profile then
		profile.currencies.Cash += cashReward
		profile.currencies.RelicShards += shardsReward
		profile.completedHeistsCount += 1
		if extractionPointId == "exit_gamma" then
			profile.completedQuests["quest_vault_catacombs"] = true
		end
		InventoryService.AddRelic(player, heistDef.targetRelicId)
		EconomyService.SyncProfileToClient(player)

		local questServiceModule = script.Parent:FindFirstChild("QuestService")
		if questServiceModule then
			local QuestService = require(questServiceModule :: ModuleScript) :: any
			QuestService.EvaluateQuests(player)
		end
	end

	-- Teleport safely back to Forgotten Market Hub
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		hrp.CFrame = CFrame.new(HUB_SPAWN_POSITION + Vector3.new(0, 3, 0))
	end

	setChaliceModelVisible(true)

	local outcome = {
		success = true,
		cashEarned = cashReward,
		shardsEarned = shardsReward,
		relicAwarded = heistDef.targetRelicId,
		finalAlarm = session.alarmLevel,
		stealthRating = stealthRating,
	}

	activeSessions[player.UserId] = nil

	local stateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.HeistStateChanged)
	stateEvent:FireClient(player, session)

	local notifEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notifEvent:FireClient(player, "Heist Complete!", string.format("Escaped with %d Cash! (Rating: %s)", cashReward, stealthRating), "Success")

	return true, "Heist successfully extracted!", outcome
end

function HeistService.AbortHeist(player: Player, isDeath: boolean?): (boolean, string)
	local session = activeSessions[player.UserId]
	if not session then
		return false, "No active heist."
	end

	session.phase = "Failed"

	-- Failure safety: Player permanent inventory and profile currencies remain fully preserved on abort or death
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		hrp.CFrame = CFrame.new(HUB_SPAWN_POSITION + Vector3.new(0, 3, 0))
	end

	setChaliceModelVisible(true)
	activeSessions[player.UserId] = nil

	local stateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.HeistStateChanged)
	stateEvent:FireClient(player, session)

	return true, "Heist aborted."
end

function HeistService.Init()
	local startFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.StartHeist)
	startFn.OnServerInvoke = function(player: Player, heistId: any, tool: any)
		if type(heistId) ~= "string" then
			return { success = false, message = "Invalid heist ID parameter." }
		end
		local ok, msg, state = HeistService.StartHeist(
			player,
			heistId,
			if type(tool) == "string" then tool else nil
		)
		return { success = ok, message = msg, sessionState = state }
	end

	local toolFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.UseHeistTool)
	toolFn.OnServerInvoke = function(player: Player)
		local ok, msg = HeistService.UseHeistTool(player)
		return { success = ok, message = msg }
	end

	local terminalFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.HackSecurityTerminal)
	terminalFn.OnServerInvoke = function(player: Player)
		local ok, msg = HeistService.HackSecurityTerminal(player)
		return { success = ok, message = msg }
	end

	local stealFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.InteractHeistObjective)
	stealFn.OnServerInvoke = function(player: Player)
		local ok, msg, state = HeistService.InteractObjective(player)
		return { success = ok, message = msg, sessionState = state }
	end

	local extractFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.ExtractHeist)
	extractFn.OnServerInvoke = function(player: Player, exitId: any)
		if type(exitId) ~= "string" then
			return { success = false, message = "Invalid exit ID parameter." }
		end
		local ok, msg, outcome = HeistService.ExtractHeist(player, exitId)
		return { success = ok, message = msg, outcome = outcome }
	end

	local abortFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.AbortHeist)
	abortFn.OnServerInvoke = function(player: Player)
		local ok, msg = HeistService.AbortHeist(player, false)
		return { success = ok, message = msg }
	end

	local function trackCharacter(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
		if humanoid then
			humanoid.Died:Connect(function()
				if activeSessions[player.UserId] then
					HeistService.AbortHeist(player, true)
				end
			end)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			trackCharacter(player, char)
		end)
		if player.Character then
			trackCharacter(player, player.Character)
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function(char)
			trackCharacter(player, char)
		end)
		if player.Character then
			trackCharacter(player, player.Character)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		activeSessions[player.UserId] = nil
	end)
end

return HeistService
