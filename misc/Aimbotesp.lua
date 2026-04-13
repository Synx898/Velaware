-- Velaware | ESP Module
-- Loaded via loadstring from main script
-- Returns ESPSystem table

local Services = {
    Players  = game:GetService("Players"),
    RunService = game:GetService("RunService"),
}

local Client = {
    Player  = Services.Players.LocalPlayer,
    Camera  = workspace.CurrentCamera,
    Character = Services.Players.LocalPlayer.Character or Services.Players.LocalPlayer.CharacterAdded:Wait(),
}

Services.Players.LocalPlayer.CharacterAdded:Connect(function(c) Client.Character = c end)

local ESPConfig = {
    Enabled       = false,
    ShowNames     = true,
    ShowDistance  = true,
    ShowHealth    = true,
    ShowTracers   = false,
    TracerOrigin  = "Bottom",
    UseTeamColors = true,
    Color         = Color3.fromRGB(54, 147, 227),
    -- New visual options
    ShowCornerBox = false,
    BoxThickness  = 2,
    TextOutline   = true,
    HealthBarWidth = 80,
    -- Performance options
    UpdateInterval = 0.5,  -- Global update interval (seconds)
    MaxTracerThickness = 3,
}

local ESPObjects = {}
local DistanceCache = {}  -- { player = { distance, lastUpdate } }
local CacheTimeout = 0.3

local function getColor(player)
    if ESPConfig.UseTeamColors and player.Team then
        return player.Team.TeamColor.Color
    end
    return ESPConfig.Color
end

local function getCachedDistance(p1, p2, player)
    local now = tick()
    if DistanceCache[player] and (now - DistanceCache[player].time) < CacheTimeout then
        return DistanceCache[player].distance
    end
    local dist = (p1 - p2).Magnitude
    DistanceCache[player] = { distance = dist, time = now }
    return dist
end

local function worldToScreen(pos)
    local sp, on = Client.Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), on
end

local function getDistance(p1, p2)
    return (p1 - p2).Magnitude
end

local ESPSystem = {}

function ESPSystem.Remove(player)
    local obj = ESPObjects[player]
    if not obj then return end
    for _, v in pairs(obj) do
        pcall(function()
            if v.Remove then v:Remove() else v:Destroy() end
        end)
    end
    ESPObjects[player] = nil
    DistanceCache[player] = nil
end

