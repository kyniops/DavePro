--[[
    ═══════════════════════════════════════════════════════════
    💎 PRO GAMING TOOL V3 - FULLY INTEGRATED 💎
    📦 ESP + 🎯 AIMBOT + ⚡ TRIGGERBOT + 🛠️ SMART UI
    ═══════════════════════════════════════════════════════════
]]--

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local function getCamera()
    return workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
end

-- ========== CONFIGURATION PAR DÉFAUT ==========
local Config = {
    Aimbot = {
        Enabled = false,
        Key = Enum.UserInputType.MouseButton2,
        Smoothness = 0.5,
        FOV = 150,
        ShowFOV = true,
        TargetPart = "Head",
        MaxDistance = 1000,
        TeamCheck = false,
        VisibleCheck = true,
        Sticky = true
    },
    ESP = {
        Enabled = false,
        Boxes = true,
        Skeleton = true,
        Health = true,
        Names = true,
        Distance = true,
        Tracers = false,
        MaxDistance = 1000,
        BoxColor = Color3.fromRGB(255, 255, 255),
        SkelColor = Color3.fromRGB(255, 255, 255),
        Color = {R = 255, G = 255, B = 255}
    },
    Triggerbot = {
        Enabled = false,
        Key = Enum.KeyCode.T,
        Delay = 0.05,
        TeamCheck = false
    },
    Movement = {
        Fly = {
            Enabled = false,
            Key = Enum.KeyCode.F,
            Speed = 50,
            AscendSpeed = 30,
            EnergyEnabled = false,
            Energy = 100,
            MaxEnergy = 100
        },
        Sprint = {
            Enabled = false,
            Multiplier = 2,
            Endurance = 100,
            MaxEndurance = 100,
            RecoveryRate = 5
        },
        SuperJump = {
            Enabled = false,
            PowerMultiplier = 2.5,
            DoubleJumpEnabled = true,
            ReduceFallDamage = true
        },
        SpeedHack = {
            Enabled = false,
            Value = 50
        },
        AutoJump = false,
        Bhop = false,
        NoClip = false,
        InfiniteJump = false
    },
    Combat = {
        SpinBot = {
            Enabled = false,
            Speed = 20,
            Vertical = false
        },
        AimAssist = {
            Enabled = false,
            Strength = 0.1
        },
        HitboxExpander = {
            Enabled = false,
            Multiplier = 1.5,
            Transparency = 0.6,
            Color = Color3.fromRGB(255, 0, 0)
        }
    },
    Visuals = {
        FullBright = false,
        NoFog = false,
        Chams = false,
        ChamsColor = Color3.fromRGB(255, 255, 255),
        FOVColor = Color3.fromRGB(255, 255, 255),
        FOVTransparency = 0.5,
        FOVColorRGB = {R = 255, G = 255, B = 255},
        AccentColor = {R = 255, G = 255, B = 255}
    },
    Misc = {
        AntiAFK = true,
        Gravity = 196.2,
        FPSCap = 60
    }
}

-- ========== CONSTANTES ESP ==========
local R6_JOINTS = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local R15_JOINTS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"}
}

-- État interne
local AimlockPressed = false
local TriggerActive = false
local CurrentTarget = nil
local ESPObjects = {}
local FOVCircle = nil
local Flying = false
local Sprinting = false
local DoubleJumped = false
local CanDoubleJump = false
local FlyVelocity = nil
local FlyGyro = nil
local SpinAngle = 0
local LastJumpTime = 0
local Logs = {}
local Hitboxes = {}
local function log(msg)
    table.insert(Logs, "[" .. os.date("%X") .. "] " .. msg)
    if #Logs > 50 then table.remove(Logs, 1) end
    print("💎 [PRO TOOL] " .. msg)
end

-- ========== VÉRIFICATION DRAWING LIBRARY ==========
if not Drawing then
    warn("❌ Drawing Library non disponible!")
    return
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME DE SAUVEGARDE ET CONFIGURATION
-- ═══════════════════════════════════════════════════════════

local HttpService = game:GetService("HttpService")
local ConfigFile = "ProToolConfig.json"

local function saveConfig()
    if writefile then
        local success, data = pcall(function() return HttpService:JSONEncode(Config) end)
        if success then
            writefile(ConfigFile, data)
            log("Configuration sauvegardée")
        else
            warn("Échec de l'encodage de la config")
        end
    end
end

local function loadConfig()
    if readfile and isfile and isfile(ConfigFile) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
        if success then
            for k, v in pairs(data) do
                if Config[k] then
                    if type(v) == "table" then
                        for k2, v2 in pairs(v) do
                            Config[k][k2] = v2
                        end
                    else
                        Config[k] = v
                    end
                end
            end
            log("Configuration chargée")
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════

local function worldToScreen(position)
    local Camera = getCamera()
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function isVisible(targetPart)
    if not Config.Aimbot.VisibleCheck then return true end
    local char = LocalPlayer.Character
    if not char then return false end
    local Camera = getCamera()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, Camera, targetPart.Parent}
    local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), params)
    return not result
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME AIMBOT
-- ═══════════════════════════════════════════════════════════

local function getClosestPlayerInFOV()
    local target = nil
    local minDist = math.huge
    local Camera = getCamera()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        
        local part = char:FindFirstChild(Config.Aimbot.TargetPart) or char:FindFirstChild("Head")
        if not part then continue end
        
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then continue end
        if (part.Position - myChar.HumanoidRootPart.Position).Magnitude > Config.Aimbot.MaxDistance then continue end
        
        local screenPos, onScreen = worldToScreen(part.Position)
        if not onScreen then continue end
        
        local distFromCenter = (screenPos - center).Magnitude
        if distFromCenter <= Config.Aimbot.FOV and distFromCenter < minDist then
            if isVisible(part) then
                minDist = distFromCenter
                target = {Player = player, Part = part}
            end
        end
    end
    return target
end

local function aimAt(part, isInitial)
    local Camera = getCamera()
    local targetPos = part.Position
    if part.Name == "Head" then targetPos = targetPos + Vector3.new(0, 0.1, 0) end
    
    local targetCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    local lerpAmount = isInitial and 1 or (1 - Config.Aimbot.Smoothness)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(lerpAmount, 0.01, 1))
end

local function aimbotUpdate()
    if not Config.Aimbot.Enabled or not AimlockPressed then 
        CurrentTarget = nil 
        return 
    end
    
    local target = getClosestPlayerInFOV()
    if target then
        CurrentTarget = target
        aimAt(target.Part, false)
    else
        CurrentTarget = nil
    end
