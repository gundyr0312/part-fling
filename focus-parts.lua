-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN DE COMBATE PESADO
local settings = {
    force = 3500,          -- Fuerza aumentada para contrarrestar Flings
    radius = 800,
    prediction = 0.1, 
    maxParts = 150, 
    scanRate = 0.1,        -- Escaneo más rápido
    safeDistance = 20,
    orbitDist = 0.15,      -- Casi pegado a la piel del objetivo
    rotationSpeed = 15,    -- Órbita más rápida
    selfSpinSpeed = 1000   -- Giro extremo para máximo daño físico
}

local parts = {}
local targetPlayer = nil
local enabled = false
local lastScan = 0
local angle = 0 
local kills = 0 
local lastTargetName = ""

-- NETWORK (BYPASS)
task.spawn(function()
    while true do
        if enabled then
            pcall(function()
                sethiddenproperty(player, "SimulationRadius", math.huge)
                sethiddenproperty(player, "MaxSimulationRadius", math.huge)
            end)
        end
        task.wait(0.1)
    end
end)

-- INTERFAZ
local gui = Instance.new("ScreenGui")
gui.Name = "Focus_Heavy_Combat"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0, 255, 120)
stroke.Thickness = 2

local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SYSTEM // OVERKILL-V2"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- CONTADOR ABAJO
local killCounter = Instance.new("TextLabel", frame)
killCounter.Size = UDim2.new(1, 0, 0, 20)
killCounter.Position = UDim2.new(0, 0, 1, -45) -- Encima del status
killCounter.BackgroundTransparency = 1
killCounter.Text = "TARGET KILLS: 0"
killCounter.TextColor3 = Color3.fromRGB(255, 255, 255)
killCounter.Font = Enum.Font.Code
killCounter.TextSize = 13

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

-- ARRASTRAR PANEL
local dragging, dStart, sPos
titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; dStart=i.Position; sPos=frame.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = i.Position - dStart
    frame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)

local mainItems = Instance.new("Frame", frame)
mainItems.Size = UDim2.new(1, 0, 1, -35)
mainItems.Position = UDim2.new(0, 0, 0, 35)
mainItems.BackgroundTransparency = 1

local targetBox = Instance.new("TextBox", mainItems)
targetBox.Size = UDim2.new(0.9, 0, 0, 35); targetBox.Position = UDim2.new(0.05, 0, 0, 15)
targetBox.PlaceholderText = "HACKER NAME..."; targetBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
targetBox.TextColor3 = Color3.fromRGB(0, 255, 120); targetBox.Font = Enum.Font.Code; targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

local huntBtn = Instance.new("TextButton", mainItems)
huntBtn.Size = UDim2.new(0.9, 0, 0, 50); huntBtn.Position = UDim2.new(0.05, 0, 0, 65)
huntBtn.Text = "SCAN TARGET"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
huntBtn.TextColor3 = Color3.fromRGB(0, 255, 120); huntBtn.Font = Enum.Font.GothamBlack; huntBtn.TextSize = 16
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel", mainItems)
status.Size = UDim2.new(1, 0, 0, 20); status.Position = UDim2.new(0, 0, 1, -25)
status.BackgroundTransparency = 1; status.Text = "SYSTEM IDLE"; status.TextColor3 = Color3.fromRGB(100, 100, 100)
status.Font = Enum.Font.Code; status.TextSize = 10

-- LÓGICA MINIMIZAR (FIXED)
local minned = false
min.MouseButton1Click:Connect(function()
    minned = not minned
    mainItems.Visible = not minned
    min.Text = minned and "+" or "-"
    frame:TweenSize(UDim2.new(0, 280, 0, minned and 35 or 220), "Out", "Quad", 0.2, true)
end)

-- SISTEMA DE FÍSICA PESADA
local function getParts()
    if not enabled then return {} end
    if tick() - lastScan < settings.scanRate then return parts end
    lastScan = tick()
    local found = {}
    local pPos = character:GetPivot().Position
    local nearby = workspace:GetPartBoundsInRadius(pPos, settings.radius)
    for _, v in ipairs(nearby) do
        if #found >= settings.maxParts then break end
        if v:IsA("BasePart") and not v.Anchored and v.CanCollide and not v.Parent:FindFirstChild("Humanoid") then
            v.Massless = true
            table.insert(found, v)
        end
    end
    parts = found; return parts
end

local hasDied = false
RunService.Heartbeat:Connect(function(dt)
    if not enabled or not targetPlayer then return end
    
    local char = targetPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head"))
    local hum = char and char:FindFirstChild("Humanoid")
    
    -- CONTADOR DE KILLS PERSISTENTE
    if hum then
        if hum.Health <= 0 and not hasDied then
            hasDied = true
            kills = kills + 1
            killCounter.Text = "TARGET KILLS: " .. tostring(kills)
        elseif hum.Health > 0 and hasDied then
            hasDied = false
        end
    end

    -- SI EL HACKER NO TIENE HRP, BUSCAMOS CUALQUIER PARTE DE SU CUERPO
    if not hrp then return end

    angle = angle + (dt * settings.rotationSpeed)
    local pPos = hrp.Position + (hrp.Velocity * settings.prediction)
    local currentParts = getParts()

    for i, part in ipairs(currentParts) do
        if part.Parent then
            local offsetAngle = angle + (i * (math.pi * 2 / #currentParts))
            local targetOrbitPos = pPos + Vector3.new(math.cos(offsetAngle) * settings.orbitDist, (i % 5) - 2, math.sin(offsetAngle) * settings.orbitDist)
            
            local direction = (targetOrbitPos - part.Position)
            
            -- FUERZA BRUTA PARA ANULAR FLING
            -- Usamos una fuerza proporcional a la distancia: mientras más lejos lo mande el fling, más rápido vuelve
            local forceMultiplier = math.clamp(direction.Magnitude * 2, 1, 5)
            part.AssemblyLinearVelocity = direction.Unit * (settings.force * forceMultiplier) + (hrp.Velocity * 1.5)
            part.AssemblyAngularVelocity = Vector3.new(settings.selfSpinSpeed, settings.selfSpinSpeed, settings.selfSpinSpeed)
        end
    end
end)

-- BOTÓN DE ACTIVACIÓN
huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        if #t >= 3 then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                    if lastTargetName ~= p.Name then
                        kills = 0
                        killCounter.Text = "TARGET KILLS: 0"
                        lastTargetName = p.Name
                    end
                    targetPlayer = p; enabled = true
                    huntBtn.Text = "HUNTING: " .. p.Name:upper()
                    huntBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                    status.Text = "TARGET LOCKED - IGNORING GODMODE"
                    return
                end
            end
        end
        status.Text = "TARGET NOT FOUND"
    else
        enabled = false; huntBtn.Text = "SCAN TARGET"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10); status.Text = "SYSTEM IDLE"
    end
end)

close.MouseButton1Click:Connect(function() enabled = false; gui:Destroy() end)
player.CharacterAdded:Connect(function(c) character = c end)
