if _G.PerkESP_Unloading then return end

print("KOMOHUB LOADING...")

local Workspace              = cloneref(game:GetService("Workspace"))
local Camera                 = Workspace.CurrentCamera
local Lighting               = cloneref(game:GetService("Lighting"))
local Players                = cloneref(game:GetService("Players"))
local LocalPlayer            = Players.LocalPlayer
local UserInputService       = cloneref(game:GetService("UserInputService"))
local HttpService            = cloneref(game:GetService("HttpService"))
local RunService             = cloneref(game:GetService("RunService"))
local CoreGui                = cloneref(game:GetService("CoreGui"))
local Stats                  = cloneref(game:GetService("Stats"))
local ReplicatedStorage      = cloneref(game:GetService("ReplicatedStorage"))
local ReplicatedFirst        = cloneref(game:GetService("ReplicatedFirst"))
local TextChatService        = cloneref(game:GetService("TextChatService"))
local GuiService             = cloneref(game:GetService("GuiService"))
local TweenService           = cloneref(game:GetService("TweenService"))
local RbxAnalyticsService    = cloneref(game:GetService("RbxAnalyticsService"))
for Index, Func in getgenv() do
    if typeof(Func) == "function" then
        clonefunction(Func)
    end
end

local VirtualInputManager    = Instance.new("VirtualInputManager")

_G.PerkESP = {
    Connections = {},
    Drawings = {}
}

