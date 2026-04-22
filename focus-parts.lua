-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN: CENTRIFUGE OVERKILL
local settings = {
    force = 2500,         -- Fuerza de atracción
    radius = 700,
    prediction = 0.15, 
    maxParts = 150, 
    scanRate = 0.15,
    safeDistance = 30,    -- Radio de seguridad personal
    orbitDist = 1,        -- Distancia de órbita ultra pegada
    rotationSpeed = 35,   -- Velocidad del torbellino alrededor del enemigo
    selfSpinSpeed = 500   -- VELOCIDAD DE GIRO INDIVIDUAL (ABSURDA)
}

local parts = {}
local targetPlayer = nil
local enabled = false
local lastScan = 0
local angle = 0

-- NETWORK BYPASS
task.spawn(function()
    while true do
        if enabled then
            pcall(function()
                sethiddenproperty(player, "SimulationRadius", 1e10)
                sethiddenproperty(player, "MaxSimulationRadius", 1e10)
            end)
        end
        task.wait(0.5)
    end
end)

-- INTERFAZ (ESTABLE Y CORREGIDA)
local gui = Instance.new("ScreenGui")
gui.Name = "Centrifuge_System"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(255, 0, 50); stroke.Thickness = 2

local mainItems = Instance.new("Frame", frame)
mainItems.Size = UDim2.new(1, 0, 1, -35); mainItems.Position = UDim2.new(0, 0, 0, 35); mainItems.BackgroundTransparency = 1

local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 35); titleBar.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, 0, 1, 0); titleLabel.BackgroundTransparency = 1; titleLabel.Text = "SYSTEM // CENTRIFUGE"; titleLabel.TextColor3 = Color3.new(1,0,0); titleLabel.Font = Enum.Font.GothamBlack; titleLabel.TextSize = 12

local targetBox = Instance.new("TextBox", mainItems)
targetBox.Size = UDim2.new(0.9, 0, 0, 35); targetBox.Position = UDim2.new(0.05, 0, 0, 15)
targetBox.PlaceholderText = "TARGET NAME..."; targetBox.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
targetBox.TextColor3 = Color3.new(1,1,1); targetBox.Font = Enum.Font.Code; targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

local huntBtn = Instance.new("TextButton", mainItems)
huntBtn.Size = UDim2.new(0.9, 0, 0, 50); huntBtn.Position = UDim2.new(0.05, 0, 0, 65)
huntBtn.Text = "READY TO OBLITERATE"; huntBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0); huntBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel", mainItems)
status.Size = UDim2.new(1, 0, 0, 20); status.Position = UDim2.new(0, 0, 1, -25); status.BackgroundTransparency = 1; status.Text = "IDLE"; status.TextColor3 = Color3.new(0.5, 0.5, 0.5); status.TextSize = 10

-- LOGICA MINIMIZAR
local minBtn = Instance.new("TextButton", titleBar); minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -35, 0, 2.5); minBtn.Text = "-"; minBtn.TextColor3 = Color3.new(1,1,1); minBtn.BackgroundTransparency = 1

local minned = false
minBtn.MouseButton1Click:Connect(function()
    minned = not minned
    mainItems.Visible = not minned
    frame:TweenSize(UDim2.new(0, 280, 0, minned and 35 or 220), "Out", "Quad", 0.2, true)
    minBtn.Text = minned and "+" or "-"
end)

-- SISTEMA DE FÍSICA PESADA
local function getParts()
    if tick() - lastScan < settings.scanRate then return parts end
    lastScan = tick()
    local found = {}
    local op = OverlapParams.new(); op.FilterDescendantsInstances = {character}; op.FilterType = Enum.RaycastFilterType.Exclude
    local nearby = workspace:GetPartBoundsInRadius(character:GetPivot().Position, settings.radius, op)
    for _, v in ipairs(nearby) do
        if #found >= settings.maxParts then break end
        if v:IsA("BasePart") and not v.Anchored and v.CanCollide and not v.Parent:FindFirstChild("Humanoid") then
            v.Massless = true
            table.insert(found, v)
        end
    end
    parts = found; return parts
end

RunService.Heartbeat:Connect(function(dt)
    if not enabled or not targetPlayer or not targetPlayer.Character then return end
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = character:FindFirstChild("HumanoidRootPart")
    if not hrp or not myHRP then return end

    angle = angle + (dt * settings.rotationSpeed)
    local targetBasePos = hrp.Position + (hrp.Velocity * settings.prediction)
    local currentParts = getParts()

    for i, part in ipairs(currentParts) do
        if part.Parent then
            local distToMe = (part.Position - myHRP.Position).Magnitude
            
            -- 1. ANTI-DAMAGE / COUNTER (REFORZADO)
            if distToMe < settings.safeDistance then
                local counterDir = (hrp.Position - part.Position).Unit
                part.AssemblyLinearVelocity = counterDir * (settings.force * 3) + Vector3.new(0, 60, 0)
                status.Text = "DEFLECTING ATTACHMENTS"
                continue
            end

            -- 2. ÓRBITA Y GIRO INDIVIDUAL ABSURDO
            local offsetAngle = angle + (i * (math.pi * 2 / #currentParts))
            local targetOrbitPos = targetBasePos + Vector3.new(math.cos(offsetAngle) * settings.orbitDist, math.random(-1, 3), math.sin(offsetAngle) * settings.orbitDist)
            
            local direction = (targetOrbitPos - part.Position)
            
            -- Movimiento hacia la órbita + compensación de lag
            part.AssemblyLinearVelocity = direction * 25 + (hrp.Velocity * 1.3)
            
            -- GIRO EN SÍ MISMA (Velocidad masiva para empujar al tocar)
            part.AssemblyAngularVelocity = Vector3.new(settings.selfSpinSpeed, settings.selfSpinSpeed, settings.selfSpinSpeed)
            
            -- Impulso extra si el enemigo intenta volar/escapar
            if (hrp.Position - part.Position).Magnitude > 5 then
                part.AssemblyLinearVelocity = (hrp.Position - part.Position).Unit * settings.force
            end
        end
    end
end)

huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                targetPlayer = p; enabled = true; huntBtn.Text = "STOP OVERKILL"; status.Text = "VORTEX ON: " .. p.Name:upper()
                return
            end
        end
    else
        enabled = false; huntBtn.Text = "READY TO OBLITERATE"; status.Text = "IDLE"
    end
end)

player.CharacterAdded:Connect(function(c) character = c end)
