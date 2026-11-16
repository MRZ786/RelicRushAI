--!strict
-- BaseService.luau
-- Authoritative Base Management, 10-Plinth Relic Income System, Placement, and Low-Risk Raiding
-- Handles 20-player plot allocation, passive income accumulation, and coffer defense.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local EconomyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local RelicDefinitions = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

local ProfileService = require(script.Parent.ProfileService)
local TransactionService = require(script.Parent.TransactionService)
local EconomyService = require(script.Parent.EconomyService)
local RelicMeshBuilder = require(script.Parent.Parent.world.RelicMeshBuilder)
local EnvironmentProps = require(script.Parent.Parent.world.EnvironmentProps)

type BasePlacedObject = CommonTypes.BasePlacedObject
type BasePlotData = CommonTypes.BasePlotData
type RelicInstance = CommonTypes.RelicInstance
type RaidSessionState = CommonTypes.RaidSessionState

local BaseService = {}

-- Plot allocations: [plotIndex] = Player.UserId
local plotAssignments: { [number]: number } = {}

-- Active raid sessions: [infiltratorUserId] = RaidSessionState
local activeRaids: { [number]: RaidSessionState } = {}
local targetRaidCooldowns: { [number]: number } = {} -- [targetUserId] = cooldown timestamp

-- Resilient plot folder resolution resolving BaseDistrict vs ForgottenMarket hierarchy
local function getPlotFolder(plotIndex: number): Folder?
	local world = Workspace:FindFirstChild("RelicRushWorld")
	if not world then return nil end

	local folderName = "BasePlot_" .. tostring(plotIndex)

	-- Check inside ForgottenMarket -> BaseDistrict
	local market = world:FindFirstChild("ForgottenMarket")
	if market then
		local district = market:FindFirstChild("BaseDistrict")
		if district then
			local plot = district:FindFirstChild(folderName)
			if plot then return plot :: Folder end
		end
		local directPlot = market:FindFirstChild(folderName)
		if directPlot then return directPlot :: Folder end
	end

	-- Check inside root BaseDistrict
	local directDistrict = world:FindFirstChild("BaseDistrict")
	if directDistrict then
		local plot = directDistrict:FindFirstChild(folderName)
		if plot then return plot :: Folder end
	end

	return nil
end

local function getPlotCenter(plotIndex: number): Vector3
	local coords = EconomyConfig.PLOT_COORDINATES
	if plotIndex >= 1 and plotIndex <= #coords then
		return coords[plotIndex]
	end
	return coords[1]
end

local PLINTH_RELATIVE_OFFSETS: { Vector3 } = {
	Vector3.new(-12, 0, -12),
	Vector3.new(-12, 0, -6),
	Vector3.new(-12, 0, 0),
	Vector3.new(-12, 0, 6),
	Vector3.new(-12, 0, 12),
	Vector3.new(12, 0, -12),
	Vector3.new(12, 0, -6),
	Vector3.new(12, 0, 0),
	Vector3.new(12, 0, 6),
	Vector3.new(12, 0, 12),
}

local function ensureBaseInfrastructure(plotIndex: number, plotFolder: Folder)
	local plotCenter = getPlotCenter(plotIndex)

	-- 1. Ensure Plinths Folder exists with 10 physical plinth models
	local plinthsFolder = plotFolder:FindFirstChild("RelicPlinthsFolder")
	if not plinthsFolder then
		plinthsFolder = Instance.new("Folder")
		plinthsFolder.Name = "RelicPlinthsFolder"
		plinthsFolder.Parent = plotFolder

		for slotIdx = 1, EconomyConfig.BASE_RELIC_SLOTS do
			local offset = PLINTH_RELATIVE_OFFSETS[slotIdx]
			local plinthCF = CFrame.new(plotCenter + offset)

			local plinthModel = Instance.new("Model")
			plinthModel.Name = "Plinth_" .. tostring(slotIdx)

			local base = Instance.new("Part")
			base.Name = "PlinthBase"
			base.Size = Vector3.new(3.5, 0.6, 3.5)
			base.CFrame = plinthCF * CFrame.new(0, 0.3, 0)
			base.Color = Color3.fromRGB(30, 28, 35)
			base.Material = Enum.Material.Marble
			base.Anchored = true
			base.CanCollide = true
			base.Parent = plinthModel

			local shaft = Instance.new("Part")
			shaft.Name = "PlinthShaft"
			shaft.Size = Vector3.new(2.6, 2.2, 2.6)
			shaft.CFrame = plinthCF * CFrame.new(0, 1.7, 0)
			shaft.Color = Color3.fromRGB(45, 42, 50)
			shaft.Material = Enum.Material.Basalt
			shaft.Anchored = true
			shaft.CanCollide = true
			shaft.Parent = plinthModel

			local goldTrim = Instance.new("Part")
			goldTrim.Name = "PlinthGoldTrim"
			goldTrim.Size = Vector3.new(2.9, 0.3, 2.9)
			goldTrim.CFrame = plinthCF * CFrame.new(0, 2.95, 0)
			goldTrim.Color = Color3.fromRGB(255, 215, 0)
			goldTrim.Material = Enum.Material.Metal
			goldTrim.Anchored = true
			goldTrim.CanCollide = true
			goldTrim.Parent = plinthModel

			local cushion = Instance.new("Part")
			cushion.Name = "VelvetCushion"
			cushion.Size = Vector3.new(2.4, 0.25, 2.4)
			cushion.CFrame = plinthCF * CFrame.new(0, 3.2, 0)
			cushion.Color = Color3.fromRGB(120, 20, 60)
			cushion.Material = Enum.Material.Fabric
			cushion.Anchored = true
			cushion.CanCollide = true
			cushion.Parent = plinthModel

			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "PlinthPrompt"
			prompt.ActionText = "Manage Relic Slot"
			prompt.ObjectText = string.format("Relic Plinth #%d", slotIdx)
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = cushion

			plinthModel.Parent = plinthsFolder
		end
	end

	-- 2. Ensure Central Vault Coffer exists
	local cofferModel = plotFolder:FindFirstChild("VaultCoffer")
	if not cofferModel then
		cofferModel = Instance.new("Model")
		cofferModel.Name = "VaultCoffer"

		local cofferBase = Instance.new("Part")
		cofferBase.Name = "CofferChest"
		cofferBase.Size = Vector3.new(5, 3.5, 3.5)
		cofferBase.CFrame = CFrame.new(plotCenter + Vector3.new(0, 1.75, 0))
		cofferBase.Color = Color3.fromRGB(35, 32, 40)
		cofferBase.Material = Enum.Material.Cobblestone
		cofferBase.Anchored = true
		cofferBase.CanCollide = true
		cofferBase.Parent = cofferModel

		local goldRim = Instance.new("Part")
		goldRim.Name = "GoldRim"
		goldRim.Size = Vector3.new(5.2, 0.4, 3.7)
		goldRim.CFrame = CFrame.new(plotCenter + Vector3.new(0, 3.6, 0))
		goldRim.Color = Color3.fromRGB(255, 215, 0)
		goldRim.Material = Enum.Material.Metal
		goldRim.Anchored = true
		goldRim.Parent = cofferModel

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CofferPrompt"
		prompt.ActionText = "Collect Tribute / Vault"
		prompt.ObjectText = "Sanctum Vault Coffer"
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = cofferBase

		cofferModel.Parent = plotFolder
	end
end

local function updateSignpostBillboard(plotIndex: number, player: Player?, profile: CommonTypes.PlayerProfile?)
	local plotFolder = getPlotFolder(plotIndex)
	if not plotFolder then return end

	local signPost = plotFolder:FindFirstChild("PlotSignPost")
	if not signPost then return end

	local bb = signPost:FindFirstChild("PlotBillboard") :: BillboardGui?
	if not bb then return end
	bb.AlwaysOnTop = false
	bb.MaxDistance = 45

	local label = bb:FindFirstChild("TitleLabel") :: TextLabel?
	if not label then return end

	if player and profile then
		local defRating = profile.baseData.defenseRating or 10
		local secLevel = "Vulnerable"
		local secColor = Color3.fromRGB(120, 220, 120)
		if defRating >= 50 then
			secLevel = "Heavily Fortified"
			secColor = Color3.fromRGB(0, 220, 255)
		elseif defRating >= 25 then
			secLevel = "Defended"
			secColor = Color3.fromRGB(255, 205, 60)
		end

		label.Text = string.format("🏰 %s'S SANCTUM\n[Tier %d Sanctuary • 10 Relic Slots]\n🛡️ Defense: %d [%s]",
			string.upper(player.DisplayName), profile.baseData.tier, defRating, secLevel)
		label.TextColor3 = secColor
	else
		label.Text = string.format("🏰 SANCTUM PLOT #%d\n[Unclaimed]", plotIndex)
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
	end
