-- RemoteEvents para la navegación de stages por UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local remotesFolder

if RunService:IsServer() then
	-- SERVIDOR: crear la carpeta y los RemoteEvents
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage

	local teleportEvent = Instance.new("RemoteEvent")
	teleportEvent.Name = "TeleportToStage"
	teleportEvent.Parent = remotesFolder
else
	-- CLIENTE: esperar a que el servidor los haya creado
	remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
end

Remotes.TeleportToStage = remotesFolder:WaitForChild("TeleportToStage")

return Remotes
