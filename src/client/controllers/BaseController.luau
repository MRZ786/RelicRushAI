--!strict
-- BaseController.luau
-- Authoritative player base plot management, Tier 2 & 3 upgrades, interactive placement preview,
-- customisation object moving/removing, defenses overview, and rival sanctum raid selector.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local HUDController = require(script.Parent.HUDController)

type PlayerProfile = CommonTypes.PlayerProfile
type RivalBaseInfo = CommonTypes.RivalBaseInfo

local BaseController = {}

local localPlayer = Players.LocalPlayer
local activePlacementGhost: Part? = nil
local placementRenderConn: RBXScriptConnection? = nil
local placementInputConn: RBXScriptConnection? = nil
local placementHud: Frame? = nil
local currentRotationY = 0

local function getPlotCenter(plotIndex: number): Vector3
	local coords = EconomyConfig.PLOT_COORDINATES
	if plotIndex >= 1 and plotIndex <= #coords then
		return coords[plotIndex]
	end
	return coords[1]
end

local function cleanPlacementMode()
	if activePlacementGhost then
		activePlacementGhost:Destroy()
		activePlacementGhost = nil
	end
	if placementRenderConn then
		placementRenderConn:Disconnect()
		placementRenderConn = nil
	end
	if placementInputConn then
		placementInputConn:Disconnect()
		placementInputConn = nil
	end
	if placementHud then
		placementHud:Destroy()
		placementHud = nil
	end
end

-- =============================================================================
-- INTERACTIVE PLACEMENT & MOVE PREVIEW
-- =============================================================================

