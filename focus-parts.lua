-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN DINÁMICA
local settings = {
    force = 1600,
    radius = 280,
    prediction = 0.18, 
    maxParts = 85, -- Optimizado para balance de daño/lag
    scanRate = 0.25,
    targetName = ""
}

local parts = {}
local targetPlayer = nil
local enabled = false
local lastScan = 0

-- SEGURIDAD: NETWORK OWNER JITTER (Menos detectable)
task.spawn(function()
    while task.wait(0.2) do
        if enabled then
            pcall(function()
                -- Varía el radio ligeramente para engañar escaneos estáticos del Anti-Cheat
                local jitter = math.random(100, 500)
                sethiddenproperty(player, "SimulationRadius", 1e8 + jitter)
                sethiddenproperty(player, "MaxSimulationRadius", 1e8 + jitter)
            end)
        end
    end
end)

-- INTERFAZ MODERNA (NEGRO/VERDE)
local gui = Instance.new("ScreenGui")
gui.Name = "FocusPartV4_Final"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 200)
frame.Position = UDim2.new(0.5, -130, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local uiStroke = Instance.new("UIStroke", frame)
uiStroke.Color = Color3.fromRGB(0, 255, 120)
uiStroke.Thickness = 1.8

-- BARRA DE TÍTULO (FOCUS-PART)
local titleBar = Instance.new("TextLabel", frame)
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(15, 35, 15)
titleBar.Text = "   FOCUS-PART V4.1"
titleBar.TextColor3 = Color3.fromRGB(0, 255, 120)
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 13
titleBar.TextXAlignment = Enum.TextXAlignment.Left

-- BOTONES DE CONTROL
local function createTitleBtn(text, pos, color)
    local btn = Instance.new("TextButton", titleBar)
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.Position = pos
    btn.Text = text
    btn.TextColor3 = color
    btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    return btn
end

local minBtn = createTitleBtn("-", UDim2.new(1, -30, 0, 2), Color3.fromRGB(0, 255, 120))
local closeBtn = createTitleBtn("X", UDim2.new(1, -60, 0, 2), Color3.fromRGB(255, 80, 80))

-- MOVIMIENTO ARRASTRABLE
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = frame.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

-- CUADRO DE BÚSQUEDA
local targetBox = Instance.new("TextBox", frame)
targetBox.Size = UDim2.new(0.9, 0, 0, 32)
targetBox.Position = UDim2.new(0.05, 0, 0, 48)
targetBox.PlaceholderText = "Nombre (3+ letras)..."
targetBox.Text = ""
targetBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
targetBox.TextColor3 = Color3.fromRGB(0, 255, 120)
targetBox.Font = Enum.Font.Gotham
targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

-- BOTÓN DE ATAQUE
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0.9, 0, 0, 42)
toggleBtn.Position = UDim2.new(0.05, 0, 0, 95)
toggleBtn.Text = "INICIAR HUNT"
toggleBtn.BackgroundColor3 = Color3.fromRGB(10, 50, 10)
toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 15
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

-- LÓGICA DE AUTOCOMPLETADO Y BOTONES
local function getTarget()
    local text = targetBox.Text:lower()
    if #text >= 3 then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and (plr.Name:lower():find(text) or plr.DisplayName:lower():find(text)) then
                return plr
            end
        end
    end
    return nil
end

toggleBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local found = getTarget()
        if found then
            targetPlayer = found
            targetBox.Text = found.Name
            enabled = true
            toggleBtn.Text = "HUNTING: " .. found.Name:upper()
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 0, 0)
        else
            targetBox.Text = "¡No encontrado!"
            task.wait(1)
            targetBox.Text = ""
        end
    else
        enabled = false
        toggleBtn.Text = "INICIAR HUNT"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(10, 50, 10)
    end
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    frame:TweenSize(UDim2.new(0, 260, 0, minimized and 32 or 200), "Out", "Quad", 0.3, true)
    minBtn.Text = minimized and "+" or "-"
end)

closeBtn.MouseButton1Click:Connect(function()
    enabled = false
    gui:Destroy()
end)

-- SISTEMA DE FÍSICA MEJORADO (ANTI-GLITCH)
local function getParts()
    if tick() - lastScan < settings.scanRate then return parts end
    lastScan = tick()
    
    local found = {}
    local op = OverlapParams.new()
    op.FilterDescendantsInstances = {character, (targetPlayer and targetPlayer.Character)}
    op.FilterType = Enum.RaycastFilterType.Exclude

    local nearby = workspace:GetPartBoundsInRadius(character:GetPivot().Position, settings.radius, op)
    local count = 0
    for _, v in ipairs(nearby) do
        if count >= settings.maxParts then break end
        if v:IsA("BasePart") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") then
            -- Solo partes físicas reales (ignora efectos visuales o UI en el workspace)
            if v.Transparency < 1 and v.Size.Magnitude > 0.5 then
                v.CanCollide = false 
                v.Massless = true
                table.insert(found, v)
                count = count + 1
            end
        end
    end
    parts = found
    return parts
end

RunService.Heartbeat:Connect(function()
    if not enabled or not targetPlayer or not targetPlayer.Character then return end
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Predicción dinámica basada en velocidad del objetivo
    local pPos = hrp.Position + (hrp.Velocity * settings.prediction)
    local currentParts = getParts()

    for _, part in ipairs(currentParts) do
        if part.Parent then
            local vector = (pPos - part.Position)
            local dist = vector.Magnitude
            
            -- Aplicación de fuerza suavizada para mayor impacto físico
            -- Evita que las piezas se queden pegadas al suelo
            local lift = Vector3.new(0, 22, 0)
            part.AssemblyLinearVelocity = vector.Unit * settings.force + lift
            part.AssemblyAngularVelocity = Vector3.new(math.random(-15,15), math.random(-15,15), math.random(-15,15))
        end
    end
end)

player.CharacterAdded:Connect(function(c) character = c end)
