--!strict
-- NavigationController.luau
-- Authoritative waypoint, 3D beacon, screen-space compass, and objective tracker for Relic Rush
-- Guides players physically to NPCs, Base Plots, Plinths, Coffers, Relic Nodes, and Regional Gateways.
-- Fully responsive across Desktop, Mobile, and Console/Gamepad.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))

local player = Players.LocalPlayer

local NavigationController = {}

-- State
local currentTargetPos: Vector3? = nil
local currentTargetLabel: string = ""
local currentTargetInstance: Instance? = nil

-- Visual Instances
local navFolder: Folder? = nil
local beaconAnchor: Part? = nil
local beaconBeam: Part? = nil
local groundRune: Part? = nil
local targetHighlight: Highlight? = nil
local billboardGui: BillboardGui? = nil
local billboardLabel: TextLabel? = nil
local billboardDist: TextLabel? = nil
local breadcrumbDots: { Part } = {}
local hasPlayedArrivalChime = false

-- Screen HUD Compass
local compassFrame: Frame? = nil
local compassArrow: TextLabel? = nil
local compassLabel: TextLabel? = nil
local compassDistance: TextLabel? = nil

local renderConnection: RBXScriptConnection? = nil

-- Predefined Canonical World Locations
local CANONICAL_LOCATIONS: { [string]: { pos: Vector3, label: string } } = {
	["ElderCorvus"] = { pos = Vector3.new(-42, 4.2, -26), label = "Elder Corvus (Sanctuary)" },
	["BrimstoneBob"] = { pos = Vector3.new(38, 2.5, -31.5), label = "Brimstone Bob (Market Merchant)" },
	["AntiquarianValeria"] = { pos = Vector3.new(74.5, 2.5, -30), label = "Valeria (Antiquarian's Vault)" },
	["AlchemistIgnis"] = { pos = Vector3.new(39.5, 2.5, 29), label = "Ignis (Alchemist's Emporium)" },
	["TorvaldBlacksmith"] = { pos = Vector3.new(-52, 2.5, 9.5), label = "Torvald (Artisan Blacksmith)" },
	["VanceShadow"] = { pos = Vector3.new(-49, 3.0, 35.5), label = "Vance the Shadow (Infiltration Den)" },
	["ForgottenWilds"] = { pos = Vector3.new(-120, 2, -150), label = "Forgotten Wilds Gateway" },
	["SunkenVault"] = { pos = Vector3.new(300, 2, 320), label = "Sunken Vault / Obsidian Outpost" },
	["AshenDomain"] = { pos = Vector3.new(0, 2, -140), label = "Ashen Domain (Empire District)" },
	["CelestialRift"] = { pos = Vector3.new(0, 2, 70), label = "Celestial Rift Void Portal" },
	["MarketCenter"] = { pos = Vector3.new(0, 2, 0), label = "Grand Central Plaza (Hollow Crown)" },
}

