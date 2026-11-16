--!strict
-- NetworkUtil.luau
-- Safe retrieval and initialization of network communication endpoints

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RemoteRegistry = require(script.Parent.RemoteRegistry)

local REMOTES_FOLDER_NAME = "Remotes"

local NetworkUtil = {}

local function getRemotesFolder(): Folder
	local rootFolder = ReplicatedStorage:WaitForChild("RelicRush", 10)
	if not rootFolder then
		rootFolder = Instance.new("Folder")
		rootFolder.Name = "RelicRush"
		rootFolder.Parent = ReplicatedStorage
	end

	local remotesFolder = rootFolder:FindFirstChild(REMOTES_FOLDER_NAME)
	if not remotesFolder then
		if RunService:IsServer() then
			remotesFolder = Instance.new("Folder")
			remotesFolder.Name = REMOTES_FOLDER_NAME
			remotesFolder.Parent = rootFolder
		else
			remotesFolder = rootFolder:WaitForChild(REMOTES_FOLDER_NAME, 10) :: Folder
		end
	end

	return remotesFolder :: Folder
end

function NetworkUtil.InitializeServer()
	assert(RunService:IsServer(), "NetworkUtil.InitializeServer can only be called from server.")
	local folder = getRemotesFolder()

	for _, name in pairs(RemoteRegistry.Functions) do
		if not folder:FindFirstChild(name) then
			local rf = Instance.new("RemoteFunction")
			rf.Name = name
			rf.Parent = folder
		end
	end

	for _, name in pairs(RemoteRegistry.Events) do
		if not folder:FindFirstChild(name) then
			local re = Instance.new("RemoteEvent")
			re.Name = name
			re.Parent = folder
		end
	end
end

function NetworkUtil.GetFunction(name: string): RemoteFunction
	local folder = getRemotesFolder()
	local rf = folder:WaitForChild(name, 10)
	assert(rf and rf:IsA("RemoteFunction"), "Missing RemoteFunction: " .. name)
	return rf
end

function NetworkUtil.GetEvent(name: string): RemoteEvent
	local folder = getRemotesFolder()
	local re = folder:WaitForChild(name, 10)
	assert(re and re:IsA("RemoteEvent"), "Missing RemoteEvent: " .. name)
	return re
end

return NetworkUtil
