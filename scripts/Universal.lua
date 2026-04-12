-- Velaware | Universal Aimbot
-- Obsidian UI

local repo        = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library     = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- MUST set library FIRST before using ThemeManager
ThemeManager:SetLibrary(Library)

-- NOW set Velaware Blue theme BEFORE creating window
ThemeManager:SetDefaultTheme({
    AccentColor = Color3.fromRGB(54, 147, 227),  -- Velaware Blue
    AccentColorDark = Color3.fromRGB(44, 127, 207),
})

-- ESP loaded as separate module
local ESPSystem = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Synx898/Velaware/refs/heads/main/misc/Aimbotesp.lua"
))()

-- ==================== SERVICES ====================
local Services = {
    Players    = game:GetService("Players"),
    UserInput  = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
}

local Client = {
    Player    = Services.Players.LocalPlayer,
    Mouse     = Services.Players.LocalPlayer:GetMouse(),
    Camera    = workspace.CurrentCamera,
    Character = Services.Players.LocalPlayer.Character or Services.Players.LocalPlayer.CharacterAdded:Wait(),
}

Services.Players.LocalPlayer.CharacterAdded:Connect(function(c) Client.Character = c end)

-- ==================== CONFIG ====================
local Config = {
    Aimbot = {
        Enabled = false, TargetPart = "Head", Radius = 30,
        Smoothing = false, SmoothAmount = 0.2,
        Prediction = false, PredictionMultiplier = 6.612,
        ShowFOV = false, LockKey = Enum.KeyCode.Q,
        AutoLock = false, AutoLockInterval = 0.1,
    },
    Triggerbot = {
        Enabled = false, Delay = 50,
        WallCheck = true, DoubleActivation = true,
    },
    Filters = {
        TeamCheck = false, UseWhitelist = false,
        Whitelist = {}, Blacklist = {},
    },
    FOV        = { Enabled = false, Value = 70 },
    AntiAFK    = { Enabled = false },
    ClientMods = {
        WalkSpeed    = { Enabled = false, Value = 16 },
        JumpPower    = { Enabled = false, Value = 50 },
        Fly          = { Enabled = false, Speed = 50 },
        Noclip       = { Enabled = false },
        InfiniteJump = { Enabled = false },
    },
    Misc = { DiscordLink = "https://discord.gg/zNuUd4SdYY" },
}

-- ==================== STATE ====================
local State = {
    Aimbot = { Active = false, CurrentTarget = nil, FOVCircle = nil },
    Device = { IsMobile = Services.UserInput.TouchEnabled and not Services.UserInput.KeyboardEnabled },
}

-- ==================== UTILS ====================
local function isAlive(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead
end

local function isVisible(player)
    if not player or not player.Character or not Client.Character then return false end
    local tp = player.Character:FindFirstChild(Config.Aimbot.TargetPart) or player.Character:FindFirstChild("Head")
    local op = Client.Character:FindFirstChild("Head") or Client.Character:FindFirstChild("HumanoidRootPart")
    if not tp or not op then return false end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {Client.Character, player.Character}
    rp.FilterType = Enum.RaycastFilterType.Blacklist; rp.IgnoreWater = true
    return workspace:Raycast(op.Position, (tp.Position - op.Position), rp) == nil
end

local function worldToScreen(pos)
    local sp, on = Client.Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), on
end

-- ==================== FILTERS ====================
local function passesFilters(player)
    if player == Client.Player then return false end
    if not isAlive(player) then return false end
    if Config.Filters.Blacklist[player.Name] then return false end
    if Config.Filters.UseWhitelist and not Config.Filters.Whitelist[player.Name] then return false end
    if Config.Filters.TeamCheck and player.Team == Client.Player.Team then return false end
    return true
end

-- ==================== TARGETING ====================
local function getTargetPos(player)
    if not player or not player.Character then return nil end
    local part = player.Character:FindFirstChild(Config.Aimbot.TargetPart)
    if not part then return nil end
    local pos = part.Position
    if Config.Aimbot.Prediction then
        local vel = part.AssemblyLinearVelocity or part.Velocity
        pos = pos + (vel / Config.Aimbot.PredictionMultiplier)
    end
    return pos
end

