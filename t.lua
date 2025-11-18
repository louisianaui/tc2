-- [[ bunnyhub tc2 ]]

-- Configuration
local Repository = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local ScriptName = "BunnyHub - TC2"
local ScriptVersion = "v1.0.0"
local MenuIcon = nil
local MenuSize = UDim2.fromOffset(750, 550)

-- Add these variables near the top with your other variables
local EnableHook = true
local Connections = {}
local RestoreFunctions = {}

-- Load Libraries
local Library = loadstring(game:HttpGet(Repository .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repository .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repository .. "addons/SaveManager.lua"))()

-- References
local Options = Library.Options
local Toggles = Library.Toggles

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = gethui() or game:GetService("CoreGui")
local RepStorage = game:GetService("ReplicatedStorage")

-- UI Creation
local Window = Library:CreateWindow({
    Title = ScriptName,
    Icon = MenuIcon,
    Footer = ScriptVersion,
    Center = true,
    AutoShow = true,
    Size = MenuSize
})

-- Tab Definitions
local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Combat = Window:AddTab("Combat", "sword"),
    Visuals = Window:AddTab("Visuals", "scan-eye"),
    Movement = Window:AddTab("Movement", "running"),
    Config = Window:AddTab("Configuration", "folder-cog")
}

-- Variables
local Highlights = {}
local HitboxLoop
local OriginalSizes = {}

-- Functions
local function ExpandPart(part, size, transparency)
    if part and part:IsA("BasePart") then
        if not OriginalSizes[part] then
            OriginalSizes[part] = part.Size
        end
        part.Massless = true
        part.CanCollide = false
        part.Transparency = transparency
        part.Size = size
    end
end

-- SIMPLE ROTATION FUNCTIONS --
local function OrientTorsoBackToPlayer(torso, localPlayerChar)
    if not torso or not localPlayerChar or not localPlayerChar:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local localPlayerPos = localPlayerChar.HumanoidRootPart.Position
    local torsoPos = torso.Position
    
    -- Calculate direction from torso to local player
    local direction = (localPlayerPos - torsoPos).Unit
    
    -- Simply set the CFrame to look away from player while keeping position
    torso.CFrame = CFrame.lookAt(torsoPos, torsoPos - direction)
end

local function ExpandPartForBackstab(part, size, localPlayerChar)
    if part and part:IsA("BasePart") then
        if not OriginalSizes[part] then
            OriginalSizes[part] = part.Size
        end
        part.Massless = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = size
        
        -- Store original CFrame and only rotate once
        if not part:GetAttribute("OriginalCFrame") then
            part:SetAttribute("OriginalCFrame", part.CFrame)
            OrientTorsoBackToPlayer(part, localPlayerChar)
        end
    end
end

local function ResetPart(part)
    if part and part:IsA("BasePart") and OriginalSizes[part] then
        part.Size = OriginalSizes[part]
        -- Restore original CFrame if we stored it
        local originalCFrame = part:GetAttribute("OriginalCFrame")
        if originalCFrame then
            part.CFrame = originalCFrame
            part:SetAttribute("OriginalCFrame", nil)
        end
    end
end

