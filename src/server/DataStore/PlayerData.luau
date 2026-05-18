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


function PlayerData:Load(player)
	local data = DSS:Get(player.UserId)


	if not data then
		data = deepCopy(Settings.DefaultData)
	end


	SessionData[player] = data
	print(data)
	return data
end


function PlayerData:Get(player)
	return SessionData[player]
end


function PlayerData:Save(player)
	if SessionData[player] then
		DSS:Set(player.UserId, SessionData[player])
	end
end


function PlayerData:Remove(player)
	SessionData[player] = nil
end


return PlayerData