local function getNearestTarget()
    local nearest, bestDist = nil, math.huge
    local mousePos = Vector2.new(Client.Mouse.X, Client.Mouse.Y + 36)
    for _, player in pairs(Services.Players:GetPlayers()) do
        if passesFilters(player) then
            local part = player.Character and player.Character:FindFirstChild(Config.Aimbot.TargetPart)
            if part then
                local sp, onScreen = worldToScreen(part.Position)
                if onScreen then
                    local dist = (mousePos - sp).Magnitude
                    if dist <= Config.Aimbot.Radius and dist < bestDist then
                        bestDist = dist; nearest = player
                    end
                end
            end
        end
    end
    return nearest
end

-- ==================== AIMBOT ====================
local AimbotSystem = {}

function AimbotSystem.Release()
    State.Aimbot.CurrentTarget = nil; State.Aimbot.Active = false
end

function AimbotSystem.Acquire()
    local t = getNearestTarget()
    if not t then return false end
    State.Aimbot.CurrentTarget = t; State.Aimbot.Active = true; return true
end

function AimbotSystem.Toggle()
    if State.Aimbot.CurrentTarget then AimbotSystem.Release()
    elseif AimbotSystem.Acquire() then State.Aimbot.Active = true end
end

function AimbotSystem.LockToTarget()
    if not (Config.Aimbot.Enabled and State.Aimbot.Active and State.Aimbot.CurrentTarget) then return end
    local pos = getTargetPos(State.Aimbot.CurrentTarget)
    if not pos then AimbotSystem.Release(); return end
    local cur = Client.Camera.CFrame
    local tgt = CFrame.new(cur.Position, pos)
    Client.Camera.CFrame = Config.Aimbot.Smoothing and cur:Lerp(tgt, Config.Aimbot.SmoothAmount) or tgt
end

function AimbotSystem.CreateFOV()
    pcall(function()
        if State.Aimbot.FOVCircle then State.Aimbot.FOVCircle:Remove(); State.Aimbot.FOVCircle = nil end
        local c = Drawing.new("Circle")
        c.Thickness = 2; c.NumSides = 50; c.Filled = false
        c.Transparency = 0.7; c.Color = Color3.fromRGB(54, 147, 227)
        c.Radius = Config.Aimbot.Radius; c.Visible = Config.Aimbot.ShowFOV
        c.Position = Vector2.new(Client.Mouse.X, Client.Mouse.Y + 36)
        State.Aimbot.FOVCircle = c
    end)
end

function AimbotSystem.UpdateFOV()
    local c = State.Aimbot.FOVCircle; if not c then return end
    c.Position = Vector2.new(Client.Mouse.X, Client.Mouse.Y + 36)
    c.Radius = Config.Aimbot.Radius; c.Visible = Config.Aimbot.ShowFOV
end

function AimbotSystem.Cleanup()
    if State.Aimbot.FOVCircle then
        pcall(function() State.Aimbot.FOVCircle:Remove() end)
        State.Aimbot.FOVCircle = nil
    end
end

function AimbotSystem.Initialize()
    AimbotSystem.CreateFOV()
    -- Input handled via KeyPicker in UI, but keep fallback
    Services.RunService.RenderStepped:Connect(function()
        AimbotSystem.LockToTarget(); AimbotSystem.UpdateFOV()
    end)
    Client.Player.AncestryChanged:Connect(AimbotSystem.Cleanup)
end

-- ==================== AUTO LOCK ====================
task.spawn(function()
    while true do
        task.wait(Config.Aimbot.AutoLockInterval)
        if Config.Aimbot.Enabled and Config.Aimbot.AutoLock then
            local t = getNearestTarget()
            if t then State.Aimbot.CurrentTarget = t; State.Aimbot.Active = true
            elseif not State.Aimbot.Active then State.Aimbot.CurrentTarget = nil end
        end
    end
end)

-- ==================== TRIGGERBOT ====================
task.spawn(function()
    while true do
        task.wait(Config.Triggerbot.Delay / 1000)
        if Config.Triggerbot.Enabled and State.Aimbot.CurrentTarget and State.Aimbot.CurrentTarget.Character then
            pcall(function()
                if not isAlive(State.Aimbot.CurrentTarget) then AimbotSystem.Release(); return end
                if Config.Triggerbot.WallCheck and not isVisible(State.Aimbot.CurrentTarget) then return end
                local tool = Client.Character and Client.Character:FindFirstChildOfClass("Tool")
                if not tool then return end
                if tool:FindFirstChild("Handle") then
                    tool:Activate()
                    if Config.Triggerbot.DoubleActivation then task.spawn(function() tool:Activate() end) end
                end
                for _, d in pairs(tool:GetDescendants()) do
                    if d:IsA("RemoteEvent") and (d.Name:lower():find("fire") or d.Name:lower():find("shoot") or d.Name:lower():find("attack")) then
                        d:FireServer()
                        if Config.Triggerbot.DoubleActivation then task.spawn(function() d:FireServer() end) end
                        break
                    end
                end
                if mouse1press then
                    mouse1press(); task.wait(0.01); mouse1release()
                    if Config.Triggerbot.DoubleActivation then
                        task.spawn(function() task.wait(0.02); mouse1press(); task.wait(0.01); mouse1release() end)
                    end
                end
            end)
        end
    end
end)

