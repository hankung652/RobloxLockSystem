--[[
🔒 Roblox Lock-On System with Circle UI (Mobile + PC)
Features:
✅ Lock enemy with Q key or mobile button
✅ Circle UI in center (hollow inside)
✅ Lock persists even if enemy leaves circle, until death or removal
✅ Drag UI for reposition (mobile)
✅ Auto unlock when target dies or removed
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- SETTINGS
local LOCK_KEY = Enum.KeyCode.Q
local LOCK_DISTANCE = 150
local LOCK_SPEED = 0.15

-- UI Creation
local gui = Instance.new("ScreenGui")
gui.Name = "LockOnUI"
gui.Parent = player:WaitForChild("PlayerGui")

-- Circle UI
local circleFrame = Instance.new("Frame")
circleFrame.Size = UDim2.new(0, 200, 0, 200)
circleFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
circleFrame.BackgroundTransparency = 1
circleFrame.BorderSizePixel = 0
circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
circleFrame.Parent = gui

local circle = Instance.new("ImageLabel")
circle.Size = UDim2.new(1, 0, 1, 0)
circle.BackgroundTransparency = 1
circle.Image = "rbxassetid://3926309567" -- Circle asset ID
circle.ImageRectOffset = Vector2.new(4, 4)
circle.ImageRectSize = Vector2.new(36, 36)
circle.ImageColor3 = Color3.fromRGB(255, 255, 255)
circle.ScaleType = Enum.ScaleType.Fit
circle.Parent = circleFrame

-- Hollow effect: We'll use ImageLabel that already has transparency inside

-- Lock Button (Mobile)
local lockButton = Instance.new("TextButton")
lockButton.Size = UDim2.new(0, 100, 0, 50)
lockButton.Position = UDim2.new(0, 20, 0.8, 0)
lockButton.Text = "Lock"
lockButton.TextScaled = true
lockButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
lockButton.Parent = gui

-- Drag UI (for circle)
local dragging = false
local dragStart
local startPos

circleFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = circleFrame.Position
    end
end)

circleFrame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        circleFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Lock System
local lockedTarget = nil

local function getNearestTarget()
    local nearest = nil
    local shortestDistance = LOCK_DISTANCE
    for _, enemy in pairs(Players:GetPlayers()) do
        if enemy ~= player and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") and enemy.Team ~= player.Team then
            local root = enemy.Character.HumanoidRootPart
            local distance = (root.Position - camera.CFrame.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearest = enemy
            end
        end
    end
    return nearest
end

local function lockTarget(target)
    lockedTarget = target
end

local function unlockTarget()
    lockedTarget = nil
end

-- Key press
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == LOCK_KEY then
        if lockedTarget then
            unlockTarget()
        else
            local newTarget = getNearestTarget()
            if newTarget then
                lockTarget(newTarget)
            end
        end
    end
end)

-- Mobile button
lockButton.MouseButton1Click:Connect(function()
    if lockedTarget then
        unlockTarget()
    else
        local newTarget = getNearestTarget()
        if newTarget then
            lockTarget(newTarget)
        end
    end
end)

-- Camera follow & auto unlock
RunService.RenderStepped:Connect(function()
    if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
        local root = lockedTarget.Character.HumanoidRootPart
        local humanoid = lockedTarget.Character:FindFirstChild("Humanoid")
        
        -- Unlock if dead
        if humanoid and humanoid.Health <= 0 then
            unlockTarget()
            return
        end
        
        -- Smooth camera
        local targetCFrame = CFrame.new(camera.CFrame.Position, root.Position)
        camera.CFrame = camera.CFrame:Lerp(targetCFrame, LOCK_SPEED)
    else
        if lockedTarget then
            unlockTarget()
        end
    end
end)
