--// CONFIG
local LOCK_RANGE = 50 -- ระยะตรวจจับ
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

--// GUI
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockOnUI"
screenGui.Parent = playerGui

-- ปุ่มเปิดปิด
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 120, 0, 50)
toggleButton.Position = UDim2.new(0.05, 0, 0.85, 0)
toggleButton.Text = "Lock-On: OFF"
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Parent = screenGui

-- ทำให้ปุ่มลากได้
local dragging = false
local dragStart, startPos
toggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = toggleButton.Position
	end
end)
toggleButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		local delta = input.Position - dragStart
		toggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- วงกลมตรงกลาง
local lockCircle = Instance.new("Frame")
lockCircle.Size = UDim2.new(0, 250, 0, 250)
lockCircle.AnchorPoint = Vector2.new(0.5, 0.5)
lockCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
lockCircle.BackgroundTransparency = 1
lockCircle.BorderSizePixel = 0
lockCircle.Visible = false
lockCircle.Parent = screenGui

local circleUI = Instance.new("UICorner")
circleUI.CornerRadius = UDim.new(1, 0)
circleUI.Parent = lockCircle

local circleOutline = Instance.new("ImageLabel")
circleOutline.Size = UDim2.new(1, 0, 1, 0)
circleOutline.AnchorPoint = Vector2.new(0.5, 0.5)
circleOutline.Position = UDim2.new(0.5, 0, 0.5, 0)
circleOutline.BackgroundTransparency = 1
circleOutline.Image = "rbxassetid://4632082392" -- วงกลมโปร่ง
circleOutline.ImageColor3 = Color3.fromRGB(0, 170, 255)
circleOutline.Parent = lockCircle

-- ตัวแปรหลัก
local lockOnEnabled = false
local lockedTarget = nil

-- ปุ่ม Toggle
toggleButton.MouseButton1Click:Connect(function()
	lockOnEnabled = not lockOnEnabled
	toggleButton.Text = "Lock-On: " .. (lockOnEnabled and "ON" or "OFF")
	lockCircle.Visible = lockOnEnabled

	if not lockOnEnabled then
		lockedTarget = nil
	end
end)

-- หาเป้าหมาย
local function getClosestEnemy()
	local closest, closestDist = nil, LOCK_RANGE
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v ~= player.Character then
			local hrp = v.HumanoidRootPart
			local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
			if onScreen then
				local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
				if dist < (lockCircle.AbsoluteSize.X/2) and dist < closestDist then
					closestDist = dist
					closest = v
				end
			end
		end
	end
	return closest
end

-- อัปเดตทุกเฟรม
RunService.RenderStepped:Connect(function()
	if lockOnEnabled then
		if not lockedTarget or lockedTarget:FindFirstChild("Humanoid").Health <= 0 then
			lockedTarget = getClosestEnemy()
		end
		if lockedTarget then
			camera.CFrame = CFrame.new(camera.CFrame.Position, lockedTarget.HumanoidRootPart.Position)
		end
	end
end)
