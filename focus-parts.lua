-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN DINÁMICA V4.4
local settings = {
    force = 2200,
    radius = 550,
    prediction = 0.18, 
    maxParts = 90, 
    scanRate = 0.3,
    pauseTime = 1.8, -- Tiempo que se queda la pieza tras el impacto
    targetName = ""
}

local parts = {}
local partData = {} -- Diccionario para guardar el estado de cada pieza
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

-- INTERFAZ (Manteniendo tu estética profesional)
local gui = Instance.new("ScreenGui")
gui.Name = "FocusPart_Magneto"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(0, 255, 120); stroke.Thickness = 2

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -35); content.Position = UDim2.new(0, 0, 0, 35); content.BackgroundTransparency = 1

local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 35); titleBar.BackgroundColor3 = Color3.fromRGB(10, 30, 10); titleBar.BorderSizePixel = 0
local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -70, 1, 0); titleLabel.Position = UDim2.new(0, 12, 0, 0); titleLabel.BackgroundTransparency = 1
titleLabel.Text = "FOCUS-PART // MAGNETO"; titleLabel.TextColor3 = Color3.fromRGB(0, 255, 120); titleLabel.Font = Enum.Font.GothamBlack; titleLabel.TextSize = 12; titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Botones Control
local function createBtn(txt, x, color)
    local b = Instance.new("TextButton", titleBar); b.Size = UDim2.new(0, 28, 0, 28); b.Position = UDim2.new(1, x, 0.5, -14)
    b.Text = txt; b.TextColor3 = color; b.BackgroundTransparency = 1; b.Font = Enum.Font.GothamBold; b.TextSize = 16; return b
end
local close = createBtn("X", -32, Color3.fromRGB(255, 50, 50))
local min = createBtn("-", -62, Color3.fromRGB(0, 255, 120))

-- Funciones de UI (Arrastrar/Minimizar)
local dragging, dStart, sPos
titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; dStart=i.Position; sPos=frame.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = i.Position - dStart
    frame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)

local targetBox = Instance.new("TextBox", content)
targetBox.Size = UDim2.new(0.9, 0, 0, 35); targetBox.Position = UDim2.new(0.05, 0, 0, 15); targetBox.PlaceholderText = "TARGET NAME..."; targetBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15); targetBox.TextColor3 = Color3.fromRGB(0, 255, 120); targetBox.Font = Enum.Font.Code; targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

local huntBtn = Instance.new("TextButton", content)
huntBtn.Size = UDim2.new(0.9, 0, 0, 50); huntBtn.Position = UDim2.new(0.05, 0, 0, 65); huntBtn.Text = "INITIALIZE MAGNETO"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 20, 5); huntBtn.TextColor3 = Color3.fromRGB(0, 255, 120); huntBtn.Font = Enum.Font.GothamBlack; huntBtn.TextSize = 14
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        if #t >= 3 then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                    targetPlayer = p; targetBox.Text = p.Name; enabled = true
                    huntBtn.Text = "MAGNETIZED: " .. p.Name:upper(); huntBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
                    return
                end
            end
        end
    else
        enabled = false; huntBtn.Text = "INITIALIZE MAGNETO"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 20, 5)
    end
end)

min.MouseButton1Click:Connect(function()
    local minned = (min.Text == "-")
    content.Visible = not minned
    frame:TweenSize(UDim2.new(0, 280, 0, minned and 35 or 220), "Out", "Quad", 0.2, true)
    min.Text = minned and "+" or "-"
end)
close.MouseButton1Click:Connect(function() gui:Destroy(); enabled = false end)

-- LÓGICA MAGNETO MEJORADA
local function getParts()
    if tick() - lastScan < settings.scanRate then return parts end
    lastScan = tick()
    local found = {}
    local op = OverlapParams.new(); op.FilterDescendantsInstances = {character}; op.FilterType = Enum.RaycastFilterType.Exclude
    local nearby = workspace:GetPartBoundsInRadius(character:GetPivot().Position, settings.radius, op)
    local count = 0
    for _, v in ipairs(nearby) do
        if count >= settings.maxParts then break end
        if v:IsA("BasePart") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") then
            v.CanCollide = false; v.Massless = true
            table.insert(found, v); count = count + 1
            if not partData[v] then partData[v] = {pauseUntil = 0} end
        end
    end
    parts = found; return parts
end

RunService.Heartbeat:Connect(function()
    if not enabled or not targetPlayer or not targetPlayer.Character then return end
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pPos = hrp.Position + (hrp.Velocity * settings.prediction)
    local currentParts = getParts()

    for _, part in ipairs(currentParts) do
        if part.Parent and partData[part] then
            local toTarget = (pPos - part.Position)
            local dist = toTarget.Magnitude
            local currentTime = tick()

            -- SISTEMA DE IMPACTO Y PAUSA
            if dist < 6 then -- Si está "impactando" (distancia corta)
                if currentTime > partData[part].pauseUntil then
                    -- Al impactar, le decimos que se detenga por X segundos
                    partData[part].pauseUntil = currentTime + settings.pauseTime
                end
            end

            -- APLICAR MOVIMIENTO SEGÚN ESTADO
            if currentTime < partData[part].pauseUntil then
                -- ESTADO PAUSA: La pieza flota sobre el enemigo sin salir volando
                part.AssemblyLinearVelocity = hrp.Velocity + Vector3.new(0, 5, 0)
                part.AssemblyAngularVelocity = Vector3.new(0, 50, 0) -- Rota como un disco
            else
                -- ESTADO ATAQUE: Vuelve a buscar al objetivo con fuerza
                local forceDir = toTarget.Unit * settings.force
                part.AssemblyLinearVelocity = forceDir + Vector3.new(0, 15, 0)
                part.AssemblyAngularVelocity = Vector3.new(math.random(-20,20), math.random(-20,20), math.random(-20,20))
            end
        end
    end
end)

player.CharacterAdded:Connect(function(c) character = c end)
