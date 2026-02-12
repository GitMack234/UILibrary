-- ════════════════════════════════════════════════════════════════
-- RockSide Hub — Main Client Script
-- ════════════════════════════════════════════════════════════════

local RockSide

if game:GetService("RunService"):IsStudio() then
    RockSide = require(script.Parent:WaitForChild("RockSideLib"))
else
    local HttpGet = (syn and syn.request or http and http.request or http_request or request or fluxus and fluxus.request)
    local response = HttpGet({
        Url    = "https://raw.githubusercontent.com/GitMack234/UILibrary/main/NEW_LIBRARY.luau",
        Method = "GET",
    })
    RockSide = loadstring(response.Body)()
end

-- ══════════════════════════════════════════════════════════════
-- BUILD UI (called on init and after theme switch)
-- ══════════════════════════════════════════════════════════════
local Window
local currentTheme = "RockSide"
local isRebuilding = false

local function BuildUI()
    -- ── Window ──
    Window = RockSide:CreateWindow({
        Name       = "RockSide",
        Version    = "v1 Stable",
        ToggleKey  = Enum.KeyCode.RightShift,
        StudioMode = true,
    })

    -- ══════════════════════════════════════════════════════════════
    -- SETTINGS TAB
    -- ══════════════════════════════════════════════════════════════
    local SettingsTab = Window:CreateTab({
        Name = "Settings",
        Icon = "rbxassetid://11293977610",
    })

    -- ── Config Section ──
    local ConfigSection = SettingsTab:CreateSection("Config", "Save & load your settings")

    local ConfigInput = ConfigSection:CreateInput({
        Name        = "Config Name",
        Placeholder = "Enter config name...",
        Default     = "",
        Callback    = function() end,
    })

    local ConfigDropdown = ConfigSection:CreateDropdown({
        Name     = "Saved Configs",
        Options  = Window:GetConfigs(),
        Callback = function(selected)
            ConfigInput:Set(selected)
        end,
    })

    ConfigSection:CreateSeparator()

    ConfigSection:CreateButton({
        Name     = "Save Config",
        Callback = function()
            local name = ConfigInput:Get()
            if name == "" then
                Window:Notify({ Title = "Error", Message = "Please enter a config name.", Type = "Error" })
                return
            end

            local ok, err = Window:SaveConfig(name)
            Window:Notify({
                Title   = ok and "Saved" or "Error",
                Message = ok and ("Config '" .. name .. "' saved successfully.") or err,
                Type    = ok and "Success" or "Error",
            })

            if ok then
                ConfigDropdown:Refresh(Window:GetConfigs())
            end
        end,
    })

    ConfigSection:CreateButton({
        Name     = "Load Config",
        Callback = function()
            local name = ConfigInput:Get()
            if name == "" then
                Window:Notify({ Title = "Error", Message = "Please enter a config name.", Type = "Error" })
                return
            end

            local ok, err = Window:LoadConfig(name)
            Window:Notify({
                Title   = ok and "Loaded" or "Error",
                Message = ok and ("Config '" .. name .. "' loaded.") or err,
                Type    = ok and "Success" or "Error",
            })
        end,
    })

    ConfigSection:CreateButton({
        Name     = "Delete Config",
        Callback = function()
            local name = ConfigInput:Get()
            if name == "" then
                Window:Notify({ Title = "Error", Message = "Please enter a config name.", Type = "Error" })
                return
            end

            local ok, err = Window:DeleteConfig(name)
            Window:Notify({
                Title   = ok and "Deleted" or "Error",
                Message = ok and ("Config '" .. name .. "' deleted.") or err,
                Type    = ok and "Success" or "Error",
            })

            if ok then
                ConfigDropdown:Refresh(Window:GetConfigs())
            end
        end,
    })

    ConfigSection:CreateSeparator()

    ConfigSection:CreateButton({
        Name     = "Refresh List",
        Callback = function()
            ConfigDropdown:Refresh(Window:GetConfigs())
            Window:Notify({ Title = "Refreshed", Message = "Config list updated.", Type = "Info", Duration = 2 })
        end,
    })

    -- ── Theme Section ──
    local ThemeSection = SettingsTab:CreateSection("Theme", "Customize the UI appearance")

    local themeNames = {}
    for name in pairs(RockSide.Themes) do
        table.insert(themeNames, name)
    end
    table.sort(themeNames)

    ThemeSection:CreateDropdown({
        Name     = "Theme Preset",
        Options  = themeNames,
        Default  = currentTheme,
        Callback = function(selected)
            if isRebuilding or selected == currentTheme then return end
            isRebuilding = true
            currentTheme = selected
            RockSide:SetTheme(selected)
            Window:Destroy()
            BuildUI()
            isRebuilding = false
            Window:Notify({
                Title    = "Theme Applied",
                Message  = "Switched to '" .. selected .. "' theme.",
                Duration = 2.5,
                Type     = "Success",
            })
        end,
    })

    -- ── Interface Section ──
    local InterfaceSection = SettingsTab:CreateSection("Interface", "UI controls")

    InterfaceSection:CreateButton({
        Name     = "Show Keybinds",
        Callback = function()
            Window:ShowKeybinds()
        end,
    })

    InterfaceSection:CreateButton({
        Name     = "Hide Keybinds",
        Callback = function()
            Window:HideKeybinds()
        end,
    })

    InterfaceSection:CreateSeparator()

    InterfaceSection:CreateButton({
        Name     = "Reset All Settings",
        Callback = function()
            if currentTheme ~= "RockSide" then
                isRebuilding = true
                currentTheme = "RockSide"
                RockSide:SetTheme("RockSide")
                Window:Destroy()
                BuildUI()
                isRebuilding = false
            else
                Window:CleanUp()
            end
            Window:Notify({ Title = "Reset", Message = "All settings reset to defaults.", Type = "Warning" })
        end,
    })

    InterfaceSection:CreateButton({
        Name     = "Destroy UI",
        Callback = function()
            Window:Destroy()
        end,
    })
end

BuildUI()
