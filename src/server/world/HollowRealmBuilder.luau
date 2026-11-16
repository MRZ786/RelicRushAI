--!strict
-- HollowRealmBuilder.luau
-- Authoritative procedural builder for Region 5: The Hollow Realm
-- Constructs a late-game supernatural void dimension:
-- Floating Obsidian Islands, Celestial Violet Light Bridges, Fractured Causeway, and Altar of The Hollow Crown.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local EnvironmentProps = require(script.Parent.EnvironmentProps)

local HollowRealmBuilder = {}

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

function HollowRealmBuilder.Build(worldFolder: Folder): Folder
	local hollowFolder = Instance.new("Folder")
	hollowFolder.Name = "HollowRealm"

	local center = Vector3.new(3200, 250, -200)

	----------------------------------------------------------------------
	-- 1. THRESHOLD OF THE ABYSS (Arrival Island at Celestial Rift Coordinates)
	----------------------------------------------------------------------
	local arrivalPos = Vector3.new(3200, 250, 0)

	-- Floating Arrival Platform (Octagonal Obsidian Slab)
	local arrivalIsland = createPart(hollowFolder, "ArrivalIsland", Vector3.new(34, 6, 34), CFrame.new(arrivalPos), Color3.fromRGB(24, 20, 28), Enum.Material.Marble)
	createPart(hollowFolder, "ArrivalCragUnder", Vector3.new(24, 18, 24), CFrame.new(arrivalPos - Vector3.new(0, 10, 0)), Color3.fromRGB(18, 15, 22), Enum.Material.Slate)

	-- Void Gateway Monoliths framing return portal
	createPart(hollowFolder, "VoidMonolithL", Vector3.new(4, 20, 4), CFrame.new(arrivalPos + Vector3.new(-10, 10, 10)), Color3.fromRGB(28, 22, 34), Enum.Material.Marble)
	createPart(hollowFolder, "VoidMonolithR", Vector3.new(4, 20, 4), CFrame.new(arrivalPos + Vector3.new(10, 10, 10)), Color3.fromRGB(28, 22, 34), Enum.Material.Marble)

	-- Return Void Portal to Forgotten Market
	local returnPortal = createPart(hollowFolder, "ReturnPortal_Market", Vector3.new(14, 16, 1.2), CFrame.new(arrivalPos + Vector3.new(0, 8, 10)), Color3.fromRGB(156, 39, 176), Enum.Material.Neon, true, false)
	createLight(returnPortal, Color3.fromRGB(156, 39, 176), 2.5, 18)

	local retPrompt = Instance.new("ProximityPrompt")
	retPrompt.Name = "Prompt_ReturnMarket_Hollow"
	retPrompt.ObjectText = "Forgotten Market Portal"
	retPrompt.ActionText = "Return to Market Settlement"
	retPrompt.HoldDuration = 0.5
	retPrompt.MaxActivationDistance = 14
	retPrompt.Parent = returnPortal

	----------------------------------------------------------------------
	-- 2. CELESTIAL LIGHT BRIDGE 1 (Arrival -> Intermediate Island)
	----------------------------------------------------------------------
	-- Architectural Forcefield Light Bridge with Translucent Lattice & Guardrails
	EnvironmentProps.CreateLightBridge(
		hollowFolder,
		arrivalPos + Vector3.new(0, 3, -16),
		center + Vector3.new(0, 3, 14),
		7.5,
		Color3.fromRGB(186, 104, 200)
	)

	-- Void Crystal Clusters flanking Arrival Island
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(arrivalPos + Vector3.new(-12, 3, 8)), Color3.fromRGB(186, 104, 200))
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(arrivalPos + Vector3.new(12, 3, 8)), Color3.fromRGB(186, 104, 200))

	----------------------------------------------------------------------
	-- 3. INTERMEDIATE STEPPING ISLAND & ESSENCE CACHE (Center, Z = -200)
	----------------------------------------------------------------------
	local midIsland = createPart(hollowFolder, "MidIsland", Vector3.new(28, 6, 28), CFrame.new(center + Vector3.new(0, 3, 0)), Color3.fromRGB(24, 20, 28), Enum.Material.Marble)
	createPart(hollowFolder, "MidCragUnder", Vector3.new(20, 16, 20), CFrame.new(center - Vector3.new(0, 8, 0)), Color3.fromRGB(18, 15, 22), Enum.Material.Slate)

	-- Levitating Void Crystal Cluster on Mid Island
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(center + Vector3.new(-9, 6, 8)), Color3.fromRGB(233, 30, 99))
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(center + Vector3.new(9, 6, -8)), Color3.fromRGB(156, 39, 176))

	-- Void Essence Cache (Lootable exploration cache)
	local cacheCF = CFrame.new(center + Vector3.new(0, 7.5, 0))
	local voidCache = createPart(hollowFolder, "VoidEssenceCache", Vector3.new(3, 3, 3), cacheCF, Color3.fromRGB(156, 39, 176), Enum.Material.Neon, true, true, Enum.PartType.Ball)
	createPart(hollowFolder, "CacheRing", Vector3.new(0.4, 4.5, 4.5), cacheCF * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 215, 0), Enum.Material.Metal, true, false, Enum.PartType.Cylinder)
	createLight(voidCache, Color3.fromRGB(233, 30, 99), 2.2, 14)

	local cachePrompt = Instance.new("ProximityPrompt")
	cachePrompt.Name = "Prompt_HollowCache"
	cachePrompt.ObjectText = "Void Essence Cache"
	cachePrompt.ActionText = "Extract Celestial Shards"
	cachePrompt.HoldDuration = 1.0
	cachePrompt.MaxActivationDistance = 12
	cachePrompt.RequiresLineOfSight = false
	cachePrompt.Parent = voidCache

	----------------------------------------------------------------------
	-- 4. CELESTIAL LIGHT BRIDGE 2 (Intermediate -> Crown Spire Apex)
	----------------------------------------------------------------------
	local apexPos = center + Vector3.new(0, 15, -70)

	EnvironmentProps.CreateLightBridge(
		hollowFolder,
		center + Vector3.new(0, 6, -14),
		apexPos + Vector3.new(0, 12, 26),
		8.0,
		Color3.fromRGB(233, 30, 99)
	)

	----------------------------------------------------------------------
	-- 5. CROWN SPIRE OF THE VOID (Apex Island, Z = -270)
	----------------------------------------------------------------------
	local apexIsland = createPart(hollowFolder, "ApexIsland", Vector3.new(52, 8, 52), CFrame.new(apexPos), Color3.fromRGB(22, 18, 26), Enum.Material.Marble)
	createPart(hollowFolder, "ApexCragUnder", Vector3.new(36, 26, 36), CFrame.new(apexPos - Vector3.new(0, 14, 0)), Color3.fromRGB(15, 12, 18), Enum.Material.Slate)

	-- Void Crystal Clusters around Apex Dais
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(apexPos + Vector3.new(-18, 12, -18)), Color3.fromRGB(233, 30, 99))
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(apexPos + Vector3.new(18, 12, -18)), Color3.fromRGB(233, 30, 99))
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(apexPos + Vector3.new(-18, 12, 18)), Color3.fromRGB(156, 39, 176))
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(apexPos + Vector3.new(18, 12, 18)), Color3.fromRGB(156, 39, 176))

	-- 8 Monumental Jagged Obsidian Spires Ringing Perimeter
	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45)
		local rad = 21
		local sx = math.cos(angle) * rad
		local sz = math.sin(angle) * rad
		local spireCF = CFrame.new(apexPos + Vector3.new(sx, 16, sz)) * CFrame.Angles(math.rad(-10), -angle, 0)
		createPart(hollowFolder, "VoidSpire_" .. tostring(i), Vector3.new(3.5, 32, 3.5), spireCF, Color3.fromRGB(18, 15, 24), Enum.Material.Marble)
		
		-- Ruby glowing apex tip on each spire
		local tip = createPart(hollowFolder, "SpireTip_" .. tostring(i), Vector3.new(1.2, 1.2, 1.2), spireCF * CFrame.new(0, 16.5, 0), Color3.fromRGB(233, 30, 99), Enum.Material.Neon, true, false, Enum.PartType.Ball)
		createLight(tip, Color3.fromRGB(233, 30, 99), 1.4, 8)
	end

	-- Altar of The Hollow Crown (Central Monument)
	local altarCenter = apexPos + Vector3.new(0, 4.5, 0)
	local altarDais1 = createPart(hollowFolder, "AltarDais1", Vector3.new(1.4, 18, 18), CFrame.new(altarCenter + Vector3.new(0, 0.7, 0)), Color3.fromRGB(28, 22, 32), Enum.Material.Marble, true, true, Enum.PartType.Cylinder)
	altarDais1.CFrame = CFrame.new(altarCenter + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local altarDais2 = createPart(hollowFolder, "AltarDais2", Vector3.new(1.2, 12, 12), CFrame.new(altarCenter + Vector3.new(0, 1.9, 0)), Color3.fromRGB(225, 185, 50), Enum.Material.Metal, true, true, Enum.PartType.Cylinder)
	altarDais2.CFrame = CFrame.new(altarCenter + Vector3.new(0, 1.9, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Floating Altar Core with Levitating Halo
	local altarCore = createPart(hollowFolder, "AltarCore", Vector3.new(2.4, 3.6, 2.4), CFrame.new(altarCenter + Vector3.new(0, 4.5, 0)), Color3.fromRGB(233, 30, 99), Enum.Material.Neon, true, false)
	local altarHalo = createPart(hollowFolder, "AltarHalo", Vector3.new(0.4, 6.0, 6.0), CFrame.new(altarCenter + Vector3.new(0, 5.0, 0)), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, true, false, Enum.PartType.Cylinder)
	altarHalo.CFrame = CFrame.new(altarCenter + Vector3.new(0, 5.0, 0)) * CFrame.Angles(0, 0, math.rad(90))
	createLight(altarCore, Color3.fromRGB(233, 30, 99), 2.8, 20)

	-- Void Essence Particle Stream
	local voidEmitter = Instance.new("ParticleEmitter")
	voidEmitter.Name = "VoidEssenceParticles"
	voidEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(233, 30, 99)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(156, 39, 176)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(103, 58, 183)),
	})
	voidEmitter.LightEmission = 0.9
	voidEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	voidEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	voidEmitter.Lifetime = NumberRange.new(3, 5)
	voidEmitter.Rate = 14
	voidEmitter.Speed = NumberRange.new(1.5, 3.0)
	voidEmitter.SpreadAngle = Vector2.new(35, 35)
	voidEmitter.Parent = altarCore

	local altarPrompt = Instance.new("ProximityPrompt")
	altarPrompt.Name = "Prompt_HollowAltar"
	altarPrompt.ObjectText = "Altar of The Hollow Crown"
	altarPrompt.ActionText = "Commune with the Void"
	altarPrompt.HoldDuration = 1.5
	altarPrompt.MaxActivationDistance = 14
	altarPrompt.RequiresLineOfSight = false
	altarPrompt.Parent = altarCore

	-- Lore Stele: "The Hollow Prophecy"
	local stelePos = apexPos + Vector3.new(0, 4, 14)
	local voidStele = createPart(hollowFolder, "HollowProphecyStele", Vector3.new(3.8, 8, 1.8), CFrame.new(stelePos), Color3.fromRGB(26, 20, 32), Enum.Material.Marble)
	local steleRune = createPart(hollowFolder, "ProphecyRuneGlow", Vector3.new(2.8, 6, 0.4), CFrame.new(stelePos + Vector3.new(0, 0, -0.95)), Color3.fromRGB(233, 30, 99), Enum.Material.Neon, true, false)
	createLight(steleRune, Color3.fromRGB(233, 30, 99), 2.0, 12)

	local stelePrompt = Instance.new("ProximityPrompt")
	stelePrompt.Name = "Prompt_HollowProphecy"
	stelePrompt.ObjectText = "The Hollow Prophecy"
	stelePrompt.ActionText = "Decipher Void Inscription"
	stelePrompt.HoldDuration = 1.0
	stelePrompt.MaxActivationDistance = 12
	stelePrompt.RequiresLineOfSight = false
	stelePrompt.Parent = voidStele

	-- Monumental Void Crown Spire with Orbital Celestial Rings
	EnvironmentProps.CreateCrownSpire(hollowFolder, CFrame.new(apexPos + Vector3.new(0, 4.0, -18)))

	-- Additional Void Crystal Clusters framing the sanctuary
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(apexPos + Vector3.new(-18, 4.0, -8)), Color3.fromRGB(233, 30, 99))
	EnvironmentProps.CreateVoidCrystalCluster(hollowFolder, CFrame.new(apexPos + Vector3.new(18, 4.0, -8)), Color3.fromRGB(156, 39, 176))

	----------------------------------------------------------------------
	-- 6. REGIONAL NPC: ECHO OF THE VOID (Sovereign Herald)
	----------------------------------------------------------------------
	local npcModel = Instance.new("Model")
	npcModel.Name = "NPC_VoidEcho"

	local npcCF = CFrame.new(apexPos + Vector3.new(-12, 1.0, 10)) * CFrame.Angles(0, math.rad(135), 0)

	-- Ethereal Robe Torso
	local torso = createPart(npcModel, "Torso", Vector3.new(2.2, 2.6, 1.4), npcCF * CFrame.new(0, 2.3, 0), Color3.fromRGB(32, 24, 45), Enum.Material.Marble)
	npcModel.PrimaryPart = torso

	-- Robe Skirt with Cosmic Void Shading
	createPart(npcModel, "RobeSkirt", Vector3.new(2.4, 2.0, 1.6), npcCF * CFrame.new(0, 1.0, 0), Color3.fromRGB(22, 15, 32), Enum.Material.Marble)

	-- Astral Girdle
	createPart(npcModel, "AstralGirdle", Vector3.new(2.3, 0.4, 1.5), npcCF * CFrame.new(0, 1.9, 0), Color3.fromRGB(156, 39, 176), Enum.Material.Neon)

	-- Robe Sleeves
	createPart(npcModel, "LeftArm", Vector3.new(0.8, 2.2, 0.8), npcCF * CFrame.new(-1.5, 2.2, 0), Color3.fromRGB(32, 24, 45), Enum.Material.Marble)
	createPart(npcModel, "RightArm", Vector3.new(0.8, 2.2, 0.8), npcCF * CFrame.new(1.5, 2.2, 0), Color3.fromRGB(32, 24, 45), Enum.Material.Marble)

	-- Floating Void Mask Head with Cosmic Ruby Eyes
	local head = createPart(npcModel, "Head", Vector3.new(1.4, 1.4, 1.4), npcCF * CFrame.new(0, 4.1, 0), Color3.fromRGB(18, 14, 24), Enum.Material.Marble)
	createPart(npcModel, "VoidCowl", Vector3.new(1.9, 1.8, 1.9), npcCF * CFrame.new(0, 4.3, -0.1), Color3.fromRGB(24, 18, 35), Enum.Material.Fabric)

	-- Astral Ruby Eyes
	createPart(npcModel, "EyeL", Vector3.new(0.18, 0.14, 0.1), npcCF * CFrame.new(-0.35, 4.25, 0.72), Color3.fromRGB(233, 30, 99), Enum.Material.Neon)
	createPart(npcModel, "EyeR", Vector3.new(0.18, 0.14, 0.1), npcCF * CFrame.new(0.35, 4.25, 0.72), Color3.fromRGB(233, 30, 99), Enum.Material.Neon)

	-- Levitating Void Crystal Orb in Front of Herald
	local orb = createPart(npcModel, "VoidOrb", Vector3.new(1.2, 1.2, 1.2), npcCF * CFrame.new(0, 3.2, 1.4), Color3.fromRGB(156, 39, 176), Enum.Material.Neon, true, false, Enum.PartType.Ball)
	createLight(orb, Color3.fromRGB(186, 104, 200), 2.2, 14)

	local orbMotes = Instance.new("ParticleEmitter")
	orbMotes.Name = "VoidOrbMotes"
	orbMotes.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(233, 30, 99)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(186, 104, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(103, 58, 183)),
	})
	orbMotes.Size = NumberSequence.new(0.25, 0.04)
	orbMotes.Lifetime = NumberRange.new(1.0, 2.0)
	orbMotes.Rate = 10
	orbMotes.Speed = NumberRange.new(0.6, 1.2)
	orbMotes.Parent = orb

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
	nameLabel.Text = "Echo of the Void"
	nameLabel.TextColor3 = Color3.fromRGB(233, 30, 99)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = bb

	local roleLabel = Instance.new("TextLabel")
	roleLabel.Size = UDim2.new(1, 0, 0, 18)
	roleLabel.Position = UDim2.new(0, 0, 0, 22)
	roleLabel.BackgroundTransparency = 1
	roleLabel.Text = "Ancient Sovereign Herald"
	roleLabel.TextColor3 = Color3.fromRGB(200, 180, 240)
	roleLabel.Font = Enum.Font.Gotham
	roleLabel.TextSize = 12
	roleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	roleLabel.TextStrokeTransparency = 0.3
	roleLabel.Parent = bb

	-- Proximity Prompt
	local voidPrompt = Instance.new("ProximityPrompt")
	voidPrompt.Name = "Prompt_VoidEcho"
	voidPrompt.ObjectText = "Echo of the Void"
	voidPrompt.ActionText = "Hear Ancient Prophecy"
	voidPrompt.HoldDuration = 0.5
	voidPrompt.MaxActivationDistance = 14
	voidPrompt.RequiresLineOfSight = false
	voidPrompt.Parent = torso

	npcModel.Parent = hollowFolder

	----------------------------------------------------------------------
	-- 7. ABYSS SAFETY RECOVERY NET (Teleports falling players back to Arrival)
	----------------------------------------------------------------------
	local safetyFloor = createPart(hollowFolder, "AbyssSafetyCatch", Vector3.new(4500, 4, 4500), CFrame.new(5000, 150, 0), Color3.fromRGB(156, 39, 176), Enum.Material.Glass, true, false)
	safetyFloor.Transparency = 1

	local lastCatch = {}
	safetyFloor.Touched:Connect(function(hit)
		local char = hit.Parent
		if not char then return end
		local player = Players:GetPlayerFromCharacter(char)
		if player then
			local now = os.clock()
			if not lastCatch[player.UserId] or (now - lastCatch[player.UserId] > 1.5) then
				lastCatch[player.UserId] = now
				local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					root.AssemblyLinearVelocity = Vector3.zero
					root.CFrame = CFrame.new(arrivalPos + Vector3.new(0, 5, 0))
				end
			end
		end
	end)

	----------------------------------------------------------------------
	-- 8. DUNGEON 3: ASTRAL SANCTUM OF THE VOID (Celestial Rift Coordinates)
	----------------------------------------------------------------------
	local sanctumOrigin = Vector3.new(6500, 290, 800)

	-- Astral Sanctum Gateway Portal
	local sanctumPortal = createPart(hollowFolder, "AstralSanctumPortal", Vector3.new(14, 18, 4), CFrame.new(sanctumOrigin + Vector3.new(0, 7, 0)), Color3.fromRGB(30, 24, 38), Enum.Material.Marble)
	local sanctumVeil = createPart(hollowFolder, "AstralSanctumVeil", Vector3.new(10, 14, 1), CFrame.new(sanctumOrigin + Vector3.new(0, 7, 0)), Color3.fromRGB(156, 39, 176), Enum.Material.Neon, true, false)
	createLight(sanctumVeil, Color3.fromRGB(186, 104, 200), 2.4, 18)

	-- 4 Levitating Void Plates (Stepping Path across the Void)
	local plateDefs = {
		{ name = "AstralLightPlate1", pos = Vector3.new(6500, 291, 840), label = "Astral Plate I" },
		{ name = "AstralLightPlate2", pos = Vector3.new(6500, 292, 880), label = "Astral Plate II" },
		{ name = "AstralLightPlate3", pos = Vector3.new(6500, 293, 920), label = "Astral Plate III" },
		{ name = "AstralLightPlate4", pos = Vector3.new(6500, 294, 960), label = "Astral Plate IV" },
	}

	for _, pd in ipairs(plateDefs) do
		local plate = createPart(hollowFolder, pd.name, Vector3.new(6, 0.6, 6), CFrame.new(pd.pos), Color3.fromRGB(186, 104, 200), Enum.Material.Glass)
		createLight(plate, Color3.fromRGB(200, 80, 230), 1.8, 10)

		local pPrompt = Instance.new("ProximityPrompt")
		pPrompt.Name = "Prompt_" .. pd.name
		pPrompt.ObjectText = pd.label
		pPrompt.ActionText = "Illuminate Void Platform"
		pPrompt.HoldDuration = 0.4
		pPrompt.MaxActivationDistance = 14
		pPrompt.RequiresLineOfSight = false
		pPrompt.Parent = plate
	end

	-- Boss Guardian: Void Singularity Sentinel
	local bossModel = Instance.new("Model")
	bossModel.Name = "Guardian_VoidSentinel_Model"
	local bCF = CFrame.new(6500, 290, 1000)
	local bTorso = createPart(bossModel, "Torso", Vector3.new(3.5, 5.0, 2.5), bCF * CFrame.new(0, 4.5, 0), Color3.fromRGB(24, 18, 32), Enum.Material.Glass)
	local bHead = createPart(bossModel, "Head", Vector3.new(2.0, 2.0, 2.0), bCF * CFrame.new(0, 7.8, 0), Color3.fromRGB(35, 25, 48), Enum.Material.Neon)
	local bEye = createPart(bossModel, "CosmicEye", Vector3.new(1.0, 1.0, 0.4), bCF * CFrame.new(0, 7.8, 1.1), Color3.fromRGB(233, 30, 99), Enum.Material.Neon)
	createLight(bEye, Color3.fromRGB(233, 30, 99), 2.5, 16)

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
	bTitle.Text = "Void Singularity Sentinel"
	bTitle.TextColor3 = Color3.fromRGB(233, 30, 99)
	bTitle.Font = Enum.Font.GothamBold
	bTitle.TextSize = 14
	bTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	bTitle.TextStrokeTransparency = 0.2
	bTitle.Parent = bBb

	local bSub = Instance.new("TextLabel")
	bSub.Size = UDim2.new(1, 0, 0, 18)
	bSub.Position = UDim2.new(0, 0, 0, 20)
	bSub.BackgroundTransparency = 1
	bSub.Text = "Dungeon Boss • 450 HP"
	bSub.TextColor3 = Color3.fromRGB(220, 180, 240)
	bSub.Font = Enum.Font.Gotham
	bSub.TextSize = 11
	bSub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	bSub.Parent = bBb

	local bPrompt = Instance.new("ProximityPrompt")
	bPrompt.Name = "Prompt_Boss_VoidSentinel"
	bPrompt.ObjectText = "Void Singularity Sentinel"
	bPrompt.ActionText = "Strike Boss Guardian"
	bPrompt.HoldDuration = 0.2
	bPrompt.MaxActivationDistance = 18
	bPrompt.RequiresLineOfSight = false
	bPrompt.Parent = bTorso

	bossModel.Parent = hollowFolder

	-- Singularity Reliquary (Vault Reward)
	local reliquary = createPart(hollowFolder, "SingularityReliquary", Vector3.new(5, 4.0, 5), CFrame.new(6500, 294, 1030), Color3.fromRGB(20, 15, 26), Enum.Material.Marble)
	createPart(hollowFolder, "ReliquaryTrim", Vector3.new(5.4, 0.8, 5.4), CFrame.new(6500, 296.4, 1030), Color3.fromRGB(233, 30, 99), Enum.Material.Neon, true, false)
	local sarcPrompt = Instance.new("ProximityPrompt")
	sarcPrompt.Name = "Prompt_SingularityReliquary"
	sarcPrompt.ObjectText = "Singularity Reliquary"
	sarcPrompt.ActionText = "Unlock Void Reliquary"
	sarcPrompt.HoldDuration = 1.0
	sarcPrompt.MaxActivationDistance = 14
	sarcPrompt.RequiresLineOfSight = false
	sarcPrompt.Parent = reliquary

	hollowFolder.Parent = worldFolder
	return hollowFolder
end

return HollowRealmBuilder