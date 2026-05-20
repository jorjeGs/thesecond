local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerData = require(game.ServerScriptService.Server.DataStore:WaitForChild("PlayerData"))
local Remotes = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

-- CONFIG
local PLATFORMS_FOLDER = "Plataformas"
local COOLDOWN = 1

local cooldowns = {} -- { [Player] = tick }

-- Obtener CFrame del Stage
local function getStageCFrame(stage)
	if stage == 0 then
		local part0 = Workspace:FindFirstChild("0")
		if part0 and part0:IsA("BasePart") then
			return part0.CFrame
		end
		return nil
	end

	local platforms = Workspace:FindFirstChild(PLATFORMS_FOLDER)
	if not platforms then return nil end

	local model = platforms:FindFirstChild(tostring(stage))
	if not model or not model:IsA("Model") then return nil end
	if not model.PrimaryPart then return nil end

	return model.PrimaryPart.CFrame
end

-- Escuchar peticiones de teleport desde la UI del cliente
Remotes.TeleportToStage.OnServerEvent:Connect(function(player, requestedStage)
	-- Validar tipo
	if typeof(requestedStage) ~= "number" then return end
	requestedStage = math.floor(requestedStage)

	-- Cooldown
	local now = tick()
	if cooldowns[player] and (now - cooldowns[player]) < COOLDOWN then return end

	-- Validar contra datos del jugador
	local data = PlayerData:Get(player)
	if not data then return end

	local maxStage = data["Max Stage"] or 0

	-- Solo puede teleportarse a stages entre 0 y su MaxStage
	if requestedStage < 0 or requestedStage > maxStage then return end

	-- Verificar que la plataforma existe
	local cframe = getStageCFrame(requestedStage)
	if not cframe then return end

	-- Teleportar
	local character = player.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	cooldowns[player] = now
	root.CFrame = CFrame.new(cframe.Position + Vector3.new(0, 5, 0)) * CFrame.Angles(0, math.rad(-90), 0)

	-- Actualizar el Stage actual del jugador
	PlayerData:UpdateStat(player, "Stage", requestedStage)
end)

-- Limpiar cooldown al salir
Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)

print("[StageTeleport] Sistema de teleport por UI inicializado")
