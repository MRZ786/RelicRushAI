--!strict
-- RelicMeshBuilder.luau
-- Authoritative high-detail procedural model builder for all Relic Rush relics
-- Uses layered geometry, precious metals, faceted gemstones, glass bezels, and subtle particle auras.

local RelicMeshBuilder = {}

local function createPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
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
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- 1. Scavenger's Compass (Antique brass case, milled coin bezel, emerald needle, winding crown)
function RelicMeshBuilder.CreateScavengerCompass(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Relic_ScavengersCompass"

	local brassDark = Color3.fromRGB(160, 115, 38)
	local brassGold = Color3.fromRGB(225, 175, 55)

	-- Outer Brass Casing with stepped milled bezel
	local casing = createPart(model, "Casing", Vector3.new(0.7, 2.8, 2.8), cframe, brassDark, Enum.Material.Metal, Enum.PartType.Cylinder)
	casing.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))
	model.PrimaryPart = casing

	local milledRim = createPart(model, "MilledRim", Vector3.new(0.75, 2.6, 2.6), cframe, brassGold, Enum.Material.Metal, Enum.PartType.Cylinder)
	milledRim.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))

	-- Aged Parchment Dial Face
	local dial = createPart(model, "DialFace", Vector3.new(0.78, 2.2, 2.2), cframe, Color3.fromRGB(240, 235, 215), Enum.Material.Sandstone, Enum.PartType.Cylinder)
	dial.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))

	-- Cardinal Compass Rose Markers (North, South, East, West)
	createPart(model, "RoseN", Vector3.new(0.08, 0.4, 0.1), cframe * CFrame.new(0, 0.8, 0.4), Color3.fromRGB(180, 40, 30), Enum.Material.SmoothPlastic)
	createPart(model, "RoseS", Vector3.new(0.08, 0.3, 0.1), cframe * CFrame.new(0, -0.8, 0.4), Color3.fromRGB(40, 40, 45), Enum.Material.SmoothPlastic)
	createPart(model, "RoseE", Vector3.new(0.08, 0.1, 0.3), cframe * CFrame.new(0.8, 0, 0.4), Color3.fromRGB(40, 40, 45), Enum.Material.SmoothPlastic)
	createPart(model, "RoseW", Vector3.new(0.08, 0.1, 0.3), cframe * CFrame.new(-0.8, 0, 0.4), Color3.fromRGB(40, 40, 45), Enum.Material.SmoothPlastic)

	-- Faceted Emerald Compass Needle
	local needleN = createPart(model, "NeedleNorth", Vector3.new(0.18, 0.95, 0.28), cframe * CFrame.new(0, 0.48, 0.42), Color3.fromRGB(46, 125, 50), Enum.Material.Neon)
	local needleS = createPart(model, "NeedleSouth", Vector3.new(0.18, 0.95, 0.28), cframe * CFrame.new(0, -0.48, 0.42), Color3.fromRGB(160, 45, 35), Enum.Material.SmoothPlastic)

	-- Center Brass Pivot Pin
	local pivot = createPart(model, "PivotPin", Vector3.new(0.85, 0.35, 0.35), cframe * CFrame.new(0, 0, 0.44), brassGold, Enum.Material.Metal, Enum.PartType.Cylinder)
	pivot.CFrame = (cframe * CFrame.new(0, 0, 0.44)) * CFrame.Angles(0, 0, math.rad(90))

	-- Domed Glass Protective Crystal
	local glass = createPart(model, "DomedGlass", Vector3.new(0.82, 2.3, 2.3), cframe * CFrame.new(0, 0, 0.45), Color3.fromRGB(220, 245, 255), Enum.Material.Glass, Enum.PartType.Cylinder)
	glass.CFrame = (cframe * CFrame.new(0, 0, 0.45)) * CFrame.Angles(0, 0, math.rad(90))
	glass.Transparency = 0.55

	-- Top Winding Crown & Suspension Ring
	createPart(model, "WindingStem", Vector3.new(0.4, 0.4, 0.4), cframe * CFrame.new(0, 1.5, 0), brassDark, Enum.Material.Metal)
	local ring = createPart(model, "SuspensionRing", Vector3.new(0.2, 0.9, 0.9), (cframe * CFrame.new(0, 1.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), brassGold, Enum.Material.Metal, Enum.PartType.Cylinder)

	-- Emerald PointLight Aura
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(76, 175, 80)
	light.Brightness = 1.6
	light.Range = 10
	light.Parent = casing

	-- Emerald Gleam Particle Emitter
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "CompassAura"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(76, 175, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(129, 199, 132)),
	})
	pe.Size = NumberSequence.new(0.18, 0.02)
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Rate = 5
	pe.Speed = NumberRange.new(0.4, 0.8)
	pe.Parent = pivot

	model.Parent = parent
	return model
end

