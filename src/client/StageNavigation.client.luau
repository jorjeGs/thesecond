local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

-- Esperar la GUI
local playerGui = player:WaitForChild("PlayerGui")
local gameGui = playerGui:WaitForChild("GameGui")
local stageFrame = gameGui:WaitForChild("StageFrame")
local stageText = stageFrame:WaitForChild("StageText")
local backArrow = stageFrame:WaitForChild("BackArrow")
local nextArrow = stageFrame:WaitForChild("NextArrow")

-- Esperar leaderstats
local leaderstats = player:WaitForChild("leaderstats")
local stageStat = leaderstats:WaitForChild("Stage")
local maxStageStat = leaderstats:WaitForChild("Max Stage")

-- CONFIG
local COOLDOWN = 1
local lastTeleportTime = 0

-- Stage que se está visualizando en la UI (no necesariamente el actual)
local viewedStage = stageStat.Value

-- Actualizar el texto del label
local function updateDisplay()
	stageText.Text = "Stage " .. viewedStage
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

-- Inicializar
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

-- Sincronizar cuando el Stage cambie desde el servidor (ej. PlatformTrigger)
stageStat.Changed:Connect(function(newStage)
	viewedStage = newStage
	updateDisplay()
end)
