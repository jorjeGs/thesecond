local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

-- Esperar leaderstats (usamos math.huge para evitar warnings de espera infinita)
local leaderstats = player:WaitForChild("leaderstats", math.huge)
local stageStat = leaderstats:WaitForChild("Stage", math.huge)
local maxStageStat = leaderstats:WaitForChild("Max Stage", math.huge)

-- CONFIG
local COOLDOWN = 1
local lastTeleportTime = 0

-- Referencia a la UI actual
local currentStageText = nil

-- Stage que se está visualizando en la UI
local viewedStage = stageStat.Value

-- Actualizar el texto del label
local function updateDisplay()
	if currentStageText then
		currentStageText.Text = "Stage " .. viewedStage
	end
end

-- Intentar teleportar (con cooldown)
local function requestTeleport(newStage)
	local now = tick()
	if (now - lastTeleportTime) < COOLDOWN then return false end

	lastTeleportTime = now
	viewedStage = newStage
	updateDisplay()
	Remotes.TeleportToStage:FireServer(newStage)
	return true
end

-- Conectar la interfaz cada vez que se crea (en cada respawn)
local function setupGUI()
	-- math.huge le dice a Roblox que espere sin lanzar advertencias
	local gameGui = playerGui:WaitForChild("GameGui", math.huge)
	local stageFrame = gameGui:WaitForChild("StageFrame", math.huge)
	
	currentStageText = stageFrame:WaitForChild("StageText", math.huge)
	local backArrow = stageFrame:WaitForChild("BackArrow", math.huge)
	local nextArrow = stageFrame:WaitForChild("NextArrow", math.huge)

	-- Actualizar UI recién creada
	updateDisplay()

	-- Botón retroceder (<)
	backArrow.MouseButton1Click:Connect(function()
		local maxStage = maxStageStat.Value
		if viewedStage > 0 then
			requestTeleport(viewedStage - 1)
		else
			requestTeleport(maxStage)
		end
	end)

	-- Botón avanzar (>)
	nextArrow.MouseButton1Click:Connect(function()
		local maxStage = maxStageStat.Value
		if viewedStage < maxStage then
			requestTeleport(viewedStage + 1)
		else
			requestTeleport(0)
		end
	end)
end

-- Escuchar respawns
player.CharacterAdded:Connect(setupGUI)

-- Ejecutar inmediatamente si el personaje ya existe al cargar el script
if player.Character then
	task.spawn(setupGUI)
end

-- Sincronizar cuando el Stage cambie desde el servidor (ej. PlatformTrigger)
stageStat.Changed:Connect(function(newStage)
	viewedStage = newStage
	updateDisplay()
end)
