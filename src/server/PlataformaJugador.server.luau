-- PlataformaJugador.server.luau
-- Clona "PlataformaJugadorModelo" de ReplicatedStorage y la suelda
-- a la mano derecha (RightHand) de cada jugador R15 con un WeldConstraint.
-- Escucha un RemoteEvent para alternar visibilidad/colisiones desde el cliente.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MODELO_NOMBRE = "PlataformaJugadorModelo"
local OFFSET = Vector3.new(-1.5, -1, 0) -- Offset respecto a la mano derecha (ajustable)

local plataformaModelo = ReplicatedStorage:WaitForChild(MODELO_NOMBRE)

-- Crear RemoteEvent para que el cliente pueda pedir el toggle
local toggleEvent = Instance.new("RemoteEvent")
toggleEvent.Name = "TogglePlataformaEvent"
toggleEvent.Parent = ReplicatedStorage

-- Tabla para rastrear las plataformas activas por jugador
local plataformasActivas: { [Player]: Model } = {}

local function obtenerPrimaryPart(modelo: Model): BasePart?
	if modelo.PrimaryPart then
		return modelo.PrimaryPart
	end
	-- Buscar la primera BasePart como fallback
	for _, child in modelo:GetDescendants() do
		if child:IsA("BasePart") then
			return child
		end
	end
	return nil
end

local function soldarPlataforma(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Esperar a que el rig R15 tenga la mano derecha
	local rightHand = character:WaitForChild("RightHand", 10)
	if not rightHand or not rightHand:IsA("BasePart") then
		warn("[PlataformaJugador] No se encontró RightHand en el character de " .. player.Name)
		return
	end

	-- Destruir plataforma anterior si existe
	if plataformasActivas[player] then
		plataformasActivas[player]:Destroy()
		plataformasActivas[player] = nil
	end

	-- Clonar el modelo
	local clon = plataformaModelo:Clone()
	clon.Name = "Plataforma_" .. player.Name

	-- Obtener la parte principal del modelo clonado
	local primaryPart = obtenerPrimaryPart(clon)
	if not primaryPart then
		warn("[PlataformaJugador] El modelo no tiene BasePart para soldar")
		clon:Destroy()
		return
	end

	-- Asignar PrimaryPart si no tiene una
	if not clon.PrimaryPart then
		clon.PrimaryPart = primaryPart
	end

	-- Posicionar el modelo en la mano + offset
	local targetCFrame = rightHand.CFrame * CFrame.new(OFFSET)
	clon:PivotTo(targetCFrame)

	-- Anclar todas las partes temporalmente para evitar que caigan al crear el weld
	local partesDesancladas: { BasePart } = {}
	for _, parte in clon:GetDescendants() do
		if parte:IsA("BasePart") then
			if not parte.Anchored then
				table.insert(partesDesancladas, parte)
			end
			parte.Anchored = false
			parte.CanCollide = false -- Evitar colisiones con el jugador
		end
	end

	-- Crear WeldConstraint entre la PrimaryPart del clon y RightHand
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rightHand
	weld.Part1 = primaryPart
	weld.Parent = primaryPart

	-- Si el modelo tiene varias partes, soldarlas entre sí para que se muevan como una unidad
	for _, parte in clon:GetDescendants() do
		if parte:IsA("BasePart") and parte ~= primaryPart then
			local weldInterno = Instance.new("WeldConstraint")
			weldInterno.Part0 = primaryPart
			weldInterno.Part1 = parte
			weldInterno.Parent = parte
		end
	end

	-- Parentear al character para que se destruya con él
	clon.Parent = character

	-- Guardar referencia
	plataformasActivas[player] = clon

	-- Iniciar la plataforma OCULTA (transparente y sin colisiones)
	for _, parte in clon:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Transparency = 1
			parte.CanCollide = false
		end
		if parte:IsA("Decal") or parte:IsA("Texture") then
			parte.Transparency = 1
		end
	end
end

local function onCharacterAdded(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Limpiar referencia anterior (el modelo ya fue destruido con el character viejo)
	if plataformasActivas[player] then
		if plataformasActivas[player].Parent then
			plataformasActivas[player]:Destroy()
		end
		plataformasActivas[player] = nil
	end

	-- Esperar a que el character cargue completamente
	if not character:IsDescendantOf(workspace) then
		character.AncestryChanged:Wait()
	end

	-- Esperar a que el Humanoid exista (señal de que el rig está listo)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	task.wait(1)

	-- Verificar que este character sigue siendo el actual (evitar race conditions)
	if player.Character ~= character then return end

	soldarPlataforma(character)
end

local function onPlayerAdded(player: Player)
	-- Si ya tiene character (raro pero posible)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end

	-- Escuchar futuros respawns
	player.CharacterAdded:Connect(onCharacterAdded)
end

local function onPlayerRemoving(player: Player)
	-- Limpiar referencia
	if plataformasActivas[player] then
		plataformasActivas[player]:Destroy()
		plataformasActivas[player] = nil
	end
end

-- Conectar eventos
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Manejar jugadores que ya estén en el servidor (por si el script carga tarde)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- ============================================================================
-- RemoteEvent: Toggle visibilidad y colisiones de la plataforma
-- ============================================================================
local function setPlataformaVisible(player: Player, visible: boolean)
	local plataforma = plataformasActivas[player]
	if not plataforma then return end

	local transparencia = if visible then 0 else 1
	local colisiones = visible

	for _, parte in plataforma:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Transparency = transparencia
			parte.CanCollide = colisiones
		end
		if parte:IsA("Decal") or parte:IsA("Texture") then
			parte.Transparency = transparencia
		end
	end
end

toggleEvent.OnServerEvent:Connect(function(player: Player, visible: any)
	-- Validar que el argumento sea booleano (seguridad contra exploits)
	if typeof(visible) ~= "boolean" then return end
	setPlataformaVisible(player, visible)
end)

print("[PlataformaJugador] Sistema inicializado")
