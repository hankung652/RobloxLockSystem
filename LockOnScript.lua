-- Parent this LocalScript under StarterPlayerScripts
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockOnGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 150, 0, 50)
toggleButton.Position = UDim2.new(0.05, 0, 0.85, 0)
toggleButton.Text = "Lock-On: OFF"
toggleButton.TextScaled = true
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Parent = screenGui

-- Lock-On Circle
local circle = Instance.new("Frame")
circle.Size = UDim2.new(0, 120, 0, 120)
circle.Position = UDim2.new(0.5, -60, 0.5, -60)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Visible = false
circle.Parent = screenGui

local circleUI = Instance.new("UICorner")
circleUI.CornerRadius = UDim.new(1, 0)
circleUI.Parent = circle

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Parent = circle

-- Variables
local lockOnEnabled = false
local target = nil
local lockRange = 100
local maxCircleSize = 360

-- Function to find closest enemy
local function getClosestEnemy()
    local closest = nil
    local shortestDistance = lockRange
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= character and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 then
                local pos = v.HumanoidRootPart.Position
                local screenPos, onScreen = camera:WorldToViewportPoint(pos)
                if onScreen then
                    local distance = (camera.CFrame.Position - pos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closest = v
                    end
                end
            end
        end
    end
    return closest
end

-- Update Lock-On
RunService.RenderStepped:Connect(function()
    if lockOnEnabled and target then
        if target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.HumanoidRootPart.Position)
            circle.Visible = true
            -- Dynamic circle size based on distance
            local distance = (camera.CFrame.Position - target.HumanoidRootPart.Position).Magnitude
            local size = math.clamp(360 - (distance * 2), 80, maxCircleSize)
            circle.Size = UDim2.new(0, size, 0, size)
        else
            -- Target dead or gone
            target = nil
            lockOnEnabled = false
            toggleButton.Text = "Lock-On: OFF"
            circle.Visible = false
        end
    else
        circle.Visible = false
    end
end)

-- Toggle Lock-On
local function toggleLockOn()
    if not lockOnEnabled then
        target = getClosestEnemy()
        if target then
            lockOnEnabled = true
            toggleButton.Text = "Lock-On: ON"
        else
            toggleButton.Text = "No Target"
            wait(1)
            toggleButton.Text = "Lock-On: OFF"
        end
    else
        lockOnEnabled = false
        target = nil
        toggleButton.Text = "Lock-On: OFF"
    end
end

toggleButton.MouseButton1Click:Connect(toggleLockOn)

-- Keybind for PC
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Q then
        toggleLockOn()
    end
end)

-- Handle Respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    lockOnEnabled = false
    target = nil
    toggleButton.Text = "Lock-On: OFF"
end)