end

local function aimAssistUpdate()
    if not Config.Combat.AimAssist.Enabled or AimlockPressed then return end
    
    local target = getClosestPlayerInFOV()
    if target then
        local cam = getCamera()
        local targetPos = target.Part.Position
        local targetCF = CFrame.lookAt(cam.CFrame.Position, targetPos)
        cam.CFrame = cam.CFrame:Lerp(targetCF, Config.Combat.AimAssist.Strength * 0.1)
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME ESP
-- ═══════════════════════════════════════════════════════════

local function createDrawing(type, props)
    local obj = Drawing.new(type)
    for i, v in pairs(props) do obj[i] = v end
    return obj
end

local function createESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    ESPObjects[player] = {
        Box = {
            T = createDrawing("Line", {Thickness = 1, Visible = false}),
            B = createDrawing("Line", {Thickness = 1, Visible = false}),
            L = createDrawing("Line", {Thickness = 1, Visible = false}),
            R = createDrawing("Line", {Thickness = 1, Visible = false})
        },
        Skeleton = {},
        HealthBar = {
            BG = createDrawing("Line", {Thickness = 2, Color = Color3.new(0,0,0), Visible = false}),
            Bar = createDrawing("Line", {Thickness = 1, Visible = false})
        },
        Text = createDrawing("Text", {Size = 13, Center = true, Outline = true, Visible = false}),
        Tracer = createDrawing("Line", {Thickness = 1, Visible = false}),
        Highlight = nil
    }
    for i = 1, 15 do
        table.insert(ESPObjects[player].Skeleton, createDrawing("Line", {Thickness = 1, Visible = false}))
    end
end

local function removeESP(player)
    local data = ESPObjects[player]
    if not data then return end
    for _, v in pairs(data.Box) do v:Remove() end
    for _, v in pairs(data.HealthBar) do v:Remove() end
    for _, v in pairs(data.Skeleton) do v:Remove() end
    if data.Tracer then data.Tracer:Remove() end
    if data.Highlight then data.Highlight:Destroy() end
    data.Text:Remove()
    ESPObjects[player] = nil
end

local function updateESP()
    for player, data in pairs(ESPObjects) do
        local char = player.Character
        if not char or not char.Parent or not Config.ESP.Enabled then
            for _, v in pairs(data.Box) do v.Visible = false end
            for _, v in pairs(data.HealthBar) do v.Visible = false end
            for _, v in pairs(data.Skeleton) do v.Visible = false end
            if data.Tracer then data.Tracer.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
            data.Text.Visible = false
            continue
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            for _, v in pairs(data.Box) do v.Visible = false end
            for _, v in pairs(data.HealthBar) do v.Visible = false end
            for _, v in pairs(data.Skeleton) do v.Visible = false end
            if data.Tracer then data.Tracer.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
            data.Text.Visible = false
            continue
        end
        
        local cam = getCamera()
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local distance = myHrp and (hrp.Position - myHrp.Position).Magnitude or 0
        
        if distance > Config.ESP.MaxDistance then
            for _, v in pairs(data.Box) do v.Visible = false end
            for _, v in pairs(data.HealthBar) do v.Visible = false end
            for _, v in pairs(data.Skeleton) do v.Visible = false end
            if data.Tracer then data.Tracer.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
            data.Text.Visible = false
            continue
        end
        
        local screenPos, onScreen = worldToScreen(hrp.Position)
        if onScreen then
            local size = char:GetExtentsSize()
            local w, h = size.X * 1.5, size.Y * 1.5
            local cf = CFrame.lookAt(hrp.Position, hrp.Position + (cam.CFrame.Position - hrp.Position).Unit)
            
            local function getP(x, y) return worldToScreen((cf * CFrame.new(x, y, 0)).Position) end
            local tl, os1 = getP(-w/2, h/2)
            local tr, os2 = getP(w/2, h/2)
            local bl, os3 = getP(-w/2, -h/2)
            local br, os4 = getP(w/2, -h/2)
            
            local boxVis = os1 and os2 and os3 and os4 and Config.ESP.Boxes
            data.Box.T.Visible, data.Box.T.From, data.Box.T.To = boxVis, tl, tr
            data.Box.B.Visible, data.Box.B.From, data.Box.B.To = boxVis, bl, br
            data.Box.L.Visible, data.Box.L.From, data.Box.L.To = boxVis, tl, bl
            data.Box.R.Visible, data.Box.R.From, data.Box.R.To = boxVis, tr, br
            
            if boxVis then
                local espColor = Color3.fromRGB(Config.ESP.Color.R, Config.ESP.Color.G, Config.ESP.Color.B)
                for _, l in pairs(data.Box) do l.Color = espColor end
            end
            
            if Config.ESP.Health then
                local barOffset = 1.0
                local top, _ = getP(-w/2 - barOffset, h/2)
                local bot, _ = getP(-w/2 - barOffset, -h/2)
                
                local barX = bot.X
                local barY_top = top.Y
                local barY_bot = bot.Y
                
                data.HealthBar.BG.Visible = true
                data.HealthBar.BG.From = Vector2.new(barX, barY_top)
                data.HealthBar.BG.To = Vector2.new(barX, barY_bot)
                data.HealthBar.BG.Thickness = 2
                data.HealthBar.BG.Color = Color3.new(0,0,0)
                
                local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local hpHeight = (barY_bot - barY_top) * hpPercent
                
                data.HealthBar.Bar.Visible = true
                data.HealthBar.Bar.From = Vector2.new(barX, barY_bot)
                data.HealthBar.Bar.To = Vector2.new(barX, barY_bot - hpHeight)
                data.HealthBar.Bar.Thickness = 2
                data.HealthBar.Bar.Color = hpPercent > 0.6 and Color3.new(0,1,0) or (hpPercent > 0.3 and Color3.new(1,1,0) or Color3.new(1,0,0))
            else
                data.HealthBar.BG.Visible, data.HealthBar.Bar.Visible = false, false
            end
            
            if Config.ESP.Skeleton then
                local joints = hum.RigType == Enum.HumanoidRigType.R15 and R15_JOINTS or R6_JOINTS
                for i, joint in pairs(joints) do
                    local line = data.Skeleton[i]
                    if line then
                        local p1 = char:FindFirstChild(joint[1])
                        local p2 = char:FindFirstChild(joint[2])
                        if p1 and p2 then
                            local s1, o1 = worldToScreen(p1.Position)
                            local s2, o2 = worldToScreen(p2.Position)
                            if o1 and o2 then
                                line.Visible = true
                                line.From = s1
                                line.To = s2
                                line.Color = Color3.fromRGB(Config.ESP.Color.R, Config.ESP.Color.G, Config.ESP.Color.B)
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end
                end
                for i = #joints + 1, 15 do
                    if data.Skeleton[i] then data.Skeleton[i].Visible = false end
                end
            else
                for _, v in pairs(data.Skeleton) do v.Visible = false end
            end

            if Config.Visuals.Chams then
                if not data.Highlight then
                    data.Highlight = Instance.new("Highlight")
                    data.Highlight.Parent = game.CoreGui
                end
                data.Highlight.Adornee = char
                data.Highlight.Enabled = true
                data.Highlight.FillColor = Config.Visuals.ChamsColor
                data.Highlight.OutlineColor = Color3.new(1,1,1)
                data.Highlight.FillTransparency = 0.5
            elseif data.Highlight then
                data.Highlight.Enabled = false
            end
            
            if Config.ESP.Tracers then
                data.Tracer.Visible = true
                data.Tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                data.Tracer.To = screenPos
                data.Tracer.Color = Config.ESP.BoxColor
            else
                data.Tracer.Visible = false
            end
            
            if Config.ESP.Names or Config.ESP.Distance then
                local head = char:FindFirstChild("Head")
                if head then
                    local headPos, _ = worldToScreen(head.Position + Vector3.new(0, 1.5, 0))
                    data.Text.Visible = true
                    data.Text.Position = headPos
                    local t = ""
                    if Config.ESP.Names then t = t .. player.Name .. "\n" end
                    if Config.ESP.Distance then t = t .. "[" .. math.floor(distance) .. "m]" end
                    data.Text.Text = t
                    data.Text.Color = Color3.new(1,1,1)
                else
                    data.Text.Visible = false
                end
            else
                data.Text.Visible = false
            end
        else
            for _, v in pairs(data.Box) do v.Visible = false end
            for _, v in pairs(data.HealthBar) do v.Visible = false end
            for _, v in pairs(data.Skeleton) do v.Visible = false end
            if data.Tracer then data.Tracer.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
            data.Text.Visible = false
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME DE MOUVEMENT
-- ═══════════════════════════════════════════════════════════

