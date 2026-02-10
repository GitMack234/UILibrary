--[[
    DarkKeySystem — Key Verification UI
    Matches the RockSide visual style.
    Integrated with Panda Development V3 Key System (Pelinda).
    V3 Library is auto-injected via Virtual Storage — all encryption handled automatically.
    
    Usage:
        local KeySystem = require(path.to.DarkKeySystem)
        
        -- ══ Panda Development V3 Mode (recommended) ══
        -- V3 library (Pelinda) must be injected via Virtual Storage.
        -- Service ID is auto-configured during VSS upload.
        KeySystem:Show({
            Title = "RockSide",
            Subtitle = "Key Verification",
            Note = "Enter your key or click Get Key to obtain one.",
            
            PremiumOnly = false,      -- Set true to require premium keys
            
            SaveKey = true,
            SaveFolder = "RockSide",
            
            Callback = function(keyData)
                -- keyData = { isPremium, expireDate, permissions } from V3
                print("Authenticated! Premium:", keyData.isPremium)
            end,
        })
        
        -- ══ Legacy / Offline Mode ══
        KeySystem:Show({
            Title = "My Script",
            Subtitle = "Key System",
            Keys = { "ABCD-1234-EFGH" },
            -- OR: Validator = function(key) return key == "secret" end,
            Callback = function() end,
        })
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local IsStudio = RunService:IsStudio()

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Theme (matched to RockSide)
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
    AccentDim       = Color3.fromRGB(108, 33, 186),
    Text            = Color3.fromRGB(225, 225, 225),
    TextDim         = Color3.fromRGB(140, 140, 140),
    TextMuted       = Color3.fromRGB(80, 80, 80),
    InputBg         = Color3.fromRGB(16, 16, 16),
    Danger          = Color3.fromRGB(220, 50, 50),
    DangerDim       = Color3.fromRGB(180, 40, 40),
    Success         = Color3.fromRGB(50, 200, 80),
    SuccessDim      = Color3.fromRGB(40, 160, 64),
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
    -- gethui() provides a hidden container not scannable by GetChildren/GetDescendants
    if gethui then
        local ok, container = pcall(gethui)
        if ok and container then return container end
    end
    -- Fallback: CoreGui with cloneref to avoid reference detection
    local ok, core = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    if ok and core then return core end
    -- Last resort
    return Player.PlayerGui
end

--- Protect a ScreenGui from anti-cheat scanning
local function _protectGui(gui)
    -- sethiddenproperty makes the GUI invisible to GetChildren/GetDescendants scans
    if sethiddenproperty then
        pcall(sethiddenproperty, gui, "OnTopOfCoreBlur", true)
    end
    -- Synapse-specific protection
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
    -- Fluxus / Script-Ware style protection
    if protect_gui then
        pcall(protect_gui, gui)
    end
end

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
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function Ripple(parent, pos)
    local circle = Create("Frame", {
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
-- Panda Development V3 Key System (Pelinda)
-- V3 Library is auto-injected via Virtual Storage.
-- All encryption & validation handled by Pelinda.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Validate a key via V3 Pelinda.Init()
--- @param key string|nil - The license key (nil for keyless)
--- @param silent boolean - Silent mode
--- @return table { success, message, isPremium, expireDate, permissions }
local function V3Validate(key, silent)
    local initArgs = { Silent = silent or false }
    if key and key ~= "" then
        initArgs.Key = key
    end

    local ok, result = pcall(Pelinda.Init, initArgs)
    if not ok or not result then
        return {
            success = false,
            message = "Failed to connect to key server. Check your connection.",
            isPremium = false,
            expireDate = nil,
        }
    end

    return {
        success = result.Success,
        message = result.Note or (result.Success and "Key validated!" or "Invalid key"),
        isPremium = result.Premium or false,
        expireDate = result.Expires,
        permissions = result.Permissions,
    }
end

--- Get the key page URL via V3 Pelinda.GetKeyLink()
--- @return string - The full GetKey URL
local function V3GetKeyURL()
    local ok, url = pcall(Pelinda.GetKeyLink)
    if ok and url then return url end
    return "https://pandadevelopment.net"
end

--- Store V3 auth state in shared registry for downstream scripts
local function V3StoreAuth(result)
    rawset(shared, "__rs_v3_" .. tostring(game.PlaceId), {
        premium = result.isPremium,
        expires = result.expireDate,
        permissions = result.permissions,
        ts = os.time(),
    })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Key System
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local KeySystem = {}
KeySystem.__index = KeySystem

--- Check if file system is available (exploit executors)
local function HasFileSystem()
    local ok = pcall(function()
        return writefile and readfile and isfile and isfolder and makefolder
    end)
    return ok
end

--- Try to load a saved key from file
local function LoadSavedKey(folder)
    if IsStudio then return nil end
    local ok, result = pcall(function()
        local path = folder .. "/key.dat"
        if isfile(path) then
            return readfile(path)
        end
        return nil
    end)
    if ok then return result end
    return nil
end

--- Save a key to file
local function SaveKeyToFile(folder, key)
    if IsStudio then return end
    pcall(function()
        if not isfolder(folder) then
            makefolder(folder)
        end
        writefile(folder .. "/key.dat", key)
    end)
end

--- Delete saved key
local function DeleteSavedKey(folder)
    if IsStudio then return end
    pcall(function()
        local path = folder .. "/key.dat"
        if isfile(path) then
            delfile(path)
        end
    end)
end

function KeySystem:Show(config)
    config = config or {}
    local title = config.Title or "Dark Library"
    local subtitle = config.Subtitle or "Key System"
    local note = config.Note or ""
    local keys = config.Keys or {}
    local validator = config.Validator
    local saveKey = config.SaveKey ~= false
    local saveFolder = config.SaveFolder or "DarkKeySystem"
    local callback = config.Callback

    -- ── Panda Development V3 Configuration ──
    local premiumOnly = config.PremiumOnly or false
    local usePelinda = Pelinda ~= nil  -- V3 is available if Pelinda was injected

    -- KeyLink: auto-generate from V3 Pelinda, otherwise use manual link
    local keyLink = config.KeyLink
    if usePelinda and not keyLink then
        keyLink = V3GetKeyURL()
    end

    -- Last validation result (carries extra data like isPremium, expireDate)
    local lastValidationData = nil

    -- Validate a key input
    -- Returns: boolean success
    -- Side effect: sets lastValidationData with API response details
    local function ValidateKey(input)
        lastValidationData = nil

        -- Priority 1: V3 Pelinda (encrypted end-to-end)
        if usePelinda then
            local result = V3Validate(input, false)
            if result then
                -- Enforce premium-only if configured
                if premiumOnly and result.success and not result.isPremium then
                    result.success = false
                    result.message = "Premium key required"
                end
                lastValidationData = {
                    isPremium = result.isPremium,
                    expireDate = result.expireDate,
                    permissions = result.permissions,
                    message = result.message,
                }
                return result.success, result.message
            end
            return false, "Failed to connect to key server"
        end

        -- Priority 2: Custom validator function
        if validator then
            local ok = validator(input)
            if ok then
                lastValidationData = { isPremium = false, expireDate = nil, message = "Key accepted" }
            end
            return ok, ok and "Key accepted" or "Invalid key"
        end

        -- Priority 3: Static key list (offline fallback)
        for _, k in ipairs(keys) do
            if k == input then
                lastValidationData = { isPremium = false, expireDate = nil, message = "Key accepted" }
                return true, "Key accepted"
            end
        end
        return false, "Invalid key"
    end

    -- Check for saved key first
    if saveKey and not IsStudio then
        local saved = LoadSavedKey(saveFolder)
        if saved then
            local isValid = ValidateKey(saved)
            if isValid then
                -- Store V3 auth state for downstream scripts
                if usePelinda and lastValidationData then
                    V3StoreAuth(lastValidationData)
                end
                if callback then
                    task.spawn(callback, lastValidationData or {})
                end
                return -- skip UI entirely
            else
                -- Saved key is no longer valid (expired / revoked), delete it
                DeleteSavedKey(saveFolder)
            end
        end
    end

    -- ── GUI Parent: use safe hidden parent ──
    local guiParent = _getSafeGuiParent()

    -- Destroy existing (use stored reference instead of FindFirstChild to avoid scanning)
    local _prevGuiRef = rawget(shared, "__rs_keygui_ref")
    if _prevGuiRef then
        pcall(function() _prevGuiRef:Destroy() end)
        rawset(shared, "__rs_keygui_ref", nil)
    end

    -- Small random delay before creating UI to avoid burst-creation detection
    task.wait(math.random() * 0.3 + 0.1)

    local ScreenGui = Create("ScreenGui", {
        Name = _getInnocuousName(),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
        Parent = guiParent,
    })

    -- Store reference for cleanup (avoid FindFirstChild detection)
    rawset(shared, "__rs_keygui_ref", ScreenGui)

    -- Protect gui from anti-cheat scanning
    _protectGui(ScreenGui)

    -- ── Notification System ──
    local notifHolder = Create("Frame", {
        Name = _randomName(),
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 260, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0.5, -130, 0, 10),
        ClipsDescendants = false,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    AddListLayout(notifHolder, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

    local function Notify(cfg)
        cfg = cfg or {}
        local notifTitle = cfg.Title or "Notification"
        local notifContent = cfg.Content or ""
        local duration = cfg.Duration or 3

        local notif = Create("Frame", {
            BackgroundColor3 = Theme.Surface,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ClipsDescendants = true,
            ZIndex = 10,
            Parent = notifHolder,
        })
        AddCorner(notif, Theme.CornerRadius)
        AddStroke(notif, Theme.Border, 1)
        AddPadding(notif, 10, 10, 12, 12)
        AddListLayout(notif, 2)

        Create("TextLabel", {
            Text = notifTitle,
            Font = Theme.FontBold,
            TextSize = 12,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 10,
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
                ZIndex = 10,
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
            if destroyed then
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

    -- UI Scale
    local panelWidth = 320
    local panelHeight = 0 -- auto-sized

    local function GetAutoScale()
        local viewport = game:GetService("Workspace").CurrentCamera
        if not viewport then return 1 end
        local viewSize = viewport.ViewportSize
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

        if isMobile then
            local shortSide = math.min(viewSize.X, viewSize.Y)
            local idealScale = (shortSide * 0.88) / panelWidth
            return math.clamp(idealScale, 0.5, 1.2)
        else
            local scaleX = (viewSize.X * 0.85) / panelWidth
            local scaleY = (viewSize.Y * 0.85) / 400
            local idealScale = math.min(scaleX, scaleY)
            return math.clamp(idealScale, 0.65, 1)
        end
    end

    local UIScaleObj = Create("UIScale", {
        Scale = GetAutoScale(),
        Parent = ScreenGui,
    })

    -- Auto-rescale on viewport resize
    local camera = game:GetService("Workspace").CurrentCamera
    local connections = {}
    if camera then
        table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            local newScale = GetAutoScale()
            Tween(UIScaleObj, { Scale = newScale }, 0.25)
        end))
    end

    -- ── Background Overlay ──
    local Overlay = Create("Frame", {
        Name = _randomName(),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = ScreenGui,
    })
    Tween(Overlay, { BackgroundTransparency = 0.5 }, 0.4)

    -- ── Main Panel ──
    local Panel = Create("Frame", {
        Name = _randomName(),
        BackgroundColor3 = Theme.Background,
        Size = UDim2.fromOffset(panelWidth, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = ScreenGui,
    })
    AddCorner(Panel, Theme.CornerLarge)
    AddStroke(Panel, Theme.Border, 1)

    local PanelLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Panel,
    })

    -- ── Header Section ──
    local Header = Create("Frame", {
        Name = _randomName(),
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        ClipsDescendants = true,
        Parent = Panel,
    })
    AddCorner(Header, Theme.CornerLarge)
    AddPadding(Header, 14, 14, 20, 20)
    local headerLayout = AddListLayout(Header, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    -- Title
    Create("TextLabel", {
        Text = title,
        Font = Theme.FontBold,
        TextSize = 17,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = Header,
    })

    -- Separator
    Create("TextLabel", {
        Text = "·",
        Font = Theme.FontBold,
        TextSize = 18,
        TextColor3 = Theme.TextMuted,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = 2,
        Parent = Header,
    })

    -- Subtitle
    Create("TextLabel", {
        Text = subtitle,
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 3,
        Parent = Header,
    })

    -- Divider
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        Size = UDim2.new(1, 0, 0, 1),
        LayoutOrder = 3,
        BorderSizePixel = 0,
        Parent = Panel,
    })

    -- ── Body Section ──
    local Body = Create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 4,
        Parent = Panel,
    })
    AddPadding(Body, 16, 16, 20, 20)
    local bodyLayout = AddListLayout(Body, 10)

    -- Note / instructions
    if note and note ~= "" then
        Create("TextLabel", {
            Text = note,
            Font = Theme.FontLight,
            TextSize = 12,
            TextColor3 = Theme.TextDim,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextWrapped = true,
            LayoutOrder = 0,
            Parent = Body,
        })
    end

    -- ── Key Input Field ──
    local InputWrapper = Create("Frame", {
        BackgroundColor3 = Theme.InputBg,
        Size = UDim2.new(1, 0, 0, 38),
        LayoutOrder = 1,
        Parent = Body,
    })
    AddCorner(InputWrapper, Theme.CornerRadius)
    local inputStroke = AddStroke(InputWrapper, Theme.Border, 1)

    local KeyInput = Create("TextBox", {
        Text = "",
        PlaceholderText = "Enter your key...",
        PlaceholderColor3 = Theme.TextMuted,
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Parent = InputWrapper,
    })

    KeyInput.Focused:Connect(function()
        Tween(inputStroke, { Color = Theme.Accent }, 0.15)
    end)
    KeyInput.FocusLost:Connect(function()
        Tween(inputStroke, { Color = Theme.Border }, 0.15)
    end)



    -- ── Buttons Container ──
    local ButtonsFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = 4,
        Parent = Body,
    })
    local buttonsLayout = AddListLayout(ButtonsFrame, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center)

    -- Calculate button size based on whether GetKey link exists
    local buttonWidth = keyLink and UDim2.new(0.48, 0, 1, 0) or UDim2.new(1, 0, 1, 0)

    -- ── Submit Button ──
    local SubmitBtn = Create("TextButton", {
        Text = "",
        BackgroundColor3 = Theme.Accent,
        Size = buttonWidth,
        AutoButtonColor = false,
        ClipsDescendants = true,
        LayoutOrder = 1,
        Parent = ButtonsFrame,
    })
    AddCorner(SubmitBtn, Theme.CornerRadius)

    local SubmitLabel = Create("TextLabel", {
        Text = "Verify Key",
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = SubmitBtn,
    })

    local keyAccepted = false

    SubmitBtn.MouseEnter:Connect(function()
        if not keyAccepted then
            Tween(SubmitBtn, { BackgroundColor3 = Theme.AccentHover }, 0.12)
        end
    end)
    SubmitBtn.MouseLeave:Connect(function()
        if not keyAccepted then
            Tween(SubmitBtn, { BackgroundColor3 = Theme.Accent }, 0.12)
        end
    end)

    -- ── Get Key Button (optional) ──
    local GetKeyBtn
    if keyLink then
        GetKeyBtn = Create("TextButton", {
            Text = "",
            BackgroundColor3 = Theme.SurfaceAlt,
            Size = UDim2.new(0.48, 0, 1, 0),
            AutoButtonColor = false,
            ClipsDescendants = true,
            LayoutOrder = 2,
            Parent = ButtonsFrame,
        })
        AddCorner(GetKeyBtn, Theme.CornerRadius)
        AddStroke(GetKeyBtn, Theme.Border, 1)

        Create("TextLabel", {
            Text = "Get Key",
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.TextDim,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = GetKeyBtn,
        })

        GetKeyBtn.MouseEnter:Connect(function()
            Tween(GetKeyBtn, { BackgroundColor3 = Theme.CardHover }, 0.12)
        end)
        GetKeyBtn.MouseLeave:Connect(function()
            Tween(GetKeyBtn, { BackgroundColor3 = Theme.SurfaceAlt }, 0.12)
        end)

        GetKeyBtn.MouseButton1Click:Connect(function()
            Ripple(GetKeyBtn, Vector2.new(Mouse.X, Mouse.Y))
            -- Copy link to clipboard if possible, otherwise just set it to the TextBox
            if setclipboard then
                pcall(setclipboard, keyLink)
                Notify({ Title = "Key Link", Content = "Link copied to clipboard!", Duration = 3 })
            elseif IsStudio then
                Notify({ Title = "Key Link", Content = keyLink, Duration = 5 })
            end
        end)
    end

    -- ── Cleanup function ──
    local destroyed = false
    local function Cleanup()
        destroyed = true
        for _, conn in ipairs(connections) do
            if conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(connections)
        -- Clear stored GUI reference
        rawset(shared, "__rs_keygui_ref", nil)
    end

    -- ── Close / Destroy with animation ──
    local function DestroyUI(skipAnim)
        if destroyed then return end
        
        if skipAnim then
            Cleanup()
            -- Destroy remaining notifications
            pcall(function()
                for _, child in ipairs(notifHolder:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end
            end)
            ScreenGui:Destroy()
            return
        end

        local closeDuration = 0.3
        Tween(Overlay, { BackgroundTransparency = 1 }, closeDuration)
        Tween(Panel, {
            Position = UDim2.new(0.5, 0, 0.5, 30),
            BackgroundTransparency = 1,
        }, closeDuration)
        
        for _, desc in ipairs(Panel:GetDescendants()) do
            if desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                Tween(desc, { BackgroundTransparency = 1 }, closeDuration)
            elseif desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                Tween(desc, { BackgroundTransparency = 1, TextTransparency = 1 }, closeDuration)
            elseif desc:IsA("UIStroke") then
                Tween(desc, { Transparency = 1 }, closeDuration)
            end
        end

        -- Fade out notifications too
        for _, child in ipairs(notifHolder:GetChildren()) do
            if child:IsA("Frame") then
                Tween(child, { BackgroundTransparency = 1 }, closeDuration)
                local nStroke = child:FindFirstChildOfClass("UIStroke")
                if nStroke then Tween(nStroke, { Transparency = 1 }, closeDuration) end
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA("TextLabel") then
                        Tween(sub, { TextTransparency = 1 }, closeDuration)
                    end
                end
            end
        end

        task.delay(closeDuration + 0.05, function()
            Cleanup()
            if ScreenGui and ScreenGui.Parent then
                ScreenGui:Destroy()
            end
        end)
    end

    -- ── Success animation ──
    local function ShowSuccess()
        -- Flash the input green and lock button to green
        keyAccepted = true
        Tween(inputStroke, { Color = Theme.Success }, 0.2)
        Tween(SubmitBtn, { BackgroundColor3 = Theme.Success }, 0.2)
        SubmitLabel.Text = "Verified!"

        -- Build notification content with Panda API details
        local notifContent = "Key verified successfully! Loading..."
        if lastValidationData then
            if lastValidationData.isPremium then
                notifContent = "Premium key verified! Loading..."
            end
            if lastValidationData.expireDate then
                notifContent = notifContent .. "\nExpires: " .. tostring(lastValidationData.expireDate)
            end
        end
        Notify({ Title = "Key System", Content = notifContent, Duration = 2 })

        task.delay(1.2, function()
            DestroyUI()
            task.delay(0.35, function()
                if callback then
                    task.spawn(callback, lastValidationData or {})
                end
            end)
        end)
    end

    -- ── Error shake animation ──
    local function ShakeInput()
        local originalPos = InputWrapper.Position
        local shakeAmount = 6
        local shakeDuration = 0.06
        for i = 1, 4 do
            Tween(InputWrapper, { Position = originalPos + UDim2.fromOffset(shakeAmount * (i % 2 == 0 and 1 or -1), 0) }, shakeDuration, Enum.EasingStyle.Quad)
            task.wait(shakeDuration)
        end
        Tween(InputWrapper, { Position = originalPos }, shakeDuration, Enum.EasingStyle.Quad)
    end

    -- ── Submit handler ──
    local processing = false

    local function TrySubmit()
        if destroyed or processing then return end
        
        local key = KeyInput.Text
        if key == "" then
            Notify({ Title = "Key System", Content = "Please enter a key.", Duration = 3 })
            ShakeInput()
            return
        end

        processing = true
        SubmitLabel.Text = "Verifying..."
        Tween(SubmitBtn, { BackgroundColor3 = Theme.AccentDim }, 0.1)

        -- Run validation (may involve HTTP request to Panda API)
        task.spawn(function()
            if destroyed then return end

            local isValid, validationMessage = ValidateKey(key)

            if destroyed then return end

            if isValid then
                -- Save key if enabled
                if saveKey and not IsStudio then
                    SaveKeyToFile(saveFolder, key)
                end
                -- Store V3 auth state for downstream scripts
                if usePelinda and lastValidationData then
                    V3StoreAuth(lastValidationData)
                end
                ShowSuccess()
            else
                processing = false
                Tween(SubmitBtn, { BackgroundColor3 = Theme.Accent }, 0.15)
                SubmitLabel.Text = "Verify Key"

                local errorMsg = validationMessage or "Invalid key. Please try again."
                Notify({ Title = "Key System", Content = errorMsg, Duration = 3 })

                -- Flash input red
                Tween(inputStroke, { Color = Theme.Danger }, 0.15)
                task.delay(1, function()
                    if not destroyed then
                        Tween(inputStroke, { Color = Theme.Border }, 0.2)
                    end
                end)

                ShakeInput()
            end
        end)
    end

    SubmitBtn.MouseButton1Click:Connect(function()
        Ripple(SubmitBtn, Vector2.new(Mouse.X, Mouse.Y))
        TrySubmit()
    end)

    -- Submit on Enter
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            TrySubmit()
        end
    end)

    -- ── Open Animation ──
    local openDuration = 0.35
    local openStyle = Enum.EasingStyle.Quint
    local shiftOffset = 30

    local panelStroke = Panel:FindFirstChildOfClass("UIStroke")

    Panel.Position = UDim2.new(0.5, 0, 0.5, shiftOffset)
    Panel.BackgroundTransparency = 1
    if panelStroke then panelStroke.Transparency = 1 end

    Tween(Panel, {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
    }, openDuration, openStyle)
    if panelStroke then Tween(panelStroke, { Transparency = 0 }, openDuration, openStyle) end

    -- Fade in children
    task.delay(0.05, function()
        local originals = {}
        for _, desc in ipairs(Panel:GetDescendants()) do
            if desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                originals[desc] = { BackgroundTransparency = desc.BackgroundTransparency }
                desc.BackgroundTransparency = 1
            elseif desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                originals[desc] = { BackgroundTransparency = desc.BackgroundTransparency, TextTransparency = desc.TextTransparency }
                desc.BackgroundTransparency = 1
                desc.TextTransparency = 1
            elseif desc:IsA("UIStroke") then
                originals[desc] = { Transparency = desc.Transparency }
                desc.Transparency = 1
            end
        end
        for desc, props in pairs(originals) do
            Tween(desc, props, openDuration, openStyle)
        end
    end)

    -- Auto-focus input after open animation
    task.delay(openDuration + 0.1, function()
        if not destroyed then
            KeyInput:CaptureFocus()
        end
    end)
end

return KeySystem
