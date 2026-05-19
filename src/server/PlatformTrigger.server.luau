local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local PlayerData = require(script.Parent.DataStore.PlayerData)

local DEBOUNCE_TIME = 0.5
local debounce = {}

local function setupPlatformTrigger(part)
	part.Touched:Connect(function(hit)
		-- Verificar que sea un personaje de jugador
		local character = hit.Parent
		if not character then return end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Debounce
		if debounce[player.UserId] then return end
		debounce[player.UserId] = true

		-- Obtener el nombre del parent como número
		local parentName = part.Parent.Name
		local stageNumber = tonumber(parentName)

		if stageNumber then
			-- Actualizar Stage en PlayerData (y automáticamente en leaderstats)
			PlayerData:UpdateStat(player, "Stage", stageNumber)

			-- Actualizar MaxStage si es un nuevo récord
			local data = PlayerData:Get(player)
			if data and stageNumber > (data["Max Stage"] or 0) then
				PlayerData:UpdateStat(player, "Max Stage", stageNumber)
			end
		else
			warn("[PlatformTrigger] El parent '" .. parentName .. "' no es un número válido")
		end

		task.delay(DEBOUNCE_TIME, function()
			debounce[player.UserId] = nil
		end)
	end)
end

-- Configurar triggers existentes al iniciar
for _, part in ipairs(CollectionService:GetTagged("PlatformTrigger")) do
	if part:IsA("BasePart") then
		setupPlatformTrigger(part)
	end
end

-- Configurar triggers que se agreguen después (ej. clonados)
CollectionService:GetInstanceAddedSignal("PlatformTrigger"):Connect(function(part)
	if part:IsA("BasePart") then
		setupPlatformTrigger(part)
	end
end)

print("[PlatformTrigger] Sistema inicializado correctamente")