local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Drawing = Drawing or {}

local selectedPart = "Head"
local wallCheck = true
local teamCheck = false
local povEnabled = true
local povSize = 50
local aimMode = "Blatant"
local playerList = {}

local aimCircle = Drawing.new("Circle")
aimCircle.Color = Color3.fromRGB(255, 0, 0)
aimCircle.Thickness = 2
aimCircle.NumSides = 50
aimCircle.Filled = false
aimCircle.Visible = false
aimCircle.Radius = povSize

local function isWallBetween(targetPart)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = (targetPos - origin).unit
    local distance = (targetPos - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local blacklist = {LocalPlayer.Character, targetPart.Parent}
    if teamCheck then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Team == LocalPlayer.Team and player.Character then
                table.insert(blacklist, player.Character)
            end
        end
    end

    raycastParams.FilterDescendantsInstances = blacklist
    raycastParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction * distance, raycastParams)
    return result ~= nil and result.Instance.CanCollide
end

local function isValidPlayer(player)
    if player == LocalPlayer or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if teamCheck and player.Team == LocalPlayer.Team then return false end
    return true
end

local function updatePlayerList()
    playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if not teamCheck or (teamCheck and player.Team ~= LocalPlayer.Team) then
                    table.insert(playerList, player)
                end
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(updatePlayerList)
end)

Players.PlayerRemoving:Connect(updatePlayerList)
RunService.Heartbeat:Connect(updatePlayerList)

local function getNearestEnemy()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local nearestPlayer = nil
    local minDistance = povSize

    for _, player in ipairs(playerList) do
        if isValidPlayer(player) then
            local targetPart = player.Character:FindFirstChild(selectedPart) or player.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screenPosition, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - screenCenter).Magnitude
                
                if onScreen and distance < minDistance then
                    if wallCheck and isWallBetween(targetPart) then
                        continue
                    end
                    minDistance = distance
                    nearestPlayer = targetPart
                end
            end
        end
    end

    return nearestPlayer
end

local function smoothAim(targetPosition)
    local tween = TweenService:Create(Camera, TweenInfo.new(0.03, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)})
    tween:Play()
end

local function updatePOVAim()
    if povEnabled then
        local nearestEnemy = getNearestEnemy()
        if nearestEnemy then
            if aimMode == "Blatant" then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearestEnemy.Position)
            else
                smoothAim(nearestEnemy.Position)
            end
        end
    end
end

local Window = Rayfield:CreateWindow({
    Name = "Aenis.cc",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Aenis"
    }
})

local CameraTab = Window:CreateTab("Camera Settings", 4483345998)

CameraTab:CreateDropdown({
    Name = "Select Part",
    Options = {"Head", "Torso"},
    CurrentOption = "Head",
    Callback = function(value)
        selectedPart = value
    end
})

CameraTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Callback = function(state)
        wallCheck = state
    end
})

CameraTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(state)
        teamCheck = state
        updatePlayerList()
    end
})

local POVTab = Window:CreateTab("FOV", 4483345998)

POVTab:CreateToggle({
    Name = "Enable FOV",
    CurrentValue = false,
    Callback = function(state)
        povEnabled = state
        aimCircle.Visible = state
    end
})

POVTab:CreateInput({
    Name = "FOV Size (1-100)",
    PlaceholderText = "50",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 and num <= 100 then
            povSize = num
            aimCircle.Radius = num
        end
    end
})

POVTab:CreateDropdown({
    Name = "Aim Mode",
    Options = {"Blatant", "Non-Blatant"},
    CurrentOption = "Blatant",
    Callback = function(value)
        aimMode = value
    end
})

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        repeat task.wait() until player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        updatePlayerList()
    end)
end)

Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

RunService.RenderStepped:Connect(function()
    if povEnabled then
        updatePOVAim()
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        aimCircle.Position = screenCenter
    end
end)

Rayfield:Notify({
    Title = "Open-Source",
    Content = "This is an open-source script, you can modify it freely.",
    Duration = 8
})

Rayfield:LoadConfiguration()
