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
}

local ESPObjects = {}

local function getColor(player)
    if ESPConfig.UseTeamColors and player.Team then
        return player.Team.TeamColor.Color
    end
    return ESPConfig.Color
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
                bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); bg.BorderSizePixel = 0
                bg.Position = UDim2.new(0.1, 0, 0, yOff); bg.Size = UDim2.new(0.8, 0, 0, 8)
                local bar = Instance.new("Frame", bg)
                bar.BackgroundColor3 = Color3.fromRGB(100, 255, 100); bar.BorderSizePixel = 0
                bar.Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 1, 0)
                task.spawn(function()
                    while bar.Parent and player.Character do
                        pcall(function()
                            local pct = hum.Health / hum.MaxHealth
                            bar.Size = UDim2.new(pct, 0, 1, 0)
                            bar.BackgroundColor3 = pct > 0.6 and Color3.fromRGB(100, 255, 100)
                                or pct > 0.3 and Color3.fromRGB(255, 200, 0)
                                or Color3.fromRGB(255, 50, 50)
                        end)
                        task.wait(0.1)
                    end
                end)
                yOff += 12
            end
        end

        if ESPConfig.ShowDistance then
            local dl = Instance.new("TextLabel", bb)
            dl.BackgroundTransparency = 1
            dl.Position = UDim2.new(0, 0, 0, yOff)
            dl.Size = UDim2.new(1, 0, 0, 20)
            dl.Font = Enum.Font.Gotham
            dl.TextColor3 = Color3.fromRGB(200, 200, 200)
            dl.TextSize = 12; dl.TextStrokeTransparency = 0.5
            task.spawn(function()
                while dl.Parent and player.Character do
                    pcall(function()
                        if Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") then
                            dl.Text = string.format("[%.0fm]", getDistance(
                                player.Character.HumanoidRootPart.Position,
                                Client.Character.HumanoidRootPart.Position
                            ))
                        end
                    end)
                    task.wait(0.2)
                end
            end)
        end

        table.insert(objects, bb)
    end

    -- Tracer
    if ESPConfig.ShowTracers then
        local tracer = Drawing.new("Line")
        tracer.Visible = true; tracer.Color = color
        tracer.Thickness = 2; tracer.Transparency = 0.7
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
                        else tracer.Visible = false end
                    end
                end)
                task.wait(0.05)
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
