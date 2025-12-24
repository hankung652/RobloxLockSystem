-- LocalScript | StarterPlayerScripts

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Player / Camera
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-------------------------------------------------
-- GUI
-------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockOnSystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- วงกลมกลางจอ
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

-- ปุ่ม Lock
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 120, 0, 50)
toggleBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
toggleBtn.Text = "Lock: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 22
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0.3,0)
btnCorner.Parent = toggleBtn

-------------------------------------------------
-- Drag ปุ่ม (มือถือ)
-------------------------------------------------
do
	local dragging = false
	local dragStart, startPos

	toggleBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = toggleBtn.Position
		end
	end)

	toggleBtn.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			toggleBtn.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-------------------------------------------------
-- Lock-On Logic
-------------------------------------------------
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

-- หาเป้าใกล้กลางจอ
local function getClosestEnemy()
	local closest, minDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local root = plr.Character.HumanoidRootPart
			local pos, onScreen = camera:WorldToViewportPoint(root.Position)
			if onScreen then
				local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
				local dist = (Vector2.new(pos.X,pos.Y) - center).Magnitude
				if dist <= 100 and dist < minDist then
					minDist = dist
					closest = plr
				end
			end
		end
	end
	return closest
end

-------------------------------------------------
-- กล้อง Lock-On
-------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not lockActive then return end

	if not lockedTarget
	or not lockedTarget.Character
	or not lockedTarget.Character:FindFirstChild("Humanoid")
	or lockedTarget.Character.Humanoid.Health <= 0 then
		lockedTarget = getClosestEnemy()
	end

	if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
		camera.CFrame = CFrame.new(
			camera.CFrame.Position,
			lockedTarget.Character.HumanoidRootPart.Position
		)
	end
end)

-------------------------------------------------
-- 🔥 จุดแก้สำคัญ: บังคับตัวละครหัน (กันแมพบล็อก)
-------------------------------------------------
RunService:BindToRenderStep(
	"LOCKON_FORCE_ROTATE",
	Enum.RenderPriority.Character.Value + 2,
	function()
		if not lockActive or not lockedTarget then return end

		local char = player.Character
		local targetChar = lockedTarget.Character
		if not char or not targetChar then return end

		local myRoot = char:FindFirstChild("HumanoidRootPart")
		local myHum = char:FindFirstChildOfClass("Humanoid")
		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")

		if not myRoot or not myHum or not targetRoot then return end
		if myHum.Health <= 0 then return end

		-- บังคับไม่ให้แมพหมุนเอง
		myHum.AutoRotate = false

		-- หมุนตัวละครให้หันหาเป้าเสมอ
		local lookPos = Vector3.new(
			targetRoot.Position.X,
			myRoot.Position.Y,
			targetRoot.Position.Z
		)

		myRoot.CFrame = CFrame.lookAt(myRoot.Position, lookPos)
	end
)

-------------------------------------------------
-- กัน Kick เบื้องต้น (เหมือนเดิม)
-------------------------------------------------
pcall(function()
	hookfunction(player.Kick, function() end)
end)
