--!strict
-- RegionService.luau
-- Authoritative server service managing region access requirements, unlocked regions,
-- and secure teleportation / gateway traversal across all 5 game regions.

local Players = game:GetService("Players")

local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local NetworkUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local ProfileService = require(script.Parent.ProfileService)
local EconomyService = require(script.Parent.EconomyService)

export type RegionId = CommonTypes.RegionId

local RegionService = {}

local REGION_SPAWNS: { [string]: Vector3 } = {
	["ForgottenMarket"] = Vector3.new(0, 12, 52),
	["EmpireDistrict"] = Vector3.new(0, 12, -3000),
	["WhisperingWilds"] = Vector3.new(-3000, 12, 0),
	["ObsidianVaults"] = Vector3.new(0, 14, 3000),
	["HollowRealm"] = Vector3.new(3200, 252, 0),
	["ForgottenWilds"] = Vector3.new(-3000, 12, 0),
	["SunkenVault"] = Vector3.new(0, 14, 3000),
	["AshenDomain"] = Vector3.new(0, 12, -3000),
	["CelestialRift"] = Vector3.new(3200, 252, 0),
}

function RegionService.CanAccessRegion(player: Player, regionId: string): (boolean, string)
	local profile = ProfileService.GetProfile(player)
	if not profile then
		return false, "Player profile unavailable."
	end

	-- Forgotten Market is the default hub open to all
	if regionId == "ForgottenMarket" then
		return true, "Authorized"
	end

	-- If already unlocked in profile, access is granted
	if profile.unlockedRegions and profile.unlockedRegions[regionId] then
		return true, "Authorized"
	end
	if profile.unlockedZones and profile.unlockedZones[regionId] then
		return true, "Authorized"
	end

	-- Check unlock prerequisites and zone aliases
	if regionId == "ForgottenWilds" or regionId == "WhisperingWilds" then
		if profile.hasSelectedStarter and #profile.inventory >= 1 then
			profile.unlockedRegions["ForgottenWilds"] = true
			profile.unlockedRegions["WhisperingWilds"] = true
			profile.unlockedZones["ForgottenWilds"] = true
			return true, "Verdant veil traversed! Welcome to the Forgotten Wilds."
		else
			return false, "Locked: Bond with a starter relic from Elder Corvus first."
		end

	elseif regionId == "SunkenVault" or regionId == "ObsidianVaults" then
		if (profile.unlockedZones and profile.unlockedZones["SunkenVault"]) or profile.hasSelectedStarter then
			profile.unlockedZones["SunkenVault"] = true
			profile.unlockedRegions["SunkenVault"] = true
			profile.unlockedRegions["ObsidianVaults"] = true
			return true, "Submerged catacombs breached! Welcome to the Sunken Vault."
		else
			return false, "Locked: You must bond with a relic before venturing into the Sunken Vault."
		end

	elseif regionId == "AshenDomain" or regionId == "EmpireDistrict" then
		if profile.baseData.tier >= 2 or profile.completedHeistsCount >= 1 or (profile.unlockedZones and profile.unlockedZones["AshenDomain"]) then
			profile.unlockedZones["AshenDomain"] = true
			profile.unlockedRegions["AshenDomain"] = true
			profile.unlockedRegions["EmpireDistrict"] = true
			return true, "Imperial volcanic gates breached! Welcome to the Ashen Domain."
		else
			return false, "Locked: Requires Codex Tier 2 (Upgrade Base Workshop to Tier 2 or complete an Infiltration)."
		end

	elseif regionId == "CelestialRift" or regionId == "HollowRealm" then
		if (profile.completedHeistsCount >= 2 and #profile.inventory >= 2) or (profile.unlockedZones and profile.unlockedZones["CelestialRift"]) then
			profile.unlockedZones["CelestialRift"] = true
			profile.unlockedRegions["CelestialRift"] = true
			profile.unlockedRegions["HollowRealm"] = true
			return true, "The Astral Void recognizes your mastery. Entering the Celestial Rift."
		else
			return false, "Locked: The Void Rift rejects you. Requires at least 2 completed Infiltrations and 2 bonded Relics."
		end
	end

	return false, "Unknown region ID: " .. tostring(regionId)
end

function RegionService.TravelToRegion(player: Player, targetRegion: string): (boolean, string)
	local canAccess, reason = RegionService.CanAccessRegion(player, targetRegion)
	if not canAccess then
		local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
		notif:FireClient(player, "Gateway Sealed", reason, "Warning")
		return false, reason
	end

	local spawnPos = REGION_SPAWNS[targetRegion]
	if not spawnPos then
		return false, "Invalid spawn position for region: " .. tostring(targetRegion)
	end

	-- Teleport Player Safely
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart :: BasePart
		hrp.CFrame = CFrame.new(spawnPos)
	end

	local profile = ProfileService.GetProfile(player)
	if profile then
		profile.unlockedRegions[targetRegion] = true
		EconomyService.SyncProfileToClient(player)

		local questServiceModule = script.Parent:FindFirstChild("QuestService")
		if questServiceModule then
			local QuestService = require(questServiceModule :: ModuleScript) :: any
			QuestService.EvaluateQuests(player)
		end
	end

	local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
	notif:FireClient(player, "Region Entered", "Traveled to " .. targetRegion .. "!", "Success")

	return true, "Traveled to " .. targetRegion
end

function RegionService.Init()
	local travelFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestTravelRegion)
	travelFn.OnServerInvoke = function(player: Player, targetRegion: any)
		if type(targetRegion) ~= "string" then
			return { success = false, message = "Invalid region parameter." }
		end
		local ok, msg = RegionService.TravelToRegion(player, targetRegion)
		return { success = ok, message = msg }
	end

	print("[RegionService] Authoritative region progression service initialized.")
end

return RegionService