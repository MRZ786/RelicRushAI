--!strict
-- HeistController.luau
-- Manages heist briefings, live in-mission alarm HUD, gadget tool activation, and post-heist recap screens

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local HeistDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("HeistDefinitions"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local HUDController = require(script.Parent.HUDController)

type HeistSessionState = CommonTypes.HeistSessionState

local HeistController = {}

local activeHeistHud: Frame? = nil
local alarmFillBar: Frame? = nil
local alarmTextLbl: TextLabel? = nil
local objectiveLbl: TextLabel? = nil
local gadgetBtn: TextButton? = nil

local currentSession: HeistSessionState? = nil

function HeistController.OpenBriefing()
	local theme = UIComponents.Theme
	SoundEffects.PlayNPCVoice("Vance")
	local heistDef = HeistDefinitions.Get("heist_obsidian_outpost")
	if not heistDef then
		return
	end

	local dimmer, content = UIComponents.CreateModal("Vance the Shadow - Heist Briefing", UDim2.new(0, 620, 0, 440))

	local missionTitle = UIComponents.CreateLabel(content, heistDef.name, UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), 18, theme.AccentGold)
	missionTitle.Font = Enum.Font.GothamBold

	local details = UIComponents.CreateLabel(
		content,
		"Target Relic: Obsidian Chalice (Rare)\n" ..
		"Objective: Infiltrate the vault, bypass laser tripwires, and extract via Main Gate (Alpha), Shadow Drain (Beta), or Catacombs (Gamma).\n" ..
		"Rewards: 🪙 300 Cash, 💎 15 Shards, and the Obsidian Chalice Relic.\n" ..
		"Failure Protection: Permanent relics in your collection are safely preserved if you fall.",
		UDim2.new(1, 0, 0, 100),
		UDim2.new(0, 0, 0, 35),
		12,
		theme.TextPrimary
	)
	details.TextWrapped = true

	-- Gadget selection
	local gadgetInfo = UIComponents.CreateRoundedFrame(
		content,
		UDim2.new(1, 0, 0, 60),
		UDim2.new(0, 0, 0, 145),
		theme.Surface,
		6
	)

	UIComponents.CreateLabel(gadgetInfo, "Tactical Infiltration Tool:", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 8), 12, theme.AccentBlue).Font = Enum.Font.GothamBold
	UIComponents.CreateLabel(gadgetInfo, "Alchemical Smoke Capsule equipped (Press [Q] during heist to suppress lasers for 10s)", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 30), 11, theme.TextSecondary)

	-- Infiltration Launch Button
	UIComponents.CreateButton(
		content,
		"Begin Infiltration",
		UDim2.new(0, 220, 0, 46),
		UDim2.new(0.5, -110, 1, -55),
		Color3.fromRGB(180, 40, 40),
		function()
			local startFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.StartHeist)
			local res = startFn:InvokeServer(heistDef.heistId, "tool_smoke_capsule")

			if res and res.success then
				dimmer:Destroy()
				HeistController.ShowHeistHud(res.session)
			else
				HUDController.ShowToast("Heist Failed to Start", res.message or "Error", "Warning")
			end
		end
	)
end

function HeistController.DeployGadget()
	if not currentSession or currentSession.toolUsed then
		return
	end

	local useToolFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.UseHeistTool)
	local res = useToolFn:InvokeServer()
	if res and res.success then
		currentSession.toolUsed = true
		if gadgetBtn then
			gadgetBtn.Text = "💨 Smoke Deployed!"
			gadgetBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		end
	end
end

function HeistController.ShowHeistHud(session: HeistSessionState)
	currentSession = session
	local mainGui = UIComponents.GetMainGui()
	local theme = UIComponents.Theme

	if activeHeistHud then
		activeHeistHud:Destroy()
	end

	local hud = UIComponents.CreateRoundedFrame(
		mainGui,
		UDim2.new(0, 360, 0, 64),
		UDim2.new(0.5, 0, 0, 70),
		theme.Background,
		8
	)
	hud.AnchorPoint = Vector2.new(0.5, 0)
	hud.ZIndex = 22
	activeHeistHud = hud

	objectiveLbl = UIComponents.CreateLabel(
		hud,
		if session.objectiveSecured then "🎯 Secured! Escape to Exit Pad!" else "🎯 Objective: Steal Obsidian Chalice",
		UDim2.new(1, -114, 0, 20),
		UDim2.new(0, 10, 0, 6),
		12,
		theme.AccentGold
	)
	objectiveLbl.Font = Enum.Font.GothamBold
	objectiveLbl.TextTruncate = Enum.TextTruncate.AtEnd
	objectiveLbl.ZIndex = 23

	-- Gadget deployment button on HUD
	gadgetBtn = UIComponents.CreateButton(
		hud,
		if session.toolUsed then "💨 Deployed" else "💨 Smoke (Q)",
		UDim2.new(0, 100, 0, 24),
		UDim2.new(1, -108, 0, 5),
		if session.toolUsed then Color3.fromRGB(70, 70, 80) else Color3.fromRGB(50, 120, 180),
		function()
			HeistController.DeployGadget()
		end
	)
	gadgetBtn.TextSize = 11
	gadgetBtn.ZIndex = 24

	-- Alarm Meter Frame
	local barBg = UIComponents.CreateRoundedFrame(
		hud,
		UDim2.new(1, -20, 0, 12),
		UDim2.new(0, 10, 0, 30),
		Color3.fromRGB(40, 40, 45),
		4
	)
	barBg.ZIndex = 23

	alarmFillBar = Instance.new("Frame")
	alarmFillBar.Size = UDim2.new(session.alarmLevel / 100, 0, 1, 0)
	alarmFillBar.BackgroundColor3 = theme.AccentGreen
	alarmFillBar.BorderSizePixel = 0
	alarmFillBar.ZIndex = 24
	alarmFillBar.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = alarmFillBar

	alarmTextLbl = UIComponents.CreateLabel(
		hud,
		string.format("Alarm Level: %d%%", session.alarmLevel),
		UDim2.new(1, -20, 0, 14),
		UDim2.new(0, 10, 0, 46),
		10,
		theme.TextSecondary
	)
	alarmTextLbl.TextTruncate = Enum.TextTruncate.AtEnd
	alarmTextLbl.ZIndex = 23