function NavigationController.Init()
	local theme = UIComponents.Theme
	local mainGui = UIComponents.GetMainGui()

	-- 1. Create Workspace Navigation Folder
	local existingFolder = Workspace:FindFirstChild("RelicRushNavigation")
	if existingFolder then
		existingFolder:Destroy()
	end

	navFolder = Instance.new("Folder")
	navFolder.Name = "RelicRushNavigation"
	navFolder.Parent = Workspace

	-- 2. Create 3D Beacon Anchor & Physical Marker
	beaconAnchor = Instance.new("Part")
	beaconAnchor.Name = "NavBeaconAnchor"
	beaconAnchor.Size = Vector3.new(1.2, 1.2, 1.2)
	beaconAnchor.Shape = Enum.PartType.Ball
	beaconAnchor.Color = theme.AccentGold
	beaconAnchor.Material = Enum.Material.Neon
	beaconAnchor.Anchored = true
	beaconAnchor.CanCollide = false
	beaconAnchor.CanTouch = false
	beaconAnchor.CanQuery = false
	beaconAnchor.Transparency = 0.1
	beaconAnchor.Parent = navFolder

	-- Vertical Beacon Light Shaft
	beaconBeam = Instance.new("Part")
	beaconBeam.Name = "NavBeaconBeam"
	beaconBeam.Size = Vector3.new(0.4, 28, 0.4)
	beaconBeam.Color = theme.AccentGold
	beaconBeam.Material = Enum.Material.Neon
	beaconBeam.Anchored = true
	beaconBeam.CanCollide = false
	beaconBeam.CanTouch = false
	beaconBeam.CanQuery = false
	beaconBeam.Transparency = 0.5
	beaconBeam.Parent = navFolder

	-- Circular Pulsing Ground Rune
	groundRune = Instance.new("Part")
	groundRune.Name = "NavGroundRune"
	groundRune.Size = Vector3.new(7.0, 0.2, 7.0)
	groundRune.Shape = Enum.PartType.Cylinder
	groundRune.Color = theme.AccentGold
	groundRune.Material = Enum.Material.Neon
	groundRune.Anchored = true
	groundRune.CanCollide = false
	groundRune.CanTouch = false
	groundRune.CanQuery = false
	groundRune.Transparency = 0.4
	groundRune.Parent = navFolder

	-- PointLight on Beacon
	local pLight = Instance.new("PointLight")
	pLight.Color = theme.AccentGold
	pLight.Brightness = 2.5
	pLight.Range = 20
	pLight.Parent = beaconAnchor

	-- 3D Floating BillboardGui
	billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "NavBillboard"
	billboardGui.Size = UDim2.new(0, 180, 0, 60)
	billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.MaxDistance = 1500
	billboardGui.Adornee = beaconAnchor
	billboardGui.Parent = navFolder

	local bbContainer = Instance.new("Frame")
	bbContainer.Size = UDim2.new(1, 0, 1, 0)
	bbContainer.BackgroundTransparency = 1
	bbContainer.Parent = billboardGui

	local bbIcon = Instance.new("TextLabel")
	bbIcon.Size = UDim2.new(1, 0, 0, 20)
	bbIcon.Position = UDim2.new(0, 0, 0, 0)
	bbIcon.BackgroundTransparency = 1
	bbIcon.Text = "▼"
	bbIcon.TextColor3 = theme.AccentGold
	bbIcon.TextSize = 18
	bbIcon.Font = Enum.Font.GothamBold
	bbIcon.Parent = bbContainer

	billboardLabel = Instance.new("TextLabel")
	billboardLabel.Size = UDim2.new(1, 0, 0, 18)
	billboardLabel.Position = UDim2.new(0, 0, 0, 20)
	billboardLabel.BackgroundTransparency = 0.3
	billboardLabel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	billboardLabel.TextColor3 = theme.TextPrimary
	billboardLabel.TextSize = 12
	billboardLabel.Font = Enum.Font.GothamBold
	billboardLabel.Text = "Objective"
	billboardLabel.Parent = bbContainer

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.AccentGold
	stroke.Thickness = 1
	stroke.Parent = billboardLabel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = billboardLabel

	billboardDist = Instance.new("TextLabel")
	billboardDist.Size = UDim2.new(1, 0, 0, 16)
	billboardDist.Position = UDim2.new(0, 0, 0, 40)
	billboardDist.BackgroundTransparency = 1
	billboardDist.TextColor3 = theme.AccentGold
	billboardDist.TextSize = 11
	billboardDist.Font = Enum.Font.GothamMedium
	billboardDist.Text = "0m"
	billboardDist.Parent = bbContainer

	-- 3. Screen-Space HUD Compass Bar (Top-Center, sleek RPG design)
	compassFrame = UIComponents.CreateRoundedFrame(
		mainGui,
		UDim2.new(0, 280, 0, 36),
		UDim2.new(0.5, -140, 0, 12),
		Color3.fromRGB(20, 22, 30),
		6
	)
	compassFrame.Name = "NavCompassHUD"
	compassFrame.Visible = false
	compassFrame.BackgroundTransparency = 0.2

	local cStroke = compassFrame:FindFirstChildOfClass("UIStroke")
	if cStroke then
		cStroke.Color = theme.BorderGold
		cStroke.Thickness = 1.2
	end

	compassArrow = UIComponents.CreateLabel(
		compassFrame,
		"▲",
		UDim2.new(0, 28, 1, 0),
		UDim2.new(0, 6, 0, 0),
		16,
		theme.AccentGold,
		Enum.TextXAlignment.Center
	)
	compassArrow.Font = Enum.Font.GothamBold

	compassLabel = UIComponents.CreateLabel(
		compassFrame,
		"Current Objective",
		UDim2.new(1, -95, 0, 18),
		UDim2.new(0, 34, 0, 2),
		11,
		theme.TextPrimary
	)
	compassLabel.Font = Enum.Font.GothamBold

	compassDistance = UIComponents.CreateLabel(
		compassFrame,
		"0m",
		UDim2.new(0, 55, 1, 0),
		UDim2.new(1, -60, 0, 0),
		11,
		theme.AccentGold,
		Enum.TextXAlignment.Right
	)
	compassDistance.Font = Enum.Font.GothamMedium

	-- Target Object Highlight
	targetHighlight = Instance.new("Highlight")
	targetHighlight.Name = "NavTargetHighlight"
	targetHighlight.FillColor = theme.AccentGold
	targetHighlight.FillTransparency = 0.75
	targetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	targetHighlight.OutlineTransparency = 0.25
	targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	targetHighlight.Enabled = false
	targetHighlight.Parent = navFolder

	-- Ground Breadcrumb Trail Dots (Directional guidance pathway)
	breadcrumbDots = {}
	local breadcrumbsFolder = Instance.new("Folder")
	breadcrumbsFolder.Name = "NavBreadcrumbs"
	breadcrumbsFolder.Parent = navFolder
	for i = 1, 7 do
		local dot = Instance.new("Part")
		dot.Name = "NavDot_" .. i
		dot.Size = Vector3.new(1.4, 0.1, 1.4)
		dot.Shape = Enum.PartType.Cylinder
		dot.Color = theme.AccentGold
		dot.Material = Enum.Material.Neon
		dot.Anchored = true
		dot.CanCollide = false
		dot.CanTouch = false
		dot.CanQuery = false
		dot.Transparency = 1
		dot.Parent = breadcrumbsFolder
		table.insert(breadcrumbDots, dot)
	end

	-- Hide initially until target set
	NavigationController.SetVisible(false)

	-- 4. Start RenderStepped Compass & Marker Update Loop
	renderConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
		if not currentTargetPos or not compassFrame or not compassFrame.Visible then
			return
		end

		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end

		-- Dynamic Instance Position Tracking (follows moving target or detects removal)
		if currentTargetInstance then
			if currentTargetInstance.Parent then
				local livePos: Vector3? = nil
				if currentTargetInstance:IsA("Model") then
					livePos = currentTargetInstance:GetPivot().Position
				elseif currentTargetInstance:IsA("BasePart") then
					livePos = currentTargetInstance.Position
				end

				if livePos and (livePos - (currentTargetPos :: Vector3)).Magnitude > 0.5 then
					currentTargetPos = livePos
					if beaconAnchor then beaconAnchor.CFrame = CFrame.new(livePos + Vector3.new(0, 6.5, 0)) end
					if beaconBeam then beaconBeam.CFrame = CFrame.new(livePos + Vector3.new(0, 14, 0)) end
					if groundRune then groundRune.CFrame = CFrame.new(livePos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)) end
				end
			else
				currentTargetInstance = nil
			end
		end

		local myPos = hrp.Position
		local targetPos = currentTargetPos :: Vector3
		local diff = targetPos - myPos
		local distStuds = diff.Magnitude
		local distMeters = math.round(distStuds * 0.28) -- 1 stud ≈ 0.28m

		-- Update Distances
		local distStr = string.format("%dm", distMeters)
		if billboardDist then billboardDist.Text = distStr end
		if compassDistance then compassDistance.Text = distStr end

		-- Update Ground Rune Pulsing Animation
		if groundRune and beaconAnchor then
			local pulse = 0.4 + math.sin(os.clock() * 4) * 0.15
			groundRune.Transparency = pulse
			beaconAnchor.Transparency = 0.1 + math.sin(os.clock() * 3) * 0.1
		end

		-- Update Ground Breadcrumbs Pathway
		local showBreadcrumbs = distStuds > 8 and distStuds < 450
		for i, dot in ipairs(breadcrumbDots) do
			if showBreadcrumbs then
				local alpha = i / 8
				local p = myPos:Lerp(targetPos, alpha)
				dot.CFrame = CFrame.new(p.X, myPos.Y - 1.2, p.Z) * CFrame.Angles(0, 0, math.rad(90))
				dot.Transparency = 0.35 + math.sin(os.clock() * 4 + i) * 0.15
			else
				dot.Transparency = 1
			end
		end

		-- Screen Direction Arrow & Proximity Guidance
		local camera = Workspace.CurrentCamera
		if camera and compassArrow then
			local camCFrame = camera.CFrame
			local lookVec = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
			local rightVec = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit
			local toTargetFlat = Vector3.new(diff.X, 0, diff.Z).Unit

			local forwardDot = lookVec:Dot(toTargetFlat)
			local rightDot = rightVec:Dot(toTargetFlat)

			if distStuds <= 8 then
				compassArrow.Text = "★"
				compassArrow.TextColor3 = Color3.fromRGB(76, 175, 80)
				if compassLabel then
					compassLabel.Text = currentTargetLabel .. " (Interact Nearby)"
				end
				if not hasPlayedArrivalChime then
					hasPlayedArrivalChime = true
					SoundEffects.PlayArrivalPing()
				end
			else
				hasPlayedArrivalChime = false
				if compassLabel then
					compassLabel.Text = currentTargetLabel
				end
				if forwardDot > 0.707 then
					compassArrow.Text = "▲"
					compassArrow.TextColor3 = theme.AccentGold
				elseif forwardDot < -0.707 then
					compassArrow.Text = "▼"
					compassArrow.TextColor3 = theme.AccentGold
				elseif rightDot > 0 then
					compassArrow.Text = "►"
					compassArrow.TextColor3 = theme.AccentGold
				else
					compassArrow.Text = "◄"
					compassArrow.TextColor3 = theme.AccentGold
				end
			end
		end
	end)

	print("[NavigationController] Physical waypoint and compass system initialized.")
