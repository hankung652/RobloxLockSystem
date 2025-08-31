-- // ตัวแปรหลัก
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- // UI Elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockOnGui"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ปุ่มเปิด/ปิด Lock-On
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 1, -70)
ToggleButton.Text = "Lock-On: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Parent = ScreenGui

-- วงกลม Lock-On (อยู่กลางจอ)
local LockCircle = Instance.new("Frame")
LockCircle.Size = UDim2.new(0, 200, 0, 200)
LockCircle.Position = UDim2.new(0.5, -100, 0.5, -100)
LockCircle.AnchorPoint = Vector2.new(0, 0)
LockCircle.BackgroundTransparency = 1
LockCircle.Visible = false
LockCircle.Parent = ScreenGui

local CircleImage = Instance.new("ImageLabel")
CircleImage.Size = UDim2.new(1, 0, 1, 0)
CircleImage.Image = "rbxassetid://3926305904" -- วงกลมโปร่ง
CircleImage.ImageColor3 = Color3.fromRGB(0, 170, 255)
CircleImage.BackgroundTransparency = 1
CircleImage.ImageTransparency = 0.3
CircleImage.Parent = LockCircle

-- // ตัวแปรสถานะ
local LockOnEnabled = false
local LockedTarget = nil
local LockRange = 100 -- ระยะล็อกเป้า

-- // ฟังก์ชันค้นหาเป้าหมายใกล้สุด
local function GetClosestTarget()
	local closest = nil
	local shortestDist = math.huge
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= player.Character then
			local hrp = v:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude
				if dist < shortestDist and dist <= LockRange then
					shortestDist = dist
					closest = v
				end
			end
		end
	end
	return closest
end

-- // ปุ่ม Toggle Lock-On
ToggleButton.MouseButton1Click:Connect(function()
	LockOnEnabled = not LockOnEnabled
	ToggleButton.Text = LockOnEnabled and "Lock-On: ON" or "Lock-On: OFF"
	LockCircle.Visible = LockOnEnabled
	if not LockOnEnabled then
		LockedTarget = nil
	end
end)

-- // อัพเดทกล้องตอน Lock-On
game:GetService("RunService").RenderStepped:Connect(function()
	if LockOnEnabled then
		if not LockedTarget or not LockedTarget:FindFirstChild("Humanoid") or LockedTarget.Humanoid.Health <= 0 then
			LockedTarget = GetClosestTarget()
		end
		if LockedTarget then
			camera.CFrame = CFrame.new(camera.CFrame.Position, LockedTarget.HumanoidRootPart.Position)
		end
	end
end)
