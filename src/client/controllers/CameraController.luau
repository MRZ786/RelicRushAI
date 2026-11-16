--!strict
-- CameraController.luau
-- Authoritative cinematic camera controller for Relic Rush
-- Provides seamless hybrid third-person exploration with cinematic focal moments
-- for NPC introductions, Hollow Crown discovery, and Rebirth ascension.
-- Supports immediate skip (Space / Click / Gamepad) and clean camera restore.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local SoundEffects = require(ReplicatedStorage:WaitForChild("RelicRush"):WaitForChild("audio"):WaitForChild("SoundEffects"))

local CameraController = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local isCinematicActive = false
local currentTween: Tween? = nil
local letterboxTop: Frame? = nil
local letterboxBottom: Frame? = nil
local skipPromptLabel: TextLabel? = nil
local originalCameraType: Enum.CameraType = Enum.CameraType.Custom

function CameraController.Init()
	local mainGui = UIComponents.GetMainGui()

	-- 1. Create Cinematic Letterbox Bars
	letterboxTop = Instance.new("Frame")
	letterboxTop.Name = "CinematicBarTop"
	letterboxTop.Size = UDim2.new(1, 0, 0, 0)
	letterboxTop.Position = UDim2.new(0, 0, 0, 0)
	letterboxTop.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	letterboxTop.BorderSizePixel = 0
	letterboxTop.ZIndex = 60
	letterboxTop.Visible = false
	letterboxTop.Parent = mainGui

	letterboxBottom = Instance.new("Frame")
	letterboxBottom.Name = "CinematicBarBottom"
	letterboxBottom.Size = UDim2.new(1, 0, 0, 0)
	letterboxBottom.Position = UDim2.new(0, 0, 1, 0)
	letterboxBottom.AnchorPoint = Vector2.new(0, 1)
	letterboxBottom.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	letterboxBottom.BorderSizePixel = 0
	letterboxBottom.ZIndex = 60
	letterboxBottom.Visible = false
	letterboxBottom.Parent = mainGui

	skipPromptLabel = UIComponents.CreateLabel(
		letterboxBottom,
		"Press [Space] or Click to Skip",
		UDim2.new(1, -20, 0, 20),
		UDim2.new(0, 10, 0, 10),
		11,
		UIComponents.Theme.TextSecondary,
		Enum.TextXAlignment.Right
	)
	skipPromptLabel.ZIndex = 61

	-- 2. Skip Listeners (Input & Gamepad)
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if not isCinematicActive then return end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA or input.UserInputType == Enum.UserInputType.MouseButton1 then
			CameraController.EndCinematic()
		end
	end)

	print("[CameraController] Cinematic camera moments initialized.")
end

function CameraController.PlayFocalMoment(targetCFrame: CFrame, durationSeconds: number?, onComplete: (() -> ())?)
	if isCinematicActive then
		CameraController.EndCinematic()
	end

	camera = Workspace.CurrentCamera
	if not camera then return end

	isCinematicActive = true
	originalCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	-- Show Letterbox Bars with Smooth Slide-in
	if letterboxTop and letterboxBottom then
		letterboxTop.Visible = true
		letterboxBottom.Visible = true
		letterboxTop.Size = UDim2.new(1, 0, 0, 0)
		letterboxBottom.Size = UDim2.new(1, 0, 0, 0)

		TweenService:Create(letterboxTop, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, 48)
		}):Play()

		TweenService:Create(letterboxBottom, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, 48)
		}):Play()
	end

	-- Smoothly Interpolate Camera to Focal Position
	local dur = durationSeconds or 3.5
	local tweenInfo = TweenInfo.new(dur, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
	currentTween = TweenService:Create(camera, tweenInfo, {
		CFrame = targetCFrame
	})

	if currentTween then
		currentTween:Play()
		currentTween.Completed:Connect(function()
			if isCinematicActive then
				CameraController.EndCinematic()
				if onComplete then
					onComplete()
				end
			end
		end)
	end
end

function CameraController.EndCinematic()
	if not isCinematicActive then return end
	isCinematicActive = false

	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end

	-- Hide Letterbox Bars
	if letterboxTop and letterboxBottom then
		local t1 = TweenService:Create(letterboxTop, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(1, 0, 0, 0)
		})
		local t2 = TweenService:Create(letterboxBottom, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(1, 0, 0, 0)
		})
		t1:Play()
		t2:Play()
		t2.Completed:Connect(function()
			if not isCinematicActive then
				if letterboxTop then letterboxTop.Visible = false end
				if letterboxBottom then letterboxBottom.Visible = false end
			end
		end)
	end

	-- Restore Player Camera Comfort
	camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end
	end
end

function CameraController.IsActive(): boolean
	return isCinematicActive
end

return CameraController