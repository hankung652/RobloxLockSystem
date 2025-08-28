-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "LockOnUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 100, 0, 40)
toggleButton.Position = UDim2.new(0.05, 0, 0.85, 0)
toggleButton.Text = "Lock On"
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = gui

-- Circle UI
local circle = Instance.new("ImageLabel")
circle.Size = UDim2.new(0, 200, 0, 200)
circle.Position = UDim2.new(0.5, -100, 0.5, -100)
circle.BackgroundTransparency = 1
circle.Image = "rbxassetid://3944703587"
circle.ImageTransparency = 0
circle.Parent = gui

-- Lock System
local locking = false
local currentTarget = nil
local lockRange = 80

-- Anti-Ban settings
local antiBanEnabled = true
local minDelay, maxDelay = 0.03, 0.07 -- delay เล็กน้อยเพื่อไม่ให้หุ่นยนต์ชัดเกินไป

-- Dragging
local dragging = false
local dragStart, startPos

local function updateInput(input)
	if dragging and input.Position then
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
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(updateInput)

-- Lock toggle
toggleButton.MouseButton1Click:Connect(function()
	locking = not locking
	if locking then
		toggleButton.Text = "Locking..."
	else
		currentTarget = nil
		toggleButton.Text = "Lock On"
	end
end)

-- Find closest target
local function getClosestTarget()
	local closest, distance = nil, math.huge
	for _, v in pairs(workspace:GetDescendants()) do
		if v:FindFirstChild("Humanoid") and v ~= player.Character then
			local hrp = v:FindFirstChild("HumanoidRootPart")
			if hrp and v.Humanoid.Health > 0 then
				local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
				if visible then
					local center = Vector2.new(circle.AbsolutePosition.X + circle.AbsoluteSize.X/2, circle.AbsolutePosition.Y + circle.AbsoluteSize.Y/2)
					local screenPos = Vector2.new(pos.X, pos.Y)
					local dist = (center - screenPos).Magnitude
					if dist < circle.AbsoluteSize.X/2 and dist < distance then
						closest = v
						distance = dist
					end
				end
			end
		end
	end
	return closest
end

-- Lock on render
RS.RenderStepped:Connect(function()
	if locking then
		if not currentTarget or not currentTarget:FindFirstChild("Humanoid") or currentTarget.Humanoid.Health <= 0 then
			currentTarget = getClosestTarget()
		end

		if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
			local cam = workspace.CurrentCamera
			local targetPos = currentTarget.HumanoidRootPart.Position
			if antiBanEnabled then
				-- Anti-Ban movement: ค่อยๆ หมุนกล้องแบบสุ่มเล็กน้อย
				local currentCFrame = cam.CFrame
				local dir = (targetPos - currentCFrame.Position).Unit
				local offset = Vector3.new(
					math.random(-2,2)/100,
					math.random(-2,2)/100,
					math.random(-2,2)/100
				)
				cam.CFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + dir + offset)
				wait(math.random(minDelay*100, maxDelay*100)/100) -- random delay เล็ก
			else
				cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
			end
		end
	end
end)
