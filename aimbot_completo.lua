--[[
╔══════════════════════════════════════════════════════════════════╗
║        🔥 AIMBOT + SILENT + ESP COMPLETO v5.0 🔥               ║
║                                                                  ║
║  🎯 Aimbot com FOV (trava na cabeça dentro do círculo)          ║
║  🔫 Silent Aim (bala vai no alvo sem mover a câmera)            ║
║  📍 ESP Line (linha do seu hip até os outros)                   ║
║  📦 ESP Box (box branca fina em volta do jogador)               ║
║  ❤️ ESP Health (barra de vida verde > amarelo > vermelho)       ║
║  👻 Tudo visível através de paredes                             ║
╚══════════════════════════════════════════════════════════════════╝
--]]

-- ================================================================
-- ⚙ CONFIGURAÇÕES
-- ================================================================
local CONFIG = {
    AimKey = "F",
    ToggleKey = "Insert",
    HideKey = "RightControl",
    FOVRadius = 80,
    FOVColor = Color3.fromRGB(0, 200, 255),
    LockColor = Color3.fromRGB(255, 50, 50),
    MaxDistance = 2000,
    ESPColor = Color3.fromRGB(255, 255, 255),
    ESPThickness = 1,
}

-- ================================================================
-- ⚡ SERVIÇOS
-- ================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ================================================================
-- 🔧 VARIÁVEIS DE ESTADO
-- ================================================================
local AimbotEnabled = false
local SilentAimEnabled = false
local VisibleCheckEnabled = true
local ESPLineEnabled = true
local ESPBoxEnabled = false
local ESPHealthEnabled = false

local CurrentTarget = nil
local ESPObjects = {}
local DrawingAvailable = false

-- Verifica se Drawing API está disponível
pcall(function()
    local test = Drawing.new("Line")
    test:Remove()
    DrawingAvailable = true
end)

-- ================================================================
-- 📦 CRIAR GUI
-- ================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotCompleteGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

local ok, err = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ================================================================
-- 🖼 FUNÇÕES AUXILIARES DE UI
-- ================================================================
local function Tween(obj, props, dur, style, dir)
    local info = TweenInfo.new(dur or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function MakeStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(255, 255, 255)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

-- ================================================================
-- 🖼 CRIAR TOGGLE SWITCH (genérico)
-- ================================================================
local function CreateToggle(parent, yPos, label, getState, setState)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9, 0, 0, 28)
    frame.Position = UDim2.new(0.05, 0, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = parent

    MakeCorner(frame, 8)

    local textLbl = Instance.new("TextLabel")
    textLbl.Size = UDim2.new(1, -45, 1, 0)
    textLbl.Position = UDim2.new(0, 10, 0, 0)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = label
    textLbl.TextColor3 = Color3.fromRGB(170, 170, 170)
    textLbl.TextSize = 12
    textLbl.Font = Enum.Font.Gotham
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.Parent = frame

    local switch = Instance.new("Frame")
    switch.Size = UDim2.new(0, 36, 0, 20)
    switch.Position = UDim2.new(1, -42, 0.5, -10)
    switch.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    switch.BorderSizePixel = 0
    switch.Parent = frame

    MakeCorner(switch, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch

    MakeCorner(knob, 7)

    local function UpdateVisuals()
        if getState() then
            Tween(switch, { BackgroundColor3 = Color3.fromRGB(0, 200, 80) }, 0.2)
            Tween(knob, { Position = UDim2.new(0, 19, 0.5, -7) }, 0.2)
        else
            Tween(switch, { BackgroundColor3 = Color3.fromRGB(50, 50, 70) }, 0.2)
            Tween(knob, { Position = UDim2.new(0, 3, 0.5, -7) }, 0.2)
        end
    end

    local btn = Instance.new("ImageButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.ImageTransparency = 1
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        setState(not getState())
        UpdateVisuals()
    end)

    UpdateVisuals()
    return frame
end

-- ================================================================
-- 🖼 CONSTRUIR PAINEL
-- ================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 540)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
MainFrame.BackgroundTransparency = 0.12
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

MakeCorner(MainFrame, 16)
MakeStroke(MainFrame, Color3.fromRGB(0, 180, 255), 1.5, 0.5)

-- TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 16, 35)
TitleBar.BackgroundTransparency = 0.2
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
MakeCorner(TitleBar, 16)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎯 AIMBOT COMPLETO"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Parent = TitleBar

