-- ========================================
-- VELAWARE - SILENT AIM MODULE
-- Murder vs Sheriff Duels
-- ========================================

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local animations = Replicated.Animations
local remotes = Replicated.Remotes
local modules = Replicated.Modules

local shootAnim = animations:WaitForChild("Shoot")
local shootRemote = remotes:WaitForChild("ShootGun")
local bulletRenderer = require(modules:WaitForChild("BulletRenderer"))

-- ========================================
-- CONFIGURATION
-- ========================================
getgenv().silentAimConfig = {
    ENABLED = false,
    FOV_RADIUS = 200,
    SHOW_FOV = true,
    WALL_CHECK = true,
    MAX_DISTANCE = 500,
    TEAM_CHECK = true,
    VISIBLE_CHECK = true,
}

-- ========================================
-- FOV CIRCLE
-- ========================================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 50
fovCircle.Radius = getgenv().silentAimConfig.FOV_RADIUS
fovCircle.Filled = false
fovCircle.Transparency = 0.7
fovCircle.Color = Color3.fromRGB(138, 43, 226)
fovCircle.Visible = false

local function updateFOVCircle()
    if getgenv().silentAimConfig.SHOW_FOV and getgenv().silentAimConfig.ENABLED then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        fovCircle.Radius = getgenv().silentAimConfig.FOV_RADIUS
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================
local function isPlayerAlive(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    
    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    if humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
    
    return true
end

local function isTargetVisible(targetChar, fromPosition)
    if not targetChar or not targetChar.Parent then return false end
    
    local targetPart = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
    if not targetPart then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character, targetChar}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local direction = targetPart.Position - fromPosition
    local rayResult = Workspace:Raycast(fromPosition, direction, raycastParams)
    
    -- If raycast hits something, check if it's a wall/solid object
    if rayResult then
        local hitPart = rayResult.Instance
        
        -- Allow shooting through certain objects (like small props, particles, effects)
        if hitPart.Transparency >= 0.5 then return true end
        if hitPart.CanCollide == false then return true end
        if hitPart:IsA("ParticleEmitter") or hitPart:IsA("Beam") then return true end
        
        -- Block if it's a solid wall/part
        return false
    end
    
    return true
end

local function isInFOV(targetPosition)
    local screenPos, onScreen = camera:WorldToViewportPoint(targetPosition)
    
    if not onScreen then return false end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos2D = Vector2.new(screenPos.X, screenPos.Y)
    
    local distance = (targetPos2D - mousePos).Magnitude
    
    return distance <= getgenv().silentAimConfig.FOV_RADIUS
end

local function isValidTarget(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    if not isPlayerAlive(targetPlayer) then return false end
    
    local char = targetPlayer.Character
    if not char or char.Parent ~= Workspace then return false end
    
    -- Team check
    if getgenv().silentAimConfig.TEAM_CHECK then
        if targetPlayer.Team and player.Team and targetPlayer.Team == player.Team then
            return false
        end
    end
    
    -- Invulnerability check
    if char:GetAttribute("Invulnerable") or char:FindFirstChild("SpeedTrail") then
        return false
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Distance check
    local myChar = player.Character
    if not myChar then return false end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return false end
    
    local distance = (hrp.Position - myHrp.Position).Magnitude
    if distance > getgenv().silentAimConfig.MAX_DISTANCE then return false end
    
    -- FOV check
    if not isInFOV(hrp.Position) then return false end
    
    -- Visibility check (wall check)
    if getgenv().silentAimConfig.WALL_CHECK and getgenv().silentAimConfig.VISIBLE_CHECK then
        if not isTargetVisible(char, myHrp.Position) then return false end
    end
    
    return true
end

-- ========================================
-- TARGETING SYSTEM
-- ========================================
local function getClosestTarget()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if isValidTarget(targetPlayer) then
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local targetPos2D = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (targetPos2D - mousePos).Magnitude
                    
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = targetPlayer
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function getTargetPosition(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return nil end
    
    -- Priority: Head > UpperTorso > HumanoidRootPart
    local char = targetPlayer.Character
    local head = char:FindFirstChild("Head")
    local upperTorso = char:FindFirstChild("UpperTorso")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    -- Check visibility for each part
    local myChar = player.Character
    if not myChar then return nil end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    
    if head and isTargetVisible(char, myHrp.Position) then
        return head.Position
    elseif upperTorso then
        return upperTorso.Position
    elseif hrp then
        return hrp.Position
    end
    
    return nil
end

-- ========================================
-- SILENT AIM FIRING (NO HOOKS)
-- ========================================
local function fireSilentShot()
    if not getgenv().silentAimConfig.ENABLED then return false end
    
    local myChar = player.Character
    if not myChar then return false end
    
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return false end
    
    -- Check if we have a gun equipped
    local gun = nil
    for _, tool in pairs(myChar:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("EquipAnimation") == "Gun_Equip" then
            gun = tool
            break
        end
    end
    
    if not gun then return false end
    
    -- Respect cooldown if no-cooldown is disabled
    if not getgenv().cooldownEnabled then
        local cooldown = gun:GetAttribute("Cooldown") or 2.5
        local lastFireTime = gun:GetAttribute("_LastFireTime") or 0
        
        if tick() - lastFireTime < cooldown then
            return false
        end
        
        gun:SetAttribute("_LastFireTime", tick())
    end
    
    local muzzle = gun:FindFirstChild("Muzzle", true)
    if not muzzle then return false end
    
    -- Find target
    local target = getClosestTarget()
    if not target then return false end
    
    local targetPos = getTargetPosition(target)
    if not targetPos then return false end
    
    -- Get animator
    local animator = myChar:FindFirstChild("Humanoid")
    if animator then
        animator = animator:FindFirstChild("Animator")
    end
    
    if not animator then return false end
    
    -- Fire gun
    local animTrack = animator:LoadAnimation(shootAnim)
    animTrack:Play()
    
    local sound = gun:FindFirstChild("Fire")
    if sound then sound:Play() end
    
    bulletRenderer(muzzle.WorldPosition, targetPos, "Default")
    
    local targetPart = target.Character:FindFirstChild("Head") 
        or target.Character:FindFirstChild("UpperTorso")
        or target.Character:FindFirstChild("HumanoidRootPart")
    
    shootRemote:FireServer(muzzle.WorldPosition, targetPos, targetPart, targetPos)
    
    return true
end

-- ========================================
-- MOUSE CLICK DETECTION
-- ========================================
local lastShot = 0
local shootCooldown = 0.1

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not getgenv().silentAimConfig.ENABLED then return end
        
        local currentTime = tick()
        if currentTime - lastShot < shootCooldown then return end
        
        if fireSilentShot() then
            lastShot = currentTime
        end
    end
end)

-- ========================================
-- FOV CIRCLE UPDATE LOOP
-- ========================================
RunService.RenderStepped:Connect(function()
    updateFOVCircle()
end)

-- ========================================
-- CLEANUP
-- ========================================
local Connections = {}

Connections[1] = RunService.RenderStepped:Connect(updateFOVCircle)

return Connections
