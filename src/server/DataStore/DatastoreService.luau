local DataStoreService = game:GetService("DataStoreService")
local Settings = require(script.Parent.Settings)


local Store = DataStoreService:GetDataStore(Settings.StoreName)
local DSS = {}


function DSS:Get(userId)
	local success, data = pcall(function()
		return Store:GetAsync(userId)
	end)


	if success then
		return data
	else
		warn("Error loading data:", data)
		return nil
	end
end


function DSS:Set(userId, data)
	local success, err = pcall(function()
		Store:SetAsync(userId, data)
	end)


	if not success then
		warn("Error saving data:", err)
	end
end


return DSS