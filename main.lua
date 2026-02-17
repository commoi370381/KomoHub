local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- CLEANUP OLD INSTANCES
if _G.PerkESP then
    if _G.PerkESP.Connections then
        for _, connection in pairs(_G.PerkESP.Connections) do
            if connection then connection:Disconnect() end
        end
    end
    
    if _G.PerkESP.Drawings then
        for _, drawing in pairs(_G.PerkESP.Drawings) do
            if drawing and drawing.Remove then drawing:Remove() end
        end
    end
    _G.PerkESP = nil
end

_G.PerkESP = {
    Connections = {},
    Drawings = {}
}

-- CONFIGURATION
local SETTINGS = {
    Enabled = true,
    TeamCheck = false,
    MaxRenderDistance = 800, 
    
    -- Auto-Execute Logic (Save script to autoexec folder for best results)
    AutoExecuteOnTeleport = true,
    MyScriptURL = "", 

    Triggerbot = {
        Enabled = true,
        AttackNPCs = true, 
        ActiveKey = Enum.UserInputType.MouseButton2,
        ShootLegs = true,
        ClickDelay = 0.08, 
        WhitelistEnabled = true,
        Whitelist = {"SunSand_Stick"},
        MaxDistance = 800,
    },

    PlayerESP = {
        Enabled = true,
        BoxColor = Color3.fromRGB(255, 255, 255),
        HighlightColor = Color3.fromRGB(255, 0, 0)
    },

    NPC_ESP = {
        Enabled = true,
        BoxColor = Color3.fromRGB(255, 255, 0),
        HighlightColor = Color3.fromRGB(255, 165, 0)
    },

    Highlight = { Enabled = true, FillTransparency = 0.5, OutlineTransparency = 0 },
    Box = { Enabled = true, Thickness = 1.5 },
    Name = { Enabled = true, Size = 16, Outline = true },
    Distance = { Enabled = true, Color = Color3.fromRGB(255, 255, 255), Size = 14, Outline = true },
    Health = {
        Box = { Enabled = true, Height = 5, Offset = 5 },
        Text = { Enabled = true, Size = 13, Outline = true, Format = "HP: %d%%" }
    }
}

local TARGET_FOLDER_NAMES = {
    "ShootingRangeEntities",
    "Mobs",
    "NPCs",
    "Enemies",
    "Dummies"
}

