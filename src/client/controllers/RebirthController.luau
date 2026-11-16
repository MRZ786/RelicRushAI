--!strict
-- RebirthController.luau
-- Authoritative client interface for Optional Prestige Rebirth
-- Features strict confirmation, requirement checks ($2,500 cash, 8 relics),
-- and side-by-side breakdown of what resets vs what is permanently retained.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local HUDController = require(script.Parent.HUDController)

type PlayerProfile = CommonTypes.PlayerProfile

local RebirthController = {}

local activeDimmer: Frame? = nil

function RebirthController.Close()
	if activeDimmer then
		activeDimmer:Destroy()
		activeDimmer = nil
	end
end

function RebirthController.IsOpen(): boolean
	return activeDimmer ~= nil
end

function RebirthController.Toggle(profile: PlayerProfile?)
	if RebirthController.IsOpen() then
		RebirthController.Close()
	else
		RebirthController.Open(profile)
	end
end

function RebirthController.Open(profile: PlayerProfile?)
	RebirthController.Close()
	SoundEffects.PlayClick()

	local targetProfile = profile
	if not targetProfile then
		local getProfileFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.GetPlayerProfile)
		targetProfile = getProfileFn:InvokeServer()
	end
	if not targetProfile then
		return
	end

	local theme = UIComponents.Theme
	local dimmer, content = UIComponents.CreateModal("🌟 PRESTIGE ASCENSION (REBIRTH)", UDim2.new(0, 620, 0, 530), function()
		activeDimmer = nil
	end)
	activeDimmer = dimmer

	dimmer.Destroying:Connect(function()
		if activeDimmer == dimmer then
			activeDimmer = nil
		end
	end)

	-- Subtitle banner
	local banner = UIComponents.CreateRoundedFrame(content, UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 0), Color3.fromRGB(30, 24, 45), 6)
	local bannerLbl = UIComponents.CreateLabel(
		banner,
		"⚡ Rebirth is completely optional. Ascend your sanctum to gain permanent passive income multipliers.",
		UDim2.new(1, -20, 1, 0),
		UDim2.new(0, 10, 0, 0),
		11,
		theme.AccentGold
	)
	bannerLbl.Font = Enum.Font.GothamMedium

	-- Current Prestige Stats Box
	local currentRebirthCount = if targetProfile.rebirthData then targetProfile.rebirthData.rebirthCount else 0
	local currentMultiplier = if targetProfile.rebirthData then targetProfile.rebirthData.prestigeMultiplier else 1.0
	local nextMultiplier = currentMultiplier + EconomyConfig.REBIRTH_PRESTIGE_BONUS

	local statsCard = UIComponents.CreateRoundedFrame(content, UDim2.new(1, 0, 0, 54), UDim2.new(0, 0, 0, 44), theme.Surface, 6)
	UIComponents.CreateLabel(
		statsCard,
		string.format("Current Rank: Rebirth #%d  |  Prestige Multiplier: %.2fx  ➔  Next Rank: %.2fx (+25%% Passive Income)",
			currentRebirthCount, currentMultiplier, nextMultiplier),
		UDim2.new(1, -20, 1, 0),
		UDim2.new(0, 14, 0, 0),
		12,
		Color3.fromRGB(200, 170, 255)
	).Font = Enum.Font.GothamBold

	-- Requirements Box
	local reqFrame = UIComponents.CreateRoundedFrame(content, UDim2.new(1, 0, 0, 72), UDim2.new(0, 0, 0, 106), theme.Background, 6)
	UIComponents.CreateLabel(reqFrame, "ASCENSION REQUIREMENTS", UDim2.new(1, -20, 0, 20), UDim2.new(0, 12, 0, 6), 11, theme.AccentGold).Font = Enum.Font.GothamBold

	local cashHave = targetProfile.currencies.Cash
	local cashReq = EconomyConfig.REBIRTH_MIN_CASH
	local hasCash = cashHave >= cashReq

	local discoveredCount = 0
	for _ in pairs(targetProfile.discoveredRelics) do
		discoveredCount += 1
	end
	local relicsReq = EconomyConfig.REBIRTH_RELIC_REQUIREMENT
	local hasRelics = discoveredCount >= relicsReq

	local cashStatusColor = if hasCash then theme.AccentGreen else Color3.fromRGB(255, 90, 90)
	local relicsStatusColor = if hasRelics then theme.AccentGreen else Color3.fromRGB(255, 90, 90)

	local cashText = string.format("🪙 Cash: $%d / $%d  %s", cashHave, cashReq, if hasCash then "✓ READY" else "✗ INSUFFICIENT")
	local relicsText = string.format("📜 Discovered Relics: %d / %d  %s", discoveredCount, relicsReq, if hasRelics then "✓ READY" else "✗ INSUFFICIENT")

	UIComponents.CreateLabel(reqFrame, cashText, UDim2.new(0.48, 0, 0, 24), UDim2.new(0, 12, 0, 32), 12, cashStatusColor).Font = Enum.Font.GothamMedium
	UIComponents.CreateLabel(reqFrame, relicsText, UDim2.new(0.48, 0, 0, 24), UDim2.new(0.52, 0, 0, 32), 12, relicsStatusColor).Font = Enum.Font.GothamMedium

	-- Comparison Columns (What Resets vs What Is Retained)
	local colWidth = UDim2.new(0.485, 0, 0, 180)
	local leftCol = UIComponents.CreateRoundedFrame(content, colWidth, UDim2.new(0, 0, 0, 186), Color3.fromRGB(36, 20, 20), 6)
	local rightCol = UIComponents.CreateRoundedFrame(content, colWidth, UDim2.new(0.515, 0, 0, 186), Color3.fromRGB(20, 36, 24), 6)

	-- Reset Column
	local resetHeader = UIComponents.CreateLabel(leftCol, "⚠️ WHAT WILL RESET", UDim2.new(1, -16, 0, 22), UDim2.new(0, 10, 0, 8), 12, Color3.fromRGB(255, 120, 120))
	resetHeader.Font = Enum.Font.GothamBold

	local resetItems = {
		"• Wallet Cash resets to $500 starting funds",
		"• Base sanctum tier resets to Tier 1",
		"• Realm gateways relock to Forgotten Wilds",
		"• Uncollected coffer tribute is cleared",
	}
	for i, item in ipairs(resetItems) do
		local lbl = UIComponents.CreateLabel(leftCol, item, UDim2.new(1, -16, 0, 28), UDim2.new(0, 10, 0, 22 + (i * 28)), 11, Color3.fromRGB(220, 190, 190))
		lbl.TextWrapped = true
	end

	-- Retained Column
	local retainHeader = UIComponents.CreateLabel(rightCol, "💎 WHAT YOU PERMANENTLY KEEP", UDim2.new(1, -16, 0, 22), UDim2.new(0, 10, 0, 8), 12, Color3.fromRGB(120, 255, 160))
	retainHeader.Font = Enum.Font.GothamBold

	local retainItems = {
		"• All owned Relics & Refinement upgrades",
		"• Full Discovered Relics & Codex progress",
		"• All Collection Milestones, Titles & Badges",
		"• +25% Permanent Passive Income Multiplier",
		"• All Lore Steles & Regional Secret Caches",
	}
	for i, item in ipairs(retainItems) do
		local lbl = UIComponents.CreateLabel(rightCol, item, UDim2.new(1, -16, 0, 24), UDim2.new(0, 10, 0, 22 + (i * 26)), 11, Color3.fromRGB(190, 230, 200))
		lbl.TextWrapped = true
	end

	-- Bottom Action Row
	local canRebirth = hasCash and hasRelics

	local closeBtn = UIComponents.CreateButton(
		content,
		"Cancel",
		UDim2.new(0.35, 0, 0, 42),
		UDim2.new(0.08, 0, 1, -48),
		theme.Surface,
		function()
			RebirthController.Close()
		end
	)

	local rebirthBtnText = if canRebirth then "🌟 ASCEND THROUGH REBIRTH" else "REQUIREMENTS INCOMPLETE"
	local rebirthBtnBg = if canRebirth then Color3.fromRGB(120, 45, 175) else Color3.fromRGB(60, 60, 65)

	local confirmStep = false
	local rebirthBtn: TextButton? = nil

	rebirthBtn = UIComponents.CreateButton(
		content,
		rebirthBtnText,
		UDim2.new(0.45, 0, 0, 42),
		UDim2.new(0.47, 0, 1, -48),
		rebirthBtnBg,
		function()
			if not canRebirth then
				HUDController.ShowToast("Cannot Rebirth", "You must meet both Cash and Discovered Relic requirements.", "Warning")
				return
			end

			if not confirmStep then
				confirmStep = true
				if rebirthBtn then
					rebirthBtn.Text = "⚠️ CLICK AGAIN TO CONFIRM REBIRTH"
					rebirthBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
				end
				return
			end

			local rebirthFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestRebirth)
			local res = rebirthFn:InvokeServer()
			RebirthController.Close()

			if res and res.success then
				SoundEffects.PlayRelicChime()
				HUDController.ShowToast("Prestige Ascension!", res.message, "Success")
			else
				HUDController.ShowToast("Rebirth Failed", (res and res.message) or "Ascension criteria failed.", "Warning")
			end
		end
	)
end

return RebirthController
