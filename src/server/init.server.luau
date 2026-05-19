print("Hello world, from server!")

local Players = game:GetService("Players")
local PlayerData = require(script.DataStore.PlayerData)

Players.PlayerAdded:Connect(function(player)
	PlayerData:Load(player)
end)


Players.PlayerRemoving:Connect(function(player)
	PlayerData:Save(player)
	PlayerData:Remove(player)
end)


game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerData:Save(player)
	end
end)