end

function NavigationController.SetVisible(visible: boolean)
	if compassFrame then compassFrame.Visible = visible end
	if beaconAnchor then beaconAnchor.Transparency = if visible then 0.1 else 1 end
	if beaconBeam then beaconBeam.Transparency = if visible then 0.5 else 1 end
	if groundRune then groundRune.Transparency = if visible then 0.4 else 1 end
	if billboardGui then billboardGui.Enabled = visible end
	if targetHighlight then targetHighlight.Enabled = visible and currentTargetInstance ~= nil end
	for _, dot in ipairs(breadcrumbDots) do
		dot.Transparency = 1
	end
end

function NavigationController.SetTarget(position: Vector3, label: string, targetInstance: Instance?)
	currentTargetPos = position
	currentTargetLabel = label
	currentTargetInstance = targetInstance

	if not navFolder then
		NavigationController.Init()
	end

	-- Position 3D Beacon
	if beaconAnchor then
		beaconAnchor.CFrame = CFrame.new(position + Vector3.new(0, 6.5, 0))
	end
	if beaconBeam then
		beaconBeam.CFrame = CFrame.new(position + Vector3.new(0, 14, 0))
	end
	if groundRune then
		groundRune.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end

	-- Update Text
	if billboardLabel then billboardLabel.Text = label end
	if compassLabel then compassLabel.Text = label end

	-- Update Highlight
	if targetHighlight then
		if targetInstance then
			targetHighlight.Adornee = targetInstance
			targetHighlight.Enabled = true
		else
			targetHighlight.Adornee = nil
			targetHighlight.Enabled = false
		end
	end

	NavigationController.SetVisible(true)