function ESPSystem.Create(player)
    if player == Client.Player then return end
    if not player.Character then return end
    ESPSystem.Remove(player)

    local objects = {}
    local color = getColor(player)

    -- Highlight
    local hl = Instance.new("Highlight", player.Character)
    hl.FillColor = color; hl.OutlineColor = Color3.new(0,0,0)
    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    table.insert(objects, hl)

    -- Corner Box (optimized with drawing)
    if ESPConfig.ShowCornerBox then
        local boxSize = 20
        local corners = {}
        for i = 1, 4 do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = color
            line.Thickness = ESPConfig.BoxThickness
            line.Transparency = 0.8
            table.insert(corners, line)
        end
        table.insert(objects, { corners = corners, type = "box" })
    end

    -- Billboard
    local head = player.Character:FindFirstChild("Head")
    if head and (ESPConfig.ShowNames or ESPConfig.ShowDistance or ESPConfig.ShowHealth) then
        local bb = Instance.new("BillboardGui", head)
        bb.Size = UDim2.new(0, 200, 0, 100)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.AlwaysOnTop = true
        local yOff = 0

        if ESPConfig.ShowNames then
            local lbl = Instance.new("TextLabel", bb)
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0, 0, 0, yOff)
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.Font = Enum.Font.GothamBold
            lbl.Text = player.Name
            lbl.TextColor3 = color
            lbl.TextSize = 14
            lbl.TextStrokeTransparency = 0.5
            yOff += 20
        end

        if ESPConfig.ShowHealth then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                local bg = Instance.new("Frame", bb)
                bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20); bg.BorderColor3 = Color3.fromRGB(60, 60, 60)
                bg.BorderSizePixel = 1
                bg.Position = UDim2.new(0.05, 0, 0, yOff); bg.Size = UDim2.new(0.9, 0, 0, 14)
                local bar = Instance.new("Frame", bg)
                bar.BackgroundColor3 = Color3.fromRGB(100, 255, 100); bar.BorderSizePixel = 0
                bar.Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 1, 0)
                local hlbl = Instance.new("TextLabel", bg)
                hlbl.BackgroundTransparency = 1
                hlbl.Size = UDim2.new(1, 0, 1, 0)
                hlbl.Font = Enum.Font.GothamBold
                hlbl.TextColor3 = Color3.new(1, 1, 1)
                hlbl.TextSize = 10
                hlbl.TextStrokeTransparency = 0.3
                task.spawn(function()
                    while bar.Parent and player.Character and hum.Parent do
                        pcall(function()
                            local pct = hum.Health / hum.MaxHealth
                            bar.Size = UDim2.new(pct, 0, 1, 0)
                            bar.BackgroundColor3 = pct > 0.6 and Color3.fromRGB(100, 255, 100)
                                or pct > 0.3 and Color3.fromRGB(255, 200, 0)
                                or Color3.fromRGB(255, 50, 50)
                            hlbl.Text = string.format("%.0f/%.0f", hum.Health, hum.MaxHealth)
                        end)
                        task.wait(0.15)
                    end
                end)
                yOff += 20
            end
        end

        if ESPConfig.ShowDistance then
            local dl = Instance.new("TextLabel", bb)
            dl.BackgroundTransparency = 1
            dl.Position = UDim2.new(0, 0, 0, yOff)
            dl.Size = UDim2.new(1, 0, 0, 16)
            dl.Font = Enum.Font.Gotham
            dl.TextColor3 = Color3.fromRGB(150, 200, 255)
            dl.TextSize = 11; dl.TextStrokeTransparency = 0.3
            task.spawn(function()
                while dl.Parent and player.Character do
                    pcall(function()
                        if Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = getCachedDistance(
                                player.Character.HumanoidRootPart.Position,
                                Client.Character.HumanoidRootPart.Position,
                                player
                            )
                            dl.Text = string.format("%.0f m", dist)
                        end
                    end)
                    task.wait(ESPConfig.UpdateInterval)
                end
            end)
        end

        table.insert(objects, bb)
    end

    -- Tracer
    if ESPConfig.ShowTracers then
        local tracer = Drawing.new("Line")
        tracer.Visible = false; tracer.Color = color
        tracer.Thickness = math.min(ESPConfig.MaxTracerThickness, 2.5)
        tracer.Transparency = 0.8
        table.insert(objects, tracer)
        task.spawn(function()
            while tracer and player.Character do
                pcall(function()
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local sp, onScreen = worldToScreen(hrp.Position)
                        if onScreen then
                            local startY = ESPConfig.TracerOrigin == "Top" and 0
                                or ESPConfig.TracerOrigin == "Middle" and Client.Camera.ViewportSize.Y / 2
                                or Client.Camera.ViewportSize.Y
                            tracer.From = Vector2.new(Client.Camera.ViewportSize.X / 2, startY)
                            tracer.To = sp; tracer.Visible = true
                            tracer.Color = getColor(player)
                        else tracer.Visible = false end
                    end
                end)
                task.wait(0.03)
            end
        end)
    end

    ESPObjects[player] = objects
end

function ESPSystem.UpdateAll(filterFn)
    for _, player in pairs(Services.Players:GetPlayers()) do
        if ESPConfig.Enabled and (not filterFn or filterFn(player)) then
            if not ESPObjects[player] and player.Character then ESPSystem.Create(player) end
        else ESPSystem.Remove(player) end
    end
end

function ESPSystem.Initialize(filterFn)
    Services.Players.PlayerAdded:Connect(function(player)
        task.wait(1)
        if ESPConfig.Enabled then ESPSystem.Create(player) end
    end)
    Services.Players.PlayerRemoving:Connect(ESPSystem.Remove)
    task.spawn(function()
        while true do task.wait(1); ESPSystem.UpdateAll(filterFn) end
    end)
end

-- Expose config so UI can mutate it
ESPSystem.Config = ESPConfig

return ESPSystem
