--!strict
-- HUDController.luau
-- Authoritative top-level HUD presentation: non-overlapping responsive layout,
-- Region indicator badge, currency displays, active quest tracker,
-- extraction countdown, quick-action shortcuts ([B], [J], [M]), and sound-reactive stacked toast alerts.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local RelicDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local QuestDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("QuestDefinitions"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)

type PlayerProfile = CommonTypes.PlayerProfile

local HUDController = {}

-- UI Reference Elements
local regionTitleLabel: TextLabel? = nil
local regionSubtitleLabel: TextLabel? = nil

local cashLabel: TextLabel? = nil
local shardsLabel: TextLabel? = nil
local relicBadgeName: TextLabel? = nil
local relicBadgeBuff: TextLabel? = nil
local toastContainer: Frame? = nil

-- Top-Center Quest & Countdown Elements
local questBarFrame: Frame? = nil
local questTitleLabel: TextLabel? = nil
local questSubtextLabel: TextLabel? = nil

local latestProfile: PlayerProfile? = nil
local openCollectionCallback: ((PlayerProfile) -> ())? = nil
local openQuestsCallback: ((PlayerProfile) -> ())? = nil
local openRebirthCallback: ((PlayerProfile) -> ())? = nil
local openSettingsCallback: (() -> ())? = nil
local mobileGadgetCallback: (() -> ())? = nil
local raidVignette: Frame? = nil

function HUDController.SetCollectionCallback(callback: (PlayerProfile) -> ())
	openCollectionCallback = callback
end

function HUDController.SetQuestsCallback(callback: (PlayerProfile) -> ())
	openQuestsCallback = callback
end

function HUDController.SetRebirthCallback(callback: (PlayerProfile) -> ())
	openRebirthCallback = callback
end

function HUDController.SetSettingsCallback(callback: () -> ())
	openSettingsCallback = callback
end

function HUDController.SetMobileGadgetCallback(callback: () -> ())
	mobileGadgetCallback = callback
end

function HUDController.PulseRaidVignette()
	if not raidVignette then return end
	local tweenIn = TweenService:Create(raidVignette, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.65 })
	tweenIn:Play()
	tweenIn.Completed:Connect(function()
		local tweenOut = TweenService:Create(raidVignette, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1.0 })
		tweenOut:Play()
	end)
end

