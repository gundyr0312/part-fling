-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN POTENCIADA
local settings = {
    force = 1800,
    radius = 450, -- RADIO AGRANDADO
    prediction = 0.22, 
    maxParts = 120, 
    scanRate = 0.3,
    targetName = ""
}

local parts = {}
local targetPlayer = nil
local enabled = false
local lastScan = 0

-- SEGURIDAD & NETWORK (RE-SYNC CONSTANTE)
task.spawn(function()
    while task.wait(0.1) do
        if enabled then
            pcall(function()
                settings.targetName = settings.targetName
                sethiddenproperty(player, "SimulationRadius", 1e9)
                sethiddenproperty(player, "MaxSimulationRadius", 1e10)
            end)
        end
    end
end)

-- INTERFAZ PROFESIONAL V4.2
local gui = Instance.new("ScreenGui")
gui.Name = "FocusPart_Ultra"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Borde Neón
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0, 255, 120)
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Barra Superior con Gradiente
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local gradient = Instance.new("UIGradient", titleBar)
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 60, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 15, 5))
}

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SYSTEM // FOCUS-PART"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Botones Control
local function createBtn(txt, x, color)
    local b = Instance.new("TextButton", titleBar)
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, x, 0.5, -14)
    b.Text = txt
    b.TextColor3 = color
    b.BackgroundTransparency = 1
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    return b
end

local close = createBtn("X", -32, Color3.fromRGB(255, 50, 50))
local min = createBtn("-", -62, Color3.fromRGB(0, 255, 120))

-- Arrastrar
local dragging, dStart, sPos
titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; dStart=i.Position; sPos=frame.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = i.Position - dStart
    frame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)

-- Input Box
local targetBox = Instance.new("TextBox", frame)
targetBox.Size = UDim2.new(0.9, 0, 0, 35)
targetBox.Position = UDim2.new(0.05, 0, 0, 50)
targetBox.PlaceholderText = "ID / NAME / 3 LETTERS"
targetBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
targetBox.TextColor3 = Color3.fromRGB(0, 255, 120)
targetBox.Font = Enum.Font.Code
targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

-- Botón Principal
local huntBtn = Instance.new("TextButton", frame)
huntBtn.Size = UDim2.new(0.9, 0, 0, 50)
huntBtn.Position = UDim2.new(0.05, 0, 0, 100)
huntBtn.Text = "READY TO SCAN"
huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
huntBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
huntBtn.Font = Enum.Font.GothamBlack
huntBtn.TextSize = 16
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

-- Status Label
local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 1, -25)
status.BackgroundTransparency = 1
status.Text = "SYSTEM IDLE"
status.TextColor3 = Color3.fromRGB(100, 100, 100)
status.Font = Enum.Font.Code
status.TextSize = 10

-- LÓGICA DE BÚSQUEDA
huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        if #t >= 3 then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                    targetPlayer = p
                    targetBox.Text = p.Name
                    enabled = true
                    huntBtn.Text = "ATTACKING: " .. p.Name:upper()
                    huntBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                    status.Text = "LOCK-ON ESTABLISHED"
                    return
                end
            end
        end
        status.Text = "ERROR: TARGET NOT FOUND"
    else
        enabled = false
        huntBtn.Text = "READY TO SCAN"
        huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
        status.Text = "SYSTEM IDLE"
    end
end)

-- LÓGICA DE FÍSICA MEJORADA
local function getParts()
    if tick() - lastScan < settings.scanRate then return parts end
    lastScan = tick()
    
    local found = {}
    local op = OverlapParams.new()
    op.FilterDescendantsInstances = {character}
    op.FilterType = Enum.RaycastFilterType.Exclude

    local nearby = workspace:GetPartBoundsInRadius(character:GetPivot().Position, settings.radius, op)
    local count = 0
    for _, v in ipairs(nearby) do
        if count >= settings.maxParts then break end
        -- FILTRO REAL: Solo partes que tengan colisión y no sean hijos de otros jugadores
        if v:IsA("BasePart") and not v.Anchored and v.CanCollide and not v.Parent:FindFirstChild("Humanoid") then
            -- "Despertar" la física (Truco para Network Ownership)
            v.Velocity = Vector3.new(0, 0.1, 0) 
            v.Massless = true
            table.insert(found, v)
            count = count + 1
        end
    end
    parts = found
    return parts
end

RunService.Heartbeat:Connect(function()
    if not enabled or not targetPlayer or not targetPlayer.Character then return end
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pPos = hrp.Position + (hrp.Velocity * settings.prediction)
    local currentParts = getParts()

    for _, part in ipairs(currentParts) do
        if part.Parent then
            local vector = (pPos - part.Position)
            -- Fuerza Dinámica: aumenta con la distancia
            local forceMag = settings.force + (vector.Magnitude * 2)
            part.AssemblyLinearVelocity = vector.Unit * forceMag + Vector3.new(0, 25, 0)
            part.AssemblyAngularVelocity = Vector3.new(math.random(-20,20), math.random(-20,20), math.random(-20,20))
        end
    end
end)

close.MouseButton1Click:Connect(function() gui:Destroy(); enabled = false end)
local minned = false
min.MouseButton1Click:Connect(function()
    minned = not minned
    frame:TweenSize(UDim2.new(0, 280, 0, minned and 35 or 220), "Out", "Quad", 0.3, true)
    min.Text = minned and "+" or "-"
end)

player.CharacterAdded:Connect(function(c) character = c end)
