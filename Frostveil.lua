--[[
    FROSTVEIL UI LIBRARY  v1.1
    Clean working version
    API style similar to Linoria | Custom look (sidebar + logo + snow)
]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local TextService       = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local RenderStepped = RunService.RenderStepped

-- Protect / parent helper (works on most executors)
local function ProtectAndParent(gui)
    local ok = pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
        if protect_gui then protect_gui(gui) end
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
ProtectAndParent(ScreenGui)

-- ══════════════════════════════════════════════════════════════
-- LIBRARY TABLE
-- ══════════════════════════════════════════════════════════════

local Library = {
    ScreenGui = ScreenGui,
    Windows = {},
    Toggles = {},
    Options = {},
    Signals = {},
    Unloaded = false,

    -- Theme
    FontColor       = Color3.fromRGB(235, 245, 255),
    MainColor       = Color3.fromRGB(14, 17, 26),
    BackgroundColor = Color3.fromRGB(9, 11, 18),
    AccentColor     = Color3.fromRGB(110, 200, 255),
    OutlineColor    = Color3.fromRGB(38, 55, 85),
    RiskColor       = Color3.fromRGB(255, 85, 115),
    SidebarColor    = Color3.fromRGB(11, 13, 21),
    ToggleOnColor   = Color3.fromRGB(90, 190, 255),
    ToggleOffColor  = Color3.fromRGB(35, 45, 65),
    LogoColor       = Color3.fromRGB(255, 60, 80),
    Font            = Enum.Font.GothamMedium,
}

getgenv().Toggles = Library.Toggles
getgenv().Options = Library.Options
getgenv().Library = Library

-- ══════════════════════════════════════════════════════════════
-- UTILITIES
-- ══════════════════════════════════════════════════════════════

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end

local function Round(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = inst
    return c
end

local function Stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Library.OutlineColor
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.3
    s.Parent = inst
    return s
end

function Library:GiveSignal(conn)
    table.insert(self.Signals, conn)
end

function Library:Notify(text, duration)
    duration = duration or 3
    local holder = ScreenGui:FindFirstChild("NotifHolder")
    if not holder then
        holder = Create("Frame", {
            Name = "NotifHolder",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 300, 1, 0),
            Position = UDim2.new(1, -320, 0, 20),
            Parent = ScreenGui,
            ZIndex = 200,
        })
        Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = holder,
        })
    end

    local notif = Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = holder,
        ZIndex = 201,
    })
    Round(notif, 8)
    Stroke(notif, Library.AccentColor, 1.2, 0.35)

    local bar = Create("Frame", {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        Parent = notif,
        ZIndex = 202,
    })
    Round(bar, 3)

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.fromOffset(16, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = tostring(text),
        TextSize = 13,
        TextColor3 = Library.FontColor,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 202,
        Parent = notif,
    })
    Create("UIPadding", {PaddingBottom = UDim.new(0, 10), Parent = notif})

    task.delay(duration, function()
        if notif and notif.Parent then
            TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            task.wait(0.3)
            notif:Destroy()
        end
    end)
end

function Library:Unload()
    for _, conn in ipairs(self.Signals) do
        pcall(function() conn:Disconnect() end)
    end
    self.Unloaded = true
    ScreenGui:Destroy()
end

-- ══════════════════════════════════════════════════════════════
-- SNOW SYSTEM
-- ══════════════════════════════════════════════════════════════