end

function BaseService.AssignPlot(player: Player): number
	local profile = ProfileService.GetProfile(player)
	if not profile then return 1 end

	for idx, uid in pairs(plotAssignments) do
		if uid == player.UserId then
			return idx
		end
	end

	local assignedIndex = 1
	for idx = 1, EconomyConfig.PLOT_COUNT do
		if not plotAssignments[idx] then
			assignedIndex = idx
			break
		end
	end

	plotAssignments[assignedIndex] = player.UserId
	profile.baseData.plotIndex = assignedIndex

	local plotFolder = getPlotFolder(assignedIndex)
	if plotFolder then
		ensureBaseInfrastructure(assignedIndex, plotFolder)
		updateSignpostBillboard(assignedIndex, player, profile)
	end

	print(string.format("[BaseService] Allocated Base Plot #%d to %s", assignedIndex, player.Name))
	return assignedIndex
end

function BaseService.ReleasePlot(player: Player)
	for idx, uid in pairs(plotAssignments) do
		if uid == player.UserId then
			plotAssignments[idx] = nil
			updateSignpostBillboard(idx, nil, nil)
			break
		end
	end
end

-- =============================================================================
-- 10-PLINTH RELIC SLOTTING & PASSIVE INCOME
-- =============================================================================

function BaseService.SlotRelic(player: Player, slotIndex: number, instanceId: string): (boolean, string)
	if slotIndex < 1 or slotIndex > EconomyConfig.BASE_RELIC_SLOTS then
		return false, "Invalid relic plinth slot index (must be 1–10)."
	end

	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Profile unavailable."
	end

	local targetInstance: RelicInstance? = nil
	for _, inst in ipairs(profile.inventory) do
		if inst.instanceId == instanceId then
			targetInstance = inst
			break
		end
	end

	if not targetInstance then
		return false, "Relic not found in player inventory."
	end

	-- Clear duplicate placements if this relic is already slotted in another plinth
	for idx = 1, EconomyConfig.BASE_RELIC_SLOTS do
		if profile.baseData.slottedRelicIds[idx] == instanceId and idx ~= slotIndex then
			profile.baseData.slottedRelicIds[idx] = nil
			local pFolder = getPlotFolder(profile.baseData.plotIndex)
			if pFolder then
				local plinths = pFolder:FindFirstChild("RelicPlinthsFolder")
				if plinths then
					local prevPlinth = plinths:FindFirstChild("Plinth_" .. tostring(idx))
					if prevPlinth then
						local disp = prevPlinth:FindFirstChild("SlottedRelicDisplay")
						if disp then disp:Destroy() end
					end
				end
			end
		end
	end

	profile.baseData.slottedRelicIds[slotIndex] = instanceId

	-- Update physical 3D relic model on the plinth
	local plotFolder = getPlotFolder(profile.baseData.plotIndex)
	if plotFolder then
		local plinthsFolder = plotFolder:FindFirstChild("RelicPlinthsFolder")
		if plinthsFolder then
			local plinth = plinthsFolder:FindFirstChild("Plinth_" .. tostring(slotIndex))
			if plinth then
				local oldDisplay = plinth:FindFirstChild("SlottedRelicDisplay")
				if oldDisplay then oldDisplay:Destroy() end

				local cushion = plinth:FindFirstChild("VelvetCushion") :: BasePart?
				if cushion then
					local displayModel = RelicMeshBuilder.SpawnRelicModel(targetInstance.definitionId, plinth, cushion.CFrame * CFrame.new(0, 1.2, 0))
					if displayModel then
						displayModel.Name = "SlottedRelicDisplay"
					end
				end
			end
		end
	end

	EconomyService.SyncProfileToClient(player)
	local relicDef = RelicDefinitions.Get(targetInstance.definitionId)
	local relicName = if relicDef then relicDef.name else "Relic"

	return true, string.format("Successfully placed %s onto Relic Plinth #%d! Generating passive income.", relicName, slotIndex)
end

function BaseService.UnslotRelic(player: Player, slotIndex: number): (boolean, string)
	if slotIndex < 1 or slotIndex > EconomyConfig.BASE_RELIC_SLOTS then
		return false, "Invalid slot index."
	end

	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Profile unavailable."
	end

	profile.baseData.slottedRelicIds[slotIndex] = nil

	local plotFolder = getPlotFolder(profile.baseData.plotIndex)
	if plotFolder then
		local plinthsFolder = plotFolder:FindFirstChild("RelicPlinthsFolder")
		if plinthsFolder then
			local plinth = plinthsFolder:FindFirstChild("Plinth_" .. tostring(slotIndex))
			if plinth then
				local oldDisplay = plinth:FindFirstChild("SlottedRelicDisplay")
				if oldDisplay then oldDisplay:Destroy() end
			end
		end
	end

	EconomyService.SyncProfileToClient(player)
	return true, string.format("Unslotted relic from Plinth #%d back to backpack.", slotIndex)
end

function BaseService.CollectIncome(player: Player): (boolean, string, number, number)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Profile unavailable.", 0, 0
	end

	local collectedCash = profile.baseData.uncollectedTributeCash
	local collectedShards = profile.baseData.uncollectedTributeShards

	if collectedCash <= 0 and collectedShards <= 0 then
		return false, "No uncollected tribute in your vault coffer yet.", 0, 0
	end

	profile.currencies.Cash += collectedCash
	profile.currencies.RelicShards += collectedShards
	profile.baseData.uncollectedTributeCash = 0
	profile.baseData.uncollectedTributeShards = 0

	EconomyService.SyncProfileToClient(player)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(
		player,
		"Tribute Collected!",
		string.format("Collected +$%d Cash and +%d Relic Shards from your base coffer!", collectedCash, collectedShards),
		"Success"
	)

	return true, "Collected tribute successfully.", collectedCash, collectedShards
end

-- =============================================================================
-- LOW-RISK BASE RAIDING MECHANIC
-- =============================================================================

function BaseService.StartRaid(infiltrator: Player, targetUserId: number): (boolean, string, RaidSessionState?)
	if infiltrator.UserId == targetUserId then
		return false, "You cannot raid your own base.", nil
	end

	local infProfile = ProfileService.GetProfile(infiltrator)
	if not infProfile then
		return false, "Infiltrator profile unavailable.", nil
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return false, "Target player is not active in this server.", nil
	end

	local targetProfile = ProfileService.GetProfile(targetPlayer)
	if not targetProfile then
		return false, "Target profile unavailable.", nil
	end

	local now = os.time()
	local lastRaid = targetRaidCooldowns[targetUserId] or 0
	if now < lastRaid + EconomyConfig.RAID_COOLDOWN_SECONDS then
		local remaining = (lastRaid + EconomyConfig.RAID_COOLDOWN_SECONDS) - now
		return false, string.format("This base's wards are currently fortified! Cooldown remaining: %d seconds.", remaining), nil
	end

	local raidId = HttpService:GenerateGUID(false)
	local session: RaidSessionState = {
		raidId = raidId,
		infiltratorUserId = infiltrator.UserId,
		targetUserId = targetUserId,
		phase = "Infiltrating",
		startTime = now,
		deadlineTime = now + EconomyConfig.RAID_TIME_LIMIT_SECONDS,
		siphonedCash = 0,
		siphonedShards = 0,
		detectedCount = 0,
		alarmLevel = 0,
		smokeActiveUntil = 0,
		bypassWireActive = false,
	}

	activeRaids[infiltrator.UserId] = session
	targetRaidCooldowns[targetUserId] = now

	local targetPlotIdx = targetProfile.baseData.plotIndex or 1
	local targetCenter = getPlotCenter(targetPlotIdx)
	if infiltrator.Character and infiltrator.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = infiltrator.Character.HumanoidRootPart :: BasePart
		hrp.CFrame = CFrame.new(targetCenter + Vector3.new(0, 3, -EconomyConfig.BASE_PLOT_HALF_SIZE - 4))
	end

	local raidAlert = NetworkUtil.GetEvent(RemoteRegistry.Events.BaseRaidAlert)
	raidAlert:FireClient(targetPlayer, infiltrator.DisplayName, targetProfile.baseData.uncollectedTributeCash)

	local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
	raidStateEvent:FireClient(infiltrator, session)

	return true, "Infiltration started! Reach the central Vault Coffer before the timer runs out.", session
