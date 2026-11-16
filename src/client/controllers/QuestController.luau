--!strict
-- QuestController.luau
-- Authoritative client UI for Quests & Objectives ([J] keybind)
-- Categorized tabs for Progression, Daily, and Repeatables with live progress and claiming.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local QuestDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("QuestDefinitions"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local HUDController = require(script.Parent.HUDController)

type PlayerProfile = CommonTypes.PlayerProfile
type QuestDefinition = CommonTypes.QuestDefinition

local QuestController = {}

local activeDimmer: Frame? = nil
local currentTab = "Progression"

function QuestController.Close()
	if activeDimmer then
		activeDimmer:Destroy()
		activeDimmer = nil
	end
end

function QuestController.IsOpen(): boolean
	return activeDimmer ~= nil
end

function QuestController.Toggle(profile: PlayerProfile?)
	if QuestController.IsOpen() then
		QuestController.Close()
	else
		QuestController.Open(profile)
	end
end

function QuestController.Open(profile: PlayerProfile?)
	QuestController.Close()
	SoundEffects.PlayClick()

	local targetProfile = profile
	if not targetProfile then
		local getProfileFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.GetPlayerProfile)
		targetProfile = getProfileFn:InvokeServer()
	end
	if not targetProfile then
		return
	end

	local theme = UIComponents.Theme
	local dimmer, content = UIComponents.CreateModal("📜 QUEST JOURNAL & OBJECTIVES", UDim2.new(0, 680, 0, 540), function()
		activeDimmer = nil
	end)
	activeDimmer = dimmer

	dimmer.Destroying:Connect(function()
		if activeDimmer == dimmer then
			activeDimmer = nil
		end
	end)

	-- Header Tabs
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "QuestTabs"
	tabContainer.Size = UDim2.new(1, 0, 0, 36)
	tabContainer.Position = UDim2.new(0, 0, 0, 0)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = content

	local scrollContainer = Instance.new("Frame")
	scrollContainer.Name = "ScrollContainer"
	scrollContainer.Size = UDim2.new(1, 0, 1, -44)
	scrollContainer.Position = UDim2.new(0, 0, 0, 42)
	scrollContainer.BackgroundTransparency = 1
	scrollContainer.Parent = content

	local function renderTabContent(category: string)
		scrollContainer:ClearAllChildren()

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "QuestScroll"
		scroll.Size = UDim2.new(1, 0, 1, 0)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 6
		scroll.ScrollBarImageColor3 = theme.AccentGold
		scroll.Parent = scrollContainer

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 8)
		listLayout.Parent = scroll

		local filteredQuests = {}
		for _, q in ipairs(QuestDefinitions.All) do
			if category == "Progression" and (q.category == "Progression" or q.category == nil) then
				table.insert(filteredQuests, q)
			elseif category == "Daily" and (q.category == "Daily" or q.category == "Repeatable") then
				table.insert(filteredQuests, q)
			end
		end

		for _, quest: QuestDefinition in ipairs(filteredQuests) do
			local isCompleted = targetProfile.completedQuests[quest.questId] or false
			local isClaimed = targetProfile.claimedQuests[quest.questId] or false

			local cardBg = if isClaimed
				then Color3.fromRGB(24, 28, 24)
				elseif isCompleted
				then Color3.fromRGB(30, 48, 36)
				else theme.Surface

			local card = UIComponents.CreateRoundedFrame(scroll, UDim2.new(1, -8, 0, 80), UDim2.new(0, 0, 0, 0), cardBg, 8)

			local tagText = if quest.category == "Daily" then "[DAILY] " elseif quest.category == "Repeatable" then "[REPEATABLE] " else ""
			local titleColor = if isClaimed then theme.TextSecondary elseif isCompleted then theme.AccentGreen else theme.AccentGold

			local title = UIComponents.CreateLabel(
				card,
				string.format("%s%d. %s", tagText, quest.order, quest.title),
				UDim2.new(0.68, 0, 0, 22),
				UDim2.new(0, 12, 0, 8),
				13,
				titleColor
			)
			title.Font = Enum.Font.GothamBold

			local desc = UIComponents.CreateLabel(
				card,
				quest.description,
				UDim2.new(0.68, 0, 0, 28),
				UDim2.new(0, 12, 0, 28),
				11,
				theme.TextPrimary
			)
			desc.TextWrapped = true

			local rewardLbl = UIComponents.CreateLabel(
				card,
				string.format("Rewards: 🪙 $%d Cash  •  💎 %d Shards", quest.rewardCash, quest.rewardShards),
				UDim2.new(0.68, 0, 0, 18),
				UDim2.new(0, 12, 0, 56),
				10,
				theme.AccentGold
			)

			-- Action / Claim Button
			local btnText = if isClaimed
				then "CLAIMED ✓"
				elseif isCompleted
				then "CLAIM REWARD"
				else "IN PROGRESS"

			local btnColor = if isClaimed
				then Color3.fromRGB(50, 60, 50)
				elseif isCompleted
				then theme.AccentGold
				else Color3.fromRGB(55, 52, 60)

			UIComponents.CreateButton(
				card,
				btnText,
				UDim2.new(0, 140, 0, 36),
				UDim2.new(1, -150, 0.5, -18),
				btnColor,
				function()
					if not isCompleted or isClaimed then return end

					local claimFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.ClaimQuestReward)
					local res = claimFn:InvokeServer(quest.questId)

					if res and res.success then
						targetProfile.claimedQuests[quest.questId] = true
						HUDController.ShowToast("Reward Claimed!", string.format("+%d Cash, +%d Shards", quest.rewardCash, quest.rewardShards), "Success")
						renderTabContent(currentTab)
					else
						HUDController.ShowToast("Claim Failed", (res and res.message) or "Error", "Warning")
					end
				end
			)
		end

		scroll.CanvasSize = UDim2.new(0, 0, 0, #filteredQuests * 88 + 10)
	end

	-- Tab Buttons
	local tabs = {
		{ name = "Progression Quests (12)", key = "Progression" },
		{ name = "Daily & Repeatable", key = "Daily" },
	}

	for i, t in ipairs(tabs) do
		UIComponents.CreateButton(
			tabContainer,
			t.name,
			UDim2.new(0, 200, 1, 0),
			UDim2.new(0, (i - 1) * 208, 0, 0),
			theme.Card,
			function()
				currentTab = t.key
				renderTabContent(currentTab)
			end
		)
	end

	renderTabContent(currentTab)
end

return QuestController
