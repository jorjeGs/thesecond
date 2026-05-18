--[[
	StatsManager - Módulo helper para manipular leaderstats
	Ubicación: ReplicatedStorage.Shared.StatsManager
	
	Uso desde cualquier server script:
		local Stats = require(game.ReplicatedStorage.Shared.StatsManager)
		
		Stats.Get(player, "Monedas")          --> obtiene el valor actual
		Stats.Set(player, "Monedas", 200)     --> establece a 200
		Stats.Add(player, "Monedas", 50)      --> suma 50 (solo Int/NumberValue)
		Stats.Increment(player, "Kills")      --> suma 1 (solo Int/NumberValue)
	
	Tipos soportados:
		IntValue, NumberValue, StringValue, BoolValue,
		Vector3Value, CFrameValue, Color3Value, BrickColorValue, ObjectValue
]]

local StatsManager = {}

---------------------------------------------------------------------------
-- FUNCIONES INTERNAS
---------------------------------------------------------------------------

--- Obtiene la carpeta leaderstats del jugador
local function getLeaderstatsFolder(player: Player): Folder?
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn("[StatsManager] leaderstats no encontrado para " .. player.Name)
		return nil
	end
	return leaderstats
end

--- Obtiene la instancia del stat (IntValue, StringValue, etc.)
function StatsManager._getStat(player: Player, statName: string): Instance?
	local leaderstats = getLeaderstatsFolder(player)
	if not leaderstats then
		return nil
	end

	local stat = leaderstats:FindFirstChild(statName)
	if not stat then
		warn("[StatsManager] Stat '" .. statName .. "' no encontrado para " .. player.Name)
		return nil
	end

	return stat
end

---------------------------------------------------------------------------
-- FUNCIONES PÚBLICAS: LECTURA Y ESCRITURA
---------------------------------------------------------------------------

--- Obtiene el valor actual de un stat
function StatsManager.Get(player: Player, statName: string): any
	local stat = StatsManager._getStat(player, statName)
	if stat then
		return stat.Value
	end
	return nil
end

--- Establece el valor de un stat
function StatsManager.Set(player: Player, statName: string, value: any)
	local stat = StatsManager._getStat(player, statName)
	if stat then
		stat.Value = value
	end
end

--- Suma una cantidad a un stat numérico (IntValue o NumberValue)
function StatsManager.Add(player: Player, statName: string, amount: number)
	local stat = StatsManager._getStat(player, statName)
	if stat then
		if stat:IsA("IntValue") or stat:IsA("NumberValue") then
			stat.Value = stat.Value + amount
		else
			warn("[StatsManager] Add() solo funciona con IntValue o NumberValue. '" .. statName .. "' es " .. stat.ClassName)
		end
	end
end

--- Incrementa un stat numérico en 1
function StatsManager.Increment(player: Player, statName: string)
	StatsManager.Add(player, statName, 1)
end

return StatsManager
