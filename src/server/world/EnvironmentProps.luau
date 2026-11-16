--!strict
-- EnvironmentProps.luau
-- Authoritative procedural asset and prop builder for high-fidelity dark fantasy environments
-- Crafts layered architectural elements, detailed furniture, and handcrafted props

local EnvironmentProps = {}

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

-- 1. Half-Timbered Medieval Wall with Recessed Inset Panels and Diagonal Braces
function EnvironmentProps.CreateTimberWall(
	parent: Instance,
	width: number,
	height: number,
	cframe: CFrame,
	hasWindow: boolean?,
	hasDoorway: boolean?
): Model
	local model = Instance.new("Model")
	model.Name = "TimberWall"

	local beamColor = Color3.fromRGB(60, 42, 28)
	local beamMat = Enum.Material.Wood
	local panelColor = Color3.fromRGB(185, 175, 160)
	local panelMat = Enum.Material.Sandstone
	local beamThick = 1.0

	-- Stone Foundation Plinth along base of wall
	createPart(model, "PlinthBase", Vector3.new(width + 0.4, 1.8, 1.6), cframe * CFrame.new(0, 0.9, 0), Color3.fromRGB(65, 65, 70), Enum.Material.Cobblestone)
	createPart(model, "PlinthCap", Vector3.new(width + 0.6, 0.4, 1.8), cframe * CFrame.new(0, 1.9, 0), Color3.fromRGB(80, 80, 85), Enum.Material.Slate)

	local wallH = height - 2.0
	local wallCenterY = 2.0 + wallH / 2

	-- Vertical Timber Corner Posts (Left & Right)
	createPart(model, "PostL", Vector3.new(beamThick, wallH, beamThick), cframe * CFrame.new(-width / 2 + beamThick / 2, wallCenterY, 0), beamColor, beamMat)
	createPart(model, "PostR", Vector3.new(beamThick, wallH, beamThick), cframe * CFrame.new(width / 2 - beamThick / 2, wallCenterY, 0), beamColor, beamMat)

	-- Horizontal Wall Plates (Top & Bottom)
	createPart(model, "PlateBottom", Vector3.new(width, beamThick, beamThick), cframe * CFrame.new(0, 2.0 + beamThick / 2, 0), beamColor, beamMat)
	createPart(model, "PlateTop", Vector3.new(width + 0.4, beamThick, beamThick + 0.4), cframe * CFrame.new(0, height - beamThick / 2, 0), beamColor, beamMat)

	if hasDoorway then
		-- Doorway Opening: left panel, right panel, and top header
		local doorW = 5.0
		local doorH = 8.0
		local sideW = (width - doorW - (beamThick * 2)) / 2

		createPart(model, "PanelLeft", Vector3.new(sideW, wallH - beamThick, 0.6), cframe * CFrame.new(-width / 2 + beamThick + sideW / 2, wallCenterY, 0), panelColor, panelMat)
		createPart(model, "PanelRight", Vector3.new(sideW, wallH - beamThick, 0.6), cframe * CFrame.new(width / 2 - beamThick - sideW / 2, wallCenterY, 0), panelColor, panelMat)

		-- Doorway Frame Posts
		createPart(model, "DoorPostL", Vector3.new(0.8, doorH, 0.9), cframe * CFrame.new(-doorW / 2, 2.0 + doorH / 2, 0), beamColor, beamMat)
		createPart(model, "DoorPostR", Vector3.new(0.8, doorH, 0.9), cframe * CFrame.new(doorW / 2, 2.0 + doorH / 2, 0), beamColor, beamMat)
		createPart(model, "DoorHeader", Vector3.new(doorW + 1.2, 0.8, 1.1), cframe * CFrame.new(0, 2.0 + doorH + 0.4, 0), beamColor, beamMat)

		-- Transom Inset Panel above door
		local transomH = (wallH - doorH - beamThick)
		if transomH > 1.0 then
			createPart(model, "PanelTransom", Vector3.new(doorW, transomH, 0.6), cframe * CFrame.new(0, 2.0 + doorH + 0.8 + transomH / 2, 0), panelColor, panelMat)
		end
	elseif hasWindow then
		-- Recessed Mullioned Window
		local winW = 4.0
		local winH = 4.0
		local winY = wallCenterY + 0.5
		local panelW = (width - winW - (beamThick * 2)) / 2

		createPart(model, "PanelL", Vector3.new(panelW, wallH - beamThick, 0.6), cframe * CFrame.new(-width / 2 + beamThick + panelW / 2, wallCenterY, 0), panelColor, panelMat)
		createPart(model, "PanelR", Vector3.new(panelW, wallH - beamThick, 0.6), cframe * CFrame.new(width / 2 - beamThick - panelW / 2, wallCenterY, 0), panelColor, panelMat)
		createPart(model, "PanelBelowWin", Vector3.new(winW, (winY - winH / 2) - 2.0, 0.6), cframe * CFrame.new(0, 2.0 + ((winY - winH / 2) - 2.0) / 2, 0), panelColor, panelMat)
		createPart(model, "PanelAboveWin", Vector3.new(winW, height - (winY + winH / 2) - beamThick, 0.6), cframe * CFrame.new(0, (winY + winH / 2) + (height - (winY + winH / 2) - beamThick) / 2, 0), panelColor, panelMat)

		-- Carved Window Sill & Lintel
		createPart(model, "WinSill", Vector3.new(winW + 0.8, 0.5, 1.2), cframe * CFrame.new(0, winY - winH / 2, 0), Color3.fromRGB(75, 75, 80), Enum.Material.Slate)
		createPart(model, "WinLintel", Vector3.new(winW + 0.8, 0.6, 1.1), cframe * CFrame.new(0, winY + winH / 2, 0), beamColor, beamMat)

		-- Leaded Glass Window Pane
		local glass = createPart(model, "GlassPane", Vector3.new(winW - 0.2, winH - 0.2, 0.2), cframe * CFrame.new(0, winY, 0), Color3.fromRGB(200, 225, 235), Enum.Material.Glass, true, true)
		glass.Transparency = 0.45

		-- Wooden Window Mullion Cross
		createPart(model, "MullionV", Vector3.new(0.3, winH, 0.35), cframe * CFrame.new(0, winY, 0), beamColor, beamMat)
		createPart(model, "MullionH", Vector3.new(winW, 0.3, 0.35), cframe * CFrame.new(0, winY, 0), beamColor, beamMat)
	else
		-- Solid Half-Timbered Panel with Center Stud and Diagonal Cross Braces
		createPart(model, "InfillPanel", Vector3.new(width - beamThick * 2, wallH - beamThick, 0.6), cframe * CFrame.new(0, wallCenterY, 0), panelColor, panelMat)
		createPart(model, "CenterStud", Vector3.new(0.8, wallH - beamThick, 0.8), cframe * CFrame.new(0, wallCenterY, 0.1), beamColor, beamMat)
	end

	model.Parent = parent
	return model
end

-- 2. True Pitched Gable Roof with Layered Slate Shingles, Ridge, and Overhanging Eaves
function EnvironmentProps.CreatePitchedRoof(
	parent: Instance,
	width: number,
	depth: number,
	cframe: CFrame,
	pitchAngleDeg: number?,
	slateColor: Color3?
): Model
	local model = Instance.new("Model")
	model.Name = "PitchedRoof"

	local angle = math.rad(pitchAngleDeg or 35)
	local slopeLen = (width / 2) / math.cos(angle) + 1.2
	local roofHeight = math.sin(angle) * slopeLen
	local tileColor = slateColor or Color3.fromRGB(48, 52, 60)
	local timberColor = Color3.fromRGB(55, 38, 25)

	-- Heavy Ridge Beam along the top apex
	createPart(model, "RidgeBeam", Vector3.new(0.9, 0.9, depth + 1.6), cframe * CFrame.new(0, roofHeight, 0), timberColor, Enum.Material.Wood)

	-- Left Sloped Roof Plane
	local leftCF = cframe * CFrame.new(-width / 4 - 0.3, roofHeight / 2, 0) * CFrame.Angles(0, 0, angle)
	createPart(model, "RoofSlopeLeft", Vector3.new(slopeLen, 0.6, depth + 1.4), leftCF, tileColor, Enum.Material.Slate)
	createPart(model, "BargeBoardL", Vector3.new(slopeLen + 0.2, 0.8, 0.4), leftCF * CFrame.new(0, 0, (depth + 1.4) / 2), timberColor, Enum.Material.Wood)
	createPart(model, "BargeBoardL_Back", Vector3.new(slopeLen + 0.2, 0.8, 0.4), leftCF * CFrame.new(0, 0, -(depth + 1.4) / 2), timberColor, Enum.Material.Wood)

	-- Right Sloped Roof Plane
	local rightCF = cframe * CFrame.new(width / 4 + 0.3, roofHeight / 2, 0) * CFrame.Angles(0, 0, -angle)
	createPart(model, "RoofSlopeRight", Vector3.new(slopeLen, 0.6, depth + 1.4), rightCF, tileColor, Enum.Material.Slate)
	createPart(model, "BargeBoardR", Vector3.new(slopeLen + 0.2, 0.8, 0.4), rightCF * CFrame.new(0, 0, (depth + 1.4) / 2), timberColor, Enum.Material.Wood)
	createPart(model, "BargeBoardR_Back", Vector3.new(slopeLen + 0.2, 0.8, 0.4), rightCF * CFrame.new(0, 0, -(depth + 1.4) / 2), timberColor, Enum.Material.Wood)

	-- Triangular Gable Infill Panels (Front & Back)
	local frontGable = createPart(model, "GableWallFront", Vector3.new(width - 0.4, roofHeight - 0.2, 0.8), cframe * CFrame.new(0, roofHeight / 2, depth / 2), Color3.fromRGB(180, 170, 155), Enum.Material.Sandstone)
	local backGable = createPart(model, "GableWallBack", Vector3.new(width - 0.4, roofHeight - 0.2, 0.8), cframe * CFrame.new(0, roofHeight / 2, -depth / 2), Color3.fromRGB(180, 170, 155), Enum.Material.Sandstone)

	model.Parent = parent
	return model
end

