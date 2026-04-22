-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN: ABSOLUTE ZERO (DISTANCIA 0)
local settings = {
    force = 4000, -- Fuerza extrema para evitar desprendimientos
    radius = 800,
    prediction = 0.05, -- Reducido para que sea casi pegado al presente
    maxParts = 200, 
    scanRate = 0.1,
    targetName = ""
}

local parts = {}
local targetPlayer = nil
local enabled = false
local lastScan = 0

-- NETWORK (BYPASS AGRESIVO)
task.spawn(function()
    while true do
        if enabled then
            pcall(function()
                sethiddenproperty(player, "SimulationRadius", 1e10)
                sethiddenproperty(player, "MaxSimulationRadius", 1e10)
            end)
        end
        task.wait(0.1)
    end
end)

-- INTERFAZ (ESTABLE PARA ESTA VERSIÓN)
local gui = Instance.new("ScreenGui")
gui.Name = "Zero_System"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(255, 255, 255); stroke.Thickness = 2

local mainItems = Instance.new("Frame", frame)
mainItems.Size = UDim2.new(1, 0, 1, -35); mainItems.Position = UDim2.new(0, 0, 0, 35); mainItems.BackgroundTransparency = 1

local huntBtn = Instance.new("TextButton", mainItems)
huntBtn.Size = UDim2.new(0.9, 0, 0, 50); huntBtn.Position = UDim2.new(0.05, 0, 0, 65)
huntBtn.Text = "ZERO DISTANCE: OFF"; huntBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
huntBtn.TextColor3 = Color3.new(1,1,1); huntBtn.Font = Enum.Font.GothamBlack; huntBtn.TextSize = 14
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

local targetBox = Instance.new("TextBox", mainItems)
targetBox.Size = UDim2.new(0.9, 0, 0, 35); targetBox.Position = UDim2.new(0.05, 0, 0, 15)
targetBox.PlaceholderText = "VICTIM NAME..."; targetBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
targetBox.TextColor3 = Color3.fromRGB(255, 255, 255); targetBox.Font = Enum.Font.Code; targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

-- ESCANEO DE PIEZAS
local function getParts()
    if tick() - lastScan < settings.scanRate then return parts end
    lastScan = tick()
    local found = {}
    local op = OverlapParams.new(); op.FilterDescendantsInstances = {character}; op.FilterType = Enum.RaycastFilterType.Exclude
    local nearby = workspace:GetPartBoundsInRadius(character:GetPivot().Position, settings.radius, op)
    for _, v in ipairs(nearby) do
        if #found >= settings.maxParts then break end
        if v:IsA("BasePart") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") then
            v.Massless = true
            v.CanCollide = false -- False para que penetren su cuerpo y lo asfixien
            v.Velocity = Vector3.new(0,0,0)
            table.insert(found, v)
        end
    end
    parts = found; return parts
end

-- LÓGICA DE FIJACIÓN TOTAL (DISTANCIA 0)
RunService.Heartbeat:Connect(function()
    if not enabled or not targetPlayer or not targetPlayer.Character then return end
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local currentParts = getParts()
    local targetPos = hrp.Position -- Posición exacta actual

    for _, part in ipairs(currentParts) do
        if part.Parent then
            -- Forzamos la velocidad para que la distancia sea 0 en el siguiente frame
            -- La fórmula (TargetPos - PartPos) / DT da la velocidad necesaria para llegar YA
            local deltaPos = (targetPos - part.Position)
            
            -- Aplicamos una velocidad que lo mantenga pegado al centro del enemigo
            part.AssemblyLinearVelocity = deltaPos * 60 + (hrp.Velocity)
            
            -- Rotación frenética para daño e imposibilidad de reset
            part.AssemblyAngularVelocity = Vector3.new(500, 500, 500) 
        end
    end
end)

huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                targetPlayer = p; enabled = true; huntBtn.Text = "ZERO DISTANCE: ON"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                return
            end
        end
    else
        enabled = false; huntBtn.Text = "ZERO DISTANCE: OFF"; huntBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end)