local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(0.9, 0, 0, 1)
Sep.Position = UDim2.new(0.05, 0, 0, 45)
Sep.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
Sep.BackgroundTransparency = 0.6
Sep.BorderSizePixel = 0
Sep.Parent = MainFrame

-- STATUS
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(0.9, 0, 0, 28)
StatusFrame.Position = UDim2.new(0.05, 0, 0, 52)
StatusFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
StatusFrame.BackgroundTransparency = 0.4
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = MainFrame
MakeCorner(StatusFrame, 8)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(0, 10, 0.5, -4)
StatusDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusFrame
MakeCorner(StatusDot, 4)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -25, 1, 0)
StatusLabel.Position = UDim2.new(0, 22, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: DESATIVADO"
StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

-- BOTÃO AIMBOT PRINCIPAL
local AimbotButton = Instance.new("ImageButton")
AimbotButton.Size = UDim2.new(0.9, 0, 0, 50)
AimbotButton.Position = UDim2.new(0.05, 0, 0, 88)
AimbotButton.BackgroundColor3 = Color3.fromRGB(20, 28, 50)
AimbotButton.BackgroundTransparency = 0.2
AimbotButton.BorderSizePixel = 0
AimbotButton.AutoButtonColor = false
AimbotButton.Parent = MainFrame
MakeCorner(AimbotButton, 10)

local BtnStroke = MakeStroke(AimbotButton, Color3.fromRGB(0, 180, 255), 1.2, 0.6)

local BtnIcon = Instance.new("TextLabel")
BtnIcon.Size = UDim2.new(0, 35, 1, 0)
BtnIcon.Position = UDim2.new(0, 8, 0, 0)
BtnIcon.BackgroundTransparency = 1
BtnIcon.Text = "🎯"
BtnIcon.TextSize = 20
BtnIcon.Parent = AimbotButton

local ButtonLabel = Instance.new("TextLabel")
ButtonLabel.Size = UDim2.new(1, -55, 1, 0)
ButtonLabel.Position = UDim2.new(0, 48, 0, 0)
ButtonLabel.BackgroundTransparency = 1
ButtonLabel.Text = "ATIVAR AIMBOT"
ButtonLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ButtonLabel.TextSize = 14
ButtonLabel.Font = Enum.Font.GothamBold
ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left
ButtonLabel.Parent = AimbotButton

local ToggleSwitch = Instance.new("Frame")
ToggleSwitch.Size = UDim2.new(0, 40, 0, 22)
ToggleSwitch.Position = UDim2.new(1, -50, 0.5, -11)
ToggleSwitch.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
ToggleSwitch.BorderSizePixel = 0
ToggleSwitch.Parent = AimbotButton
MakeCorner(ToggleSwitch, 11)

local ToggleKnob = Instance.new("Frame")
ToggleKnob.Size = UDim2.new(0, 16, 0, 16)
ToggleKnob.Position = UDim2.new(0, 3, 0.5, -8)
ToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleKnob.BorderSizePixel = 0
ToggleKnob.Parent = ToggleSwitch
MakeCorner(ToggleKnob, 8)

-- TEXTBOX
local TbLabel = Instance.new("TextLabel")
TbLabel.Size = UDim2.new(0.9, 0, 0, 22)
TbLabel.Position = UDim2.new(0.05, 0, 0, 148)
TbLabel.BackgroundTransparency = 1
TbLabel.Text = "⚙ TECLA DE ATALHO"
TbLabel.TextColor3 = Color3.fromRGB(140, 140, 180)
TbLabel.TextSize = 11
TbLabel.Font = Enum.Font.GothamSemibold
TbLabel.TextXAlignment = Enum.TextXAlignment.Left
TbLabel.Parent = MainFrame

local TbFrame = Instance.new("Frame")
TbFrame.Size = UDim2.new(0.9, 0, 0, 36)
TbFrame.Position = UDim2.new(0.05, 0, 0, 172)
TbFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 38)
TbFrame.BackgroundTransparency = 0.3
TbFrame.BorderSizePixel = 0
TbFrame.Parent = MainFrame
MakeCorner(TbFrame, 8)
MakeStroke(TbFrame, Color3.fromRGB(50, 50, 90), 1, 0.5)

