-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Config
local Config = {
    AutoFarm = {
        Enabled = false,
        TargetCashRegisters = true,
        TargetSafes = true,
        ShowStats = true,
        AutoRespawn = true,
        SafeMode = true, -- Anti-Bom Mode
        CheckRadius = 100, -- Radius untuk cek player lain
        GodMode = true -- God Mode (Invincible)
    }
}

-- Stats
local AutoFarmStats = {
    StartTime = 0,
    Earnings = 0,
    InitialCash = 0,
    Hours = 0,
    Minutes = 0,
    Seconds = 0
}

local AutoFarmRunning = false
local RespawnConnection = nil
local DeathConnection = nil

-- Format Number Function
local function formatNumber(n)
    local formatted = tostring(n)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Check if area is safe (no players nearby)
local function IsAreaSafe(position, radius)
    if not Config.AutoFarm.SafeMode then return true end
    
    local count = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local distance = (humanoidRootPart.Position - position).Magnitude
                if distance < radius then
                    count = count + 1
                end
            end
        end
    end
    
    return count == 0
end

-- Create UI
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoFarmUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 380, 0, 360)
    MainFrame.Position = UDim2.new(0.5, -190, 0.5, -180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(60, 60, 70)
    UIStroke.Thickness = 2
    UIStroke.Parent = MainFrame

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header

    local HeaderBottom = Instance.new("Frame")
    HeaderBottom.Size = UDim2.new(1, 0, 0, 12)
    HeaderBottom.Position = UDim2.new(0, 0, 1, -12)
    HeaderBottom.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    HeaderBottom.BorderSizePixel = 0
    HeaderBottom.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🚀 Auto Farm Pro"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 20
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Header

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 35, 0, 35)
    CloseButton.Position = UDim2.new(1, -45, 0, 7.5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    CloseButton.Text = "✕"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 18
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.BorderSizePixel = 0
    CloseButton.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton

    -- Content
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -30, 1, -80)
    Content.Position = UDim2.new(0, 15, 0, 65)
    Content.BackgroundTransparency = 1
    Content.Parent = MainFrame

    -- Settings Frame
    local SettingsFrame = Instance.new("Frame")
    SettingsFrame.Name = "SettingsFrame"
    SettingsFrame.Size = UDim2.new(1, 0, 0, 95)
    SettingsFrame.Position = UDim2.new(0, 0, 0, 0)
    SettingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    SettingsFrame.BorderSizePixel = 0
    SettingsFrame.Parent = Content

    local SettingsCorner = Instance.new("UICorner")
    SettingsCorner.CornerRadius = UDim.new(0, 10)
    SettingsCorner.Parent = SettingsFrame

    local SettingsTitle = Instance.new("TextLabel")
    SettingsTitle.Size = UDim2.new(1, -20, 0, 25)
    SettingsTitle.Position = UDim2.new(0, 10, 0, 5)
    SettingsTitle.BackgroundTransparency = 1
    SettingsTitle.Text = "⚙️ Settings"
    SettingsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    SettingsTitle.TextSize = 14
    SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    SettingsTitle.Font = Enum.Font.GothamSemibold
    SettingsTitle.Parent = SettingsFrame

    -- Auto Respawn Toggle
    local RespawnFrame = Instance.new("Frame")
    RespawnFrame.Name = "RespawnFrame"
    RespawnFrame.Size = UDim2.new(1, -20, 0, 30)
    RespawnFrame.Position = UDim2.new(0, 10, 0, 35)
    RespawnFrame.BackgroundTransparency = 1
    RespawnFrame.Parent = SettingsFrame

    local RespawnLabel = Instance.new("TextLabel")
    RespawnLabel.Size = UDim2.new(0.65, 0, 1, 0)
    RespawnLabel.BackgroundTransparency = 1
    RespawnLabel.Text = "🔄 Auto Respawn"
    RespawnLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    RespawnLabel.TextSize = 13
    RespawnLabel.TextXAlignment = Enum.TextXAlignment.Left
    RespawnLabel.Font = Enum.Font.GothamSemibold
    RespawnLabel.Parent = RespawnFrame

    local RespawnToggle = Instance.new("TextButton")
    RespawnToggle.Name = "RespawnToggle"
    RespawnToggle.Size = UDim2.new(0, 60, 0, 28)
    RespawnToggle.Position = UDim2.new(1, -60, 0, 1)
    RespawnToggle.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
    RespawnToggle.Text = "ON"
    RespawnToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    RespawnToggle.TextSize = 12
    RespawnToggle.Font = Enum.Font.GothamBold
    RespawnToggle.BorderSizePixel = 0
    RespawnToggle.Parent = RespawnFrame

    local RespawnToggleCorner = Instance.new("UICorner")
    RespawnToggleCorner.CornerRadius = UDim.new(0, 7)
    RespawnToggleCorner.Parent = RespawnToggle

    -- Safe Mode Toggle (Anti-Bom)
    local SafeModeFrame = Instance.new("Frame")
    SafeModeFrame.Name = "SafeModeFrame"
    SafeModeFrame.Size = UDim2.new(1, -20, 0, 30)
    SafeModeFrame.Position = UDim2.new(0, 10, 0, 60)
    SafeModeFrame.BackgroundTransparency = 1
    SafeModeFrame.Parent = SettingsFrame

    local SafeModeLabel = Instance.new("TextLabel")
    SafeModeLabel.Size = UDim2.new(0.65, 0, 1, 0)
    SafeModeLabel.BackgroundTransparency = 1
    SafeModeLabel.Text = "🛡️ Safe Mode (Anti-Bom)"
    SafeModeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    SafeModeLabel.TextSize = 13
    SafeModeLabel.TextXAlignment = Enum.TextXAlignment.Left
    SafeModeLabel.Font = Enum.Font.GothamSemibold
    SafeModeLabel.Parent = SafeModeFrame

    local SafeModeToggle = Instance.new("TextButton")
    SafeModeToggle.Name = "SafeModeToggle"
    SafeModeToggle.Size = UDim2.new(0, 60, 0, 28)
    SafeModeToggle.Position = UDim2.new(1, -60, 0, 1)
    SafeModeToggle.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
    SafeModeToggle.Text = "ON"
    SafeModeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    SafeModeToggle.TextSize = 12
    SafeModeToggle.Font = Enum.Font.GothamBold
    SafeModeToggle.BorderSizePixel = 0
    SafeModeToggle.Parent = SafeModeFrame

    local SafeModeToggleCorner = Instance.new("UICorner")
    SafeModeToggleCorner.CornerRadius = UDim.new(0, 7)
    SafeModeToggleCorner.Parent = SafeModeToggle

    -- Toggle Button
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(1, 0, 0, 50)
    ToggleButton.Position = UDim2.new(0, 0, 0, 110)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    ToggleButton.Text = "▶ Start Auto Farm"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 16
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Parent = Content

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 10)
    ToggleCorner.Parent = ToggleButton

    -- Stats Frame
    local StatsFrame = Instance.new("Frame")
    StatsFrame.Name = "StatsFrame"
    StatsFrame.Size = UDim2.new(1, 0, 0, 100)
    StatsFrame.Position = UDim2.new(0, 0, 0, 175)
    StatsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    StatsFrame.BorderSizePixel = 0
    StatsFrame.Parent = Content

    local StatsCorner = Instance.new("UICorner")
    StatsCorner.CornerRadius = UDim.new(0, 10)
    StatsCorner.Parent = StatsFrame

    -- Timer Label
    local TimerLabel = Instance.new("TextLabel")
    TimerLabel.Name = "TimerLabel"
    TimerLabel.Size = UDim2.new(1, -20, 0, 30)
    TimerLabel.Position = UDim2.new(0, 10, 0, 10)
    TimerLabel.BackgroundTransparency = 1
    TimerLabel.Text = "⏱️ Time: 00:00:00"
    TimerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    TimerLabel.TextSize = 14
    TimerLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimerLabel.Font = Enum.Font.GothamSemibold
    TimerLabel.Parent = StatsFrame

    -- Cash Label
    local CashLabel = Instance.new("TextLabel")
    CashLabel.Name = "CashLabel"
    CashLabel.Size = UDim2.new(1, -20, 0, 30)
    CashLabel.Position = UDim2.new(0, 10, 0, 40)
    CashLabel.BackgroundTransparency = 1
    CashLabel.Text = "💰 Earnings: $0"
    CashLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
    CashLabel.TextSize = 14
    CashLabel.TextXAlignment = Enum.TextXAlignment.Left
    CashLabel.Font = Enum.Font.GothamSemibold
    CashLabel.Parent = StatsFrame

    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -20, 0, 25)
    StatusLabel.Position = UDim2.new(0, 10, 0, 70)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "🔴 Status: Inactive"
    StatusLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
    StatusLabel.TextSize = 13
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = StatsFrame

    -- Make UI Draggable
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- Respawn Toggle Click
    RespawnToggle.MouseButton1Click:Connect(function()
        Config.AutoFarm.AutoRespawn = not Config.AutoFarm.AutoRespawn
        if Config.AutoFarm.AutoRespawn then
            RespawnToggle.Text = "ON"
            RespawnToggle.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
        else
            RespawnToggle.Text = "OFF"
            RespawnToggle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        end
    end)

    -- Safe Mode Toggle Click
    SafeModeToggle.MouseButton1Click:Connect(function()
        Config.AutoFarm.SafeMode = not Config.AutoFarm.SafeMode
        if Config.AutoFarm.SafeMode then
            SafeModeToggle.Text = "ON"
            SafeModeToggle.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
        else
            SafeModeToggle.Text = "OFF"
            SafeModeToggle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        end
    end)

    -- Close Button Function
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        if AutoFarmRunning then
            StopAutoFarm()
        end
    end)

    return ScreenGui, ToggleButton, TimerLabel, CashLabel, StatusLabel
