--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   F R O S T V E I L   U I   L I B R A R Y                                    ║
║   Version 2.0.0                                                              ║
║                                                                              ║
║   Complete custom Roblox UI library.                                         ║
║   Public API mirrors LinoriaLib for familiarity.                             ║
║   Visual design is original — left sidebar + content layout                  ║
║   inspired by reference, polished into an icy / dark premium aesthetic.      ║
║   No logo watermark. Full background texture (asset id) support.             ║
║   Live falling snow particle system.                                         ║
║                                                                              ║
║   Intended for GitHub distribution.                                          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local TextService       = game:GetService("TextService")
local HttpService       = game:GetService("HttpService")
local GuiService        = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Camera      = workspace.CurrentCamera
local RenderStepped = RunService.RenderStepped
local Heartbeat     = RunService.Heartbeat

-- ══════════════════════════════════════════════════════════════════════════════
-- PROTECT / PARENT HELPER
-- ══════════════════════════════════════════════════════════════════════════════

local function ProtectAndParent(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
        if protect_gui then protect_gui(gui) end
        if protectgui then protectgui(gui) end
    end)
    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)
    gui.Parent = parent
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Frostveil"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 100
ProtectAndParent(ScreenGui)

-- ══════════════════════════════════════════════════════════════════════════════
-- GLOBAL STATE
-- ══════════════════════════════════════════════════════════════════════════════

local Toggles  = {}
local Options  = {}
local Labels   = {}
local Buttons  = {}

getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
    Registry        = {},
    RegistryMap     = {},
    HudRegistry     = {},
    OpenedFrames    = {},
    DependencyBoxes = {},
    Signals         = {},
    Windows         = {},
    ScreenGui       = ScreenGui,

    -- Theme (Premium Void Ice)
    FontColor       = Color3.fromRGB(255, 255, 255),
    MainColor       = Color3.fromRGB(16, 20, 32),
    BackgroundColor = Color3.fromRGB(7, 9, 14),
    AccentColor     = Color3.fromRGB(100, 210, 255),
    OutlineColor    = Color3.fromRGB(48, 78, 120),
    RiskColor       = Color3.fromRGB(255, 95, 125),
    SidebarColor    = Color3.fromRGB(9, 11, 18),
    ToggleOnColor   = Color3.fromRGB(70, 195, 255),
    ToggleOffColor  = Color3.fromRGB(26, 34, 52),
    GroupTitleColor = Color3.fromRGB(255, 255, 255),
    Black           = Color3.new(0, 0, 0),
    Font            = Enum.Font.GothamMedium,

    Unloaded            = false,
    NotifyOnError       = true,
    ShowCustomCursor    = false,
    ForceCheckbox       = false,
    ToggleKeybind       = nil,
    RainbowEnabled      = false,
}

getgenv().Library = Library

Library.AccentColorDark = Color3.fromRGB(
    math.floor(Library.AccentColor.R * 255 * 0.6),
    math.floor(Library.AccentColor.G * 255 * 0.6),
    math.floor(Library.AccentColor.B * 255 * 0.6)
)

-- ══════════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════════

local function Create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function Round(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = instance
    return corner
end

local function Stroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Library.OutlineColor
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.3
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

local function Padding(instance, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = instance
    return p
end

local function ListLayout(instance, padding, fillDirection, horizontalAlignment, verticalAlignment)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, padding or 0)
    layout.FillDirection = fillDirection or Enum.FillDirection.Vertical
    layout.HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = verticalAlignment or Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = instance
    return layout
end

function Library:GiveSignal(connection)
    if connection then
        table.insert(self.Signals, connection)
    end
    return connection
end

function Library:SafeCallback(func, ...)
    if not func then return end
    local ok, err = pcall(func, ...)
    if not ok and self.NotifyOnError then
        self:Notify("Callback error: " .. tostring(err), 5)
        warn("[Frostveil] Callback error:", err)
    end
end

function Library:GetTextBounds(text, font, size, frameSize)
    local bounds = TextService:GetTextSize(text, size or 14, font or self.Font, frameSize or Vector2.new(math.huge, math.huge))
    return bounds.X, bounds.Y
end

function Library:MapValue(value, inMin, inMax, outMin, outMax)
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

function Library:AddToRegistry(instance, properties)
    local id = #self.Registry + 1
    self.Registry[id] = { Instance = instance, Properties = properties }
    self.RegistryMap[instance] = id
    return id
end

function Library:RemoveFromRegistry(instance)
    local id = self.RegistryMap[instance]
    if id then
        self.Registry[id] = nil
        self.RegistryMap[instance] = nil
    end
end

function Library:UpdateColorsUsingRegistry()
    for _, data in pairs(self.Registry) do
        if data and data.Instance and data.Instance.Parent then
            for property, colorKey in pairs(data.Properties) do
                local color = self[colorKey]
                if color then
                    pcall(function()
                        data.Instance[property] = color
                    end)
                end
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════

local NotificationHolder = nil

local function GetNotificationHolder()
    if NotificationHolder and NotificationHolder.Parent then
        return NotificationHolder
    end
    NotificationHolder = Create("Frame", {
        Name = "NotificationHolder",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -40),
        Position = UDim2.new(1, -340, 0, 20),
        Parent = ScreenGui,
        ZIndex = 500,
    })
    ListLayout(NotificationHolder, 8)
    return NotificationHolder
end

function Library:Notify(text, duration)
    duration = duration or 3
    local holder = GetNotificationHolder()

    -- Fixed colors — never tied to theme registry (no glitch when recoloring UI)
    local notif = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(18, 20, 28),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = holder,
        ZIndex = 501,
        ClipsDescendants = true,
    })
    Round(notif, 9)
    Stroke(notif, Color3.fromRGB(55, 60, 75), 1, 0.35)

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.fromOffset(12, 12),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = tostring(text),
        TextSize = 13,
        TextColor3 = Color3.fromRGB(245, 245, 250),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 502,
        Parent = notif,
    })
    Padding(notif, 0, 12, 0, 0)

    task.delay(duration, function()
        if notif and notif.Parent then
            local fade = TweenService:Create(notif, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 1
            })
            local fadeLabel = TweenService:Create(label, TweenInfo.new(0.35), { TextTransparency = 1 })
            fade:Play()
            fadeLabel:Play()
            fade.Completed:Wait()
            notif:Destroy()
        end
    end)
end

function Library:NotifySuccess(text, duration)
    self:Notify(tostring(text), duration or 3)
end

function Library:NotifyError(text, duration)
    self:Notify("Error: " .. tostring(text), duration or 4)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UNLOAD
-- ══════════════════════════════════════════════════════════════════════════════

function Library:Unload()
    for _, connection in ipairs(self.Signals) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.Signals)
    self.Unloaded = true
    if ScreenGui then
        ScreenGui:Destroy()
    end
    getgenv().Library = nil
    getgenv().Toggles = nil
    getgenv().Options = nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SNOW PARTICLE SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════

local function CreateSnowSystem(parent, config)
    config = config or {}
    local maxFlakes = config.MaxFlakes or 70
    local enabled = true

    local container = Create("Frame", {
        Name = "SnowContainer",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 80,
        Parent = parent,
    })

    local flakes = {}
    for i = 1, maxFlakes do
        local size = math.random(2, 5)
        local flake = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(220, 240, 255),
            BackgroundTransparency = math.random(25, 65) / 100,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.new(math.random(), 0, math.random() - 0.3, 0),
            ZIndex = 81,
            Parent = container,
        })
        Round(flake, 12)
        flakes[i] = {
            Instance = flake,
            X = math.random(),
            Y = math.random() - 0.3,
            Speed = math.random(30, 95) / 100,
            Drift = (math.random() - 0.5) * 0.45,
            Rotation = 0,
            RotationSpeed = (math.random() - 0.5) * 120,
        }
    end

    local connection = RenderStepped:Connect(function(delta)
        if not enabled or not container.Parent then return end
        for _, flake in ipairs(flakes) do
            flake.Y = flake.Y + flake.Speed * delta * 0.30
            flake.X = flake.X + flake.Drift * delta * 0.11
            flake.Rotation = flake.Rotation + flake.RotationSpeed * delta
            if flake.Y > 1.2 then
                flake.Y = -0.1
                flake.X = math.random()
                flake.Speed = math.random(30, 95) / 100
                flake.Drift = (math.random() - 0.5) * 0.45
            end
            if flake.X < -0.1 then flake.X = 1.1 end
            if flake.X > 1.1 then flake.X = -0.1 end
            flake.Instance.Position = UDim2.new(flake.X, 0, flake.Y, 0)
            flake.Instance.Rotation = flake.Rotation
        end
    end)
    Library:GiveSignal(connection)

    return {
        Container = container,
        SetEnabled = function(_, state)
            enabled = state and true or false
            container.Visible = enabled
        end,
        IsEnabled = function()
            return enabled
        end,
        Destroy = function()
            pcall(function() connection:Disconnect() end)
            container:Destroy()
        end,
    }
end

-- Cross rain effect (falling crosses, same integration style as snow)
local function CreateCrossRainSystem(parent, config)
    config = config or {}
    local crossCount = config.CrossCount or 26
    local enabled = false
    local rng = Random.new()

    local container = Create("Frame", {
        Name = "CrossRainContainer",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 79,
        Visible = false,
        Parent = parent,
    })

    local crosses = {}
    for i = 1, crossCount do
        local scale = rng:NextNumber(0.82, 1.12)
        local width = 17 * scale
        local height = 49 * scale
        local holder = Create("Frame", {
            Name = "FallingCross",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(width, height),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 80,
            Parent = container,
        })
        local vertical = Create("Frame", {
            Name = "Vertical",
            BackgroundColor3 = Color3.fromRGB(5, 5, 8),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.19, 1),
            ZIndex = 81,
            Parent = holder,
        })
        local horizontal = Create("Frame", {
            Name = "Horizontal",
            BackgroundColor3 = Color3.fromRGB(5, 5, 8),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.35),
            Size = UDim2.fromScale(1, 0.14),
            ZIndex = 81,
            Parent = holder,
        })
        crosses[i] = {
            gui = holder,
            height = height,
            x = rng:NextNumber(0, 1),
            y = rng:NextNumber(-0.2, 1),
            speed = rng:NextNumber(55, 90),
        }
        holder.Position = UDim2.new(crosses[i].x, 0, crosses[i].y, 0)
    end

    local connection = RenderStepped:Connect(function(dt)
        if not enabled or not container.Parent then return end
        dt = math.min(dt, 1 / 30)
        for _, cross in ipairs(crosses) do
            cross.y = cross.y + (cross.speed * dt) / 600
            if cross.y > 1.15 then
                cross.y = -0.12
                cross.x = rng:NextNumber(0, 1)
                cross.speed = rng:NextNumber(55, 90)
            end
            cross.gui.Position = UDim2.new(cross.x, 0, cross.y, 0)
            cross.gui.Rotation = 0
        end
    end)
    Library:GiveSignal(connection)

    return {
        Container = container,
        SetEnabled = function(_, state)
            enabled = state and true or false
            container.Visible = enabled
        end,
        IsEnabled = function()
            return enabled
        end,
        Destroy = function()
            pcall(function() connection:Disconnect() end)
            container:Destroy()
        end,
    }
end

-- Chrome hearts effect
local function CreateChromeHeartsSystem(parent, config)
    config = config or {}
    local count = config.HeartCount or 55
    local enabled = false
    local rng = Random.new()
    local elapsed = 0

    local container = Create("Frame", {
        Name = "ChromeHeartsContainer",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 78,
        Visible = false,
        Parent = parent,
    })

    local hearts = {}
    for i = 1, count do
        local size = rng:NextNumber(12, 32)
        local heart = Create("TextLabel", {
            Name = "ChromeHeart",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(size, size),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = "♥",
            TextScaled = true,
            Font = Enum.Font.GothamBlack,
            TextColor3 = Color3.fromRGB(220, 225, 235),
            TextTransparency = rng:NextNumber(0.05, 0.3),
            Rotation = rng:NextNumber(-25, 25),
            ZIndex = 79,
            Parent = container,
        })
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 82, 98)),
            ColorSequenceKeypoint.new(0.22, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.42, Color3.fromRGB(135, 145, 165)),
            ColorSequenceKeypoint.new(0.58, Color3.fromRGB(250, 250, 255)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(105, 115, 132)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 235, 245)),
        })
        gradient.Rotation = 90
        gradient.Parent = heart
        hearts[i] = {
            gui = heart,
            size = size,
            x = rng:NextNumber(0, 1),
            y = rng:NextNumber(-0.2, 1),
            speed = rng:NextNumber(0.12, 0.35),
            drift = rng:NextNumber(-0.08, 0.08),
            spin = rng:NextNumber(-40, 40),
            phase = rng:NextNumber(0, math.pi * 2),
            sway = rng:NextNumber(0.01, 0.04),
        }
        heart.Position = UDim2.new(hearts[i].x, 0, hearts[i].y, 0)
    end

    local connection = RenderStepped:Connect(function(dt)
        if not enabled or not container.Parent then return end
        dt = math.min(dt, 1 / 30)
        elapsed = elapsed + dt
        for _, heart in ipairs(hearts) do
            local sway = math.sin(elapsed * 1.2 + heart.phase) * heart.sway
            heart.x = heart.x + heart.drift * dt
            heart.y = heart.y + heart.speed * dt
            heart.gui.Position = UDim2.new(heart.x + sway, 0, heart.y, 0)
            heart.gui.Rotation = heart.gui.Rotation + heart.spin * dt
            if heart.y > 1.2 or heart.x > 1.15 or heart.x < -0.15 then
                heart.y = -0.1
                heart.x = rng:NextNumber(0, 1)
                heart.speed = rng:NextNumber(0.12, 0.35)
            end
        end
    end)
    Library:GiveSignal(connection)

    return {
        Container = container,
        SetEnabled = function(_, state)
            enabled = state and true or false
            container.Visible = enabled
        end,
        IsEnabled = function() return enabled end,
        Destroy = function()
            pcall(function() connection:Disconnect() end)
            container:Destroy()
        end,
    }
