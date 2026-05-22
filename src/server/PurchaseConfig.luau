--[[
	PurchaseConfig - Configuración de compras del juego
	Ubicación: ServerScriptService.Server.PurchaseConfig
	
	Responsabilidades:
		- Registrar IDs de Developer Products y sus funciones de recompensa.
		- Registrar IDs de GamePasses y sus beneficios.
		
	Instrucciones:
		- Reemplaza los IDs de ejemplo (1234567 y 7654321) por los IDs reales de tu juego en Roblox.
]]

local PlayerData = require(script.Parent.DataStore.PlayerData)

local PurchaseConfig = {}

-- DICCIONARIO DE DEVELOPER PRODUCTS (Productos de Desarrollador)
-- Estructura: [ID_NUMERICO] = callback(player) -> boolean
PurchaseConfig.Products = {

	-- Skip Stage
	[3596942758] = function(player: Player)
		local data = PlayerData:Get(player)
		if not data then return false end

		local currentMaxStage = data["Max Stage"] or 0
		local nextStage = currentMaxStage + 1

		-- Actualizar stats
		PlayerData:UpdateStat(player, "Max Stage", nextStage)
		PlayerData:UpdateStat(player, "Stage", nextStage)

		-- Teleportar jugador al siguiente stage
		local platforms = game.Workspace:FindFirstChild("Plataformas")
		if platforms then
			local targetModel = platforms:FindFirstChild(tostring(nextStage))
			if targetModel and targetModel:IsA("Model") and targetModel.PrimaryPart then
				local character = player.Character
				if character then
					local root = character:FindFirstChild("HumanoidRootPart")
					if root then
						root.CFrame = CFrame.new(targetModel.PrimaryPart.CFrame.Position + Vector3.new(0, 5, 0)) * CFrame.Angles(0, math.rad(-90), 0)
					end
				end
			end
		end

		print(("[PurchaseConfig] Compra exitosa. Se compro SKIP STAGE a %s. Nuevo Stage: %d"):format(player.Name, nextStage))
		return true
	end,
	
}

-- DICCIONARIO DE GAMEPASSES
-- Estructura: [ID_NUMERICO] = callback(player) -> ()
PurchaseConfig.GamePasses = {
	
	-- EJEMPLO: Súper Velocidad (WalkSpeed = 32)
	-- Reemplaza 7654321 por el ID real de tu GamePass
	[7654321] = function(player: Player)
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 32
			end
		end
		print(("[PurchaseConfig] Se aplicó el beneficio de Súper Velocidad a %s"):format(player.Name))
	end,
	
}

return PurchaseConfig
