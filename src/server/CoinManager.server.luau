local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.DataStore.PlayerData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local COOLDOWN_DURATION = 60
local cooldowns = {} -- [player.UserId] = { [coinModel] = lastCollectedTimestamp }

local function setupCoinTrigger(part: BasePart)
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Validar que el jugador tenga sus datos cargados
		local data = PlayerData:Get(player)
		if not data then return end

		local coinModel = part.Parent
		if not coinModel or not coinModel:IsA("Model") then return end

		-- Inicializar tabla de cooldowns para el jugador si no existe
		if not cooldowns[player.UserId] then
			cooldowns[player.UserId] = {}
		end

		local playerCooldowns = cooldowns[player.UserId]
		local lastCollected = playerCooldowns[coinModel]
		local currentTime = os.clock()

		-- Validar si el cooldown está activo
		if lastCollected and (currentTime - lastCollected) < COOLDOWN_DURATION then
			return
		end

		-- Registrar/Actualizar timestamp del cooldown
		playerCooldowns[coinModel] = currentTime

		-- Incrementar Coins en el sistema PlayerData
		local currentCoins = data.Coins or 0
		PlayerData:UpdateStat(player, "Coins", currentCoins + 1)

		-- Enviar evento al cliente de este jugador específico para que oculte la moneda
		Remotes.CoinCollected:FireClient(player, coinModel)
	end)
end

-- Limpieza de cooldowns cuando los jugadores se desconectan
Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.UserId] = nil
end)

-- Configurar los triggers existentes al iniciar el juego
for _, part in ipairs(CollectionService:GetTagged("CoinTrigger")) do
	if part:IsA("BasePart") then
		setupCoinTrigger(part)
	end
end

-- Escuchar por nuevos triggers agregados dinámicamente
CollectionService:GetInstanceAddedSignal("CoinTrigger"):Connect(function(part)
	if part:IsA("BasePart") then
		setupCoinTrigger(part)
	end
end)

print("[CoinManager Server] Inicializado correctamente")