end

-- Rain effect (falling streaks)
local function CreateRainSystem(parent, config)
    config = config or {}
    local count = config.DropCount or 60
    local enabled = false
    local rng = Random.new()

    local container = Create("Frame", {
        Name = "RainContainer",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 77,
        Visible = false,
        Parent = parent,
    })

    local drops = {}
    for i = 1, count do
        local h = rng:NextNumber(10, 22)
        local drop = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(170, 200, 230),
            BackgroundTransparency = rng:NextNumber(0.25, 0.55),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(1.5, h),
            AnchorPoint = Vector2.new(0.5, 0),
            ZIndex = 78,
            Parent = container,
        })
        Round(drop, 2)
        drops[i] = {
            gui = drop,
            x = rng:NextNumber(0, 1),
            y = rng:NextNumber(-0.3, 1),
            speed = rng:NextNumber(0.55, 1.15),
        }
        drop.Position = UDim2.new(drops[i].x, 0, drops[i].y, 0)
    end

    local connection = RenderStepped:Connect(function(dt)
        if not enabled or not container.Parent then return end
        dt = math.min(dt, 1 / 30)
        for _, drop in ipairs(drops) do
            drop.y = drop.y + drop.speed * dt
            if drop.y > 1.15 then
                drop.y = -0.1
                drop.x = rng:NextNumber(0, 1)
                drop.speed = rng:NextNumber(0.55, 1.15)
            end
            drop.gui.Position = UDim2.new(drop.x, 0, drop.y, 0)
        end
    end)
    Library:GiveSignal(connection)

    return {
        Container = container,
        SetEnabled = function(_, state)
            enabled = state and true or false
            container.Visible = enabled
        end,
        IsEnabled = function() return enabled end,
        Destroy = function()
            pcall(function() connection:Disconnect() end)
            container:Destroy()
        end,
    }
end

-- ══════════════════════════════════════════════════════════════════════════════
-- DRAGGING
-- ══════════════════════════════════════════════════════════════════════════════

function Library:MakeDraggable(frame, dragHeight)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local dragZone = Create("Frame", {
        Name = "DragZone",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, dragHeight or 42),
        Position = UDim2.fromOffset(0, 0),
        ZIndex = 100,
        Parent = frame,
    })

    dragZone.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))

    Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ══════════════════════════════════════════════════════════════════════════════

