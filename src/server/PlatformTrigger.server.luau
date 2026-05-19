local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local PlayerData = require(script.Parent.DataStore.PlayerData)

local DEBOUNCE_TIME = 0.5
local debounce = {}

local function setupPlatformTrigger(part)
	part.Touched:Connect(function(hit)
		-- Verificar que sea un personaje de jugador
		local character = hit.Parent
		if not character then return end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Debounce
		if debounce[player.UserId] then return end
		debounce[player.UserId] = true

		-- Obtener el nombre del parent como número
		local parentName = part.Parent.Name
		local stageNumber = tonumber(parentName)

		if stageNumber then
			-- Actualizar Stage en PlayerData (y automáticamente en leaderstats)
			PlayerData:UpdateStat(player, "Stage", stageNumber)
		else
			warn("[PlatformTrigger] El parent '" .. parentName .. "' no es un número válido")
		end

		task.delay(DEBOUNCE_TIME, function()
			debounce[player.UserId] = nil
		end)
	end)
end

-- Configurar triggers existentes al iniciar
for _, part in ipairs(CollectionService:GetTagged("PlatformTrigger")) do
	if part:IsA("BasePart") then
		setupPlatformTrigger(part)
	end
end

-- Configurar triggers que se agreguen después (ej. clonados)
CollectionService:GetInstanceAddedSignal("PlatformTrigger"):Connect(function(part)
	if part:IsA("BasePart") then
		setupPlatformTrigger(part)
	end
end)

print("[PlatformTrigger] Sistema inicializado correctamente")

---------------------------------------------------------------------------
-- 🔍 DIAGNÓSTICO TEMPORAL - Eliminar después de debuggear
---------------------------------------------------------------------------
task.defer(function()
	local plataformasFolder = workspace:FindFirstChild("Plataformas")
	if not plataformasFolder then
		warn("[DIAG] No se encontró la carpeta 'Plataformas' en Workspace")
		return
	end

	print("\n[DIAG] ========== DIAGNÓSTICO DE TRIGGERS ==========")
	for i = 1, 15 do
		local platform = plataformasFolder:FindFirstChild(tostring(i))
		if platform then
			local trigger = platform:FindFirstChild("Trigger")
			if trigger and trigger:IsA("BasePart") then
				local tags = CollectionService:GetTags(trigger)
				print(string.format(
					"[DIAG] Plataforma %d | CanTouch=%s | CanCollide=%s | Anchored=%s | Size=%s | Pos=%s | Tags=%s",
					i,
					tostring(trigger.CanTouch),
					tostring(trigger.CanCollide),
					tostring(trigger.Anchored),
					tostring(trigger.Size),
					tostring(trigger.Position),
					table.concat(tags, ",")
				))
			else
				warn("[DIAG] Plataforma " .. i .. ": NO tiene un hijo 'Trigger' que sea BasePart")
				-- Listar los hijos para ver qué tiene
				for _, child in platform:GetChildren() do
					print("[DIAG]   -> hijo: " .. child.Name .. " (" .. child.ClassName .. ")")
				end
			end
		else
			warn("[DIAG] Plataforma " .. i .. " NO encontrada en la carpeta")
		end
	end
	print("[DIAG] ================================================\n")
end)