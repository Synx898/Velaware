-- ========================================
-- VELAWARE - SILENT AIM MODULE (FIXED)
-- Murder vs Sheriff Duels
-- ========================================

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

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
    PREDICT_MOVEMENT = true,
    PREDICTION_MULTIPLIER = 0.12,
}

-- ========================================
-- FOV CIRCLE (FOLLOWS CURSOR)
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
        -- Follow the mouse cursor instead of screen center
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
    if not targetChar or not targetChar.Parent then return false end
    if not getgenv().silentAimConfig.WALL_CHECK then return true end
    
    local targetPart = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
    if not targetPart then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character, targetChar}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local direction = targetPart.Position - fromPosition
    local rayResult = Workspace:Raycast(fromPosition, direction, raycastParams)
    
    -- If no wall hit, target is visible
    if not rayResult then return true end
    
    -- If we hit the target or something on the target, it's visible
    if rayResult.Instance:IsDescendantOf(targetChar) then
        return true
    end
    
    -- We hit a wall, target not visible
    return false
end

local function isInFOV(targetPosition)
    local screenPos, onScreen = camera:WorldToViewportPoint(targetPosition)
    
    if not onScreen then return false end
    
    -- Use mouse position instead of screen center
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
    
    -- Visibility check (wall check) - only prevents targeting people behind walls
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
    
    -- Use mouse position instead of screen center
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
    
    -- Calculate velocity-based prediction
    local velocity = hrp.AssemblyLinearVelocity
    if velocity.Magnitude < 1 then return nil end -- Target is stationary
    
    local myChar = player.Character
    if not myChar then return nil end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    
    -- Calculate distance and approximate bullet travel time
    local distance = (hrp.Position - myHrp.Position).Magnitude
    local bulletSpeed = 500 -- Approximate bullet speed
    local travelTime = distance / bulletSpeed
    
    -- Predict where target will be
    local prediction = velocity * travelTime * getgenv().silentAimConfig.PREDICTION_MULTIPLIER
    
    return prediction
end

local function getTargetPosition(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return nil end
    
    local char = targetPlayer.Character
    local head = char:FindFirstChild("Head")
    local upperTorso = char:FindFirstChild("UpperTorso")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    local myChar = player.Character
    if not myChar then return nil end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    
    -- Prioritize head for better accuracy
    local targetPart = nil
    local basePosition = nil
    
    if head then
        targetPart = head
        basePosition = head.Position
    elseif upperTorso then
        targetPart = upperTorso
        basePosition = upperTorso.Position
    elseif hrp then
        targetPart = hrp
        basePosition = hrp.Position
    else
        return nil
    end
    
    -- Apply prediction if enabled
    local prediction = predictTargetPosition(targetPlayer)
    if prediction then
        basePosition = basePosition + prediction
    end
    
    return basePosition, targetPart
end

-- ========================================
-- SILENT AIM HOOK (FIXED)
-- ========================================
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    -- Hook the shoot remote when silent aim is enabled
    if not checkcaller() and method == "FireServer" and self == shootRemote then
        if getgenv().silentAimConfig.ENABLED then
            local target = getClosestTarget()
            
            if target then
                local targetPos, targetPart = getTargetPosition(target)
                
                if targetPos and targetPart then
                    -- Modify the arguments to aim at the target
                    -- args[1] = muzzle position (keep original)
                    -- args[2] = aim direction (modify this)
                    -- args[3] = hit part (modify this)
                    -- args[4] = hit position (modify this)
                    
                    args[2] = targetPos  -- Aim direction
                    args[3] = targetPart  -- Hit part
                    args[4] = targetPos   -- Hit position
                end
            end
        end
        
        -- Call original with potentially modified args
        return oldNamecall(self, unpack(args))
    end
    
    return oldNamecall(self, ...)
end))

-- ========================================
-- FOV CIRCLE UPDATE LOOP
-- ========================================
local connection = RunService.RenderStepped:Connect(function()
    updateFOVCircle()
end)

-- ========================================
-- CLEANUP
-- ========================================
local Connections = {}
Connections[1] = connection

print("[VELAWARE] Silent Aim initialized!")
print("  ✓ FOV follows cursor")
print("  ✓ Improved wall check")
print("  ✓ Movement prediction")
print("  ✓ Respects game cooldowns")

return Connections