end

function BaseService.SiphonCoffer(infiltrator: Player): (boolean, string, number, number)
	local session = activeRaids[infiltrator.UserId]
	if not session or session.phase ~= "Infiltrating" then
		return false, "No active raid infiltration session.", 0, 0
	end

	local now = os.time()
	if now > session.deadlineTime then
		session.phase = "Repelled"
		activeRaids[infiltrator.UserId] = nil
		local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
		raidStateEvent:FireClient(infiltrator, session)
		return false, "Raid time limit expired! Wards repelled you.", 0, 0
	end

	local targetPlayer = Players:GetPlayerByUserId(session.targetUserId)
	local targetProfile = if targetPlayer then ProfileService.GetProfile(targetPlayer) else nil

	local uncollectedCash = if targetProfile then targetProfile.baseData.uncollectedTributeCash else 0
	local uncollectedShards = if targetProfile then targetProfile.baseData.uncollectedTributeShards else 0

	-- Exploit prevention: A raid must not generate free currency when no valid tribute exists!
	if uncollectedCash <= 0 and uncollectedShards <= 0 then
		session.phase = "CofferBreached"
		session.siphonedCash = 0
		session.siphonedShards = 0
		activeRaids[infiltrator.UserId] = nil

		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notif:FireClient(
			infiltrator,
			"Vault Coffer Empty",
			"The vault coffer had no uncollected tribute! The owner recently emptied it.",
			"Info"
		)
		local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
		raidStateEvent:FireClient(infiltrator, session)
		return false, "Vault coffer was empty; no tribute available to siphon.", 0, 0
	end

	-- Siphon strictly from available uncollected tribute (up to RAID_SIPHON_PERCENTAGE = 25%)
	local defenseMult = 1.0
	if targetProfile and targetProfile.baseData.defenseRating then
		defenseMult = math.clamp(1.0 - (targetProfile.baseData.defenseRating * 0.005), 0.5, 1.0)
	end

	local effectivePercent = EconomyConfig.RAID_SIPHON_PERCENTAGE * defenseMult
	local siphonedCash = math.floor(uncollectedCash * effectivePercent)
	local siphonedShards = math.floor(uncollectedShards * effectivePercent)

	if siphonedCash <= 0 and uncollectedCash > 0 then siphonedCash = 1 end
	if siphonedShards <= 0 and uncollectedShards > 0 then siphonedShards = 1 end

	siphonedCash = math.min(siphonedCash, uncollectedCash)
	siphonedShards = math.min(siphonedShards, uncollectedShards)

	if targetProfile then
		targetProfile.baseData.uncollectedTributeCash -= siphonedCash
		targetProfile.baseData.uncollectedTributeShards -= siphonedShards
		if targetPlayer then
			EconomyService.SyncProfileToClient(targetPlayer)
			local alert = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
			alert:FireClient(
				targetPlayer,
				"Sanctum Breached!",
				string.format("A shadow raider breached your Vault Coffer and siphoned $%d Cash and %d Shards from uncollected tribute!", siphonedCash, siphonedShards),
				"Warning"
			)
		end
	end

	session.phase = "CofferBreached"
	session.siphonedCash = siphonedCash
	session.siphonedShards = siphonedShards

	local infProfile = ProfileService.GetProfile(infiltrator)
	if infProfile then
		infProfile.currencies.Cash += siphonedCash
		infProfile.currencies.RelicShards += siphonedShards
		EconomyService.SyncProfileToClient(infiltrator)
	end

	local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
	raidStateEvent:FireClient(infiltrator, session)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(
		infiltrator,
		"Coffer Siphoned!",
		string.format("Raid successful! Siphoned +$%d Cash and +%d Shards from uncollected tribute. Escape to plot boundary!", siphonedCash, siphonedShards),
		"Success"
	)

	return true, "Siphoned vault coffer successfully.", siphonedCash, siphonedShards
end

function BaseService.ExtractRaid(infiltrator: Player): (boolean, string)
	local session = activeRaids[infiltrator.UserId]
	if not session then
		if infiltrator.Character and infiltrator.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = infiltrator.Character.HumanoidRootPart :: BasePart
			hrp.CFrame = CFrame.new(Vector3.new(0, 4, 0))
		end
		return true, "Returned safely to Forgotten Market."
	end

	session.phase = "Escaped"
	local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
	raidStateEvent:FireClient(infiltrator, session)

	activeRaids[infiltrator.UserId] = nil

	if infiltrator.Character and infiltrator.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = infiltrator.Character.HumanoidRootPart :: BasePart
		hrp.CFrame = CFrame.new(Vector3.new(0, 4, 0))
	end

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(
		infiltrator,
		"Raid Extraction Complete",
		string.format("Safely escaped with %d Cash and %d Shards!", session.siphonedCash, session.siphonedShards),
		"Success"
	)

	return true, "Extracted successfully."
end

function BaseService.UseRaidGadget(infiltrator: Player, gadgetItemId: string): (boolean, string)
	local session = activeRaids[infiltrator.UserId]
	if not session or (session.phase ~= "Infiltrating" and session.phase ~= "CofferBreached") then
		return false, "No active raid infiltration session."
	end

	local now = os.time()
	if gadgetItemId == "tool_smoke_capsule" then
		session.smokeActiveUntil = now + 8
		local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
		raidStateEvent:FireClient(infiltrator, session)

		if infiltrator.Character and infiltrator.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = infiltrator.Character.HumanoidRootPart :: BasePart
			local smoke = Instance.new("Part")
			smoke.Name = "SmokeCloud"
			smoke.Size = Vector3.new(16, 6, 16)
			smoke.CFrame = hrp.CFrame
			smoke.Color = Color3.fromRGB(80, 80, 95)
			smoke.Material = Enum.Material.Smoke
			smoke.Transparency = 0.5
			smoke.Anchored = true
			smoke.CanCollide = false
			smoke.Parent = Workspace
			task.delay(8, function()
				if smoke then smoke:Destroy() end
			end)
		end

		return true, "Smoke Capsule deployed! Sentry totems blinded for 8 seconds."
	elseif gadgetItemId == "tool_lockpick_wire" then
		session.bypassWireActive = true
		local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
		raidStateEvent:FireClient(infiltrator, session)
		return true, "Bypass Wire Set active! Lock-cracking speed doubled."
	end

	return false, "Unknown raid gadget."
end

function BaseService.TriggerDecoyTrap(infiltrator: Player): (boolean, string)
	local session = activeRaids[infiltrator.UserId]
	if not session then
		return false, "No active raid session."
	end

	session.alarmLevel = 100
	session.deadlineTime = math.max(os.time() + 5, session.deadlineTime - 10)

	local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
	raidStateEvent:FireClient(infiltrator, session)

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(infiltrator, "⚡ DECOY DETONATED!", "You cracked a Gilded Decoy Coffer! Arcane shocks triggered full base alarm!", "Warning")

	local targetPlayer = Players:GetPlayerByUserId(session.targetUserId)
	if targetPlayer then
		notif:FireClient(targetPlayer, "🛡️ DECOY TRAP TRIGGERED!", string.format("%s was fooled by your Gilded Decoy Coffer!", infiltrator.DisplayName), "Success")
	end

	return true, "Decoy trap triggered."
end

function BaseService.GetRivalBaseList(infiltrator: Player): { CommonTypes.RivalBaseInfo }
	local results: { CommonTypes.RivalBaseInfo } = {}
	local now = os.time()

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer.UserId ~= infiltrator.UserId then
			local targetProfile = ProfileService.GetProfile(targetPlayer)
			if targetProfile then
				local lastRaid = targetRaidCooldowns[targetPlayer.UserId] or 0
				local remaining = math.max(0, (lastRaid + EconomyConfig.RAID_COOLDOWN_SECONDS) - now)
				local isEligible = (remaining == 0)

				table.insert(results, {
					userId = targetPlayer.UserId,
					username = targetPlayer.Name,
					displayName = targetPlayer.DisplayName,
					plotIndex = targetProfile.baseData.plotIndex or 1,
					baseTier = targetProfile.baseData.tier,
					defenseRating = targetProfile.baseData.defenseRating or 10,
					uncollectedTributeCash = targetProfile.baseData.uncollectedTributeCash,
					isEligible = isEligible,
					cooldownRemaining = remaining,
				})
			end
		end
	end

	return results
