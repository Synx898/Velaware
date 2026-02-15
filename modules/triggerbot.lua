-- ========================================
-- VELAWARE - TRIGGERBOT MODULE
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

-- ========================================
-- CONFIGURATION
-- ========================================
getgenv().triggerbotConfig = {
    ENABLED = false,
    DELAY = 0.05, -- Delay before shooting (more human-like)
    TEAM_CHECK = true,
    STRICT_WALL_CHECK = true, -- Very strict visibility check
    REQUIRE_CROSSHAIR = true, -- Only shoot if directly aiming at them
    CROSSHAIR_TOLERANCE = 15, -- Pixels from exact center (very tight)
}

-- ========================================
-- STRICT WALL CHECK
-- ========================================
local function isStrictlyVisible(targetChar)
    if not targetChar or not targetChar.Parent then return false end
    if not player.Character then return false end
    
    local myHrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return false end
    
    -- Get the part we're actually aiming at
    local targetPart = mouse.Target
    if not targetPart then return false end
    
    -- Make sure the part belongs to the target character
    if not targetPart:IsDescendantOf(targetChar) then return false end
    
    -- STRICT raycast from camera to target
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character, camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local cameraPos = camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = (targetPos - cameraPos).Unit
    local distance = (targetPos - cameraPos).Magnitude
    
    -- Cast ray from camera to target
    local rayResult = Workspace:Raycast(cameraPos, direction * distance, raycastParams)
    
    if rayResult then
        local hitPart = rayResult.Instance
        
        -- MUST hit the target character's part directly
        if not hitPart:IsDescendantOf(targetChar) then
            return false
        end
        
        -- Extra check: Don't shoot through transparent objects
        if hitPart.Transparency >= 0.9 then
            return false
        end
        
        -- Don't shoot through non-collidable objects
        if not hitPart.CanCollide and hitPart.Name ~= "Head" and hitPart.Name ~= "HumanoidRootPart" then
            return false
        end
    end
    
    -- Double check from player position
    raycastParams.FilterDescendantsInstances = {player.Character, targetChar}
    local rayResult2 = Workspace:Raycast(myHrp.Position, direction * distance, raycastParams)
    
    -- If anything blocks the shot from player position, don't shoot
    if rayResult2 then
        return false
    end
    
    return true
end

-- ========================================
-- CROSSHAIR CHECK
-- ========================================
local function isOnCrosshair(targetChar)
    if not targetChar then return false end
    
    local targetPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not targetPart then return false end
    
    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
    
    if not onScreen then return false end
    
    local screenSize = camera.ViewportSize
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    local targetPos2D = Vector2.new(screenPos.X, screenPos.Y)
    
    local distance = (targetPos2D - screenCenter).Magnitude
    
    return distance <= getgenv().triggerbotConfig.CROSSHAIR_TOLERANCE
end

-- ========================================
-- TARGET VALIDATION
-- ========================================
local function isValidTarget(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    
    local char = targetPlayer.Character
    if not char or char.Parent ~= Workspace then return false end
    
    -- Team check
    if getgenv().triggerbotConfig.TEAM_CHECK then
        if targetPlayer.Team and player.Team and targetPlayer.Team == player.Team then
            return false
        end
    end
    
    -- Alive check
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- Invulnerability check
    if char:GetAttribute("Invulnerable") or char:FindFirstChild("SpeedTrail") then
        return false
    end
    
    return true
end

-- ========================================
-- GET TARGET UNDER MOUSE
-- ========================================
local function getTargetUnderMouse()
    local target = mouse.Target
    if not target then return nil end
    
    -- Find which player this part belongs to
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer.Character and target:IsDescendantOf(targetPlayer.Character) then
            if isValidTarget(targetPlayer) then
                return targetPlayer
            end
        end
    end
    
    return nil
end

-- ========================================
-- SHOOTING LOGIC
-- ========================================
local lastShot = 0
local isHoldingMouse = false

local function attemptShoot()
    if not getgenv().triggerbotConfig.ENABLED then return end
    if not isHoldingMouse then return end
    
    local currentTime = tick()
    if currentTime - lastShot < getgenv().triggerbotConfig.DELAY then return end
    
    -- Get target under mouse
    local target = getTargetUnderMouse()
    if not target then return end
    
    -- STRICT wall check
    if getgenv().triggerbotConfig.STRICT_WALL_CHECK then
        if not isStrictlyVisible(target.Character) then
            return
        end
    end
    
    -- Crosshair check
    if getgenv().triggerbotConfig.REQUIRE_CROSSHAIR then
        if not isOnCrosshair(target.Character) then
            return
        end
    end
    
    -- All checks passed - trigger shot
    lastShot = currentTime
    
    -- Actually click the mouse
    mouse1click()
end

-- ========================================
-- MOUSE TRACKING
-- ========================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isHoldingMouse = true
    end
end)

UserInputService.InputEnded:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isHoldingMouse = false
    end
end)

-- ========================================
-- UPDATE LOOP
-- ========================================
RunService.Heartbeat:Connect(function()
    attemptShoot()
end)

-- ========================================
-- CLEANUP
-- ========================================
local Connections = {}

print("[Velaware] Triggerbot loaded - Strict wall checks enabled")

return Connections