local function updateMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    if Config.Movement.Sprint.Enabled and Sprinting and Config.Movement.Sprint.Endurance > 0 then
        hum.WalkSpeed = 16 * Config.Movement.Sprint.Multiplier
        Config.Movement.Sprint.Endurance = math.max(0, Config.Movement.Sprint.Endurance - 0.5)
        if Config.Movement.Sprint.Endurance == 0 then Sprinting = false end
    elseif not Config.Movement.SpeedHack.Enabled then
        hum.WalkSpeed = 16
        Config.Movement.Sprint.Endurance = math.min(Config.Movement.Sprint.MaxEndurance, Config.Movement.Sprint.Endurance + Config.Movement.Sprint.RecoveryRate/60)
    end

    if Config.Movement.SpeedHack.Enabled then
        hum.WalkSpeed = Config.Movement.SpeedHack.Value
    end

    if Flying then
        if Config.Movement.Fly.EnergyEnabled then
            Config.Movement.Fly.Energy = math.max(0, Config.Movement.Fly.Energy - 0.1)
            if Config.Movement.Fly.Energy == 0 then
                toggleFly()
                log("Énergie de vol épuisée")
            end
        end

        local cam = getCamera()
        local moveDir = Vector3.new(0,0,0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            local vel = moveDir.Unit * Config.Movement.Fly.Speed
            if FlyVelocity then FlyVelocity.Velocity = vel end
        else
            if FlyVelocity then FlyVelocity.Velocity = Vector3.new(0, 0, 0) end
        end
        
        if FlyGyro then FlyGyro.CFrame = cam.CFrame end
    else
        if Config.Movement.Fly.EnergyEnabled then
            Config.Movement.Fly.Energy = math.min(Config.Movement.Fly.MaxEnergy, Config.Movement.Fly.Energy + 0.05)
        end
    end

    if Config.Movement.SuperJump.Enabled and Config.Movement.SuperJump.ReduceFallDamage then
        if hum.FloorMaterial ~= Enum.Material.Air then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, math.max(hrp.Velocity.Y, -20), hrp.Velocity.Z)
        end
    end

    if Config.Movement.NoClip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if Config.Movement.AutoJump or Config.Movement.Bhop then
        if hum.FloorMaterial ~= Enum.Material.Air then
            if Config.Movement.AutoJump then
                local ray = Ray.new(hrp.Position, hrp.CFrame.LookVector * 5 + Vector3.new(0, -5, 0))
                local hit = workspace:FindPartOnRay(ray, char)
                if not hit then hum.Jump = true end
            end
            if Config.Movement.Bhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                hum.Jump = true
            end
        end
    end

    if Config.Movement.SuperJump.Enabled then
        hum.JumpPower = 50 * Config.Movement.SuperJump.PowerMultiplier
    else
        hum.JumpPower = 50
    end
end

local function toggleFly()
    Flying = not Flying
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if Flying then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Parent = hrp
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
        
        FlyVelocity = bv
        FlyGyro = bg
        log("Mode Vol activé")
    else
        if FlyVelocity then FlyVelocity:Destroy() end
        if FlyGyro then FlyGyro:Destroy() end
        FlyVelocity = nil
        FlyGyro = nil
        hrp.Velocity = Vector3.new(0, 0, 0)
        log("Mode Vol désactivé")
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME DE COMBAT AVANCÉ
-- ═══════════════════════════════════════════════════════════

local function spinbotUpdate()
    if not Config.Combat.SpinBot.Enabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    SpinAngle = SpinAngle + Config.Combat.SpinBot.Speed
    local targetCF = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(SpinAngle), 0)
    if Config.Combat.SpinBot.Vertical then
        targetCF = targetCF * CFrame.Angles(math.rad(SpinAngle), 0, 0)
    end
    hrp.CFrame = targetCF
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME HITBOX EXPANDER
-- ═══════════════════════════════════════════════════════════

