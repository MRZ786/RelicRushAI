--!strict
-- WhisperingWildsBuilder.luau
-- Authoritative procedural builder for Region 3: The Whispering Wilds
-- Constructs an overgrown ancient wilderness:
-- Emerald Threshold, Elder Ironwood Tree, Whispering Hollow, Shrine of the Shifting Sands, and Sunken Amphitheater.

local Workspace = game:GetService("Workspace")
local EnvironmentProps = require(script.Parent.EnvironmentProps)

local WhisperingWildsBuilder = {}

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
	part.Anchored = if anchored ~= nil then anchored else true
	part.CanCollide = if canCollide ~= nil then canCollide else true
	if shape then
		part.Shape = shape
	end
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
	light.Parent = parent
	return light
end

function WhisperingWildsBuilder.Build(worldFolder: Folder): Folder
	local wildsFolder = Instance.new("Folder")
	wildsFolder.Name = "WhisperingWilds"

	local center = Vector3.new(-280, 1, -150)

	----------------------------------------------------------------------
	-- 1. WILDERNESS TERRAIN & MOSS FOUNDATION
	----------------------------------------------------------------------
	-- Main Forest Floor
	createPart(wildsFolder, "WildsFloor", Vector3.new(190, 2, 210), CFrame.new(center + Vector3.new(0, -1, 0)), Color3.fromRGB(38, 52, 36), Enum.Material.Grass)

	-- Rocky Boundary Cliffs & Overgrowth Ridges
	createPart(wildsFolder, "CliffNorth", Vector3.new(190, 32, 16), CFrame.new(center + Vector3.new(0, 15, -105)), Color3.fromRGB(48, 50, 46), Enum.Material.Slate)
	createPart(wildsFolder, "CliffSouth", Vector3.new(190, 32, 16), CFrame.new(center + Vector3.new(0, 15, 105)), Color3.fromRGB(48, 50, 46), Enum.Material.Slate)
	createPart(wildsFolder, "CliffWest", Vector3.new(16, 32, 210), CFrame.new(center + Vector3.new(-95, 15, 0)), Color3.fromRGB(48, 50, 46), Enum.Material.Slate)

	-- Winding Stone Forest Path
	createPart(wildsFolder, "ForestPath", Vector3.new(160, 0.4, 18), CFrame.new(center + Vector3.new(0, 0.3, 0)), Color3.fromRGB(65, 60, 52), Enum.Material.Sandstone)

	----------------------------------------------------------------------
	-- 2. THE EMERALD THRESHOLD (East Border Entrance from Emerald Highway)
	----------------------------------------------------------------------
	local gateX = -2985

	-- Megalithic Dolmen Archway Entrance
	EnvironmentProps.CreateDolmenArch(wildsFolder, CFrame.new(gateX, 10.8, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(76, 175, 80))

	-- Swirling Verdant Portal Veil (Return to Market Settlement)
	local portalVeil = createPart(wildsFolder, "WildsPortalVeil", Vector3.new(1.2, 17, 16), CFrame.new(gateX, 18.5, 0), Color3.fromRGB(76, 175, 80), Enum.Material.Neon, true, false)
	createLight(portalVeil, Color3.fromRGB(76, 175, 80), 2.5, 18)

	-- Return Travel Gate Marker
	local retPrompt = Instance.new("ProximityPrompt")
	retPrompt.Name = "Prompt_ReturnMarket_Wilds"
	retPrompt.ObjectText = "Forgotten Market Portal"
	retPrompt.ActionText = "Return to Market Settlement"
	retPrompt.HoldDuration = 0.5
	retPrompt.MaxActivationDistance = 14
	retPrompt.Parent = portalVeil

	-- Forest Crossroads Directional Signpost
	EnvironmentProps.CreateDirectionalSignpost(wildsFolder, CFrame.new(center + Vector3.new(50, 0.8, 0)), {
		{ text = "North: Shifting Sands Shrine", angleDeg = 0, color = Color3.fromRGB(255, 200, 60) },
		{ text = "West: Elder Ironwood Hollow", angleDeg = 90, color = Color3.fromRGB(100, 255, 140) },
		{ text = "South: Sunken Amphitheater", angleDeg = 180, color = Color3.fromRGB(120, 200, 255) },
		{ text = "East: Forgotten Market Hub", angleDeg = 270, color = Color3.fromRGB(240, 220, 150) },
	})

	-- Bioluminescent Glowing Mushroom Clusters across pathways
	EnvironmentProps.CreateGlowingMushroomCluster(wildsFolder, CFrame.new(center + Vector3.new(62, 0.8, 8)), Color3.fromRGB(100, 255, 140))
	EnvironmentProps.CreateGlowingMushroomCluster(wildsFolder, CFrame.new(center + Vector3.new(35, 0.8, -10)), Color3.fromRGB(76, 215, 80))
	EnvironmentProps.CreateGlowingMushroomCluster(wildsFolder, CFrame.new(center + Vector3.new(-18, 0.8, 14)), Color3.fromRGB(130, 240, 160))
	EnvironmentProps.CreateGlowingMushroomCluster(wildsFolder, CFrame.new(center + Vector3.new(16, 0.8, -22)), Color3.fromRGB(100, 255, 180))

	----------------------------------------------------------------------
	-- 3. THE WHISPERING HOLLOW & ELDER IRONWOOD TREE (Center)
	----------------------------------------------------------------------
	-- Massive Ancient Ironwood Trunk
	local treeTrunk = createPart(wildsFolder, "IronwoodTrunk", Vector3.new(10, 48, 10), CFrame.new(center + Vector3.new(0, 24, 0)), Color3.fromRGB(45, 30, 20), Enum.Material.Wood, true, true, Enum.PartType.Cylinder)
	treeTrunk.CFrame = CFrame.new(center + Vector3.new(0, 24, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Ambient Spore Motes drifting beneath the canopy
	local sporeEmitter = Instance.new("ParticleEmitter")
	sporeEmitter.Name = "ForestSporeMotes"
	sporeEmitter.Color = ColorSequence.new(Color3.fromRGB(120, 255, 140))
	sporeEmitter.LightEmission = 0.8
	sporeEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	sporeEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	sporeEmitter.Lifetime = NumberRange.new(4, 7)
	sporeEmitter.Rate = 10
	sporeEmitter.Speed = NumberRange.new(1, 2.2)
	sporeEmitter.SpreadAngle = Vector2.new(45, 45)
	sporeEmitter.Parent = treeTrunk

	-- Sprawling Buttress Roots
	for r = 1, 6 do
		local rAngle = math.rad((r - 1) * 60)
		local rootPos = center + Vector3.new(math.cos(rAngle) * 9, 3, math.sin(rAngle) * 9)
		createPart(wildsFolder, "RootButtress_" .. tostring(r), Vector3.new(3.5, 6, 6), CFrame.new(rootPos) * CFrame.Angles(0, -rAngle, 0), Color3.fromRGB(40, 28, 18), Enum.Material.Wood)
	end

	-- Layered Foliage Canopies
	createPart(wildsFolder, "CanopyLower", Vector3.new(50, 14, 50), CFrame.new(center + Vector3.new(0, 42, 0)), Color3.fromRGB(28, 75, 35), Enum.Material.Grass, true, true, Enum.PartType.Ball)
	createPart(wildsFolder, "CanopyUpper", Vector3.new(36, 12, 36), CFrame.new(center + Vector3.new(0, 52, 0)), Color3.fromRGB(36, 95, 45), Enum.Material.Grass, true, true, Enum.PartType.Ball)

	-- Bioluminescent Hanging Wisp Pods
	for w = 1, 8 do
		local wAngle = math.rad((w - 1) * 45)
		local wPos = center + Vector3.new(math.cos(wAngle) * 18, 35, math.sin(wAngle) * 18)
		local wisp = createPart(wildsFolder, "HangingWisp_" .. tostring(w), Vector3.new(1.8, 2.4, 1.8), CFrame.new(wPos), Color3.fromRGB(129, 199, 132), Enum.Material.Neon, true, false, Enum.PartType.Ball)
		createLight(wisp, Color3.fromRGB(76, 175, 80), 1.8, 14)
	end

	-- Druidic Standing Stones Circle surrounding tree
	for s = 1, 6 do
		local sAngle = math.rad((s - 1) * 60 + 30)
		local sPos = center + Vector3.new(math.cos(sAngle) * 22, 5, math.sin(sAngle) * 22)
		local stone = createPart(wildsFolder, "DruidStone_" .. tostring(s), Vector3.new(2.8, 10, 2.0), CFrame.new(sPos) * CFrame.Angles(0, -sAngle, math.rad(math.random(-5, 5))), Color3.fromRGB(55, 62, 55), Enum.Material.Slate)
		-- Glowing emerald carved rune band
		createPart(wildsFolder, "RuneBand_" .. tostring(s), Vector3.new(2.9, 1.2, 2.1), CFrame.new(sPos + Vector3.new(0, 1, 0)), Color3.fromRGB(76, 175, 80), Enum.Material.Neon, true, false)
	end

	-- Lore Monolith: "Chronicles of the Wilds"
	local lorePos = center + Vector3.new(0, 4.5, 20)
	local wildsStele = createPart(wildsFolder, "WildsLoreMonolith", Vector3.new(4, 9, 2), CFrame.new(lorePos), Color3.fromRGB(42, 52, 42), Enum.Material.Marble)
	local wildsRune = createPart(wildsFolder, "WildsSteleRune", Vector3.new(3, 7, 0.4), CFrame.new(lorePos + Vector3.new(0, 0, 1.05)), Color3.fromRGB(100, 255, 120), Enum.Material.Neon, true, false)
	createLight(wildsRune, Color3.fromRGB(76, 175, 80), 2.0, 14)

	local lorePrompt = Instance.new("ProximityPrompt")
	lorePrompt.Name = "Prompt_WildsLore"
	lorePrompt.ObjectText = "Chronicles of the Wilds"
	lorePrompt.ActionText = "Decipher Overgrown Runes"
	lorePrompt.HoldDuration = 1.0
	lorePrompt.MaxActivationDistance = 12
	lorePrompt.RequiresLineOfSight = false
	lorePrompt.Parent = wildsStele

	----------------------------------------------------------------------
	-- 4. SHRINE OF THE SHIFTING SANDS (North Clearing, Z = -220)
	----------------------------------------------------------------------
	local shrineCenter = center + Vector3.new(0, 0, -70)

	-- Sandstone Stepped Temple Foundation
	createPart(wildsFolder, "ShrinePlinth1", Vector3.new(36, 1.5, 36), CFrame.new(shrineCenter + Vector3.new(0, 0.75, 0)), Color3.fromRGB(180, 150, 100), Enum.Material.Sandstone)
	createPart(wildsFolder, "ShrinePlinth2", Vector3.new(28, 1.2, 28), CFrame.new(shrineCenter + Vector3.new(0, 2.1, 0)), Color3.fromRGB(210, 180, 120), Enum.Material.Sandstone)

	-- 6 Weathered Sandstone Columns
	for c = 1, 6 do
		local cAngle = math.rad((c - 1) * 60)
		local cPos = shrineCenter + Vector3.new(math.cos(cAngle) * 11, 7.5, math.sin(cAngle) * 11)
		local col = createPart(wildsFolder, "ShrineCol_" .. tostring(c), Vector3.new(1.8, 11, 1.8), CFrame.new(cPos), Color3.fromRGB(200, 175, 125), Enum.Material.Sandstone, true, true, Enum.PartType.Cylinder)
		col.CFrame = CFrame.new(cPos) * CFrame.Angles(0, 0, math.rad(90))
	end

	-- Central Altar of the Shifting Sands
	local altarCF = CFrame.new(shrineCenter + Vector3.new(0, 3.2, 0))
	local sandsAltar = createPart(wildsFolder, "HourglassAltar", Vector3.new(5, 2.4, 5), altarCF, Color3.fromRGB(160, 120, 60), Enum.Material.Marble)
	createPart(wildsFolder, "HourglassGlowRune", Vector3.new(4, 0.4, 4), altarCF * CFrame.new(0, 1.3, 0), Color3.fromRGB(255, 175, 30), Enum.Material.Neon)
	createLight(sandsAltar, Color3.fromRGB(255, 180, 40), 2.2, 16)

	local altarPrompt = Instance.new("ProximityPrompt")
	altarPrompt.Name = "Prompt_HourglassAltar"
	altarPrompt.ObjectText = "Altar of Shifting Sands"
	altarPrompt.ActionText = "Commune & Recover Ancient Hourglass"
	altarPrompt.HoldDuration = 1.2
	altarPrompt.MaxActivationDistance = 14
	altarPrompt.RequiresLineOfSight = false
	altarPrompt.Parent = sandsAltar

	-- Druidic Offering Urn (Exploration Salvage Cache)
	local urnCF = CFrame.new(shrineCenter + Vector3.new(8, 2.8, -4))
	local offeringUrn = createPart(wildsFolder, "DruidicOfferingUrn", Vector3.new(2.8, 3.4, 2.8), urnCF, Color3.fromRGB(65, 80, 65), Enum.Material.Slate, true, true, Enum.PartType.Cylinder)
	offeringUrn.CFrame = urnCF * CFrame.Angles(0, 0, math.rad(90))
	createPart(wildsFolder, "UrnGoldLid", Vector3.new(3.0, 0.6, 3.0), urnCF * CFrame.new(0, 1.8, 0), Color3.fromRGB(230, 185, 50), Enum.Material.Metal)

	local urnPrompt = Instance.new("ProximityPrompt")
	urnPrompt.Name = "Prompt_WildsOffering"
	urnPrompt.ObjectText = "Druidic Offering Urn"
	urnPrompt.ActionText = "Loot Shrine Offering"
	urnPrompt.HoldDuration = 1.0
	urnPrompt.MaxActivationDistance = 12
	urnPrompt.RequiresLineOfSight = false
	urnPrompt.Parent = offeringUrn

	-- Shrine Dune Swells & Golden Flora
	createPart(wildsFolder, "SandDune1", Vector3.new(24, 2.2, 12), CFrame.new(shrineCenter + Vector3.new(-18, 1.1, -16)) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(195, 165, 110), Enum.Material.Sand)
	createPart(wildsFolder, "SandDune2", Vector3.new(20, 1.8, 14), CFrame.new(shrineCenter + Vector3.new(16, 0.9, 18)) * CFrame.Angles(0, math.rad(-30), 0), Color3.fromRGB(195, 165, 110), Enum.Material.Sand)
	EnvironmentProps.CreateGlowingMushroomCluster(wildsFolder, CFrame.new(shrineCenter + Vector3.new(-16, 0.8, 14)), Color3.fromRGB(255, 200, 80))
	EnvironmentProps.CreateGlowingMushroomCluster(wildsFolder, CFrame.new(shrineCenter + Vector3.new(16, 0.8, -14)), Color3.fromRGB(255, 180, 50))

	----------------------------------------------------------------------
	-- 5. SUNKEN AMPHITHEATER RUINS (South Clearing, Z = -80)
	----------------------------------------------------------------------
	local amphiCenter = center + Vector3.new(0, 0, 70)

	-- Semicircular Tiered Seating
	for tier = 1, 4 do
		local radius = 12 + (tier * 4)
		for seg = 1, 6 do
			local angle = math.rad((seg - 1) * 30 + 15)
			local segPos = amphiCenter + Vector3.new(math.cos(angle) * radius, tier * 1.0, math.sin(angle) * radius)
			createPart(wildsFolder, "AmphiBench_" .. tier .. "_" .. seg, Vector3.new(4, 1.0, 4), CFrame.new(segPos) * CFrame.Angles(0, -angle, 0), Color3.fromRGB(58, 65, 58), Enum.Material.Cobblestone)
		end
	end

	-- Sunken Tranquil Reflecting Pool
	createPart(wildsFolder, "AmphiPool", Vector3.new(18, 0.4, 18), CFrame.new(amphiCenter + Vector3.new(0, 0.2, 0)), Color3.fromRGB(40, 130, 180), Enum.Material.Glass)

	-- Amphitheater Flanking Columns & Azure Fungi
	createPart(wildsFolder, "AmphiColL", Vector3.new(2.4, 12, 2.4), CFrame.new(amphiCenter + Vector3.new(-14, 6, -10)), Color3.fromRGB(60, 68, 60), Enum.Material.Cobblestone)
	createPart(wildsFolder, "AmphiColR", Vector3.new(2.4, 12, 2.4), CFrame.new(amphiCenter + Vector3.new(14, 6, -10)), Color3.fromRGB(60, 68, 60), Enum.Material.Cobblestone)
	EnvironmentProps.CreateGlowingMushroomCluster(wildsFolder, CFrame.new(amphiCenter + Vector3.new(-18, 0.8, 12)), Color3.fromRGB(80, 220, 255))
	EnvironmentProps.CreateGlowingMushroomCluster(wildsFolder, CFrame.new(amphiCenter + Vector3.new(18, 0.8, -12)), Color3.fromRGB(100, 200, 255))

	----------------------------------------------------------------------
	-- 5B. ROLLING FOREST TERRAIN VARIATION, BOULDERS & FALLEN LOGS
	----------------------------------------------------------------------
	-- Rolling Moss Mounds & Knolls for naturalistic ground height variation
	local knollPositions = {
		Vector3.new(-45, 1.2, -45), Vector3.new(45, 1.4, -35),
		Vector3.new(-55, 1.5, 40), Vector3.new(35, 1.2, 50),
		Vector3.new(-25, 1.0, 75), Vector3.new(20, 1.3, -80),
	}
	for k, kOffset in ipairs(knollPositions) do
		local knollPart = createPart(wildsFolder, "ForestKnoll_" .. k, Vector3.new(26, 3.2, 24), CFrame.new(center + kOffset), Color3.fromRGB(36, 50, 34), Enum.Material.Grass, true, true, Enum.PartType.Ball)
		knollPart.Size = Vector3.new(32, 2.8, 30)
	end

	-- Weathered Mossy Granite Boulder Clusters
	EnvironmentProps.CreateMossyBoulderCluster(wildsFolder, CFrame.new(center + Vector3.new(-38, 0.8, -25)))
	EnvironmentProps.CreateMossyBoulderCluster(wildsFolder, CFrame.new(center + Vector3.new(42, 0.8, 28)))
	EnvironmentProps.CreateMossyBoulderCluster(wildsFolder, CFrame.new(center + Vector3.new(-28, 0.8, 48)))

	-- Ancient Hollow Fallen Logs across natural clearings
	EnvironmentProps.CreateFallenLog(wildsFolder, CFrame.new(center + Vector3.new(-40, 0.8, 15)) * CFrame.Angles(0, math.rad(35), 0), 22)
	EnvironmentProps.CreateFallenLog(wildsFolder, CFrame.new(center + Vector3.new(30, 0.8, -50)) * CFrame.Angles(0, math.rad(-25), 0), 20)

	-- Towering Druidic Monoliths with Glowing Runic Reliefs
	EnvironmentProps.CreateDruidicMonolith(wildsFolder, CFrame.new(center + Vector3.new(-20, 0.8, -35)), Color3.fromRGB(76, 215, 110))
	EnvironmentProps.CreateDruidicMonolith(wildsFolder, CFrame.new(center + Vector3.new(25, 0.8, 25)), Color3.fromRGB(100, 255, 140))

	----------------------------------------------------------------------
	-- 6. REGIONAL NPC: KEEPER SYLVA (Warden of the Wilds)
	----------------------------------------------------------------------
	local npcModel = Instance.new("Model")
	npcModel.Name = "NPC_KeeperSylva"

	local npcCF = CFrame.new(center + Vector3.new(15, 1.0, 5)) * CFrame.Angles(0, math.rad(-70), 0)

	-- Torso in Forest Robes
	local torso = createPart(npcModel, "Torso", Vector3.new(2.2, 2.6, 1.4), npcCF * CFrame.new(0, 2.3, 0), Color3.fromRGB(36, 68, 42), Enum.Material.Fabric)
	npcModel.PrimaryPart = torso

	-- Flowing Leaf-Green Robe Skirt
	createPart(npcModel, "RobeSkirt", Vector3.new(2.4, 2.0, 1.6), npcCF * CFrame.new(0, 1.0, 0), Color3.fromRGB(28, 55, 32), Enum.Material.Fabric)

	-- Braided Vine Belt
	createPart(npcModel, "VineBelt", Vector3.new(2.3, 0.4, 1.5), npcCF * CFrame.new(0, 1.9, 0), Color3.fromRGB(60, 42, 25), Enum.Material.Wood)

	-- Arms in Embroidered Sleeves
	createPart(npcModel, "LeftArm", Vector3.new(0.8, 2.2, 0.8), npcCF * CFrame.new(-1.5, 2.2, 0), Color3.fromRGB(36, 68, 42), Enum.Material.Fabric)
	createPart(npcModel, "RightArm", Vector3.new(0.8, 2.2, 0.8), npcCF * CFrame.new(1.5, 2.2, 0), Color3.fromRGB(36, 68, 42), Enum.Material.Fabric)

	-- Head with Glowing Emerald Eyes & Antlered Druidic Cowl
	local head = createPart(npcModel, "Head", Vector3.new(1.4, 1.4, 1.4), npcCF * CFrame.new(0, 4.1, 0), Color3.fromRGB(230, 200, 175), Enum.Material.SmoothPlastic)
	createPart(npcModel, "DruidCowl", Vector3.new(1.9, 1.8, 1.9), npcCF * CFrame.new(0, 4.3, -0.1), Color3.fromRGB(24, 45, 28), Enum.Material.Fabric)

	-- Carved Ironwood Antlers atop Cowl
	local antlerL = createPart(npcModel, "AntlerL", Vector3.new(0.25, 1.8, 0.25), (npcCF * CFrame.new(-0.8, 5.5, 0)) * CFrame.Angles(0, 0, math.rad(-25)), Color3.fromRGB(80, 55, 30), Enum.Material.Wood)
	local antlerR = createPart(npcModel, "AntlerR", Vector3.new(0.25, 1.8, 0.25), (npcCF * CFrame.new(0.8, 5.5, 0)) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(80, 55, 30), Enum.Material.Wood)

	-- Luminous Emerald Eyes
	createPart(npcModel, "EyeL", Vector3.new(0.18, 0.14, 0.1), npcCF * CFrame.new(-0.35, 4.25, 0.72), Color3.fromRGB(100, 255, 140), Enum.Material.Neon)
	createPart(npcModel, "EyeR", Vector3.new(0.18, 0.14, 0.1), npcCF * CFrame.new(0.35, 4.25, 0.72), Color3.fromRGB(100, 255, 140), Enum.Material.Neon)

	-- Elderwood Stave with Swirling Verdant Spores
	local staff = createPart(npcModel, "DruidStaff", Vector3.new(0.35, 7.8, 0.35), npcCF * CFrame.new(1.8, 3.6, 0.8), Color3.fromRGB(60, 40, 22), Enum.Material.Wood)
	local staffOrb = createPart(npcModel, "StaffOrb", Vector3.new(1.0, 1.0, 1.0), npcCF * CFrame.new(1.8, 7.6, 0.8), Color3.fromRGB(76, 215, 80), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(staffOrb, Color3.fromRGB(76, 215, 80), 2.2, 14)

	local staffMotes = Instance.new("ParticleEmitter")
	staffMotes.Name = "StaffMotes"
	staffMotes.Color = ColorSequence.new(Color3.fromRGB(120, 255, 140))
	staffMotes.Size = NumberSequence.new(0.2, 0.04)
	staffMotes.Lifetime = NumberRange.new(0.8, 1.6)
	staffMotes.Rate = 8
	staffMotes.Speed = NumberRange.new(0.5, 1.0)
	staffMotes.Parent = staffOrb

	-- Overhead Title Billboard
	local bb = Instance.new("BillboardGui")
	bb.Name = "Nameplate"
	bb.Size = UDim2.new(0, 210, 0, 48)
	bb.StudsOffset = Vector3.new(0, 3.6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 65
	bb.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Keeper Sylva"
	nameLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = bb

	local roleLabel = Instance.new("TextLabel")
	roleLabel.Size = UDim2.new(1, 0, 0, 18)
	roleLabel.Position = UDim2.new(0, 0, 0, 22)
	roleLabel.BackgroundTransparency = 1
	roleLabel.Text = "Warden of the Whispering Wilds"
	roleLabel.TextColor3 = Color3.fromRGB(180, 230, 190)
	roleLabel.Font = Enum.Font.Gotham
	roleLabel.TextSize = 12
	roleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	roleLabel.TextStrokeTransparency = 0.3
	roleLabel.Parent = bb

	-- Proximity Prompt
	local sylvaPrompt = Instance.new("ProximityPrompt")
	sylvaPrompt.Name = "Prompt_Sylva"
	sylvaPrompt.ObjectText = "Keeper Sylva"
	sylvaPrompt.ActionText = "Seek Druidic Wisdom"
	sylvaPrompt.HoldDuration = 0.5
	sylvaPrompt.MaxActivationDistance = 14
	sylvaPrompt.RequiresLineOfSight = false
	sylvaPrompt.Parent = torso

	npcModel.Parent = wildsFolder

	----------------------------------------------------------------------
	-- 8. DUNGEON 1: SUNKEN CRYPT OF THE DRUIDS
	----------------------------------------------------------------------
	local cryptOrigin = Vector3.new(-6200, 10, -500)

	-- Megalithic Crypt Gateway Arch
	createPart(wildsFolder, "SunkenCryptArch", Vector3.new(14, 16, 4), CFrame.new(cryptOrigin + Vector3.new(0, 6, 0)), Color3.fromRGB(48, 52, 48), Enum.Material.Slate)
	createPart(wildsFolder, "CryptArchLintel", Vector3.new(16, 3, 5), CFrame.new(cryptOrigin + Vector3.new(0, 14.5, 0)), Color3.fromRGB(35, 40, 36), Enum.Material.Cobblestone)
	local cryptVeil = createPart(wildsFolder, "CryptVeil", Vector3.new(10, 12, 1), CFrame.new(cryptOrigin + Vector3.new(0, 6, 0)), Color3.fromRGB(40, 180, 80), Enum.Material.Neon, true, false)
	createLight(cryptVeil, Color3.fromRGB(40, 180, 80), 2.0, 16)

	-- 4 Elemental Rune Pillars (Sequence: Earth -> Water -> Flora -> Sun)
	local runeDefs = {
		{ name = "CryptRune_Earth", offset = Vector3.new(-7, 2, 8), color = Color3.fromRGB(120, 180, 60), label = "Earth Rune" },
		{ name = "CryptRune_Water", offset = Vector3.new(7, 2, 8), color = Color3.fromRGB(40, 120, 240), label = "Water Rune" },
		{ name = "CryptRune_Flora", offset = Vector3.new(-7, 2, -8), color = Color3.fromRGB(50, 220, 90), label = "Flora Rune" },
		{ name = "CryptRune_Sun", offset = Vector3.new(7, 2, -8), color = Color3.fromRGB(255, 210, 40), label = "Sun Rune" },
	}

	for _, rd in ipairs(runeDefs) do
		local pillar = createPart(wildsFolder, rd.name, Vector3.new(2.4, 8.0, 2.4), CFrame.new(cryptOrigin + rd.offset), Color3.fromRGB(55, 60, 56), Enum.Material.Slate)
		local band = createPart(wildsFolder, rd.name .. "_Band", Vector3.new(2.6, 1.2, 2.6), CFrame.new(cryptOrigin + rd.offset + Vector3.new(0, 1.5, 0)), rd.color, Enum.Material.Neon, true, false)
		createLight(band, rd.color, 1.8, 12)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Prompt_" .. rd.name
		prompt.ObjectText = rd.label
		prompt.ActionText = "Attune Elemental Seal"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = pillar
	end

	-- Boss Guardian: Ancient Ironwood Golem
	local golemModel = Instance.new("Model")
	golemModel.Name = "Guardian_DruidGolem_Model"
	local gCF = CFrame.new(-6200, 10, -700)
	local gTorso = createPart(golemModel, "Torso", Vector3.new(5.0, 6.0, 3.0), gCF * CFrame.new(0, 5.0, 0), Color3.fromRGB(50, 42, 34), Enum.Material.Wood)
	local gHead = createPart(golemModel, "Head", Vector3.new(2.5, 2.5, 2.5), gCF * CFrame.new(0, 9.0, 0), Color3.fromRGB(60, 65, 58), Enum.Material.Slate)
	createPart(golemModel, "GolemLimbs", Vector3.new(8.0, 5.0, 2.5), gCF * CFrame.new(0, 5.5, 0), Color3.fromRGB(45, 38, 30), Enum.Material.Wood)
	local gEyeL = createPart(golemModel, "EyeL", Vector3.new(0.4, 0.3, 0.2), gCF * CFrame.new(-0.6, 9.2, 1.3), Color3.fromRGB(76, 215, 80), Enum.Material.Neon)
	local gEyeR = createPart(golemModel, "EyeR", Vector3.new(0.4, 0.3, 0.2), gCF * CFrame.new(0.6, 9.2, 1.3), Color3.fromRGB(76, 215, 80), Enum.Material.Neon)
	createLight(gHead, Color3.fromRGB(76, 215, 80), 2.2, 14)

	local gBb = Instance.new("BillboardGui")
	gBb.Name = "BossHealthBar"
	gBb.Size = UDim2.new(0, 220, 0, 44)
	gBb.StudsOffset = Vector3.new(0, 4.0, 0)
	gBb.AlwaysOnTop = false
	gBb.MaxDistance = 45
	gBb.Parent = gHead

	local gTitle = Instance.new("TextLabel")
	gTitle.Size = UDim2.new(1, 0, 0, 22)
	gTitle.BackgroundTransparency = 1
	gTitle.Text = "Ancient Ironwood Golem"
	gTitle.TextColor3 = Color3.fromRGB(120, 255, 140)
	gTitle.Font = Enum.Font.GothamBold
	gTitle.TextSize = 14
	gTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	gTitle.TextStrokeTransparency = 0.2
	gTitle.Parent = gBb

	local gSub = Instance.new("TextLabel")
	gSub.Size = UDim2.new(1, 0, 0, 18)
	gSub.Position = UDim2.new(0, 0, 0, 20)
	gSub.BackgroundTransparency = 1
	gSub.Text = "Dungeon Boss • 250 HP"
	gSub.TextColor3 = Color3.fromRGB(220, 200, 160)
	gSub.Font = Enum.Font.Gotham
	gSub.TextSize = 11
	gSub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	gSub.Parent = gBb

	local gPrompt = Instance.new("ProximityPrompt")
	gPrompt.Name = "Prompt_Boss_DruidGolem"
	gPrompt.ObjectText = "Ancient Ironwood Golem"
	gPrompt.ActionText = "Strike Boss Guardian"
	gPrompt.HoldDuration = 0.2
	gPrompt.MaxActivationDistance = 18
	gPrompt.RequiresLineOfSight = false
	gPrompt.Parent = gTorso

	golemModel.Parent = wildsFolder

	-- Crypt Sarcophagus (Vault Reward)
	local sarcophagus = createPart(wildsFolder, "DruidSarcophagus", Vector3.new(7, 4.5, 12), CFrame.new(-6200, 13.5, -700), Color3.fromRGB(65, 70, 66), Enum.Material.Slate)
	createPart(wildsFolder, "SarcophagusTrim", Vector3.new(7.4, 0.8, 12.4), CFrame.new(-6200, 15.8, -700), Color3.fromRGB(76, 215, 80), Enum.Material.Neon, true, false)
	local sarcPrompt = Instance.new("ProximityPrompt")
	sarcPrompt.Name = "Prompt_CryptSarcophagus"
	sarcPrompt.ObjectText = "Ancient Druid Sarcophagus"
	sarcPrompt.ActionText = "Unlock Crypt Vault"
	sarcPrompt.HoldDuration = 1.0
	sarcPrompt.MaxActivationDistance = 14
	sarcPrompt.RequiresLineOfSight = false
	sarcPrompt.Parent = sarcophagus

	wildsFolder.Parent = worldFolder
	return wildsFolder
end

return WhisperingWildsBuilder