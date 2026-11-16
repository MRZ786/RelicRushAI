--!strict
-- MarketBuilder.luau
-- Authoritative world construction for the complete Forgotten Market Hub, Base District, and Regional Gateways
-- Features two-story medieval half-timbered guildhalls, artisan forge, 4-plot player base district,
-- 5-region gateways, and cliffside overlook ruins with lore stele and lootable urns.

local RelicMeshBuilder = require(script.Parent.RelicMeshBuilder)
local EnvironmentProps = require(script.Parent.EnvironmentProps)
local EconomyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))

local MarketBuilder = {}

local function createPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	anchored: boolean?,
	canCollide: boolean?,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	if shape then
		part.Shape = shape
	end
	part.Anchored = if anchored ~= nil then anchored else true
	part.CanCollide = if canCollide ~= nil then canCollide else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createLight(parent: Instance, color: Color3, brightness: number, range: number): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = true
	light.Parent = parent
	return light
end

local function createNPC(
	parent: Instance,
	modelName: string,
	rootCFrame: CFrame,
	titleName: string,
	roleSubtext: string,
	tunicColor: Color3,
	cloakColor: Color3,
	hasStaff: boolean?,
	hasSpectacles: boolean?
): (Model, Part)
	local model = Instance.new("Model")
	model.Name = modelName

	-- Torso
	local torso = createPart(model, "Torso", Vector3.new(2.2, 2.6, 1.4), rootCFrame * CFrame.new(0, 2.3, 0), tunicColor, Enum.Material.SmoothPlastic)
	model.PrimaryPart = torso

	-- Robe / Tunic Skirt
	createPart(model, "RobeSkirt", Vector3.new(2.4, 2.0, 1.6), rootCFrame * CFrame.new(0, 1.0, 0), cloakColor, Enum.Material.Fabric)

	-- Belt with Brass Buckle
	createPart(model, "LeatherBelt", Vector3.new(2.3, 0.4, 1.5), rootCFrame * CFrame.new(0, 1.9, 0), Color3.fromRGB(50, 32, 20), Enum.Material.Fabric)
	createPart(model, "BeltBuckle", Vector3.new(0.6, 0.5, 0.2), rootCFrame * CFrame.new(0, 1.9, 0.8), Color3.fromRGB(220, 180, 50), Enum.Material.Metal)

	-- Arms with Cuffs
	createPart(model, "LeftArm", Vector3.new(0.8, 2.2, 0.8), rootCFrame * CFrame.new(-1.5, 2.2, 0), cloakColor, Enum.Material.Fabric)
	createPart(model, "RightArm", Vector3.new(0.8, 2.2, 0.8), rootCFrame * CFrame.new(1.5, 2.2, 0), cloakColor, Enum.Material.Fabric)

	-- Head & Cowl / Hat
	local head = createPart(model, "Head", Vector3.new(1.4, 1.4, 1.4), rootCFrame * CFrame.new(0, 4.1, 0), Color3.fromRGB(235, 195, 160), Enum.Material.SmoothPlastic)

	if modelName == "NPC_BrimstoneBob" then
		-- Brimstone Bob's Feathered Velvet Beret
		createPart(model, "MerchantCap", Vector3.new(2.3, 0.5, 2.3), rootCFrame * CFrame.new(0, 4.75, 0), Color3.fromRGB(130, 25, 35), Enum.Material.Fabric)
		local feather = createPart(model, "CapFeather", Vector3.new(0.15, 1.3, 0.4), rootCFrame * CFrame.new(0.85, 5.2, 0), Color3.fromRGB(245, 210, 60), Enum.Material.SmoothPlastic)
		feather.CFrame = rootCFrame * CFrame.new(0.85, 5.2, 0) * CFrame.Angles(0, 0, math.rad(-25))
		createPart(model, "CapBrooch", Vector3.new(0.3, 0.35, 0.35), rootCFrame * CFrame.new(0.7, 4.8, 0.8), Color3.fromRGB(230, 185, 50), Enum.Material.Metal, false, false, Enum.PartType.Ball)
		
		-- Jeweler's Monocular Appraisal Loupe over Left Eye
		local loupe = createPart(model, "LoupeTube", Vector3.new(0.35, 0.35, 0.4), rootCFrame * CFrame.new(-0.35, 4.2, 0.8), Color3.fromRGB(225, 180, 50), Enum.Material.Metal, false, false, Enum.PartType.Cylinder)
		loupe.CFrame = rootCFrame * CFrame.new(-0.35, 4.2, 0.8) * CFrame.Angles(0, 0, math.rad(90))
		local lens = createPart(model, "LoupeLens", Vector3.new(0.3, 0.3, 0.1), rootCFrame * CFrame.new(-0.35, 4.2, 1.02), Color3.fromRGB(200, 240, 255), Enum.Material.Glass, false, false, Enum.PartType.Cylinder)
		lens.CFrame = rootCFrame * CFrame.new(-0.35, 4.2, 1.02) * CFrame.Angles(0, 0, math.rad(90))
		lens.Transparency = 0.4

		-- Well-groomed Mustache
		createPart(model, "Mustache", Vector3.new(0.8, 0.2, 0.2), rootCFrame * CFrame.new(0, 3.85, 0.72), Color3.fromRGB(55, 35, 22), Enum.Material.Fabric)

		-- Velvet Doublet Gold Buttons
		for b = 1, 4 do
			createPart(model, "Button" .. b, Vector3.new(0.16, 0.16, 0.16), rootCFrame * CFrame.new(0, 1.8 + b * 0.32, 0.72), Color3.fromRGB(240, 200, 50), Enum.Material.Metal, false, false, Enum.PartType.Ball)
		end

		-- Gold Pocket Watch Chain Draped Across Vest
		local chain = createPart(model, "WatchChain", Vector3.new(1.0, 0.08, 0.1), rootCFrame * CFrame.new(0.3, 2.3, 0.73), Color3.fromRGB(235, 195, 55), Enum.Material.Metal)
		chain.CFrame = rootCFrame * CFrame.new(0.3, 2.3, 0.73) * CFrame.Angles(0, 0, math.rad(-15))

		-- Bulging Leather Coin Purse with Brass Cinch
		createPart(model, "CoinPurse", Vector3.new(0.85, 0.9, 0.7), rootCFrame * CFrame.new(1.3, 1.6, 0.3), Color3.fromRGB(115, 75, 38), Enum.Material.Leather, false, false, Enum.PartType.Ball)
		createPart(model, "PurseCinch", Vector3.new(0.35, 0.25, 0.35), rootCFrame * CFrame.new(1.3, 2.05, 0.3), Color3.fromRGB(220, 180, 50), Enum.Material.Metal)

		-- Gold Signet Rings
		createPart(model, "SignetRingL", Vector3.new(0.35, 0.15, 0.35), rootCFrame * CFrame.new(-1.5, 1.15, 0), Color3.fromRGB(240, 200, 50), Enum.Material.Metal)
		createPart(model, "SignetRingR", Vector3.new(0.35, 0.15, 0.35), rootCFrame * CFrame.new(1.5, 1.15, 0), Color3.fromRGB(240, 200, 50), Enum.Material.Metal)

	elseif modelName == "NPC_ElderCorvus" then
		-- Elder Corvus: Scholarly Cowl with Runic Hem
		createPart(model, "Cowl", Vector3.new(1.9, 1.8, 1.9), rootCFrame * CFrame.new(0, 4.3, -0.1), cloakColor, Enum.Material.Fabric)
		createPart(model, "CowlGoldTrim", Vector3.new(1.95, 0.2, 1.95), rootCFrame * CFrame.new(0, 3.45, -0.1), Color3.fromRGB(225, 185, 55), Enum.Material.Metal)

		-- Flowing Silver/White Sage Beard
		createPart(model, "SageBeard", Vector3.new(1.0, 1.5, 0.45), rootCFrame * CFrame.new(0, 3.45, 0.75), Color3.fromRGB(230, 235, 245), Enum.Material.Fabric)

		-- Mystic Luminous Sage-Green Eyes
		createPart(model, "EyeL", Vector3.new(0.18, 0.14, 0.1), rootCFrame * CFrame.new(-0.35, 4.25, 0.72), Color3.fromRGB(100, 255, 120), Enum.Material.Neon)
		createPart(model, "EyeR", Vector3.new(0.18, 0.14, 0.1), rootCFrame * CFrame.new(0.35, 4.25, 0.72), Color3.fromRGB(100, 255, 120), Enum.Material.Neon)

		-- Gold Runic Shoulder Mantle
		createPart(model, "RunicMantle", Vector3.new(3.2, 0.45, 1.8), rootCFrame * CFrame.new(0, 3.5, 0), Color3.fromRGB(215, 175, 50), Enum.Material.Metal)

		-- Slung Illuminated Grimoire at Left Hip
		local grimoireCF = rootCFrame * CFrame.new(-1.4, 1.8, 0.2) * CFrame.Angles(0, math.rad(25), math.rad(15))
		createPart(model, "GrimoireCover", Vector3.new(0.4, 1.6, 1.2), grimoireCF, Color3.fromRGB(120, 30, 25), Enum.Material.Leather)
		createPart(model, "GrimoirePages", Vector3.new(0.35, 1.45, 1.05), grimoireCF, Color3.fromRGB(240, 230, 200), Enum.Material.Sandstone)
		createPart(model, "GrimoireClasp", Vector3.new(0.45, 0.3, 0.3), grimoireCF * CFrame.new(0, 0, 0.5), Color3.fromRGB(225, 185, 55), Enum.Material.Metal)

		-- Scholar's Stave with Arcane Dragon Prongs & Motes
		local staffPole = createPart(model, "StaffPole", Vector3.new(0.35, 7.8, 0.35), rootCFrame * CFrame.new(2.0, 3.7, 0.8), Color3.fromRGB(65, 40, 22), Enum.Material.Wood)
		-- Dragon Claw Prongs clutching orb
		createPart(model, "Claw1", Vector3.new(0.15, 0.8, 0.15), rootCFrame * CFrame.new(1.8, 7.3, 0.8), Color3.fromRGB(180, 130, 40), Enum.Material.Metal)
		createPart(model, "Claw2", Vector3.new(0.15, 0.8, 0.15), rootCFrame * CFrame.new(2.2, 7.3, 0.8), Color3.fromRGB(180, 130, 40), Enum.Material.Metal)
		createPart(model, "Claw3", Vector3.new(0.15, 0.8, 0.15), rootCFrame * CFrame.new(2.0, 7.3, 0.6), Color3.fromRGB(180, 130, 40), Enum.Material.Metal)
		createPart(model, "Claw4", Vector3.new(0.15, 0.8, 0.15), rootCFrame * CFrame.new(2.0, 7.3, 1.0), Color3.fromRGB(180, 130, 40), Enum.Material.Metal)

		local staffOrb = createPart(model, "StaffOrb", Vector3.new(1.0, 1.0, 1.0), rootCFrame * CFrame.new(2.0, 7.7, 0.8), Color3.fromRGB(76, 175, 80), Enum.Material.Neon, true, false, Enum.PartType.Ball)
		createLight(staffOrb, Color3.fromRGB(76, 175, 80), 2.2, 14)

		local pe = Instance.new("ParticleEmitter")
		pe.Name = "StaffMotes"
		pe.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(129, 199, 132)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(46, 125, 50)),
		})
		pe.Size = NumberSequence.new(0.2, 0.04)
		pe.Lifetime = NumberRange.new(0.8, 1.5)
		pe.Rate = 8
		pe.Speed = NumberRange.new(0.4, 0.9)
		pe.Parent = staffOrb

	elseif modelName == "NPC_VanceShadow" then
		-- Vance: Tactical Assassin Shadow Cowl & Stealth Mask
		createPart(model, "ShadowHood", Vector3.new(2.1, 2.0, 2.1), rootCFrame * CFrame.new(0, 4.35, 0), Color3.fromRGB(24, 24, 28), Enum.Material.Fabric)
		createPart(model, "StealthMask", Vector3.new(1.5, 0.8, 0.75), rootCFrame * CFrame.new(0, 3.8, 0.48), Color3.fromRGB(32, 32, 38), Enum.Material.Fabric)

		-- Piercing Silver Tactical Eyes
		createPart(model, "EyeL", Vector3.new(0.16, 0.12, 0.1), rootCFrame * CFrame.new(-0.35, 4.25, 0.72), Color3.fromRGB(200, 230, 255), Enum.Material.Neon)
		createPart(model, "EyeR", Vector3.new(0.16, 0.12, 0.1), rootCFrame * CFrame.new(0.35, 4.25, 0.72), Color3.fromRGB(200, 230, 255), Enum.Material.Neon)

		-- Reinforced Dark Leather Brigandine Chest Plate
		createPart(model, "BrigandineChest", Vector3.new(2.3, 1.9, 0.55), rootCFrame * CFrame.new(0, 2.5, 0.5), Color3.fromRGB(30, 32, 38), Enum.Material.Metal)

		-- Diagonal Leather Bandolier Harness
		local bandolier = createPart(model, "Bandolier", Vector3.new(2.4, 0.35, 1.6), rootCFrame * CFrame.new(0, 2.4, 0), Color3.fromRGB(55, 38, 25), Enum.Material.Fabric)
		bandolier.CFrame = rootCFrame * CFrame.new(0, 2.4, 0) * CFrame.Angles(0, 0, math.rad(28))

		-- 3 Sheathed Silver Throwing Daggers on Chest Bandolier
		for d = 1, 3 do
			local daggerCF = rootCFrame * CFrame.new(-0.5 + d * 0.35, 2.1 + d * 0.25, 0.85) * CFrame.Angles(0, 0, math.rad(28))
			createPart(model, "DaggerBlade_" .. d, Vector3.new(0.12, 0.55, 0.15), daggerCF, Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
			createPart(model, "DaggerHilt_" .. d, Vector3.new(0.16, 0.22, 0.16), daggerCF * CFrame.new(0, 0.35, 0), Color3.fromRGB(30, 30, 35), Enum.Material.Fabric)
		end

		-- Reinforced Metal Vambraces on Forearms
		createPart(model, "VambraceL", Vector3.new(0.9, 1.1, 0.9), rootCFrame * CFrame.new(-1.5, 1.7, 0), Color3.fromRGB(48, 52, 60), Enum.Material.Metal)
		createPart(model, "VambraceR", Vector3.new(0.9, 1.1, 0.9), rootCFrame * CFrame.new(1.5, 1.7, 0), Color3.fromRGB(48, 52, 60), Enum.Material.Metal)

		-- Tactical Utility Belt with Lockpick Pouch & Coiled Grappling Hook
		createPart(model, "LockpickPouch", Vector3.new(0.5, 0.7, 0.7), rootCFrame * CFrame.new(-1.3, 1.8, 0.2), Color3.fromRGB(45, 30, 20), Enum.Material.Fabric)
		local grapple = createPart(model, "GrappleCoil", Vector3.new(0.4, 0.8, 0.8), rootCFrame * CFrame.new(1.3, 1.8, 0.2), Color3.fromRGB(75, 70, 60), Enum.Material.Fabric, false, false, Enum.PartType.Cylinder)
		grapple.CFrame = rootCFrame * CFrame.new(1.3, 1.8, 0.2) * CFrame.Angles(math.rad(90), 0, 0)

	else
		-- Default Cowl & Accessories
		createPart(model, "Cowl", Vector3.new(1.9, 1.8, 1.9), rootCFrame * CFrame.new(0, 4.3, -0.1), cloakColor, Enum.Material.Fabric)

		if hasSpectacles then
			createPart(model, "SpecBridge", Vector3.new(0.6, 0.1, 0.1), rootCFrame * CFrame.new(0, 4.2, 0.75), Color3.fromRGB(220, 180, 50), Enum.Material.Metal)
			createPart(model, "SpecLensL", Vector3.new(0.4, 0.4, 0.1), rootCFrame * CFrame.new(-0.35, 4.2, 0.75), Color3.fromRGB(200, 240, 255), Enum.Material.Glass)
			createPart(model, "SpecLensR", Vector3.new(0.4, 0.4, 0.1), rootCFrame * CFrame.new(0.35, 4.2, 0.75), Color3.fromRGB(200, 240, 255), Enum.Material.Glass)
		end

		if hasStaff then
			createPart(model, "StaffPole", Vector3.new(0.3, 7.5, 0.3), rootCFrame * CFrame.new(2.0, 3.5, 0.8), Color3.fromRGB(75, 45, 25), Enum.Material.Wood)
			local staffOrb = createPart(model, "StaffOrb", Vector3.new(0.9, 0.9, 0.9), rootCFrame * CFrame.new(2.0, 7.4, 0.8), Color3.fromRGB(76, 175, 80), Enum.Material.Neon, true, false, Enum.PartType.Ball)
			createLight(staffOrb, Color3.fromRGB(76, 175, 80), 1.8, 12)
		end
	end

	-- Overhead Title Billboard
	local bb = Instance.new("BillboardGui")
	bb.Name = "Nameplate"
	bb.Size = UDim2.new(0, 190, 0, 46)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 65
	bb.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = titleName
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.TextStrokeColor3 = Color3.fromRGB(20, 20, 25)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = bb

	local roleLabel = Instance.new("TextLabel")
	roleLabel.Size = UDim2.new(1, 0, 0, 18)
	roleLabel.Position = UDim2.new(0, 0, 0, 22)
	roleLabel.BackgroundTransparency = 1
	roleLabel.Text = "[" .. roleSubtext .. "]"
	roleLabel.TextColor3 = cloakColor
	roleLabel.Font = Enum.Font.GothamMedium
	roleLabel.TextSize = 12
	roleLabel.TextStrokeColor3 = Color3.fromRGB(10, 10, 15)
	roleLabel.TextStrokeTransparency = 0.3
	roleLabel.Parent = bb

	model.Parent = parent
	return model, torso
end

function MarketBuilder.Build(worldFolder: Folder): Folder
	local marketFolder = Instance.new("Folder")
	marketFolder.Name = "ForgottenMarket"
	marketFolder.Parent = worldFolder

	----------------------------------------------------------------------
	-- 1. CONCENTRIC MULTI-TIER RADIAL PLAZA PAVING
	----------------------------------------------------------------------
	-- Base Bedrock & Cobblestone Foundation
	createPart(marketFolder, "PlazaBedrock", Vector3.new(170, 4, 170), CFrame.new(0, -2, 0), Color3.fromRGB(52, 52, 56), Enum.Material.Basalt)
	createPart(marketFolder, "PlazaPavingLower", Vector3.new(154, 1, 154), CFrame.new(0, 0.4, 0), Color3.fromRGB(72, 70, 75), Enum.Material.Cobblestone)

	-- Concentric Slate & Marble Radial Inlay Rings
	local outerRing = createPart(marketFolder, "RingCobbleOuter", Vector3.new(1.0, 78, 78), CFrame.new(0, 0.5, 0), Color3.fromRGB(60, 58, 62), Enum.Material.Cobblestone, true, true, Enum.PartType.Cylinder)
	outerRing.CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))

	local midRing = createPart(marketFolder, "RingMarbleMid", Vector3.new(1.05, 54, 54), CFrame.new(0, 0.55, 0), Color3.fromRGB(175, 170, 160), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	midRing.CFrame = CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90))

	local innerRing = createPart(marketFolder, "RingSlateInner", Vector3.new(1.1, 36, 36), CFrame.new(0, 0.6, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Slate, true, true, Enum.PartType.Cylinder)
	innerRing.CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90))

	-- Radial Paved Pathways with Polished Marble Curbs (North, South, East, West)
	createPart(marketFolder, "AvenueSouth", Vector3.new(18, 0.2, 45), CFrame.new(0, 0.65, 45), Color3.fromRGB(85, 82, 80), Enum.Material.Cobblestone)
	createPart(marketFolder, "AvenueCurbSouthL", Vector3.new(1.2, 0.5, 45), CFrame.new(-9.6, 0.8, 45), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)
	createPart(marketFolder, "AvenueCurbSouthR", Vector3.new(1.2, 0.5, 45), CFrame.new(9.6, 0.8, 45), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)

	createPart(marketFolder, "AvenueNorth", Vector3.new(18, 0.2, 45), CFrame.new(0, 0.65, -45), Color3.fromRGB(85, 82, 80), Enum.Material.Cobblestone)
	createPart(marketFolder, "AvenueCurbNorthL", Vector3.new(1.2, 0.5, 45), CFrame.new(-9.6, 0.8, -45), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)
	createPart(marketFolder, "AvenueCurbNorthR", Vector3.new(1.2, 0.5, 45), CFrame.new(9.6, 0.8, -45), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)

	createPart(marketFolder, "AvenueEast", Vector3.new(45, 0.2, 18), CFrame.new(45, 0.65, 0), Color3.fromRGB(85, 82, 80), Enum.Material.Cobblestone)
	createPart(marketFolder, "AvenueCurbEastN", Vector3.new(45, 0.5, 1.2), CFrame.new(45, 0.8, -9.6), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)
	createPart(marketFolder, "AvenueCurbEastS", Vector3.new(45, 0.5, 1.2), CFrame.new(45, 0.8, 9.6), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)

	createPart(marketFolder, "AvenueWest", Vector3.new(45, 0.2, 18), CFrame.new(-45, 0.65, 0), Color3.fromRGB(85, 82, 80), Enum.Material.Cobblestone)
	createPart(marketFolder, "AvenueCurbWestN", Vector3.new(45, 0.5, 1.2), CFrame.new(-45, 0.8, -9.6), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)
	createPart(marketFolder, "AvenueCurbWestS", Vector3.new(45, 0.5, 1.2), CFrame.new(-45, 0.8, 9.6), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)

	-- Fortified Stone Perimeter Rampart Walls with Crenellations
	local function createStoneRampart(name: string, cframe: CFrame, length: number)
		local wall = createPart(marketFolder, name, Vector3.new(length, 10, 4), cframe, Color3.fromRGB(55, 54, 58), Enum.Material.Slate)
		createPart(marketFolder, name .. "_Cap", Vector3.new(length + 1, 1.4, 5.2), cframe * CFrame.new(0, 5.5, 0), Color3.fromRGB(75, 74, 78), Enum.Material.Cobblestone)
		-- Crenellation battlements
		local battlementCount = math.floor(length / 8)
		for b = 1, battlementCount do
			local bX = -length / 2 + (b - 0.5) * 8
			createPart(marketFolder, name .. "_Battle_" .. tostring(b), Vector3.new(4.5, 3.0, 5.0), cframe * CFrame.new(bX, 7.5, 0), Color3.fromRGB(60, 58, 62), Enum.Material.Slate)
		end
	end

	createStoneRampart("WallWest", CFrame.new(-76, 5, 0) * CFrame.Angles(0, math.rad(90), 0), 154)
	createStoneRampart("WallEastNorth", CFrame.new(76, 5, -46) * CFrame.Angles(0, math.rad(90), 0), 62)
	createStoneRampart("WallEastSouth", CFrame.new(76, 5, 46) * CFrame.Angles(0, math.rad(90), 0), 62)
	createStoneRampart("WallSouthLeft", CFrame.new(-46, 5, 76), 60)
	createStoneRampart("WallSouthRight", CFrame.new(46, 5, 76), 60)

	----------------------------------------------------------------------
	-- 2. GRAND ENTRANCE PORTAL & WATCHTOWERS (South Approach)
	----------------------------------------------------------------------
	-- Twin Hexagonal Watchtowers with Conical Roofs
	local function createWatchtower(name: string, cframe: CFrame)
		createPart(marketFolder, name .. "_Base", Vector3.new(11, 24, 11), cframe * CFrame.new(0, 12, 0), Color3.fromRGB(58, 56, 62), Enum.Material.Slate)
		createPart(marketFolder, name .. "_Cornice", Vector3.new(13, 2, 13), cframe * CFrame.new(0, 24, 0), Color3.fromRGB(75, 72, 78), Enum.Material.Cobblestone)
		-- Conical / Pyramidal Roof
		createPart(marketFolder, name .. "_Roof", Vector3.new(12, 8, 12), cframe * CFrame.new(0, 28, 0), Color3.fromRGB(42, 45, 52), Enum.Material.Slate)
	end

	createWatchtower("TowerL", CFrame.new(-18, 0, 76))
	createWatchtower("TowerR", CFrame.new(18, 0, 76))

	-- Great Stone Gateway Arch & Heavy Portcullis
	createPart(marketFolder, "GateArch", Vector3.new(36, 6, 8), CFrame.new(0, 22, 76), Color3.fromRGB(70, 68, 72), Enum.Material.Cobblestone)
	createPart(marketFolder, "PortcullisIron", Vector3.new(20, 14, 1.2), CFrame.new(0, 13, 76), Color3.fromRGB(35, 38, 42), Enum.Material.Metal)

	-- Guild Banners on entrance towers
	createPart(marketFolder, "BannerLeft", Vector3.new(0.3, 12, 4.0), CFrame.new(-13, 14, 73), Color3.fromRGB(46, 125, 50), Enum.Material.Fabric)
	createPart(marketFolder, "BannerRight", Vector3.new(0.3, 12, 4.0), CFrame.new(13, 14, 73), Color3.fromRGB(215, 120, 30), Enum.Material.Fabric)

	-- Player Spawn Pad (Inside South Gateway)
	local spawnPad = Instance.new("SpawnLocation")
	spawnPad.Name = "MarketSpawn"
	spawnPad.Size = Vector3.new(16, 1, 16)
	spawnPad.CFrame = CFrame.lookAt(Vector3.new(0, 1.1, 52), Vector3.new(0, 1.1, 0))
	spawnPad.Anchored = true
	spawnPad.CanCollide = true
	spawnPad.Material = Enum.Material.Marble
	spawnPad.Color = Color3.fromRGB(110, 110, 115)
	spawnPad.Duration = 0
	spawnPad.Neutral = true
	spawnPad.Enabled = true
	spawnPad.Parent = marketFolder

	local spawnInlay = createPart(marketFolder, "SpawnRuneGlow", Vector3.new(0.2, 12, 12), CFrame.new(0, 1.2, 52), Color3.fromRGB(64, 196, 255), Enum.Material.Neon, true, false, Enum.PartType.Cylinder)
	spawnInlay.CFrame = CFrame.new(0, 1.2, 52) * CFrame.Angles(0, 0, math.rad(90))
	createLight(spawnInlay, Color3.fromRGB(64, 196, 255), 2.0, 16)

	----------------------------------------------------------------------
	-- 3. GRAND CENTRAL PLAZA LANDMARK & HOLLOW CROWN DISPLAY
	----------------------------------------------------------------------
	local monumentOrigin = Vector3.new(0, 1, 0)

	-- Sunken Octagonal Reflecting Pool with Stepped Granite Rims
	local poolBasin = createPart(marketFolder, "PoolBasin", Vector3.new(2.4, 28, 28), CFrame.new(monumentOrigin + Vector3.new(0, 0.8, 0)), Color3.fromRGB(65, 65, 70), Enum.Material.Cobblestone, true, true, Enum.PartType.Cylinder)
	poolBasin.CFrame = CFrame.new(monumentOrigin + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local poolRim = createPart(marketFolder, "PoolRimGranite", Vector3.new(3.0, 25, 25), CFrame.new(monumentOrigin + Vector3.new(0, 1.2, 0)), Color3.fromRGB(140, 135, 130), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	poolRim.CFrame = CFrame.new(monumentOrigin + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Reflective Turquoise Water Surface
	local water = createPart(marketFolder, "PoolWater", Vector3.new(1.0, 22, 22), CFrame.new(monumentOrigin + Vector3.new(0, 1.7, 0)), Color3.fromRGB(0, 180, 215), Enum.Material.Glass, true, false, Enum.PartType.Cylinder)
	water.CFrame = CFrame.new(monumentOrigin + Vector3.new(0, 1.7, 0)) * CFrame.Angles(0, 0, math.rad(90))
	water.Transparency = 0.4
	createLight(water, Color3.fromRGB(0, 190, 225), 2.2, 24)

	-- Central Obsidian Relic Pedestal with Gold Foliate Mounts
	createPart(marketFolder, "PedestalBase", Vector3.new(6.0, 4.5, 6.0), CFrame.new(monumentOrigin + Vector3.new(0, 3.8, 0)), Color3.fromRGB(24, 22, 28), Enum.Material.Marble)
	createPart(marketFolder, "PedestalGoldRim", Vector3.new(6.8, 0.8, 6.8), CFrame.new(monumentOrigin + Vector3.new(0, 6.4, 0)), Color3.fromRGB(235, 195, 50), Enum.Material.Metal)

	-- Showcase Display: The Fabled Hollow Crown
	RelicMeshBuilder.CreateHollowCrown(marketFolder, CFrame.new(monumentOrigin + Vector3.new(0, 7.8, 0)))

	-- 4 Monumental Carved Obelisks at Cardinal Angles
	local obeliskOffsets = {
		Vector3.new(-14, 0, -14), Vector3.new(14, 0, -14),
		Vector3.new(-14, 0, 14), Vector3.new(14, 0, 14),
	}
	for i, off in ipairs(obeliskOffsets) do
		local obBase = createPart(marketFolder, "Obelisk_" .. tostring(i), Vector3.new(2.8, 14.0, 2.8), CFrame.new(monumentOrigin + off + Vector3.new(0, 7.0, 0)), Color3.fromRGB(48, 48, 54), Enum.Material.Slate)
		createPart(marketFolder, "ObeliskGoldCollar_" .. tostring(i), Vector3.new(3.2, 0.8, 3.2), CFrame.new(monumentOrigin + off + Vector3.new(0, 12.0, 0)), Color3.fromRGB(225, 180, 50), Enum.Material.Metal)
		-- Floating Blue Fire Brazier
		local fire = createPart(marketFolder, "BrazierFlame_" .. tostring(i), Vector3.new(1.3, 1.3, 1.3), CFrame.new(monumentOrigin + off + Vector3.new(0, 14.8, 0)), Color3.fromRGB(64, 196, 255), Enum.Material.Neon, true, false, Enum.PartType.Ball)
		createLight(fire, Color3.fromRGB(64, 196, 255), 2.2, 14)
	end

	-- Carved Stone Plaza Seating Benches
	EnvironmentProps.CreatePlazaStoneBench(marketFolder, CFrame.new(monumentOrigin + Vector3.new(0, 0, 18)))
	EnvironmentProps.CreatePlazaStoneBench(marketFolder, CFrame.new(monumentOrigin + Vector3.new(0, 0, -18)) * CFrame.Angles(0, math.rad(180), 0))
	EnvironmentProps.CreatePlazaStoneBench(marketFolder, CFrame.new(monumentOrigin + Vector3.new(18, 0, 0)) * CFrame.Angles(0, math.rad(-90), 0))
	EnvironmentProps.CreatePlazaStoneBench(marketFolder, CFrame.new(monumentOrigin + Vector3.new(-18, 0, 0)) * CFrame.Angles(0, math.rad(90), 0))

	-- Carved Granite Planters with Bioluminescent Flora
	local planterOffsets = {
		Vector3.new(-22, 0, -22), Vector3.new(22, 0, -22),
		Vector3.new(-22, 0, 22), Vector3.new(22, 0, 22),
	}
	for _, pOff in ipairs(planterOffsets) do
		EnvironmentProps.CreateStonePlanter(marketFolder, CFrame.new(monumentOrigin + pOff))
	end

	-- Monumental Heroic Statues flanking avenues
	EnvironmentProps.CreateHeroicStatue(marketFolder, CFrame.new(-14, 0.8, 38), false) -- South Avenue Guardian Knight
	EnvironmentProps.CreateHeroicStatue(marketFolder, CFrame.new(14, 0.8, 38) * CFrame.Angles(0, math.rad(180), 0), false)
	EnvironmentProps.CreateHeroicStatue(marketFolder, CFrame.new(-14, 0.8, -42), true) -- North Gateway Scholar Sage
	EnvironmentProps.CreateHeroicStatue(marketFolder, CFrame.new(14, 0.8, -42) * CFrame.Angles(0, math.rad(180), 0), true)

	-- Ancient Bioluminescent Wispwood Trees framing the settlement
	EnvironmentProps.CreateWispwoodTree(marketFolder, CFrame.new(-32, 0.8, -4), Color3.fromRGB(64, 196, 255))
	EnvironmentProps.CreateWispwoodTree(marketFolder, CFrame.new(32, 0.8, -4), Color3.fromRGB(64, 196, 255))
	EnvironmentProps.CreateWispwoodTree(marketFolder, CFrame.new(-4, 0.8, 30), Color3.fromRGB(76, 175, 80))
	EnvironmentProps.CreateWispwoodTree(marketFolder, CFrame.new(-4, 0.8, -52), Color3.fromRGB(156, 39, 176))

	-- Vibrant Artisan Market Stalls along Thoroughfares
	EnvironmentProps.CreateMarketStall(marketFolder, CFrame.new(24, 0.8, 14) * CFrame.Angles(0, math.rad(-90), 0), "Textiles")
	EnvironmentProps.CreateMarketStall(marketFolder, CFrame.new(24, 0.8, -14) * CFrame.Angles(0, math.rad(-90), 0), "Spices")
	EnvironmentProps.CreateMarketStall(marketFolder, CFrame.new(-24, 0.8, 14) * CFrame.Angles(0, math.rad(90), 0), "Pottery")
	EnvironmentProps.CreateMarketStall(marketFolder, CFrame.new(-24, 0.8, -14) * CFrame.Angles(0, math.rad(90), 0), "Salvage")
	EnvironmentProps.CreateMarketStall(marketFolder, CFrame.new(14, 0.8, 28) * CFrame.Angles(0, 0, 0), "Elixirs")
	EnvironmentProps.CreateMarketStall(marketFolder, CFrame.new(-14, 0.8, 28) * CFrame.Angles(0, 0, 0), "Runesmith")

	----------------------------------------------------------------------
	-- 4. BRIMSTONE BOB'S ANTIQUITIES GUILDHALL (North-East Building)
	----------------------------------------------------------------------
	local bobOrigin = Vector3.new(42, 1, -26)

	-- Polished Oak Plank Interior Floor
	createPart(marketFolder, "BobGuildFloor", Vector3.new(22, 0.8, 20), CFrame.new(bobOrigin + Vector3.new(0, 0.4, 0)), Color3.fromRGB(75, 48, 28), Enum.Material.WoodPlanks)

	-- Half-Timbered Walls (Fully Enclosed Structure with Front Arched Doorway)
	EnvironmentProps.CreateTimberWall(marketFolder, 22, 12, CFrame.new(bobOrigin + Vector3.new(0, 0, -10)), false, false) -- Back Wall
	EnvironmentProps.CreateTimberWall(marketFolder, 20, 12, CFrame.new(bobOrigin + Vector3.new(-11, 0, 0)) * CFrame.Angles(0, math.rad(90), 0), true, false) -- Side Wall Left (Windowed)
	EnvironmentProps.CreateTimberWall(marketFolder, 20, 12, CFrame.new(bobOrigin + Vector3.new(11, 0, 0)) * CFrame.Angles(0, math.rad(90), 0), true, false) -- Side Wall Right (Windowed)
	EnvironmentProps.CreateTimberWall(marketFolder, 22, 12, CFrame.new(bobOrigin + Vector3.new(0, 0, 10)), false, true) -- Front Facade with Arched Entrance Doorway

	-- Pitched Slate Roof with Overhanging Eaves and Bargeboards
	EnvironmentProps.CreatePitchedRoof(marketFolder, 24, 22, CFrame.new(bobOrigin + Vector3.new(0, 12, 0)), 32, Color3.fromRGB(45, 48, 55))

	-- Handcrafted Merchant Counter with Scales, Coins, Ledger, and Gems
	EnvironmentProps.CreateDetailedMerchantCounter(marketFolder, CFrame.new(bobOrigin + Vector3.new(0, 0, -2)))

	-- Curio Display Shelving with Books, Relics & Glowing Phials on Back Wall
	EnvironmentProps.CreateCurioShelving(marketFolder, CFrame.new(bobOrigin + Vector3.new(0, 0, -8.6)))

	-- Open Ironbound Treasure Chest overflowing with Gold
	EnvironmentProps.CreateIronboundChest(marketFolder, CFrame.new(bobOrigin + Vector3.new(7.5, 0, -2.5)), true)

	-- Entrance Fabric Awning with Scalloped Valance
	local awningCF = CFrame.new(bobOrigin + Vector3.new(0, 7.0, 12.0)) * CFrame.Angles(math.rad(20), 0, 0)
	createPart(marketFolder, "AwningCloth", Vector3.new(18.0, 0.3, 5.0), awningCF, Color3.fromRGB(180, 50, 45), Enum.Material.Fabric)
	createPart(marketFolder, "AwningValance", Vector3.new(18.0, 0.8, 0.3), CFrame.new(bobOrigin + Vector3.new(0, 5.7, 14.3)), Color3.fromRGB(240, 200, 70), Enum.Material.Fabric)

	-- Hanging Tavern Guild Sign
	local signPost = createPart(marketFolder, "GuildSignBracket", Vector3.new(0.3, 0.3, 3.5), CFrame.new(bobOrigin + Vector3.new(-11.5, 10, 8)), Color3.fromRGB(45, 45, 50), Enum.Material.Metal)
	local guildSign = createPart(marketFolder, "GuildSignWood", Vector3.new(0.2, 2.5, 3.0), CFrame.new(bobOrigin + Vector3.new(-11.5, 8.2, 8)), Color3.fromRGB(75, 45, 25), Enum.Material.WoodPlanks)
	createPart(marketFolder, "SignGoldTrim", Vector3.new(0.25, 2.7, 3.2), CFrame.new(bobOrigin + Vector3.new(-11.5, 8.2, 8)), Color3.fromRGB(220, 175, 50), Enum.Material.Metal)

	-- Brimstone Bob NPC
	local _, bobTorso = createNPC(
		marketFolder,
		"NPC_BrimstoneBob",
		CFrame.new(bobOrigin + Vector3.new(0, 1.5, -5.5)),
		"Brimstone Bob",
		"Master Appraiser & Merchant",
		Color3.fromRGB(115, 68, 38),
		Color3.fromRGB(180, 85, 30),
		false,
		true
	)

	local merchantPrompt = Instance.new("ProximityPrompt")
	merchantPrompt.Name = "Prompt_Merchant"
	merchantPrompt.ObjectText = "Brimstone Bob"
	merchantPrompt.ActionText = "Trade Goods & Appraise Relics"
	merchantPrompt.HoldDuration = 0.5
	merchantPrompt.MaxActivationDistance = 14
	merchantPrompt.RequiresLineOfSight = false
	merchantPrompt.Parent = bobTorso

	----------------------------------------------------------------------
	-- 4B. THE ANTIQUARIAN'S VAULT (Archaeological Repository & Curio Exhibition)
	----------------------------------------------------------------------
	local vaultOrigin = Vector3.new(70, 1, -26)

	-- Polished Flagstone Flooring
	createPart(marketFolder, "VaultFloor", Vector3.new(22, 0.8, 20), CFrame.new(vaultOrigin + Vector3.new(0, 0.4, 0)), Color3.fromRGB(48, 48, 54), Enum.Material.Slate)

	-- Enclosed Half-Timbered Walls with Display Glazing
	EnvironmentProps.CreateTimberWall(marketFolder, 22, 12, CFrame.new(vaultOrigin + Vector3.new(0, 0, -10)), false, false) -- Back Wall
	EnvironmentProps.CreateTimberWall(marketFolder, 20, 12, CFrame.new(vaultOrigin + Vector3.new(-11, 0, 0)) * CFrame.Angles(0, math.rad(90), 0), true, false) -- Left Wall
	EnvironmentProps.CreateTimberWall(marketFolder, 20, 12, CFrame.new(vaultOrigin + Vector3.new(11, 0, 0)) * CFrame.Angles(0, math.rad(-90), 0), true, false) -- Right Wall
	EnvironmentProps.CreateTimberWall(marketFolder, 22, 12, CFrame.new(vaultOrigin + Vector3.new(0, 0, 10)), false, true) -- Front Facade with Doorway

	-- Pitched Roof with Verdigris Copper Trim
	EnvironmentProps.CreatePitchedRoof(marketFolder, 24, 22, CFrame.new(vaultOrigin + Vector3.new(0, 12, 0)), 30, Color3.fromRGB(38, 48, 52))

	-- Antiquarian's Rare Relic Display Cabinet (Full glass exhibition)
	EnvironmentProps.CreateAntiquarianDisplayCabinet(marketFolder, CFrame.new(vaultOrigin + Vector3.new(0, 0, -7.5)))

	-- Archaeological Field Excavation Table (Maps, Loupe, Calipers, Fossils)
	EnvironmentProps.CreateExcavationTable(marketFolder, CFrame.new(vaultOrigin + Vector3.new(0, 0, 1.5)))

	-- Vault Exterior Hanging Sign
	createPart(marketFolder, "VaultSignBracket", Vector3.new(0.3, 0.3, 3.5), CFrame.new(vaultOrigin + Vector3.new(-11.5, 9.5, 8)), Color3.fromRGB(45, 45, 50), Enum.Material.Metal)
	createPart(marketFolder, "VaultSignWood", Vector3.new(0.2, 2.4, 3.2), CFrame.new(vaultOrigin + Vector3.new(-11.5, 8.0, 8)), Color3.fromRGB(50, 32, 20), Enum.Material.WoodPlanks)
	createPart(marketFolder, "VaultSignTrim", Vector3.new(0.25, 2.6, 3.4), CFrame.new(vaultOrigin + Vector3.new(-11.5, 8.0, 8)), Color3.fromRGB(225, 180, 50), Enum.Material.Metal)

	-- Antiquarian Valeria NPC (Curator of the Vault)
	local _, valeriaTorso = createNPC(
		marketFolder,
		"NPC_AntiquarianValeria",
		CFrame.new(vaultOrigin + Vector3.new(4.5, 1.5, -4)) * CFrame.Angles(0, math.rad(-45), 0),
		"Valeria the Antiquarian",
		"Curator of Ancient Curios",
		Color3.fromRGB(65, 45, 75),
		Color3.fromRGB(140, 95, 165),
		false,
		true
	)

	local valeriaPrompt = Instance.new("ProximityPrompt")
	valeriaPrompt.Name = "Prompt_Valeria"
	valeriaPrompt.ObjectText = "Valeria the Antiquarian"
	valeriaPrompt.ActionText = "Appraise Curios & Lore"
	valeriaPrompt.HoldDuration = 0.5
	valeriaPrompt.MaxActivationDistance = 14
	valeriaPrompt.RequiresLineOfSight = false
	valeriaPrompt.Parent = valeriaTorso

	----------------------------------------------------------------------
	-- 4C. THE ALCHEMIST'S EMPORIUM (South-East Apothecary Building)
	----------------------------------------------------------------------
	local alchemistOrigin = Vector3.new(42, 1, 32)

	-- Slate Floor
	createPart(marketFolder, "AlchFloor", Vector3.new(20, 0.8, 20), CFrame.new(alchemistOrigin + Vector3.new(0, 0.4, 0)), Color3.fromRGB(50, 52, 56), Enum.Material.Slate)

	-- Half-Timbered Walls (Fully Enclosed 4 Walls)
	EnvironmentProps.CreateTimberWall(marketFolder, 20, 12, CFrame.new(alchemistOrigin + Vector3.new(0, 0, 10)) * CFrame.Angles(0, math.rad(180), 0), false, false) -- Back Wall
	EnvironmentProps.CreateTimberWall(marketFolder, 18, 12, CFrame.new(alchemistOrigin + Vector3.new(10, 0, 0)) * CFrame.Angles(0, math.rad(-90), 0), true, false) -- Right Wall
	EnvironmentProps.CreateTimberWall(marketFolder, 18, 12, CFrame.new(alchemistOrigin + Vector3.new(-10, 0, 0)) * CFrame.Angles(0, math.rad(90), 0), true, false) -- Left Wall
	EnvironmentProps.CreateTimberWall(marketFolder, 20, 12, CFrame.new(alchemistOrigin + Vector3.new(0, 0, -10)), false, true) -- Front Facade with Doorway

	-- Pitched Roof with Dark Forest-Slate Shingles
	EnvironmentProps.CreatePitchedRoof(marketFolder, 22, 22, CFrame.new(alchemistOrigin + Vector3.new(0, 12, 0)), 30, Color3.fromRGB(40, 52, 48))

	-- Alchemist's Workstation with Still, Coils, Flasks & Apothecary Scales
	EnvironmentProps.CreateAlchemistWorkstation(marketFolder, CFrame.new(alchemistOrigin + Vector3.new(0, 0, 3)))

	-- Bubbling Copper Cauldron with Glowing Emerald Brew
	local cauldronCF = CFrame.new(alchemistOrigin + Vector3.new(-5.5, 0.8, -3))
	local cauldron = createPart(marketFolder, "AlchCauldron", Vector3.new(3.0, 2.6, 3.0), cauldronCF * CFrame.new(0, 1.3, 0), Color3.fromRGB(160, 95, 45), Enum.Material.Metal, true, true, Enum.PartType.Ball)
	local brew = createPart(marketFolder, "CauldronBrew", Vector3.new(2.4, 0.3, 2.4), cauldronCF * CFrame.new(0, 2.2, 0), Color3.fromRGB(76, 175, 80), Enum.Material.Neon, false, false, Enum.PartType.Cylinder)
	brew.CFrame = (cauldronCF * CFrame.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	createLight(brew, Color3.fromRGB(76, 175, 80), 2.0, 12)

	-- Hanging Apothecary Mortar Sign
	createPart(marketFolder, "AlchSignBracket", Vector3.new(0.3, 0.3, 3.5), CFrame.new(alchemistOrigin + Vector3.new(-10.5, 9, -8)), Color3.fromRGB(45, 45, 50), Enum.Material.Metal)
	createPart(marketFolder, "AlchSignWood", Vector3.new(0.2, 2.4, 2.8), CFrame.new(alchemistOrigin + Vector3.new(-10.5, 7.5, -8)), Color3.fromRGB(60, 42, 28), Enum.Material.WoodPlanks)
	createPart(marketFolder, "AlchEmblem", Vector3.new(0.3, 1.2, 1.2), CFrame.new(alchemistOrigin + Vector3.new(-10.5, 7.5, -8)), Color3.fromRGB(64, 196, 255), Enum.Material.Neon, true, false, Enum.PartType.Ball)

	-- Alchemist Ignis NPC (Master of Arcane Elixirs)
	local _, ignisTorso = createNPC(
		marketFolder,
		"NPC_AlchemistIgnis",
		CFrame.new(alchemistOrigin + Vector3.new(-2.5, 1.5, -3)) * CFrame.Angles(0, math.rad(-90), 0),
		"Ignis the Alchemist",
		"Master of Arcane Elixirs",
		Color3.fromRGB(45, 65, 55),
		Color3.fromRGB(76, 175, 80),
		false,
		false
	)

	local ignisPrompt = Instance.new("ProximityPrompt")
	ignisPrompt.Name = "Prompt_Ignis"
	ignisPrompt.ObjectText = "Alchemist Ignis"
	ignisPrompt.ActionText = "Brew Shadow Draught (10 Shards)"
	ignisPrompt.HoldDuration = 0.5
	ignisPrompt.MaxActivationDistance = 14
	ignisPrompt.RequiresLineOfSight = false
	ignisPrompt.Parent = ignisTorso

	----------------------------------------------------------------------
	-- 5. ELDER CORVUS'S MARBLE SANCTUARY (North-West Pavilion)
	----------------------------------------------------------------------
	local guideOrigin = Vector3.new(-42, 1, -26)

	-- Hexagonal Marble Dais with Stepped Plinth
	createPart(marketFolder, "DaisTier1", Vector3.new(22, 2.0, 22), CFrame.new(guideOrigin + Vector3.new(0, 1.0, 0)), Color3.fromRGB(75, 72, 70), Enum.Material.Cobblestone)
	createPart(marketFolder, "DaisTier2", Vector3.new(18, 1.2, 18), CFrame.new(guideOrigin + Vector3.new(0, 2.6, 0)), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)

	-- 6 Fluted Classical Columns Supporting Canopy
	local colAngles = { 0, 60, 120, 180, 240, 300 }
	for _, deg in ipairs(colAngles) do
		local rad = math.rad(deg)
		local cX = math.cos(rad) * 7.5
		local cZ = math.sin(rad) * 7.5
		EnvironmentProps.CreateFlutedColumn(marketFolder, 12, 0.75, CFrame.new(guideOrigin + Vector3.new(cX, 3.2, cZ)))
	end

	-- Layered Emerald Fabric Canopy Roof with Gold Trim
	local canopy = createPart(marketFolder, "CanopyRoof", Vector3.new(18, 2.0, 18), CFrame.new(guideOrigin + Vector3.new(0, 15.2, 0)), Color3.fromRGB(35, 95, 45), Enum.Material.Fabric)
	createPart(marketFolder, "CanopyGoldEaves", Vector3.new(19, 0.5, 19), CFrame.new(guideOrigin + Vector3.new(0, 14.4, 0)), Color3.fromRGB(225, 180, 50), Enum.Material.Metal)
	createLight(canopy, Color3.fromRGB(150, 255, 160), 2.0, 18)

	-- Ancient Carved Stone Lectern & Illuminated Grimoire
	local lectern = createPart(marketFolder, "SanctuaryLectern", Vector3.new(2.4, 4.0, 2.0), CFrame.new(guideOrigin + Vector3.new(0, 4.6, -2.5)), Color3.fromRGB(60, 45, 35), Enum.Material.WoodPlanks)
	local tome = createPart(marketFolder, "GrimoireTome", Vector3.new(1.8, 0.4, 1.4), CFrame.new(guideOrigin + Vector3.new(0, 6.7, -2.5)) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(180, 140, 70), Enum.Material.Fabric)

	local _, guideTorso = createNPC(
		marketFolder,
		"NPC_ElderCorvus",
		CFrame.new(guideOrigin + Vector3.new(0, 3.2, 0)),
		"Elder Corvus",
		"Scholar & Relic Seeker",
		Color3.fromRGB(40, 70, 45),
		Color3.fromRGB(46, 125, 50),
		true,
		false
	)

	local guidePrompt = Instance.new("ProximityPrompt")
	guidePrompt.Name = "Prompt_Guide"
	guidePrompt.ObjectText = "Elder Corvus"
	guidePrompt.ActionText = "Seek Guidance & Bond Relic"
	guidePrompt.HoldDuration = 0.5
	guidePrompt.MaxActivationDistance = 14
	guidePrompt.RequiresLineOfSight = false
	guidePrompt.Parent = guideTorso

	----------------------------------------------------------------------
	-- 6. ARTISAN BLACKSMITH WORKSHOP (West Plaza)
	----------------------------------------------------------------------
	local forgeOrigin = Vector3.new(-52, 1, 6)

	-- Heavy Ashlar Stone Back & Side Retaining Walls
	createPart(marketFolder, "SmithyBackWall", Vector3.new(20, 14, 2.4), CFrame.new(forgeOrigin + Vector3.new(0, 7, -6)), Color3.fromRGB(55, 52, 58), Enum.Material.Cobblestone)
	createPart(marketFolder, "SmithySideWallL", Vector3.new(2.4, 8, 14), CFrame.new(forgeOrigin + Vector3.new(-9, 4, 1)), Color3.fromRGB(55, 52, 58), Enum.Material.Cobblestone)

	-- Complete Forge Station (Foundation, Hearth, Hood, Chimney, Anvil, Trough)
	EnvironmentProps.CreateArtisanForgeStation(marketFolder, CFrame.new(forgeOrigin))

	-- Chimney Stack Piercing Roof
	createPart(marketFolder, "SmithyChimneyExt", Vector3.new(4.2, 16, 4.2), CFrame.new(forgeOrigin + Vector3.new(0, 12, -4.5)), Color3.fromRGB(48, 46, 52), Enum.Material.Slate)

	-- Timber Canopy over Outdoor Forge Hearth
	local forgeTimberCol = Color3.fromRGB(60, 42, 28)
	createPart(marketFolder, "ForgePost1", Vector3.new(1.0, 11, 1.0), CFrame.new(forgeOrigin + Vector3.new(-8, 5.5, -4)), forgeTimberCol, Enum.Material.Wood)
	createPart(marketFolder, "ForgePost2", Vector3.new(1.0, 11, 1.0), CFrame.new(forgeOrigin + Vector3.new(8, 5.5, -4)), forgeTimberCol, Enum.Material.Wood)
	createPart(marketFolder, "ForgePost3", Vector3.new(1.0, 11, 1.0), CFrame.new(forgeOrigin + Vector3.new(-8, 5.5, 8)), forgeTimberCol, Enum.Material.Wood)
	createPart(marketFolder, "ForgePost4", Vector3.new(1.0, 11, 1.0), CFrame.new(forgeOrigin + Vector3.new(8, 5.5, 8)), forgeTimberCol, Enum.Material.Wood)
	EnvironmentProps.CreatePitchedRoof(marketFolder, 18, 16, CFrame.new(forgeOrigin + Vector3.new(0, 11, 2)), 25, Color3.fromRGB(52, 54, 60))

	-- Stacks of Raw Iron Ingots, Bronze Bars & Coal Barrels
	createPart(marketFolder, "IronIngotStack", Vector3.new(3.0, 1.4, 2.0), CFrame.new(forgeOrigin + Vector3.new(-6.5, 0.7, 7)), Color3.fromRGB(60, 62, 68), Enum.Material.Metal)
	createPart(marketFolder, "BronzeIngotStack", Vector3.new(2.4, 1.2, 1.8), CFrame.new(forgeOrigin + Vector3.new(-6.5, 0.6, 4.5)), Color3.fromRGB(180, 120, 50), Enum.Material.Metal)
	createPart(marketFolder, "CoalCask1", Vector3.new(2.2, 3.0, 2.2), (CFrame.new(forgeOrigin + Vector3.new(6.5, 1.5, 5.5))) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 30, 22), Enum.Material.Wood, true, true, Enum.PartType.Cylinder)

	-- Tool Rack with Blacksmith Tongs and Hammers
	local toolRackCF = CFrame.new(forgeOrigin + Vector3.new(5.0, 4.5, -4.5))
	createPart(marketFolder, "ToolBoard", Vector3.new(6.0, 3.0, 0.4), toolRackCF, Color3.fromRGB(75, 48, 28), Enum.Material.WoodPlanks)
	createPart(marketFolder, "SledgeHammer", Vector3.new(0.3, 3.2, 0.8), toolRackCF * CFrame.new(-1.8, 0, 0.3), Color3.fromRGB(80, 80, 85), Enum.Material.Metal)
	createPart(marketFolder, "SmithyTongs", Vector3.new(0.2, 2.8, 0.5), toolRackCF * CFrame.new(0.5, 0, 0.3), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)

	-- Blacksmith Torvald NPC (Artificer of the Iron Hearth)
	local _, torvaldTorso = createNPC(
		marketFolder,
		"NPC_TorvaldBlacksmith",
		CFrame.new(forgeOrigin + Vector3.new(0, 1.5, 3.5)),
		"Torvald the Blacksmith",
		"Master Artificer & Forgemaster",
		Color3.fromRGB(60, 40, 30),
		Color3.fromRGB(180, 80, 35),
		false,
		false
	)

	local torvaldPrompt = Instance.new("ProximityPrompt")
	torvaldPrompt.Name = "Prompt_Torvald"
	torvaldPrompt.ObjectText = "Torvald the Blacksmith"
	torvaldPrompt.ActionText = "Consult Master Forgemaster"
	torvaldPrompt.HoldDuration = 0.5
	torvaldPrompt.MaxActivationDistance = 14
	torvaldPrompt.RequiresLineOfSight = false
	torvaldPrompt.Parent = torvaldTorso

	----------------------------------------------------------------------
	-- 7. VANCE'S HEIST OPERATIONS DEN (South-West Infiltration Bunker)
	----------------------------------------------------------------------
	local vanceOrigin = Vector3.new(-50, 1, 38)

	-- Heavy Reinforced Masonry Walls & Bunker Ceiling
	createPart(marketFolder, "VanceWallBack", Vector3.new(2.4, 13, 22), CFrame.new(vanceOrigin + Vector3.new(-10, 6.5, 0)), Color3.fromRGB(42, 42, 48), Enum.Material.Slate)
	createPart(marketFolder, "VanceWallSideN", Vector3.new(22, 13, 2.4), CFrame.new(vanceOrigin + Vector3.new(0, 6.5, -10)), Color3.fromRGB(42, 42, 48), Enum.Material.Slate)
	createPart(marketFolder, "VanceWallSideS", Vector3.new(22, 13, 2.4), CFrame.new(vanceOrigin + Vector3.new(0, 6.5, 10)), Color3.fromRGB(42, 42, 48), Enum.Material.Slate)
	createPart(marketFolder, "VanceBunkerRoof", Vector3.new(22, 1.8, 22), CFrame.new(vanceOrigin + Vector3.new(0, 13.5, 0)), Color3.fromRGB(36, 36, 42), Enum.Material.Metal)

	-- Heavy Camouflage Canvas Drape over Front Entrance
	createPart(marketFolder, "VanceCamoCurtain", Vector3.new(1.0, 10.0, 8.0), CFrame.new(vanceOrigin + Vector3.new(10.5, 5.0, 0)), Color3.fromRGB(48, 56, 42), Enum.Material.Fabric)

	-- Military Weapon Rack with Halberds and Shields
	EnvironmentProps.CreateWeaponRack(marketFolder, CFrame.new(vanceOrigin + Vector3.new(-6, 0, 5)) * CFrame.Angles(0, math.rad(90), 0))

	-- Locked Ironbound Munitions Chest
	EnvironmentProps.CreateIronboundChest(marketFolder, CFrame.new(vanceOrigin + Vector3.new(-6, 0, -5)), false)

	-- Heavy Oak War Table with 3D Relief Contours of the Obsidian Fortress
	local warTable = createPart(marketFolder, "WarTable", Vector3.new(9, 3.8, 6), CFrame.new(vanceOrigin + Vector3.new(1, 1.9, 0)), Color3.fromRGB(55, 38, 25), Enum.Material.WoodPlanks)
	local mapRelief = createPart(marketFolder, "CarvedMapRelief", Vector3.new(7.6, 0.4, 4.8), CFrame.new(vanceOrigin + Vector3.new(1, 3.9, 0)), Color3.fromRGB(150, 140, 120), Enum.Material.Marble)
	
	-- Miniature Fortress Relief on Map: Fortress Walls & Glowing Objective Beacons
	createPart(marketFolder, "MapMiniFortress", Vector3.new(3.2, 0.6, 3.2), CFrame.new(vanceOrigin + Vector3.new(1, 4.3, 0)), Color3.fromRGB(35, 35, 40), Enum.Material.Slate)
	local chalicePin = createPart(marketFolder, "MapChaliceBeacon", Vector3.new(0.4, 0.8, 0.4), CFrame.new(vanceOrigin + Vector3.new(1, 4.8, 0.6)), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, false, false, Enum.PartType.Ball)
	local laserPin = createPart(marketFolder, "MapLaserBeacon", Vector3.new(0.3, 0.6, 0.3), CFrame.new(vanceOrigin + Vector3.new(1, 4.7, -0.6)), Color3.fromRGB(244, 67, 54), Enum.Material.Neon, false, false, Enum.PartType.Ball)

	-- Crimson Tactical Cage Lanterns
	local redLantern = createPart(marketFolder, "TacticalRedLantern", Vector3.new(1.0, 1.6, 1.0), CFrame.new(vanceOrigin + Vector3.new(4, 5.0, 3)), Color3.fromRGB(244, 67, 54), Enum.Material.Neon)
	createLight(redLantern, Color3.fromRGB(244, 67, 54), 2.2, 14)

	local _, vanceTorso = createNPC(
		marketFolder,
		"NPC_VanceShadow",
		CFrame.new(vanceOrigin + Vector3.new(1, 2.0, -2.5)),
		"Vance the Shadow",
		"Infiltration Operative",
		Color3.fromRGB(35, 35, 40),
		Color3.fromRGB(195, 45, 45),
		false,
		false
	)

	local heistPrompt = Instance.new("ProximityPrompt")
	heistPrompt.Name = "Prompt_Heist"
	heistPrompt.ObjectText = "Obsidian Outpost Infiltration"
	heistPrompt.ActionText = "Plan Heist & Deploy"
	heistPrompt.HoldDuration = 0.5
	heistPrompt.MaxActivationDistance = 14
	heistPrompt.RequiresLineOfSight = false
	heistPrompt.Parent = vanceTorso

	----------------------------------------------------------------------
	-- 8. THE 5-REGION GATEWAY PLAZA (North Avenue)
	----------------------------------------------------------------------
	local northGateZ = -76

	-- 1. EMPIRE DISTRICT GATEWAY (Triumphal Archway & Portcullis)
	local empGate = createPart(marketFolder, "Gate_EmpireDistrict", Vector3.new(24, 20, 5), CFrame.new(0, 10, northGateZ), Color3.fromRGB(55, 52, 58), Enum.Material.Slate)
	createPart(marketFolder, "EmpArchCornice", Vector3.new(26, 2.5, 6), CFrame.new(0, 20.5, northGateZ), Color3.fromRGB(75, 72, 78), Enum.Material.Cobblestone)
	createPart(marketFolder, "EmpPortcullis", Vector3.new(16, 15, 1.2), CFrame.new(0, 9, northGateZ), Color3.fromRGB(35, 38, 42), Enum.Material.Metal)

	local empSign = Instance.new("BillboardGui")
	empSign.Size = UDim2.new(0, 220, 0, 44)
	empSign.StudsOffset = Vector3.new(0, 12, 0)
	empSign.AlwaysOnTop = true
	empSign.Parent = empGate
	local empLabel = Instance.new("TextLabel")
	empLabel.Size = UDim2.new(1, 0, 1, 0)
	empLabel.BackgroundTransparency = 1
	empLabel.Text = "🏛️ EMPIRE DISTRICT\n[Locked: Requires Codex Tier 2]"
	empLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	empLabel.Font = Enum.Font.GothamBold
	empLabel.TextSize = 13
	empLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	empLabel.TextStrokeTransparency = 0.2
	empLabel.Parent = empSign

	local empPrompt = Instance.new("ProximityPrompt")
	empPrompt.Name = "Prompt_Gate_EmpireDistrict"
	empPrompt.ObjectText = "Empire District Gateway"
	empPrompt.ActionText = "Travel to Empire District"
	empPrompt.HoldDuration = 0.5
	empPrompt.MaxActivationDistance = 14
	empPrompt.RequiresLineOfSight = false
	empPrompt.Parent = empGate

	-- 2. WHISPERING WILDS PORTAL (Megalithic Stone Dolmen & Emerald Wisp Mist)
	local wildsGate = createPart(marketFolder, "Gate_WhisperingWilds", Vector3.new(18, 17, 5), CFrame.new(-48, 8.5, northGateZ), Color3.fromRGB(48, 62, 48), Enum.Material.Slate)
	local wildsPortal = createPart(marketFolder, "WildsPortalRune", Vector3.new(10, 13, 1.2), CFrame.new(-48, 7.5, northGateZ), Color3.fromRGB(76, 175, 80), Enum.Material.Neon, true, true)
	createLight(wildsPortal, Color3.fromRGB(76, 175, 80), 2.2, 16)

	local wildsPrompt = Instance.new("ProximityPrompt")
	wildsPrompt.Name = "Prompt_Gate_WhisperingWilds"
	wildsPrompt.ObjectText = "Whispering Wilds Portal"
	wildsPrompt.ActionText = "Travel to Whispering Wilds"
	wildsPrompt.HoldDuration = 0.5
	wildsPrompt.MaxActivationDistance = 14
	wildsPrompt.RequiresLineOfSight = false
	wildsPrompt.Parent = wildsGate

	-- 3. THE HOLLOW REALM RIFT (Hovering Jagged Obsidian Monoliths & Void Rift)
	local hollowGate = createPart(marketFolder, "Gate_HollowRealm", Vector3.new(18, 17, 5), CFrame.new(48, 8.5, northGateZ), Color3.fromRGB(28, 24, 32), Enum.Material.Slate)
	local hollowRift = createPart(marketFolder, "HollowRiftCore", Vector3.new(10, 13, 1.2), CFrame.new(48, 7.5, northGateZ), Color3.fromRGB(156, 39, 176), Enum.Material.Neon, true, true)
	createLight(hollowRift, Color3.fromRGB(156, 39, 176), 2.6, 18)

	local hollowPrompt = Instance.new("ProximityPrompt")
	hollowPrompt.Name = "Prompt_Gate_HollowRealm"
	hollowPrompt.ObjectText = "Hollow Realm Rift"
	hollowPrompt.ActionText = "Travel to Hollow Realm"
	hollowPrompt.HoldDuration = 0.5
	hollowPrompt.MaxActivationDistance = 14
	hollowPrompt.RequiresLineOfSight = false
	hollowPrompt.Parent = hollowGate

	-- 4. SUNKEN VAULT GATEWAY (Submerged Obsidian Basalt Gateway)
	local vaultGate = createPart(marketFolder, "Gate_SunkenVault", Vector3.new(18, 17, 5), CFrame.new(96, 8.5, northGateZ), Color3.fromRGB(32, 38, 48), Enum.Material.Basalt)
	local vaultPool = createPart(marketFolder, "VaultPoolCore", Vector3.new(10, 13, 1.2), CFrame.new(96, 7.5, northGateZ), Color3.fromRGB(40, 120, 240), Enum.Material.Neon, true, true)
	createLight(vaultPool, Color3.fromRGB(40, 120, 240), 2.6, 18)

	local vaultSign = Instance.new("BillboardGui")
	vaultSign.Size = UDim2.new(0, 220, 0, 44)
	vaultSign.StudsOffset = Vector3.new(0, 11, 0)
	vaultSign.AlwaysOnTop = true
	vaultSign.Parent = vaultGate
	local vaultLabel = Instance.new("TextLabel")
	vaultLabel.Size = UDim2.new(1, 0, 1, 0)
	vaultLabel.BackgroundTransparency = 1
	vaultLabel.Text = "🌊 SUNKEN VAULT\n[Breached Catacombs & Heist]"
	vaultLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
	vaultLabel.Font = Enum.Font.GothamBold
	vaultLabel.TextSize = 13
	vaultLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	vaultLabel.TextStrokeTransparency = 0.2
	vaultLabel.Parent = vaultSign

	local vaultPrompt = Instance.new("ProximityPrompt")
	vaultPrompt.Name = "Prompt_Gate_SunkenVault"
	vaultPrompt.ObjectText = "Sunken Vault Gateway"
	vaultPrompt.ActionText = "Travel to Sunken Vault"
	vaultPrompt.HoldDuration = 0.5
	vaultPrompt.MaxActivationDistance = 14
	vaultPrompt.RequiresLineOfSight = false
	vaultPrompt.Parent = vaultGate

	----------------------------------------------------------------------
	-- 9. CLIFFSIDE OVERLOOK RUINS & MOUNTAIN PERIMETER
	----------------------------------------------------------------------
	-- Tiered Stone Stairway climbing up to Lookout Platform (-82, 18, -48)
	for step = 1, 16 do
		local stepY = step * 1.1
		local stepX = -65 - (step * 0.7)
		createPart(marketFolder, "OverlookStep_" .. tostring(step), Vector3.new(6, 1.2, 5), CFrame.new(stepX, stepY, -48), Color3.fromRGB(68, 68, 72), Enum.Material.Cobblestone)
	end

	local overlookCenter = Vector3.new(-82, 18, -48)
	createPart(marketFolder, "OverlookTerrace", Vector3.new(26, 2, 26), CFrame.new(overlookCenter), Color3.fromRGB(58, 58, 62), Enum.Material.Slate)
	createPart(marketFolder, "OverlookRailingN", Vector3.new(26, 3.5, 1.2), CFrame.new(overlookCenter + Vector3.new(0, 2.5, -13)), Color3.fromRGB(48, 48, 52), Enum.Material.Slate)
	createPart(marketFolder, "OverlookRailingW", Vector3.new(1.2, 3.5, 26), CFrame.new(overlookCenter + Vector3.new(-13, 2.5, 0)), Color3.fromRGB(48, 48, 52), Enum.Material.Slate)

	-- Ancient Lore Stele Monument with Glowing Runes
	local loreStele = createPart(marketFolder, "AncientLoreStele", Vector3.new(3.2, 9, 1.6), CFrame.new(overlookCenter + Vector3.new(0, 5.5, -9)), Color3.fromRGB(32, 30, 36), Enum.Material.Marble)
	local steleRune = createPart(marketFolder, "SteleRuneGlow", Vector3.new(2.2, 6.5, 0.4), CFrame.new(overlookCenter + Vector3.new(0, 5.5, -8.1)), Color3.fromRGB(64, 196, 255), Enum.Material.Neon, true, false)
	createLight(steleRune, Color3.fromRGB(64, 196, 255), 2.0, 12)

	local lorePrompt = Instance.new("ProximityPrompt")
	lorePrompt.Name = "Prompt_ReadLore"
	lorePrompt.ObjectText = "Ancient Lore Stele"
	lorePrompt.ActionText = "Decipher Inscription (Earn Rewards)"
	lorePrompt.HoldDuration = 1.0
	lorePrompt.MaxActivationDistance = 12
	lorePrompt.RequiresLineOfSight = false
	lorePrompt.Parent = loreStele

	-- 3 Lootable Ancient Treasure Urns
	local urnLocations = {
		overlookCenter + Vector3.new(-7, 2, -5),
		overlookCenter + Vector3.new(7, 2, -5),
		overlookCenter + Vector3.new(-5, 2, 7),
	}
	for i, uPos in ipairs(urnLocations) do
		local urn = createPart(marketFolder, "TreasureUrn_" .. tostring(i), Vector3.new(1.8, 2.8, 1.8), CFrame.new(uPos), Color3.fromRGB(150, 90, 50), Enum.Material.Cobblestone, true, true, Enum.PartType.Cylinder)
		local urnPrompt = Instance.new("ProximityPrompt")
		urnPrompt.Name = "Prompt_LootUrn"
		urnPrompt.ObjectText = "Ancient Treasure Urn"
		urnPrompt.ActionText = "Search for Salvage"
		urnPrompt.HoldDuration = 0.5
		urnPrompt.MaxActivationDistance = 10
		urnPrompt.RequiresLineOfSight = false
		urnPrompt.Parent = urn
	end

	-- Rocky Cliff Perimeter Walls (Frames world and removes the flat black void!)
	EnvironmentProps.CreateRockCliff(marketFolder, CFrame.new(-98, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 220, 36)
	EnvironmentProps.CreateRockCliff(marketFolder, CFrame.new(0, 0, -98), 220, 36)
	EnvironmentProps.CreateRockCliff(marketFolder, CFrame.new(50, 0, 98) * CFrame.Angles(0, math.rad(180), 0), 220, 36)
	EnvironmentProps.CreateRockCliff(marketFolder, CFrame.new(185, 0, 0) * CFrame.Angles(0, math.rad(-90), 0), 220, 36)

	----------------------------------------------------------------------
	-- 10. MULTI-PLOT BASE DISTRICT (East Grand Bridge & 20 Spacious Sanctum Plots)
	----------------------------------------------------------------------
	-- Grand Stone Bridge to Base District
	createPart(marketFolder, "BridgeToBase", Vector3.new(54, 2.2, 20), CFrame.new(103, 0.9, 0), Color3.fromRGB(75, 74, 80), Enum.Material.Cobblestone)
	createPart(marketFolder, "BridgeRailingL", Vector3.new(54, 3.5, 1.4), CFrame.new(103, 3.4, 10), Color3.fromRGB(50, 50, 55), Enum.Material.Slate)
	createPart(marketFolder, "BridgeRailingR", Vector3.new(54, 3.5, 1.4), CFrame.new(103, 3.4, -10), Color3.fromRGB(50, 50, 55), Enum.Material.Slate)

	-- Central Grand Sanctum Avenue (East-West Boulevard, 28 studs wide)
	createPart(marketFolder, "GrandSanctumAvenue", Vector3.new(410, 1.6, 28), CFrame.new(328, 0.8, 0), Color3.fromRGB(72, 70, 75), Enum.Material.Cobblestone)
	createPart(marketFolder, "AvenueCurbN", Vector3.new(410, 0.8, 1.5), CFrame.new(328, 1.8, 14.5), Color3.fromRGB(150, 145, 140), Enum.Material.Marble)
	createPart(marketFolder, "AvenueCurbS", Vector3.new(410, 0.8, 1.5), CFrame.new(328, 1.8, -14.5), Color3.fromRGB(150, 145, 140), Enum.Material.Marble)

	-- North & South Parallel Boulevards
	createPart(marketFolder, "BoulevardNorth", Vector3.new(410, 1.4, 20), CFrame.new(328, 0.7, 102), Color3.fromRGB(68, 66, 70), Enum.Material.Cobblestone)
	createPart(marketFolder, "BoulevardSouth", Vector3.new(410, 1.4, 20), CFrame.new(328, 0.7, -102), Color3.fromRGB(68, 66, 70), Enum.Material.Cobblestone)

	-- Cross-Streets connecting the avenues between column clusters
	local crossStreetX = { 600, 950, 1300, 1650, 2000 }
	for _, csX in ipairs(crossStreetX) do
		createPart(marketFolder, "CrossStreet_" .. tostring(csX), Vector3.new(36, 1.4, 1500), CFrame.new(csX, 10.75, 0), Color3.fromRGB(65, 64, 68), Enum.Material.Cobblestone)
	end

	-- Construct 20 Handcrafted Player Base Plots in BaseDistrict
	local baseDistrict = marketFolder:FindFirstChild("BaseDistrict")
	if not baseDistrict then
		baseDistrict = Instance.new("Folder")
		baseDistrict.Name = "BaseDistrict"
		baseDistrict.Parent = marketFolder
	end

	for plotIdx = 1, EconomyConfig.PLOT_COUNT do
		local plotCoord = EconomyConfig.PLOT_COORDINATES[plotIdx]
		local plotFolder = Instance.new("Folder")
		plotFolder.Name = "BasePlot_" .. tostring(plotIdx)
		plotFolder.Parent = baseDistrict

		-- Spacious 60x60 Flagstone Plot Floor
		createPart(plotFolder, "PlotFloor", Vector3.new(60, 3, 60), CFrame.new(plotCoord), Color3.fromRGB(90, 80, 72), Enum.Material.WoodPlanks)

		-- Corner Stone Pillars with Glowing Boundary Runes (at 60x60 perimeter)
		local cornerDeltas = {
			Vector3.new(-29, 0, -29), Vector3.new(29, 0, -29),
			Vector3.new(-29, 0, 29), Vector3.new(29, 0, 29)
		}
		for cIdx, delta in ipairs(cornerDeltas) do
			local post = createPart(plotFolder, "CornerPost_" .. tostring(cIdx), Vector3.new(2.2, 6, 2.2), CFrame.new(plotCoord + delta + Vector3.new(0, 4.0, 0)), Color3.fromRGB(60, 60, 65), Enum.Material.Slate)
			local postRune = createPart(plotFolder, "RuneCap", Vector3.new(1.2, 0.6, 1.2), CFrame.new(plotCoord + delta + Vector3.new(0, 7.2, 0)), Color3.fromRGB(64, 196, 255), Enum.Material.Neon, true, false)
			createLight(postRune, Color3.fromRGB(64, 196, 255), 1.2, 8)
		end

		-- Dynamic Ownership Billboard (MaxDistance clamped to 45 studs, AlwaysOnTop = false to completely prevent skyline label overlap)
		local signPost = createPart(plotFolder, "PlotSignPost", Vector3.new(1.2, 7, 1.2), CFrame.new(plotCoord + Vector3.new(-26, 4.5, -26)), Color3.fromRGB(80, 50, 30), Enum.Material.Wood)
		local signBb = Instance.new("BillboardGui")
		signBb.Name = "PlotBillboard"
		signBb.Size = UDim2.new(0, 180, 0, 40)
		signBb.StudsOffset = Vector3.new(0, 3.5, 0)
		signBb.AlwaysOnTop = false
		signBb.MaxDistance = 45
		signBb.Parent = signPost
		local signLabel = Instance.new("TextLabel")
		signLabel.Name = "TitleLabel"
		signLabel.Size = UDim2.new(1, 0, 1, 0)
		signLabel.BackgroundTransparency = 1
		signLabel.Text = string.format("🏰 SANCTUM PLOT #%d\n[Unclaimed]", plotIdx)
		signLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		signLabel.Font = Enum.Font.GothamBold
		signLabel.TextSize = 13
		signLabel.TextStrokeColor3 = Color3.fromRGB(20, 20, 25)
		signLabel.TextStrokeTransparency = 0.2
		signLabel.Parent = signBb

		-- Starter Shelter with Pitched Roof (Tier 1)
		local starterShelter = Instance.new("Folder")
		starterShelter.Name = "StarterShelterTier1"
		starterShelter.Parent = plotFolder
		EnvironmentProps.CreatePitchedRoof(starterShelter, 18, 14, CFrame.new(plotCoord + Vector3.new(0, 9.5, -16)), 28, Color3.fromRGB(55, 42, 32))
		createPart(starterShelter, "ShelterPostL", Vector3.new(1.2, 8.0, 1.2), CFrame.new(plotCoord + Vector3.new(-8, 5.5, -10)), Color3.fromRGB(60, 42, 28), Enum.Material.Wood)
		createPart(starterShelter, "ShelterPostR", Vector3.new(1.2, 8.0, 1.2), CFrame.new(plotCoord + Vector3.new(8, 5.5, -10)), Color3.fromRGB(60, 42, 28), Enum.Material.Wood)
		createPart(starterShelter, "ShelterPostBL", Vector3.new(1.2, 8.0, 1.2), CFrame.new(plotCoord + Vector3.new(-8, 5.5, -22)), Color3.fromRGB(60, 42, 28), Enum.Material.Wood)
		createPart(starterShelter, "ShelterPostBR", Vector3.new(1.2, 8.0, 1.2), CFrame.new(plotCoord + Vector3.new(8, 5.5, -22)), Color3.fromRGB(60, 42, 28), Enum.Material.Wood)
		local shelterLantern = createPart(starterShelter, "ShelterLantern", Vector3.new(1.0, 1.4, 1.0), CFrame.new(plotCoord + Vector3.new(0, 7.5, -10)), Color3.fromRGB(255, 180, 50), Enum.Material.Neon)
		createLight(shelterLantern, Color3.fromRGB(255, 180, 60), 2.0, 14)

		-- Workshop Bench
		local workbench = createPart(plotFolder, "BaseWorkshopBench", Vector3.new(8, 3.8, 3.5), CFrame.new(plotCoord + Vector3.new(0, 3.4, -16)), Color3.fromRGB(115, 68, 38), Enum.Material.WoodPlanks)
		local workbenchPrompt = Instance.new("ProximityPrompt")
		workbenchPrompt.Name = "Prompt_BaseWorkbench"
		workbenchPrompt.ObjectText = "Workshop Bench"
		workbenchPrompt.ActionText = "Manage Workshop / Upgrades"
		workbenchPrompt.HoldDuration = 0.5
		workbenchPrompt.MaxActivationDistance = 14
		workbenchPrompt.RequiresLineOfSight = false
		workbenchPrompt.Parent = workbench

		-- Trophy Plinth (Showcase for Active Bonded Relic)
		local plinth = createPart(plotFolder, "BaseDisplayPlinth", Vector3.new(5, 3.5, 5), CFrame.new(plotCoord + Vector3.new(0, 3.2, 14)), Color3.fromRGB(150, 150, 160), Enum.Material.Marble)
		createPart(plotFolder, "PlinthGoldTrim", Vector3.new(5.4, 0.5, 5.4), CFrame.new(plotCoord + Vector3.new(0, 5.1, 14)), Color3.fromRGB(255, 215, 0), Enum.Material.Metal)
		local plinthPrompt = Instance.new("ProximityPrompt")
		plinthPrompt.Name = "Prompt_Plinth"
		plinthPrompt.ObjectText = "Relic Trophy Plinth"
		plinthPrompt.ActionText = "Inspect Relic Loadout"
		plinthPrompt.HoldDuration = 0.5
		plinthPrompt.MaxActivationDistance = 12
		plinthPrompt.RequiresLineOfSight = false
		plinthPrompt.Parent = plinth

		-- Sample starter compass on plinth
		RelicMeshBuilder.CreateScavengerCompass(plotFolder, CFrame.new(plotCoord + Vector3.new(0, 6.5, 14)))

		-- Base Storage Chest
		local chest = createPart(plotFolder, "BaseStorageChest", Vector3.new(3.5, 2.5, 2.5), CFrame.new(plotCoord + Vector3.new(16, 2.8, -14)), Color3.fromRGB(95, 62, 38), Enum.Material.WoodPlanks)
		local chestPrompt = Instance.new("ProximityPrompt")
		chestPrompt.Name = "Prompt_StorageChest"
		chestPrompt.ObjectText = "Sanctum Storage Chest"
		chestPrompt.ActionText = "Open Storage"
		chestPrompt.HoldDuration = 0.5
		chestPrompt.MaxActivationDistance = 12
		chestPrompt.RequiresLineOfSight = false
		chestPrompt.Parent = chest
	end

	-- Handcrafted Ornate Streetlamps along thoroughfares
	local lanternLocations = {
		CFrame.new(-22, 0, 22), CFrame.new(22, 0, 22),
		CFrame.new(-22, 0, -22), CFrame.new(22, 0, -22),
		CFrame.new(0, 0, 32), CFrame.new(0, 0, -48),
		CFrame.new(84, 0, 0), CFrame.new(132, 0, 0),
	}
	for _, lCF in ipairs(lanternLocations) do
		EnvironmentProps.CreateStreetLantern(marketFolder, lCF)
	end

	----------------------------------------------------------------------
	-- 11. MONUMENTAL TOWN SQUARE CLOCKTOWER & SKYLINE
	----------------------------------------------------------------------
	EnvironmentProps.CreateClockTower(marketFolder, CFrame.new(28, 0.8, 42))

	----------------------------------------------------------------------
	-- 12. CENTRAL DIRECTIONAL SIGNPOSTS
	----------------------------------------------------------------------
	EnvironmentProps.CreateDirectionalSignpost(marketFolder, CFrame.new(0, 0.8, 14), {
		{ text = "🏛️ Empire District (N)", angle = 0 },
		{ text = "🌲 Whispering Wilds (W)", angle = 90 },
		{ text = "🌌 Hollow Realm (NE)", angle = -45 },
		{ text = "🏰 Base District (E)", angle = -90 },
		{ text = "⚔️ Vance's Den (SW)", angle = 135 },
	})

	EnvironmentProps.CreateDirectionalSignpost(marketFolder, CFrame.new(0, 0.8, -48), {
		{ text = "🏛️ Empire District", angle = 0 },
		{ text = "🌲 Whispering Wilds", angle = 90 },
		{ text = "🌌 Hollow Realm", angle = -90 },
		{ text = "📍 Market Plaza", angle = 180 },
	})

	----------------------------------------------------------------------
	-- 13. BUSTLING CARGO CRATE & BARREL CLUSTERS
	----------------------------------------------------------------------
	EnvironmentProps.CreateCrateAndBarrelCluster(marketFolder, CFrame.new(30, 0.8, -26))
	EnvironmentProps.CreateCrateAndBarrelCluster(marketFolder, CFrame.new(-42, 0.8, 6))
	EnvironmentProps.CreateCrateAndBarrelCluster(marketFolder, CFrame.new(-38, 0.8, 38))
	EnvironmentProps.CreateCrateAndBarrelCluster(marketFolder, CFrame.new(58, 0.8, -26))

	----------------------------------------------------------------------
	-- 14. WALKABLE PERIMETER RAMPART STAIRWAYS
	----------------------------------------------------------------------
	-- West Rampart Staircase climbing from plaza level to 10-stud battlement
	for step = 1, 10 do
		local sY = step * 1.0
		local sZ = 10 - (step * 1.2)
		createPart(marketFolder, "WestRampartStep_" .. tostring(step), Vector3.new(4.5, 1.0, 1.4), CFrame.new(-72, sY, sZ), Color3.fromRGB(68, 68, 72), Enum.Material.Cobblestone)
	end

	-- South Rampart Staircase near Gatehouse
	for step = 1, 10 do
		local sY = step * 1.0
		local sX = -26 - (step * 1.2)
		createPart(marketFolder, "SouthRampartStep_" .. tostring(step), Vector3.new(1.4, 1.0, 4.5), CFrame.new(sX, sY, 72), Color3.fromRGB(68, 68, 72), Enum.Material.Cobblestone)
	end

	return marketFolder
end

return MarketBuilder
