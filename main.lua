local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

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

    Triggerbot = {
        Enabled = true,
        AttackNPCs = true, 
        ActiveKey = Enum.UserInputType.MouseButton2,
        ShootLegs = true,
        ClickDelay = 0.08, 
        WhitelistEnabled = true,
        Whitelist = {},
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

local SETTINGS = _G.PerkESP_Settings or DEFAULT_SETTINGS
_G.PerkESP_Settings = SETTINGS

local lastShot = 0
local ValidParts = {"Head", "UpperTorso", "LowerTorso", "Torso", "LeftArm", "RightArm", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand"}
local LegParts = {"LeftLeg", "RightLeg", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"}
local ESP_STORAGE = {}
local CONNECTED_FOLDERS = {}

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
    for _, name in pairs(ValidParts) do if partName == name then return true end end
    if SETTINGS.Triggerbot.ShootLegs then
        for _, name in pairs(LegParts) do if partName == name then return true end end
    end
    return false
end

local function isWhitelisted(char, player)
    local tb = SETTINGS.Triggerbot
    if not tb or not tb.WhitelistEnabled then return false end
    local wl = tb.Whitelist
    if type(wl) ~= "table" or #wl == 0 then return false end
    if player and table.find(wl, player.Name) then return true end
    if char and table.find(wl, char.Name) then return true end
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
        if typeof(d) == "userdata" then d.Visible = false end
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

local function CheckItem(item)
    if not item:IsA("Model") then return end
    if ESP_STORAGE[item] then return end

    local hum = item:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    if Players:GetPlayerFromCharacter(item) then return end

    if getRoot(item) then
        CreateESP(item, true)
    end
end

local function SetupNPCFolder(folder)
    if not folder or CONNECTED_FOLDERS[folder] then return end
    CONNECTED_FOLDERS[folder] = true

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
        local folder = workspace:FindFirstChild(name)
        if folder then
            SetupNPCFolder(folder)
        end
    end

    AddConnection(workspace.ChildAdded:Connect(function(child)
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
        task.wait(3)

        for char, data in pairs(ESP_STORAGE) do
            local character = data.CachedChar
            local hum = data.CachedHum

            if not character or not character:IsDescendantOf(workspace) or not hum or hum.Health <= 0 then
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

    AddConnection(RunService.RenderStepped:Connect(function()
        if not SETTINGS.Triggerbot.Enabled and not SETTINGS.Enabled then
            return
        end

        local hasESP = next(ESP_STORAGE) ~= nil
        local camPos = Camera.CFrame.Position
        local fovFactor = math.tan(math.rad(Camera.FieldOfView / 2)) * 2

        if SETTINGS.Triggerbot.Enabled and UIS:IsMouseButtonPressed(SETTINGS.Triggerbot.ActiveKey) then
            local mousePos = UIS:GetMouseLocation()
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
                        else
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

            for _, char in ipairs(toRemove) do
                RemoveESP(char)
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
    end))

    task.spawn(AuditESP)

    if SETTINGS.AutoExecuteOnTeleport then
        local queue_on_teleport_fn = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if queue_on_teleport_fn then
            queue_on_teleport_fn([[loadstring(game:HttpGet("https://raw.githubusercontent.com/commoi370381/KomoHub/refs/heads/main/main.lua"))()]])

            AddConnection(LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Started then
                    queue_on_teleport_fn([[loadstring(game:HttpGet("https://raw.githubusercontent.com/commoi370381/KomoHub/refs/heads/main/main.lua"))()]])
                end
            end))
        end
    end

    StarterGui:SetCore("SendNotification", {Title = "LOADED", Text = "Script Active", Duration = 5})
end

pcall(InitializePerk)