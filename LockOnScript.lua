local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ตัวแปรสถานะ
local Locking = false
local Target = nil
local previousRenderConnection = nil
local existingGui = nil

-- ฟังก์ชันหาเป้าหมายที่ใกล้ที่สุด
local function GetClosest()
	local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not Root then return nil end

	local shortest = math.huge
	local closest = nil
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart
			local dist = (Root.Position - hrp.Position).Magnitude
			if dist < shortest and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
				shortest = dist
				closest = hrp
			end
		end
	end
	return closest
end

-- เคลียร์ระบบเดิมเมื่อรันใหม่
local function resetOldSystem()
	if previousRenderConnection then
		previousRenderConnection:Disconnect()
		previousRenderConnection = nil
	end

	if existingGui then
		existingGui:Destroy()
		existingGui = nil
	end

	Locking = false
	Target = nil
end

-- สร้าง UI
local function createUI()
	resetOldSystem()

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "LockOnUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	existingGui = ScreenGui

	local ToggleButton = Instance.new("TextButton", ScreenGui)
	ToggleButton.Size = UDim2.new(0, 120, 0, 50)
	ToggleButton.Position = UDim2.new(0, 20, 1, -70)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToggleButton.Font = Enum.Font.SourceSansBold
	ToggleButton.TextSize = 20
	ToggleButton.Text = "Lock: OFF"

	ToggleButton.MouseButton1Click:Connect(function()
		Locking = not Locking
		ToggleButton.Text = "Lock: " .. (Locking and "ON" or "OFF")
		if not Locking then Target = nil end
	end)

	-- ระบบลาก UI
	local dragging = false
	local dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		ToggleButton.Position = UDim2.new(
			0, math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - ToggleButton.AbsoluteSize.X),
			0, math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - ToggleButton.AbsoluteSize.Y)
		)
	end

	ToggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = ToggleButton.Position
		end
	end)

	ToggleButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)
end

-- ระบบหมุนกล้อง
local function startLockingLoop()
	previousRenderConnection = RunService.RenderStepped:Connect(function()
		if Locking then
			local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not Root then return end

			if not Target or not Target.Parent or Target.Parent:FindFirstChild("Humanoid").Health <= 0 then
				Target = GetClosest()
			end

			if Target then
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Position)
			end
		end
	end)
end

-- เมื่อเกิดใหม่
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	createUI()
	startLockingLoop()
end)

-- ครั้งแรกตอนโหลด
if LocalPlayer.Character then
	createUI()
	startLockingLoop()
end
