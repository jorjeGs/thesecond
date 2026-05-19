local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerData = require(game.ServerScriptService.Server.DataStore:WaitForChild("PlayerData"))

-- CONFIG
local FALL_Y_LIMIT = -10
local CHECK_INTERVAL = 0.2
local PLATFORMS_FOLDER = "Plataformas"
local DATA_TIMEOUT = 10

-- Esperar PlayerData con timeout
local function waitForPlayerData(player)
	local startTime = os.clock()

	while os.clock() - startTime < DATA_TIMEOUT do
		local data = PlayerData:Get(player)
		if data then
			return data
		end
		task.wait()
	end

	warn("TeleportSystem: Timeout esperando PlayerData para", player.Name)
	return nil
end

-- Obtener Stage del jugador
local function getPlayerStage(player)
	local data = waitForPlayerData(player)
	return data and data.Stage or 0
end

-- Obtener CFrame del Stage
local function getStageCFrame(stage)
	if stage == 0 then
		local part0 = Workspace:FindFirstChild("0")
		if part0 and part0:IsA("BasePart") then
			return part0.CFrame
		end
		return nil
	end

	local platforms = Workspace:FindFirstChild(PLATFORMS_FOLDER)
	if not platforms then return nil end

	local model = platforms:FindFirstChild(tostring(stage))
	if not model or not model:IsA("Model") then return nil end
	if not model.PrimaryPart then return nil end

	return model.PrimaryPart.CFrame
end

-- Teletransportar jugador a su Stage
local function teleportToStage(player)
	if not player.Character then return end

	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local stage = getPlayerStage(player)
	local cframe = getStageCFrame(stage)

	if cframe then
		root.CFrame = CFrame.new(cframe.Position + Vector3.new(0, 5, 0)) * CFrame.Angles(0, math.rad(-90), 0)
	end
end

-- Monitor de caída por personaje
local function monitorCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then return end

	task.spawn(function()
		while character.Parent and player.Parent do
			if root.Position.Y < FALL_Y_LIMIT then
				teleportToStage(player)
				task.wait(1) -- evitar bucle instantáneo
			end
			task.wait(CHECK_INTERVAL)
		end
	end)
end

-- PlayerAdded
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		monitorCharacter(player, character)
	end)
end)