end

function NavigationController.ClearTarget()
	currentTargetPos = nil
	currentTargetLabel = ""
	currentTargetInstance = nil
	NavigationController.SetVisible(false)
end

function NavigationController.GetTarget(): (Vector3?, string?)
	return currentTargetPos, currentTargetLabel
end

-- Sets target by canonical name or finds dynamic world instances
function NavigationController.SetTargetByName(name: string): boolean
	-- 1. Check Canonical List
	local entry = CANONICAL_LOCATIONS[name]
	if entry then
		-- Search for actual model in Workspace for highlighting
		local foundInstance: Instance? = nil
		local market = Workspace:FindFirstChild("ForgottenMarket")
		if market then
			if name == "ElderCorvus" then
				foundInstance = market:FindFirstChild("NPC_ElderCorvus")
			elseif name == "BrimstoneBob" then
				foundInstance = market:FindFirstChild("NPC_BrimstoneBob")
			elseif name == "AntiquarianValeria" then
				foundInstance = market:FindFirstChild("NPC_AntiquarianValeria")
			elseif name == "AlchemistIgnis" then
				foundInstance = market:FindFirstChild("NPC_AlchemistIgnis")
			elseif name == "TorvaldBlacksmith" then
				foundInstance = market:FindFirstChild("NPC_TorvaldBlacksmith")
			elseif name == "VanceShadow" then
				foundInstance = market:FindFirstChild("NPC_VanceShadow")
			end
		end

		NavigationController.SetTarget(entry.pos, entry.label, foundInstance)
		return true
	end

	-- 2. Dynamic Targets
	if name == "MyBase" or name == "MyPlinth" or name == "MyCoffer" then
		-- Find assigned base plot
		local char = player.Character
		local myUserId = player.UserId
		local baseDistrict = Workspace:FindFirstChild("BaseDistrict") or (Workspace:FindFirstChild("ForgottenMarket") and Workspace.ForgottenMarket:FindFirstChild("BaseDistrict"))
		
		local targetPlot: Folder? = nil
		if baseDistrict then
			for _, child in ipairs(baseDistrict:GetChildren()) do
				if child:IsA("Folder") and child.Name:sub(1, 9) == "BasePlot_" then
					local sign = child:FindFirstChild("PlotSignPost")
					if sign then
						local bb = sign:FindFirstChild("PlotBillboard") :: BillboardGui?
						local lbl = bb and bb:FindFirstChildOfClass("TextLabel")
						if lbl and lbl.Text:find(player.Name) then
							targetPlot = child
							break
						end
					end
				end
			end
		end

		if targetPlot then
			if name == "MyPlinth" then
				local plinths = targetPlot:FindFirstChild("RelicPlinthsFolder")
				local p1 = plinths and plinths:FindFirstChild("Plinth_1")
				if p1 and p1:IsA("BasePart") then
					NavigationController.SetTarget(p1.Position, "Your Relic Plinth", p1)
					return true
				end
			elseif name == "MyCoffer" then
				local coffer = targetPlot:FindFirstChild("VaultCoffer")
				local basePart = coffer and coffer:FindFirstChildWhichIsA("BasePart")
				if basePart then
					NavigationController.SetTarget(basePart.Position, "Your Sanctum Coffer", coffer)
					return true
				end
			end

			-- Default to plot center
			local floor = targetPlot:FindFirstChild("PlotFloor") :: BasePart?
			local pos = if floor then floor.Position else Vector3.new(80, 2, -72)
			NavigationController.SetTarget(pos, "Your Sanctum Plot", targetPlot)
			return true
		else
			-- Fallback to Base District Bridge
			NavigationController.SetTarget(Vector3.new(80, 2, 0), "Base District", nil)
			return true
		end

	elseif name == "ExcavationNode" then
		-- Locate nearest active dynamic relic node in workspace
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local myPos = if hrp then hrp.Position else Vector3.new(0, 0, 0)

		local nearestNode: Model? = nil
		local nearestDist = math.huge

		local wilds = Workspace:FindFirstChild("WhisperingWilds") or Workspace
		for _, desc in ipairs(wilds:GetDescendants()) do
			if desc:IsA("Model") and (desc.Name:find("RelicNode") or desc.Name:find("Node_")) then
				local primary = desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart")
				if primary then
					local d = (primary.Position - myPos).Magnitude
					if d < nearestDist then
						nearestDist = d
						nearestNode = desc
					end
				end
			end
		end

		if nearestNode then
			local primary = nearestNode.PrimaryPart or nearestNode:FindFirstChildWhichIsA("BasePart")
			if primary then
				NavigationController.SetTarget(primary.Position, "Glowing Relic Node", nearestNode)
				return true
			end
		else
			-- Fallback to Forgotten Wilds Dig Site
			NavigationController.SetTarget(Vector3.new(-220, 2, -150), "Forgotten Wilds Dig Site", nil)
			return true
		end
	end

	return false
end

return NavigationController
