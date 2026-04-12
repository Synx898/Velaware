-- ========================================
-- VELAWARE MAINTENANCE NOTICE (BLOCKING)
-- ========================================
-- This GUI displays the custom maintenance message from the admin panel

local maintenanceMessage = ... or "Velaware is currently under maintenance. Please check back soon."

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VelawareMaintenanceNotice"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 320)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = mainFrame

-- Stroke border
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 2
stroke.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 16)
topCorner.Parent = topBar

local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 16)
topBarFix.Position = UDim2.new(0, 0, 1, -16)
topBarFix.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
topBarFix.BorderSizePixel = 0
topBarFix.Parent = topBar

local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(0, 40, 0, 40)
icon.Position = UDim2.new(0, 10, 0, 5)
icon.BackgroundTransparency = 1
icon.Font = Enum.Font.GothamBold
icon.Text = "⚠️"
icon.TextColor3 = Color3.fromRGB(255, 200, 0)
icon.TextSize = 28
icon.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.new(0, 55, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "UNDER MAINTENANCE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 35, 0, 35)
minimizeButton.Position = UDim2.new(1, -80, 0, 7.5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minimizeButton.BorderSizePixel = 0
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Text = "−"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 22
minimizeButton.Parent = topBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 8)
minimizeCorner.Parent = minimizeButton

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -40, 0, 7.5)
closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 26
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -40, 1, -90)
contentFrame.Position = UDim2.new(0, 20, 0, 60)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "🔴 STATUS: OFFLINE"
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.TextSize = 16
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = contentFrame

local message = Instance.new("TextLabel")
message.Size = UDim2.new(1, 0, 0, 150)
message.Position = UDim2.new(0, 0, 0, 35)
message.BackgroundTransparency = 1
message.Font = Enum.Font.Gotham
message.Text = maintenanceMessage
message.TextColor3 = Color3.fromRGB(220, 220, 220)
message.TextSize = 15
message.TextWrapped = true
message.TextYAlignment = Enum.TextYAlignment.Top
message.TextXAlignment = Enum.TextXAlignment.Left
message.Parent = contentFrame

local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, 0, 0, 45)
buttonContainer.Position = UDim2.new(0, 0, 1, -50)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = contentFrame

local discordButton = Instance.new("TextButton")
discordButton.Size = UDim2.new(1, 0, 1, 0)
discordButton.Position = UDim2.new(0, 0, 0, 0)
discordButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
discordButton.BorderSizePixel = 0
discordButton.Font = Enum.Font.GothamBold
discordButton.Text = "Join Discord for Updates"
discordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
discordButton.TextSize = 16
discordButton.AutoButtonColor = false
discordButton.Parent = buttonContainer

local discordCorner = Instance.new("UICorner")
discordCorner.CornerRadius = UDim.new(0, 10)
discordCorner.Parent = discordButton

local discordStroke = Instance.new("UIStroke")
discordStroke.Color = Color3.fromRGB(80, 80, 80)
discordStroke.Thickness = 1.5
discordStroke.Parent = discordButton

-- Hover effects
discordButton.MouseEnter:Connect(function() 
    discordButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
end)
discordButton.MouseLeave:Connect(function() 
    discordButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end)

minimizeButton.MouseEnter:Connect(function() minimizeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70) end)
minimizeButton.MouseLeave:Connect(function() minimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50) end)
closeButton.MouseEnter:Connect(function() closeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70) end)
closeButton.MouseLeave:Connect(function() closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50) end)

-- Discord button
discordButton.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/zNuUd4SdYY")
    discordButton.Text = "✓ Discord Link Copied!"
    discordButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    task.wait(2)
    discordButton.Text = "Join Discord for Updates"
    discordButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end)

-- Close button
closeButton.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- Minimize
local isMinimized = false
minimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        contentFrame.Visible = false
        mainFrame:TweenSize(UDim2.new(0, 450, 0, 50), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
        minimizeButton.Text = "+"
    else
        mainFrame:TweenSize(UDim2.new(0, 450, 0, 320), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true, function()
            contentFrame.Visible = true
        end)
        minimizeButton.Text = "−"
    end
end)

-- Make draggable
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

topBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- Parent GUI
local success = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not success then screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("VELAWARE - UNDER MAINTENANCE")
print(maintenanceMessage)
print("Join Discord for updates: discord.gg/zNuUd4SdYY")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- BLOCK SCRIPT EXECUTION - DO NOT CONTINUE
while true do task.wait() end