function BaseController.EnterPlacementMode(itemId: string, existingPlacementId: string?)
	cleanPlacementMode()

	local item = EconomyConfig.GetItem(itemId)
	if not item then return end

	local camera = Workspace.CurrentCamera
	if not camera then return end

	local plotIndex = 1
	-- Retrieve assigned plot index from signpost or default
	local world = Workspace:FindFirstChild("RelicRushWorld")
	if world then
		for idx = 1, EconomyConfig.PLOT_COUNT do
			local folder = world:FindFirstChild("BasePlot_" .. tostring(idx), true)
			if folder then
				local sign = folder:FindFirstChild("PlotSignPost")
				if sign then
					local bb = sign:FindFirstChild("PlotBillboard") :: BillboardGui?
					if bb then
						local lbl = bb:FindFirstChild("TitleLabel") :: TextLabel?
						if lbl and string.find(string.lower(lbl.Text), string.lower(localPlayer.DisplayName)) then
							plotIndex = idx
							break
						end
					end
				end
			end
		end
	end

	local plotCenter = getPlotCenter(plotIndex)
	currentRotationY = 0

	-- Create translucent ghost part
	local ghost = Instance.new("Part")
	ghost.Name = "PlacementPreviewGhost"
	ghost.Size = Vector3.new(4, 2, 4)
	ghost.Color = Color3.fromRGB(0, 255, 120)
	ghost.Material = Enum.Material.Neon
	ghost.Transparency = 0.5
	ghost.CanCollide = false
	ghost.Anchored = true
	ghost.Parent = Workspace
	activePlacementGhost = ghost

	-- Onscreen Build Control Banner
	local mainGui = UIComponents.GetMainGui()
	local theme = UIComponents.Theme
	local banner = UIComponents.CreateRoundedFrame(
		mainGui,
		UDim2.new(0, 480, 0, 56),
		UDim2.new(0.5, -240, 0, 16),
		theme.Surface,
		8
	)
	banner.Name = "BuildModeBanner"
	banner.ZIndex = 60
	placementHud = banner

	local bannerTitle = if existingPlacementId
		then string.format("REPOSITIONING: %s", item.name)
		else string.format("BUILDING: %s", item.name)

	local titleLbl = UIComponents.CreateLabel(
		banner,
		bannerTitle,
		UDim2.new(1, -20, 0, 20),
		UDim2.new(0, 10, 0, 6),
		12,
		theme.AccentGold
	)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.ZIndex = 61

	local instrLbl = UIComponents.CreateLabel(
		banner,
		"Left Click: Place | [R]: Rotate 45° | [X] / [Esc]: Cancel",
		UDim2.new(1, -20, 0, 18),
		UDim2.new(0, 10, 0, 28),
		11,
		theme.TextPrimary
	)
	instrLbl.ZIndex = 61

	local lastTargetRelPos = Vector3.new(0, 1, 0)
	local isValidPosition = true

	placementRenderConn = RunService.RenderStepped:Connect(function()
		if not activePlacementGhost then return end

		local mousePos = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { activePlacementGhost, localPlayer.Character }

		local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
		local hitPos = if result then result.Position else (plotCenter + Vector3.new(0, 1, 0))

		local rel = hitPos - plotCenter
		local clampedX = math.clamp(rel.X, -EconomyConfig.BASE_PLOT_HALF_SIZE, EconomyConfig.BASE_PLOT_HALF_SIZE)
		local clampedZ = math.clamp(rel.Z, -EconomyConfig.BASE_PLOT_HALF_SIZE, EconomyConfig.BASE_PLOT_HALF_SIZE)
		lastTargetRelPos = Vector3.new(clampedX, 1, clampedZ)

		isValidPosition = (math.abs(rel.X) <= EconomyConfig.BASE_PLOT_HALF_SIZE and math.abs(rel.Z) <= EconomyConfig.BASE_PLOT_HALF_SIZE)

		activePlacementGhost.CFrame = CFrame.new(plotCenter + lastTargetRelPos) * CFrame.Angles(0, math.rad(currentRotationY), 0)
		if isValidPosition then
			activePlacementGhost.Color = Color3.fromRGB(0, 255, 120)
		else
			activePlacementGhost.Color = Color3.fromRGB(255, 50, 50)
		end
	end)

	placementInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.R then
			currentRotationY = (currentRotationY + 45) % 360
		elseif input.KeyCode == Enum.KeyCode.X or input.KeyCode == Enum.KeyCode.Escape then
			cleanPlacementMode()
			HUDController.ShowToast("Placement Cancelled", "Exited base build mode.", "Info")
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not isValidPosition then
				HUDController.ShowToast("Invalid Location", "Must be inside your 40x40 base plot boundaries.", "Warning")
				return
			end

			if existingPlacementId then
				-- Move existing
				local moveFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestMoveBaseObject)
				local res = moveFn:InvokeServer(existingPlacementId, lastTargetRelPos, currentRotationY)
				cleanPlacementMode()
				if res and res.success then
					HUDController.ShowToast("Repositioned!", res.message, "Success")
				else
					HUDController.ShowToast("Move Failed", res.message or "Error", "Warning")
				end
			else
				-- Place new
				local key = HttpService:GenerateGUID(false)
				local placeFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestPlaceBaseObject)
				local res = placeFn:InvokeServer(itemId, lastTargetRelPos, currentRotationY, key)
				cleanPlacementMode()
				if res and res.success then
					HUDController.ShowToast("Placed!", res.message, "Success")
				else
					HUDController.ShowToast("Placement Failed", res.message or "Error", "Warning")
				end
			end
		end
	end)
end

-- =============================================================================
-- RIVAL BASE INFILTRATION SELECTOR MODAL
-- =============================================================================