end

-- =============================================================================
-- BASE OBJECT PLACEMENT & UPGRADES
-- =============================================================================

local function spawnPhysicalModel(itemId: string, worldCFrame: CFrame, parent: Instance, placementId: string?): Model
	local model = Instance.new("Model")
	model.Name = "Placed_" .. itemId
	if placementId then
		model:SetAttribute("PlacementId", placementId)
	end
	model:SetAttribute("ItemId", itemId)

	local primaryPart: Part? = nil

	if itemId == "floor_obsidian_tiles" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "FloorPlate"
		primaryPart.Size = Vector3.new(8, 0.4, 8)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 0.2, 0)
		primaryPart.Color = Color3.fromRGB(25, 25, 30)
		primaryPart.Material = Enum.Material.Basalt
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local border = Instance.new("Part")
		border.Name = "FloorTrim"
		border.Size = Vector3.new(8.3, 0.45, 8.3)
		border.CFrame = worldCFrame * CFrame.new(0, 0.18, 0)
		border.Color = Color3.fromRGB(50, 48, 55)
		border.Material = Enum.Material.Metal
		border.Anchored = true
		border.CanCollide = false
		border.Parent = model

	elseif itemId == "floor_marble_mosaic" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "FloorPlate"
		primaryPart.Size = Vector3.new(8, 0.4, 8)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 0.2, 0)
		primaryPart.Color = Color3.fromRGB(220, 218, 225)
		primaryPart.Material = Enum.Material.Marble
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local goldInlay = Instance.new("Part")
		goldInlay.Name = "GoldInlay"
		goldInlay.Size = Vector3.new(4, 0.42, 4)
		goldInlay.CFrame = worldCFrame * CFrame.new(0, 0.21, 0) * CFrame.Angles(0, math.rad(45), 0)
		goldInlay.Color = Color3.fromRGB(255, 215, 0)
		goldInlay.Material = Enum.Material.Metal
		goldInlay.Anchored = true
		goldInlay.CanCollide = false
		goldInlay.Parent = model

	elseif itemId == "floor_runic_cobble" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "FloorPlate"
		primaryPart.Size = Vector3.new(8, 0.4, 8)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 0.2, 0)
		primaryPart.Color = Color3.fromRGB(55, 55, 60)
		primaryPart.Material = Enum.Material.Cobblestone
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local runeGlow = Instance.new("Part")
		runeGlow.Name = "RuneGlow"
		runeGlow.Size = Vector3.new(4.5, 0.42, 4.5)
		runeGlow.CFrame = worldCFrame * CFrame.new(0, 0.21, 0)
		runeGlow.Color = Color3.fromRGB(64, 196, 255)
		runeGlow.Material = Enum.Material.Neon
		runeGlow.Transparency = 0.3
		runeGlow.Anchored = true
		runeGlow.CanCollide = false
		runeGlow.Parent = model

	elseif itemId == "wall_granite_parapet" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "WallBase"
		primaryPart.Size = Vector3.new(8, 4.5, 1.4)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 2.25, 0)
		primaryPart.Color = Color3.fromRGB(90, 85, 80)
		primaryPart.Material = Enum.Material.Slate
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		for ci = -1, 1 do
			local crenel = Instance.new("Part")
			crenel.Name = "Crenel"
			crenel.Size = Vector3.new(1.8, 1.2, 1.5)
			crenel.CFrame = worldCFrame * CFrame.new(ci * 2.8, 5.1, 0)
			crenel.Color = Color3.fromRGB(75, 70, 65)
			crenel.Material = Enum.Material.Slate
			crenel.Anchored = true
			crenel.CanCollide = true
			crenel.Parent = model
		end

	elseif itemId == "wall_runic_battlement" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "WallBase"
		primaryPart.Size = Vector3.new(8, 6.0, 1.6)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 3.0, 0)
		primaryPart.Color = Color3.fromRGB(35, 30, 42)
		primaryPart.Material = Enum.Material.Basalt
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local runeBand = Instance.new("Part")
		runeBand.Name = "RuneBand"
		runeBand.Size = Vector3.new(8.2, 0.6, 1.7)
		runeBand.CFrame = worldCFrame * CFrame.new(0, 3.5, 0)
		runeBand.Color = Color3.fromRGB(140, 80, 255)
		runeBand.Material = Enum.Material.Neon
		runeBand.Anchored = true
		runeBand.CanCollide = false
		runeBand.Parent = model

	elseif itemId == "wall_iron_gate" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "ArchBase"
		primaryPart.Size = Vector3.new(8, 0.5, 1.6)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 0.25, 0)
		primaryPart.Color = Color3.fromRGB(45, 45, 50)
		primaryPart.Material = Enum.Material.Metal
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local pL = Instance.new("Part")
		pL.Name = "PillarLeft"
		pL.Size = Vector3.new(1.2, 7.5, 1.4)
		pL.CFrame = worldCFrame * CFrame.new(-3.4, 3.75, 0)
		pL.Color = Color3.fromRGB(30, 30, 35)
		pL.Material = Enum.Material.Basalt
		pL.Anchored = true
		pL.CanCollide = true
		pL.Parent = model

		local pR = Instance.new("Part")
		pR.Name = "PillarRight"
		pR.Size = Vector3.new(1.2, 7.5, 1.4)
		pR.CFrame = worldCFrame * CFrame.new(3.4, 3.75, 0)
		pR.Color = Color3.fromRGB(30, 30, 35)
		pR.Material = Enum.Material.Basalt
		pR.Anchored = true
		pR.CanCollide = true
		pR.Parent = model

		local archTop = Instance.new("Part")
		archTop.Name = "ArchTop"
		archTop.Size = Vector3.new(8, 1.2, 1.5)
		archTop.CFrame = worldCFrame * CFrame.new(0, 7.6, 0)
		archTop.Color = Color3.fromRGB(215, 175, 45)
		archTop.Material = Enum.Material.Metal
		archTop.Anchored = true
		archTop.CanCollide = true
		archTop.Parent = model

	elseif itemId == "light_soulfire_lantern" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "PostBase"
		primaryPart.Size = Vector3.new(1.4, 0.4, 1.4)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 0.2, 0)
		primaryPart.Color = Color3.fromRGB(40, 40, 45)
		primaryPart.Material = Enum.Material.Metal
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local shaft = Instance.new("Part")
		shaft.Name = "LanternPost"
		shaft.Size = Vector3.new(0.5, 6.0, 0.5)
		shaft.CFrame = worldCFrame * CFrame.new(0, 3.2, 0)
		shaft.Color = Color3.fromRGB(30, 30, 35)
		shaft.Material = Enum.Material.Metal
		shaft.Anchored = true
		shaft.CanCollide = true
		shaft.Parent = model

		local lantern = Instance.new("Part")
		lantern.Name = "SoulLantern"
		lantern.Size = Vector3.new(1.2, 1.6, 1.2)
		lantern.CFrame = worldCFrame * CFrame.new(0, 6.5, 0)
		lantern.Color = Color3.fromRGB(64, 220, 255)
		lantern.Material = Enum.Material.Neon
		lantern.Anchored = true
		lantern.CanCollide = false
		lantern.Parent = model

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(64, 220, 255)
		light.Brightness = 2.5
		light.Range = 22
		light.Shadows = true
		light.Parent = lantern

	elseif itemId == "light_crystal_sconce" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "SconceMount"
		primaryPart.Size = Vector3.new(1.2, 1.8, 0.6)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 2.5, 0)
		primaryPart.Color = Color3.fromRGB(45, 42, 50)
		primaryPart.Material = Enum.Material.Metal
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local crystal = Instance.new("Part")
		crystal.Name = "AstralCrystal"
		crystal.Size = Vector3.new(0.8, 2.4, 0.8)
		crystal.CFrame = worldCFrame * CFrame.new(0, 3.2, 0.4) * CFrame.Angles(math.rad(15), 0, 0)
		crystal.Color = Color3.fromRGB(200, 80, 255)
		crystal.Material = Enum.Material.Neon
		crystal.Anchored = true
		crystal.CanCollide = false
		crystal.Parent = model

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(200, 80, 255)
		light.Brightness = 3.0
		light.Range = 24
		light.Shadows = true
		light.Parent = crystal

	elseif itemId == "decor_gold_pedestal" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "PedestalBase"
		primaryPart.Size = Vector3.new(3.8, 0.6, 3.8)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 0.3, 0)
		primaryPart.Color = Color3.fromRGB(215, 175, 45)
		primaryPart.Material = Enum.Material.Metal
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local shaft = Instance.new("Part")
		shaft.Name = "PedestalShaft"
		shaft.Size = Vector3.new(2.4, 3.0, 2.4)
		shaft.CFrame = worldCFrame * CFrame.new(0, 2.1, 0)
		shaft.Color = Color3.fromRGB(30, 28, 35)
		shaft.Material = Enum.Material.Marble
		shaft.Anchored = true
		shaft.CanCollide = true
		shaft.Parent = model

		local cap = Instance.new("Part")
		cap.Name = "PedestalCap"
		cap.Size = Vector3.new(3.4, 0.5, 3.4)
		cap.CFrame = worldCFrame * CFrame.new(0, 3.8, 0)
		cap.Color = Color3.fromRGB(255, 215, 0)
		cap.Material = Enum.Material.Metal
		cap.Anchored = true
		cap.CanCollide = true
		cap.Parent = model

	elseif itemId == "decor_trophy_dais" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "DaisTier1"
		primaryPart.Size = Vector3.new(7.0, 0.5, 7.0)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 0.25, 0)
		primaryPart.Color = Color3.fromRGB(60, 58, 65)
		primaryPart.Material = Enum.Material.Marble
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local d2 = Instance.new("Part")
		d2.Name = "DaisTier2"
		d2.Size = Vector3.new(5.2, 0.5, 5.2)
		d2.CFrame = worldCFrame * CFrame.new(0, 0.75, 0)
		d2.Color = Color3.fromRGB(215, 175, 45)
		d2.Material = Enum.Material.Metal
		d2.Anchored = true
		d2.CanCollide = true
		d2.Parent = model

		local d3 = Instance.new("Part")
		d3.Name = "DaisTier3"
		d3.Size = Vector3.new(3.6, 0.5, 3.6)
		d3.CFrame = worldCFrame * CFrame.new(0, 1.25, 0)
		d3.Color = Color3.fromRGB(240, 238, 245)
		d3.Material = Enum.Material.Marble
		d3.Anchored = true
		d3.CanCollide = true
		d3.Parent = model

	elseif itemId == "decor_stone_plinth" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "PlinthBase"
		primaryPart.Size = Vector3.new(4, 0.8, 4)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 0.4, 0)
		primaryPart.Color = Color3.fromRGB(120, 115, 110)
		primaryPart.Material = Enum.Material.Marble
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

	elseif itemId == "decor_brazier" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "BrazierStand"
		primaryPart.Size = Vector3.new(2.4, 3.2, 2.4)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 1.6, 0)
		primaryPart.Color = Color3.fromRGB(150, 100, 50)
		primaryPart.Material = Enum.Material.Metal
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local flame = Instance.new("Part")
		flame.Name = "BrazierFlame"
		flame.Size = Vector3.new(1.4, 1.4, 1.4)
		flame.CFrame = worldCFrame * CFrame.new(0, 3.5, 0)
		flame.Color = Color3.fromRGB(255, 130, 20)
		flame.Material = Enum.Material.Neon
		flame.Shape = Enum.PartType.Ball
		flame.Anchored = true
		flame.CanCollide = false
		flame.Parent = model

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 130, 20)
		light.Brightness = 2.0
		light.Range = 18
		light.Parent = flame

	elseif itemId == "decor_gargoyle" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "GargoyleBase"
		primaryPart.Size = Vector3.new(2.4, 2.8, 2.4)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 1.4, 0)
		primaryPart.Color = Color3.fromRGB(30, 28, 35)
		primaryPart.Material = Enum.Material.Basalt
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local eyes = Instance.new("Part")
		eyes.Name = "GargoyleEyes"
		eyes.Size = Vector3.new(1.0, 0.3, 0.3)
		eyes.CFrame = worldCFrame * CFrame.new(0, 2.2, -1.1)
		eyes.Color = Color3.fromRGB(255, 60, 60)
		eyes.Material = Enum.Material.Neon
		eyes.Anchored = true
		eyes.CanCollide = false
		eyes.Parent = model

	elseif itemId == "decor_market_banner" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "BannerPole"
		primaryPart.Size = Vector3.new(0.6, 8.0, 0.6)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 4.0, 0)
		primaryPart.Color = Color3.fromRGB(80, 50, 30)
		primaryPart.Material = Enum.Material.Wood
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local fabric = Instance.new("Part")
		fabric.Name = "BannerCloth"
		fabric.Size = Vector3.new(3.0, 4.5, 0.2)
		fabric.CFrame = worldCFrame * CFrame.new(1.5, 5.2, 0)
		fabric.Color = Color3.fromRGB(160, 25, 45)
		fabric.Material = Enum.Material.Fabric
		fabric.Anchored = true
		fabric.CanCollide = false
		fabric.Parent = model

	elseif itemId == "defense_runic_ward" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "RunicWardObelisk"
		primaryPart.Size = Vector3.new(2.4, 6.0, 2.4)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 3.0, 0)
		primaryPart.Color = Color3.fromRGB(30, 25, 45)
		primaryPart.Material = Enum.Material.Basalt
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local glyph = Instance.new("Part")
		glyph.Name = "WardRuneGlyph"
		glyph.Size = Vector3.new(2.6, 1.2, 2.6)
		glyph.CFrame = worldCFrame * CFrame.new(0, 3.5, 0)
		glyph.Color = Color3.fromRGB(64, 196, 255)
		glyph.Material = Enum.Material.Neon
		glyph.Anchored = true
		glyph.CanCollide = false
		glyph.Parent = model

		local field = Instance.new("Part")
		field.Name = "WardFieldAura"
		field.Shape = Enum.PartType.Cylinder
		field.Size = Vector3.new(0.2, 12, 12)
		field.CFrame = worldCFrame * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90))
		field.Color = Color3.fromRGB(64, 196, 255)
		field.Material = Enum.Material.Neon
		field.Transparency = 0.8
		field.Anchored = true
		field.CanCollide = false
		field.Parent = model

	elseif itemId == "defense_sentry_totem" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "TotemShaft"
		primaryPart.Size = Vector3.new(1.6, 7.0, 1.6)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 3.5, 0)
		primaryPart.Color = Color3.fromRGB(55, 45, 40)
		primaryPart.Material = Enum.Material.Slate
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local eye = Instance.new("Part")
		eye.Name = "TotemEye"
		eye.Size = Vector3.new(1.6, 1.6, 1.6)
		eye.CFrame = worldCFrame * CFrame.new(0, 7.2, 0)
		eye.Color = Color3.fromRGB(255, 50, 50)
		eye.Material = Enum.Material.Neon
		eye.Shape = Enum.PartType.Ball
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model

		local spot = Instance.new("SpotLight")
		spot.Color = Color3.fromRGB(255, 60, 60)
		spot.Brightness = 3.0
		spot.Range = 26
		spot.Angle = 65
		spot.Face = Enum.NormalId.Front
		spot.Parent = eye

	elseif itemId == "defense_decoy_coffer" then
		primaryPart = Instance.new("Part")
		primaryPart.Name = "DecoyChest"
		primaryPart.Size = Vector3.new(5, 3.5, 3.5)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 1.75, 0)
		primaryPart.Color = Color3.fromRGB(35, 32, 40)
		primaryPart.Material = Enum.Material.Cobblestone
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model

		local goldRim = Instance.new("Part")
		goldRim.Name = "GoldRim"
		goldRim.Size = Vector3.new(5.2, 0.4, 3.7)
		goldRim.CFrame = worldCFrame * CFrame.new(0, 3.6, 0)
		goldRim.Color = Color3.fromRGB(255, 215, 0)
		goldRim.Material = Enum.Material.Metal
		goldRim.Anchored = true
		goldRim.CanCollide = true
		goldRim.Parent = model

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DecoyCofferPrompt"
		prompt.ActionText = "Crack Vault Coffer"
		prompt.ObjectText = "Sanctum Vault Coffer"
		prompt.HoldDuration = 2.0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = primaryPart

	else
		primaryPart = Instance.new("Part")
		primaryPart.Name = "ChestBase"
		primaryPart.Size = Vector3.new(3, 2, 2)
		primaryPart.CFrame = worldCFrame * CFrame.new(0, 1, 0)
		primaryPart.Color = Color3.fromRGB(110, 75, 40)
		primaryPart.Material = Enum.Material.Wood
		primaryPart.Anchored = true
		primaryPart.CanCollide = true
		primaryPart.Parent = model
	end

	model.PrimaryPart = primaryPart
	model.Parent = parent
	return model
