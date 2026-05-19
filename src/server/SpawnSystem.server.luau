local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerData = require(game.ServerScriptService.Server.DataStore:WaitForChild("PlayerData"))

Players.CharacterAutoLoads = false

-- CONFIG
local RESPAWN_TIME = 1
local PLATFORMS_FOLDER = "Plataformas"
local DATA_TIMEOUT = 10 -- segundos m�x esperando datos

-- ? Esperar a que PlayerData est� cargado
local function waitForPlayerData(player)
	local startTime = os.clock()

	while os.clock() - startTime < DATA_TIMEOUT do
		local data = PlayerData:Get(player)
		if data then
			return data
		end
		task.wait()
	end

	warn("SpawnSystem: Timeout esperando PlayerData para", player.Name)
	return nil
end

-- Obtener Stage (SEGURADO)
local function getPlayerStage(player)
	local data = waitForPlayerData(player)
	return data and data.Stage or 0
end

-- Obtener CFrame de spawn seg�n Stage
local function getSpawnCFrame(stage)
	-- Stage 0
	if stage == 0 then
		local part0 = Workspace:FindFirstChild("0")
		if part0 and part0:IsA("BasePart") then
			return part0.CFrame
		end
		warn("SpawnSystem: No existe Workspace > 0")
		return nil
	end

	-- Stage > 0
	local platforms = Workspace:FindFirstChild(PLATFORMS_FOLDER)
	if not platforms then
		warn("SpawnSystem: No existe la carpeta Plataformas")
		return nil
	end

	local model = platforms:FindFirstChild(tostring(stage))
	if not model or not model:IsA("Model") then
		warn("SpawnSystem: Plataforma no encontrada:", stage)
		return nil
	end

	if not model.PrimaryPart then
		warn("SpawnSystem: El modelo", stage, "no tiene PrimaryPart")
		return nil
	end

	return model.PrimaryPart.CFrame
end

-- Spawnear personaje
local function spawnCharacter(player)
	if not player then return end

	-- ? Asegurar datos antes de spawnear
	local stage = getPlayerStage(player)

	player:LoadCharacter()

	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then return end

	local spawnCFrame = getSpawnCFrame(stage)
	if spawnCFrame then
		root.CFrame = CFrame.new(spawnCFrame.Position + Vector3.new(0, 5, 0)) * CFrame.Angles(0, math.rad(-90), 0)
	end
end

-- Respawn al morir
local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		task.wait(RESPAWN_TIME)

		if player and player.Parent == Players then
			spawnCharacter(player)
		end
	end)
end

-- PlayerAdded
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	
	spawnCharacter(player)
end)