local KeyTextBox = Instance.new("TextBox")
KeyTextBox.Size = UDim2.new(1, -16, 1, 0)
KeyTextBox.Position = UDim2.new(0, 8, 0, 0)
KeyTextBox.BackgroundTransparency = 1
KeyTextBox.PlaceholderText = CONFIG.AimKey
KeyTextBox.Text = CONFIG.AimKey
KeyTextBox.TextColor3 = Color3.fromRGB(200, 200, 255)
KeyTextBox.TextSize = 16
KeyTextBox.Font = Enum.Font.GothamBold
KeyTextBox.ClearTextOnFocus = false
KeyTextBox.Parent = TbFrame

-- LABEL SEÇÃO: AIMBOT
local aimSec = Instance.new("TextLabel")
aimSec.Size = UDim2.new(0.9, 0, 0, 22)
aimSec.Position = UDim2.new(0.05, 0, 0, 218)
aimSec.BackgroundTransparency = 1
aimSec.Text = "🎯 CONFIGURAÇÕES DO AIMBOT"
aimSec.TextColor3 = Color3.fromRGB(140, 140, 180)
aimSec.TextSize = 11
aimSec.Font = Enum.Font.GothamSemibold
aimSec.TextXAlignment = Enum.TextXAlignment.Left
aimSec.Parent = MainFrame

-- VISIBLE CHECK TOGGLE
CreateToggle(MainFrame, 242, "Visible Check (ignorar paredes)",
    function() return VisibleCheckEnabled end,
    function(v) VisibleCheckEnabled = v end)

-- LABEL SEÇÃO: SILENT
local silSec = Instance.new("TextLabel")
silSec.Size = UDim2.new(0.9, 0, 0, 22)
silSec.Position = UDim2.new(0.05, 0, 0, 278)
silSec.BackgroundTransparency = 1
silSec.Text = "🔫 SILENT AIM"
silSec.TextColor3 = Color3.fromRGB(140, 140, 180)
silSec.TextSize = 11
silSec.Font = Enum.Font.GothamSemibold
silSec.TextXAlignment = Enum.TextXAlignment.Left
silSec.Parent = MainFrame

-- SILENT AIM TOGGLE
CreateToggle(MainFrame, 302, "Silent Aim (bala no alvo)",
    function() return SilentAimEnabled end,
    function(v) SilentAimEnabled = v end)

-- LABEL SEÇÃO: ESP
local espSec = Instance.new("TextLabel")
espSec.Size = UDim2.new(0.9, 0, 0, 22)
espSec.Position = UDim2.new(0.05, 0, 0, 338)
espSec.BackgroundTransparency = 1
espSec.Text = "📍 ESP"
espSec.TextColor3 = Color3.fromRGB(140, 140, 180)
espSec.TextSize = 11
espSec.Font = Enum.Font.GothamSemibold
espSec.TextXAlignment = Enum.TextXAlignment.Left
espSec.Parent = MainFrame

-- ESP LINE TOGGLE
CreateToggle(MainFrame, 362, "ESP Line (hip to hip)",
    function() return ESPLineEnabled end,
    function(v) ESPLineEnabled = v end)

-- ESP BOX TOGGLE
CreateToggle(MainFrame, 394, "ESP Box (caixa no jogador)",
    function() return ESPBoxEnabled end,
    function(v) ESPBoxEnabled = v end)

-- ESP HEALTH TOGGLE
CreateToggle(MainFrame, 426, "ESP Health (barra de vida)",
    function() return ESPHealthEnabled end,
    function(v) ESPHealthEnabled = v end)

-- FOOTER
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0, 28)
Footer.Position = UDim2.new(0, 0, 1, -28)
Footer.BackgroundTransparency = 1
Footer.Text = "FOV | AIM | SILENT | ESP LINE | BOX | HEALTH"
Footer.TextColor3 = Color3.fromRGB(80, 80, 120)
Footer.TextSize = 9
Footer.Font = Enum.Font.Gotham
Footer.Parent = MainFrame

