--!strict
-- OnboardingController.luau
-- Authoritative 9-step first-time player onboarding and guided tutorial system
-- Seamlessly integrated with 3D Navigation Waypoints, Compass Tracker, and Highlights.
-- Includes Skip, Resume, real-time objective updates, and completion rewards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local HUDController = require(script.Parent.HUDController)
local NavigationController = require(script.Parent.NavigationController)

type PlayerProfile = CommonTypes.PlayerProfile

local OnboardingController = {}

local tutorialBanner: Frame? = nil
local stepNumberLbl: TextLabel? = nil
local instructionLbl: TextLabel? = nil
local progressLbl: TextLabel? = nil
local skipBtn: TextButton? = nil
local welcomeModalShown = false
local currentStep = 1

local TUTORIAL_STEPS = {
	[1] = {
		title = "STEP 1: MEET ELDER CORVUS",
		instruction = "Follow the golden beacon west across the plaza to meet Elder Corvus. Press [E] to talk to him.",
		short = "Elder Corvus",
		navTarget = "ElderCorvus",
	},
	[2] = {
		title = "STEP 2: BOND STARTER RELIC",
		instruction = "In Elder Corvus's menu, choose one of 4 starter relics (Compass, Chisel, Eye, or Talisman) to bond your soul.",
		short = "Starter Relic",
		navTarget = "ElderCorvus",
	},
	[3] = {
		title = "STEP 3: EXPLORE FORGOTTEN WILDS",
		instruction = "Head west through the stone gateway arch into the overgrown ruins of the Forgotten Wilds.",
		short = "Explore Wilds",
		navTarget = "ForgottenWilds",
	},
	[4] = {
		title = "STEP 4: EXCAVATE A RELIC NODE",
		instruction = "Find a glowing relic mound in the wild forest and hold [E] to excavate your relic.",
		short = "Excavate Relic",
		navTarget = "ExcavationNode",
	},
	[5] = {
		title = "STEP 5: RETURN TO SANCTUM BASE",
		instruction = "Head east across the market into the Base District and find your personal assigned sanctum plot.",
		short = "Return to Base",
		navTarget = "MyBase",
	},
	[6] = {
		title = "STEP 6: SLOT RELIC ON PLINTH",
		instruction = "Approach one of your 10 Relic Plinths, press [E], and place a relic to start passive income.",
		short = "Slot on Plinth",
		navTarget = "MyPlinth",
	},
	[7] = {
		title = "STEP 7: COLLECT VAULT TRIBUTE",
		instruction = "Approach your central Sanctum Vault Coffer and press [E] to collect accumulated tribute.",
		short = "Collect Income",
		navTarget = "MyCoffer",
	},
	[8] = {
		title = "STEP 8: DISCOVER QUEST JOURNAL",
		instruction = "Press [J] or click 'Quests' on your HUD to review progression objectives and rewards.",
		short = "Quest Journal",
		navTarget = nil,
	},
	[9] = {
		title = "STEP 9: SANCTUM DEFENSE & RAIDING",
		instruction = "Open your workbench for base defenses (Wards, Totems), or plan a heist with Vance the Shadow.",
		short = "Defenses & Raids",
		navTarget = "VanceShadow",
	},
}

function OnboardingController.Init()
	local mainGui = UIComponents.GetMainGui()
	local theme = UIComponents.Theme

	-- Onboarding RPG Objective Banner
	local banner = UIComponents.CreateRoundedFrame(
		mainGui,
		UDim2.new(0, 360, 0, 92),
		UDim2.new(0, 16, 0, 68),
		theme.Surface,
		8
	)
	banner.Name = "OnboardingBanner"
	banner.Visible = false

	local stroke = banner:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = theme.AccentGold
		stroke.Thickness = 1.4
	end

	-- Golden Corner Accent Bar
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 4)
	topBar.BackgroundColor3 = theme.AccentGold
	topBar.BorderSizePixel = 0
	topBar.Parent = banner

	stepNumberLbl = UIComponents.CreateLabel(
		banner,
		"🧭 TUTORIAL: STEP 1 OF 9",
		UDim2.new(1, -95, 0, 18),
		UDim2.new(0, 12, 0, 8),
		11,
		theme.AccentGold
	)
	stepNumberLbl.Font = Enum.Font.GothamBold

	progressLbl = UIComponents.CreateLabel(
		banner,
		"[1/9]",
		UDim2.new(0, 70, 0, 16),
		UDim2.new(1, -82, 0, 8),
		11,
		theme.TextSecondary,
		Enum.TextXAlignment.Right
	)
	progressLbl.Font = Enum.Font.GothamMedium

	instructionLbl = UIComponents.CreateLabel(
		banner,
		TUTORIAL_STEPS[1].instruction,
		UDim2.new(1, -24, 0, 38),
		UDim2.new(0, 12, 0, 28),
		11,
		theme.TextPrimary
	)
	instructionLbl.TextWrapped = true

	-- Skip Tutorial Button
	skipBtn = UIComponents.CreateButton(
		banner,
		"Skip Tutorial",
		UDim2.new(0, 96, 0, 22),
		UDim2.new(1, -108, 1, -26),
		Color3.fromRGB(50, 48, 55),
		function()
			local skipFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.SkipTutorial)
			local res = skipFn:InvokeServer()
			if res and res.success then
				HUDController.ShowToast("Tutorial Skipped", "Onboarding skipped. You have full access to the world!", "Info")
				banner.Visible = false
				NavigationController.ClearTarget()
			end
		end
	)
	skipBtn.TextSize = 10

	tutorialBanner = banner