local function CleanupHighlights()
    for playerName, highlight in pairs(Highlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    Highlights = {}
end

local function CleanupHitboxes()
    if HitboxLoop then
        HitboxLoop:Disconnect()
        HitboxLoop = nil
    end
    for part, originalSize in pairs(OriginalSizes) do
        if part and part.Parent then
            part.Size = originalSize
        end
    end
    OriginalSizes = {}
end

-- MAIN TAB
local MainGeneral = Tabs.Main:AddLeftGroupbox("General")
MainGeneral:AddLabel("Welcome to TC2 Script")
MainGeneral:AddLabel("Version: " .. ScriptVersion)

-- COMBAT TAB
local CombatHitboxes = Tabs.Combat:AddLeftGroupbox("Hitboxes")
CombatHitboxes:AddToggle("CH_Enabled", { Text = "Hitbox Expander", Default = false, Tooltip = "Expand player hitboxes" })

local CH_Enabled_True = CombatHitboxes:AddDependencyBox()
CH_Enabled_True:AddSlider("CH_Size", { Text = "Hitbox Size", Default = 15, Min = 5, Max = 50, Rounding = 0, Compact = true })
CH_Enabled_True:AddDropdown("CH_Target", { 
    Values = { "Both", "Head Only", "Torso Only" }, 
    Default = 1, 
    Multi = false, 
    Text = "Target Hitboxes",
    Tooltip = "Choose which hitboxes to expand"
})
CH_Enabled_True:AddToggle("CH_RotateBackstab", { Text = "Rotate Backstab Hitboxes", Default = false, Tooltip = "Make torso hitboxes face towards you for backstabs" })
CH_Enabled_True:SetupDependencies({ { Toggles.CH_Enabled, true } })

-- VISUALS TAB
local VisualsESP = Tabs.Visuals:AddLeftGroupbox("Player ESP")
VisualsESP:AddToggle("VE_PlayerESP", { Text = "Player Highlights", Default = false, Tooltip = "Highlight all players" })
VisualsESP:AddToggle("VE_TeamColors", { Text = "Team Colors", Default = true, Tooltip = "Use team colors for highlights" })
VisualsESP:AddToggle("VE_ShowNames", { Text = "Show Names", Default = true, Tooltip = "Display player names" })
VisualsESP:AddToggle("VE_HideTeammates", { Text = "Hide Teammates", Default = false, Tooltip = "Don't show ESP for teammates" })

local VisualsEffects = Tabs.Visuals:AddRightGroupbox("Effects")
VisualsEffects:AddToggle("VV_CustomFOV", { Text = "Custom FOV", Default = false, Tooltip = "Enable custom field of view" })
VisualsEffects:AddSlider("VV_FOVValue", { 
    Text = "FOV Value", 
    Default = 80, 
    Min = 50, 
    Max = 120, 
    Rounding = 0, 
    Compact = true,
    Tooltip = "Set custom field of view value"
})
VisualsEffects:AddDivider()
VisualsEffects:AddToggle("VV_Notifications", { Text = "Notifications", Default = true, Tooltip = "Show script notifications" })

-- MOVEMENT TAB
local MovementSpeed = Tabs.Movement:AddLeftGroupbox("Speed")
MovementSpeed:AddToggle("MO_SpeedDemon", { Text = "Speed Demon", Default = false, Tooltip = "Enable bunny hop/speed boost" })

-- CONFIGURATION TAB
local MenuProperties = Tabs.Config:AddLeftGroupbox("Menu")
MenuProperties:AddButton("Unload", function()
    Library:Unload()
    Library.Unloaded = true
    EnableHook = false

    for _, Connection in Connections do
        Connection:Disconnect()
    end
    for _, Function in RestoreFunctions do
        restorefunction(Function)
    end
end)

MenuProperties:AddLabel("Menu bind"):AddKeyPicker("MP_MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuProperties:AddDivider()
MenuProperties:AddToggle("MP_ShowKeybinds", { Text = "Show Keybinds", Default = false })

Toggles.MP_ShowKeybinds:OnChanged(function()
    Library.KeybindFrame.Visible = Toggles.MP_ShowKeybinds.Value
end)

Library.ToggleKeybind = Options.MP_MenuKeybind

local BunnyHubTheme = {
    BackgroundColor = Color3.fromRGB(15, 15, 15),
    OutlineColor = Color3.fromRGB(40, 40, 40),
    MainColor = Color3.fromRGB(25, 25, 25),
    AccentColor = Color3.new(0, 1, 0.5),
    FontColor = Color3.new(1, 1, 1),
    FontFace = "BuilderSans"
}

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("BunnyHub/Themes")
ThemeManager:SetDefaultTheme(BunnyHubTheme)
ThemeManager:ApplyToTab(Tabs.Config)
ThemeManager:ThemeUpdate()

SaveManager:SetLibrary(Library)
SaveManager:SetFolder("BunnyHub/TC2")
SaveManager:BuildConfigSection(Tabs.Config)
SaveManager:IgnoreThemeSettings()

-- Function to refresh all features after config load
local function RefreshAllFeatures()
    -- Refresh Hitbox Expander if enabled
    if Toggles.CH_Enabled.Value then
        Toggles.CH_Enabled:SetValue(false)
        wait(0.1)
        Toggles.CH_Enabled:SetValue(true)
    end
    
    -- Refresh ESP if enabled
    if Toggles.VE_PlayerESP.Value then
        Toggles.VE_PlayerESP:SetValue(false)
        wait(0.1)
        Toggles.VE_PlayerESP:SetValue(true)
    end
    
    -- Refresh FOV if enabled
    if Toggles.VV_CustomFOV.Value then
        UpdateFOV()
    end
    
    -- Refresh Speed Demon if enabled
    if Toggles.MO_SpeedDemon.Value then
        -- Speed Demon will auto-retry due to our previous fix
    end
    
    print("[CONFIG] All features refreshed after autoload")
end

-- Load autoload config with delay
task.spawn(function()
    wait(3) -- Wait 3 seconds for game to fully load
    SaveManager:LoadAutoloadConfig()
    
    -- Verify and refresh all features after config load
    wait(1)
    RefreshAllFeatures()
end)

-- Hitbox Expander Logic
Toggles.CH_Enabled:OnChanged(function(State)
    if State then
        HitboxLoop = game:GetService("RunService").Heartbeat:Connect(function()
            local localPlayerChar = LocalPlayer.Character
            
            for _, player in Players:GetPlayers() do 
                local Character = player.Character
                if Character and Character:FindFirstChild("Head") then
                    if player.Team ~= LocalPlayer.Team then
                        local headHB = Character:FindFirstChild("HeadHB")
                        local hitbox = Character:FindFirstChild("Hitbox")
                        local targetMode = Options.CH_Target.Value
                        
                        -- Check if we're using backstab rotation
                        local useBackstabMode = Toggles.CH_RotateBackstab.Value and localPlayerChar
                        
                        if headHB and (targetMode == "Both" or targetMode == "Head Only") then
                            ExpandPart(headHB, Vector3.one * Options.CH_Size.Value, 1)
                        end
                        
                        if hitbox and (targetMode == "Both" or targetMode == "Torso Only") then
                            if useBackstabMode then
                                -- Use special backstab expansion for torso
                                ExpandPartForBackstab(hitbox, Vector3.one * Options.CH_Size.Value, localPlayerChar)
                            else
                                ExpandPart(hitbox, Vector3.one * Options.CH_Size.Value, 1)
                            end
                        end
                    else
                        local headHB = Character:FindFirstChild("HeadHB")
                        local hitbox = Character:FindFirstChild("Hitbox")
                        if headHB then ResetPart(headHB) end
                        if hitbox then ResetPart(hitbox) end
                    end
                end
            end
        end)
        if Toggles.VV_Notifications.Value then
            Library:Notify("Hitbox Expander enabled!")
        end
    else
        CleanupHitboxes()
        if Toggles.VV_Notifications.Value then
            Library:Notify("Hitbox Expander disabled!")
        end
    end
end)

-- Hitbox Size Change
Options.CH_Size:OnChanged(function(Value)
    if Toggles.CH_Enabled.Value and Toggles.VV_Notifications.Value then
        Library:Notify("Hitbox size updated: " .. Value)
    end
end)

-- [[ add plesp here ]]
local ESPObjects = {}
local ESPLoop

local function CreateESP(player)
    if ESPObjects[player.Name] then return end
    if Toggles.VE_HideTeammates.Value and player.Team == LocalPlayer.Team then return end
    
    local highlight = Instance.new("Highlight")
    local billboard = Instance.new("BillboardGui")
    local nameLabel = Instance.new("TextLabel")
    
    -- Setup Highlight
    highlight.Name = player.Name .. "ESP"
    highlight.Adornee = player.Character
    highlight.Parent = CoreGui
    highlight.Enabled = true
    highlight.FillColor = Toggles.VE_TeamColors.Value and player.TeamColor.Color or Color3.new(1, 0, 1)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- Setup Billboard GUI for name
    billboard.Name = player.Name .. "Name"
    billboard.Adornee = player.Character:WaitForChild("HumanoidRootPart")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0) -- Slightly above character
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 512
    billboard.Parent = CoreGui
    
    -- Setup Name Label
    nameLabel.Name = "NameLabel"
    nameLabel.Parent = billboard
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Toggles.VE_TeamColors.Value and player.TeamColor.Color or Color3.new(1, 0, 1)
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Visible = Toggles.VE_ShowNames.Value

    ESPObjects[player.Name] = {
        Highlight = highlight,
        Billboard = billboard,
        NameLabel = nameLabel,
        Player = player
    }
end

local function RemoveESP(playerName)
    if ESPObjects[playerName] then
        if ESPObjects[playerName].Highlight then
            ESPObjects[playerName].Highlight:Destroy()
        end
        if ESPObjects[playerName].Billboard then
            ESPObjects[playerName].Billboard:Destroy()
        end
        ESPObjects[playerName] = nil
    end
end

local function UpdateESP()
    if not Toggles.VE_PlayerESP.Value then return end
    
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character then
            local espData = ESPObjects[player.Name]
            
            -- Check if we should show/hide based on team settings
            local shouldShow = not Toggles.VE_HideTeammates.Value or player.Team ~= LocalPlayer.Team
            
            if shouldShow then
                if not espData then
                    -- Create new ESP
                    CreateESP(player)
                else
                    -- Update existing ESP
                    if espData.Highlight then
                        espData.Highlight.FillColor = Toggles.VE_TeamColors.Value and player.TeamColor.Color or Color3.new(1, 0, 1)
                        espData.Highlight.Enabled = true
                    end
                    if espData.NameLabel then
                        espData.NameLabel.TextColor3 = Toggles.VE_TeamColors.Value and player.TeamColor.Color or Color3.new(1, 0, 1)
                        espData.NameLabel.Visible = Toggles.VE_ShowNames.Value
                    end
                    if espData.Billboard and player.Character:FindFirstChild("HumanoidRootPart") then
                        espData.Billboard.Adornee = player.Character.HumanoidRootPart
                    end
                end
            else
                -- Remove ESP if shouldn't show
                if espData then
                    RemoveESP(player.Name)
                end
            end
        else
            -- Remove ESP if player left or no character
            if ESPObjects[player.Name] then
                RemoveESP(player.Name)
            end
        end
    end
end

local function CleanupESP()
    for playerName, espData in pairs(ESPObjects) do
        RemoveESP(playerName)
    end
    ESPObjects = {}
    if ESPLoop then
        ESPLoop:Disconnect()
        ESPLoop = nil
    end
end

-- Player Highlights
Toggles.VE_PlayerESP:OnChanged(function(State)
    if State then
        -- Create ESP for existing players
        for _, player in Players:GetPlayers() do
            if player ~= LocalPlayer and player.Character then
                CreateESP(player)
            end
        end
        
        -- Start ESP update loop
        ESPLoop = game:GetService("RunService").Heartbeat:Connect(function()
            UpdateESP()
        end)
        
        -- Player added event
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                wait(1) -- Wait for character to load
                if Toggles.VE_PlayerESP.Value then
                    CreateESP(player)
                end
            end)
        end)
        
        -- Player removing event
        Players.PlayerRemoving:Connect(function(player)
            RemoveESP(player.Name)
        end)
        
        if Toggles.VV_Notifications.Value then
            Library:Notify("Player ESP enabled!")
        end
    else
        CleanupESP()
        if Toggles.VV_Notifications.Value then
            Library:Notify("Player ESP disabled!")
        end
    end
