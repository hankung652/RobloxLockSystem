-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- UI สร้างใน PlayerGui
local gui = Instance.new("ScreenGui")
gui.Name = "LockOnUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- ปุ่ม Toggle + ลากได้
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 100, 0, 40)
toggleButton.Position = UDim2.new(0.05, 0, 0.85, 0)
toggleButton.Text = "Lock On"
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = gui

-- วงกลมตรงกลางจอ
local circle = Instance.new("ImageLabel")
circle.Size = UDim2.new(0, 200, 0, 200)
circle.Position = UDim2.new(0.5, -100, 0.5, -100)
circle.BackgroundTransparency = 1
circle.Image = "rbxassetid://3944703587" -- วงกลมกลวง
circle.ImageTransparency = 0
circle.Parent = gui

-- ตัวแปรระบบ Lock
local locking = false
local currentTarget = nil
local lockRange = 80 -- ระยะตรวจจับ
local targetAlive = true

-- ระบบลาก UI (ปุ่ม Toggle)
local dragging = false
local dragStart, startPos

local function updateInput(input)
	if dragging then
		local delta = input.Position - dragStart
		toggleButton.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end

toggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = toggleButton.Position
	end
end)

UIS.InputChanged:Connect(updateInput)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- ระบบ Lock Target
toggleButton.MouseButton1Click:Connect(function()
	locking = not locking
	if not locking then
		currentTarget = nil
		toggleButton.Text = "Lock On"
	else
		toggleButton.Text = "Locking..."
	end
end)

-- ฟังก์ชันค้นหาเป้าหมายใกล้สุดในวงกลม
local function getClosestTarget()
	local closest, distance = nil, math.huge
	for _, v in pairs(workspace:GetDescendants()) do
		if v:FindFirstChild("Humanoid") and v ~= player.Character then
			local hrp = v:FindFirstChild("HumanoidRootPart")
			if hrp then
				local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
				if visible then
					local center = Vector2.new(circle.AbsolutePosition.X + circle.AbsoluteSize.X / 2, circle.AbsolutePosition.Y + circle.AbsoluteSize.Y / 2)
					local screenPos = Vector2.new(pos.X, pos.Y)
					local dist = (center - screenPos).Magnitude
					if dist < circle.AbsoluteSize.X / 2 and dist < distance then
						closest = v
						distance = dist
					end
				end
			end
		end
	end
	return closest
end

-- ติดตามศัตรูจนตาย
RS.RenderStepped:Connect(function()
	if locking then
		if not currentTarget or not currentTarget:FindFirstChild("Humanoid") or currentTarget.Humanoid.Health <= 0 then
			currentTarget = getClosestTarget()
		end

		if currentTarget then
			workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, currentTarget.HumanoidRootPart.Position)
		end
	end
end)