-- 2. Merchant's Eye (Winged filigree gold talisman with glowing amber cat-eye gemstone)
function RelicMeshBuilder.CreateMerchantsEye(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Relic_MerchantsEye"

	local goldLight = Color3.fromRGB(245, 195, 45)
	local goldDark = Color3.fromRGB(180, 130, 28)

	-- Winged Gold Backplate
	local backplate = createPart(model, "WingBackplate", Vector3.new(0.4, 2.2, 3.8), cframe, goldDark, Enum.Material.Metal)
	model.PrimaryPart = backplate

	-- Left & Right Sculpted Wing Feathers
	createPart(model, "WingTipL", Vector3.new(0.3, 1.4, 1.4), (cframe * CFrame.new(-1.8, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(30)), goldLight, Enum.Material.Metal)
	createPart(model, "WingTipR", Vector3.new(0.3, 1.4, 1.4), (cframe * CFrame.new(1.8, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(-30)), goldLight, Enum.Material.Metal)

	-- Almond Eye Bezel
	local bezel = createPart(model, "EyeBezel", Vector3.new(0.6, 2.4, 2.4), cframe * CFrame.new(0, 0, 0.2), goldLight, Enum.Material.Metal, Enum.PartType.Cylinder)
	bezel.CFrame = (cframe * CFrame.new(0, 0, 0.2)) * CFrame.Angles(0, 0, math.rad(90))

	-- Radiant Amber Eyeball Gemstone
	local amber = createPart(model, "AmberGem", Vector3.new(1.5, 1.5, 1.5), cframe * CFrame.new(0, 0, 0.4), Color3.fromRGB(255, 175, 10), Enum.Material.Neon, Enum.PartType.Ball)

	-- Vertical Obsidian Slit Pupil
	createPart(model, "SlitPupil", Vector3.new(0.12, 1.2, 0.25), cframe * CFrame.new(0, 0, 1.15), Color3.fromRGB(15, 15, 20), Enum.Material.SmoothPlastic)

	-- 3 Suspended Gold Teardrop Pendants
	local drop1 = createPart(model, "PendantL", Vector3.new(0.45, 0.9, 0.45), cframe * CFrame.new(-0.9, -1.4, 0), goldLight, Enum.Material.Metal, Enum.PartType.Ball)
	local drop2 = createPart(model, "PendantCenter", Vector3.new(0.6, 1.2, 0.6), cframe * CFrame.new(0, -1.8, 0), goldLight, Enum.Material.Metal, Enum.PartType.Ball)
	local drop3 = createPart(model, "PendantR", Vector3.new(0.45, 0.9, 0.45), cframe * CFrame.new(0.9, -1.4, 0), goldLight, Enum.Material.Metal, Enum.PartType.Ball)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 185, 20)
	light.Brightness = 1.8
	light.Range = 12
	light.Parent = amber

	-- Amber Glint Particle Emitter
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "EyeGleam"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 64)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 160, 0)),
	})
	pe.Size = NumberSequence.new(0.2, 0.04)
	pe.Lifetime = NumberRange.new(0.5, 1.0)
	pe.Rate = 6
	pe.Speed = NumberRange.new(0.3, 0.7)
	pe.Parent = amber

	model.Parent = parent
	return model
end

-- 3. Shadow Talisman (Faceted obsidian pendulum, silver runic cage, amethyst core)
function RelicMeshBuilder.CreateShadowTalisman(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Relic_ShadowTalisman"

	local silverColor = Color3.fromRGB(195, 200, 210)
	local obsidianColor = Color3.fromRGB(22, 20, 28)

	-- Main Faceted Obsidian Prism
	local corePrism = createPart(model, "ObsidianPrism", Vector3.new(1.8, 3.4, 1.8), cframe, obsidianColor, Enum.Material.Marble)
	model.PrimaryPart = corePrism

	-- Glowing Amethyst Inner Core
	local amethyst = createPart(model, "AmethystGem", Vector3.new(1.1, 2.2, 1.1), cframe * CFrame.new(0, 0, 0.2), Color3.fromRGB(156, 39, 176), Enum.Material.Neon)

	-- Silver Runic Suspension Cap
	createPart(model, "SilverCap", Vector3.new(2.0, 0.6, 2.0), cframe * CFrame.new(0, 1.9, 0), silverColor, Enum.Material.Metal)
	local ring = createPart(model, "SilverBale", Vector3.new(0.18, 0.8, 0.8), (cframe * CFrame.new(0, 2.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), silverColor, Enum.Material.Metal, Enum.PartType.Cylinder)

	-- Silver Corner Cages
	createPart(model, "CageRib1", Vector3.new(0.2, 3.4, 0.2), cframe * CFrame.new(-0.85, 0, -0.85), silverColor, Enum.Material.Metal)
	createPart(model, "CageRib2", Vector3.new(0.2, 3.4, 0.2), cframe * CFrame.new(0.85, 0, -0.85), silverColor, Enum.Material.Metal)
	createPart(model, "CageRib3", Vector3.new(0.2, 3.4, 0.2), cframe * CFrame.new(-0.85, 0, 0.85), silverColor, Enum.Material.Metal)
	createPart(model, "CageRib4", Vector3.new(0.2, 3.4, 0.2), cframe * CFrame.new(0.85, 0, 0.85), silverColor, Enum.Material.Metal)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(156, 39, 176)
	light.Brightness = 1.6
	light.Range = 10
	light.Parent = amethyst

	-- Void Shadow Mist Particle Emitter
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "ShadowMist"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(186, 104, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 10, 60)),
	})
	pe.Size = NumberSequence.new(0.3, 0.05)
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Rate = 7
	pe.Speed = NumberRange.new(0.3, 0.8)
	pe.Parent = amethyst

	model.Parent = parent
	return model
