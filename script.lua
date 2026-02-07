-- ======================
-- UI INIT
-- ======================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Universal", "Ocean")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer

-- ======================
-- COMBAT TAB
-- ======================
local Combat = Window:NewTab("Combat")
local AimSection = Combat:NewSection("Aim")

local aimEnabled = false
local aimHolding = false
local aimBind = Enum.UserInputType.MouseButton2 -- default PPM
local aimSmooth = 8
local showFOV = false
local fovRadius = 120
local teamCheck = true
local wallCheck = true

-- FOV CIRCLE
local fovCircle
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1
    fovCircle.NumSides = 100
    fovCircle.Color = Color3.fromRGB(255,255,255)
    fovCircle.Filled = false
    fovCircle.Visible = false
end)

-- FUNCTIONS
local function wallVisible(char, part)
    if not wallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {player.Character}
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local result = workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(char)
end

local function getClosestTarget()
    local closest, shortest = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                if teamCheck and plr.Team == player.Team then continue end
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist <= fovRadius and dist < shortest and wallVisible(plr.Character, head) then
                        closest = head
                        shortest = dist
                    end
                end
            end
        end
    end
    return closest
end

-- AIM LOOP
RunService.RenderStepped:Connect(function()
    if aimEnabled and aimHolding then
        local target = getClosestTarget()
        if target then
            local camPos = Camera.CFrame.Position
            local goal = CFrame.new(camPos, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, 1 / aimSmooth)
        end
    end
end)

-- INPUT
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if (input.UserInputType == aimBind or input.KeyCode == aimBind) then
        aimHolding = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if (input.UserInputType == aimBind or input.KeyCode == aimBind) then
        aimHolding = false
    end
end)

-- UI
AimSection:NewToggle("Aim Enabled", "Enable hold-to-aim", function(state) aimEnabled = state end)
AimSection:NewToggle("Use Mouse Button (PPM)", "Toggle for mouse bind", function(state) aimBind = state and Enum.UserInputType.MouseButton2 or Enum.KeyCode.E end)
AimSection:NewSlider("Aim Smooth", "Higher = smoother", 20, 1, function(v) aimSmooth = v end)
AimSection:NewToggle("Show FOV", "Draw FOV circle", function(state) showFOV = state if fovCircle then fovCircle.Visible = state end end)
AimSection:NewSlider("FOV Scale", "Aim radius", 500, 50, function(v) fovRadius = v end)
AimSection:NewToggle("Team Check", "Ignore teammates", function(state) teamCheck = state end)
AimSection:NewToggle("Wall Check", "Ignore walls", function(state) wallCheck = state end)

-- FOV DRAW LOOP
RunService.RenderStepped:Connect(function()
    if fovCircle then
        local mouse = UserInputService:GetMouseLocation()
        fovCircle.Position = mouse
        fovCircle.Radius = fovRadius
        fovCircle.Visible = showFOV
    end
end)

-- ======================
-- MOVEMENT TAB
-- ======================
local Movement = Window:NewTab("Movement")
local SpeedSection = Movement:NewSection("Speed")

local walkSpeed = 16
local MIN_SPEED = 16

SpeedSection:NewSlider("WalkSpeed", "Minimum 16", 100, MIN_SPEED, function(v)
    walkSpeed = math.max(v, MIN_SPEED)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = walkSpeed
    end
end)

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = math.max(walkSpeed, MIN_SPEED)
    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if hum.WalkSpeed < MIN_SPEED then hum.WalkSpeed = MIN_SPEED end
    end)
end)

-- Infinite Jump
local JumpSection = Movement:NewSection("Infinite Jump")
local infJump = false
JumpSection:NewToggle("Infinite Jump", "Jump in air", function(state) infJump = state end)
UserInputService.JumpRequest:Connect(function()
    if infJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ======================
-- VISUALS TAB (3D OUTLINE ESP)
-- ======================
local Visuals = Window:NewTab("Visuals")
local ESPSection = Visuals:NewSection("ESP Settings")

local espEnabled = false
local espTeamCheck = true
local espColor = Color3.fromRGB(255,255,255)

local highlights = {}

local function clearESP()
    for _, h in pairs(highlights) do
        if h then h:Destroy() end
    end
    highlights = {}
end

ESPSection:NewToggle("ESP Enabled", "3D outline on players", function(state)
    espEnabled = state
    if not state then
        clearESP()
    end
end)

ESPSection:NewToggle("Team Check", "Ignore teammates", function(state)
    espTeamCheck = state
end)

ESPSection:NewColorPicker("Outline Color", "Color of outline", espColor, function(c)
    espColor = c
end)

-- ODSWIEŻANIE CO 0.1s
task.spawn(function()
    while task.wait(0.1) do
        if not espEnabled then
            clearESP()
            continue
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                if espTeamCheck and plr.Team == player.Team then
                    if highlights[plr] then
                        highlights[plr]:Destroy()
                        highlights[plr] = nil
                    end
                    continue
                end

                local char = plr.Character
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local hl = highlights[plr]

                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Adornee = char
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillTransparency = 1 -- tylko outline
                        hl.Parent = char
                        highlights[plr] = hl
                    end

                    hl.OutlineColor = espColor
                    hl.Enabled = true
                end
            elseif highlights[plr] then
                highlights[plr]:Destroy()
                highlights[plr] = nil
            end
        end
    end
end)
-- ======================
-- FUN TAB
-- ======================
local Fun = Window:NewTab("Fun")
local SpinSection = Fun:NewSection("SpinBot")

local spinSpeed = 10
local angle = 0
local spinConn
local root

local function setupChar(char)
    root = char:WaitForChild("HumanoidRootPart")
    angle = 0
end
if player.Character then setupChar(player.Character) end
player.CharacterAdded:Connect(setupChar)

SpinSection:NewToggle("SpinBot", "makes you SPINNN!!1!", function(state)
    if state then
        spinConn = RunService.RenderStepped:Connect(function(dt)
            if root then
                angle += spinSpeed * dt
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, angle, 0)
            end
        end)
    else
        if spinConn then spinConn:Disconnect() spinConn = nil end
    end
end)
SpinSection:NewSlider("Spin Speed", "Spinbot speed", 50, 0, function(v) spinSpeed = v end)
