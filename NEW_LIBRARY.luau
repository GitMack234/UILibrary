--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                   RockSide UI Library                       ║
    ║                     v1 Stable                               ║
    ║         Modern Executor UI Framework for Roblox             ║
    ╚══════════════════════════════════════════════════════════════╝
    
    Features:
        • Parents to CoreGui (undetectable)
        • Modern dark theme with accent highlights
        • Smooth animations via TweenService
        • Full element suite: Toggle, Slider, Dropdown,
          Button, Input, Keybind, ColorPicker, Label
        • Notification system
        • Target HUD (hover to show player info & health)
        • Draggable window with minimize/hide (RightShift)
        • Player info panel with avatar
        • Category tab system with sections
]]

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════════════════
local Theme = {
    Background   = Color3.fromRGB(15, 15, 22),
    Sidebar      = Color3.fromRGB(19, 19, 28),
    Content      = Color3.fromRGB(21, 21, 31),
    Section      = Color3.fromRGB(27, 27, 39),
    Element      = Color3.fromRGB(32, 32, 46),
    ElementHover = Color3.fromRGB(39, 39, 55),

    Accent       = Color3.fromRGB(90, 103, 244),
    AccentHover  = Color3.fromRGB(111, 123, 255),
    AccentDark   = Color3.fromRGB(66, 79, 219),

    Text         = Color3.fromRGB(234, 234, 244),
    TextDim      = Color3.fromRGB(130, 130, 160),
    TextDark     = Color3.fromRGB(81, 81, 106),

    Border       = Color3.fromRGB(40, 40, 57),
    Divider      = Color3.fromRGB(33, 33, 49),

    ToggleOff    = Color3.fromRGB(52, 52, 70),
    ToggleOn     = Color3.fromRGB(90, 103, 244),
    SliderTrack  = Color3.fromRGB(44, 44, 62),

    Success      = Color3.fromRGB(67, 181, 129),
    Warning      = Color3.fromRGB(250, 166, 26),
    Error        = Color3.fromRGB(237, 66, 69),
}

-- ════════════════════════════════════════════════════════════════
-- CONSTANTS
-- ════════════════════════════════════════════════════════════════
local SIDEBAR_WIDTH  = 180
local WINDOW_W       = 700
local WINDOW_H       = 470
local CORNER_MAIN    = UDim.new(0, 15)
local CORNER_ELEMENT = UDim.new(0, 7)
local ANIM_SPEED     = 0.22

local FONT_BOLD    = Enum.Font.GothamBold
local FONT_SEMI    = Enum.Font.GothamSemibold
local FONT_MEDIUM  = Enum.Font.GothamMedium
local FONT_REGULAR = Enum.Font.Gotham

-- ════════════════════════════════════════════════════════════════
-- ANTI-DETECTION & NAME ENCRYPTION
-- ════════════════════════════════════════════════════════════════

--[[
    Automatic anti-detection system:
    1) RandomName   – generates cryptographic random instance names
                      so games cannot find the UI by searching for
                      known names like "RockSideGui", "Sidebar", etc.
    2) Instance registry – weak table tracking every UI instance
                           created by the library.
    3) ApplyAntiDetection – hooks executor metamethods (__namecall,
                            __index) to hide ALL library instances
                            from game anti-cheat scripts that
                            enumerate CoreGui / PlayerGui.
    Supported executor APIs:
        hookmetamethod, newcclosure, getnamecallmethod,
        checkcaller, gethui
]]

-- Cryptographic random name generator
local _rng = Random.new(tick() * os.clock() * 1e4)
local _nameLetters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local _nameChars   = _nameLetters .. "0123456789"

local function RandomName(minLen, maxLen)
    minLen = minLen or 6
    maxLen = maxLen or 14
    local len = _rng:NextInteger(minLen, maxLen)
    local buf = table.create(len)
    -- First char must be a letter (valid Lua identifier start)
    local idx = _rng:NextInteger(1, #_nameLetters)
    buf[1] = string.sub(_nameLetters, idx, idx)
    for i = 2, len do
        idx = _rng:NextInteger(1, #_nameChars)
        buf[i] = string.sub(_nameChars, idx, idx)
    end
    return table.concat(buf)
end

-- Weak registry of all library-created instances (for hook filtering)
local _guiRegistry = setmetatable({}, { __mode = "k" })

local function RegisterInstance(inst)
    _guiRegistry[inst] = true
end

local function IsOurInstance(inst)
    return _guiRegistry[inst] == true
end

-- Apply anti-detection hooks to hide UI from game anti-cheat scripts
-- Works with common executor APIs; gracefully degrades if unavailable
local _antiDetectionApplied = false

local function ApplyAntiDetection(rootGui)
    if _studioMode or _antiDetectionApplied then return end

    -- Detect executor environment
    local _hook  = type(hookmetamethod) == "function" and hookmetamethod
    local _newcc = type(newcclosure) == "function" and newcclosure or function(f) return f end
    local _getnc = type(getnamecallmethod) == "function" and getnamecallmethod
                   or (type(get_namecall_method) == "function" and get_namecall_method)
    local _check = type(checkcaller) == "function" and checkcaller or function() return false end

    if not (_hook and _getnc) then return end -- executor doesn't support required hooks
    _antiDetectionApplied = true

    -- Register root GUI and all current descendants
    RegisterInstance(rootGui)
    for _, desc in ipairs(rootGui:GetDescendants()) do
        RegisterInstance(desc)
    end
    -- Auto-register any future descendants
    rootGui.DescendantAdded:Connect(function(d) RegisterInstance(d) end)

    -- Filter helper: remove our instances from result tables
    local function Filter(tbl)
        local out = {}
        for i = 1, #tbl do
            if not IsOurInstance(tbl[i]) then
                out[#out + 1] = tbl[i]
            end
        end
        return out
    end

    -- Hook __namecall: intercepts :GetChildren(), :GetDescendants(),
    --   :FindFirstChild(), :FindFirstChildOfClass(), :FindFirstChildWhichIsA(),
    --   :IsAncestorOf(), :IsDescendantOf()
    pcall(function()
        local oldNC
        oldNC = _hook(game, "__namecall", _newcc(function(self, ...)
            local method = _getnc()
            -- Only filter calls from game scripts (not our own code)
            if not _check() then
                -- Hide from child / descendant enumeration
                if method == "GetChildren" or method == "GetDescendants" then
                    local r = oldNC(self, ...)
                    if typeof(r) == "table" then
                        return Filter(r)
                    end
                end
                -- Hide from find methods
                if method == "FindFirstChild" or method == "FindFirstChildOfClass"
                  or method == "FindFirstChildWhichIsA" then
                    local r = oldNC(self, ...)
                    if r and IsOurInstance(r) then return nil end
                end
                -- Deny ancestry relationship checks
                if method == "IsAncestorOf" then
                    local target = ...
                    if target and IsOurInstance(target) then return false end
                end
                if method == "IsDescendantOf" then
                    if IsOurInstance(self) then return false end
                end
            end
            return oldNC(self, ...)
        end))
    end)

    -- Hook __index: spoof .Parent on our instances so game reads nil
    pcall(function()
        local oldIdx
        oldIdx = _hook(game, "__index", _newcc(function(self, key)
            if not _check() and IsOurInstance(self) then
                if key == "Parent" then return nil end
            end
            return oldIdx(self, key)
        end))
    end)
end

-- ════════════════════════════════════════════════════════════════
-- UTILITIES
-- ════════════════════════════════════════════════════════════════
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    -- Auto-encrypt instance names in non-studio (live/executor) mode
    if not _studioMode then
        inst.Name = RandomName()
    end
    -- Register for anti-detection filtering
    RegisterInstance(inst)
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(inst, props, dur, style, dir)
    local tw = TweenService:Create(
        inst,
        TweenInfo.new(dur or ANIM_SPEED, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function Corner(parent, radius)
    return Create("UICorner", { CornerRadius = radius or CORNER_MAIN, Parent = parent })
end

local function Stroke(parent, color, thick, transp)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thick or 1,
        Transparency = transp or 0,
        Parent = parent,
    })
end

local function Padding(parent, t, r, b, l)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingRight  = UDim.new(0, r or t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
        PaddingLeft   = UDim.new(0, l or r or t or 0),
        Parent = parent,
    })
end

local function Gradient(parent, colorSeq, rotation)
    return Create("UIGradient", {
        Color = colorSeq,
        Rotation = rotation or 0,
        Parent = parent,
    })
end

local function GradientStroke(parent, colorSeq, rotation, thick, transp)
    local stroke = Create("UIStroke", {
        Color = Color3.new(1, 1, 1),
        Thickness = thick or 1,
        Transparency = transp or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
    Create("UIGradient", {
        Color = colorSeq,
        Rotation = rotation or -80,
        Parent = stroke,
    })
    return stroke
end

-- Gradient color sequences
local ACCENT_GRADIENT = ColorSequence.new{
    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(90, 103, 244)),
    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(60, 72, 163))
}
local BORDER_GRADIENT = ColorSequence.new{
    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(40, 40, 57)),
    ColorSequenceKeypoint.new(0.500, Color3.fromRGB(127, 127, 182)),
    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(40, 40, 57))
}
local SIDEBAR_GRADIENT = ColorSequence.new{
    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(19, 19, 28)),
    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(34, 33, 51))
}
local DIVIDER_GRADIENT = ColorSequence.new{
    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(40, 40, 57)),
    ColorSequenceKeypoint.new(0.500, Color3.fromRGB(66, 66, 94)),
    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(40, 40, 57))
}
local USERCARD_GRADIENT = ColorSequence.new{
    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(34, 34, 50)),
    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(34, 33, 51))
}

local _studioMode = false

local function ProtectGui(gui)
    if _studioMode then
        -- Studio mode: parent to PlayerGui for testing
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    else
        local ok = false
        -- Attempt 1: gethui() — executor hidden UI container (most undetectable)
        if type(gethui) == "function" then
            ok = pcall(function() gui.Parent = gethui() end)
        end
        -- Attempt 2: CoreGui — standard hidden container
        if not ok then
            ok = pcall(function() gui.Parent = CoreGui end)
        end
        -- Attempt 3: PlayerGui — last resort
        if not ok then
            gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
        -- Activate anti-detection hooks (hides all library instances
        -- from game scripts that enumerate CoreGui / PlayerGui)
        ApplyAntiDetection(gui)
    end
end

-- ════════════════════════════════════════════════════════════════
-- LIBRARY
-- ════════════════════════════════════════════════════════════════
local RockSide = {}