end

-- 4. Obsidian Chalice (Fluted goblet, gold acanthus collar, glowing sapphire elixir)
function RelicMeshBuilder.CreateObsidianChalice(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Relic_ObsidianChalice"

	local obsColor = Color3.fromRGB(20, 22, 26)
	local goldColor = Color3.fromRGB(240, 195, 50)

	-- Stepped Circular Foot
	local foot1 = createPart(model, "FootBase", Vector3.new(0.4, 2.8, 2.8), cframe * CFrame.new(0, 0.2, 0), obsColor, Enum.Material.Marble, Enum.PartType.Cylinder)
	foot1.CFrame = (cframe * CFrame.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	model.PrimaryPart = foot1

	local footGold = createPart(model, "FootGoldRim", Vector3.new(0.45, 2.5, 2.5), cframe * CFrame.new(0, 0.45, 0), goldColor, Enum.Material.Metal, Enum.PartType.Cylinder)
	footGold.CFrame = (cframe * CFrame.new(0, 0.45, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Fluted Obsidian Stem
	local stem = createPart(model, "Stem", Vector3.new(1.6, 0.9, 0.9), cframe * CFrame.new(0, 1.4, 0), obsColor, Enum.Material.Marble, Enum.PartType.Cylinder)
	stem.CFrame = (cframe * CFrame.new(0, 1.4, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Gold Acanthus Foliate Waist Knop
	local knop = createPart(model, "WaistKnop", Vector3.new(0.5, 1.4, 1.4), cframe * CFrame.new(0, 1.8, 0), goldColor, Enum.Material.Metal, Enum.PartType.Cylinder)
	knop.CFrame = (cframe * CFrame.new(0, 1.8, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Fluted Goblet Cup Body
	local cupLower = createPart(model, "CupLower", Vector3.new(1.0, 2.2, 2.2), cframe * CFrame.new(0, 2.5, 0), obsColor, Enum.Material.Marble, Enum.PartType.Cylinder)
	cupLower.CFrame = (cframe * CFrame.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local cupUpper = createPart(model, "CupUpper", Vector3.new(1.2, 2.6, 2.6), cframe * CFrame.new(0, 3.4, 0), obsColor, Enum.Material.Marble, Enum.PartType.Cylinder)
	cupUpper.CFrame = (cframe * CFrame.new(0, 3.4, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Gold Filigree Cup Lip Rim
	local rim = createPart(model, "GoldLipRim", Vector3.new(0.3, 2.8, 2.8), cframe * CFrame.new(0, 4.0, 0), goldColor, Enum.Material.Metal, Enum.PartType.Cylinder)
	rim.CFrame = (cframe * CFrame.new(0, 4.0, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Luminous Sapphire Celestial Elixir Liquid
	local liquid = createPart(model, "SapphireElixir", Vector3.new(0.4, 2.4, 2.4), cframe * CFrame.new(0, 3.7, 0), Color3.fromRGB(33, 150, 243), Enum.Material.Neon, Enum.PartType.Cylinder)
	liquid.CFrame = (cframe * CFrame.new(0, 3.7, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(33, 150, 243)
	light.Brightness = 2.2
	light.Range = 14
	light.Parent = liquid

	-- Swirling Sapphire Celestial Vapor
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "ElixirVapor"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 80, 200)),
	})
	pe.Size = NumberSequence.new(0.35, 0.08)
	pe.Lifetime = NumberRange.new(1.0, 1.8)
	pe.Rate = 12
	pe.Speed = NumberRange.new(0.6, 1.4)
	pe.Parent = liquid

	model.Parent = parent
	return model
end

-- 5. The Hollow Crown (Blackened gold circlet, 8 jagged obsidian spires, glowing ruby tips, levitating halo, orbiting void runes, void vortex)
function RelicMeshBuilder.CreateHollowCrown(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Relic_TheHollowCrown"

	local goldColor = Color3.fromRGB(245, 205, 50)
	local obsColor = Color3.fromRGB(24, 20, 28)
	local rubyColor = Color3.fromRGB(233, 30, 99)
	local voidViolet = Color3.fromRGB(156, 39, 176)

	-- Base Circlet Ring
	local circlet = createPart(model, "Circlet", Vector3.new(0.7, 3.4, 3.4), cframe, goldColor, Enum.Material.Metal, Enum.PartType.Cylinder)
	circlet.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))
	model.PrimaryPart = circlet

	-- Blackened Iron Inlay Band
	local innerBand = createPart(model, "IronInlayBand", Vector3.new(0.75, 3.2, 3.2), cframe, obsColor, Enum.Material.Slate, Enum.PartType.Cylinder)
	innerBand.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))

	-- 8 Spired Crown Points with Glowing Ruby Tips
	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45)
		local radius = 1.55
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local height = if i % 2 == 1 then 2.4 else 1.6

		local spireCF = (cframe * CFrame.new(x, height / 2 + 0.3, z)) * CFrame.Angles(0, -angle, 0)
		createPart(model, "Spire_" .. tostring(i), Vector3.new(0.35, height, 0.4), spireCF, obsColor, Enum.Material.Marble)

		-- Cabochon Ruby Gemstone Tip
		createPart(model, "RubyTip_" .. tostring(i), Vector3.new(0.42, 0.42, 0.42), cframe * CFrame.new(x, height + 0.55, z), rubyColor, Enum.Material.Neon, Enum.PartType.Ball)
	end

	-- Central Floating Void Core / Singularity
	local voidCore = createPart(model, "VoidSingularity", Vector3.new(0.9, 0.9, 0.9), cframe * CFrame.new(0, 1.4, 0), voidViolet, Enum.Material.Neon)
	voidCore.CFrame = (cframe * CFrame.new(0, 1.4, 0)) * CFrame.Angles(math.rad(45), math.rad(45), 0)

	-- 4 Orbiting Levitating Void Runes
	for r = 1, 4 do
		local rAngle = math.rad((r - 1) * 90 + 22.5)
		local rRadius = 2.2
		local rx = math.cos(rAngle) * rRadius
		local rz = math.sin(rAngle) * rRadius
		local runeCF = (cframe * CFrame.new(rx, 1.6, rz)) * CFrame.Angles(math.rad(30), rAngle, math.rad(15))
		local rune = createPart(model, "VoidRune_" .. tostring(r), Vector3.new(0.2, 0.5, 0.3), runeCF, Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
	end

	-- Floating Levitating Halo Ring
	local halo = createPart(model, "LevitatingHalo", Vector3.new(0.2, 2.4, 2.4), cframe * CFrame.new(0, 3.2, 0), goldColor, Enum.Material.Neon, Enum.PartType.Cylinder)
	halo.CFrame = (cframe * CFrame.new(0, 3.2, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Divine Crimson & Violet PointLight Aura
	local light = Instance.new("PointLight")
	light.Color = rubyColor
	light.Brightness = 3.2
	light.Range = 22
	light.Parent = circlet

	-- Celestial Embers Particle Emitter
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "CrownEmbers"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(233, 30, 99)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(156, 39, 176)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(64, 196, 255)),
	})
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	pe.Lifetime = NumberRange.new(1.0, 2.0)
	pe.Rate = 20
	pe.Speed = NumberRange.new(0.8, 1.8)
	pe.SpreadAngle = Vector2.new(30, 30)
	pe.Parent = voidCore

	model.Parent = parent
	return model
end

-- 6. Ancient Hourglass (Golden sand falling upward, ornate brass stanchions, glowing time motes)
function RelicMeshBuilder.CreateAncientHourglass(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Relic_AncientHourglass"

	local brassColor = Color3.fromRGB(212, 168, 67)
	local darkBrass = Color3.fromRGB(140, 105, 35)
	local sandGold = Color3.fromRGB(255, 193, 7)
	local glassColor = Color3.fromRGB(230, 245, 255)

	-- Bottom Base Plate (Stepped Hexagonal / Cylindrical Brass)
	local basePlate = createPart(model, "BasePlate", Vector3.new(0.4, 3.0, 3.0), cframe * CFrame.new(0, 0.2, 0), brassColor, Enum.Material.Metal, Enum.PartType.Cylinder)
	basePlate.CFrame = (cframe * CFrame.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	model.PrimaryPart = basePlate

	local baseBezel = createPart(model, "BaseBezel", Vector3.new(0.45, 2.6, 2.6), cframe * CFrame.new(0, 0.4, 0), darkBrass, Enum.Material.Metal, Enum.PartType.Cylinder)
	baseBezel.CFrame = (cframe * CFrame.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Top Cap Plate
	local topPlate = createPart(model, "TopPlate", Vector3.new(0.4, 3.0, 3.0), cframe * CFrame.new(0, 4.4, 0), brassColor, Enum.Material.Metal, Enum.PartType.Cylinder)
	topPlate.CFrame = (cframe * CFrame.new(0, 4.4, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local topBezel = createPart(model, "TopBezel", Vector3.new(0.45, 2.6, 2.6), cframe * CFrame.new(0, 4.2, 0), darkBrass, Enum.Material.Metal, Enum.PartType.Cylinder)
	topBezel.CFrame = (cframe * CFrame.new(0, 4.2, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- 4 Ornate Brass Pillars / Stanchions
	local pillarPositions = {
		Vector3.new(1.1, 2.3, 1.1),
		Vector3.new(-1.1, 2.3, 1.1),
		Vector3.new(1.1, 2.3, -1.1),
		Vector3.new(-1.1, 2.3, -1.1),
	}
	for i, pos in ipairs(pillarPositions) do
		createPart(model, "Stanchion_" .. tostring(i), Vector3.new(0.25, 4.0, 0.25), cframe * CFrame.new(pos), brassColor, Enum.Material.Metal)
		-- Ornate mid-knop
		createPart(model, "StanchionKnop_" .. tostring(i), Vector3.new(0.4, 0.4, 0.4), cframe * CFrame.new(pos), darkBrass, Enum.Material.Metal, Enum.PartType.Ball)
	end

	-- Lower Glass Bulb
	local lowerBulb = createPart(model, "LowerBulb", Vector3.new(1.8, 1.8, 1.8), cframe * CFrame.new(0, 1.5, 0), glassColor, Enum.Material.Glass, Enum.PartType.Ball)
	lowerBulb.Transparency = 0.55

	-- Upper Glass Bulb
	local upperBulb = createPart(model, "UpperBulb", Vector3.new(1.8, 1.8, 1.8), cframe * CFrame.new(0, 3.1, 0), glassColor, Enum.Material.Glass, Enum.PartType.Ball)
	upperBulb.Transparency = 0.55

	-- Glass Waist Neck
	local neck = createPart(model, "GlassWaistNeck", Vector3.new(0.6, 0.5, 0.5), cframe * CFrame.new(0, 2.3, 0), glassColor, Enum.Material.Glass, Enum.PartType.Cylinder)
	neck.CFrame = (cframe * CFrame.new(0, 2.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	neck.Transparency = 0.5

	-- Settled Sand Heap in Lower Bulb
	createPart(model, "LowerSandHeap", Vector3.new(1.2, 0.8, 1.2), cframe * CFrame.new(0, 1.2, 0), sandGold, Enum.Material.Sand, Enum.PartType.Ball)

	-- Falling Golden Sand Stream in Neck
	createPart(model, "SandStream", Vector3.new(0.15, 1.2, 0.15), cframe * CFrame.new(0, 2.3, 0), sandGold, Enum.Material.Neon)

	-- Upper Sand Funnel
	local upperSand = createPart(model, "UpperSandFunnel", Vector3.new(1.3, 0.9, 1.3), cframe * CFrame.new(0, 3.1, 0), sandGold, Enum.Material.Neon, Enum.PartType.Ball)

	-- Amber Time Light
	local light = Instance.new("PointLight")
	light.Color = sandGold
	light.Brightness = 2.0
	light.Range = 12
	light.Parent = upperSand

	-- Upward Defying Time Motes Particle Emitter
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "TimeMotes"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 152, 0)),
	})
	pe.Size = NumberSequence.new(0.16, 0.03)
	pe.Lifetime = NumberRange.new(1.2, 2.2)
	pe.Rate = 10
	pe.Speed = NumberRange.new(0.6, 1.4)
	-- Negative acceleration causes particles to rise upward (defying gravity)
	pe.Acceleration = Vector3.new(0, 2.5, 0)
	pe.Parent = upperSand

	model.Parent = parent
	return model
end

-- 7. Unified Helper: Spawn any relic model by definitionId
function RelicMeshBuilder.SpawnRelicModel(definitionId: string, parent: Instance, cframe: CFrame): Model?
	if definitionId == "relic_scavenger_compass" then
		return RelicMeshBuilder.CreateScavengerCompass(parent, cframe)
	elseif definitionId == "relic_merchants_eye" then
		return RelicMeshBuilder.CreateMerchantsEye(parent, cframe)
	elseif definitionId == "relic_shadow_talisman" then
		return RelicMeshBuilder.CreateShadowTalisman(parent, cframe)
	elseif definitionId == "relic_obsidian_chalice" then
		return RelicMeshBuilder.CreateObsidianChalice(parent, cframe)
	elseif definitionId == "relic_ancient_hourglass" then
		return RelicMeshBuilder.CreateAncientHourglass(parent, cframe)
	elseif definitionId == "relic_hollow_crown" then
		return RelicMeshBuilder.CreateHollowCrown(parent, cframe)
	else
		return RelicMeshBuilder.CreateScavengerCompass(parent, cframe)
	end
end

-- 7. Wearable Hollow Crown for Player Character
function RelicMeshBuilder.CreateWearableHollowCrown(character: Model): Model?
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then return nil end

	local old = character:FindFirstChild("WearableHollowCrown")
	if old then old:Destroy() end

	local crownModel = Instance.new("Model")
	crownModel.Name = "WearableHollowCrown"

	local circlet = Instance.new("Part")
	circlet.Name = "CrownRing"
	circlet.Size = Vector3.new(0.3, 1.4, 1.4)
	circlet.CFrame = head.CFrame * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90))
	circlet.Color = Color3.fromRGB(245, 205, 50)
	circlet.Material = Enum.Material.Metal
	circlet.Shape = Enum.PartType.Cylinder
	circlet.CanCollide = false
	circlet.Anchored = false
	circlet.Parent = crownModel
	crownModel.PrimaryPart = circlet

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = circlet
	weld.Parent = circlet

	-- 8 Miniature Crown Spikes with Ruby Tips
	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45)
		local rad = 0.65
		local x = math.cos(angle) * rad
		local z = math.sin(angle) * rad
		local h = if i % 2 == 1 then 0.7 else 0.45

		local spike = Instance.new("Part")
		spike.Name = "Spike_" .. tostring(i)
		spike.Size = Vector3.new(0.12, h, 0.12)
		spike.CFrame = (circlet.CFrame * CFrame.new(0, h / 2, 0) * CFrame.new(x, 0, z)) * CFrame.Angles(0, -angle, 0)
		spike.Color = Color3.fromRGB(25, 20, 25)
		spike.Material = Enum.Material.Marble
		spike.CanCollide = false
		spike.Anchored = false
		spike.Parent = crownModel

		local sweld = Instance.new("WeldConstraint")
		sweld.Part0 = head
		sweld.Part1 = spike
		sweld.Parent = spike
	end

	-- Floating Halo
	local halo = Instance.new("Part")
	halo.Name = "CrownHalo"
	halo.Size = Vector3.new(0.12, 1.2, 1.2)
	halo.CFrame = head.CFrame * CFrame.new(0, 1.9, 0) * CFrame.Angles(0, 0, math.rad(90))
	halo.Color = Color3.fromRGB(245, 205, 50)
	halo.Material = Enum.Material.Neon
	halo.Shape = Enum.PartType.Cylinder
	halo.CanCollide = false
	halo.Anchored = false
	halo.Parent = crownModel

	local haloWeld = Instance.new("WeldConstraint")
	haloWeld.Part0 = head
	haloWeld.Part1 = halo
	haloWeld.Parent = halo

	-- Miniature Floating Void Singularity in wearable crown
	local voidCore = Instance.new("Part")
	voidCore.Name = "WearableVoidSingularity"
	voidCore.Size = Vector3.new(0.35, 0.35, 0.35)
	voidCore.CFrame = head.CFrame * CFrame.new(0, 1.7, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0)
	voidCore.Color = Color3.fromRGB(156, 39, 176)
	voidCore.Material = Enum.Material.Neon
	voidCore.CanCollide = false
	voidCore.Anchored = false
	voidCore.Parent = crownModel

	local coreWeld = Instance.new("WeldConstraint")
	coreWeld.Part0 = head
	coreWeld.Part1 = voidCore
	coreWeld.Parent = voidCore

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(233, 30, 99)
	light.Brightness = 2.2
	light.Range = 14
	light.Parent = circlet

	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(233, 30, 99)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(156, 39, 176)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(64, 196, 255)),
	})
	pe.Size = NumberSequence.new(0.25, 0.05)
	pe.Lifetime = NumberRange.new(0.5, 1.0)
	pe.Rate = 12
	pe.Speed = NumberRange.new(0.8, 1.6)
	pe.Parent = circlet

	crownModel.Parent = character
	return crownModel
end

-- Unified: Attach visual 3D accessory with particle fx for ANY equipped relic
function RelicMeshBuilder.AttachEquippedRelic(character: Model, relicDefId: string): Model?
	local oldVisual = character:FindFirstChild("EquippedRelicVisual")
	if oldVisual then
		oldVisual:Destroy()
	end
	local oldCrown = character:FindFirstChild("WearableHollowCrown")
	if oldCrown then
		oldCrown:Destroy()
	end

	if relicDefId == "relic_hollow_crown" then
		local crown = RelicMeshBuilder.CreateWearableHollowCrown(character)
		if crown then
			crown.Name = "EquippedRelicVisual"
		end
		return crown
	end

	local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") :: BasePart?
	if not root then return nil end

	local model = Instance.new("Model")
	model.Name = "EquippedRelicVisual"

	if relicDefId == "relic_scavenger_compass" then
		-- Scavenger Compass: Hip holster charm with emerald dial and glowing needle
		local basePart = Instance.new("Part")
		basePart.Name = "CompassCharm"
		basePart.Size = Vector3.new(0.3, 0.9, 0.9)
		basePart.CFrame = root.CFrame * CFrame.new(1.15, -0.4, 0.1) * CFrame.Angles(0, 0, math.rad(90))
		basePart.Color = Color3.fromRGB(225, 175, 55)
		basePart.Material = Enum.Material.Metal
		basePart.Shape = Enum.PartType.Cylinder
		basePart.CanCollide = false
		basePart.Anchored = false
		basePart.Parent = model
		model.PrimaryPart = basePart

		local dial = Instance.new("Part")
		dial.Name = "CompassDial"
		dial.Size = Vector3.new(0.32, 0.7, 0.7)
		dial.CFrame = basePart.CFrame
		dial.Color = Color3.fromRGB(46, 125, 50)
		dial.Material = Enum.Material.Neon
		dial.Shape = Enum.PartType.Cylinder
		dial.CanCollide = false
		dial.Anchored = false
		dial.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = basePart
		weld.Parent = basePart

		local dialWeld = Instance.new("WeldConstraint")
		dialWeld.Part0 = basePart
		dialWeld.Part1 = dial
		dialWeld.Parent = dial

		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(76, 215, 80))
		pe.Size = NumberSequence.new(0.12, 0.02)
		pe.Lifetime = NumberRange.new(0.4, 0.8)
		pe.Rate = 4
		pe.Speed = NumberRange.new(0.3, 0.6)
		pe.Parent = dial

	elseif relicDefId == "relic_merchants_eye" then
		-- Merchant's Eye: Chest pendant amulet with radiant amber pupil
		local basePart = Instance.new("Part")
		basePart.Name = "EyeAmulet"
		basePart.Size = Vector3.new(0.2, 0.8, 1.2)
		basePart.CFrame = root.CFrame * CFrame.new(0, 0.4, -0.65)
		basePart.Color = Color3.fromRGB(245, 195, 45)
		basePart.Material = Enum.Material.Metal
		basePart.CanCollide = false
		basePart.Anchored = false
		basePart.Parent = model
		model.PrimaryPart = basePart

		local eye = Instance.new("Part")
		eye.Name = "AmberEyeCore"
		eye.Size = Vector3.new(0.5, 0.5, 0.5)
		eye.CFrame = basePart.CFrame * CFrame.new(0, 0, -0.1)
		eye.Color = Color3.fromRGB(255, 175, 10)
		eye.Material = Enum.Material.Neon
		eye.Shape = Enum.PartType.Ball
		eye.CanCollide = false
		eye.Anchored = false
		eye.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = basePart
		weld.Parent = basePart

		local eyeWeld = Instance.new("WeldConstraint")
		eyeWeld.Part0 = basePart
		eyeWeld.Part1 = eye
		eyeWeld.Parent = eye

		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 215, 64))
		pe.Size = NumberSequence.new(0.14, 0.03)
		pe.Lifetime = NumberRange.new(0.5, 0.9)
		pe.Rate = 5
		pe.Speed = NumberRange.new(0.3, 0.7)
		pe.Parent = eye

	elseif relicDefId == "relic_shadow_talisman" then
		-- Shadow Talisman: Faceted obsidian pendant on left hip with purple mist
		local basePart = Instance.new("Part")
		basePart.Name = "TalismanPrism"
		basePart.Size = Vector3.new(0.5, 1.2, 0.5)
		basePart.CFrame = root.CFrame * CFrame.new(-1.15, -0.3, 0)
		basePart.Color = Color3.fromRGB(22, 20, 28)
		basePart.Material = Enum.Material.Marble
		basePart.CanCollide = false
		basePart.Anchored = false
		basePart.Parent = model
		model.PrimaryPart = basePart

		local core = Instance.new("Part")
		core.Name = "AmethystCore"
		core.Size = Vector3.new(0.35, 0.8, 0.35)
		core.CFrame = basePart.CFrame
		core.Color = Color3.fromRGB(156, 39, 176)
		core.Material = Enum.Material.Neon
		core.CanCollide = false
		core.Anchored = false
		core.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = basePart
		weld.Parent = basePart

		local coreWeld = Instance.new("WeldConstraint")
		coreWeld.Part0 = basePart
		coreWeld.Part1 = core
		coreWeld.Parent = core

		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(186, 104, 200))
		pe.Size = NumberSequence.new(0.18, 0.04)
		pe.Lifetime = NumberRange.new(0.6, 1.1)
		pe.Rate = 6
		pe.Speed = NumberRange.new(0.2, 0.5)
		pe.Parent = core

	elseif relicDefId == "relic_obsidian_chalice" then
		-- Obsidian Chalice: Mini fluted chalice charm with sapphire vapor
		local basePart = Instance.new("Part")
		basePart.Name = "ChaliceCup"
		basePart.Size = Vector3.new(0.8, 0.8, 0.8)
		basePart.CFrame = root.CFrame * CFrame.new(1.15, -0.2, -0.3)
		basePart.Color = Color3.fromRGB(20, 22, 26)
		basePart.Material = Enum.Material.Marble
		basePart.CanCollide = false
		basePart.Anchored = false
		basePart.Parent = model
		model.PrimaryPart = basePart

		local elixir = Instance.new("Part")
		elixir.Name = "SapphireElixirTop"
		elixir.Size = Vector3.new(0.6, 0.2, 0.6)
		elixir.CFrame = basePart.CFrame * CFrame.new(0, 0.35, 0)
		elixir.Color = Color3.fromRGB(33, 150, 243)
		elixir.Material = Enum.Material.Neon
		elixir.CanCollide = false
		elixir.Anchored = false
		elixir.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = basePart
		weld.Parent = basePart

		local elixirWeld = Instance.new("WeldConstraint")
		elixirWeld.Part0 = basePart
		elixirWeld.Part1 = elixir
		elixirWeld.Parent = elixir

		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
		pe.Size = NumberSequence.new(0.2, 0.05)
		pe.Lifetime = NumberRange.new(0.6, 1.2)
		pe.Rate = 7
		pe.Speed = NumberRange.new(0.4, 0.8)
		pe.Parent = elixir

	elseif relicDefId == "relic_ancient_hourglass" then
		-- Ancient Hourglass: Brass hourglass with golden time sand
		local basePart = Instance.new("Part")
		basePart.Name = "HourglassWaist"
		basePart.Size = Vector3.new(0.6, 1.3, 0.6)
		basePart.CFrame = root.CFrame * CFrame.new(-1.15, -0.2, -0.3)
		basePart.Color = Color3.fromRGB(212, 168, 67)
		basePart.Material = Enum.Material.Metal
		basePart.CanCollide = false
		basePart.Anchored = false
		basePart.Parent = model
		model.PrimaryPart = basePart

		local sand = Instance.new("Part")
		sand.Name = "HourglassSandGlow"
		sand.Size = Vector3.new(0.4, 0.9, 0.4)
		sand.CFrame = basePart.CFrame
		sand.Color = Color3.fromRGB(255, 193, 7)
		sand.Material = Enum.Material.Neon
		sand.CanCollide = false
		sand.Anchored = false
		sand.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = basePart
		weld.Parent = basePart

		local sandWeld = Instance.new("WeldConstraint")
		sandWeld.Part0 = basePart
		sandWeld.Part1 = sand
		sandWeld.Parent = sand

		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 215, 120))
		pe.Size = NumberSequence.new(0.12, 0.02)
		pe.Lifetime = NumberRange.new(0.7, 1.4)
		pe.Rate = 6
		pe.Speed = NumberRange.new(0.3, 0.7)
		pe.Acceleration = Vector3.new(0, 1.5, 0)
		pe.Parent = sand
	end

	model.Parent = character
	return model