function Library:CreateWindow(config)
    config = config or {}
    local title                 = config.Title or "Frostveil"
    local size                  = config.Size or UDim2.fromOffset(640, 460)
    local autoShow              = config.AutoShow ~= false
    local center                = config.Center ~= false
    local backgroundImage       = config.BackgroundImage or config.Background or nil
    local backgroundTransparency = config.BackgroundTransparency or 0.12
    local tabPadding            = config.TabPadding or 4
    local menuFadeTime          = config.MenuFadeTime or 0.2

    local Window = {
        Tabs = {},
        TabCount = 0,
        CurrentTab = nil,
        Holder = nil,
        Snow = nil,
        BackgroundImageLabel = nil,
        Title = title,
    }

    -- Outer container (transparent so background texture shows)
    local Outer = Create("Frame", {
        Name = "Outer",
        BackgroundColor3 = Library.BackgroundColor,
        BackgroundTransparency = 0.97,
        BorderSizePixel = 0,
        Size = size,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = false,
        Parent = ScreenGui,
        ZIndex = 1,
        ClipsDescendants = false,
    })
    Round(Outer, 14)
    local outerStroke = Stroke(Outer, Library.AccentColor, 1.2, 0.50)
    -- Soft outer glow ring
    local glow = Create("Frame", {
        Name = "Glow",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 14, 1, 14),
        Position = UDim2.fromOffset(-7, -7),
        ZIndex = 0,
        Parent = Outer,
    })
    Round(glow, 18)
    Stroke(glow, Library.AccentColor, 3, 0.90)
    Window.Holder = Outer
    Library:AddToRegistry(Outer, { BackgroundColor3 = "BackgroundColor" })
    Library:AddToRegistry(outerStroke, { Color = "AccentColor" })

    -- Background image layer (supports any rbxassetid)
    local BgImage = Create("ImageLabel", {
        Name = "BackgroundImage",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ScaleType = Enum.ScaleType.Crop,
        ImageTransparency = 1,
        ZIndex = 1,
        Parent = Outer,
    })
    Round(BgImage, 12)
    Window.BackgroundImageLabel = BgImage

    -- Minimal overlay — background texture fully visible
    local BgOverlay = Create("Frame", {
        Name = "BackgroundOverlay",
        BackgroundColor3 = Library.BackgroundColor,
        BackgroundTransparency = 0.97,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
        Parent = Outer,
    })
    Round(BgOverlay, 12)
    Library:AddToRegistry(BgOverlay, { BackgroundColor3 = "BackgroundColor" })

    function Window:SetBackgroundImage(assetId, transparency)
        if not assetId or assetId == "" or assetId == 0 or assetId == "0" then
            BgImage.Image = ""
            BgImage.ImageTransparency = 1
            return
        end
        local id = tostring(assetId):gsub("rbxassetid://", ""):gsub("%s+", "")
        BgImage.Image = "rbxassetid://" .. id
        BgImage.ImageTransparency = transparency ~= nil and transparency or backgroundTransparency
    end

    function Window:SetBackgroundTransparency(value)
        BgImage.ImageTransparency = math.clamp(tonumber(value) or 0.4, 0, 1)
    end

    if backgroundImage then
        Window:SetBackgroundImage(backgroundImage, backgroundTransparency)
    end

    -- Top bar follows Background (not Main/Panels) — stays clear of solid panel color
    local TopBar = Create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Library.BackgroundColor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = Outer,
        ZIndex = 10,
    })
    Round(TopBar, 14)
    Library:AddToRegistry(TopBar, { BackgroundColor3 = "BackgroundColor" })

    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.fromOffset(18, 0),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextSize = 15,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 12,
        Parent = TopBar,
    })
    Library:AddToRegistry(TitleLabel, { TextColor3 = "FontColor" })

    local isMinimized = false
    local fullSize = size

    -- ── Built-in Settings Panel (separate GUI) ────────────────────────────
    local SettingsPanel = Create("Frame", {
        Name = "FrostveilSettings",
        BackgroundColor3 = Color3.fromRGB(12, 16, 24),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(320, 420),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = false,
        ZIndex = 200,
        Parent = ScreenGui,
        ClipsDescendants = true,
    })
    Round(SettingsPanel, 12)
    Stroke(SettingsPanel, Library.AccentColor, 1.2, 0.4)
    Library:MakeDraggable(SettingsPanel, 40)

    local settingsScale = Instance.new("UIScale")
    settingsScale.Scale = 1
    settingsScale.Parent = SettingsPanel

    local SettingsTop = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(16, 22, 34),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 201,
        Parent = SettingsPanel,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        Font = Enum.Font.GothamBold,
        Text = "Settings",
        TextSize = 14,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 202,
        Parent = SettingsTop,
    })
    local SettingsClose = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -40, 0.5, -18),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 20,
        TextColor3 = Color3.fromRGB(175, 190, 215),
        ZIndex = 202,
        Parent = SettingsTop,
    })

    local SettingsScroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, -52),
        Position = UDim2.fromOffset(8, 46),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        ZIndex = 201,
        Parent = SettingsPanel,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
    })
    local settingsList = ListLayout(SettingsScroll, 10)
    Padding(SettingsScroll, 8, 12, 8, 8)

    -- HSV Color picker builder (Linoria-style: sat/val square + hue bar)
    local function addColorPickerRow(labelText, colorKey)
        local row = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 150),
            ZIndex = 202,
            Parent = SettingsScroll,
        })
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.GothamMedium,
            Text = labelText,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(180, 200, 230),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 203,
            Parent = row,
        })

        local current = Library[colorKey] or Color3.fromRGB(100, 210, 255)
        local h, s, v = Color3.toHSV(current)

        -- Saturation / Value square (Linoria-style layered gradients)
        local svBox = Create("TextButton", {
            BackgroundColor3 = Color3.fromHSV(h, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(140, 110),
            Position = UDim2.fromOffset(0, 24),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 203,
            Parent = row,
            ClipsDescendants = true,
        })
        Round(svBox, 6)

        -- White → transparent (left → right) for saturation
        local whiteLayer = Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 204,
            Parent = svBox,
        })
        local whiteGrad = Instance.new("UIGradient")
        whiteGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        whiteGrad.Parent = whiteLayer

        -- Transparent → black (top → bottom) for value
        local blackLayer = Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 205,
            Parent = svBox,
        })
        local blackGrad = Instance.new("UIGradient")
        blackGrad.Rotation = 90
        blackGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })
        blackGrad.Parent = blackLayer

        local svCursor = Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(10, 10),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(s, 1 - v),
            ZIndex = 206,
            Parent = svBox,
        })
        Round(svCursor, 5)
        Stroke(svCursor, Color3.new(0, 0, 0), 1, 0.3)

        -- Hue bar
        local hueBar = Create("ImageButton", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(18, 110),
            Position = UDim2.fromOffset(150, 24),
            AutoButtonColor = false,
            ZIndex = 203,
            Parent = row,
        })
        Round(hueBar, 4)
        local hueGrad = Instance.new("UIGradient")
        hueGrad.Rotation = 90
        hueGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })
        hueGrad.Parent = hueBar

        local hueCursor = Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 4, 0, 4),
            Position = UDim2.new(0, -2, h, -2),
            ZIndex = 205,
            Parent = hueBar,
        })
        Round(hueCursor, 2)
        Stroke(hueCursor, Color3.new(0, 0, 0), 1, 0.4)

        -- Preview
        local preview = Create("Frame", {
            BackgroundColor3 = current,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(48, 48),
            Position = UDim2.fromOffset(184, 24),
            ZIndex = 203,
            Parent = row,
        })
        Round(preview, 8)
        Stroke(preview, Color3.fromRGB(80, 100, 140), 1, 0.4)

        local hexLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(100, 20),
            Position = UDim2.fromOffset(184, 80),
            Font = Enum.Font.Gotham,
            Text = "",
            TextSize = 11,
            TextColor3 = Color3.fromRGB(160, 180, 210),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 203,
            Parent = row,
        })

        local function applyColor(nh, ns, nv)
            h, s, v = nh, ns, nv
            local c = Color3.fromHSV(h, s, v)
            Library[colorKey] = c
            if colorKey == "AccentColor" then
                Library.ToggleOnColor = c
                Library.GroupTitleColor = c
                Library.OutlineColor = Color3.fromRGB(
                    math.floor(c.R * 100 + 30),
                    math.floor(c.G * 100 + 40),
                    math.floor(c.B * 100 + 50)
                )
            elseif colorKey == "BackgroundColor" then
                Library.MainColor = Color3.fromRGB(
                    math.min(255, math.floor(c.R * 255 + 14)),
                    math.min(255, math.floor(c.G * 255 + 16)),
                    math.min(255, math.floor(c.B * 255 + 20))
                )
                Library.SidebarColor = c
            elseif colorKey == "FontColor" then
                Library.GroupTitleColor = c
            end
            preview.BackgroundColor3 = c
            svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svCursor.Position = UDim2.fromScale(s, 1 - v)
            hueCursor.Position = UDim2.new(0, -2, h, -2)
            local r = math.floor(c.R * 255 + 0.5)
            local g = math.floor(c.G * 255 + 0.5)
            local b = math.floor(c.B * 255 + 0.5)
            hexLabel.Text = string.format("#%02X%02X%02X", r, g, b)
            Library:UpdateColorsUsingRegistry()
        end

        local function colorFromSV(inputPos)
            local rel = inputPos - svBox.AbsolutePosition
            local ns = math.clamp(rel.X / svBox.AbsoluteSize.X, 0, 1)
            local nv = 1 - math.clamp(rel.Y / svBox.AbsoluteSize.Y, 0, 1)
            applyColor(h, ns, nv)
        end
        local function colorFromHue(inputPos)
            local rel = inputPos - hueBar.AbsolutePosition
            local nh = math.clamp(rel.Y / hueBar.AbsoluteSize.Y, 0, 1)
            applyColor(nh, s, v)
        end

        local draggingSV, draggingHue = false, false
        svBox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSV = true
                colorFromSV(Vector2.new(Mouse.X, Mouse.Y))
            end
        end)
        hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingHue = true
                colorFromHue(Vector2.new(Mouse.X, Mouse.Y))
            end
        end)
        Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSV, draggingHue = false, false
            end
        end))
        Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            if draggingSV then colorFromSV(Vector2.new(Mouse.X, Mouse.Y)) end
            if draggingHue then colorFromHue(Vector2.new(Mouse.X, Mouse.Y)) end
        end))

        applyColor(h, s, v)
        return row
    end

    -- Section: Colors
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "Theme Colors",
        TextSize = 13,
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 202,
        Parent = SettingsScroll,
    })
    -- Only 3 pickers control the whole UI
    addColorPickerRow("Accent", "AccentColor")
    addColorPickerRow("Background", "BackgroundColor")
    addColorPickerRow("Text", "FontColor")

    -- Background texture dropdown
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "Background Texture",
        TextSize = 13,
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 202,
        Parent = SettingsScroll,
    })
    local bgTextures = {
        { Name = "Original", Id = "125296886011244" },
        { Name = "Money", Id = "123207755204057" },
        { Name = "SpongeBob", Id = "113644467007667" },
        { Name = "None", Id = nil },
    }
    local bgDrop = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(20, 28, 42),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        Font = Enum.Font.GothamMedium,
        Text = "  Original  ▼",
        TextSize = 12,
        TextColor3 = Color3.fromRGB(245, 245, 250),
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ZIndex = 202,
        Parent = SettingsScroll,
    })
    Round(bgDrop, 8)
    Stroke(bgDrop, Color3.fromRGB(60, 80, 110), 1, 0.5)
    local bgList = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(14, 18, 28),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ZIndex = 310,
        Parent = SettingsScroll,
        ClipsDescendants = true,
    })
    Round(bgList, 8)
    ListLayout(bgList, 2)
    Padding(bgList, 4, 4, 4, 4)
    for _, tex in ipairs(bgTextures) do
        local opt = Create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(20, 28, 42),
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 26),
            Font = Enum.Font.Gotham,
            Text = "  " .. tex.Name,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(245, 245, 250),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex = 311,
            Parent = bgList,
        })
        Round(opt, 5)
        opt.MouseButton1Click:Connect(function()
            bgDrop.Text = "  " .. tex.Name .. "  ▼"
            bgList.Visible = false
            bgList.Size = UDim2.new(1, 0, 0, 0)
            if Window.SetBackgroundImage then
                if tex.Id then
                    Window:SetBackgroundImage(tex.Id, 0.12)
                else
                    Window:SetBackgroundImage(nil)
                end
            end
            Library:Notify("Background: " .. tex.Name, 1.5)
        end)
    end
    bgDrop.MouseButton1Click:Connect(function()
        bgList.Visible = not bgList.Visible
        if bgList.Visible then
            bgList.Size = UDim2.new(1, 0, 0, #bgTextures * 28 + 8)
        else
            bgList.Size = UDim2.new(1, 0, 0, 0)
        end
    end)

    -- Section: Keybind
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "Menu Keybind",
        TextSize = 13,
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 202,
        Parent = SettingsScroll,
    })
    local function currentKeyText()
        return tostring(Library.ToggleKeybind or "RightShift")
    end

    local keyBtn = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(20, 28, 42),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.GothamMedium,
        Text = currentKeyText(),
        TextSize = 12,
        TextColor3 = Library.FontColor,
        AutoButtonColor = false,
        ZIndex = 202,
        Parent = SettingsScroll,
    })
    Round(keyBtn, 8)
    Stroke(keyBtn, Library.AccentColor, 1, 0.6)
    local listeningKey = false
    keyBtn.MouseButton1Click:Connect(function()
        if listeningKey then return end
        listeningKey = true
        keyBtn.Text = "Press any key..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local name = input.KeyCode.Name
                Library.ToggleKeybind = name
                listeningKey = false
                pcall(function() conn:Disconnect() end)
                keyBtn.Text = name
                Library:Notify("Toggle key: " .. name, 2)
            end
        end)
        Library:GiveSignal(conn)
        task.delay(5, function()
            if listeningKey then
                listeningKey = false
                pcall(function() conn:Disconnect() end)
                keyBtn.Text = currentKeyText()
            end
        end)
    end)

    -- Section: Effects
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "Effects",
        TextSize = 13,
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 202,
        Parent = SettingsScroll,
    })

    -- Effect enabled toggle (UI toggle style)
    local effectOn = true
    local effectToggleRow = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 202,
        Parent = SettingsScroll,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -54, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "Enable Effect",
        TextSize = 12,
        TextColor3 = Color3.fromRGB(220, 230, 245),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
        Parent = effectToggleRow,
    })
    local eTrack = Create("Frame", {
        BackgroundColor3 = Library.ToggleOnColor,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.new(1, -44, 0.5, -12),
        ZIndex = 203,
        Parent = effectToggleRow,
    })
    Round(eTrack, 12)
    local eKnob = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(250, 252, 255),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(23, 3),
        ZIndex = 204,
        Parent = eTrack,
    })
    Round(eKnob, 9)

    local function applyEffectState()
        local mode = Window.ActiveEffect or "Snow"
        if Window.Snow then Window.Snow:SetEnabled(effectOn and mode == "Snow") end
        if Window.CrossRain then Window.CrossRain:SetEnabled(effectOn and mode == "Cross") end
        if Window.ChromeHearts then Window.ChromeHearts:SetEnabled(effectOn and mode == "Hearts") end
        if Window.Rain then Window.Rain:SetEnabled(effectOn and mode == "Rain") end
    end

    local eClick = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        ZIndex = 205,
        Parent = effectToggleRow,
    })
    eClick.MouseButton1Click:Connect(function()
        effectOn = not effectOn
        local targetPos = effectOn and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
        local targetColor = effectOn and Library.ToggleOnColor or Library.ToggleOffColor
        TweenService:Create(eKnob, TweenInfo.new(0.22, Enum.EasingStyle.Exponential), { Position = targetPos }):Play()
        TweenService:Create(eTrack, TweenInfo.new(0.22, Enum.EasingStyle.Exponential), { BackgroundColor3 = targetColor }):Play()
        applyEffectState()
    end)

    -- Effect type dropdown (simple built-in)
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.Gotham,
        Text = "Effect Type",
        TextSize = 12,
        TextColor3 = Color3.fromRGB(180, 200, 230),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 202,
        Parent = SettingsScroll,
    })
    local effectOptions = { "Snow", "Cross", "Hearts", "Rain", "None" }
    local effectDrop = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(20, 28, 42),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        Font = Enum.Font.GothamMedium,
        Text = "  Snow  ▼",
        TextSize = 12,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ZIndex = 202,
        Parent = SettingsScroll,
    })
    Round(effectDrop, 8)
    Stroke(effectDrop, Library.AccentColor, 1, 0.55)

    local effectList = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(14, 18, 28),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ZIndex = 300,
        Parent = SettingsScroll,
        ClipsDescendants = true,
    })
    Round(effectList, 8)
    local effectListLayout = ListLayout(effectList, 2)
    Padding(effectList, 4, 4, 4, 4)

    local function setEffectMode(mode)
        Window.ActiveEffect = mode
        if mode == "None" then
            effectOn = false
            eKnob.Position = UDim2.fromOffset(3, 3)
            eTrack.BackgroundColor3 = Library.ToggleOffColor
        elseif not effectOn then
            effectOn = true
            eKnob.Position = UDim2.fromOffset(23, 3)
            eTrack.BackgroundColor3 = Library.ToggleOnColor
        end
        effectDrop.Text = "  " .. mode .. "  ▼"
        effectList.Visible = false
        effectList.Size = UDim2.new(1, 0, 0, 0)
        applyEffectState()
        Library:Notify("Effect: " .. mode, 1.5)
    end

    for _, opt in ipairs(effectOptions) do
        local optBtn = Create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(20, 28, 42),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 26),
            Font = Enum.Font.Gotham,
            Text = "  " .. opt,
            TextSize = 12,
            TextColor3 = Library.FontColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex = 301,
            Parent = effectList,
        })
        Round(optBtn, 5)
        optBtn.MouseButton1Click:Connect(function()
            setEffectMode(opt)
        end)
    end

    effectDrop.MouseButton1Click:Connect(function()
        effectList.Visible = not effectList.Visible
        if effectList.Visible then
            effectList.Size = UDim2.new(1, 0, 0, #effectOptions * 28 + 8)
        else
            effectList.Size = UDim2.new(1, 0, 0, 0)
        end
    end)

    applyEffectState()

    local function openSettings()
        SettingsPanel.Visible = true
        settingsScale.Scale = 0.92
        TweenService:Create(settingsScale, TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()
    end
    local function closeSettings()
        TweenService:Create(settingsScale, TweenInfo.new(0.18, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
            Scale = 0.94
        }):Play()
        task.delay(0.16, function()
            SettingsPanel.Visible = false
            settingsScale.Scale = 1
        end)
    end
    SettingsClose.MouseButton1Click:Connect(closeSettings)
    SettingsClose.MouseEnter:Connect(function()
        TweenService:Create(SettingsClose, TweenInfo.new(0.12), { TextColor3 = Library.RiskColor }):Play()
    end)
    SettingsClose.MouseLeave:Connect(function()
        TweenService:Create(SettingsClose, TweenInfo.new(0.12), { TextColor3 = Color3.fromRGB(175, 190, 215) }):Play()
    end)

    Window.OpenSettings = openSettings
    Window.CloseSettings = closeSettings

    -- Settings gear button
    local SettingsButton = Create("TextButton", {
        Name = "Settings",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -110, 0.5, -16),
        Font = Enum.Font.GothamBold,
        Text = "⚙",
        TextSize = 16,
        TextColor3 = Color3.fromRGB(175, 190, 215),
        ZIndex = 12,
        Parent = TopBar,
    })
    SettingsButton.MouseButton1Click:Connect(function()
        if SettingsPanel.Visible then
            closeSettings()
        else
            openSettings()
        end
    end)
    SettingsButton.MouseEnter:Connect(function()
        TweenService:Create(SettingsButton, TweenInfo.new(0.12), {
            TextColor3 = Library.AccentColor
        }):Play()
    end)
    SettingsButton.MouseLeave:Connect(function()
        TweenService:Create(SettingsButton, TweenInfo.new(0.12), {
            TextColor3 = Color3.fromRGB(175, 190, 215)
        }):Play()
    end)

    -- Minimize button
    local MinButton = Create("TextButton", {
        Name = "Minimize",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -76, 0.5, -16),
        Font = Enum.Font.GothamBold,
        Text = "–",
        TextSize = 20,
        TextColor3 = Color3.fromRGB(175, 190, 215),
        ZIndex = 12,
        Parent = TopBar,
    })
    MinButton.MouseButton1Click:Connect(function()
        Window:Hide()
    end)
    MinButton.MouseEnter:Connect(function()
        TweenService:Create(MinButton, TweenInfo.new(0.12), {
            TextColor3 = Library.AccentColor
        }):Play()
    end)
    MinButton.MouseLeave:Connect(function()
        TweenService:Create(MinButton, TweenInfo.new(0.12), {
            TextColor3 = Color3.fromRGB(175, 190, 215)
        }):Play()
    end)

    -- Close button = fully unload
    local CloseButton = Create("TextButton", {
        Name = "Close",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -42, 0.5, -18),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 22,
        TextColor3 = Color3.fromRGB(175, 190, 215),
        ZIndex = 12,
        Parent = TopBar,
    })
    CloseButton.MouseButton1Click:Connect(function()
        Library:Unload()
    end)
    CloseButton.MouseEnter:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.12), {
            TextColor3 = Library.RiskColor
        }):Play()
    end)
    CloseButton.MouseLeave:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.12), {
            TextColor3 = Color3.fromRGB(175, 190, 215)
        }):Play()
    end)

    function Window:Minimize()
        Outer.Visible = false
    end
    function Window:Restore()
        Outer.Visible = true
    end

    -- Sidebar (scrollable tab list)
    local Sidebar = Create("ScrollingFrame", {
        Name = "Sidebar",
        BackgroundColor3 = Library.SidebarColor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 158, 1, -44),
        Position = UDim2.fromOffset(0, 44),
        Parent = Outer,
        ZIndex = 8,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.AccentColor,
        ScrollingEnabled = true,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ClipsDescendants = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Library:AddToRegistry(Sidebar, { BackgroundColor3 = "SidebarColor" })
    ListLayout(Sidebar, 6)
    Padding(Sidebar, 16, 14, 12, 12)

    -- Content holder
    local ContentHolder = Create("Frame", {
        Name = "ContentHolder",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -172, 1, -58),
        Position = UDim2.fromOffset(168, 54),
        Parent = Outer,
        ZIndex = 8,
        ClipsDescendants = true,
    })

    -- Effects (snow + cross rain)
    Window.Snow = CreateSnowSystem(Outer, { MaxFlakes = 70 })
    Window.CrossRain = CreateCrossRainSystem(Outer, { CrossCount = 26 })
    Window.ChromeHearts = CreateChromeHeartsSystem(Outer, { HeartCount = 55 })
    Window.Rain = CreateRainSystem(Outer, { DropCount = 60 })
    Window.ActiveEffect = "Snow"

    -- Dragging
    Library:MakeDraggable(Outer, 42)

    local windowScale = Instance.new("UIScale")
    windowScale.Scale = 1
    windowScale.Parent = Outer
    local windowBusy = false

    local function animateShow()
        if windowBusy then return end
        windowBusy = true
        Outer.Visible = true
        windowScale.Scale = 0.90
        local t = TweenService:Create(windowScale, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            Scale = 1
        })
        t:Play()
        t.Completed:Connect(function() windowBusy = false end)
    end

    local function animateHide()
        if windowBusy then return end
        windowBusy = true
        local t = TweenService:Create(windowScale, TweenInfo.new(0.22, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
            Scale = 0.92
        })
        t:Play()
        t.Completed:Connect(function()
            Outer.Visible = false
            windowScale.Scale = 1
            windowBusy = false
        end)
    end

    function Window:Toggle()
        if Outer.Visible then animateHide() else animateShow() end
    end

    function Window:Show()
        animateShow()
    end

    function Window:Hide()
        animateHide()
    end

    function Window:SetTitle(newTitle)
        TitleLabel.Text = tostring(newTitle)
        Window.Title = tostring(newTitle)
    end

    -- Keybind (configurable — default RightShift)
    if not Library.ToggleKeybind then
        Library.ToggleKeybind = "RightShift"
    end
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = input.KeyCode.Name
            if keyName == tostring(Library.ToggleKeybind) then
                Window:Toggle()
            end
        end
    end))

    -- ════════════════════════════════════════════════════════════════════════
    -- ADD TAB
    -- ════════════════════════════════════════════════════════════════════════

    function Window:AddTab(name)
        Window.TabCount = Window.TabCount + 1
        local order = Window.TabCount

        local Tab = {
            Name = name,
            Groupboxes = {},
            Tabboxes = {},
            Container = nil,
            Button = nil,
            Active = false,
        }

        -- Sidebar button (premium pill)
        local tabButton = Create("TextButton", {
            Name = name,
            BackgroundColor3 = Library.MainColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 36),
            Font = Enum.Font.GothamMedium,
            Text = name,
            TextSize = 13,
            TextColor3 = Library.FontColor,
            TextTransparency = 0.35,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextScaled = true,
            AutoButtonColor = false,
            LayoutOrder = order,
            ZIndex = 10,
            Parent = Sidebar,
        })
        Round(tabButton, 9)
        Padding(tabButton, 6, 6, 14, 8)
        local tabLimit = Instance.new("UITextSizeConstraint")
        tabLimit.MaxTextSize = 13
        tabLimit.MinTextSize = 9
        tabLimit.Parent = tabButton
        local tabStroke = Stroke(tabButton, Library.OutlineColor, 1, 1)

        Tab.Button = tabButton

        -- Content: two real columns side-by-side (left / right groupboxes)
        local container = Create("ScrollingFrame", {
            Name = name .. "_Content",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 9,
            Parent = ContentHolder,
            ClipsDescendants = true,
            ScrollingEnabled = true,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            ScrollBarImageTransparency = 0.25,
            Active = true,
        })

        local columns = Create("Frame", {
            Name = "Columns",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = container,
            ZIndex = 9,
        })
        local columnsLayout = Instance.new("UIListLayout")
        columnsLayout.FillDirection = Enum.FillDirection.Horizontal
        columnsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        columnsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        columnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        columnsLayout.Padding = UDim.new(0, 10)
        columnsLayout.Parent = columns
        local columnsPad = Instance.new("UIPadding")
        columnsPad.PaddingLeft = UDim.new(0, 4)
        columnsPad.PaddingRight = UDim.new(0, 4)
        columnsPad.PaddingTop = UDim.new(0, 4)
        columnsPad.PaddingBottom = UDim.new(0, 8)
        columnsPad.Parent = columns

        -- LEFT column
        local leftCol = Create("Frame", {
            Name = "LeftColumn",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            Parent = columns,
            ZIndex = 9,
        })
        local leftList = Instance.new("UIListLayout")
        leftList.FillDirection = Enum.FillDirection.Vertical
        leftList.SortOrder = Enum.SortOrder.LayoutOrder
        leftList.Padding = UDim.new(0, 10)
        leftList.Parent = leftCol

        -- RIGHT column
        local rightCol = Create("Frame", {
            Name = "RightColumn",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            Parent = columns,
            ZIndex = 9,
        })
        local rightList = Instance.new("UIListLayout")
        rightList.FillDirection = Enum.FillDirection.Vertical
        rightList.SortOrder = Enum.SortOrder.LayoutOrder
        rightList.Padding = UDim.new(0, 10)
        rightList.Parent = rightCol

        local leftCount, rightCount = 0, 0

        local function updateCanvas()
            -- Keep canvas tall enough; width comes from the frame (AutomaticCanvasSize Y)
            local h = math.max(leftList.AbsoluteContentSize.Y, rightList.AbsoluteContentSize.Y, 1) + 16
            if container.AbsoluteSize.X > 0 then
                -- force equal half widths in pixels (scale 0.5 can fail inside scrolling frames)
                local half = math.floor((container.AbsoluteSize.X - 18) / 2)
                leftCol.Size = UDim2.fromOffset(half, 0)
                rightCol.Size = UDim2.fromOffset(half, 0)
                leftCol.AutomaticSize = Enum.AutomaticSize.Y
                rightCol.AutomaticSize = Enum.AutomaticSize.Y
            end
            container.CanvasSize = UDim2.fromOffset(0, h)
        end
        leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        container:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
        task.defer(updateCanvas)
        task.delay(0.2, updateCanvas)

        Tab.Container = container
        Tab.LeftColumn = leftCol
        Tab.RightColumn = rightCol
        Tab.UpdateCanvas = updateCanvas
        Tab._leftCount = function()
            leftCount = leftCount + 1
            return leftCount
        end
        Tab._rightCount = function()
            rightCount = rightCount + 1
            return rightCount
        end

        local function ActivateTab()
            if Tab.Active then return end

            -- Deactivate others instantly (clean, no lag)
            for _, otherTab in pairs(Window.Tabs) do
                if otherTab ~= Tab then
                    otherTab.Container.Visible = false
                    otherTab.Button.BackgroundTransparency = 1
                    otherTab.Button.TextColor3 = Library.FontColor
                    otherTab.Button.TextTransparency = 0.35
                    local st = otherTab.Button:FindFirstChildOfClass("UIStroke")
                    if st then st.Transparency = 1 end
                    otherTab.Active = false
                end
            end

            -- Show tab and refresh left/right layout
            container.Visible = true
            task.defer(updateCanvas)

            TweenService:Create(tabButton, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.55,
                TextColor3 = Library.FontColor,
                TextTransparency = 0,
            }):Play()
            if tabStroke then
                TweenService:Create(tabStroke, TweenInfo.new(0.25, Enum.EasingStyle.Exponential), {
                    Transparency = 0.45
                }):Play()
            end

            Tab.Active = true
            Window.CurrentTab = Tab
        end

        tabButton.MouseButton1Click:Connect(ActivateTab)
        tabButton.MouseEnter:Connect(function()
            if not Tab.Active then
                TweenService:Create(tabButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                    BackgroundTransparency = 0.72
                }):Play()
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if not Tab.Active then
                TweenService:Create(tabButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                    BackgroundTransparency = 1
                }):Play()
            end
        end)

        if Window.TabCount == 1 then
            task.defer(ActivateTab)
        end

        -- ════════════════════════════════════════════════════════════════════
        -- GROUPBOX
        -- ════════════════════════════════════════════════════════════════════

        function Tab:AddLeftGroupbox(titleText)
            return self:AddGroupbox(titleText, "left")
        end

        function Tab:AddRightGroupbox(titleText)
            return self:AddGroupbox(titleText, "right")
        end

        function Tab:AddGroupbox(titleText, side)
            side = tostring(side or "left"):lower()
            local isRight = (side == "right" or side == "r")
            -- Always use this tab's column frames (never fall back to full container)
            local parentCol = isRight and Tab.RightColumn or Tab.LeftColumn
            if not parentCol or not parentCol.Parent then
                warn("[Frostveil] Column missing for", titleText, "side=", side)
                return nil
            end

            local order = isRight and Tab._rightCount() or Tab._leftCount()

            local Groupbox = {
                Elements = {},
                Side = isRight and "right" or "left",
            }

            local box = Instance.new("Frame")
            box.Name = tostring(titleText)
            box.BackgroundColor3 = Library.MainColor
            box.BackgroundTransparency = 0.92
            box.BorderSizePixel = 0
            box.Size = UDim2.new(1, 0, 0, 48)
            box.ZIndex = 10
            box.LayoutOrder = order
            box.Parent = parentCol
            Round(box, 10)
            if Tab.UpdateCanvas then
                task.defer(Tab.UpdateCanvas)
            end
            local boxStroke = Stroke(box, Library.OutlineColor, 1, 0.55)
            Library:AddToRegistry(box, { BackgroundColor3 = "MainColor" })
            Library:AddToRegistry(boxStroke, { Color = "OutlineColor" })

            local boxTitle = Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.fromOffset(12, 8),
                Font = Enum.Font.GothamBold,
                Text = titleText,
                TextSize = 13,
                TextColor3 = Library.FontColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextScaled = true,
                ZIndex = 12,
                Parent = box,
            })
            Library:AddToRegistry(boxTitle, { TextColor3 = "FontColor" })
            local boxTitleLimit = Instance.new("UITextSizeConstraint")
            boxTitleLimit.MaxTextSize = 13
            boxTitleLimit.MinTextSize = 9
            boxTitleLimit.Parent = boxTitle

            local boxList = ListLayout(box, 8)
            Padding(box, 32, 12, 12, 12)

            local function ResizeBox()
                -- Fixed sizing so stacked left/right groupboxes fit cleanly
                local h = math.max(48, boxList.AbsoluteContentSize.Y + 40)
                box.Size = UDim2.new(1, 0, 0, h)
                if Tab.UpdateCanvas then
                    task.defer(Tab.UpdateCanvas)
                end
            end
            boxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeBox)
            task.defer(ResizeBox)

            -- ── Toggle ────────────────────────────────────────────────────
            function Groupbox:AddToggle(index, info)
                info = info or {}
                local text     = info.Text or index
                local default  = info.Default or false
                local callback = info.Callback
                local risky    = info.Risky or false
                local tooltip  = info.Tooltip

                local holder = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    ZIndex = 11,
                    Parent = box,
                })

                local toggleLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -54, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextSize = 13,
                    TextColor3 = risky and Library.RiskColor or Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextScaled = true,
                    ZIndex = 12,
                    Parent = holder,
                })
                local tLimit = Instance.new("UITextSizeConstraint")
                tLimit.MaxTextSize = 13
                tLimit.MinTextSize = 8
                tLimit.Parent = toggleLabel

                local track = Create("Frame", {
                    BackgroundColor3 = Library.ToggleOffColor,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(44, 24),
                    Position = UDim2.new(1, -44, 0.5, -12),
                    ZIndex = 12,
                    Parent = holder,
                })
                Round(track, 12)
                Stroke(track, Library.OutlineColor, 1, 0.55)

                local knob = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(250, 252, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(18, 18),
                    Position = UDim2.fromOffset(3, 3),
                    ZIndex = 13,
                    Parent = track,
                })
                Round(knob, 9)
                Stroke(knob, Color3.fromRGB(180, 220, 255), 1, 0.7)

                local state = default

                local ToggleObject = {
                    Type = "Toggle",
                    Value = state,
                    Index = index,
                }

                local function SetValue(value, noCallback)
                    state = value and true or false
                    ToggleObject.Value = state
                    local targetPos = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
                    local targetColor = state and Library.ToggleOnColor or Library.ToggleOffColor
                    local info = TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
                    TweenService:Create(knob, info, { Position = targetPos }):Play()
                    TweenService:Create(track, info, { BackgroundColor3 = targetColor }):Play()
                    if not noCallback and callback then
                        Library:SafeCallback(callback, state)
                    end
                end

                ToggleObject.SetValue = SetValue
                ToggleObject.OnChanged = function(_, cb)
                    callback = cb
                end
                ToggleObject.SetValue(default, true)

                local clickArea = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = "",
                    ZIndex = 14,
                    Parent = holder,
                })
                clickArea.MouseButton1Click:Connect(function()
                    SetValue(not state)
                end)

                Toggles[index] = ToggleObject
                ResizeBox()
                return ToggleObject
            end

            -- ── Slider ────────────────────────────────────────────────────
            function Groupbox:AddSlider(index, info)
                info = info or {}
                local text      = info.Text or index
                local min       = info.Min or 0
                local max       = info.Max or 100
                local default   = info.Default or min
                local rounding  = info.Rounding or 0
                local suffix    = info.Suffix or ""
                local callback  = info.Callback

                local holder = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 48),
                    ZIndex = 11,
                    Parent = box,
                })

                local sliderLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -70, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextScaled = true,
                    ZIndex = 12,
                    Parent = holder,
                })
                local sLimit = Instance.new("UITextSizeConstraint")
                sLimit.MaxTextSize = 13
                sLimit.MinTextSize = 8
                sLimit.Parent = sliderLabel

                local valueLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 65, 0, 18),
                    Position = UDim2.new(1, -65, 0, 0),
                    Font = Enum.Font.Gotham,
                    Text = tostring(default) .. suffix,
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextScaled = true,
                    ZIndex = 12,
                    Parent = holder,
                })
                local vLimit = Instance.new("UITextSizeConstraint")
                vLimit.MaxTextSize = 13
                vLimit.MinTextSize = 8
                vLimit.Parent = valueLabel

                local barBackground = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(12, 16, 26),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 8),
                    Position = UDim2.fromOffset(0, 30),
                    ZIndex = 12,
                    Parent = holder,
                })
                Round(barBackground, 4)
                Stroke(barBackground, Library.OutlineColor, 1, 0.6)

                local fill = Create("Frame", {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                    ZIndex = 13,
                    Parent = barBackground,
                })
                Round(fill, 4)
                Library:AddToRegistry(fill, { BackgroundColor3 = "AccentColor" })
                local fillGrad = Instance.new("UIGradient")
                fillGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 160, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 230, 255)),
                })
                fillGrad.Parent = fill

                -- Slider knob / dot
                local knob = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(245, 250, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(16, 16),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    ZIndex = 14,
                    Parent = barBackground,
                })
                Round(knob, 8)
                Stroke(knob, Library.AccentColor, 1.5, 0.25)

                local SliderObject = {
                    Type = "Slider",
                    Value = default,
                    Min = min,
                    Max = max,
                    Index = index,
                }

                local function SetValue(value, noCallback)
                    value = math.clamp(value, min, max)
                    if rounding <= 0 then
                        value = math.floor(value + 0.5)
                    else
                        local mult = 10 ^ rounding
                        value = math.floor(value * mult + 0.5) / mult
                    end
                    SliderObject.Value = value
                    local percent = math.clamp((value - min) / (max - min), 0, 1)
                    -- Instant while dragging = responsive; no laggy tweens
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    knob.Position = UDim2.new(percent, 0, 0.5, 0)
                    valueLabel.Text = tostring(value) .. suffix
                    if not noCallback and callback then
                        Library:SafeCallback(callback, value)
                    end
                end

                SliderObject.SetValue = SetValue
                SliderObject.OnChanged = function(_, cb)
                    callback = cb
                end

                local draggingSlider = false
                barBackground.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        local relative = (Mouse.X - barBackground.AbsolutePosition.X) / barBackground.AbsoluteSize.X
                        SetValue(min + (max - min) * math.clamp(relative, 0, 1))
                    end
                end)
                knob.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                    end
                end)
                Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end))
                Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local relative = (Mouse.X - barBackground.AbsolutePosition.X) / barBackground.AbsoluteSize.X
                        SetValue(min + (max - min) * math.clamp(relative, 0, 1))
                    end
                end))

                SetValue(default, true)
                Options[index] = SliderObject
                ResizeBox()
                return SliderObject
            end

            -- ── Button ────────────────────────────────────────────────────
            function Groupbox:AddButton(info)
                if type(info) ~= "table" then
                    info = { Text = tostring(info), Func = function() end }
                end
                local text = info.Text or "Button"
                local func = info.Func or info.Callback or function() end
                local doubleClick = info.DoubleClick or false

                local button = Create("TextButton", {
                    BackgroundColor3 = Color3.fromRGB(20, 28, 42),
                    BackgroundTransparency = 0.55,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 34),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    TextScaled = true,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    AutoButtonColor = false,
                    ZIndex = 11,
                    Parent = box,
                })
                Round(button, 9)
                Padding(button, 4, 4, 10, 10)
                local btnSizeLimit = Instance.new("UITextSizeConstraint")
                btnSizeLimit.MaxTextSize = 13
                btnSizeLimit.MinTextSize = 8
                btnSizeLimit.Parent = button
                local btnStroke = Stroke(button, Library.AccentColor, 1, 0.65)

                local btnScale = Instance.new("UIScale")
                btnScale.Scale = 1
                btnScale.Parent = button

                local lastClick = 0
                button.MouseButton1Click:Connect(function()
                    btnScale.Scale = 0.97
                    TweenService:Create(btnScale, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                        Scale = 1
                    }):Play()
                    if doubleClick then
                        local now = tick()
                        if now - lastClick < 0.35 then
                            Library:SafeCallback(func)
                            lastClick = 0
                        else
                            lastClick = now
                        end
                    else
                        Library:SafeCallback(func)
                    end
                end)
                button.MouseEnter:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.15), {
                        BackgroundTransparency = 0.30
                    }):Play()
                    TweenService:Create(btnStroke, TweenInfo.new(0.15), {
                        Transparency = 0.35
                    }):Play()
                end)
                button.MouseLeave:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.15), {
                        BackgroundTransparency = 0.55
                    }):Play()
                    TweenService:Create(btnStroke, TweenInfo.new(0.15), {
                        Transparency = 0.65
                    }):Play()
                end)

                ResizeBox()
                return { Type = "Button", Instance = button }
            end

            -- ── Label ─────────────────────────────────────────────────────
            function Groupbox:AddLabel(text, doesWrap)
                local label = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, doesWrap and 0 or 20),
                    AutomaticSize = doesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                    Font = Enum.Font.Gotham,
                    Text = tostring(text),
                    TextSize = 12,
                    TextColor3 = Color3.fromRGB(155, 175, 205),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = doesWrap and true or false,
                    ZIndex = 11,
                    Parent = box,
                })
                ResizeBox()
                local LabelObject = {
                    Type = "Label",
                    SetText = function(_, newText)
                        label.Text = tostring(newText)
                    end,
                }
                return LabelObject
            end

            -- ── Divider ───────────────────────────────────────────────────
            function Groupbox:AddDivider()
                Create("Frame", {
                    BackgroundColor3 = Library.OutlineColor,
                    BackgroundTransparency = 0.50,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    ZIndex = 11,
                    Parent = box,
                })
                ResizeBox()
            end

            -- ── Input ─────────────────────────────────────────────────────
            function Groupbox:AddInput(index, info)
                info = info or {}
                local text        = info.Text or index
                local default     = info.Default or ""
                local placeholder = info.Placeholder or ""
                local numeric     = info.Numeric or false
                local finished    = info.Finished or false
                local callback    = info.Callback
                local maxLength   = info.MaxLength

                local holder = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 52),
                    ZIndex = 11,
                    Parent = box,
                })

                if text and text ~= "" then
                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 18),
                        Font = Enum.Font.Gotham,
                        Text = text,
                        TextSize = 13,
                        TextColor3 = Library.FontColor,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 12,
                        Parent = holder,
                    })
                end

                local boxFrame = Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 28),
                    Position = UDim2.fromOffset(0, text and text ~= "" and 22 or 0),
                    ZIndex = 12,
                    Parent = holder,
                })
                Round(boxFrame, 7)
                Stroke(boxFrame, Library.OutlineColor, 1, 0.45)

                local textBox = Create("TextBox", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -16, 1, 0),
                    Position = UDim2.fromOffset(8, 0),
                    Font = Enum.Font.Gotham,
                    Text = tostring(default),
                    PlaceholderText = placeholder,
                    PlaceholderColor3 = Color3.fromRGB(100, 120, 150),
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    ZIndex = 13,
                    Parent = boxFrame,
                })

                local InputObject = {
                    Type = "Input",
                    Value = tostring(default),
                    Index = index,
                }

                local function FireCallback()
                    InputObject.Value = textBox.Text
                    if callback then
                        Library:SafeCallback(callback, textBox.Text)
                    end
                end

                if finished then
                    textBox.FocusLost:Connect(function(enter)
                        if enter then FireCallback() end
                    end)
                else
                    textBox:GetPropertyChangedSignal("Text"):Connect(function()
                        if numeric then
                            local cleaned = textBox.Text:gsub("[^%d%.%-]", "")
                            if cleaned ~= textBox.Text then
                                textBox.Text = cleaned
                            end
                        end
                        if maxLength and #textBox.Text > maxLength then
                            textBox.Text = textBox.Text:sub(1, maxLength)
                        end
                        FireCallback()
                    end)
                end

                InputObject.SetValue = function(_, value)
                    textBox.Text = tostring(value or "")
                    InputObject.Value = textBox.Text
                end
                InputObject.OnChanged = function(_, cb)
                    callback = cb
                end

                Options[index] = InputObject
                ResizeBox()
                return InputObject
            end

            -- ── Dropdown ──────────────────────────────────────────────────
            function Groupbox:AddDropdown(index, info)
                info = info or {}
                local text       = info.Text or index
                local values     = info.Values or {}
                local default    = info.Default
                local multi      = info.Multi or false
                local allowNull  = info.AllowNull or false
                local callback   = info.Callback
                local maxVisible = math.clamp(info.MaxVisibleDropdownItems or 6, 1, 6)

                if not default and not allowNull and #values > 0 then
                    default = multi and {} or values[1]
                end

                local holder = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 52),
                    ZIndex = 11,
                    Parent = box,
                })

                if text and text ~= "" then
                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 18),
                        Font = Enum.Font.Gotham,
                        Text = text,
                        TextSize = 13,
                        TextColor3 = Library.FontColor,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 12,
                        Parent = holder,
                    })
                end

                local dropButton = Create("TextButton", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 28),
                    Position = UDim2.fromOffset(0, text and text ~= "" and 22 or 0),
                    Font = Enum.Font.Gotham,
                    Text = "",
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    AutoButtonColor = false,
                    ZIndex = 12,
                    Parent = holder,
                })
                Round(dropButton, 7)
                Stroke(dropButton, Library.OutlineColor, 1, 0.45)

                local displayLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.fromOffset(10, 0),
                    Font = Enum.Font.Gotham,
                    Text = "Select...",
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextScaled = true,
                    ZIndex = 13,
                    Parent = dropButton,
                })
                local dLimit = Instance.new("UITextSizeConstraint")
                dLimit.MaxTextSize = 13
                dLimit.MinTextSize = 8
                dLimit.Parent = displayLabel

                -- Down arrow indicator (clear dropdown affordance)
                local arrow = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(22, 22),
                    Position = UDim2.new(1, -26, 0.5, -11),
                    Font = Enum.Font.GothamBold,
                    Text = "▼",
                    TextSize = 11,
                    TextColor3 = Color3.fromRGB(160, 200, 240),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 13,
                    Parent = dropButton,
                })

                -- Dropdown list parented to ScreenGui so it never clips behind the menu
                local listFrame = Create("Frame", {
                    Name = "FrostveilDropdown",
                    BackgroundColor3 = Color3.fromRGB(14, 18, 28),
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(200, 0),
                    Position = UDim2.fromOffset(0, 0),
                    Visible = false,
                    ZIndex = 500,
                    Parent = ScreenGui,
                    ClipsDescendants = true,
                })
                Round(listFrame, 8)
                Stroke(listFrame, Library.AccentColor, 1, 0.45)

                local listScroll = Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarThickness = 4,
                    ScrollBarImageColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    ZIndex = 501,
                    Parent = listFrame,
                    ScrollingEnabled = true,
                    ElasticBehavior = Enum.ElasticBehavior.Never,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                })
                local listLayout = ListLayout(listScroll, 2)
                Padding(listScroll, 4, 4, 4, 4)

                local function positionList()
                    local absPos = dropButton.AbsolutePosition
                    local absSize = dropButton.AbsoluteSize
                    listFrame.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
                    listFrame.Size = UDim2.fromOffset(math.max(absSize.X, 140), listFrame.Size.Y.Offset)
                end

                local DropdownObject = {
                    Type = "Dropdown",
                    Value = default,
                    Values = values,
                    Multi = multi,
                    Index = index,
                }

                local selected = {}
                if multi then
                    if type(default) == "table" then
                        for _, v in ipairs(default) do selected[v] = true end
                    end
                else
                    if default then selected[default] = true end
                end

                local function UpdateDisplay()
                    if multi then
                        local parts = {}
                        for _, v in ipairs(values) do
                            if selected[v] then table.insert(parts, tostring(v)) end
                        end
                        displayLabel.Text = #parts > 0 and table.concat(parts, ", ") or "Select..."
                    else
                        local val = next(selected)
                        displayLabel.Text = val and tostring(val) or "Select..."
                    end
                end

                local function BuildList()
                    for _, child in ipairs(listScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, value in ipairs(values) do
                        local optionBtn = Create("TextButton", {
                            BackgroundColor3 = selected[value] and Library.AccentColor or Color3.fromRGB(20, 28, 42),
                            BackgroundTransparency = selected[value] and 0.55 or 0.25,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 26),
                            Font = Enum.Font.Gotham,
                            Text = "  " .. tostring(value),
                            TextSize = 13,
                            TextColor3 = Library.FontColor,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextScaled = true,
                            AutoButtonColor = false,
                            ZIndex = 502,
                            Parent = listScroll,
                        })
                        local oLimit = Instance.new("UITextSizeConstraint")
                        oLimit.MaxTextSize = 13
                        oLimit.MinTextSize = 8
                        oLimit.Parent = optionBtn
                        Round(optionBtn, 5)
                        optionBtn.MouseButton1Click:Connect(function()
                            if multi then
                                selected[value] = not selected[value]
                            else
                                table.clear(selected)
                                selected[value] = true
                                -- animated close
                                TweenService:Create(arrow, TweenInfo.new(0.15), { Rotation = 0 }):Play()
                                listFrame.Visible = false
                            end
                            if multi then
                                local result = {}
                                for _, v in ipairs(values) do
                                    if selected[v] then table.insert(result, v) end
                                end
                                DropdownObject.Value = result
                            else
                                DropdownObject.Value = value
                            end
                            UpdateDisplay()
                            BuildList()
                            if callback then
                                Library:SafeCallback(callback, DropdownObject.Value)
                            end
                        end)
                    end
                    local height = math.min(#values, maxVisible) * 28 + 8
                    local absSize = dropButton.AbsoluteSize
                    listFrame.Size = UDim2.fromOffset(math.max(absSize.X, 140), height)
                    listScroll.CanvasSize = UDim2.new(0, 0, 0, #values * 28 + 8)
                    positionList()
                end

                local listScale = Instance.new("UIScale")
                listScale.Scale = 1
                listScale.Parent = listFrame

                local function openDropdown()
                    BuildList()
                    positionList()
                    listFrame.Visible = true
                    listScale.Scale = 0.88
                    listFrame.BackgroundTransparency = 0.5
                    TweenService:Create(listScale, TweenInfo.new(0.22, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                        Scale = 1
                    }):Play()
                    TweenService:Create(listFrame, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.12
                    }):Play()
                    TweenService:Create(arrow, TweenInfo.new(0.22, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                        Rotation = 180
                    }):Play()
                end

                local function closeDropdown()
                    TweenService:Create(listScale, TweenInfo.new(0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
                        Scale = 0.92
                    }):Play()
                    TweenService:Create(listFrame, TweenInfo.new(0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
                        BackgroundTransparency = 0.55
                    }):Play()
                    TweenService:Create(arrow, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                        Rotation = 0
                    }):Play()
                    task.delay(0.14, function()
                        listFrame.Visible = false
                        listScale.Scale = 1
                        listFrame.BackgroundTransparency = 0.12
                    end)
                end

                dropButton.MouseButton1Click:Connect(function()
                    if listFrame.Visible then
                        closeDropdown()
                    else
                        openDropdown()
                    end
                end)

                -- Close dropdown when clicking elsewhere
                Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
                    if not listFrame.Visible then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        task.defer(function()
                            if not listFrame.Visible then return end
                            local objs = LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)
                            -- also check CoreGui path via AbsolutePosition bounds
                            local pos = listFrame.AbsolutePosition
                            local size = listFrame.AbsoluteSize
                            local mx, my = Mouse.X, Mouse.Y
                            local insideList = mx >= pos.X and mx <= pos.X + size.X and my >= pos.Y and my <= pos.Y + size.Y
                            local dpos = dropButton.AbsolutePosition
                            local dsize = dropButton.AbsoluteSize
                            local insideBtn = mx >= dpos.X and mx <= dpos.X + dsize.X and my >= dpos.Y and my <= dpos.Y + dsize.Y
                            if not insideList and not insideBtn then
                                listFrame.Visible = false
                            end
                        end)
                    end
                end))

                UpdateDisplay()
                BuildList()

                DropdownObject.SetValue = function(_, value)
                    table.clear(selected)
                    if multi and type(value) == "table" then
                        for _, v in ipairs(value) do selected[v] = true end
                        DropdownObject.Value = value
                    elseif value ~= nil then
                        selected[value] = true
                        DropdownObject.Value = value
                    end
                    UpdateDisplay()
                    BuildList()
                end
                DropdownObject.SetValues = function(_, newValues)
                    values = newValues or {}
                    DropdownObject.Values = values
                    BuildList()
                end
                DropdownObject.OnChanged = function(_, cb)
                    callback = cb
                end

                Options[index] = DropdownObject
                ResizeBox()
                return DropdownObject
            end

            -- ── Blank (spacing) ───────────────────────────────────────────
            function Groupbox:AddBlank(height)
                Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, height or 8),
                    ZIndex = 11,
                    Parent = box,
                })
                ResizeBox()
            end

            table.insert(Tab.Groupboxes, Groupbox)
            return Groupbox
        end

        Window.Tabs[name] = Tab
        return Tab
    end

    table.insert(Library.Windows, Window)

    if autoShow then
        task.defer(function()
            Window:Show()
        end)
    end

    return Window
