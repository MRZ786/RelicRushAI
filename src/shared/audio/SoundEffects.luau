--!strict
-- SoundEffects.luau
-- Authoritative multi-channel audio engine and atmospheric soundscape for Relic Rush
-- Supports Master, SFX, and Music volume channels, zone ambience with crossfading,
-- and tiered rarity discovery audio using built-in Roblox client audio assets.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundEffects = {}

local isMuted = false
local masterVolume = 0.8
local sfxVolume = 0.8
local musicVolume = 0.6

local currentAmbienceSound: Sound? = nil
local currentZoneId: string = ""

function SoundEffects.SetMuted(muted: boolean)
	isMuted = muted
	if currentAmbienceSound then
		currentAmbienceSound.Volume = if muted then 0 else (musicVolume * masterVolume * 0.5)
	end
end

function SoundEffects.IsMuted(): boolean
	return isMuted
end

function SoundEffects.SetMasterVolume(vol: number)
	masterVolume = math.clamp(vol, 0, 1)
	if currentAmbienceSound and not isMuted then
		currentAmbienceSound.Volume = musicVolume * masterVolume * 0.5
	end
end

function SoundEffects.GetMasterVolume(): number
	return masterVolume
end

function SoundEffects.SetSFXVolume(vol: number)
	sfxVolume = math.clamp(vol, 0, 1)
end

function SoundEffects.GetSFXVolume(): number
	return sfxVolume
end

function SoundEffects.SetMusicVolume(vol: number)
	musicVolume = math.clamp(vol, 0, 1)
	if currentAmbienceSound and not isMuted then
		currentAmbienceSound.Volume = musicVolume * masterVolume * 0.5
	end
end

function SoundEffects.GetMusicVolume(): number
	return musicVolume
end

local function playLocalSound(soundPath: string, baseVolume: number?, pitch: number?): Sound?
	if isMuted then return nil end

	local effectiveVol = (baseVolume or 0.6) * sfxVolume * masterVolume
	if effectiveVol <= 0 then return nil end

	local sound: Sound? = nil
	pcall(function()
		sound = Instance.new("Sound")
		sound.SoundId = soundPath
		sound.Volume = effectiveVol
		sound.PlaybackSpeed = pitch or 1.0
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
	return sound
end

-- 1. UI & Tactical Feedback
function SoundEffects.PlayClick()
	playLocalSound("rbxasset://sounds/button.wav", 0.5, 1.1)
end

function SoundEffects.PlayCash()
	playLocalSound("rbxasset://sounds/uiman_ok.wav", 0.7, 1.0)
end

function SoundEffects.PlayRelicChime()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.25)
end

function SoundEffects.PlayAlarm()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.85, 0.6)
end

function SoundEffects.PlaySentryAlert()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 0.5)
end

function SoundEffects.PlayGatewayTravel()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.4)
end

function SoundEffects.PlayCacheLoot()
	playLocalSound("rbxasset://sounds/uiman_ok.wav", 0.8, 1.2)
end

function SoundEffects.PlayLoreDecipher()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 0.9)
end

function SoundEffects.PlayRefineSuccess()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.85, 1.45)
end

function SoundEffects.PlayVaultStore()
	playLocalSound("rbxasset://sounds/button.wav", 0.7, 0.85)
end

function SoundEffects.PlayQuestComplete()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.35)
end

function SoundEffects.PlayQuestReward()
	playLocalSound("rbxasset://sounds/uiman_ok.wav", 0.9, 1.25)
	task.delay(0.12, function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.8, 1.5)
	end)
end

function SoundEffects.PlayExtractionSuccess()
	playLocalSound("rbxasset://sounds/uiman_ok.wav", 0.95, 1.15)
end

function SoundEffects.PlaySmokeDeploy()
	playLocalSound("rbxasset://sounds/action_falling.mp3", 0.8, 1.5)
end

-- 2. Phase 5 Excavation & Discovery Feedback
function SoundEffects.PlayExcavation()
	playLocalSound("rbxasset://sounds/action_footstep_plastic.mp3", 0.75, 0.8)
	task.delay(0.15, function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.2)
	end)
end

function SoundEffects.PlayRaidSuccess()
	playLocalSound("rbxasset://sounds/uiman_ok.wav", 1.0, 1.2)
	task.delay(0.15, function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.4)
	end)
end

function SoundEffects.PlayRaidFailure()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 0.55)
	task.delay(0.2, function()
		playLocalSound("rbxasset://sounds/action_falling.mp3", 0.7, 0.7)
	end)
end

function SoundEffects.PlayRebirthAscension()
	playLocalSound("rbxasset://sounds/uiman_ok.wav", 1.0, 1.0)
	task.delay(0.2, function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.3)
	end)
	task.delay(0.4, function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.6)
	end)
	task.delay(0.6, function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 1.85)
	end)
end

