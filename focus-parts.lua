-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN DE IMPACTO
local settings = {
    baseForce = 1500,
    maxForce = 3500,
    radius = 900,
    prediction = 0.1, 
    maxParts = 155, 
    scanRate = 0.08,
    orbitDist = 0.1,
    rotationSpeed = 8,
    selfSpinSpeed = 1500
}

local parts = {}
local targetPlayer = nil
local enabled = false
local lastScan = 0
local angle = 0 
local kills = 0 
local lastTargetName = ""

-- PRIORIDAD DE RED
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

-- INTERFAZ
local gui = Instance.new("ScreenGui")
gui.Name = "Focus_MoveFixed_V6"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
frame.BorderSizePixel = 0
frame.Active = true -- Permite que el GUI sea interactivo
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0, 255, 120)
stroke.Thickness = 2

local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
titleBar.Active = true -- Importante para el arrastre

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SYSTEM // OVERKILL-FIXED"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- CONTADOR
local killCounter = Instance.new("TextLabel", frame)
killCounter.Size = UDim2.new(1, 0, 0, 20)
killCounter.Position = UDim2.new(0, 0, 1, -45)
killCounter.BackgroundTransparency = 1
killCounter.Text = "KILLS RECORDED: 0"
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

local mainItems = Instance.new("Frame", frame)
mainItems.Size = UDim2.new(1, 0, 1, -35)
mainItems.Position = UDim2.new(0, 0, 0, 35)
mainItems.BackgroundTransparency = 1

local targetBox = Instance.new("TextBox", mainItems)
targetBox.Size = UDim2.new(0.9, 0, 0, 35); targetBox.Position = UDim2.new(0.05, 0, 0, 15)
targetBox.PlaceholderText = "TARGET NAME..."; targetBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
targetBox.TextColor3 = Color3.fromRGB(0, 255, 120); targetBox.Font = Enum.Font.Code; targetBox.TextSize = 14
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

local huntBtn = Instance.new("TextButton", mainItems)
huntBtn.Size = UDim2.new(0.9, 0, 0, 50); huntBtn.Position = UDim2.new(0.05, 0, 0, 65)
huntBtn.Text = "ENGAGE TARGET"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
huntBtn.TextColor3 = Color3.fromRGB(0, 255, 120); huntBtn.Font = Enum.Font.GothamBlack; huntBtn.TextSize = 16
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel", mainItems)
status.Size = UDim2.new(1, 0, 0, 20); status.Position = UDim2.new(0, 0, 1, -25)
status.BackgroundTransparency = 1; status.Text = "SYSTEM IDLE"; status.TextColor3 = Color3.fromRGB(100, 100, 100)
status.Font = Enum.Font.Code; status.TextSize = 10

--- LÓGICA DE ARRASTRE (FIXED) ---
local dragging, dragInput, dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--- MINIMIZAR ---
local minned = false
min.MouseButton1Click:Connect(function()
    minned = not minned
    mainItems.Visible = not minned
    killCounter.Visible = not minned
    min.Text = minned and "+" or "-"
    frame:TweenSize(UDim2.new(0, 280, 0, minned and 35 or 220), "Out", "Quad", 0.15, true)
end)

--- FÍSICA Y RASTREO ---
local function getParts()
    if not enabled then return {} end
    if tick() - lastScan < settings.scanRate then return parts end
    lastScan = tick()
    local found = {}
    local nearby = workspace:GetPartBoundsInRadius(character:GetPivot().Position, settings.radius)
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
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum then
        if hum.Health <= 0 and not hasDied then
            hasDied = true
            kills = kills + 1
            killCounter.Text = "KILLS RECORDED: " .. tostring(kills)
        elseif hum.Health > 0 and hasDied then
            hasDied = false
        end
    end

    if not hrp then return end

    angle = angle + (dt * settings.rotationSpeed)
    local pPos = hrp.Position + (hrp.Velocity * settings.prediction)
    local currentParts = getParts()

    for i, part in ipairs(currentParts) do
        if part.Parent then
            local offsetAngle = angle + (i * (math.pi * 2 / #currentParts))
            local ellipseX = math.cos(offsetAngle) * (settings.orbitDist + (i % 2 == 0 and 0.5 or -0.2))
            local ellipseZ = math.sin(offsetAngle) * (settings.orbitDist + (i % 2 == 0 and -0.2 or 0.5))
            
            local targetOrbitPos = pPos + Vector3.new(ellipseX, (i % 5) - 2, ellipseZ)
            local direction = (targetOrbitPos - part.Position)
            local dist = direction.Magnitude
            
            local impactForce = settings.baseForce
            if dist < 1.5 then
                impactForce = 60 
            elseif dist > 10 then
                impactForce = settings.maxForce
            end
            
            part.AssemblyLinearVelocity = direction.Unit * impactForce + (hrp.Velocity * 1.1)
            part.AssemblyAngularVelocity = Vector3.new(settings.selfSpinSpeed, settings.selfSpinSpeed, settings.selfSpinSpeed)
        end
    end
end)

huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                if lastTargetName ~= p.Name then
                    kills = 0; killCounter.Text = "KILLS RECORDED: 0"
                    lastTargetName = p.Name
                end
                targetPlayer = p; enabled = true
                huntBtn.Text = "SMASHING: " .. p.Name:upper()
                huntBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                status.Text = "TARGET LOCKED"
                return
            end
        end
    else
        enabled = false; huntBtn.Text = "ENGAGE TARGET"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10); status.Text = "SYSTEM IDLE"
    end
end)

close.MouseButton1Click:Connect(function() enabled = false; gui:Destroy() end)
player.CharacterAdded:Connect(function(c) character = c end)
