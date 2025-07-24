local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MAX_WALKSPEED = 24 -- Max sprint speed
local MAX_JUMP_HEIGHT = 8 -- Max jump height
local COOLDOWN = 0.2 -- Check interval

local playerData = {} -- Server-side player data (position, inventory, currency)

Players.PlayerAdded:Connect(function(player)
    playerData[player.UserId] = {
        LastPosition = nil,
        LastCheckTime = tick(),
        Inventory = {}, -- {WeaponName = ammoCount}
        Currency = 0
    }
end)

RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        local char = player.Character
        local data = playerData[player.UserId]
        if char and char.HumanoidRootPart then
            local currentPos = char.HumanoidRootPart.Position
            local currentSpeed = char.Humanoid.WalkSpeed
            local currentHeight = char.HumanoidRootPart.Position.Y

            -- Speed Hack Detection
            if currentSpeed > MAX_WALKSPEED then
                char.Humanoid.WalkSpeed = MAX_WALKSPEED
                WarnPlayer(player, "Speed hack detected")
            end

            -- Fly Hack Detection
            if data.LastPosition and (currentPos.Y - data.LastPosition.Y) > MAX_JUMP_HEIGHT then
                if not IsInVehicle(player) then
                    KickPlayer(player, "Fly hack detected")
                end
            end

            -- Update last position
            data.LastPosition = currentPos
        end
    end
end)

-- RemoteEvent for shooting
game.ReplicatedStorage:WaitForChild("FireWeapon").OnServerEvent:Connect(function(player), args)
    local weapon = args.Weapon
    local ammo = args.Ammo
    local data = playerData[player.UserId]

    -- Validate weapon
    if not data.Inventory[weapon] or data.Inventory[weapon] < ammo then
        KickPlayer(player, "Invalid weapon detected")
    else
        -- Process shot
        ValidateShot(player, args.Origin, args.Direction, weapon)
        data.Inventory[weapon] = data.Ammo - ammo
    end
end)

function WarnPlayer(player, reason)
    -- Log to external server or DataStore
    print("Warning: " .. player.Name .. " - " .. reason)
end

function KickPlayer(player, reason)
    player:Kick(reason)
    -- Log to external server
end

function ValidateShot(player, origin, direction, weapon)
    -- Raycast to verify hit
    local params = RaycastParams.new()
    params.FilterDescendants = {player.Character}
    local result = workspace:Raycast(origin, direction * 100, params)
    if result and result.Instance.Parent:FindFirstChild("Humanoid") then
        -- Apply damage based on weapon
    else
        WarnPlayer(player, "Invalid shot trajectory")
    end
end