-- ================================================================
-- ⭕ FOV - CÍRCULO LIMPO (sem crosshair bugado)
-- ================================================================
local FOVCircle = Instance.new("ImageLabel")
FOVCircle.Name = "FOVCircle"
FOVCircle.Size = UDim2.new(0, CONFIG.FOVRadius * 2, 0, CONFIG.FOVRadius * 2)
FOVCircle.Position = UDim2.new(0.5, -CONFIG.FOVRadius, 0.5, -CONFIG.FOVRadius)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Image = "rbxassetid://2661626982"
FOVCircle.ImageColor3 = CONFIG.FOVColor
FOVCircle.ImageTransparency = 0.25
FOVCircle.ScaleType = Enum.ScaleType.Fit
FOVCircle.Visible = false
FOVCircle.Parent = ScreenGui

local FOVInner = Instance.new("ImageLabel")
FOVInner.Size = UDim2.new(0.9, 0, 0.9, 0)
FOVInner.Position = UDim2.new(0.05, 0, 0.05, 0)
FOVInner.BackgroundTransparency = 1
FOVInner.Image = "rbxassetid://2661626982"
FOVInner.ImageColor3 = CONFIG.FOVColor
FOVInner.ImageTransparency = 0.85
FOVInner.Parent = FOVCircle

-- ================================================================
-- 🧠 FUNÇÕES DO JOGADOR
-- ================================================================
local function IsAlive(plr)
    return plr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0
end

local function GetHead(plr)
    if plr and plr.Character then
        return plr.Character:FindFirstChild("Head")
    end
    return nil
end

local function GetHip(plr)
    if plr and plr.Character then
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
        local torso = plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("UpperTorso")
        if torso then return torso end
    end
    return nil
end

local function GetHumanoid(plr)
    if plr and plr.Character then
        return plr.Character:FindFirstChild("Humanoid")
    end
    return nil
end

local function IsVisible(part)
    if not part then return false end
    if not VisibleCheckEnabled then return true end
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin).Unit
    local dist = (part.Position - origin).Magnitude
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(origin, dir * dist, params)
    if result and result.Instance then
        return result.Instance:IsDescendantOf(LocalPlayer.Character)
    end
    return true
end

-- ================================================================
-- 🎯 AIMBOT - ALVO DENTRO DO FOV
-- ================================================================
local function GetTargetInFOV()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best = nil
    local bestDist = CONFIG.FOVRadius

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            local head = GetHead(plr)
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= bestDist and IsVisible(head) then
                        if d < bestDist then
                            best = plr
                            bestDist = d
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ================================================================
-- 🔁 LOOP AIMBOT
-- ================================================================
RunService:BindToRenderStep("AimbotLoop", 200, function()
    FOVCircle.Visible = AimbotEnabled

    if not AimbotEnabled then
        CurrentTarget = nil
        FOVCircle.ImageColor3 = CONFIG.FOVColor
        FOVInner.ImageColor3 = CONFIG.FOVColor
        return
    end

    local newTarget = GetTargetInFOV()
    if newTarget then
        CurrentTarget = newTarget
    end

    if CurrentTarget and IsAlive(CurrentTarget) then
        local head = GetHead(CurrentTarget)
        if head then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            FOVCircle.ImageColor3 = CONFIG.LockColor
            FOVInner.ImageColor3 = CONFIG.LockColor
        else
            CurrentTarget = nil
            FOVCircle.ImageColor3 = CONFIG.FOVColor
            FOVInner.ImageColor3 = CONFIG.FOVColor
        end
    else
        CurrentTarget = nil
        FOVCircle.ImageColor3 = CONFIG.FOVColor
        FOVInner.ImageColor3 = CONFIG.FOVColor
    end
end)

-- ================================================================
-- 🔫 SILENT AIM - Hook no Mouse.Hit e Mouse.Target
-- ================================================================
if DrawingAvailable then
    local __index
    __index = hookmetamethod(game, "__index", function(self, key)
        if SilentAimEnabled and CurrentTarget and IsAlive(CurrentTarget) and (self == Mouse or self == LocalPlayer:GetMouse()) then
            local head = GetHead(CurrentTarget)
            if head then
                if key == "Hit" then
                    return CFrame.new(head.Position)
                end
                if key == "Target" then
                    return head
                end
            end
        end
        return __index(self, key)
    end)
end

