--!strict
-- RaidController.luau
-- Authoritative client controller for active player base infiltration raiding
-- Manages live raid HUD overlay, sentry alarm meter, countdown timer, gadget shortcuts, and extraction zones.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local HUDController = require(script.Parent.HUDController)

type RaidSessionState = CommonTypes.RaidSessionState

local RaidController = {}

local activeRaidHud: Frame? = nil
local alarmFillBar: Frame? = nil
local alarmTextLbl: TextLabel? = nil
local timerLbl: TextLabel? = nil
local objectiveLbl: TextLabel? = nil
local smokeGadgetBtn: TextButton? = nil
local wireGadgetBtn: TextButton? = nil
local extractionBeamPart: Part? = nil

local currentSession: RaidSessionState? = nil
local heartbeatConn: RBXScriptConnection? = nil
local localPlayer = Players.LocalPlayer

function RaidController.GetCurrentSession(): RaidSessionState?
	return currentSession
end

local function cleanExtractionVisuals()
	if extractionBeamPart then
		extractionBeamPart:Destroy()
		extractionBeamPart = nil
	end
end

local function spawnExtractionBoundaryVisuals(targetUserId: number)
	cleanExtractionVisuals()

	-- Find target plot center
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	local targetPlotIdx = 1
	if targetPlayer then
		local pFolder = workspace:FindFirstChild("RelicRushWorld")
		if pFolder then
			-- estimate target center
			for idx = 1, EconomyConfig.PLOT_COUNT do
				local folderName = "BasePlot_" .. tostring(idx)
				local plot = pFolder:FindFirstChild(folderName, true)
				if plot then
					local sign = plot:FindFirstChild("PlotSignPost")
					if sign then
						local bb = sign:FindFirstChild("PlotBillboard") :: BillboardGui?
						if bb then
							local lbl = bb:FindFirstChild("TitleLabel") :: TextLabel?
							if lbl and string.find(string.lower(lbl.Text), string.lower(targetPlayer.DisplayName)) then
								targetPlotIdx = idx
								break
							end
						end
					end
				end
			end
		end
	end

	local plotCoords = EconomyConfig.PLOT_COORDINATES
	local center = if targetPlotIdx <= #plotCoords then plotCoords[targetPlotIdx] else Vector3.new(80, 2, -72)

	local beacon = Instance.new("Part")
	beacon.Name = "RaidExtractionPerimeterRing"
	beacon.Size = Vector3.new(42, 1, 42)
	beacon.CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0))
	beacon.Color = Color3.fromRGB(0, 255, 170)
	beacon.Material = Enum.Material.Neon
	beacon.Transparency = 0.6
	beacon.CanCollide = false
	beacon.Anchored = true
	beacon.Parent = workspace
	extractionBeamPart = beacon
end

function RaidController.ShowRaidHud(session: RaidSessionState)
	currentSession = session
	local mainGui = UIComponents.GetMainGui()
	local theme = UIComponents.Theme

	if activeRaidHud then
		activeRaidHud:Destroy()
		activeRaidHud = nil
	end

	local hud = UIComponents.CreateRoundedFrame(
		mainGui,
		UDim2.new(0, 440, 0, 110),
		UDim2.new(0.5, -220, 0, 72),
		theme.Surface,
		10
	)
	hud.Name = "ActiveRaidHud"
	hud.ZIndex = 50
	activeRaidHud = hud

	local targetPlayer = Players:GetPlayerByUserId(session.targetUserId)
	local targetName = if targetPlayer then targetPlayer.DisplayName else "Rival Sanctum"

	local title = UIComponents.CreateLabel(
		hud,
		string.format("⚔️ SANCTUM INFILTRATION: %s", string.upper(targetName)),
		UDim2.new(1, -20, 0, 20),
		UDim2.new(0, 10, 0, 8),
		12,
		theme.AccentGold
	)
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 51

	objectiveLbl = UIComponents.CreateLabel(
		hud,
		"Infiltrate the Sanctum & crack the central Vault Coffer",
		UDim2.new(1, -20, 0, 18),
		UDim2.new(0, 10, 0, 28),
		11,
		theme.TextPrimary
	)
	objectiveLbl.ZIndex = 51

	-- Alarm Meter
	local meterBg = UIComponents.CreateRoundedFrame(
		hud,
		UDim2.new(0.6, 0, 0, 16),
		UDim2.new(0, 10, 0, 52),
		Color3.fromRGB(30, 25, 35),
		4
	)
	meterBg.ZIndex = 51

	alarmFillBar = Instance.new("Frame")
	alarmFillBar.Name = "AlarmFill"
	alarmFillBar.Size = UDim2.new(0, 0, 1, 0)
	alarmFillBar.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
	alarmFillBar.BorderSizePixel = 0
	alarmFillBar.ZIndex = 52
	alarmFillBar.Parent = meterBg

	alarmTextLbl = UIComponents.CreateLabel(
		hud,
		"Sentry Alarm: 0%",
		UDim2.new(0.6, 0, 0, 16),
		UDim2.new(0, 10, 0, 52),
		10,
		Color3.fromRGB(255, 255, 255)
	)
	alarmTextLbl.Font = Enum.Font.GothamBold
	alarmTextLbl.ZIndex = 53

	-- Countdown Timer Label
	timerLbl = UIComponents.CreateLabel(
		hud,
		"⏱️ 45s",
		UDim2.new(0.35, 0, 0, 24),
		UDim2.new(0.63, 0, 0, 48),
		16,
		Color3.fromRGB(255, 215, 0)
	)
	timerLbl.Font = Enum.Font.GothamBold
	timerLbl.ZIndex = 51

	-- Gadget Quick Buttons
	smokeGadgetBtn = UIComponents.CreateButton(
		hud,
		"💨 Smoke [Q]",
		UDim2.new(0, 110, 0, 26),
		UDim2.new(0, 10, 0, 76),
		Color3.fromRGB(60, 65, 80),
		function()
			RaidController.DeploySmoke()
		end
	)
	smokeGadgetBtn.TextSize = 10
	smokeGadgetBtn.ZIndex = 52

	wireGadgetBtn = UIComponents.CreateButton(
		hud,
		"⚡ Bypass [E]",
		UDim2.new(0, 110, 0, 26),
		UDim2.new(0, 130, 0, 76),
		Color3.fromRGB(60, 65, 80),
		function()
			RaidController.DeployBypassWire()
		end
	)
	wireGadgetBtn.TextSize = 10
	wireGadgetBtn.ZIndex = 52

	local abortBtn = UIComponents.CreateButton(
		hud,
		"Abort Raid",
		UDim2.new(0, 90, 0, 26),
		UDim2.new(1, -100, 0, 76),
		Color3.fromRGB(150, 40, 40),
		function()
			local extractFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.ExtractRaid)
			extractFn:InvokeServer()
			RaidController.HideRaidHud()
		end
	)
	abortBtn.TextSize = 10
	abortBtn.ZIndex = 52

	-- Heartbeat listener for timer and perimeter extraction
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end

	heartbeatConn = RunService.Heartbeat:Connect(function()
		if not currentSession then return end
		local now = os.time()
		local remaining = math.max(0, currentSession.deadlineTime - now)

		if timerLbl then
			timerLbl.Text = string.format("⏱️ %ds", remaining)
			if remaining <= 10 then
				timerLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
			else
				timerLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
			end
		end

		-- Extraction boundary auto-detection if coffer is breached
		if currentSession.phase == "CofferBreached" and localPlayer.Character then
			local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and extractionBeamPart then
				local dist = (hrp.Position - extractionBeamPart.Position).Magnitude
				-- When player reaches plot perimeter boundary (~20 studs from center)
				if dist >= 18 and dist <= 30 then
					local extractFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.ExtractRaid)
					extractFn:InvokeServer()
					RaidController.HideRaidHud()
				end
			end
		end
	end)
