local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Locking = false
local Target = nil

-- รายชื่อผู้ใช้ที่ปลอดภัย
local safeUsers = {
    ["hankung652"] = true,
    [LocalPlayer.Name] = true -- เพิ่มตัวเองอัตโนมัติ
}

-- ฟังก์ชันสร้าง UI
local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LockOnUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 120, 0, 50)
    ToggleButton.Position = UDim2.new(0, 20, 1, -70)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 20
    ToggleButton.Text = "Lock: OFF"
    ToggleButton.Parent = ScreenGui

    ToggleButton.MouseButton1Click:Connect(function()
        Locking = not Locking
        ToggleButton.Text = "Lock: " .. (Locking and "ON" or "OFF")
        if not Locking then Target = nil end
    end)

    -- ระบบลาก UI แบบไม่ไวเกินไป
    local dragging = false
    local dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(
            0, math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - ToggleButton.AbsoluteSize.X),
            0, math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - ToggleButton.AbsoluteSize.Y)
        )
    end

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
            update(input)
        end
    end)
end

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

-- ระบบล็อกกล้อง
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

-- ระบบกันแบน
local function isSafe()
    return safeUsers[LocalPlayer.Name]
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

local function autoHideUI()
    local gui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LockOnUI")
    while true do
        task.wait(2)
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and not safeUsers[plr.Name] then
                gui.Enabled = false
                Locking = false
                Target = nil
                task.wait(3)
                gui.Enabled = true
            end
        end
    end
end

-- สร้าง UI เมื่อเกิดใหม่
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    createUI()
end)

if LocalPlayer.Character then
    createUI()
end

-- เรียกใช้ระบบกันแบน
if isSafe() then
    task.spawn(protectFromRemoteSpy)
    task.spawn(autoHideUI)
end