function BaseController.OpenRivalSelector(profile: PlayerProfile)
	local theme = UIComponents.Theme
	local dimmer, content = UIComponents.CreateModal("Sanctum Infiltration — Target Rival", UDim2.new(0, 640, 0, 480))

	local introLbl = UIComponents.CreateLabel(
		content,
		"Infiltrate online rivals in this server to siphon uncollected tribute.\n" ..
		"Permanent relics and wallet cash are protected. Vault wards mitigates siphon yield.",
		UDim2.new(1, -20, 0, 36),
		UDim2.new(0, 10, 0, 4),
		11,
		theme.TextSecondary
	)
	introLbl.TextWrapped = true

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "RivalsList"
	listFrame.Size = UDim2.new(1, -20, 1, -60)
	listFrame.Position = UDim2.new(0, 10, 0, 46)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 6
	listFrame.ScrollBarImageColor3 = theme.AccentGold
	listFrame.Parent = content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = listFrame

	-- Fetch live rival bases from server
	task.spawn(function()
		local rivalsFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.GetRivalBaseList)
		local res = rivalsFn:InvokeServer()

		if not res or not res.rivals or #res.rivals == 0 then
			local emptyLbl = UIComponents.CreateLabel(
				listFrame,
				"No other rival players currently in the server to infiltrate.\nExplore world zones or invite others to test defenses!",
				UDim2.new(1, 0, 0, 80),
				UDim2.new(0, 0, 0, 20),
				13,
				theme.TextSecondary
			)
			emptyLbl.TextWrapped = true
			return
		end

		for _, rival: RivalBaseInfo in ipairs(res.rivals) do
			local card = UIComponents.CreateRoundedFrame(
				listFrame,
				UDim2.new(1, -8, 0, 68),
				UDim2.new(0, 0, 0, 0),
				theme.Surface,
				8
			)

			local rName = UIComponents.CreateLabel(
				card,
				string.format("🏰 %s (Plot #%d)", rival.displayName, rival.plotIndex),
				UDim2.new(0.6, 0, 0, 22),
				UDim2.new(0, 12, 0, 8),
				13,
				theme.TextPrimary
			)
			rName.Font = Enum.Font.GothamBold

			local secLevel = if rival.defenseRating >= 50 then "Heavily Fortified" elseif rival.defenseRating >= 25 then "Defended" else "Vulnerable"
			local tributeText = if rival.uncollectedTributeCash > 0
				then string.format("🪙 ~$%.0f Siphonable", rival.uncollectedTributeCash * 0.25)
				else "🪙 Coffer Empty ($0)"

			local rStats = UIComponents.CreateLabel(
				card,
				string.format("Tier %d Sanctuary • 🛡️ Defense: %d [%s] • %s",
					rival.baseTier, rival.defenseRating, secLevel, tributeText),
				UDim2.new(0.65, 0, 0, 20),
				UDim2.new(0, 12, 0, 34),
				11,
				theme.AccentGold
			)

			local btnText = if rival.isEligible
				then "Infiltrate Base"
				else string.format("Fortified (%ds)", rival.cooldownRemaining)

			local btnColor = if rival.isEligible
				then Color3.fromRGB(190, 40, 40)
				else Color3.fromRGB(70, 70, 80)

			UIComponents.CreateButton(
				card,
				btnText,
				UDim2.new(0, 140, 0, 38),
				UDim2.new(1, -152, 0.5, -19),
				btnColor,
				function()
					if not rival.isEligible then
						HUDController.ShowToast("Fortified Sanctum", "Target base is currently on raid cooldown.", "Warning")
						return
					end

					local raidFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestRaidBase)
					local raidRes = raidFn:InvokeServer(rival.userId)

					if raidRes and raidRes.success then
						dimmer:Destroy()
						HUDController.ShowToast("Infiltration Commenced", raidRes.message, "Success")
					else
						HUDController.ShowToast("Infiltration Failed", (raidRes and raidRes.message) or "Unable to start raid", "Warning")
					end
				end
			)
		end

		listFrame.CanvasSize = UDim2.new(0, 0, 0, #res.rivals * 76 + 20)
	end)
end

-- =============================================================================
-- SANCTUM WORKSHOP BENCH MODAL (BASE MANAGEMENT & CUSTOMISATION)
-- =============================================================================

