--[[
	PlayerData - Módulo de gestión de datos del jugador
	Ubicación: ServerScriptService.Server.DataStore.PlayerData
	
	Responsabilidades:
		- Cargar datos del jugador desde DataStore (o usar defaults)
		- Mantener los datos en caché (SessionData) durante la sesión
		- Sincronizar los datos con los leaderstats del jugador
		- Guardar datos al DataStore cuando se solicite
	
	Uso desde otros scripts del servidor:
		local PlayerData = require(ruta.DataStore.PlayerData)
		
		PlayerData:Load(player)                        --> carga datos y sincroniza leaderstats
		PlayerData:Get(player)                         --> obtiene la tabla de SessionData
		PlayerData:UpdateStat(player, "Stage", 42)     --> actualiza SessionData + leaderstats
		PlayerData:Save(player)                        --> guarda SessionData en DataStore
		PlayerData:Remove(player)                      --> limpia SessionData de memoria
]]

local Settings = require(script.Parent.Settings)
local DSS = require(script.Parent.DatastoreService)


local PlayerData = {}
local SessionData = {}


local function deepCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = typeof(v) == "table" and deepCopy(v) or v
	end
	return copy
end


---------------------------------------------------------------------------
-- SINCRONIZACIÓN CON LEADERSTATS
-- Actualiza los ValueObjects del leaderboard con los datos de SessionData.
-- Usa WaitForChild con timeout para manejar la race condition con
-- Leaderstats.server.luau (que crea el folder en su propio PlayerAdded).
---------------------------------------------------------------------------

--- Sincroniza TODOS los datos de SessionData al leaderstats del jugador
local function syncToLeaderstats(player)
	local data = SessionData[player]
	if not data then return end

	-- Esperar a que Leaderstats.server.luau cree el folder (máximo 10 segundos)
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		warn("[PlayerData] No se encontró leaderstats para " .. player.Name .. " (timeout)")
		return
	end

	for statName, value in data do
		local stat = leaderstats:FindFirstChild(statName)
		if stat then
			stat.Value = value
		end
	end
end


---------------------------------------------------------------------------
-- FUNCIONES PÚBLICAS
---------------------------------------------------------------------------

--- Carga los datos del jugador desde DataStore y sincroniza con leaderstats
function PlayerData:Load(player)
	local data = DSS:Get(player.UserId)

	if not data then
		data = deepCopy(Settings.DefaultData)
	end

	SessionData[player] = data

	-- Sincronizar datos cargados con los leaderstats del jugador
	syncToLeaderstats(player)

	return data
end


--- Obtiene la tabla completa de SessionData del jugador
function PlayerData:Get(player)
	return SessionData[player]
end


--[[
	Actualiza un stat individual en SessionData Y en el leaderstats.
	Esta es la forma recomendada de modificar datos del jugador
	ya que mantiene ambos sistemas sincronizados.
	
	Ejemplo:
		PlayerData:UpdateStat(player, "Stage", 42)
		PlayerData:UpdateStat(player, "Coins", 100)
]]
function PlayerData:UpdateStat(player, statName: string, value: any)
	local data = SessionData[player]
	if not data then
		warn("[PlayerData] ⚠️ No hay datos en sesión para " .. player.Name)
		return
	end

	-- Actualizar en SessionData (caché en memoria)
	data[statName] = value

	-- Actualizar en leaderstats (UI del leaderboard)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local stat = leaderstats:FindFirstChild(statName)
		if stat then
			stat.Value = value
		end
	end
end


--- Guarda los datos del jugador en DataStore
function PlayerData:Save(player)
	if SessionData[player] then
		DSS:Set(player.UserId, SessionData[player])
	end
end


--- Elimina los datos del jugador de la memoria (después de guardar)
function PlayerData:Remove(player)
	SessionData[player] = nil
end


return PlayerData