-- Tiered Rarity Discovery Chimes
function SoundEffects.PlayRarityDiscovery(rarity: string)
	if rarity == "Common" then
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.65, 1.05)
	elseif rarity == "Uncommon" then
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.75, 1.2)
	elseif rarity == "Rare" then
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.85, 1.35)
	elseif rarity == "Epic" then
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.5)
		task.delay(0.15, function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.7)
		end)
	elseif rarity == "Legendary" then
		playLocalSound("rbxasset://sounds/uiman_ok.wav", 0.95, 1.2)
		task.delay(0.15, function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.6)
		end)
		task.delay(0.3, function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 1.9)
		end)
	elseif rarity == "Mythic" then
		-- Majestic Hollow Crown / Mythic Fanfare
		playLocalSound("rbxasset://sounds/uiman_ok.wav", 1.0, 1.1)
		task.delay(0.15, function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.95, 1.4)
		end)
		task.delay(0.35, function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 1.8)
		end)
	elseif rarity == "Cursed" then
		-- Deep Ominous Chord
		playLocalSound("rbxasset://sounds/action_falling.mp3", 0.8, 0.6)
		task.delay(0.1, function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 0.5)
		end)
	else
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.2)
	end
end

-- 3. Atmospheric Zone Ambience System (Crossfading)
local ZONE_AMBIENCE_CONFIG: { [string]: { soundId: string, volume: number, pitch: number } } = {
	["ForgottenMarket"] = {
		soundId = "rbxasset://sounds/action_ambient_wind.mp3",
		volume = 0.40,
		pitch = 1.05,
	},
	["ForgottenWilds"] = {
		soundId = "rbxasset://sounds/action_ambient_wind.mp3",
		volume = 0.55,
		pitch = 0.88,
	},
	["SunkenVault"] = {
		soundId = "rbxasset://sounds/action_ambient_wind.mp3",
		volume = 0.65,
		pitch = 0.65,
	},
	["AshenDomain"] = {
		soundId = "rbxasset://sounds/action_falling.mp3",
		volume = 0.35,
		pitch = 0.40,
	},
	["CelestialRift"] = {
		soundId = "rbxasset://sounds/action_ambient_wind.mp3",
		volume = 0.50,
		pitch = 1.35,
	},
}

-- 4. Voice-Ready NPC Dialogue Audio Architecture
-- Maps canonical NPCs to distinct vocal pitch/tone profiles or custom recorded voice audio IDs
local NPC_VOICE_PROFILES: { [string]: { pitch: number, volume: number, customAssetId: string? } } = {
	["ElderCorvus"] = { pitch = 0.92, volume = 0.65, customAssetId = nil }, -- Gentle scholarly baritone
	["BrimstoneBob"] = { pitch = 1.15, volume = 0.70, customAssetId = nil }, -- Energetic merchant tenor
	["Valeria"] = { pitch = 1.05, volume = 0.65, customAssetId = nil },      -- Analytical antiquarian alto
	["Ignis"] = { pitch = 0.82, volume = 0.60, customAssetId = nil },        -- Muttering arcane alchemist
	["Torvald"] = { pitch = 0.72, volume = 0.75, customAssetId = nil },      -- Deep booming blacksmith bass
	["Vance"] = { pitch = 0.88, volume = 0.60, customAssetId = nil },        -- Quiet covert operative whisper
	["Sylva"] = { pitch = 1.10, volume = 0.65, customAssetId = nil },        -- Resonant melodic druidic warden
	["Aurelius"] = { pitch = 0.76, volume = 0.75, customAssetId = nil },     -- Authoritative praetorian commander
	["VoidEcho"] = { pitch = 0.58, volume = 0.70, customAssetId = nil },     -- Ethereal primordial sovereign resonance
}

function SoundEffects.PlayNPCVoice(npcKey: string)
	local profile = NPC_VOICE_PROFILES[npcKey] or { pitch = 1.0, volume = 0.6, customAssetId = nil }
	if profile.customAssetId and profile.customAssetId ~= "" then
		playLocalSound(profile.customAssetId, profile.volume, profile.pitch)
	else
		-- Distinct procedural character vocal murmur (two-tone pitch blip)
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", profile.volume * 0.45, profile.pitch)
		task.delay(0.08, function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", profile.volume * 0.40, profile.pitch * 1.05)
		end)
	end
end

function SoundEffects.PlayArrivalPing()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.65, 1.45)
end

function SoundEffects.PlayZoneAmbience(zoneId: string)
	if zoneId == currentZoneId then return end
	currentZoneId = zoneId

	local config = ZONE_AMBIENCE_CONFIG[zoneId] or ZONE_AMBIENCE_CONFIG["ForgottenMarket"]

	local oldSound = currentAmbienceSound
	if oldSound then
		local fadeOut = TweenService:Create(oldSound, TweenInfo.new(1.0), { Volume = 0 })
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			oldSound:Stop()
			oldSound:Destroy()
		end)
	end

	pcall(function()
		local sound = Instance.new("Sound")
		sound.Name = "ZoneAmbience_" .. zoneId
		sound.SoundId = config.soundId
		sound.Looped = true
		sound.PlaybackSpeed = config.pitch
		sound.Volume = 0
		sound.Parent = SoundService
		sound:Play()

		currentAmbienceSound = sound

		local targetVol = if isMuted then 0 else (config.volume * musicVolume * masterVolume)
		local fadeIn = TweenService:Create(sound, TweenInfo.new(1.5), { Volume = targetVol })
		fadeIn:Play()
	end)
end

return SoundEffects
