--!strict
-- DialogueController.luau
-- Manages NPC dialogue and the 3-relic starter selection interface

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonTypes = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("types"):WaitForChild("CommonTypes"))
local RelicDefinitions = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("definitions"):WaitForChild("RelicDefinitions"))
local NetworkUtil = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("NetworkUtil"))
local RemoteRegistry = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("network"):WaitForChild("RemoteRegistry"))
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local HUDController = require(script.Parent.HUDController)

type PlayerProfile = CommonTypes.PlayerProfile

local DialogueController = {}

function DialogueController.OpenGuideDialogue(profile: PlayerProfile)
	local theme = UIComponents.Theme
	SoundEffects.PlayNPCVoice("ElderCorvus")

	if not profile.hasSelectedStarter then
		-- Starter Relic Selection Flow (4 Mutually Exclusive Archetypes)
		local dimmer, content = UIComponents.CreateModal("Elder Corvus - Choose Your Starter Relic", UDim2.new(0, 890, 0, 440))

		local intro = UIComponents.CreateLabel(
			content,
			"Welcome, seeker. The Forgotten Market reveals ancient powers to those who listen.\nChoose one bonded relic to begin your journey. Choose wisely—each bestows a permanent unique blessing.",
			UDim2.new(1, 0, 0, 38),
			UDim2.new(0, 0, 0, 0),
			13,
			theme.TextSecondary
		)

		-- 4 Cards Layout with Responsive Horizontal Scroll for Mobile/Touch
		local cardsScroll = Instance.new("ScrollingFrame")
		cardsScroll.Name = "StarterCardsScroll"
		cardsScroll.Size = UDim2.new(1, 0, 1, -44)
		cardsScroll.Position = UDim2.new(0, 0, 0, 44)
		cardsScroll.BackgroundTransparency = 1
		cardsScroll.BorderSizePixel = 0
		cardsScroll.ScrollBarThickness = 4
		cardsScroll.ScrollBarImageColor3 = theme.AccentGold
		cardsScroll.CanvasSize = UDim2.new(0, 856, 0, 0)
		cardsScroll.ZIndex = 10
		cardsScroll.Parent = content

		local cardWidth = 200
		local cardSpacing = 14

		for index, relicId in ipairs(RelicDefinitions.StarterRelicIds) do
			local def = RelicDefinitions.Get(relicId)
			if not def then
				continue
			end

			local xPos = (index - 1) * (cardWidth + cardSpacing)
			local card = UIComponents.CreateRoundedFrame(
				cardsScroll,
				UDim2.new(0, cardWidth, 0, 275),
				UDim2.new(0, xPos, 0, 4),
				theme.Surface,
				8
			)
			card.Active = true
			card.ZIndex = 11

			-- Accent Header
			local accentBar = Instance.new("Frame")
			accentBar.Size = UDim2.new(1, 0, 0, 6)
			accentBar.BackgroundColor3 = def.accentColor
			accentBar.BorderSizePixel = 0
			accentBar.Parent = card

			local nameLbl = UIComponents.CreateLabel(card, def.name, UDim2.new(1, -16, 0, 24), UDim2.new(0, 10, 0, 14), 14, def.accentColor)
			nameLbl.Font = Enum.Font.GothamBold

			local rarityLbl = UIComponents.CreateLabel(card, "Rarity: " .. def.rarity, UDim2.new(1, -16, 0, 18), UDim2.new(0, 10, 0, 38), 11, theme.TextSecondary)

			local buffLbl = UIComponents.CreateLabel(card, def.buff.description, UDim2.new(1, -16, 0, 24), UDim2.new(0, 10, 0, 60), 12, theme.AccentGold)
			buffLbl.Font = Enum.Font.GothamBold

			local descLbl = UIComponents.CreateLabel(card, def.description, UDim2.new(1, -16, 0, 70), UDim2.new(0, 10, 0, 90), 11, theme.TextPrimary)
			descLbl.TextWrapped = true

			local loreLbl = UIComponents.CreateLabel(card, "“" .. def.lore .. "”", UDim2.new(1, -16, 0, 50), UDim2.new(0, 10, 0, 165), 10, theme.TextSecondary)
			loreLbl.TextWrapped = true

			local selectBtn = UIComponents.CreateButton(
				card,
				"Bond & Claim",
				UDim2.new(1, -20, 0, 36),
				UDim2.new(0, 10, 1, -46),
				def.accentColor,
				function()
					print(string.format("[DialogueController] Selected starter relic: %s", def.definitionId))
					local key = HttpService:GenerateGUID(false)
					local selectFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.SelectStarterRelic)
					local result = selectFn:InvokeServer(def.definitionId, key)

					if result and result.success then
						if result.profile then
							HUDController.UpdateProfile(result.profile)
						end
						dimmer:Destroy()
						HUDController.ShowToast("Relic Bonded!", "You have received the " .. def.name, "Success")
					else
						local errMsg = (result and result.message) or "Unknown error occurred."
						warn("[DialogueController] Starter selection failed: " .. errMsg)
						HUDController.ShowToast("Selection Failed", errMsg, "Warning")
					end
				end
			)
			selectBtn.ZIndex = 25
		end
	else
		-- Return Visit Dialogue
		local dimmer, content = UIComponents.CreateModal("Elder Corvus - Market Guide", UDim2.new(0, 520, 0, 280))

		local msg = UIComponents.CreateLabel(
			content,
			"Greetings again, seeker. Your bond with your relic grows stronger.\n\n" ..
			"• Visit Brimstone Bob to trade curiosities or purchase workshop supplies.\n" ..
			"• Expand your starter base east of the plaza.\n" ..
			"• Speak with Vance by the back alley to plan your infiltration of the Obsidian Outpost.",
			UDim2.new(1, 0, 0, 120),
			UDim2.new(0, 0, 0, 10),
			13,
			theme.TextPrimary
		)
		msg.TextWrapped = true

		UIComponents.CreateButton(content, "Understood", UDim2.new(0, 140, 0, 38), UDim2.new(0.5, -70, 1, -50), theme.AccentGold, function()
			dimmer:Destroy()
		end)
	end
