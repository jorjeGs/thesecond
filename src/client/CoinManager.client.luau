local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local COOLDOWN_DURATION = 60

local function findCoinPart(coinModel: Instance): BasePart?
	local targetNames = {"COIN", "Coin", "coin"}
	-- 1. Buscar inmediatamente
	for _, name in targetNames do
		local part = coinModel:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end

	-- 2. Esperar brevemente por si está cargando (StreamingEnabled)
	for _, name in targetNames do
		local part = coinModel:WaitForChild(name, 2)
		if part and part:IsA("BasePart") then
			return part
		end
	end

	-- 3. Buscar cualquier parte que contenga "coin" o "moneda" en su nombre
	for _, child in coinModel:GetChildren() do
		if child:IsA("BasePart") then
			local lowerName = string.lower(child.Name)
			if string.find(lowerName, "coin") or string.find(lowerName, "moneda") then
				return child
			end
		end
	end

	-- 4. Fallback al PrimaryPart
	if coinModel:IsA("Model") and coinModel.PrimaryPart then
		return coinModel.PrimaryPart
	end

	-- 5. Fallback a la primera BasePart que encontremos
	for _, child in coinModel:GetChildren() do
		if child:IsA("BasePart") then
			return child
		end
	end

	return nil
end

local function onCoinCollected(coinModel: Instance)
	if not coinModel or not coinModel:IsA("Model") then 
		warn("[CoinManager Client] El objeto recibido no es un Model válido: " .. tostring(coinModel))
		return 
	end

	local coinPart = findCoinPart(coinModel)
	if coinPart then
		-- Hacer la parte visual de la moneda invisible
		coinPart.Transparency = 1

		-- Programar que vuelva a aparecer después de 60 segundos de forma no bloqueante
		task.delay(COOLDOWN_DURATION, function()
			-- Validar que la moneda y la parte sigan existiendo en el juego
			if coinModel.Parent and coinPart.Parent then
				coinPart.Transparency = 0
			end
		end)
	else
		warn("[CoinManager Client] No se encontró una parte visual de moneda válida (ej. 'Coin' o 'COIN') en el modelo: " .. coinModel.Name)
	end
end

-- Escuchar cuando el servidor nos notifique de una recolección válida
Remotes.CoinCollected.OnClientEvent:Connect(onCoinCollected)

print("[CoinManager Client] Inicializado correctamente")