local function CreateSnow(parent)
    local container = Create("Frame", {
        Name = "Snow",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 50,
        Parent = parent,
    })

    local flakes = {}
    for i = 1, 60 do
        local size = math.random(2, 5)
        local flake = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(220, 240, 255),
            BackgroundTransparency = math.random(30, 60) / 100,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.new(math.random(), 0, math.random() - 0.2, 0),
            ZIndex = 51,
            Parent = container,
        })
        Round(flake, 10)
        table.insert(flakes, {
            inst = flake,
            x = math.random(),
            y = math.random() - 0.2,
            speed = math.random(35, 90) / 100,
            drift = (math.random() - 0.5) * 0.4,
            rot = 0,
            rotSpeed = (math.random() - 0.5) * 100,
        })
    end

    local conn = RenderStepped:Connect(function(dt)
        if not container.Parent then return end
        for _, f in ipairs(flakes) do
            f.y = f.y + f.speed * dt * 0.32
            f.x = f.x + f.drift * dt * 0.12
            f.rot = f.rot + f.rotSpeed * dt
            if f.y > 1.15 then
                f.y = -0.08
                f.x = math.random()
                f.speed = math.random(35, 90) / 100
            end
            f.inst.Position = UDim2.new(f.x, 0, f.y, 0)
            f.inst.Rotation = f.rot
        end
    end)
    Library:GiveSignal(conn)

    return {
        Container = container,
        SetEnabled = function(_, state)
            container.Visible = state
        end,
    }
end

-- ══════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ══════════════════════════════════════════════════════════════