end

-- Setup Auto Respawn
local function SetupAutoRespawn()
    if RespawnConnection then
        RespawnConnection:Disconnect()
    end
    if DeathConnection then
        DeathConnection:Disconnect()
    end

    -- Handle Death
    local function OnCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        if DeathConnection then
            DeathConnection:Disconnect()
        end
        
        DeathConnection = humanoid.Died:Connect(function()
            if Config.AutoFarm.AutoRespawn and Config.AutoFarm.Enabled then
                print("💀 Died! Waiting for respawn...")
                AutoFarmRunning = false
            end
        end)
        
        -- Restart farming after respawn
        if Config.AutoFarm.Enabled and not AutoFarmRunning then
            task.wait(3) -- Wait longer for full load
            print("🔄 Respawning and restarting farm...")
            SetupAutoFarm()
        end
    end

    RespawnConnection = localPlayer.CharacterAdded:Connect(OnCharacterAdded)
    
    -- Setup for current character
    if localPlayer.Character then
        OnCharacterAdded(localPlayer.Character)
    end
end

-- Setup Auto Farm Function
local function SetupAutoFarm()
    local Workspace = game:GetService("Workspace")
    local VirtualUser = game:GetService("VirtualUser")
    
    local isStreamingEnabled = Workspace.StreamingEnabled
    print("StreamingEnabled =", isStreamingEnabled)
    
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    -- Wait for character to be fully loaded
    if not humanoid or not humanoidRootPart or humanoid.Health <= 0 then
        warn("⚠️ Character not ready, waiting...")
        return
    end
    
    local bag = localPlayer:WaitForChild("States"):WaitForChild("Bag")
    local bagSizeLevel = localPlayer:WaitForChild("Stats"):WaitForChild("BagSizeLevel"):WaitForChild("CurrentAmount")
    local robEvent = ReplicatedStorage:WaitForChild("GeneralEvents"):WaitForChild("Rob")
    local targetPosition = CFrame.new(1636.62537, 104.349976, -1736.184)
    
    if humanoid then
        local clonedHumanoid = humanoid:Clone()
        clonedHumanoid.Parent = character
        localPlayer.Character = nil
        clonedHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        clonedHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        clonedHumanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        humanoid:Destroy()
        localPlayer.Character = character
        local camera = Workspace.CurrentCamera
        camera.CameraSubject = clonedHumanoid
        camera.CFrame = camera.CFrame
        clonedHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        local animate = character:FindFirstChild("Animate")
        if animate then
            animate.Disabled = true
            task.wait()
            animate.Disabled = false
        end
        clonedHumanoid.Health = clonedHumanoid.MaxHealth
        humanoid = clonedHumanoid
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    end
    
    localPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    
    local function teleportToModel(model, targetPart)
        if not humanoidRootPart or not model then return false end
        
        local targetCFrame = targetPart and targetPart:IsA("BasePart") and targetPart.CFrame or model:GetPivot()
        
        -- Check if area is safe before teleporting
        if not IsAreaSafe(targetCFrame.Position, Config.AutoFarm.CheckRadius) then
            print("⚠️ Area not safe, skipping...")
            return false
        end
        
        if isStreamingEnabled then
            pcall(function()
                localPlayer:RequestStreamAroundAsync(targetCFrame.Position)
            end)
        end
        
        humanoidRootPart.CFrame = targetCFrame
        return true
    end
    
    local function moveToTarget()
        if humanoidRootPart then
            if isStreamingEnabled then
                pcall(function()
                    localPlayer:RequestStreamAroundAsync(targetPosition.Position)
                end)
            end
            humanoidRootPart.CFrame = targetPosition
        end
    end
    
    local function checkCashRegister()
        if not Config.AutoFarm.TargetCashRegisters then return false end
        
        for _, item in ipairs(Workspace:GetChildren()) do
            if bag.Value >= bagSizeLevel.Value then
                moveToTarget()
                break
            elseif item:IsA("Model") and item.Name == "CashRegister" then
                local openPart = item:FindFirstChild("Open")
                if openPart then
                    if teleportToModel(item, openPart) then
                        robEvent:FireServer("Register", {
                            Part = item:FindFirstChild("Union"),
                            OpenPart = openPart,
                            ActiveValue = item:FindFirstChild("Active"),
                            Active = true
                        })
                        return true
                    end
                end
            end
        end
        return false
    end
    
    local function checkSafe()
        if not Config.AutoFarm.TargetSafes then return false end
        
        for _, item in ipairs(Workspace:GetChildren()) do
            if bag.Value >= bagSizeLevel.Value then
                moveToTarget()
                break
            elseif item:IsA("Model") and item.Name == "Safe" and item:FindFirstChild("Amount") and item.Amount.Value > 0 then
                local safePart = item:FindFirstChild("Safe")
                if safePart then
                    if teleportToModel(item, safePart) then
                        local openFlag = item:FindFirstChild("Open")
                        if openFlag and openFlag.Value then
                            robEvent:FireServer("Safe", item)
                        else
                            local openSafe = item:FindFirstChild("OpenSafe")
                            if openSafe then
                                openSafe:FireServer("Completed")
                            end
                            robEvent:FireServer("Safe", item)
                        end
                        return true
                    end
                end
            end
        end
        return false
    end
    
    AutoFarmRunning = true
    
    -- Reset or continue timer
    if AutoFarmStats.StartTime == 0 then
        AutoFarmStats.StartTime = tick()
        AutoFarmStats.Seconds = 0
        AutoFarmStats.Minutes = 0
        AutoFarmStats.Hours = 0
    end
    
    local leaderstats = localPlayer:WaitForChild("leaderstats")
    local cashStat = leaderstats:WaitForChild("$$")
    
    if AutoFarmStats.InitialCash == 0 then
        AutoFarmStats.InitialCash = cashStat.Value
    end
    
    spawn(function()
        while AutoFarmRunning and Config.AutoFarm.Enabled do
            task.wait(1)
            AutoFarmStats.Seconds = AutoFarmStats.Seconds + 1
            if AutoFarmStats.Seconds >= 60 then
                AutoFarmStats.Seconds = 0
                AutoFarmStats.Minutes = AutoFarmStats.Minutes + 1
            end
            if AutoFarmStats.Minutes >= 60 then
                AutoFarmStats.Minutes = 0
                AutoFarmStats.Hours = AutoFarmStats.Hours + 1
            end
        end
    end)
    
    spawn(function()
        while AutoFarmRunning and Config.AutoFarm.Enabled do
            task.wait(0.5)
            AutoFarmStats.Earnings = cashStat.Value - AutoFarmStats.InitialCash
        end
    end)
    
    spawn(function()
        while AutoFarmRunning and Config.AutoFarm.Enabled do
            RunService.RenderStepped:Wait()
            if humanoid and humanoid.Health > 0 then
                if not checkCashRegister() then
                    checkSafe()
                end
            else
                break
            end
        end
    end)
    
    print("✅ Auto Farm Started!")