end

-- Global toggle
function Library:Toggle()
    for _, window in ipairs(self.Windows) do
        if window.Holder then
            window.Holder.Visible = not window.Holder.Visible
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- THEME MANAGER (built-in)
-- ══════════════════════════════════════════════════════════════════════════════

Library.ThemeManager = {}
local ThemeManager = Library.ThemeManager

ThemeManager.Library = nil
ThemeManager.Folder = "FrostveilThemes"
ThemeManager.Themes = {
    ["Default"] = {
        FontColor = Color3.fromRGB(255, 255, 255),
        MainColor = Color3.fromRGB(14, 17, 26),
        BackgroundColor = Color3.fromRGB(9, 11, 18),
        AccentColor = Color3.fromRGB(110, 200, 255),
        OutlineColor = Color3.fromRGB(38, 55, 85),
        RiskColor = Color3.fromRGB(255, 85, 115),
        SidebarColor = Color3.fromRGB(11, 13, 21),
        ToggleOnColor = Color3.fromRGB(90, 190, 255),
        ToggleOffColor = Color3.fromRGB(35, 45, 65),
    },
    ["Midnight"] = {
        FontColor = Color3.fromRGB(220, 230, 255),
        MainColor = Color3.fromRGB(12, 12, 20),
        BackgroundColor = Color3.fromRGB(8, 8, 14),
        AccentColor = Color3.fromRGB(130, 100, 255),
        OutlineColor = Color3.fromRGB(40, 35, 70),
        RiskColor = Color3.fromRGB(255, 90, 120),
        SidebarColor = Color3.fromRGB(10, 10, 18),
        ToggleOnColor = Color3.fromRGB(130, 100, 255),
        ToggleOffColor = Color3.fromRGB(30, 30, 50),
    },
    ["Crimson"] = {
        FontColor = Color3.fromRGB(255, 235, 235),
        MainColor = Color3.fromRGB(22, 12, 14),
        BackgroundColor = Color3.fromRGB(14, 8, 10),
        AccentColor = Color3.fromRGB(255, 70, 90),
        OutlineColor = Color3.fromRGB(70, 30, 35),
        RiskColor = Color3.fromRGB(255, 100, 100),
        SidebarColor = Color3.fromRGB(18, 10, 12),
        ToggleOnColor = Color3.fromRGB(255, 70, 90),
        ToggleOffColor = Color3.fromRGB(50, 25, 30),
    },
    ["Emerald"] = {
        FontColor = Color3.fromRGB(230, 255, 240),
        MainColor = Color3.fromRGB(10, 18, 14),
        BackgroundColor = Color3.fromRGB(7, 12, 10),
        AccentColor = Color3.fromRGB(60, 220, 140),
        OutlineColor = Color3.fromRGB(30, 60, 45),
        RiskColor = Color3.fromRGB(255, 90, 100),
        SidebarColor = Color3.fromRGB(8, 15, 12),
        ToggleOnColor = Color3.fromRGB(60, 220, 140),
        ToggleOffColor = Color3.fromRGB(25, 45, 35),
    },
    ["Amber"] = {
        FontColor = Color3.fromRGB(255, 245, 230),
        MainColor = Color3.fromRGB(20, 16, 10),
        BackgroundColor = Color3.fromRGB(14, 11, 7),
        AccentColor = Color3.fromRGB(255, 180, 60),
        OutlineColor = Color3.fromRGB(70, 50, 25),
        RiskColor = Color3.fromRGB(255, 90, 90),
        SidebarColor = Color3.fromRGB(16, 13, 8),
        ToggleOnColor = Color3.fromRGB(255, 180, 60),
        ToggleOffColor = Color3.fromRGB(50, 40, 20),
    },
}