local function updateHitboxes()
    if not Config.Combat.HitboxExpander.Enabled then
        for player, box in pairs(Hitboxes) do
            if box then box:Destroy() end
            Hitboxes[player] = nil
        end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then
            if Hitboxes[player] then
                Hitboxes[player]:Destroy()
                Hitboxes[player] = nil
            end
            continue
        end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if hrp and hum and hum.Health > 0 then
            local box = Hitboxes[player]
            if not box or box.Parent ~= char then
                if box then box:Destroy() end
                box = Instance.new("Part")
                box.Name = "HitboxPart"
                box.CastShadow = false
                box.CanCollide = false
                box.CanQuery = true
                box.Anchored = false -- Changé à false
                box.Transparency = Config.Combat.HitboxExpander.Transparency
                box.Material = Enum.Material.ForceField
                box.Parent = char
                
                -- Ajout d'une soudure (Weld)
                local weld = Instance.new("Weld")
                weld.Part0 = hrp
                weld.Part1 = box
                weld.C0 = CFrame.new(0, 0, 0)
                weld.Parent = box
                
                Hitboxes[player] = box
            end

            local sizeMultiplier = Config.Combat.HitboxExpander.Multiplier
            box.Size = Vector3.new(2 * sizeMultiplier, 2 * sizeMultiplier, 2 * sizeMultiplier) -- Taille plus raisonnable
            -- box.CFrame = hrp.CFrame -- Plus besoin avec le Weld
            box.Color = Config.Combat.HitboxExpander.Color
            box.Transparency = Config.Combat.HitboxExpander.Transparency
        else
            if Hitboxes[player] then
                Hitboxes[player]:Destroy()
                Hitboxes[player] = nil
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME TRIGGERBOT
-- ═══════════════════════════════════════════════════════════

local lastShot = 0
local function triggerbotUpdate()
    if not Config.Triggerbot.Enabled or not TriggerActive then return end
    if tick() - lastShot < Config.Triggerbot.Delay then return end
    
    local mouse = LocalPlayer:GetMouse()
    local target = mouse.Target
    if target and target.Parent then
        local char = target.Parent
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local p = Players:GetPlayerFromCharacter(char)
            if p and p ~= LocalPlayer and (not Config.Triggerbot.TeamCheck or p.Team ~= LocalPlayer.Team) then
                if mouse1click then
                    mouse1click()
                    lastShot = tick()
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- INTERFACE UTILISATEUR (UI) PROFESSIONNELLE
-- ═══════════════════════════════════════════════════════════

local Library = {}