local lastShot = 0
local ValidParts = {"Head", "UpperTorso", "LowerTorso", "Torso", "LeftArm", "RightArm", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand"}
local LegParts = {"LeftLeg", "RightLeg", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"}
local ESP_STORAGE = {}
local CONNECTED_FOLDERS = {} -- Prevents double-connecting events

-- Utility Functions
local function AddConnection(connection)
    table.insert(_G.PerkESP.Connections, connection)
    return connection
end

local function TrackDrawing(drawing)
    table.insert(_G.PerkESP.Drawings, drawing)
    return drawing
end

local function checkPart(partName)
    for _, name in pairs(ValidParts) do if partName == name then return true end end
    if SETTINGS.Triggerbot.ShootLegs then
        for _, name in pairs(LegParts) do if partName == name then return true end end
    end
    return false
end

local function getRoot(model)
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model.PrimaryPart
end

local function getChar(part)
    local current = part
    while current and current ~= workspace do
        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then return current end
        current = current.Parent
    end
    return nil
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

local function CreateESP(obj, isNPC)
    if ESP_STORAGE[obj] then return end
    
    local character = isNPC and obj or obj.Character
    if not character then return end

    local root = getRoot(character)
    local hum = character:FindFirstChildOfClass("Humanoid")

    if not root or not hum then return end 

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
        CachedChar = character
    }

    for _, d in pairs(drawings) do
        if typeof(d) == "userdata" then d.Visible = false end
    end

    drawings.Box.Filled = false
    drawings.HealthBg.Filled = true
    drawings.HealthMain.Filled = true
    drawings.Name.Center, drawings.Dist.Center, drawings.HealthText.Center = true, true, true
    drawings.Name.Outline, drawings.Dist.Outline, drawings.HealthText.Outline = true, true, true

    ESP_STORAGE[obj] = drawings
end

local function RemoveESP(obj)
    if ESP_STORAGE[obj] then
        for _, drawing in pairs(ESP_STORAGE[obj]) do 
            if typeof(drawing) == "userdata" and drawing.Remove then 
                drawing.Visible = false 
                drawing:Remove() 
            end 
        end
        ESP_STORAGE[obj] = nil
    end
end

local function CastPiercingRay(origin, direction, params, depth)
    depth = depth or 0
    if depth > 3 then return nil end 
    local result = workspace:Raycast(origin, direction, params)
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

-- NEW: Helper to check a single item
local function CheckItem(item)
    if item:IsA("Model") then
        local hum = item:FindFirstChildOfClass("Humanoid")
        if hum then
            if not Players:GetPlayerFromCharacter(item) and not ESP_STORAGE[item] then
                 if getRoot(item) and hum.Health > 0 then
                     CreateESP(item, true)
                 end
            end
        end
    end
end

-- NEW: Recursive Scan that attaches listeners
local function RecursiveScan(parent, depth)
    depth = depth or 0
    if depth > 50 then return end 

    local items = parent:GetChildren()
    for i, item in ipairs(items) do
        if i % 200 == 0 then task.wait() end 

        if item:IsA("Model") then
            CheckItem(item)
        elseif item:IsA("Folder") then
            -- Connect listener to folder if not already connected
            if not CONNECTED_FOLDERS[item] then
                CONNECTED_FOLDERS[item] = true
                AddConnection(item.ChildAdded:Connect(function(child)
                    -- Wait for child to load properties
                    task.delay(0.1, function() CheckItem(child) end)
                end))
            end
            RecursiveScan(item, depth + 1)
        end
    end
end

local function ScanForNPCs()
    local foldersToScan = {} 
    
    for _, name in pairs(TARGET_FOLDER_NAMES) do
        local folder = workspace:FindFirstChild(name)
        if folder then table.insert(foldersToScan, folder) end
    end

    task.spawn(function()
        for _, folder in ipairs(foldersToScan) do
            -- Connect listener to main folder
            if not CONNECTED_FOLDERS[folder] then
                CONNECTED_FOLDERS[folder] = true
                AddConnection(folder.ChildAdded:Connect(function(child)
                     task.delay(0.1, function() CheckItem(child) end)
                end))
            end
            pcall(function()
                RecursiveScan(folder)
            end)
        end
    end)
end

-- Setup Players
local function SetupPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then CreateESP(player, false) end
    AddConnection(player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        CreateESP(player, false)
    end))
end

for _, p in ipairs(Players:GetPlayers()) do SetupPlayer(p) end
AddConnection(Players.PlayerAdded:Connect(SetupPlayer))
AddConnection(Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end))

-- BACKGROUND LOGIC: Auto-Repair + Scanner
local lastScanTime = 0
AddConnection(RunService.Heartbeat:Connect(function()
    -- Scan every 3 seconds for folders, but Events handle instant spawns
    if tick() - lastScanTime > 3 then
        lastScanTime = tick()
        ScanForNPCs()
        
        -- Auto-Repair Audit
        for obj, data in pairs(ESP_STORAGE) do
            local isValid = true
            
            -- If parent is nil, it streamed out. Remove immediately.
            if not obj or not obj.Parent then
                isValid = false
            else
                 local char = data.CachedChar
                 local root = data.CachedRoot
                 local hum = data.CachedHum
                 if not char or not char.Parent or not root or not root.Parent or not hum or hum.Health <= 0 then
                    isValid = false
                 end
            end
            
            if not isValid then
                RemoveESP(obj) 
            end
        end
    end
end))