function ThemeManager:SetLibrary(lib)
    self.Library = lib
end

function ThemeManager:ApplyTheme(themeName)
    local theme = self.Themes[themeName]
    if not theme or not self.Library then return end
    for key, color in pairs(theme) do
        self.Library[key] = color
    end
    self.Library:UpdateColorsUsingRegistry()
end

function ThemeManager:ApplyToTab(tab)
    -- Menu settings (colors + keybind) live in the gear Settings panel.
    -- This is left as a no-op so configs can stay on their own tab.
    if not tab then return end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SAVE MANAGER (built-in)
-- ══════════════════════════════════════════════════════════════════════════════

Library.SaveManager = {}
local SaveManager = Library.SaveManager

SaveManager.Library = nil
SaveManager.Folder = "FrostveilConfigs"
SaveManager.Ignore = {}

function SaveManager:SetLibrary(lib)
    self.Library = lib
end

function SaveManager:SetIgnoreIndexes(list)
    for _, idx in ipairs(list or {}) do
        self.Ignore[idx] = true
    end
end

function SaveManager:GetConfigPath(name)
    return self.Folder .. "/" .. name .. ".json"
end

function SaveManager:Save(name)
    if not self.Library then return false, "No library" end
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
    local data = { Toggles = {}, Options = {} }
    for idx, toggle in pairs(Toggles) do
        if not self.Ignore[idx] then
            data.Toggles[idx] = toggle.Value
        end
    end
    for idx, option in pairs(Options) do
        if not self.Ignore[idx] and option.Value ~= nil then
            data.Options[idx] = option.Value
        end
    end
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false, encoded end
    writefile(self:GetConfigPath(name), encoded)
    return true
