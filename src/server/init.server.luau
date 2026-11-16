--!strict
-- init.server.luau
-- Authoritative server entry point for Relic Rush Official Release Candidate
-- Coordinates services, world generation, and automated QA diagnostics with robust step recovery

print("==================================================")
print("  STARTING RELIC RUSH SERVER (Release Candidate)  ")
print("==================================================")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local totalSteps = 0
local successfulSteps = 0
local failureLog: { string } = {}

local function runSubsystem(stepName: string, isCritical: boolean, fn: () -> ()): boolean
	totalSteps += 1
	local t0 = os.clock()
	print(string.format("[ServerInit] [%d] Initializing %s...", totalSteps, stepName))
	local ok, err = pcall(fn)
	local elapsed = (os.clock() - t0) * 1000
	if ok then
		successfulSteps += 1
		print(string.format("[ServerInit] [OK] %s initialized in %.2fms", stepName, elapsed))
		return true
	else
		local errMsg = string.format("[ServerInit] [FAIL] %s failed (%.2fms): %s", stepName, elapsed, tostring(err))
		warn(errMsg)
		table.insert(failureLog, stepName .. ": " .. tostring(err))
		if isCritical then
			warn("[ServerInit] CRITICAL failure detected in core domain module!")
		end
		return false
	end
end

-- 1. Initialize Network Layer
runSubsystem("NetworkRemotes", true, function()
	local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
	NetworkUtil.InitializeServer()
end)

-- 2. Domain Services
local TransactionService = nil
runSubsystem("TransactionService", true, function()
	TransactionService = require(script.services.TransactionService)
	TransactionService.Init()
end)

local ProfileService = nil
runSubsystem("ProfileService", true, function()
	ProfileService = require(script.services.ProfileService)
	ProfileService.Init()
end)

local InventoryService = nil
runSubsystem("InventoryService", true, function()
	InventoryService = require(script.services.InventoryService)
	InventoryService.Init()
end)

local EconomyService = nil
runSubsystem("EconomyService", true, function()
	EconomyService = require(script.services.EconomyService)
	EconomyService.Init()
end)

local BaseService = nil
runSubsystem("BaseService", true, function()
	BaseService = require(script.services.BaseService)
	BaseService.Init()
end)

local HeistService = nil
runSubsystem("HeistService", true, function()
	HeistService = require(script.services.HeistService)
	HeistService.Init()
end)

local QuestService = nil
runSubsystem("QuestService", true, function()
	QuestService = require(script.services.QuestService)
	QuestService.Init()
end)

local ExplorationService = nil
runSubsystem("ExplorationService", true, function()
	ExplorationService = require(script.services.ExplorationService)
	ExplorationService.Init()
end)

local InteractionService = nil
runSubsystem("InteractionService", true, function()
	InteractionService = require(script.services.InteractionService)
	InteractionService.Init()
end)

local RegionService = nil
runSubsystem("RegionService", true, function()
	RegionService = require(script.services.RegionService)
	RegionService.Init()
end)

local DungeonCombatService = nil
runSubsystem("DungeonCombatService", true, function()
	DungeonCombatService = require(script.services.DungeonCombatService)
	DungeonCombatService.Init()
end)

-- 3. Construct Game World (All 5 Regions, Dungeons & Arenas)
runSubsystem("WorldBuilder", true, function()
	local WorldBuilder = require(script.world.WorldBuilder)
	WorldBuilder.Build(HeistService, ExplorationService, RegionService, InteractionService, DungeonCombatService)
end)

-- 4. Dynamic Sentry AI Service
runSubsystem("SentryService", false, function()
	local SentryService = require(script.services.SentryService)
	SentryService.Init()
end)

-- Startup Summary Banner
print("==================================================")
if #failureLog == 0 then
	print(string.format("  SERVER STARTUP SUCCESSFUL: %d/%d Subsystems OK", successfulSteps, totalSteps))
	print("  Relic Rush world and domain services are live!")
else
	warn(string.format("  SERVER STARTUP DEGRADED: %d Passed, %d Failed", successfulSteps, #failureLog))
	for _, fail in ipairs(failureLog) do
		warn("   • " .. fail)
	end
end
print("==================================================")

-- 5. Comprehensive QA Assertion Suite (Runs asynchronously after boot)
task.defer(function()
	local ok, TestRunner = pcall(function()
		return require(script.tests.VerticalSliceTestRunner)
	end)
	if ok and TestRunner then
		pcall(function()
			TestRunner.RunAllTests()
		end)
	else
		warn("[ServerInit] VerticalSliceTestRunner module failed to load: " .. tostring(TestRunner))
	end
end)

print("[ServerInit] Relic Rush server is fully ready and accepting player sessions.")
