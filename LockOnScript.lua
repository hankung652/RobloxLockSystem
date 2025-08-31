--// Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlayerGui = player:WaitForChild("PlayerGui")

--// GUI Setup
local screenGui = Instance.new("ScreenGui", PlayerGui)

-- วงกลมตรงกลางจอ
local circle = Instance.new("Frame")
circle.Size = UDim2.new(0, 200, 0, 200)
circle.Position = UDim2.new(0.5, -100, 0.5, -100)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
circle.BackgroundTransparency = 0.8
circle.BorderSizePixel = 2
circle.BorderColor3 = Color3.fromRGB(0, 170, 255)
circle.Visible = false
circle.Parent = screenGui
circle.ZIndex = 5
circle.ClipsDescendants = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = circle

-- ปุ่ม Lock-On ที่ลากได้
local lockButton = Instance.new("ImageButton")
lockButton.Size = UDim2.new(0, 80, 0, 80)
lockButton.Position = UDim2.new(0.9, 0, 0.4, 0)
lockButton.Image = "rbxassetid://6035047409" -- ไอคอนล็อก
lockButton.BackgroundTransparency = 1
lockButton.Parent = screenGui
lockButton.ZIndex = 10

-- ทำให้ปุ่มลากได้
local dragging = false
local dragStart, startPos
lockButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = lockButton.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		lockButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--// Lock-On System
local lockOnEnabled = false
local currentTarget = nil
local maxDistance = 100 -- ระยะสูงสุดในการล็อกเป้า

-- ฟังก์ชันหาศัตรูที่ใกล้ที่สุด
local function getClosestEnemy()
	local closestEnemy = nil
	local shortestDistance = maxDistance
	for _, enemy in pairs(workspace:GetDescendants()) do
		if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy ~= player.Character then
			local distance = (enemy.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
			if distance < shortestDistance and enemy.Humanoid.Health > 0 then
				shortestDistance = distance
				closestEnemy = enemy
			end
		end
	end
	return closestEnemy
end

-- กดปุ่ม Lock-On
lockButton.MouseButton1Click:Connect(function()
	lockOnEnabled = not lockOnEnabled
	circle.Visible = lockOnEnabled
	if lockOnEnabled then
		currentTarget = getClosestEnemy()
	else
		currentTarget = nil
	end
end)

-- ติดตามเป้า
RunService.RenderStepped:Connect(function()
	if lockOnEnabled and currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") and currentTarget.Humanoid.Health > 0 then
		camera.CFrame = CFrame.new(camera.CFrame.Position, currentTarget.HumanoidRootPart.Position)
	else
		if lockOnEnabled then
			currentTarget = getClosestEnemy()
		end
	end
end)
