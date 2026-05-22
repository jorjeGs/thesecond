--[[
	PurchaseManager - Controlador central de compras en el servidor
	Ubicación: ServerScriptService.Server.PurchaseManager
	
	Responsabilidades:
		- Escuchar y procesar la compra de Developer Products (ProcessReceipt).
		- Verificar y otorgar beneficios de GamePasses al entrar el jugador y al ser comprados.
		- Sincronizar con PlayerData para asegurar que las recompensas de Developer Products se guarden inmediatamente.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local PlayerData = require(script.Parent.DataStore.PlayerData)
local PurchaseConfig = require(script.Parent.PurchaseConfig)

-- Tabla caché en memoria para los GamePasses activos de cada jugador
-- Estructura: [player] = { [passId] = true }
local activeGamePasses = {}

---------------------------------------------------------------------------
-- 🎮 GESTIÓN DE GAMEPASSES
---------------------------------------------------------------------------

-- Aplica el beneficio de un GamePass de forma segura
local function applyGamePass(player: Player, passId: number)
	local handler = PurchaseConfig.GamePasses[passId]
	if not handler then return end
	
	task.spawn(function()
		local success, err = pcall(handler, player)
		if not success then
			warn(("[PurchaseManager] Error al aplicar GamePass %d para %s: %s"):format(passId, player.Name, tostring(err)))
		end
	end)
end

-- Verifica la propiedad de todos los GamePasses registrados cuando el jugador entra
local function checkPlayerGamePasses(player: Player)
	activeGamePasses[player] = {}
	
	for passId in pairs(PurchaseConfig.GamePasses) do
		task.spawn(function()
			local success, ownsPass = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			
			if success and ownsPass then
				-- Guardar en caché para reaplicaciones al reaparecer (ej. velocidad)
				local playerPasses = activeGamePasses[player]
				if playerPasses then
					playerPasses[passId] = true
				end
				
				applyGamePass(player, passId)
			elseif not success then
				warn(("[PurchaseManager] Error al verificar propiedad de GamePass %d para %s: %s"):format(passId, player.Name, tostring(ownsPass)))
			end
		end)
	end
end

-- Escuchar cuando una compra de GamePass finaliza con éxito en juego
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, wasPurchased: boolean)
	if wasPurchased and PurchaseConfig.GamePasses[passId] then
		if not activeGamePasses[player] then
			activeGamePasses[player] = {}
		end
		activeGamePasses[player][passId] = true
		applyGamePass(player, passId)
	end
end)

---------------------------------------------------------------------------
-- 💎 GESTIÓN DE DEVELOPER PRODUCTS (ProcessReceipt)
---------------------------------------------------------------------------

local function processReceipt(receiptInfo)
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local purchaseId = receiptInfo.PurchaseId
	
	-- 1. Intentar encontrar al jugador en el servidor
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		warn(("[PurchaseManager] El jugador con UserId %d no está en el servidor. Reintentando compra %s luego."):format(playerId, purchaseId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- 2. Buscar si el producto tiene un callback registrado
	local handler = PurchaseConfig.Products[productId]
	if not handler then
		warn(("[PurchaseManager] Producto con ID %d no registrado en PurchaseConfig. Se ignora."):format(productId))
		return Enum.ProductPurchaseDecision.PurchaseGranted -- Se descarta porque no existe lógica para este ID
	end
	
	-- 3. Ejecutar el callback de recompensa
	local handlerSuccess, handlerResult = pcall(handler, player)
	if not handlerSuccess or not handlerResult then
		warn(("[PurchaseManager] Error al ejecutar recompensa para producto %d (Jugador: %s): %s"):format(productId, player.Name, tostring(handlerResult or "retornó false/nil")))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- 4. Forzar el guardado inmediato de los datos del jugador
	local saveSuccess = PlayerData:Save(player)
	if not saveSuccess then
		warn(("[PurchaseManager] ⚠️ No se pudo guardar datos de %s tras comprar producto %d. Reintentando luego para evitar pérdida de datos."):format(player.Name, productId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	print(("[PurchaseManager] Compra de Developer Product %d procesada y guardada correctamente para %s (PurchaseId: %s)"):format(productId, player.Name, purchaseId))
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Registrar el callback oficial para procesar recibos de compra
MarketplaceService.ProcessReceipt = processReceipt

---------------------------------------------------------------------------
-- 🌐 CICLO DE VIDA DE JUGADORES
---------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	-- Al reaparecer el personaje, volver a aplicar los GamePasses activos (físicos/estado)
	player.CharacterAdded:Connect(function(character)
		-- Esperar a que el personaje esté listo en el árbol del Workspace
		task.wait()
		local playerPasses = activeGamePasses[player]
		if playerPasses then
			for passId in pairs(playerPasses) do
				applyGamePass(player, passId)
			end
		end
	end)
	
	-- Verificar GamePasses que ya posea al unirse
	checkPlayerGamePasses(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Manejar jugadores que ya estaban antes de que el script se cargara (ej. Studio Play)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	activeGamePasses[player] = nil
end)

print("[PurchaseManager Server] Sistema inicializado y escuchando compras")
