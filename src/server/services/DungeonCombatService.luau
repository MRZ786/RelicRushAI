--!strict
-- DungeonCombatService.luau
-- Authoritative Dungeon Complexes, Environmental Traps, Puzzles, Guardian PvE Action Combat,
-- and Designated Low-Risk Contested PvP Zones for Relic Rush.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local RelicDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))

local ProfileService = require(script.Parent.ProfileService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local RegionService = require(script.Parent.RegionService)

export type GuardianData = {
	id: string,
	name: string,
	dungeonId: string,
	model: Model?,
	maxHealth: number,
	currentHealth: number,
	position: Vector3,
	isAlive: boolean,
	respawnTimestamp: number,
	lootGranted: boolean,
}

local DungeonCombatService = {}

-- 3 Signature Regional Dungeons
local DUNGEONS = {
	["Dungeon_Wilds_Crypt"] = {
		id = "Dungeon_Wilds_Crypt",
		name = "Sunken Crypt of the Druids",
		zoneId = "ForgottenWilds",
		entrancePos = Vector3.new(-6200, 10, -500),
		exitPos = Vector3.new(-6100, 12, -500),
		puzzleSequence = { "Earth", "Water", "Flora", "Sun" },
		playerPuzzleProgress = {} :: { [number]: number }, -- [userId] = nextExpectedIndex
		guardianId = "Guardian_DruidGolem",
		bossDefeated = {} :: { [number]: boolean },
	},
	["Dungeon_Ashen_Catacombs"] = {
		id = "Dungeon_Ashen_Catacombs",
		name = "Catacombs of the Praetors",
		zoneId = "AshenDomain",
		entrancePos = Vector3.new(-1200, 10, -5200),
		exitPos = Vector3.new(-1150, 12, -5200),
		plateTimers = {} :: { [number]: number }, -- [userId] = expiryTimestamp
		platesActive = {} :: { [number]: { [number]: boolean } },
		guardianId = "Guardian_PraetorCenturion",
		bossDefeated = {} :: { [number]: boolean },
	},
	["Dungeon_Hollow_Sanctum"] = {
		id = "Dungeon_Hollow_Sanctum",
		name = "Astral Sanctum of the Void",
		zoneId = "CelestialRift",
		entrancePos = Vector3.new(6500, 290, 800),
		exitPos = Vector3.new(6400, 292, 800),
		lightPathIndex = {} :: { [number]: number },
		guardianId = "Guardian_VoidSentinel",
		bossDefeated = {} :: { [number]: boolean },
	},
}

-- Dungeon Boss Guardians
local GUARDIANS: { [string]: GuardianData } = {
	["Guardian_DruidGolem"] = {
		id = "Guardian_DruidGolem",
		name = "Ancient Ironwood Golem",
		dungeonId = "Dungeon_Wilds_Crypt",
		maxHealth = 250,
		currentHealth = 250,
		position = Vector3.new(-6200, 10, -700),
		isAlive = true,
		respawnTimestamp = 0,
		lootGranted = false,
	},
	["Guardian_PraetorCenturion"] = {
		id = "Guardian_PraetorCenturion",
		name = "Praetorian Centurion Shade",
		dungeonId = "Dungeon_Ashen_Catacombs",
		maxHealth = 350,
		currentHealth = 350,
		position = Vector3.new(-1200, 10, -5400),
		isAlive = true,
		respawnTimestamp = 0,
		lootGranted = false,
	},
	["Guardian_VoidSentinel"] = {
		id = "Guardian_VoidSentinel",
		name = "Void Singularity Sentinel",
		dungeonId = "Dungeon_Hollow_Sanctum",
		maxHealth = 450,
		currentHealth = 450,
		position = Vector3.new(6500, 290, 1000),
		isAlive = true,
		respawnTimestamp = 0,
		lootGranted = false,
	},
}

-- Designated Contested PvP Zone: The Scorched Crucible in Ashen Domain
local PVP_CRUCIBLE_BOUNDS = {
	minX = -80, maxX = 80,
	minZ = -4580, maxZ = -4420,
	minY = 0, maxY = 60,
}

local playerPvPStates: { [number]: boolean } = {}

function DungeonCombatService.IsPlayerInPvPZone(position: Vector3): boolean
	return position.X >= PVP_CRUCIBLE_BOUNDS.minX and position.X <= PVP_CRUCIBLE_BOUNDS.maxX
		and position.Z >= PVP_CRUCIBLE_BOUNDS.minZ and position.Z <= PVP_CRUCIBLE_BOUNDS.maxZ
		and position.Y >= PVP_CRUCIBLE_BOUNDS.minY and position.Y <= PVP_CRUCIBLE_BOUNDS.maxY
end

-- =============================================================================
-- PUZZLE INTERACTION LOGIC
-- =============================================================================
function DungeonCombatService.InteractPuzzle(player: Player, dungeonId: string, puzzleElement: string): (boolean, string, boolean)
	local dungeon = DUNGEONS[dungeonId]
	if not dungeon then
		return false, "Unknown dungeon complex.", false
	end

	local uId = player.UserId

	if dungeonId == "Dungeon_Wilds_Crypt" then
		-- Elemental Rune Sequence: Earth (1) -> Water (2) -> Flora (3) -> Sun (4)
		local currentStep = dungeon.playerPuzzleProgress[uId] or 1
		local expectedElement = dungeon.puzzleSequence[currentStep]

		if puzzleElement == expectedElement then
			if currentStep == #dungeon.puzzleSequence then
				dungeon.playerPuzzleProgress[uId] = #dungeon.puzzleSequence + 1
				return true, "✨ The final elemental seal resonates! The crypt gate unseals!", true
			else
				dungeon.playerPuzzleProgress[uId] = currentStep + 1
				return true, string.format("Rune '%s' aligns! [%d/%d seals active]", puzzleElement, currentStep, #dungeon.puzzleSequence), false
			end
		else
			-- Mistake resets sequence
			dungeon.playerPuzzleProgress[uId] = 1
			return false, string.format("⚡ Runic backlash! '%s' disrupted the alignment. The seals reset.", puzzleElement), false
		end

	elseif dungeonId == "Dungeon_Ashen_Catacombs" then
		-- Timed Pressure Plates (Plates 1, 2, 3 must all be triggered within 18s)
		local plateNum = tonumber(puzzleElement) or 1
		local now = os.time()
		local expiry = dungeon.plateTimers[uId] or 0

		if now > expiry then
			dungeon.platesActive[uId] = {}
			dungeon.plateTimers[uId] = now + 18
		end

		dungeon.platesActive[uId] = dungeon.platesActive[uId] or {}
		dungeon.platesActive[uId][plateNum] = true

		local activeCount = 0
		for _ in pairs(dungeon.platesActive[uId]) do
			activeCount += 1
		end

		if activeCount >= 3 then
			dungeon.plateTimers[uId] = now + 9999
			return true, "⚙️ Heavy bronze gears engage! All 3 pressure plates locked! The portcullis raises!", true
		else
			local timeLeft = (dungeon.plateTimers[uId] or now) - now
			return true, string.format("Plate %d depressed! [%d/3 active • %ds remaining]", plateNum, activeCount, math.max(0, timeLeft)), false
		end

	elseif dungeonId == "Dungeon_Hollow_Sanctum" then
		-- Levitating Crystal Light-Path (Step on plates 1 to 4)
		local stepNum = tonumber(puzzleElement) or 1
		local cur = dungeon.lightPathIndex[uId] or 1

		if stepNum == cur then
			if cur == 4 then
				dungeon.lightPathIndex[uId] = 5
				return true, "🌌 Starlight bridge solidifies across the cosmic void! Passage granted!", true
			else
				dungeon.lightPathIndex[uId] = cur + 1
				return true, string.format("Void crystal %d illuminated! [%d/4]", stepNum, cur), false
			end
		else
			dungeon.lightPathIndex[uId] = 1
			return false, "The astral platform fades into shadow! Path reset.", false
		end
	end

	return false, "Unrecognized puzzle operation.", false
end

-- =============================================================================
-- ACTION COMBAT SYSTEM (PVE GUARDIANS & CONTESTED PVP)
-- =============================================================================
function DungeonCombatService.PlayerAttack(player: Player, targetEntityId: string): (boolean, string, number)
	local char = player.Character
	if not char then return false, "Character not found.", 0 end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return false, "RootPart not found.", 0 end

	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Profile unavailable.", 0 end

	-- Calculate Player Attack Power based on Equipped Relic
	local attackDamage = 35
	if profile.equippedRelicId then
		for _, inst in ipairs(profile.inventory) do
			if inst.instanceId == profile.equippedRelicId then
				local def = RelicDefinitions.Get(inst.definitionId)
				if def then
					if def.rarity == "Mythic" or def.id == "relic_hollow_crown" then
						attackDamage = 95
					elseif def.rarity == "Legendary" then
						attackDamage = 75
					elseif def.rarity == "Epic" then
						attackDamage = 60
					elseif def.rarity == "Rare" then
						attackDamage = 48
					end
				end
				break
			end
		end
	end

	-- 1. Check if Target is a Dungeon Guardian
	local guardian = GUARDIANS[targetEntityId]
	if guardian and guardian.isAlive then
		local dist = (hrp.Position - guardian.position).Magnitude
		if dist > 24 then
			return false, "Target is out of attack range.", 0
		end

		guardian.currentHealth = math.max(0, guardian.currentHealth - attackDamage)
		local event = NetworkUtil.GetEvent(RemoteRegistry.Events.CombatDamageDealt)
		event:FireClient(player, guardian.name, attackDamage, guardian.currentHealth, guardian.maxHealth)

		if guardian.currentHealth <= 0 then
			guardian.isAlive = false
			guardian.respawnTimestamp = os.time() + 180 -- 3-minute respawn timer

			local dungeon = DUNGEONS[guardian.dungeonId]
			if dungeon then
				dungeon.bossDefeated[player.UserId] = true
			end

			local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
			notif:FireClient(player, "🏆 Guardian Vanquished!", string.format("You defeated %s! The treasure vault is now accessible.", guardian.name), "Success")
			return true, string.format("Vanquished %s!", guardian.name), attackDamage
		end

		return true, string.format("Hit %s for %d damage!", guardian.name, attackDamage), attackDamage
	end

	-- 2. Check if Target is a Rival Player in Contested PvP Zone
	local targetPlayer = Players:GetPlayerByUserId(tonumber(targetEntityId) or 0)
	if targetPlayer and targetPlayer ~= player then
		local targetChar = targetPlayer.Character
		local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if targetHrp then
			-- Verify BOTH players are in the designated PvP Crucible
			local attackerInPvP = DungeonCombatService.IsPlayerInPvPZone(hrp.Position)
			local targetInPvP = DungeonCombatService.IsPlayerInPvPZone(targetHrp.Position)

			if not attackerInPvP or not targetInPvP then
				return false, "PvP is strictly disabled outside The Scorched Crucible.", 0
			end

			local dist = (hrp.Position - targetHrp.Position).Magnitude
			if dist > 18 then
				return false, "Rival player is out of melee range.", 0
			end

			local pvpDamage = math.floor(attackDamage * 0.4) -- Balanced PvP damage scaling
			local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
			if targetHum then
				targetHum:TakeDamage(pvpDamage)

				local event = NetworkUtil.GetEvent(RemoteRegistry.Events.CombatDamageDealt)
				event:FireClient(player, targetPlayer.DisplayName, pvpDamage, math.max(0, targetHum.Health), targetHum.MaxHealth)

				-- Check for Non-Destructive PvP Knockout
				if targetHum.Health <= 0 then
					-- Reward attacker with system honor bonus
					EconomyService.AddCash(player, 50)
					EconomyService.AddShards(player, 10)

					local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
					notif:FireClient(player, "⚔️ Crucible Victory!", string.format("Defeated %s in the Crucible! Earned $50 Honor Cash & 10 Shards.", targetPlayer.DisplayName), "Success")
					notif:FireClient(targetPlayer, "🛡️ Crucible Defeat", "Fell in the Crucible. Respawning safely with zero relic or wallet losses.", "Warning")
				end

				return true, string.format("Hit %s for %d PvP damage!", targetPlayer.DisplayName, pvpDamage), pvpDamage
			end
		end
	end

	return false, "No valid combat target in range.", 0
end

-- =============================================================================
-- DUNGEON TREASURE VAULT REWARDS
-- =============================================================================
function DungeonCombatService.ClaimDungeonTreasure(player: Player, dungeonId: string): (boolean, string)
	local dungeon = DUNGEONS[dungeonId]
	if not dungeon then return false, "Unknown dungeon." end

	local uId = player.UserId
	if not dungeon.bossDefeated[uId] then
		return false, "The guardian seal remains active. Defeat the guardian to claim the vault."
	end

	local profile = ProfileService.GetProfile(player)
	if not profile then return false, "Profile unavailable." end

	-- Check cooldown or per-session claim
	dungeon.bossDefeated[uId] = false -- Reset for repeat runs

	if dungeonId == "Dungeon_Wilds_Crypt" then
		EconomyService.AddCash(player, 150)
		EconomyService.AddShards(player, 40)
		InventoryService.AddRelic(player, "relic_shadow_talisman")
		return true, "Ancient Druid Sarcophagus unlocked! Awarded $150 Cash, 40 Shards, and Shadow Talisman!"

	elseif dungeonId == "Dungeon_Ashen_Catacombs" then
		EconomyService.AddCash(player, 220)
		EconomyService.AddShards(player, 65)
		InventoryService.AddRelic(player, "relic_merchants_eye")
		return true, "Imperial Praetor Sarcophagus opened! Awarded $220 Cash, 65 Shards, and Merchant's Eye!"

	elseif dungeonId == "Dungeon_Hollow_Sanctum" then
		EconomyService.AddCash(player, 350)
		EconomyService.AddShards(player, 120)
		InventoryService.AddRelic(player, "relic_hollow_crown")
		return true, "🌌 Reliquary of the Void opened! Awarded $350 Cash, 120 Shards, and The Hollow Crown!"
	end

	return false, "Invalid vault claim."
end

-- =============================================================================
-- INITIALIZATION & HEARTBEAT LOOP
-- =============================================================================
function DungeonCombatService.Init()
	print("[DungeonCombatService] Initializing Dungeons, Traps, Guardian AI, and Contested PvP...")

	-- 1. Hook Remote Functions
	local attackFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestCombatAttack)
	attackFn.OnServerInvoke = function(player: Player, targetId: any)
		if type(targetId) ~= "string" then
			return { success = false, message = "Invalid combat target." }
		end
		local ok, msg, dmg = DungeonCombatService.PlayerAttack(player, targetId)
		return { success = ok, message = msg, damage = dmg }
	end

	local puzzleFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.DungeonInteractPuzzle)
	puzzleFn.OnServerInvoke = function(player: Player, dungeonId: any, element: any)
		if type(dungeonId) ~= "string" or type(element) ~= "string" then
			return { success = false, message = "Invalid puzzle arguments." }
		end
		local ok, msg, solved = DungeonCombatService.InteractPuzzle(player, dungeonId, element)
		return { success = ok, message = msg, isSolved = solved }
	end

	local treasureFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.DungeonClaimTreasure)
	treasureFn.OnServerInvoke = function(player: Player, dungeonId: any)
		if type(dungeonId) ~= "string" then
			return { success = false, message = "Invalid dungeon id." }
		end
		local ok, msg = DungeonCombatService.ClaimDungeonTreasure(player, dungeonId)
		return { success = ok, message = msg }
	end

	-- 2. PvP Boundary Detection & Guardian Respawn Loop
	task.spawn(function()
		while true do
			task.wait(1.0)
			local now = os.time()

			-- Check Guardian Respawns
			for _, g in pairs(GUARDIANS) do
				if not g.isAlive and now >= g.respawnTimestamp then
					g.isAlive = true
					g.currentHealth = g.maxHealth
					print(string.format("[DungeonCombat] Guardian '%s' has regenerated!", g.name))
				end
			end

			-- Check Active Players for Contested PvP State Transitions
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					local inPvP = DungeonCombatService.IsPlayerInPvPZone(hrp.Position)
					local wasInPvP = playerPvPStates[player.UserId] or false

					if inPvP ~= wasInPvP then
						playerPvPStates[player.UserId] = inPvP
						local pvpEvent = NetworkUtil.GetEvent(RemoteRegistry.Events.PvPZoneStateChanged)
						pvpEvent:FireClient(player, inPvP)

						local notif = NetworkUtil.GetEvent(RemoteRegistry.Events.Notification)
						if inPvP then
							notif:FireClient(player, "⚔️ The Scorched Crucible", "WARNING: Entering Contested PvP Zone. Attacks against rival players enabled!", "Warning")
						else
							notif:FireClient(player, "🛡️ Protected Zone", "Exited Contested Zone. Attacks against rival players disabled.", "Info")
						end
					end
				end
			end
		end
	end)

	print("[DungeonCombatService] Dungeons & Action Combat initialized successfully.")
end

return DungeonCombatService