end

local function StopAutoFarm()
    AutoFarmRunning = false
    Config.AutoFarm.Enabled = false
    print("⏹️ Auto Farm Stopped!")
end

-- Main
local ScreenGui, ToggleButton, TimerLabel, CashLabel, StatusLabel = CreateUI()

-- Setup Auto Respawn
SetupAutoRespawn()

-- Update UI Loop
spawn(function()
    while wait(0.1) do
        if ScreenGui and ScreenGui.Parent then
            TimerLabel.Text = string.format("⏱️ Time: %02d:%02d:%02d", AutoFarmStats.Hours, AutoFarmStats.Minutes, AutoFarmStats.Seconds)
            CashLabel.Text = "💰 Earnings: $" .. formatNumber(AutoFarmStats.Earnings)
            
            if AutoFarmRunning then
                StatusLabel.Text = "🟢 Status: Active"
                StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
            else
                StatusLabel.Text = "🔴 Status: Inactive"
                StatusLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            end
        end
    end
end)

-- Toggle Button Click
ToggleButton.MouseButton1Click:Connect(function()
    Config.AutoFarm.Enabled = not Config.AutoFarm.Enabled
    
    if Config.AutoFarm.Enabled then
        ToggleButton.Text = "⏸ Stop Auto Farm"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
        SetupAutoFarm()
    else
        ToggleButton.Text = "▶ Start Auto Farm"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        StopAutoFarm()
    end
end)

print("✅ Auto Farm UI Loaded Successfully!")
print("🛡️ Safe Mode:", Config.AutoFarm.SafeMode and "ON" or "OFF")
print("🔄 Auto Respawn:", Config.AutoFarm.AutoRespawn and "ON" or "OFF")