end

function BaseService.ApplyVisualUpgrade(plotIndex: number, tier: number)
	local plotFolder = getPlotFolder(plotIndex)
	if not plotFolder then return end
	local plotCenter = getPlotCenter(plotIndex)

	if tier >= 2 then
		local s1 = plotFolder:FindFirstChild("StarterShelterTier1")
		if s1 then s1:Destroy() end

		local existingT2 = plotFolder:FindFirstChild("WorkshopTier2Visuals")
		if not existingT2 then
			local t2Folder = Instance.new("Folder")
			t2Folder.Name = "WorkshopTier2Visuals"
			t2Folder.Parent = plotFolder
			EnvironmentProps.CreateArtisanForgeStation(t2Folder, CFrame.new(plotCenter + Vector3.new(0, 0, -12)))
		end
	end

	if tier >= 3 then
		local existingT3 = plotFolder:FindFirstChild("SanctuaryTier3Visuals")
		if not existingT3 then
			local t3Folder = Instance.new("Folder")
			t3Folder.Name = "SanctuaryTier3Visuals"
			t3Folder.Parent = plotFolder

			local offsets = {
				Vector3.new(-14, 0, -14), Vector3.new(14, 0, -14),
				Vector3.new(-14, 0, 14), Vector3.new(14, 0, 14),
			}
			for _, off in ipairs(offsets) do
				EnvironmentProps.CreateFlutedColumn(t3Folder, 15, 1.1, CFrame.new(plotCenter + off), Color3.fromRGB(235, 230, 238))
			end
		end
	end
