--!strict
-- LightingConfig.luau
-- Authoritative cinematic dark fantasy lighting for Relic Rush
-- Balances warm directional golden-hour sunlight with atmospheric dusk haze,
-- guaranteeing crisp visibility of architecture and textures without excessive darkness or neon glare.

local Lighting = game:GetService("Lighting")

local LightingConfig = {}

function LightingConfig.Apply()
	-- Core Sun & Sky Properties (Golden Sunset / Twilight transition)
	Lighting.ClockTime = 17.35
	Lighting.GeographicLatitude = 38
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(75, 72, 85)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 95, 115)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 215, 175) -- Warm golden sun rays
	Lighting.ColorShift_Bottom = Color3.fromRGB(45, 40, 55)  -- Deep twilight ground bounce
	Lighting.ShadowSoftness = 0.25
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.6

	-- Atmosphere Effect (Soft dusk haze with rich horizon depth)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(180, 190, 215)
	atmosphere.Decay = Color3.fromRGB(90, 75, 100)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 0.9

	-- ColorCorrection Effect (Rich dark fantasy film grade)
	local cc = Lighting:FindFirstChild("RelicRushColorCorrection") :: ColorCorrectionEffect?
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "RelicRushColorCorrection"
		cc.Parent = Lighting
	end
	cc.Brightness = 0.01
	cc.Contrast = 0.12
	cc.Saturation = 0.18
	cc.TintColor = Color3.fromRGB(255, 250, 245)

	-- Bloom Effect (Restrained to prevent blown-out glare)
	local bloom = Lighting:FindFirstChild("RelicRushBloom") :: BloomEffect?
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "RelicRushBloom"
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.35
	bloom.Size = 18
	bloom.Threshold = 0.94

	-- SunRays Effect (Subtle golden godrays through archways)
	local sunRays = Lighting:FindFirstChild("RelicRushSunRays") :: SunRaysEffect?
	if not sunRays then
		sunRays = Instance.new("SunRaysEffect")
		sunRays.Name = "RelicRushSunRays"
		sunRays.Parent = Lighting
	end
	sunRays.Intensity = 0.08
	sunRays.Spread = 0.65

	print("[LightingConfig] High-fidelity dark fantasy lighting applied with optimal scene visibility.")
end

return LightingConfig