end

function DialogueController.OpenValeriaDialogue(profile: PlayerProfile)
	local theme = UIComponents.Theme
	SoundEffects.PlayNPCVoice("Valeria")
	local dimmer, content = UIComponents.CreateModal("Valeria the Antiquarian", UDim2.new(0, 520, 0, 300))

	local msg = UIComponents.CreateLabel(
		content,
		"Greetings, seeker of old curiosities.\n\n" ..
		"I document the five ancient realms of this world:\n" ..
		"• The Empire District: Triumphal arches and secured civic vaults.\n" ..
		"• The Whispering Wilds: Overgrown roots shielding the Ancient Hourglass.\n" ..
		"• The Hollow Realm: Floating celestial obsidian spires and the Hollow Crown.",
		UDim2.new(1, 0, 0, 140),
		UDim2.new(0, 0, 0, 10),
		13,
		theme.TextPrimary
	)
	msg.TextWrapped = true

	UIComponents.CreateButton(content, "Consult & Appraise", UDim2.new(0, 180, 0, 38), UDim2.new(0.5, -90, 1, -50), theme.AccentGold, function()
		local npcFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.InteractNPC)
		npcFn:InvokeServer("Valeria")
		dimmer:Destroy()
	end)
end

function DialogueController.OpenIgnisDialogue(profile: PlayerProfile)
	local theme = UIComponents.Theme
	SoundEffects.PlayNPCVoice("Ignis")
	local dimmer, content = UIComponents.CreateModal("Alchemist Ignis - Arcane Distillation", UDim2.new(0, 520, 0, 290))

	local msg = UIComponents.CreateLabel(
		content,
		"Ah, traveler. The cauldron whispers with potential.\n\n" ..
		"For 10 Relic Shards, I can distill a concentrated vial of shadow-mist.\n" ..
		"When deployed inside the Obsidian Vaults, it will completely blind sentry optical sensors and laser grids.",
		UDim2.new(1, 0, 0, 130),
		UDim2.new(0, 0, 0, 10),
		13,
		theme.TextPrimary
	)
	msg.TextWrapped = true

	UIComponents.CreateButton(content, "Brew Draught (10 Shards)", UDim2.new(0, 200, 0, 38), UDim2.new(0.5, -100, 1, -50), theme.AccentGreen, function()
		local npcFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.InteractNPC)
		npcFn:InvokeServer("Ignis")
		dimmer:Destroy()
	end)
end