-- ================================================================
-- 📍 DESENHAR ESP (Drawing API)
-- ================================================================
if DrawingAvailable then
    -- Cache de objetos Drawing por jogador
    local ESPDraw = {}

    local function GetESP(plr)
        if not ESPDraw[plr] then
            ESPDraw[plr] = {}
        end
        return ESPDraw[plr]
    end

    local function EnsureLine(plr, name)
        local tbl = GetESP(plr)
        if not tbl[name] then
            local line = Drawing.new("Line")
            line.Color = CONFIG.ESPColor
            line.Thickness = CONFIG.ESPThickness
            line.Transparency = 1
            line.Visible = false
            tbl[name] = line
        end
        return tbl[name]
    end

    local function EnsureSquare(plr)
        local tbl = GetESP(plr)
        local needed = {"BoxTop", "BoxBot", "BoxLef", "BoxRig"}
        for _, name in ipairs(needed) do
            if not tbl[name] then
                local line = Drawing.new("Line")
                line.Color = CONFIG.ESPColor
                line.Thickness = CONFIG.ESPThickness
                line.Transparency = 1
                line.Visible = false
                tbl[name] = line
            end
        end
    end

    local function EnsureHealth(plr)
        local tbl = GetESP(plr)
        local needed = {"HealthBg", "HealthFill", "HealthOutline"}
        for _, name in ipairs(needed) do
            if not tbl[name] then
                local line
                if name == "HealthOutline" then
                    line = Drawing.new("Square")
                    line.Color = Color3.fromRGB(200, 200, 200)
                    line.Thickness = 1
                    line.Transparency = 1
                    line.Visible = false
                else
                    line = Drawing.new("Line")
                    line.Thickness = 1
                    line.Transparency = 1
                    line.Visible = false
                end
                tbl[name] = line
            end
        end
    end

    -- Limpeza de jogadores que saíram
    local function CleanupESP()
        for plr, tbl in pairs(ESPDraw) do
            if not Players:FindFirstChild(plr.Name) then
                for _, obj in pairs(tbl) do
                    obj:Remove()
                end
                ESPDraw[plr] = nil
            end
        end
    end

    -- ================================================================
    -- 📍 LOOP PRINCIPAL DO ESP
    -- ================================================================
    RunService:BindToRenderStep("ESPLoop", 199, function()
        CleanupESP()

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer or not IsAlive(plr) then
                -- Esconder tudo do jogador morto
                local tbl = ESPDraw[plr]
                if tbl then
                    for _, obj in pairs(tbl) do
                        obj.Visible = false
                    end
                end
                continue
            end

            local myHip = GetHip(LocalPlayer)
            local targetHip = GetHip(plr)
            local head = GetHead(plr)

            if not myHip or not targetHip or not head then
                local tbl = ESPDraw[plr]
                if tbl then
                    for _, obj in pairs(tbl) do
                        obj.Visible = false
                    end
                end
                continue
            end

            local myPos, targetPos, headPos
            local myScreen = Camera:WorldToViewportPoint(myHip.Position)
            local targetScreen = Camera:WorldToViewportPoint(targetHip.Position)
            local headScreen = Camera:WorldToViewportPoint(head.Position)

            -- ================================
            -- ESP LINE
            -- ================================
            if ESPLineEnabled then
                local line = EnsureLine(plr, "ESPLine")
                line.From = Vector2.new(myScreen.X, myScreen.Y)
                line.To = Vector2.new(targetScreen.X, targetScreen.Y)
                line.Visible = true
                line.Color = Color3.fromRGB(255, 255, 255)
                line.Thickness = 1
            else
                local line = EnsureLine(plr, "ESPLine")
                line.Visible = false
            end

            -- ================================
            -- ESP BOX (caixa ao redor do jogador)
            -- ================================
            if ESPBoxEnabled then
                EnsureSquare(plr)
                local tbl = ESPDraw[plr]

                -- Calcular tamanho baseado na distância
                local dist = (targetHip.Position - Camera.CFrame.Position).Magnitude
                local boxHeight = (headScreen.Y - targetScreen.Y) * 1.3
                local boxWidth = boxHeight * 0.6
                local boxX = targetScreen.X - boxWidth / 2
                local boxY = headScreen.Y - (boxHeight * 0.15)

                -- Top
                tbl["BoxTop"].From = Vector2.new(boxX, boxY)
                tbl["BoxTop"].To = Vector2.new(boxX + boxWidth, boxY)
                tbl["BoxTop"].Visible = true
                tbl["BoxTop"].Color = CONFIG.ESPColor
                tbl["BoxTop"].Thickness = 1

                -- Bottom
                tbl["BoxBot"].From = Vector2.new(boxX, boxY + boxHeight)
                tbl["BoxBot"].To = Vector2.new(boxX + boxWidth, boxY + boxHeight)
                tbl["BoxBot"].Visible = true
                tbl["BoxBot"].Color = CONFIG.ESPColor
                tbl["BoxBot"].Thickness = 1

                -- Left
                tbl["BoxLef"].From = Vector2.new(boxX, boxY)
                tbl["BoxLef"].To = Vector2.new(boxX, boxY + boxHeight)
                tbl["BoxLef"].Visible = true
                tbl["BoxLef"].Color = CONFIG.ESPColor
                tbl["BoxLef"].Thickness = 1

                -- Right
                tbl["BoxRig"].From = Vector2.new(boxX + boxWidth, boxY)
                tbl["BoxRig"].To = Vector2.new(boxX + boxWidth, boxY + boxHeight)
                tbl["BoxRig"].Visible = true
                tbl["BoxRig"].Color = CONFIG.ESPColor
                tbl["BoxRig"].Thickness = 1
            else
                local tbl = ESPDraw[plr]
                if tbl then
                    local names = {"BoxTop", "BoxBot", "BoxLef", "BoxRig"}
                    for _, n in ipairs(names) do
                        if tbl[n] then tbl[n].Visible = false end
                    end
                end
            end

            -- ================================
            -- ESP HEALTH (barra de vida)
            -- ================================
            if ESPHealthEnabled then
                EnsureHealth(plr)
                local tbl = ESPDraw[plr]
                local humanoid = GetHumanoid(plr)
                if humanoid then
                    local health = humanoid.Health
                    local maxHealth = humanoid.MaxHealth
                    local pct = math.clamp(health / maxHealth, 0, 1)

                    local dist = (targetHip.Position - Camera.CFrame.Position).Magnitude
                    local boxHeight = (headScreen.Y - targetScreen.Y) * 1.3
                    local boxWidth = boxHeight * 0.6
                    local boxX = targetScreen.X - boxWidth / 2
                    local boxY = headScreen.Y - (boxHeight * 0.15)

                    -- Posição da barra (lado direito da box)
                    local barX = boxX + boxWidth + 3
                    local barWidth = 4
                    local barHeight = boxHeight
                    local fillHeight = barHeight * pct

                    -- Cor baseada na vida
                    local hColor
                    if pct > 0.6 then
                        hColor = Color3.fromRGB(0, 255, 50)       -- Verde
                    elseif pct > 0.35 then
                        hColor = Color3.fromRGB(255, 255, 0)      -- Amarelo
                    elseif pct > 0.15 then
                        hColor = Color3.fromRGB(255, 150, 0)      -- Laranja
                    else
                        hColor = Color3.fromRGB(255, 0, 0)        -- Vermelho
                    end

                    -- Background (fundo escuro)
                    tbl["HealthBg"].From = Vector2.new(barX, barY)
                    tbl["HealthBg"].To = Vector2.new(barX + barWidth, barY + barHeight)
                    tbl["HealthBg"].Color = Color3.fromRGB(30, 30, 30)
                    tbl["HealthBg"].Thickness = barWidth + 2
                    tbl["HealthBg"].Visible = true

                    -- Fill (preenchimento da vida)
                    tbl["HealthFill"].From = Vector2.new(barX, barY + barHeight - fillHeight)
                    tbl["HealthFill"].To = Vector2.new(barX + barWidth, barY + barHeight - fillHeight)
                    tbl["HealthFill"].Color = hColor
                    tbl["HealthFill"].Thickness = barWidth + 2
                    tbl["HealthFill"].Visible = true

                    -- Outline (borda)
                    tbl["HealthOutline"].From = Vector2.new(barX - 1, barY - 1)
                    tbl["HealthOutline"].To = Vector2.new(barX + barWidth + 1, barY + barHeight + 1)
                    tbl["HealthOutline"].Visible = true
                end
            else
                local tbl = ESPDraw[plr]
                if tbl then
                    local names = {"HealthBg", "HealthFill", "HealthOutline"}
                    for _, n in ipairs(names) do
                        if tbl[n] then tbl[n].Visible = false end
                    end
                end
            end
        end
    end)

    -- Criação inicial de ESP para jogadores existentes
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            EnsureLine(plr, "ESPLine")
        end
    end

    Players.PlayerAdded:Connect(function(plr)
        if plr ~= LocalPlayer then
            EnsureLine(plr, "ESPLine")
        end
    end)