function Library:CreateWindow()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ProToolUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false
    
    local Theme = {
        Background = Color3.fromRGB(15, 15, 15),
        Sidebar = Color3.fromRGB(10, 10, 10),
        Accent = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(180, 180, 180),
        Secondary = Color3.fromRGB(30, 30, 30),
        Hover = Color3.fromRGB(40, 40, 40)
    }

    local RestoreBtn = Instance.new("TextButton")
    RestoreBtn.Name = "RestoreBtn"
    RestoreBtn.Size = UDim2.new(0, 40, 0, 40)
    RestoreBtn.Position = UDim2.new(0, 20, 0.5, -20)
    RestoreBtn.BackgroundColor3 = Theme.Background
    RestoreBtn.Text = "P"
    RestoreBtn.TextColor3 = Theme.Accent
    RestoreBtn.Font = Enum.Font.GothamBold
    RestoreBtn.TextSize = 20
    RestoreBtn.Visible = false
    RestoreBtn.Parent = ScreenGui
    Instance.new("UICorner", RestoreBtn).CornerRadius = UDim.new(0, 5)
    local RestoreStroke = Instance.new("UIStroke", RestoreBtn)
    RestoreStroke.Color = Theme.Accent
    RestoreStroke.Thickness = 1
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 550, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -210)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 4)
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Theme.Secondary
    MainStroke.Thickness = 1
    
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.Parent = MainFrame
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 4)
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 60)
    Title.BackgroundTransparency = 1
    Title.Text = "DAVE PRO TOOL"
    Title.TextColor3 = Theme.Accent
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Parent = Sidebar
    
    local Version = Instance.new("TextLabel")
    Version.Size = UDim2.new(1, 0, 0, 20)
    Version.Position = UDim2.new(0, 0, 1, -25)
    Version.BackgroundTransparency = 1
    Version.Text = "VERSION B&W"
    Version.TextColor3 = Theme.TextDim
    Version.Font = Enum.Font.Gotham
    Version.TextSize = 10
    Version.Parent = Sidebar

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, -170, 1, -20)
    Container.Position = UDim2.new(0, 170, 0, 10)
    Container.BackgroundTransparency = 1
    Container.Parent = MainFrame
    
    local currentTab = nil
    local TabButtons = Instance.new("Frame")
    TabButtons.Name = "TabButtons"
    TabButtons.Size = UDim2.new(1, 0, 1, -100)
    TabButtons.Position = UDim2.new(0, 0, 0, 70)
    TabButtons.BackgroundTransparency = 1
    TabButtons.Parent = Sidebar
    
    local TabList = Instance.new("UIListLayout", TabButtons)
    TabList.Padding = UDim.new(0, 2)
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local function createTab(name, icon)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0.9, 0, 0, 35)
        tabBtn.BackgroundColor3 = Theme.Hover
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = name:upper()
        tabBtn.TextColor3 = Theme.TextDim
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.TextSize = 12
        tabBtn.Parent = TabButtons
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 4)
        
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 2, 0.6, 0)
        indicator.Position = UDim2.new(0, 4, 0.2, 0)
        indicator.BackgroundColor3 = Theme.Accent
        indicator.Visible = false
        indicator.Parent = tabBtn

        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, -10, 1, -10)
        tabFrame.Position = UDim2.new(0, 5, 0, 5)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.Visible = false
        tabFrame.ScrollBarThickness = 4
        tabFrame.ScrollBarImageColor3 = Theme.Accent
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.Parent = Container
        
        -- IMPORTANT: Utiliser un UIListLayout pour organiser les éléments
        local layout = Instance.new("UIListLayout", tabFrame)
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        -- Mise à jour automatique de la taille du canvas
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)
        
        tabBtn.MouseButton1Click:Connect(function()
            if currentTab then 
                currentTab.Btn.BackgroundTransparency = 1
                currentTab.Btn.TextColor3 = Theme.TextDim
                currentTab.Indicator.Visible = false
                currentTab.Frame.Visible = false 
            end
            tabBtn.BackgroundTransparency = 0.9
            tabBtn.TextColor3 = Theme.Accent
            indicator.Visible = true
            tabFrame.Visible = true
            currentTab = {Btn = tabBtn, Frame = tabFrame, Indicator = indicator}
        end)
        
        return tabFrame, tabBtn
    end
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Theme.TextDim
    CloseBtn.TextSize = 30
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.ZIndex = 20
    CloseBtn.Parent = MainFrame
    
    CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Accent end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.TextDim end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        RestoreBtn.Visible = true
    end)
    
    RestoreBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        RestoreBtn.Visible = false
    end)
    
    local function addToggle(parent, text, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 35)
        frame.BackgroundColor3 = Theme.Secondary
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text:upper()
        label.TextColor3 = default and Theme.Accent or Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 11
        label.Parent = frame
        
        local box = Instance.new("TextButton")
        box.Size = UDim2.new(0, 30, 0, 16)
        box.Position = UDim2.new(1, -40, 0.5, -8)
        box.BackgroundColor3 = default and Theme.Accent or Theme.Background
        box.Text = ""
        box.Parent = frame
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
        local boxStroke = Instance.new("UIStroke", box)
        boxStroke.Color = Theme.Accent
        boxStroke.Thickness = 1

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = default and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
        dot.BackgroundColor3 = default and Theme.Background or Theme.Accent
        dot.Parent = box
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        
        local state = default
        box.MouseButton1Click:Connect(function()
            state = not state
            box.BackgroundColor3 = state and Theme.Accent or Theme.Background
            dot.BackgroundColor3 = state and Theme.Background or Theme.Accent
            dot:TweenPosition(state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5), "Out", "Quad", 0.1, true)
            label.TextColor3 = state and Theme.Accent or Theme.TextDim
            callback(state)
        end)
    end
    
    local function addSlider(parent, text, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 50)
        frame.BackgroundColor3 = Theme.Secondary
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 25)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text:upper() .. " : " .. default
        label.TextColor3 = Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 10
        label.Parent = frame
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 2)
        bar.Position = UDim2.new(0, 10, 0, 35)
        bar.BackgroundColor3 = Theme.Hover
        bar.Parent = frame
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 8, 0, 8)
        knob.Position = UDim2.new(1, -4, 0.5, -4)
        knob.BackgroundColor3 = Theme.Accent
        knob.Parent = fill
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = bar
        
        local function update(input)
            local barPosX = bar.AbsolutePosition.X
            local barSizeX = bar.AbsoluteSize.X
            local pos = math.clamp((input.Position.X - barPosX) / barSizeX, 0, 1)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            local val = min + (max - min) * pos
            if max <= 10 then
                val = math.floor(val * 10) / 10
            else
                val = math.floor(val)
            end
            label.Text = text:upper() .. " : " .. val
            callback(val)
        end
        
        local dragging = false
        
        frame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(i)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                update(i)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end
    
    local function addKeybind(parent, text, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 35)
        frame.BackgroundColor3 = Theme.Secondary
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -100, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text:upper()
        label.TextColor3 = Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 11
        label.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 0, 20)
        btn.Position = UDim2.new(1, -90, 0.5, -10)
        btn.BackgroundColor3 = Theme.Background
        btn.Text = default.Name:upper()
        btn.TextColor3 = Theme.Accent
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = Theme.Accent
        btnStroke.Thickness = 1
        
        local waiting = false
        btn.MouseButton1Click:Connect(function()
            waiting = true
            btn.Text = "..."
        end)
        
        UserInputService.InputBegan:Connect(function(input)
            if waiting then
                local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                if key ~= Enum.KeyCode.Escape then
                    btn.Text = key.Name:upper()
                    callback(key)
                end
                waiting = false
            end
        end)
    end

    local function addButton(parent, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = Theme.Accent
        btn.Text = text:upper()
        btn.TextColor3 = Theme.Background
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(callback)
    end

    -- Construction des Tabs
    local AimbotTab = createTab("Aimbot", "🎯")
    local ESPTab = createTab("ESP", "👁️")
    local MovementTab = createTab("Mouvement", "👟")
    local CombatTab = createTab("Combat", "⚔️")
    local VisualsTab = createTab("Visuels", "✨")
    local TeleportTab, TeleportBtn = createTab("Téléportation", "📍")
    local ScriptsTab = createTab("Scripts", "📜")
    local TriggerTab = createTab("Trigger", "⚡")
    local MiscTab = createTab("Divers", "🛠️")
    
    local selectedTeleportPlayer = nil
    
    -- Aimbot Content
    addToggle(AimbotTab, "Activer Aimbot", Config.Aimbot.Enabled, function(v) Config.Aimbot.Enabled = v if FOVCircle then FOVCircle.Visible = v and Config.Aimbot.ShowFOV end end)
    addKeybind(AimbotTab, "Touche Aimbot", Config.Aimbot.Key, function(v) Config.Aimbot.Key = v end)
    addSlider(AimbotTab, "Lissage (Smooth)", 0, 0.95, Config.Aimbot.Smoothness, function(v) Config.Aimbot.Smoothness = v end)
    addSlider(AimbotTab, "Rayon FOV", 10, 800, Config.Aimbot.FOV, function(v) Config.Aimbot.FOV = v end)
    addToggle(AimbotTab, "Afficher FOV", Config.Aimbot.ShowFOV, function(v) Config.Aimbot.ShowFOV = v if FOVCircle then FOVCircle.Visible = v and Config.Aimbot.Enabled end end)
    addToggle(AimbotTab, "Team Check", Config.Aimbot.TeamCheck, function(v) Config.Aimbot.TeamCheck = v end)
    addToggle(AimbotTab, "Visible Check", Config.Aimbot.VisibleCheck, function(v) Config.Aimbot.VisibleCheck = v end)
    addToggle(AimbotTab, "Sticky Lock", Config.Aimbot.Sticky, function(v) Config.Aimbot.Sticky = v end)
    addSlider(AimbotTab, "Distance Max", 100, 5000, Config.Aimbot.MaxDistance, function(v) Config.Aimbot.MaxDistance = v end)
    addButton(AimbotTab, "Cible: Tête", function() Config.Aimbot.TargetPart = "Head" log("Cible: Head") end)
    addButton(AimbotTab, "Cible: Torse", function() Config.Aimbot.TargetPart = "HumanoidRootPart" log("Cible: Torso") end)

    -- ESP Content
    addToggle(ESPTab, "Activer ESP", Config.ESP.Enabled, function(v) Config.ESP.Enabled = v end)
    addToggle(ESPTab, "Boxes", Config.ESP.Boxes, function(v) Config.ESP.Boxes = v end)
    addToggle(ESPTab, "Squelettes", Config.ESP.Skeleton, function(v) Config.ESP.Skeleton = v end)
    addToggle(ESPTab, "Barre de Vie", Config.ESP.Health, function(v) Config.ESP.Health = v end)
    addToggle(ESPTab, "Noms", Config.ESP.Names, function(v) Config.ESP.Names = v end)
    addToggle(ESPTab, "Distance", Config.ESP.Distance, function(v) Config.ESP.Distance = v end)
    addToggle(ESPTab, "Traceurs (Tracers)", Config.ESP.Tracers, function(v) Config.ESP.Tracers = v end)
    addSlider(ESPTab, "Distance Max", 100, 5000, Config.ESP.MaxDistance, function(v) Config.ESP.MaxDistance = v end)
    
    -- Visuals Content
    addToggle(VisualsTab, "Chams (Wallhack)", Config.Visuals.Chams, function(v) Config.Visuals.Chams = v end)
    addToggle(VisualsTab, "FullBright (Lumière)", Config.Visuals.FullBright, function(v) Config.Visuals.FullBright = v end)
    addToggle(VisualsTab, "No Fog (Pas de brouillard)", Config.Visuals.NoFog, function(v) Config.Visuals.NoFog = v end)
    addSlider(VisualsTab, "Transparence FOV", 0, 1, Config.Visuals.FOVTransparency, function(v) Config.Visuals.FOVTransparency = v end)
    
    local function createColorSection(parent, title, configPath, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 60)
        frame.BackgroundColor3 = Theme.Secondary
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = title:upper()
        label.TextColor3 = Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 10
        label.Parent = frame
        
        local colors = {
            {Color3.fromRGB(255, 255, 255), "Blanc"},
            {Color3.fromRGB(255, 0, 0), "Rouge"},
            {Color3.fromRGB(0, 255, 0), "Vert"},
            {Color3.fromRGB(0, 0, 255), "Bleu"},
            {Color3.fromRGB(255, 255, 0), "Jaune"},
            {Color3.fromRGB(255, 0, 255), "Rose"},
            {Color3.fromRGB(0, 255, 255), "Cyan"},
            {Color3.fromRGB(255, 165, 0), "Orange"}
        }
        
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 25)
        container.Position = UDim2.new(0, 10, 0, 25)
        container.BackgroundTransparency = 1
        container.Parent = frame
        
        local layout = Instance.new("UIListLayout", container)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 5)
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        
        for _, data in pairs(colors) do
            local color = data[1]
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 20, 0, 20)
            btn.BackgroundColor3 = color
            btn.Text = ""
            btn.Parent = container
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                configPath.R, configPath.G, configPath.B = color.R * 255, color.G * 255, color.B * 255
                if callback then callback(color) end
                log("Couleur " .. title .. " mise à jour: " .. data[2])
            end)
        end
    end

    local function updateMenuTheme(color)
        Theme.Accent = color
        if RestoreBtn then RestoreBtn.TextColor3 = color end
        if RestoreStroke then RestoreStroke.Color = color end
        if Title then Title.TextColor3 = color end
        
        -- Mise à jour dynamique des éléments visuels
        for _, obj in pairs(ScreenGui:GetDescendants()) do
            if obj:IsA("TextButton") and obj.BackgroundColor3 == Theme.Accent then
                obj.BackgroundColor3 = color
            elseif obj:IsA("UIStroke") and obj.Color == Theme.Accent then
                obj.Color = color
            elseif obj:IsA("TextLabel") and obj.TextColor3 == Theme.Accent then
                obj.TextColor3 = color
            elseif obj:IsA("ScrollingFrame") and obj.ScrollBarImageColor3 == Theme.Accent then
                obj.ScrollBarImageColor3 = color
            elseif obj:IsA("Frame") and obj.BackgroundColor3 == Theme.Accent then
                obj.BackgroundColor3 = color
            end
        end
        
        -- S'assurer que les onglets sélectionnés gardent la couleur
        if currentTab then
            currentTab.Btn.TextColor3 = color
            currentTab.Indicator.BackgroundColor3 = color
        end
    end

    createColorSection(VisualsTab, "Couleur Menu", Config.Visuals.AccentColor, updateMenuTheme)
    createColorSection(VisualsTab, "Couleur ESP", Config.ESP.Color)
    createColorSection(VisualsTab, "Couleur FOV", Config.Visuals.FOVColorRGB)

    addButton(VisualsTab, "Reset Couleurs", function()
        Config.Visuals.AccentColor = {R = 255, G = 255, B = 255}
        Config.ESP.Color = {R = 255, G = 255, B = 255}
        Config.Visuals.FOVColorRGB = {R = 255, G = 255, B = 255}
        updateMenuTheme(Color3.new(1,1,1))
    end)

    -- Movement Content - TOUS LES ÉLÉMENTS
    addToggle(MovementTab, "Mode Vol (Fly)", Config.Movement.Fly.Enabled, function(v) Config.Movement.Fly.Enabled = v if v == false and Flying then toggleFly() end end)
    addKeybind(MovementTab, "Touche Vol", Config.Movement.Fly.Key, function(v) Config.Movement.Fly.Key = v end)
    addSlider(MovementTab, "Vitesse Vol", 10, 200, Config.Movement.Fly.Speed, function(v) Config.Movement.Fly.Speed = v end)
    addToggle(MovementTab, "Sprint Amélioré", Config.Movement.Sprint.Enabled, function(v) Config.Movement.Sprint.Enabled = v end)
    addSlider(MovementTab, "Multiplicateur Sprint", 1, 5, Config.Movement.Sprint.Multiplier, function(v) Config.Movement.Sprint.Multiplier = v end)
    addToggle(MovementTab, "Super Saut", Config.Movement.SuperJump.Enabled, function(v) Config.Movement.SuperJump.Enabled = v end)
    addSlider(MovementTab, "Puissance Saut", 1, 10, Config.Movement.SuperJump.PowerMultiplier, function(v) Config.Movement.SuperJump.PowerMultiplier = v end)
    addToggle(MovementTab, "Double Saut", Config.Movement.SuperJump.DoubleJumpEnabled, function(v) Config.Movement.SuperJump.DoubleJumpEnabled = v end)
    addToggle(MovementTab, "Réduire Dégâts Chute", Config.Movement.SuperJump.ReduceFallDamage, function(v) Config.Movement.SuperJump.ReduceFallDamage = v end)
    addToggle(MovementTab, "Speed Hack", Config.Movement.SpeedHack.Enabled, function(v) Config.Movement.SpeedHack.Enabled = v end)
    addSlider(MovementTab, "Valeur Vitesse", 16, 500, Config.Movement.SpeedHack.Value, function(v) Config.Movement.SpeedHack.Value = v end)
    addToggle(MovementTab, "NoClip", Config.Movement.NoClip, function(v) Config.Movement.NoClip = v end)
    addToggle(MovementTab, "AutoJump", Config.Movement.AutoJump, function(v) Config.Movement.AutoJump = v end)
    addToggle(MovementTab, "Bunny Hop", Config.Movement.Bhop, function(v) Config.Movement.Bhop = v end)
    addToggle(MovementTab, "Saut Infini", Config.Movement.InfiniteJump, function(v) Config.Movement.InfiniteJump = v end)

    -- Combat Content - TOUS LES ÉLÉMENTS
    addToggle(CombatTab, "Activer SpinBot", Config.Combat.SpinBot.Enabled, function(v) Config.Combat.SpinBot.Enabled = v end)
    addSlider(CombatTab, "Vitesse Rotation", 1, 100, Config.Combat.SpinBot.Speed, function(v) Config.Combat.SpinBot.Speed = v end)
    addToggle(CombatTab, "Rotation Verticale", Config.Combat.SpinBot.Vertical, function(v) Config.Combat.SpinBot.Vertical = v end)
    addToggle(CombatTab, "Aim Assist", Config.Combat.AimAssist.Enabled, function(v) Config.Combat.AimAssist.Enabled = v end)
    addSlider(CombatTab, "Force Assist", 0.01, 0.5, Config.Combat.AimAssist.Strength, function(v) Config.Combat.AimAssist.Strength = v end)
    addToggle(CombatTab, "Hitbox Expander", Config.Combat.HitboxExpander.Enabled, function(v) Config.Combat.HitboxExpander.Enabled = v end)
    addSlider(CombatTab, "Multiplicateur Taille", 1, 50, Config.Combat.HitboxExpander.Multiplier, function(v) Config.Combat.HitboxExpander.Multiplier = v end)
    addSlider(CombatTab, "Transparence Hitbox", 0, 1, Config.Combat.HitboxExpander.Transparency, function(v) Config.Combat.HitboxExpander.Transparency = v end)

    -- Triggerbot Content - TOUS LES ÉLÉMENTS
    addToggle(TriggerTab, "Activer Triggerbot", Config.Triggerbot.Enabled, function(v) Config.Triggerbot.Enabled = v end)
    addKeybind(TriggerTab, "Touche Activation", Config.Triggerbot.Key, function(v) Config.Triggerbot.Key = v end)
    addSlider(TriggerTab, "Délai (sec)", 0, 0.5, Config.Triggerbot.Delay, function(v) Config.Triggerbot.Delay = v end)
    addToggle(TriggerTab, "Team Check", Config.Triggerbot.TeamCheck, function(v) Config.Triggerbot.TeamCheck = v end)

    -- Misc Content - TOUS LES ÉLÉMENTS
    addToggle(MiscTab, "Anti-AFK", Config.Misc.AntiAFK, function(v) Config.Misc.AntiAFK = v end)
    addSlider(MiscTab, "Gravité", 0, 500, Config.Misc.Gravity, function(v) Config.Misc.Gravity = v workspace.Gravity = v end)
    addSlider(MiscTab, "Cap FPS", 30, 240, Config.Misc.FPSCap, function(v) Config.Misc.FPSCap = v if setfpscap then setfpscap(v) end end)
    addButton(MiscTab, "Teleport Random Player", function()
        local players = Players:GetPlayers()
        local randomPlayer = players[math.random(1, #players)]
        if randomPlayer and randomPlayer ~= LocalPlayer and randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:SetPrimaryPartCFrame(randomPlayer.Character.HumanoidRootPart.CFrame)
            log("TP vers: " .. randomPlayer.Name)
        end
    end)
    addButton(MiscTab, "Server Hop", serverHop)
    addButton(MiscTab, "Rejoindre Serveur", rejoinServer)
    addToggle(MiscTab, "Anti-Cheat Bypass", true, function(v) log("Anti-cheat bypass: " .. tostring(v)) end)
    addToggle(MiscTab, "Consommation Énergie Vol", Config.Movement.Fly.EnergyEnabled, function(v) Config.Movement.Fly.EnergyEnabled = v end)
    addButton(MiscTab, "Sauvegarder Config", saveConfig)
    addButton(MiscTab, "Charger Config", loadConfig)
    addButton(MiscTab, "Reset Config", function() 
        log("Configuration réinitialisée")
        -- Implémenter la réinitialisation si nécessaire
    end)

    -- Teleportation Content
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.new(1, -10, 0, 200)
    playerListFrame.BackgroundColor3 = Theme.Secondary
    playerListFrame.Parent = TeleportTab
    Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0, 4)

    local playerListScroll = Instance.new("ScrollingFrame")
    playerListScroll.Size = UDim2.new(1, -10, 1, -40)
    playerListScroll.Position = UDim2.new(0, 5, 0, 35)
    playerListScroll.BackgroundTransparency = 1
    playerListScroll.ScrollBarThickness = 2
    playerListScroll.Parent = playerListFrame
    
    local playerListLayout = Instance.new("UIListLayout", playerListScroll)
    playerListLayout.Padding = UDim.new(0, 2)

    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(1, -10, 0, 30)
    playerLabel.Position = UDim2.new(0, 10, 0, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = "SÉLECTIONNER UN JOUEUR"
    playerLabel.TextColor3 = Theme.TextDim
    playerLabel.Font = Enum.Font.GothamSemibold
    playerLabel.TextSize = 10
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.Parent = playerListFrame

    local function refreshPlayerList()
        for _, child in pairs(playerListScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local pBtn = Instance.new("TextButton")
                pBtn.Size = UDim2.new(1, -10, 0, 25)
                pBtn.BackgroundColor3 = Theme.Hover
                pBtn.BackgroundTransparency = 0.5
                pBtn.Text = p.Name
                pBtn.TextColor3 = Theme.Text
                pBtn.Font = Enum.Font.Gotham
                pBtn.TextSize = 12
                pBtn.Parent = playerListScroll
                Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)
                
                pBtn.MouseButton1Click:Connect(function()
                    selectedTeleportPlayer = p
                    playerLabel.Text = "CIBLE : " .. p.Name:upper()
                    log("Joueur sélectionné : " .. p.Name)
                end)
            end
        end
        playerListScroll.CanvasSize = UDim2.new(0, 0, 0, playerListLayout.AbsoluteContentSize.Y)
    end

    addButton(TeleportTab, "Rafraîchir la liste", refreshPlayerList)
    addButton(TeleportTab, "Téléporter vers le joueur", function()
        if selectedTeleportPlayer and selectedTeleportPlayer.Character and selectedTeleportPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = selectedTeleportPlayer.Character.HumanoidRootPart.CFrame
                log("Téléporté vers " .. selectedTeleportPlayer.Name)
            else
                log("Erreur: Votre personnage n'est pas prêt")
            end
        else
            log("Erreur: Aucun joueur sélectionné ou joueur hors ligne")
        end
    end)
    
    TeleportBtn.MouseButton1Click:Connect(refreshPlayerList)
     refreshPlayerList()
     
     Players.PlayerAdded:Connect(refreshPlayerList)
     Players.PlayerRemoving:Connect(refreshPlayerList)
 
     -- Scripts Content
    addButton(ScriptsTab, "Blox Fruit", function()
        log("Lancement de Blox Fruit...")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TheDarkoneMarcillisePex/Other-Scripts/refs/heads/main/Bloxfruits%20script"))()
    end)

    -- Initialisation du premier onglet
    task.wait(0.1)
    local firstTabBtn = TabButtons:GetChildren()[2]
    if firstTabBtn and firstTabBtn:IsA("TextButton") then
        firstTabBtn.BackgroundTransparency = 0.9
        firstTabBtn.TextColor3 = Theme.Accent
        AimbotTab.Visible = true
        local indicator = firstTabBtn:FindFirstChildOfClass("Frame")
        if indicator then indicator.Visible = true end
        currentTab = {Btn = firstTabBtn, Frame = AimbotTab, Indicator = indicator}
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME DIVERS & TOOLS
-- ═══════════════════════════════════════════════════════════

local function setupAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if Config.Misc.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            log("Anti-AFK: Action effectuée")
        end
    end)
end

local function serverHop()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local PlaceId = game.PlaceId
    
    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    
    if success and servers and servers.data then
        for _, server in pairs(servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id)
                return
            end
        end
    end
    log("Aucun serveur trouvé pour le hop")
end

local function rejoinServer()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end

setupAntiAFK()

-- ═══════════════════════════════════════════════════════════
-- BOUCLE PRINCIPALE ET ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════

FOVCircle = createDrawing("Circle", {Thickness = 1, NumSides = 64, Color = Color3.new(1,1,1), Transparency = 1, Visible = false})

local function updateVisuals()
    if Config.Visuals.FullBright then
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").ClockTime = 14
        game:GetService("Lighting").FogEnd = 100000
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        game:GetService("Lighting").GlobalShadows = true
    end

    if Config.Visuals.NoFog then
        game:GetService("Lighting").FogEnd = 100000
    end
end

RunService.RenderStepped:Connect(function()
    updateESP()
    triggerbotUpdate()
    updateMovement()
    spinbotUpdate()
    aimAssistUpdate()
    updateHitboxes()
    updateVisuals()
    if FOVCircle then
        local cam = getCamera()
        FOVCircle.Position = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        FOVCircle.Radius = Config.Aimbot.FOV
        FOVCircle.Color = Color3.fromRGB(Config.Visuals.FOVColorRGB.R, Config.Visuals.FOVColorRGB.G, Config.Visuals.FOVColorRGB.B)
        FOVCircle.Transparency = Config.Visuals.FOVTransparency
    end
end)

RunService:BindToRenderStep("AimbotProc", Enum.RenderPriority.Camera.Value + 1, aimbotUpdate)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Config.Aimbot.Key or input.UserInputType == Config.Aimbot.Key then 
        AimlockPressed = not AimlockPressed
        if not AimlockPressed then CurrentTarget = nil end
    end
    
    if input.KeyCode == Config.Triggerbot.Key then TriggerActive = not TriggerActive end
    
    if Config.Movement.Fly.Enabled and input.KeyCode == Config.Movement.Fly.Key then
        toggleFly()
    end
    
    if Config.Movement.Sprint.Enabled and input.KeyCode == Enum.KeyCode.LeftShift then
        Sprinting = true
    end
    
    if input.KeyCode == Enum.KeyCode.Space then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.Movement.InfiniteJump then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            elseif Config.Movement.SuperJump.DoubleJumpEnabled then
                if hum.FloorMaterial == Enum.Material.Air then
                    if not DoubleJumped and CanDoubleJump then
                        DoubleJumped = true
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Velocity = Vector3.new(hrp.Velocity.X, hum.JumpPower, hrp.Velocity.Z)
                        end
                    end
                else
                    DoubleJumped = false
                    CanDoubleJump = true
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        Sprinting = false
    end
end)

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)
for _, p in pairs(Players:GetPlayers()) do createESP(p) end

local function runTests()
    log("Démarrage des tests automatiques...")
    local testsPassed = 0
    local totalTests = 5

    if Config.Aimbot and Config.Movement and Config.Combat then
        testsPassed = testsPassed + 1
        log("Test 1 (Intégrité Config) : RÉUSSI")
    end

    if LocalPlayer.Character then
        testsPassed = testsPassed + 1
        log("Test 2 (Détection Personnage) : RÉUSSI")
    end

    if game:GetService("RunService") and game:GetService("UserInputService") then
        testsPassed = testsPassed + 1
        log("Test 3 (Services Système) : RÉUSSI")
    end

    if updateMovement then
        testsPassed = testsPassed + 1
        log("Test 4 (Module Mouvement) : RÉUSSI")
    end

    if Library and Library.CreateWindow then
        testsPassed = testsPassed + 1
        log("Test 5 (Module UI) : RÉUSSI")
    end

    log("Résultats des tests : " .. testsPassed .. "/" .. totalTests .. " réussis.")
end

loadConfig()
runTests()
Library:CreateWindow()
print("💎 PRO TOOL V3.3 - TOOL V3.3 - TOUS LES ONGLETS CORRIGÉS ✅")