local DEFAULT_SETTINGS = {
    Enabled = true,
    TeamCheck = false,
    MaxRenderDistance = 800,
    
    AutoExecuteOnTeleport = true,

    TargetFolders = {
        "ShootingRangeEntities",
        "Mobs",
        "NPCs",
        "Enemies",
        "Dummies"
    },

    HeadParts = {"Head"},
    BodyParts = {"UpperTorso", "LowerTorso", "Torso", "LeftArm", "RightArm", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    LegParts = {"LeftLeg", "RightLeg", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"},

    Triggerbot = {
        Enabled = true,
        AttackNPCs = true, 
        ActiveKey = Enum.UserInputType.MouseButton2,
        ShootLegs = true,
        ClickDelay = 0.08, 
        WhitelistEnabled = false,
        Whitelist = {},
        MaxDistance = 800,
    },

    PlayerESP = {
        Enabled = true,
        BoxColor = Color3.fromRGB(255, 255, 255),
        HighlightColor = Color3.fromRGB(255, 0, 0),
        Name = { Enabled = true, Size = 16 },
        Distance = { Enabled = true, Color = Color3.fromRGB(255, 255, 255), Size = 14 },
        Health = { Box = { Enabled = true }, Text = { Enabled = true, Size = 13 } },
        WhitelistEnabled = false,
        Whitelist = {}
    },

    NPC_ESP = {
        Enabled = true,
        BoxColor = Color3.fromRGB(255, 255, 0),
        HighlightColor = Color3.fromRGB(255, 165, 0),
        Name = { Enabled = true, Size = 16 },
        Distance = { Enabled = true, Color = Color3.fromRGB(255, 255, 255), Size = 14 },
        Health = { Box = { Enabled = true }, Text = { Enabled = true, Size = 13 } },
        WhitelistEnabled = false,
        Whitelist = {}
    },

    Highlight = { Enabled = true, FillTransparency = 0.5, OutlineTransparency = 0 },
    Box = { Enabled = true, Thickness = 1.5 },
    Name = { Enabled = true, Size = 16, Outline = true },
    Distance = { Enabled = true, Color = Color3.fromRGB(255, 255, 255), Size = 14, Outline = true },
    NameMultiplier = 1,
    DistanceMultiplier = 1,
    Health = {
        Box = { Enabled = true, Height = 5, Offset = 5 },
        Text = { Enabled = true, Size = 13, Outline = true, Format = "HP: %d%%" }
    }
}

local SETTINGS = _G.PerkESP_Settings or DEFAULT_SETTINGS
_G.PerkESP_Settings = SETTINGS

local ESP_STORAGE = {}
local CONNECTED_FOLDERS = {}

if _G.UNLOAD_KOMOHUB and not _G.PerkESP_Unloading then
    _G.UNLOAD_KOMOHUB()
    task.wait(3)
end
_G.UNLOAD_KOMOHUB = function()
    task.defer(function()
        _G.PerkESP_Unloading = true
        local pk = _G.PerkESP
        if pk and pk.RenderConnection and pk.RenderConnection.Disconnect then
            pcall(function() pk.RenderConnection:Disconnect() end)
            pk.RenderConnection = nil
        end
        if pk and pk.Connections then
            for i = #pk.Connections, 1, -1 do
                local conn = pk.Connections[i]
                pcall(function() if conn and conn.Disconnect then conn:Disconnect() end end)
            end
        end
        for char, data in pairs(ESP_STORAGE) do
            if data and data.CachedChar then
                pcall(function()
                    local h = data.CachedChar:FindFirstChild("PerkHighlight")
                    if h then h:Destroy() end
                end)
            end
            if data and data.Connections then
                for _, conn in ipairs(data.Connections) do
                    pcall(function() if conn and conn.Disconnect then conn:Disconnect() end end)
                end
            end
        end
        for k in pairs(ESP_STORAGE) do ESP_STORAGE[k] = nil end
        if pk and pk.Drawings then
            for i = #pk.Drawings, 1, -1 do
                local d = pk.Drawings[i]
                pcall(function() if d and d.Remove then d:Remove() end end)
            end
        end
        _G.PerkESP = nil
        _G.PerkESP_Settings = nil
        if _G.Library and _G.Library.Destroy then
            pcall(function() _G.Library:Destroy() end)
        end
        task.wait(3)
        _G.PerkESP_Unloading = false
    end)
end

-- Load UI Library (loadstring from GitHub)
local UI_LIB_URL = "https://raw.githubusercontent.com/commoi370381/KomoHub/refs/heads/main/UI%20_G.Library"
local success, err = pcall(function()
    _G.Library = loadstring(game:HttpGet(UI_LIB_URL))()
end)
if success and _G.Library then
    _G.Library.MenuKey = Enum.KeyCode.Insert
    if not SETTINGS.PlayerESP.Name then SETTINGS.PlayerESP.Name = { Enabled = true, Size = 16 } end
    if not SETTINGS.PlayerESP.Distance then SETTINGS.PlayerESP.Distance = { Enabled = true, Color = Color3.fromRGB(255,255,255), Size = 14 } end
    if not SETTINGS.PlayerESP.Health then SETTINGS.PlayerESP.Health = { Box = { Enabled = true }, Text = { Enabled = true, Size = 13 } } end
    if not SETTINGS.PlayerESP.WhitelistEnabled then SETTINGS.PlayerESP.WhitelistEnabled = false end
    if not SETTINGS.PlayerESP.Whitelist then SETTINGS.PlayerESP.Whitelist = {} end
    if not SETTINGS.NPC_ESP.Name then SETTINGS.NPC_ESP.Name = { Enabled = true, Size = 16 } end
    if not SETTINGS.NPC_ESP.Distance then SETTINGS.NPC_ESP.Distance = { Enabled = true, Color = Color3.fromRGB(255,255,255), Size = 14 } end
    if not SETTINGS.NPC_ESP.Health then SETTINGS.NPC_ESP.Health = { Box = { Enabled = true }, Text = { Enabled = true, Size = 13 } } end
    if not SETTINGS.NPC_ESP.WhitelistEnabled then SETTINGS.NPC_ESP.WhitelistEnabled = false end
    if not SETTINGS.NPC_ESP.Whitelist then SETTINGS.NPC_ESP.Whitelist = {} end

    local MainTab = _G.Library:Tab("Perk ESP", 10455603612)

    local GeneralGroup = MainTab:Group("General")
    local espTog = GeneralGroup:Toggle({Name = "ESP Enabled", Tooltip = "Master switch - disables ESP and Triggerbot when off", Callback = function(v)
        SETTINGS.Enabled = v
        if v then
            task.defer(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and not ESP_STORAGE[p.Character] then CreateESP(p, false) end
                end
                for _, name in ipairs(GetTargetFolders()) do
                    local folder = Workspace:FindFirstChild(name)
                    if folder then
                        for _, desc in ipairs(folder:GetDescendants()) do CheckItem(desc) end
                    end
                end
            end)
        end
    end})
    espTog.Set(SETTINGS.Enabled)
    local teamTog = GeneralGroup:Toggle({Name = "Team Check", Tooltip = "Don't show teammates", Callback = function(v) SETTINGS.TeamCheck = v end})
    teamTog.Set(SETTINGS.TeamCheck)
    GeneralGroup:Slider({Name = "Max Render Distance", Min = 100, Max = 2000, Default = SETTINGS.MaxRenderDistance, Unit = " studs", Callback = function(v) SETTINGS.MaxRenderDistance = v end})

    local PlayerESPGroup = MainTab:Group("Player ESP")
    local pEspTog = PlayerESPGroup:Toggle({Name = "Player ESP", Callback = function(v)
        SETTINGS.PlayerESP.Enabled = v
        if v and SETTINGS.Enabled then
            task.defer(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and not ESP_STORAGE[p.Character] then CreateESP(p, false) end
                end
            end)
        end
    end})
    pEspTog.Set(SETTINGS.PlayerESP.Enabled)
    PlayerESPGroup:ColorPicker({Name = "Box Color", Default = SETTINGS.PlayerESP.BoxColor, Callback = function(c) SETTINGS.PlayerESP.BoxColor = c end})
    PlayerESPGroup:ColorPicker({Name = "Highlight", Default = SETTINGS.PlayerESP.HighlightColor, Callback = function(c) SETTINGS.PlayerESP.HighlightColor = c end})
    local pNameTog = PlayerESPGroup:Toggle({Name = "Name", Callback = function(v) SETTINGS.PlayerESP.Name.Enabled = v end})
    pNameTog.Set(SETTINGS.PlayerESP.Name.Enabled)
    PlayerESPGroup:Slider({Name = "Name Size", Min = 10, Max = 24, Default = SETTINGS.PlayerESP.Name.Size, Callback = function(v) SETTINGS.PlayerESP.Name.Size = v end})
    local pDistTog = PlayerESPGroup:Toggle({Name = "Distance", Callback = function(v) SETTINGS.PlayerESP.Distance.Enabled = v end})
    pDistTog.Set(SETTINGS.PlayerESP.Distance.Enabled)
    PlayerESPGroup:Slider({Name = "Distance Size", Min = 10, Max = 20, Default = SETTINGS.PlayerESP.Distance.Size, Callback = function(v) SETTINGS.PlayerESP.Distance.Size = v end})
    PlayerESPGroup:ColorPicker({Name = "Distance Color", Default = SETTINGS.PlayerESP.Distance.Color, Callback = function(c) SETTINGS.PlayerESP.Distance.Color = c end})
    local     pHpBoxTog = PlayerESPGroup:Toggle({Name = "Health Bar", Callback = function(v) SETTINGS.PlayerESP.Health.Box.Enabled = v end})
    pHpBoxTog.Set(SETTINGS.PlayerESP.Health.Box.Enabled)
    local pHpTextTog = PlayerESPGroup:Toggle({Name = "Health Text", Callback = function(v) SETTINGS.PlayerESP.Health.Text.Enabled = v end})
    pHpTextTog.Set(SETTINGS.PlayerESP.Health.Text.Enabled)
    if not SETTINGS.PlayerESP.Health.Text.Size then SETTINGS.PlayerESP.Health.Text.Size = 13 end
    PlayerESPGroup:Slider({Name = "Health Text Size", Min = 8, Max = 24, Default = SETTINGS.PlayerESP.Health.Text.Size, Callback = function(v) SETTINGS.PlayerESP.Health.Text.Size = v end})
    local pWlTog = PlayerESPGroup:Toggle({Name = "Whitelist Enabled", Tooltip = "Hide ESP for whitelisted players", Callback = function(v) SETTINGS.PlayerESP.WhitelistEnabled = v end})
    pWlTog.Set(SETTINGS.PlayerESP.WhitelistEnabled)
    PlayerESPGroup:Textbox({Name = "Whitelist (comma-separated)", Default = table.concat(SETTINGS.PlayerESP.Whitelist or {}, ", "), Placeholder = "Player1, Player2", Callback = function(txt) SETTINGS.PlayerESP.Whitelist = parseWhitelistStr(txt) end})

    local NPCESPGroup = MainTab:Group("NPC ESP")
    local npcEspTog = NPCESPGroup:Toggle({Name = "NPC ESP", Callback = function(v)
        SETTINGS.NPC_ESP.Enabled = v
        if v and SETTINGS.Enabled then
            task.defer(function()
                for _, name in ipairs(GetTargetFolders()) do
                    local folder = Workspace:FindFirstChild(name)
                    if folder then
                        for _, desc in ipairs(folder:GetDescendants()) do CheckItem(desc) end
                    end
                end
            end)
        end
    end})
    npcEspTog.Set(SETTINGS.NPC_ESP.Enabled)
    NPCESPGroup:ColorPicker({Name = "Box Color", Default = SETTINGS.NPC_ESP.BoxColor, Callback = function(c) SETTINGS.NPC_ESP.BoxColor = c end})
    NPCESPGroup:ColorPicker({Name = "Highlight", Default = SETTINGS.NPC_ESP.HighlightColor, Callback = function(c) SETTINGS.NPC_ESP.HighlightColor = c end})
    local nNameTog = NPCESPGroup:Toggle({Name = "Name", Callback = function(v) SETTINGS.NPC_ESP.Name.Enabled = v end})
    nNameTog.Set(SETTINGS.NPC_ESP.Name.Enabled)
    NPCESPGroup:Slider({Name = "Name Size", Min = 10, Max = 24, Default = SETTINGS.NPC_ESP.Name.Size, Callback = function(v) SETTINGS.NPC_ESP.Name.Size = v end})
    local nDistTog = NPCESPGroup:Toggle({Name = "Distance", Callback = function(v) SETTINGS.NPC_ESP.Distance.Enabled = v end})
    nDistTog.Set(SETTINGS.NPC_ESP.Distance.Enabled)
    NPCESPGroup:Slider({Name = "Distance Size", Min = 10, Max = 20, Default = SETTINGS.NPC_ESP.Distance.Size, Callback = function(v) SETTINGS.NPC_ESP.Distance.Size = v end})
    NPCESPGroup:ColorPicker({Name = "Distance Color", Default = SETTINGS.NPC_ESP.Distance.Color, Callback = function(c) SETTINGS.NPC_ESP.Distance.Color = c end})
    local     nHpBoxTog = NPCESPGroup:Toggle({Name = "Health Bar", Callback = function(v) SETTINGS.NPC_ESP.Health.Box.Enabled = v end})
    nHpBoxTog.Set(SETTINGS.NPC_ESP.Health.Box.Enabled)
    local nHpTextTog = NPCESPGroup:Toggle({Name = "Health Text", Callback = function(v) SETTINGS.NPC_ESP.Health.Text.Enabled = v end})
    nHpTextTog.Set(SETTINGS.NPC_ESP.Health.Text.Enabled)
    if not SETTINGS.NPC_ESP.Health.Text.Size then SETTINGS.NPC_ESP.Health.Text.Size = 13 end
    NPCESPGroup:Slider({Name = "Health Text Size", Min = 8, Max = 24, Default = SETTINGS.NPC_ESP.Health.Text.Size, Callback = function(v) SETTINGS.NPC_ESP.Health.Text.Size = v end})
    local nWlTog = NPCESPGroup:Toggle({Name = "Whitelist Enabled", Tooltip = "Hide ESP for whitelisted NPCs by name", Callback = function(v) SETTINGS.NPC_ESP.WhitelistEnabled = v end})
    nWlTog.Set(SETTINGS.NPC_ESP.WhitelistEnabled)
    NPCESPGroup:Textbox({Name = "Whitelist (comma-separated)", Default = table.concat(SETTINGS.NPC_ESP.Whitelist or {}, ", "), Placeholder = "NPC1, Dummy", Callback = function(txt) SETTINGS.NPC_ESP.Whitelist = parseWhitelistStr(txt) end})

    local VisualsGroup = MainTab:Group("Global")
    local hTog = VisualsGroup:Toggle({Name = "Highlight", Callback = function(v) SETTINGS.Highlight.Enabled = v end})
    hTog.Set(SETTINGS.Highlight.Enabled)
    local boxTog = VisualsGroup:Toggle({Name = "Box", Callback = function(v) SETTINGS.Box.Enabled = v end})
    boxTog.Set(SETTINGS.Box.Enabled)
    VisualsGroup:Slider({Name = "Name Size Multiplier", Min = 50, Max = 200, Default = math.floor((SETTINGS.NameMultiplier or 1) * 100), Unit = "%", Callback = function(v) SETTINGS.NameMultiplier = v / 100 end})
    VisualsGroup:Slider({Name = "Distance Size Multiplier", Min = 50, Max = 200, Default = math.floor((SETTINGS.DistanceMultiplier or 1) * 100), Unit = "%", Callback = function(v) SETTINGS.DistanceMultiplier = v / 100 end})

    local CombatTab = _G.Library:Tab("Combat", 10455604811)
    local TriggerGroup = CombatTab:Group("Triggerbot")
    local trigTog = TriggerGroup:Toggle({Name = "Triggerbot Enabled", Callback = function(v) SETTINGS.Triggerbot.Enabled = v end})
    trigTog.Set(SETTINGS.Triggerbot.Enabled)
    local atkTog = TriggerGroup:Toggle({Name = "Attack NPCs", Callback = function(v) SETTINGS.Triggerbot.AttackNPCs = v end})
    atkTog.Set(SETTINGS.Triggerbot.AttackNPCs)
    local legsTog = TriggerGroup:Toggle({Name = "Shoot Legs", Callback = function(v) SETTINGS.Triggerbot.ShootLegs = v end})
    legsTog.Set(SETTINGS.Triggerbot.ShootLegs)
    TriggerGroup:Slider({Name = "Click Delay", Min = 0, Max = 500, Default = math.floor(SETTINGS.Triggerbot.ClickDelay * 1000), Unit = " ms", Callback = function(v) SETTINGS.Triggerbot.ClickDelay = v / 1000 end})
    local wlTog = TriggerGroup:Toggle({Name = "Whitelist Enabled", Tooltip = "Don't shoot whitelisted players/NPCs", Callback = function(v) SETTINGS.Triggerbot.WhitelistEnabled = v end})
    wlTog.Set(SETTINGS.Triggerbot.WhitelistEnabled)
    if not SETTINGS.Triggerbot.Whitelist then SETTINGS.Triggerbot.Whitelist = {} end
    TriggerGroup:Textbox({Name = "Whitelist (comma-separated)", Default = table.concat(SETTINGS.Triggerbot.Whitelist or {}, ", "), Placeholder = "Player1, NPC1", Callback = function(txt) SETTINGS.Triggerbot.Whitelist = parseWhitelistStr(txt) end})
    TriggerGroup:Slider({Name = "Max Distance", Min = 100, Max = 1500, Default = SETTINGS.Triggerbot.MaxDistance, Unit = " studs", Callback = function(v) SETTINGS.Triggerbot.MaxDistance = v end})
    TriggerGroup:Dropdown({Name = "Triggerbot Key", Options = {"Right Mouse", "Left Mouse"}, Default = SETTINGS.Triggerbot.ActiveKey == Enum.UserInputType.MouseButton2 and "Right Mouse" or "Left Mouse", Callback = function(opt)
        SETTINGS.Triggerbot.ActiveKey = (opt == "Right Mouse") and Enum.UserInputType.MouseButton2 or Enum.UserInputType.MouseButton1
    end})

    local SettingsTab = _G.Library:Tab("Settings", 12403097620)
    local SettingsGroup = SettingsTab:Group("Script")
    local teleTog = SettingsGroup:Toggle({Name = "Auto Execute On Teleport", Tooltip = "Re-run script after teleport", Callback = function(v) SETTINGS.AutoExecuteOnTeleport = v end})
    teleTog.Set(SETTINGS.AutoExecuteOnTeleport)
    SettingsGroup:Button({Name = "Unload", Variant = "Danger", Tooltip = "Stop script and close UI", Callback = function()
        _G.UNLOAD_KOMOHUB()
    end})

    _G.Library:Notify("KomoHub Loaded", "Success")
else
    warn("[KomoHub] UI _G.Library failed to load:", err)
end

local lastShot = 0
local function GetHeadParts()
    local t = SETTINGS.HeadParts
    if type(t) ~= "table" or #t == 0 then return DEFAULT_SETTINGS.HeadParts end
    return t
end

local function GetBodyParts()
    local t = SETTINGS.BodyParts
    if type(t) ~= "table" or #t == 0 then return DEFAULT_SETTINGS.BodyParts end
    return t
end

local function GetLegParts()
    local t = SETTINGS.LegParts
    if type(t) ~= "table" or #t == 0 then return DEFAULT_SETTINGS.LegParts end
    return t
end

local function GetTargetFolders()
    local tf = SETTINGS.TargetFolders
    if type(tf) ~= "table" or #tf == 0 then
        return DEFAULT_SETTINGS.TargetFolders
    end
    return tf
end

local function AddConnection(connection)
    table.insert(_G.PerkESP.Connections, connection)
    return connection
end

local function TrackDrawing(drawing)
    table.insert(_G.PerkESP.Drawings, drawing)
    return drawing
end

local function checkPart(partName)
    for _, name in pairs(GetHeadParts()) do if partName == name then return true end end
    for _, name in pairs(GetBodyParts()) do if partName == name then return true end end
    if SETTINGS.Triggerbot.ShootLegs then
        for _, name in pairs(GetLegParts()) do if partName == name then return true end end
    end
    return false
end

local function isWhitelisted(char, player)
    local tb = SETTINGS.Triggerbot
    if not tb or not tb.WhitelistEnabled then return false end
    return isInWhitelist(tb.Whitelist or {}, player, char)
end

local function isESPWhitelisted(char, player, config)
    if not config or not config.WhitelistEnabled then return false end
    return isInWhitelist(config.Whitelist or {}, player, char)
end

local function parseWhitelistStr(str)
    local out = {}
    if type(str) ~= "string" then return out end
    for s in string.gmatch(str:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1"), "[^,]+") do
        local name = s:match("^%s*(.-)%s*$")
        if #name > 0 then
            local lower = name:lower()
            local found = false
            for _, existing in ipairs(out) do
                if existing:lower() == lower then found = true break end
            end
            if not found then table.insert(out, name) end
        end
    end
    return out
end

local function isInWhitelist(wl, player, char)
    if type(wl) ~= "table" or #wl == 0 then return false end
    local function matches(name)
        if not name or #name == 0 then return false end
        local lower = name:lower()
        for _, entry in ipairs(wl) do
            if type(entry) == "string" and entry:lower() == lower then return true end
        end
        return false
    end
    if player and (matches(player.Name) or matches(player.DisplayName)) then return true end
    if char and matches(char.Name) then return true end
    return false
end

local function getRoot(model)
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model.PrimaryPart
end

local function getChar(part)
    local current = part
    while current and current ~= Workspace do
        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then return current end
        current = current.Parent
    end
    return nil
end

local function getVisual(config, key, subkey, default)
    local c = config and config[key]
    if subkey then
        c = c and c[subkey]
    end
    if c ~= nil then return c end
    local g = SETTINGS[key]
    if subkey then g = g and g[subkey] end
    return g ~= nil and g or default
end

local function ManageHighlight(character, shouldShow, color)
    local highlight = character:FindFirstChild("PerkHighlight")
    if shouldShow and SETTINGS.Highlight.Enabled then
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "PerkHighlight"
            highlight.Parent = character
        end
        if highlight.FillColor ~= color then highlight.FillColor = color end
        highlight.FillTransparency = SETTINGS.Highlight.FillTransparency
        highlight.OutlineColor = Color3.new(1,1,1)
    else
        if highlight then highlight:Destroy() end
    end
end

local function CreateESP(target, isNPC)
    local character = isNPC and target or target.Character
    if not character or ESP_STORAGE[character] then return end

    local root = getRoot(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    local drawings = {
        Box = TrackDrawing(Drawing.new("Square")),
        Name = TrackDrawing(Drawing.new("Text")),
        Dist = TrackDrawing(Drawing.new("Text")),
        HealthBg = TrackDrawing(Drawing.new("Square")),
        HealthMain = TrackDrawing(Drawing.new("Square")),
        HealthText = TrackDrawing(Drawing.new("Text")),
        IsNPC = isNPC,
        CachedRoot = root,
        CachedHum = hum,
        CachedChar = character,
        Player = isNPC and nil or target,
        Connections = {}
    }

    for _, d in pairs(drawings) do
        if typeof(d) == "userdata" then
            d.Visible = false
            pcall(function() d.ZIndex = 0 end)
        end
    end

    drawings.Box.Filled = false
    drawings.HealthBg.Filled = true
    drawings.HealthMain.Filled = true
    drawings.Name.Center, drawings.Dist.Center, drawings.HealthText.Center = true, true, true
    drawings.Name.Outline, drawings.Dist.Outline, drawings.HealthText.Outline = true, true, true

    drawings.Connections[#drawings.Connections + 1] = AddConnection(character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            RemoveESP(character)
        end
    end))

    drawings.Connections[#drawings.Connections + 1] = AddConnection(hum.Died:Connect(function()
        RemoveESP(character)
    end))

    ESP_STORAGE[character] = drawings
end

local function RemoveESP(obj)
    if not obj then return end

    -- 允許傳入任意部件（例如 Humanoid、BodyPart 等），會自動往上找到對應角色 Model
    local charKey = obj
    local data = ESP_STORAGE[charKey]

    if not data and typeof(obj) == "Instance" then
        local char = getChar(obj)
        if char then
            charKey = char
            data = ESP_STORAGE[charKey]
        end
    end

    if not data then return end

    if data.Connections then
        for _, conn in ipairs(data.Connections) do
            if conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
    end

    if data.CachedChar then
        pcall(function()
            ManageHighlight(data.CachedChar, false)
        end)
    end

    for _, drawing in pairs(data) do
        if typeof(drawing) == "userdata" and drawing.Remove then
            drawing.Visible = false
            drawing:Remove()
        end
    end

    ESP_STORAGE[charKey] = nil
end

local function CastPiercingRay(origin, direction, params, depth)
    depth = depth or 0
    if depth > 3 then return nil end 
    local result = Workspace:Raycast(origin, direction, params)
    if result then
        local hit = result.Instance
        local char = getChar(hit)
        if char and checkPart(hit.Name) then return result end
        if (hit.Transparency >= 0.8 or not hit.CanCollide or not hit.CanQuery) and not char then
            local newOrigin = result.Position + (direction.Unit * 0.1)
            return CastPiercingRay(newOrigin, direction - (newOrigin - origin), params, depth + 1)
        end
    end
    return result
end

local function CheckItem(item)
    if not item or not item.Parent then return end

    -- 嘗試從任意子物件往上找到 NPC Model
    local char = item

    if not (item:IsA("Model") and item:FindFirstChildOfClass("Humanoid")) then
        char = getChar(item)
    end

    if not char or ESP_STORAGE[char] then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- 排除玩家角色，只處理 NPC
    if Players:GetPlayerFromCharacter(char) then return end

    if getRoot(char) then
        CreateESP(char, true)
    end
end

local function SetupNPCFolder(folder)
    if not folder or CONNECTED_FOLDERS[folder] then return end
    CONNECTED_FOLDERS[folder] = true

    -- 先掃描這個資料夾目前已存在的所有 NPC
    for _, desc in ipairs(folder:GetDescendants()) do
        CheckItem(desc)
    end

    AddConnection(folder.DescendantAdded:Connect(function(child)
        task.delay(0.05, function()
            if child and child:IsDescendantOf(folder) then
                CheckItem(child)
            end
        end)
    end))

    AddConnection(folder.DescendantRemoving:Connect(function(child)
        if not child then return end

        if ESP_STORAGE[child] then
            RemoveESP(child)
            return
        end

        local char = getChar(child)
        if char and ESP_STORAGE[char] then
            RemoveESP(char)
        end
    end))
end

local function WaitForLocalCharacter()
    local char = LocalPlayer.Character
    if not char or not char.Parent then
        char = LocalPlayer.CharacterAdded:Wait()
    end

    if char then
        pcall(function()
            char:WaitForChild("HumanoidRootPart", 5)
        end)
    end

    return char
end

-- 初始化所有目標資料夾與未來新生成的資料夾
local function InitNPCFolderEvents()
    local targetFolders = GetTargetFolders()
    for _, name in ipairs(targetFolders) do
        local folder = Workspace:FindFirstChild(name)
        if folder then
            SetupNPCFolder(folder)
        end
    end

    AddConnection(Workspace.ChildAdded:Connect(function(child)
        if child and child:IsA("Folder") then
            local currentTargets = GetTargetFolders()
            if table.find(currentTargets, child.Name) then
                SetupNPCFolder(child)
            end
        end
    end))
end

local function SetupPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then
        CreateESP(player, false)
    end
    AddConnection(player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        CreateESP(player, false)
    end))
end

local function AuditESP()
    while true do
        if _G.PerkESP_Unloading then break end
        task.wait(3)

        for char, data in pairs(ESP_STORAGE) do
            local character = data.CachedChar
            local hum = data.CachedHum

            if not character or not character:IsDescendantOf(Workspace) or not hum or hum.Health <= 0 then
                RemoveESP(char)
            else
                if data.Player and (not Players:FindFirstChild(data.Player.Name) or data.Player.Character ~= character) then
                    RemoveESP(char)
                end
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not ESP_STORAGE[p.Character] then
                CreateESP(p, false)
            end
        end
    end
end

local function InitializePerk()
    local char = WaitForLocalCharacter()
    if not char then return end

    for _, p in ipairs(Players:GetPlayers()) do
        SetupPlayer(p)
    end

    AddConnection(Players.PlayerAdded:Connect(SetupPlayer))
    AddConnection(Players.PlayerRemoving:Connect(function(p)
        if p.Character then
            RemoveESP(p.Character)
        end
    end))

    InitNPCFolderEvents()

    local renderConn = RunService.RenderStepped:Connect(function()
        if _G.PerkESP_Unloading then return end
        if not SETTINGS.Enabled then
            for _, drawings in pairs(ESP_STORAGE) do
                for _, key in ipairs({"Box", "Name", "Dist", "HealthBg", "HealthMain", "HealthText"}) do
                    local d = drawings[key]
                    if d and typeof(d) == "userdata" then
                        d.Visible = false
                    end
                end
                if drawings.CachedChar then
                    pcall(function() ManageHighlight(drawings.CachedChar, false) end)
                end
            end
            local allDrawings = _G.PerkESP and _G.PerkESP.Drawings
            if allDrawings then
                for i = 1, #allDrawings do
                    local d = allDrawings[i]
                    if d and typeof(d) == "userdata" and d.Visible then
                        pcall(function() d.Visible = false end)
                    end
                end
            end
            return
        end

        local hasESP = next(ESP_STORAGE) ~= nil
        local camPos = Camera.CFrame.Position
        local fovFactor = math.tan(math.rad(Camera.FieldOfView / 2)) * 2

        if SETTINGS.Triggerbot.Enabled and UserInputService:IsMouseButtonPressed(SETTINGS.Triggerbot.ActiveKey) then
            local mousePos = UserInputService:GetMouseLocation()
            local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

            local result = CastPiercingRay(ray.Origin, ray.Direction * SETTINGS.Triggerbot.MaxDistance, params)
            if result and result.Instance then
                local c = getChar(result.Instance)
                if c and c ~= LocalPlayer.Character then
                    local dist = (camPos - result.Position).Magnitude
                    if dist <= SETTINGS.MaxRenderDistance then
                        local hum = c:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local targetP = Players:GetPlayerFromCharacter(c)
                            if isWhitelisted(c, targetP) then
                                return
                            end
                            local canShoot = (targetP and (not SETTINGS.TeamCheck or targetP.Team ~= LocalPlayer.Team)) or (not targetP and SETTINGS.Triggerbot.AttackNPCs)
                            if canShoot and (tick() - lastShot) > SETTINGS.Triggerbot.ClickDelay then
                                lastShot = tick()
                                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                                task.spawn(function()
                                    task.wait(0.01)
                                    VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                                end)
                            end
                        end
                    end
                end
            end
        end

        if SETTINGS.Enabled and hasESP then
            local toRemove = {}
            local toRespawn = {}

            for char, drawings in pairs(ESP_STORAGE) do
                local character = drawings.CachedChar
                local root = drawings.CachedRoot
                local hum = drawings.CachedHum

                local config = drawings.IsNPC and SETTINGS.NPC_ESP or SETTINGS.PlayerESP
                local isActuallyVisible = false

                if not character or not character.Parent then
                    table.insert(toRemove, char)
                else
                    if not drawings.IsNPC and drawings.Player and drawings.Player.Character and drawings.Player.Character ~= character then
                        table.insert(toRespawn, drawings.Player)
                        table.insert(toRemove, char)
                    else
                        if not root or not root.Parent then
                            root = getRoot(character)
                            drawings.CachedRoot = root
                        end
                        if not hum or not hum.Parent then
                            hum = character:FindFirstChildOfClass("Humanoid")
                            drawings.CachedHum = hum
                        end

                        if root and root.Parent and hum and hum.Health > 0 and config.Enabled then
                            local isTeammate = SETTINGS.TeamCheck and drawings.Player and drawings.Player.Team and LocalPlayer.Team and drawings.Player.Team == LocalPlayer.Team
                            if isTeammate then
                                if character then ManageHighlight(character, false) end
                            elseif isESPWhitelisted(character, drawings.Player, config) then
                                if character then ManageHighlight(character, false) end
                            else
                                local rootPos = root.Position
                                local dist = (camPos - rootPos).Magnitude

                                if dist <= SETTINGS.MaxRenderDistance then
                                    local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)

                                    if onScreen then
                                        isActuallyVisible = true
                                        ManageHighlight(character, true, config.HighlightColor)

                                        local nameEnabled = getVisual(config, "Name", "Enabled", true)
                                        local nameSize = math.floor((getVisual(config, "Name", "Size", 16)) * (SETTINGS.NameMultiplier or 1))
                                        local distEnabled = getVisual(config, "Distance", "Enabled", true)
                                        local distSize = math.floor((getVisual(config, "Distance", "Size", 14)) * (SETTINGS.DistanceMultiplier or 1))
                                        local distColor = getVisual(config, "Distance", "Color", SETTINGS.Distance.Color)
                                        local healthBoxEnabled = (config.Health and config.Health.Box and config.Health.Box.Enabled ~= nil) and config.Health.Box.Enabled or SETTINGS.Health.Box.Enabled
                                        local healthTextEnabled = (config.Health and config.Health.Text and config.Health.Text.Enabled ~= nil) and config.Health.Text.Enabled or SETTINGS.Health.Text.Enabled
                                        local healthTextSize = (config.Health and config.Health.Text and config.Health.Text.Size) or SETTINGS.Health.Text.Size or 13

                                        local scale = 1 / (dist * fovFactor) * 1000
                                        local w, h = scale * 6, scale * 8
                                        local x, y = screenPos.X - w/2, screenPos.Y - h/2

                                        drawings.Box.Visible = SETTINGS.Box.Enabled
                                        drawings.Box.Size = Vector2.new(w, h)
                                        drawings.Box.Position = Vector2.new(x, y)
                                        drawings.Box.Color = config.BoxColor

                                        drawings.Name.Visible = nameEnabled
                                        drawings.Name.Size = nameSize
                                        if drawings.IsNPC then
                                            drawings.Name.Text = "[NPC] " .. character.Name
                                        elseif drawings.Player then
                                            drawings.Name.Text = drawings.Player.Name
                                        else
                                            drawings.Name.Text = character.Name
                                        end
                                        drawings.Name.Position = Vector2.new(screenPos.X, y - 20)
                                        drawings.Name.Color = config.BoxColor

                                        local healthP = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

                                        drawings.HealthBg.Visible = healthBoxEnabled
                                        drawings.HealthBg.Size = Vector2.new(w, 5)
                                        drawings.HealthBg.Position = Vector2.new(x, y + h + 5)

                                        drawings.HealthMain.Visible = healthBoxEnabled
                                        drawings.HealthMain.Size = Vector2.new(w * healthP, 5)
                                        drawings.HealthMain.Position = Vector2.new(x, y + h + 5)
                                        drawings.HealthMain.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthP)

                                        drawings.HealthText.Visible = healthTextEnabled
                                        drawings.HealthText.Size = healthTextSize
                                        drawings.HealthText.Text = string.format("HP: %d%%", math.floor(healthP * 100))
                                        drawings.HealthText.Position = Vector2.new(screenPos.X, y + h + 15)
                                        drawings.HealthText.Color = Color3.fromRGB(0, 255, 0)

                                        drawings.Dist.Visible = distEnabled
                                        drawings.Dist.Size = distSize
                                        drawings.Dist.Text = math.floor(dist) .. " studs"
                                        drawings.Dist.Position = Vector2.new(screenPos.X, y + h + 25)
                                        drawings.Dist.Color = distColor
                                    end
                                end
                            end
                        elseif not root or not root.Parent or not hum or hum.Health <= 0 then
                            table.insert(toRemove, char)
                        end
                    end
                end

                if not isActuallyVisible then
                    drawings.Box.Visible = false
                    drawings.Name.Visible = false
                    drawings.HealthBg.Visible = false
                    drawings.HealthMain.Visible = false
                    drawings.HealthText.Visible = false
                    drawings.Dist.Visible = false
                    if character then ManageHighlight(character, false) end
                end
            end

            for _, charRemove in ipairs(toRemove) do
                RemoveESP(charRemove)
            end

            if #toRespawn > 0 then
                local seen = {}
                for _, plr in ipairs(toRespawn) do
                    if plr and not seen[plr] then
                        seen[plr] = true
                        CreateESP(plr, false)
                    end
                end
            end
        end
    end)
    AddConnection(renderConn)
    _G.PerkESP.RenderConnection = renderConn

    task.spawn(AuditESP)

    if SETTINGS.AutoExecuteOnTeleport then
        local queue_on_teleport_fn = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if queue_on_teleport_fn then
            local teleportConn = LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Started then
                    queue_on_teleport_fn([[loadstring(game:HttpGet("https://raw.githubusercontent.com/commoi370381/KomoHub/refs/heads/main/Main.lua"))()]])
                end
            end)
            AddConnection(teleportConn)
        end
    end
end

pcall(InitializePerk)
