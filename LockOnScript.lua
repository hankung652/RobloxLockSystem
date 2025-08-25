-- LockOnScript.lua

-- กำหนดค่าพื้นฐาน
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- UI Elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockOnUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- ปุ่ม Toggle
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 150, 0, 50)
toggleButton.Position = UDim2.new(0.02, 0, 0.85, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "Lock-On"
toggleButton.Parent = screenGui

-- วงกลมตรงกลางจอ
local lockCircle = Instance.new("ImageLabel")
lockCircle.Size = UDim2.new(0, 100, 0, 100)
lockCircle.Position = UDim2.new(0.5, -50, 0.5, -50)
lockCircle.BackgroundTransparency = 1
lockCircle.Image = "rbxassetid://3570695787"
lockCircle.ImageColor3 = Color3.fromRGB(255, 255, 255)
lockCircle.ImageTransparency = 0.2
lockCircle.Visible = false
lockCircle.Parent = screenGui

-- ตัวแปรสถานะ
local lockOnEnabled = false
local target = nil

-- ฟังก์ชันหาเป้าหมายที่ใกล้สุด
local function getClosestTarget()
    local closest, distance = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local charPos = v.Character.HumanoidRootPart.Position
            local mag = (charPos - player.Character.HumanoidRootPart.Position).Magnitude
            if mag < distance and mag < 100 then
                closest, distance = v.Character.HumanoidRootPart, mag
            end
        end
    end
    return closest
end

-- ฟังก์ชันเปิด/ปิด Lock-On
local function toggleLock()
    lockOnEnabled = not lockOnEnabled
    lockCircle.Visible = lockOnEnabled
    if not lockOnEnabled then
        target = nil
    end
end

-- Event สำหรับปุ่ม UI
toggleButton.MouseButton1Click:Connect(toggleLock)

-- Event สำหรับปุ่ม L
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.L then
        toggleLock()
    end
end)

-- อัปเดตการล็อกเป้าหมาย
RunService.RenderStepped:Connect(function()
    if lockOnEnabled then
        if not target or (target.Position - player.Character.HumanoidRootPart.Position).Magnitude > 100 then
            target = getClosestTarget()
        end
        if target then
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
        end
    end
end)

-- ป้องกันสคริปต์ซ้อนเมื่อ Respawn
player.CharacterAdded:Connect(function()
    lockOnEnabled = false
    target = nil
    lockCircle.Visible = false
end)