end

function HeistController.UpdateHeistState(session: HeistSessionState)
	currentSession = session
	if session.phase == "Extracted" or session.phase == "Failed" then
		HUDController.SetEscapeCountdown(0)
		if activeHeistHud then
			activeHeistHud:Destroy()
			activeHeistHud = nil
		end
		HeistController.ShowRecap(session)
		return
	end

	if session.phase == "ObjectiveSecured" and session.extractionDeadline then
		local remaining = math.max(0, session.extractionDeadline - os.time())
		HUDController.SetEscapeCountdown(remaining)
	else
		HUDController.SetEscapeCountdown(0)
	end

	if not activeHeistHud then
		HeistController.ShowHeistHud(session)
	end

	if alarmFillBar and alarmTextLbl then
		local pct = math.clamp(session.alarmLevel / 100, 0, 1)
		alarmFillBar.Size = UDim2.new(pct, 0, 1, 0)
		alarmTextLbl.Text = string.format("Alarm Level: %d%%", session.alarmLevel)

		if session.alarmLevel > 70 then
			alarmFillBar.BackgroundColor3 = UIComponents.Theme.AccentRed
		elseif session.alarmLevel > 35 then
			alarmFillBar.BackgroundColor3 = UIComponents.Theme.AccentGold
		else
			alarmFillBar.BackgroundColor3 = UIComponents.Theme.AccentGreen
		end
	end

	if objectiveLbl then
		if session.objectiveSecured then
			objectiveLbl.Text = "🎯 Chalice Secured! Escape via Main Gate (Alpha), Drain (Beta), or Catacombs (Gamma)!"
			objectiveLbl.TextColor3 = UIComponents.Theme.AccentGreen
		end
	end
end

function HeistController.ShowRecap(session: HeistSessionState)
	local theme = UIComponents.Theme
	local isSuccess = (session.phase == "Extracted")
	local title = if isSuccess then "HEIST ACCOMPLISHED" else "HEIST ABORTED"
	local dimmer, content = UIComponents.CreateModal(title, UDim2.new(0, 500, 0, 320))

	local banner = UIComponents.CreateLabel(
		content,
		if isSuccess then "You successfully infiltrated the Obsidian Outpost and escaped with the vault relic!" else "Mission concluded. Your permanent collection was safely protected.",
		UDim2.new(1, 0, 0, 48),
		UDim2.new(0, 0, 0, 10),
		13,
		if isSuccess then theme.AccentGreen else theme.AccentRed
	)
	banner.TextWrapped = true

	local statsText = if isSuccess
		then "• Cash Earned: 🪙 300\n• Relic Shards: 💎 15\n• Relic Added to Collection: Obsidian Chalice (Rare)\n• Final Alarm: " .. tostring(session.alarmLevel) .. "%"
		else "• Cash Earned: 0\n• Permanent Relics Lost: 0 (Safely Preserved)\n• You may plan another infiltration at any time."

	local statsLbl = UIComponents.CreateLabel(content, statsText, UDim2.new(1, 0, 0, 90), UDim2.new(0, 0, 0, 65), 12, theme.TextPrimary)

	UIComponents.CreateButton(content, "Return to Market", UDim2.new(0, 180, 0, 40), UDim2.new(0.5, -90, 1, -50), theme.AccentGold, function()
		dimmer:Destroy()
	end)
end

function HeistController.Init()
	local stateEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.HeistStateChanged)
	stateEvent.OnClientEvent:Connect(function(sessionState: HeistSessionState)
		HeistController.UpdateHeistState(sessionState)
	end)

	local alarmEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.AlarmTriggered)
	alarmEvent.OnClientEvent:Connect(function(level: number, reason: string)
		HUDController.ShowToast("Alarm Warning", reason .. " (Alarm: " .. tostring(level) .. "%)", "Warning")
	end)
end

return HeistController