end

-- ================================================================
-- 🎮 CONTROLES
-- ================================================================
local function ToggleAimbot()
    AimbotEnabled = not AimbotEnabled
    UpdateUI(AimbotEnabled)
    if not AimbotEnabled then CurrentTarget = nil end
end

local function UpdateUI(state)
    if state then
        Tween(ToggleSwitch, { BackgroundColor3 = Color3.fromRGB(0, 200, 80) }, 0.25)
        Tween(ToggleKnob, { Position = UDim2.new(0, 21, 0.5, -8) }, 0.25)
        Tween(StatusDot, { BackgroundColor3 = Color3.fromRGB(0, 255, 50) }, 0.25)
        Tween(BtnStroke, { Color = Color3.fromRGB(0, 255, 100), Transparency = 0.3 }, 0.25)
        StatusLabel.Text = "Status: ATIVADO"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 50)
        ButtonLabel.Text = "DESATIVAR AIMBOT"
    else
        Tween(ToggleSwitch, { BackgroundColor3 = Color3.fromRGB(50, 50, 70) }, 0.25)
        Tween(ToggleKnob, { Position = UDim2.new(0, 3, 0.5, -8) }, 0.25)
        Tween(StatusDot, { BackgroundColor3 = Color3.fromRGB(255, 50, 50) }, 0.25)
        Tween(BtnStroke, { Color = Color3.fromRGB(0, 180, 255), Transparency = 0.6 }, 0.25)
        StatusLabel.Text = "Status: DESATIVADO"
        StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
        ButtonLabel.Text = "ATIVAR AIMBOT"
    end
