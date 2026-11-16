--!strict
-- SentryService.luau
-- Authoritative dynamic infiltration sentry AI system for Relic Rush
-- Manages sentry spawning, waypoint patrolling, line-of-sight raycasting,
-- suspicion buildup, smoke/cover stealth counterplay, and alarm escalation.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

local HeistService = require(script.Parent.HeistService)
local ProfileService = require(script.Parent.ProfileService)

export type SentryState = "Patrol" | "Suspicious" | "Alerted" | "Investigating"

export type SentryData = {
	id: string,
	model: Model,
	rootPart: Part,
	visorPart: Part,
	statusLabel: TextLabel,
	state: SentryState,
	suspicion: number, -- 0 to 100
	waypoints: { Vector3 },
	currentWaypointIndex: number,
	moveSpeed: number,
	lastAlertTime: number,
	targetPlayer: Player?,
	lastKnownPos: Vector3?,
}

local SentryService = {}
local activeSentries: { [string]: SentryData } = {}
local heartbeatConnection: RBXScriptConnection? = nil
local lastTickTime = os.clock()

local function createPart(parent: Instance, name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = col
	p.Material = mat
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function spawnSentryModel(sentryDef: { id: string, name: string, initialPos: Vector3, waypoints: { Vector3 }, armorCol: Color3 }): SentryData
	local model = Instance.new("Model")
	model.Name = "Sentry_" .. sentryDef.id

	local root = createPart(model, "HumanoidRootPart", Vector3.new(2.4, 4.8, 1.6), CFrame.new(sentryDef.initialPos + Vector3.new(0, 2.4, 0)), sentryDef.armorCol, Enum.Material.Metal)
	model.PrimaryPart = root

	-- Heavy Iron Breastplate & Pauldrons
	createPart(model, "ChestCuirass", Vector3.new(2.6, 2.4, 1.8), root.CFrame * CFrame.new(0, 0.4, 0), sentryDef.armorCol, Enum.Material.Metal)
	createPart(model, "PauldronL", Vector3.new(1.2, 1.2, 1.4), root.CFrame * CFrame.new(-1.6, 1.2, 0), sentryDef.armorCol, Enum.Material.Metal)
	createPart(model, "PauldronR", Vector3.new(1.2, 1.2, 1.4), root.CFrame * CFrame.new(1.6, 1.2, 0), sentryDef.armorCol, Enum.Material.Metal)

	-- Great Helm with Visor
	local helm = createPart(model, "GreatHelm", Vector3.new(1.8, 1.8, 1.8), root.CFrame * CFrame.new(0, 2.6, 0), Color3.fromRGB(35, 38, 42), Enum.Material.Metal)
	local visor = createPart(model, "SensorVisor", Vector3.new(1.2, 0.35, 0.4), helm.CFrame * CFrame.new(0, 0.1, -0.85), Color3.fromRGB(0, 220, 255), Enum.Material.Neon)

	-- Halberd Polearm in Right Hand
	local weapon = createPart(model, "PolearmShaft", Vector3.new(0.3, 7.5, 0.3), root.CFrame * CFrame.new(1.6, 1.2, -0.6), Color3.fromRGB(45, 30, 20), Enum.Material.Wood)
	createPart(model, "PolearmBlade", Vector3.new(0.2, 1.8, 1.0), weapon.CFrame * CFrame.new(0, 3.2, 0.3), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)

	-- Overhead Detection Status Billboard
	local bb = Instance.new("BillboardGui")
	bb.Name = "SentryDetectionGui"
	bb.Size = UDim2.new(0, 160, 0, 36)
	bb.StudsOffset = Vector3.new(0, 3.8, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	bb.Parent = helm

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(1, 0, 1, 0)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "[PATROL]"
	statusLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
	statusLbl.Font = Enum.Font.GothamBold
	statusLbl.TextSize = 13
	statusLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	statusLbl.TextStrokeTransparency = 0.2
	statusLbl.Parent = bb

	local worldContainer = Workspace:FindFirstChild("RelicRushWorld") or Workspace
	model.Parent = worldContainer

	return {
		id = sentryDef.id,
		model = model,
		rootPart = root,
		visorPart = visor,
		statusLabel = statusLbl,
		state = "Patrol",
		suspicion = 0,
		waypoints = sentryDef.waypoints,
		currentWaypointIndex = 1,
		moveSpeed = 6.5, -- studs per second
		lastAlertTime = 0,
		targetPlayer = nil,
		lastKnownPos = nil,
	}
end

-- Deterministic unit-testable detection logic
function SentryService.ProcessDetection(
	sentry: SentryData,
	player: Player,
	distance: number,
	hasLOS: boolean,
	isSmokeActive: boolean,
	hasShadowTalisman: boolean,
	dt: number
): (SentryState, number, boolean)
	if isSmokeActive then
		-- Smoke completely suppresses line of sight detection
		sentry.suspicion = math.max(0, sentry.suspicion - (25 * dt))
		if sentry.suspicion == 0 then
			sentry.state = "Patrol"
		elseif sentry.suspicion < 100 and sentry.state == "Alerted" then
			sentry.state = "Suspicious"
		end
		return sentry.state, sentry.suspicion, false
	end

	if hasLOS and distance <= 40 then
		-- Suspicion buildup rate inversely proportional to distance
		local rate = 45 -- % per second
		if distance < 15 then
			rate = 75
		end
		if hasShadowTalisman then
			rate = rate * 0.8 -- -20% buildup from Shadow Talisman
		end

		sentry.suspicion = math.min(100, sentry.suspicion + (rate * dt))

		if sentry.suspicion >= 100 then
			sentry.state = "Alerted"
			return "Alerted", 100, true
		else
			sentry.state = "Suspicious"
			return "Suspicious", sentry.suspicion, false
		end
	else
		-- Gradually decay suspicion when player is out of sight or in cover
		sentry.suspicion = math.max(0, sentry.suspicion - (20 * dt))
		if sentry.suspicion == 0 then
			sentry.state = "Patrol"
		elseif sentry.suspicion < 100 and sentry.state == "Alerted" then
			sentry.state = "Suspicious"
		end
		return sentry.state, sentry.suspicion, false
	end
end

function SentryService.CheckLineOfSight(sentryPos: Vector3, targetPos: Vector3, sentryLookVector: Vector3, sentryModel: Model?): boolean
	local toTarget = targetPos - sentryPos
	local dist = toTarget.Magnitude
	if dist > 40 then
		return false
	end

	-- Hearing radius: unconditional detection within 8 studs
	if dist <= 8 then
		return true
	end

	-- Forward vision cone check (dot product > 0.4 = ~66 degree half-angle)
	local dir = toTarget.Unit
	local dot = sentryLookVector:Dot(dir)
	if dot < 0.4 then
		return false
	end

	-- Raycast check for physical cover (excluding the sentry model to prevent self-occlusion)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if sentryModel then { sentryModel } else {}
	params.IgnoreWater = true

	local result = Workspace:Raycast(sentryPos, toTarget, params)
	if result and result.Instance then
		-- If hit object is close to target (within 3 studs), LOS is clear
		local hitDist = (result.Position - sentryPos).Magnitude
		if hitDist >= dist - 3.5 then
			return true
		else
			-- Obstructed by wall, sandbag, or cover barrier
			return false
		end
	end

	return true
end

function SentryService.Update(dt: number)
	for _, sentry in pairs(activeSentries) do
		local root = sentry.rootPart
		local visor = sentry.visorPart
		local lbl = sentry.statusLabel
		local currentPos = root.Position
		local lookVec = root.CFrame.LookVector

		-- 1. Scan for nearby players
		local detectedPlayer: Player? = nil
		local detectedDist = 999
		local playerHasSmoke = false
		local playerHasTalisman = false

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local hrp = char.HumanoidRootPart :: BasePart
				local pDist = (hrp.Position - currentPos).Magnitude

				if pDist <= 42 then
					-- Check Heist session smoke tool
					local session = HeistService.GetActiveSession(player)
					if session and session.smokeActiveUntil and os.clock() < session.smokeActiveUntil then
						playerHasSmoke = true
					end

					-- Check Shadow Talisman
					local profile = ProfileService.GetProfile(player)
					if profile and profile.equippedRelicId then
						for _, inst in ipairs(profile.inventory) do
							if inst.instanceId == profile.equippedRelicId and inst.definitionId == "relic_shadow_talisman" then
								playerHasTalisman = true
								break
							end
						end
					end

					local los = SentryService.CheckLineOfSight(currentPos + Vector3.new(0, 2.5, 0), hrp.Position, lookVec, sentry.model)
					if los then
						detectedPlayer = player
						detectedDist = pDist
						break
					end
				end
			end
		end

		-- 2. Process Detection State Machine
		local newState, newSuspicion, justAlerted = SentryService.ProcessDetection(
			sentry,
			detectedPlayer or ({} :: any),
			detectedDist,
			detectedPlayer ~= nil,
			playerHasSmoke,
			playerHasTalisman,
			dt
		)

		-- 3. Update Visuals & Sound Feedback
		if newState == "Alerted" then
			visor.Color = Color3.fromRGB(255, 30, 30)
			lbl.TextColor3 = Color3.fromRGB(255, 30, 30)
			lbl.Text = "ALERTED !"

			if justAlerted and detectedPlayer and (os.clock() - sentry.lastAlertTime > 4.0) then
				sentry.lastAlertTime = os.clock()
				sentry.targetPlayer = detectedPlayer
				sentry.lastKnownPos = detectedPlayer.Character and detectedPlayer.Character:FindFirstChild("HumanoidRootPart")
					and (detectedPlayer.Character.HumanoidRootPart :: BasePart).Position

				local heistSession = HeistService.GetActiveSession(detectedPlayer)
				if heistSession and heistSession.phase ~= "Extracted" and heistSession.phase ~= "Failed" then
					HeistService.TriggerAlarm(detectedPlayer, 25, "Obsidian Sentry spotted intruder!")
					local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
					notif:FireClient(detectedPlayer, "Sentry Alerted!", "A vault guard spotted you! Alarm raised (+25%)!", "Warning")
				else
					local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
					notif:FireClient(detectedPlayer, "Sentinel Alerted!", "An Imperial Sentinel spotted you!", "Info")
				end
			end

		elseif newState == "Suspicious" then
			visor.Color = Color3.fromRGB(255, 175, 10)
			lbl.TextColor3 = Color3.fromRGB(255, 175, 10)
			lbl.Text = string.format("SUSPICIOUS ? %d%%", math.floor(newSuspicion))

			-- Turn toward the detected disturbance
			if detectedPlayer and detectedPlayer.Character and detectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local targetP = (detectedPlayer.Character.HumanoidRootPart :: BasePart).Position
				local lookAt = Vector3.new(targetP.X, currentPos.Y, targetP.Z)
				root.CFrame = CFrame.lookAt(currentPos, lookAt)
			end

		else -- Patrol
			visor.Color = Color3.fromRGB(0, 220, 255)
			lbl.TextColor3 = Color3.fromRGB(0, 220, 255)
			lbl.Text = "[PATROL]"

			-- Patrol Movement between Waypoints
			if #sentry.waypoints >= 2 then
				local targetWP = sentry.waypoints[sentry.currentWaypointIndex]
				local toWP = targetWP - currentPos
				toWP = Vector3.new(toWP.X, 0, toWP.Z)
				local distToWP = toWP.Magnitude

				if distToWP < 2.0 then
					sentry.currentWaypointIndex = (sentry.currentWaypointIndex % #sentry.waypoints) + 1
				else
					local moveDir = toWP.Unit
					local stepDist = math.min(distToWP, sentry.moveSpeed * dt)
					local newPos = currentPos + (moveDir * stepDist)
					local lookTarget = newPos + moveDir
					root.CFrame = CFrame.lookAt(newPos, lookTarget)
				end
			end
		end
	end
end

function SentryService.SpawnOutpostSentries()
	-- Clear any existing sentries
	for id, s in pairs(activeSentries) do
		if s.model then s.model:Destroy() end
	end
	table.clear(activeSentries)

	-- Sentry 1: Courtyard Patrol
	local s1 = spawnSentryModel({
		id = "Courtyard_1",
		name = "Courtyard Warden",
		initialPos = Vector3.new(500, 52, 440),
		waypoints = {
			Vector3.new(500, 52, 435),
			Vector3.new(518, 52, 452),
			Vector3.new(482, 52, 452),
		},
		armorCol = Color3.fromRGB(48, 50, 56),
	})
	activeSentries[s1.id] = s1

	-- Sentry 2: Sentry Corridor Patrol
	local s2 = spawnSentryModel({
		id = "Corridor_2",
		name = "Corridor Sentry",
		initialPos = Vector3.new(500, 52, 480),
		waypoints = {
			Vector3.new(500, 52, 475),
			Vector3.new(500, 52, 515),
		},
		armorCol = Color3.fromRGB(38, 40, 46),
	})
	activeSentries[s2.id] = s2

	-- Sentry 3: Vault Antechamber Sentry
	local s3 = spawnSentryModel({
		id = "Vault_3",
		name = "Vault Praetorian",
		initialPos = Vector3.new(488, 52, 535),
		waypoints = {
			Vector3.new(488, 52, 535),
			Vector3.new(512, 52, 535),
		},
		armorCol = Color3.fromRGB(30, 32, 38),
	})
	activeSentries[s3.id] = s3

	-- Sentry 4: Empire Forum Sentinel (Empire District)
	local s4 = spawnSentryModel({
		id = "Empire_4",
		name = "Imperial Praetorian",
		initialPos = Vector3.new(0, 3, -185),
		waypoints = {
			Vector3.new(0, 3, -185),
			Vector3.new(16, 3, -200),
			Vector3.new(0, 3, -215),
			Vector3.new(-16, 3, -200),
		},
		armorCol = Color3.fromRGB(65, 55, 45),
	})
	activeSentries[s4.id] = s4

	print("[SentryService] 4 Infiltration AI Sentries deployed (3 in Obsidian Outpost, 1 in Empire District).")
end

function SentryService.GetSentries(): { [string]: SentryData }
	return activeSentries
end

function SentryService.Init()
	SentryService.SpawnOutpostSentries()

	-- Throttled 4 Hz update loop (every 0.25s) for smooth AI without CPU overhead
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
	end

	local accumulator = 0
	heartbeatConnection = RunService.Heartbeat:Connect(function(step)
		accumulator += step
		if accumulator >= 0.25 then
			SentryService.Update(accumulator)
			accumulator = 0
		end
	end)

	print("[SentryService] Authoritative Sentry AI Service initialized.")
end

return SentryService