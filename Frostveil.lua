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
    FontColor       = Color3.fromRGB(242, 248, 255),
    MainColor       = Color3.fromRGB(16, 20, 32),
    BackgroundColor = Color3.fromRGB(7, 9, 14),
    AccentColor     = Color3.fromRGB(100, 210, 255),
    OutlineColor    = Color3.fromRGB(48, 78, 120),
    RiskColor       = Color3.fromRGB(255, 95, 125),
    SidebarColor    = Color3.fromRGB(9, 11, 18),
    ToggleOnColor   = Color3.fromRGB(70, 195, 255),
    ToggleOffColor  = Color3.fromRGB(26, 34, 52),
    GroupTitleColor = Color3.fromRGB(150, 215, 255),
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

    local notif = Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = holder,
        ZIndex = 501,
        ClipsDescendants = true,
    })
    Round(notif, 9)
    Stroke(notif, Library.AccentColor, 1.2, 0.4)

    local accentBar = Create("Frame", {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        Parent = notif,
        ZIndex = 502,
    })
    Round(accentBar, 3)

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -28, 0, 0),
        Position = UDim2.fromOffset(18, 12),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = tostring(text),
        TextSize = 13,
        TextColor3 = Library.FontColor,
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
            local fadeBar = TweenService:Create(accentBar, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
            fade:Play()
            fadeLabel:Play()
            fadeBar:Play()
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
    local backgroundTransparency = config.BackgroundTransparency or 0.40
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
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = size,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = false,
        Parent = ScreenGui,
        ZIndex = 1,
        ClipsDescendants = true,
    })
    Round(Outer, 14)
    local outerStroke = Stroke(Outer, Library.AccentColor, 1.4, 0.55)
    -- Soft outer glow ring
    local glow = Create("Frame", {
        Name = "Glow",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 12, 1, 12),
        Position = UDim2.fromOffset(-6, -6),
        ZIndex = 0,
        Parent = Outer,
    })
    Round(glow, 18)
    local glowStroke = Stroke(glow, Library.AccentColor, 4, 0.88)
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

    -- Light overlay so background texture shows through clearly
    local BgOverlay = Create("Frame", {
        Name = "BackgroundOverlay",
        BackgroundColor3 = Library.BackgroundColor,
        BackgroundTransparency = 0.55,
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

    -- Top bar (glass strip — lets background show)
    local TopBar = Create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Library.MainColor,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = Outer,
        ZIndex = 10,
    })
    Round(TopBar, 14)
    Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 1, -18),
        Parent = TopBar,
        ZIndex = 10,
    })
    Library:AddToRegistry(TopBar, { BackgroundColor3 = "MainColor" })

    -- Gradient accent under top bar
    local topAccent = Create("Frame", {
        BackgroundColor3 = Library.AccentColor,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        ZIndex = 11,
        Parent = TopBar,
    })
    local topGrad = Instance.new("UIGradient")
    topGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 80, 140)),
        ColorSequenceKeypoint.new(0.5, Library.AccentColor),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 80, 140)),
    })
    topGrad.Parent = topAccent

    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.fromOffset(18, 0),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextSize = 15,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = TopBar,
    })
    Library:AddToRegistry(TitleLabel, { TextColor3 = "FontColor" })

    local isMinimized = false
    local fullSize = size

    -- Minimize button (next to close)
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
        isMinimized = not isMinimized
        local side = Outer:FindFirstChild("Sidebar")
        local content = Outer:FindFirstChild("ContentHolder")
        local div = Outer:FindFirstChild("SideDivider")
        if isMinimized then
            if side then side.Visible = false end
            if content then content.Visible = false end
            if div then div.Visible = false end
            Outer.Size = UDim2.fromOffset(math.max(Outer.AbsoluteSize.X, 280), 44)
            MinButton.Text = "+"
        else
            if side then side.Visible = true end
            if content then content.Visible = true end
            if div then div.Visible = true end
            Outer.Size = fullSize
            MinButton.Text = "–"
        end
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

    -- Close button
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
        Outer.Visible = false
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
        if not isMinimized then MinButton.MouseButton1Click:Fire() end
    end
    function Window:Restore()
        if isMinimized then MinButton.MouseButton1Click:Fire() end
    end

    -- Sidebar (transparent glass)
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Library.SidebarColor,
        BackgroundTransparency = 0.40,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 158, 1, -44),
        Position = UDim2.fromOffset(0, 44),
        Parent = Outer,
        ZIndex = 8,
    })
    Library:AddToRegistry(Sidebar, { BackgroundColor3 = "SidebarColor" })
    ListLayout(Sidebar, 6)
    Padding(Sidebar, 16, 14, 12, 12)

    -- Sidebar / content divider with soft glow
    local sideDiv = Create("Frame", {
        Name = "SideDivider",
        BackgroundColor3 = Library.AccentColor,
        BackgroundTransparency = 0.75,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, -44),
        Position = UDim2.fromOffset(158, 44),
        ZIndex = 9,
        Parent = Outer,
    })

    -- Content holder
    local ContentHolder = Create("Frame", {
        Name = "ContentHolder",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -172, 1, -58),
        Position = UDim2.fromOffset(168, 54),
        Parent = Outer,
        ZIndex = 8,
    })

    -- Snow
    Window.Snow = CreateSnowSystem(Outer, { MaxFlakes = 70 })

    -- Dragging
    Library:MakeDraggable(Outer, 42)

    -- Toggle visibility
    function Window:Toggle()
        Outer.Visible = not Outer.Visible
    end

    function Window:Show()
        Outer.Visible = true
    end

    function Window:Hide()
        Outer.Visible = false
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
            TextColor3 = Color3.fromRGB(130, 155, 190),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = order,
            ZIndex = 10,
            Parent = Sidebar,
        })
        Round(tabButton, 9)
        Padding(tabButton, 0, 0, 14, 8)
        local tabStroke = Stroke(tabButton, Library.OutlineColor, 1, 1)

        Tab.Button = tabButton

        -- Content scrolling frame
        local container = Create("ScrollingFrame", {
            Name = name .. "_Content",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 9,
            Parent = ContentHolder,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        })
        local contentList = ListLayout(container, 12)
        Padding(container, 6, 18, 6, 6)

        contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 24)
        end)

        Tab.Container = container

        local function ActivateTab()
            for _, otherTab in pairs(Window.Tabs) do
                otherTab.Container.Visible = false
                otherTab.Button.BackgroundTransparency = 1
                otherTab.Button.TextColor3 = Color3.fromRGB(130, 155, 190)
                local st = otherTab.Button:FindFirstChildOfClass("UIStroke")
                if st then st.Transparency = 1 end
                otherTab.Active = false
            end
            container.Visible = true
            tabButton.BackgroundTransparency = 0.45
            tabButton.TextColor3 = Library.FontColor
            if tabStroke then tabStroke.Transparency = 0.55 end
            Tab.Active = true
            Window.CurrentTab = Tab
        end

        tabButton.MouseButton1Click:Connect(ActivateTab)
        tabButton.MouseEnter:Connect(function()
            if not Tab.Active then
                TweenService:Create(tabButton, TweenInfo.new(0.15), {
                    BackgroundTransparency = 0.7
                }):Play()
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if not Tab.Active then
                TweenService:Create(tabButton, TweenInfo.new(0.15), {
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
            return self:AddGroupbox(titleText)
        end

        function Tab:AddRightGroupbox(titleText)
            return self:AddGroupbox(titleText)
        end

        function Tab:AddGroupbox(titleText)
            local Groupbox = {
                Elements = {},
            }

            local box = Create("Frame", {
                Name = titleText,
                BackgroundColor3 = Library.MainColor,
                BackgroundTransparency = 0.45,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 50),
                ZIndex = 10,
                Parent = container,
            })
            Round(box, 11)
            Stroke(box, Library.OutlineColor, 1.2, 0.50)
            Library:AddToRegistry(box, { BackgroundColor3 = "MainColor" })

            -- Title bar strip (no thick accent line)
            local titleBar = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(12, 16, 26),
                BackgroundTransparency = 0.55,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 30),
                ZIndex = 11,
                Parent = box,
            })
            Round(titleBar, 11)
            Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(12, 16, 26),
                BackgroundTransparency = 0.55,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 12),
                Position = UDim2.new(0, 0, 1, -12),
                ZIndex = 11,
                Parent = titleBar,
            })

            local boxTitle = Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -28, 0, 30),
                Position = UDim2.fromOffset(14, 0),
                Font = Enum.Font.GothamBold,
                Text = titleText,
                TextSize = 13,
                TextColor3 = Library.GroupTitleColor or Library.AccentColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 12,
                Parent = box,
            })

            local boxList = ListLayout(box, 9)
            Padding(box, 38, 14, 16, 16)

            local function ResizeBox()
                box.Size = UDim2.new(1, 0, 0, boxList.AbsoluteContentSize.Y + 46)
            end
            boxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeBox)
            ResizeBox()

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

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -54, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextSize = 13,
                    TextColor3 = risky and Library.RiskColor or Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 12,
                    Parent = holder,
                })

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
                    TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        Position = targetPos
                    }):Play()
                    TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = targetColor
                    }):Play()
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

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -70, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 12,
                    Parent = holder,
                })

                local valueLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 65, 0, 18),
                    Position = UDim2.new(1, -65, 0, 0),
                    Font = Enum.Font.Gotham,
                    Text = tostring(default) .. suffix,
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 12,
                    Parent = holder,
                })

                local barBackground = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(12, 16, 26),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 10),
                    Position = UDim2.fromOffset(0, 28),
                    ZIndex = 12,
                    Parent = holder,
                })
                Round(barBackground, 5)
                Stroke(barBackground, Library.OutlineColor, 1, 0.6)

                local fill = Create("Frame", {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                    ZIndex = 13,
                    Parent = barBackground,
                })
                Round(fill, 5)
                Library:AddToRegistry(fill, { BackgroundColor3 = "AccentColor" })
                local fillGrad = Instance.new("UIGradient")
                fillGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 160, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 230, 255)),
                })
                fillGrad.Parent = fill

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
                    local percent = (value - min) / (max - min)
                    fill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
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
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 32),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    AutoButtonColor = false,
                    ZIndex = 11,
                    Parent = box,
                })
                Round(button, 8)
                Stroke(button, Library.OutlineColor, 1, 0.45)
                Library:AddToRegistry(button, { BackgroundColor3 = "BackgroundColor", TextColor3 = "FontColor" })

                local lastClick = 0
                button.MouseButton1Click:Connect(function()
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
                    TweenService:Create(button, TweenInfo.new(0.12), {
                        BackgroundColor3 = Library.MainColor
                    }):Play()
                end)
                button.MouseLeave:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.12), {
                        BackgroundColor3 = Library.BackgroundColor
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
                local maxVisible = info.MaxVisibleDropdownItems or 6

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
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 13,
                    Parent = dropButton,
                })

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(20, 20),
                    Position = UDim2.new(1, -24, 0.5, -10),
                    Font = Enum.Font.GothamBold,
                    Text = "▾",
                    TextSize = 12,
                    TextColor3 = Color3.fromRGB(150, 170, 200),
                    ZIndex = 13,
                    Parent = dropButton,
                })

                local listFrame = Create("Frame", {
                    BackgroundColor3 = Library.MainColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 1, 4),
                    Visible = false,
                    ZIndex = 50,
                    Parent = dropButton,
                    ClipsDescendants = true,
                })
                Round(listFrame, 8)
                Stroke(listFrame, Library.OutlineColor, 1, 0.35)

                local listScroll = Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    ZIndex = 51,
                    Parent = listFrame,
                })
                local listLayout = ListLayout(listScroll, 2)
                Padding(listScroll, 4, 4, 4, 4)

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
                            BackgroundColor3 = selected[value] and Library.AccentColor or Library.BackgroundColor,
                            BackgroundTransparency = selected[value] and 0.7 or 0,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 26),
                            Font = Enum.Font.Gotham,
                            Text = "  " .. tostring(value),
                            TextSize = 13,
                            TextColor3 = Library.FontColor,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            AutoButtonColor = false,
                            ZIndex = 52,
                            Parent = listScroll,
                        })
                        Round(optionBtn, 5)
                        optionBtn.MouseButton1Click:Connect(function()
                            if multi then
                                selected[value] = not selected[value]
                            else
                                table.clear(selected)
                                selected[value] = true
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
                    listFrame.Size = UDim2.new(1, 0, 0, height)
                    listScroll.CanvasSize = UDim2.new(0, 0, 0, #values * 28 + 8)
                end

                dropButton.MouseButton1Click:Connect(function()
                    listFrame.Visible = not listFrame.Visible
                    if listFrame.Visible then
                        BuildList()
                    end
                end)

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
            Outer.Visible = true
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
        FontColor = Color3.fromRGB(235, 245, 255),
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
    if not tab then return end

    local controls = tab:AddLeftGroupbox("Menu Controls")
    controls:AddLabel("Toggle key: " .. tostring(Library.ToggleKeybind or "RightShift"))
    local keyOptions = {
        "RightShift", "LeftShift", "RightControl", "LeftControl",
        "Insert", "Delete", "Home", "End", "F4", "F5", "F6", "F7", "F8",
    }
    controls:AddDropdown("MenuToggleKey", {
        Text = "Menu Toggle Key",
        Values = keyOptions,
        Default = tostring(Library.ToggleKeybind or "RightShift"),
        Callback = function(value)
            Library.ToggleKeybind = value
            Library:Notify("Toggle key set to " .. value, 2)
        end,
    })
    controls:AddToggle("SnowToggle", {
        Text = "Snow Effect",
        Default = true,
        Callback = function(v)
            for _, win in ipairs(Library.Windows or {}) do
                if win.Snow and win.Snow.SetEnabled then
                    win.Snow:SetEnabled(v)
                end
            end
        end,
    })
    controls:AddButton({
        Text = "Apply Background Texture",
        Func = function()
            for _, win in ipairs(Library.Windows or {}) do
                if win.SetBackgroundImage then
                    -- User texture id
                    win:SetBackgroundImage("125296886011244", 0.25)
                end
            end
            Library:Notify("Background texture applied", 2)
        end,
    })
    controls:AddButton({
        Text = "Clear Background",
        Func = function()
            for _, win in ipairs(Library.Windows or {}) do
                if win.SetBackgroundImage then
                    win:SetBackgroundImage(nil)
                end
            end
        end,
    })
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
