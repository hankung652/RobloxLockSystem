-- LocalScript (StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--=========================
-- GUI
--=========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockOnSystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- วงกลม Lock-On (กลางจอ, ซ่อนตอนแรก)
local circle = Instance.new("Frame")
circle.Size = UDim2.new(0, 200, 0, 200)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Visible = false
circle.Name = "LockCircle"
circle.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = circle

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 0, 0)
stroke.Thickness = 3
stroke.Parent = circle

-- ปุ่ม Toggle Lock-On (ลากได้)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 100, 0, 50)
toggleBtn.Position = UDim2.new(0.5, -50, 0.8, 0)
toggleBtn.Text = "Lock: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 24
toggleBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0.3, 0)
btnCorner.Parent = toggleBtn

-- ระบบลากปุ่ม
local dragging = false
local dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position
    end
end)

toggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        if dragging then
            update(input)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

--=========================
-- Lock-On System
--=========================
local lockedTarget = nil
local lockActive = false

toggleBtn.MouseButton1Click:Connect(function()
    lockActive = not lockActive
    toggleBtn.Text = lockActive and "Lock: ON" or "Lock: OFF"
    circle.Visible = lockActive
    if not lockActive then
        lockedTarget = nil
        -- เปิด AutoRotate คืน
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.AutoRotate = true
        end
    end
end)

-- ฟังก์ชันหาศัตรูใกล้สุด (ในวงกลม)
local function getClosestEnemy()
    local closestEnemy, minDist = nil, math.huge
    for _, enemy in ipairs(Players:GetPlayers()) do
        if enemy ~= player and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            local root = enemy.Character.HumanoidRootPart
            local pos, onScreen = camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local screenPos = Vector2.new(pos.X, pos.Y)
                local centerPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                local distance = (screenPos - centerPos).Magnitude
                if distance <= 100 and distance < minDist then
                    closestEnemy = enemy
                    minDist = distance
                end
            end
        end
    end
    return closestEnemy
end

-- อัพเดตทุกเฟรม
RunService.RenderStepped:Connect(function()
    if lockActive then
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        local root = player.Character.HumanoidRootPart

        if not lockedTarget or not lockedTarget.Character or not lockedTarget.Character:FindFirstChild("Humanoid") or lockedTarget.Character.Humanoid.Health <= 0 then
            lockedTarget = getClosestEnemy()
        end

        if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = lockedTarget.Character.HumanoidRootPart

            -- กล้องหันตามศัตรู
            camera.CFrame = CFrame.new(camera.CFrame.Position, targetRoot.Position)

            -- ตัวละครหันไปทางศัตรู
            if humanoid then
                humanoid.AutoRotate = false
                local lookAt = Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z)
                root.CFrame = CFrame.new(root.Position, lookAt)
            end
        end
    end
end)

--=========================
-- Anti-Ban (กัน Kick เบื้องต้น)
--=========================
hookfunction(game:GetService("Players").LocalPlayer.Kick, function() return end)