end

function RaidController.UpdateSession(session: RaidSessionState)
	currentSession = session

	if not activeRaidHud and (session.phase == "Infiltrating" or session.phase == "CofferBreached") then
		RaidController.ShowRaidHud(session)
	end

	if alarmFillBar and session.alarmLevel then
		local percent = math.clamp(session.alarmLevel / 100, 0, 1)
		alarmFillBar.Size = UDim2.new(percent, 0, 1, 0)
		if percent >= 0.8 then
			alarmFillBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		elseif percent >= 0.4 then
			alarmFillBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
		else
			alarmFillBar.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
		end
	end

	if alarmTextLbl and session.alarmLevel then
		alarmTextLbl.Text = string.format("Sentry Alarm: %d%%", math.floor(session.alarmLevel))
	end

	if session.phase == "CofferBreached" then
		if objectiveLbl then
			objectiveLbl.Text = string.format("🏃 COFFER BREACHED (+$%d, +%d)! Run to perimeter boundary to escape!",
				session.siphonedCash, session.siphonedShards)
			objectiveLbl.TextColor3 = Color3.fromRGB(0, 255, 170)
		end
		spawnExtractionBoundaryVisuals(session.targetUserId)
	elseif session.phase == "Escaped" then
		HUDController.ShowToast("Raid Complete!", string.format("Successfully escaped with $%d Cash and %d Shards!", session.siphonedCash, session.siphonedShards), "Success")
		RaidController.HideRaidHud()
	elseif session.phase == "Repelled" then
		HUDController.ShowToast("Raid Failed", "Sanctum wards repelled you! Tribute lost.", "Warning")
		RaidController.HideRaidHud()
	end
end

function RaidController.HideRaidHud()
	if activeRaidHud then
		activeRaidHud:Destroy()
		activeRaidHud = nil
	end
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	cleanExtractionVisuals()
	currentSession = nil
end

function RaidController.DeploySmoke()
	local gadgetFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.UseRaidGadget)
	local res = gadgetFn:InvokeServer("tool_smoke_capsule")
	if res and res.success then
		HUDController.ShowToast("Smoke Deployed", res.message, "Success")
	else
		HUDController.ShowToast("Gadget Unavailable", res.message or "Cannot deploy smoke", "Warning")
	end
end

function RaidController.DeployBypassWire()
	local gadgetFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.UseRaidGadget)
	local res = gadgetFn:InvokeServer("tool_lockpick_wire")
	if res and res.success then
		HUDController.ShowToast("Bypass Wire Set", res.message, "Success")
	else
		HUDController.ShowToast("Gadget Unavailable", res.message or "Cannot deploy bypass wire", "Warning")
	end
end

function RaidController.Init()
	local raidEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.RaidStateChanged)
	raidEvent.OnClientEvent:Connect(function(session: RaidSessionState)
		RaidController.UpdateSession(session)
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or not currentSession then return end

		if input.KeyCode == Enum.KeyCode.Q then
			RaidController.DeploySmoke()
		elseif input.KeyCode == Enum.KeyCode.E then
			RaidController.DeployBypassWire()
		end
	end)

	print("[RaidController] Active Infiltration Raiding Client initialized.")
end

return RaidController