function Library:CreateWindow(config)
    config = config or {}
    local title    = config.Title or "Frostveil"
    local logoText = config.LogoText or "RAPID"
    local size     = config.Size or UDim2.fromOffset(620, 450)
    local autoShow = config.AutoShow ~= false
    local center   = config.Center ~= false

    local Window = {
        Tabs = {},
        TabCount = 0,
        CurrentTab = nil,
        Holder = nil,
        Snow = nil,
    }

    -- Main frame
    local Outer = Create("Frame", {
        Name = "Outer",
        BackgroundColor3 = Library.BackgroundColor,
        BorderSizePixel = 0,
        Size = size,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = false,
        Parent = ScreenGui,
        ZIndex = 1,
    })
    Round(Outer, 11)
    Stroke(Outer, Library.OutlineColor, 1.5, 0.25)
    Window.Holder = Outer

    -- Top bar
    local TopBar = Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = Outer,
        ZIndex = 2,
    })
    Round(TopBar, 11)
    Create("Frame", { -- cover bottom corners
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        Parent = TopBar,
        ZIndex = 2,
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextSize = 15,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = TopBar,
    })

    -- Close
    local CloseBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -40, 0.5, -17),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 22,
        TextColor3 = Library.FontColor,
        ZIndex = 3,
        Parent = TopBar,
    })
    CloseBtn.MouseButton1Click:Connect(function()
        Outer.Visible = false
    end)

    -- Sidebar
    local Sidebar = Create("Frame", {
        BackgroundColor3 = Library.SidebarColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 145, 1, -40),
        Position = UDim2.fromOffset(0, 40),
        Parent = Outer,
        ZIndex = 2,
    })
    local SideList = Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Sidebar,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = Sidebar,
    })

    -- Content
    local Content = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -155, 1, -50),
        Position = UDim2.fromOffset(155, 48),
        Parent = Outer,
        ZIndex = 2,
    })

    -- Big logo
    local Logo = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(0.9, 0.5),
        Position = UDim2.fromScale(0.5, 0.55),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Font = Enum.Font.GothamBlack,
        Text = logoText,
        TextScaled = true,
        TextColor3 = Library.LogoColor,
        TextTransparency = 0.4,
        ZIndex = 4,
        Parent = Content,
    })
    local logoStroke = Stroke(Logo, Library.LogoColor, 2, 0.45)

    task.spawn(function()
        while Logo.Parent and not Library.Unloaded do
            for t = 0.32, 0.48, 0.007 do
                Logo.TextTransparency = t
                logoStroke.Transparency = t + 0.1
                task.wait(0.03)
            end
            for t = 0.48, 0.32, -0.007 do
                Logo.TextTransparency = t
                logoStroke.Transparency = t + 0.1
                task.wait(0.03)
            end
        end
    end)

    -- Snow
    Window.Snow = CreateSnow(Outer)

    -- Dragging
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Outer.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Outer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Toggle function for this window
    function Window:Toggle()
        Outer.Visible = not Outer.Visible
    end

    -- Global toggle (RightShift)
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            Window:Toggle()
        end
    end))

    -- ── AddTab ─────────────────────────────────────────────
    function Window:AddTab(name)
        Window.TabCount = Window.TabCount + 1
        local order = Window.TabCount

        local Tab = {
            Name = name,
            Container = nil,
            Button = nil,
            Active = false,
        }

        -- Sidebar button
        local btn = Create("TextButton", {
            BackgroundColor3 = Library.MainColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
            Font = Enum.Font.GothamMedium,
            Text = name,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(150, 170, 200),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = order,
            ZIndex = 3,
            Parent = Sidebar,
        })
        Round(btn, 7)
        Create("UIPadding", {PaddingLeft = UDim.new(0, 14), Parent = btn})

        local indicator = Create("Frame", {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 0.55, 0),
            Position = UDim2.new(0, 0, 0.225, 0),
            Visible = false,
            ZIndex = 4,
            Parent = btn,
        })
        Round(indicator, 2)
        Tab.Button = btn

        -- Content scroll
        local container = Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 3,
            Parent = Content,
        })
        local list = Create("UIListLayout", {
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = container,
        })
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 16),
            Parent = container,
        })
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
        end)
        Tab.Container = container

        local function Activate()
            for _, t in pairs(Window.Tabs) do
                t.Container.Visible = false
                t.Button.BackgroundTransparency = 1
                t.Button.TextColor3 = Color3.fromRGB(150, 170, 200)
                local ind = t.Button:FindFirstChildOfClass("Frame")
                if ind then ind.Visible = false end
                t.Active = false
            end
            container.Visible = true
            btn.BackgroundTransparency = 0.55
            btn.TextColor3 = Library.FontColor
            indicator.Visible = true
            Tab.Active = true
            Window.CurrentTab = Tab
        end

        btn.MouseButton1Click:Connect(Activate)
        btn.MouseEnter:Connect(function()
            if not Tab.Active then
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0.8}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if not Tab.Active then
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
            end
        end)

        if Window.TabCount == 1 then
            task.defer(Activate)
        end

        -- ── Groupbox ───────────────────────────────────────
        function Tab:AddLeftGroupbox(title)  return self:AddGroupbox(title) end
        function Tab:AddRightGroupbox(title) return self:AddGroupbox(title) end

        function Tab:AddGroupbox(title)
            local Groupbox = {}

            local box = Create("Frame", {
                BackgroundColor3 = Library.MainColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 50),
                ZIndex = 4,
                Parent = container,
            })
            Round(box, 9)
            Stroke(box, Library.OutlineColor, 1, 0.5)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 0, 28),
                Position = UDim2.fromOffset(14, 6),
                Font = Enum.Font.GothamBold,
                Text = title,
                TextSize = 13,
                TextColor3 = Library.AccentColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = box,
            })

            local boxList = Create("UIListLayout", {
                Padding = UDim.new(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = box,
            })
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 34),
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 14),
                PaddingRight = UDim.new(0, 14),
                Parent = box,
            })

            local function resize()
                box.Size = UDim2.new(1, 0, 0, boxList.AbsoluteContentSize.Y + 46)
            end
            boxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
            resize()

            -- Toggle
            function Groupbox:AddToggle(idx, info)
                info = info or {}
                local text = info.Text or idx
                local default = info.Default or false
                local callback = info.Callback
                local risky = info.Risky or false

                local holder = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    ZIndex = 5,
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
                    ZIndex = 6,
                    Parent = holder,
                })

                local track = Create("Frame", {
                    BackgroundColor3 = Library.ToggleOffColor,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(40, 22),
                    Position = UDim2.new(1, -40, 0.5, -11),
                    ZIndex = 6,
                    Parent = holder,
                })
                Round(track, 11)

                local knob = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(245, 250, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(18, 18),
                    Position = UDim2.fromOffset(2, 2),
                    ZIndex = 7,
                    Parent = track,
                })
                Round(knob, 9)

                local state = default
                local function set(val)
                    state = val
                    local pos = val and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)
                    local col = val and Library.ToggleOnColor or Library.ToggleOffColor
                    TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Position = pos}):Play()
                    TweenService:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {BackgroundColor3 = col}):Play()
                    if callback then pcall(callback, val) end
                end
                set(default)

                local click = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = "",
                    ZIndex = 8,
                    Parent = holder,
                })
                click.MouseButton1Click:Connect(function() set(not state) end)

                local toggle = {
                    Value = state,
                    Type = "Toggle",
                    SetValue = set,
                    OnChanged = function(_, cb) callback = cb end,
                }
                -- keep Value in sync
                local oldSet = set
                set = function(val)
                    oldSet(val)
                    toggle.Value = val
                end
                toggle.SetValue = set

                Library.Toggles[idx] = toggle
                resize()
                return toggle
            end

            -- Slider
            function Groupbox:AddSlider(idx, info)
                info = info or {}
                local text = info.Text or idx
                local min = info.Min or 0
                local max = info.Max or 100
                local default = info.Default or min
                local rounding = info.Rounding or 0
                local suffix = info.Suffix or ""
                local callback = info.Callback

                local holder = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 48),
                    ZIndex = 5,
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
                    ZIndex = 6,
                    Parent = holder,
                })

                local valLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 65, 0, 18),
                    Position = UDim2.new(1, -65, 0, 0),
                    Font = Enum.Font.Gotham,
                    Text = tostring(default) .. suffix,
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 6,
                    Parent = holder,
                })

                local barBg = Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 8),
                    Position = UDim2.fromOffset(0, 28),
                    ZIndex = 6,
                    Parent = holder,
                })
                Round(barBg, 4)

                local fill = Create("Frame", {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0),
                    ZIndex = 7,
                    Parent = barBg,
                })
                Round(fill, 4)

                local slider = {Value = default, Type = "Slider"}

                local function set(val)
                    val = math.clamp(val, min, max)
                    if rounding == 0 then
                        val = math.floor(val + 0.5)
                    else
                        val = math.floor(val * 10^rounding + 0.5) / 10^rounding
                    end
                    slider.Value = val
                    fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
                    valLabel.Text = tostring(val) .. suffix
                    if callback then pcall(callback, val) end
                end
                slider.SetValue = set
                slider.OnChanged = function(_, cb) callback = cb end

                local draggingSlider = false
                barBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = (Mouse.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X
                        set(min + (max - min) * math.clamp(rel, 0, 1))
                    end
                end)

                set(default)
                Library.Options[idx] = slider
                resize()
                return slider
            end

            -- Button
            function Groupbox:AddButton(info)
                info = type(info) == "table" and info or {Text = tostring(info), Func = function() end}
                local text = info.Text or "Button"
                local func = info.Func or function() end

                local btn = Create("TextButton", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 32),
                    Font = Enum.Font.GothamMedium,
                    Text = text,
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    AutoButtonColor = false,
                    ZIndex = 5,
                    Parent = box,
                })
                Round(btn, 7)
                Stroke(btn, Library.OutlineColor, 1, 0.45)

                btn.MouseButton1Click:Connect(function()
                    pcall(func)
                end)
                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Library.MainColor}):Play()
                end)
                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Library.BackgroundColor}):Play()
                end)

                resize()
                return {Type = "Button"}
            end

            -- Label
            function Groupbox:AddLabel(text)
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = tostring(text),
                    TextSize = 12,
                    TextColor3 = Color3.fromRGB(160, 180, 210),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5,
                    Parent = box,
                })
                resize()
            end

            -- Divider
            function Groupbox:AddDivider()
                local d = Create("Frame", {
                    BackgroundColor3 = Library.OutlineColor,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    ZIndex = 5,
                    Parent = box,
                })
                resize()
            end

            return Groupbox
        end

        Window.Tabs[name] = Tab
        return Tab
    end

    table.insert(Library.Windows, Window)

    -- Show window
    if autoShow then
        task.defer(function()
            Outer.Visible = true
        end)
    end

    return Window
end

-- Global toggle helper
function Library:Toggle()
    for _, win in ipairs(self.Windows) do
        if win.Holder then
            win.Holder.Visible = not win.Holder.Visible
        end
    end
end

print("[Frostveil] v1.1 loaded successfully")
return Library