end

function BaseService.SetBaseTheme(player: Player, themeId: string): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Profile unavailable." end

	local themeDef = EconomyConfig.BaseThemes and EconomyConfig.BaseThemes[themeId]
	if not themeDef then
		return false, "Invalid base theme: " .. tostring(themeId)
	end

	profile.baseData.theme = themeId

	local plotIndex = profile.baseData.plotIndex or 1
	local plotFolder = getPlotFolder(plotIndex)
	if plotFolder then
		local floor = plotFolder:FindFirstChild("PlotFloor") :: BasePart?
		if floor then
			floor.Material = themeDef.floorMaterial
			floor.Color = themeDef.floorColor
		end
		for cIdx = 1, 4 do
			local post = plotFolder:FindFirstChild("CornerPost_" .. tostring(cIdx)) :: BasePart?
			if post then
				post.Color = themeDef.pillarColor
			end
		end
	end

	return true, "Sanctum architectural style transformed to " .. themeDef.name
end

function BaseService.ValidatePlacement(position: Vector3): boolean
	local halfSize = EconomyConfig.BASE_PLOT_HALF_SIZE
	if math.abs(position.X) > halfSize or math.abs(position.Z) > halfSize then
		return false
	end
	if position.Y < -1 or position.Y > 20 then
		return false
	end
	return true
end

function BaseService.PlaceObject(
	player: Player,
	itemId: string,
	relativePosition: Vector3,
	rotationY: number,
	idempotencyKey: string?
): (boolean, string, BasePlotData?)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Profile unavailable.", nil end

	if #profile.baseData.placedObjects >= EconomyConfig.MAX_PLACED_OBJECTS_PER_BASE then
		return false, string.format("Base placement limit reached (Max %d objects). Remove existing objects to place more.", EconomyConfig.MAX_PLACED_OBJECTS_PER_BASE), nil
	end

	local item = EconomyConfig.GetItem(itemId)
	if not item or (item.category ~= "Decoration" and item.category ~= "Defense") then
		return false, "Invalid placeable item.", nil
	end

	if not BaseService.ValidatePlacement(relativePosition) then
		return false, "Placement coordinates exceed plot boundaries.", nil
	end

	if profile.currencies.Cash < item.priceCash then
		return false, string.format("Insufficient Cash to purchase and place %s (Cost: $%d, You have: $%d).", item.name, item.priceCash, profile.currencies.Cash), nil
	end

	local plotIndex = profile.baseData.plotIndex or 1
	local plotCenter = getPlotCenter(plotIndex)
	local plotFolder = getPlotFolder(plotIndex)
	if not plotFolder then return false, "Plot workspace container unavailable.", nil end

	return TransactionService.Process(player, idempotencyKey, "PlaceBaseObject:" .. itemId, function()
		profile.currencies.Cash -= item.priceCash

		local placementId = HttpService:GenerateGUID(false)
		local newPlaced: BasePlacedObject = {
			placementId = placementId,
			itemId = itemId,
			position = relativePosition,
			rotationY = rotationY,
		}

		table.insert(profile.baseData.placedObjects, newPlaced)

		local baseTierDef = if profile.baseData.tier == 3 then 40 elseif profile.baseData.tier == 2 then 25 else 10
		local placedDef = 0
		for _, obj in ipairs(profile.baseData.placedObjects) do
			local oItem = EconomyConfig.GetItem(obj.itemId)
			if oItem and oItem.defenseValue then
				placedDef += oItem.defenseValue
			end
		end
		profile.baseData.defenseRating = baseTierDef + placedDef

		local placedFolder = plotFolder:FindFirstChild("PlacedObjectsFolder")
		if not placedFolder then
			placedFolder = Instance.new("Folder")
			placedFolder.Name = "PlacedObjectsFolder"
			placedFolder.Parent = plotFolder
		end

		local worldCF = CFrame.new(plotCenter + relativePosition) * CFrame.Angles(0, math.rad(rotationY), 0)
		spawnPhysicalModel(itemId, worldCF, placedFolder, placementId)

		updateSignpostBillboard(plotIndex, player, profile)
		EconomyService.SyncProfileToClient(player)
		return true, string.format("Placed %s successfully in your sanctum!", item.name), profile.baseData
	end)
end

function BaseService.MoveObject(
	player: Player,
	placementId: string,
	newRelativePosition: Vector3,
	newRotationY: number
): (boolean, string, BasePlotData?)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Profile unavailable.", nil end

	if not BaseService.ValidatePlacement(newRelativePosition) then
		return false, "New position exceeds plot boundaries.", nil
	end

	local targetPlaced: BasePlacedObject? = nil
	for _, p in ipairs(profile.baseData.placedObjects) do
		if p.placementId == placementId then
			targetPlaced = p
			break
		end
	end

	if not targetPlaced then
		return false, "Placed object not found in your base.", nil
	end

	targetPlaced.position = newRelativePosition
	targetPlaced.rotationY = newRotationY

	local plotIndex = profile.baseData.plotIndex or 1
	local plotCenter = getPlotCenter(plotIndex)
	local plotFolder = getPlotFolder(plotIndex)
	if plotFolder then
		local placedFolder = plotFolder:FindFirstChild("PlacedObjectsFolder")
		if placedFolder then
			for _, child in ipairs(placedFolder:GetChildren()) do
				if child:GetAttribute("PlacementId") == placementId and child:IsA("Model") then
					local newCF = CFrame.new(plotCenter + newRelativePosition) * CFrame.Angles(0, math.rad(newRotationY), 0)
					if child.PrimaryPart then
						child:SetPrimaryPartCFrame(newCF)
					else
						local currentCF = child:GetPivot()
						local offset = newCF * currentCF:Inverse()
						for _, part in ipairs(child:GetDescendants()) do
							if part:IsA("BasePart") then
								part.CFrame = offset * part.CFrame
							end
						end
					end
					break
				end
			end
		end
	end

	EconomyService.SyncProfileToClient(player)
	return true, "Object moved successfully.", profile.baseData
end

