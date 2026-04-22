-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN
local settings = {
    force = 2000,
    radius = 700,
    prediction = 0.12, 
    maxParts = 140, 
    scanRate = 0.2,
    safeDistance = 25,
    orbitDist = 0.2,
    rotationSpeed = 10,
    selfSpinSpeed = 500
}

local parts = {}
local targetPlayer = nil
local enabled = false
local lastScan = 0
local angle = 0 
local kills = 0 
local lastTargetName = "" -- Para detectar cambios de objetivo

-- NETWORK
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

-- INTERFAZ VERDE
local gui = Instance.new("ScreenGui")
gui.Name = "FocusPart_Persistent_Lock"
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
titleLabel.Text = "SYSTEM // TARGET-LOCK"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local killCounter = Instance.new("TextLabel", frame)
killCounter.Size = UDim2.new(0, 80, 0, 20)
killCounter.Position = UDim2.new(1, -90, 0, 40)
killCounter.BackgroundTransparency = 1
killCounter.Text = "KILLS: 0"
killCounter.TextColor3 = Color3.fromRGB(0, 255, 120)
killCounter.Font = Enum.Font.Code
killCounter.TextSize = 12
killCounter.TextXAlignment = Enum.TextXAlignment.Right

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

-- ARRASTRAR
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
targetBox.PlaceholderText = "ID / NAME / 3 LETTERS"; targetBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
targetBox.TextColor3 = Color3.fromRGB(0, 255, 120); targetBox.Font = Enum.Font.Code; targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

local huntBtn = Instance.new("TextButton", mainItems)
huntBtn.Size = UDim2.new(0.9, 0, 0, 50); huntBtn.Position = UDim2.new(0.05, 0, 0, 65)
huntBtn.Text = "READY TO SCAN"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
huntBtn.TextColor3 = Color3.fromRGB(0, 255, 120); huntBtn.Font = Enum.Font.GothamBlack; huntBtn.TextSize = 16
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel", mainItems)
status.Size = UDim2.new(1, 0, 0, 20); status.Position = UDim2.new(0, 0, 1, -25)
status.BackgroundTransparency = 1; status.Text = "SYSTEM IDLE"; status.TextColor3 = Color3.fromRGB(100, 100, 100)
status.Font = Enum.Font.Code; status.TextSize = 10

-- MUERTE DETECTADA (Lógica persistente)
local hasDied = false
RunService.Heartbeat:Connect(function(dt)
    if not enabled or not targetPlayer then return end
    
    local char = targetPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    -- Detectar muerte sin apagar el script
    if hum and hum.Health <= 0 and not hasDied then
        hasDied = true
        kills = kills + 1
        killCounter.Text = "KILLS: " .. tostring(kills)
        status.Text = "TARGET DEAD - WAITING RESPAWN"
    elseif hum and hum.Health > 0 and hasDied then
        hasDied = false
        status.Text = "TARGET RESPAWNED - RELOCKING"
    end

    -- Si el objetivo no tiene cuerpo (esta muerto o cargando), no movemos piezas
    if not hrp or hasDied then return end

    angle = angle + (dt * settings.rotationSpeed)
    local pPos = hrp.Position + (hrp.Velocity * settings.prediction)
    
    -- Movimiento de piezas (Filtro de piezas activado solo si enabled)
    local op = OverlapParams.new(); op.FilterDescendantsInstances = {character}; op.FilterType = Enum.RaycastFilterType.Exclude
    local nearby = workspace:GetPartBoundsInRadius(character:GetPivot().Position, settings.radius, op)
    local count = 0
    for _, part in ipairs(nearby) do
        if count >= settings.maxParts then break end
        if part:IsA("BasePart") and not part.Anchored and part.CanCollide and not part.Parent:FindFirstChild("Humanoid") then
            part.Massless = true; part.CanTouch = false
            
            local offsetAngle = angle + (count * (math.pi * 2 / 20)) -- 20 es un divisor visual
            local targetOrbitPos = pPos + Vector3.new(math.cos(offsetAngle) * settings.orbitDist, (count % 3) - 1, math.sin(offsetAngle) * settings.orbitDist)
            local direction = (targetOrbitPos - part.Position)
            
            part.AssemblyLinearVelocity = direction.Unit * settings.force + (hrp.Velocity * 1.1)
            part.AssemblyAngularVelocity = Vector3.new(settings.selfSpinSpeed, settings.selfSpinSpeed, settings.selfSpinSpeed)
            count = count + 1
        end
    end
end)

-- BOTÓN DE ATAQUE CON RESET DE KILLS
huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                -- Si es un objetivo nuevo, reiniciamos contador
                if lastTargetName ~= p.Name then
                    kills = 0
                    killCounter.Text = "KILLS: 0"
                    lastTargetName = p.Name
                end
                
                targetPlayer = p; enabled = true
                huntBtn.Text = "LOCK-ON: " .. p.Name:upper(); huntBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                status.Text = "PERSISTENT TRACKING ACTIVE"
                return
            end
        end
    else
        enabled = false; huntBtn.Text = "READY TO SCAN"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10); status.Text = "SYSTEM IDLE"
    end
end)

close.MouseButton1Click:Connect(function() enabled = false; gui:Destroy() end)
player.CharacterAdded:Connect(function(c) character = c end)