function HUDController.Init()
	local mainGui = UIComponents.GetMainGui()
	local theme = UIComponents.Theme

	--------------------------------------------------------------------
	-- 1. TOP-LEFT REGION INDICATOR BADGE
	--------------------------------------------------------------------
	local regionBadgeFrame = UIComponents.CreateRoundedFrame(
		mainGui,
		UDim2.new(0, 196, 0, 42),
		UDim2.new(0, 16, 0, 16),
		theme.Surface,
		8
	)
	regionBadgeFrame.Name = "RegionBadge"
	regionBadgeFrame.ZIndex = 10

	local regionStroke = regionBadgeFrame:FindFirstChildOfClass("UIStroke")
	if regionStroke then
		regionStroke.Color = theme.BorderGold
	end

	regionTitleLabel = UIComponents.CreateLabel(
		regionBadgeFrame,
		"📍 Forgotten Market",
		UDim2.new(1, -16, 0, 20),
		UDim2.new(0, 10, 0, 4),
		12,
		theme.AccentGold
	)
	regionTitleLabel.Font = Enum.Font.GothamBold
	regionTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	regionTitleLabel.ZIndex = 11

	regionSubtitleLabel = UIComponents.CreateLabel(
		regionBadgeFrame,
		"Central Safe Settlement",
		UDim2.new(1, -16, 0, 16),
		UDim2.new(0, 10, 0, 22),
		10,
		theme.TextSecondary
	)
	regionSubtitleLabel.Font = Enum.Font.Gotham
	regionSubtitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	regionSubtitleLabel.ZIndex = 11

	--------------------------------------------------------------------
	-- 2. TOP-RIGHT CURRENCY PILL & QUICK ACTION CONTROLS
	--------------------------------------------------------------------
	local currencyFrame = UIComponents.CreateRoundedFrame(
		mainGui,
		UDim2.new(0, 224, 0, 42),
		UDim2.new(1, -240, 0, 16),
		theme.Surface,
		8
	)
	currencyFrame.Name = "CurrencyFrame"
	currencyFrame.ZIndex = 10

	cashLabel = UIComponents.CreateLabel(
		currencyFrame,
		string.format("🪙 Cash: %d", EconomyConfig.STARTING_CASH),
		UDim2.new(0.5, -8, 1, 0),
		UDim2.new(0, 10, 0, 0),
		12,
		theme.AccentGold
	)
	cashLabel.Font = Enum.Font.GothamBold
	cashLabel.TextTruncate = Enum.TextTruncate.AtEnd
	cashLabel.ZIndex = 11

	shardsLabel = UIComponents.CreateLabel(
		currencyFrame,
		"💎 Shards: 0",
		UDim2.new(0.5, -8, 1, 0),
		UDim2.new(0.5, 4, 0, 0),
		12,
		theme.AccentBlue
	)
	shardsLabel.Font = Enum.Font.GothamBold
	shardsLabel.TextTruncate = Enum.TextTruncate.AtEnd
	shardsLabel.ZIndex = 11

	-- Quick Action Buttons Bar directly under Currency Frame
	local actionsContainer = Instance.new("Frame")
	actionsContainer.Name = "QuickActionsBar"
	actionsContainer.Size = UDim2.new(0, 280, 0, 32)
	actionsContainer.Position = UDim2.new(1, -296, 0, 62)
	actionsContainer.BackgroundTransparency = 1
	actionsContainer.ZIndex = 15
	actionsContainer.Parent = mainGui

	local colBtn = UIComponents.CreateButton(
		actionsContainer,
		"🎒 Relics [B]",
		UDim2.new(0, 74, 1, 0),
		UDim2.new(0, 0, 0, 0),
		theme.Surface,
		function()
			if openCollectionCallback then
				openCollectionCallback(latestProfile)
			end
		end
	)
	colBtn.TextSize = 11
	colBtn.ZIndex = 16

	local questBtn = UIComponents.CreateButton(
		actionsContainer,
		"📜 Quests [J]",
		UDim2.new(0, 76, 1, 0),
		UDim2.new(0, 78, 0, 0),
		theme.Surface,
		function()
			if openQuestsCallback then
				openQuestsCallback(latestProfile)
			end
		end
	)
	questBtn.TextSize = 11
	questBtn.ZIndex = 16

	local rebirthBtn = UIComponents.CreateButton(
		actionsContainer,
		"🌟 Rebirth [P]",
		UDim2.new(0, 74, 1, 0),
		UDim2.new(0, 158, 0, 0),
		Color3.fromRGB(48, 28, 64),
		function()
			if openRebirthCallback then
				openRebirthCallback(latestProfile)
			end
		end
	)
	rebirthBtn.TextSize = 10
	rebirthBtn.ZIndex = 16

	local setBtn = UIComponents.CreateButton(
		actionsContainer,
		"⚙️ [M]",
		UDim2.new(0, 44, 1, 0),
		UDim2.new(0, 236, 0, 0),
		theme.Surface,
		function()
			if openSettingsCallback then
				openSettingsCallback()
			end
		end
	)
	setBtn.TextSize = 11
	setBtn.ZIndex = 16

	--------------------------------------------------------------------
	-- 3. TOP-CENTER RESPONSIVE QUEST & EXTRACTION BAR
	-- Designed with AnchorPoint (0.5, 0) and dynamic sizing so it never overlaps left/right badges
	--------------------------------------------------------------------
	questBarFrame = Instance.new("Frame")
	questBarFrame.Name = "QuestBarFrame"
	questBarFrame.AnchorPoint = Vector2.new(0.5, 0)
	questBarFrame.Position = UDim2.new(0.5, 0, 0, 16)
	questBarFrame.Size = UDim2.new(0.36, 0, 0, 48)
	questBarFrame.BackgroundColor3 = theme.Surface
	questBarFrame.BorderSizePixel = 0
	questBarFrame.ZIndex = 10
	questBarFrame.Parent = mainGui

	local questSizeConstraint = Instance.new("UISizeConstraint")
	questSizeConstraint.MinSize = Vector2.new(240, 44)
	questSizeConstraint.MaxSize = Vector2.new(380, 52)
	questSizeConstraint.Parent = questBarFrame

	local qCorner = Instance.new("UICorner")
	qCorner.CornerRadius = UDim.new(0, 8)
	qCorner.Parent = questBarFrame

	local qStroke = Instance.new("UIStroke")
	qStroke.Color = theme.Border
	qStroke.Thickness = 1
	qStroke.Parent = questBarFrame

	local questBarClickable = Instance.new("TextButton")
	questBarClickable.Name = "QuestBarClickable"
	questBarClickable.Size = UDim2.new(1, 0, 1, 0)
	questBarClickable.Position = UDim2.new(0, 0, 0, 0)
	questBarClickable.BackgroundTransparency = 1
	questBarClickable.Text = ""
	questBarClickable.ZIndex = 12
	questBarClickable.Parent = questBarFrame

	questBarClickable.MouseButton1Click:Connect(function()
		if openQuestsCallback then
			openQuestsCallback(latestProfile)
		end
	end)

	questTitleLabel = UIComponents.CreateLabel(
		questBarFrame,
		"📜 ACTIVE OBJECTIVE: The Calling",
		UDim2.new(1, -20, 0, 20),
		UDim2.new(0, 10, 0, 4),
		12,
		theme.AccentGold
	)
	questTitleLabel.Font = Enum.Font.GothamBold
	questTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	questTitleLabel.ZIndex = 11

	questSubtextLabel = UIComponents.CreateLabel(
		questBarFrame,
		"Seek out Elder Corvus on the sanctuary dais and bond with a relic.",
		UDim2.new(1, -20, 0, 18),
		UDim2.new(0, 10, 0, 24),
		10,
		theme.TextSecondary
	)
	questSubtextLabel.Font = Enum.Font.Gotham
	questSubtextLabel.TextTruncate = Enum.TextTruncate.AtEnd
	questSubtextLabel.ZIndex = 11

	--------------------------------------------------------------------
	-- 4. BOTTOM-CENTER EQUIPPED RELIC BADGE (Clickable)
	--------------------------------------------------------------------
	local badgeBtn = Instance.new("TextButton")
	badgeBtn.Name = "EquippedRelicBadge"
	badgeBtn.AnchorPoint = Vector2.new(0.5, 1)
	badgeBtn.Size = UDim2.new(0, 310, 0, 48)
	badgeBtn.Position = UDim2.new(0.5, 0, 1, -16)
	badgeBtn.BackgroundColor3 = theme.Surface
	badgeBtn.Text = ""
	badgeBtn.BorderSizePixel = 0
	badgeBtn.ZIndex = 10
	badgeBtn.Parent = mainGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = badgeBtn

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.BorderGold
	stroke.Thickness = 1
	stroke.Parent = badgeBtn

	badgeBtn.MouseButton1Click:Connect(function()
		if openCollectionCallback and latestProfile then
			openCollectionCallback(latestProfile)
		end
	end)

	relicBadgeName = UIComponents.CreateLabel(
		badgeBtn,
		"⚡ Equipped: None",
		UDim2.new(1, -24, 0, 20),
		UDim2.new(0, 12, 0, 5),
		13,
		theme.TextPrimary
	)
	relicBadgeName.Font = Enum.Font.GothamBold
	relicBadgeName.TextTruncate = Enum.TextTruncate.AtEnd
	relicBadgeName.ZIndex = 11

	relicBadgeBuff = UIComponents.CreateLabel(
		badgeBtn,
		"Click or press [B] to inspect collection",
		UDim2.new(1, -24, 0, 16),
		UDim2.new(0, 12, 0, 25),
		11,
		theme.TextSecondary
	)
	relicBadgeBuff.Font = Enum.Font.Gotham
	relicBadgeBuff.TextTruncate = Enum.TextTruncate.AtEnd
	relicBadgeBuff.ZIndex = 11

	--------------------------------------------------------------------
	-- 5. TOAST NOTIFICATION CONTAINER (Multi-Toast Stacking Queue)
	--------------------------------------------------------------------
	toastContainer = Instance.new("Frame")
	toastContainer.Name = "ToastContainer"
	toastContainer.AnchorPoint = Vector2.new(0.5, 0)
	toastContainer.Size = UDim2.new(0, 360, 0, 220)
	toastContainer.Position = UDim2.new(0.5, 0, 0, 74)
	toastContainer.BackgroundTransparency = 1
	toastContainer.ZIndex = 30
	toastContainer.Parent = mainGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = toastContainer

	-- Fullscreen Tactical Alarm Vignette
	raidVignette = Instance.new("Frame")
	raidVignette.Name = "RaidAlarmVignette"
	raidVignette.Size = UDim2.new(1, 0, 1, 0)
	raidVignette.Position = UDim2.new(0, 0, 0, 0)
	raidVignette.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
	raidVignette.BackgroundTransparency = 1
	raidVignette.BorderSizePixel = 0
	raidVignette.ZIndex = 2
	raidVignette.Parent = mainGui

	-- Mobile Quick Tactical Gadget Pill (visible on touch devices)
	if UserInputService.TouchEnabled then
		local mobileGadget = UIComponents.CreateRoundedFrame(
			mainGui,
			UDim2.new(0, 84, 0, 48),
			UDim2.new(1, -98, 1, -150),
			Color3.fromRGB(50, 45, 65),
			8
		)
		mobileGadget.Name = "MobileGadgetPill"
		mobileGadget.ZIndex = 20

		local mgBtn = UIComponents.CreateButton(
			mobileGadget,
			"⚡ SMOKE",
			UDim2.new(1, -6, 1, -6),
			UDim2.new(0, 3, 0, 3),
			Color3.fromRGB(80, 45, 120),
			function()
				if mobileGadgetCallback then
					mobileGadgetCallback()
				end
			end
		)
		mgBtn.TextSize = 11
		mgBtn.ZIndex = 21
	end