function BaseService.RemoveObject(
	player: Player,
	placementId: string
): (boolean, string, BasePlotData?)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Profile unavailable.", nil end

	local targetIdx: number? = nil
	local targetPlaced: BasePlacedObject? = nil
	for i, p in ipairs(profile.baseData.placedObjects) do
		if p.placementId == placementId then
			targetIdx = i
			targetPlaced = p
			break
		end
	end

	if not targetPlaced or not targetIdx then
		return false, "Placed object not found in base.", nil
	end

	table.remove(profile.baseData.placedObjects, targetIdx)

	local item = EconomyConfig.GetItem(targetPlaced.itemId)
	local refund = 0
	if item then
		refund = math.floor(item.priceCash * 0.5)
		profile.currencies.Cash += refund
	end

	local baseTierDef = if profile.baseData.tier == 3 then 40 elseif profile.baseData.tier == 2 then 25 else 10
	local placedDef = 0
	for _, obj in ipairs(profile.baseData.placedObjects) do
		local oItem = EconomyConfig.GetItem(obj.itemId)
		if oItem and oItem.defenseValue then
			placedDef += oItem.defenseValue
		end
	end
	profile.baseData.defenseRating = baseTierDef + placedDef

	local plotIndex = profile.baseData.plotIndex or 1
	local plotFolder = getPlotFolder(plotIndex)
	if plotFolder then
		local placedFolder = plotFolder:FindFirstChild("PlacedObjectsFolder")
		if placedFolder then
			for _, child in ipairs(placedFolder:GetChildren()) do
				if child:GetAttribute("PlacementId") == placementId then
					child:Destroy()
					break
				end
			end
		end
		updateSignpostBillboard(plotIndex, player, profile)
	end

	EconomyService.SyncProfileToClient(player)
	return true, string.format("Object removed. Refunded $%d Cash (50%%).", refund), profile.baseData
end

function BaseService.UpgradeBase(player: Player, idempotencyKey: string?): (boolean, string, BasePlotData?)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Profile unavailable.", nil end

	local currentTier = profile.baseData.tier
	if currentTier >= 3 then
		return false, "Your Sanctum is already upgraded to the Master Tier (Tier 3 Arcane Sanctuary).", nil
	end

	local nextTier = currentTier + 1
	local cost = if nextTier == 2 then EconomyConfig.BASE_UPGRADE_TIER_2_COST else EconomyConfig.BASE_UPGRADE_TIER_3_COST

	if profile.currencies.Cash < cost then
		return false, string.format("Insufficient Cash for Tier %d upgrade (Cost: %d, You have: %d).", nextTier, cost, profile.currencies.Cash), nil
	end

	return TransactionService.Process(player, idempotencyKey, "UpgradeBasePlot_Tier" .. tostring(nextTier), function()
		profile.currencies.Cash -= cost
		profile.baseData.tier = nextTier

		local baseTierDef = if nextTier == 3 then 40 elseif nextTier == 2 then 25 else 10
		local placedDef = 0
		for _, obj in ipairs(profile.baseData.placedObjects) do
			local oItem = EconomyConfig.GetItem(obj.itemId)
			if oItem and oItem.defenseValue then
				placedDef += oItem.defenseValue
			end
		end
		profile.baseData.defenseRating = baseTierDef + placedDef

		local plotIndex = profile.baseData.plotIndex or 1
		BaseService.ApplyVisualUpgrade(plotIndex, nextTier)
		updateSignpostBillboard(plotIndex, player, profile)
		EconomyService.SyncProfileToClient(player)

		return true, string.format("Sanctum successfully upgraded to Tier %d!", nextTier), profile.baseData
	end)
end

-- =============================================================================
-- REBIRTH & ZONE UNLOCKS
-- =============================================================================

function BaseService.UnlockZone(player: Player, zoneId: string): (boolean, string)
	local cost = EconomyConfig.ZONE_UNLOCK_COSTS[zoneId]
	if not cost then return false, "Invalid zone ID." end

	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Profile unavailable." end

	if profile.unlockedZones[zoneId] then
		return false, "Zone is already unlocked."
	end

	if profile.currencies.Cash < cost then
		return false, string.format("Insufficient Cash to unlock %s (Cost: $%d, You have: $%d).", zoneId, cost, profile.currencies.Cash)
	end

	profile.currencies.Cash -= cost
	profile.unlockedZones[zoneId] = true
	profile.unlockedRegions[zoneId] = true
	EconomyService.SyncProfileToClient(player)

	return true, string.format("Successfully unlocked %s! Venture forth to uncover its secrets.", zoneId)
end

function BaseService.Rebirth(player: Player): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Profile unavailable." end

	if profile.currencies.Cash < EconomyConfig.REBIRTH_MIN_CASH then
		return false, string.format("Rebirth requires at least $%d Cash (You have: $%d).", EconomyConfig.REBIRTH_MIN_CASH, profile.currencies.Cash)
	end

	local count = 0
	for _, _ in pairs(profile.discoveredRelics) do count += 1 end
	if count < EconomyConfig.REBIRTH_RELIC_REQUIREMENT then
		return false, string.format("Rebirth requires discovering at least %d unique relics (Discovered: %d).", EconomyConfig.REBIRTH_RELIC_REQUIREMENT, count)
	end

	profile.rebirthData.rebirthCount += 1
	profile.rebirthData.prestigeMultiplier += EconomyConfig.REBIRTH_PRESTIGE_BONUS
	profile.rebirthData.totalRebirthSpentCash += profile.currencies.Cash

	profile.currencies.Cash = EconomyConfig.STARTING_CASH
	profile.unlockedZones = { ["ForgottenWilds"] = true }
	profile.unlockedRegions = { ["ForgottenMarket"] = true, ["ForgottenWilds"] = true }

	EconomyService.SyncProfileToClient(player)

	return true, string.format("Ascended through Rebirth #%d! Permanent +%d%% Prestige Income Multiplier active.",
		profile.rebirthData.rebirthCount, math.floor(profile.rebirthData.prestigeMultiplier * 100 - 100))
end

-- =============================================================================
-- SERVER INITIALIZATION & PASSIVE INCOME LOOP
-- =============================================================================