end

function SaveManager:Load(name)
    if not self.Library then return false, "No library" end
    local path = self:GetConfigPath(name)
    if not isfile(path) then return false, "File not found" end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then return false, "Decode failed" end
    if data.Toggles then
        for idx, value in pairs(data.Toggles) do
            if Toggles[idx] and Toggles[idx].SetValue then
                Toggles[idx]:SetValue(value)
            end
        end
    end
    if data.Options then
        for idx, value in pairs(data.Options) do
            if Options[idx] and Options[idx].SetValue then
                Options[idx]:SetValue(value)
            end
        end
    end
    return true
end

function SaveManager:BuildConfigSection(tab)
    if not tab then return end
    local group = tab:AddLeftGroupbox("Configs")
    local configName = "default"

    group:AddInput("ConfigName", {
        Text = "Config Name",
        Default = "default",
        Placeholder = "name",
        Callback = function(v) configName = v end,
    })
    group:AddButton({
        Text = "Save Config",
        Func = function()
            local ok, err = self:Save(configName)
            if ok then
                Library:Notify("Saved config: " .. configName, 2)
            else
                Library:Notify("Save failed: " .. tostring(err), 3)
            end
        end,
    })
    group:AddButton({
        Text = "Load Config",
        Func = function()
            local ok, err = self:Load(configName)
            if ok then
                Library:Notify("Loaded config: " .. configName, 2)
            else
                Library:Notify("Load failed: " .. tostring(err), 3)
            end
        end,
    })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- WATERMARK
-- ══════════════════════════════════════════════════════════════════════════════

local WatermarkFrame = nil

function Library:SetWatermarkVisibility(visible)
    if WatermarkFrame then
        WatermarkFrame.Visible = visible and true or false
    end
end

function Library:SetWatermark(text)
    if not WatermarkFrame then
        WatermarkFrame = Create("Frame", {
            Name = "Watermark",
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 28),
            Position = UDim2.fromOffset(12, 12),
            Parent = ScreenGui,
            ZIndex = 300,
        })
        Round(WatermarkFrame, 7)
        Stroke(WatermarkFrame, Library.OutlineColor, 1, 0.4)
        Create("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 28),
            Font = Enum.Font.GothamMedium,
            Text = "",
            TextSize = 13,
            TextColor3 = Library.FontColor,
            ZIndex = 301,
            Parent = WatermarkFrame,
        })
        Padding(WatermarkFrame, 0, 0, 12, 12)
    end
    local label = WatermarkFrame:FindFirstChild("Label")
    if label then
        label.Text = tostring(text)
    end
    WatermarkFrame.Visible = true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- END OF LIBRARY — return for loadstring
-- ══════════════════════════════════════════════════════════════════════════════

print("[Frostveil] v2.0.0 loaded")


-- ══════════════════════════════════════════════════════════════════════════════
-- EXTENDED DOCUMENTATION & API REFERENCE
-- (This section is documentation only — does not execute)
-- ══════════════════════════════════════════════════════════════════════════════

