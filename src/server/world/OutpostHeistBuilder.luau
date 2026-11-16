--!strict
-- OutpostHeistBuilder.luau
-- Authoritative procedural construction for the connected Obsidian Outpost fortress environment
-- Features high-fidelity curtain walls with talus base & crenellations, twin gatehouses with blast doors,
-- courtyard infiltration with spiked abatis & cover, groined barrel-vaulted sentry corridor with laser tripwires,
-- security control room with mainframe terminal & phosphor CRT screen, massive circular vault blast door with gear teeth,
-- grand octagonal vault with sacred geometry mosaic & 8 fluted columns, Obsidian Chalice dais, and dual extraction routes.

local Players = game:GetService("Players")
local RelicMeshBuilder = require(script.Parent.RelicMeshBuilder)
local EnvironmentProps = require(script.Parent.EnvironmentProps)

local OutpostHeistBuilder = {}

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

local function createTorch(parent: Instance, cframe: CFrame, flameColor: Color3?): Model
	local model = Instance.new("Model")
	model.Name = "SconceTorch"

	local bracket = createPart(model, "Bracket", Vector3.new(0.5, 0.5, 1.4), cframe * CFrame.new(0, 0, 0.7), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
	local torchWood = createPart(model, "TorchWood", Vector3.new(0.4, 2.2, 0.4), cframe * CFrame.new(0, 0.8, 1.2), Color3.fromRGB(60, 40, 25), Enum.Material.Wood)
	local flame = createPart(model, "Flame", Vector3.new(0.8, 1.0, 0.8), cframe * CFrame.new(0, 2.0, 1.2), flameColor or Color3.fromRGB(255, 130, 40), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(flame, flameColor or Color3.fromRGB(255, 140, 50), 2.2, 16)

	model.Parent = parent
	return model
end

-- Helper: Constructs a fortified curtain wall with sloped talus base, machicolation corbels, and crenellations
local function buildFortifiedWall(
	parent: Instance,
	wallName: string,
	startPos: Vector3,
	endPos: Vector3,
	height: number,
	thickness: number
)
	local delta = endPos - startPos
	local length = delta.Magnitude
	local center = (startPos + endPos) / 2
	local forward = delta.Unit
	local up = Vector3.new(0, 1, 0)
	local right = forward:Cross(up)
	local baseCF = CFrame.fromMatrix(center, right, up, -forward)

	local wallColor = Color3.fromRGB(48, 48, 54)
	local stoneDark = Color3.fromRGB(36, 36, 42)
	local stoneCap = Color3.fromRGB(65, 65, 72)

	-- 1. Sloped Talus Foundation Plinth along exterior
	createPart(parent, wallName .. "_TalusBase", Vector3.new(thickness + 2.0, 3.5, length), baseCF * CFrame.new(0, 1.75, 0), stoneDark, Enum.Material.Slate)
	createPart(parent, wallName .. "_TalusLedge", Vector3.new(thickness + 0.8, 0.6, length), baseCF * CFrame.new(0, 3.8, 0), stoneCap, Enum.Material.Cobblestone)

	-- 2. Main Vertical Ashlar Curtain Wall
	local mainH = height - 4.0
	createPart(parent, wallName .. "_Curtain", Vector3.new(thickness, mainH, length), baseCF * CFrame.new(0, 4.0 + mainH / 2, 0), wallColor, Enum.Material.Slate)

	-- 3. Parapet Walkway (Chemin de Ronde) on interior side
	createPart(parent, wallName .. "_Walkway", Vector3.new(thickness + 3.0, 1.0, length), baseCF * CFrame.new(-1.0, height, 0), stoneCap, Enum.Material.Cobblestone)

	-- 4. Machicolation Corbels under outer parapet
	local corbelSpacing = 8.0
	local numCorbels = math.floor(length / corbelSpacing)
	for i = 1, numCorbels do
		local zOff = -length / 2 + (i - 0.5) * corbelSpacing
		createPart(parent, wallName .. "_Corbel_" .. tostring(i), Vector3.new(1.8, 1.6, 1.4), baseCF * CFrame.new(thickness / 2 + 0.6, height - 1.0, zOff), stoneDark, Enum.Material.Slate)
	end

	-- 5. Crenellated Parapet with Merlons and Embrasures
	local merlonW = 4.0
	local embrasureW = 3.0
	local unitW = merlonW + embrasureW
	local numUnits = math.floor(length / unitW)

	for i = 1, numUnits do
		local zCenter = -length / 2 + (i - 1) * unitW + merlonW / 2
		-- Merlon (solid raised parapet block)
		createPart(parent, wallName .. "_Merlon_" .. tostring(i), Vector3.new(1.4, 4.0, merlonW), baseCF * CFrame.new(thickness / 2 + 0.4, height + 2.5, zCenter), wallColor, Enum.Material.Slate)
		createPart(parent, wallName .. "_MerlonCap_" .. tostring(i), Vector3.new(1.8, 0.5, merlonW + 0.4), baseCF * CFrame.new(thickness / 2 + 0.4, height + 4.75, zCenter), stoneCap, Enum.Material.Cobblestone)

		-- Embrasure (lower opening between merlons)
		local zEmb = zCenter + merlonW / 2 + embrasureW / 2
		createPart(parent, wallName .. "_Embrasure_" .. tostring(i), Vector3.new(1.4, 1.5, embrasureW), baseCF * CFrame.new(thickness / 2 + 0.4, height + 1.25, zEmb), stoneDark, Enum.Material.Slate)
	end
end

-- Helper: Constructs an octagonal defensive corner bastion watchtower
local function buildBastionTower(parent: Instance, towerName: string, center: Vector3, height: number, radius: number): Model
	local model = Instance.new("Model")
	model.Name = towerName

	local towerColor = Color3.fromRGB(42, 42, 48)
	local trimColor = Color3.fromRGB(60, 60, 68)

	-- Stepped Foundation
	local step1 = createPart(model, "BaseStep1", Vector3.new(1.8, radius * 2.6, radius * 2.6), CFrame.new(center + Vector3.new(0, 0.9, 0)), Color3.fromRGB(30, 30, 35), Enum.Material.Slate, true, true, Enum.PartType.Cylinder)
	step1.CFrame = CFrame.new(center + Vector3.new(0, 0.9, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local step2 = createPart(model, "BaseStep2", Vector3.new(1.8, radius * 2.3, radius * 2.3), CFrame.new(center + Vector3.new(0, 2.7, 0)), trimColor, Enum.Material.Cobblestone, true, true, Enum.PartType.Cylinder)
	step2.CFrame = CFrame.new(center + Vector3.new(0, 2.7, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Main Tower Shaft
	local shaftH = height - 6.0
	local shaft = createPart(model, "Shaft", Vector3.new(shaftH, radius * 2, radius * 2), CFrame.new(center + Vector3.new(0, 3.6 + shaftH / 2, 0)), towerColor, Enum.Material.Slate, true, true, Enum.PartType.Cylinder)
	shaft.CFrame = CFrame.new(center + Vector3.new(0, 3.6 + shaftH / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Corbelled Overhanging Battlement Platform
	local plat = createPart(model, "Platform", Vector3.new(1.8, radius * 2.5, radius * 2.5), CFrame.new(center + Vector3.new(0, height - 1.5, 0)), trimColor, Enum.Material.Cobblestone, true, true, Enum.PartType.Cylinder)
	plat.CFrame = CFrame.new(center + Vector3.new(0, height - 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Battlement Turret Ring
	local ring = createPart(model, "BattlementWall", Vector3.new(3.6, radius * 2.4, radius * 2.4), CFrame.new(center + Vector3.new(0, height + 1.2, 0)), towerColor, Enum.Material.Slate, true, true, Enum.PartType.Cylinder)
	ring.CFrame = CFrame.new(center + Vector3.new(0, height + 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Sentry Torch on Top
	createTorch(model, CFrame.new(center + Vector3.new(0, height + 2.0, 0)), Color3.fromRGB(255, 120, 30))

	model.Parent = parent
	return model
end

function OutpostHeistBuilder.Build(worldFolder: Folder, heistService: any): Folder
	local heistFolder = Instance.new("Folder")
	heistFolder.Name = "ObsidianOutpost"
	heistFolder.Parent = worldFolder

	-- Return Travel Gate Marker (Entrance from Southern Causeway at Z = 3000)
	local returnGate = createPart(heistFolder, "ReturnPad_Market", Vector3.new(14, 0.6, 8), CFrame.new(0, 14.3, 2985), Color3.fromRGB(80, 180, 255), Enum.Material.Neon, true, false)
	local retPrompt = Instance.new("ProximityPrompt")
	retPrompt.Name = "Prompt_ReturnMarket_Vault"
	retPrompt.ObjectText = "Forgotten Market Portal"
	retPrompt.ActionText = "Return to Market Settlement"
	retPrompt.HoldDuration = 0.5
	retPrompt.MaxActivationDistance = 14
	retPrompt.RequiresLineOfSight = false
	retPrompt.Parent = returnGate

	local origin = Vector3.new(500, 50, 500)

	----------------------------------------------------------------------
	-- 1. CITADEL FOUNDATION, FORTIFIED CURTAIN WALLS & BASTIONS
	----------------------------------------------------------------------
	-- Massive Stepped Basalt Foundation
	createPart(heistFolder, "CitadelFloor", Vector3.new(204, 4, 204), CFrame.new(origin), Color3.fromRGB(28, 28, 34), Enum.Material.Slate)
	createPart(heistFolder, "CitadelPlinthEdge", Vector3.new(208, 1.2, 208), CFrame.new(origin + Vector3.new(0, 1.8, 0)), Color3.fromRGB(45, 45, 52), Enum.Material.Basalt)

	local wallH = 28
	local wallThick = 6

	-- North Fortress Curtain Wall
	buildFortifiedWall(heistFolder, "NorthWall", origin + Vector3.new(-95, 2, 95), origin + Vector3.new(95, 2, 95), wallH, wallThick)
	-- West Fortress Curtain Wall
	buildFortifiedWall(heistFolder, "WestWall", origin + Vector3.new(-95, 2, -95), origin + Vector3.new(-95, 2, 95), wallH, wallThick)
	-- East Fortress Curtain Wall
	buildFortifiedWall(heistFolder, "EastWall", origin + Vector3.new(95, 2, -95), origin + Vector3.new(95, 2, 95), wallH, wallThick)

	-- South Breached Wall with Gatehouse Opening
	buildFortifiedWall(heistFolder, "SouthWallL", origin + Vector3.new(-95, 2, -95), origin + Vector3.new(-20, 2, -95), wallH, wallThick)
	buildFortifiedWall(heistFolder, "SouthWallR", origin + Vector3.new(20, 2, -95), origin + Vector3.new(95, 2, -95), wallH, wallThick)

	-- 4 Corner Defensive Bastions
	buildBastionTower(heistFolder, "BastionNW", origin + Vector3.new(-95, 2, 95), 36, 9)
	buildBastionTower(heistFolder, "BastionNE", origin + Vector3.new(95, 2, 95), 36, 9)
	buildBastionTower(heistFolder, "BastionSW", origin + Vector3.new(-95, 2, -95), 36, 9)
	buildBastionTower(heistFolder, "BastionSE", origin + Vector3.new(95, 2, -95), 36, 9)

	-- Bastion Searchlight Illuminators
	local function createSearchlight(name: string, pos: Vector3, lookTarget: Vector3)
		local base = createPart(heistFolder, name .. "_Mount", Vector3.new(2, 3, 2), CFrame.new(pos), Color3.fromRGB(40, 42, 48), Enum.Material.Metal)
		local headCF = CFrame.lookAt(pos + Vector3.new(0, 2, 0), lookTarget)
		local lamp = createPart(heistFolder, name .. "_Housing", Vector3.new(2.4, 2.4, 3.2), headCF, Color3.fromRGB(30, 32, 36), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
		lamp.CFrame = headCF * CFrame.Angles(0, 0, math.rad(90))
		local lens = createPart(heistFolder, name .. "_Lens", Vector3.new(0.4, 2.2, 2.2), headCF * CFrame.new(0, 0, -1.5), Color3.fromRGB(255, 245, 180), Enum.Material.Neon, true, false, Enum.PartType.Ball)
		createLight(lens, Color3.fromRGB(255, 240, 170), 3.0, 32)

		-- Translucent Visual Light Cone Beam
		local beamDist = (lookTarget - pos).Magnitude
		local beamMid = pos + (lookTarget - pos).Unit * (beamDist * 0.4)
		local cone = createPart(heistFolder, name .. "_BeamCone", Vector3.new(3.5, 3.5, beamDist * 0.7), CFrame.lookAt(beamMid, lookTarget), Color3.fromRGB(255, 250, 200), Enum.Material.Glass, true, false)
		cone.Transparency = 0.88
	end

	createSearchlight("Searchlight_SW", origin + Vector3.new(-95, 38, -95), origin + Vector3.new(-15, 2, -55))
	createSearchlight("Searchlight_SE", origin + Vector3.new(95, 38, -95), origin + Vector3.new(15, 2, -55))

	----------------------------------------------------------------------
	-- 2. MASSIVE TWIN GATEHOUSES & REINFORCED IRON BLAST GATE
	----------------------------------------------------------------------
	local gateOrigin = origin + Vector3.new(0, 0, -95)

	-- Fortified Perimeter Dry Moat Trench & Drawbridge
	createPart(heistFolder, "FortressMoatFloor", Vector3.new(190, 2, 18), CFrame.new(origin + Vector3.new(0, -6, -104)), Color3.fromRGB(20, 20, 24), Enum.Material.Basalt)
	createPart(heistFolder, "FortressMoatWallN", Vector3.new(190, 8, 2), CFrame.new(origin + Vector3.new(0, -2, -96)), Color3.fromRGB(35, 35, 40), Enum.Material.Slate)
	createPart(heistFolder, "FortressMoatWallS", Vector3.new(190, 8, 2), CFrame.new(origin + Vector3.new(0, -2, -112)), Color3.fromRGB(35, 35, 40), Enum.Material.Slate)

	-- Heavy Iron-Reinforced Oak Drawbridge spanning Moat
	createPart(heistFolder, "DrawbridgeDeck", Vector3.new(14, 1.4, 20), CFrame.new(origin + Vector3.new(0, 1.5, -104)), Color3.fromRGB(65, 45, 28), Enum.Material.WoodPlanks)
	createPart(heistFolder, "DrawbridgeBeamL", Vector3.new(1.0, 1.6, 20), CFrame.new(origin + Vector3.new(-6.8, 1.6, -104)), Color3.fromRGB(45, 48, 54), Enum.Material.Metal)
	createPart(heistFolder, "DrawbridgeBeamR", Vector3.new(1.0, 1.6, 20), CFrame.new(origin + Vector3.new(6.8, 1.6, -104)), Color3.fromRGB(45, 48, 54), Enum.Material.Metal)

	-- Massive Suspension Chains
	createPart(heistFolder, "BridgeChainL", Vector3.new(0.4, 18, 0.4), (CFrame.new(origin + Vector3.new(-6.8, 10, -101))) * CFrame.Angles(math.rad(-35), 0, 0), Color3.fromRGB(65, 68, 75), Enum.Material.Metal)
	createPart(heistFolder, "BridgeChainR", Vector3.new(0.4, 18, 0.4), (CFrame.new(origin + Vector3.new(6.8, 10, -101))) * CFrame.Angles(math.rad(-35), 0, 0), Color3.fromRGB(65, 68, 75), Enum.Material.Metal)

	-- Left and Right Gatehouses
	createPart(heistFolder, "GatehouseL", Vector3.new(16, wallH + 4, 16), CFrame.new(gateOrigin + Vector3.new(-18, (wallH + 4) / 2, 0)), Color3.fromRGB(38, 38, 44), Enum.Material.Slate)
	createPart(heistFolder, "GatehouseR", Vector3.new(16, wallH + 4, 16), CFrame.new(gateOrigin + Vector3.new(18, (wallH + 4) / 2, 0)), Color3.fromRGB(38, 38, 44), Enum.Material.Slate)

	-- Arched Gate Arch & Carved Lintel
	createPart(heistFolder, "GateArchLintel", Vector3.new(40, 6, 12), CFrame.new(gateOrigin + Vector3.new(0, wallH + 2, 0)), Color3.fromRGB(48, 48, 55), Enum.Material.Slate)
	createPart(heistFolder, "GateKeystone", Vector3.new(5, 5, 14), CFrame.new(gateOrigin + Vector3.new(0, wallH + 3, 0)), Color3.fromRGB(65, 65, 75), Enum.Material.Cobblestone)

	-- Lowered Heavy Iron Portcullis with Spikes
	for barX = -8, 8, 2 do
		createPart(heistFolder, "PortcullisBar_" .. tostring(barX), Vector3.new(0.6, 20, 0.6), CFrame.new(gateOrigin + Vector3.new(barX, 12, 0)), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
		-- Spiked tooth at bottom
		createPart(heistFolder, "PortcullisSpike_" .. tostring(barX), Vector3.new(0.4, 1.2, 0.4), (CFrame.new(gateOrigin + Vector3.new(barX, 2.6, 0))) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(60, 62, 68), Enum.Material.Metal)
	end
	createPart(heistFolder, "PortcullisCrossBar1", Vector3.new(20, 0.6, 0.8), CFrame.new(gateOrigin + Vector3.new(0, 8, 0)), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
	createPart(heistFolder, "PortcullisCrossBar2", Vector3.new(20, 0.6, 0.8), CFrame.new(gateOrigin + Vector3.new(0, 16, 0)), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)

	-- Reinforced Iron Blast Doors (Slightly cracked open for infiltration path)
	createPart(heistFolder, "BlastDoorL", Vector3.new(9, 18, 1.4), (CFrame.new(gateOrigin + Vector3.new(-6.5, 9, 3))) * CFrame.Angles(0, math.rad(-25), 0), Color3.fromRGB(50, 52, 60), Enum.Material.DiamondPlate)
	createPart(heistFolder, "BlastDoorR", Vector3.new(9, 18, 1.4), (CFrame.new(gateOrigin + Vector3.new(6.5, 9, 3))) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(50, 52, 60), Enum.Material.DiamondPlate)

	----------------------------------------------------------------------
	-- 3. COURTYARD INFILTRATION ZONE & DEFENSIVE TACTICAL COVER
	----------------------------------------------------------------------
	local courtCenter = origin + Vector3.new(0, 0, -55)

	-- Tactical Spiked Abatis Barricades & Heavy Sandbag Parapets
	EnvironmentProps.CreateSpikedAbatis(heistFolder, CFrame.new(courtCenter + Vector3.new(-12, 0, -10)), 14)
	EnvironmentProps.CreateSpikedAbatis(heistFolder, CFrame.new(courtCenter + Vector3.new(14, 0, 5)), 12)

	-- Sandbag Tactical Parapets behind barricades
	createPart(heistFolder, "SandbagWallL", Vector3.new(12, 2.8, 2.2), CFrame.new(courtCenter + Vector3.new(-12, 1.4, -7)), Color3.fromRGB(165, 145, 120), Enum.Material.Fabric)
	createPart(heistFolder, "SandbagWallR", Vector3.new(10, 2.8, 2.2), CFrame.new(courtCenter + Vector3.new(14, 1.4, 8)), Color3.fromRGB(165, 145, 120), Enum.Material.Fabric)

	-- Weathered Stone Pillars & Rubble Heaps
	createPart(heistFolder, "RubblePillarL", Vector3.new(5, 14, 5), CFrame.new(courtCenter + Vector3.new(-18, 7, -5)), Color3.fromRGB(50, 50, 56), Enum.Material.Slate)
	createPart(heistFolder, "RubbleCapL", Vector3.new(6, 1.2, 6), CFrame.new(courtCenter + Vector3.new(-18, 14.6, -5)), Color3.fromRGB(65, 65, 72), Enum.Material.Cobblestone)

	createPart(heistFolder, "RubblePillarR", Vector3.new(5, 10, 5), CFrame.new(courtCenter + Vector3.new(18, 5, -5)), Color3.fromRGB(50, 50, 56), Enum.Material.Slate)
	createPart(heistFolder, "FallenCapitalR", Vector3.new(4, 2, 4), (CFrame.new(courtCenter + Vector3.new(19, 1, -2))) * CFrame.Angles(math.rad(15), math.rad(20), 0), Color3.fromRGB(65, 65, 72), Enum.Material.Marble)

	-- Broken Heavy Ballista Wreckage in Courtyard Corner
	local balCF = CFrame.new(courtCenter + Vector3.new(-24, 0, 12)) * CFrame.Angles(0, math.rad(35), 0)
	createPart(heistFolder, "BallistaBase", Vector3.new(4.5, 1.4, 6.0), balCF * CFrame.new(0, 0.7, 0), Color3.fromRGB(60, 42, 26), Enum.Material.WoodPlanks)
	createPart(heistFolder, "BallistaBowArmL", Vector3.new(0.6, 1.0, 5.0), (balCF * CFrame.new(-2.2, 1.8, 1.0)) * CFrame.Angles(0, math.rad(-25), 0), Color3.fromRGB(45, 30, 18), Enum.Material.Wood)
	createPart(heistFolder, "BallistaBowArmR", Vector3.new(0.6, 1.0, 5.0), (balCF * CFrame.new(2.2, 1.8, 1.0)) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(45, 30, 18), Enum.Material.Wood)
	createPart(heistFolder, "BallistaBolt", Vector3.new(0.3, 0.3, 7.0), balCF * CFrame.new(0, 2.0, 0), Color3.fromRGB(80, 80, 85), Enum.Material.Metal)

	-- Military Munitions & Supply Crates
	createPart(heistFolder, "SupplyCrate1", Vector3.new(4.5, 4.5, 4.5), CFrame.new(courtCenter + Vector3.new(-8, 2.25, 14)), Color3.fromRGB(85, 58, 36), Enum.Material.WoodPlanks)
	createPart(heistFolder, "SupplyCrate2", Vector3.new(3.8, 3.8, 3.8), (CFrame.new(courtCenter + Vector3.new(-7.5, 6.4, 14))) * CFrame.Angles(0, math.rad(12), 0), Color3.fromRGB(75, 52, 32), Enum.Material.WoodPlanks)
	createPart(heistFolder, "IronMunitionsBox", Vector3.new(3.2, 2.2, 4.2), CFrame.new(courtCenter + Vector3.new(8, 1.1, 14)), Color3.fromRGB(48, 50, 56), Enum.Material.Metal)

	-- Iron Courtyard Braziers
	EnvironmentProps.CreateStoneBrazier(heistFolder, CFrame.new(origin + Vector3.new(-16, 2, -72)), Color3.fromRGB(255, 130, 40))
	EnvironmentProps.CreateStoneBrazier(heistFolder, CFrame.new(origin + Vector3.new(16, 2, -72)), Color3.fromRGB(255, 130, 40))

	----------------------------------------------------------------------
	-- 4. FORTIFIED SENTRY CORRIDOR & LASER TRIPWIRE GALLERY
	----------------------------------------------------------------------
	-- Heavy Stone Groined Barrel-Vaulted Corridor Walls
	createPart(heistFolder, "CorridorWallLeft", Vector3.new(5, 20, 56), CFrame.new(origin + Vector3.new(-13.5, 10, -35)), Color3.fromRGB(38, 38, 44), Enum.Material.Slate)
	createPart(heistFolder, "CorridorWallRight", Vector3.new(5, 20, 56), CFrame.new(origin + Vector3.new(13.5, 10, -35)), Color3.fromRGB(38, 38, 44), Enum.Material.Slate)
	createPart(heistFolder, "CorridorFloorSlab", Vector3.new(24, 2, 56), CFrame.new(origin + Vector3.new(0, 1, -35)), Color3.fromRGB(32, 32, 38), Enum.Material.Cobblestone)

	-- Transverse Vault Arch Ribs & Carved Corbels
	for zOff = -55, -15, 10 do
		createPart(heistFolder, "CeilingRib_" .. tostring(zOff), Vector3.new(26, 3, 3.5), CFrame.new(origin + Vector3.new(0, 19, zOff)), Color3.fromRGB(55, 55, 62), Enum.Material.Slate)
		-- Left & right supporting corbels
		createPart(heistFolder, "RibCorbelL_" .. tostring(zOff), Vector3.new(2.4, 2.4, 3.5), CFrame.new(origin + Vector3.new(-10.5, 17, zOff)), Color3.fromRGB(65, 65, 72), Enum.Material.Slate)
		createPart(heistFolder, "RibCorbelR_" .. tostring(zOff), Vector3.new(2.4, 2.4, 3.5), CFrame.new(origin + Vector3.new(10.5, 17, zOff)), Color3.fromRGB(65, 65, 72), Enum.Material.Slate)
	end

	-- Wall Sconce Torches along Corridor
	createTorch(heistFolder, CFrame.new(origin + Vector3.new(-10.5, 10, -50)), Color3.fromRGB(255, 150, 60))
	createTorch(heistFolder, CFrame.new(origin + Vector3.new(10.5, 10, -50)), Color3.fromRGB(255, 150, 60))
	createTorch(heistFolder, CFrame.new(origin + Vector3.new(-10.5, 10, -20)), Color3.fromRGB(255, 150, 60))
	createTorch(heistFolder, CFrame.new(origin + Vector3.new(10.5, 10, -20)), Color3.fromRGB(255, 150, 60))

	-- INDUSTRIAL LASER TRIPWIRES
	local function createLaserTripwire(name: string, cframe: CFrame)
		-- Bronze/Iron Industrial Emitter Pods
		createPart(heistFolder, name .. "_EmitterL", Vector3.new(1.8, 2.6, 1.8), cframe * CFrame.new(-11, 0, 0), Color3.fromRGB(180, 120, 40), Enum.Material.Metal)
		createPart(heistFolder, name .. "_EmitterR", Vector3.new(1.8, 2.6, 1.8), cframe * CFrame.new(11, 0, 0), Color3.fromRGB(180, 120, 40), Enum.Material.Metal)

		-- Warning Indicator LEDs atop emitters
		local ledL = createPart(heistFolder, name .. "_LED_L", Vector3.new(0.6, 0.6, 0.6), cframe * CFrame.new(-11, 1.6, 0), Color3.fromRGB(255, 60, 20), Enum.Material.Neon, true, false, Enum.PartType.Ball)
		local ledR = createPart(heistFolder, name .. "_LED_R", Vector3.new(0.6, 0.6, 0.6), cframe * CFrame.new(11, 1.6, 0), Color3.fromRGB(255, 60, 20), Enum.Material.Neon, true, false, Enum.PartType.Ball)
		createLight(ledL, Color3.fromRGB(255, 60, 20), 1.6, 8)
		createLight(ledR, Color3.fromRGB(255, 60, 20), 1.6, 8)

		-- Main High-Frequency Laser Beam
		local laser = createPart(heistFolder, name, Vector3.new(22, 0.45, 0.45), cframe, Color3.fromRGB(255, 20, 20), Enum.Material.Neon, true, false)
		createLight(laser, Color3.fromRGB(255, 0, 0), 2.8, 12)

		-- Touched Debounced Alarm Escallation
		local lastTrigger = 0
		laser.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if player and (os.clock() - lastTrigger > 2) then
				lastTrigger = os.clock()
				heistService.TriggerAlarm(player, 25, "Laser Tripwire Tripped!")
			end
		end)
	end

	createLaserTripwire("LaserTripwire_1", CFrame.new(origin + Vector3.new(0, 3.5, -45)))
	createLaserTripwire("LaserTripwire_2", CFrame.new(origin + Vector3.new(0, 4.0, -25)))

	----------------------------------------------------------------------
	-- 5. SECURITY CONTROL ROOM & HACKABLE MAINFRAME TERMINAL
	----------------------------------------------------------------------
	local secRoomCenter = origin + Vector3.new(32, 0, -10)
	createPart(heistFolder, "SecRoomFloor", Vector3.new(30, 2, 26), CFrame.new(secRoomCenter + Vector3.new(0, 1, 0)), Color3.fromRGB(35, 35, 42), Enum.Material.Slate)
	createPart(heistFolder, "SecRoomWallE", Vector3.new(4, 18, 26), CFrame.new(secRoomCenter + Vector3.new(15, 9, 0)), Color3.fromRGB(30, 30, 36), Enum.Material.Slate)
	createPart(heistFolder, "SecRoomWallN", Vector3.new(30, 18, 4), CFrame.new(secRoomCenter + Vector3.new(0, 9, 13)), Color3.fromRGB(30, 30, 36), Enum.Material.Slate)
	createPart(heistFolder, "SecRoomWallS", Vector3.new(30, 18, 4), CFrame.new(secRoomCenter + Vector3.new(0, 9, -13)), Color3.fromRGB(30, 30, 36), Enum.Material.Slate)

	-- Wire Conduits along North Wall
	createPart(heistFolder, "ConduitPipe1", Vector3.new(28, 0.4, 0.4), CFrame.new(secRoomCenter + Vector3.new(0, 8, 10.8)), Color3.fromRGB(80, 80, 85), Enum.Material.Metal)
	createPart(heistFolder, "ConduitPipe2", Vector3.new(28, 0.4, 0.4), CFrame.new(secRoomCenter + Vector3.new(0, 7.2, 10.8)), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)

	-- Server Rack Cabinets with Blinking Blades
	local rackCF = CFrame.new(secRoomCenter + Vector3.new(10, 0, 0))
	createPart(heistFolder, "ServerRackBody", Vector3.new(4, 12, 16), rackCF * CFrame.new(0, 6, 0), Color3.fromRGB(24, 26, 30), Enum.Material.Metal)
	for r = 1, 4 do
		local bladeY = 3.0 + (r - 1) * 2.5
		createPart(heistFolder, "BladeUnit_" .. tostring(r), Vector3.new(3.8, 1.8, 15.6), rackCF * CFrame.new(-0.2, bladeY, 0), Color3.fromRGB(38, 40, 46), Enum.Material.Metal)
		-- Green / Amber Status LEDs
		createPart(heistFolder, "BladeLED_G_" .. tostring(r), Vector3.new(0.3, 0.4, 1.2), rackCF * CFrame.new(-2.1, bladeY + 0.4, -4), Color3.fromRGB(0, 230, 118), Enum.Material.Neon)
		createPart(heistFolder, "BladeLED_A_" .. tostring(r), Vector3.new(0.3, 0.4, 1.2), rackCF * CFrame.new(-2.1, bladeY + 0.4, -2), Color3.fromRGB(255, 179, 0), Enum.Material.Neon)
	end

	-- Master High-Voltage Breaker Box & Hazard Warning Strobe
	local breakerCF = CFrame.new(secRoomCenter + Vector3.new(-8, 7, -11))
	createPart(heistFolder, "BreakerBoxHousing", Vector3.new(3.6, 5.0, 1.2), breakerCF, Color3.fromRGB(60, 62, 68), Enum.Material.Metal)
	createPart(heistFolder, "BreakerStripe", Vector3.new(3.4, 0.4, 1.25), breakerCF * CFrame.new(0, 1.8, 0), Color3.fromRGB(255, 193, 7), Enum.Material.Neon)
	createPart(heistFolder, "BreakerHandle", Vector3.new(0.4, 1.8, 0.8), breakerCF * CFrame.new(0.8, -0.2, 0.4) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(220, 40, 40), Enum.Material.Metal)
	local breakerStrobe = createPart(heistFolder, "BreakerStrobe", Vector3.new(0.6, 0.6, 0.6), breakerCF * CFrame.new(0, 2.8, 0), Color3.fromRGB(255, 200, 0), Enum.Material.Neon, false, false, Enum.PartType.Ball)
	createLight(breakerStrobe, Color3.fromRGB(255, 200, 0), 1.6, 10)

	-- Guard Armor & Weapon Locker on West Wall
	local lockerCF = CFrame.new(secRoomCenter + Vector3.new(-12, 0, 0))
	createPart(heistFolder, "GuardLocker", Vector3.new(1.8, 10.0, 8.0), lockerCF * CFrame.new(0, 5.0, 0), Color3.fromRGB(48, 50, 56), Enum.Material.DiamondPlate)
	createPart(heistFolder, "LockerHandle1", Vector3.new(0.2, 1.2, 0.2), lockerCF * CFrame.new(0.95, 5.0, -1.8), Color3.fromRGB(215, 170, 50), Enum.Material.Metal)
	createPart(heistFolder, "LockerHandle2", Vector3.new(0.2, 1.2, 0.2), lockerCF * CFrame.new(0.95, 5.0, 1.8), Color3.fromRGB(215, 170, 50), Enum.Material.Metal)

	-- Security Console Desk Workstation with Auxiliary Surveillance Screens
	local termDesk = createPart(heistFolder, "SecurityConsoleDesk", Vector3.new(12, 3.6, 4.5), CFrame.new(secRoomCenter + Vector3.new(0, 1.8, 8)), Color3.fromRGB(42, 46, 52), Enum.Material.Metal)
	createPart(heistFolder, "ConsoleKeyboardPanel", Vector3.new(8, 0.4, 2.2), (CFrame.new(secRoomCenter + Vector3.new(0, 3.8, 7.2))) * CFrame.Angles(math.rad(15), 0, 0), Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic)

	-- Phosphor CRT Monitor Screen (Main Hackable Terminal)
	local termScreen = createPart(heistFolder, "SecurityConsoleScreen", Vector3.new(5.5, 3.4, 0.5), CFrame.new(secRoomCenter + Vector3.new(0, 5.8, 9.2)), Color3.fromRGB(0, 230, 118), Enum.Material.Neon, true, false)
	createLight(termScreen, Color3.fromRGB(0, 230, 118), 2.2, 14)

	-- Auxiliary CCTV Surveillance Feeds (Gatehouse & Vault Cam)
	local camL = createPart(heistFolder, "CCTV_Screen_L", Vector3.new(2.4, 2.0, 0.4), (CFrame.new(secRoomCenter + Vector3.new(-4.2, 5.6, 8.8))) * CFrame.Angles(0, math.rad(15), 0), Color3.fromRGB(30, 140, 220), Enum.Material.Neon, false, false)
	local camR = createPart(heistFolder, "CCTV_Screen_R", Vector3.new(2.4, 2.0, 0.4), (CFrame.new(secRoomCenter + Vector3.new(4.2, 5.6, 8.8))) * CFrame.Angles(0, math.rad(-15), 0), Color3.fromRGB(30, 140, 220), Enum.Material.Neon, false, false)

	-- Screen Hood / Shroud
	createPart(heistFolder, "ScreenHood", Vector3.new(6.0, 3.8, 1.8), CFrame.new(secRoomCenter + Vector3.new(0, 5.8, 9.5)), Color3.fromRGB(35, 38, 42), Enum.Material.Metal)

	-- Terminal Proximity Prompt (Preserves exact name for WorldBuilder!)
	local termPrompt = Instance.new("ProximityPrompt")
	termPrompt.Name = "Prompt_HackTerminal"
	termPrompt.ObjectText = "Security Terminal"
	termPrompt.ActionText = "Override Laser Defenses (20s)"
	termPrompt.HoldDuration = 1.0
	termPrompt.MaxActivationDistance = 14
	termPrompt.RequiresLineOfSight = false
	termPrompt.Parent = termDesk

	-- Security Rolling Caster Chair
	local chairCF = CFrame.new(secRoomCenter + Vector3.new(0, 0, 3.5))
	createPart(heistFolder, "ChairPedestal", Vector3.new(1.8, 0.4, 1.8), chairCF * CFrame.new(0, 0.4, 0), Color3.fromRGB(30, 30, 35), Enum.Material.Metal)
	createPart(heistFolder, "ChairStem", Vector3.new(0.5, 2.0, 0.5), chairCF * CFrame.new(0, 1.4, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Metal)
	createPart(heistFolder, "ChairSeat", Vector3.new(2.4, 0.6, 2.4), chairCF * CFrame.new(0, 2.6, 0), Color3.fromRGB(20, 20, 22), Enum.Material.Fabric)
	createPart(heistFolder, "ChairBack", Vector3.new(2.4, 2.6, 0.5), chairCF * CFrame.new(0, 4.0, -1.0), Color3.fromRGB(20, 20, 22), Enum.Material.Fabric)

	----------------------------------------------------------------------
	-- 6. STEALTH FLANK TUNNEL (WEST SIDE MAINTENANCE DUCT)
	----------------------------------------------------------------------
	createPart(heistFolder, "FlankWallL", Vector3.new(4, 16, 42), CFrame.new(origin + Vector3.new(-34, 8, -10)), Color3.fromRGB(30, 30, 36), Enum.Material.Slate)
	createPart(heistFolder, "FlankFloor", Vector3.new(18, 2, 42), CFrame.new(origin + Vector3.new(-25, 1, -10)), Color3.fromRGB(36, 36, 42), Enum.Material.Cobblestone)
	createPart(heistFolder, "FlankCatwalk", Vector3.new(8, 0.5, 40), CFrame.new(origin + Vector3.new(-25, 2.2, -10)), Color3.fromRGB(75, 50, 30), Enum.Material.WoodPlanks)

	-- Industrial Rusty Steam Pipes & Valve Wheels
	createPart(heistFolder, "SteamPipeMain", Vector3.new(0.8, 0.8, 38), CFrame.new(origin + Vector3.new(-31, 10, -10)), Color3.fromRGB(110, 60, 40), Enum.Material.Metal, true, true, Enum.PartType.Cylinder)
	local valveWheel = createPart(heistFolder, "PipeValveWheel", Vector3.new(0.2, 1.4, 1.4), (CFrame.new(origin + Vector3.new(-30.5, 10, -5))) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(215, 50, 40), Enum.Material.Metal, false, false, Enum.PartType.Cylinder)

	-- Broken Drainage Grate Entrance
	createPart(heistFolder, "GrateFrame", Vector3.new(8, 8, 1), CFrame.new(origin + Vector3.new(-25, 5, -31)), Color3.fromRGB(45, 45, 50), Enum.Material.Metal)
	createPart(heistFolder, "BentBar1", Vector3.new(0.4, 7, 0.4), (CFrame.new(origin + Vector3.new(-27, 5, -31))) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(55, 55, 60), Enum.Material.Metal)
	createPart(heistFolder, "BentBar2", Vector3.new(0.4, 7, 0.4), (CFrame.new(origin + Vector3.new(-23, 5, -31))) * CFrame.Angles(0, 0, math.rad(-20)), Color3.fromRGB(55, 55, 60), Enum.Material.Metal)

	local flankLight = createPart(heistFolder, "FlankLightNode", Vector3.new(0.8, 0.8, 0.8), CFrame.new(origin + Vector3.new(-25, 12, -10)), Color3.fromRGB(76, 175, 80), Enum.Material.Neon)
	createLight(flankLight, Color3.fromRGB(76, 175, 80), 2.2, 16)

	----------------------------------------------------------------------
	-- 7. VAULT ANTECHAMBER & MASSIVE CIRCULAR BLAST DOOR
	----------------------------------------------------------------------
	local anteOrigin = origin + Vector3.new(0, 0, 18)
	createPart(heistFolder, "AnteWallL", Vector3.new(5, 22, 28), CFrame.new(anteOrigin + Vector3.new(-19, 11, 0)), Color3.fromRGB(36, 36, 42), Enum.Material.Slate)
	createPart(heistFolder, "AnteWallR", Vector3.new(5, 22, 28), CFrame.new(anteOrigin + Vector3.new(19, 11, 0)), Color3.fromRGB(36, 36, 42), Enum.Material.Slate)
	createPart(heistFolder, "AnteFloor", Vector3.new(34, 2, 28), CFrame.new(anteOrigin + Vector3.new(0, 1, 0)), Color3.fromRGB(28, 28, 34), Enum.Material.Marble)

	-- Reinforced Vault Bulkhead Wall with Hazard Chevron Striping
	createPart(heistFolder, "VaultDoorWall", Vector3.new(38, 22, 5), CFrame.new(anteOrigin + Vector3.new(0, 11, 14)), Color3.fromRGB(24, 26, 30), Enum.Material.Metal)
	-- Industrial Caution Stripes
	createPart(heistFolder, "CautionStripeUpper", Vector3.new(38, 1.2, 5.2), CFrame.new(anteOrigin + Vector3.new(0, 19, 14)), Color3.fromRGB(255, 193, 7), Enum.Material.Neon)
	createPart(heistFolder, "CautionStripeLower", Vector3.new(38, 1.2, 5.2), CFrame.new(anteOrigin + Vector3.new(0, 3, 14)), Color3.fromRGB(255, 193, 7), Enum.Material.Neon)

	-- Massive Circular Vault Door (Rotated open to allow infiltration into vault chamber)
	local vDoorCenter = anteOrigin + Vector3.new(0, 10, 14)

	-- Heavy Outer Door Frame Rim
	local frameRim = createPart(heistFolder, "VaultDoorOuterRim", Vector3.new(1.8, 18, 18), CFrame.new(vDoorCenter), Color3.fromRGB(48, 50, 56), Enum.Material.Metal, true, true, Enum.PartType.Cylinder)
	frameRim.CFrame = CFrame.new(vDoorCenter) * CFrame.Angles(0, 0, math.rad(90))

	-- Circular Blast Door (Ajar, swung open 40 degrees)
	local doorSwingCF = CFrame.new(vDoorCenter + Vector3.new(-8, 0, 0)) * CFrame.Angles(0, math.rad(-40), 0) * CFrame.new(8, 0, 0)

	local doorBody = createPart(heistFolder, "VaultDoorHingedL", Vector3.new(1.6, 16, 16), doorSwingCF, Color3.fromRGB(55, 60, 70), Enum.Material.DiamondPlate, true, true, Enum.PartType.Cylinder)
	doorBody.CFrame = doorSwingCF * CFrame.Angles(0, 0, math.rad(90))

	-- Radial Locking Lugs & Mechanical Gear Teeth on Door Rim
	for lugA = 0, 315, 45 do
		local rad = math.rad(lugA)
		local lugCF = doorSwingCF * CFrame.new(math.cos(rad) * 7.2, math.sin(rad) * 7.2, 0)
		createPart(heistFolder, "LockingLug_" .. tostring(lugA), Vector3.new(1.4, 1.8, 1.4), lugCF, Color3.fromRGB(215, 170, 50), Enum.Material.Metal)
	end

	-- Central Brass Vault Locking Wheel
	local wheelHub = createPart(heistFolder, "VaultWheelHub", Vector3.new(0.8, 4.0, 4.0), doorSwingCF * CFrame.new(0, 0, -1.0), Color3.fromRGB(225, 180, 50), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	wheelHub.CFrame = (doorSwingCF * CFrame.new(0, 0, -1.0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Hydraulic Piston Cylinder
	createPart(heistFolder, "HydraulicPiston", Vector3.new(1.2, 7.0, 1.2), (CFrame.new(anteOrigin + Vector3.new(-12, 12, 12))) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(70, 75, 85), Enum.Material.Metal)

	-- Emergency Rotating Siren Beacons (Exact names VaultSirenL and VaultSirenR preserved!)
	local sirenLeft = createPart(heistFolder, "VaultSirenL", Vector3.new(1.8, 1.8, 1.8), CFrame.new(anteOrigin + Vector3.new(-12, 19, 11)), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	local sirenRight = createPart(heistFolder, "VaultSirenR", Vector3.new(1.8, 1.8, 1.8), CFrame.new(anteOrigin + Vector3.new(12, 19, 11)), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(sirenLeft, Color3.fromRGB(255, 30, 30), 2.8, 20)
	createLight(sirenRight, Color3.fromRGB(255, 30, 30), 2.8, 20)

	----------------------------------------------------------------------
	-- 8. THE INNER SANCTUM / GRAND OCTAGONAL VAULT
	----------------------------------------------------------------------
	local vaultCenter = origin + Vector3.new(0, 0, 56)

	-- Polished Dark Marble Floor
	createPart(heistFolder, "VaultChamberFloor", Vector3.new(64, 2, 64), CFrame.new(vaultCenter + Vector3.new(0, 1, 0)), Color3.fromRGB(22, 22, 28), Enum.Material.Marble)

	-- Sacred Geometry Floor Mosaic Inlays: Radiating Gold Concentric Circles
	local mosaicRing1 = createPart(heistFolder, "MosaicGoldRing1", Vector3.new(0.2, 34, 34), CFrame.new(vaultCenter + Vector3.new(0, 2.05, 0)), Color3.fromRGB(255, 215, 0), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	mosaicRing1.CFrame = CFrame.new(vaultCenter + Vector3.new(0, 2.05, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local mosaicRing2 = createPart(heistFolder, "MosaicGoldRing2", Vector3.new(0.25, 24, 24), CFrame.new(vaultCenter + Vector3.new(0, 2.06, 0)), Color3.fromRGB(255, 215, 0), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	mosaicRing2.CFrame = CFrame.new(vaultCenter + Vector3.new(0, 2.06, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- 8 Classical Fluted Obsidian Columns with Gilded Capitals
	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45)
		local colRadius = 26
		local colX = math.cos(angle) * colRadius
		local colZ = math.sin(angle) * colRadius

		-- Fluted Classical Pillar
		EnvironmentProps.CreateFlutedColumn(heistFolder, 26, 1.4, CFrame.new(vaultCenter + Vector3.new(colX, 2, colZ)), Color3.fromRGB(20, 22, 26))

		-- Wall Sconce Torch on each pillar
		createTorch(heistFolder, CFrame.new(vaultCenter + Vector3.new(colX * 0.9, 12, colZ * 0.9)) * CFrame.Angles(0, -angle, 0), Color3.fromRGB(40, 150, 255))
	end

	-- Multi-Tiered Vault Ceremonial Dais
	local daisStep1 = createPart(heistFolder, "VaultDaisStep1", Vector3.new(1.6, 20, 20), CFrame.new(vaultCenter + Vector3.new(0, 2.0, 0)), Color3.fromRGB(36, 38, 48), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	daisStep1.CFrame = CFrame.new(vaultCenter + Vector3.new(0, 2.0, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local daisStep2 = createPart(heistFolder, "VaultDaisStep2", Vector3.new(1.6, 15, 15), CFrame.new(vaultCenter + Vector3.new(0, 3.6, 0)), Color3.fromRGB(48, 52, 65), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	daisStep2.CFrame = CFrame.new(vaultCenter + Vector3.new(0, 3.6, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Sculpted Obsidian Pedestal Base & Gilded Capital Trim
	createPart(heistFolder, "VaultPedestalBase", Vector3.new(4.5, 4.5, 4.5), CFrame.new(vaultCenter + Vector3.new(0, 6.2, 0)), Color3.fromRGB(24, 28, 36), Enum.Material.Marble)
	createPart(heistFolder, "VaultPedestalGold", Vector3.new(5.0, 0.8, 5.0), CFrame.new(vaultCenter + Vector3.new(0, 8.6, 0)), Color3.fromRGB(255, 215, 0), Enum.Material.Metal)

	-- 4 Runic Containment Pylons around Chalice Dais
	local pylonOffsets = {
		Vector3.new(-7, 0, -7), Vector3.new(7, 0, -7),
		Vector3.new(-7, 0, 7), Vector3.new(7, 0, 7)
	}
	for pIdx, pOff in ipairs(pylonOffsets) do
		local pylon = createPart(heistFolder, "VaultPylon_" .. tostring(pIdx), Vector3.new(1.8, 8.5, 1.8), CFrame.new(vaultCenter + pOff + Vector3.new(0, 5.5, 0)), Color3.fromRGB(24, 24, 30), Enum.Material.Basalt)
		local rune = createPart(heistFolder, "VaultPylonRune_" .. tostring(pIdx), Vector3.new(0.4, 5.0, 0.4), CFrame.new(vaultCenter + pOff + Vector3.new(0, 5.5, 0)), Color3.fromRGB(0, 220, 255), Enum.Material.Neon, false, false)
		createLight(rune, Color3.fromRGB(0, 220, 255), 1.6, 10)
	end

	-- Sculpted Obsidian Chalice Model (Centerpiece!)
	local chaliceModel = RelicMeshBuilder.CreateObsidianChalice(heistFolder, CFrame.new(vaultCenter + Vector3.new(0, 9.1, 0)))
	chaliceModel.Name = "Relic_ObsidianChalice_Model"

	if chaliceModel.PrimaryPart then
		local chalicePrompt = Instance.new("ProximityPrompt")
		chalicePrompt.Name = "Prompt_StealChalice"
		chalicePrompt.ObjectText = "Obsidian Chalice"
		chalicePrompt.ActionText = "Crack Vault Seals & Secure Relic"
		chalicePrompt.HoldDuration = 1.2
		chalicePrompt.MaxActivationDistance = 14
		chalicePrompt.RequiresLineOfSight = false
		chalicePrompt.Parent = chaliceModel.PrimaryPart
	end

	-- Chamber Perimeter Vault Treasure Riches in 4 Alcoves
	EnvironmentProps.CreateIronboundChest(heistFolder, CFrame.new(vaultCenter + Vector3.new(-22, 2, 10)), true)
	EnvironmentProps.CreateIronboundChest(heistFolder, CFrame.new(vaultCenter + Vector3.new(22, 2, 10)), true)
	EnvironmentProps.CreateGoldBullionStack(heistFolder, CFrame.new(vaultCenter + Vector3.new(-18, 2, 20)))
	EnvironmentProps.CreateGoldBullionStack(heistFolder, CFrame.new(vaultCenter + Vector3.new(18, 2, 20)))

	-- Additional Treasure Spoils in North Alcoves
	EnvironmentProps.CreateIronboundChest(heistFolder, CFrame.new(vaultCenter + Vector3.new(-16, 2, -18)), true)
	EnvironmentProps.CreateIronboundChest(heistFolder, CFrame.new(vaultCenter + Vector3.new(16, 2, -18)), false)

	----------------------------------------------------------------------
	-- 9. DUAL EXTRACTION BEACONS
	----------------------------------------------------------------------
	-- Route Alpha: Main Gate Courtyard Escape
	local exitAlphaPos = origin + Vector3.new(0, 2, -75)
	local exitAlphaBeacon = createPart(heistFolder, "ExitPad_Alpha", Vector3.new(1.0, 16, 16), CFrame.new(exitAlphaPos), Color3.fromRGB(0, 200, 255), Enum.Material.Neon, true, false, Enum.PartType.Cylinder)
	exitAlphaBeacon.CFrame = CFrame.new(exitAlphaPos) * CFrame.Angles(0, 0, math.rad(90))
	createLight(exitAlphaBeacon, Color3.fromRGB(0, 200, 255), 2.8, 22)

	local alphaMotes = Instance.new("ParticleEmitter")
	alphaMotes.Name = "AlphaBeaconMotes"
	alphaMotes.Color = ColorSequence.new(Color3.fromRGB(0, 220, 255))
	alphaMotes.LightEmission = 0.9
	alphaMotes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	alphaMotes.Lifetime = NumberRange.new(2, 3)
	alphaMotes.Rate = 10
	alphaMotes.Speed = NumberRange.new(4, 7)
	alphaMotes.SpreadAngle = Vector2.new(10, 10)
	alphaMotes.Parent = exitAlphaBeacon

	local alphaRing = createPart(heistFolder, "AlphaRingTrim", Vector3.new(0.4, 18, 18), CFrame.new(exitAlphaPos), Color3.fromRGB(30, 80, 140), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	alphaRing.CFrame = CFrame.new(exitAlphaPos) * CFrame.Angles(0, 0, math.rad(90))

	local alphaSign = Instance.new("BillboardGui")
	alphaSign.Size = UDim2.new(0, 190, 0, 48)
	alphaSign.StudsOffset = Vector3.new(0, 3.5, 0)
	alphaSign.AlwaysOnTop = true
	alphaSign.Parent = exitAlphaBeacon

	local alphaLabel = Instance.new("TextLabel")
	alphaLabel.Size = UDim2.new(1, 0, 1, 0)
	alphaLabel.BackgroundTransparency = 1
	alphaLabel.Text = "🚪 EXTRACTION ALPHA\n[Main Fortress Gate]"
	alphaLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	alphaLabel.Font = Enum.Font.GothamBold
	alphaLabel.TextSize = 13
	alphaLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	alphaLabel.TextStrokeTransparency = 0.2
	alphaLabel.Parent = alphaSign

	local exitAlphaPrompt = Instance.new("ProximityPrompt")
	exitAlphaPrompt.Name = "Prompt_ExitAlpha"
	exitAlphaPrompt.ObjectText = "Extraction Alpha (Main Gate)"
	exitAlphaPrompt.ActionText = "Extract to Market"
	exitAlphaPrompt.HoldDuration = 0.8
	exitAlphaPrompt.MaxActivationDistance = 16
	exitAlphaPrompt.RequiresLineOfSight = false
	exitAlphaPrompt.Parent = exitAlphaBeacon

	-- Route Beta: Shadow Drain Flume Escape (Subterranean Masonry Aqueduct)
	local exitBetaPos = origin + Vector3.new(65, 2, 20)

	-- Stone Aqueduct Flume Masonry
	createPart(heistFolder, "FlumeTunnelWallL", Vector3.new(2, 14, 30), CFrame.new(exitBetaPos + Vector3.new(-8, 7, 0)), Color3.fromRGB(42, 45, 50), Enum.Material.Cobblestone)
	createPart(heistFolder, "FlumeTunnelWallR", Vector3.new(2, 14, 30), CFrame.new(exitBetaPos + Vector3.new(8, 7, 0)), Color3.fromRGB(42, 45, 50), Enum.Material.Cobblestone)
	createPart(heistFolder, "FlumeTunnelArch", Vector3.new(18, 2, 30), CFrame.new(exitBetaPos + Vector3.new(0, 14, 0)), Color3.fromRGB(50, 52, 58), Enum.Material.Slate)

	-- Heavy Iron Sluice Gate with Hoisting Chains
	createPart(heistFolder, "SluiceGateFrame", Vector3.new(14, 12, 1.2), CFrame.new(exitBetaPos + Vector3.new(0, 6, 12)), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
	createPart(heistFolder, "SluiceChainL", Vector3.new(0.4, 8, 0.4), CFrame.new(exitBetaPos + Vector3.new(-4, 10, 12)), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
	createPart(heistFolder, "SluiceChainR", Vector3.new(0.4, 8, 0.4), CFrame.new(exitBetaPos + Vector3.new(4, 10, 12)), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)

	-- Wooden Plank Walkway Suspended above Flowing Drainage Water
	createPart(heistFolder, "FlumeWalkway", Vector3.new(7, 0.6, 26), CFrame.new(exitBetaPos + Vector3.new(0, 1.2, 0)), Color3.fromRGB(75, 48, 28), Enum.Material.WoodPlanks)
	local drainWater = createPart(heistFolder, "FlumeWater", Vector3.new(14, 0.6, 28), CFrame.new(exitBetaPos + Vector3.new(0, 0.3, 0)), Color3.fromRGB(35, 75, 95), Enum.Material.Glass, true, false)
	drainWater.Transparency = 0.45

	local exitBetaBeacon = createPart(heistFolder, "ExitPad_Beta", Vector3.new(1.0, 14, 14), CFrame.new(exitBetaPos + Vector3.new(0, 0.8, 0)), Color3.fromRGB(76, 175, 80), Enum.Material.Neon, true, false, Enum.PartType.Cylinder)
	exitBetaBeacon.CFrame = CFrame.new(exitBetaPos + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	createLight(exitBetaBeacon, Color3.fromRGB(76, 175, 80), 2.8, 20)

	local betaMotes = Instance.new("ParticleEmitter")
	betaMotes.Name = "BetaBeaconMotes"
	betaMotes.Color = ColorSequence.new(Color3.fromRGB(76, 220, 100))
	betaMotes.LightEmission = 0.9
	betaMotes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	betaMotes.Lifetime = NumberRange.new(2, 3)
	betaMotes.Rate = 10
	betaMotes.Speed = NumberRange.new(4, 7)
	betaMotes.SpreadAngle = Vector2.new(10, 10)
	betaMotes.Parent = exitBetaBeacon

	local betaSign = Instance.new("BillboardGui")
	betaSign.Size = UDim2.new(0, 190, 0, 48)
	betaSign.StudsOffset = Vector3.new(0, 3.5, 0)
	betaSign.AlwaysOnTop = true
	betaSign.Parent = exitBetaBeacon

	local betaLabel = Instance.new("TextLabel")
	betaLabel.Size = UDim2.new(1, 0, 1, 0)
	betaLabel.BackgroundTransparency = 1
	betaLabel.Text = "🌊 EXTRACTION BETA\n[Shadow Drain Flume]"
	betaLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
	betaLabel.Font = Enum.Font.GothamBold
	betaLabel.TextSize = 13
	betaLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	betaLabel.TextStrokeTransparency = 0.2
	betaLabel.Parent = betaSign

	local exitBetaPrompt = Instance.new("ProximityPrompt")
	exitBetaPrompt.Name = "Prompt_ExitBeta"
	exitBetaPrompt.ObjectText = "Extraction Beta (Drain Flume)"
	exitBetaPrompt.ActionText = "Extract via Aqueduct"
	exitBetaPrompt.HoldDuration = 0.8
	exitBetaPrompt.MaxActivationDistance = 16
	exitBetaPrompt.RequiresLineOfSight = false
	exitBetaPrompt.Parent = exitBetaBeacon

	----------------------------------------------------------------------
	-- 8C. EXTRACTION GAMMA: DEEP SUB-LEVEL CATACOMBS GRATE
	----------------------------------------------------------------------
	local exitGammaPos = origin + Vector3.new(-65, 2, 20)

	-- Subterranean Catacomb Masonry Vault
	createPart(heistFolder, "CatacombTunnelL", Vector3.new(2, 14, 28), CFrame.new(exitGammaPos + Vector3.new(-8, 7, 0)), Color3.fromRGB(38, 38, 44), Enum.Material.Cobblestone)
	createPart(heistFolder, "CatacombTunnelR", Vector3.new(2, 14, 28), CFrame.new(exitGammaPos + Vector3.new(8, 7, 0)), Color3.fromRGB(38, 38, 44), Enum.Material.Cobblestone)
	createPart(heistFolder, "CatacombArch", Vector3.new(18, 2, 28), CFrame.new(exitGammaPos + Vector3.new(0, 14, 0)), Color3.fromRGB(45, 45, 52), Enum.Material.Slate)

	-- Heavy Iron Sewer Escape Grate
	local sewerGrate = createPart(heistFolder, "SewerEscapeGrate", Vector3.new(12, 1.2, 12), CFrame.new(exitGammaPos + Vector3.new(0, 0.4, 0)), Color3.fromRGB(50, 52, 58), Enum.Material.Metal)

	-- High-intensity Amber Emergency Extraction Beacon
	local exitGammaBeacon = createPart(heistFolder, "ExitPad_Gamma", Vector3.new(1.0, 14, 14), CFrame.new(exitGammaPos + Vector3.new(0, 0.8, 0)), Color3.fromRGB(255, 175, 10), Enum.Material.Neon, true, false, Enum.PartType.Cylinder)
	exitGammaBeacon.CFrame = CFrame.new(exitGammaPos + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	createLight(exitGammaBeacon, Color3.fromRGB(255, 175, 10), 2.8, 20)

	local gammaMotes = Instance.new("ParticleEmitter")
	gammaMotes.Name = "GammaBeaconMotes"
	gammaMotes.Color = ColorSequence.new(Color3.fromRGB(255, 190, 40))
	gammaMotes.LightEmission = 0.9
	gammaMotes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	gammaMotes.Lifetime = NumberRange.new(2, 3)
	gammaMotes.Rate = 10
	gammaMotes.Speed = NumberRange.new(4, 7)
	gammaMotes.SpreadAngle = Vector2.new(10, 10)
	gammaMotes.Parent = exitGammaBeacon

	local gammaSign = Instance.new("BillboardGui")
	gammaSign.Size = UDim2.new(0, 190, 0, 48)
	gammaSign.StudsOffset = Vector3.new(0, 3.5, 0)
	gammaSign.AlwaysOnTop = true
	gammaSign.Parent = exitGammaBeacon

	local gammaLabel = Instance.new("TextLabel")
	gammaLabel.Size = UDim2.new(1, 0, 1, 0)
	gammaLabel.BackgroundTransparency = 1
	gammaLabel.Text = "🚪 EXTRACTION GAMMA\n[Deep Catacombs Grate]"
	gammaLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	gammaLabel.Font = Enum.Font.GothamBold
	gammaLabel.TextSize = 13
	gammaLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	gammaLabel.TextStrokeTransparency = 0.2
	gammaLabel.Parent = gammaSign

	local exitGammaPrompt = Instance.new("ProximityPrompt")
	exitGammaPrompt.Name = "Prompt_ExitGamma"
	exitGammaPrompt.ObjectText = "Extraction Gamma (Catacombs)"
	exitGammaPrompt.ActionText = "Escape via Catacombs"
	exitGammaPrompt.HoldDuration = 0.8
	exitGammaPrompt.MaxActivationDistance = 16
	exitGammaPrompt.RequiresLineOfSight = false
	exitGammaPrompt.Parent = exitGammaBeacon

	return heistFolder
end

return OutpostHeistBuilder