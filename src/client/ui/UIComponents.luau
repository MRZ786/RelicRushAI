--!strict
-- UIComponents.luau
-- Clean programmatic UI building blocks for Relic Rush client interfaces
-- Features luxury dark-fantasy styling, embossed borders, and tactile audio feedback

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))

local UIComponents = {}

local THEME = {
	Background = Color3.fromRGB(22, 24, 30),
	Surface = Color3.fromRGB(32, 36, 46),
	SurfaceHover = Color3.fromRGB(44, 50, 64),
	AccentGold = Color3.fromRGB(255, 193, 7),
	AccentBlue = Color3.fromRGB(64, 196, 255),
	AccentGreen = Color3.fromRGB(76, 175, 80),
	AccentRed = Color3.fromRGB(244, 67, 54),
	TextPrimary = Color3.fromRGB(245, 245, 250),
	TextSecondary = Color3.fromRGB(180, 185, 195),
	Border = Color3.fromRGB(65, 70, 85),
	BorderGold = Color3.fromRGB(180, 140, 50),
}

UIComponents.Theme = THEME

function UIComponents.GetMainGui(): ScreenGui
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local gui = playerGui:FindFirstChild("RelicRushGui") :: ScreenGui?
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "RelicRushGui"
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = playerGui
	end
	return gui :: ScreenGui
end

function UIComponents.CreateRoundedFrame(parent: Instance, size: UDim2, position: UDim2, bgColor: Color3?, radius: number?): Frame
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = bgColor or THEME.Surface
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.Border
	stroke.Thickness = 1
	stroke.Parent = frame

	return frame
end

function UIComponents.CreateButton(parent: Instance, text: string, size: UDim2, position: UDim2, bgColor: Color3?, onClick: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = bgColor or THEME.AccentGold
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(20, 20, 25)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.AutoButtonColor = true
	btn.BorderSizePixel = 0
	btn.Active = true
	btn.Selectable = true
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.8
	stroke.Thickness = 1
	stroke.Parent = btn

	btn.ZIndex = 15

	local debounce = false
	local function trigger()
		if debounce then return end
		debounce = true
		task.delay(0.25, function() debounce = false end)
		SoundEffects.PlayClick()
		onClick()
	end

	btn.Activated:Connect(trigger)

	return btn
end

function UIComponents.CreateLabel(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number?, color: Color3?, align: Enum.TextXAlignment?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or THEME.TextPrimary
	label.Font = Enum.Font.GothamMedium
	label.TextSize = textSize or 14
	label.TextXAlignment = align or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

function UIComponents.CreateModal(title: string, size: UDim2, onClose: (() -> ())?): (Frame, Frame)
	local mainGui = UIComponents.GetMainGui()

	-- Full screen dimmer
	local dimmer = Instance.new("Frame")
	dimmer.Name = "ModalDimmer_" .. title
	dimmer.Size = UDim2.new(1, 0, 1, 0)
	dimmer.Position = UDim2.new(0, 0, 0, 0)
	dimmer.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	dimmer.BackgroundTransparency = 0.45
	dimmer.Active = true
	dimmer.ZIndex = 50
	dimmer.Parent = mainGui

	-- Calculate responsive dimensions against screen viewport
	local camera = Workspace.CurrentCamera
	local vp = if camera and camera.ViewportSize.X > 100 then camera.ViewportSize else Vector2.new(1280, 720)
	local targetW = math.clamp(size.X.Offset, 300, math.floor(vp.X * 0.94))
	local targetH = math.clamp(size.Y.Offset, 220, math.floor(vp.Y * 0.92))

	-- Modal container
	local modal = UIComponents.CreateRoundedFrame(dimmer, UDim2.new(0, targetW, 0, targetH), UDim2.new(0.5, 0, 0.52, 0), THEME.Background, 10)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Active = true
	modal.ZIndex = 51

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(targetW, targetH)
	sizeConstraint.MinSize = Vector2.new(280, 200)
	sizeConstraint.Parent = modal

	-- Smooth entrance tween
	local openTween = TweenService:Create(modal, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	openTween:Play()

	-- Gold Trim Accent on Modal
	local stroke = modal:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = THEME.BorderGold
		stroke.Thickness = 1.5
	end

	-- Title Bar
	local titleLabel = UIComponents.CreateLabel(modal, title, UDim2.new(1, -60, 0, 40), UDim2.new(0, 20, 0, 10), 17, THEME.AccentGold)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.ZIndex = 52

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -45, 0, 15)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Modal = true -- Frees mouse from 3D camera navigation while modal is active
	closeBtn.Active = true
	closeBtn.Selectable = true
	closeBtn.ZIndex = 52
	closeBtn.Parent = modal

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = closeBtn

	local function triggerClose()
		SoundEffects.PlayClick()
		if onClose then
			onClose()
		end
		dimmer:Destroy()
	end

	closeBtn.Activated:Connect(triggerClose)

	-- Content container
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -40, 1, -70)
	content.Position = UDim2.new(0, 20, 0, 60)
	content.BackgroundTransparency = 1
	content.Active = true
	content.ZIndex = 52
	content.Parent = modal

	return dimmer, content
end

-- Backward-compatible alias supporting either parameter order
function UIComponents.CreateModalFrame(title: string, size: UDim2, onClose: (() -> ())?): (Frame, Frame)
	local dimmer, content = UIComponents.CreateModal(title, size, onClose)
	return content, dimmer
end

return UIComponents