function BaseController.OpenBaseManager(profile: PlayerProfile)
	local theme = UIComponents.Theme
	local currentTier = profile.baseData.tier
	local nextTier = currentTier + 1
	local upgradeCost = if nextTier == 2 then EconomyConfig.BASE_UPGRADE_TIER_2_COST else EconomyConfig.BASE_UPGRADE_TIER_3_COST

	local dimmer, content = UIComponents.CreateModal("Sanctum Workshop Bench", UDim2.new(0, 680, 0, 520))

	local defRating = profile.baseData.defenseRating or 10
	local secLevel = if defRating >= 50 then "Heavily Fortified" elseif defRating >= 25 then "Defended" else "Vulnerable"

	-- Header Info
	UIComponents.CreateLabel(
		content,
		string.format("Sanctum Plot #%d — Tier %d Sanctuary • 🛡️ Defense Rating: %d [%s]\nPlaced Objects: %d / %d Capacity",
			profile.baseData.plotIndex or 1, currentTier, defRating, secLevel,
			#profile.baseData.placedObjects, EconomyConfig.MAX_PLACED_OBJECTS_PER_BASE),
		UDim2.new(0.68, 0, 0, 42),
		UDim2.new(0, 8, 0, 0),
		12,
		theme.AccentGold
	)

	-- "Raid Rival Sanctums" Quick Button in Header
	UIComponents.CreateButton(
		content,
		"⚔️ Raid Rivals",
		UDim2.new(0, 160, 0, 36),
		UDim2.new(1, -170, 0, 4),
		Color3.fromRGB(170, 40, 40),
		function()
			dimmer:Destroy()
			BaseController.OpenRivalSelector(profile)
		end
	)

	-- 1. Upgrade Sanctum Frame
	local upgradeFrame = UIComponents.CreateRoundedFrame(
		content,
		UDim2.new(1, 0, 0, 80),
		UDim2.new(0, 0, 0, 46),
		theme.Surface,
		6
	)

	local upgTitleText = if currentTier >= 3
		then "Sanctuary Tier 3: Arcane Master (MAXED)"
		elseif currentTier == 2
		then "Upgrade to Tier 3: Arcane Sanctuary (+15 Defense, Marble Columns, Levitating Crystal)"
		else "Upgrade to Tier 2: Stone Workshop (+15 Defense, Master Blacksmith Forge, Azure Canopy)"

	local upgTitle = UIComponents.CreateLabel(upgradeFrame, upgTitleText, UDim2.new(0.72, 0, 0, 24), UDim2.new(0, 12, 0, 8), 12, theme.AccentBlue)
	upgTitle.Font = Enum.Font.GothamBold

	local upgBtnText = if currentTier >= 3 then "MAXED" else string.format("Upgrade (🪙 %d)", upgradeCost)
	local upgBtnColor = if currentTier >= 3 then Color3.fromRGB(80, 80, 90) else theme.AccentGold

	UIComponents.CreateButton(
		upgradeFrame,
		upgBtnText,
		UDim2.new(0.24, 0, 0, 36),
		UDim2.new(0.74, 0, 0.5, -18),
		upgBtnColor,
		function()
			if currentTier >= 3 then return end
			local key = HttpService:GenerateGUID(false)
			local upgFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestBaseUpgrade)
			local res = upgFn:InvokeServer(key)

			if res and res.success then
				HUDController.ShowToast("Upgrade Complete!", res.message, "Success")
				dimmer:Destroy()
			else
				HUDController.ShowToast("Upgrade Failed", res.message or "Error", "Warning")
			end
		end
	)

	-- 2. Customisation Tabs Bar
	local categories = {
		{ name = "Decor", key = "decor" },
		{ name = "Flooring", key = "floor" },
		{ name = "Walls", key = "wall" },
		{ name = "Lighting", key = "light" },
		{ name = "Defenses", key = "defense" },
		{ name = string.format("Manage (%d)", #profile.baseData.placedObjects), key = "manage" },
	}

	local currentTab = "decor"
	local scrollContent: ScrollingFrame? = nil

	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "CategoryTabs"
	tabContainer.Size = UDim2.new(1, 0, 0, 32)
	tabContainer.Position = UDim2.new(0, 0, 0, 134)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = content

	local listContainer = Instance.new("Frame")
	listContainer.Name = "ListContainer"
	listContainer.Size = UDim2.new(1, 0, 1, -172)
	listContainer.Position = UDim2.new(0, 0, 0, 170)
	listContainer.BackgroundTransparency = 1
	listContainer.Parent = content

	local function renderTabContent(tabKey: string)
		listContainer:ClearAllChildren()

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "ScrollItems"
		scroll.Size = UDim2.new(1, 0, 1, 0)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 6
		scroll.ScrollBarImageColor3 = theme.AccentGold
		scroll.Parent = listContainer
		scrollContent = scroll

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 6)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = scroll

		if tabKey == "manage" then
			-- Manage placed items
			if #profile.baseData.placedObjects == 0 then
				UIComponents.CreateLabel(scroll, "No customisation objects placed yet. Select items from other tabs to decorate your base!", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10), 12, theme.TextSecondary)
				return
			end

			for _, placed in ipairs(profile.baseData.placedObjects) do
				local pItem = EconomyConfig.GetItem(placed.itemId)
				local itemName = if pItem then pItem.name else placed.itemId

				local row = UIComponents.CreateRoundedFrame(
					scroll,
					UDim2.new(1, -8, 0, 52),
					UDim2.new(0, 0, 0, 0),
					theme.Surface,
					6
				)

				local nameLbl = UIComponents.CreateLabel(
					row,
					string.format("%s (Pos: %.1f, %.1f • Rot: %d°)", itemName, placed.position.X, placed.position.Z, placed.rotationY),
					UDim2.new(0.6, 0, 1, 0),
					UDim2.new(0, 10, 0, 0),
					12,
					theme.TextPrimary
				)
				nameLbl.Font = Enum.Font.GothamMedium

				-- Move button
				UIComponents.CreateButton(
					row,
					"Move",
					UDim2.new(0, 80, 0, 32),
					UDim2.new(1, -185, 0.5, -16),
					theme.Card,
					function()
						dimmer:Destroy()
						BaseController.EnterPlacementMode(placed.itemId, placed.placementId)
					end
				)

				-- Remove button
				UIComponents.CreateButton(
					row,
					"Remove",
					UDim2.new(0, 85, 0, 32),
					UDim2.new(1, -95, 0.5, -16),
					Color3.fromRGB(160, 45, 45),
					function()
						local removeFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestRemoveBaseObject)
						local res = removeFn:InvokeServer(placed.placementId)
						if res and res.success then
							HUDController.ShowToast("Removed", res.message, "Success")
							dimmer:Destroy()
						else
							HUDController.ShowToast("Remove Failed", res.message or "Error", "Warning")
						end
					end
				)
			end

			scroll.CanvasSize = UDim2.new(0, 0, 0, #profile.baseData.placedObjects * 60 + 10)
		else
			-- Catalog items for the selected category
			local catalogItems = {}
			for itemId, cItem in pairs(EconomyConfig.ShopCatalog) do
				if tabKey == "decor" and cItem.category == "Decoration" and (string.sub(itemId, 1, 6) == "decor_") then
					table.insert(catalogItems, cItem)
				elseif tabKey == "floor" and string.sub(itemId, 1, 6) == "floor_" then
					table.insert(catalogItems, cItem)
				elseif tabKey == "wall" and string.sub(itemId, 1, 5) == "wall_" then
					table.insert(catalogItems, cItem)
				elseif tabKey == "light" and string.sub(itemId, 1, 6) == "light_" then
					table.insert(catalogItems, cItem)
				elseif tabKey == "defense" and cItem.category == "Defense" then
					table.insert(catalogItems, cItem)
				end
			end

			table.sort(catalogItems, function(a, b) return a.priceCash < b.priceCash end)

			for _, cItem in ipairs(catalogItems) do
				local row = UIComponents.CreateRoundedFrame(
					scroll,
					UDim2.new(1, -8, 0, 62),
					UDim2.new(0, 0, 0, 0),
					theme.Surface,
					6
				)

				local nameLbl = UIComponents.CreateLabel(
					row,
					cItem.name,
					UDim2.new(0.65, 0, 0, 20),
					UDim2.new(0, 10, 0, 8),
					13,
					theme.TextPrimary
				)
				nameLbl.Font = Enum.Font.GothamBold

				local defBonus = if cItem.defenseValue then string.format(" • 🛡️ +%d Defense", cItem.defenseValue) else ""
				local descLbl = UIComponents.CreateLabel(
					row,
					string.format("🪙 %d Cash%s — %s", cItem.priceCash, defBonus, cItem.description),
					UDim2.new(0.65, 0, 0, 24),
					UDim2.new(0, 10, 0, 30),
					11,
					theme.AccentGold
				)
				descLbl.TextWrapped = true

				UIComponents.CreateButton(
					row,
					string.format("+ Place (%d)", cItem.priceCash),
					UDim2.new(0, 130, 0, 38),
					UDim2.new(1, -140, 0.5, -19),
					theme.Card,
					function()
						dimmer:Destroy()
						BaseController.EnterPlacementMode(cItem.itemId, nil)
					end
				)
			end

			scroll.CanvasSize = UDim2.new(0, 0, 0, #catalogItems * 70 + 10)
		end
	end

	-- Create tab buttons
	local tabWidth = 108
	for i, cat in ipairs(categories) do
		local btn = UIComponents.CreateButton(
			tabContainer,
			cat.name,
			UDim2.new(0, tabWidth, 1, 0),
			UDim2.new(0, (i - 1) * (tabWidth + 4), 0, 0),
			theme.Card,
			function()
				currentTab = cat.key
				renderTabContent(currentTab)
			end
		)
		btn.TextSize = 11
	end

	renderTabContent("decor")
end

return BaseController
