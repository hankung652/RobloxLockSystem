local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera
local Locking = false
local Target = nil

-- UI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "LockOnUI"

local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 120, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 1, -70)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 20
ToggleButton.Text = "Lock: OFF"

-- เปิด/ปิดระบบ
ToggleButton.MouseButton1Click:Connect(function()
	Locking = not Locking
	ToggleButton.Text = "Lock: " .. (Locking and "ON" or "OFF")
	if not Locking then Target = nil end
end)

-- ระบบลากปุ่ม UI
local dragging, dragInput, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	ToggleButton.Position = UDim2.new(
		0, startPos.X.Offset + delta.X,
		0, startPos.Y.Offset + delta.Y
	)
end

ToggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = ToggleButton.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

ToggleButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- หาเป้าหมายที่ใกล้ที่สุด
local function GetClosest()
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

-- หมุนกล้องไปหาเป้า
RunService.RenderStepped:Connect(function()
	if Locking then
		if not Target or not Target.Parent or Target.Parent:FindFirstChild("Humanoid").Health <= 0 then
			Target = GetClosest()
		end
		if Target then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Position)
		end
	end
end)
