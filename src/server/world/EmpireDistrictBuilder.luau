--!strict
-- EmpireDistrictBuilder.luau
-- Authoritative procedural builder for Region 2: The Empire District
-- Constructs a fortified classical Roman/Gothic imperial city:
-- Avenue of the Caesars, Triumphal Gatehouse, Senatorial Forum, Imperial Treasury, and Sunken Aqueduct.

local Workspace = game:GetService("Workspace")
local EnvironmentProps = require(script.Parent.EnvironmentProps)

local EmpireDistrictBuilder = {}

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

function EmpireDistrictBuilder.Build(worldFolder: Folder): Folder
	local empireFolder = Instance.new("Folder")
	empireFolder.Name = "EmpireDistrict"

	local districtCenter = Vector3.new(0, 1, -220)

	----------------------------------------------------------------------
	-- 1. DISTRICT GROUND & PAVEMENT
	----------------------------------------------------------------------
	-- Massive Ashlar Flagstone Foundation
	createPart(empireFolder, "EmpireGround", Vector3.new(180, 2, 220), CFrame.new(districtCenter + Vector3.new(0, -1, 0)), Color3.fromRGB(48, 48, 54), Enum.Material.Slate)

	-- Avenue of the Caesars (North-South Broad Highway)
	createPart(empireFolder, "AvenuePavement", Vector3.new(28, 0.4, 210), CFrame.new(0, 1.2, -220), Color3.fromRGB(72, 70, 75), Enum.Material.Cobblestone)
	createPart(empireFolder, "AvenueCurbL", Vector3.new(2, 0.8, 210), CFrame.new(-15, 1.4, -220), Color3.fromRGB(150, 145, 140), Enum.Material.Marble)
	createPart(empireFolder, "AvenueCurbR", Vector3.new(2, 0.8, 210), CFrame.new(15, 1.4, -220), Color3.fromRGB(150, 145, 140), Enum.Material.Marble)

	----------------------------------------------------------------------
	-- 2. TRIUMPHAL IMPERIAL GATEHOUSE & WATCHTOWERS (South Border, Z = -115)
	----------------------------------------------------------------------
	local gateZ = -115

	-- Left Watchtower (4-Tier Fortress Bastion)
	createPart(empireFolder, "GateTowerL_Base", Vector3.new(14, 28, 14), CFrame.new(-22, 14, gateZ), Color3.fromRGB(60, 58, 64), Enum.Material.Slate)
	createPart(empireFolder, "GateTowerL_Trim", Vector3.new(16, 2, 16), CFrame.new(-22, 28, gateZ), Color3.fromRGB(180, 140, 60), Enum.Material.Metal)
	createPart(empireFolder, "GateTowerL_Crown", Vector3.new(15, 5, 15), CFrame.new(-22, 31.5, gateZ), Color3.fromRGB(52, 50, 56), Enum.Material.Cobblestone)

	-- Right Watchtower
	createPart(empireFolder, "GateTowerR_Base", Vector3.new(14, 28, 14), CFrame.new(22, 14, gateZ), Color3.fromRGB(60, 58, 64), Enum.Material.Slate)
	createPart(empireFolder, "GateTowerR_Trim", Vector3.new(16, 2, 16), CFrame.new(22, 28, gateZ), Color3.fromRGB(180, 140, 60), Enum.Material.Metal)
	createPart(empireFolder, "GateTowerR_Crown", Vector3.new(15, 5, 15), CFrame.new(22, 31.5, gateZ), Color3.fromRGB(52, 50, 56), Enum.Material.Cobblestone)

	-- Triumphal Archway Lintel & Inscription Block Spanning Road
	local arch = createPart(empireFolder, "TriumphalLintel", Vector3.new(34, 10, 8), CFrame.new(0, 23, gateZ), Color3.fromRGB(75, 72, 78), Enum.Material.Marble)
	createPart(empireFolder, "ArchGoldPediment", Vector3.new(36, 3, 9), CFrame.new(0, 29.5, gateZ), Color3.fromRGB(220, 180, 50), Enum.Material.Metal)

	-- Portcullis Grill
	createPart(empireFolder, "GatePortcullis", Vector3.new(26, 18, 1.4), CFrame.new(0, 10, gateZ), Color3.fromRGB(35, 38, 42), Enum.Material.Metal, true, false)

	-- Return Travel Gate Marker (Entrance from Northern Imperial Highway at Z = -3000)
	local returnGate = createPart(empireFolder, "ReturnPad_Market", Vector3.new(14, 0.6, 8), CFrame.new(0, 12.3, -2985), Color3.fromRGB(220, 180, 50), Enum.Material.Neon, true, false)
	local retPrompt = Instance.new("ProximityPrompt")
	retPrompt.Name = "Prompt_ReturnMarket_Empire"
	retPrompt.ObjectText = "Forgotten Market Portal"
	retPrompt.ActionText = "Return to Market Settlement"
	retPrompt.HoldDuration = 0.5
	retPrompt.MaxActivationDistance = 14
	retPrompt.Parent = returnGate

	-- Sentry Braziers atop towers
	local brazierL = createPart(empireFolder, "TowerBrazierL", Vector3.new(3, 2, 3), CFrame.new(-22, 35, gateZ), Color3.fromRGB(255, 100, 20), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(brazierL, Color3.fromRGB(255, 120, 30), 2.5, 20)
	local brazierR = createPart(empireFolder, "TowerBrazierR", Vector3.new(3, 2, 3), CFrame.new(22, 35, gateZ), Color3.fromRGB(255, 100, 20), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(brazierR, Color3.fromRGB(255, 120, 30), 2.5, 20)

	----------------------------------------------------------------------
	-- 3. AVENUE COLONNADE & IMPERIAL BANNERS
	----------------------------------------------------------------------
	for zStep = -135, -290, -30 do
		-- West Column
		local colW = createPart(empireFolder, "AvenueCol_W_" .. tostring(zStep), Vector3.new(1.8, 14, 1.8), CFrame.new(-16, 8, zStep), Color3.fromRGB(195, 190, 185), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
		colW.CFrame = CFrame.new(-16, 8, zStep) * CFrame.Angles(0, 0, math.rad(90))
		createPart(empireFolder, "ColCap_W_" .. tostring(zStep), Vector3.new(2.8, 1.2, 2.8), CFrame.new(-16, 15.5, zStep), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)

		-- East Column
		local colE = createPart(empireFolder, "AvenueCol_E_" .. tostring(zStep), Vector3.new(1.8, 14, 1.8), CFrame.new(16, 8, zStep), Color3.fromRGB(195, 190, 185), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
		colE.CFrame = CFrame.new(16, 8, zStep) * CFrame.Angles(0, 0, math.rad(90))
		createPart(empireFolder, "ColCap_E_" .. tostring(zStep), Vector3.new(2.8, 1.2, 2.8), CFrame.new(16, 15.5, zStep), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)

		-- Hanging Red & Gold Imperial Banner
		local bannerW = createPart(empireFolder, "Banner_W_" .. tostring(zStep), Vector3.new(0.3, 7.0, 3.2), CFrame.new(-14, 10.5, zStep), Color3.fromRGB(160, 25, 35), Enum.Material.Fabric)
		createPart(empireFolder, "BannerTrim_W_" .. tostring(zStep), Vector3.new(0.35, 1.0, 3.3), CFrame.new(-14, 7.0, zStep), Color3.fromRGB(235, 195, 50), Enum.Material.Metal)
		local bannerE = createPart(empireFolder, "Banner_E_" .. tostring(zStep), Vector3.new(0.3, 7.0, 3.2), CFrame.new(14, 10.5, zStep), Color3.fromRGB(160, 25, 35), Enum.Material.Fabric)
		createPart(empireFolder, "BannerTrim_E_" .. tostring(zStep), Vector3.new(0.35, 1.0, 3.3), CFrame.new(14, 7.0, zStep), Color3.fromRGB(235, 195, 50), Enum.Material.Metal)
	end

	----------------------------------------------------------------------
	-- 4. SENATORIAL FORUM & MONUMENTAL ROTUNDA (Center, Z = -220)
	----------------------------------------------------------------------
	local forumCenter = Vector3.new(0, 1, -220)

	-- Stepped Circular Marble Dais
	local dais1 = createPart(empireFolder, "ForumDais1", Vector3.new(1.4, 56, 56), CFrame.new(forumCenter + Vector3.new(0, 0.7, 0)), Color3.fromRGB(190, 185, 180), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	dais1.CFrame = CFrame.new(forumCenter + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local dais2 = createPart(empireFolder, "ForumDais2", Vector3.new(1.2, 44, 44), CFrame.new(forumCenter + Vector3.new(0, 2.0, 0)), Color3.fromRGB(220, 215, 210), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	dais2.CFrame = CFrame.new(forumCenter + Vector3.new(0, 2.0, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Central Golden Imperial Eagle Monolith
	local obeliskBase = createPart(empireFolder, "EagleObeliskBase", Vector3.new(6, 4, 6), CFrame.new(forumCenter + Vector3.new(0, 4.6, 0)), Color3.fromRGB(42, 40, 45), Enum.Material.Marble)
	local obeliskShaft = createPart(empireFolder, "EagleObeliskShaft", Vector3.new(4, 16, 4), CFrame.new(forumCenter + Vector3.new(0, 14.6, 0)), Color3.fromRGB(30, 28, 35), Enum.Material.Marble)
	
	-- Golden Eagle Sculpture atop shaft
	local eagleBody = createPart(empireFolder, "EagleBody", Vector3.new(3, 3, 3), CFrame.new(forumCenter + Vector3.new(0, 24, 0)), Color3.fromRGB(245, 205, 50), Enum.Material.Metal, true, false, Enum.PartType.Ball)
	local wingL = createPart(empireFolder, "EagleWingL", Vector3.new(1.2, 4.5, 2.2), CFrame.new(forumCenter + Vector3.new(-3, 25.5, 0)) * CFrame.Angles(0, 0, math.rad(-30)), Color3.fromRGB(240, 195, 45), Enum.Material.Metal, true, false)
	local wingR = createPart(empireFolder, "EagleWingR", Vector3.new(1.2, 4.5, 2.2), CFrame.new(forumCenter + Vector3.new(3, 25.5, 0)) * CFrame.Angles(0, 0, math.rad(30)), Color3.fromRGB(240, 195, 45), Enum.Material.Metal, true, false)
	createLight(eagleBody, Color3.fromRGB(255, 215, 50), 2.2, 18)

	-- Imperial Golden Glory Motes
	local eagleGleam = Instance.new("ParticleEmitter")
	eagleGleam.Name = "EagleGloryMotes"
	eagleGleam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100))
	eagleGleam.LightEmission = 0.9
	eagleGleam.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	eagleGleam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	eagleGleam.Lifetime = NumberRange.new(2, 4)
	eagleGleam.Rate = 8
	eagleGleam.Speed = NumberRange.new(0.8, 1.8)
	eagleGleam.SpreadAngle = Vector2.new(30, 30)
	eagleGleam.Parent = eagleBody

	-- Senatorial Inscription Stele: "The Imperial Annals"
	local steleCF = CFrame.new(forumCenter + Vector3.new(0, 2.6, 14))
	local annalsStele = createPart(empireFolder, "ImperialAnnalsStele", Vector3.new(3.6, 8, 1.8), steleCF * CFrame.new(0, 4, 0), Color3.fromRGB(38, 36, 42), Enum.Material.Marble)
	local annalsRune = createPart(empireFolder, "AnnalsGoldPlate", Vector3.new(2.8, 5.5, 0.4), steleCF * CFrame.new(0, 4, 0.95), Color3.fromRGB(245, 205, 50), Enum.Material.Neon, true, false)
	createLight(annalsRune, Color3.fromRGB(245, 205, 50), 1.8, 10)

	local annalsPrompt = Instance.new("ProximityPrompt")
	annalsPrompt.Name = "Prompt_ImperialAnnals"
	annalsPrompt.ObjectText = "The Imperial Annals"
	annalsPrompt.ActionText = "Decipher Golden Chronicles"
	annalsPrompt.HoldDuration = 1.0
	annalsPrompt.MaxActivationDistance = 12
	annalsPrompt.RequiresLineOfSight = false
	annalsPrompt.Parent = annalsStele

	-- Semicircular Marble Peristyle Colonnade (North Arc)
	for i = 1, 8 do
		local angle = math.rad(180 + (i - 1) * 25.7)
		local rad = 23
		local colX = math.cos(angle) * rad
		local colZ = math.sin(angle) * rad
		local pCol = createPart(empireFolder, "PeristyleCol_" .. tostring(i), Vector3.new(1.6, 12, 1.6), CFrame.new(forumCenter + Vector3.new(colX, 8, colZ)), Color3.fromRGB(210, 205, 200), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
		pCol.CFrame = CFrame.new(forumCenter + Vector3.new(colX, 8, colZ)) * CFrame.Angles(0, 0, math.rad(90))
	end

	----------------------------------------------------------------------
	-- 5. IMPERIAL TREASURY & ARMORY (East Wing, X = 55, Z = -220)
	----------------------------------------------------------------------
	local treasuryCenter = Vector3.new(55, 1, -220)

	-- Fortified Foundation
	createPart(empireFolder, "TreasuryFloor", Vector3.new(34, 1.2, 34), CFrame.new(treasuryCenter + Vector3.new(0, 0.6, 0)), Color3.fromRGB(52, 50, 56), Enum.Material.Cobblestone)

	-- Heavy Masonry Walls
	createPart(empireFolder, "TreasuryWallN", Vector3.new(34, 16, 2.5), CFrame.new(treasuryCenter + Vector3.new(0, 9, -16)), Color3.fromRGB(60, 58, 65), Enum.Material.Slate)
	createPart(empireFolder, "TreasuryWallS", Vector3.new(34, 16, 2.5), CFrame.new(treasuryCenter + Vector3.new(0, 9, 16)), Color3.fromRGB(60, 58, 65), Enum.Material.Slate)
	createPart(empireFolder, "TreasuryWallE", Vector3.new(2.5, 16, 34), CFrame.new(treasuryCenter + Vector3.new(16, 9, 0)), Color3.fromRGB(60, 58, 65), Enum.Material.Slate)
	createPart(empireFolder, "TreasuryWallW_A", Vector3.new(2.5, 16, 10), CFrame.new(treasuryCenter + Vector3.new(-16, 9, -12)), Color3.fromRGB(60, 58, 65), Enum.Material.Slate)
	createPart(empireFolder, "TreasuryWallW_B", Vector3.new(2.5, 16, 10), CFrame.new(treasuryCenter + Vector3.new(-16, 9, 12)), Color3.fromRGB(60, 58, 65), Enum.Material.Slate)

	-- Vaulted Ceiling
	createPart(empireFolder, "TreasuryRoof", Vector3.new(36, 2.5, 36), CFrame.new(treasuryCenter + Vector3.new(0, 18, 0)), Color3.fromRGB(45, 42, 48), Enum.Material.Cobblestone)

	-- Imperial Tribute Chest (Salvage Cache)
	local chestCF = CFrame.new(treasuryCenter + Vector3.new(6, 1.2, 0))
	local chestBody = createPart(empireFolder, "ImperialTributeChest", Vector3.new(4.5, 3.2, 3.0), chestCF * CFrame.new(0, 1.6, 0), Color3.fromRGB(75, 45, 25), Enum.Material.WoodPlanks)
	createPart(empireFolder, "ChestGoldTrim", Vector3.new(4.7, 3.4, 3.2), chestCF * CFrame.new(0, 1.6, 0), Color3.fromRGB(235, 195, 50), Enum.Material.Metal)
	createLight(chestBody, Color3.fromRGB(255, 215, 60), 2.0, 12)

	local chestPrompt = Instance.new("ProximityPrompt")
	chestPrompt.Name = "Prompt_ImperialTribute"
	chestPrompt.ObjectText = "Imperial Tribute Chest"
	chestPrompt.ActionText = "Loot Imperial Vault Cache"
	chestPrompt.HoldDuration = 1.0
	chestPrompt.MaxActivationDistance = 12
	chestPrompt.RequiresLineOfSight = false
	chestPrompt.Parent = chestBody

	-- Imperial Weapon Rack in Treasury
	createPart(empireFolder, "ArmoryBoard", Vector3.new(0.5, 6.0, 12.0), CFrame.new(treasuryCenter + Vector3.new(14.5, 5, 0)), Color3.fromRGB(75, 50, 30), Enum.Material.WoodPlanks)
	for i = 1, 4 do
		local zOff = -4.5 + (i - 1) * 3.0
		createPart(empireFolder, "ImpSpear_" .. tostring(i), Vector3.new(0.3, 7.5, 0.3), CFrame.new(treasuryCenter + Vector3.new(13.8, 5, zOff)), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
	end

	----------------------------------------------------------------------
	-- 6. SUNKEN AQUEDUCT & CRYPT (West Wing, X = -55, Z = -220)
	----------------------------------------------------------------------
	local aqueductCenter = Vector3.new(-55, 1, -220)

	-- Aqueduct Stone Foundation Arches
	for a = -1, 1 do
		local aZ = a * 18
		createPart(empireFolder, "AqueductPierL_" .. tostring(a), Vector3.new(4, 20, 4), CFrame.new(aqueductCenter + Vector3.new(-6, 10, aZ)), Color3.fromRGB(68, 65, 70), Enum.Material.Cobblestone)
		createPart(empireFolder, "AqueductPierR_" .. tostring(a), Vector3.new(4, 20, 4), CFrame.new(aqueductCenter + Vector3.new(6, 10, aZ)), Color3.fromRGB(68, 65, 70), Enum.Material.Cobblestone)
		createPart(empireFolder, "AqueductArch_" .. tostring(a), Vector3.new(16, 3, 5), CFrame.new(aqueductCenter + Vector3.new(0, 19, aZ)), Color3.fromRGB(75, 72, 78), Enum.Material.Slate)
	end

	-- Water Channel Lined with Verdigris
	createPart(empireFolder, "AqueductWater", Vector3.new(8, 0.8, 54), CFrame.new(aqueductCenter + Vector3.new(0, 21, 0)), Color3.fromRGB(33, 150, 243), Enum.Material.Glass)

	-- Subterranean Crypt Entrance (Sunken Steps)
	for step = 1, 8 do
		local sY = 1.0 - (step * 0.8)
		local sX = -45 - (step * 1.0)
		createPart(empireFolder, "CryptStep_" .. tostring(step), Vector3.new(1.2, 0.8, 8), CFrame.new(sX, sY, -220), Color3.fromRGB(55, 52, 58), Enum.Material.Cobblestone)
	end

	-- Sunken Undercroft Chamber
	createPart(empireFolder, "CryptFloor", Vector3.new(22, 1, 22), CFrame.new(-65, -5.5, -220), Color3.fromRGB(38, 36, 42), Enum.Material.Slate)
	local cryptAltar = createPart(empireFolder, "CryptRelicPlinth", Vector3.new(4, 3, 4), CFrame.new(-65, -3.5, -220), Color3.fromRGB(48, 45, 52), Enum.Material.Marble)
	createPart(empireFolder, "CryptRuneGlow", Vector3.new(3, 0.3, 3), CFrame.new(-65, -1.9, -220), Color3.fromRGB(64, 196, 255), Enum.Material.Neon)
	createLight(cryptAltar, Color3.fromRGB(64, 196, 255), 1.8, 12)

	local cryptPrompt = Instance.new("ProximityPrompt")
	cryptPrompt.Name = "Prompt_CryptPlinth"
	cryptPrompt.ObjectText = "Imperial Crypt Altar"
	cryptPrompt.ActionText = "Extract Imperial Essence"
	cryptPrompt.HoldDuration = 1.0
	cryptPrompt.MaxActivationDistance = 12
	cryptPrompt.RequiresLineOfSight = false
	cryptPrompt.Parent = cryptAltar

	----------------------------------------------------------------------
	-- 7. REGIONAL NPC: PRAETORIAN TRIBUNE AURELIUS
	----------------------------------------------------------------------
	local npcModel = Instance.new("Model")
	npcModel.Name = "NPC_TribuneAurelius"

	local npcCF = CFrame.new(-10, 2.2, -208) * CFrame.Angles(0, math.rad(45), 0)

	-- Torso in Lorica Segmentata Armor
	local torso = createPart(npcModel, "Torso", Vector3.new(2.2, 2.6, 1.4), npcCF * CFrame.new(0, 2.3, 0), Color3.fromRGB(180, 140, 50), Enum.Material.Metal)
	npcModel.PrimaryPart = torso

	-- Crimson Tunic Skirt & Pteruges
	createPart(npcModel, "RobeSkirt", Vector3.new(2.4, 2.0, 1.6), npcCF * CFrame.new(0, 1.0, 0), Color3.fromRGB(160, 25, 35), Enum.Material.Fabric)

	-- Gilded Belt & Scabbard
	createPart(npcModel, "LeatherBelt", Vector3.new(2.3, 0.4, 1.5), npcCF * CFrame.new(0, 1.9, 0), Color3.fromRGB(60, 35, 20), Enum.Material.Fabric)
	createPart(npcModel, "BeltBuckle", Vector3.new(0.6, 0.5, 0.2), npcCF * CFrame.new(0, 1.9, 0.8), Color3.fromRGB(240, 200, 50), Enum.Material.Metal)

	-- Arms in Bronze Vambraces
	createPart(npcModel, "LeftArm", Vector3.new(0.8, 2.2, 0.8), npcCF * CFrame.new(-1.5, 2.2, 0), Color3.fromRGB(180, 140, 50), Enum.Material.Metal)
	createPart(npcModel, "RightArm", Vector3.new(0.8, 2.2, 0.8), npcCF * CFrame.new(1.5, 2.2, 0), Color3.fromRGB(180, 140, 50), Enum.Material.Metal)

	-- Head & Centurion Galea Helmet with Transverse Crimson Crest
	local head = createPart(npcModel, "Head", Vector3.new(1.4, 1.4, 1.4), npcCF * CFrame.new(0, 4.1, 0), Color3.fromRGB(235, 195, 160), Enum.Material.SmoothPlastic)
	local helmet = createPart(npcModel, "Helmet", Vector3.new(1.8, 1.6, 1.8), npcCF * CFrame.new(0, 4.4, 0), Color3.fromRGB(215, 175, 55), Enum.Material.Metal)
	local crest = createPart(npcModel, "HelmetCrest", Vector3.new(0.3, 1.2, 2.2), npcCF * CFrame.new(0, 5.4, 0), Color3.fromRGB(190, 20, 25), Enum.Material.Fabric)

	-- Scarlet Mantle Cape
	createPart(npcModel, "MantleCape", Vector3.new(2.6, 4.5, 0.4), npcCF * CFrame.new(0, 2.0, -0.85), Color3.fromRGB(160, 25, 35), Enum.Material.Fabric)

	-- Gladius Sword at Hip
	local swordCF = npcCF * CFrame.new(-1.4, 1.8, 0) * CFrame.Angles(0, 0, math.rad(-20))
	createPart(npcModel, "GladiusScabbard", Vector3.new(0.3, 2.8, 0.6), swordCF, Color3.fromRGB(60, 35, 20), Enum.Material.Leather)
	createPart(npcModel, "GladiusHilt", Vector3.new(0.35, 0.8, 0.35), swordCF * CFrame.new(0, 1.6, 0), Color3.fromRGB(240, 200, 50), Enum.Material.Metal)

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
	nameLabel.Text = "Tribune Aurelius"
	nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = bb

	local roleLabel = Instance.new("TextLabel")
	roleLabel.Size = UDim2.new(1, 0, 0, 18)
	roleLabel.Position = UDim2.new(0, 0, 0, 22)
	roleLabel.BackgroundTransparency = 1
	roleLabel.Text = "Imperial Praetorian Commander"
	roleLabel.TextColor3 = Color3.fromRGB(220, 180, 120)
	roleLabel.Font = Enum.Font.Gotham
	roleLabel.TextSize = 12
	roleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	roleLabel.TextStrokeTransparency = 0.3
	roleLabel.Parent = bb

	-- Proximity Prompt
	local aureliusPrompt = Instance.new("ProximityPrompt")
	aureliusPrompt.Name = "Prompt_Aurelius"
	aureliusPrompt.ObjectText = "Tribune Aurelius"
	aureliusPrompt.ActionText = "Consult Imperial Commander"
	aureliusPrompt.HoldDuration = 0.5
	aureliusPrompt.MaxActivationDistance = 14
	aureliusPrompt.RequiresLineOfSight = false
	aureliusPrompt.Parent = torso

	npcModel.Parent = empireFolder

	----------------------------------------------------------------------
	-- 8. MONUMENTAL IMPERIAL SENATE BASILICA (Curia Facade, North Border Z = -325)
	----------------------------------------------------------------------
	local curiaCenter = Vector3.new(0, 1, -325)

	-- Stepped Marble Podium & Flight of Steps
	createPart(empireFolder, "CuriaPodiumBase", Vector3.new(64, 2.5, 32), CFrame.new(curiaCenter + Vector3.new(0, 1.25, 0)), Color3.fromRGB(180, 175, 170), Enum.Material.Marble)
	for step = 1, 6 do
		local sY = 0.4 + (step * 0.4)
		local sZ = -309 + (step * 1.5)
		createPart(empireFolder, "CuriaStep_" .. tostring(step), Vector3.new(44, 0.4, 1.6), CFrame.new(0, sY, sZ), Color3.fromRGB(205, 200, 195), Enum.Material.Marble)
	end

	-- Back Hall Wall & Monumental Bronze Portal
	createPart(empireFolder, "CuriaBackWall", Vector3.new(62, 28, 4), CFrame.new(curiaCenter + Vector3.new(0, 16.5, -12)), Color3.fromRGB(65, 62, 68), Enum.Material.Slate)
	createPart(empireFolder, "CuriaBronzePortal", Vector3.new(12, 16, 1.2), CFrame.new(curiaCenter + Vector3.new(0, 10.5, -9.6)), Color3.fromRGB(160, 120, 50), Enum.Material.Metal)
	createPart(empireFolder, "PortalGoldTrim", Vector3.new(13.2, 17.2, 1.4), CFrame.new(curiaCenter + Vector3.new(0, 10.5, -9.6)), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)

	-- 8 Monumental Corinthian Portico Columns
	for colIdx = 1, 8 do
		local cX = -26 + (colIdx - 1) * 7.4
		local col = createPart(empireFolder, "CuriaCol_" .. tostring(colIdx), Vector3.new(2.4, 22, 2.4), CFrame.new(curiaCenter + Vector3.new(cX, 13.5, 6)), Color3.fromRGB(220, 215, 210), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
		col.CFrame = CFrame.new(curiaCenter + Vector3.new(cX, 13.5, 6)) * CFrame.Angles(0, 0, math.rad(90))
		createPart(empireFolder, "CuriaCap_" .. tostring(colIdx), Vector3.new(3.2, 1.6, 3.2), CFrame.new(curiaCenter + Vector3.new(cX, 24.5, 6)), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)
	end

	-- Classical Triangular Pediment & Entablature
	createPart(empireFolder, "CuriaEntablature", Vector3.new(64, 3, 20), CFrame.new(curiaCenter + Vector3.new(0, 26, 0)), Color3.fromRGB(200, 195, 190), Enum.Material.Marble)
	createPart(empireFolder, "CuriaPedimentGold", Vector3.new(66, 6, 4), CFrame.new(curiaCenter + Vector3.new(0, 30.5, 8)), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)

	----------------------------------------------------------------------
	-- 9. IMPERIAL CAESAR STATUES ALONG THE AVENUE
	----------------------------------------------------------------------
	local statuePositions = {
		Vector3.new(-22, 1.2, -170),
		Vector3.new(22, 1.2, -170),
		Vector3.new(-22, 1.2, -270),
		Vector3.new(22, 1.2, -270),
	}
	for i, sPos in ipairs(statuePositions) do
		local facing = if sPos.X > 0 then math.rad(-90) else math.rad(90)
		createPart(empireFolder, "CaesarPedestal_" .. tostring(i), Vector3.new(3.5, 4.0, 3.5), CFrame.new(sPos + Vector3.new(0, 2.0, 0)), Color3.fromRGB(60, 58, 64), Enum.Material.Slate)
		createPart(empireFolder, "CaesarTrim_" .. tostring(i), Vector3.new(4.0, 0.6, 4.0), CFrame.new(sPos + Vector3.new(0, 4.2, 0)), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)
		createPart(empireFolder, "CaesarTorso_" .. tostring(i), Vector3.new(2.4, 3.5, 1.6), CFrame.new(sPos + Vector3.new(0, 6.2, 0)) * CFrame.Angles(0, facing, 0), Color3.fromRGB(220, 215, 210), Enum.Material.Marble)
		createPart(empireFolder, "CaesarHead_" .. tostring(i), Vector3.new(1.4, 1.5, 1.4), CFrame.new(sPos + Vector3.new(0, 8.5, 0)), Color3.fromRGB(220, 215, 210), Enum.Material.Marble)
		createPart(empireFolder, "CaesarLaurel_" .. tostring(i), Vector3.new(1.6, 0.4, 1.6), CFrame.new(sPos + Vector3.new(0, 8.8, 0)), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)
	end

	----------------------------------------------------------------------
	-- 10. SUBTERRANEAN CRYPT SARCOPHAGI & BLUE SOUL BRAZIERS
	----------------------------------------------------------------------
	local cryptOrigin = Vector3.new(-65, -5.5, -220)
	local sarcophagusOffsets = {
		Vector3.new(-7, 1.0, -7),
		Vector3.new(7, 1.0, -7),
		Vector3.new(-7, 1.0, 7),
		Vector3.new(7, 1.0, 7),
	}
	for sIdx, sOff in ipairs(sarcophagusOffsets) do
		local sCF = CFrame.new(cryptOrigin + sOff)
		createPart(empireFolder, "SarcophagusTub_" .. tostring(sIdx), Vector3.new(3.0, 2.2, 6.0), sCF * CFrame.new(0, 1.1, 0), Color3.fromRGB(45, 42, 50), Enum.Material.Slate)
		createPart(empireFolder, "SarcophagusLid_" .. tostring(sIdx), Vector3.new(3.4, 0.8, 6.4), sCF * CFrame.new(0, 2.4, 0), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)
		createPart(empireFolder, "LidGoldCross_" .. tostring(sIdx), Vector3.new(1.0, 0.2, 4.0), sCF * CFrame.new(0, 2.85, 0), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)
		local soulFlame = createPart(empireFolder, "SoulFlame_" .. tostring(sIdx), Vector3.new(0.8, 0.8, 0.8), sCF * CFrame.new(0, 4.0, 0), Color3.fromRGB(64, 196, 255), Enum.Material.Neon, true, false, Enum.PartType.Ball)
		createLight(soulFlame, Color3.fromRGB(64, 196, 255), 1.6, 10)
	end

	----------------------------------------------------------------------
	-- 11. MONUMENTAL AQUEDUCT, PRAETORIAN BARRACKS & VOLCANIC FISSURES
	----------------------------------------------------------------------
	-- Grand Classical Aqueduct along Western Boundary (elevated water conduit)
	EnvironmentProps.CreateCanalAqueduct(
		empireFolder,
		Vector3.new(-75, 1.2, -130),
		Vector3.new(-75, 1.2, -310),
		18.0
	)

	-- Praetorian Garrison Barracks on Eastern Wing
	EnvironmentProps.CreatePraetorianBarracks(
		empireFolder,
		CFrame.new(52, 1.2, -180) * CFrame.Angles(0, math.rad(-90), 0)
	)

	-- Volcanic Fissures with Magma Core & Embers along Ashen Border
	EnvironmentProps.CreateVolcanicFissure(
		empireFolder,
		CFrame.new(-42, 1.2, -260) * CFrame.Angles(0, math.rad(20), 0),
		32.0
	)
	EnvironmentProps.CreateVolcanicFissure(
		empireFolder,
		CFrame.new(46, 1.2, -260) * CFrame.Angles(0, math.rad(-15), 0),
		28.0
	)

	----------------------------------------------------------------------
	-- 12. CONTESTED PVP ZONE: THE SCORCHED CRUCIBLE
	----------------------------------------------------------------------
	-- Sunken Volcanic Arena Floor (Spans PvP bounds minX=-80, maxX=80, minZ=-4580, maxZ=-4420)
	local arenaCenter = Vector3.new(0, 0.4, -4500)
	createPart(empireFolder, "CrucibleFloor", Vector3.new(160, 0.4, 160), CFrame.new(arenaCenter), Color3.fromRGB(28, 25, 30), Enum.Material.Basalt)
	local magmaVein = createPart(empireFolder, "CrucibleMagmaVein", Vector3.new(12, 0.5, 140), CFrame.new(arenaCenter + Vector3.new(0, 0.05, 0)), Color3.fromRGB(255, 80, 15), Enum.Material.Neon, true, false)
	createLight(magmaVein, Color3.fromRGB(255, 90, 20), 2.8, 24)

	-- 4 Roaring Skull Braziers guarding arena corners
	local brazierCorners = {
		Vector3.new(-70, 7.0, -4430),
		Vector3.new(70, 7.0, -4430),
		Vector3.new(-70, 7.0, -4570),
		Vector3.new(70, 7.0, -4570),
	}
	for bIdx, bPos in ipairs(brazierCorners) do
		local pillar = createPart(empireFolder, "CrucibleBrazier_" .. tostring(bIdx), Vector3.new(4, 14, 4), CFrame.new(bPos), Color3.fromRGB(45, 42, 48), Enum.Material.Slate)
		local fire = createPart(empireFolder, "CrucibleFire_" .. tostring(bIdx), Vector3.new(3.5, 3.5, 3.5), CFrame.new(bPos + Vector3.new(0, 7.5, 0)), Color3.fromRGB(255, 120, 20), Enum.Material.Neon, true, false, Enum.PartType.Ball)
		createLight(fire, Color3.fromRGB(255, 120, 20), 3.0, 22)
	end

	-- Overhead Warning Arch & Sign
	local archWarn = createPart(empireFolder, "CrucibleWarningArch", Vector3.new(28, 4, 3), CFrame.new(0, 14, -4420), Color3.fromRGB(60, 40, 42), Enum.Material.Slate)
	local warnBb = Instance.new("BillboardGui")
	warnBb.Name = "CrucibleBanner"
	warnBb.Size = UDim2.new(0, 280, 0, 48)
	warnBb.StudsOffset = Vector3.new(0, 3.0, 0)
	warnBb.AlwaysOnTop = false
	warnBb.MaxDistance = 50
	warnBb.Parent = archWarn

	local warnTitle = Instance.new("TextLabel")
	warnTitle.Size = UDim2.new(1, 0, 0, 24)
	warnTitle.BackgroundTransparency = 1
	warnTitle.Text = "⚔️ THE SCORCHED CRUCIBLE"
	warnTitle.TextColor3 = Color3.fromRGB(255, 100, 50)
	warnTitle.Font = Enum.Font.GothamBold
	warnTitle.TextSize = 14
	warnTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	warnTitle.Parent = warnBb

	local warnSub = Instance.new("TextLabel")
	warnSub.Size = UDim2.new(1, 0, 0, 18)
	warnSub.Position = UDim2.new(0, 0, 0, 22)
	warnSub.BackgroundTransparency = 1
	warnSub.Text = "Contested PvP Zone • Non-Destructive Combat"
	warnSub.TextColor3 = Color3.fromRGB(255, 200, 150)
	warnSub.Font = Enum.Font.Gotham
	warnSub.TextSize = 11
	warnSub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	warnSub.Parent = warnBb

	----------------------------------------------------------------------
	-- 13. DUNGEON 2: CATACOMBS OF THE PRAETORS (Ashen Domain Expanded Coordinates)
	----------------------------------------------------------------------
	local catacombsOrigin = Vector3.new(-1200, 10, -5200)

	-- Sunken Portal to Catacombs
	local catacombsPortal = createPart(empireFolder, "PraetorCatacombsPortal", Vector3.new(14, 16, 4), CFrame.new(catacombsOrigin + Vector3.new(0, 7.0, 0)), Color3.fromRGB(48, 45, 52), Enum.Material.Slate)
	local catVeil = createPart(empireFolder, "PraetorCatacombsVeil", Vector3.new(10, 12, 1), CFrame.new(catacombsOrigin + Vector3.new(0, 7.0, 0)), Color3.fromRGB(220, 160, 40), Enum.Material.Neon, true, false)
	createLight(catVeil, Color3.fromRGB(220, 160, 40), 2.2, 16)

	-- 3 Timed Pressure Plates (18s coordination window)
	local plateData = {
		{ name = "PressurePlate_1", pos = Vector3.new(-1200, 11.4, -5230), label = "Pressure Plate I" },
		{ name = "PressurePlate_2", pos = Vector3.new(-1218, 11.4, -5250), label = "Pressure Plate II" },
		{ name = "PressurePlate_3", pos = Vector3.new(-1182, 11.4, -5250), label = "Pressure Plate III" },
	}

	for _, pd in ipairs(plateData) do
		local plate = createPart(empireFolder, pd.name, Vector3.new(6, 0.5, 6), CFrame.new(pd.pos), Color3.fromRGB(190, 155, 45), Enum.Material.Metal)
		createLight(plate, Color3.fromRGB(255, 200, 50), 1.5, 8)

		local pPrompt = Instance.new("ProximityPrompt")
		pPrompt.Name = "Prompt_" .. pd.name
		pPrompt.ObjectText = pd.label
		pPrompt.ActionText = "Depress Timed Plate"
		pPrompt.HoldDuration = 0.4
		pPrompt.MaxActivationDistance = 12
		pPrompt.RequiresLineOfSight = false
		pPrompt.Parent = plate
	end

	-- Boss Guardian: Praetorian Centurion Shade
	local bossModel = Instance.new("Model")
	bossModel.Name = "Guardian_PraetorCenturion_Model"
	local bCF = CFrame.new(-1200, 10, -5400)
	local bTorso = createPart(bossModel, "Torso", Vector3.new(3.5, 5.0, 2.2), bCF * CFrame.new(0, 4.5, 0), Color3.fromRGB(40, 38, 48), Enum.Material.Slate)
	local bHead = createPart(bossModel, "Head", Vector3.new(2.0, 2.0, 2.0), bCF * CFrame.new(0, 7.8, 0), Color3.fromRGB(50, 48, 58), Enum.Material.Slate)
	local bCrest = createPart(bossModel, "CenturionCrest", Vector3.new(0.6, 2.5, 3.2), bCF * CFrame.new(0, 9.2, 0), Color3.fromRGB(180, 40, 30), Enum.Material.Neon)
	createPart(bossModel, "PraetorShield", Vector3.new(1.0, 5.0, 3.5), bCF * CFrame.new(-2.5, 4.5, 0.5), Color3.fromRGB(190, 155, 45), Enum.Material.Metal)
	createLight(bHead, Color3.fromRGB(220, 50, 40), 2.2, 14)

	local bBb = Instance.new("BillboardGui")
	bBb.Name = "BossHealthBar"
	bBb.Size = UDim2.new(0, 220, 0, 44)
	bBb.StudsOffset = Vector3.new(0, 4.0, 0)
	bBb.AlwaysOnTop = false
	bBb.MaxDistance = 45
	bBb.Parent = bHead

	local bTitle = Instance.new("TextLabel")
	bTitle.Size = UDim2.new(1, 0, 0, 22)
	bTitle.BackgroundTransparency = 1
	bTitle.Text = "Praetorian Centurion Shade"
	bTitle.TextColor3 = Color3.fromRGB(255, 120, 80)
	bTitle.Font = Enum.Font.GothamBold
	bTitle.TextSize = 14
	bTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	bTitle.TextStrokeTransparency = 0.2
	bTitle.Parent = bBb

	local bSub = Instance.new("TextLabel")
	bSub.Size = UDim2.new(1, 0, 0, 18)
	bSub.Position = UDim2.new(0, 0, 0, 20)
	bSub.BackgroundTransparency = 1
	bSub.Text = "Dungeon Boss • 350 HP"
	bSub.TextColor3 = Color3.fromRGB(255, 200, 160)
	bSub.Font = Enum.Font.Gotham
	bSub.TextSize = 11
	bSub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	bSub.Parent = bBb

	local bPrompt = Instance.new("ProximityPrompt")
	bPrompt.Name = "Prompt_Boss_PraetorCenturion"
	bPrompt.ObjectText = "Praetorian Centurion Shade"
	bPrompt.ActionText = "Strike Boss Guardian"
	bPrompt.HoldDuration = 0.2
	bPrompt.MaxActivationDistance = 18
	bPrompt.RequiresLineOfSight = false
	bPrompt.Parent = bTorso

	bossModel.Parent = empireFolder

	-- Imperial Sarcophagus (Vault Reward)
	local pSarc = createPart(empireFolder, "PraetorSarcophagus", Vector3.new(8, 4.5, 14), CFrame.new(-1200, 14, -5420), Color3.fromRGB(160, 155, 150), Enum.Material.Marble)
	createPart(empireFolder, "PraetorSarcTrim", Vector3.new(8.4, 0.8, 14.4), CFrame.new(-1200, 16.35, -5420), Color3.fromRGB(225, 185, 50), Enum.Material.Metal)
	local sarcPrompt = Instance.new("ProximityPrompt")
	sarcPrompt.Name = "Prompt_PraetorSarcophagus"
	sarcPrompt.ObjectText = "Imperial Praetor Sarcophagus"
	sarcPrompt.ActionText = "Unlock Catacomb Vault"
	sarcPrompt.HoldDuration = 1.0
	sarcPrompt.MaxActivationDistance = 14
	sarcPrompt.RequiresLineOfSight = false
	sarcPrompt.Parent = pSarc

	empireFolder.Parent = worldFolder
	return empireFolder
end

return EmpireDistrictBuilder