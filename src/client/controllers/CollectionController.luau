--!strict
-- CollectionController.luau
-- Manages the full Relic Collection, active loadout, discovery codex (discovered vs ???),
-- collection milestones claiming, relic refinement upgrading, and base vault management.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local RelicDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local MilestoneDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("MilestoneDefinitions"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local HUDController = require(script.Parent.HUDController)

type PlayerProfile = CommonTypes.PlayerProfile
type RelicInstance = CommonTypes.RelicInstance
type RelicDefinition = CommonTypes.RelicDefinition
type MilestoneDefinition = CommonTypes.MilestoneDefinition

local CollectionController = {}

local activeDimmer: Frame? = nil
local currentTab = "Inventory"

function CollectionController.Close()
	if activeDimmer then
		activeDimmer:Destroy()
		activeDimmer = nil
	end
end

function CollectionController.IsOpen(): boolean
	return activeDimmer ~= nil
end

function CollectionController.Toggle(profile: PlayerProfile?)
	if CollectionController.IsOpen() then
		CollectionController.Close()
	else
		CollectionController.OpenShowcase(profile)
	end
end

local function isMilestoneEligible(profile: PlayerProfile, milestone: MilestoneDefinition): (boolean, string)
	if milestone.category == "DiscoveryCount" then
		local count = 0
		for _ in pairs(profile.discoveredRelics or {}) do
			count += 1
		end
		local req = milestone.targetCount or 1
		return count >= req, string.format("Progress: %d/%d Relics", count, req)
	elseif milestone.category == "RarityTier" then
		local targetRarity = milestone.targetRarity or "Uncommon"
		for relId in pairs(profile.discoveredRelics or {}) do
			local def = RelicDefinitions.Get(relId)
			if def and def.rarity == targetRarity then
				return true, string.format("Discovered %s relic", targetRarity)
			end
		end
		return false, string.format("Requires discovering a %s relic", targetRarity)
	elseif milestone.category == "SignatureRelic" then
		local targetId = milestone.targetRelicId or "relic_hollow_crown"
		local hasCrown = profile.discoveredRelics ~= nil and profile.discoveredRelics[targetId] == true
		return hasCrown, if hasCrown then "Hollow Crown Discovered" else "Requires The Hollow Crown"
	end

	return false, "Incomplete"
end

function CollectionController.OpenShowcase(profile: PlayerProfile?, initialTab: string?)
	CollectionController.Close()
	SoundEffects.PlayClick()

	local targetProfile = profile
	if not targetProfile then
		local getProfileFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.GetPlayerProfile)
		targetProfile = getProfileFn:InvokeServer()
	end
	if not targetProfile then
		return
	end

	currentTab = initialTab or "Inventory"

	local theme = UIComponents.Theme
	local dimmer, content = UIComponents.CreateModal("🏛️ RELIC CODEX & COLLECTION VAULT", UDim2.new(0, 840, 0, 580), function()
		activeDimmer = nil
	end)
	activeDimmer = dimmer

	dimmer.Destroying:Connect(function()
		if activeDimmer == dimmer then
			activeDimmer = nil
		end
	end)

	-- Navigation Tabs
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "NavTabs"
	tabContainer.Size = UDim2.new(1, 0, 0, 36)
	tabContainer.Position = UDim2.new(0, 0, 0, 0)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = content

	local bodyContainer = Instance.new("Frame")
	bodyContainer.Name = "BodyContainer"
	bodyContainer.Size = UDim2.new(1, 0, 1, -44)
	bodyContainer.Position = UDim2.new(0, 0, 0, 42)
	bodyContainer.BackgroundTransparency = 1
	bodyContainer.Parent = content

	local renderCurrentTab: () -> ()

	local function updateTabButtons()
		tabContainer:ClearAllChildren()

		local tabs = {
			{ id = "Inventory", label = "🎒 Loadout & Inventory" },
			{ id = "Codex", label = "📖 Discovery Codex" },
			{ id = "Milestones", label = "🏆 Milestones & Prestige" },
		}

		local tabWidth = 1 / #tabs
		for i, tab in ipairs(tabs) do
			local isSelected = currentTab == tab.id
			local bg = if isSelected then theme.AccentGold else theme.Surface
			local textCol = if isSelected then Color3.fromRGB(15, 15, 20) else theme.TextPrimary

			local btn = UIComponents.CreateButton(
				tabContainer,
				tab.label,
				UDim2.new(tabWidth, -6, 1, 0),
				UDim2.new(tabWidth * (i - 1), 3, 0, 0),
				bg,
				function()
					if currentTab ~= tab.id then
						currentTab = tab.id
						updateTabButtons()
						renderCurrentTab()
					end
				end
			)
			btn.TextColor3 = textCol
			btn.Font = if isSelected then Enum.Font.GothamBold else Enum.Font.GothamMedium
		end
	end

	renderCurrentTab = function()
		bodyContainer:ClearAllChildren()

		local discoveredCount = 0
		for _ in pairs(targetProfile.discoveredRelics or {}) do
			discoveredCount += 1
		end

		local allRelicsCatalog: { RelicDefinition } = {}
		for _, def in pairs(RelicDefinitions.GetAll()) do
			table.insert(allRelicsCatalog, def)
		end
		table.sort(allRelicsCatalog, function(a, b)
			return a.baseValue < b.baseValue
		end)

		if currentTab == "Inventory" then
			--------------------------------------------------------------------
			-- TAB 1: INVENTORY & LOADOUT
			--------------------------------------------------------------------
			-- Top Stats Bar
			local statsBar = UIComponents.CreateRoundedFrame(bodyContainer, UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 0, 0), theme.Surface, 6)
			local synergyText = ""
			if targetProfile.relicSynergies and #targetProfile.relicSynergies > 0 then
				synergyText = "  |  ⚡ Synergies: " .. table.concat(targetProfile.relicSynergies, ", ")
			end

			UIComponents.CreateLabel(
				statsBar,
				string.format("📜 Codex: %d/%d Discovered  |  🎒 Inventory: %d/25  |  🏆 Raids/Heists: %d%s",
					discoveredCount, #allRelicsCatalog, #targetProfile.inventory, targetProfile.completedHeistsCount, synergyText),
				UDim2.new(1, -20, 1, 0),
				UDim2.new(0, 12, 0, 0),
				11,
				theme.AccentGold
			).Font = Enum.Font.GothamBold

			-- Left Column: Active Loadout Card (Width: 260)
			local loadoutFrame = UIComponents.CreateRoundedFrame(bodyContainer, UDim2.new(0, 260, 1, -50), UDim2.new(0, 0, 0, 48), theme.Surface, 8)
			UIComponents.CreateLabel(loadoutFrame, "ACTIVE BONDED LOADOUT", UDim2.new(1, -20, 0, 24), UDim2.new(0, 12, 0, 8), 12, theme.AccentBlue).Font = Enum.Font.GothamBold

			local equippedInst: RelicInstance? = nil
			if targetProfile.equippedRelicId then
				for _, inst in ipairs(targetProfile.inventory) do
					if inst.instanceId == targetProfile.equippedRelicId then
						equippedInst = inst
						break
					end
				end
			end

			if equippedInst then
				local def = RelicDefinitions.Get(equippedInst.definitionId)
				if def then
					local card = UIComponents.CreateRoundedFrame(loadoutFrame, UDim2.new(1, -24, 0, 260), UDim2.new(0, 12, 0, 36), theme.Background, 6)

					local accent = Instance.new("Frame")
					accent.Size = UDim2.new(1, 0, 0, 4)
					accent.BackgroundColor3 = def.accentColor
					accent.BorderSizePixel = 0
					accent.Parent = card

					local lvl = equippedInst.upgradeLevel or 1
					UIComponents.CreateLabel(card, def.name .. string.format(" (Lvl %d)", lvl), UDim2.new(1, -16, 0, 22), UDim2.new(0, 10, 0, 10), 13, def.accentColor).Font = Enum.Font.GothamBold
					UIComponents.CreateLabel(card, "Rarity: " .. def.rarity .. "  •  Value: " .. tostring(def.baseValue) .. " 🪙", UDim2.new(1, -16, 0, 18), UDim2.new(0, 10, 0, 32), 11, theme.TextSecondary)
					UIComponents.CreateLabel(card, def.buff.description, UDim2.new(1, -16, 0, 22), UDim2.new(0, 10, 0, 52), 11, theme.AccentGold).Font = Enum.Font.GothamBold

					local desc = UIComponents.CreateLabel(card, def.description, UDim2.new(1, -16, 0, 50), UDim2.new(0, 10, 0, 76), 10, theme.TextPrimary)
					desc.TextWrapped = true

					local lore = UIComponents.CreateLabel(card, "“" .. def.lore .. "”", UDim2.new(1, -16, 0, 45), UDim2.new(0, 10, 0, 130), 10, theme.TextSecondary)
					lore.TextWrapped = true

					UIComponents.CreateButton(card, "Unequip Relic", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 1, -40), Color3.fromRGB(180, 50, 50), function()
						local unequipFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestUnequipRelic)
						local res = unequipFn:InvokeServer()
						dimmer:Destroy()
						if res and res.success then
							HUDController.ShowToast("Unequipped", res.message, "Success")
						end
					end)
				end
			else
				local emptyCard = UIComponents.CreateRoundedFrame(loadoutFrame, UDim2.new(1, -24, 0, 140), UDim2.new(0, 12, 0, 36), theme.Background, 6)
				local emptyLbl = UIComponents.CreateLabel(
					emptyCard,
					"No relic currently equipped.\nSelect any relic from your collection on the right to bond and activate its passive blessing.",
					UDim2.new(1, -20, 1, -20),
					UDim2.new(0, 10, 0, 10),
					11,
					theme.TextSecondary
				)
				emptyLbl.TextWrapped = true
			end

			-- Base Showcase Box
			local showcaseBox = UIComponents.CreateRoundedFrame(loadoutFrame, UDim2.new(1, -24, 0, 90), UDim2.new(0, 12, 1, -100), theme.Background, 6)
			UIComponents.CreateLabel(showcaseBox, "🏛️ SANCTUM PLINTH SHOWCASE", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 6), 11, theme.AccentGold).Font = Enum.Font.GothamBold

			local showcaseName = "None"
			if targetProfile.showcaseRelicId then
				for _, inst in ipairs(targetProfile.inventory) do
					if inst.instanceId == targetProfile.showcaseRelicId then
						local def = RelicDefinitions.Get(inst.definitionId)
						if def then showcaseName = def.name end
						break
					end
				end
			end
			UIComponents.CreateLabel(showcaseBox, "Spotlight: " .. showcaseName, UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 26), 11, theme.TextPrimary)
			UIComponents.CreateLabel(showcaseBox, "Featured on your central base sanctum plinth.", UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 46), 10, theme.TextSecondary).TextWrapped = true

			-- Right Column: Owned Relic Collection Scroll (Width: 540)
			local scroll = Instance.new("ScrollingFrame")
			scroll.Size = UDim2.new(1, -280, 1, -50)
			scroll.Position = UDim2.new(0, 275, 0, 48)
			scroll.BackgroundTransparency = 1
			scroll.BorderSizePixel = 0
			scroll.ScrollBarThickness = 6
			scroll.ScrollBarImageColor3 = theme.AccentGold
			scroll.Parent = bodyContainer

			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 10)
			layout.Parent = scroll

			if #targetProfile.inventory == 0 then
				local noRelics = UIComponents.CreateLabel(
					scroll,
					"Your backpack is empty.\nSpeak with Elder Corvus in the market square or harvest ancient excavation nodes!",
					UDim2.new(1, 0, 0, 80),
					UDim2.new(0, 0, 0, 20),
					12,
					theme.TextSecondary
				)
				noRelics.TextWrapped = true
				return
			end

			for _, inst in ipairs(targetProfile.inventory) do
				local def = RelicDefinitions.Get(inst.definitionId)
				if not def then continue end

				local row = UIComponents.CreateRoundedFrame(scroll, UDim2.new(1, -10, 0, 110), UDim2.new(0, 0, 0, 0), theme.Surface, 6)

				local accentStripe = Instance.new("Frame")
				accentStripe.Size = UDim2.new(0, 5, 1, 0)
				accentStripe.BackgroundColor3 = def.accentColor
				accentStripe.BorderSizePixel = 0
				accentStripe.Parent = row

				local lvl = inst.upgradeLevel or 1
				local nameLbl = UIComponents.CreateLabel(
					row,
					string.format("%s (Lvl %d)", def.name, lvl) .. (if inst.isEquipped then "  [EQUIPPED]" else ""),
					UDim2.new(0.55, 0, 0, 22),
					UDim2.new(0, 16, 0, 8),
					13,
					def.accentColor
				)
				nameLbl.Font = Enum.Font.GothamBold

				UIComponents.CreateLabel(row, string.format("Rarity: %s  |  Buff: %s", def.rarity, def.buff.description), UDim2.new(0.55, 0, 0, 18), UDim2.new(0, 16, 0, 30), 11, theme.AccentGold)

				local descLbl = UIComponents.CreateLabel(row, def.description, UDim2.new(0.55, 0, 0, 48), UDim2.new(0, 16, 0, 50), 10, theme.TextSecondary)
				descLbl.TextWrapped = true

				-- Button 1: Equip / Active tag
				if not inst.isEquipped then
					UIComponents.CreateButton(row, "Equip", UDim2.new(0.20, 0, 0, 30), UDim2.new(0.58, 0, 0, 15), theme.AccentGold, function()
						local equipFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestEquipRelic)
						local res = equipFn:InvokeServer(inst.instanceId)
						dimmer:Destroy()
						if res and res.success then
							HUDController.ShowToast("Relic Equipped!", res.message, "Success")
						end
					end)
				else
					local eqTag = UIComponents.CreateLabel(row, "✓ ACTIVE", UDim2.new(0.20, 0, 0, 30), UDim2.new(0.58, 0, 0, 15), 11, theme.AccentGreen)
					eqTag.Font = Enum.Font.GothamBold
					eqTag.TextXAlignment = Enum.TextXAlignment.Center
				end

				-- Button 2: Refine
				if lvl < 3 then
					local cost = if lvl == 1 then 25 else 60
					UIComponents.CreateButton(row, string.format("Refine (%d💎)", cost), UDim2.new(0.20, 0, 0, 30), UDim2.new(0.79, 0, 0, 15), Color3.fromRGB(156, 39, 176), function()
						local refineFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestRefineRelic)
						local res = refineFn:InvokeServer(inst.instanceId)
						if res and res.success then
							SoundEffects.PlayRelicChime()
							dimmer:Destroy()
							HUDController.ShowToast("Refinement Success", res.message, "Success")
						else
							HUDController.ShowToast("Refine Failed", (res and res.message) or "Failed", "Warning")
						end
					end)
				else
					local maxTag = UIComponents.CreateLabel(row, "MAX LEVEL", UDim2.new(0.20, 0, 0, 30), UDim2.new(0.79, 0, 0, 15), 11, Color3.fromRGB(255, 215, 0))
					maxTag.Font = Enum.Font.GothamBold
					maxTag.TextXAlignment = Enum.TextXAlignment.Center
				end

				-- Button 3: Showcase on Base Plinth
				local isShowcased = targetProfile.showcaseRelicId == inst.instanceId
				local scText = if isShowcased then "★ Plinth" else "Set Plinth"
				local scCol = if isShowcased then Color3.fromRGB(40, 80, 120) else Color3.fromRGB(60, 65, 75)
				UIComponents.CreateButton(row, scText, UDim2.new(0.20, 0, 0, 28), UDim2.new(0.58, 0, 0, 58), scCol, function()
					local showcaseFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestSetShowcaseRelic)
					local res = showcaseFn:InvokeServer(inst.instanceId)
					dimmer:Destroy()
					if res and res.success then
						HUDController.ShowToast("Showcase Updated", "This relic is now featured on your base plinth!", "Success")
					end
				end)

				-- Button 4: Deposit into Vault Storage
				UIComponents.CreateButton(row, "Deposit Vault", UDim2.new(0.20, 0, 0, 28), UDim2.new(0.79, 0, 0, 58), Color3.fromRGB(50, 55, 65), function()
					local depFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestDepositVault)
					local res = depFn:InvokeServer(inst.instanceId)
					dimmer:Destroy()
					if res and res.success then
						HUDController.ShowToast("Vault Storage", "Relic safely stored in your base vault.", "Info")
					else
						HUDController.ShowToast("Storage Error", (res and res.message) or "Error", "Warning")
					end
				end)
			end

		elseif currentTab == "Codex" then
			--------------------------------------------------------------------
			-- TAB 2: DISCOVERY CODEX (Discovered vs ???)
			--------------------------------------------------------------------
			local pct = math.floor((discoveredCount / #allRelicsCatalog) * 100)
			local codexHeader = UIComponents.CreateRoundedFrame(bodyContainer, UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 0, 0), theme.Surface, 6)
			UIComponents.CreateLabel(
				codexHeader,
				string.format("📖 ARCHAEOLOGICAL CODEX: %d/%d Unique Relics Discovered (%d%% Completed)", discoveredCount, #allRelicsCatalog, pct),
				UDim2.new(1, -20, 1, 0),
				UDim2.new(0, 14, 0, 0),
				12,
				theme.AccentGold
			).Font = Enum.Font.GothamBold

			local scroll = Instance.new("ScrollingFrame")
			scroll.Size = UDim2.new(1, 0, 1, -50)
			scroll.Position = UDim2.new(0, 0, 0, 48)
			scroll.BackgroundTransparency = 1
			scroll.BorderSizePixel = 0
			scroll.ScrollBarThickness = 6
			scroll.ScrollBarImageColor3 = theme.AccentGold
			scroll.Parent = bodyContainer

			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 8)
			layout.Parent = scroll

			for _, def in ipairs(allRelicsCatalog) do
				local isDiscovered = targetProfile.discoveredRelics ~= nil and targetProfile.discoveredRelics[def.definitionId] == true

				if isDiscovered then
					-- Discovered Card
					local row = UIComponents.CreateRoundedFrame(scroll, UDim2.new(1, -8, 0, 86), UDim2.new(0, 0, 0, 0), theme.Surface, 6)

					local stripe = Instance.new("Frame")
					stripe.Size = UDim2.new(0, 5, 1, 0)
					stripe.BackgroundColor3 = def.accentColor
					stripe.BorderSizePixel = 0
					stripe.Parent = row

					local titleLbl = UIComponents.CreateLabel(
						row,
						def.name .. "  [DISCOVERED]",
						UDim2.new(0.65, 0, 0, 22),
						UDim2.new(0, 16, 0, 8),
						13,
						def.accentColor
					)
					titleLbl.Font = Enum.Font.GothamBold

					UIComponents.CreateLabel(
						row,
						string.format("Rarity: %s  |  Base Value: $%d  |  Plinth Yield: +$%d/tick  |  Buff: %s",
							def.rarity, def.baseValue, def.incomeRateCash, def.buff.description),
						UDim2.new(0.70, 0, 0, 18),
						UDim2.new(0, 16, 0, 30),
						11,
						theme.AccentGold
					)

					local loreLbl = UIComponents.CreateLabel(
						row,
						"“" .. def.lore .. "”",
						UDim2.new(0.70, 0, 0, 32),
						UDim2.new(0, 16, 0, 48),
						10,
						theme.TextSecondary
					)
					loreLbl.TextWrapped = true

					local badge = UIComponents.CreateRoundedFrame(row, UDim2.new(0.24, 0, 0, 34), UDim2.new(0.74, 0, 0.5, -17), Color3.fromRGB(24, 45, 30), 6)
					local bLbl = UIComponents.CreateLabel(badge, "✓ CHRONICLED", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 11, theme.AccentGreen)
					bLbl.Font = Enum.Font.GothamBold
					bLbl.TextXAlignment = Enum.TextXAlignment.Center

				else
					-- Undiscovered (???) Mystery Card
					local row = UIComponents.CreateRoundedFrame(scroll, UDim2.new(1, -8, 0, 86), UDim2.new(0, 0, 0, 0), Color3.fromRGB(20, 20, 25), 6)

					local stripe = Instance.new("Frame")
					stripe.Size = UDim2.new(0, 5, 1, 0)
					stripe.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
					stripe.BorderSizePixel = 0
					stripe.Parent = row

					local titleLbl = UIComponents.CreateLabel(
						row,
						"??? [Undiscovered Artifact]",
						UDim2.new(0.65, 0, 0, 22),
						UDim2.new(0, 16, 0, 8),
						13,
						Color3.fromRGB(150, 150, 160)
					)
					titleLbl.Font = Enum.Font.GothamBold

					UIComponents.CreateLabel(
						row,
						string.format("Rarity: %s  |  Status: Shrouded in Antiquity", def.rarity),
						UDim2.new(0.70, 0, 0, 18),
						UDim2.new(0, 16, 0, 30),
						11,
						Color3.fromRGB(120, 120, 130)
					)

					local hintLbl = UIComponents.CreateLabel(
						row,
						"Excavate dynamic relic nodes, explore ancient realm dungeons, or raid rival vaults to catalog this relic.",
						UDim2.new(0.70, 0, 0, 32),
						UDim2.new(0, 16, 0, 48),
						10,
						Color3.fromRGB(100, 100, 110)
					)
					hintLbl.TextWrapped = true

					local badge = UIComponents.CreateRoundedFrame(row, UDim2.new(0.24, 0, 0, 34), UDim2.new(0.74, 0, 0.5, -17), Color3.fromRGB(30, 30, 35), 6)
					local bLbl = UIComponents.CreateLabel(badge, "🔒 UNDISCOVERED", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 11, Color3.fromRGB(140, 140, 150))
					bLbl.Font = Enum.Font.GothamMedium
					bLbl.TextXAlignment = Enum.TextXAlignment.Center
				end
			end

		elseif currentTab == "Milestones" then
			--------------------------------------------------------------------
			-- TAB 3: MILESTONES & PRESTIGE
			--------------------------------------------------------------------
			local claimedCount = 0
			for _ in pairs(targetProfile.collectionMilestonesClaimed or {}) do
				claimedCount += 1
			end

			local mHeader = UIComponents.CreateRoundedFrame(bodyContainer, UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 0, 0), theme.Surface, 6)
			UIComponents.CreateLabel(
				mHeader,
				string.format("🏆 COLLECTION MILESTONES: %d/%d Tiers Claimed  •  Rewards validate authoritatively", claimedCount, #MilestoneDefinitions.All),
				UDim2.new(1, -20, 1, 0),
				UDim2.new(0, 14, 0, 0),
				12,
				theme.AccentGold
			).Font = Enum.Font.GothamBold

			local scroll = Instance.new("ScrollingFrame")
			scroll.Size = UDim2.new(1, 0, 1, -50)
			scroll.Position = UDim2.new(0, 0, 0, 48)
			scroll.BackgroundTransparency = 1
			scroll.BorderSizePixel = 0
			scroll.ScrollBarThickness = 6
			scroll.ScrollBarImageColor3 = theme.AccentGold
			scroll.Parent = bodyContainer

			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 8)
			layout.Parent = scroll

			for _, m in ipairs(MilestoneDefinitions.All) do
				local isClaimed = targetProfile.collectionMilestonesClaimed ~= nil and targetProfile.collectionMilestonesClaimed[m.milestoneId] == true
				local eligible, progText = isMilestoneEligible(targetProfile, m)

				local bgCol = if isClaimed
					then Color3.fromRGB(24, 28, 24)
					elseif eligible
					then Color3.fromRGB(30, 45, 35)
					else theme.Surface

				local card = UIComponents.CreateRoundedFrame(scroll, UDim2.new(1, -8, 0, 84), UDim2.new(0, 0, 0, 0), bgCol, 6)

				local categoryTag = if m.category == "DiscoveryCount" then "[COUNT] "
					elseif m.category == "RarityTier" then "[RARITY] "
					else "★ [SIGNATURE] "

				local titleCol = if isClaimed then theme.TextSecondary
					elseif eligible then theme.AccentGreen
					else theme.AccentGold

				local titleLbl = UIComponents.CreateLabel(
					card,
					categoryTag .. m.title,
					UDim2.new(0.68, 0, 0, 22),
					UDim2.new(0, 14, 0, 8),
					13,
					titleCol
				)
				titleLbl.Font = Enum.Font.GothamBold

				local rewardStr = string.format("Rewards: +$%d Cash  |  +%d Shards%s",
					m.rewardCash, m.rewardShards, if m.rewardTitle then "  |  Title: [" .. m.rewardTitle .. "]" else "")
				UIComponents.CreateLabel(card, rewardStr, UDim2.new(0.68, 0, 0, 18), UDim2.new(0, 14, 0, 30), 11, theme.AccentGold)

				local descLbl = UIComponents.CreateLabel(card, m.description, UDim2.new(0.68, 0, 0, 32), UDim2.new(0, 14, 0, 48), 10, theme.TextSecondary)
				descLbl.TextWrapped = true

				-- Status & Action on Right
				if isClaimed then
					local clTag = UIComponents.CreateLabel(card, "✓ CLAIMED", UDim2.new(0.24, 0, 0, 32), UDim2.new(0.73, 0, 0.5, -16), 11, theme.AccentGreen)
					clTag.Font = Enum.Font.GothamBold
					clTag.TextXAlignment = Enum.TextXAlignment.Center
				elseif eligible then
					UIComponents.CreateButton(card, "Claim Reward", UDim2.new(0.24, 0, 0, 34), UDim2.new(0.73, 0, 0.5, -17), theme.AccentGold, function()
						local claimFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.ClaimCollectionMilestone)
						local res = claimFn:InvokeServer(m.milestoneId)
						if res and res.success then
							SoundEffects.PlayRelicChime()
							HUDController.ShowToast("Milestone Claimed!", res.message, "Success")
							if not targetProfile.collectionMilestonesClaimed then
								targetProfile.collectionMilestonesClaimed = {}
							end
							targetProfile.collectionMilestonesClaimed[m.milestoneId] = true
							renderCurrentTab()
						else
							HUDController.ShowToast("Claim Failed", (res and res.message) or "Criteria unmet.", "Warning")
						end
					end)
				else
					local progLbl = UIComponents.CreateLabel(card, progText, UDim2.new(0.24, 0, 0, 32), UDim2.new(0.73, 0, 0.5, -16), 10, Color3.fromRGB(160, 160, 170))
					progLbl.Font = Enum.Font.GothamMedium
					progLbl.TextXAlignment = Enum.TextXAlignment.Center
				end
			end
		end
	end

	updateTabButtons()
	renderCurrentTab()
end

return CollectionController