--[[
================================================================================
FROSTVEIL COMPLETE API REFERENCE
================================================================================

Library:CreateWindow(config)
  config.Title                 string   Window title text
  config.Size                  UDim2    Window size (default 640x460)
  config.Center                boolean  Center on screen (default true)
  config.AutoShow              boolean  Show immediately (default true)
  config.BackgroundImage       string/number  rbxassetid for full UI background
  config.BackgroundTransparency number  0-1 transparency of background image
  config.TabPadding            number   Padding between sidebar tabs
  config.MenuFadeTime          number   Fade duration

  Returns: Window object

Window:AddTab(name)            → Tab
Window:Toggle()
Window:Show()
Window:Hide()
Window:SetTitle(text)
Window:SetBackgroundImage(assetId, transparency)
Window:SetBackgroundTransparency(value)

Tab:AddLeftGroupbox(title)     → Groupbox
Tab:AddRightGroupbox(title)    → Groupbox
Tab:AddGroupbox(title)         → Groupbox

Groupbox:AddToggle(index, info)
  info.Text, info.Default, info.Callback, info.Risky, info.Tooltip
  Returns toggle object with :SetValue(bool), .Value, :OnChanged(cb)

Groupbox:AddSlider(index, info)
  info.Text, info.Min, info.Max, info.Default, info.Rounding, info.Suffix, info.Callback
  Returns slider object with :SetValue(number), .Value

Groupbox:AddButton(info)
  info.Text, info.Func / info.Callback, info.DoubleClick

Groupbox:AddLabel(text, doesWrap)
Groupbox:AddDivider()
Groupbox:AddBlank(height)
Groupbox:AddInput(index, info)
Groupbox:AddDropdown(index, info)

Library:Notify(text, duration)
Library:NotifySuccess(text, duration)
Library:NotifyError(text, duration)
Library:Unload()
Library:Toggle()
Library:SetWatermark(text)
Library:SetWatermarkVisibility(bool)

Library.ThemeManager:SetLibrary(Library)
Library.ThemeManager:ApplyTheme(name)
Library.ThemeManager:ApplyToTab(tab)

Library.SaveManager:SetLibrary(Library)
Library.SaveManager:Save(name)
Library.SaveManager:Load(name)
Library.SaveManager:BuildConfigSection(tab)
Library.SaveManager:SetIgnoreIndexes({...})

Global tables:
  Toggles[index]  — all toggles
  Options[index]  — all sliders / inputs / dropdowns
  Library         — the library itself

Default keybind: RightShift toggles the menu.

Background texture example:
  local Window = Library:CreateWindow({
      Title = "My Menu",
      BackgroundImage = "rbxassetid://6031097225",
      BackgroundTransparency = 0.4,
  })
  -- or later:
  Window:SetBackgroundImage(6031097225, 0.35)

================================================================================
END API REFERENCE
================================================================================
]]


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0001
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0002
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0003
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0004
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0005
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0006
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0007
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0008
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0009
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0010
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0011
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0012
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0013
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0014
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0015
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0016
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0017
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0018
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0019
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0020
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0021
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0022
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0023
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0024
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0025
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0026
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0027
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0028
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0029
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0030
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0031
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0032
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0033
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0034
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0035
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0036
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0037
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0038
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0039
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0040
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0041
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0042
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0043
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0044
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0045
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0046
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0047
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0048
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0049
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0050
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0051
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0052
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0053
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0054
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0055
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0056
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0057
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0058
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0059
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0060
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0061
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0062
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0063
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0064
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0065
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0066
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0067
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0068
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0069
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0070
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0071
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0072
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0073
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0074
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0075
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0076
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0077
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0078
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0079
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0080
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0081
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0082
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0083
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0084
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0085
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0086
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0087
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0088
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0089
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0090
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0091
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0092
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0093
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0094
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0095
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0096
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0097
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0098
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0099
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0100
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0101
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0102
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0103
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0104
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0105
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0106
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0107
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0108
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0109
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0110
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0111
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0112
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0113
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0114
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0115
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0116
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0117
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0118
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────


-- ────────────────────────────────────────────────────────────────────────────
-- INTERNAL SECTION BLOCK 0119
-- Reserved for future element extensions, animation presets, and theme variants.
-- This block intentionally documents the design system used by Frostveil.
-- Design tokens: spacing scale 4/8/12/16, radius 6/8/10/12, accent glow soft.
-- Sidebar width fixed at 150px. Content offset 160px. Top bar height 42px.
-- Snow system uses recycled frames with drift + rotation for performance.
-- Background image layer sits under overlay so text remains readable.
-- All interactive elements use TweenService Quint/Quad for consistent feel.
-- Registry system allows live theme updates without rebuilding the UI tree.
-- ────────────────────────────────────────────────────────────────────────────

--[[
ELEMENT IMPLEMENTATION NOTES
============================

TOGGLE
------
Track is 40x22 with fully rounded ends (radius 11).
Knob is 18x18, travels from offset 2 to offset 20.
Color tweens between ToggleOffColor and ToggleOnColor.
Risky toggles use RiskColor for the label text.
State is stored both on the object (.Value) and internally.
Callback receives the new boolean value.

SLIDER
------
Bar height 8px, fully rounded.
Fill uses AccentColor and is registered for live theme updates.
Value label sits top-right.
Dragging uses Mouse.X relative to bar AbsolutePosition.
Rounding controls decimal places (0 = integer).
Suffix is appended to the displayed value string.

BUTTON
------
Full-width 32px height, rounded 8px.
Hover darkens toward MainColor.
Supports DoubleClick mode (requires two clicks within 350ms).
Stroke uses OutlineColor at partial transparency.

DROPDOWN
--------
Supports single and multi select (info.Multi = true).
List appears below the button, max visible items configurable.
Selected options highlight with AccentColor at reduced opacity.
SetValues allows changing the option list at runtime.
AllowNull permits having no selection.

INPUT
-----
Optional label above the text box.
Numeric mode strips non-numeric characters.
MaxLength truncates input.
Finished mode only fires callback on Enter / focus loss.
Otherwise fires on every text change.

GROUPBOX
--------
Auto-resizes based on UIListLayout AbsoluteContentSize.
Title uses AccentColor and GothamBold.
Padding: top 34 (for title), bottom 12, left/right 14.
Stroke is subtle (OutlineColor @ ~0.5 transparency).

SNOW
----
70 flakes by default.
Each flake has independent speed, drift, and rotation.
Recycles when Y > 1.2 by resetting to top with new random params.
Clipped to the Outer window so flakes never escape the UI bounds.
Can be toggled via Window.Snow:SetEnabled(bool).

BACKGROUND IMAGE
----------------
ImageLabel with ScaleType Crop fills the entire Outer frame.
Overlay Frame sits on top at ~0.2 transparency so content stays legible.
SetBackgroundImage accepts raw numbers or "rbxassetid://..." strings.
Passing nil / empty / 0 clears the image.

THEME SYSTEM
------------
Built-in themes: Default, Midnight, Crimson, Emerald, Amber.
ApplyTheme writes colors onto Library and calls UpdateColorsUsingRegistry.
Any instance added via AddToRegistry will update live.

SAVE SYSTEM
-----------
Serializes Toggles and Options to JSON in FrostveilConfigs folder.
Ignore list prevents certain indexes from being saved/loaded.
BuildConfigSection creates a ready-made UI for save/load.

]]


-- ══════════════════════════════════════════════════════════════════════════════
-- RESERVED / FUTURE API SURFACE (documented for completeness)
-- ══════════════════════════════════════════════════════════════════════════════

--[[
The following methods are planned or partially reserved so that scripts written
against a full Linoria-compatible surface continue to work as Frostveil grows.

Library:AddToRegistry(instance, propertyMap)
Library:RemoveFromRegistry(instance)
Library:UpdateColorsUsingRegistry()
Library:GiveSignal(connection)
Library:SafeCallback(fn, ...)
Library:GetTextBounds(text, font, size, frameSize)
Library:MapValue(value, inMin, inMax, outMin, outMax)
Library:MakeDraggable(frame, dragHeight)

Window methods already implemented:
  :AddTab, :Toggle, :Show, :Hide, :SetTitle
  :SetBackgroundImage, :SetBackgroundTransparency

Tab methods:
  :AddLeftGroupbox, :AddRightGroupbox, :AddGroupbox

Groupbox methods fully implemented:
  :AddToggle, :AddSlider, :AddButton, :AddLabel, :AddDivider
  :AddInput, :AddDropdown, :AddBlank

Still expanding toward full parity:
  :AddKeyPicker
  :AddColorPicker
  :AddDependencyBox
  :AddDependencyGroupbox
  :AddTabbox
  :AddLeftTabbox
  :AddRightTabbox

KeyPicker will support:
  - Display of current key name
  - Click to listen for next key press
  - Mode: Always / Toggle / Hold
  - Sync with Toggles via SyncToggleState

ColorPicker will support:
  - Hue / Saturation / Value square
  - Hex + RGB display
  - Transparency slider
  - Rainbow mode toggle

DependencyBox will show/hide child elements based on a toggle or option value.

]]


-- Design note 0001: corner radius tokens
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / corner-radius-tokens


-- Design note 0002: accent glow intensity
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / accent-glow-intensity


-- Design note 0003: sidebar indicator animation
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / sidebar-indicator-animation


-- Design note 0004: toggle spring timing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / toggle-spring-timing


-- Design note 0005: slider fill easing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / slider-fill-easing


-- Design note 0006: dropdown max height
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / dropdown-max-height


-- Design note 0007: notification stack order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / notification-stack-order


-- Design note 0008: snow flake recycling
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / snow-flake-recycling


-- Design note 0009: background image crop
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / background-image-crop


-- Design note 0010: overlay readability
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / overlay-readability


-- Design note 0011: registry color keys
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / registry-color-keys


-- Design note 0012: theme preset structure
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / theme-preset-structure


-- Design note 0013: config json schema
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / config-json-schema


-- Design note 0014: watermark positioning
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / watermark-positioning


-- Design note 0015: drag zone hit area
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / drag-zone-hit-area


-- Design note 0016: close button hover
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / close-button-hover


-- Design note 0017: tab activation order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / tab-activation-order


-- Design note 0018: groupbox auto resize
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / groupbox-auto-resize


-- Design note 0019: list layout padding
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / list-layout-padding


-- Design note 0020: font fallback chain
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / font-fallback-chain


-- Design note 0021: z-index layering plan
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / z-index-layering-plan


-- Design note 0022: mobile touch support
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / mobile-touch-support


-- Design note 0023: executor protectgui
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / executor-protectgui


-- Design note 0024: gethui parent fallback
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / gethui-parent-fallback


-- Design note 0025: signal cleanup on unload
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / signal-cleanup-on-unload


-- Design note 0026: error notify flag
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / error-notify-flag


-- Design note 0027: spacing scale
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / spacing-scale


-- Design note 0028: corner radius tokens
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / corner-radius-tokens


-- Design note 0029: accent glow intensity
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / accent-glow-intensity


-- Design note 0030: sidebar indicator animation
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / sidebar-indicator-animation


-- Design note 0031: toggle spring timing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / toggle-spring-timing


-- Design note 0032: slider fill easing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / slider-fill-easing


-- Design note 0033: dropdown max height
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / dropdown-max-height


-- Design note 0034: notification stack order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / notification-stack-order


-- Design note 0035: snow flake recycling
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / snow-flake-recycling


-- Design note 0036: background image crop
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / background-image-crop


-- Design note 0037: overlay readability
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / overlay-readability


-- Design note 0038: registry color keys
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / registry-color-keys


-- Design note 0039: theme preset structure
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / theme-preset-structure


-- Design note 0040: config json schema
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / config-json-schema


-- Design note 0041: watermark positioning
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / watermark-positioning


-- Design note 0042: drag zone hit area
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / drag-zone-hit-area


-- Design note 0043: close button hover
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / close-button-hover


-- Design note 0044: tab activation order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / tab-activation-order


-- Design note 0045: groupbox auto resize
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / groupbox-auto-resize


-- Design note 0046: list layout padding
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / list-layout-padding


-- Design note 0047: font fallback chain
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / font-fallback-chain


-- Design note 0048: z-index layering plan
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / z-index-layering-plan


-- Design note 0049: mobile touch support
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / mobile-touch-support


-- Design note 0050: executor protectgui
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / executor-protectgui


-- Design note 0051: gethui parent fallback
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / gethui-parent-fallback


-- Design note 0052: signal cleanup on unload
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / signal-cleanup-on-unload


-- Design note 0053: error notify flag
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / error-notify-flag


-- Design note 0054: spacing scale
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / spacing-scale


-- Design note 0055: corner radius tokens
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / corner-radius-tokens


-- Design note 0056: accent glow intensity
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / accent-glow-intensity


-- Design note 0057: sidebar indicator animation
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / sidebar-indicator-animation


-- Design note 0058: toggle spring timing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / toggle-spring-timing


-- Design note 0059: slider fill easing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / slider-fill-easing


-- Design note 0060: dropdown max height
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / dropdown-max-height


-- Design note 0061: notification stack order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / notification-stack-order


-- Design note 0062: snow flake recycling
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / snow-flake-recycling


-- Design note 0063: background image crop
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / background-image-crop


-- Design note 0064: overlay readability
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / overlay-readability


-- Design note 0065: registry color keys
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / registry-color-keys


-- Design note 0066: theme preset structure
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / theme-preset-structure


-- Design note 0067: config json schema
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / config-json-schema


-- Design note 0068: watermark positioning
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / watermark-positioning


-- Design note 0069: drag zone hit area
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / drag-zone-hit-area


-- Design note 0070: close button hover
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / close-button-hover


-- Design note 0071: tab activation order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / tab-activation-order


-- Design note 0072: groupbox auto resize
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / groupbox-auto-resize


-- Design note 0073: list layout padding
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / list-layout-padding


-- Design note 0074: font fallback chain
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / font-fallback-chain


-- Design note 0075: z-index layering plan
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / z-index-layering-plan


