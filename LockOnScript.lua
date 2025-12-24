-- LocalScript (ใส่ใน StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ================= UI =================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockOnSystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- วงกลม Lock-On (กลางจอ / ไม่ลาก / โชว์เฉพาะตอนเปิด)
local circle = Instance.new("Frame")
circle.Size = UDim2.new(0, 200, 0, 200)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Visible = false
circle.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = circle

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 0, 0)
stroke.Thickness = 3
stroke.Parent = circle

-- ปุ่ม Toggle Lock
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 120, 0, 50)
toggleBtn.Position = UDim2.new(0.05, 0, 0.8, 0)
toggleBtn.Text = "Lock: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 22
toggleBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0.3, 0)
btnCorner.Parent = toggleBtn

-- ลากปุ่ม (มือถือ)
local dragging = false
local dragStart, startPos

toggleBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = toggleBtn.Position
	end
end)

toggleBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		toggleBtn.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

-- ================= Lock System =================

local lockActive = false
local lockedTarget = nil

toggleBtn.MouseButton1Click:Connect(function()
	lockActive = not lockActive
	toggleBtn.Text = lockActive and "Lock: ON" or "Lock: OFF"
	circle.Visible = lockActive

	if not lockActive then
		lockedTarget = nil
	end
end)

-- หาเป้าในวงกลมกลางจอ
local function getClosestEnemy()
	local closest, minDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local hum = plr.Character:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				local pos, onScreen = camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
				if onScreen then
					local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
					local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
					if dist <= 100 and dist < minDist then
						minDist = dist
						closest = plr
					end
				end
			end
		end
	end
	return closest
end

-- ================= Render Loop =================
-- 🔥 ตรงนี้คือ "จุดเดียว" ที่แก้บั๊กบางแมพไม่หัน

RunService.RenderStepped:Connect(function()
	if lockActive then
		if not lockedTarget
		or not lockedTarget.Character
		or not lockedTarget.Character:FindFirstChild("Humanoid")
		or lockedTarget.Character.Humanoid.Health <= 0 then
			lockedTarget = getClosestEnemy()
		end

		if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
			local targetRoot = lockedTarget.Character.HumanoidRootPart
			local myChar = player.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			local humanoid = myChar and myChar:FindFirstChild("Humanoid")

			-- กล้อง (เหมือนเดิม)
			camera.CFrame = CFrame.new(camera.CFrame.Position, targetRoot.Position)

			-- 🔥 บังคับหมุนตัวละคร (แก้เฉพาะแมพที่ไม่หมุน)
			if myRoot and humanoid then
				humanoid.AutoRotate = false
				myRoot.CFrame = CFrame.lookAt(
					myRoot.Position,
					Vector3.new(
						targetRoot.Position.X,
						myRoot.Position.Y,
						targetRoot.Position.Z
					)
				)
			end
		end
	else
		-- คืนค่าเมื่อปิดล็อก
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
		end
	end
end)

-- กัน Kick เบื้องต้น (เหมือนเดิม)
pcall(function()
	hookfunction(player.Kick, function() return end)
end)
