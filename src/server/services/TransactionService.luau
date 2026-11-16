--!strict
-- TransactionService.luau
-- Authoritative transaction manager with idempotency enforcement and ledger auditing

local HttpService = game:GetService("HttpService")
local CommonTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))

type TransactionReceipt = CommonTypes.TransactionReceipt

local TransactionService = {}

-- Store processed transactions per player: [playerId] = { [idempotencyKey] = { receipt = TransactionReceipt, data = any } }
local processedTransactions: { [number]: { [string]: { receipt: TransactionReceipt, data: any } } } = {}

function TransactionService.Init()
	-- Clean up on player removing
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		processedTransactions[player.UserId] = nil
	end)
end

function TransactionService.Process<T>(
	player: Player,
	idempotencyKey: string?,
	reasonCode: string,
	operation: () -> (boolean, string, T?)
): (boolean, string, T?, TransactionReceipt)
	local userId = player.UserId

	if not processedTransactions[userId] then
		processedTransactions[userId] = {}
	end

	-- If an idempotency key was supplied and was already processed, return the cached result
	if idempotencyKey and idempotencyKey ~= "" then
		local cached = processedTransactions[userId][idempotencyKey]
		if cached then
			warn(string.format("[TransactionService] Duplicate request intercepted for Player %s (Key: %s). Returning cached result.", player.Name, idempotencyKey))
			return cached.receipt.success, cached.receipt.reasonCode, cached.data, cached.receipt
		end
	else
		-- Auto-generate a key if not provided
		idempotencyKey = HttpService:GenerateGUID(false)
	end

	-- Execute the authoritative transaction operation
	local success, message, resultData = operation()

	local receipt: TransactionReceipt = {
		transactionId = HttpService:GenerateGUID(false),
		idempotencyKey = idempotencyKey :: string,
		playerId = userId,
		success = success,
		reasonCode = if success then reasonCode else message,
		timestamp = os.time(),
	}

	-- Cache result
	processedTransactions[userId][idempotencyKey :: string] = {
		receipt = receipt,
		data = resultData,
	}

	return success, message, resultData, receipt
end

return TransactionService
