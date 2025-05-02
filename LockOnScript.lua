local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Locking = false
local Target = nil

-- ลบ UI เก่า
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("LockOnUI")
if oldGui then oldGui:Destroy() end

-- ตรวจสอบสิทธิ์ใช้งาน
local safeUsers = {
	[LocalPlayer.Name] = true
}

local function isSafe()
	return safeUsers[LocalPlayer.Name]
end

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockOnUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ปุ่มเปิด/ปิด
local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 120, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 1, -70)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 20
ToggleButton.Text = "Lock: OFF"

-- วงกลมเล็งกลางจอ
local Crosshair = Instance.new("Frame", ScreenGui)
Crosshair.Size = UDim2.new(0, 25, 0, 25)
Crosshair.Position = UDim2.new(0.5, -12, 0.5, -12)
Crosshair.BackgroundTransparency = 1
Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)

local circle = Instance.new("ImageLabel", Crosshair)
circle.Size = UDim2.new(1, 0, 1, 0)
circle.BackgroundTransparency = 1
circle.Image = "rbxassetid://16748711079" -- วงกลมล็อกเป้า
circle.ImageColor3 = Color3.fromRGB(255, 0, 0)

-- กดเปิด/ปิด
ToggleButton.MouseButton1Click:Connect(function()
	Locking = not Locking
	ToggleButton.Text = "Lock: " .. (Locking and "ON" or "OFF")
	if not Locking then Target = nil end
end)

-- ลาก UI
local dragging, dragStart, startPos
ToggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = ToggleButton.Position
	end
end)

ToggleButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		ToggleButton.Position = UDim2.new(
			0, math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - ToggleButton.AbsoluteSize.X),
			0, math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - ToggleButton.AbsoluteSize.Y)
		)
	end
end)

-- หาเป้าหมายใกล้สุด
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

-- หมุนกล้องหาเป้า
RunService.RenderStepped:Connect(function()
	if Locking then
		local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not Root then return end

		if not Target or not Target.Parent or not Target.Parent:FindFirstChild("Humanoid") or Target.Parent.Humanoid.Health <= 0 then
			Target = GetClosest()
		end
		if Target then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Position)
		end
	end
end)

-- ระบบกันแบนเบื้องต้น (ตัด Remote ของ Anti-Cheat)
local function protectFromRemoteSpy()
	for _, obj in pairs(getgc(true)) do
		if typeof(obj) == "function" and islclosure(obj) then
			local info = debug.getinfo(obj)
			if info.name == "FireServer" and info.short_src:lower():find("anticheat") then
				hookfunction(obj, function(...)
					if isSafe() then return nil end
					return obj(...)
				end)
			end
		end
	end
end

-- ซ่อน UI ถ้ามีผู้เล่นอื่นอยู่ใกล้
local function autoHideUI()
	while true do
		task.wait(2)
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and not safeUsers[plr.Name] then
				ScreenGui.Enabled = false
				Locking = false
				Target = nil
				task.wait(3)
				ScreenGui.Enabled = true
			end
		end
	end
end

-- เรียกเมื่อเกิดใหม่
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	script:Clone().Parent = LocalPlayer:WaitForChild("PlayerScripts")
end)

-- เรียกระบบกันแบนถ้าปลอดภัย
if isSafe() then
	task.spawn(protectFromRemoteSpy)
	task.spawn(autoHideUI)
end