end

AimbotButton.MouseButton1Click:Connect(ToggleAimbot)

AimbotButton.MouseEnter:Connect(function()
    if not AimbotEnabled then
        Tween(AimbotButton, { BackgroundColor3 = Color3.fromRGB(28, 40, 70) }, 0.2)
    end
end)
AimbotButton.MouseLeave:Connect(function()
    Tween(AimbotButton, { BackgroundColor3 = Color3.fromRGB(20, 28, 50) }, 0.2)
end)

-- Teclas
UserInputService.InputBegan:Connect(function(input, gpo)
    if gpo then return end

    local key = KeyTextBox.Text:upper():sub(1, 1)
    if key == "" then key = "F" end
    KeyTextBox.Text = key

    if input.KeyCode == Enum.KeyCode[key] then ToggleAimbot() end
    if input.KeyCode == Enum.KeyCode.Insert then ToggleAimbot() end
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ================================================================
-- 🔄 DRAG
-- ================================================================
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ================================================================
-- 🚀 ANIMAÇÃO DE ENTRADA
-- ================================================================
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundTransparency = 1
Tween(MainFrame, {
    Size = UDim2.new(0, 280, 0, 540),
    BackgroundTransparency = 0.12
}, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ================================================================
-- ✅ LOG
-- ================================================================
print("╔══════════════════════════════════════════════════════════════╗")
print("║   🔥 AIMBOT + SILENT + ESP COMPLETO v5.0 CARREGADO         ║")
print("║                                                            ║")
print("║  🎯 Aimbot por FOV (trava na cabeça)                       ║")
print("║  🔫 Silent Aim (bala vai no alvo sem mover câmera)         ║")
print("║  📍 ESP Line (linha hip to hip)                            ║")
print("║  📦 ESP Box (caixa branca fina)                            ║")
print("║  ❤️ ESP Health (barra verde/amarelo/laranja/vermelho)      ║")
print("║  👻 Tudo visível através de paredes                        ║")
print("║                                                            ║")
print("║  [F] Toggle aimbot | [Insert] Toggle rápido                ║")
print("║  [Ctrl] Esconder UI                                        ║")
print("╚══════════════════════════════════════════════════════════════╝")
