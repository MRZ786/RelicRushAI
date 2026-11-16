--!strict
-- SettingsController.luau
-- Authoritative client UI for game settings, audio channels (SFX/Music), graphics mode, and multiplatform controls cheatsheet

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local RebirthController = require(script.Parent.RebirthController)

local SettingsController = {}

local activeDimmer: Frame? = nil
local isPerformanceMode = false
local currentSfxStep = 4 -- 80%
local currentMusicStep = 3 -- 60%

local SFX_STEPS = { 0.2, 0.4, 0.6, 0.8, 1.0 }
local MUSIC_STEPS = { 0.0, 0.25, 0.50, 0.75, 1.0 }

function SettingsController.Close()
	if activeDimmer then
		activeDimmer:Destroy()
		activeDimmer = nil
	end
end

function SettingsController.IsOpen(): boolean
	return activeDimmer ~= nil
end

function SettingsController.Open()
	SettingsController.Close()
	SoundEffects.PlayClick()

	local theme = UIComponents.Theme
	local dimmer, content = UIComponents.CreateModal("⚙️ SETTINGS & CONTROLS", UDim2.new(0, 560, 0, 560), function()
		activeDimmer = nil
	end)
	activeDimmer = dimmer

	dimmer.Destroying:Connect(function()
		if activeDimmer == dimmer then
			activeDimmer = nil
		end
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = theme.AccentGold
	scroll.Parent = content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scroll

	-- 1. Audio Channels Card
	local audioFrame = UIComponents.CreateRoundedFrame(scroll, UDim2.new(1, -10, 0, 130), UDim2.new(0, 0, 0, 0), theme.Surface, 8)
	local audioHeader = UIComponents.CreateLabel(audioFrame, "🔊 AUDIO & ATMOSPHERIC SOUNDSCAPE", UDim2.new(1, -20, 0, 22), UDim2.new(0, 14, 0, 6), 12, theme.AccentGold)
	audioHeader.Font = Enum.Font.GothamBold

	-- Mute Toggle
	local isMuted = SoundEffects.IsMuted()
	local soundBtnText = if isMuted then "MUTED" else "SOUND ON"
	local soundBtnBg = if isMuted then Color3.fromRGB(90, 40, 40) else theme.AccentGreen
	local muteBtn: TextButton? = nil

	muteBtn = UIComponents.CreateButton(
		audioFrame,
		soundBtnText,
		UDim2.new(0.28, 0, 0, 32),
		UDim2.new(0, 14, 0, 34),
		soundBtnBg,
		function()
			local newMuted = not SoundEffects.IsMuted()
			SoundEffects.SetMuted(newMuted)
			if muteBtn then
				muteBtn.Text = if newMuted then "MUTED" else "SOUND ON"
				muteBtn.BackgroundColor3 = if newMuted then Color3.fromRGB(90, 40, 40) else theme.AccentGreen
			end
		end
	)

	-- SFX Volume Button
	local sfxBtn: TextButton? = nil
	local sfxVal = math.floor(SoundEffects.GetSFXVolume() * 100)
	sfxBtn = UIComponents.CreateButton(
		audioFrame,
		string.format("SFX: %d%%", sfxVal),
		UDim2.new(0.32, 0, 0, 32),
		UDim2.new(0.32, 0, 0, 34),
		theme.Surface,
		function()
			currentSfxStep = (currentSfxStep % #SFX_STEPS) + 1
			local newVol = SFX_STEPS[currentSfxStep]
			SoundEffects.SetSFXVolume(newVol)
			if sfxBtn then
				sfxBtn.Text = string.format("SFX: %d%%", math.floor(newVol * 100))
			end
			SoundEffects.PlayRelicChime()
		end
	)

	-- Music / Ambience Volume Button
	local musicBtn: TextButton? = nil
	local musicVal = math.floor(SoundEffects.GetMusicVolume() * 100)
	musicBtn = UIComponents.CreateButton(
		audioFrame,
		string.format("Music: %d%%", musicVal),
		UDim2.new(0.32, 0, 0, 32),
		UDim2.new(0.66, 0, 0, 34),
		theme.Surface,
		function()
			currentMusicStep = (currentMusicStep % #MUSIC_STEPS) + 1
			local newVol = MUSIC_STEPS[currentMusicStep]
			SoundEffects.SetMusicVolume(newVol)
			if musicBtn then
				musicBtn.Text = string.format("Music: %d%%", math.floor(newVol * 100))
			end
		end
	)

	local audioSubtext = UIComponents.CreateLabel(
		audioFrame,
		"Click buttons to cycle volume levels. Zone ambient soundscape crossfades as you travel.",
		UDim2.new(1, -28, 0, 40),
		UDim2.new(0, 14, 0, 74),
		10,
		theme.TextSecondary
	)
	audioSubtext.TextWrapped = true

	-- 2. Graphics & Performance Mode Card
	local perfFrame = UIComponents.CreateRoundedFrame(scroll, UDim2.new(1, -10, 0, 68), UDim2.new(0, 0, 0, 0), theme.Surface, 8)
	local perfLbl = UIComponents.CreateLabel(perfFrame, "⚡ Performance Graphics Mode", UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 14, 0, 0), 13, theme.TextPrimary)
	perfLbl.Font = Enum.Font.GothamBold

	local perfBtnText = if isPerformanceMode then "ACTIVE" else "STANDARD"
	local perfBtnBg = if isPerformanceMode then Color3.fromRGB(46, 125, 50) else theme.Surface
	local perfBtn: TextButton? = nil

	perfBtn = UIComponents.CreateButton(
		perfFrame,
		perfBtnText,
		UDim2.new(0.32, 0, 0, 34),
		UDim2.new(0.64, 0, 0.5, -17),
		perfBtnBg,
		function()
			isPerformanceMode = not isPerformanceMode
			local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
			if bloom then bloom.Enabled = not isPerformanceMode end
			local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
			if sunRays then sunRays.Enabled = not isPerformanceMode end

			if perfBtn then
				perfBtn.Text = if isPerformanceMode then "ACTIVE" else "STANDARD"
				perfBtn.BackgroundColor3 = if isPerformanceMode then Color3.fromRGB(46, 125, 50) else theme.Surface
			end
		end
	)

	-- 3. Prestige Ascension (Rebirth) Row
	local rebirthFrame = UIComponents.CreateRoundedFrame(scroll, UDim2.new(1, -10, 0, 68), UDim2.new(0, 0, 0, 0), Color3.fromRGB(36, 24, 48), 8)
	local rbtLbl = UIComponents.CreateLabel(rebirthFrame, "🌟 Prestige Ascension (Rebirth)", UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 14, 0, 0), 13, Color3.fromRGB(220, 190, 255))
	rbtLbl.Font = Enum.Font.GothamBold

	UIComponents.CreateButton(
		rebirthFrame,
		"OPEN PORTAL",
		UDim2.new(0.32, 0, 0, 34),
		UDim2.new(0.64, 0, 0.5, -17),
		Color3.fromRGB(130, 50, 180),
		function()
			SettingsController.Close()
			RebirthController.Open()
		end
	)

	-- 4. Multiplatform Controls & Cheatsheet Box
	local keysFrame = UIComponents.CreateRoundedFrame(scroll, UDim2.new(1, -10, 0, 240), UDim2.new(0, 0, 0, 0), theme.Surface, 8)
	local keysHeader = UIComponents.CreateLabel(keysFrame, "🎮 MULTIPLATFORM CONTROLS & SHORTCUTS", UDim2.new(1, -20, 0, 24), UDim2.new(0, 14, 0, 8), 12, theme.AccentGold)
	keysHeader.Font = Enum.Font.GothamBold

	local controls = {
		"[E] / (A) / Tap Prompt — Interact with NPCs, Shops, Pedestals & Terminals",
		"[B] / (X) — Open Relic Collection, Refinement & Discovery Codex",
		"[J] / (Y) — Open Journey & Quests Milestone Log",
		"[P] / (L1) — Open Prestige Ascension (Rebirth) Portal",
		"[Q] / (R1) — Deploy Alchemical Smoke Capsule during Base Raids",
		"[M] / (Select) — Open Game Settings, Graphics & Audio Menu",
		"Mobile Touch — On-screen Quick Action pills are available on top bar",
	}

	for i, text in ipairs(controls) do
		UIComponents.CreateLabel(
			keysFrame,
			text,
			UDim2.new(1, -24, 0, 22),
			UDim2.new(0, 14, 0, 28 + (i * 26)),
			11,
			theme.TextSecondary
		)
	end
end

function SettingsController.Toggle()
	if SettingsController.IsOpen() then
		SettingsController.Close()
	else
		SettingsController.Open()
	end
end

return SettingsController