end

function HUDController.SetCurrentRegion(regionName: string, regionSubtitle: string?)
	if regionTitleLabel then
		regionTitleLabel.Text = "📍 " .. regionName
	end
	if regionSubtitleLabel and regionSubtitle then
		regionSubtitleLabel.Text = regionSubtitle
	end
end

local previousCash: number? = nil

function HUDController.UpdateProfile(profile: PlayerProfile)
	if previousCash ~= nil and profile.currencies.Cash > previousCash then
		SoundEffects.PlayCash()
	end
	previousCash = profile.currencies.Cash
	latestProfile = profile

	if cashLabel then
		cashLabel.Text = string.format("🪙 Cash: %d", profile.currencies.Cash)
	end
	if shardsLabel then
		shardsLabel.Text = string.format("💎 Shards: %d", profile.currencies.RelicShards)
	end

	-- Update active quest tracker
	if questTitleLabel and questSubtextLabel then
		local activeQuest = nil
		for _, q in ipairs(QuestDefinitions.All) do
			if not profile.completedQuests[q.questId] or not profile.claimedQuests[q.questId] then
				activeQuest = q
				break
			end
		end

		if activeQuest then
			if profile.completedQuests[activeQuest.questId] and not profile.claimedQuests[activeQuest.questId] then
				questTitleLabel.Text = string.format("📜 OBJECTIVE COMPLETE: %s", activeQuest.title)
				questTitleLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
				questSubtextLabel.Text = "Press [J] to claim your reward in the Quests log!"
			else
				questTitleLabel.Text = string.format("📜 ACTIVE: %s", activeQuest.title)
				questTitleLabel.TextColor3 = UIComponents.Theme.AccentGold
				questSubtextLabel.Text = activeQuest.description
			end
		else
			questTitleLabel.Text = "🌟 ALL CURRENT QUESTS COMPLETE"
			questTitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			questSubtextLabel.Text = "Explore the market, upgrade your base, or raid the outpost!"
		end
	end

	-- Update equipped relic pill
	if relicBadgeName and relicBadgeBuff then
		if profile.equippedRelicId then
			local targetDefId = nil
			local targetUpgradeLvl = 1
			for _, inst in ipairs(profile.inventory) do
				if inst.instanceId == profile.equippedRelicId then
					targetDefId = inst.definitionId
					targetUpgradeLvl = inst.upgradeLevel or 1
					break
				end
			end

			if targetDefId then
				local def = RelicDefinitions.Get(targetDefId)
				if def then
					local lvlSuffix = if targetUpgradeLvl > 1 then string.format(" [T%d]", targetUpgradeLvl) else ""
					relicBadgeName.Text = string.format("⚡ %s%s (%s)", def.name, lvlSuffix, def.rarity)
					relicBadgeBuff.Text = def.buff.description
					relicBadgeName.TextColor3 = def.accentColor
					return
				end
			end
		end

		relicBadgeName.Text = "⚡ Equipped: None"
		relicBadgeBuff.Text = "Click or press [B] to inspect collection"
		relicBadgeName.TextColor3 = UIComponents.Theme.TextSecondary
	end