function DialogueController.OpenTorvaldDialogue(profile: PlayerProfile)
	local theme = UIComponents.Theme
	SoundEffects.PlayNPCVoice("Torvald")
	local dimmer, content = UIComponents.CreateModal("Torvald the Blacksmith", UDim2.new(0, 520, 0, 290))

	local msg = UIComponents.CreateLabel(
		content,
		"The iron hearth never sleeps.\n\n" ..
		"• Tier 1 Sanctum: A humble shelter for starting your journey.\n" ..
		"• Tier 2 Artisan Workshop: Masonry chimney, anvil, and reinforced weapon racks.\n" ..
		"• Tier 3 Arcane Sanctuary: Fluted marble colonnade and a rotating cosmic power core.",
		UDim2.new(1, 0, 0, 130),
		UDim2.new(0, 0, 0, 10),
		13,
		theme.TextPrimary
	)
	msg.TextWrapped = true

	UIComponents.CreateButton(content, "Consult Forgemaster", UDim2.new(0, 180, 0, 38), UDim2.new(0.5, -90, 1, -50), theme.AccentGold, function()
		local npcFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.InteractNPC)
		npcFn:InvokeServer("Torvald")
		dimmer:Destroy()
	end)
end

function DialogueController.OpenAureliusDialogue(profile: PlayerProfile)
	local theme = UIComponents.Theme
	SoundEffects.PlayNPCVoice("Aurelius")
	local dimmer, content = UIComponents.CreateModal("Tribune Aurelius - Imperial Commander", UDim2.new(0, 540, 0, 310))

	local msg = UIComponents.CreateLabel(
		content,
		"Halt, citizen. You stand upon the Avenue of Caesars in the Empire District.\n\n" ..
		"• The Senatorial Forum is secured by Praetorian sentinels.\n" ..
		"• The Imperial Treasury holds ancient tribute chests to the east.\n" ..
		"• Beneath the Western Aqueduct lies the Sunken Crypt, where royal essence still hums.",
		UDim2.new(1, 0, 0, 140),
		UDim2.new(0, 0, 0, 10),
		13,
		theme.TextPrimary
	)
	msg.TextWrapped = true

	UIComponents.CreateButton(content, "Receive Imperial Orders", UDim2.new(0, 200, 0, 38), UDim2.new(0.5, -100, 1, -50), theme.AccentGold, function()
		local npcFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.InteractNPC)
		npcFn:InvokeServer("Aurelius")
		dimmer:Destroy()
	end)
end

function DialogueController.OpenSylvaDialogue(profile: PlayerProfile)
	local theme = UIComponents.Theme
	SoundEffects.PlayNPCVoice("Sylva")
	local dimmer, content = UIComponents.CreateModal("Keeper Sylva - Warden of the Wilds", UDim2.new(0, 540, 0, 310))

	local msg = UIComponents.CreateLabel(
		content,
		"Peace be upon your footsteps, seeker. The Whispering Wilds welcome those who revere the ancient growth.\n\n" ..
		"• The Elder Ironwood Tree breathes life and mystic spores through the canopy.\n" ..
		"• To the north, the Shrine of Shifting Sands conceals the Ancient Hourglass.\n" ..
		"• To the south, the Sunken Amphitheater reflects the starlight of centuries past.",
		UDim2.new(1, 0, 0, 140),
		UDim2.new(0, 0, 0, 10),
		13,
		theme.TextPrimary
	)
	msg.TextWrapped = true

	UIComponents.CreateButton(content, "Commune with Nature", UDim2.new(0, 190, 0, 38), UDim2.new(0.5, -95, 1, -50), theme.AccentGreen, function()
		local npcFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.InteractNPC)
		npcFn:InvokeServer("Sylva")
		dimmer:Destroy()
	end)
end

function DialogueController.OpenVoidEchoDialogue(profile: PlayerProfile)
	local theme = UIComponents.Theme
	SoundEffects.PlayNPCVoice("VoidEcho")
	local dimmer, content = UIComponents.CreateModal("Echo of the Void - Ancient Sovereign Herald", UDim2.new(0, 560, 0, 320))

	local msg = UIComponents.CreateLabel(
		content,
		"You have breached the Threshold of the Abyss and ascended to the Crown Spire.\n\n" ..
		"Before you rests the Altar of The Hollow Crown, forged in the primordial void.\n" ..
		"Only a master who has conquered the Obsidian Outpost and gathered the sacred relics may commune with the core and claim dominion over the realms.",
		UDim2.new(1, 0, 0, 150),
		UDim2.new(0, 0, 0, 10),
		13,
		theme.TextPrimary
	)
	msg.TextWrapped = true

	UIComponents.CreateButton(content, "Heed the Prophecy", UDim2.new(0, 180, 0, 38), UDim2.new(0.5, -90, 1, -50), Color3.fromRGB(233, 30, 99), function()
		local npcFn = NetworkUtil.GetFunction(RemoteRegistry.Functions.InteractNPC)
		npcFn:InvokeServer("VoidEcho")
		dimmer:Destroy()
	end)
end

return DialogueController