-- RENDER LOGIC
AddConnection(RunService.RenderStepped:Connect(function()
    if not SETTINGS.Enabled then return end
    
    local camPos = Camera.CFrame.Position
    local fovFactor = math.tan(math.rad(Camera.FieldOfView / 2)) * 2

    -- TRIGGERBOT
    if SETTINGS.Triggerbot.Enabled and UIS:IsMouseButtonPressed(SETTINGS.Triggerbot.ActiveKey) then
        local mousePos = UIS:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        
        local result = CastPiercingRay(ray.Origin, ray.Direction * SETTINGS.Triggerbot.MaxDistance, params)
        if result and result.Instance then
            local char = getChar(result.Instance)
            if char and char ~= LocalPlayer.Character then
                local dist = (camPos - result.Position).Magnitude
                if dist <= SETTINGS.MaxRenderDistance then 
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local targetP = Players:GetPlayerFromCharacter(char)
                        local canShoot = (targetP and (not SETTINGS.TeamCheck or targetP.Team ~= LocalPlayer.Team)) or (not targetP and SETTINGS.Triggerbot.AttackNPCs)
                        if canShoot and (tick() - lastShot) > SETTINGS.Triggerbot.ClickDelay then
                            lastShot = tick()
                            VIM:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                            task.spawn(function()
                                task.wait(0.01)
                                VIM:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                            end)
                        end
                    end
                end
            end
        end
    end

    -- ESP RENDER
    for obj, drawings in pairs(ESP_STORAGE) do
        local character = drawings.CachedChar
        local root = drawings.CachedRoot
        local hum = drawings.CachedHum
        
        -- Player Respawn Check
        if not drawings.IsNPC and obj.Character and obj.Character ~= character then
            RemoveESP(obj)
            CreateESP(obj, false)
        end

        local config = drawings.IsNPC and SETTINGS.NPC_ESP or SETTINGS.PlayerESP
        local isActuallyVisible = false

        if not character or not character.Parent or not root or not root.Parent or not hum or hum.Health <= 0 then
            -- Audit loop will remove, just hide for now
            isActuallyVisible = false
        else
            if config.Enabled then
                local rootPos = root.Position
                local dist = (camPos - rootPos).Magnitude
                
                if dist <= SETTINGS.MaxRenderDistance then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)
                    
                    if onScreen then
                        isActuallyVisible = true
                        ManageHighlight(character, true, config.HighlightColor)
                        
                        local scale = 1 / (dist * fovFactor) * 1000
                        local w, h = scale * 6, scale * 8
                        local x, y = screenPos.X - w/2, screenPos.Y - h/2

                        drawings.Box.Visible = SETTINGS.Box.Enabled
                        drawings.Box.Size = Vector2.new(w, h)
                        drawings.Box.Position = Vector2.new(x, y)
                        drawings.Box.Color = config.BoxColor

                        drawings.Name.Visible = SETTINGS.Name.Enabled
                        drawings.Name.Text = (drawings.IsNPC and "[NPC] " .. character.Name or obj.Name)
                        drawings.Name.Position = Vector2.new(screenPos.X, y - 20)
                        drawings.Name.Color = config.BoxColor
                        
                        local healthP = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        
                        drawings.HealthBg.Visible = SETTINGS.Health.Box.Enabled
                        drawings.HealthBg.Size = Vector2.new(w, 5)
                        drawings.HealthBg.Position = Vector2.new(x, y + h + 5)
                        
                        drawings.HealthMain.Visible = SETTINGS.Health.Box.Enabled
                        drawings.HealthMain.Size = Vector2.new(w * healthP, 5)
                        drawings.HealthMain.Position = Vector2.new(x, y + h + 5)
                        drawings.HealthMain.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthP)
                        
                        drawings.HealthText.Visible = SETTINGS.Health.Text.Enabled
                        drawings.HealthText.Text = string.format("HP: %d%%", math.floor(healthP * 100))
                        drawings.HealthText.Position = Vector2.new(screenPos.X, y + h + 15)
                        drawings.HealthText.Color = Color3.fromRGB(0, 255, 0)

                        drawings.Dist.Visible = SETTINGS.Distance.Enabled
                        drawings.Dist.Text = math.floor(dist) .. " studs"
                        drawings.Dist.Position = Vector2.new(screenPos.X, y + h + 25)
                        drawings.Dist.Color = SETTINGS.Distance.Color
                    end
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
end))

-- TELEPORT HANDLER
if SETTINGS.AutoExecuteOnTeleport then
    local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if queue_on_teleport then
        AddConnection(LocalPlayer.OnTeleport:Connect(function(State)
            if State == Enum.TeleportState.Started then
                if SETTINGS.MyScriptURL ~= "" then
                    queue_on_teleport('loadstring(game:HttpGet("'..SETTINGS.MyScriptURL..'"))()')
                end
            end
        end))
    end
end

StarterGui:SetCore("SendNotification", {Title = "Perk Loaded", Text = "Instant Refresh (Events) Active", Duration = 5})