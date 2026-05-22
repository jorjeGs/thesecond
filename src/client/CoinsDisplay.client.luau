-- CoinsDisplay.client.luau
-- Updates the CoinsText UI to display the player's current Coins from leaderstats.
-- Lives in StarterPlayerScripts via Rojo, accesses GUI through PlayerGui.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ============================================================================
-- GUI References & State
-- ============================================================================
local playerGui = player:WaitForChild("PlayerGui", math.huge)
local coinsTextLabel = nil
local coinsValueConnection = nil

local function formatCoins(value: number): string
	if value < 1000 then
		return tostring(value)
	elseif value < 1000000 then
		local formatted = string.format("%.2f", value / 1000)
		formatted = string.gsub(formatted, "%.?0+$", "")
		return formatted .. "k"
	elseif value < 1000000000 then
		local formatted = string.format("%.2f", value / 1000000)
		formatted = string.gsub(formatted, "%.?0+$", "")
		return formatted .. "M"
	else
		local formatted = string.format("%.2f", value / 1000000000)
		formatted = string.gsub(formatted, "%.?0+$", "")
		return formatted .. "B"
	end
end

-- ============================================================================
-- Display Update Logic
-- ============================================================================
local function updateCoinsDisplay(value)
	if coinsTextLabel then
		coinsTextLabel.Text = formatCoins(value)
	end
end

-- ============================================================================
-- Leaderstats Setup
-- ============================================================================
local function setupLeaderstatsTracking()
	-- Clean up old connection if any
	if coinsValueConnection then
		coinsValueConnection:Disconnect()
		coinsValueConnection = nil
	end

	-- Wait for leaderstats and Coins value to exist
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		return
	end

	local coinsValue = leaderstats:WaitForChild("Coins", 10)
	if not coinsValue or not coinsValue:IsA("ValueBase") then
		return
	end

	-- Connect change listener and update initial display
	coinsValueConnection = coinsValue.Changed:Connect(updateCoinsDisplay)
	updateCoinsDisplay(coinsValue.Value)
end

-- ============================================================================
-- Character Setup (handles UI recreation on respawn due to ResetOnSpawn)
-- ============================================================================
local function onCharacterAdded(character)
	-- Resolve current UI references
	local success = pcall(function()
		local gameGui = playerGui:WaitForChild("GameGui", 10)
		if not gameGui then return end
		local botonesDerechaFrame = gameGui:WaitForChild("BotonesDerechaFrame", 10)
		local coinsFrame = botonesDerechaFrame:WaitForChild("CoinsFrame", 10)
		coinsTextLabel = coinsFrame:WaitForChild("CoinsText", 10)
	end)

	if not success or not coinsTextLabel then
		return
	end

	-- Re-run leaderstats setup to bind to the new UI label
	setupLeaderstatsTracking()
end

-- Connect to current character (if already loaded) and future respawns
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