end)

-- Team Colors Toggle
Toggles.VE_TeamColors:OnChanged(function(State)
    if Toggles.VE_PlayerESP.Value then
        for playerName, espData in pairs(ESPObjects) do
            local player = espData.Player
            if player and espData.Highlight then
                espData.Highlight.FillColor = State and player.TeamColor.Color or Color3.new(1, 0, 1)
            end
            if player and espData.NameLabel then
                espData.NameLabel.TextColor3 = State and player.TeamColor.Color or Color3.new(1, 0, 1)
            end
        end
    end
end)

-- Show Names Toggle
Toggles.VE_ShowNames:OnChanged(function(State)
    if Toggles.VE_PlayerESP.Value then
        for _, espData in pairs(ESPObjects) do
            if espData.NameLabel then
                espData.NameLabel.Visible = State
            end
        end
    end
end)

-- Hide Teammates Toggle
Toggles.VE_HideTeammates:OnChanged(function(State)
    if Toggles.VE_PlayerESP.Value then
        -- The UpdateESP loop will handle showing/hiding teammates automatically
        if Toggles.VV_Notifications.Value then
            if State then
                Library:Notify("Teammates hidden from ESP!")
            else
                Library:Notify("Showing all players in ESP!")
            end
        end
    end
end)

-- FOV System
local FOVLoop