-- ==================== ANTI AFK ====================
Client.Player.Idled:Connect(function()
    if Config.AntiAFK.Enabled then
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ==================== FOV ====================
local function updateFOV()
    Client.Camera.FieldOfView = Config.FOV.Enabled and Config.FOV.Value or 70
end
task.spawn(function() while true do task.wait(0.5); updateFOV() end end)
Client.Player.CharacterAdded:Connect(function() task.wait(0.5); updateFOV() end)

-- ==================== CLIENT MODS ====================
local FlyState    = { Flying = false, BV = nil, BG = nil }
local OrigValues  = { WalkSpeed = nil, JumpPower = nil }
local ActiveLoops = { WalkSpeed = nil, JumpPower = nil, Noclip = nil }

local function cacheOriginals()
    local hum = Client.Character and Client.Character:FindFirstChildOfClass("Humanoid")
    if hum then OrigValues.WalkSpeed = hum.WalkSpeed; OrigValues.JumpPower = hum.JumpPower end
end

local function restoreOriginals()
    if not OrigValues.WalkSpeed then return end
    local hum = Client.Character and Client.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = OrigValues.WalkSpeed; hum.JumpPower = OrigValues.JumpPower end
end

local function updateWalkSpeed()
    if ActiveLoops.WalkSpeed then task.cancel(ActiveLoops.WalkSpeed); ActiveLoops.WalkSpeed = nil end
    if Config.ClientMods.WalkSpeed.Enabled then
        ActiveLoops.WalkSpeed = task.spawn(function()
            while Config.ClientMods.WalkSpeed.Enabled do
                task.wait(0.1)
                local hum = Client.Character and Client.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = Config.ClientMods.WalkSpeed.Value end
            end
        end)
    else
        local hum = Client.Character and Client.Character:FindFirstChildOfClass("Humanoid")
        if hum and OrigValues.WalkSpeed then hum.WalkSpeed = OrigValues.WalkSpeed end
    end
end

local function updateJumpPower()
    if ActiveLoops.JumpPower then task.cancel(ActiveLoops.JumpPower); ActiveLoops.JumpPower = nil end
    if Config.ClientMods.JumpPower.Enabled then
        ActiveLoops.JumpPower = task.spawn(function()
            while Config.ClientMods.JumpPower.Enabled do
                task.wait(0.1)
                local hum = Client.Character and Client.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = Config.ClientMods.JumpPower.Value end
            end
        end)
    else
        local hum = Client.Character and Client.Character:FindFirstChildOfClass("Humanoid")
        if hum and OrigValues.JumpPower then hum.JumpPower = OrigValues.JumpPower end
    end
end

local function updateNoclip()
    if ActiveLoops.Noclip then task.cancel(ActiveLoops.Noclip); ActiveLoops.Noclip = nil end
    if Config.ClientMods.Noclip.Enabled then
        ActiveLoops.Noclip = task.spawn(function()
            while Config.ClientMods.Noclip.Enabled do
                task.wait()
                if Client.Character then
                    for _, p in pairs(Client.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end
        end)
    end
end

local function startFly()
    if FlyState.Flying then return end
    FlyState.Flying = true
    local hrp = Client.Character and Client.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    FlyState.BV = Instance.new("BodyVelocity", hrp)
    FlyState.BV.Velocity = Vector3.zero; FlyState.BV.MaxForce = Vector3.new(9e4,9e4,9e4)
    FlyState.BG = Instance.new("BodyGyro", hrp)
    FlyState.BG.P = 9e4; FlyState.BG.MaxTorque = Vector3.new(9e4,9e4,9e4)
    FlyState.BG.CFrame = hrp.CFrame
    task.spawn(function()
        while FlyState.Flying and Config.ClientMods.Fly.Enabled do
            task.wait()
            local cam = workspace.CurrentCamera; local ui = Services.UserInput; local mv = Vector3.zero
            if ui:IsKeyDown(Enum.KeyCode.W) then mv += cam.CFrame.LookVector end
            if ui:IsKeyDown(Enum.KeyCode.S) then mv -= cam.CFrame.LookVector end
            if ui:IsKeyDown(Enum.KeyCode.A) then mv -= cam.CFrame.RightVector end
            if ui:IsKeyDown(Enum.KeyCode.D) then mv += cam.CFrame.RightVector end
            if ui:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0,1,0) end
            if ui:IsKeyDown(Enum.KeyCode.LeftShift) then mv -= Vector3.new(0,1,0) end
            if FlyState.BV then FlyState.BV.Velocity = mv * Config.ClientMods.Fly.Speed end
            if FlyState.BG then FlyState.BG.CFrame = cam.CFrame end
        end
    end)
end

local function stopFly()
    FlyState.Flying = false
    if FlyState.BV then FlyState.BV:Destroy(); FlyState.BV = nil end
    if FlyState.BG then FlyState.BG:Destroy(); FlyState.BG = nil end
end

Services.UserInput.JumpRequest:Connect(function()
    if Config.ClientMods.InfiniteJump.Enabled and Client.Character then
        local hum = Client.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

task.wait(0.5); cacheOriginals(); restoreOriginals()

Client.Player.CharacterAdded:Connect(function()
    FlyState.Flying = false; FlyState.BV = nil; FlyState.BG = nil
    for k in pairs(ActiveLoops) do
        if ActiveLoops[k] then task.cancel(ActiveLoops[k]); ActiveLoops[k] = nil end
    end
    task.wait(0.5); cacheOriginals(); restoreOriginals()
    if Config.ClientMods.WalkSpeed.Enabled   then updateWalkSpeed() end
    if Config.ClientMods.JumpPower.Enabled   then updateJumpPower() end
    if Config.ClientMods.Fly.Enabled         then startFly() end
    if Config.ClientMods.Noclip.Enabled      then updateNoclip() end
end)

-- ==================== INIT SYSTEMS ====================
AimbotSystem.Initialize()
ESPSystem.Initialize(passesFilters)

-- ==================== WINDOW ====================
local Window = Library:CreateWindow({
    Title            = "Velaware",
    Footer           = "Universal Aimbot | made by sl1yy",
    Icon             = 'rbxassetid://113383178639673',
    CornerRadius     = 10,
    Center           = true,
    AutoShow         = true,
    Resizable        = true,
    ShowCustomCursor = false,
    NotifySide       = "Right",
    GlobalSearch     = true,
})

local Tabs = {
    Aimbot     = Window:AddTab("Aimbot",      "crosshair"),
    Triggerbot = Window:AddTab("Triggerbot",  "zap"),
    ESP        = Window:AddTab("ESP",         "eye"),
    Filters    = Window:AddTab("Filters",     "sliders-horizontal"),
    Visuals    = Window:AddTab("Visuals",     "palette"),
    ClientMods = Window:AddTab("Client Mods", "user"),
    Settings   = Window:AddTab("Settings",    "settings"),
}

-- ==================== AIMBOT TAB ====================
local AG1 = Tabs.Aimbot:AddLeftGroupbox("Core")
local AG2 = Tabs.Aimbot:AddRightGroupbox("Prediction & Smoothing")

AG1:AddToggle("AimbotEnabled", { Text = "Enable Aimbot", Default = false,
    Callback = function(v) Config.Aimbot.Enabled = v end })

AG1:AddDropdown("AimPart", {
    Text = "Target Part", Values = {"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
    Default = "Head", Callback = function(v) Config.Aimbot.TargetPart = v end })

AG1:AddSlider("AimRadius", { Text = "Aim Radius", Default = 30, Min = 10, Max = 500, Rounding = 0,
    Callback = function(v) Config.Aimbot.Radius = v end })

AG1:AddToggle("ShowFOV", { Text = "Show FOV Circle", Default = false,
    Callback = function(v) Config.Aimbot.ShowFOV = v end })

-- Lock key as a proper KeyPicker
AG1:AddLabel("Lock Key"):AddKeyPicker("LockKeyPicker", {
    Default    = "Q",
    NoUI       = false,
    Text       = "Aimbot Lock Key",
    Mode       = "Toggle",
    Callback   = function() AimbotSystem.Toggle() end,
    ChangedCallback = function(newKey)
        Config.Aimbot.LockKey = Enum.KeyCode[newKey] or Enum.KeyCode.Q
    end,
})

AG1:AddDivider()
AG1:AddToggle("AutoLock", { Text = "Auto-Lock", Default = false,
    Callback = function(v) Config.Aimbot.AutoLock = v; if not v then AimbotSystem.Release() end end })

AG1:AddSlider("AutoLockInterval", { Text = "Update Speed", Default = 0.1, Min = 0.05, Max = 1, Rounding = 2,
    Callback = function(v) Config.Aimbot.AutoLockInterval = v end })

AG2:AddToggle("Prediction", { Text = "Enable Prediction", Default = false,
    Callback = function(v) Config.Aimbot.Prediction = v end })

AG2:AddSlider("PredMulti", { Text = "Prediction Multiplier", Default = 6.6, Min = 1, Max = 20, Rounding = 1,
    Callback = function(v) Config.Aimbot.PredictionMultiplier = v end })

AG2:AddToggle("Smoothing", { Text = "Enable Smoothing", Default = false,
    Callback = function(v) Config.Aimbot.Smoothing = v end })

AG2:AddSlider("SmoothAmt", { Text = "Smooth Amount", Default = 0.2, Min = 0.01, Max = 1, Rounding = 2,
    Callback = function(v) Config.Aimbot.SmoothAmount = v end })

-- ==================== TRIGGERBOT TAB ====================
local TG = Tabs.Triggerbot:AddLeftGroupbox("Triggerbot")

TG:AddToggle("TrigEnabled", { Text = "Enable Triggerbot", Default = false,
    Callback = function(v) Config.Triggerbot.Enabled = v end })

TG:AddToggle("WallCheck", { Text = "Wall Check", Default = true,
    Callback = function(v) Config.Triggerbot.WallCheck = v end })

TG:AddSlider("TrigDelay", { Text = "Fire Delay (ms)", Default = 50, Min = 10, Max = 500, Rounding = 0,
    Callback = function(v) Config.Triggerbot.Delay = v end })

TG:AddToggle("DoubleActivation", { Text = "Double Activation", Default = true,
    Callback = function(v) Config.Triggerbot.DoubleActivation = v end })

-- ==================== ESP TAB ====================
local EG1 = Tabs.ESP:AddLeftGroupbox("ESP")
local EG2 = Tabs.ESP:AddRightGroupbox("Display")
local ESPCfg = ESPSystem.Config

EG1:AddToggle("ESPEnabled", { Text = "Enable ESP", Default = false,
    Callback = function(v) ESPCfg.Enabled = v; ESPSystem.UpdateAll(passesFilters) end })

EG1:AddToggle("ShowNames", { Text = "Show Names", Default = true,
    Callback = function(v) ESPCfg.ShowNames = v; ESPSystem.UpdateAll(passesFilters) end })

EG1:AddToggle("ShowDistance", { Text = "Show Distance", Default = true,
    Callback = function(v) ESPCfg.ShowDistance = v; ESPSystem.UpdateAll(passesFilters) end })

EG1:AddToggle("ShowHealth", { Text = "Show Health Bar", Default = true,
    Callback = function(v) ESPCfg.ShowHealth = v; ESPSystem.UpdateAll(passesFilters) end })

EG1:AddToggle("UseTeamColors", { Text = "Use Team Colors", Default = true,
    Callback = function(v) ESPCfg.UseTeamColors = v; ESPSystem.UpdateAll(passesFilters) end })

EG1:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
    Default  = Color3.fromRGB(54, 147, 227),
    Title    = "ESP Color",
    Callback = function(v) ESPCfg.Color = v; ESPSystem.UpdateAll(passesFilters) end,
})

EG2:AddToggle("ShowTracers", { Text = "Show Tracers", Default = false,
    Callback = function(v) ESPCfg.ShowTracers = v; ESPSystem.UpdateAll(passesFilters) end })

EG2:AddDropdown("TracerOrigin", {
    Text = "Tracer Origin", Values = {"Bottom","Middle","Top"}, Default = "Bottom",
    Callback = function(v) ESPCfg.TracerOrigin = v end })

-- ==================== FILTERS TAB ====================
local FG1 = Tabs.Filters:AddLeftGroupbox("Filters")
local FG2 = Tabs.Filters:AddRightGroupbox("Lists")

FG1:AddToggle("TeamCheck", { Text = "Team Check", Default = false,
    Callback = function(v) Config.Filters.TeamCheck = v end })

FG1:AddToggle("UseWhitelist", { Text = "Whitelist Mode", Default = false,
    Callback = function(v) Config.Filters.UseWhitelist = v end })

FG2:AddInput("AddWhitelist", { Text = "Add to Whitelist", Placeholder = "Player name",
    Callback = function(v)
        if v ~= "" then Config.Filters.Whitelist[v] = true; Library:Notify(v .. " whitelisted", 2) end
    end })

FG2:AddInput("AddBlacklist", { Text = "Add to Blacklist", Placeholder = "Player name",
    Callback = function(v)
        if v ~= "" then Config.Filters.Blacklist[v] = true; Library:Notify(v .. " blacklisted", 2) end
    end })

FG2:AddButton("Clear Whitelist", function()
    Config.Filters.Whitelist = {}; Library:Notify("Whitelist cleared", 2)
end)
FG2:AddButton("Clear Blacklist", function()
    Config.Filters.Blacklist = {}; Library:Notify("Blacklist cleared", 2)
end)

-- ==================== VISUALS TAB ====================
local VG = Tabs.Visuals:AddLeftGroupbox("FOV")

VG:AddToggle("FOVEnabled", { Text = "Custom FOV", Default = false,
    Callback = function(v) Config.FOV.Enabled = v; updateFOV() end })

VG:AddSlider("FOVValue", { Text = "FOV Amount", Default = 70, Min = 70, Max = 120, Rounding = 0,
    Callback = function(v) Config.FOV.Value = v; updateFOV() end })

-- ==================== CLIENT MODS TAB ====================
local CG1 = Tabs.ClientMods:AddLeftGroupbox("Movement")
local CG2 = Tabs.ClientMods:AddRightGroupbox("Advanced")

CG1:AddToggle("WSEnabled", { Text = "Custom Walk Speed", Default = false,
    Callback = function(v) Config.ClientMods.WalkSpeed.Enabled = v; updateWalkSpeed() end })

CG1:AddSlider("WSValue", { Text = "Walk Speed", Default = 16, Min = 16, Max = 200, Rounding = 0,
    Callback = function(v) Config.ClientMods.WalkSpeed.Value = v end })

CG1:AddToggle("JPEnabled", { Text = "Custom Jump Power", Default = false,
    Callback = function(v) Config.ClientMods.JumpPower.Enabled = v; updateJumpPower() end })

CG1:AddSlider("JPValue", { Text = "Jump Power", Default = 50, Min = 50, Max = 200, Rounding = 0,
    Callback = function(v) Config.ClientMods.JumpPower.Value = v end })

CG1:AddToggle("InfJump", { Text = "Infinite Jump", Default = false,
    Callback = function(v) Config.ClientMods.InfiniteJump.Enabled = v end })

CG2:AddToggle("FlyEnabled", { Text = "Fly (WASD + Space/Shift)", Default = false,
    Callback = function(v)
        Config.ClientMods.Fly.Enabled = v
        if v then startFly() else stopFly() end
    end })

CG2:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 200, Rounding = 0,
    Callback = function(v) Config.ClientMods.Fly.Speed = v end })

CG2:AddToggle("Noclip", { Text = "Noclip", Default = false,
    Callback = function(v) Config.ClientMods.Noclip.Enabled = v; updateNoclip() end })

-- ==================== SETTINGS TAB ====================
local SG = Tabs.Settings:AddLeftGroupbox("Settings")

SG:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift", NoUI = true, Text = "Menu keybind"
})
Library.ToggleKeybind = Library.Options.MenuKeybind

SG:AddToggle("AntiAFK", { Text = "Anti-AFK", Default = false,
    Callback = function(v) Config.AntiAFK.Enabled = v end })

SG:AddButton("Copy Discord Link", function()
    if setclipboard then setclipboard(Config.Misc.DiscordLink) end
    Library:Notify("Discord link copied!", 3)
end)

SG:AddButton("Unload", function() Library:Unload() end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Velaware")
SaveManager:SetFolder("Velaware/Universal")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    AimbotSystem.Cleanup()
    for _, p in pairs(Services.Players:GetPlayers()) do ESPSystem.Remove(p) end
    stopFly()
    print("[Velaware] Unloaded.")
end)

Library:Notify("Velaware loaded! RightShift to toggle.", 4)
print("[Velaware] Universal Aimbot loaded.")
