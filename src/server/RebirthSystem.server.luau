-- RebirthSystem.server.luau
-- Handles the server-side logic for the Rebirth system.
-- Deducts coins, increments rebirths, resets stages, and respawns player at Stage 0.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.DataStore.PlayerData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- CONFIGURATION
local REBIRTH_COST = 100

local function onRebirthRequested(player: Player)
	local data = PlayerData:Get(player)
	if not data then
		warn("[RebirthSystem] Player data not loaded for " .. player.Name)
		return
	end

	local currentCoins = data.Coins or 0
	local currentRebirths = data.Rebirths or 0

	-- Check if player has enough coins
	if currentCoins >= REBIRTH_COST then
		local newCoins = currentCoins - REBIRTH_COST
		local newRebirths = currentRebirths + 1

		-- Update all stats in player data & leaderstats
		PlayerData:UpdateStat(player, "Coins", newCoins)
		PlayerData:UpdateStat(player, "Stage", 0)
		PlayerData:UpdateStat(player, "Max Stage", 0)
		PlayerData:UpdateStat(player, "Rebirths", newRebirths)

		print(("[RebirthSystem] Rebirth successful for %s. Rebirths: %d, Coins remaining: %.2f"):format(player.Name, newRebirths, newCoins))

		-- Respawn player at stage 0 (since their Stage stat is now 0)
		task.spawn(function()
			player:LoadCharacter()
		end)
	else
		warn(("[RebirthSystem] %s attempted to Rebirth but lacked coins (Has: %.2f, Cost: %d)"):format(player.Name, currentCoins, REBIRTH_COST))
	end
end

-- Connect RemoteEvent
Remotes.RebirthRequest.OnServerEvent:Connect(onRebirthRequested)

print("[RebirthSystem Server] Inicializado correctamente")