local function UpdateFOV()
    if Toggles.VV_CustomFOV.Value then
        workspace.CurrentCamera.FieldOfView = Options.VV_FOVValue.Value
    end
end

Toggles.VV_CustomFOV:OnChanged(function(State)
    if State then
        FOVLoop = game:GetService("RunService").Heartbeat:Connect(function()
            UpdateFOV()
        end)
        if Toggles.VV_Notifications.Value then
            Library:Notify("Custom FOV enabled: " .. Options.VV_FOVValue.Value)
        end
    else
        if FOVLoop then
            FOVLoop:Disconnect()
            FOVLoop = nil
        end
        -- Reset to default FOV when disabled
        workspace.CurrentCamera.FieldOfView = 70 -- Default Roblox FOV
        if Toggles.VV_Notifications.Value then
            Library:Notify("Custom FOV disabled")
        end
    end
end)

Options.VV_FOVValue:OnChanged(function(Value)
    if Toggles.VV_CustomFOV.Value then
        UpdateFOV()
        if Toggles.VV_Notifications.Value then
            Library:Notify("FOV updated: " .. Value)
        end
    end
end)

-- Speed Demon
Toggles.MO_SpeedDemon:OnChanged(function(State)
    task.spawn(function()
        local maxAttempts = 512
        local attempt = 0
        
        while attempt < maxAttempts do
            local success, errorMsg = pcall(function()
                local vipSettings = RepStorage:FindFirstChild("VIPSettings")
                if not vipSettings then
                    error("VIPSettings folder not found")
                end
                
                local speedDemon = vipSettings:FindFirstChild("SpeedDemon")
                if not speedDemon then
                    error("SpeedDemon object not found")
                end
                
                print("[DEBUG] Attempt", attempt + 1, "SpeedDemon Type:", speedDemon.ClassName, "Current Value:", speedDemon.Value)
                
                -- Handle different value types
                if speedDemon:IsA("BoolValue") then
                    speedDemon.Value = State
                elseif speedDemon:IsA("StringValue") then
                    speedDemon.Value = State and "checked" or "unchecked"
                elseif speedDemon:IsA("IntValue") or speedDemon:IsA("NumberValue") then
                    speedDemon.Value = State and 1 or 0
                else
                    error("Unknown SpeedDemon type: " .. speedDemon.ClassName)
                end
                
                print("[DEBUG] SpeedDemon set to:", speedDemon.Value)
                return true -- Success
            end)
            
            if success then
                if Toggles.VV_Notifications.Value then
                    if State then
                        Library:Notify("Speed Demon enabled!")
                    else
                        Library:Notify("Speed Demon disabled!")
                    end
                end
                break -- Exit the loop on success
            else
                warn("Speed Demon Attempt", attempt + 1, "Error:", errorMsg)
                attempt = attempt + 1
                if attempt < maxAttempts then
                    wait(1) -- Wait 1 second before retry
                else
                    if Toggles.VV_Notifications.Value then
                        Library:Notify("Speed Demon: Failed after " .. maxAttempts .. " attempts")
                    end
                end
            end
        end
    end)
end)

-- Initialize UI Customization
task.spawn(function()
    -- Apply transparency effects (optional)
    Library.ScreenGui.Main.ScrollingFrame.Transparency = 0.3
    Library.ScreenGui.Main.Container.Transparency = 0.8
    Library.ScreenGui.Main.Transparency = 0.7
    
    -- Set watermark
    Library:SetWatermarkVisibility(true)
    Library.ShowCustomCursor = false
    
    -- Toggle keybinds visibility (already set above)
    Toggles.MP_ShowKeybinds:OnChanged(function()
        Library.KeybindFrame.Visible = Toggles.MP_ShowKeybinds.Value
    end)
    
    Library.ToggleKeybind = Options.MP_MenuKeybind
end)

print(string.format("[%s] %s loaded successfully!", ScriptVersion, ScriptName))
