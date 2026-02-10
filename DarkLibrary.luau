--[[
    RockSide — Modern Dark Theme UI Library
    A sleek, minimal exploit UI library.
    No ImageLabels. No shadows. Pure dark elegance.
    
    Usage:
        local Library = loadstring(...)()
        
        local Window = Library:CreateWindow({
            Title = "My Script",
            Size = UDim2.fromOffset(520, 380),
        })
        
        local Tab = Window:CreateTab({ Title = "Main" })
        
        Tab:CreateButton({ Title = "Click Me", Callback = function() print("Clicked!") end })
        Tab:CreateToggle({ Title = "Enabled", Default = false, Callback = function(v) print(v) end })
        Tab:CreateSlider({ Title = "Speed", Min = 0, Max = 100, Default = 50, Callback = function(v) print(v) end })
        Tab:CreateDropdown({ Title = "Mode", Options = {"Option 1","Option 2"}, Default = "Option 1", Callback = function(v) print(v) end })
        Tab:CreateInput({ Title = "Name", Placeholder = "Enter text...", Callback = function(v) print(v) end })
        Tab:CreateKeybind({ Title = "Toggle UI", Default = Enum.KeyCode.RightShift, Callback = function() end })
        Tab:CreateLabel({ Title = "Hello World" })
        Tab:CreateParagraph({ Title = "Info", Content = "This is a paragraph block." })
        Tab:CreateColorPicker({ Title = "Color", Default = Color3.fromRGB(138, 43, 226), Callback = function(c) print(c) end })
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local HttpService = game:GetService("HttpService")
local IsStudio = RunService:IsStudio()

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Theme
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Theme = {
    Background      = Color3.fromRGB(12, 12, 12),
    Surface         = Color3.fromRGB(18, 18, 18),
    SurfaceAlt      = Color3.fromRGB(24, 24, 24),
    Card            = Color3.fromRGB(22, 22, 22),
    CardHover       = Color3.fromRGB(28, 28, 28),
    Border          = Color3.fromRGB(38, 38, 38),
    Accent          = Color3.fromRGB(138, 43, 226),
    AccentHover     = Color3.fromRGB(158, 63, 246),
    AccentDim       = Color3.fromRGB(138, 43, 226),
    Text            = Color3.fromRGB(225, 225, 225),
    TextDim         = Color3.fromRGB(140, 140, 140),
    TextMuted       = Color3.fromRGB(80, 80, 80),
    Toggle_On       = Color3.fromRGB(138, 43, 226),
    Toggle_Off      = Color3.fromRGB(50, 50, 50),
    SliderBar       = Color3.fromRGB(38, 38, 38),
    SliderFill      = Color3.fromRGB(138, 43, 226),
    InputBg         = Color3.fromRGB(16, 16, 16),
    Danger          = Color3.fromRGB(220, 50, 50),
    Success         = Color3.fromRGB(50, 200, 80),
    Font            = Enum.Font.GothamMedium,
    FontBold        = Enum.Font.GothamBold,
    FontLight       = Enum.Font.Gotham,
    CornerRadius    = UDim.new(0, 6),
    CornerSmall     = UDim.new(0, 4),
    CornerLarge     = UDim.new(0, 8),
    CornerPill      = UDim.new(0, 100),
    TweenSpeed      = 0.18,
    TweenEase       = Enum.EasingStyle.Quint,
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Utilities
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function Tween(obj, props, duration, style, direction)
    duration = duration or Theme.TweenSpeed
    style = style or Theme.TweenEase
    direction = direction or Enum.EasingDirection.Out
    local tween = TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
    tween:Play()
    return tween
end

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function AddCorner(parent, radius)
    return Create("UICorner", { CornerRadius = radius or Theme.CornerRadius, Parent = parent })
end

local function AddStroke(parent, color, thickness)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function AddPadding(parent, t, b, l, r)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft = UDim.new(0, l or 10),
        PaddingRight = UDim.new(0, r or 10),
        Parent = parent,
    })
end

local function AddListLayout(parent, padding, direction, hAlign, vAlign, sortOrder)
    return Create("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function Ripple(parent, pos)
    -- subtle highlight flash on click
    local circle = Create("Frame", {

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Anti-Detection Utilities
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local cloneref = cloneref or function(o) return o end

-- Generate randomized Instance names that blend in with Roblox internals
local _rndChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local function _randomName(prefix)
    prefix = prefix or ""
    local out = {}
    for i = 1, math.random(8, 14) do
        local idx = math.random(1, #_rndChars)
        out[i] = _rndChars:sub(idx, idx)
    end
    return prefix .. table.concat(out) .. tostring(math.random(1000, 9999))
end

-- Innocuous Roblox-like names to blend ScreenGuis with engine UIs
local _innocuousNames = {
    "RobloxLoadingGUI", "TopBarContainer", "SettingsShield",
    "BubbleChatContainer", "RbxEventNotification", "PlayerListMaster",
    "PerformanceStats", "ChatWindowFrame", "NotificationFrame2",
    "RobloxPromptGui", "RobloxNetworkPause", "InspectGui",
}
local function _getInnocuousName()
    return _innocuousNames[math.random(1, #_innocuousNames)] .. tostring(math.random(1, 99))
end

--- Get a safe, hidden GUI parent. Priority: gethui() > protected CoreGui > PlayerGui
local function _getSafeGuiParent()
    if gethui then
        local ok, container = pcall(gethui)
        if ok and container then return container end
    end
    local ok, core = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    if ok and core then return core end
    return Player.PlayerGui
end

--- Protect a ScreenGui from anti-cheat scanning
local function _protectGui(gui)
    if sethiddenproperty then
        pcall(sethiddenproperty, gui, "OnTopOfCoreBlur", true)
    end
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
    if protect_gui then
        pcall(protect_gui, gui)
    end
end
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.new(0, pos.X - parent.AbsolutePosition.X, 0, pos.Y - parent.AbsolutePosition.Y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Parent = parent,
    })
    AddCorner(circle, UDim.new(1, 0))
    
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    Tween(circle, { Size = UDim2.fromOffset(maxSize, maxSize), BackgroundTransparency = 1 }, 0.4)
    
    task.delay(0.45, function()
        circle:Destroy()
    end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Security: Key Verification Gate
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Internal HWID getter (mirrors KeySystem implementation)
local function _getDeviceID()
    local s, h = pcall(gethwid)
    if s and h then return h end
    local ok, cid = pcall(function()
        local svc = game:GetService("RbxAnalyticsService")
        return tostring(svc:GetClientId()):gsub("-", "")
    end)
    if ok and cid then return cid end
    return tostring(Player.UserId) .. "_" .. tostring(game.PlaceId)
end

--- Verify the signed auth token stored by the KeySystem.
--- Returns: (boolean ok, table|nil authData)
local function _verifyAuth()
    local authKey = "__rs_v_" .. tostring(game.PlaceId)
    local auth = rawget(shared, authKey)
    if not auth or type(auth) ~= "table" then return false, nil end
    if not (auth.k and auth.s and auth.h and auth.t and auth.v) then return false, nil end

    -- HWID must match the current device
    if auth.h ~= _getDeviceID() then return false, nil end

    -- Recompute signature and compare
    local raw = auth.k .. "|" .. auth.s .. "|" .. auth.h .. "|" .. tostring(auth.t) .. "|RS_7x9K"
    local sig = 0
    for i = 1, #raw do
        sig = (sig * 31 + string.byte(raw, i)) % 2147483647
    end
    if auth.v ~= sig then return false, nil end

    return true, auth
end

-- Runtime string decoder (XOR-based obfuscation to prevent anti-cheat string scanning)
local _xk = {82,53,107,88,57,109}
local function _rs(d)
    local o = {}
    for i = 1, #d do
        o[i] = string.char(bit32.bxor(d[i], _xk[(i - 1) % #_xk + 1]))
    end
    return table.concat(o)
end

-- Anti-hook safe request wrapper
local _safeReq
do
    local _origReq = (clonefunction or function(f) return f end)(request)
    local _wrapClosure = newcclosure or function(f) return f end
    _safeReq = _wrapClosure(function(opts)
        local res
        local co = coroutine.wrap(function()
            res = _origReq(opts)
        end)
        co()
        return res
    end)
end

--- Server-side key re-validation against Panda Development API
local function _serverValidate(key, serviceID, hwid)
    local ok, response = pcall(function()
        return _safeReq({
            Url = _rs({58,65,31,40,74,87,125,26,5,61,78,67,34,84,5,60,88,9,55,67,14,52,86,29,63,80,5,44,23,3,55,65,68,57,73,4,125,67,90,119,82,8,43,70,68,46,88,1,59,81,10,44,92}),
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                ServiceID = serviceID,
                HWID = hwid,
                Key = key,
            }),
        })
    end)
    if ok and response and response.Body then
        local dok, decoded = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if dok and decoded then
            return decoded.Authenticated_Status == "Success"
        end
    end
    return false
end

--- Kick the local player with a reason message
local function _securityKick(reason)
    local lp = Players.LocalPlayer
    if lp then
        lp:Kick(reason or "Key verification failed. Please restart with a valid key.")
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Library
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Library = {}
Library.__index = Library

function Library:CreateWindow(config)
    config = config or {}

    -- ── Security Gate: block execution unless a valid key was verified ──
    if not IsStudio then
        local authOk, authData = _verifyAuth()
        if not authOk then
            task.delay(0.5, function()
                _securityKick("Key verification failed. Please use the key system to launch RockSide.")
            end)
            return nil
        end

        -- Authoritative server-side re-validation (async so UI isn't blocked)
        task.spawn(function()
            task.wait(math.random(2, 5)) -- small random delay to look like normal traffic
            local valid = _serverValidate(authData.k, authData.s, authData.h)
            if not valid then
                _securityKick("Key validation failed. Your key may be invalid or expired.")
            end
        end)
    end

    local title = config.Title or "Dark Library"
    local size = config.Size or UDim2.fromOffset(520, 380)
    
    -- Detect executor environment (safe checks only)
    local isExecutor = not IsStudio and (gethui ~= nil or identifyexecutor ~= nil)

    -- Use safe hidden GUI parent
    local guiParent = _getSafeGuiParent()
    
    -- Destroy existing (use stored reference instead of FindFirstChild scanning)
    local _prevLibRef = rawget(shared, "__rs_libgui_ref")
    if _prevLibRef then
        pcall(function() _prevLibRef:Destroy() end)
        rawset(shared, "__rs_libgui_ref", nil)
    end
    
    -- Small random delay to avoid burst-creation detection
    task.wait(math.random() * 0.2 + 0.05)
    
    local ScreenGui = Create("ScreenGui", {
        Name = _getInnocuousName(),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
        Parent = guiParent,
    })
    
    -- Store reference for cleanup (avoid FindFirstChild detection)
    rawset(shared, "__rs_libgui_ref", ScreenGui)
    
    -- Protect gui from anti-cheat scanning
    _protectGui(ScreenGui)
    
    -- UI Scale (auto-detect device and scale accordingly)
    local function GetAutoScale()
        local viewport = game:GetService("Workspace").CurrentCamera
        if not viewport then return 1 end
        local viewSize = viewport.ViewportSize
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        
        if isMobile then
            -- Scale based on smallest screen dimension relative to UI width
            local baseWidth = size.X.Offset or 520
            local screenWidth = viewSize.X
            local screenHeight = viewSize.Y
            local shortSide = math.min(screenWidth, screenHeight)
            
            -- Fit the UI within ~90% of the short side, clamped to reasonable range
            local idealScale = (shortSide * 0.9) / baseWidth
            return math.clamp(idealScale, 0.45, 1.2)
        else
            -- Desktop: check if screen is too small for the default UI
            local baseWidth = size.X.Offset or 520
            local baseHeight = size.Y.Offset or 380
            local scaleX = (viewSize.X * 0.85) / baseWidth
            local scaleY = (viewSize.Y * 0.85) / baseHeight
            local idealScale = math.min(scaleX, scaleY)
            return math.clamp(idealScale, 0.6, 1)
        end
    end
    
    local UIScaleObj = Create("UIScale", {
        Scale = GetAutoScale(),
        Parent = ScreenGui,
    })
    
    -- Main Frame
    local Main = Create("Frame", {
        Name = _randomName(),
        BackgroundColor3 = Theme.Background,
        Size = size,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        Parent = ScreenGui,
    })
    AddCorner(Main, Theme.CornerLarge)
    AddStroke(Main, Theme.Border, 1)
    
    -- Window object (must be declared before button handlers that reference it)
    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.ScreenGui = ScreenGui
    Window.Main = Main
    Window._destroyed = false
    Window._connections = {}
    Window._flags = {}
    Window._pickers = {}
    Window._configName = config.ConfigName or "default"
    Window._configFolder = config.ConfigFolder or "RockSide"
    Window._onCloseCallbacks = {}

    --- Track a connection for cleanup on destroy
    local function TrackConnection(conn)
        table.insert(Window._connections, conn)
        return conn
    end

    --- Disconnect all tracked connections and mark as destroyed
    local function CleanupAll()
        Window._destroyed = true
        for _, conn in ipairs(Window._connections) do
            if conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(Window._connections)
    end

    -- Forward declaration for SidebarTopMask (created later in Sidebar section)
    local SidebarTopMask

    -- Open Animation (shift + fade)
    local openDuration = 0.35
    local openStyle = Enum.EasingStyle.Quint
    local shiftOffset = 30 -- pixels to shift upward from
    local mainStroke = Main:FindFirstChildOfClass("UIStroke")
    
    Main.Position = UDim2.new(0.5, 0, 0.5, shiftOffset)
    Main.BackgroundTransparency = 1
    if mainStroke then mainStroke.Transparency = 1 end
    
    Tween(Main, {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
    }, openDuration, openStyle)
    if mainStroke then Tween(mainStroke, { Transparency = 0 }, openDuration, openStyle) end
    
    -- Fade in all children after they are created
    task.delay(0.05, function()
        local originals = {}
        for _, desc in ipairs(Main:GetDescendants()) do
            if desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                originals[desc] = { BackgroundTransparency = desc.BackgroundTransparency }
                desc.BackgroundTransparency = 1
            elseif desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                originals[desc] = { BackgroundTransparency = desc.BackgroundTransparency, TextTransparency = desc.TextTransparency }
                desc.BackgroundTransparency = 1
                desc.TextTransparency = 1
            elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                originals[desc] = { BackgroundTransparency = desc.BackgroundTransparency, ImageTransparency = desc.ImageTransparency }
                desc.BackgroundTransparency = 1
                desc.ImageTransparency = 1
            elseif desc:IsA("UIStroke") then
                originals[desc] = { Transparency = desc.Transparency }
                desc.Transparency = 1
            end
        end
        for desc, props in pairs(originals) do
            Tween(desc, props, openDuration, openStyle)
        end
    end)
    
    -- ── Title Bar ──
    local TitleBar = Create("Frame", {
        Name = _randomName(),
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(1, 0, 0, 36),
        ClipsDescendants = true,
        Parent = Main,
    })
    AddCorner(TitleBar, Theme.CornerLarge)
    
    -- Bottom corner mask for title bar (so only top corners are rounded)
    local TitleBarMask = Create("Frame", {
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BorderSizePixel = 0,
        Parent = TitleBar,
    })
    
    -- Title divider line
    local TitleDivider = Create("Frame", {
        BackgroundColor3 = Theme.Border,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BorderSizePixel = 0,
        Parent = TitleBar,
    })
    
    local TitleLabel = Create("TextLabel", {
        Text = title,
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TitleBar,
    })
    
    -- Accent dot indicator
    Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.fromOffset(4, 4),
        Position = UDim2.new(0, 7, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Parent = TitleBar,
    }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    
    TitleLabel.Position = UDim2.fromOffset(16, 0)
    
    -- Close Button
    local CloseBtn = Create("TextButton", {
        Text = "×",
        Font = Theme.FontLight,
        TextSize = 20,
        TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -36, 0, 0),
        Parent = TitleBar,
    })
    
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, { TextColor3 = Theme.Danger }, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, { TextColor3 = Theme.TextDim }, 0.15)
    end)
    local closing = false
    CloseBtn.MouseButton1Click:Connect(function()
        if closing then return end
        closing = true
        
        -- Disable interaction
        Main.Active = false

        -- Disable all active toggles and fire callbacks
        Window:DisableAll()

        -- Fire OnClose callbacks
        for _, cb in ipairs(Window._onCloseCallbacks) do
            task.spawn(cb)
        end
        
        -- Hide all color pickers
        for _, picker in ipairs(Window._pickers) do
            if picker and picker.Parent then picker.Visible = false end
        end
        
        -- Shift + fade out
        local closeDuration = 0.35
        local closeStyle = Enum.EasingStyle.Quint
        
        Tween(Main, {
            Position = UDim2.new(0.5, 0, 0.5, shiftOffset),
            BackgroundTransparency = 1,
        }, closeDuration, closeStyle)
        
        for _, desc in ipairs(Main:GetDescendants()) do
            if desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                Tween(desc, { BackgroundTransparency = 1 }, closeDuration, closeStyle)
            elseif desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                Tween(desc, { BackgroundTransparency = 1, TextTransparency = 1 }, closeDuration, closeStyle)
            elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                Tween(desc, { BackgroundTransparency = 1, ImageTransparency = 1 }, closeDuration, closeStyle)
            elseif desc:IsA("UIStroke") then
                Tween(desc, { Transparency = 1 }, closeDuration, closeStyle)
            end
        end
        
        task.delay(closeDuration + 0.05, function()
            pcall(CleanupAll)
            if ScreenGui and ScreenGui.Parent then
                ScreenGui:Destroy()
            end
        end)
    end)
    
    -- Minimize Button
    local MinBtn = Create("TextButton", {
        Text = "─",
        Font = Theme.FontLight,
        TextSize = 12,
        TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -68, 0, 0),
        Parent = TitleBar,
    })
    
    local minimized = false
    local originalSize = size
    
    MinBtn.MouseEnter:Connect(function()
        Tween(MinBtn, { TextColor3 = Theme.Text }, 0.15)
    end)
    MinBtn.MouseLeave:Connect(function()
        Tween(MinBtn, { TextColor3 = Theme.TextDim }, 0.15)
    end)
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(Main, { Size = UDim2.new(0, size.X.Offset, 0, 36) }, 0.25)
            TitleDivider.Visible = false
            TitleBarMask.Visible = false
            SidebarTopMask.Visible = false
            -- Hide all color pickers
            for _, picker in ipairs(Window._pickers) do
                if picker and picker.Parent then picker.Visible = false end
            end
        else
            Tween(Main, { Size = originalSize }, 0.25)
            TitleDivider.Visible = true
            TitleBarMask.Visible = true
            SidebarTopMask.Visible = true
        end
    end)
    
    -- ── Dragging ──
    local dragging, dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if Window._destroyed then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
    
    -- ── Tab Bar (left sidebar) ──
    local Sidebar = Create("Frame", {
        Name = _randomName(),
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(0, 130, 1, -37),
        Position = UDim2.fromOffset(0, 37),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Main,
    })
    
    AddCorner(Sidebar, Theme.CornerLarge)
    
    -- Only round bottom-left; mask top corners
    SidebarTopMask = Create("Frame", {
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
    
    -- Right border
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
    
    local TabHolder = Create("ScrollingFrame", {
        Name = _randomName(),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -2, 1, -8),
        Position = UDim2.fromOffset(0, 4),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 0,
        BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = Sidebar,
    })
    AddPadding(TabHolder, 4, 4, 8, 9)
    AddListLayout(TabHolder, 2)
    
    -- ── Content Area ──
    local ContentArea = Create("Frame", {
        Name = _randomName(),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -131, 1, -37),
        Position = UDim2.fromOffset(131, 37),
        ClipsDescendants = true,
        Parent = Main,
    })
    
-- (Window, TrackConnection, CleanupAll declared above open animation section)
    
    -- Auto-rescale on viewport resize (e.g. device rotation)
    local _autoScaleEnabled = true
    local camera = game:GetService("Workspace").CurrentCamera
    if camera then
        TrackConnection(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if Window._destroyed then return end
            if _autoScaleEnabled then
                local newScale = GetAutoScale()
                Tween(UIScaleObj, { Scale = newScale }, 0.25)
            end
        end))
    end
    
    --- Set the UI scale (0.5 - 2.0). Disables auto-scaling.
    function Window:SetScale(scale)
        if self._destroyed then return end
        _autoScaleEnabled = false
        scale = math.clamp(scale, 0.5, 2)
        Tween(UIScaleObj, { Scale = scale }, 0.2)
    end
    
    --- Reset to automatic device-based scaling
    function Window:SetAutoScale()
        if self._destroyed then return end
        _autoScaleEnabled = true
        local newScale = GetAutoScale()
        Tween(UIScaleObj, { Scale = newScale }, 0.2)
    end
    
    --- Get current UI scale
    function Window:GetScale()
        return UIScaleObj.Scale
    end
    
    --- Register a flag (called internally by elements)
    function Window:_RegisterFlag(flag, element)
        if flag and flag ~= "" then
            self._flags[flag] = element
        end
    end

    --- Register a callback to run when the window is closed/destroyed
    function Window:OnClose(callback)
        if callback and typeof(callback) == "function" then
            table.insert(self._onCloseCallbacks, callback)
        end
    end

    --- Disable all toggle flags (set to false) and fire their callbacks
    function Window:DisableAll()
        for flag, element in pairs(self._flags) do
            local val = element:Get()
            if typeof(val) == "boolean" and val == true then
                element:Set(false)
                if element._callback then
                    task.spawn(element._callback, false)
                end
            end
        end
    end
    
    --- Set config name
    function Window:SetConfigName(name)
        self._configName = name or "default"
    end
    
    --- Get all flag values as a table
    function Window:GetFlagValues()
        local data = {}
        for flag, element in pairs(self._flags) do
            local value = element:Get()
            -- Serialize special types
            if typeof(value) == "Color3" then
                data[flag] = { _type = "Color3", R = math.floor(value.R * 255), G = math.floor(value.G * 255), B = math.floor(value.B * 255) }
            elseif typeof(value) == "EnumItem" then
                local enumTypeName = tostring(value.EnumType)
                -- tostring(Enum.KeyCode) returns "Enum.KeyCode"; strip the prefix
                if enumTypeName:sub(1, 5) == "Enum." then
                    enumTypeName = enumTypeName:sub(6)
                end
                data[flag] = { _type = "EnumItem", EnumType = enumTypeName, Name = value.Name }
            else
                data[flag] = value
            end
        end
        return data
    end
    
    --- Check if file system functions are available (exploit executors only)
    local function HasFileSystem()
        return typeof(rawget(_G, "writefile") or writefile) == "function"
            or (typeof(writefile) == "function")
    end

    --- Save config to file (exploit executors only)
    function Window:SaveConfig(name)
        if IsStudio then
            warn("[RockSide] Config saving is not available in Studio")
            return false
        end
        if not pcall(function() return writefile and readfile and isfile and isfolder and makefolder end) then
            warn("[RockSide] File system functions are not available in this environment")
            self:Notify({ Title = "Config Error", Content = "File system not available in this environment.", Duration = 4 })
            return false
        end
        name = name or self._configName
        local folder = self._configFolder
        
        local success, err = pcall(function()
            if not isfolder(folder) then
                makefolder(folder)
            end
            local data = self:GetFlagValues()
            local json = HttpService:JSONEncode(data)
            writefile(folder .. "/" .. name .. ".json", json)
        end)
        
        if success then
            self:Notify({ Title = "Config Saved", Content = 'Saved as "' .. name .. '"', Duration = 3 })
        else
            warn("[RockSide] Failed to save config:", err)
            self:Notify({ Title = "Save Failed", Content = tostring(err), Duration = 4 })
        end
        return success
    end
    
    --- Load config from file (exploit executors only)
    function Window:LoadConfig(name)
        if IsStudio then
            warn("[RockSide] Config loading is not available in Studio")
            return false
        end
        if not pcall(function() return readfile and isfile and isfolder end) then
            warn("[RockSide] File system functions are not available in this environment")
            self:Notify({ Title = "Config Error", Content = "File system not available in this environment.", Duration = 4 })
            return false
        end
        name = name or self._configName
        local folder = self._configFolder
        local filePath = folder .. "/" .. name .. ".json"
        
        local success, err = pcall(function()
            if not isfile(filePath) then
                error('Config file not found: "' .. name .. '". Save a config first.')
            end
            local json = readfile(filePath)
            local data = HttpService:JSONDecode(json)
            
            for flag, value in pairs(data) do
                local element = self._flags[flag]
                if element then
                    -- Deserialize special types
                    if type(value) == "table" and value._type == "Color3" then
                        element:Set(Color3.fromRGB(value.R, value.G, value.B))
                    elseif type(value) == "table" and value._type == "EnumItem" then
                        local enumTypeStr = value.EnumType
                        -- Handle both "KeyCode" and legacy "Enum.KeyCode" format
                        if type(enumTypeStr) == "string" and enumTypeStr:sub(1, 5) == "Enum." then
                            enumTypeStr = enumTypeStr:sub(6)
                        end
                        local enumType = Enum[enumTypeStr]
                        if enumType then
                            element:Set(enumType[value.Name])
                        end
                    else
                        element:Set(value)
                    end
                    -- Fire callback if element has one
                    if element._callback then
                        task.spawn(element._callback, element:Get())
                    end
                end
            end
        end)
        
        if success then
            self:Notify({ Title = "Config Loaded", Content = 'Loaded "' .. name .. '"', Duration = 3 })
        else
            warn("[RockSide] Failed to load config:", err)
            self:Notify({ Title = "Load Failed", Content = tostring(err), Duration = 4 })
        end
        return success
    end
    
    --- List available config files
    function Window:GetConfigs()
        if IsStudio then return {} end
        local configs = {}
        local folder = self._configFolder
        local success = pcall(function()
            if isfolder(folder) then
                for _, file in ipairs(listfiles(folder)) do
                    local name = file:match("([^/\\]+)%.json$")
                    if name then
                        table.insert(configs, name)
                    end
                end
            end
        end)
        return configs
    end
    
    --- Delete a config file
    function Window:DeleteConfig(name)
        if IsStudio then return false end
        if not pcall(function() return isfile and delfile end) then
            warn("[RockSide] File system functions are not available in this environment")
            self:Notify({ Title = "Config Error", Content = "File system not available in this environment.", Duration = 4 })
            return false
        end
        name = name or self._configName
        local filePath = self._configFolder .. "/" .. name .. ".json"
        local success, err = pcall(function()
            if isfile(filePath) then
                delfile(filePath)
                self:Notify({ Title = "Config Deleted", Content = 'Deleted "' .. name .. '"', Duration = 3 })
            else
                self:Notify({ Title = "Not Found", Content = 'Config "' .. name .. '" does not exist.', Duration = 3 })
            end
        end)
        if not success then
            warn("[RockSide] Failed to delete config:", err)
            self:Notify({ Title = "Delete Failed", Content = tostring(err), Duration = 4 })
        end
        return success
    end
    
    -- ── Tab System ──
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabTitle = tabConfig.Title or "Tab"
        local tabIcon = tabConfig.Icon or nil
        
        -- Tab button in sidebar
        local TabButton = Create("TextButton", {
            Name = _randomName(),
            Text = "",
            BackgroundColor3 = Theme.SurfaceAlt,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            ClipsDescendants = true,
            AutoButtonColor = false,
            Parent = TabHolder,
        })
        AddCorner(TabButton, Theme.CornerSmall)
        
        -- Accent bar (visible when active)
        local AccentBar = Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            Size = UDim2.new(0, 2, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundTransparency = 1,
            Parent = TabButton,
        })
        AddCorner(AccentBar, UDim.new(1, 0))
        
        local TabLabel = Create("TextLabel", {
            Text = tabTitle,
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.TextDim,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.fromOffset(10, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = TabButton,
        })
        
        -- Content page for this tab
        local TabPage = Create("ScrollingFrame", {
            Name = _randomName(),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Border,
            BorderSizePixel = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ClipsDescendants = true,
            Parent = ContentArea,
        })
        AddPadding(TabPage, 10, 10, 10, 10)
        AddListLayout(TabPage, 6)
        
        local tabData = { Button = TabButton, Page = TabPage, Label = TabLabel, AccentBar = AccentBar }
        table.insert(self.Tabs, tabData)
        
        -- Set first tab active
        local function ActivateTab()
            for _, t in ipairs(self.Tabs) do
                t.Page.Visible = false
                Tween(t.Label, { TextColor3 = Theme.TextDim }, 0.15)
                Tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
                Tween(t.AccentBar, { BackgroundTransparency = 1 }, 0.15)
            end
            tabData.Page.Visible = true
            Tween(tabData.Label, { TextColor3 = Theme.Text }, 0.15)
            Tween(tabData.Button, { BackgroundTransparency = 0.85 }, 0.15)
            Tween(tabData.AccentBar, { BackgroundTransparency = 0 }, 0.15)
            self.ActiveTab = tabData
        end
        
        TabButton.MouseEnter:Connect(function()
            if self.ActiveTab ~= tabData then
                Tween(TabButton, { BackgroundTransparency = 0.9 }, 0.12)
                Tween(TabLabel, { TextColor3 = Theme.Text }, 0.12)
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if self.ActiveTab ~= tabData then
                Tween(TabButton, { BackgroundTransparency = 1 }, 0.12)
                Tween(TabLabel, { TextColor3 = Theme.TextDim }, 0.12)
            end
        end)
        TabButton.MouseButton1Click:Connect(ActivateTab)
        
        if #self.Tabs == 1 then
            ActivateTab()
        end
        
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Tab Element Builders
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        local Tab = {}
        
        -- Helper: create element container
        local function ElementCard(height)
            local card = Create("Frame", {
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(1, 0, 0, height or 36),
                ClipsDescendants = true,
                Parent = TabPage,
            })
            AddCorner(card, Theme.CornerRadius)
            AddStroke(card, Theme.Border, 1)
            return card
        end
        
        -- ── Section Header ──
        function Tab:CreateSection(cfg)
            cfg = cfg or {}
            local section = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                Parent = TabPage,
            })
            Create("TextLabel", {
                Text = (cfg.Title or "Section"):upper(),
                Font = Theme.FontBold,
                TextSize = 10,
                TextColor3 = Theme.TextMuted,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.fromOffset(2, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section,
            })
            return section
        end
        
        -- ── Label ──
        function Tab:CreateLabel(cfg)
            cfg = cfg or {}
            local card = ElementCard(30)
            AddPadding(card, 0, 0, 10, 10)
            
            local label = Create("TextLabel", {
                Text = cfg.Title or "Label",
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.TextDim,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            
            local obj = {}
            function obj:Set(text)
                label.Text = text
            end
            return obj
        end
        
        -- ── Paragraph ──
        function Tab:CreateParagraph(cfg)
            cfg = cfg or {}
            local card = ElementCard(0)
            card.AutomaticSize = Enum.AutomaticSize.Y
            AddPadding(card, 10, 10, 12, 12)
            
            local layout = AddListLayout(card, 4)
            
            Create("TextLabel", {
                Text = cfg.Title or "Title",
                Font = Theme.FontBold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            
            local contentLabel = Create("TextLabel", {
                Text = cfg.Content or "",
                Font = Theme.FontLight,
                TextSize = 12,
                TextColor3 = Theme.TextDim,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Parent = card,
            })
            
            local obj = {}
            function obj:Set(title, content)
                if title then card:FindFirstChild("TextLabel").Text = title end
                if content then contentLabel.Text = content end
            end
            return obj
        end
        
        -- ── Button ──
        function Tab:CreateButton(cfg)
            cfg = cfg or {}
            local card = ElementCard(36)
            
            local btn = Create("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ClipsDescendants = true,
                AutoButtonColor = false,
                Parent = card,
            })
            
            Create("TextLabel", {
                Text = cfg.Title or "Button",
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.fromOffset(12, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = btn,
            })
            
            -- Arrow indicator
            Create("ImageLabel", {
                Image = "rbxassetid://116535928766178",
                ImageColor3 = Theme.TextMuted,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.new(1, -24, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Rotation = -90,
                ScaleType = Enum.ScaleType.Fit,
                Parent = btn,
            })
            
            btn.MouseEnter:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.12)
            end)
            btn.MouseLeave:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.Card }, 0.12)
            end)
            btn.MouseButton1Click:Connect(function()
                if Window._destroyed then return end
                Ripple(btn, Vector2.new(Mouse.X, Mouse.Y))
                if cfg.Callback then
                    task.spawn(cfg.Callback)
                end
            end)
        end
        
        -- ── Toggle ──
        function Tab:CreateToggle(cfg)
            cfg = cfg or {}
            local state = cfg.Default or false
            local card = ElementCard(36)
            AddPadding(card, 0, 0, 12, 10)
            
            Create("TextLabel", {
                Text = cfg.Title or "Toggle",
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -50, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            
            -- Toggle track
            local track = Create("Frame", {
                BackgroundColor3 = state and Theme.Toggle_On or Theme.Toggle_Off,
                Size = UDim2.fromOffset(34, 18),
                Position = UDim2.new(1, -5, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                ClipsDescendants = true,
                Parent = card,
            })
            AddCorner(track, Theme.CornerPill)
            
            -- Toggle knob (oval)
            local knob = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.fromOffset(16, 12),
                Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Parent = track,
            })
            AddCorner(knob, UDim.new(1, 0))
            
            local btn = Create("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = card,
            })
            
            local function UpdateToggle()
                Tween(track, { BackgroundColor3 = state and Theme.Toggle_On or Theme.Toggle_Off }, 0.2)
                Tween(knob, { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.2)
            end
            
            local function DoToggle()
                if Window._destroyed then return end
                state = not state
                UpdateToggle()
                if cfg.Callback then
                    task.spawn(cfg.Callback, state)
                end
            end
            
            btn.MouseButton1Click:Connect(DoToggle)
            
            -- HoldKey: bind a keyboard key to toggle this on/off
            if cfg.HoldKey then
                TrackConnection(UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if Window._destroyed then return end
                    if input.KeyCode == cfg.HoldKey or input.UserInputType == cfg.HoldKey then
                        DoToggle()
                    end
                end))
            end
            
            btn.MouseEnter:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.12)
            end)
            btn.MouseLeave:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.Card }, 0.12)
            end)
            
            local obj = {}
            obj._callback = cfg.Callback
            function obj:Set(val)
                state = val
                UpdateToggle()
            end
            function obj:Get()
                return state
            end
            if cfg.Flag then Window:_RegisterFlag(cfg.Flag, obj) end
            return obj
        end
        
        -- ── Slider ──
        function Tab:CreateSlider(cfg)
            cfg = cfg or {}
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local value = cfg.Default or min
            local suffix = cfg.Suffix or ""
            local increment = cfg.Increment or 1
            
            local card = ElementCard(52)
            AddPadding(card, 0, 0, 12, 12)
            
            Create("TextLabel", {
                Text = cfg.Title or "Slider",
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 0, 20),
                Position = UDim2.fromOffset(0, 6),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            
            local valueLabel = Create("TextLabel", {
                Text = tostring(value) .. suffix,
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 0, 20),
                Position = UDim2.new(0.5, 0, 0, 6),
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = card,
            })
            
            -- Slider bar
            local sliderBar = Create("Frame", {
                BackgroundColor3 = Theme.SliderBar,
                Size = UDim2.new(1, 0, 0, 4),
                Position = UDim2.new(0, 0, 1, -14),
                ClipsDescendants = true,
                Active = true,
                Parent = card,
            })
            AddCorner(sliderBar, UDim.new(1, 0))
            
            local pct = (value - min) / (max - min)
            local fill = Create("Frame", {
                BackgroundColor3 = Theme.SliderFill,
                Size = UDim2.new(pct, 0, 1, 0),
                Parent = sliderBar,
            })
            AddCorner(fill, UDim.new(1, 0))
            
            -- Knob (parented to card so ClipsDescendants on sliderBar doesn't clip it)
            local sliderKnob = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.fromOffset(16, 12),
                Position = UDim2.new(pct, 0, 1, -12),
                AnchorPoint = Vector2.new(0.5, 0.5),
                ZIndex = 3,
                Active = true,
                Parent = card,
            })
            AddCorner(sliderKnob, UDim.new(1, 0))
            
            -- Inner highlight for depth
            Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(240, 240, 240),
                Size = UDim2.fromOffset(6, 6),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Parent = sliderKnob,
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            
            local sliding = false
            
            local function UpdateSlider(input)
                local pos = math.clamp(
                    (input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X,
                    0, 1
                )
                -- Snap to increment
                local rawVal = min + (max - min) * pos
                if increment < 1 then
                    value = math.floor(rawVal / increment + 0.5) * increment
                else
                    value = math.floor(rawVal / increment + 0.5) * increment
                end
                value = math.clamp(value, min, max)
                local newPct = (value - min) / (max - min)
                
                fill.Size = UDim2.new(newPct, 0, 1, 0)
                sliderKnob.Position = UDim2.new(newPct, 0, 1, -12)
                valueLabel.Text = tostring(value) .. suffix
                
                if cfg.Callback then
                    task.spawn(cfg.Callback, value)
                end
            end
            
            sliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    UpdateSlider(input)
                end
            end)
            
            sliderKnob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    UpdateSlider(input)
                end
            end)
            
            TrackConnection(UserInputService.InputChanged:Connect(function(input)
                if Window._destroyed then return end
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end))
            
            TrackConnection(UserInputService.InputEnded:Connect(function(input)
                if Window._destroyed then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end))
            
            card.MouseEnter:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.12)
            end)
            card.MouseLeave:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.Card }, 0.12)
            end)
            
            local obj = {}
            obj._callback = cfg.Callback
            function obj:Set(val)
                -- Snap to increment for consistency
                val = math.floor(val / increment + 0.5) * increment
                value = math.clamp(val, min, max)
                local p = (value - min) / (max - min)
                fill.Size = UDim2.new(p, 0, 1, 0)
                sliderKnob.Position = UDim2.new(p, 0, 1, -12)
                valueLabel.Text = tostring(value) .. suffix
            end
            function obj:Get()
                return value
            end
            if cfg.Flag then Window:_RegisterFlag(cfg.Flag, obj) end
            return obj
        end
        
        -- ── Dropdown ──
        function Tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local options = cfg.Options or {}
            local selected = cfg.Default or (options[1] or "")
            local opened = false
            local closedHeight = 36
            
            -- Card uses AutomaticSize so it expands inline
            local card = Create("Frame", {
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(1, 0, 0, closedHeight),
                ClipsDescendants = true,
                Parent = TabPage,
            })
            AddCorner(card, Theme.CornerRadius)
            AddStroke(card, Theme.Border, 1)
            
            -- Header area (always visible, fixed 36px)
            local header = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, closedHeight),
                Parent = card,
            })
            AddPadding(header, 0, 0, 12, 10)
            
            Create("TextLabel", {
                Text = cfg.Title or "Dropdown",
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = header,
            })
            
            local selectedLabel = Create("TextLabel", {
                Text = tostring(selected),
                Font = Theme.FontLight,
                TextSize = 11,
                TextColor3 = Theme.TextDim,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -20, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = header,
            })
            
            -- Chevron
            local chevron = Create("ImageLabel", {
                Image = "rbxassetid://116535928766178",
                ImageColor3 = Theme.TextMuted,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(12, 12),
                Position = UDim2.new(1, -6, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                Rotation = 0,
                ScaleType = Enum.ScaleType.Fit,
                Parent = header,
            })
            
            -- Options container (inside card, below header)
            local optionsHolder = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, closedHeight),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = card,
            })
            AddPadding(optionsHolder, 2, 6, 6, 6)
            AddListLayout(optionsHolder, 1)
            
            local function GetExpandedHeight()
                local count = math.min(#options, 5)
                return closedHeight + count * 28 + 10
            end
            
            local function CloseDropdown()
                if not opened then return end
                opened = false
                Tween(card, { Size = UDim2.new(1, 0, 0, closedHeight) }, 0.18)
                Tween(chevron, { Rotation = 0 }, 0.18)
            end
            
            local function OpenDropdown()
                if opened then return end
                opened = true
                local targetH = GetExpandedHeight()
                Tween(card, { Size = UDim2.new(1, 0, 0, targetH) }, 0.18)
                Tween(chevron, { Rotation = 180 }, 0.18)
                
                -- Auto-scroll the tab page simultaneously so the dropdown is visible
                local cardBottom = card.AbsolutePosition.Y + targetH
                local pageBottom = TabPage.AbsolutePosition.Y + TabPage.AbsoluteSize.Y
                if cardBottom > pageBottom then
                    local scrollOffset = TabPage.CanvasPosition.Y + (cardBottom - pageBottom) + 10
                    Tween(TabPage, { CanvasPosition = Vector2.new(0, scrollOffset) }, 0.18)
                end
            end
            
            local function BuildOptions()
                for _, child in ipairs(optionsHolder:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                
                for _, opt in ipairs(options) do
                    local optBtn = Create("TextButton", {
                        Text = tostring(opt),
                        Font = Theme.Font,
                        TextSize = 11,
                        TextColor3 = (opt == selected) and Theme.Accent or Theme.TextDim,
                        BackgroundColor3 = Theme.SurfaceAlt,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 26),
                        AutoButtonColor = false,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = optionsHolder,
                    })
                    AddCorner(optBtn, Theme.CornerSmall)
                    AddPadding(optBtn, 0, 0, 8, 8)
                    
                    optBtn.MouseEnter:Connect(function()
                        Tween(optBtn, { BackgroundTransparency = 0.6, TextColor3 = Theme.Text }, 0.1)
                    end)
                    optBtn.MouseLeave:Connect(function()
                        Tween(optBtn, {
                            BackgroundTransparency = 1,
                            TextColor3 = (opt == selected) and Theme.Accent or Theme.TextDim
                        }, 0.1)
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        selectedLabel.Text = tostring(opt)
                        CloseDropdown()
                        BuildOptions()
                        if cfg.Callback then
                            task.spawn(cfg.Callback, selected)
                        end
                    end)
                end
                
                -- Update expanded size if already open
                if opened then
                    local targetH = GetExpandedHeight()
                    Tween(card, { Size = UDim2.new(1, 0, 0, targetH) }, 0.18)
                end
            end
            BuildOptions()
            
            -- Toggle dropdown on header click
            local mainBtn = Create("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, closedHeight),
                ZIndex = 2,
                Parent = card,
            })
            
            mainBtn.MouseButton1Click:Connect(function()
                if opened then
                    CloseDropdown()
                else
                    OpenDropdown()
                end
            end)
            
            mainBtn.MouseEnter:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.12)
            end)
            mainBtn.MouseLeave:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.Card }, 0.12)
            end)
            
            local obj = {}
            obj._callback = cfg.Callback
            function obj:Set(val)
                selected = val
                selectedLabel.Text = tostring(val)
                BuildOptions()
            end
            function obj:SetOptions(newOpts)
                options = newOpts
                BuildOptions()
            end
            function obj:Get()
                return selected
            end
            if cfg.Flag then Window:_RegisterFlag(cfg.Flag, obj) end
            return obj
        end
        
        -- ── TextInput ──
        function Tab:CreateInput(cfg)
            cfg = cfg or {}
            local card = ElementCard(36)
            AddPadding(card, 0, 0, 12, 8)
            
            Create("TextLabel", {
                Text = cfg.Title or "Input",
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.45, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            
            local inputBox = Create("Frame", {
                BackgroundColor3 = Theme.InputBg,
                Size = UDim2.new(0.5, 0, 0, 24),
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                ClipsDescendants = true,
                Parent = card,
            })
            AddCorner(inputBox, Theme.CornerSmall)
            AddStroke(inputBox, Theme.Border, 1)
            
            local textBox = Create("TextBox", {
                Text = cfg.Default or "",
                PlaceholderText = cfg.Placeholder or "...",
                PlaceholderColor3 = Theme.TextMuted,
                Font = Theme.FontLight,
                TextSize = 11,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -12, 1, 0),
                Position = UDim2.fromOffset(6, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = cfg.ClearOnFocus or false,
                ClipsDescendants = true,
                Parent = inputBox,
            })
            
            local inputStroke = inputBox:FindFirstChildOfClass("UIStroke")
            
            textBox.Focused:Connect(function()
                Tween(inputStroke, { Color = Theme.Accent }, 0.15)
            end)
            textBox.FocusLost:Connect(function(enterPressed)
                Tween(inputStroke, { Color = Theme.Border }, 0.15)
                if enterPressed and cfg.Callback then
                    task.spawn(cfg.Callback, textBox.Text)
                end
            end)
            
            card.MouseEnter:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.12)
            end)
            card.MouseLeave:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.Card }, 0.12)
            end)
            
            local obj = {}
            obj._callback = cfg.Callback
            function obj:Set(val)
                textBox.Text = val
            end
            function obj:Get()
                return textBox.Text
            end
            if cfg.Flag then Window:_RegisterFlag(cfg.Flag, obj) end
            return obj
        end
        
        -- ── Keybind ──
        function Tab:CreateKeybind(cfg)
            cfg = cfg or {}
            local key = cfg.Default or Enum.KeyCode.Unknown
            local listening = false
            
            local card = ElementCard(36)
            AddPadding(card, 0, 0, 12, 8)
            
            Create("TextLabel", {
                Text = cfg.Title or "Keybind",
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            
            local keyBox = Create("Frame", {
                BackgroundColor3 = Theme.InputBg,
                Size = UDim2.new(0, 70, 0, 22),
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                ClipsDescendants = true,
                Parent = card,
            })
            AddCorner(keyBox, Theme.CornerSmall)
            AddStroke(keyBox, Theme.Border, 1)
            
            local keyLabel = Create("TextLabel", {
                Text = key.Name or "None",
                Font = Theme.Font,
                TextSize = 10,
                TextColor3 = Theme.TextDim,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = keyBox,
            })
            
            local keyBtn = Create("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = card,
            })
            
            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyLabel.Text = "..."
                Tween(keyBox:FindFirstChildOfClass("UIStroke"), { Color = Theme.Accent }, 0.15)
            end)
            
            TrackConnection(UserInputService.InputBegan:Connect(function(input, processed)
                if Window._destroyed then return end
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Backspace then
                            -- Unbind the key
                            key = Enum.KeyCode.Unknown
                            keyLabel.Text = "None"
                        else
                            key = input.KeyCode
                            keyLabel.Text = key.Name
                        end
                        listening = false
                        Tween(keyBox:FindFirstChildOfClass("UIStroke"), { Color = Theme.Border }, 0.15)
                    end
                elseif not processed and key ~= Enum.KeyCode.Unknown and input.KeyCode == key then
                    if cfg.Callback then
                        task.spawn(cfg.Callback)
                    end
                end
            end))
            
            card.MouseEnter:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.12)
            end)
            card.MouseLeave:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.Card }, 0.12)
            end)
            
            local obj = {}
            obj._callback = cfg.Callback
            function obj:Set(newKey)
                key = newKey
                keyLabel.Text = (key == Enum.KeyCode.Unknown) and "None" or key.Name
            end
            function obj:Get()
                return key
            end
            if cfg.Flag then Window:_RegisterFlag(cfg.Flag, obj) end
            return obj
        end
        
        -- ── Color Picker ──
        function Tab:CreateColorPicker(cfg)
            cfg = cfg or {}
            local color = cfg.Default or Color3.fromRGB(138, 43, 226)
            local h, s, v = color:ToHSV()
            local pickerOpen = false
            
            local card = ElementCard(36)
            AddPadding(card, 0, 0, 12, 10)
            
            Create("TextLabel", {
                Text = cfg.Title or "Color",
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            
            local preview = Create("Frame", {
                BackgroundColor3 = color,
                Size = UDim2.fromOffset(24, 18),
                Position = UDim2.new(1, -2, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                Parent = card,
            })
            AddCorner(preview, Theme.CornerSmall)
            AddStroke(preview, Theme.Border, 1)
            
            -- Picker Panel (parented to ScreenGui, positioned to the right of Main)
            local pickerPanel = Create("Frame", {
                BackgroundColor3 = Theme.Surface,
                Size = UDim2.fromOffset(200, 170),
                Visible = false,
                ZIndex = 60,
                ClipsDescendants = true,
                Parent = ScreenGui,
            })
            AddCorner(pickerPanel, Theme.CornerRadius)
            AddStroke(pickerPanel, Theme.Border, 1)
            AddPadding(pickerPanel, 8, 8, 8, 8)
            table.insert(Window._pickers, pickerPanel)
            
            -- Forward-declare color picking flags
            local pickingSV = false
            local pickingH = false
            
            -- Picker dragging (only when not picking color)
            local pickerDragging, pickerDragStart, pickerStartPos
            pickerPanel.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    -- Defer slightly so pickingSV/pickingH can be set first
                    task.defer(function()
                        if not pickingSV and not pickingH then
                            pickerDragging = true
                            pickerDragStart = input.Position
                            pickerStartPos = pickerPanel.Position
                        end
                    end)
                end
            end)
            pickerPanel.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    pickerDragging = false
                end
            end)
            TrackConnection(UserInputService.InputChanged:Connect(function(input)
                if Window._destroyed then return end
                if pickerDragging and not pickingSV and not pickingH and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local delta = input.Position - pickerDragStart
                    pickerPanel.Position = UDim2.new(
                        pickerStartPos.X.Scale, pickerStartPos.X.Offset + delta.X,
                        pickerStartPos.Y.Scale, pickerStartPos.Y.Offset + delta.Y
                    )
                end
            end))
            
            -- SV Field (saturation-value)
            local svField = Create("Frame", {
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                Size = UDim2.new(1, -24, 0, 120),
                Position = UDim2.fromOffset(0, 0),
                ClipsDescendants = true,
                ZIndex = 61,
                Parent = pickerPanel,
            })
            AddCorner(svField, Theme.CornerSmall)
            
            -- White gradient overlay (saturation)
            local whiteGrad = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 62,
                Parent = svField,
            })
            Create("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = whiteGrad,
            })
            AddCorner(whiteGrad, Theme.CornerSmall)
            
            -- Black gradient overlay (value)
            local blackGrad = Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 63,
                Parent = svField,
            })
            Create("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Rotation = 90,
                Parent = blackGrad,
            })
            AddCorner(blackGrad, Theme.CornerSmall)
            
            -- SV cursor
            local svCursor = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Size = UDim2.fromOffset(8, 8),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(s, 0, 1 - v, 0),
                ZIndex = 65,
                Parent = svField,
            })
            AddCorner(svCursor, UDim.new(1, 0))
            AddStroke(svCursor, Color3.new(0, 0, 0), 1)
            
            -- Hue Bar
            local hueBar = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(0, 12, 0, 120),
                Position = UDim2.new(1, 0, 0, 0),
                AnchorPoint = Vector2.new(1, 0),
                ClipsDescendants = true,
                ZIndex = 61,
                Parent = pickerPanel,
            })
            AddCorner(hueBar, Theme.CornerSmall)
            
            -- Hue gradient
            Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.000, Color3.fromHSV(0, 1, 1)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                    ColorSequenceKeypoint.new(0.500, Color3.fromHSV(0.5, 1, 1)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                    ColorSequenceKeypoint.new(1.000, Color3.fromHSV(1, 1, 1)),
                }),
                Rotation = 90,
                Parent = hueBar,
            })
            
            -- Hue cursor
            local hueCursor = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(1, 4, 0, 4),
                Position = UDim2.new(0.5, 0, h, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                ZIndex = 62,
                Parent = hueBar,
            })
            AddCorner(hueCursor, UDim.new(1, 0))
            AddStroke(hueCursor, Color3.new(0, 0, 0), 1)
            
            -- Hex display
            local hexLabel = Create("TextLabel", {
                Text = "#" .. color:ToHex():upper(),
                Font = Theme.Font,
                TextSize = 10,
                TextColor3 = Theme.TextDim,
                BackgroundColor3 = Theme.InputBg,
                Size = UDim2.new(1, -24, 0, 22),
                Position = UDim2.new(0, 0, 1, -22),
                ZIndex = 61,
                Parent = pickerPanel,
            })
            AddCorner(hexLabel, Theme.CornerSmall)
            
            local function UpdateColor()
                color = Color3.fromHSV(h, s, v)
                preview.BackgroundColor3 = color
                svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                hueCursor.Position = UDim2.new(0.5, 0, h, 0)
                hexLabel.Text = "#" .. color:ToHex():upper()
                if cfg.Callback then
                    task.spawn(cfg.Callback, color)
                end
            end
            
            -- SV interaction
            svField.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    pickingSV = true
                    s = math.clamp((input.Position.X - svField.AbsolutePosition.X) / svField.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((input.Position.Y - svField.AbsolutePosition.Y) / svField.AbsoluteSize.Y, 0, 1)
                    UpdateColor()
                end
            end)
            
            -- Hue interaction
            hueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    pickingH = true
                    h = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                    UpdateColor()
                end
            end)
            
            TrackConnection(UserInputService.InputChanged:Connect(function(input)
                if Window._destroyed then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    if pickingSV then
                        s = math.clamp((input.Position.X - svField.AbsolutePosition.X) / svField.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((input.Position.Y - svField.AbsolutePosition.Y) / svField.AbsoluteSize.Y, 0, 1)
                        UpdateColor()
                    end
                    if pickingH then
                        h = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                        UpdateColor()
                    end
                end
            end))
            
            TrackConnection(UserInputService.InputEnded:Connect(function(input)
                if Window._destroyed then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    pickingSV = false
                    pickingH = false
                end
            end))
            
            -- Toggle picker
            local colorBtn = Create("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 2,
                Parent = card,
            })
            
            local pickerFading = false
            colorBtn.MouseButton1Click:Connect(function()
                if pickerFading then return end
                pickerOpen = not pickerOpen
                if pickerOpen then
                    -- Position picker to the right of Main frame, vertically centered
                    local mainPos = Main.AbsolutePosition
                    local mainSize = Main.AbsoluteSize
                    local x = mainPos.X + mainSize.X + 12
                    local y = mainPos.Y + (mainSize.Y - 170) / 2
                    pickerPanel.Position = UDim2.fromOffset(x, y)
                    
                    -- Fade in
                    pickerPanel.Visible = true
                    pickerPanel.BackgroundTransparency = 1
                    Tween(pickerPanel, { BackgroundTransparency = 0 }, 0.2)
                    local pickerStroke = pickerPanel:FindFirstChildOfClass("UIStroke")
                    if pickerStroke then
                        pickerStroke.Transparency = 1
                        Tween(pickerStroke, { Transparency = 0 }, 0.2)
                    end
                    for _, desc in ipairs(pickerPanel:GetDescendants()) do
                        if desc:IsA("Frame") then
                            desc.BackgroundTransparency = 1
                            Tween(desc, { BackgroundTransparency = 0 }, 0.2)
                        elseif desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                            desc.BackgroundTransparency = 1
                            desc.TextTransparency = 1
                            Tween(desc, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.2)
                        elseif desc:IsA("UIStroke") then
                            desc.Transparency = 1
                            Tween(desc, { Transparency = 0 }, 0.2)
                        elseif desc:IsA("UIGradient") then
                            -- skip, gradients don't have transparency
                        end
                    end
                else
                    -- Fade out
                    pickerFading = true
                    Tween(pickerPanel, { BackgroundTransparency = 1 }, 0.2)
                    local pickerStroke = pickerPanel:FindFirstChildOfClass("UIStroke")
                    if pickerStroke then
                        Tween(pickerStroke, { Transparency = 1 }, 0.2)
                    end
                    for _, desc in ipairs(pickerPanel:GetDescendants()) do
                        if desc:IsA("Frame") then
                            Tween(desc, { BackgroundTransparency = 1 }, 0.2)
                        elseif desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                            Tween(desc, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.2)
                        elseif desc:IsA("UIStroke") then
                            Tween(desc, { Transparency = 1 }, 0.2)
                        end
                    end
                    task.delay(0.22, function()
                        pickerPanel.Visible = false
                        pickerFading = false
                    end)
                end
            end)
            
            card.MouseEnter:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.12)
            end)
            card.MouseLeave:Connect(function()
                Tween(card, { BackgroundColor3 = Theme.Card }, 0.12)
            end)
            
            -- Clean up picker when card is destroyed
            card.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    pickerPanel:Destroy()
                end
            end)
            
            local obj = {}
            obj._callback = cfg.Callback
            function obj:Set(newColor)
                color = newColor
                h, s, v = color:ToHSV()
                UpdateColor()
            end
            function obj:Get()
                return color
            end
            if cfg.Flag then Window:_RegisterFlag(cfg.Flag, obj) end
            return obj
        end
        
        -- ── Notification ──
        function Tab:CreateNotification(cfg)
            -- Notifications are window-level, but accessible from tab for convenience
            Window:Notify(cfg)
        end
        
        return Tab
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- Notifications
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    local notifHolder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 260, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0.5, -130, 0, 10),
        ClipsDescendants = false,
        Parent = ScreenGui,
    })
    AddListLayout(notifHolder, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)
    
    function Window:Notify(cfg)
        if Window._destroyed then return end
        cfg = cfg or {}
        local notifTitle = cfg.Title or "Notification"
        local notifContent = cfg.Content or ""
        local duration = cfg.Duration or 3
        
        local notif = Create("Frame", {
            BackgroundColor3 = Theme.Surface,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ClipsDescendants = true,
            Parent = notifHolder,
        })
        AddCorner(notif, Theme.CornerRadius)
        AddStroke(notif, Theme.Border, 1)
        AddPadding(notif, 10, 10, 12, 12)
        
        local notifLayout = AddListLayout(notif, 2)
        
        Create("TextLabel", {
            Text = notifTitle,
            Font = Theme.FontBold,
            TextSize = 12,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
            Parent = notif,
        })
        
        if notifContent ~= "" then
            Create("TextLabel", {
                Text = notifContent,
                Font = Theme.FontLight,
                TextSize = 11,
                TextColor3 = Theme.TextDim,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 1,
                Parent = notif,
            })
        end
        
        -- Slide in from top
        notif.Position = UDim2.new(0, 0, 0, -60)
        notif.BackgroundTransparency = 1
        local notifStroke = notif:FindFirstChildOfClass("UIStroke")
        if notifStroke then notifStroke.Transparency = 1 end
        Tween(notif, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.3)
        if notifStroke then Tween(notifStroke, { Transparency = 0 }, 0.3) end
        -- Fade in text children
        for _, child in ipairs(notif:GetChildren()) do
            if child:IsA("TextLabel") then
                child.TextTransparency = 1
                Tween(child, { TextTransparency = 0 }, 0.3)
            end
        end
        
        task.delay(duration, function()
            if Window._destroyed then
                pcall(function() notif:Destroy() end)
                return
            end
            Tween(notif, { Position = UDim2.new(0, 0, 0, -60), BackgroundTransparency = 1 }, 0.25)
            local nStroke = notif:FindFirstChildOfClass("UIStroke")
            if nStroke then Tween(nStroke, { Transparency = 1 }, 0.25) end
            for _, child in ipairs(notif:GetChildren()) do
                if child:IsA("TextLabel") then
                    Tween(child, { TextTransparency = 1 }, 0.25)
                end
            end
            task.delay(0.3, function()
                pcall(function() notif:Destroy() end)
            end)
        end)
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- Toggle UI Keybind
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    
    TrackConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if Window._destroyed then return end
        if input.KeyCode == toggleKey then
            local vis = not Main.Visible
            Main.Visible = vis
            notifHolder.Visible = vis
            -- Hide all color pickers when hiding UI
            if not vis then
                for _, picker in ipairs(Window._pickers) do
                    if picker and picker.Parent then picker.Visible = false end
                end
            end
        end
    end))
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- Destroy Method
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    function Window:Destroy()
        -- Disable all active toggles and fire callbacks
        Window:DisableAll()

        -- Fire OnClose callbacks
        for _, cb in ipairs(Window._onCloseCallbacks) do
            task.spawn(cb)
        end

        CleanupAll()
        -- Clear stored GUI reference
        rawset(shared, "__rs_libgui_ref", nil)
        -- Destroy any remaining notifications
        pcall(function()
            for _, child in ipairs(notifHolder:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
        end)
        ScreenGui:Destroy()
    end

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- Periodic Key Re-validation
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    if not IsStudio then
        task.spawn(function()
            while true do
                -- Random interval (75-120s) to prevent pattern detection
                task.wait(math.random(75, 120))
                if Window._destroyed then break end

                -- Verify auth token integrity
                local authOk, authData = _verifyAuth()
                if not authOk then
                    _securityKick("Session expired. Please restart with a valid key.")
                    break
                end

                -- Server-side re-check (authoritative)
                local valid = _serverValidate(authData.k, authData.s, authData.h)
                if not valid then
                    _securityKick("Key revoked or expired. Please obtain a new key.")
                    break
                end
            end
        end)
    end
    
    return Window
end

return Library
