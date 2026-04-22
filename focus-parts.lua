-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN DINÁMICA V4.3
local settings = {
    force = 2000,
    radius = 500, -- Radio máximo de recolección
    returnDist = 50, -- Si la pieza se aleja más de esto del objetivo, regresa
    prediction = 0.2, 
    maxParts = 100, 
    scanRate = 0.3,
    targetName = ""
}

local parts = {}
local targetPlayer = nil
local enabled = false
local lastScan = 0

-- SEGURIDAD & NETWORK
task.spawn(function()
    while task.wait(0.1) do
        if enabled then
            pcall(function()
                sethiddenproperty(player, "SimulationRadius", 1e10)
                sethiddenproperty(player, "MaxSimulationRadius", 1e10)
            end)
        end
    end
end)

-- INTERFAZ PROFESIONAL CORREGIDA
local gui = Instance.new("ScreenGui")
gui.Name = "FocusPart_Ultimate"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true -- ARREGLO PARA EL BUG VISUAL
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0, 255, 120)
stroke.Thickness = 2

-- Contenedor de elementos (para ocultar al minimizar)
local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -35)
content.Position = UDim2.new(0, 0, 0, 35)
content.BackgroundTransparency = 1
content.Name = "Content"

-- Barra Superior
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(15, 35, 15)
titleBar.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "FOCUS-PART // STABLE"
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

-- Input Box (Dentro de content)
local targetBox = Instance.new("TextBox", content)
targetBox.Size = UDim2.new(0.9, 0, 0, 35)
targetBox.Position = UDim2.new(0.05, 0, 0, 15)
targetBox.PlaceholderText = "TARGET NAME..."
targetBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
targetBox.TextColor3 = Color3.fromRGB(0, 255, 120)
targetBox.Font = Enum.Font.Code
targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

-- Botón Principal (Dentro de content)
local huntBtn = Instance.new("TextButton", content)
huntBtn.Size = UDim2.new(0.9, 0, 0, 50)
huntBtn.Position = UDim2.new(0.05, 0, 0, 65)
huntBtn.Text = "READY TO SCAN"
huntBtn.BackgroundColor3 = Color3.fromRGB(0, 25, 10)
huntBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
huntBtn.Font = Enum.Font.GothamBlack
huntBtn.TextSize = 16
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

-- Lógica de Búsqueda
huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        if #t >= 3 then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                    targetPlayer = p
                    targetBox.Text = p.Name
                    enabled = true
                    huntBtn.Text = "LOCK-ON: " .. p.Name:upper()
                    huntBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
                    return
                end
            end
        end
    else
        enabled = false
        huntBtn.Text = "READY TO SCAN"
        huntBtn.BackgroundColor3 = Color3.fromRGB(0, 25, 10)
    end
end)

-- Minimizar corregido
local minned = false
min.MouseButton1Click:Connect(function()
    minned = not minned
    content.Visible = not minned -- OCULTA EL CONTENIDO PARA QUE NO HAYA BUGS
    frame:TweenSize(UDim2.new(0, 280, 0, minned and 35 or 220), "Out", "Quad", 0.2, true)
    min.Text = minned and "+" or "-"
end)

close.MouseButton1Click:Connect(function() gui:Destroy(); enabled = false end)

-- LÓGICA DE FÍSICA "BOOMERANG"
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
        if v:IsA("BasePart") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") then
            v.CanCollide = false
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
            local toTarget = (pPos - part.Position)
            local distFromTarget = toTarget.Magnitude
            
            -- LÓGICA DE REBORTE/BOOMERANG
            -- Si la pieza está muy lejos del objetivo, le aplicamos una fuerza extrema para que regrese
            local returnMultiplier = 1
            if distFromTarget > settings.returnDist then
                returnMultiplier = 1.5 -- Aumenta la fuerza si se está escapando
            end

            part.AssemblyLinearVelocity = toTarget.Unit * (settings.force * returnMultiplier) + Vector3.new(0, 20, 0)
            part.AssemblyAngularVelocity = Vector3.new(math.random(-30,30), math.random(-30,30), math.random(-30,30))
        end
    end
end)

player.CharacterAdded:Connect(function(c) character = c end)
