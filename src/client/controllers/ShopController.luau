--!strict
-- ShopController.luau
-- Manages merchant trading, catalog browsing, and relic sales with before/after Cash confirmation

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("EconomyConfig"))
local RelicDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local HUDController = require(script.Parent.HUDController)

type PlayerProfile = CommonTypes.PlayerProfile
type RelicInstance = CommonTypes.RelicInstance

local ShopController = {}

local function showSellConfirmation(profile: PlayerProfile, inst: RelicInstance, onComplete: () -> ())
	local theme = UIComponents.Theme
	local def = RelicDefinitions.Get(inst.definitionId)
	if not def then return end

	local currentCash = profile.currencies.Cash
	local sellValue = def.baseValue
	local lvl = inst.upgradeLevel or 1
	if lvl == 2 then
		sellValue = math.floor(sellValue * 1.35)
	elseif lvl >= 3 then
		sellValue = math.floor(sellValue * 1.75)
	end

	-- Check if player has Merchant's Eye equipped for bonus calculation
	if profile.equippedRelicId then
		for _, item in ipairs(profile.inventory) do
			if item.instanceId == profile.equippedRelicId then
				local eqDef = RelicDefinitions.Get(item.definitionId)
				if eqDef and eqDef.buff.buffType == "SaleBonus" then
					local eqLvl = item.upgradeLevel or 1
					local mult = if eqLvl == 2 then 1.5 elseif eqLvl >= 3 then 2.0 else 1.0
					sellValue = math.floor(sellValue * (1 + (eqDef.buff.magnitude * mult)))
				end
				break
			end
		end
	end

	local afterCash = currentCash + sellValue

	local dimmer, content = UIComponents.CreateModal("Confirm Relic Appraisal & Sale", UDim2.new(0, 480, 0, 320))

	local intro = UIComponents.CreateLabel(
		content,
		string.format("Are you sure you wish to sell %s?\nOnce sold, ownership transfers permanently to Brimstone Bob.", def.name),
		UDim2.new(1, 0, 0, 40),
		UDim2.new(0, 0, 0, 10),
		13,
		theme.TextPrimary
	)
	intro.TextWrapped = true

	local previewFrame = UIComponents.CreateRoundedFrame(
		content,
		UDim2.new(1, 0, 0, 90),
		UDim2.new(0, 0, 0, 65),
		theme.Surface,
		8
	)

	UIComponents.CreateLabel(
		previewFrame,
		string.format("Appraised Value: 🪙 +%d Cash", sellValue),
		UDim2.new(1, -20, 0, 24),
		UDim2.new(0, 12, 0, 8),
		14,
		theme.AccentGold
	).Font = Enum.Font.GothamBold

	UIComponents.CreateLabel(
		previewFrame,
		string.format("Current Balance: 🪙 %d Cash  ➔  After Sale: 🪙 %d Cash", currentCash, afterCash),
		UDim2.new(1, -20, 0, 24),
		UDim2.new(0, 12, 0, 36),
		12,
		theme.AccentBlue
	)

	if inst.isEquipped then
		local eqWarning = UIComponents.CreateLabel(
			previewFrame,
			"⚠️ WARNING: This relic is currently equipped. Selling will unequip it.",
			UDim2.new(1, -20, 0, 20),
			UDim2.new(0, 12, 0, 62),
			11,
			theme.AccentRed
		)
	end

	-- Confirm Button
	UIComponents.CreateButton(
		content,
		string.format("Confirm Sale (+%d Cash)", sellValue),
		UDim2.new(0.5, -10, 0, 42),
		UDim2.new(0, 0, 1, -50),
		Color3.fromRGB(220, 90, 40),
		function()
			local key = HttpService:GenerateGUID(false)
			local sellFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestSellRelic)
			local res = sellFn:InvokeServer(inst.instanceId, key)

			dimmer:Destroy()
			if res and res.success then
				HUDController.ShowToast("Relic Sold!", res.message, "Success")
				onComplete()
			else
				HUDController.ShowToast("Sale Failed", res.message or "Error", "Warning")
			end
		end
	)

	-- Retain / Cancel Button
	UIComponents.CreateButton(
		content,
		"Retain Item",
		UDim2.new(0.5, -10, 0, 42),
		UDim2.new(0.5, 10, 1, -50),
		theme.Surface,
		function()
			dimmer:Destroy()
		end
	)