function RockSide:CreateWindow(cfg)
    cfg = cfg or {}
    local hubName    = cfg.Name or "RockSide"
    local version    = cfg.Version or "v1 Stable"
    local toggleKey  = cfg.ToggleKey or Enum.KeyCode.RightShift

    -- Set studio mode from config
    if cfg.StudioMode ~= nil then
        _studioMode = cfg.StudioMode
    end

    local Window     = {}
    Window.Tabs      = {}
    Window.ActiveTab = nil
    Window.Visible   = true

    -- Internal tracking for auto cleanup (no globals)
    local _connections = {}  -- all global signal connections
    local _elements    = {}  -- all created elements with default values and Set functions
    local _binds       = {}  -- all bind entries for keybinds panel
    local _keybindsPanelOpen = false
    local _refreshKeybindsPanel  -- forward declaration
    local _fadeKeybindsPanel     -- forward declaration

    local function TrackConnection(conn)
        table.insert(_connections, conn)
        return conn
    end

    -- ──────────────────────────────────────
    -- ScreenGui
    -- ──────────────────────────────────────
    local ScreenGui = Create("ScreenGui", {
        Name              = "RockSideGui",
        ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
        ScreenInsets      = Enum.ScreenInsets.DeviceSafeInsets,
        ResetOnSpawn      = false,
        DisplayOrder      = 999,
    })
    ProtectGui(ScreenGui)

    -- ──────────────────────────────────────
    -- Main Window Frame (CanvasGroup for GroupTransparency)
    -- ──────────────────────────────────────
    local MainFrame = Create("CanvasGroup", {
        Name              = "W",
        BackgroundColor3  = Theme.Background,
        AnchorPoint       = Vector2.new(0.5, 0.5),
        Position          = UDim2.new(0.5, 0, 0.5, 0),
        Size              = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
        ClipsDescendants  = true,
        GroupTransparency = 0,
        Parent            = ScreenGui,
    })
    Corner(MainFrame)

    -- ──────────────────────────────────────
    -- Drag Logic
    -- ──────────────────────────────────────
    local dragging, dragStart, startPos

    -- Drag handle covers entire top strip
    local DragHandle = Create("Frame", {
        Name                 = "DragHandle",
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 0, 30),
        ZIndex               = 50,
        Parent               = MainFrame,
    })

    DragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))

    -- ╔════════════════════════════════════════════════════════════╗
    -- ║                        SIDEBAR                            ║
    -- ╚════════════════════════════════════════════════════════════╝
    local Sidebar = Create("Frame", {
        Name             = "Sidebar",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size             = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
        BorderSizePixel  = 0,
        Parent           = MainFrame,
    })
    -- Only round left corners – cover right side
    Corner(Sidebar)
    Gradient(Sidebar, SIDEBAR_GRADIENT, 90)
    local SidebarEdge = Create("Frame", {
        Name              = "SidebarEdge",
        BackgroundColor3  = Color3.new(1, 1, 1),
        Position          = UDim2.new(1, -6, 0, 0),
        Size              = UDim2.new(0, 6, 1, 0),
        BorderSizePixel   = 0,
        Parent            = Sidebar,
    })
    Gradient(SidebarEdge, SIDEBAR_GRADIENT, 90)

    -- Right-edge divider line
    Create("Frame", {
        Name              = "SidebarDivider",
        BackgroundColor3  = Theme.Border,
        Position          = UDim2.new(1, 0, 0, 0),
        Size              = UDim2.new(0, 1, 1, 0),
        BorderSizePixel   = 0,
        Parent            = Sidebar,
    })

    -- ── Logo ──────────────────────────────
    local LogoArea = Create("Frame", {
        Name                 = "LogoArea",
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 0, 58),
        Parent               = Sidebar,
    })

    -- Accent diamond icon
    local LogoIcon = Create("TextLabel", {
        Name                 = "Icon",
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 18, 0.5, -10),
        Size                 = UDim2.new(0, 20, 0, 20),
        Font                 = FONT_BOLD,
        Text                 = "◆",
        TextColor3           = Color3.new(1, 1, 1),
        TextSize             = 18,
        Parent               = LogoArea,
    })
    Gradient(LogoIcon, ACCENT_GRADIENT, 90)

    local LogoTitle = Create("TextLabel", {
        Name                 = "Title",
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 42, 0.5, -11),
        Size                 = UDim2.new(1, -52, 0, 22),
        Font                 = FONT_BOLD,
        Text                 = hubName,
        TextColor3           = Color3.new(1, 1, 1),
        TextSize             = 17,
        TextXAlignment       = Enum.TextXAlignment.Left,
        Parent               = LogoArea,
    })
    Gradient(LogoTitle, ACCENT_GRADIENT, 90)

    -- Divider under logo
    local LogoDiv = Create("Frame", {
        Name             = "Div",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position         = UDim2.new(0, 14, 1, -1),
        Size             = UDim2.new(1, -28, 0, 1),
        BorderSizePixel  = 0,
        Parent           = LogoArea,
    })
    Gradient(LogoDiv, DIVIDER_GRADIENT)

    -- ── Tab Buttons Container ─────────────
    local TabScroll = Create("ScrollingFrame", {
        Name                  = "Tabs",
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 0, 0, 62),
        Size                  = UDim2.new(1, 0, 1, -175),
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ScrollBarThickness    = 0,
        ScrollingDirection    = Enum.ScrollingDirection.Y,
        Parent                = Sidebar,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 7),
        Parent    = TabScroll,
    })
    Padding(TabScroll, 6, 10, 6, 10)

    -- ── User Info (bottom of sidebar) ─────
    local UserArea = Create("Frame", {
        Name                 = "UserArea",
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 0, 1, -110),
        Size                 = UDim2.new(1, 0, 0, 110),
        Parent               = Sidebar,
    })

    -- divider
    local UserDiv = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position         = UDim2.new(0, 14, 0.28, 0),
        Size             = UDim2.new(1, -28, 0, 1),
        BorderSizePixel  = 0,
        Parent           = UserArea,
    })
    Gradient(UserDiv, DIVIDER_GRADIENT)

    -- User card background
    local UserCard = Create("Frame", {
        Name             = "UserCard",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position         = UDim2.new(0, 10, 0, 40),
        Size             = UDim2.new(0, 160, 0, 60),
        Parent           = UserArea,
    })
    Corner(UserCard, UDim.new(0, 10))
    Gradient(UserCard, USERCARD_GRADIENT, 90)
    GradientStroke(UserCard, BORDER_GRADIENT, -80, 1, 0.5)

    -- Avatar
    local AvatarHolder = Create("Frame", {
        Name             = "AvatarHolder",
        BackgroundColor3 = Theme.Element,
        Position         = UDim2.new(0, 10, 0.5, -22),
        Size             = UDim2.new(0, 44, 0, 44),
        Parent           = UserCard,
    })
    Corner(AvatarHolder, UDim.new(1, 0))
    local avatarStroke = Stroke(AvatarHolder, Color3.new(1, 1, 1), 2, 0.45)
    Gradient(avatarStroke, ACCENT_GRADIENT, 90)

    local AvatarImg = Create("ImageLabel", {
        Name                 = "Img",
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 1, 0),
        Image                = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
        Parent               = AvatarHolder,
    })
    Corner(AvatarImg, UDim.new(1, 0))

    -- Player name
    Create("TextLabel", {
        Name                 = "Name",
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 62, 0, 13),
        Size                 = UDim2.new(1, -72, 0, 16),
        Font                 = FONT_SEMI,
        Text                 = LocalPlayer.DisplayName,
        TextColor3           = Theme.Text,
        TextSize             = 13,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextTruncate         = Enum.TextTruncate.AtEnd,
        Parent               = UserCard,
    })

    -- Version
    Create("TextLabel", {
        Name                 = "Version",
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 62, 0, 31),
        Size                 = UDim2.new(1, -72, 0, 14),
        Font                 = FONT_REGULAR,
        Text                 = version,
        TextColor3           = Theme.TextDim,
        TextSize             = 11,
        TextXAlignment       = Enum.TextXAlignment.Left,
        Parent               = UserCard,
    })



    -- ╔════════════════════════════════════════════════════════════╗
    -- ║                     CONTENT AREA                          ║
    -- ╚════════════════════════════════════════════════════════════╝
    local ContentArea = Create("Frame", {
        Name             = "Content",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position         = UDim2.new(0, SIDEBAR_WIDTH + 1, 0, 0),
        Size             = UDim2.new(1, -(SIDEBAR_WIDTH + 1), 1, 0),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
        Parent           = MainFrame,
    })
    Corner(ContentArea)
    Gradient(ContentArea, SIDEBAR_GRADIENT, 90)
    local ContentEdge = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size             = UDim2.new(0, 6, 1, 0),
        BorderSizePixel  = 0,
        Parent           = ContentArea,
    })
    Gradient(ContentEdge, SIDEBAR_GRADIENT, 90)

    -- ── Content Header ────────────────────
    local Header = Create("Frame", {
        Name                 = "Header",
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 0, 48),
        Parent               = ContentArea,
    })

    local HeaderTitle = Create("TextLabel", {
        Name                 = "Title",
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 20, 0, -4),
        Size                 = UDim2.new(0, 311, 0, 48),
        Font                 = FONT_SEMI,
        Text                 = "",
        TextColor3           = Theme.Text,
        TextSize             = 15,
        TextXAlignment       = Enum.TextXAlignment.Left,
        Parent               = Header,
    })

    -- Subtitle showing section context
    local HeaderSub = Create("TextLabel", {
        Name                 = "Sub",
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 20, 0, 28),
        Size                 = UDim2.new(0.5, 0, 0, 14),
        Font                 = FONT_REGULAR,
        Text                 = "",
        TextColor3           = Theme.TextDim,
        TextSize             = 10,
        TextXAlignment       = Enum.TextXAlignment.Left,
        Parent               = Header,
    })

    -- Minimize button
    local MinBtn = Create("ImageButton", {
        Name                 = "Min",
        BackgroundColor3     = Theme.Element,
        BackgroundTransparency = 1,
        Position             = UDim2.new(1, -62, 0, 15),
        Size                 = UDim2.new(0, 18, 0, 18),
        Image                = "rbxassetid://11293980042",
        ScaleType            = Enum.ScaleType.Fit,
        AutoButtonColor      = false,
        Parent               = Header,
    })
    Corner(MinBtn, UDim.new(0, 6))

    MinBtn.MouseEnter:Connect(function() Tween(MinBtn, {ImageColor3 = Theme.Warning}, 0.12) end)
    MinBtn.MouseLeave:Connect(function() Tween(MinBtn, {ImageColor3 = Color3.new(1, 1, 1)}, 0.12) end)

    -- Close / Hide button
    local CloseBtn = Create("ImageButton", {
        Name                 = "Close",
        BackgroundColor3     = Theme.Element,
        BackgroundTransparency = 1,
        Position             = UDim2.new(1, -36, 0, 15),
        Size                 = UDim2.new(0, 18, 0, 18),
        Image                = "rbxassetid://11293981586",
        ScaleType            = Enum.ScaleType.Fit,
        AutoButtonColor      = false,
        Parent               = Header,
    })
    Corner(CloseBtn, UDim.new(0, 6))

    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {ImageColor3 = Theme.Error}, 0.12) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {ImageColor3 = Color3.new(1, 1, 1)}, 0.12) end)

    -- Header divider
    local HeaderDiv = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position         = UDim2.new(0, 15, 1, -1),
        Size             = UDim2.new(1, -30, 0, 1),
        BorderSizePixel  = 0,
        Parent           = Header,
    })
    Gradient(HeaderDiv, DIVIDER_GRADIENT)

    -- ── Tab Pages Container ───────────────
    local PagesHolder = Create("Frame", {
        Name                 = "Pages",
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 0, 0, 48),
        Size                 = UDim2.new(1, 0, 1, -48),
        ClipsDescendants     = true,
        Parent               = ContentArea,
    })

    -- Forward-declare so ToggleWindow / Minimize / Restore can reference it
    local FadeNotifs
    local FadeTargetHud

    -- Minimize
    local minimized = false

    -- ──────────────────────────────────────
    -- Window Toggle (Hide / Show)
    -- ──────────────────────────────────────
    local function ToggleWindow()
        -- If minimized, restore first then proceed
        if minimized then
            return
        end

        Window.Visible = not Window.Visible
        if Window.Visible then
            ScreenGui.Enabled = true
            MainFrame.Visible = true
            MainFrame.GroupTransparency = 1
            MainScale.Scale = 1
            Tween(MainFrame, {GroupTransparency = 0}, 0.15, Enum.EasingStyle.Sine)
            -- Restore notifications
            FadeNotifs(0, 0.15, Enum.EasingStyle.Sine)
            -- Restore keybinds panel
            if _keybindsPanelOpen and _fadeKeybindsPanel then _fadeKeybindsPanel(0, 0.15) end
            -- Restore target HUD
            if FadeTargetHud then FadeTargetHud(0, 0.15) end
        else
            -- Auto clean up all elements on close
            for _, entry in ipairs(_elements) do
                local el = entry.element
                if el and el.Set then
                    pcall(el.Set, el, entry.default)
                end
            end

            local tw = Tween(MainFrame, {GroupTransparency = 1}, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            -- Fade & scale down notifications
            FadeNotifs(1, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            -- Hide keybinds panel
            if _keybindsPanelOpen and _fadeKeybindsPanel then _fadeKeybindsPanel(1, 0.12) end
            -- Hide target HUD
            if FadeTargetHud then FadeTargetHud(1, 0.12) end
            tw.Completed:Connect(function()
                if not Window.Visible then
                    ScreenGui.Enabled = false
                end
            end)
        end
    end

    CloseBtn.MouseButton1Click:Connect(ToggleWindow)

    TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            ToggleWindow()
        end
    end))

    -- Mini icon wrapper (CanvasGroup for proper GroupTransparency with gradients)
    local MiniWrap = Create("CanvasGroup", {
        Name                 = "MiniWrap",
        BackgroundTransparency = 1,
        AnchorPoint          = Vector2.new(0.5, 0.5),
        Position             = UDim2.new(0.5, 0, 0.5, 0),
        Size                 = UDim2.new(0, 48, 0, 48),
        GroupTransparency    = 0,
        Visible              = false,
        ZIndex               = 100,
        Parent               = ScreenGui,
    })

    local MiniScale = Create("UIScale", {
        Scale  = 1,
        Parent = MiniWrap,
    })

    local MiniIcon = Create("TextButton", {
        Name                 = "MiniIcon",
        BackgroundColor3     = Color3.new(1, 1, 1),
        Size                 = UDim2.new(1, 0, 1, 0),
        Text                 = "",
        AutoButtonColor      = false,
        ZIndex               = 100,
        Parent               = MiniWrap,
    })
    Corner(MiniIcon, UDim.new(0, 10))
    Gradient(MiniIcon, SIDEBAR_GRADIENT, 90)
    local MiniStroke = Stroke(MiniIcon, Theme.Border, 1.5)

    local miniFirstLetter = string.sub(hubName, 1, 1)
    local MiniLabel = Create("TextLabel", {
        Name                 = miniFirstLetter,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 1, 0),
        Font                 = FONT_BOLD,
        Text                 = miniFirstLetter,
        TextColor3           = Color3.new(1, 1, 1),
        TextSize             = 24,
        ZIndex               = 101,
        Parent               = MiniIcon,
    })
    Gradient(MiniLabel, ACCENT_GRADIENT, 90)

    -- Drag logic for mini icon (distinguishes drag from click)
    local miniDragging, miniDragStart, miniStartPos
    local MINI_DRAG_THRESHOLD = 5
    local miniDidDrag = false
    MiniIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            miniDragging  = true
            miniDidDrag   = false
            miniDragStart = input.Position
            miniStartPos  = MiniWrap.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    miniDragging = false
                end
            end)
        end
    end)
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if miniDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - miniDragStart
            if d.Magnitude > MINI_DRAG_THRESHOLD then
                miniDidDrag = true
            end
            MiniWrap.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + d.X, miniStartPos.Y.Scale, miniStartPos.Y.Offset + d.Y)
        end
    end))

    -- UIScale for smooth minimize/restore scaling (keeps layout intact)
    local MainScale = Create("UIScale", {
        Scale  = 1,
        Parent = MainFrame,
    })

    -- Anchor to center so UIScale scales from the middle
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

    -- Store the last MainFrame position so we can restore it
    local savedPosition = MainFrame.Position

    local function MinimizeWindow()
        minimized = true
        savedPosition = MainFrame.Position

        -- Place mini icon at the center of the window
        local absCX = MainFrame.AbsolutePosition.X + MainFrame.AbsoluteSize.X / 2
        local absCY = MainFrame.AbsolutePosition.Y + MainFrame.AbsoluteSize.Y / 2

        -- Position the wrapper at center of window
        MiniWrap.Position = UDim2.new(0, absCX, 0, absCY)

        -- Scale down via UIScale + fade all elements via GroupTransparency
        local tw = Tween(MainScale, {Scale = 0}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        Tween(MainFrame, {GroupTransparency = 1}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

        -- Fade & scale down notifications
        FadeNotifs(1, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        -- Fade target HUD
        if FadeTargetHud then FadeTargetHud(1, 0.2) end

        tw.Completed:Connect(function()
            if minimized then
                MainFrame.Visible = false
                -- Pop-in the mini icon via UIScale + GroupTransparency
                MiniWrap.Visible = true
                MiniScale.Scale = 0
                MiniWrap.GroupTransparency = 1
                Tween(MiniScale, {Scale = 1}, 0.15, Enum.EasingStyle.Quart)
                Tween(MiniWrap, {GroupTransparency = 0}, 0.15, Enum.EasingStyle.Quart)
            end
        end)
    end

    local function RestoreWindow()
        minimized = false

        -- Shrink mini icon out via UIScale + GroupTransparency
        local tw = Tween(MiniScale, {Scale = 0}, 0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        Tween(MiniWrap, {GroupTransparency = 1}, 0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        tw.Completed:Connect(function()
            MiniWrap.Visible = false

            -- Prepare: scale 0, fully transparent, then animate back
            MainScale.Scale = 0
            MainFrame.GroupTransparency = 1
            MainFrame.Position = savedPosition
            MainFrame.Visible = true

            -- Scale up via UIScale + fade in all elements
            Tween(MainScale, {Scale = 1}, 0.2, Enum.EasingStyle.Quart)
            Tween(MainFrame, {GroupTransparency = 0}, 0.2, Enum.EasingStyle.Quart)

            -- Restore notifications
            FadeNotifs(0, 0.2, Enum.EasingStyle.Quart)
            -- Restore target HUD
            if FadeTargetHud then FadeTargetHud(0, 0.2) end
        end)
    end

    MinBtn.MouseButton1Click:Connect(function()
        if not minimized then
            MinimizeWindow()
        end
    end)

    MiniIcon.MouseButton1Click:Connect(function()
        if minimized and not miniDidDrag then
            RestoreWindow()
        end
    end)

    -- ╔════════════════════════════════════════════════════════════╗
    -- ║                     TAB CREATION                          ║
    -- ╚════════════════════════════════════════════════════════════╝
    function Window:CreateTab(tabCfg)
        tabCfg = tabCfg or {}
        local tabName = tabCfg.Name or "Tab"
        local tabIcon = tabCfg.Icon or "rbxassetid://11433532654"

        local Tab = {}
        Tab.Name     = tabName
        Tab.Sections = {}

        -- ── Sidebar Button ────────────────
        local Btn = Create("TextButton", {
            Name             = "Tab_" .. tabName,
            BackgroundColor3 = Theme.Sidebar,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, 0, 0, 34),
            Text             = "",
            AutoButtonColor  = false,
            Parent           = TabScroll,
        })
        Corner(Btn, UDim.new(0, 7))

        -- Tab border stroke (only visible when active)
        local TabStroke = Create("UIStroke", {
            Transparency    = 1,
            Color           = Color3.new(1, 1, 1),
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent          = Btn,
        })
        Gradient(TabStroke, BORDER_GRADIENT, -80)

        local IconLbl = Create("ImageLabel", {
            Name                 = "Icon",
            BackgroundTransparency = 1,
            Position             = UDim2.new(0, 12, 0, 0),
            Size                 = UDim2.new(0, 20, 1, 0),
            Image                = tabIcon,
            ImageColor3          = Theme.TextDim,
            ScaleType            = Enum.ScaleType.Fit,
            Parent               = Btn,
        })

        local NameLbl = Create("TextLabel", {
            Name                 = "Label",
            BackgroundTransparency = 1,
            Position             = UDim2.new(0, 38, 0, 0),
            Size                 = UDim2.new(1, -44, 1, 0),
            Font                 = FONT_MEDIUM,
            Text                 = tabName,
            TextColor3           = Theme.TextDim,
            TextSize             = 13,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = Btn,
        })

        -- ── Page (content scroll) ─────────
        local Page = Create("ScrollingFrame", {
            Name                  = "P_" .. tabName,
            BackgroundTransparency = 1,
            Size                  = UDim2.new(1, 0, 1, 0),
            CanvasSize            = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize   = Enum.AutomaticSize.Y,
            ScrollBarThickness    = 3,
            ScrollBarImageColor3  = Theme.Accent,
            ScrollBarImageTransparency = 0.6,
            ScrollingDirection    = Enum.ScrollingDirection.Y,
            Visible               = false,
            Parent                = PagesHolder,
        })
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 10),
            Parent    = Page,
        })
        Padding(Page, 10, 15, 15, 15)

        -- ── Tab Selection ─────────────────
        local function Select()
            for _, t in ipairs(Window.Tabs) do
                t._btn.BackgroundTransparency = 1
                t._name.TextColor3     = Theme.TextDim
                t._icon.ImageColor3    = Theme.TextDim
                Tween(t._stroke, {Transparency = 1}, 0.18)
                t._page.Visible = false
            end
            Btn.BackgroundTransparency = 0
            Tween(Btn, {BackgroundColor3 = Theme.Section}, 0.15)
            NameLbl.TextColor3 = Theme.Text
            IconLbl.ImageColor3 = Theme.Text
            Tween(TabStroke, {Transparency = 0.5}, 0.18)
            Page.Visible = true
            HeaderTitle.Text = tabName
            HeaderSub.Text   = "Module configuration"
            Window.ActiveTab = Tab
        end

        Btn.MouseButton1Click:Connect(Select)
        Btn.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(NameLbl, {TextColor3 = Theme.Text}, 0.12)
                Tween(IconLbl, {ImageColor3 = Theme.Text}, 0.12)
            end
        end)
        Btn.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(NameLbl, {TextColor3 = Theme.TextDim}, 0.12)
                Tween(IconLbl, {ImageColor3 = Theme.TextDim}, 0.12)
            end
        end)

        Tab._btn      = Btn
        Tab._name     = NameLbl
        Tab._icon     = IconLbl
        Tab._stroke   = TabStroke
        Tab._page     = Page

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then Select() end

        -- ╔════════════════════════════════════════════════════════╗
        -- ║                   SECTION CREATION                    ║
        -- ╚════════════════════════════════════════════════════════╝
        function Tab:CreateSection(secName, secDesc)
            secName = secName or "Section"
            local Section = {}

            local hasDesc = secDesc ~= nil and secDesc ~= ""
            local headerH = hasDesc and 44 or 28

            local SecFrame = Create("Frame", {
                Name             = "S_" .. secName,
                BackgroundColor3 = Theme.Section,
                AutomaticSize    = Enum.AutomaticSize.Y,
                Size             = UDim2.new(1, 0, 0, 0),
                Parent           = Page,
            })
            Corner(SecFrame, UDim.new(0, 8))
            GradientStroke(SecFrame, BORDER_GRADIENT, -80, 1, 0.5)

            -- Section title row
            local SecHeader = Create("Frame", {
                Name                 = "Hdr",
                BackgroundTransparency = 1,
                Size                 = UDim2.new(1, 0, 0, headerH),
                Parent               = SecFrame,
            })

            Create("TextLabel", {
                Name                 = "Title",
                BackgroundTransparency = 1,
                Position             = UDim2.new(0, 12, 0, 8),
                Size                 = UDim2.new(1, -24, 0, 14),
                Font                 = FONT_SEMI,
                Text                 = string.upper(secName),
                TextColor3           = Theme.TextDim,
                TextSize             = 10,
                TextXAlignment       = Enum.TextXAlignment.Left,
                Parent               = SecHeader,
            })

            -- Optional subtitle / description inside the header
            if hasDesc then
                Create("TextLabel", {
                    Name                 = "Desc",
                    BackgroundTransparency = 1,
                    Position             = UDim2.new(0, 12, 0, 24),
                    Size                 = UDim2.new(1, -24, 0, 14),
                    Font                 = FONT_REGULAR,
                    Text                 = secDesc,
                    TextColor3           = Theme.TextDark,
                    TextSize             = 11,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    Parent               = SecHeader,
                })
            end

            -- Elements container
            local Elems = Create("Frame", {
                Name                 = "Elems",
                BackgroundTransparency = 1,
                Position             = UDim2.new(0, 0, 0, headerH),
                AutomaticSize        = Enum.AutomaticSize.Y,
                Size                 = UDim2.new(1, 0, 0, 0),
                Parent               = SecFrame,
            })
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 4),
                Parent    = Elems,
            })
            Padding(Elems, 0, 8, 8, 8)

            -- ══════════════════════════════
            -- TOGGLE
            -- ══════════════════════════════
            function Section:CreateToggle(c)
                c = c or {}
                local name     = c.Name or "Toggle"
                local default  = c.Default or false
                local callback = c.Callback or function() end
                local toggled  = default

                local Frame = Create("Frame", {
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = 0.3,
                    Size             = UDim2.new(1, 0, 0, 36),
                    Parent           = Elems,
                })
                Corner(Frame, CORNER_ELEMENT)

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size     = UDim2.new(1, -60, 1, 0),
                    Font     = FONT_MEDIUM,
                    Text     = name,
                    TextColor3     = Theme.Text,
                    TextSize       = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent   = Frame,
                })

                local SwitchBg = Create("Frame", {
                    BackgroundColor3 = toggled and Color3.new(1, 1, 1) or Theme.ToggleOff,
                    Position = UDim2.new(1, -52, 0.5, -10),
                    Size     = UDim2.new(0, 40, 0, 20),
                    Parent   = Frame,
                })
                Corner(SwitchBg, UDim.new(1, 0))
                local SwitchGrad = Gradient(SwitchBg, toggled and ACCENT_GRADIENT or ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)), 90)

                local Circle = Create("Frame", {
                    BackgroundColor3 = Theme.Text,
                    Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    Size     = UDim2.new(0, 16, 0, 16),
                    Parent   = SwitchBg,
                })
                Corner(Circle, UDim.new(1, 0))

                local HitBtn = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = Frame,
                })

                local function Set(v)
                    toggled = v
                    if v then
                        SwitchBg.BackgroundColor3 = Color3.new(1, 1, 1)
                        SwitchGrad.Color = ACCENT_GRADIENT
                    else
                        SwitchBg.BackgroundColor3 = Theme.ToggleOff
                        SwitchGrad.Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1))
                    end
                    Tween(Circle, {Position = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.32, Enum.EasingStyle.Quart)
                    callback(v)
                end

                HitBtn.MouseButton1Click:Connect(function() Set(not toggled) end)

                if default then task.defer(callback, true) end

                local elem = { Set = function(_, v) Set(v) end, Get = function() return toggled end }
                table.insert(_elements, { type = "toggle", default = default, element = elem })
                return elem
            end

            -- ══════════════════════════════
            -- SLIDER
            -- ══════════════════════════════
            function Section:CreateSlider(c)
                c = c or {}
                local name      = c.Name or "Slider"
                local min       = c.Min or 0
                local max       = c.Max or 100
                local default   = c.Default or min
                local increment = c.Increment or 1
                local suffix    = c.Suffix or ""
                local callback  = c.Callback or function() end
                local value     = math.clamp(default, min, max)

                local Frame = Create("Frame", {
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = 0.3,
                    Size             = UDim2.new(1, 0, 0, 50),
                    Parent           = Elems,
                })
                Corner(Frame, CORNER_ELEMENT)

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 2),
                    Size     = UDim2.new(0.5, -12, 0, 20),
                    Font     = FONT_MEDIUM,
                    Text     = name,
                    TextColor3     = Theme.Text,
                    TextSize       = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent   = Frame,
                })

                local ValLbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0, 2),
                    Size     = UDim2.new(0.5, -12, 0, 20),
                    Font     = FONT_MEDIUM,
                    Text     = tostring(value) .. suffix,
                    TextColor3     = Color3.new(1, 1, 1),
                    TextSize       = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent   = Frame,
                })
                Gradient(ValLbl, ACCENT_GRADIENT, 90)

                local Track = Create("Frame", {
                    BackgroundColor3 = Theme.SliderTrack,
                    Position = UDim2.new(0, 12, 0, 30),
                    Size     = UDim2.new(1, -24, 0, 6),
                    Parent   = Frame,
                })
                Corner(Track, UDim.new(1, 0))

                local pct = (value - min) / (max - min)

                local Fill = Create("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Size = UDim2.new(pct, 0, 1, 0),
                    Parent = Track,
                })
                Corner(Fill, UDim.new(1, 0))
                Gradient(Fill, ACCENT_GRADIENT, 90)

                local Knob = Create("Frame", {
                    BackgroundColor3 = Theme.Text,
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = UDim2.new(pct, 0, 0.5, 0),
                    Size             = UDim2.new(0, 14, 0, 14),
                    ZIndex           = 2,
                    Parent           = Track,
                })
                Corner(Knob, UDim.new(1, 0))

                local HitArea = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 22),
                    Size     = UDim2.new(1, -24, 0, 22),
                    Text     = "",
                    Parent   = Frame,
                })

                local sliding = false

                local function Update(input)
                    local rel = math.clamp((input.Position.X - HitArea.AbsolutePosition.X) / HitArea.AbsoluteSize.X, 0, 1)
                    value = math.clamp(math.floor((min + (max - min) * rel) / increment + 0.5) * increment, min, max)
                    local p = (value - min) / (max - min)
                    Tween(Fill, {Size = UDim2.new(p, 0, 1, 0)}, 0.06)
                    Tween(Knob, {Position = UDim2.new(p, 0, 0.5, 0)}, 0.06)
                    ValLbl.Text = tostring(value) .. suffix
                    callback(value)
                end

                HitArea.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        sliding = true; Update(i)
                    end
                end)
                HitArea.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)
                TrackConnection(UserInputService.InputChanged:Connect(function(i)
                    if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        Update(i)
                    end
                end))

                local elem = {
                    Set = function(_, v)
                        value = math.clamp(math.floor(v / increment + 0.5) * increment, min, max)
                        local p = (value - min) / (max - min)
                        Fill.Size    = UDim2.new(p, 0, 1, 0)
                        Knob.Position = UDim2.new(p, 0, 0.5, 0)
                        ValLbl.Text  = tostring(value) .. suffix
                        callback(value)
                    end,
                    Get = function() return value end
                }
                table.insert(_elements, { type = "slider", default = default, element = elem })
                return elem
            end

            -- ══════════════════════════════
            -- DROPDOWN
            -- ══════════════════════════════
            function Section:CreateDropdown(c)
                c = c or {}
                local name        = c.Name or "Dropdown"
                local options     = c.Options or {}
                local default     = c.Default or (options[1] or "")
                local multiSelect = c.MultiSelect or false
                local callback    = c.Callback or function() end

                local selected = multiSelect and {} or default
                local opened   = false

                if multiSelect and type(c.Default) == "table" then
                    for _, v in ipairs(c.Default) do selected[v] = true end
                end

                -- Transparent wrapper that expands to push layout
                local Frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size             = UDim2.new(1, 0, 0, 36),
                    ClipsDescendants = true,
                    Parent           = Elems,
                })

                -- Visible header bar (always 36px)
                local HeaderBar = Create("Frame", {
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = 0.3,
                    Size             = UDim2.new(1, 0, 0, 36),
                    ZIndex           = 5,
                    Parent           = Frame,
                })
                Corner(HeaderBar, CORNER_ELEMENT)

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size     = UDim2.new(0.45, 0, 0, 36),
                    Font     = FONT_MEDIUM,
                    Text     = name,
                    TextColor3     = Theme.Text,
                    TextSize       = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex   = 5,
                    Parent   = HeaderBar,
                })

                local function DisplayText()
                    if multiSelect then
                        local t = {}
                        for k, v in pairs(selected) do if v then table.insert(t, k) end end
                        return #t > 0 and table.concat(t, ", ") or "None"
                    end
                    return tostring(selected)
                end

                local SelLbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.45, 0, 0, 0),
                    Size     = UDim2.new(0.55, -38, 0, 36),
                    Font     = FONT_REGULAR,
                    Text     = DisplayText(),
                    TextColor3     = Theme.TextDim,
                    TextSize       = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextTruncate   = Enum.TextTruncate.AtEnd,
                    ZIndex   = 5,
                    Parent   = HeaderBar,
                })

                local Arrow = Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint  = Vector2.new(0.5, 0.5),
                    Position     = UDim2.new(1, -24, 0.5, 0),
                    Size         = UDim2.new(0, 16, 0, 16),
                    Image        = "rbxassetid://11421095840",
                    ImageColor3  = Theme.TextDim,
                    ScaleType    = Enum.ScaleType.Fit,
                    Rotation     = 180,
                    ZIndex       = 5,
                    Parent       = HeaderBar,
                })

                -- Dropdown list panel
                local List = Create("Frame", {
                    BackgroundColor3 = Theme.Section,
                    Position         = UDim2.new(0, 4, 0, 44),
                    Size             = UDim2.new(1, -8, 0, 0),
                    ClipsDescendants = true,
                    Visible          = false,
                    ZIndex           = 10,
                    Parent           = Frame,
                })
                Corner(List, UDim.new(0, 6))
                GradientStroke(List, BORDER_GRADIENT, -80, 1, 0.5)

                Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding   = UDim.new(0, 3),
                    Parent    = List,
                })
                Padding(List, 4, 4, 4, 4)

                local function Build()
                    for _, ch in ipairs(List:GetChildren()) do
                        if ch:IsA("TextButton") then ch:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local isSel = (multiSelect and selected[opt]) or (not multiSelect and selected == opt)
                        local OBtn = Create("TextButton", {
                            BackgroundColor3      = Color3.new(1, 1, 1),
                            BackgroundTransparency = isSel and 0.15 or 0.5,
                            Size     = UDim2.new(1, 0, 0, 26),
                            Text     = "",
                            AutoButtonColor = false,
                            ZIndex   = 11,
                            Parent   = List,
                        })
                        Corner(OBtn, UDim.new(0, 5))
                        local OBtnGrad = Gradient(OBtn, isSel and ACCENT_GRADIENT or ColorSequence.new(Theme.Element, Theme.Element), 90)

                        Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size     = UDim2.new(1, 0, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            Font     = FONT_MEDIUM,
                            Text     = opt,
                            TextColor3     = Theme.Text,
                            TextSize       = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex   = 12,
                            Parent   = OBtn,
                        })

                        OBtn.MouseEnter:Connect(function() Tween(OBtn, {BackgroundTransparency = 0.05}, 0.08) end)
                        OBtn.MouseLeave:Connect(function()
                            local s = (multiSelect and selected[opt]) or (not multiSelect and selected == opt)
                            Tween(OBtn, {BackgroundTransparency = s and 0.15 or 0.5}, 0.08)
                        end)

                        OBtn.MouseButton1Click:Connect(function()
                            if multiSelect then
                                selected[opt] = not selected[opt]
                                OBtnGrad.Color = selected[opt] and ACCENT_GRADIENT or ColorSequence.new(Theme.Element, Theme.Element)
                                OBtn.BackgroundTransparency = selected[opt] and 0.15 or 0.5
                                SelLbl.Text = DisplayText()
                                local r = {}; for k, v in pairs(selected) do if v then table.insert(r, k) end end
                                callback(r)
                            else
                                selected = opt; SelLbl.Text = opt; callback(opt)
                                Build()
                            end
                        end)
                    end
                end
                Build()

                -- Click target only covers the header area
                local Toggle = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size     = UDim2.new(1, 0, 0, 36),
                    Text     = "",
                    ZIndex   = 6,
                    Parent   = Frame,
                })

                Toggle.MouseButton1Click:Connect(function()
                    opened = not opened
                    if opened then
                        List.Visible = true
                        local listH = math.min(#options * 29 + 10, 185)
                        Tween(Frame, {Size = UDim2.new(1, 0, 0, 44 + listH + 6)}, 0.2, Enum.EasingStyle.Quart)
                        Tween(List, {Size = UDim2.new(1, -8, 0, listH)}, 0.2, Enum.EasingStyle.Quart)
                        Tween(Arrow, {Rotation = 0}, 0.2)
                        -- Auto-scroll page to show dropdown
                        local expandH = 44 + listH + 6
                        local frameTop = Frame.AbsolutePosition.Y
                        local pageTop = Page.AbsolutePosition.Y
                        local pageH = Page.AbsoluteSize.Y
                        local frameBottom = (frameTop - pageTop + Page.CanvasPosition.Y) + expandH
                        local visibleBottom = Page.CanvasPosition.Y + pageH
                        if frameBottom > visibleBottom then
                            local scrollOffset = frameBottom - visibleBottom + 10
                            Tween(Page, {CanvasPosition = Vector2.new(0, Page.CanvasPosition.Y + scrollOffset)}, 0.2, Enum.EasingStyle.Quart)
                        end
                    else
                        Tween(Frame, {Size = UDim2.new(1, 0, 0, 36)}, 0.18)
                        Tween(List, {Size = UDim2.new(1, -8, 0, 0)}, 0.18)
                        Tween(Arrow, {Rotation = 180}, 0.18)
                        task.delay(0.18, function() List.Visible = false end)
                    end
                end)

                local elem = {
                    Set = function(_, v) selected = v; SelLbl.Text = DisplayText(); Build(); callback(v) end,
                    Refresh = function(_, newOpts) options = newOpts; Build() end,
                    Get = function() return selected end,
                }
                table.insert(_elements, { type = "dropdown", default = default, element = elem })
                return elem
            end

            -- ══════════════════════════════
            -- BUTTON
            -- ══════════════════════════════
            function Section:CreateButton(c)
                c = c or {}
                local name     = c.Name or "Button"
                local callback = c.Callback or function() end

                local Btn = Create("TextButton", {
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = 0.3,
                    Size             = UDim2.new(1, 0, 0, 36),
                    Text             = "",
                    AutoButtonColor  = false,
                    Parent           = Elems,
                })
                Corner(Btn, CORNER_ELEMENT)

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size     = UDim2.new(1, -36, 1, 0),
                    Font     = FONT_MEDIUM,
                    Text     = name,
                    TextColor3     = Theme.Text,
                    TextSize       = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent   = Btn,
                })

                Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -28, 0.5, -7),
                    Size     = UDim2.new(0, 14, 0, 14),
                    Image    = "rbxassetid://11422142913",
                    ImageColor3 = Theme.TextDim,
                    ScaleType = Enum.ScaleType.Fit,
                    Parent   = Btn,
                })

                Btn.MouseButton1Click:Connect(function()
                    Tween(Btn, {BackgroundTransparency = 0}, 0.08)
                    task.delay(0.12, function() Tween(Btn, {BackgroundTransparency = 0.3}, 0.15) end)
                    callback()
                end)
            end

            -- ══════════════════════════════
            -- INPUT / TEXTBOX
            -- ══════════════════════════════
            function Section:CreateInput(c)
                c = c or {}
                local name        = c.Name or "Input"
                local placeholder = c.Placeholder or "Type here..."
                local default     = c.Default or ""
                local callback    = c.Callback or function() end

                local Frame = Create("Frame", {
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = 0.3,
                    Size             = UDim2.new(1, 0, 0, 36),
                    Parent           = Elems,
                })
                Corner(Frame, CORNER_ELEMENT)

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size     = UDim2.new(0.38, 0, 1, 0),
                    Font     = FONT_MEDIUM,
                    Text     = name,
                    TextColor3     = Theme.Text,
                    TextSize       = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent   = Frame,
                })

                local Box = Create("TextBox", {
                    BackgroundColor3   = Theme.Section,
                    Position           = UDim2.new(0.38, 4, 0, 5),
                    Size               = UDim2.new(0.62, -16, 1, -10),
                    Font               = FONT_REGULAR,
                    Text               = default,
                    PlaceholderText    = placeholder,
                    PlaceholderColor3  = Theme.TextDark,
                    TextColor3         = Theme.Text,
                    TextSize           = 12,
                    ClearTextOnFocus   = false,
                    Parent             = Frame,
                })
                Corner(Box, UDim.new(0, 5))
                Padding(Box, 0, 8, 0, 8)

                Box.Focused:Connect(function() end)
                Box.FocusLost:Connect(function(enter)
                    if enter then callback(Box.Text) end
                end)

                return {
                    Set = function(_, t) Box.Text = t; callback(t) end,
                    Get = function() return Box.Text end,
                }
            end

            -- ══════════════════════════════
            -- KEYBIND
            -- ══════════════════════════════
            function Section:CreateKeybind(c)
                c = c or {}
                local name     = c.Name or "Keybind"
                local default  = c.Default or Enum.KeyCode.Unknown
                local callback = c.Callback or function() end
                local current  = default
                local listening = false

                local Frame = Create("Frame", {
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = 0.3,
                    Size             = UDim2.new(1, 0, 0, 36),
                    Parent           = Elems,
                })
                Corner(Frame, CORNER_ELEMENT)

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size     = UDim2.new(0.55, 0, 1, 0),
                    Font     = FONT_MEDIUM,
                    Text     = name,
                    TextColor3     = Theme.Text,
                    TextSize       = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent   = Frame,
                })

                local KeyBtn = Create("TextButton", {
                    BackgroundColor3 = Theme.Section,
                    Position = UDim2.new(1, -90, 0.5, -12),
                    Size     = UDim2.new(0, 76, 0, 24),
                    Font     = FONT_MEDIUM,
                    Text     = current == Enum.KeyCode.Unknown and "None" or current.Name,
                    TextColor3     = Theme.TextDim,
                    TextSize       = 11,
                    AutoButtonColor = false,
                    Parent   = Frame,
                })
                Corner(KeyBtn, UDim.new(0, 5))
                local kStroke = Stroke(KeyBtn, Theme.Border, 1, 0.4)

                KeyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KeyBtn.Text = "..."
                    Tween(kStroke, {Color = Theme.Accent}, 0.12)
                end)

                TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            listening = false
                            if input.KeyCode == Enum.KeyCode.Escape then
                                current = Enum.KeyCode.Unknown
                                KeyBtn.Text = "None"
                            else
                                current = input.KeyCode
                                KeyBtn.Text = input.KeyCode.Name
                            end
                            Tween(kStroke, {Color = Theme.Border}, 0.12)
                            callback(current)
                        end
                    elseif not gpe and current ~= Enum.KeyCode.Unknown and input.KeyCode == current then
                        callback(current)
                    end
                end))

                local elem = {
                    Set = function(_, k) current = k; KeyBtn.Text = k == Enum.KeyCode.Unknown and "None" or k.Name end,
                    Get = function() return current end,
                }
                table.insert(_elements, { type = "keybind", default = default, element = elem })
                return elem
            end

            -- ══════════════════════════════
            -- COLOR PICKER
            -- ══════════════════════════════
            function Section:CreateColorPicker(c)
                c = c or {}
                local name     = c.Name or "Color"
                local default  = c.Default or Color3.fromRGB(255, 255, 255)
                local callback = c.Callback or function() end
                local color    = default
                local pickerOpen = false

                local h, s, v = color:ToHSV()

                -- Transparent wrapper that expands to push layout
                local Frame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size             = UDim2.new(1, 0, 0, 36),
                    ClipsDescendants = true,
                    Parent           = Elems,
                })

                -- Visible header bar (always 36px)
                local HeaderBar = Create("Frame", {
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = 0.3,
                    Size             = UDim2.new(1, 0, 0, 36),
                    ZIndex           = 4,
                    Parent           = Frame,
                })
                Corner(HeaderBar, CORNER_ELEMENT)

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size     = UDim2.new(1, -56, 0, 36),
                    Font     = FONT_MEDIUM,
                    Text     = name,
                    TextColor3     = Theme.Text,
                    TextSize       = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex   = 4,
                    Parent   = HeaderBar,
                })

                local Preview = Create("Frame", {
                    BackgroundColor3 = color,
                    Position = UDim2.new(1, -42, 0.5, -10),
                    Size     = UDim2.new(0, 28, 0, 20),
                    ZIndex   = 4,
                    Parent   = HeaderBar,
                })
                Corner(Preview, UDim.new(0, 5))
                Stroke(Preview, Theme.Border, 1)

                -- Picker panel
                local Panel = Create("Frame", {
                    BackgroundColor3 = Theme.Section,
                    Position         = UDim2.new(0, 4, 0, 44),
                    Size             = UDim2.new(1, -8, 0, 0),
                    ClipsDescendants = true,
                    Visible          = false,
                    ZIndex           = 15,
                    Parent           = Frame,
                })
                Corner(Panel, UDim.new(0, 6))
                GradientStroke(Panel, BORDER_GRADIENT, -80, 1, 0.5)

                -- Hue bar
                local HueBar = Create("TextButton", {
                    BackgroundColor3  = Color3.new(1, 1, 1),
                    Position          = UDim2.new(0, 10, 0, 10),
                    Size              = UDim2.new(1, -20, 0, 14),
                    AutoButtonColor   = false,
                    Text              = "",
                    ZIndex            = 16,
                    Parent            = Panel,
                })
                Corner(HueBar, UDim.new(0, 4))

                Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0)),
                    }),
                    Parent = HueBar,
                })

                local HueCursor = Create("Frame", {
                    BackgroundColor3 = Theme.Text,
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = UDim2.new(h, 0, 0.5, 0),
                    Size             = UDim2.new(0, 4, 1, 4),
                    ZIndex           = 17,
                    Parent           = HueBar,
                })
                Corner(HueCursor, UDim.new(0, 2))
                Stroke(HueCursor, Color3.new(0, 0, 0), 1.5)

                -- Saturation / Value box
                -- Clip container with rounded corners
                local SVClip = Create("Frame", {
                    BackgroundTransparency = 1,
                    Position         = UDim2.new(0, 10, 0, 30),
                    Size             = UDim2.new(1, -20, 0, 95),
                    ClipsDescendants = true,
                    ZIndex           = 16,
                    Parent           = Panel,
                })
                Corner(SVClip, UDim.new(0, 4))

                local SVBox = Create("TextButton", {
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    Size             = UDim2.new(1, 0, 1, 0),
                    AutoButtonColor  = false,
                    Text             = "",
                    ZIndex           = 16,
                    Parent           = SVClip,
                })
                Corner(SVBox, UDim.new(0, 4))

                -- White overlay (saturation axis)
                local WhiteOvr = Create("Frame", {
                    BackgroundColor3       = Color3.new(1, 1, 1),
                    Size                   = UDim2.new(1, 0, 1, 0),
                    ZIndex                 = 17,
                    Parent                 = SVBox,
                })
                Corner(WhiteOvr, UDim.new(0, 4))
                Create("UIGradient", {
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    Parent = WhiteOvr,
                })

                -- Black overlay (value axis)
                local BlackOvr = Create("Frame", {
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    Size             = UDim2.new(1, 0, 1, 0),
                    ZIndex           = 18,
                    Parent           = SVBox,
                })
                Corner(BlackOvr, UDim.new(0, 4))
                Create("UIGradient", {
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                    Rotation = 90,
                    Parent   = BlackOvr,
                })

                local SVCursor = Create("Frame", {
                    BackgroundColor3 = Theme.Text,
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = UDim2.new(s, 0, 1 - v, 0),
                    Size             = UDim2.new(0, 10, 0, 10),
                    ZIndex           = 19,
                    Parent           = SVBox,
                })
                Corner(SVCursor, UDim.new(1, 0))
                Stroke(SVCursor, Color3.new(0, 0, 0), 1.5)

                local function Refresh()
                    color = Color3.fromHSV(h, s, v)
                    Preview.BackgroundColor3 = color
                    SVBox.BackgroundColor3   = Color3.fromHSV(h, 1, 1)
                    HueCursor.Position       = UDim2.new(h, 0, 0.5, 0)
                    SVCursor.Position        = UDim2.new(s, 0, 1 - v, 0)
                    callback(color)
                end

                local hueDrag, svDrag = false, false

                HueBar.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        hueDrag = true
                        h = math.clamp((i.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                        Refresh()
                    end
                end)
                HueBar.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then hueDrag = false end
                end)

                SVBox.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        svDrag = true
                        s = math.clamp((i.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((i.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                        Refresh()
                    end
                end)
                SVBox.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then svDrag = false end
                end)

                TrackConnection(UserInputService.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                        if hueDrag then
                            h = math.clamp((i.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                            Refresh()
                        elseif svDrag then
                            s = math.clamp((i.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                            v = 1 - math.clamp((i.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                            Refresh()
                        end
                    end
                end))

                TrackConnection(UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        hueDrag = false; svDrag = false
                    end
                end))

                -- Toggle panel
                local TogBtn = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size   = UDim2.new(1, 0, 0, 36),
                    Text   = "",
                    ZIndex = 5,
                    Parent = Frame,
                })

                TogBtn.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    if pickerOpen then
                        Panel.Visible = true
                        Tween(Frame, {Size = UDim2.new(1, 0, 0, 44 + 138 + 6)}, 0.22, Enum.EasingStyle.Quart)
                        Tween(Panel, {Size = UDim2.new(1, -8, 0, 138)}, 0.22)
                        -- Auto-scroll page to show picker
                        local expandH = 44 + 138 + 6
                        local frameTop = Frame.AbsolutePosition.Y
                        local pageTop = Page.AbsolutePosition.Y
                        local pageH = Page.AbsoluteSize.Y
                        local frameBottom = (frameTop - pageTop + Page.CanvasPosition.Y) + expandH
                        local visibleBottom = Page.CanvasPosition.Y + pageH
                        if frameBottom > visibleBottom then
                            local scrollOffset = frameBottom - visibleBottom + 10
                            Tween(Page, {CanvasPosition = Vector2.new(0, Page.CanvasPosition.Y + scrollOffset)}, 0.2, Enum.EasingStyle.Quart)
                        end
                    else
                        Tween(Frame, {Size = UDim2.new(1, 0, 0, 36)}, 0.18)
                        Tween(Panel, {Size = UDim2.new(1, -8, 0, 0)}, 0.18)
                        task.delay(0.18, function() Panel.Visible = false end)
                    end
                end)

                Refresh()

                local elem = {
                    Set = function(_, clr) h, s, v = clr:ToHSV(); Refresh() end,
                    Get = function() return color end,
                }
                table.insert(_elements, { type = "colorpicker", default = default, element = elem })
                return elem
            end

            -- ══════════════════════════════
            -- BIND
            -- ══════════════════════════════
            function Section:CreateBind(c)
                c = c or {}
                local name      = c.Name or "Bind"
                local default   = c.Default or Enum.KeyCode.Unknown
                local callback  = c.Callback or function() end
                local current   = default
                local listening = false
                local linkedToggle = nil

                local Frame = Create("Frame", {
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = 0.3,
                    Size             = UDim2.new(1, 0, 0, 36),
                    Parent           = Elems,
                })
                Corner(Frame, CORNER_ELEMENT)

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size     = UDim2.new(0.55, 0, 1, 0),
                    Font     = FONT_MEDIUM,
                    Text     = name,
                    TextColor3     = Theme.Text,
                    TextSize       = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent   = Frame,
                })

                local BindBtn = Create("TextButton", {
                    BackgroundColor3 = Theme.Section,
                    Position = UDim2.new(1, -90, 0.5, -12),
                    Size     = UDim2.new(0, 76, 0, 24),
                    Font     = FONT_MEDIUM,
                    Text     = current == Enum.KeyCode.Unknown and "None" or current.Name,
                    TextColor3     = Theme.TextDim,
                    TextSize       = 11,
                    AutoButtonColor = false,
                    Parent   = Frame,
                })
                Corner(BindBtn, UDim.new(0, 5))
                local bStroke = Stroke(BindBtn, Theme.Border, 1, 0.4)

                BindBtn.MouseButton1Click:Connect(function()
                    listening = true
                    BindBtn.Text = "..."
                    Tween(bStroke, {Transparency = 1}, 0.12)
                    Tween(BindBtn, {TextColor3 = Theme.Accent}, 0.12)
                end)

                TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            listening = false
                            if input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Backspace then
                                -- Delete/Backspace clears the bind
                                current = Enum.KeyCode.Unknown
                                BindBtn.Text = "None"
                            elseif input.KeyCode == Enum.KeyCode.Escape then
                                -- Escape cancels without changing
                                BindBtn.Text = current == Enum.KeyCode.Unknown and "None" or current.Name
                            else
                                current = input.KeyCode
                                BindBtn.Text = input.KeyCode.Name
                            end
                            Tween(bStroke, {Transparency = 0.4}, 0.12)
                            Tween(BindBtn, {TextColor3 = Theme.TextDim}, 0.12)
                        end
                    elseif not gpe and current ~= Enum.KeyCode.Unknown and input.KeyCode == current then
                        if linkedToggle then
                            local newState = not linkedToggle:Get()
                            linkedToggle:Set(newState)
                        end
                        callback()
                    end
                end))

                local elem = {
                    Set = function(_, k) current = k; BindBtn.Text = k == Enum.KeyCode.Unknown and "None" or k.Name; if _refreshKeybindsPanel then _refreshKeybindsPanel() end end,
                    Get = function() return current end,
                    ConnectToggle = function(_, toggle) linkedToggle = toggle; if _refreshKeybindsPanel then _refreshKeybindsPanel() end end,
                }
                -- Register in binds list for keybinds panel
                local bindEntry = {
                    name = name,
                    getKey = function() return current end,
                    getToggle = function() return linkedToggle end,
                    element = elem,
                }
                table.insert(_binds, bindEntry)
                table.insert(_elements, { type = "bind", default = default, element = elem })
                if _refreshKeybindsPanel then _refreshKeybindsPanel() end
                return elem
            end

            -- ══════════════════════════════
            -- LABEL
            -- ══════════════════════════════
            function Section:CreateLabel(text)
                local Lbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size     = UDim2.new(1, 0, 0, 22),
                    Font     = FONT_REGULAR,
                    Text     = text or "",
                    TextColor3     = Theme.TextDim,
                    TextSize       = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent   = Elems,
                })
                Padding(Lbl, 0, 12, 0, 12)

                return {
                    Set = function(_, t) Lbl.Text = t end,
                }
            end

            -- ══════════════════════════════
            -- SEPARATOR
            -- ══════════════════════════════
            function Section:CreateSeparator()
                local Sep = Create("Frame", {
                    BackgroundColor3       = Theme.Divider,
                    Size                   = UDim2.new(1, -8, 0, 1),
                    Position               = UDim2.new(0, 4, 0, 0),
                    BorderSizePixel        = 0,
                    Parent                 = Elems,
                })
            end

            table.insert(Tab.Sections, Section)
            return Section
        end

        return Tab
    end

    -- ╔════════════════════════════════════════════════════════════╗
    -- ║                      TARGET HUD                           ║
    -- ╚════════════════════════════════════════════════════════════╝
    local _targetHudEnabled  = false
    local _targetHudInstance  = nil   -- the CanvasGroup on screen
    local _targetHudConn     = nil   -- RenderStepped connection
    local _currentTarget     = nil   -- Player currently shown
    local _targetHudFading   = false

    -- Forward-declare fade for use in window hide/minimize
    local FadeTargetHud

    --[[ FindHumanoid: walks a character model to find a Humanoid.
         Handles games that rename Humanoid to something else. ]]
    local function FindHumanoid(character)
        if not character then return nil end
        -- Try the default name first (fastest path)
        local hum = character:FindFirstChild("Humanoid")
        if hum and hum:IsA("Humanoid") then return hum end
        -- Fallback: search by ClassName
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Humanoid") then
                return obj
            end
        end
        return nil
    end

    --[[ GetPlayerFromCharacterPart: given a BasePart, resolve the
         owning Player (if any). ]]
    local function GetPlayerFromCharacterPart(part)
        if not part or not part:IsA("BasePart") then return nil end
        local model = part:FindFirstAncestorOfClass("Model")
        if not model then return nil end
        return Players:GetPlayerFromCharacter(model)
    end

    function Window:CreateTargetHUD(cfg)
        cfg = cfg or {}
        local hudW       = cfg.Width  or 220
        local hudH       = cfg.Height or 68
        local maxDist    = cfg.MaxDistance or 2500

        -- ── Build HUD Frame ──────────────
        local THud = Create("CanvasGroup", {
            Name              = "TargetHUD",
            BackgroundTransparency = 1,
            AnchorPoint       = Vector2.new(0.5, 0),
            Position          = UDim2.new(0.5, 0, 0, 100),
            Size              = UDim2.new(0, hudW, 0, hudH),
            GroupTransparency = 1,
            Visible           = false,
            ZIndex            = 180,
            Parent            = ScreenGui,
        })

        local THudScale = Create("UIScale", {
            Scale  = 0.85,
            Parent = THud,
        })

        -- Background
        local THudBg = Create("Frame", {
            Name             = "Bg",
            BackgroundColor3 = Color3.new(1, 1, 1),
            Size             = UDim2.new(1, 0, 1, 0),
            Parent           = THud,
        })
        Corner(THudBg, UDim.new(0, 10))
        Gradient(THudBg, SIDEBAR_GRADIENT, 90)

        -- Avatar holder
        local THudAvatarHolder = Create("Frame", {
            Name             = "AvatarHolder",
            BackgroundColor3 = Theme.Element,
            Position         = UDim2.new(0, 10, 0.5, -22),
            Size             = UDim2.new(0, 44, 0, 44),
            Parent           = THudBg,
        })
        Corner(THudAvatarHolder, UDim.new(1, 0))
        local thAvatarStroke = Stroke(THudAvatarHolder, Color3.new(1, 1, 1), 2, 0.45)
        Gradient(thAvatarStroke, ACCENT_GRADIENT, 90)

        local THudAvatar = Create("ImageLabel", {
            Name                 = "Img",
            BackgroundTransparency = 1,
            Size                 = UDim2.new(1, 0, 1, 0),
            Image                = "",
            Parent               = THudAvatarHolder,
        })
        Corner(THudAvatar, UDim.new(1, 0))

        -- Player name label
        local THudName = Create("TextLabel", {
            Name                 = "PlayerName",
            BackgroundTransparency = 1,
            Position             = UDim2.new(0, 62, 0, 8),
            Size                 = UDim2.new(1, -72, 0, 16),
            Font                 = FONT_SEMI,
            Text                 = "",
            TextColor3           = Theme.Text,
            TextSize             = 13,
            TextXAlignment       = Enum.TextXAlignment.Left,
            TextTruncate         = Enum.TextTruncate.AtEnd,
            Parent               = THudBg,
        })

        -- Health bar background
        local THudHealthBg = Create("Frame", {
            Name             = "HealthBg",
            BackgroundColor3 = Theme.SliderTrack,
            Position         = UDim2.new(0, 62, 0, 30),
            Size             = UDim2.new(1, -74, 0, 8),
            Parent           = THudBg,
        })
        Corner(THudHealthBg, UDim.new(0, 4))

        -- Health bar fill
        local THudHealthFill = Create("Frame", {
            Name             = "Fill",
            BackgroundColor3 = Theme.Success,
            Size             = UDim2.new(1, 0, 1, 0),
            Parent           = THudHealthBg,
        })
        Corner(THudHealthFill, UDim.new(0, 4))

        -- Health text
        local THudHealthText = Create("TextLabel", {
            Name                 = "HealthText",
            BackgroundTransparency = 1,
            Position             = UDim2.new(0, 62, 0, 42),
            Size                 = UDim2.new(1, -72, 0, 14),
            Font                 = FONT_REGULAR,
            Text                 = "100 / 100",
            TextColor3           = Theme.TextDim,
            TextSize             = 10,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = THudBg,
        })

        _targetHudInstance = THud

        -- ── Show / Hide helpers ──────────
        local function ShowHud(player)
            if _currentTarget == player and THud.Visible then return end
            _currentTarget = player
            _targetHudFading = false

            THudAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
            THudName.Text    = player.DisplayName .. " (@" .. player.Name .. ")"

            THud.Visible = true
            Tween(THud, {GroupTransparency = 0}, 0.18, Enum.EasingStyle.Quart)
            Tween(THudScale, {Scale = 1}, 0.18, Enum.EasingStyle.Quart)
        end

        local function HideHud()
            if not THud.Visible or _targetHudFading then return end
            _targetHudFading = true
            local tw = Tween(THud, {GroupTransparency = 1}, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            Tween(THudScale, {Scale = 0.85}, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            tw.Completed:Connect(function()
                if _targetHudFading then
                    THud.Visible = false
                    _currentTarget = nil
                    _targetHudFading = false
                end
            end)
        end

        -- Health color helper  (green → yellow → red)
        local function HealthColor(pct)
            if pct > 0.5 then
                -- green → yellow
                local t = (pct - 0.5) / 0.5
                return Color3.fromRGB(
                    math.floor(67 + (250 - 67) * (1 - t)),
                    math.floor(181 + (166 - 181) * (1 - t)),
                    math.floor(129 + (26 - 129) * (1 - t))
                )
            else
                -- yellow → red
                local t = pct / 0.5
                return Color3.fromRGB(
                    math.floor(237 + (250 - 237) * t),
                    math.floor(66 + (166 - 66) * t),
                    math.floor(69 + (26 - 69) * t)
                )
            end
        end

        -- ── Update loop ──────────────────
        local Camera = workspace.CurrentCamera

        _targetHudConn = TrackConnection(RunService.RenderStepped:Connect(function()
            if not _targetHudEnabled or not Window.Visible or minimized then
                if THud.Visible and not _targetHudFading then HideHud() end
                return
            end

            -- Raycast from mouse position
            local mousePos = UserInputService:GetMouseLocation()
            local ray      = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local params   = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {LocalPlayer.Character}
            local result = workspace:Raycast(ray.Origin, ray.Direction * maxDist, params)

            if result and result.Instance then
                local targetPlayer = GetPlayerFromCharacterPart(result.Instance)
                if targetPlayer and targetPlayer ~= LocalPlayer then
                    local character = targetPlayer.Character
                    local humanoid  = FindHumanoid(character)
                    if humanoid and humanoid.Health > 0 then
                        ShowHud(targetPlayer)
                        -- Update health
                        local hp    = humanoid.Health
                        local maxHp = humanoid.MaxHealth
                        local pct   = math.clamp(hp / maxHp, 0, 1)
                        Tween(THudHealthFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.12)
                        Tween(THudHealthFill, {BackgroundColor3 = HealthColor(pct)}, 0.12)
                        THudHealthText.Text = math.floor(hp) .. " / " .. math.floor(maxHp)
                        return
                    end
                end
            end

            -- Nothing valid under cursor
            if _currentTarget then
                HideHud()
            end
        end))

        -- ── Fade for window hide / minimize ──
        FadeTargetHud = function(targetTransparency, dur)
            Tween(THud, {GroupTransparency = targetTransparency}, dur, Enum.EasingStyle.Sine)
        end

        -- ── Public API ───────────────────
        local TargetHUD = {}

        function TargetHUD:Enable()
            _targetHudEnabled = true
        end

        function TargetHUD:Disable()
            _targetHudEnabled = false
            HideHud()
        end

        function TargetHUD:Toggle()
            if _targetHudEnabled then
                self:Disable()
            else
                self:Enable()
            end
        end

        function TargetHUD:IsEnabled()
            return _targetHudEnabled
        end

        function TargetHUD:SetMaxDistance(dist)
            maxDist = dist
        end

        return TargetHUD
    end

    -- ╔════════════════════════════════════════════════════════════╗
    -- ║                    NOTIFICATIONS                          ║
    -- ╚════════════════════════════════════════════════════════════╝
    local NOTIF_HEIGHT = 62
    local NOTIF_MAX    = 2

    local activeNotifs = {} -- ordered list of active notification CanvasGroups

    -- Container with UIListLayout — notifications stack automatically
    local NotifContainer = Create("Frame", {
        Name                 = "NotifContainer",
        BackgroundTransparency = 1,
        AnchorPoint          = Vector2.new(0.5, 0),
        Position             = UDim2.new(0.5, 0, 0, 10),
        Size                 = UDim2.new(0, 280, 1, -10),
        ZIndex               = 200,
        Parent               = ScreenGui,
    })
    Create("UIListLayout", {
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent        = NotifContainer,
    })

    FadeNotifs = function(targetTransparency, dur, style, dir)
        for _, nf in ipairs(activeNotifs) do
            Tween(nf, {GroupTransparency = targetTransparency}, dur, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
        end
    end

    local function RemoveNotif(nFrame)
        -- Remove from active list immediately
        for i, nf in ipairs(activeNotifs) do
            if nf == nFrame then
                table.remove(activeNotifs, i)
                break
            end
        end

        local nScale = nFrame:FindFirstChildWhichIsA("UIScale")

        -- Fade out and scale down simultaneously
        Tween(nFrame, {GroupTransparency = 1}, 0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        if nScale then
            local tw = Tween(nScale, {Scale = 0}, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw.Completed:Connect(function()
                nFrame:Destroy()
            end)
        else
            task.delay(0.08, function()
                nFrame:Destroy()
            end)
        end
    end

    function Window:Notify(c)
        c = c or {}
        local title    = c.Title or "Notification"
        local message  = c.Message or ""
        local duration = c.Duration or 3.5
        local nType    = c.Type or "Info"

        local accent = Theme.Accent
        if nType == "Success" then accent = Theme.Success
        elseif nType == "Warning" then accent = Theme.Warning
        elseif nType == "Error" then accent = Theme.Error end

        -- Expire oldest notification so only 1 stays visible
        while #activeNotifs >= 1 do
            local oldest = activeNotifs[1]
            if oldest then
                RemoveNotif(oldest)
            end
        end

        local NFrame = Create("CanvasGroup", {
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, 0, 0, NOTIF_HEIGHT),
            GroupTransparency = 1,  -- start fully transparent
            ZIndex           = 200,
            Parent           = NotifContainer,
        })

        -- UIScale for enter/exit size animations
        local NScale = Create("UIScale", {
            Scale  = 0,  -- start at zero size
            Parent = NFrame,
        })

        -- Background frame (takes the gradient)
        local NFrameBg = Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Size             = UDim2.new(1, 0, 1, 0),
            Parent           = NFrame,
        })
        Corner(NFrameBg, UDim.new(0, 10))
        Gradient(NFrameBg, SIDEBAR_GRADIENT, 90)

        -- Track this notification
        table.insert(activeNotifs, NFrame)

        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 0),
            Size     = UDim2.new(1, -32, 0.5, 0),
            Font     = FONT_SEMI,
            Text     = title,
            TextColor3     = Theme.Text,
            TextSize       = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            Parent   = NFrame,
        })

        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0.5, 2),
            Size     = UDim2.new(1, -32, 0.5, -2),
            Font     = FONT_REGULAR,
            Text     = message,
            TextColor3     = Theme.TextDim,
            TextSize       = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped    = true,
            Parent   = NFrame,
        })

        -- Scale up and fade in simultaneously
        Tween(NScale, {Scale = 1}, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.delay(0.05, function()
            Tween(NFrame, {GroupTransparency = 0}, 0.08, Enum.EasingStyle.Sine)
        end)

        -- Auto-dismiss after duration (counted from creation)
        task.delay(duration, function()
            local found = false
            for _, nf in ipairs(activeNotifs) do
                if nf == NFrame then found = true; break end
            end
            if found then
                RemoveNotif(NFrame)
            end
        end)
    end

    -- ╔════════════════════════════════════════════════════════════╗
    -- ║                    KEYBINDS PANEL                         ║
    -- ╚════════════════════════════════════════════════════════════╝
    local KBPANEL_W = 220

    local KBPanel = Create("CanvasGroup", {
        Name              = "KeybindsPanel",
        BackgroundTransparency = 1,
        AnchorPoint       = Vector2.new(1, 0),
        Position          = UDim2.new(1, -12, 0, 12),
        Size              = UDim2.new(0, KBPANEL_W, 0, 0),
        AutomaticSize     = Enum.AutomaticSize.Y,
        GroupTransparency = 1,
        Visible           = false,
        ZIndex            = 150,
        Parent            = ScreenGui,
    })

    local KBScale = Create("UIScale", {
        Scale  = 0,
        Parent = KBPanel,
    })

    -- Panel background
    local KBBg = Create("Frame", {
        Name             = "Bg",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        Parent           = KBPanel,
    })
    Corner(KBBg, UDim.new(0, 10))
    Gradient(KBBg, SIDEBAR_GRADIENT, 90)

    -- Panel header (also serves as drag handle)
    local KBHeader = Create("Frame", {
        Name                 = "Header",
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 0, 32),
        Parent               = KBBg,
    })

    -- Drag logic for keybinds panel
    local kbDragging, kbDragStart, kbStartPos
    KBHeader.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            kbDragging = true
            kbDragStart = input.Position
            kbStartPos = KBPanel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    kbDragging = false
                end
            end)
        end
    end)
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if kbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - kbDragStart
            KBPanel.Position = UDim2.new(kbStartPos.X.Scale, kbStartPos.X.Offset + d.X, kbStartPos.Y.Scale, kbStartPos.Y.Offset + d.Y)
        end
    end))

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size     = UDim2.new(1, -24, 1, 0),
        Font     = FONT_SEMI,
        Text     = "KEYBINDS",
        TextColor3     = Theme.TextDim,
        TextSize       = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent   = KBHeader,
    })

    -- Divider under header
    local KBDiv = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position         = UDim2.new(0, 10, 1, -1),
        Size             = UDim2.new(1, -20, 0, 1),
        BorderSizePixel  = 0,
        Parent           = KBHeader,
    })
    Gradient(KBDiv, DIVIDER_GRADIENT)

    -- Entries container
    local KBEntries = Create("Frame", {
        Name                 = "Entries",
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 0, 0, 32),
        Size                 = UDim2.new(1, 0, 0, 0),
        AutomaticSize        = Enum.AutomaticSize.Y,
        Parent               = KBBg,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 2),
        Parent    = KBEntries,
    })
    Padding(KBEntries, 4, 8, 8, 8)

    -- No binds label
    local KBEmpty = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 0, 28),
        Font     = FONT_REGULAR,
        Text     = "No keybinds set",
        TextColor3 = Theme.TextDark,
        TextSize   = 11,
        Parent   = KBEntries,
    })

    _refreshKeybindsPanel = function()
        -- Clear existing entry frames
        for _, child in ipairs(KBEntries:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        local hasBinds = false
        for _, bind in ipairs(_binds) do
            local key = bind.getKey()
            if key ~= Enum.KeyCode.Unknown then
                hasBinds = true
                local toggle = bind.getToggle()
                local isOn = toggle and toggle.Get and toggle:Get() or false

                local row = Create("Frame", {
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = 0.4,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = KBEntries,
                })
                Corner(row, UDim.new(0, 5))

                -- Bind name
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size     = UDim2.new(0.5, -8, 1, 0),
                    Font     = FONT_MEDIUM,
                    Text     = bind.name,
                    TextColor3 = Theme.Text,
                    TextSize   = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate   = Enum.TextTruncate.AtEnd,
                    Parent   = row,
                })

                -- Key badge
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size     = UDim2.new(0.25, 0, 1, 0),
                    Font     = FONT_MEDIUM,
                    Text     = "[" .. key.Name .. "]",
                    TextColor3 = Theme.Accent,
                    TextSize   = 10,
                    Parent   = row,
                })

                -- Status indicator
                if toggle then
                    local statusDot = Create("Frame", {
                        BackgroundColor3 = isOn and Theme.Success or Theme.Error,
                        AnchorPoint      = Vector2.new(0, 0.5),
                        Position         = UDim2.new(1, -18, 0.5, 0),
                        Size             = UDim2.new(0, 8, 0, 8),
                        Parent           = row,
                    })
                    Corner(statusDot, UDim.new(1, 0))
                end
            end
        end

        KBEmpty.Visible = not hasBinds
    end

    -- Fade keybinds panel (used by minimize/restore/toggle window)
    _fadeKeybindsPanel = function(targetTransparency, dur)
        Tween(KBPanel, {GroupTransparency = targetTransparency}, dur, Enum.EasingStyle.Sine)
    end

    -- Auto-refresh keybinds panel when open (throttled)
    local _kbRefreshTimer = 0
    TrackConnection(RunService.Heartbeat:Connect(function(dt)
        if _keybindsPanelOpen then
            _kbRefreshTimer = _kbRefreshTimer + dt
            if _kbRefreshTimer >= 0.25 then
                _kbRefreshTimer = 0
                _refreshKeybindsPanel()
            end
        end
    end))

    function Window:ToggleKeybinds()
        _keybindsPanelOpen = not _keybindsPanelOpen
        if _keybindsPanelOpen then
            _refreshKeybindsPanel()
            KBPanel.Visible = true
            KBPanel.GroupTransparency = 1
            KBScale.Scale = 0
            -- Scale up then fade in
            Tween(KBScale, {Scale = 1}, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.delay(0.05, function()
                Tween(KBPanel, {GroupTransparency = 0}, 0.08, Enum.EasingStyle.Sine)
            end)
        else
            -- Fade out then scale down
            Tween(KBPanel, {GroupTransparency = 1}, 0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            local tw = Tween(KBScale, {Scale = 0}, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw.Completed:Connect(function()
                if not _keybindsPanelOpen then
                    KBPanel.Visible = false
                end
            end)
        end
    end

    function Window:ShowKeybinds()
        if not _keybindsPanelOpen then
            self:ToggleKeybinds()
        end
    end

    function Window:HideKeybinds()
        if _keybindsPanelOpen then
            self:ToggleKeybinds()
        end
    end

    -- ╔════════════════════════════════════════════════════════════╗
    -- ║                    AUTO CLEAN UP                          ║
    -- ╚════════════════════════════════════════════════════════════╝
    function Window:CleanUp()
        -- Reset all elements to their default values
        for _, entry in ipairs(_elements) do
            local el = entry.element
            if el and el.Set then
                pcall(el.Set, el, entry.default)
            end
        end
    end

    -- ╔════════════════════════════════════════════════════════════╗
    -- ║                       DESTROY                             ║
    -- ╚════════════════════════════════════════════════════════════╝
    function Window:Destroy()
        -- Disconnect all tracked connections
        for _, conn in ipairs(_connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(_connections)
        table.clear(_elements)
        table.clear(_binds)

        ScreenGui:Destroy()
    end

    return Window
end

return RockSide
