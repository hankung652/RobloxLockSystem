local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Locking = false
local Target = nil

-- ========== Anti-Ban System ==========
local safeUserIds = {
	[LocalPlayer.UserId] = true
}

local function isSafe()
	return safeUserIds[LocalPlayer.UserId]
end

local function protectFromRemoteSpy()
	for _, obj in pairs(getgc(true)) do
		if typeof(obj) == "function" and islclosure(obj) then
			local info = debug.getinfo(obj)
			if info.name == "FireServer" and info.short_src:lower():find("anticheat") then
				hookfunction(obj, function(...)
					if isSafe() then
						return nil
					end
					return obj(...)
				end)
			end
		end
	end
end

local function autoHideUI(ScreenGui)
	while true do
		task.wait(2)
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and not safeUserIds[plr.UserId] then
				ScreenGui.Enabled = false
				Locking = false
				Target = nil
				task.wait(3)
				ScreenGui.Enabled = true
			end
		end
	end
end

-- ========== UI ==========
local function createUI()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "LockOnUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local ToggleButton = Instance.new("TextButton", ScreenGui)
	ToggleButton.Size = UDim2.new(0, 120, 0, 50)
	ToggleButton.Position = UDim2.new(0, 20, 1, -70)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToggleButton.Font = Enum.Font.SourceSansBold
	ToggleButton.TextSize = 20
	ToggleButton.Text = "Lock: OFF"

	-- วงกลมตรงกลางจอ
	local CircleFrame = Instance.new("Frame", ScreenGui)
	CircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	CircleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	CircleFrame.Size = UDim2.new(0, 160, 0, 160) -- ปรับขนาดวงกลม
	CircleFrame.BackgroundTransparency = 1

	local Circle = Instance.new("UICorner", CircleFrame)
	Circle.CornerRadius = UDim.new(1, 0)

	local CircleStroke = Instance.new("UIStroke", CircleFrame)
	CircleStroke.Thickness = 4
	CircleStroke.Color = Color3.fromRGB(255, 255, 255)
	CircleStroke.Transparency = 0.3
	CircleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	CircleFrame.Visible = false -- ซ่อนก่อน

	ToggleButton.MouseButton1Click:Connect(function()
		Locking = not Locking
		ToggleButton.Text = "Lock: " .. (Locking and "ON" or "OFF")
		CircleFrame.Visible = Locking
		if not Locking then Target = nil end
	end)

	-- Drag UI (ปุ่ม Lock ลากได้)
	local dragging, dragStart, startPos
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

	-- เริ่มระบบกันแบน
	if isSafe() then
		task.spawn(function() protectFromRemoteSpy() end)
		task.spawn(function() autoHideUI(ScreenGui) end)
	end
end

-- ========== Lock-on Logic ==========
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

RunService.RenderStepped:Connect(function()
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

-- เรียก UI ครั้งแรก + ทุกครั้งที่เกิดใหม่
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	createUI()
end)

if LocalPlayer.Character then
	createUI()
end
