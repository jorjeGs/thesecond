local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats", math.huge)
local stageStat = leaderstats:WaitForChild("Stage", math.huge)

local plataformasFolder = workspace:WaitForChild("Plataformas", math.huge)

-- Referencias a los elementos de la GUI
local gameGui = playerGui:WaitForChild("GameGui", math.huge)
local progressFrame = gameGui:WaitForChild("ProgressFrame", math.huge)
local background = progressFrame:WaitForChild("Background", math.huge)
local progress = background:WaitForChild("Progress", math.huge)

-- Info para animar la barra de progreso de forma suave
local TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Función para actualizar la barra de progreso
local function updateProgressBar()
	local totalPlatforms = #plataformasFolder:GetChildren()
	local stage = stageStat.Value
	
	local ratio = 0
	if totalPlatforms > 0 then
		ratio = math.clamp(stage / totalPlatforms, 0, 1)
	end
	
	-- Animación suave del tamaño (escala en X de 0 a 1)
	local targetSize = UDim2.fromScale(ratio, 1)
	local tween = TweenService:Create(progress, TWEEN_INFO, {Size = targetSize})
	tween:Play()
end

-- Escuchar cuando cambia la cantidad de plataformas (por si el servidor clona más de forma asíncrona)
plataformasFolder.ChildAdded:Connect(updateProgressBar)
plataformasFolder.ChildRemoved:Connect(updateProgressBar)

-- Escuchar cuando cambia el Stage del jugador
stageStat.Changed:Connect(updateProgressBar)

-- Inicializar la barra al cargar el script o respawnear
local function setupGUI()
	-- Volver a buscar las referencias de la UI por si se reseteó en respawn
	gameGui = playerGui:WaitForChild("GameGui", math.huge)
	progressFrame = gameGui:WaitForChild("ProgressFrame", math.huge)
	background = progressFrame:WaitForChild("Background", math.huge)
	progress = background:WaitForChild("Progress", math.huge)
	
	updateProgressBar()
end

-- Conectar el setup al renacer del personaje (por si ResetOnSpawn está activo en el ScreenGui)
player.CharacterAdded:Connect(setupGUI)

-- Ejecución inicial
if player.Character then
	task.spawn(setupGUI)
else
	-- Si el personaje no ha cargado aún, de todos modos actualizamos el estado inicial
	updateProgressBar()
end

print("[ProgressBar Client] Inicializado y escuchando cambios de Stage y plataformas")
