-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN: CENTRIFUGE OVERKILL (DISTANCIA 1)
local settings = {
    force = 2500,
    radius = 700,
    prediction = 0.18, 
    maxParts = 130, 
    scanRate = 0.2,
    safeDistance = 25,
    orbitDist = 1,        -- Órbita pegada
    rotationSpeed = 30,   -- Giro del torbellino
    selfSpinSpeed = 500   -- Giro individual masivo
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

-- INTERFAZ VERDE ORIGINAL (CORREGIDA)
local gui = Instance.new("ScreenGui")
gui.Name = "FocusPart_Classic_Vortex"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0, 255, 120)
stroke.Thickness = 2

-- BARRA DE TÍTULO MOVIBLE
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

-- BOTONES X Y -
local function createBtn(txt, x, color)
    local b = Instance.new("TextButton", titleBar)
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, x, 0.5, -14)
    b.Text = txt; b.TextColor3 = color
    b.BackgroundTransparency = 1; b.Font = Enum.Font.GothamBold; b.TextSize = 16
    return b
end

local close = createBtn("X", -32, Color3.fromRGB(255, 50, 50))
local min = createBtn("-", -62, Color3.fromRGB(0, 255, 120))

-- ARRASTRAR LÓGICA
local dragging, dStart, sPos
titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; dStart=i.Position; sPos=frame.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = i.Position - dStart
    frame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)

-- CONTENEDOR (PARA EVITAR BUGS AL MINIMIZAR)
local mainItems = Instance.new("Frame", frame)
mainItems.Size = UDim2.new(1, 0, 1, -35)
mainItems.Position = UDim2.new(0, 0, 0, 35)
mainItems.BackgroundTransparency = 1

local targetBox = Instance.new("TextBox", mainItems)
targetBox.Size = UDim2.new(0.9, 0, 0, 35); targetBox.Position = UDim2.new(0.05, 0, 0, 15)
targetBox.PlaceholderText = "ID / NAME / 3 LETTERS"; targetBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
targetBox.TextColor3 = Color3.fromRGB(0, 255, 120); targetBox.Font = Enum.Font.Code; targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

local huntBtn = Instance.new("TextButton", mainItems)
huntBtn.Size = UDim2.new(0.9, 0, 0, 50); huntBtn.Position = UDim2.new(0.05, 0, 0, 65)
huntBtn.Text = "READY TO SCAN"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
huntBtn.TextColor3 = Color3.fromRGB(0, 255, 120); huntBtn.Font = Enum.Font.GothamBlack; huntBtn.TextSize = 16
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel", mainItems)
status.Size = UDim2.new(1, 0, 0, 20); status.Position = UDim2.new(0, 0, 1, -25); status.BackgroundTransparency = 1
status.Text = "SYSTEM IDLE"; status.TextColor3 = Color3.fromRGB(100, 100, 100); status.Font = Enum.Font.Code; status.TextSize = 10

-- LÓGICA DE MINIMIZAR ESTABLE
local minned = false
min.MouseButton1Click:Connect(function()
    minned = not minned
    if minned then
        mainItems.Visible = false
        frame:TweenSize(UDim2.new(0, 280, 0, 35), "Out", "Quad", 0.2, true)
        min.Text = "+"
    else
        frame:TweenSize(UDim2.new(0, 280, 0, 220), "Out", "Quad", 0.2, true, function() mainItems.Visible = true end)
        min.Text = "-"
    end
end)

-- ESCANEO
local function getParts()
    if tick() - lastScan < settings.scanRate then return parts end
    lastScan = tick()
    local found = {}
    local op = OverlapParams.new(); op.FilterDescendantsInstances = {character}; op.FilterType = Enum.RaycastFilterType.Exclude
    local nearby = workspace:GetPartBoundsInRadius(character:GetPivot().Position, settings.radius, op)
    for _, v in ipairs(nearby) do
        if #found >= settings.maxParts then break end
        if v:IsA("BasePart") and not v.Anchored and v.CanCollide and not v.Parent:FindFirstChild("Humanoid") then
            v.Massless = true; v.CanTouch = false
            table.insert(found, v)
        end
    end
    parts = found; return parts
end

-- HEARTBEAT: FÍSICA CENTRIFUGADORA
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
            
            -- CONTRAATAQUE (SIEMPRE ACTIVO)
            if distToMe < settings.safeDistance then
                local counterDir = (hrp.Position - part.Position).Unit
                part.AssemblyLinearVelocity = counterDir * (settings.force * 2.5) + Vector3.new(0, 50, 0)
                continue
            end

            -- ÓRBITA DISTANCIA 1 + GIRO MASIVO INDIVIDUAL
            local offsetAngle = angle + (i * (math.pi * 2 / #currentParts))
            local targetOrbitPos = targetBasePos + Vector3.new(math.cos(offsetAngle) * settings.orbitDist, math.random(-1, 3), math.sin(offsetAngle) * settings.orbitDist)
            
            local direction = (targetOrbitPos - part.Position)
            
            -- Fuerza centrífuga y seguimiento
            part.AssemblyLinearVelocity = direction * 30 + (hrp.Velocity * 1.3)
            part.AssemblyAngularVelocity = Vector3.new(settings.selfSpinSpeed, settings.selfSpinSpeed, settings.selfSpinSpeed)
            
            -- Asegurar que no se despeguen si el objetivo corre
            if direction.Magnitude > 4 then
                part.AssemblyLinearVelocity = direction.Unit * settings.force
            end
        end
    end
end)

-- BOTÓN DE ATAQUE
huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                targetPlayer = p; targetBox.Text = p.Name; enabled = true
                huntBtn.Text = "STOP OBLITERATION"; huntBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                status.Text = "LOCK-ON: " .. p.Name:upper()
                return
            end
        end
        status.Text = "TARGET NOT FOUND"
    else
        enabled = false; huntBtn.Text = "READY TO SCAN"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10); status.Text = "SYSTEM IDLE"
    end
end)

close.MouseButton1Click:Connect(function() enabled = false; gui:Destroy() end)
player.CharacterAdded:Connect(function(c) character = c end)
