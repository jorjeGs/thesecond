local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local COOLDOWN_DURATION = 60
local REWARD_FLOAT_DURATION = 3
local REWARD_TWEEN_INFO = TweenInfo.new(REWARD_FLOAT_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function formatRewardAmount(amount: number): string
	local formatted = string.format("%.2f", amount)
	formatted = string.gsub(formatted, "%.?0+$", "")
	return formatted
end

local function showCoinRewardText(amount: number)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then return end

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	-- Dispersión aleatoria para evitar que múltiples textos se encabalguen
	local randomX = (math.random() * 3) - 1.5
	local randomZ = (math.random() * 3) - 1.5

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "CoinRewardFloat"
	billboardGui.Adornee = rootPart
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 0
	billboardGui.Size = UDim2.fromOffset(180, 70)
	billboardGui.StudsOffset = Vector3.new(randomX, 2.5, randomZ)
	billboardGui.Parent = playerGui

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Text = "+$" .. formatRewardAmount(amount)
	textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	textLabel.TextScaled = true
	textLabel.TextStrokeTransparency = 1
	textLabel.Parent = billboardGui

	local uiStroke = Instance.new("UIStroke")
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	uiStroke.Color = Color3.fromRGB(80, 40, 0)
	uiStroke.Thickness = 3
	uiStroke.Transparency = 0
	uiStroke.Parent = textLabel

	TweenService:Create(billboardGui, REWARD_TWEEN_INFO, {
		StudsOffset = Vector3.new(randomX, 6, randomZ),
	}):Play()
	TweenService:Create(textLabel, REWARD_TWEEN_INFO, {
		TextTransparency = 1,
	}):Play()
	TweenService:Create(uiStroke, REWARD_TWEEN_INFO, {
		Transparency = 1,
	}):Play()

	task.delay(REWARD_FLOAT_DURATION, function()
		if billboardGui.Parent then
			billboardGui:Destroy()
		end
	end)
end

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

	-- 6. No se encontró ninguna parte
	return nil
end

local function onCoinCollected(coinModel: Instance, coinsEarned: number?)
	if not coinModel or not coinModel:IsA("Model") then 
		warn("[CoinManager Client] El objeto recibido no es un Model válido: " .. tostring(coinModel))
		return 
	end

	local coinPart = findCoinPart(coinModel)
	if coinPart then
		-- Hacer la parte visual de la moneda invisible
		coinPart.Transparency = 1

		-- Reproducir el sonido CoinCollect desde SoundService
		local coinSound = SoundService:FindFirstChild("CoinCollect", true)
		if coinSound and coinSound:IsA("Sound") then
			coinSound:Play()
		else
			warn("[CoinManager Client] No se encontró el sonido 'CoinCollect' en SoundService")
		end

		-- Programar que vuelva a aparecer después de 60 segundos de forma no bloqueante
		showCoinRewardText(coinsEarned or 1)

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