end

function OnboardingController.AdvanceStep(newStep: number)
	if newStep <= currentStep then return end
	currentStep = newStep

	local tutFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.CompleteTutorialStep)
	tutFn:InvokeServer(newStep)

	if newStep > 9 then
		if tutorialBanner then tutorialBanner.Visible = false end
		NavigationController.ClearTarget()
	end
end

function OnboardingController.ShowWelcomeModal(profile: PlayerProfile)
	if welcomeModalShown then return end
	welcomeModalShown = true

	local theme = UIComponents.Theme
	local dimmer, content = UIComponents.CreateModal("Welcome to Relic Rush", UDim2.new(0, 580, 0, 440))

	UIComponents.CreateLabel(
		content,
		"THE FORGOTTEN MARKET AWAITS",
		UDim2.new(1, 0, 0, 24),
		UDim2.new(0, 0, 0, 0),
		16,
		theme.AccentGold,
		Enum.TextXAlignment.Center
	).Font = Enum.Font.GothamBold

	local welcomeDesc = UIComponents.CreateLabel(
		content,
		"You have arrived at the threshold of an ancient dark-fantasy realm fractured into five zones.\n\n" ..
		"🪙 CASH & 💎 SHARDS: Fund your journey, expand your base, and refine your relics.\n" ..
		"🏛️ 10-PLINTH SANCTUM: Your personal base generates continuous passive income from placed relics.\n" ..
		"⚔️ LOW-RISK RAIDING: Infiltrate rival bases to siphon uncollected tribute. Permanent relics and stored cash are always safe!\n" ..
		"📜 9-STEP ONBOARDING: Follow the guided instructions or skip at any time.\n" ..
		"🧭 WAYPOINTS & COMPASS: The golden compass at the top of your screen points directly to your active objective.",
		UDim2.new(1, 0, 0, 240),
		UDim2.new(0, 0, 0, 36),
		12,
		theme.TextPrimary
	)
	welcomeDesc.TextWrapped = true

	UIComponents.CreateButton(
		content,
		"Begin Journey",
		UDim2.new(0, 180, 0, 42),
		UDim2.new(0.5, -90, 1, -52),
		theme.AccentGold,
		function()
			SoundEffects.PlayClick()
			dimmer:Destroy()
		end
	)
end

function OnboardingController.UpdateProfile(profile: PlayerProfile)
	if profile.completedTutorial then
		if tutorialBanner then
			tutorialBanner.Visible = false
		end
		NavigationController.ClearTarget()
		return
	end

	if not profile.hasSelectedStarter and not welcomeModalShown then
		task.delay(0.5, function()
			OnboardingController.ShowWelcomeModal(profile)
		end)
	end

	if not tutorialBanner or not instructionLbl or not progressLbl or not stepNumberLbl then
		return
	end

	-- Determine step based on saved profile progress or actions
	local step = math.clamp(profile.tutorialStep or 1, 1, 9)

	if not profile.hasSelectedStarter then
		step = 1
	elseif #profile.inventory < 2 and (not profile.discoveredCaches or not profile.discoveredCaches["cache_wilds_offering"]) then
		-- Has starter, needs to explore wilds and excavate
		step = if step < 3 then 3 else step
	elseif #profile.inventory >= 2 then
		-- Check if player has placed any relics on plinths
		local hasSlotted = false
		if profile.baseData and profile.baseData.slottedRelicIds then
			for _, rid in pairs(profile.baseData.slottedRelicIds) do
				if rid ~= nil then
					hasSlotted = true
					break
				end
			end
		end

		if not hasSlotted then
			step = if step < 5 then 5 else step
		end
	end

	currentStep = step
	local stepInfo = TUTORIAL_STEPS[step] or TUTORIAL_STEPS[1]

	tutorialBanner.Visible = true
	stepNumberLbl.Text = string.format("🧭 %s", stepInfo.title)
	instructionLbl.Text = stepInfo.instruction
	progressLbl.Text = string.format("[%d/9]", step)

	-- Update 3D Navigation Waypoint & Screen Compass
	if stepInfo.navTarget then
		NavigationController.SetTargetByName(stepInfo.navTarget)
	else
		NavigationController.ClearTarget()
	end
end

return OnboardingController