-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- CONFIGURACIÓN
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
local lastTargetName = ""

-- INTERFAZ
local gui = Instance.new("ScreenGui")
gui.Name = "Focus_Universal_Move"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
frame.BorderSizePixel = 0
frame.Active = true 
frame.Selectable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 40) -- Un poco más grande para facilitar el toque
titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
titleBar.Active = true

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SYSTEM // MOBILE-FIX"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

--- 🛠 LÓGICA DE ARRASTRE UNIVERSAL (OPTIMIZADA CELULAR) 🛠 ---
local dragging = false
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)
------------------------------------------------------------

local mainItems = Instance.new("Frame", frame)
mainItems.Size = UDim2.new(1, 0, 1, -40); mainItems.Position = UDim2.new(0, 0, 0, 40)
mainItems.BackgroundTransparency = 1

local targetBox = Instance.new("TextBox", mainItems)
targetBox.Size = UDim2.new(0.9, 0, 0, 35); targetBox.Position = UDim2.new(0.05, 0, 0, 10)
targetBox.PlaceholderText = "NAME..."; targetBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
targetBox.TextColor3 = Color3.fromRGB(0, 255, 120); targetBox.Font = Enum.Font.Code; targetBox.TextSize = 14
targetBox.ClearTextOnFocus = false
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

local huntBtn = Instance.new("TextButton", mainItems)
huntBtn.Size = UDim2.new(0.9, 0, 0, 45); huntBtn.Position = UDim2.new(0.05, 0, 0, 55)
huntBtn.Text = "ENGAGE"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
huntBtn.TextColor3 = Color3.fromRGB(0, 255, 120); huntBtn.Font = Enum.Font.GothamBlack; huntBtn.TextSize = 16
huntBtn.Modal = true -- Esto ayuda a capturar toques en móviles
Instance.new("UICorner", huntBtn).CornerRadius = UDim.new(0, 6)

local close = Instance.new("TextButton", titleBar)
close.Size = UDim2.new(0, 30, 0, 30); close.Position = UDim2.new(1, -35, 0.5, -15)
close.Text = "X"; close.TextColor3 = Color3.fromRGB(255, 50, 50)
close.BackgroundTransparency = 1; close.Font = Enum.Font.GothamBold; close.TextSize = 18

-- LÓGICA DE FÍSICA
local function getParts()
    if not enabled then return {} end
    if tick() - lastScan < 0.08 then return parts end
    lastScan = tick()
    local found = {}
    local nearby = workspace:GetPartBoundsInRadius(character:GetPivot().Position, 900)
    for _, v in ipairs(nearby) do
        if #found >= 155 then break end
        if v:IsA("BasePart") and not v.Anchored and v.CanCollide and not v.Parent:FindFirstChild("Humanoid") then
            v.Massless = true
            table.insert(found, v)
        end
    end
    parts = found; return parts
end

RunService.Heartbeat:Connect(function(dt)
    if not enabled or not targetPlayer then return end
    local char = targetPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
    if not hrp then return end

    angle = angle + (dt * 8)
    local pPos = hrp.Position + (hrp.Velocity * 0.1)
    local currentParts = getParts()

    for i, part in ipairs(currentParts) do
        if part.Parent then
            local offsetAngle = angle + (i * (math.pi * 2 / #currentParts))
            local targetOrbitPos = pPos + Vector3.new(math.cos(offsetAngle) * 0.1, (i % 5) - 2, math.sin(offsetAngle) * 0.1)
            local direction = (targetOrbitPos - part.Position)
            local impactForce = direction.Magnitude < 1.5 and 60 or 1500
            part.AssemblyLinearVelocity = direction.Unit * impactForce + (hrp.Velocity * 1.1)
        end
    end
end)

huntBtn.MouseButton1Click:Connect(function()
    if not enabled then
        local t = targetBox.Text:lower()
        if t == "" then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and (p.Name:lower():find(t) or p.DisplayName:lower():find(t)) then
                targetPlayer = p; enabled = true
                huntBtn.Text = "ACTIVE"; huntBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                return
            end
        end
    else
        enabled = false; huntBtn.Text = "ENGAGE"; huntBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
    end
end)

close.MouseButton1Click:Connect(function() enabled = false; gui:Destroy() end)
