-- ========================================
-- VELAWARE - ADVANCED HOOKLESS SILENT AIM
-- Murder vs Sheriff Duels
-- Works WITH game's original controllers - no conflicts
-- ========================================

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

local remotes = Replicated.Remotes
local modules = Replicated.Modules
local animations = Replicated.Animations

local shootRemote = remotes:WaitForChild("ShootGun")
local shootAnim = animations:WaitForChild("Shoot")
local bulletRenderer = require(modules:WaitForChild("BulletRenderer"))

-- ========================================
-- CONFIGURATION
-- ========================================
getgenv().silentAimConfig = getgenv().silentAimConfig or {
    ENABLED = false,
    FOV_RADIUS = 200,
    SHOW_FOV = true,
    WALL_CHECK = true,
    MAX_DISTANCE = 500,
    TEAM_CHECK = true,
    VISIBLE_CHECK = true,
    PREDICT_MOVEMENT = true,
    PREDICTION_MULTIPLIER = 0.15,
}

-- ========================================
-- FOV CIRCLE (FOLLOWS MOUSE)
-- ========================================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 64
fovCircle.Radius = getgenv().silentAimConfig.FOV_RADIUS
fovCircle.Filled = false
fovCircle.Transparency = 0.8
fovCircle.Color = Color3.fromRGB(138, 43, 226)
fovCircle.Visible = false

local function updateFOVCircle()
    if getgenv().silentAimConfig.SHOW_FOV and getgenv().silentAimConfig.ENABLED then
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
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
    if not getgenv().silentAimConfig.WALL_CHECK then return true end
    if not targetChar or not targetChar.Parent then return false end
    
    local targetPart = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetPart then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character, targetChar}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local direction = targetPart.Position - fromPosition
    local rayResult = Workspace:Raycast(fromPosition, direction, raycastParams)
    
    -- Allow if no obstruction or hit the target itself
    if not rayResult then return true end
    if rayResult.Instance:IsDescendantOf(targetChar) then return true end
    
    return false
end

local function isInFOV(targetPosition)
    local screenPos, onScreen = camera:WorldToViewportPoint(targetPosition)
    
    if not onScreen then return false end
    
    local mousePos = Vector2.new(mouse.X, mouse.Y)
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
    
    -- Visibility check
    if getgenv().silentAimConfig.VISIBLE_CHECK then
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
    
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    
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

local function predictTargetPosition(targetPlayer)
    if not getgenv().silentAimConfig.PREDICT_MOVEMENT then return nil end
    if not targetPlayer or not targetPlayer.Character then return nil end
    
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local velocity = hrp.AssemblyLinearVelocity
    if velocity.Magnitude < 1 then return nil end
    
    local myChar = player.Character
    if not myChar then return nil end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    
    local distance = (hrp.Position - myHrp.Position).Magnitude
    local bulletSpeed = 500
    local travelTime = distance / bulletSpeed
    
    return velocity * travelTime * getgenv().silentAimConfig.PREDICTION_MULTIPLIER
end

local function getTargetPosition(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return nil, nil end
    
    local char = targetPlayer.Character
    local head = char:FindFirstChild("Head")
    local upperTorso = char:FindFirstChild("UpperTorso")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    local targetPart = head or upperTorso or hrp
    if not targetPart then return nil, nil end
    
    local basePosition = targetPart.Position
    
    -- Apply prediction
    local prediction = predictTargetPosition(targetPlayer)
    if prediction then
        basePosition = basePosition + prediction
    end
    
    return basePosition, targetPart
end

-- ========================================
-- INTERCEPT SHOOTING (NO HOOKS)
-- ========================================
local isShooting = false
local lastShotTime = 0
local MIN_SHOT_INTERVAL = 0.1

-- Store original remote to prevent interference
local originalFireServer = shootRemote.FireServer

-- Intercept function that gets called INSTEAD of game's shoot
local function interceptShot(origin, direction, hitPart, hitPosition)
    if not getgenv().silentAimConfig.ENABLED then
        -- Silent aim disabled, use normal shot
        return originalFireServer(shootRemote, origin, direction, hitPart, hitPosition)
    end
    
    -- Check cooldown
    local currentTime = tick()
    if currentTime - lastShotTime < MIN_SHOT_INTERVAL then
        return
    end
    lastShotTime = currentTime
    
    -- Find target
    local target = getClosestTarget()
    
    if target then
        local targetPos, targetPart = getTargetPosition(target)
        
        if targetPos and targetPart then
            -- Redirect to target
            local myChar = player.Character
            if myChar then
                local muzzle = nil
                for _, tool in pairs(myChar:GetChildren()) do
                    if tool:IsA("Tool") then
                        muzzle = tool:FindFirstChild("Muzzle", true)
                        if muzzle then break end
                    end
                end
                
                if muzzle then
                    -- Visual bullet trail
                    bulletRenderer(muzzle.WorldPosition, targetPos, "Default")
                    
                    -- Fire with silent aim
                    return originalFireServer(shootRemote, muzzle.WorldPosition, targetPos, targetPart, targetPos)
                end
            end
        end
    end
    
    -- No target found, shoot normally
    return originalFireServer(shootRemote, origin, direction, hitPart, hitPosition)
end

-- Replace the FireServer method
shootRemote.FireServer = interceptShot

-- ========================================
-- ALTERNATIVE: LISTEN FOR GAME'S SHOTS
-- ========================================
-- Backup method: monitor when game tries to shoot
local oldRemoteCall
oldRemoteCall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if getnamecallmethod() == "FireServer" and self == shootRemote then
        local args = {...}
        
        if getgenv().silentAimConfig.ENABLED then
            local target = getClosestTarget()
            
            if target then
                local targetPos, targetPart = getTargetPosition(target)
                
                if targetPos and targetPart then
                    -- Modify arguments
                    args[2] = targetPos
                    args[3] = targetPart
                    args[4] = targetPos
                end
            end
        end
        
        return oldRemoteCall(self, unpack(args))
    end
    
    return oldRemoteCall(self, ...)
end))

-- ========================================
-- FOV CIRCLE UPDATE
-- ========================================
RunService.RenderStepped:Connect(function()
    updateFOVCircle()
end)

-- ========================================
-- CLEANUP
-- ========================================
print("[Velaware] Advanced Silent Aim loaded")
print("  - Hookless primary method")
print("  - Hook backup method")
print("  - Movement prediction enabled")
print("  - FOV follows cursor")

return {
    Disable = function()
        getgenv().silentAimConfig.ENABLED = false
        fovCircle:Remove()
    end
}