end

function ShopController.OpenShop(profile: PlayerProfile)
	local theme = UIComponents.Theme
	SoundEffects.PlayNPCVoice("BrimstoneBob")
	local dimmer, content = UIComponents.CreateModal("Brimstone Bob - Appraiser & Merchant", UDim2.new(0, 680, 0, 480))

	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(1, 0, 0, 36)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = content

	local listScroll = Instance.new("ScrollingFrame")
	listScroll.Size = UDim2.new(1, 0, 1, -50)
	listScroll.Position = UDim2.new(0, 0, 0, 45)
	listScroll.BackgroundTransparency = 1
	listScroll.BorderSizePixel = 0
	listScroll.ScrollBarThickness = 6
	listScroll.Parent = content

	local function renderBuyTab()
		listScroll:ClearAllChildren()
		local layoutInner = Instance.new("UIListLayout")
		layoutInner.Padding = UDim.new(0, 8)
		layoutInner.Parent = listScroll

		for itemId, item in pairs(EconomyConfig.ShopCatalog) do
			local row = UIComponents.CreateRoundedFrame(listScroll, UDim2.new(1, -10, 0, 64), UDim2.new(0, 0, 0, 0), theme.Surface, 6)

			local nameLbl = UIComponents.CreateLabel(row, item.name, UDim2.new(0.6, 0, 0, 22), UDim2.new(0, 12, 0, 8), 14, theme.AccentGold)
			nameLbl.Font = Enum.Font.GothamBold

			local descLbl = UIComponents.CreateLabel(row, item.description, UDim2.new(0.6, 0, 0, 20), UDim2.new(0, 12, 0, 32), 11, theme.TextSecondary)

			local priceLbl = UIComponents.CreateLabel(row, string.format("🪙 %d Cash", item.priceCash), UDim2.new(0.2, 0, 1, 0), UDim2.new(0.62, 0, 0, 0), 13, theme.TextPrimary)

			UIComponents.CreateButton(row, "Purchase", UDim2.new(0.16, 0, 0, 36), UDim2.new(0.82, 0, 0.5, -18), theme.AccentGold, function()
				local key = HttpService:GenerateGUID(false)
				local buyFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.RequestBuyItem)
				local res = buyFn:InvokeServer(itemId, key)

				if res and res.success then
					HUDController.ShowToast("Purchased!", res.message, "Success")
				else
					HUDController.ShowToast("Purchase Failed", res.message or "Error", "Warning")
				end
			end)
		end
	end

	local function renderSellTab()
		listScroll:ClearAllChildren()
		local layoutInner = Instance.new("UIListLayout")
		layoutInner.Padding = UDim.new(0, 8)
		layoutInner.Parent = listScroll

		if #profile.inventory == 0 then
			local empty = UIComponents.CreateLabel(listScroll, "You do not currently carry any relics in your inventory.", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 20), 13, theme.TextSecondary)
			return
		end

		for _, inst in ipairs(profile.inventory) do
			local def = RelicDefinitions.Get(inst.definitionId)
			if not def then
				continue
			end

			local row = UIComponents.CreateRoundedFrame(listScroll, UDim2.new(1, -10, 0, 64), UDim2.new(0, 0, 0, 0), theme.Surface, 6)

			local nameText = def.name .. (if inst.isEquipped then " [Equipped]" else "")
			local nameLbl = UIComponents.CreateLabel(row, nameText, UDim2.new(0.6, 0, 0, 22), UDim2.new(0, 12, 0, 8), 14, def.accentColor)
			nameLbl.Font = Enum.Font.GothamBold

			local descLbl = UIComponents.CreateLabel(row, def.buff.description, UDim2.new(0.6, 0, 0, 20), UDim2.new(0, 12, 0, 32), 11, theme.TextSecondary)

			local value = def.baseValue
			local valLbl = UIComponents.CreateLabel(row, string.format("Appraised: 🪙 %d", value), UDim2.new(0.2, 0, 1, 0), UDim2.new(0.62, 0, 0, 0), 13, theme.TextPrimary)

			UIComponents.CreateButton(row, "Appraise & Sell", UDim2.new(0.18, 0, 0, 36), UDim2.new(0.80, 0, 0.5, -18), Color3.fromRGB(220, 100, 50), function()
				showSellConfirmation(profile, inst, function()
					dimmer:Destroy()
				end)
			end)
		end
	end

	local function renderCosmeticsTab()
		listScroll:ClearAllChildren()
		local layoutInner = Instance.new("UIListLayout")
		layoutInner.Padding = UDim.new(0, 8)
		layoutInner.Parent = listScroll

		local notice = UIComponents.CreateRoundedFrame(listScroll, UDim2.new(1, -10, 0, 36), UDim2.new(0, 0, 0, 0), Color3.fromRGB(36, 28, 48), 6)
		UIComponents.CreateLabel(notice, "✨ COSMETIC ONLY — ZERO PAY-TO-WIN ADVANTAGES — ALL EQUAL GAMEPLAY", UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0), 11, theme.AccentGold).Font = Enum.Font.GothamBold

		local cosmeticList = EconomyConfig.CosmeticCatalog or {}
		for itemId, item in pairs(cosmeticList) do
			local row = UIComponents.CreateRoundedFrame(listScroll, UDim2.new(1, -10, 0, 72), UDim2.new(0, 0, 0, 0), theme.Surface, 6)

			local tagCol = if item.category == "Aura" then Color3.fromRGB(200, 130, 255)
				elseif item.category == "PedestalTrim" then theme.AccentGold
				elseif item.category == "Skin" then theme.AccentBlue
				else Color3.fromRGB(120, 255, 180)

			local nameLbl = UIComponents.CreateLabel(row, string.format("[%s] %s", item.category:upper(), item.name), UDim2.new(0.62, 0, 0, 22), UDim2.new(0, 12, 0, 8), 13, tagCol)
			nameLbl.Font = Enum.Font.GothamBold

			local descLbl = UIComponents.CreateLabel(row, item.description, UDim2.new(0.62, 0, 0, 34), UDim2.new(0, 12, 0, 30), 10, theme.TextSecondary)
			descLbl.TextWrapped = true

			local priceLbl = UIComponents.CreateLabel(row, string.format("💎 %d Shards", item.priceShards), UDim2.new(0.18, 0, 1, 0), UDim2.new(0.64, 0, 0, 0), 12, theme.AccentBlue)

			UIComponents.CreateButton(row, "Unlock", UDim2.new(0.16, 0, 0, 34), UDim2.new(0.82, 0, 0.5, -17), Color3.fromRGB(140, 55, 180), function()
				HUDController.ShowToast("Cosmetic Preview", string.format("Unlocked %s! Equippable in your sanctum builder.", item.name), "Success")
			end)
		end
	end

	-- Tab Buttons
	local buyTabBtn = UIComponents.CreateButton(tabContainer, "Buy Supplies", UDim2.new(0.32, 0, 1, 0), UDim2.new(0, 0, 0, 0), theme.AccentGold, function()
		renderBuyTab()
	end)

	local sellTabBtn = UIComponents.CreateButton(tabContainer, "Sell Relics", UDim2.new(0.32, 0, 1, 0), UDim2.new(0.34, 0, 0, 0), theme.Surface, function()
		renderSellTab()
	end)

	local cosmeticTabBtn = UIComponents.CreateButton(tabContainer, "✨ Cosmetics", UDim2.new(0.32, 0, 1, 0), UDim2.new(0.68, 0, 0, 0), Color3.fromRGB(50, 35, 65), function()
		renderCosmeticsTab()
	end)

	renderBuyTab()
end

return ShopController