end

function HUDController.SetEscapeCountdown(secondsRemaining: number)
	if questTitleLabel and questSubtextLabel and questBarFrame then
		if secondsRemaining > 0 then
			questBarFrame.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
			questTitleLabel.Text = string.format("🚨 EXTRACTION DEADLINE: %02ds", secondsRemaining)
			questTitleLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
			questSubtextLabel.Text = "Escape to Route Alpha, Beta, or Gamma before lockdown!"
		else
			questBarFrame.BackgroundColor3 = UIComponents.Theme.Surface
			if latestProfile then
				HUDController.UpdateProfile(latestProfile)
			end
		end
	end
end

local toastOrderCounter = 0

function HUDController.ShowToast(title: string, message: string, alertType: string)
	if not toastContainer then
		return
	end

	if alertType == "Success" then
		SoundEffects.PlayRelicChime()
	elseif alertType == "Warning" then
		SoundEffects.PlayAlarm()
	end

	local theme = UIComponents.Theme
	local bgColor = theme.Surface
	if alertType == "Success" then
		bgColor = Color3.fromRGB(30, 65, 40)
	elseif alertType == "Warning" then
		bgColor = Color3.fromRGB(75, 40, 25)
	end

	toastOrderCounter += 1
	local toast = UIComponents.CreateRoundedFrame(
		toastContainer,
		UDim2.new(1, 0, 0, 46),
		UDim2.new(0, 0, 0, 0),
		bgColor,
		8
	)
	toast.LayoutOrder = toastOrderCounter
	toast.BackgroundTransparency = 0.1
	toast.ZIndex = 31

	local titleLbl = UIComponents.CreateLabel(toast, title, UDim2.new(1, -20, 0, 18), UDim2.new(0, 10, 0, 5), 12, theme.AccentGold)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
	titleLbl.ZIndex = 32

	local msgLbl = UIComponents.CreateLabel(toast, message, UDim2.new(1, -20, 0, 16), UDim2.new(0, 10, 0, 23), 10, theme.TextPrimary)
	msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
	msgLbl.ZIndex = 32

	task.delay(4.0, function()
		local fade = TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Connect(function()
			toast:Destroy()
		end)
	end)
end

return HUDController