function BaseService.Init()
	-- Connect Remotes
	local slotFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestSlotBaseRelic)
	slotFn.OnServerInvoke = function(player: Player, slotIdx: any, instId: any)
		if type(slotIdx) ~= "number" or type(instId) ~= "string" then
			return { success = false, message = "Malformed slot arguments." }
		end
		local ok, msg = BaseService.SlotRelic(player, slotIdx, instId)
		return { success = ok, message = msg }
	end

	local unslotFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestUnslotBaseRelic)
	unslotFn.OnServerInvoke = function(player: Player, slotIdx: any)
		if type(slotIdx) ~= "number" then
			return { success = false, message = "Malformed unslot arguments." }
		end
		local ok, msg = BaseService.UnslotRelic(player, slotIdx)
		return { success = ok, message = msg }
	end

	local collectFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestCollectBaseIncome)
	collectFn.OnServerInvoke = function(player: Player)
		local ok, msg, c, s = BaseService.CollectIncome(player)
		return { success = ok, message = msg, cash = c, shards = s }
	end

	local raidFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestRaidBase)
	raidFn.OnServerInvoke = function(player: Player, targetUid: any)
		if type(targetUid) ~= "number" then
			return { success = false, message = "Malformed target user ID." }
		end
		local ok, msg, session = BaseService.StartRaid(player, targetUid)
		return { success = ok, message = msg, session = session }
	end

	local siphonFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestSiphonCoffer)
	siphonFn.OnServerInvoke = function(player: Player)
		local ok, msg, c, s = BaseService.SiphonCoffer(player)
		return { success = ok, message = msg, cash = c, shards = s }
	end

	local extractRaidFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.ExtractRaid)
	extractRaidFn.OnServerInvoke = function(player: Player)
		local ok, msg = BaseService.ExtractRaid(player)
		return { success = ok, message = msg }
	end

	local moveFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestMoveBaseObject)
	moveFn.OnServerInvoke = function(player: Player, placementId: any, newPos: any, newRotY: any)
		if type(placementId) ~= "string" or typeof(newPos) ~= "Vector3" or type(newRotY) ~= "number" then
			return { success = false, message = "Malformed move parameters." }
		end
		local ok, msg, plotData = BaseService.MoveObject(player, placementId, newPos, newRotY)
		return { success = ok, message = msg, plotData = plotData }
	end

	local removeFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestRemoveBaseObject)
	removeFn.OnServerInvoke = function(player: Player, placementId: any)
		if type(placementId) ~= "string" then
			return { success = false, message = "Malformed remove parameters." }
		end
		local ok, msg, plotData = BaseService.RemoveObject(player, placementId)
		return { success = ok, message = msg, plotData = plotData }
	end

	local rivalsFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.GetRivalBaseList)
	rivalsFn.OnServerInvoke = function(player: Player)
		local list = BaseService.GetRivalBaseList(player)
		return { success = true, rivals = list }
	end

	local gadgetFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.UseRaidGadget)
	gadgetFn.OnServerInvoke = function(player: Player, gadgetItemId: any)
		if type(gadgetItemId) ~= "string" then
			return { success = false, message = "Malformed gadget ID." }
		end
		local ok, msg = BaseService.UseRaidGadget(player, gadgetItemId)
		return { success = ok, message = msg }
	end

	local placeFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestPlaceBaseObject)
	placeFn.OnServerInvoke = function(player: Player, itemId: any, pos: any, rotY: any, key: any)
		if type(itemId) ~= "string" or typeof(pos) ~= "Vector3" or type(rotY) ~= "number" then
			return { success = false, message = "Malformed placement parameters." }
		end
		local ok, msg, plotData = BaseService.PlaceObject(
			player,
			itemId,
			pos,
			rotY,
			if type(key) == "string" then key else nil
		)
		return { success = ok, message = msg, plotData = plotData }
	end

	local upgradeFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestBaseUpgrade)
	upgradeFn.OnServerInvoke = function(player: Player, key: any)
		local ok, msg, plotData = BaseService.UpgradeBase(
			player,
			if type(key) == "string" then key else nil
		)
		return { success = ok, message = msg, plotData = plotData }
	end

	local themeFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestSetBaseTheme)
	themeFn.OnServerInvoke = function(player: Player, themeId: any)
		if type(themeId) ~= "string" then
			return { success = false, message = "Invalid theme parameter." }
		end
		local ok, msg = BaseService.SetBaseTheme(player, themeId)
		return { success = ok, message = msg }
	end

	local unlockFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestUnlockZone)
	unlockFn.OnServerInvoke = function(player: Player, zoneId: any)
		if type(zoneId) ~= "string" then
			return { success = false, message = "Invalid zone parameter." }
		end
		local ok, msg = BaseService.UnlockZone(player, zoneId)
		return { success = ok, message = msg }
	end

	local rebirthFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestRebirth)
	rebirthFn.OnServerInvoke = function(player: Player)
		local ok, msg = BaseService.Rebirth(player)
		return { success = ok, message = msg }
	end

	-- Handle player connection / plot allocation
	Players.PlayerAdded:Connect(function(player)
		task.delay(1.5, function()
			local plotIndex = BaseService.AssignPlot(player)
			local profile = ProfileService.GetProfile(player)
			if profile then
				if profile.baseData.tier >= 2 then
					BaseService.ApplyVisualUpgrade(plotIndex, profile.baseData.tier)
				end

				local plotFolder = getPlotFolder(plotIndex)
				if plotFolder then
					local plotCenter = getPlotCenter(plotIndex)
					local placedFolder = plotFolder:FindFirstChild("PlacedObjectsFolder")
					if not placedFolder then
						placedFolder = Instance.new("Folder")
						placedFolder.Name = "PlacedObjectsFolder"
						placedFolder.Parent = plotFolder
					end

					for _, placed in ipairs(profile.baseData.placedObjects) do
						local worldCF = CFrame.new(plotCenter + placed.position) * CFrame.Angles(0, math.rad(placed.rotationY), 0)
						spawnPhysicalModel(placed.itemId, worldCF, placedFolder, placed.placementId)
					end
				end
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		BaseService.ReleasePlot(player)
	end)

	-- Active Infiltration Raiding Heartbeat Loop (Runs every 0.5s)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.time()

			for infiltratorUserId, session in pairs(activeRaids) do
				local infiltrator = Players:GetPlayerByUserId(infiltratorUserId)
				if not infiltrator or not infiltrator.Parent then
					activeRaids[infiltratorUserId] = nil
					continue
				end

				-- Check timeout
				if now > session.deadlineTime then
					session.phase = "Repelled"
					activeRaids[infiltratorUserId] = nil

					local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
					notif:FireClient(infiltrator, "Raid Expired", "Base wards activated and repelled you!", "Warning")

					local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
					raidStateEvent:FireClient(infiltrator, session)

					if infiltrator.Character and infiltrator.Character:FindFirstChild("HumanoidRootPart") then
						local hrp = infiltrator.Character.HumanoidRootPart :: BasePart
						hrp.CFrame = CFrame.new(Vector3.new(0, 4, 0))
					end
					continue
				end

				-- Sentry detection check if infiltrator is currently infiltrating
				if session.phase == "Infiltrating" and infiltrator.Character then
					local hrp = infiltrator.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						local targetPlayer = Players:GetPlayerByUserId(session.targetUserId)
						local targetProfile = if targetPlayer then ProfileService.GetProfile(targetPlayer) else nil
						local targetPlotIdx = if targetProfile then targetProfile.baseData.plotIndex or 1 else 1
						local targetPlotFolder = getPlotFolder(targetPlotIdx)

						local isSmokeActive = (session.smokeActiveUntil or 0) > now
						local sentryDetected = false

						if targetPlotFolder and not isSmokeActive then
							local placedFolder = targetPlotFolder:FindFirstChild("PlacedObjectsFolder")
							if placedFolder then
								for _, child in ipairs(placedFolder:GetChildren()) do
									if child.Name == "Placed_defense_sentry_totem" and child:IsA("Model") then
										local totemEye = child:FindFirstChild("TotemEye") :: BasePart?
										if totemEye then
											local dist = (hrp.Position - totemEye.Position).Magnitude
											if dist <= 28 then
												sentryDetected = true
												break
											end
										end
									end
								end
							end
						end

						if sentryDetected then
							session.alarmLevel = math.min(100, (session.alarmLevel or 0) + 12)
							if session.alarmLevel >= 100 and (session.detectedCount or 0) == 0 then
								session.detectedCount = 1
								session.deadlineTime = math.max(now + 5, session.deadlineTime - 8)
								if targetPlayer then
									local alert = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
									alert:FireClient(targetPlayer, "🚨 DEFENSE ALARM!", string.format("Intruder %s was detected by your Arcane Sentries!", infiltrator.DisplayName), "Warning")
								end
							end
						else
							session.alarmLevel = math.max(0, (session.alarmLevel or 0) - 4)
						end

						local raidStateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
						raidStateEvent:FireClient(infiltrator, session)
					end
				end
			end
		end
	end)

	-- Real-Time Passive Income Loop (Runs every 10 seconds)
	task.spawn(function()
		while true do
			task.wait(EconomyConfig.INCOME_TICK_SECONDS)

			for _, player in ipairs(Players:GetPlayers()) do
				local profile = ProfileService.GetProfile(player)
				if profile then
					local cashRate = 0
					local shardsRate = 0
					local prestigeMult = if profile.rebirthData then profile.rebirthData.prestigeMultiplier else 1.0

					for slotIdx = 1, EconomyConfig.BASE_RELIC_SLOTS do
						local instId = profile.baseData.slottedRelicIds[slotIdx]
						if instId then
							for _, inst in ipairs(profile.inventory) do
								if inst.instanceId == instId then
									local def = RelicDefinitions.Get(inst.definitionId)
									if def then
										local upgradeMult = if inst.upgradeLevel == 2 then 1.3 elseif inst.upgradeLevel >= 3 then 1.6 else 1.0
										cashRate += math.floor(def.incomeRateCash * upgradeMult * prestigeMult)
										shardsRate += math.floor(def.incomeRateShards * upgradeMult * prestigeMult)
									end
									break
								end
							end
						end
					end

					if cashRate > 0 or shardsRate > 0 then
						profile.baseData.uncollectedTributeCash += cashRate
						profile.baseData.uncollectedTributeShards += shardsRate
						profile.baseData.lastIncomeTick = os.time()

						local incomeEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.BaseIncomeTick)
						incomeEvent:FireClient(player, profile.baseData.uncollectedTributeCash, profile.baseData.uncollectedTributeShards, cashRate, shardsRate)
					end
				end
			end
		end
	end)
end

return BaseService