-- 3. Handcrafted Ornate Street Lantern Post
function EnvironmentProps.CreateStreetLantern(parent: Instance, cframe: CFrame, lightColor: Color3?): Model
	local model = Instance.new("Model")
	model.Name = "OrnateStreetLantern"

	local metalColor = Color3.fromRGB(40, 42, 48)
	local goldColor = Color3.fromRGB(215, 170, 50)
	local glassColor = lightColor or Color3.fromRGB(255, 205, 120)

	-- Stepped Granite Base Plinth
	createPart(model, "BasePlinth", Vector3.new(2.0, 1.2, 2.0), cframe * CFrame.new(0, 0.6, 0), Color3.fromRGB(75, 75, 80), Enum.Material.Slate)
	createPart(model, "BaseBevel", Vector3.new(1.6, 0.4, 1.6), cframe * CFrame.new(0, 1.4, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Cobblestone)

	-- Tapered Cast-Iron Column
	createPart(model, "ColumnLower", Vector3.new(0.7, 4.0, 0.7), cframe * CFrame.new(0, 3.6, 0), metalColor, Enum.Material.Metal)
	createPart(model, "GoldCollar", Vector3.new(0.9, 0.3, 0.9), cframe * CFrame.new(0, 5.7, 0), goldColor, Enum.Material.Metal)
	createPart(model, "ColumnUpper", Vector3.new(0.5, 4.0, 0.5), cframe * CFrame.new(0, 7.8, 0), metalColor, Enum.Material.Metal)

	-- Arched Scrollwork Arm
	createPart(model, "ScrollArm", Vector3.new(1.8, 0.3, 0.3), cframe * CFrame.new(0.9, 9.6, 0), metalColor, Enum.Material.Metal)
	createPart(model, "ScrollStrut", Vector3.new(1.2, 0.2, 0.2), (cframe * CFrame.new(0.5, 9.0, 0)) * CFrame.Angles(0, 0, math.rad(45)), metalColor, Enum.Material.Metal)

	-- Hexagonal Lantern Housing
	local lCF = cframe * CFrame.new(1.8, 9.0, 0)
	createPart(model, "LanternCap", Vector3.new(1.2, 0.4, 1.2), lCF * CFrame.new(0, 0.8, 0), metalColor, Enum.Material.Metal)
	createPart(model, "LanternFinial", Vector3.new(0.3, 0.6, 0.3), lCF * CFrame.new(0, 1.2, 0), goldColor, Enum.Material.Metal)

	local glass = createPart(model, "LanternGlass", Vector3.new(0.8, 1.2, 0.8), lCF, glassColor, Enum.Material.Neon, true, false)
	createPart(model, "LanternBase", Vector3.new(1.0, 0.3, 1.0), lCF * CFrame.new(0, -0.7, 0), metalColor, Enum.Material.Metal)

	-- Controlled, warm PointLight (No blinding glare!)
	createLight(glass, glassColor, 1.6, 18)

	model.Parent = parent
	return model
end

-- 4. Handcrafted Fluted Classical Pillar with Ionic Capital & Plinth
function EnvironmentProps.CreateFlutedColumn(
	parent: Instance,
	height: number,
	radius: number,
	cframe: CFrame,
	marbleColor: Color3?
): Model
	local model = Instance.new("Model")
	model.Name = "FlutedColumn"

	local colColor = marbleColor or Color3.fromRGB(225, 220, 215)
	local goldColor = Color3.fromRGB(235, 195, 60)

	-- Square Base Plinth & Torus Moldings
	createPart(model, "Plinth", Vector3.new(radius * 2.8, 0.8, radius * 2.8), cframe * CFrame.new(0, 0.4, 0), Color3.fromRGB(120, 115, 110), Enum.Material.Marble)
	local torus1 = createPart(model, "Torus1", Vector3.new(0.5, radius * 2.4, radius * 2.4), cframe * CFrame.new(0, 1.0, 0), colColor, Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	torus1.CFrame = (cframe * CFrame.new(0, 1.0, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Main Column Shaft
	local colH = height - 2.8
	local shaft = createPart(model, "Shaft", Vector3.new(colH, radius * 2, radius * 2), cframe * CFrame.new(0, 1.2 + colH / 2, 0), colColor, Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	shaft.CFrame = (cframe * CFrame.new(0, 1.2 + colH / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Gold Capital Ring
	createPart(model, "GoldRing", Vector3.new(radius * 2.2, 0.3, radius * 2.2), cframe * CFrame.new(0, height - 1.2, 0), goldColor, Enum.Material.Metal)

	-- Carved Abacus & Capital
	createPart(model, "Capital", Vector3.new(radius * 2.6, 0.8, radius * 2.6), cframe * CFrame.new(0, height - 0.6, 0), colColor, Enum.Material.Marble)
	createPart(model, "AbacusCap", Vector3.new(radius * 2.9, 0.4, radius * 2.9), cframe * CFrame.new(0, height - 0.2, 0), colColor, Enum.Material.Marble)

	model.Parent = parent
	return model
end

-- 5. Detailed Appraiser Merchant Counter with Brass Scales, Coins & Ledger
function EnvironmentProps.CreateDetailedMerchantCounter(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "AppraiserCounter"

	local woodDark = Color3.fromRGB(80, 50, 32)
	local woodTop = Color3.fromRGB(115, 75, 48)
	local brassColor = Color3.fromRGB(220, 180, 50)

	-- Main Heavy Counter Body with Recessed Panels
	createPart(model, "CounterBase", Vector3.new(16.0, 3.8, 3.2), cframe * CFrame.new(0, 1.9, 0), woodDark, Enum.Material.WoodPlanks)
	createPart(model, "CounterTop", Vector3.new(17.0, 0.6, 3.8), cframe * CFrame.new(0, 4.0, 0), woodTop, Enum.Material.WoodPlanks)
	createPart(model, "CounterTrimFront", Vector3.new(17.2, 0.4, 0.4), cframe * CFrame.new(0, 4.0, 1.8), brassColor, Enum.Material.Metal)

	-- Working Brass Balance Scale
	local sCF = cframe * CFrame.new(-4.5, 4.3, 0)
	createPart(model, "ScaleBase", Vector3.new(1.2, 0.3, 1.2), sCF * CFrame.new(0, 0.15, 0), brassColor, Enum.Material.Metal)
	createPart(model, "ScaleMast", Vector3.new(0.2, 2.2, 0.2), sCF * CFrame.new(0, 1.2, 0), brassColor, Enum.Material.Metal)
	createPart(model, "ScaleCrossbar", Vector3.new(2.2, 0.15, 0.15), sCF * CFrame.new(0, 2.2, 0), brassColor, Enum.Material.Metal)
	-- Suspended Weighing Pans
	createPart(model, "PanLeft", Vector3.new(0.1, 0.8, 0.8), (sCF * CFrame.new(-1.0, 1.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), brassColor, Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	createPart(model, "PanRight", Vector3.new(0.1, 0.8, 0.8), (sCF * CFrame.new(1.0, 1.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), brassColor, Enum.Material.Metal, true, false, Enum.PartType.Cylinder)

	-- Stacks of Gold & Silver Coins
	local cCF = cframe * CFrame.new(-2.2, 4.3, 0.5)
	for i = 1, 4 do
		local coin = createPart(model, "CoinStack1_" .. tostring(i), Vector3.new(0.12, 0.6, 0.6), (cCF * CFrame.new(0, (i - 1) * 0.14 + 0.07, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(245, 195, 45), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	end
	for i = 1, 3 do
		local coin = createPart(model, "CoinStack2_" .. tostring(i), Vector3.new(0.12, 0.5, 0.5), (cCF * CFrame.new(0.7, (i - 1) * 0.14 + 0.07, 0.2)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 205, 215), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	end

	-- Open Leather Sales Ledger
	local lCF = cframe * CFrame.new(1.5, 4.35, 0)
	createPart(model, "LedgerCover", Vector3.new(1.8, 0.15, 1.4), lCF, Color3.fromRGB(90, 45, 25), Enum.Material.Fabric)
	createPart(model, "LedgerPagesL", Vector3.new(0.8, 0.1, 1.2), lCF * CFrame.new(-0.45, 0.12, 0), Color3.fromRGB(240, 235, 215), Enum.Material.Sandstone)
	createPart(model, "LedgerPagesR", Vector3.new(0.8, 0.1, 1.2), lCF * CFrame.new(0.45, 0.12, 0), Color3.fromRGB(240, 235, 215), Enum.Material.Sandstone)
	createPart(model, "Quill", Vector3.new(0.1, 0.8, 0.1), (lCF * CFrame.new(1.1, 0.2, 0.3)) * CFrame.Angles(0, 0, math.rad(30)), Color3.fromRGB(220, 220, 230), Enum.Material.SmoothPlastic)

	-- Velvet Jeweled Showcase Case
	local jCF = cframe * CFrame.new(5.0, 4.3, 0)
	createPart(model, "CaseTray", Vector3.new(3.6, 0.4, 2.2), jCF * CFrame.new(0, 0.2, 0), Color3.fromRGB(60, 40, 25), Enum.Material.WoodPlanks)
	createPart(model, "VelvetCushion", Vector3.new(3.2, 0.2, 1.8), jCF * CFrame.new(0, 0.45, 0), Color3.fromRGB(120, 25, 45), Enum.Material.Fabric)
	local caseGlass = createPart(model, "CaseGlass", Vector3.new(3.4, 0.8, 2.0), jCF * CFrame.new(0, 0.8, 0), Color3.fromRGB(210, 235, 245), Enum.Material.Glass)
	caseGlass.Transparency = 0.55

	-- Gemstones on Velvet
	createPart(model, "CutRuby", Vector3.new(0.4, 0.4, 0.4), jCF * CFrame.new(-0.8, 0.6, 0), Color3.fromRGB(220, 30, 70), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createPart(model, "CutSapphire", Vector3.new(0.4, 0.4, 0.4), jCF * CFrame.new(0, 0.6, 0), Color3.fromRGB(30, 130, 240), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createPart(model, "CutEmerald", Vector3.new(0.4, 0.4, 0.4), jCF * CFrame.new(0.8, 0.6, 0), Color3.fromRGB(40, 180, 80), Enum.Material.Neon, true, false, Enum.PartType.Ball)

	model.Parent = parent
	return model
end

-- 6. Handcrafted Artisan Blacksmith Forge & Horn Anvil
function EnvironmentProps.CreateArtisanForgeStation(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "ArtisanForgeStation"

	local stoneColor = Color3.fromRGB(65, 62, 60)
	local ironColor = Color3.fromRGB(42, 44, 48)

	-- Stone Ashlar Hearth & Firebox
	createPart(model, "HearthFoundation", Vector3.new(8.0, 3.2, 6.0), cframe * CFrame.new(0, 1.6, 0), stoneColor, Enum.Material.Cobblestone)
	createPart(model, "HearthTopStone", Vector3.new(8.4, 0.6, 6.4), cframe * CFrame.new(0, 3.5, 0), Color3.fromRGB(50, 48, 48), Enum.Material.Slate)

	-- Arched Fire Opening & Chimney Hood
	createPart(model, "ChimneyHood", Vector3.new(6.0, 4.0, 5.0), cframe * CFrame.new(0, 5.8, -0.5), stoneColor, Enum.Material.Cobblestone)
	local chimneyStack = createPart(model, "ChimneyStack", Vector3.new(3.5, 12.0, 3.5), cframe * CFrame.new(0, 13.8, -0.5), stoneColor, Enum.Material.Cobblestone)

	-- Glowing Embers Pit
	local fireBed = createPart(model, "FireBed", Vector3.new(3.8, 0.6, 3.2), cframe * CFrame.new(0, 3.8, 0.5), Color3.fromRGB(255, 95, 20), Enum.Material.Neon, true, false)
	local forgeLight = createLight(fireBed, Color3.fromRGB(255, 120, 30), 2.2, 16)

	-- Chimney Smoke Particle Emitter
	local smoke = Instance.new("Smoke")
	smoke.Name = "ForgeSmoke"
	smoke.Color = Color3.fromRGB(85, 80, 85)
	smoke.Size = 2.5
	smoke.RiseVelocity = 3.5
	smoke.Parent = chimneyStack

	-- Heavy Blacksmith Horn Anvil on Carved Oak Log Stump
	local aCF = cframe * CFrame.new(0, 0, 7.5)
	local stump = createPart(model, "AnvilStump", Vector3.new(2.6, 2.2, 2.6), aCF * CFrame.new(0, 1.1, 0), Color3.fromRGB(75, 48, 28), Enum.Material.Wood, true, true, Enum.PartType.Cylinder)
	stump.CFrame = (aCF * CFrame.new(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Sculpted Iron Anvil Body & Horn
	createPart(model, "AnvilBase", Vector3.new(2.4, 0.6, 1.4), aCF * CFrame.new(0, 2.5, 0), ironColor, Enum.Material.Metal)
	createPart(model, "AnvilWaist", Vector3.new(1.4, 0.8, 0.8), aCF * CFrame.new(0, 3.1, 0), ironColor, Enum.Material.Metal)
	createPart(model, "AnvilFace", Vector3.new(2.6, 0.6, 1.2), aCF * CFrame.new(0, 3.7, 0), Color3.fromRGB(70, 72, 78), Enum.Material.Metal)
	-- Pointed Horn Cone
	createPart(model, "AnvilHorn", Vector3.new(1.0, 0.4, 0.6), aCF * CFrame.new(1.6, 3.7, 0), Color3.fromRGB(70, 72, 78), Enum.Material.Metal)

	-- Quenching Water Trough
	local qCF = cframe * CFrame.new(5.5, 0, 4.0)
	createPart(model, "TroughWood", Vector3.new(2.5, 2.4, 4.5), qCF * CFrame.new(0, 1.2, 0), Color3.fromRGB(68, 42, 24), Enum.Material.WoodPlanks)
	local water = createPart(model, "TroughWater", Vector3.new(2.1, 0.2, 4.1), qCF * CFrame.new(0, 2.1, 0), Color3.fromRGB(50, 140, 180), Enum.Material.Glass, true, false)
	water.Transparency = 0.4

	model.Parent = parent
	return model
end

-- 7. Naturalistic Rocky Cliff Face Module (Encloses boundaries and removes the flat black void)
function EnvironmentProps.CreateRockCliff(parent: Instance, cframe: CFrame, width: number, height: number): Model
	local model = Instance.new("Model")
	model.Name = "RockCliffWall"

	local stoneDark = Color3.fromRGB(48, 48, 52)
	local stoneMid = Color3.fromRGB(62, 60, 64)
	local stoneLight = Color3.fromRGB(80, 78, 80)

	-- Layered Stepped Cliff Terraces
	local tiers = math.max(2, math.floor(height / 8))
	for t = 1, tiers do
		local tH = height / tiers
		local tY = (t - 1) * tH + tH / 2
		local tDepth = 8 + (tiers - t) * 4
		local col = if t % 2 == 0 then stoneDark else stoneMid

		local slab = createPart(model, "CliffTier_" .. tostring(t), Vector3.new(width, tH + 0.4, tDepth), cframe * CFrame.new(0, tY, (t - 1) * 2), col, Enum.Material.Slate)

		-- Weathered rock protrusions
		for p = 1, 3 do
			local pX = -width / 2 + (p / 4) * width
			local crag = createPart(model, "CragRock_" .. tostring(t) .. "_" .. tostring(p), Vector3.new(width * 0.28, tH * 0.8, 4), cframe * CFrame.new(pX, tY, (t - 1) * 2 - 2), stoneLight, Enum.Material.Basalt)
		end
	end

	-- Top Moss/Pine Crest
	local topCap = createPart(model, "CliffCrest", Vector3.new(width, 1.5, 6), cframe * CFrame.new(0, height + 0.5, 4), Color3.fromRGB(55, 68, 48), Enum.Material.Grass)

	model.Parent = parent
	return model
end

-- 8. Carved Stone & Wrought Iron Brazier
function EnvironmentProps.CreateStoneBrazier(parent: Instance, cframe: CFrame, flameColor: Color3?): Model
	local model = Instance.new("Model")
	model.Name = "OrnateBrazier"

	local ironColor = Color3.fromRGB(40, 42, 46)
	local stoneColor = Color3.fromRGB(60, 60, 65)
	local glowCol = flameColor or Color3.fromRGB(255, 120, 30)

	-- Stepped Octagonal Plinth
	createPart(model, "PlinthBase", Vector3.new(3.0, 0.6, 3.0), cframe * CFrame.new(0, 0.3, 0), stoneColor, Enum.Material.Slate)
	createPart(model, "PlinthPillar", Vector3.new(2.2, 1.2, 2.2), cframe * CFrame.new(0, 1.2, 0), stoneColor, Enum.Material.Cobblestone)
	createPart(model, "PlinthCap", Vector3.new(2.8, 0.4, 2.8), cframe * CFrame.new(0, 2.0, 0), stoneColor, Enum.Material.Slate)

	-- Forged Iron Tripod Feet
	for a = 0, 240, 120 do
		local rad = math.rad(a)
		local legCF = cframe * CFrame.new(math.cos(rad) * 1.1, 1.6, math.sin(rad) * 1.1) * CFrame.Angles(0, -rad, math.rad(25))
		createPart(model, "BrazierLeg_" .. tostring(a), Vector3.new(0.3, 1.8, 0.3), legCF, ironColor, Enum.Material.Metal)
	end

	-- Iron Fire Bowl with Spiked Rim
	local bowl = createPart(model, "FireBowl", Vector3.new(0.8, 3.2, 3.2), cframe * CFrame.new(0, 2.6, 0), ironColor, Enum.Material.Metal, true, true, Enum.PartType.Cylinder)
	bowl.CFrame = (cframe * CFrame.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Glowing Ember Core
	local flameCore = createPart(model, "EmberBed", Vector3.new(2.2, 0.8, 2.2), cframe * CFrame.new(0, 3.0, 0), glowCol, Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(flameCore, glowCol, 2.4, 18)

	model.Parent = parent
	return model
end

-- 9. Heavy Ironbound Oak Storage Chest
function EnvironmentProps.CreateIronboundChest(parent: Instance, cframe: CFrame, isOpen: boolean?): Model
	local model = Instance.new("Model")
	model.Name = "IronboundChest"

	local woodColor = Color3.fromRGB(95, 62, 38)
	local ironColor = Color3.fromRGB(45, 48, 52)
	local goldColor = Color3.fromRGB(235, 190, 45)

	-- Main Box
	createPart(model, "ChestBase", Vector3.new(4.2, 2.4, 2.6), cframe * CFrame.new(0, 1.2, 0), woodColor, Enum.Material.WoodPlanks)

	-- Corner Iron Brackets & Banding
	local bands = { -1.9, -0.6, 0.6, 1.9 }
	for i, x in ipairs(bands) do
		createPart(model, "IronBand_" .. tostring(i), Vector3.new(0.3, 2.45, 2.65), cframe * CFrame.new(x, 1.2, 0), ironColor, Enum.Material.Metal)
	end

	-- Heavy Iron Padlock & Hasp
	createPart(model, "IronHasp", Vector3.new(0.4, 0.8, 0.2), cframe * CFrame.new(0, 1.6, 1.35), ironColor, Enum.Material.Metal)
	createPart(model, "Padlock", Vector3.new(0.5, 0.5, 0.3), cframe * CFrame.new(0, 1.3, 1.4), goldColor, Enum.Material.Metal)

	-- Arched Lid
	if isOpen then
		local lidCF = (cframe * CFrame.new(0, 2.6, -1.2)) * CFrame.Angles(math.rad(-60), 0, 0)
		createPart(model, "ChestLid", Vector3.new(4.4, 0.6, 2.8), lidCF * CFrame.new(0, 0.3, 1.3), woodColor, Enum.Material.WoodPlanks)
		local goldBed = createPart(model, "TreasureGold", Vector3.new(3.8, 0.6, 2.2), cframe * CFrame.new(0, 1.9, 0), goldColor, Enum.Material.Metal)
		createLight(goldBed, goldColor, 1.4, 8)
	else
		createPart(model, "ChestLid", Vector3.new(4.4, 0.6, 2.8), cframe * CFrame.new(0, 2.6, 0), woodColor, Enum.Material.WoodPlanks)
		for i, x in ipairs(bands) do
			createPart(model, "LidBand_" .. tostring(i), Vector3.new(0.3, 0.65, 2.85), cframe * CFrame.new(x, 2.6, 0), ironColor, Enum.Material.Metal)
		end
	end

	model.Parent = parent
	return model
end

-- 10. Spiked Defensive Abatis Barricade
function EnvironmentProps.CreateSpikedAbatis(parent: Instance, cframe: CFrame, width: number?): Model
	local model = Instance.new("Model")
	model.Name = "SpikedAbatis"

	local w = width or 12
	local logColor = Color3.fromRGB(80, 52, 32)
	local ironColor = Color3.fromRGB(45, 45, 50)

	-- Crossed Support Legs
	for x = -w / 2 + 1.5, w / 2 - 1.5, 4.5 do
		local legL = createPart(model, "CrossA_" .. tostring(x), Vector3.new(0.8, 4.5, 0.8), (cframe * CFrame.new(x, 1.8, 0)) * CFrame.Angles(math.rad(30), 0, 0), logColor, Enum.Material.Wood)
		local legR = createPart(model, "CrossB_" .. tostring(x), Vector3.new(0.8, 4.5, 0.8), (cframe * CFrame.new(x, 1.8, 0)) * CFrame.Angles(math.rad(-30), 0, 0), logColor, Enum.Material.Wood)
		createPart(model, "IronBinding_" .. tostring(x), Vector3.new(1.1, 0.8, 1.1), cframe * CFrame.new(x, 1.8, 0), ironColor, Enum.Material.Metal)
	end

	-- Longitudinal Ridge Beam
	createPart(model, "RidgeLog", Vector3.new(w + 0.6, 0.9, 0.9), cframe * CFrame.new(0, 1.8, 0), logColor, Enum.Material.Wood)

	-- Sharpened Angled Spikes facing outward
	for x = -w / 2 + 1.0, w / 2 - 1.0, 2.2 do
		local spike = createPart(model, "Spike_" .. tostring(x), Vector3.new(0.5, 3.8, 0.5), (cframe * CFrame.new(x, 1.5, -0.6)) * CFrame.Angles(math.rad(45), 0, 0), logColor, Enum.Material.Wood)
		createPart(model, "SpikeTip_" .. tostring(x), Vector3.new(0.4, 0.8, 0.4), (cframe * CFrame.new(x, 2.6, -1.8)) * CFrame.Angles(math.rad(45), 0, 0), ironColor, Enum.Material.Metal)
	end

	model.Parent = parent
	return model
end

-- 11. Carved Basalt Gargoyle Sentinel Statue
function EnvironmentProps.CreateGargoyleStatue(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "GargoyleSentinel"

	local stoneColor = Color3.fromRGB(42, 42, 48)
	local eyeColor = Color3.fromRGB(240, 30, 40)

	-- Stepped Pedestal Base
	createPart(model, "PedestalBase", Vector3.new(3.4, 1.0, 3.4), cframe * CFrame.new(0, 0.5, 0), stoneColor, Enum.Material.Slate)
	createPart(model, "PedestalShaft", Vector3.new(2.6, 3.2, 2.6), cframe * CFrame.new(0, 2.6, 0), stoneColor, Enum.Material.Basalt)
	createPart(model, "PedestalCap", Vector3.new(3.2, 0.6, 3.2), cframe * CFrame.new(0, 4.5, 0), stoneColor, Enum.Material.Slate)

	-- Crouching Gargoyle Torso & Limbs
	local gCF = cframe * CFrame.new(0, 5.0, 0)
	createPart(model, "Torso", Vector3.new(1.8, 2.0, 1.6), gCF * CFrame.new(0, 1.0, 0), stoneColor, Enum.Material.Slate)
	createPart(model, "Head", Vector3.new(1.4, 1.2, 1.3), gCF * CFrame.new(0, 2.2, 0.3), stoneColor, Enum.Material.Slate)
	createPart(model, "HornL", Vector3.new(0.3, 0.9, 0.3), (gCF * CFrame.new(-0.6, 2.8, 0.1)) * CFrame.Angles(0, 0, math.rad(-25)), stoneColor, Enum.Material.Basalt)
	createPart(model, "HornR", Vector3.new(0.3, 0.9, 0.3), (gCF * CFrame.new(0.6, 2.8, 0.1)) * CFrame.Angles(0, 0, math.rad(25)), stoneColor, Enum.Material.Basalt)
	createPart(model, "EyeL", Vector3.new(0.2, 0.2, 0.2), gCF * CFrame.new(-0.35, 2.3, 0.95), eyeColor, Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createPart(model, "EyeR", Vector3.new(0.2, 0.2, 0.2), gCF * CFrame.new(0.35, 2.3, 0.95), eyeColor, Enum.Material.Neon, true, false, Enum.PartType.Ball)
	local wingL = createPart(model, "WingL", Vector3.new(0.3, 2.6, 2.2), (gCF * CFrame.new(-1.2, 1.8, -0.6)) * CFrame.Angles(0, math.rad(-30), math.rad(-20)), stoneColor, Enum.Material.Slate)
	local wingR = createPart(model, "WingR", Vector3.new(0.3, 2.6, 2.2), (gCF * CFrame.new(1.2, 1.8, -0.6)) * CFrame.Angles(0, math.rad(30), math.rad(20)), stoneColor, Enum.Material.Slate)

	model.Parent = parent
	return model
end

-- 12. Stack of Golden Bullion Bars on Timber Pallet
function EnvironmentProps.CreateGoldBullionStack(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "GoldBullionStack"

	local palletColor = Color3.fromRGB(90, 60, 35)
	local goldColor = Color3.fromRGB(245, 195, 45)

	-- Timber Skid Pallet
	createPart(model, "PalletDeck", Vector3.new(4.0, 0.4, 4.0), cframe * CFrame.new(0, 0.4, 0), palletColor, Enum.Material.WoodPlanks)
	createPart(model, "PalletRunner1", Vector3.new(0.4, 0.4, 4.0), cframe * CFrame.new(-1.6, 0.2, 0), palletColor, Enum.Material.Wood)
	createPart(model, "PalletRunner2", Vector3.new(0.4, 0.4, 4.0), cframe * CFrame.new(0, 0.2, 0), palletColor, Enum.Material.Wood)
	createPart(model, "PalletRunner3", Vector3.new(0.4, 0.4, 4.0), cframe * CFrame.new(1.6, 0.2, 0), palletColor, Enum.Material.Wood)

	-- Pyramid Stack of Gold Bars
	local barH = 0.35
	local barW = 0.7
	local barL = 1.6
	for layer = 1, 3 do
		local count = 4 - layer
		local startX = -(count - 1) * (barW + 0.1) / 2
		local y = 0.6 + (layer - 1) * (barH + 0.05) + barH / 2
		for b = 1, count do
			local x = startX + (b - 1) * (barW + 0.1)
			createPart(model, "GoldBar_" .. tostring(layer) .. "_" .. tostring(b), Vector3.new(barW, barH, barL), cframe * CFrame.new(x, y, 0), goldColor, Enum.Material.Metal)
		end
	end

	local shine = createLight(model:FindFirstChild("PalletDeck") :: Instance, goldColor, 1.2, 10)

	model.Parent = parent
	return model
end

-- 13. Curio & Antiquities Display Shelving Unit
function EnvironmentProps.CreateCurioShelving(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "CurioShelving"

	local woodDark = Color3.fromRGB(65, 42, 26)
	local shelfW = 12.0
	local shelfH = 10.0
	local shelfD = 2.4

	-- Heavy Outer Case
	createPart(model, "CaseBack", Vector3.new(shelfW, shelfH, 0.4), cframe * CFrame.new(0, shelfH / 2, -shelfD / 2), Color3.fromRGB(50, 32, 20), Enum.Material.WoodPlanks)
	createPart(model, "CaseSideL", Vector3.new(0.6, shelfH, shelfD), cframe * CFrame.new(-shelfW / 2 + 0.3, shelfH / 2, 0), woodDark, Enum.Material.Wood)
	createPart(model, "CaseSideR", Vector3.new(0.6, shelfH, shelfD), cframe * CFrame.new(shelfW / 2 - 0.3, shelfH / 2, 0), woodDark, Enum.Material.Wood)
	createPart(model, "CaseTop", Vector3.new(shelfW + 0.8, 0.8, shelfD + 0.6), cframe * CFrame.new(0, shelfH, 0), Color3.fromRGB(80, 52, 32), Enum.Material.Wood)
	createPart(model, "CaseBase", Vector3.new(shelfW + 0.8, 0.8, shelfD + 0.6), cframe * CFrame.new(0, 0.4, 0), woodDark, Enum.Material.Wood)

	-- 3 Horizontal Shelves
	local shelfYs = { 3.2, 6.2 }
	for i, y in ipairs(shelfYs) do
		createPart(model, "Shelf_" .. tostring(i), Vector3.new(shelfW - 1.2, 0.5, shelfD - 0.4), cframe * CFrame.new(0, y, 0), woodDark, Enum.Material.WoodPlanks)
	end

	-- Row of Books & Grimoires on Lower Shelf (y = 0.8)
	local bookColors = { Color3.fromRGB(120, 35, 35), Color3.fromRGB(35, 65, 110), Color3.fromRGB(45, 80, 45), Color3.fromRGB(90, 60, 30), Color3.fromRGB(110, 85, 30) }
	for b = 1, 8 do
		local bx = -4.5 + (b - 1) * 0.9
		local bH = 1.8 + (b % 3) * 0.2
		local col = bookColors[(b % #bookColors) + 1]
		createPart(model, "Grimoire_" .. tostring(b), Vector3.new(0.7, bH, 1.4), cframe * CFrame.new(bx, 0.8 + bH / 2, 0.2), col, Enum.Material.Fabric)
	end
	-- Rolled Ancient Parchment Scrolls
	createPart(model, "ScrollStack", Vector3.new(2.4, 1.0, 1.2), (cframe * CFrame.new(3.6, 1.3, 0.2)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(230, 215, 185), Enum.Material.Sandstone, true, true, Enum.PartType.Cylinder)

	-- Mid Shelf: Clay Amphora Urn & Brass Astrolabe (y = 3.5)
	local urn = createPart(model, "AntiqueUrn", Vector3.new(2.0, 2.2, 2.0), cframe * CFrame.new(-3.5, 4.8, 0), Color3.fromRGB(165, 95, 55), Enum.Material.Cobblestone, true, true, Enum.PartType.Cylinder)
	urn.CFrame = (cframe * CFrame.new(-3.5, 4.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	-- Brass Astrolabe Ring
	local astrolabe = createPart(model, "BrassAstrolabe", Vector3.new(0.3, 2.0, 2.0), cframe * CFrame.new(0, 4.8, 0), Color3.fromRGB(225, 180, 50), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	astrolabe.CFrame = (cframe * CFrame.new(0, 4.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	-- Cut Jade Figurine
	createPart(model, "JadeFigurine", Vector3.new(1.0, 1.8, 1.0), cframe * CFrame.new(3.5, 4.6, 0), Color3.fromRGB(45, 160, 90), Enum.Material.Neon)

	-- Upper Shelf: Glowing Elixir Phials (y = 6.5)
	local potionSpecs = {
		{ x = -4.0, col = Color3.fromRGB(64, 196, 255) },
		{ x = -2.2, col = Color3.fromRGB(255, 60, 60) },
		{ x = 0.0, col = Color3.fromRGB(76, 175, 80) },
		{ x = 2.2, col = Color3.fromRGB(170, 60, 255) },
		{ x = 4.0, col = Color3.fromRGB(255, 193, 7) },
	}
	for i, spec in ipairs(potionSpecs) do
		local phial = createPart(model, "PotionPhial_" .. tostring(i), Vector3.new(0.8, 1.6, 0.8), cframe * CFrame.new(spec.x, 7.5, 0), spec.col, Enum.Material.Neon, true, false, Enum.PartType.Cylinder)
		phial.CFrame = (cframe * CFrame.new(spec.x, 7.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		-- Cork stopper
		createPart(model, "Cork_" .. tostring(i), Vector3.new(0.4, 0.4, 0.4), cframe * CFrame.new(spec.x, 8.5, 0), Color3.fromRGB(130, 85, 45), Enum.Material.Wood)
		createLight(phial, spec.col, 1.2, 6)
	end

	model.Parent = parent
	return model
end

-- 14. Handcrafted Alchemist Workbench with Alembic, Retorts & Phials
function EnvironmentProps.CreateAlchemistWorkstation(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "AlchemistWorkstation"

	local woodColor = Color3.fromRGB(75, 48, 28)
	local stoneTop = Color3.fromRGB(55, 52, 58)
	local brassColor = Color3.fromRGB(220, 175, 45)

	-- Heavy Bench Table with Slate Top
	createPart(model, "TableTop", Vector3.new(12.0, 0.7, 4.2), cframe * CFrame.new(0, 3.8, 0), stoneTop, Enum.Material.Slate)
	createPart(model, "TableLegL", Vector3.new(1.2, 3.6, 3.8), cframe * CFrame.new(-5.2, 1.8, 0), woodColor, Enum.Material.Wood)
	createPart(model, "TableLegR", Vector3.new(1.2, 3.6, 3.8), cframe * CFrame.new(5.2, 1.8, 0), woodColor, Enum.Material.Wood)
	createPart(model, "TableStretcher", Vector3.new(10.0, 0.6, 0.6), cframe * CFrame.new(0, 1.2, 0), woodColor, Enum.Material.Wood)

	-- Brass Alembic Still & Distillation Coils
	local stillCF = cframe * CFrame.new(-3.5, 4.2, 0)
	local stillBase = createPart(model, "AlembicBoiler", Vector3.new(1.8, 2.0, 1.8), stillCF * CFrame.new(0, 1.0, 0), brassColor, Enum.Material.Metal, true, true, Enum.PartType.Ball)
	createPart(model, "BurnerStand", Vector3.new(1.4, 0.8, 1.4), stillCF * CFrame.new(0, 0.4, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Metal)
	local burnerFlame = createPart(model, "BurnerFlame", Vector3.new(0.6, 0.6, 0.6), stillCF * CFrame.new(0, 0.5, 0), Color3.fromRGB(255, 120, 30), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(burnerFlame, Color3.fromRGB(255, 120, 30), 1.4, 8)

	-- Coiled Glass Condenser Tube
	createPart(model, "GlassCoil1", Vector3.new(0.3, 0.3, 2.4), stillCF * CFrame.new(1.5, 1.8, 0), Color3.fromRGB(200, 230, 245), Enum.Material.Glass)
	createPart(model, "GlassCoil2", Vector3.new(0.3, 1.2, 0.3), stillCF * CFrame.new(2.6, 1.2, 0), Color3.fromRGB(200, 230, 245), Enum.Material.Glass)

	-- Collection Flask with Glowing Celestial Elixir
	local flask = createPart(model, "CollectionFlask", Vector3.new(1.2, 1.4, 1.2), stillCF * CFrame.new(2.6, 0.7, 0), Color3.fromRGB(0, 220, 255), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(flask, Color3.fromRGB(0, 220, 255), 1.6, 8)

	-- Mortar & Pestle
	local mCF = cframe * CFrame.new(1.5, 4.2, 0.5)
	local mortar = createPart(model, "MortarBowl", Vector3.new(0.6, 1.2, 1.2), mCF * CFrame.new(0, 0.3, 0), Color3.fromRGB(150, 145, 140), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	mortar.CFrame = (mCF * CFrame.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	createPart(model, "Pestle", Vector3.new(0.25, 1.2, 0.25), (mCF * CFrame.new(0.2, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(150, 145, 140), Enum.Material.Marble)

	-- Apothecary Scale & Specimen Jars
	local sCF = cframe * CFrame.new(4.2, 4.2, 0)
	createPart(model, "ScaleStem", Vector3.new(0.2, 1.6, 0.2), sCF * CFrame.new(0, 0.8, 0), brassColor, Enum.Material.Metal)
	createPart(model, "ScaleBeam", Vector3.new(1.6, 0.1, 0.1), sCF * CFrame.new(0, 1.5, 0), brassColor, Enum.Material.Metal)
	createPart(model, "SpecimenJar1", Vector3.new(0.8, 1.4, 0.8), sCF * CFrame.new(-1.2, 0.7, 0.8), Color3.fromRGB(140, 220, 150), Enum.Material.Glass)
	createPart(model, "SpecimenJar2", Vector3.new(0.8, 1.1, 0.8), sCF * CFrame.new(1.2, 0.55, 0.8), Color3.fromRGB(240, 160, 80), Enum.Material.Glass)

	model.Parent = parent
	return model
end

-- 15. Carved Stone Plaza Seating Bench
function EnvironmentProps.CreatePlazaStoneBench(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "PlazaStoneBench"

	local stoneColor = Color3.fromRGB(68, 66, 72)
	local marbleSeat = Color3.fromRGB(175, 170, 165)

	-- Stepped Support Legs
	createPart(model, "LegL", Vector3.new(1.2, 1.8, 2.6), cframe * CFrame.new(-3.4, 0.9, 0), stoneColor, Enum.Material.Slate)
	createPart(model, "LegR", Vector3.new(1.2, 1.8, 2.6), cframe * CFrame.new(3.4, 0.9, 0), stoneColor, Enum.Material.Slate)

	-- Polished Marble Seat Slab
	createPart(model, "SeatSlab", Vector3.new(8.8, 0.5, 3.0), cframe * CFrame.new(0, 1.9, 0), marbleSeat, Enum.Material.Marble)

	-- Carved Backrest with End Finials
	createPart(model, "Backrest", Vector3.new(8.8, 1.8, 0.6), cframe * CFrame.new(0, 2.9, -1.2), stoneColor, Enum.Material.Slate)
	createPart(model, "FinialL", Vector3.new(0.6, 0.8, 0.6), cframe * CFrame.new(-4.2, 3.9, -1.2), Color3.fromRGB(215, 175, 50), Enum.Material.Metal)
	createPart(model, "FinialR", Vector3.new(0.6, 0.8, 0.6), cframe * CFrame.new(4.2, 3.9, -1.2), Color3.fromRGB(215, 175, 50), Enum.Material.Metal)

	model.Parent = parent
	return model
end

-- 16. Free-Standing Military Weapon Rack with Halberds & Shields
function EnvironmentProps.CreateWeaponRack(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "WeaponRack"

	local woodColor = Color3.fromRGB(75, 48, 28)
	local steelColor = Color3.fromRGB(140, 142, 148)

	-- A-Frame Timber Frame
	createPart(model, "BaseBeam", Vector3.new(8.0, 0.5, 3.0), cframe * CFrame.new(0, 0.25, 0), woodColor, Enum.Material.WoodPlanks)
	createPart(model, "FrameLegL", Vector3.new(0.6, 6.0, 0.6), (cframe * CFrame.new(-3.6, 3.0, 0)) * CFrame.Angles(0, 0, math.rad(-10)), woodColor, Enum.Material.Wood)
	createPart(model, "FrameLegR", Vector3.new(0.6, 6.0, 0.6), (cframe * CFrame.new(3.6, 3.0, 0)) * CFrame.Angles(0, 0, math.rad(10)), woodColor, Enum.Material.Wood)
	createPart(model, "CrossBeam", Vector3.new(7.6, 0.4, 0.4), cframe * CFrame.new(0, 4.8, 0), woodColor, Enum.Material.Wood)

	-- 3 Steel Halberds Resting in Rack
	local halberdXs = { -2.2, 0.0, 2.2 }
	for i, x in ipairs(halberdXs) do
		local hCF = cframe * CFrame.new(x, 3.2, 0) * CFrame.Angles(math.rad(12), 0, 0)
		createPart(model, "Shaft_" .. tostring(i), Vector3.new(0.2, 6.8, 0.2), hCF, Color3.fromRGB(60, 38, 22), Enum.Material.Wood)
		-- Halberd Axe Blade & Spear Tip
		createPart(model, "AxeBlade_" .. tostring(i), Vector3.new(1.0, 0.8, 0.1), hCF * CFrame.new(0.5, 3.0, 0), steelColor, Enum.Material.Metal)
		createPart(model, "SpearTip_" .. tostring(i), Vector3.new(0.2, 1.4, 0.2), hCF * CFrame.new(0, 3.8, 0), steelColor, Enum.Material.Metal)
	end

	-- 2 Iron-Banded Heater Shields
	local shieldL = createPart(model, "ShieldL", Vector3.new(1.8, 2.6, 0.3), (cframe * CFrame.new(-3.2, 1.8, 1.0)) * CFrame.Angles(math.rad(-15), math.rad(25), 0), Color3.fromRGB(160, 40, 40), Enum.Material.WoodPlanks)
	createPart(model, "BossL", Vector3.new(0.4, 0.4, 0.4), shieldL.CFrame * CFrame.new(0, 0, 0.2), Color3.fromRGB(45, 45, 50), Enum.Material.Metal, true, false, Enum.PartType.Ball)

	local shieldR = createPart(model, "ShieldR", Vector3.new(1.8, 2.6, 0.3), (cframe * CFrame.new(3.2, 1.8, 1.0)) * CFrame.Angles(math.rad(-15), math.rad(-25), 0), Color3.fromRGB(35, 75, 140), Enum.Material.WoodPlanks)
	createPart(model, "BossR", Vector3.new(0.4, 0.4, 0.4), shieldR.CFrame * CFrame.new(0, 0, 0.2), Color3.fromRGB(45, 45, 50), Enum.Material.Metal, true, false, Enum.PartType.Ball)

	model.Parent = parent
	return model
end

-- 17. Carved Granite Plaza Planter with Night-Flora
function EnvironmentProps.CreateStonePlanter(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "StonePlanter"

	local stoneColor = Color3.fromRGB(62, 60, 66)

	-- Stepped Granite Urn Body
	createPart(model, "PlanterBase", Vector3.new(3.2, 0.5, 3.2), cframe * CFrame.new(0, 0.25, 0), stoneColor, Enum.Material.Slate)
	createPart(model, "PlanterBody", Vector3.new(2.8, 2.4, 2.8), cframe * CFrame.new(0, 1.5, 0), Color3.fromRGB(75, 72, 78), Enum.Material.Cobblestone)
	createPart(model, "PlanterRim", Vector3.new(3.4, 0.5, 3.4), cframe * CFrame.new(0, 2.8, 0), stoneColor, Enum.Material.Slate)

	-- Dark Earth
	createPart(model, "EarthBed", Vector3.new(2.5, 0.2, 2.5), cframe * CFrame.new(0, 2.7, 0), Color3.fromRGB(45, 35, 25), Enum.Material.Ground)

	-- Bioluminescent Night-Blooming Buds
	local fCF = cframe * CFrame.new(0, 3.0, 0)
	createPart(model, "FernLeaves", Vector3.new(2.2, 1.6, 2.2), fCF, Color3.fromRGB(40, 75, 50), Enum.Material.Grass)
	local bud1 = createPart(model, "BiolumBud1", Vector3.new(0.5, 0.5, 0.5), fCF * CFrame.new(-0.5, 0.9, 0.3), Color3.fromRGB(64, 196, 255), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	local bud2 = createPart(model, "BiolumBud2", Vector3.new(0.4, 0.4, 0.4), fCF * CFrame.new(0.6, 0.7, -0.4), Color3.fromRGB(156, 39, 176), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(bud1, Color3.fromRGB(64, 196, 255), 1.0, 6)

	model.Parent = parent
	return model
end

-- 18. Antiquarian's Vault Display Cabinet with Rare Artifacts & Illuminated Relics
function EnvironmentProps.CreateAntiquarianDisplayCabinet(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "AntiquarianDisplayCabinet"

	local mahogany = Color3.fromRGB(58, 34, 22)
	local goldTrim = Color3.fromRGB(225, 180, 50)
	local velvet = Color3.fromRGB(80, 20, 30)

	-- Stepped Plinth Base
	createPart(model, "CabinetBase", Vector3.new(10.0, 1.4, 3.2), cframe * CFrame.new(0, 0.7, 0), mahogany, Enum.Material.WoodPlanks)
	createPart(model, "BaseGoldTrim", Vector3.new(10.4, 0.3, 3.4), cframe * CFrame.new(0, 1.4, 0), goldTrim, Enum.Material.Metal)

	-- Mahogany Vertical Pillars & Crown Cornice
	createPart(model, "PillarL", Vector3.new(0.8, 8.5, 0.8), cframe * CFrame.new(-4.6, 5.65, 1.2), mahogany, Enum.Material.Wood)
	createPart(model, "PillarR", Vector3.new(0.8, 8.5, 0.8), cframe * CFrame.new(4.6, 5.65, 1.2), mahogany, Enum.Material.Wood)
	createPart(model, "BackWall", Vector3.new(9.6, 8.5, 0.4), cframe * CFrame.new(0, 5.65, -1.4), Color3.fromRGB(45, 26, 18), Enum.Material.WoodPlanks)

	-- Ornate Carved Crown Cornice & Finials
	createPart(model, "CrownCornice", Vector3.new(10.6, 1.0, 3.6), cframe * CFrame.new(0, 10.4, 0), mahogany, Enum.Material.Wood)
	createPart(model, "CrownGoldPeak", Vector3.new(4.0, 0.8, 0.6), cframe * CFrame.new(0, 11.2, 1.4), goldTrim, Enum.Material.Metal)

	-- Glass Panes (Front & Sides)
	local frontGlass = createPart(model, "FrontGlass", Vector3.new(9.2, 8.2, 0.2), cframe * CFrame.new(0, 5.65, 1.4), Color3.fromRGB(210, 235, 245), Enum.Material.Glass)
	frontGlass.Transparency = 0.6
	local sideGlassL = createPart(model, "SideGlassL", Vector3.new(0.2, 8.2, 2.6), cframe * CFrame.new(-4.6, 5.65, 0), Color3.fromRGB(210, 235, 245), Enum.Material.Glass)
	sideGlassL.Transparency = 0.6
	local sideGlassR = createPart(model, "SideGlassR", Vector3.new(0.2, 8.2, 2.6), cframe * CFrame.new(4.6, 5.65, 0), Color3.fromRGB(210, 235, 245), Enum.Material.Glass)
	sideGlassR.Transparency = 0.6

	-- Velvet Tier Shelves
	createPart(model, "ShelfLower", Vector3.new(9.2, 0.4, 2.6), cframe * CFrame.new(0, 4.2, 0), velvet, Enum.Material.Fabric)
	createPart(model, "ShelfUpper", Vector3.new(9.2, 0.4, 2.6), cframe * CFrame.new(0, 7.2, 0), velvet, Enum.Material.Fabric)

	-- Displayed Artifact 1: Golden Scarab Idol with Turquoise Wings (Lower Shelf, Left)
	local scarabCF = cframe * CFrame.new(-3.0, 4.8, 0)
	createPart(model, "ScarabBody", Vector3.new(1.0, 0.6, 1.4), scarabCF, goldTrim, Enum.Material.Metal, false, false, Enum.PartType.Ball)
	createPart(model, "ScarabWingL", Vector3.new(0.8, 0.1, 1.2), scarabCF * CFrame.new(-0.6, 0.1, 0), Color3.fromRGB(0, 180, 215), Enum.Material.Neon, false, false)
	createPart(model, "ScarabWingR", Vector3.new(0.8, 0.1, 1.2), scarabCF * CFrame.new(0.6, 0.1, 0), Color3.fromRGB(0, 180, 215), Enum.Material.Neon, false, false)

	-- Displayed Artifact 2: Ancient Cuneiform Clay Tablet on Brass Stand (Lower Shelf, Center)
	local tabCF = cframe * CFrame.new(0, 4.8, 0) * CFrame.Angles(math.rad(20), 0, 0)
	createPart(model, "ClayTablet", Vector3.new(1.8, 2.2, 0.3), tabCF, Color3.fromRGB(175, 140, 105), Enum.Material.Sandstone)
	createPart(model, "TabletStand", Vector3.new(1.2, 0.6, 1.0), cframe * CFrame.new(0, 4.6, -0.2), Color3.fromRGB(160, 120, 40), Enum.Material.Metal)

	-- Displayed Artifact 3: Carved Ivory Skull Figurine (Lower Shelf, Right)
	local skullCF = cframe * CFrame.new(3.0, 4.8, 0)
	createPart(model, "IvorySkull", Vector3.new(1.1, 1.2, 1.3), skullCF, Color3.fromRGB(235, 230, 215), Enum.Material.Marble, false, false, Enum.PartType.Ball)
	createPart(model, "SkullEyeL", Vector3.new(0.2, 0.2, 0.2), skullCF * CFrame.new(-0.25, 0.1, 0.6), Color3.fromRGB(244, 67, 54), Enum.Material.Neon, false, false, Enum.PartType.Ball)
	createPart(model, "SkullEyeR", Vector3.new(0.2, 0.2, 0.2), skullCF * CFrame.new(0.25, 0.1, 0.6), Color3.fromRGB(244, 67, 54), Enum.Material.Neon, false, false, Enum.PartType.Ball)

	-- Displayed Artifact 4: Floating Runic Amber Core (Upper Shelf, Center)
	local amber = createPart(model, "AmberRelic", Vector3.new(1.2, 1.8, 1.2), cframe * CFrame.new(0, 8.2, 0), Color3.fromRGB(255, 160, 20), Enum.Material.Neon, false, false, Enum.PartType.Ball)
	createPart(model, "AmberGoldRing", Vector3.new(0.2, 1.6, 1.6), (cframe * CFrame.new(0, 8.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), goldTrim, Enum.Material.Metal, false, false, Enum.PartType.Cylinder)
	local light = createLight(amber, Color3.fromRGB(255, 170, 30), 1.6, 10)

	-- Displayed Artifact 5 & 6: Antiquities Pottery Jars (Upper Shelf, Sides)
	local jarL = createPart(model, "PotteryJarL", Vector3.new(1.6, 1.8, 1.6), cframe * CFrame.new(-2.8, 8.2, 0), Color3.fromRGB(150, 80, 50), Enum.Material.Cobblestone, false, false, Enum.PartType.Cylinder)
	jarL.CFrame = (cframe * CFrame.new(-2.8, 8.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local jarR = createPart(model, "PotteryJarR", Vector3.new(1.4, 2.0, 1.4), cframe * CFrame.new(2.8, 8.3, 0), Color3.fromRGB(70, 110, 120), Enum.Material.Slate, false, false, Enum.PartType.Cylinder)
	jarR.CFrame = (cframe * CFrame.new(2.8, 8.3, 0)) * CFrame.Angles(0, 0, math.rad(90))

	model.Parent = parent
	return model
end

-- 19. Antiquarian's Field Archaeological Excavation Table
function EnvironmentProps.CreateExcavationTable(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "ExcavationTable"

	local wood = Color3.fromRGB(80, 55, 35)
	local brass = Color3.fromRGB(215, 170, 50)

	-- Trestle Drafting Table
	createPart(model, "TableTop", Vector3.new(9.0, 0.5, 4.5), cframe * CFrame.new(0, 3.6, 0), wood, Enum.Material.WoodPlanks)
	createPart(model, "TrestleL", Vector3.new(0.8, 3.4, 3.8), cframe * CFrame.new(-3.8, 1.7, 0), wood, Enum.Material.Wood)
	createPart(model, "TrestleR", Vector3.new(0.8, 3.4, 3.8), cframe * CFrame.new(3.8, 1.7, 0), wood, Enum.Material.Wood)
	createPart(model, "Stretcher", Vector3.new(7.0, 0.4, 0.6), cframe * CFrame.new(0, 1.2, 0), wood, Enum.Material.Wood)

	-- Unrolled Archaeological Map of the Obsidian Fortress & Tombs
	createPart(model, "TombMapParchment", Vector3.new(5.0, 0.05, 3.2), cframe * CFrame.new(-1.0, 3.9, 0), Color3.fromRGB(235, 225, 200), Enum.Material.Sandstone)
	-- Weighted Brass Corner Coins
	createPart(model, "Paperweight1", Vector3.new(0.4, 0.2, 0.4), cframe * CFrame.new(-3.2, 3.95, -1.3), brass, Enum.Material.Metal, false, false, Enum.PartType.Cylinder)
	createPart(model, "Paperweight2", Vector3.new(0.4, 0.2, 0.4), cframe * CFrame.new(1.2, 3.95, 1.3), brass, Enum.Material.Metal, false, false, Enum.PartType.Cylinder)

	-- Brass Surveying Sextant / Compass
	local cCF = cframe * CFrame.new(2.4, 3.9, -0.6)
	createPart(model, "BrassCaliper", Vector3.new(1.2, 0.1, 0.6), cCF, brass, Enum.Material.Metal)

	-- Glass Magnifying Loupe
	local loupeCF = cframe * CFrame.new(-2.2, 3.9, 0.6)
	local lens = createPart(model, "LoupeGlass", Vector3.new(0.1, 0.9, 0.9), loupeCF * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 240, 255), Enum.Material.Glass, false, false, Enum.PartType.Cylinder)
	lens.Transparency = 0.5
	createPart(model, "LoupeHandle", Vector3.new(0.15, 0.9, 0.15), (loupeCF * CFrame.new(0.6, 0, 0)) * CFrame.Angles(0, 0, math.rad(45)), wood, Enum.Material.Wood)

	-- Archaeological Excavation Pickaxe & Trowel resting on bench
	local pickCF = cframe * CFrame.new(3.0, 3.9, 1.2) * CFrame.Angles(0, math.rad(25), 0)
	createPart(model, "PickShaft", Vector3.new(0.2, 0.2, 2.4), pickCF, wood, Enum.Material.Wood)
	createPart(model, "PickHead", Vector3.new(1.4, 0.3, 0.3), pickCF * CFrame.new(0, 0, -1.1), Color3.fromRGB(80, 80, 85), Enum.Material.Metal)

	model.Parent = parent
	return model
end

-- 20. Monumental Dark-Fantasy Heroic Statue (Plaza & Avenue Monument)
function EnvironmentProps.CreateHeroicStatue(parent: Instance, cframe: CFrame, isScholar: boolean?): Model
	local model = Instance.new("Model")
	model.Name = if isScholar then "HeroicScholarStatue" else "HeroicGuardianStatue"

	local basalt = Color3.fromRGB(38, 38, 44)
	local slate = Color3.fromRGB(55, 55, 62)
	local gold = Color3.fromRGB(220, 180, 50)

	-- Stepped Pedestal Foundation
	createPart(model, "PedestalTier1", Vector3.new(7.0, 1.4, 7.0), cframe * CFrame.new(0, 0.7, 0), basalt, Enum.Material.Slate)
	createPart(model, "PedestalTier2", Vector3.new(5.6, 1.2, 5.6), cframe * CFrame.new(0, 2.0, 0), slate, Enum.Material.Cobblestone)
	createPart(model, "PedestalShaft", Vector3.new(4.4, 4.0, 4.4), cframe * CFrame.new(0, 4.6, 0), basalt, Enum.Material.Marble)
	createPart(model, "PedestalCornice", Vector3.new(5.2, 0.8, 5.2), cframe * CFrame.new(0, 7.0, 0), slate, Enum.Material.Slate)
	createPart(model, "GoldDedicationPlaque", Vector3.new(2.8, 1.8, 0.2), cframe * CFrame.new(0, 4.6, 2.25), gold, Enum.Material.Metal)

	-- Carved Hero Figure (Stands atop Pedestal)
	local figCF = cframe * CFrame.new(0, 7.4, 0)
	-- Greaves / Boots
	createPart(model, "BootL", Vector3.new(1.1, 2.8, 1.4), figCF * CFrame.new(-1.0, 1.4, 0), slate, Enum.Material.Slate)
	createPart(model, "BootR", Vector3.new(1.1, 2.8, 1.4), figCF * CFrame.new(1.0, 1.4, 0), slate, Enum.Material.Slate)

	-- Armored Cuirass / Robes
	createPart(model, "Torso", Vector3.new(3.0, 3.6, 1.8), figCF * CFrame.new(0, 4.6, 0), basalt, Enum.Material.Marble)
	createPart(model, "GoldGirdle", Vector3.new(3.2, 0.6, 2.0), figCF * CFrame.new(0, 3.2, 0), gold, Enum.Material.Metal)

	-- Flowing Sculpted Cloak behind
	createPart(model, "CloakBack", Vector3.new(3.4, 7.0, 0.6), figCF * CFrame.new(0, 4.2, -1.0) * CFrame.Angles(math.rad(8), 0, 0), slate, Enum.Material.Slate)

	-- Arms & Shoulders
	createPart(model, "Pauldrons", Vector3.new(4.6, 1.2, 2.2), figCF * CFrame.new(0, 6.2, 0), basalt, Enum.Material.Slate)

	if isScholar then
		-- Scholar holds illuminated open Grimoire and Celestial Staff
		createPart(model, "ArmL", Vector3.new(1.0, 2.4, 1.0), (figCF * CFrame.new(-1.8, 5.0, 0.6)) * CFrame.Angles(math.rad(45), 0, 0), slate, Enum.Material.Slate)
		createPart(model, "Tome", Vector3.new(1.6, 0.4, 2.2), figCF * CFrame.new(-1.4, 5.8, 1.4) * CFrame.Angles(math.rad(30), 0, 0), gold, Enum.Material.Metal)
		-- Celestial Staff in Right Hand
		createPart(model, "StaffShaft", Vector3.new(0.3, 10.0, 0.3), figCF * CFrame.new(1.8, 5.0, 0.8), basalt, Enum.Material.Metal)
		local orb = createPart(model, "StaffOrb", Vector3.new(1.2, 1.2, 1.2), figCF * CFrame.new(1.8, 10.2, 0.8), Color3.fromRGB(64, 196, 255), Enum.Material.Neon, false, false, Enum.PartType.Ball)
		createLight(orb, Color3.fromRGB(64, 196, 255), 1.8, 12)
	else
		-- Guardian Knight rests hands upon pommel of massive Claymore
		createPart(model, "ClaymoreBlade", Vector3.new(0.4, 6.5, 1.2), figCF * CFrame.new(0, 3.2, 1.2), Color3.fromRGB(180, 185, 195), Enum.Material.Metal)
		createPart(model, "ClaymoreCrossguard", Vector3.new(2.6, 0.4, 0.4), figCF * CFrame.new(0, 6.4, 1.2), gold, Enum.Material.Metal)
		createPart(model, "ClaymorePommel", Vector3.new(0.6, 0.6, 0.6), figCF * CFrame.new(0, 7.8, 1.2), gold, Enum.Material.Metal, false, false, Enum.PartType.Ball)
	end

	-- Helmeted Head / Crowned Hood
	createPart(model, "HelmHead", Vector3.new(1.6, 2.0, 1.6), figCF * CFrame.new(0, 7.2, 0), basalt, Enum.Material.Marble)
	createPart(model, "CrownCrest", Vector3.new(1.8, 0.8, 1.8), figCF * CFrame.new(0, 8.2, 0), gold, Enum.Material.Metal)

	model.Parent = parent
	return model
end

-- 21. Bioluminescent Ancient Wispwood Fantasy Tree
function EnvironmentProps.CreateWispwoodTree(parent: Instance, cframe: CFrame, leafGlowColor: Color3?): Model
	local model = Instance.new("Model")
	model.Name = "AncientWispwoodTree"

	local barkCol = Color3.fromRGB(42, 32, 28)
	local foliageCol = Color3.fromRGB(28, 52, 44)
	local glow = leafGlowColor or Color3.fromRGB(64, 196, 255)

	-- Gnarled Twisted Roots Gripping Paving
	local rootAngles = { 0, 72, 144, 216, 288 }
	for _, a in ipairs(rootAngles) do
		local rad = math.rad(a)
		local rootCF = (cframe * CFrame.new(math.cos(rad) * 2.2, 0.6, math.sin(rad) * 2.2)) * CFrame.Angles(0, -rad, math.rad(28))
		createPart(model, "Root_" .. tostring(a), Vector3.new(1.2, 2.8, 1.4), rootCF, barkCol, Enum.Material.Wood)
	end

	-- Massive Main Gnarled Trunk (Tapering 3 sections)
	local trunk1 = createPart(model, "TrunkBase", Vector3.new(4.8, 3.2, 3.2), (cframe * CFrame.new(0, 2.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), barkCol, Enum.Material.Wood, true, true, Enum.PartType.Cylinder)
	local trunk2 = createPart(model, "TrunkMid", Vector3.new(5.2, 2.6, 2.6), (cframe * CFrame.new(0.4, 6.8, 0.2)) * CFrame.Angles(math.rad(6), 0, math.rad(84)), barkCol, Enum.Material.Wood, true, true, Enum.PartType.Cylinder)
	local trunk3 = createPart(model, "TrunkUpper", Vector3.new(5.0, 2.0, 2.0), (cframe * CFrame.new(-0.2, 11.2, -0.3)) * CFrame.Angles(math.rad(-8), 0, math.rad(96)), barkCol, Enum.Material.Wood, true, true, Enum.PartType.Cylinder)

	-- Spreading Canopy Branches
	local branchOffsets = {
		{ cf = CFrame.new(-3.5, 14.5, -1.5) * CFrame.Angles(math.rad(-25), math.rad(-45), math.rad(35)), w = 9, h = 4, d = 9 },
		{ cf = CFrame.new(3.8, 14.8, 2.0) * CFrame.Angles(math.rad(20), math.rad(60), math.rad(-30)), w = 10, h = 4, d = 10 },
		{ cf = CFrame.new(0, 17.5, 0), w = 11, h = 5, d = 11 },
		{ cf = CFrame.new(1.5, 15.2, -3.5) * CFrame.Angles(math.rad(-35), math.rad(30), 0), w = 8, h = 4, d = 8 },
	}

	for i, b in ipairs(branchOffsets) do
		-- Dark Fantasy Foliage Layer
		local foliage = createPart(model, "Canopy_" .. tostring(i), Vector3.new(b.w, b.h, b.d), cframe * b.cf, foliageCol, Enum.Material.Grass, true, true, Enum.PartType.Ball)
		
		-- Bioluminescent Hanging Wisp Orb
		local wisp = createPart(model, "WispOrb_" .. tostring(i), Vector3.new(0.9, 0.9, 0.9), cframe * b.cf * CFrame.new(0, -b.h * 0.45, 0), glow, Enum.Material.Neon, false, false, Enum.PartType.Ball)
		createLight(wisp, glow, 1.4, 10)
	end

	model.Parent = parent
	return model
end

local function getStallColor(stallType: string): Color3
	if stallType == "Textiles" then
		return Color3.fromRGB(150, 35, 45) -- Crimson
	elseif stallType == "Spices" then
		return Color3.fromRGB(215, 150, 30) -- Saffron Gold
	elseif stallType == "Elixirs" then
		return Color3.fromRGB(46, 125, 50) -- Forest Emerald
	elseif stallType == "Runesmith" then
		return Color3.fromRGB(103, 58, 183) -- Mystic Amethyst
	else
		return Color3.fromRGB(35, 75, 120) -- Deep Lapis Blue
	end
end

-- 22. Colorful Market Stall with Striped Canopy, Merchandise & Produce
function EnvironmentProps.CreateMarketStall(
	parent: Instance,
	cframe: CFrame,
	stallType: string -- "Textiles", "Spices", "Pottery", "Salvage"
): Model
	local model = Instance.new("Model")
	model.Name = "MarketStall_" .. stallType

	local wood = Color3.fromRGB(75, 48, 28)
	local primaryColor = getStallColor(stallType)

	-- 4 Corner Timber Posts
	createPart(model, "PostFL", Vector3.new(0.6, 8.5, 0.6), cframe * CFrame.new(-4.5, 4.25, 3.2), wood, Enum.Material.Wood)
	createPart(model, "PostFR", Vector3.new(0.6, 8.5, 0.6), cframe * CFrame.new(4.5, 4.25, 3.2), wood, Enum.Material.Wood)
	createPart(model, "PostBL", Vector3.new(0.6, 9.5, 0.6), cframe * CFrame.new(-4.5, 4.75, -3.2), wood, Enum.Material.Wood)
	createPart(model, "PostBR", Vector3.new(0.6, 9.5, 0.6), cframe * CFrame.new(4.5, 4.75, -3.2), wood, Enum.Material.Wood)

	-- Sloped Striped Canvas Awning
	local canopyCF = (cframe * CFrame.new(0, 9.0, 0)) * CFrame.Angles(math.rad(-10), 0, 0)
	createPart(model, "StallCanopy", Vector3.new(10.2, 0.3, 7.8), canopyCF, primaryColor, Enum.Material.Fabric)

	-- Scalloped Front Valance
	createPart(model, "CanopyValance", Vector3.new(10.2, 0.8, 0.2), cframe * CFrame.new(0, 8.1, 3.7), Color3.fromRGB(240, 220, 180), Enum.Material.Fabric)

	-- Display Counter Table
	createPart(model, "StallCounter", Vector3.new(9.2, 3.2, 3.4), cframe * CFrame.new(0, 1.6, 0), wood, Enum.Material.WoodPlanks)
	createPart(model, "CounterLedge", Vector3.new(9.6, 0.4, 3.8), cframe * CFrame.new(0, 3.3, 0), Color3.fromRGB(95, 62, 38), Enum.Material.WoodPlanks)

	-- Hanging Lantern under canopy
	local lamp = createPart(model, "StallLamp", Vector3.new(0.6, 0.9, 0.6), cframe * CFrame.new(0, 7.6, 0), Color3.fromRGB(255, 200, 110), Enum.Material.Neon, false, false)
	createLight(lamp, Color3.fromRGB(255, 200, 110), 1.6, 12)

	-- Specific Merchandise Based on Stall Type
	if stallType == "Textiles" then
		-- Rolled Rugs & Dyed Cloth Stacks
		local clothColors = { Color3.fromRGB(160, 35, 45), Color3.fromRGB(30, 80, 150), Color3.fromRGB(210, 160, 40) }
		for i, col in ipairs(clothColors) do
			createPart(model, "ClothBolt_" .. tostring(i), Vector3.new(2.4, 0.6, 0.8), cframe * CFrame.new(-2.6 + (i - 1) * 2.6, 3.7, 0), col, Enum.Material.Fabric)
		end
	elseif stallType == "Spices" then
		-- Clay Spice Bowls with Saffron, Paprika, Mint, Indigo
		local spices = {
			{ col = Color3.fromRGB(245, 180, 20), x = -3.0 },
			{ col = Color3.fromRGB(195, 45, 30), x = -1.0 },
			{ col = Color3.fromRGB(45, 140, 60), x = 1.0 },
			{ col = Color3.fromRGB(50, 60, 160), x = 3.0 },
		}
		for i, sp in ipairs(spices) do
			local bowl = createPart(model, "SpiceBowl_" .. tostring(i), Vector3.new(0.4, 1.4, 1.4), (cframe * CFrame.new(sp.x, 3.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(160, 100, 60), Enum.Material.Cobblestone, true, true, Enum.PartType.Cylinder)
			createPart(model, "SpiceMound_" .. tostring(i), Vector3.new(1.1, 0.5, 1.1), cframe * CFrame.new(sp.x, 3.9, 0), sp.col, Enum.Material.Sandstone, false, false, Enum.PartType.Ball)
		end
	elseif stallType == "Elixirs" then
		-- Glowing Potion Phials & Flasks
		local potions = {
			{ col = Color3.fromRGB(76, 215, 80), x = -2.8 },
			{ col = Color3.fromRGB(64, 196, 255), x = -0.9 },
			{ col = Color3.fromRGB(233, 30, 99), x = 1.0 },
			{ col = Color3.fromRGB(255, 180, 50), x = 2.9 },
		}
		for i, p in ipairs(potions) do
			local flask = createPart(model, "ElixirFlask_" .. i, Vector3.new(0.8, 1.4, 0.8), cframe * CFrame.new(p.x, 4.0, 0), p.col, Enum.Material.Neon, false, false, Enum.PartType.Cylinder)
			flask.CFrame = cframe * CFrame.new(p.x, 4.0, 0) * CFrame.Angles(0, 0, math.rad(90))
			createLight(flask, p.col, 1.4, 8)
		end
	elseif stallType == "Runesmith" then
		-- Inscribed Runic Stones & Polished Talismans
		local runes = {
			{ col = Color3.fromRGB(186, 104, 200), x = -2.5 },
			{ col = Color3.fromRGB(100, 255, 180), x = 0.0 },
			{ col = Color3.fromRGB(255, 215, 0), x = 2.5 },
		}
		for i, r in ipairs(runes) do
			createPart(model, "RuneStone_" .. i, Vector3.new(1.6, 0.4, 1.6), cframe * CFrame.new(r.x, 3.6, 0), Color3.fromRGB(45, 45, 52), Enum.Material.Slate)
			local glyph = createPart(model, "Glyph_" .. i, Vector3.new(1.0, 0.1, 1.0), cframe * CFrame.new(r.x, 3.85, 0), r.col, Enum.Material.Neon, false, false)
			createLight(glyph, r.col, 1.5, 8)
		end
	else -- "Salvage" or "Pottery"
		-- Salvaged Iron Gears, Antique Urns & Crates
		createPart(model, "SalvageGear", Vector3.new(0.3, 1.8, 1.8), (cframe * CFrame.new(-2.2, 4.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(180, 130, 40), Enum.Material.Metal, false, false, Enum.PartType.Cylinder)
		local urn = createPart(model, "StallUrn", Vector3.new(1.8, 2.0, 1.8), (cframe * CFrame.new(2.2, 4.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 80, 50), Enum.Material.Cobblestone, false, false, Enum.PartType.Cylinder)
	end

	model.Parent = parent
	return model
end

-- 23. Monumental 4-Tier Town Square Clocktower & Bell Spire (42 studs tall)
function EnvironmentProps.CreateClockTower(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "TownClockTower"

	local stoneColor = Color3.fromRGB(52, 50, 56)
	local trimColor = Color3.fromRGB(75, 72, 78)
	local roofColor = Color3.fromRGB(42, 60, 58) -- Verdigris aged copper
	local goldColor = Color3.fromRGB(225, 185, 50)

	-- Tier 1: Heavy Ashlar Base Plinth & Portico (Y: 0 to 12)
	createPart(model, "BasePlinth", Vector3.new(14, 2, 14), cframe * CFrame.new(0, 1, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Basalt)
	createPart(model, "BaseShaft", Vector3.new(12, 10, 12), cframe * CFrame.new(0, 7, 0), stoneColor, Enum.Material.Slate)
	createPart(model, "BaseStringCourse", Vector3.new(13.4, 1.2, 13.4), cframe * CFrame.new(0, 12.6, 0), trimColor, Enum.Material.Cobblestone)
	-- Arched portal doorway at base
	createPart(model, "TowerDoor", Vector3.new(4.5, 7, 0.6), cframe * CFrame.new(0, 5.5, 6.0), Color3.fromRGB(50, 32, 20), Enum.Material.WoodPlanks)

	-- Tier 2: Slender Mid-Tower Shaft with Slit Arrow Windows (Y: 13 to 27)
	createPart(model, "MidShaft", Vector3.new(10.5, 14, 10.5), cframe * CFrame.new(0, 20, 0), stoneColor, Enum.Material.Slate)
	-- Slit Windows with Golden Grilles
	for faceAngle = 0, 270, 90 do
		local fRad = math.rad(faceAngle)
		local winCF = (cframe * CFrame.new(0, 21, 0)) * CFrame.Angles(0, fRad, 0) * CFrame.new(0, 0, 5.3)
		createPart(model, "ArrowSlit_" .. faceAngle, Vector3.new(1.0, 4.5, 0.4), winCF, Color3.fromRGB(20, 20, 25), Enum.Material.Metal)
	end
	createPart(model, "MidCornice", Vector3.new(12.2, 1.4, 12.2), cframe * CFrame.new(0, 27.7, 0), trimColor, Enum.Material.Cobblestone)

	-- Tier 3: Open Arched Belfry & 4 Luminous Clock Faces (Y: 28 to 36)
	createPart(model, "BelfryFloor", Vector3.new(11.5, 1.0, 11.5), cframe * CFrame.new(0, 29, 0), stoneColor, Enum.Material.Slate)
	-- 4 Corner Belfry Pillars
	for _, pX in ipairs({ -5, 5 }) do
		for _, pZ in ipairs({ -5, 5 }) do
			createPart(model, "BelfryCol_" .. pX .. "_" .. pZ, Vector3.new(1.6, 7.5, 1.6), cframe * CFrame.new(pX, 33.25, pZ), trimColor, Enum.Material.Cobblestone)
		end
	end
	-- Great Bronze Sanctuary Bell inside Belfry
	local bell = createPart(model, "SanctuaryBell", Vector3.new(3.5, 4.0, 3.5), cframe * CFrame.new(0, 33.5, 0), Color3.fromRGB(180, 120, 45), Enum.Material.Metal, true, false, Enum.PartType.Ball)
	createPart(model, "BellRim", Vector3.new(4.2, 0.6, 4.2), cframe * CFrame.new(0, 31.8, 0), Color3.fromRGB(205, 145, 55), Enum.Material.Metal)

	-- 4 Luminous Golden Clock Faces (North, South, East, West)
	for cAngle = 0, 270, 90 do
		local cRad = math.rad(cAngle)
		local dialCF = (cframe * CFrame.new(0, 33.5, 0)) * CFrame.Angles(0, cRad, 0) * CFrame.new(0, 0, 5.8)
		local dialRim = createPart(model, "ClockRim_" .. cAngle, Vector3.new(0.4, 4.4, 4.4), dialCF * CFrame.Angles(0, 0, math.rad(90)), goldColor, Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
		local dialGlow = createPart(model, "ClockGlow_" .. cAngle, Vector3.new(0.5, 3.8, 3.8), dialCF * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 235, 175), Enum.Material.Neon, true, false, Enum.PartType.Cylinder)
		createLight(dialGlow, Color3.fromRGB(255, 225, 150), 1.8, 14)
	end
	createPart(model, "BelfryRoofBase", Vector3.new(12.5, 1.2, 12.5), cframe * CFrame.new(0, 37.6, 0), trimColor, Enum.Material.Cobblestone)

	-- Tier 4: Steep Pyramidal Copper Spire with Gold Finial (Y: 38 to 48)
	createPart(model, "SpireRoof", Vector3.new(11, 9, 11), cframe * CFrame.new(0, 42.7, 0), roofColor, Enum.Material.Slate)
	-- Gold Spire Needle & Weather Vane
	createPart(model, "SpireRod", Vector3.new(0.5, 5.0, 0.5), cframe * CFrame.new(0, 49.5, 0), goldColor, Enum.Material.Metal)
	local spireOrb = createPart(model, "SpireOrb", Vector3.new(1.4, 1.4, 1.4), cframe * CFrame.new(0, 52.2, 0), goldColor, Enum.Material.Metal, true, false, Enum.PartType.Ball)
	createLight(spireOrb, Color3.fromRGB(255, 215, 60), 2.0, 16)

	model.Parent = parent
	return model
end

-- 24. Carved Directional Signpost with Multi-Directional Guidance Arrows
function EnvironmentProps.CreateDirectionalSignpost(
	parent: Instance,
	cframe: CFrame,
	signs: { { text: string, angle: number } }
): Model
	local model = Instance.new("Model")
	model.Name = "DirectionalSignpost"

	local woodCol = Color3.fromRGB(65, 42, 25)
	local metalCol = Color3.fromRGB(45, 45, 50)
	local goldCol = Color3.fromRGB(255, 215, 0)

	-- Stone Base Collar
	createPart(model, "SignBase", Vector3.new(1.8, 0.8, 1.8), cframe * CFrame.new(0, 0.4, 0), Color3.fromRGB(65, 65, 70), Enum.Material.Slate)
	-- Wooden Post
	createPart(model, "SignPost", Vector3.new(0.7, 8.5, 0.7), cframe * CFrame.new(0, 4.65, 0), woodCol, Enum.Material.Wood)
	createPart(model, "PostCap", Vector3.new(0.9, 0.4, 0.9), cframe * CFrame.new(0, 8.95, 0), metalCol, Enum.Material.Metal)

	-- Hanging Lantern at top
	local lamp = createPart(model, "SignLamp", Vector3.new(0.6, 0.9, 0.6), cframe * CFrame.new(0, 8.3, 0.8), Color3.fromRGB(255, 210, 120), Enum.Material.Neon, false, false)
	createLight(lamp, Color3.fromRGB(255, 210, 120), 1.6, 12)

	-- Attached Sign Arrows at staggered heights
	for i, s in ipairs(signs) do
		local yOffset = 5.0 + (i - 1) * 1.1
		local rotCF = (cframe * CFrame.new(0, yOffset, 0)) * CFrame.Angles(0, math.rad(s.angle), 0)
		local signBoard = createPart(model, "SignBoard_" .. tostring(i), Vector3.new(3.8, 0.8, 0.25), rotCF * CFrame.new(1.9, 0, 0), woodCol, Enum.Material.WoodPlanks)

		-- Pointer Arrow Tip
		createPart(model, "SignTip_" .. tostring(i), Vector3.new(0.6, 0.8, 0.25), rotCF * CFrame.new(4.1, 0, 0), goldCol, Enum.Material.Metal)

		-- Glowing Directional Billboard Label
		local bb = Instance.new("BillboardGui")
		bb.Name = "SignBillboard"
		bb.Size = UDim2.new(0, 160, 0, 32)
		bb.StudsOffset = Vector3.new(0, 0.1, 0)
		bb.AlwaysOnTop = false
		bb.MaxDistance = 50
		bb.Parent = signBoard

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = s.text
		lbl.TextColor3 = goldCol
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		lbl.TextStrokeTransparency = 0.2
		lbl.Parent = bb
	end

	model.Parent = parent
	return model
end

-- 25. Realistic Crate and Barrel Merchant Cargo Cluster
function EnvironmentProps.CreateCrateAndBarrelCluster(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "CargoCluster"

	local woodPlank = Color3.fromRGB(80, 52, 32)
	local darkWood = Color3.fromRGB(55, 36, 22)
	local ironCol = Color3.fromRGB(48, 50, 55)

	-- Base Large Ironbound Crate
	createPart(model, "CrateLarge1", Vector3.new(3.2, 3.2, 3.2), cframe * CFrame.new(-1.6, 1.6, 0), woodPlank, Enum.Material.WoodPlanks)
	createPart(model, "CrateTrim1", Vector3.new(3.3, 0.3, 3.3), cframe * CFrame.new(-1.6, 3.1, 0), ironCol, Enum.Material.Metal)

	-- Stacked Smaller Crate on Top
	local crateTopCF = (cframe * CFrame.new(-1.6, 4.4, 0)) * CFrame.Angles(0, math.rad(18), 0)
	createPart(model, "CrateSmall", Vector3.new(2.4, 2.4, 2.4), crateTopCF, woodPlank, Enum.Material.WoodPlanks)

	-- Upright Ale/Oil Casks
	local cask1 = createPart(model, "Cask1", Vector3.new(2.4, 3.2, 2.4), cframe * CFrame.new(1.6, 1.6, -1.0), darkWood, Enum.Material.Wood, true, true, Enum.PartType.Cylinder)
	cask1.CFrame = (cframe * CFrame.new(1.6, 1.6, -1.0)) * CFrame.Angles(0, 0, math.rad(90))
	createPart(model, "CaskHoop1", Vector3.new(0.3, 2.5, 2.5), (cframe * CFrame.new(1.6, 2.2, -1.0)) * CFrame.Angles(0, 0, math.rad(90)), ironCol, Enum.Material.Metal, true, true, Enum.PartType.Cylinder)

	local cask2 = createPart(model, "Cask2", Vector3.new(2.2, 3.0, 2.2), cframe * CFrame.new(1.8, 1.5, 1.6), darkWood, Enum.Material.Wood, true, true, Enum.PartType.Cylinder)
	cask2.CFrame = (cframe * CFrame.new(1.8, 1.5, 1.6)) * CFrame.Angles(0, 0, math.rad(90))

	-- Rolled Canvas Burlap Tarp draped over side
	createPart(model, "RolledTarp", Vector3.new(3.0, 0.8, 1.2), (cframe * CFrame.new(0.2, 0.4, 2.2)) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(175, 160, 135), Enum.Material.Fabric)

	model.Parent = parent
	return model
end

-- 26. Ancient Druidic Megalithic Dolmen Archway
function EnvironmentProps.CreateDolmenArch(parent: Instance, cframe: CFrame, glowColor: Color3?): Model
	local model = Instance.new("Model")
	model.Name = "DruidicDolmenArch"

	local stoneCol = Color3.fromRGB(48, 55, 48)
	local runeGlow = glowColor or Color3.fromRGB(76, 175, 80)

	-- Left Standing Megalith (Rough-hewn pillar)
	createPart(model, "MegalithL", Vector3.new(5.5, 18, 5.5), cframe * CFrame.new(-9, 9, 0), stoneCol, Enum.Material.Slate)
	-- Glowing Rune Inscription on Left Megalith
	createPart(model, "RuneGlyphL", Vector3.new(1.4, 12, 0.3), cframe * CFrame.new(-8.6, 9, 2.8), runeGlow, Enum.Material.Neon, true, false)

	-- Right Standing Megalith
	createPart(model, "MegalithR", Vector3.new(5.5, 18, 5.5), cframe * CFrame.new(9, 9, 0), stoneCol, Enum.Material.Slate)
	createPart(model, "RuneGlyphR", Vector3.new(1.4, 12, 0.3), cframe * CFrame.new(8.6, 9, 2.8), runeGlow, Enum.Material.Neon, true, false)

	-- Massive Horizontal Capstone Lintel Spanning Megaliths
	local capstone = createPart(model, "CapstoneLintel", Vector3.new(28, 4.5, 8), cframe * CFrame.new(0, 19.5, 0), stoneCol, Enum.Material.Slate)
	createPart(model, "CapstoneRune", Vector3.new(20, 1.2, 0.4), cframe * CFrame.new(0, 19.5, 4.1), runeGlow, Enum.Material.Neon, true, false)
	createLight(capstone, runeGlow, 2.2, 18)

	-- Swirling Portal Mist Particles between stones
	local mistPart = createPart(model, "PortalMistCore", Vector3.new(12, 14, 1.0), cframe * CFrame.new(0, 8.5, 0), runeGlow, Enum.Material.Glass, true, false)
	mistPart.Transparency = 0.85

	local pe = Instance.new("ParticleEmitter")
	pe.Name = "DolmenMist"
	pe.Color = ColorSequence.new(runeGlow)
	pe.LightEmission = 0.8
	pe.Size = NumberSequence.new(0.5, 2.0)
	pe.Transparency = NumberSequence.new(0.5, 1.0)
	pe.Lifetime = NumberRange.new(2.5, 4.5)
	pe.Rate = 12
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.SpreadAngle = Vector2.new(35, 35)
	pe.Parent = mistPart

	model.Parent = parent
	return model
end

-- 27. Bioluminescent Wild Mushroom Cluster with Soft Glow
function EnvironmentProps.CreateGlowingMushroomCluster(parent: Instance, cframe: CFrame, glowColor: Color3?): Model
	local model = Instance.new("Model")
	model.Name = "GlowingMushroomCluster"

	local stemCol = Color3.fromRGB(220, 215, 200)
	local capGlow = glowColor or Color3.fromRGB(100, 255, 160)

	local offsets = {
		{ x = 0, z = 0, h = 2.4, r = 1.8 },
		{ x = 1.6, z = 0.8, h = 1.8, r = 1.4 },
		{ x = -1.4, z = 0.6, h = 1.5, r = 1.2 },
		{ x = 0.6, z = -1.4, h = 1.2, r = 1.0 },
		{ x = -0.8, z = -1.2, h = 2.0, r = 1.5 },
	}

	for i, m in ipairs(offsets) do
		local mCF = cframe * CFrame.new(m.x, 0, m.z)
		-- Stem
		createPart(model, "Stem_" .. tostring(i), Vector3.new(0.4, m.h, 0.4), mCF * CFrame.new(0, m.h / 2, 0), stemCol, Enum.Material.SmoothPlastic)
		-- Glowing Cap
		local cap = createPart(model, "Cap_" .. tostring(i), Vector3.new(m.r, 0.6, m.r), mCF * CFrame.new(0, m.h, 0), capGlow, Enum.Material.Neon, true, false, Enum.PartType.Ball)
		if i == 1 then
			createLight(cap, capGlow, 1.5, 10)
		end
	end

	model.Parent = parent
	return model
end

-- 28. Faceted Levitating Void Crystal Cluster
function EnvironmentProps.CreateVoidCrystalCluster(parent: Instance, cframe: CFrame, crystalColor: Color3?): Model
	local model = Instance.new("Model")
	model.Name = "VoidCrystalCluster"

	local rockCol = Color3.fromRGB(22, 18, 28)
	local gemCol = crystalColor or Color3.fromRGB(186, 104, 200)

	-- Jagged Obsidian Rock Base
	createPart(model, "CragBase", Vector3.new(6.0, 2.5, 6.0), cframe * CFrame.new(0, 1.25, 0), rockCol, Enum.Material.Basalt)

	-- 3 Staggered Prismatic Crystals sprouting at dynamic angles
	local crystal1 = createPart(model, "CrystalMain", Vector3.new(2.2, 9.0, 2.2), (cframe * CFrame.new(0, 5.5, 0)) * CFrame.Angles(math.rad(8), math.rad(25), math.rad(-12)), gemCol, Enum.Material.Neon)
	createLight(crystal1, gemCol, 2.4, 16)

	local crystal2 = createPart(model, "CrystalSmallL", Vector3.new(1.6, 6.5, 1.6), (cframe * CFrame.new(-1.8, 4.0, 0.8)) * CFrame.Angles(math.rad(-15), math.rad(40), math.rad(20)), gemCol, Enum.Material.Neon)
	local crystal3 = createPart(model, "CrystalSmallR", Vector3.new(1.4, 5.5, 1.4), (cframe * CFrame.new(1.6, 3.5, -0.8)) * CFrame.Angles(math.rad(20), math.rad(-30), math.rad(-15)), gemCol, Enum.Material.Neon)

	-- Cosmic void particle sparkles
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "VoidSparks"
	pe.Color = ColorSequence.new(gemCol)
	pe.LightEmission = 0.9
	pe.Size = NumberSequence.new(0.2, 0.05)
	pe.Lifetime = NumberRange.new(1.5, 3.0)
	pe.Rate = 10
	pe.Speed = NumberRange.new(0.6, 1.4)
	pe.SpreadAngle = Vector2.new(45, 45)
	pe.Parent = crystal1

	model.Parent = parent
	return model
end

-- 29. Translucent Celestial Forcefield Light Bridge with Guard Rails
function EnvironmentProps.CreateLightBridge(
	parent: Instance,
	startPos: Vector3,
	endPos: Vector3,
	width: number,
	bridgeColor: Color3?
): Model
	local model = Instance.new("Model")
	model.Name = "CelestialLightBridge"

	local bColor = bridgeColor or Color3.fromRGB(64, 196, 255)
	local metalCol = Color3.fromRGB(36, 30, 48)

	local delta = endPos - startPos
	local length = delta.Magnitude
	local center = startPos + delta / 2
	local bridgeCFrame = CFrame.lookAt(center, endPos)

	-- Glowing Luminous Forcefield Pathway (Walkable)
	local walkway = createPart(model, "LightWalkway", Vector3.new(width, 0.8, length), bridgeCFrame, bColor, Enum.Material.Neon, true, true)
	walkway.Transparency = 0.25
	createLight(walkway, bColor, 2.0, 16)

	-- Translucent Hexagonal Lattice Underlay
	local underlay = createPart(model, "ForcefieldLattice", Vector3.new(width + 0.4, 0.4, length), bridgeCFrame * CFrame.new(0, -0.3, 0), Color3.fromRGB(255, 255, 255), Enum.Material.Glass, true, false)
	underlay.Transparency = 0.6

	-- Glowing Safety Energy Guardrails on Left and Right
	local halfW = width / 2
	local railL = createPart(model, "GuardRailL", Vector3.new(0.3, 2.5, length), bridgeCFrame * CFrame.new(-halfW, 1.25, 0), bColor, Enum.Material.Neon, true, true)
	railL.Transparency = 0.4
	local railR = createPart(model, "GuardRailR", Vector3.new(0.3, 2.5, length), bridgeCFrame * CFrame.new(halfW, 1.25, 0), bColor, Enum.Material.Neon, true, true)
	railR.Transparency = 0.4

	-- Anchor Pylons at Start and End
	createPart(model, "PylonStartL", Vector3.new(1.8, 5.0, 1.8), CFrame.new(startPos + (bridgeCFrame.RightVector * -halfW)), metalCol, Enum.Material.Marble)
	createPart(model, "PylonStartR", Vector3.new(1.8, 5.0, 1.8), CFrame.new(startPos + (bridgeCFrame.RightVector * halfW)), metalCol, Enum.Material.Marble)
	createPart(model, "PylonEndL", Vector3.new(1.8, 5.0, 1.8), CFrame.new(endPos + (bridgeCFrame.RightVector * -halfW)), metalCol, Enum.Material.Marble)
	createPart(model, "PylonEndR", Vector3.new(1.8, 5.0, 1.8), CFrame.new(endPos + (bridgeCFrame.RightVector * halfW)), metalCol, Enum.Material.Marble)

	model.Parent = parent
	return model
end

-- 30. Smoldering Volcanic Fissure with Magma Core & Rising Embers
function EnvironmentProps.CreateVolcanicFissure(
	parent: Instance,
	cframe: CFrame,
	length: number?
): Model
	local model = Instance.new("Model")
	model.Name = "VolcanicFissure"
	local len = length or 24.0

	-- Basalt Rift Bedrock Sides
	createPart(model, "CrustLeft", Vector3.new(3.5, 1.4, len), cframe * CFrame.new(-2.8, 0.4, 0) * CFrame.Angles(0, 0, math.rad(6)), Color3.fromRGB(34, 30, 32), Enum.Material.Basalt)
	createPart(model, "CrustRight", Vector3.new(3.5, 1.4, len), cframe * CFrame.new(2.8, 0.4, 0) * CFrame.Angles(0, 0, math.rad(-6)), Color3.fromRGB(34, 30, 32), Enum.Material.Basalt)

	-- Molten Lava Core Surface
	local lava = createPart(model, "LavaCore", Vector3.new(2.8, 0.6, len - 1), cframe * CFrame.new(0, -0.1, 0), Color3.fromRGB(255, 75, 20), Enum.Material.Neon)
	createLight(lava, Color3.fromRGB(255, 90, 25), 2.5, 18)

	-- Rising Fiery Embers & Smoke
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "MagmaEmbers"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 60)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 60, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 20)),
	})
	pe.Size = NumberSequence.new(0.3, 0.05)
	pe.Lifetime = NumberRange.new(2.0, 3.8)
	pe.Rate = 12
	pe.Speed = NumberRange.new(2.0, 4.5)
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.Acceleration = Vector3.new(0, 1.5, 0)
	pe.Parent = lava

	model.Parent = parent
	return model
end

-- 31. Praetorian Garrison Barracks with War Standards & Armory
function EnvironmentProps.CreatePraetorianBarracks(
	parent: Instance,
	cframe: CFrame
): Model
	local model = Instance.new("Model")
	model.Name = "PraetorianBarracks"

	local stoneCol = Color3.fromRGB(60, 58, 64)
	local roofCol = Color3.fromRGB(150, 60, 45) -- Roman Terracotta

	-- Foundation Plinth
	createPart(model, "Foundation", Vector3.new(32, 1.6, 24), cframe * CFrame.new(0, 0.8, 0), Color3.fromRGB(50, 48, 52), Enum.Material.Slate)

	-- Fortified Stone Walls
	createPart(model, "BackWall", Vector3.new(30, 14, 2), cframe * CFrame.new(0, 8.6, -10), stoneCol, Enum.Material.Cobblestone)
	createPart(model, "LeftWall", Vector3.new(2, 14, 20), cframe * CFrame.new(-14, 8.6, 0), stoneCol, Enum.Material.Cobblestone)
	createPart(model, "RightWall", Vector3.new(2, 14, 20), cframe * CFrame.new(14, 8.6, 0), stoneCol, Enum.Material.Cobblestone)

	-- Front Portico Columns
	for i = -1, 1 do
		local colX = i * 11
		EnvironmentProps.CreateFlutedColumn(model, 14, 2.0, cframe * CFrame.new(colX, 1.6, 10))
	end

	-- Terracotta Pitched Roof
	EnvironmentProps.CreatePitchedRoof(model, 34, 26, cframe * CFrame.new(0, 16.5, 0), 24, roofCol)

	-- Imperial War Standards (Crimson & Gold)
	local stdL = createPart(model, "WarBannerL", Vector3.new(0.3, 10, 3.2), cframe * CFrame.new(-8, 9, 10.5), Color3.fromRGB(140, 25, 30), Enum.Material.Fabric)
	createPart(model, "BannerGoldTrimL", Vector3.new(0.35, 1.0, 3.4), cframe * CFrame.new(-8, 4.5, 10.5), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)
	local stdR = createPart(model, "WarBannerR", Vector3.new(0.3, 10, 3.2), cframe * CFrame.new(8, 9, 10.5), Color3.fromRGB(140, 25, 30), Enum.Material.Fabric)
	createPart(model, "BannerGoldTrimR", Vector3.new(0.35, 1.0, 3.4), cframe * CFrame.new(8, 4.5, 10.5), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)

	-- Praetorian Sentry Braziers
	EnvironmentProps.CreateStoneBrazier(model, cframe * CFrame.new(-12, 1.6, 12), Color3.fromRGB(255, 110, 30))
	EnvironmentProps.CreateStoneBrazier(model, cframe * CFrame.new(12, 1.6, 12), Color3.fromRGB(255, 110, 30))

	-- Weapon Rack inside portico
	EnvironmentProps.CreateWeaponRack(model, cframe * CFrame.new(0, 1.6, 2))

	model.Parent = parent
	return model
end

-- 32. Monumental Classical Stone Aqueduct with Flowing Water Channel
function EnvironmentProps.CreateCanalAqueduct(
	parent: Instance,
	startPos: Vector3,
	endPos: Vector3,
	height: number?
): Model
	local model = Instance.new("Model")
	model.Name = "CanalAqueduct"

	local h = height or 18.0
	local delta = endPos - startPos
	local length = delta.Magnitude
	local center = (startPos + endPos) / 2
	local forward = delta.Unit
	local up = Vector3.new(0, 1, 0)
	local right = forward:Cross(up)
	local baseCF = CFrame.fromMatrix(center, right, up, -forward)

	local stoneCol = Color3.fromRGB(70, 68, 72)
	local capCol = Color3.fromRGB(90, 88, 92)

	-- Massive Foundation Piers every 16 studs
	local pierSpacing = 16.0
	local numPiers = math.max(2, math.floor(length / pierSpacing))
	for p = 0, numPiers do
		local t = p / numPiers
		local pierPos = startPos + delta * t
		local pierCF = CFrame.fromMatrix(pierPos + Vector3.new(0, h / 2, 0), right, up, -forward)
		createPart(model, "Pier_" .. p, Vector3.new(4.5, h, 4.5), pierCF, stoneCol, Enum.Material.Slate)
		createPart(model, "PierCapital_" .. p, Vector3.new(5.5, 1.2, 5.5), pierCF * CFrame.new(0, h / 2 + 0.6, 0), capCol, Enum.Material.Cobblestone)
	end

	-- Connecting Arched Spans along top
	createPart(model, "AqueductSpans", Vector3.new(5.0, 3.5, length), baseCF * CFrame.new(0, h + 1.75, 0), stoneCol, Enum.Material.Cobblestone)

	-- Trough Channel Side Walls
	createPart(model, "TroughWallL", Vector3.new(0.8, 2.0, length), baseCF * CFrame.new(-2.1, h + 4.5, 0), capCol, Enum.Material.Slate)
	createPart(model, "TroughWallR", Vector3.new(0.8, 2.0, length), baseCF * CFrame.new(2.1, h + 4.5, 0), capCol, Enum.Material.Slate)

	-- Water Stream Channel
	local water = createPart(model, "AqueductWater", Vector3.new(3.4, 0.4, length), baseCF * CFrame.new(0, h + 3.8, 0), Color3.fromRGB(45, 145, 190), Enum.Material.Glass, true, false)
	water.Transparency = 0.35
	createLight(water, Color3.fromRGB(45, 160, 210), 1.5, 14)

	model.Parent = parent
	return model
end

-- 33. Ancient Druidic Runic Monolith with Climbing Vines
function EnvironmentProps.CreateDruidicMonolith(
	parent: Instance,
	cframe: CFrame,
	runeColor: Color3?
): Model
	local model = Instance.new("Model")
	model.Name = "DruidicMonolith"
	local rCol = runeColor or Color3.fromRGB(76, 215, 110)

	-- Weathered Megalith Shaft
	local stone = createPart(model, "MegalithShaft", Vector3.new(3.8, 14, 2.6), cframe * CFrame.new(0, 7, 0), Color3.fromRGB(50, 58, 52), Enum.Material.Slate)
	stone.CFrame = cframe * CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(2), 0, math.rad(-2))

	-- Carved Spiraling Runic Bands
	for r = 1, 3 do
		local rY = 3.5 + r * 2.8
		local rune = createPart(model, "RuneBand_" .. r, Vector3.new(3.9, 0.8, 2.7), cframe * CFrame.new(0, rY, 0), rCol, Enum.Material.Neon, true, false)
		createLight(rune, rCol, 1.8, 12)
	end

	-- Ivy Vine Clusters Clinging to Base
	createPart(model, "IvyVines1", Vector3.new(4.2, 4.0, 1.2), cframe * CFrame.new(0, 2.5, 1.2), Color3.fromRGB(36, 75, 40), Enum.Material.Grass, true, false)
	createPart(model, "IvyVines2", Vector3.new(1.2, 5.0, 3.0), cframe * CFrame.new(-1.8, 3.0, 0), Color3.fromRGB(40, 85, 45), Enum.Material.Grass, true, false)

	-- Floating Druidic Motes
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "DruidicMotes"
	pe.Color = ColorSequence.new(rCol)
	pe.Size = NumberSequence.new(0.25, 0.05)
	pe.Lifetime = NumberRange.new(2.0, 4.0)
	pe.Rate = 6
	pe.Speed = NumberRange.new(0.5, 1.2)
	pe.Parent = stone

	model.Parent = parent
	return model
end

-- 34. Natural Mossy Boulder Cluster with Weathered Crags
function EnvironmentProps.CreateMossyBoulderCluster(
	parent: Instance,
	cframe: CFrame
): Model
	local model = Instance.new("Model")
	model.Name = "MossyBoulderCluster"

	-- Main Central Boulder
	createPart(model, "BoulderMain", Vector3.new(7.0, 5.5, 6.5), cframe * CFrame.new(0, 2.5, 0), Color3.fromRGB(55, 60, 54), Enum.Material.Slate)
	createPart(model, "MossCapMain", Vector3.new(6.2, 1.2, 5.8), cframe * CFrame.new(0, 5.0, 0), Color3.fromRGB(45, 80, 42), Enum.Material.Grass, true, true, Enum.PartType.Ball)

	-- Secondary Satellite Boulders
	createPart(model, "BoulderWest", Vector3.new(4.5, 3.8, 4.2), cframe * CFrame.new(-4.2, 1.6, 1.2) * CFrame.Angles(math.rad(10), math.rad(25), 0), Color3.fromRGB(50, 54, 48), Enum.Material.Slate)
	createPart(model, "MossCapWest", Vector3.new(4.0, 0.8, 3.8), cframe * CFrame.new(-4.2, 3.2, 1.2), Color3.fromRGB(42, 75, 38), Enum.Material.Grass, true, true, Enum.PartType.Ball)

	createPart(model, "BoulderEast", Vector3.new(3.8, 3.0, 4.8), cframe * CFrame.new(3.8, 1.3, -1.5) * CFrame.Angles(0, math.rad(-35), math.rad(15)), Color3.fromRGB(58, 62, 55), Enum.Material.Slate)

	model.Parent = parent
	return model
end

-- 35. Ancient Fallen Hollow Log with Shelf Fungi
function EnvironmentProps.CreateFallenLog(
	parent: Instance,
	cframe: CFrame,
	length: number?
): Model
	local model = Instance.new("Model")
	model.Name = "FallenHollowLog"
	local len = length or 18.0

	-- Outer Hollow Trunk
	local trunk = createPart(model, "HollowTrunk", Vector3.new(4.2, len, 4.2), cframe * CFrame.new(0, 2.1, 0), Color3.fromRGB(55, 38, 24), Enum.Material.Wood, true, true, Enum.PartType.Cylinder)
	trunk.CFrame = cframe * CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(90))

	-- Moss Blanket on Top
	local moss = createPart(model, "TrunkMoss", Vector3.new(len - 2, 0.6, 2.8), cframe * CFrame.new(0, 4.1, 0), Color3.fromRGB(40, 72, 38), Enum.Material.Grass)

	-- Shelf Fungi Brackets Growing along flanks
	for f = -1, 1 do
		local fX = f * (len * 0.28)
		createPart(model, "ShelfFungusL_" .. f, Vector3.new(1.4, 0.3, 1.2), cframe * CFrame.new(fX, 2.4, 2.1), Color3.fromRGB(160, 130, 85), Enum.Material.SmoothPlastic, true, false, Enum.PartType.Ball)
		createPart(model, "ShelfFungusR_" .. f, Vector3.new(1.2, 0.3, 1.4), cframe * CFrame.new(fX + 1.2, 2.0, -2.1), Color3.fromRGB(180, 145, 95), Enum.Material.SmoothPlastic, true, false, Enum.PartType.Ball)
	end

	model.Parent = parent
	return model
end

-- 36. Monumental Void Crown Spire with Orbital Celestial Rings
function EnvironmentProps.CreateCrownSpire(
	parent: Instance,
	cframe: CFrame
): Model
	local model = Instance.new("Model")
	model.Name = "CrownSpire"

	local voidObsidian = Color3.fromRGB(18, 14, 24)
	local celestialViolet = Color3.fromRGB(186, 104, 200)

	-- Multi-tier Spire Base
	createPart(model, "SpirePlinth", Vector3.new(14, 2.5, 14), cframe * CFrame.new(0, 1.25, 0), voidObsidian, Enum.Material.Marble)
	createPart(model, "SpireTier2", Vector3.new(10, 2.0, 10), cframe * CFrame.new(0, 3.5, 0), voidObsidian, Enum.Material.Marble)

	-- Monumental Central Spire Needle
	createPart(model, "SpireNeedleLower", Vector3.new(4.5, 24, 4.5), cframe * CFrame.new(0, 16, 0), voidObsidian, Enum.Material.Marble)
	createPart(model, "SpireNeedleUpper", Vector3.new(2.5, 18, 2.5), cframe * CFrame.new(0, 37, 0), voidObsidian, Enum.Material.Marble)
	createPart(model, "SpireApex", Vector3.new(1.2, 10, 1.2), cframe * CFrame.new(0, 51, 0), celestialViolet, Enum.Material.Neon)

	-- Concentric Floating Orbital Rings
	local ring1 = createPart(model, "OrbitalRing1", Vector3.new(1.0, 18, 18), cframe * CFrame.new(0, 26, 0), celestialViolet, Enum.Material.Neon, true, false, Enum.PartType.Cylinder)
	ring1.CFrame = cframe * CFrame.new(0, 26, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring1.Transparency = 0.35

	local ring2 = createPart(model, "OrbitalRing2", Vector3.new(0.8, 12, 12), cframe * CFrame.new(0, 38, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	ring2.CFrame = cframe * CFrame.new(0, 38, 0) * CFrame.Angles(0, 0, math.rad(90))

	-- Void Beacon Light
	local beacon = createPart(model, "BeaconOrb", Vector3.new(3.0, 3.0, 3.0), cframe * CFrame.new(0, 32, 0), celestialViolet, Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(beacon, celestialViolet, 3.0, 26)

	-- Upward Ascension Void Motes
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "AscensionMotes"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, celestialViolet),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 140, 240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 20, 90)),
	})
	pe.Size = NumberSequence.new(0.4, 0.1)
	pe.Lifetime = NumberRange.new(3.0, 5.0)
	pe.Rate = 18
	pe.Speed = NumberRange.new(3.0, 6.0)
	pe.Acceleration = Vector3.new(0, 2.0, 0)
	pe.Parent = beacon

	model.Parent = parent
	return model
end

-- 37. Monumental 4-Tier Watchtower with Cantilevered Crow's Nest
function EnvironmentProps.CreateMonumentalWatchtower(
	parent: Instance,
	cframe: CFrame
): Model
	local model = Instance.new("Model")
	model.Name = "MonumentalWatchtower"

	local stoneColor = Color3.fromRGB(68, 68, 72)
	local timberColor = Color3.fromRGB(55, 38, 26)
	local roofColor = Color3.fromRGB(45, 45, 50)

	-- Tier 1: Massive Stone Foundation Plinth
	createPart(model, "TowerPlinth", Vector3.new(16, 3, 16), cframe * CFrame.new(0, 1.5, 0), stoneColor, Enum.Material.Cobblestone)
	createPart(model, "PlinthCap", Vector3.new(15, 0.8, 15), cframe * CFrame.new(0, 3.4, 0), Color3.fromRGB(80, 80, 85), Enum.Material.Slate)

	-- Tier 2: Heavy Timber Corner Columns & Masonry Infill
	for _, dx in ipairs({ -6, 6 }) do
		for _, dz in ipairs({ -6, 6 }) do
			createPart(model, "CornerBeam_" .. dx .. "_" .. dz, Vector3.new(1.8, 20, 1.8), cframe * CFrame.new(dx, 13.4, dz), timberColor, Enum.Material.Wood)
		end
	end
	createPart(model, "TowerBody", Vector3.new(11, 18, 11), cframe * CFrame.new(0, 12.8, 0), Color3.fromRGB(90, 85, 80), Enum.Material.Sandstone)

	-- Tier 3: Cantilevered Machicolation Corbel Deck
	createPart(model, "CorbelDeck", Vector3.new(18, 1.4, 18), cframe * CFrame.new(0, 23.5, 0), timberColor, Enum.Material.WoodPlanks)
	-- Parapet crenellations
	for _, angle in ipairs({ 0, 90, 180, 270 }) do
		local rotCF = cframe * CFrame.new(0, 25.5, 0) * CFrame.Angles(0, math.rad(angle), 0)
		createPart(model, "Parapet_" .. angle, Vector3.new(16, 2.6, 1.0), rotCF * CFrame.new(0, 0, 8.5), stoneColor, Enum.Material.Cobblestone)
	end

	-- Tier 4: Observation Pavilion & Pitched Slate Canopy
	for _, dx in ipairs({ -5.5, 5.5 }) do
		for _, dz in ipairs({ -5.5, 5.5 }) do
			createPart(model, "CanopyPost_" .. dx .. "_" .. dz, Vector3.new(1.2, 8, 1.2), cframe * CFrame.new(dx, 27.5, dz), timberColor, Enum.Material.Wood)
		end
	end
	createPart(model, "TowerRoofPyramid", Vector3.new(17, 4.5, 17), cframe * CFrame.new(0, 33.5, 0), roofColor, Enum.Material.Slate)
	createPart(model, "RoofApexFinial", Vector3.new(0.8, 4.0, 0.8), cframe * CFrame.new(0, 37.0, 0), Color3.fromRGB(220, 180, 50), Enum.Material.Metal)

	-- Watchman's Beacon Fire Sconce
	local beacon = createPart(model, "WatchBeacon", Vector3.new(2.2, 1.8, 2.2), cframe * CFrame.new(0, 25.0, 0), Color3.fromRGB(255, 140, 40), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(beacon, Color3.fromRGB(255, 160, 50), 2.5, 22)

	model.Parent = parent
	return model
end

-- 38. Megalithic Celtic Dolmen Altar Shrine
function EnvironmentProps.CreateDolmenShrine(
	parent: Instance,
	cframe: CFrame
): Model
	local model = Instance.new("Model")
	model.Name = "DolmenShrine"

	local rockColor = Color3.fromRGB(75, 78, 75)
	local runeColor = Color3.fromRGB(80, 220, 140)

	-- Foundation Dais
	createPart(model, "ShrineDais", Vector3.new(14, 1.2, 14), cframe * CFrame.new(0, 0.6, 0), rockColor, Enum.Material.Slate)

	-- 2 Giant Standing Upright Portal Stones
	local uprightL = createPart(model, "UprightPillarL", Vector3.new(3.2, 9.5, 2.6), cframe * CFrame.new(-4.5, 5.2, 0) * CFrame.Angles(0, 0, math.rad(-3)), rockColor, Enum.Material.Rock)
	local uprightR = createPart(model, "UprightPillarR", Vector3.new(3.2, 9.5, 2.6), cframe * CFrame.new(4.5, 5.2, 0) * CFrame.Angles(0, 0, math.rad(3)), rockColor, Enum.Material.Rock)

	-- Massive Rough Table Capstone
	local capstone = createPart(model, "CapstoneSlab", Vector3.new(15, 2.2, 8.5), cframe * CFrame.new(0, 10.5, 0) * CFrame.Angles(math.rad(2), 0, math.rad(-1)), rockColor, Enum.Material.Rock)

	-- Central Offering Altar Stone
	local altar = createPart(model, "OfferingAltar", Vector3.new(4.5, 2.2, 3.5), cframe * CFrame.new(0, 1.7, 0), Color3.fromRGB(55, 58, 55), Enum.Material.Slate)
	-- Glowing Inlaid Druidic Rune
	local rune = createPart(model, "RuneInlay", Vector3.new(2.8, 0.2, 2.2), cframe * CFrame.new(0, 2.85, 0), runeColor, Enum.Material.Neon)
	createLight(rune, runeColor, 1.8, 12)

	model.Parent = parent
	return model
end

-- 39. Volcanic Skull Brazier with Horned Reliquary
function EnvironmentProps.CreateVolcanicSkullBrazier(
	parent: Instance,
	cframe: CFrame
): Model
	local model = Instance.new("Model")
	model.Name = "VolcanicSkullBrazier"

	local basaltColor = Color3.fromRGB(32, 28, 30)
	local lavaColor = Color3.fromRGB(255, 80, 20)

	-- Stepped Basalt Pedestal
	createPart(model, "PedestalBase", Vector3.new(5.0, 1.2, 5.0), cframe * CFrame.new(0, 0.6, 0), basaltColor, Enum.Material.Basalt)
	createPart(model, "PedestalShaft", Vector3.new(2.8, 4.0, 2.8), cframe * CFrame.new(0, 3.0, 0), basaltColor, Enum.Material.Basalt)
	createPart(model, "PedestalBowl", Vector3.new(4.2, 1.6, 4.2), cframe * CFrame.new(0, 5.6, 0), basaltColor, Enum.Material.Basalt)

	-- 4 Demon Horn Prongs clutching fire
	for _, angle in ipairs({ 45, 135, 225, 315 }) do
		local hCF = cframe * CFrame.new(0, 6.2, 0) * CFrame.Angles(0, math.rad(angle), 0)
		createPart(model, "HornProng_" .. angle, Vector3.new(0.6, 2.2, 0.6), hCF * CFrame.new(0, 0.8, 1.8) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(20, 18, 20), Enum.Material.Metal)
	end

	-- Glowing Magma Core
	local magma = createPart(model, "MagmaCore", Vector3.new(2.6, 1.0, 2.6), cframe * CFrame.new(0, 6.2, 0), lavaColor, Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(magma, lavaColor, 2.6, 16)

	-- Flame Emitter
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "BrazierFlames"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 60)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 60, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 10, 10)),
	})
	pe.Size = NumberSequence.new(1.0, 0.2)
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Rate = 12
	pe.Speed = NumberRange.new(2.0, 4.0)
	pe.Parent = magma

	model.Parent = parent
	return model
end

-- 40. Levitating Celestial Void Obelisk
function EnvironmentProps.CreateVoidObelisk(
	parent: Instance,
	cframe: CFrame
): Model
	local model = Instance.new("Model")
	model.Name = "VoidObelisk"

	local voidColor = Color3.fromRGB(15, 12, 22)
	local cosmicColor = Color3.fromRGB(175, 90, 240)

	-- Sunken Astral Dais
	createPart(model, "AstralDais", Vector3.new(8, 0.8, 8), cframe * CFrame.new(0, 0.4, 0), voidColor, Enum.Material.Marble)
	createPart(model, "RuneRing", Vector3.new(6.8, 0.2, 6.8), cframe * CFrame.new(0, 0.85, 0), cosmicColor, Enum.Material.Neon)

	-- Floating Monolithic Needle
	local obelisk = createPart(model, "ObeliskCore", Vector3.new(2.4, 16, 2.4), cframe * CFrame.new(0, 10.5, 0), voidColor, Enum.Material.Marble)
	createPart(model, "ObeliskApex", Vector3.new(1.6, 4.0, 1.6), cframe * CFrame.new(0, 20.0, 0), cosmicColor, Enum.Material.Neon)

	-- Orbiting Levitating Void Shards
	for i = 1, 4 do
		local angle = (i - 1) * 90
		local sCF = cframe * CFrame.new(0, 12 + i * 1.5, 0) * CFrame.Angles(0, math.rad(angle), 0)
		createPart(model, "OrbitShard_" .. i, Vector3.new(0.6, 1.4, 0.6), sCF * CFrame.new(0, 0, 3.2), voidColor, Enum.Material.Neon)
	end

	local light = createLight(obelisk, cosmicColor, 2.2, 18)

	model.Parent = parent
	return model
end

return EnvironmentProps