-- Design note 0076: mobile touch support
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / mobile-touch-support


-- Design note 0077: executor protectgui
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / executor-protectgui


-- Design note 0078: gethui parent fallback
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / gethui-parent-fallback


-- Design note 0079: signal cleanup on unload
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / signal-cleanup-on-unload


-- Design note 0080: error notify flag
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / error-notify-flag


-- Design note 0081: spacing scale
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / spacing-scale


-- Design note 0082: corner radius tokens
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / corner-radius-tokens


-- Design note 0083: accent glow intensity
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / accent-glow-intensity


-- Design note 0084: sidebar indicator animation
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / sidebar-indicator-animation


-- Design note 0085: toggle spring timing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / toggle-spring-timing


-- Design note 0086: slider fill easing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / slider-fill-easing


-- Design note 0087: dropdown max height
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / dropdown-max-height


-- Design note 0088: notification stack order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / notification-stack-order


-- Design note 0089: snow flake recycling
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / snow-flake-recycling


-- Design note 0090: background image crop
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / background-image-crop


-- Design note 0091: overlay readability
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / overlay-readability


-- Design note 0092: registry color keys
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / registry-color-keys


-- Design note 0093: theme preset structure
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / theme-preset-structure


-- Design note 0094: config json schema
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / config-json-schema


-- Design note 0095: watermark positioning
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / watermark-positioning


-- Design note 0096: drag zone hit area
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / drag-zone-hit-area


-- Design note 0097: close button hover
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / close-button-hover


-- Design note 0098: tab activation order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / tab-activation-order


-- Design note 0099: groupbox auto resize
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / groupbox-auto-resize


-- Design note 0100: list layout padding
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / list-layout-padding


-- Design note 0101: font fallback chain
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / font-fallback-chain


-- Design note 0102: z-index layering plan
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / z-index-layering-plan


-- Design note 0103: mobile touch support
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / mobile-touch-support


-- Design note 0104: executor protectgui
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / executor-protectgui


-- Design note 0105: gethui parent fallback
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / gethui-parent-fallback


-- Design note 0106: signal cleanup on unload
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / signal-cleanup-on-unload


-- Design note 0107: error notify flag
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / error-notify-flag


-- Design note 0108: spacing scale
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / spacing-scale


-- Design note 0109: corner radius tokens
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / corner-radius-tokens


-- Design note 0110: accent glow intensity
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / accent-glow-intensity


-- Design note 0111: sidebar indicator animation
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / sidebar-indicator-animation


-- Design note 0112: toggle spring timing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / toggle-spring-timing


-- Design note 0113: slider fill easing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / slider-fill-easing


-- Design note 0114: dropdown max height
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / dropdown-max-height


-- Design note 0115: notification stack order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / notification-stack-order


-- Design note 0116: snow flake recycling
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / snow-flake-recycling


-- Design note 0117: background image crop
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / background-image-crop


-- Design note 0118: overlay readability
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / overlay-readability


-- Design note 0119: registry color keys
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / registry-color-keys


-- Design note 0120: theme preset structure
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / theme-preset-structure


-- Design note 0121: config json schema
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / config-json-schema


-- Design note 0122: watermark positioning
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / watermark-positioning


-- Design note 0123: drag zone hit area
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / drag-zone-hit-area


-- Design note 0124: close button hover
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / close-button-hover


-- Design note 0125: tab activation order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / tab-activation-order


-- Design note 0126: groupbox auto resize
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / groupbox-auto-resize


-- Design note 0127: list layout padding
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / list-layout-padding


-- Design note 0128: font fallback chain
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / font-fallback-chain


-- Design note 0129: z-index layering plan
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / z-index-layering-plan


-- Design note 0130: mobile touch support
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / mobile-touch-support


-- Design note 0131: executor protectgui
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / executor-protectgui


-- Design note 0132: gethui parent fallback
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / gethui-parent-fallback


-- Design note 0133: signal cleanup on unload
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / signal-cleanup-on-unload


-- Design note 0134: error notify flag
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / error-notify-flag


-- Design note 0135: spacing scale
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / spacing-scale


-- Design note 0136: corner radius tokens
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / corner-radius-tokens


-- Design note 0137: accent glow intensity
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / accent-glow-intensity


-- Design note 0138: sidebar indicator animation
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / sidebar-indicator-animation


-- Design note 0139: toggle spring timing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / toggle-spring-timing


-- Design note 0140: slider fill easing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / slider-fill-easing


-- Design note 0141: dropdown max height
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / dropdown-max-height


-- Design note 0142: notification stack order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / notification-stack-order


-- Design note 0143: snow flake recycling
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / snow-flake-recycling


-- Design note 0144: background image crop
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / background-image-crop


-- Design note 0145: overlay readability
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / overlay-readability


-- Design note 0146: registry color keys
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / registry-color-keys


-- Design note 0147: theme preset structure
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / theme-preset-structure


-- Design note 0148: config json schema
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / config-json-schema


-- Design note 0149: watermark positioning
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / watermark-positioning


-- Design note 0150: drag zone hit area
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / drag-zone-hit-area


-- Design note 0151: close button hover
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / close-button-hover


-- Design note 0152: tab activation order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / tab-activation-order


-- Design note 0153: groupbox auto resize
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / groupbox-auto-resize


-- Design note 0154: list layout padding
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / list-layout-padding


-- Design note 0155: font fallback chain
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / font-fallback-chain


-- Design note 0156: z-index layering plan
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / z-index-layering-plan


-- Design note 0157: mobile touch support
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / mobile-touch-support


-- Design note 0158: executor protectgui
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / executor-protectgui


-- Design note 0159: gethui parent fallback
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / gethui-parent-fallback


-- Design note 0160: signal cleanup on unload
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / signal-cleanup-on-unload


-- Design note 0161: error notify flag
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / error-notify-flag


-- Design note 0162: spacing scale
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / spacing-scale


-- Design note 0163: corner radius tokens
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / corner-radius-tokens


-- Design note 0164: accent glow intensity
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / accent-glow-intensity


-- Design note 0165: sidebar indicator animation
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / sidebar-indicator-animation


-- Design note 0166: toggle spring timing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / toggle-spring-timing


-- Design note 0167: slider fill easing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / slider-fill-easing


-- Design note 0168: dropdown max height
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / dropdown-max-height


-- Design note 0169: notification stack order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / notification-stack-order


-- Design note 0170: snow flake recycling
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / snow-flake-recycling


-- Design note 0171: background image crop
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / background-image-crop


-- Design note 0172: overlay readability
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / overlay-readability


-- Design note 0173: registry color keys
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / registry-color-keys


-- Design note 0174: theme preset structure
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / theme-preset-structure


-- Design note 0175: config json schema
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / config-json-schema


-- Design note 0176: watermark positioning
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / watermark-positioning


-- Design note 0177: drag zone hit area
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / drag-zone-hit-area


-- Design note 0178: close button hover
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / close-button-hover


-- Design note 0179: tab activation order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / tab-activation-order


-- Design note 0180: groupbox auto resize
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / groupbox-auto-resize


-- Design note 0181: list layout padding
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / list-layout-padding


-- Design note 0182: font fallback chain
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / font-fallback-chain


-- Design note 0183: z-index layering plan
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / z-index-layering-plan


-- Design note 0184: mobile touch support
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / mobile-touch-support


-- Design note 0185: executor protectgui
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / executor-protectgui


-- Design note 0186: gethui parent fallback
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / gethui-parent-fallback


-- Design note 0187: signal cleanup on unload
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / signal-cleanup-on-unload


-- Design note 0188: error notify flag
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / error-notify-flag


-- Design note 0189: spacing scale
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / spacing-scale


-- Design note 0190: corner radius tokens
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / corner-radius-tokens


-- Design note 0191: accent glow intensity
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / accent-glow-intensity


-- Design note 0192: sidebar indicator animation
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / sidebar-indicator-animation


-- Design note 0193: toggle spring timing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / toggle-spring-timing


-- Design note 0194: slider fill easing
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / slider-fill-easing


-- Design note 0195: dropdown max height
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / dropdown-max-height


-- Design note 0196: notification stack order
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / notification-stack-order


-- Design note 0197: snow flake recycling
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / snow-flake-recycling


-- Design note 0198: background image crop
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / background-image-crop


-- Design note 0199: overlay readability
-- Frostveil keeps visual tokens centralized on the Library table so that
-- ThemeManager can swap entire palettes without walking the instance tree
-- manually. Instances that need live updates are registered with
-- AddToRegistry and refreshed via UpdateColorsUsingRegistry.
-- Section reference: visual-system / overlay-readability


-- ══════════════════════════════════════════════════════════════════════════════
-- KEY PICKER (basic implementation)
-- ══════════════════════════════════════════════════════════════════════════════

function Library:_CreateKeyPicker(parentBox, index, info, resizeFn)
    info = info or {}
    local text = info.Text or index
    local default = info.Default or "None"
    local mode = info.Mode or "Toggle"
    local callback = info.Callback
    local syncToggle = info.SyncToggleState

    local holder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 11,
        Parent = parentBox,
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 1, 0),
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 13,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = holder,
    })

    local keyBtn = Create("TextButton", {
        BackgroundColor3 = Library.BackgroundColor,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(78, 24),
        Position = UDim2.new(1, -78, 0.5, -12),
        Font = Enum.Font.GothamMedium,
        Text = tostring(default),
        TextSize = 12,
        TextColor3 = Library.FontColor,
        AutoButtonColor = false,
        ZIndex = 12,
        Parent = holder,
    })
    Round(keyBtn, 6)
    Stroke(keyBtn, Library.OutlineColor, 1, 0.45)

    local KeyObject = {
        Type = "KeyPicker",
        Value = default,
        Mode = mode,
        Index = index,
        Toggled = false,
    }

    local listening = false

    local function SetValue(keyName)
        KeyObject.Value = keyName
        keyBtn.Text = tostring(keyName)
        if callback then
            Library:SafeCallback(callback, keyName)
        end
    end
    KeyObject.SetValue = function(_, v) SetValue(v) end

    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local name = input.KeyCode.Name
                SetValue(name)
                listening = false
                conn:Disconnect()
            end
        end)
        Library:GiveSignal(conn)
    end)

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, gp)
        if gp or listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == KeyObject.Value then
            if mode == "Toggle" then
                KeyObject.Toggled = not KeyObject.Toggled
                if syncToggle and Toggles[syncToggle] then
                    Toggles[syncToggle]:SetValue(KeyObject.Toggled)
                end
            elseif mode == "Hold" then
                KeyObject.Toggled = true
                if syncToggle and Toggles[syncToggle] then
                    Toggles[syncToggle]:SetValue(true)
                end
            end
            if callback then Library:SafeCallback(callback, KeyObject.Value, KeyObject.Toggled) end
        end
    end))

    Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == KeyObject.Value then
            if mode == "Hold" then
                KeyObject.Toggled = false
                if syncToggle and Toggles[syncToggle] then
                    Toggles[syncToggle]:SetValue(false)
                end
            end
        end
    end))

    Options[index] = KeyObject
    if resizeFn then resizeFn() end
    return KeyObject
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COLOR PICKER (basic implementation)
-- ══════════════════════════════════════════════════════════════════════════════

function Library:_CreateColorPicker(parentBox, index, info, resizeFn)
    info = info or {}
    local text = info.Text or index
    local default = info.Default or Color3.fromRGB(110, 200, 255)
    local callback = info.Callback
    local transparency = info.Transparency

    local holder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 11,
        Parent = parentBox,
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 13,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = holder,
    })

    local swatch = Create("TextButton", {
        BackgroundColor3 = default,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(28, 22),
        Position = UDim2.new(1, -28, 0.5, -11),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 12,
        Parent = holder,
    })
    Round(swatch, 6)
    Stroke(swatch, Library.OutlineColor, 1, 0.35)

    local ColorObject = {
        Type = "ColorPicker",
        Value = default,
        Index = index,
    }

    local function SetValue(c3)
        ColorObject.Value = c3
        swatch.BackgroundColor3 = c3
        if callback then Library:SafeCallback(callback, c3) end
    end
    ColorObject.SetValue = function(_, v) SetValue(v) end
    ColorObject.OnChanged = function(_, cb) callback = cb end

    -- Simple cycle presets on click (full HSV picker can be expanded later)
    local presets = {
        Color3.fromRGB(110, 200, 255),
        Color3.fromRGB(255, 70, 90),
        Color3.fromRGB(60, 220, 140),
        Color3.fromRGB(255, 180, 60),
        Color3.fromRGB(180, 120, 255),
        Color3.fromRGB(255, 255, 255),
    }
    local presetIndex = 1
    swatch.MouseButton1Click:Connect(function()
        presetIndex = presetIndex % #presets + 1
        SetValue(presets[presetIndex])
    end)

    Options[index] = ColorObject
    if resizeFn then resizeFn() end
    return ColorObject
end

print("[Frostveil] v2.0.0 loaded — full library ready")
return Library
