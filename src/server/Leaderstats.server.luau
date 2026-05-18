--[[
	Leaderstats Template - Sistema configurable de leaderstats
	Ubicación: ServerScriptService.Server.Leaderstats
	
	INSTRUCCIONES:
	1. Edita la tabla STATS_CONFIG para definir tus stats
	2. Cada stat necesita: name, type, default, order
	3. "order" controla el orden visual en la leaderboard (menor = más a la izquierda)
	
	Tipos soportados:
		IntValue, NumberValue, StringValue, BoolValue,
		Vector3Value, CFrameValue, Color3Value, BrickColorValue, ObjectValue
	
	Para modificar stats desde otros scripts:
		local Stats = require(game.ReplicatedStorage.Shared.StatsManager)
		Stats.Get(player, "Coins")
		Stats.Set(player, "Coins", 200)
		Stats.Add(player, "Coins", 50)
		Stats.Increment(player, "Coins")
	
	Nota: La persistencia de datos se maneja desde DataStore/.
	Este script SOLO controla la creación y visualización del leaderboard.
]]

local Players = game:GetService("Players")

---------------------------------------------------------------------------
-- ⚙️ CONFIGURACIÓN - Edita esta tabla para cada proyecto
---------------------------------------------------------------------------
local STATS_CONFIG = {
	{ name = "Nivel",  type = "IntValue",  default = 0,  order = 1 },
	{ name = "Coins",  type = "IntValue",  default = 0,  order = 2 },
}
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- MAPA DE TIPOS VÁLIDOS
-- Valida que el tipo de stat sea correcto antes de crear la instancia.
-- Evita errores crípticos de Instance.new() si se escribe mal un tipo.
---------------------------------------------------------------------------
local VALID_TYPES: { [string]: boolean } = {
	IntValue        = true,
	NumberValue     = true,
	StringValue     = true,
	BoolValue       = true,
	Vector3Value    = true,
	CFrameValue     = true,
	Color3Value     = true,
	BrickColorValue = true,
	ObjectValue     = true,
}

---------------------------------------------------------------------------
-- VALIDACIÓN Y ORDENAMIENTO
---------------------------------------------------------------------------

-- Ordenar la config por el campo "order"
table.sort(STATS_CONFIG, function(a, b)
	return a.order < b.order
end)

-- Validar tipos al inicio (detectar errores de configuración temprano)
for _, config in STATS_CONFIG do
	if not VALID_TYPES[config.type] then
		error(("[Leaderstats] Tipo inválido '%s' para stat '%s'. Tipos válidos: IntValue, NumberValue, StringValue, BoolValue, Vector3Value, CFrameValue, Color3Value, BrickColorValue, ObjectValue"):format(
			tostring(config.type), tostring(config.name)
		))
	end
end

---------------------------------------------------------------------------
-- SETUP DEL JUGADOR
---------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	-- task.defer asegura que el player esté completamente listo
	-- antes de manipular sus children (buena práctica defensiva)
	task.defer(function()
		-- Verificar si ya tiene leaderstats (evitar duplicados, ej: reconexión rápida)
		if player:FindFirstChild("leaderstats") then
			warn("[Leaderstats] El jugador " .. player.Name .. " ya tiene leaderstats. Se omite la creación.")
			return
		end

		-- Crear la carpeta leaderstats
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"

		-- Crear cada stat en el orden configurado
		for _, config in STATS_CONFIG do
			-- Verificar duplicados dentro del folder (por si acaso)
			if leaderstats:FindFirstChild(config.name) then
				warn(("[Leaderstats] Stat '%s' duplicado en config. Se omite."):format(config.name))
				continue
			end

			local stat = Instance.new(config.type)
			stat.Name = config.name
			stat.Value = config.default
			stat.Parent = leaderstats
		end

		-- Asignar leaderstats al jugador
		leaderstats.Parent = player
	end)
end

---------------------------------------------------------------------------
-- CONEXIONES
---------------------------------------------------------------------------

Players.PlayerAdded:Connect(onPlayerAdded)

-- Manejar jugadores que ya estaban antes de que el script cargara (Studio Play)
for _, player in Players:GetPlayers() do
	if not player:FindFirstChild("leaderstats") then
		task.spawn(onPlayerAdded, player)
	end
end

print("[Leaderstats] Sistema inicializado correctamente")