end

-- 8. Museum-Grade Relic Display Plinth
function RelicMeshBuilder.CreateRelicPlinth(parent: Instance, cframe: CFrame, relicDefId: string): Model
	local model = Instance.new("Model")
	model.Name = "ShowcasePlinth_" .. relicDefId

	-- Stepped Obsidian / Marble Pedestal Base
	local basePlinth = createPart(model, "PlinthBase", Vector3.new(0.6, 5.0, 5.0), cframe * CFrame.new(0, 0.3, 0), Color3.fromRGB(30, 26, 35), Enum.Material.Marble, Enum.PartType.Cylinder)
	basePlinth.CFrame = (cframe * CFrame.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	model.PrimaryPart = basePlinth

	-- Gold Filigree Inlay Ring
	local goldRing = createPart(model, "PlinthGoldRim", Vector3.new(0.65, 4.6, 4.6), cframe * CFrame.new(0, 0.6, 0), Color3.fromRGB(225, 185, 50), Enum.Material.Metal, Enum.PartType.Cylinder)
	goldRing.CFrame = (cframe * CFrame.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Fluted Pedestal Column
	local column = createPart(model, "PlinthCol", Vector3.new(2.8, 3.2, 3.2), cframe * CFrame.new(0, 2.2, 0), Color3.fromRGB(24, 20, 28), Enum.Material.Marble, Enum.PartType.Cylinder)
	column.CFrame = (cframe * CFrame.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Velvet Exhibition Cushion Top
	local cushion = createPart(model, "VelvetCushion", Vector3.new(0.5, 3.8, 3.8), cframe * CFrame.new(0, 3.8, 0), Color3.fromRGB(115, 25, 40), Enum.Material.Fabric, Enum.PartType.Cylinder)
	cushion.CFrame = (cframe * CFrame.new(0, 3.8, 0)) * CFrame.Angles(0, 0, math.rad(90))

	-- Engraved Brass Name Plaque
	local plaque = createPart(model, "BrassNamePlaque", Vector3.new(1.8, 0.6, 0.1), cframe * CFrame.new(0, 1.8, 1.7), Color3.fromRGB(235, 195, 55), Enum.Material.Metal)

	-- Spawn the actual 3D relic model on top of the cushion
	local relicModel = RelicMeshBuilder.SpawnRelicModel(relicDefId, model, cframe * CFrame.new(0, 4.4, 0))

	-- Ambient Display Spotlight
	local spotlight = Instance.new("SpotLight")
	spotlight.Brightness = 2.4
	spotlight.Range = 16
	spotlight.Angle = 45
	spotlight.Face = Enum.NormalId.Top
	spotlight.Color = Color3.fromRGB(255, 235, 180)
	spotlight.Parent = cushion

	model.Parent = parent
	return model
end

return RelicMeshBuilder
